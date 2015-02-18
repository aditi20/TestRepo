/*
 * Class that deals with generating the meta data used by mobile clients
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class GenerateMetaData {

    // The suffix for the file name that will contain the metadata json for a given device
    public static final String METADATA_ATTACHMENT_NAME = '_metadata.json';

    /**
     * Get the attachment that contains the previous full metadata json. If the attachment didn't exist the create it
     *
     * @param parentId - The id of the parent object. It could be a Mobile_User__c or a Contact.
     * @param deviceId - The Device__c.DeviceId__c that the metadata is being generated for
     * @param lastSync - The time stamp for the last time the device synchronized
     *
     * @return - The attachment
     */
    public static Attachment getPreviousMetaDataAttachment(
            Id parentId,
            String deviceId,
            DateTime lastSync
    ) {
        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Attachment.Body,
                Attachment.Name,
                Attachment.ParentId
            }
        );
        Attachment previousAttachment;
        if(lastSync != null){
            String selectQuery = 'SELECT Body ' +
                                 'FROM Attachment ' +
                                 'WHERE Name = \'' + String.escapeSingleQuotes(deviceId) + lastSync.getTime() + METADATA_ATTACHMENT_NAME + '\' ' +
                                   'AND ParentId = \'' + String.escapeSingleQuotes(parentId) + '\'';
            Attachment[] attachments = DBFullAccess.querySObject(selectQuery);

            if (!attachments.isEmpty()) {
                previousAttachment = attachments[0];

                // Clean uneeded metadata attachments
                String deleteQuery = 'SELECT Id ' +
                                     'FROM Attachment ' +
                                     'WHERE ParentId = \'' + String.escapeSingleQuotes(parentId) + '\' ' +
                                       'AND Name LIKE \'' + String.escapeSingleQuotes(deviceId) + '%' + METADATA_ATTACHMENT_NAME + '\' ' +
                                       'AND Id != \'' + previousAttachment.Id + '\'';

                Attachment[] attachmentsToDelete = DBFullAccess.querySObject(deleteQuery);
                attachmentCreator.checkObjectDeletable();
                DBFullAccess.deleteSObject(attachmentsToDelete);
            }
        }

        return previousAttachment != null
               ? previousAttachment
               : new Attachment(Name = deviceId + METADATA_ATTACHMENT_NAME, ParentId = parentId);
    }

    /**
     * Get the metadata delta for the given user and device
     *
     * @param attachmentParent - The id of the parent object. It could be a Mobile_User__c or a Contact
     * @param deviceId         - The Device__c.Device_Id__c that the metadata is being generated for
     * @param lastSync         - The time stamp for the last time the device synchronized
     * @param newSync          - The time stamp for this synchronization
     * @param requiredObjects  - The hierarchy metadata for the mobile user
     *
     * @return the metadata delta for the response
     */
    public static MetaDataDelta getMetaDataDelta(
            Id attachmentParent,
            String deviceId,
            DateTime lastSync,
            DateTime newSync,
            Map<String, HierarchyObjectDefinitions> requiredObjects
    ) {
        return getMetaDataDelta(
            attachmentParent, deviceId, getPreviousMetaDataAttachment(attachmentParent, deviceId, lastSync), newSync, requiredObjects
        );
    }

    /**
     * Update the Taro works metadata for a given mobile user with a given device.
     * Calling method is responsible for updating the attachment to have the latest full metadata
     *
     * @param attachmentParent - The id of the parent object. It could be a Mobile_User__c or a Contact
     * @param deviceId        - Device__c.Device_Id__c that the metadata is being generated for
     * @param attachment      - The attachment that does or will contain the most recent metadata
     * @param newSync         - The time stamp for this synchronization
     * @param requiredObjects - The hierarchy metadata for the mobile user
     *
     * @return - An instance of MetaDataDelta class with the corresponding meta data delta
     */
    public static MetaDataDelta getMetaDataDelta(
            Id attachmentParent,
            String deviceId,
            Attachment attachment,
            DateTime newSync,
            Map<String, HierarchyObjectDefinitions> requiredObjects
    ) {

        // Get the old metadata attachment from the Contact record
        FullMetaData originalMetaData;

        if (attachment.Body == null) {
            originalMetaData = new FullMetaData();
        }
        else {
            try {
                originalMetaData = (FullMetaData)JSON.deserialize(attachment.Body.toString(), FullMetaData.class);
            }
            catch (Exception e) {

                // Original metadata is garbled so start again
                originalMetaData = new FullMetaData();
                System.debug(LoggingLevel.INFO, e.getMessage());
            }
        }

        // Generate the new full meta data
        FullMetaData newMetaData = generateFullMetaData(requiredObjects);
        saveMetaData(attachmentParent, deviceId, newSync, newMetaData);

        // Get the delta
        MetaDataDelta metaDataDelta = getMetaDataDifference(originalMetaData, newMetaData);

        // Return the delta
        return metaDataDelta;
    }

    /**
     * Add the metadata json to an attachment and save to the DB
     *
     * @param parentId - The id of the parent object. It could be a Mobile_User__c or a Contact.
     * @param deviceId - Device__c.Device_Id__c that the metadata is being generated for
     * @param newSync  - The time stamp for this synchronization
     * @param metadata - FullMetaData object
     */
    public static void saveMetaData(
            Id parentId,
            String deviceId,
            DateTime newSync,
            FullMetaData metadata
    ) {
        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        Attachment newMetaData = (Attachment) attachmentCreator.createNewRecord();
        attachmentCreator.populateFields(
            newMetaData,
            new Map<Schema.SObjectField, Object> {
                Attachment.Name => deviceId + newSync.getTime() + METADATA_ATTACHMENT_NAME,
                Attachment.ParentId => parentId,
                Attachment.Body => Blob.valueOf(JSON.serialize(metadata))
            }
        );
        DBFullAccess.insertSObject(newMetaData);
    }

    /**
     * Generate the full meta data for a given mobile user.
     * Currently this means getting all the JobTemplates in the system but in future groups would be used to only allow certain JobTemplates for given FOs
     *
     * @param requiredObjects - The hierarchy metadata for the mobile user
     *
     * @return - The full meta-data for the mobile user. Calling method needs to serialize it
     */
    public static FullMetaData generateFullMetaData(Map<String, HierarchyObjectDefinitions> requiredObjects) {

        FullMetaData fullMetaData = new FullMetaData();

        // Loop through the objects recovered and create an ObjectDefinition for it
        for (String objectName : requiredObjects.keySet()) {
            Schema.DescribeSObjectResult objectDescribe = DescribeHandler.getObjectDescribeResult(objectName, true);

            ObjectDefinition objectDefinition = new ObjectDefinition(objectName);

            // Loop through the returned fields and add the field definition
            for (String fieldName : requiredObjects.get(objectName).fieldNames) {
                Schema.DescribeFieldResult fieldDescribe = DescribeHandler.getFieldDescribe(objectName, fieldName);

                // Check to see if the field is a reference
                String fieldType = fieldDescribe.getType().name();
                if (fieldType.equals(Schema.DisplayType.Reference.name())) {
                    // TODO - It is possible for a reference to be to two objects. This is ignored here but we will need to think about it
                    // I am a little worried about the possibility of hitting the describe limit here
                    fieldType = fieldType + ' (' + fieldDescribe.getReferenceTo()[0].getDescribe().getName() + ')';
                }
                objectDefinition.addFieldDefinition(
                    new FieldDefinition(
                        fieldDescribe.getName(),
                        fieldDescribe.getLabel(),
                        fieldType,
                        fieldDescribe.getLength()
                    )
                );
            }
            fullMetaData.addObjectDefinition(objectDefinition);
        }

        // Return the full meta-data
        return fullMetaData;
    }

    /**
     * Calculate the delta between two meta-datas
     *
     * @return - The MetaDataDelta object that contains the differences between the two metadatas
     *              null if there is no difference
     */
    public static MetaDataDelta getMetaDataDifference(String originalMetaData, String newMetaData) {

        // Check that they are not the same
        if (originalMetaData.equals(newMetaData)) {
            return null;
        }

        return getMetaDataDifference(
            (FullMetaData)JSON.deserialize(originalMetaData, FullMetaData.class),
            (FullMetaData)JSON.deserialize(newMetaData, FullMetaData.class)
        );
    }
    public static MetaDataDelta getMetaDataDifference(String originalMetaData, FullMetaData newMetaData) {
        return getMetaDataDifference((FullMetaData)JSON.deserialize(originalMetaData, FullMetaData.class), newMetaData);
    }
    public static MetaDataDelta getMetaDataDifference(FullMetaData originalMetaData, FullMetaData newMetaData) {
        MetaDataDelta delta = new MetaDataDelta();
        Set<String> checkedObjects = new Set<String>();

        // Loop through the new full meta data and compare it to the old one
        for (String objectName : newMetaData.metaData.keySet()) {

            ObjectDefinitionDelta objectDelta = new ObjectDefinitionDelta(objectName);

            // The old meta data does not contain this object. Add all the objects field defs
            if (!originalMetaData.metaData.containsKey(objectName)) {
                objectDelta.addFieldDefs(newMetaData.metaData.get(objectName).availableFields.values());
            }
            else {

                // Loop through the new fields and add to delta if they are not in the old meta data
                for (FieldDefinition fieldDef : newMetaData.metaData.get(objectName).availableFields.values()) {

                    // Field is know about on the phone. Check for changes
                    if (originalMetaData.metaData.get(objectName).availableFields.containsKey(fieldDef.fieldName)) {
                        FieldDefinition oldFieldDef = originalMetaData.metaData.get(objectName).availableFields.get(fieldDef.fieldName);
                        if (
                                !oldFieldDef.label.equals(fieldDef.label) ||
                                !oldFieldDef.fieldType.equals(fieldDef.fieldType) ||
                                oldFieldDef.length != fieldDef.length
                        ) {
                            objectDelta.addFieldDef(fieldDef);
                        }
                    }
                    else {

                        // A newly added field so add the full field definition
                        objectDelta.addFieldDef(fieldDef);
                    }
                }

                // Loop through the old meta data and check to see if any fields have been removed
                for (FieldDefinition fieldDef : originalMetaData.metaData.get(objectName).availableFields.values()) {
                    if (!newMetaData.metaData.get(objectName).availableFields.containsKey(fieldDef.fieldName)) {
                        objectDelta.addFieldToRemove(fieldDef.fieldName);
                    }
                }
            }
            if (objectDelta.add.size() > 0 || objectDelta.remove.size() > 0) {
                delta.metaData.add(objectDelta);
            }
        }

        // Go throught the old metadata and check for any objects that have been removed
        if (!newMetaData.metaData.keySet().containsAll(originalMetaData.metaData.keySet())) {
            for (String objectName : originalMetaData.metaData.keySet()) {
                if (!newMetaData.metaData.keySet().contains(objectName)) {
                    delta.removedObjects.add(objectName);
                }
            }
        }
        return delta;
    }

    /**
     * Generate a Map of the field names for all the objects that are in the hierarchy of a list of jobs
     * Assumes that calling method is passing in only jobs it wants the hierarchy for
     *
     * @param jobTemplates - A list of the jobs that are available to the FO
     *
     * @return A map of String to a HierarchyObjectDefinitions, where the key of the map is
     *         the API name of the objects that will be sent, and the value .
     */
    public static Map<String, HierarchyObjectDefinitions> getHierarchyMetadata(List<JobTemplate__c> jobTemplates) {

        Map<String, HierarchyObjectDefinitions> objectDescription =
            new Map<String, HierarchyObjectDefinitions>();

        // Loop through the jobs
        for (JobTemplate__c jobTemplate : jobTemplates) {
            if (String.isEmpty(jobTemplate.Hierarchy__c)) {
                continue;
            }
            getHierarchyFromTemplate(
                (List<JobTemplateDo.ObjectHierarchy>)JSON.deserialize(
                    jobTemplate.Hierarchy__c, List<JobTemplateDo.ObjectHierarchy>.class
                ),
                objectDescription
            );
        }
        return objectDescription;
    }

    /**
     * Create or augment the HierarchyObjectDefinitions that a JobTemplate defines
     */
    private static void getHierarchyFromTemplate(
            List<JobTemplateDo.ObjectHierarchy> hierarchyObjects,
            Map<String, HierarchyObjectDefinitions> objectDescription
    ) {

        PathToTopLevel path;
        String topLevelApiName;
        for (JobTemplateDo.ObjectHierarchy hierarchyObject : hierarchyObjects) {
            HierarchyObjectDefinitions objDef = objectDescription.get(hierarchyObject.objectName);
            if (objDef == null) {
                objDef = new HierarchyObjectDefinitions(hierarchyObject.objectName);
            }

            // Get the list view fields for the object and add all to the set
            objDef.addFieldNames(hierarchyObject.listFields);

            // Add all the detail view fields
            if (hierarchyObject.detailFields != null && !hierarchyObject.detailFields.isEmpty()) {
                objDef.addFieldNames(hierarchyObject.detailFields);
            }
            if (hierarchyObject.relations == null || hierarchyObject.relations.isEmpty()) {
                topLevelApiName = hierarchyObject.objectName;
            } else {
                path = objDef.parseRelations(hierarchyObject.relations, path, topLevelApiName);
            }
            objectDescription.put(hierarchyObject.objectName, objDef);
        }
    }

    /**
     * Container for a meta-data delta.
     */
    public class MetaDataDelta {

        public List<ObjectDefinitionDelta> metaData;
        public List<String> removedObjects;

        public MetaDataDelta() {
            this.metaData = new List<ObjectDefinitionDelta>();
            this.removedObjects = new List<String>();
        }

        public void addToMetaData(ObjectDefinitionDelta objectDeltaDefinition) {
            this.metaData.add(objectDeltaDefinition);
        }

        public void addRemovedObjects(String objectName) {
            this.removedObjects.add(objectName);
        }
    }

    /**
     * Definition of the changes to an object since the last sync
     * Fields to add will have  a full definition.
     * Fields to remove will just be the name of the field
     */
    public class ObjectDefinitionDelta {

        public String objectName;
        public List<FieldDefinition> add;
        public List<String> remove;

        public ObjectDefinitionDelta(String objectName) {
            this.objectName = objectName;
            this.add = new List<FieldDefinition>();
            this.remove = new List<String>();
        }

        /**
         * Add a list of FieldDefinitions that are being added to the ObjectDefinitionDelta
         *
         * @param fieldDefs - The field definitions that are being added
         */
        public void addFieldDefs(List<FieldDefinition> fieldDefs) {
            this.add.addAll(fieldDefs);
        }

        /**
         * Add a FieldDefinitions to the ObjectDefinitionDelta
         *
         * @param fieldDef - The field definition that are being added
         */
        public void addFieldDef(FieldDefinition fieldDef) {
            this.add.add(fieldDef);
        }

        /**
         * Add a list of field API names that are to be removed from the metadata
         *
         * @param fieldNames - A list of field API names that are being removed from the metadata
         */
        public void addFieldToRemove(String fieldNames) {
            this.remove.add(fieldNames);
        }
    }

    /**
     * Container object for full Object Definitions so they can be serialized easily
     */
    public class FullMetaData {

        Map<String, ObjectDefinition> metaData;

        public FullMetaData() {
            this.metaData = new Map<String, ObjectDefinition>();
        }

        public void addObjectDefinition(ObjectDefinition objectDefinition) {
            this.metaData.put(objectDefinition.objectName, objectDefinition);
        }

        public Map<String, ObjectDefinition> getMetaData() {
            return this.metaData;
        }
    }

    /**
     * Definition of an object. This is not what gets sent to the phone as that is always a delta.
     * This is the full meta-data definition for an object
     */
    public class ObjectDefinition {

        String objectName;
        Map<String, FieldDefinition> availableFields;

        public ObjectDefinition(String objectName) {
            this.objectName = objectName;
            this.availableFields = new Map<String, FieldDefinition>();
        }

        /**
         * Add a new field definitions to an object
         *
         * @param field - FieldDefinition being added
         */
        public void addFieldDefinition(FieldDefinition field) {
            if (!availableFields.containsKey(field.fieldName)) {
                this.availableFields.put(field.fieldName, field);
            }
        }

        public String getObjectName() {
            return this.objectName;
        }

        public Map<String, FieldDefinition> getFieldDefs() {
            return this.availableFields;
        }
    }

    /**
     * Definition of a field for an object. This is what will be sent to the mobile to describe the field for inclusion in the DB
     */
    public class FieldDefinition {

        public String fieldName;
        public String label;
        public String fieldType;
        public Integer length;

        public FieldDefinition(String fieldName, String label, String fieldType, Integer length) {
            this.fieldName = fieldName;
            this.label = label;
            this.fieldType = fieldType;
            this.length = length;
        }

        public FieldDefinition(Schema.DescribeFieldResult fieldDescribe) {
            this.fieldName = fieldDescribe.getName();
            this.label = fieldDescribe.getLabel();
            this.fieldType = fieldDescribe.getType().name();
            if (fieldType.equals(Schema.DisplayType.Reference.name())) {
                // TODO - It is possible for a reference to be to two objects. This is ignored here but we will need to think about it
                // I am a little worried about the possibility of hitting the describe limit here
                fieldType = fieldType + ' (' + fieldDescribe.getReferenceTo()[0].getDescribe().getName() + ')';
            }
            this.length = fieldDescribe.getLength();
        }

        public String getFieldName() {
            return this.fieldName;
        }

        public String getLabel() {
            return this.label;
        }

        public String getFieldType() {
            return this.fieldType;
        }

        public Integer getLength() {
            return this.length;
        }
    }

    /**
     * Definition of the fields that an object instance data needs to include and the relationships
     * it has to parent objects.
     * Slightly mis-using the JobTemplateDO.Relation object as the parent field will be the API Name of the parent
     * not the generated id as it is in other cases
     */
    public class HierarchyObjectDefinitions {

        public String objectName;
        Set<String> fieldNames;
        Map<String, Set<String>> pathsToTop;

        public HierarchyObjectDefinitions(String objectName) {
            this.objectName = objectName;
            this.fieldNames = new Set<String>();
            this.pathsToTop = new Map<String, Set<String>>();
        }

        public String getObjectName() {
            return this.objectName;
        }

        public Set<String> getFieldNames() {
            return this.fieldNames;
        }

        public Map<String, Set<String>> getPathsToTop() {
            return this.pathsToTop;
        }

        public PathToTopLevel parseRelations(
                List<JobTemplateDo.Relation> relations,
                PathToTopLevel path,
                String topLevelApiName
        ) {

            // TODO - This only works as we allow 1 path to the top at the moment.
            //          Will need to update this when that restriction is lifted
            for (JobTemplateDo.Relation relation : relations) {
                if (path == null) {
                    path = new PathToTopLevel(relation.field);
                } else {
                    path.updatePath(relation.field);
                }
                this.addPath(topLevelApiName, path.path);
                this.addFieldName(relation.field);
            }
            return path;
        }

        /**
         * Add a list of field API names to the fieldNames set
         */
        public void addFieldNames(List<String> fieldNames) {
            this.fieldNames.addAll(fieldNames);
        }

        /**
         * Add a  field API name to the fieldNames set
         */
        public Boolean addFieldName(String fieldName) {
            return this.fieldNames.add(fieldName);
        }

        @TestVisible
        private void addPath(String topLevelApiName, String path) {

            Set<String> pathsToTopLevelObject = this.pathsToTop.get(topLevelApiName);
            if (pathsToTopLevelObject == null) {
                pathsToTopLevelObject = new Set<String>();
            }
            pathsToTopLevelObject.add(path);
            this.pathsToTop.put(topLevelApiName, pathsToTopLevelObject);
        }

        public Boolean isOnlyTopLevel() {
            return this.pathsToTop.size() == 0;
        }

        public String buildQuery(Map<String, Set<String>> topLevelIds) {

            String whereClause = buildWhereClause(topLevelIds);
            if (
                    (
                        this.pathsToTop.isEmpty() &&
                        !topLevelIds.containsKey(this.objectName)
                    ) ||
                    String.isEmpty(whereClause)
            ) {
                return '';
            }

            return buildSelectClause() + buildFromClause() + buildWhereClause(topLevelIds);
        }

        private String buildSelectClause() {

            List<String> fieldNames = new List<String>();
            Boolean addedLastModified = this.addFieldName('LastModifiedDate');
            fieldNames.addAll(this.fieldNames);
            String query = 'SELECT ' + String.join(fieldNames, ',');

            // Take the last modified date out if needed so it is not included in the JSON
            if (addedLastModified) {
                this.fieldNames.remove('LastModifiedDate');
            }
            return query;
        }

        private String buildFromClause() {
            return ' FROM ' + this.objectName;
        }

        private String buildWhereClause(Map<String, Set<String>> topLevelIds) {

            List<String> clauses = new List<String>();
            for (String key : this.pathsToTop.keySet()) {
                for (String path : this.pathsToTop.get(key)) {
                    if (topLevelIds.containsKey(key)) {
                        clauses.add(createInClause(topLevelIds.get(key), path));
                    }
                }
            }
            if (topLevelIds.containsKey(this.objectName)) {
                clauses.add(createInClause(topLevelIds.get(this.objectName), 'Id'));
            }
            if (clauses.isEmpty()) {
                return '';
            } else {
                return joinClausesWithOr(clauses);
            }
        }

        private String createInClause(
                Set<String> topLevelIds,
                String path
        ) {
            StringBuilder.InClauseBuilder inClauseBuilder =
                new StringBuilder.InClauseBuilder(topLevelIds);
            inClauseBuilder.setShouldEscapeSingleQuotes(true);
            return path + ' IN (' + inClauseBuilder.generateString() + ')';
        }

        private String joinClausesWithOr(List<String> clauses) {
            return ' WHERE ' + String.join(clauses, ' OR ');
        }
    }

    /**
     * Helper class that assists in the building of a path in a WHERE clause for a SOQL query
     * TODO - Look to move when SoC is done. Possibly to SoqlQueryBuilder or something similar
     */
    @TestVisible
    private class PathToTopLevel {
        public String path;

        public PathToTopLevel(String fieldName) {
            this.path = fieldName;
        }

        @TestVisible
        private void updatePath(String fieldName) {
            path = convertToPath(fieldName) + path;
        }

        private String convertToPath(String fieldName) {
            return convertFieldName(fieldName) + '.';
        }

        private String convertFieldName(String fieldName) {

            if (fieldName.endsWithIgnoreCase('__c')) {
                fieldName = fieldName.subString(0, fieldName.length() - 1) + 'r';
            } else if (fieldName.endsWithIgnoreCase('Id')) {
                fieldName = fieldName.substringBeforeLast('Id');
            }
            return fieldName;
        }
    }
}
