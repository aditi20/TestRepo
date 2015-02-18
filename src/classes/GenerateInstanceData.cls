/*
 * Class that deals with generating the instance data used by mobile clients
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
 public without sharing class GenerateInstanceData {

    /**
     * Get the instance data for a mobile user. This will get all the records that have
     * changed since the last sync of the mobile user and also indicate the records
     * that are new or that now need to be deleted
     *
     * @param contactId              - The Contact__c.Id for the user of the phone
     * @param knowInstancesByObject  - The Ids for the instances that are on the phone already.
     *                                   Used to check for deletes
     * @param lastSync               - The date that the mobile user successfully last sync'd
     * @param requiredObjects        - The hierarchy metadata for the mobile user
     *
     * @return the instances to be sent to the mobile
     */
    public static List<ObjectInstanceDataDefinition> generateInstanceData(
            Id contactId,
            List<KnownInstance> knowInstancesByObject,
            DateTime lastSync,
            Map<String, GenerateMetaData.HierarchyObjectDefinitions> requiredObjects
    ) {

        // Build the map of known instances
        Map<String, KnownInstance> knownInstancesMap = new Map<String, KnownInstance>();
        if (knowInstancesByObject != null) {
            for (KnownInstance instance : knowInstancesByObject) {
                knownInstancesMap.put(instance.objectName, instance);
            }
        }
        return generateInstanceData(requiredObjects, contactId, knownInstancesMap, lastSync);
    }

    /**
     * Get the instance data for a mobile user. This will get all the records that have changed
     * since the last sync of the mobile user and also indicate the records that are new o
     * that now need to be deleted
     *
     * @param requiredObjects        - The object hierarchy definitions for the objects that the
     *                                   mobile user can see
     * @param contactId              - The Contact__c.Id for the user of the phone
     * @param knowInstancesByObject  - The Ids for the instances that are on the phone already.
     *                                   Used to check for deletes
     * @param lastSync               - The date that the mobile user successfully last sync'd
     *
     * @return the instances to be sent to the mobile
     */
    public static List<ObjectInstanceDataDefinition> generateInstanceData(
            Map<String, GenerateMetaData.HierarchyObjectDefinitions> requiredObjects,
            Id contactId,
            Map<String, KnownInstance> knowInstancesByObject,
            DateTime lastSync
    ) {

        InstanceDataWrapper instanceDataWrapper =
            new InstanceDataWrapper(contactId, lastSync, knowInstancesByObject);

        if (instanceDataWrapper.hasRecordsAssigned) {

            // Loop through the required objects and construct the queries for them
            for (GenerateMetaData.HierarchyObjectDefinitions definition : requiredObjects.values()) {
                instanceDataWrapper.loadObjectInstances(definition);
            }
            instanceDataWrapper.genearateDeletedInstances();
        }
        return instanceDataWrapper.getAllObjectInstances();
    }

    /**
     * Wrapper class to contain the found ObjectInstances and the foundIds
     */
    private class InstanceDataWrapper {

        Map<String, ObjectInstanceDataDefinition> objectInstances;
        Map<String, Set<Id>> foundIds;
        Map<String, Set<String>> assignedIdsByObject;
        DateTime lastSync;
        Map<String, KnownInstance> knowInstancesByObject;
        Boolean hasRecordsAssigned;

        public InstanceDataWrapper(
                Id contactId,
                DateTime lastSync,
                Map<String, KnownInstance> knowInstancesByObject
        ) {
            this.objectInstances = new Map<String, ObjectInstanceDataDefinition>();
            this.foundIds = new Map<String, Set<Id>>();
            this.assignedIdsByObject =
                SObjectContactAssociationDO.getMapOfIdsForContact(contactId);
            this.hasRecordsAssigned = this.assignedIdsByObject.size() != 0;
            this.lastSync = lastSync;
            this.knowInstancesByObject = knowInstancesByObject;
        }

        public List<ObjectInstanceDataDefinition> getAllObjectInstances() {
            return this.objectInstances.values();
        }

        public Boolean getHasRecordsAssigned() {
            return this.hasRecordsAssigned;
        }

        /**
         * Loads all the records for a given HierarchyObjectDefinitions
         */
        public void loadObjectInstances(GenerateMetaData.HierarchyObjectDefinitions definition) {
            foundIds.put(definition.getObjectName(), new Set<Id>());
            objectInstances.put(
                definition.getObjectName(), new ObjectInstanceDataDefinition(definition.getObjectName())
            );
            List<SObject> queryResults = executeQuery(definition);
            parseQueryResults(queryResults, definition);
        }

        public void genearateDeletedInstances() {
            for (String objectName : this.objectInstances.keySet()) {
                KnownInstance knownInstance = knowInstancesByObject.get(objectName);
                ObjectInstanceDataDefinition ObjectInstanceDataDefinition = objectInstances.get(objectName);
                if (knownInstance != null) {
                    knownInstance.removeAll(foundIds.get(objectName));
                    ObjectInstanceDataDefinition.setDeletedInstances(knownInstance.getExistingRecords());
                }
            }
        }

        private List<SObject> executeQuery(GenerateMetaData.HierarchyObjectDefinitions definition) {

            String query = definition.buildQuery(this.assignedIdsByObject);
            if (String.isEmpty(query)) {
                return new List<SObject>();
            } else {
                return database.query(query);
            }
        }

        private void parseQueryResults(
                List<SObject> queryResults,
                GenerateMetaData.HierarchyObjectDefinitions definition
        ) {
            if (!queryResults.isEmpty()) {
                for (Sobject record : queryResults) {
                    parseRecord(record, definition);
                }
            }
        }

        private void parseRecord(
                SObject record, 
                GenerateMetaData.HierarchyObjectDefinitions definition
        ) {
            Id recordId = (Id)record.get('id');
            this.foundIds.get(definition.getObjectName()).add(recordId);
            if (
                    includeRecord(
                        record.get('LastModifiedDate'), recordId, definition.getObjectName()
                    )
            ) {
                objectInstances.get(definition.getObjectName()).addRecord(
                    new InstanceDefinition(record, definition.getFieldNames())
                );
            }
        }
        private Boolean includeRecord(
                Object lastModifiedDateString,
                String recordId,
                String objectName
        ) {
            return (
                (
                    this.lastSync == null ||
                    (DateTime.valueOf(lastModifiedDateString).getTime() > this.lastSync.getTime())
                ) ||
                (
                    this.knowInstancesByObject.get(objectName) == null ||
                    !this.knowInstancesByObject.get(objectName).getExistingRecords().contains(recordId)
                )
            );
        }
    }

    /**
     * Container class for an object's records
     * Used to ease serialization
     */
    public class ObjectInstanceDataDefinition {
        String objectName;
        List<InstanceDefinition> records;
        Set<Id> deletedInstances;

        public ObjectInstanceDataDefinition(String objectName) {
            this.objectName = objectName;
            this.records = new List<InstanceDefinition>();
            this.deletedInstances = new Set<Id>();
        }

        public void addRecord(InstanceDefinition record) {
            this.records.add(record);
        }

        public Set<Id> getDeletedInstances() {
            return this.deletedInstances;
        }

        public void setDeletedInstances(Set<Id> ids) {
            this.deletedInstances = ids;
        }

        public String getObjectName() {
            return this.objectName;
        }

        public List<InstanceDefinition> getRecords() {
            return this.records;
        }
    }

    /**
     * Container class for the definition of a record
     * Used to ease serialization
     */
    public class InstanceDefinition {
        public Id instanceId;
        List<FieldValue> fieldValues;

        public InstanceDefinition(SObject record) {
            this.instanceId = (Id)record.get('id');
            this.fieldValues = new List<FieldValue>();
        }

        public InstanceDefinition(
                SObject record,
                Set<String> fieldNames
        ) {
            this(record);
            for (String fieldName : fieldNames) {
                addFieldValue(
                    new Fieldvalue(
                        fieldName,
                        populateFieldValue(record, fieldName)
                    )
                );
            }
        }

        public InstanceDefinition(
                SObject record,
                List<String> fieldNames
        ) {
            this(record);
            for (String fieldName : fieldNames) {
                addFieldValue(
                    new Fieldvalue(
                        fieldName,
                        populateFieldValue(record, fieldName)
                    )
                );
            }
        }

        public void addFieldValue(FieldValue fieldValue) {
            this.fieldValues.add(fieldValue);
        }

        public Id getInstanceId() {
            return this.instanceId;
        }
    }

    /**
     * Method to process fields and make proper format for geolocation fields
     */
    @TestVisible
    private static String populateFieldValue(SObject record, String fieldName) {
        String fieldValue = '';
        String objectName = record.getSObjectType().getDescribe().getName();

        fieldValue =
            String.valueOf(
                record.get(
                    DescribeHandler.getFieldType(
                        objectName,
                        fieldName
                    )
                )
            );
        if (
                DescribeHandler.getFieldDescribe(objectName, fieldName).getType() ==
                Schema.Displaytype.LOCATION
        ) {
            fieldValue = SurveyUtils.formatGeolocationFields(fieldValue);
        }

        return fieldValue;
    }

    /**
     * Cointainer class for a field value.
     * Used so the number of fields sent down can be of length n
     * Used to ease serialization
     */
    public class FieldValue {
       String fieldName;
       String fieldValue;

        public FieldValue(String fieldName, String fieldValue) {
            this.fieldName = fieldName;
            this.fieldValue = fieldValue;
        }
    }

    /**
     * Class to represent the object instances that are already on the mobile.
     */
    public class KnownInstance {

        public String objectName;
        public Set<Id> records;

        /**
         * Constructor
         *
         * @param objectName - The API name for the object
         */
        public KnownInstance(String objectName) {
            this.objectName = objectName;
            this.records = new Set<Id>();
        }

        public void addRecords(Set<Id> records) {
            this.records = records;
        }

        public Set<Id> getExistingRecords() {
            return this.records;
        }

        public void removeAll(Set<Id> toRemove) {
            this.records.removeAll(toRemove);
        }
    }
}