/**
 * Domain class for the SObjectContactAssociation object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Aditi Satpute
 */
public with sharing class SObjectContactAssociationDO extends SObjectDomain {

    @TestVisible
    private static final Integer MAX_LENGTH_OF_ASSOCIATE_IDS = 1700;

    public SObjectContactAssociationDO() {
        super(SObjectContactAssociation__c.SObjectType);
    }
    public SObjectContactAssociationDO(List<SObjectContactAssociation__c> sObjects) {
        super(sObjects);
    }

    /**
     * Create all the SObjectContactAssociation__c needed to deal with any given
     * number of AssoctaitedIds. Will create 1 or many. Uses different branches for
     * 1 OR many to aid efficency
     */
    public static List<SObjectContactAssociation__c> createNewRecords(
        Id contactId,
        String sObjectApiName,
        List<Id> associatedIds
    ) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();

        List<SObjectContactAssociation__c> newSObjectContactAssociation =
            new List<SObjectContactAssociation__c>();
        if (associatedIds.size() < MAX_LENGTH_OF_ASSOCIATE_IDS) {
            newSObjectContactAssociation.add(createNew(
                contactId,
                sObjectApiName,
                associatedIds
            ));
        } else {
            newSObjectContactAssociation.addAll(associateMultipleInstances(
                contactId,
                sObjectApiName,
                associatedIds,
                new List<SObjectContactAssociation__c>()
            ));
        }
        return newSObjectContactAssociation;
    }

    /**
     * Create a new SObjectContactAssociation
     */
    @TestVisible
    private static SObjectContactAssociation__c createNew(
            Id contactId,
            String sObjectApiName,
            List<Id> associatedIds
    ) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        SObjectContactAssociation__c association =
            (SObjectContactAssociation__c) sObjectContactAssociationCreator.createNewRecord();
        sObjectContactAssociationCreator.populateFields(
            association,
            new Map<Schema.SObjectField, Object> {
                SObjectContactAssociation__c.Contact__c => contactId,
                SObjectContactAssociation__c.SObjectApiName__c => sObjectApiName,
                SObjectContactAssociation__c.AssociatedIds__c =>
                    String.join(associatedIds, ','),
                SObjectContactAssociation__c.NumberOfRecords__c => associatedIds.size()
            }
        );
        return association;
    }

    /**
     * Create a new SObjectContactAssociation with a non default instance
     */
    @TestVisible
    private static SObjectContactAssociation__c createNew(
            Id contactId,
            String sObjectApiName,
            List<Id> associatedIds,
            Integer instance
    ) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        SObjectContactAssociation__c association =
            createNew(contactId, sObjectApiName, associatedIds);
        sObjectContactAssociationCreator.populateFields(
            association,
            new Map<Schema.SObjectField, Object> {
                SObjectContactAssociation__c.Instance__c => instance
            }
        );
        return association;
    }

    /**
     * Remove ids for a given object
     */
    public static void removeIds(Id contactId, String sObjectApiName, List<String> idsToRemove) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        SObjectContactAssociationSelector selector = new SObjectContactAssociationSelector();
        List<SObjectContactAssociation__c> associations =
            selector.getAllForContactAndObject(
                contactId,
                new List<String>{sObjectApiName}
            );
        Set<String> foundIds = new Set<String>();
        for (SObjectContactAssociation__c association : associations) {
            foundIds.addAll(association.AssociatedIds__c.split(','));
        }
        foundIds.removeAll(idsToRemove);
        List<String> remainingIdString = new List<String>();
        remainingIdString.addAll(foundIds);
        updateAssignations(contactId, sObjectApiName, C.convertListToId(remainingIdString));
    }

    /**
     * Remove all the associations for a given list of objects for a given contact
     */
    public static void removeAllObjects(
            Id contactId,
            List<String> sObjectApiNames
    ) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        SObjectContactAssociationSelector selector = new SObjectContactAssociationSelector();
        sObjectContactAssociationCreator.checkObjectDeletable();
        delete selector.getAllForContactAndObject(contactId, sObjectApiNames);
    }

    /**
     * Update the assignations for a contact and object to keep the given ids
     */
    public static void updateAssignations(
            Id contactId,
            String sObjectApiName,
            List<String> associatedIds
    ) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();

        List<SObjectContactAssociation__c> newAssociations =
            new List<SObjectContactAssociation__c>();
        SObjectContactAssociationSelector selector =
            new SObjectContactAssociationSelector();
        List<SObjectContactAssociation__c> oldAssociations =
            selector.getAllForContactAndObject(
                contactId,
                new List<String>{sObjectApiName}
            );

        if (associatedIds.size() < MAX_LENGTH_OF_ASSOCIATE_IDS) {
            newAssociations.add(oldAssociations.remove(0));
            sObjectContactAssociationCreator.populateFields(
                newAssociations[0],
                new Map<Schema.SObjectField, Object> {
                    SObjectContactAssociation__c.AssociatedIds__c =>
                        String.join(associatedIds, ','),
                    SObjectContactAssociation__c.NumberOfRecords__c =>
                        associatedIds.size()
                }
            );
        } else {
            newAssociations = associateMultipleInstances(
                contactId,
                sObjectApiName,
                associatedIds,
                oldAssociations
            );
        }
        sObjectContactAssociationCreator.checkObjectUpdateable();
        upsert newAssociations;
        if (!oldAssociations.isEmpty()) {
            sObjectContactAssociationCreator.checkObjectDeletable();
            delete oldAssociations;
        }
    }

    /**
     * Associate the given ids to multiple instances.
     * The instances may already exists or not
     */
    private static List<SObjectContactAssociation__c> associateMultipleInstances(
            Id contactId,
            String sObjectApiName,
            List<String> associatedIds,
            List<SObjectContactAssociation__c> oldAssociations
    ) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        List<SObjectContactAssociation__c> newAssociations =
                new List<SObjectContactAssociation__c>();
        Integer numberOfAssociatedIds = associatedIds.size();
        Integer associatedIdsIndex = 0;
        Integer instance = 1;
        List<Id> idsToAdd = new List<Id>();

        while (associatedIdsIndex < numberOfAssociatedIds) {
            idsToAdd.clear();
            idsToAdd.addAll(C.convertListToId(C.getListSubset(
                associatedIdsIndex,
                MAX_LENGTH_OF_ASSOCIATE_IDS * instance,
                associatedIds
            )));

            SObjectContactAssociation__c currentAssociation;
            if (oldAssociations.isEmpty()) {
                currentAssociation = createNew(
                    contactId,
                    sObjectApiName,
                    idsToAdd,
                    instance
                );
            } else {
                currentAssociation = oldAssociations.remove(0);
                sObjectContactAssociationCreator.populateFields(
                    currentAssociation,
                    new Map<Schema.SObjectField, Object> {
                        SObjectContactAssociation__c.AssociatedIds__c => String.join(idsToAdd, ','),
                        SObjectContactAssociation__c.Instance__c => instance,
                        SObjectContactAssociation__c.NumberOfRecords__c => idsToAdd.size()
                    }
                );
            }
            newAssociations.add(currentAssociation);
            associatedIdsIndex += MAX_LENGTH_OF_ASSOCIATE_IDS;
            instance++;
        }

        return newAssociations;
    }

    /**
     * Get the associated ids for the given contact and object joined in a string
     */
    public static String getAllAssignedIdsForContactAndObject(
            Id contactId,
            String sObjectApiName
    ) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        String associatedIds = '';
        SObjectContactAssociationSelector selector = new SObjectContactAssociationSelector();
        List<SObjectContactAssociation__c> associations =
            selector.getAllForContactAndObject(
                contactId,
                new List<String>{sObjectApiName}
            );

        for (SObjectContactAssociation__c association : associations) {
            associatedIds += association.AssociatedIds__c + ',';
        }
        return associatedIds;
    }

    /**
     * Unassign all the records for the given contact and object
     */
    public static void unassignAllForContactAndObject(
            Id contactId,
            String sObjectApiName
    ) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        sObjectContactAssociationCreator.checkObjectDeletable();
        SObjectContactAssociationSelector selector = new SObjectContactAssociationSelector();
        delete selector.getAllForContactAndObject(
            contactId,
            new List<String>{sObjectApiName}
        );
    }

    /**
     * Get a Map with the ObjectApiName as the key of all the.
     * Escapes single quotes in the single quotes that may be in the id string
     * to make it DB safe
     */
    public static Map<String, Set<String>> getMapOfIdsForContact(Id contactId) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        Map<String, Set<String>> objectToIdMap = new Map<String, Set<String>>();
        SObjectContactAssociationSelector selector = new SObjectContactAssociationSelector();
        List<SObjectContactAssociation__c> associations =
            selector.getAllForContact(contactId);
        String objectName = '';
        Set<String> foundIds = new Set<String>();
        for (SObjectContactAssociation__c association : associations) {
            if (!objectName.equals(association.SObjectApiName__c)) {
                objectToIdMap.put(objectName, foundIds.clone());
                foundIds.clear();
                objectName = association.SObjectApiName__c;
            }
            foundIds.addAll(
                String.escapeSingleQuotes(
                    association.AssociatedIds__c
                ).split(',')
            );
        }
        objectToIdMap.put(objectName, foundIds.clone());
        objectToIdMap.remove('');
        return objectToIdMap;
    }

    /**
     * Get the number of associations for an object and removes all invalid associations
     */
    public static Map<String, Decimal> getNumberOfRecordsPerValidObject(Id contactId) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        sObjectContactAssociationCreator.checkObjectDeletable();
        SObjectContactAssociationSelector selector = new SObjectContactAssociationSelector();
        return getNumberOfRecordsPerObject(
            deleteInvalidAssociations(
                selector.getAllForContact(contactId)
            )
        );
    }

    /**
    * Get the number of associations adding all the instances per Object
    *
    * @param assignedRecords List of the assigned records to count all the instances
    * @return Map of object name as key and the total number of associations as value
    */
    private static Map<String, Decimal> getNumberOfRecordsPerObject(
            List<SObjectContactAssociation__c> assignedRecords
    ) {
        Map <String, Decimal> recordsPerObject = new Map<String, Decimal>();

        for (SObjectContactAssociation__c assignedRecord : assignedRecords) {
            if (recordsPerObject.get(assignedRecord.SObjectApiName__c) == null) {
                recordsPerObject.put(
                    assignedRecord.SObjectApiName__c,
                    assignedRecord.NumberOfRecords__c
                );
            } else {
                recordsPerObject.put(
                    assignedRecord.SObjectApiName__c,
                    recordsPerObject.get(assignedRecord.SObjectApiName__c)
                        + assignedRecord.NumberOfRecords__c
                );
            }
        }
        return recordsPerObject;
    }

    /**
     * Deletes any associations that belong to a deleted object
     *
     * @return - The SObjectContactAssociation__c that are still valid
     */
    @TestVisible
    private static List<SObjectContactAssociation__c> deleteInvalidAssociations(
            List<SObjectContactAssociation__c> associationsToValidate
    ) {

        List<SObjectContactAssociation__c> associationsToDelete =
            new List<SObjectContactAssociation__c>();
        List<SObjectContactAssociation__c> validAssociations =
            new List<SObjectContactAssociation__c>();
        for (SObjectContactAssociation__c association : associationsToValidate) {
            if (!DescribeHandler.objectExists(association.SObjectApiName__c)) {
                associationsToDelete.add(association);
            } else {
                validAssociations.add(association);
            }
        }
        if (!associationsToDelete.isEmpty()) {
            GenericObjectCreator sObjectContactAssociationCreator =
                new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
            sObjectContactAssociationCreator.checkObjectDeletable();
            delete associationsToDelete;
       }
       return validAssociations;
    }

    /**
     * Delete a list of assignments
     */
    public static void deleteAssignments(List<SObjectContactAssociation__c> assignations) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        sObjectContactAssociationCreator.checkObjectDeletable();
        delete assignations;
    }

    /**
     * Build a set with the object API name of the objects already assigned with a contact
     */
    public static Set<String> getAssignedObjectsForContact(Id contactId) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        Set<String> assignedObjects = new Set<String>();
        SObjectContactAssociationSelector selector =
            new SObjectContactAssociationSelector();
        for (SObjectContactAssociation__c association :
                selector.getAllForContact(contactId)
        ) {
            assignedObjects.add(association.SObjectApiName__c);
        }
        return assignedObjects;
    }

    /**
     * Set the unique key for each record in the domain
     */
    public void setUniqueKeys(List<SObjectContactAssociation__c> associations) {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        sObjectContactAssociationCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SObjectContactAssociation__c.UniqueKey__c
            }
        );
        for (
                SObjectContactAssociation__c association :
                    (List<SObjectContactAssociation__c>) records
        ) {
            sObjectContactAssociationCreator.populateFields(
                association,
                new Map<Schema.SObjectField, Object> {
                    SObjectContactAssociation__c.UniqueKey__c =>
                        createUniqueKey(association)
                }
            );
        }
    }

    /**
     * Create a string that should identify this record as unique
     */
    @TestVisible
    private String createUniqueKey(SObjectContactAssociation__c association) {
        return
            association.Contact__c + '_' +
            association.Instance__c + '_' +
            association.SObjectApiName__c;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public SObjectContactAssociationDO constructWithRecords(List<SObject> sObjectList) {
            return new SObjectContactAssociationDO(sObjectList);
        }
        public SObjectContactAssociationDO constructEmpty() {
            return new SObjectContactAssociationDO();
        }
    }
}