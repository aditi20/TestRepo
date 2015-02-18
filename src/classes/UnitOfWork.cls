/**
 * Unit of work implementation.
 * TODO:
 *      - Check for the same object being added twice (check by id)
 *      - Allow for partial insert and processing of
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * Based on Separation of Concerns concept from Andrew Fawcett so including his copyright banner
 * Copyright (c) 2012, FinancialForce.com, inc
 * All rights reserved.
 *
 * @author - Owen Davies (odavies@grameenfoundation.org)
 */
public with sharing class UnitOfWork {

    private Savepoint masterSavePoint;
    private Boolean overrideRollback;

    @TestVisible
    private List<String> insertionOrder;

    @TestVisible
    private Map<String, Integer> numberOfLevelsInInsertionOrder;

    private List<String> updateOrder;
    private Map<String, Integer> numberOfLevelsInUpdateOrder;

    private Map<String, List<SObject>> recordsToInsert;
    private Map<String, List<SObject>> recordsToUpdate;
    private Map<String, List<SObject>> recordsToDelete;
    private Map<String, Relationships> relationships;


    // String constants used in this class
    private static final String SPLITTER = '_#@#_';

    public UnitOfWork() {
        reset();
    }

    public UnitOfWork(Boolean overrideRollback) {
        this();
        this.overrideRollback = overrideRollback;
    }

    public UnitOfWork(List<Schema.SObjectType> insertionOrder) {
        this();
        for (Schema.SObjectType objectType : insertionOrder) {
            addToInsertionOrder(objectType);
        }
    }

    public UnitOfWork(List<String> insertionOrder) {
        this();
        for (String objectName : insertionOrder) {
            addToInsertionOrder(objectName);
        }
    }

    public UnitOfWork(List<Schema.SObjectType> insertionOrder, Boolean overrideRollback) {
        this();
        for (Schema.SObjectType objectType : insertionOrder) {
            addToInsertionOrder(objectType);
        }
    }

    public void setMasterSavePoint(Savepoint sp) {
        if (this.masterSavePoint == null) {
            this.masterSavePoint = sp;
        }
    }

    public void setDefaultMasterSavePoint() {
        this.setMasterSavePoint(Database.setSavePoint());
    }

    public void rollbackToMaster() {
        if (this.masterSavePoint != null && !this.overrideRollback) {
            Database.rollback(this.masterSavePoint);
        }
    }

    public void setOverrideRollbackToMaster(Boolean value) {
        this.overrideRollback = value;
    }

    public void reset() {
        this.insertionOrder = new List<String>();
        this.updateOrder = new List<String>();
        this.numberOfLevelsInInsertionOrder = new Map<String, Integer>();
        this.numberOfLevelsInUpdateOrder = new Map<String, Integer>();
        this.recordsToInsert = new Map<String, List<SObject>>();
        this.recordsToUpdate = new Map<String, List<SObject>>();
        this.recordsToDelete = new Map<String, List<SObject>>();
        this.relationships = new Map<String, Relationships>();
        this.overrideRollback = false;
    }

    public void addToInsertionOrder(List<Schema.SObjectType> objectList) {
        for (Schema.SObjectType objectType : objectList) {
            addToInsertionOrder(objectType.getDescribe().getName());
        }
    }

    public Integer addToInsertionOrder(Schema.SObjectType objectType) {
        return addToInsertionOrder(objectType.getDescribe().getName());
    }

    /**
     * Callilng without a specified level will assume that you wish to start a new level.
     */
    public Integer addToInsertionOrder(String objectName) {
        Integer numberOfTimesEntered = numberOfLevelsInInsertionOrder.get(objectName);
        numberOfTimesEntered = (numberOfTimesEntered == null) ? 0 : numberOfTimesEntered;
        numberOfTimesEntered = numberOfTimesEntered + 1;
        return addToInsertionOrder(objectName, numberOfTimesEntered);
    }

    /**
     * Specify the level to insert the record at that level. Use to add to an existing
     * level. Will create the new level if the specified one doesn't exist
     */
    public Integer addToInsertionOrder(Schema.SObjectType objectType, Integer level) {
        return addToInsertionOrder(objectType.getDescribe().getName(), level);
    }

    public Integer addToInsertionOrder(String objectName, Integer level) {
        if (
                numberOfLevelsInInsertionOrder.get(objectName) == null ||
                numberOfLevelsInInsertionOrder.get(objectName) < level
        ) {
            numberOfLevelsInInsertionOrder.put(objectName, level);
            String key = generateKey(objectName, level);
            this.insertionOrder.add(key);
            this.recordsToInsert.put(key, new List<SObject>());
            this.relationships.put(key, new Relationships());
        }
        return level;
    }

    /**
     * Same concept as adding to insert order
     */
    public void addToUpdateOrder(List<Schema.SObjectType> objectList) {
        for (Schema.SObjectType objectType : objectList) {
            addToUpdateOrder(objectType.getDescribe().getName());
        }
    }

    public Integer addToUpdateOrder(Schema.SObjectType objectType) {
        return addToUpdateOrder(objectType.getDescribe().getName());
    }

    public Integer addToUpdateOrder(String objectName) {
        Integer numberOfTimesEntered = numberOfLevelsInUpdateOrder.get(objectName);
        numberOfTimesEntered = (numberOfTimesEntered == null) ? 0 : numberOfTimesEntered;
        numberOfTimesEntered = numberOfTimesEntered + 1;
        return addToUpdateOrder(objectName, numberOfTimesEntered);
    }

    public Integer addToUpdateOrder(Schema.SObjectType objectType, Integer level) {
        return addToUpdateOrder(objectType.getDescribe().getName(), level);
    }

    public Integer addToUpdateOrder(String objectName, Integer level) {
        if (
                numberOfLevelsInUpdateOrder.get(objectName) == null ||
                numberOfLevelsInUpdateOrder.get(objectName) < level
        ) {
            numberOfLevelsInUpdateOrder.put(objectName, level);
            String key = generateKey(objectName, level);
            this.updateOrder.add(key);
            this.recordsToUpdate.put(key, new List<SObject>());
        }
        return level;
    }

    /**
     * Add a record to the insert list. If not specifying a level then assume the first
     */
    public void addToInsertList(SObject record) {
        addToInsertList(record, 1);
    }

    public void addToInsertList(SObject record, Integer level) {
        addToInsertList(record, null, null, level);
    }

    public void addToInsertList(
            SObject record,
            Schema.SObjectField parentField,
            SObject parentRecord
    ) {
        addToInsertList(record, parentField, parentRecord, 1);
    }

    /**
     * Add to insert list with a relationship. Pass null for parentField and parentRecord
     * to not add a relationship
     */
    public void addToInsertList(
            SObject record,
            Schema.SObjectField parentField,
            SObject parentRecord,
            Integer level
    ) {

        validateInsert(record, level);
        String objectName = record.getSObjectType().getDescribe().getName();
        String key = generateKey(objectName, level);
        if (parentField != null && parentRecord != null) {
            createRelationship(record, parentField, parentRecord, key);
        }
        this.recordsToInsert.get(key).add(record);
    }

    /**
     * Same concept as adding to Insert List
     */
    public void addToUpdateList(SObject record) {
        addToUpdateList(record, 1);
    }

    public void addToUpdateList(SObject record, Integer level) {
        validateUpdate(record, level);
        String objectName = record.getSObjectType().getDescribe().getName();
        String key = generateKey(objectName, level);
        this.recordsToUpdate.get(key).add(record);
    }

    /**
     * Create a relationship for a child record that is in the insertion list
     * at the given level
     */
    public void createRelationship(
            SObject record,
            Schema.SObjectField parentField,
            SObject parentRecord,
            Integer level
    ) {
        String objectName = record.getSObjectType().getDescribe().getName();
        String key = generateKey(objectName, level);
        createRelationship(record, parentField, parentRecord, key);
    }

    public void createRelationship(
            SObject record,
            Schema.SObjectField parentField,
            SObject parentRecord,
            String key
    ) {
        if (parentField != null && parentRecord != null) {
            this.relationships.get(key).addRelationship(
                record,
                parentField,
                parentRecord
            );
        }
    }

    /**
     * Save the records. Will check CRUD access and resolve all relationships
     * TODO - Implement Delete, Upsert, use of DBFullAccess and return SaveResult
     */
    public void commitWork() {
        this.setDefaultMasterSavePoint();
        try {

            // Insert by type
            for (String key : this.insertionOrder) {
                checkCreationPermission(key);
                this.relationships.get(key).resolveAllRelationships();
                insert this.recordsToInsert.get(key);
            }

            // Update by type
            for (String key : this.updateOrder) {
                checkUpdatePermission(key);
                update this.recordsToUpdate.get(key);
            }

            // Delete by type

        } catch (Exception e) {
            this.rollbackToMaster();
            throw e;
        }
    }

    public String generateKey(String objectName, Integer level) {
        return objectName + SPLITTER + level;
    }

    private List<String> breakDownKey(String key) {
        return key.split(SPLITTER);
    }

    public List<SObject> getAllInsertedRecords() {

        List<SObject> insertedObjects = new List<SObject>();
        for (String key : this.insertionOrder) {
            insertedObjects.addAll(this.recordsToInsert.get(key));
        }
        return insertedObjects;
    }

    private void validateInsert(SObject record, Integer level) {

        String objectName = record.getSObjectType().getDescribe().getName();
        if (record.Id != null) {
            throw new UnitOfWorkException(System.Label.ONLY_NEW_RECORDS_INSERTED);
        }
        if (!this.recordsToInsert.containsKey(generateKey(objectName, level))) {
            throw new UnitOfWorkException(
                System.Label.OBJECT_NOT_SUPPORTED,
                new List<String>{objectName, String.valueOf(level)}
            );
        }
    }

    private void checkCreationPermission(String key) {

        String objectName = breakDownKey(key)[0];
        GenericObjectCreator creator = new GenericObjectCreator(objectName);
        creator.checkObjectCreateable();
    }

    private void validateUpdate(SObject record, Integer level) {

        String objectName = record.getSObjectType().getDescribe().getName();
        if (record.Id == null) {
            throw new UnitOfWorkException(System.Label.UPDATE_RECORD_MUST_HAVE_ID);
        }
        if (!this.recordsToUpdate.containsKey(generateKey(objectName, level))) {
            throw new UnitOfWorkException(
                System.Label.OBJECT_NOT_SUPPORTED,
                new List<String>{objectName, String.valueOf(level)}
            );
        }
    }

    private void checkUpdatePermission(String key) {

        String objectName = breakDownKey(key)[0];
        GenericObjectCreator creator = new GenericObjectCreator(objectName);
        creator.checkObjectUpdateable();
    }

    /**
     * Class to hold all the Relationships at a given level
     */
    private Class Relationships {

        private List<Relationship> relationships;

        public Relationships() {
            this.relationships = new List<Relationship>();
        }

        public void addRelationship(
                SObject record,
                Schema.SObjectField relationField,
                SObject parentRecord
        ) {
            this.relationships.add(
                new Relationship(record, relationField, parentRecord)
            );
        }

        public void resolveAllRelationships() {
            for (Relationship relationship : relationships) {
                relationship.resolveRelationship();
            }
        }
    }

    /**
     * Represents and individual relationship between a parent and a child
     */
    @TestVisible
    private Class Relationship {

        private SObject record;
        private Schema.SObjectField relationField;
        private SObject parentRecord;

        public Relationship(
                SObject record,
                Schema.SObjectField relationField,
                SObject parentRecord
        ) {
            this.record = record;
            this.relationField = relationField;
            this.parentRecord = parentRecord;
        }

        public void resolveRelationship() {
            validateRelationship();
            this.record.put(this.relationField, this.parentRecord.Id);
        }

        private void validateRelationship() {
            String objectName = record.getSObjectType().getDescribe().getName();
            String fieldName = relationField.getDescribe().getName();
            if (this.parentRecord.Id == null) {
                throw new UnitOfWorkException(
                    System.Label.PARENT_RECORD_REQUIRES_ID,
                    new List<String>{fieldName, objectName}
                );
            }
            if (!DescribeHandler.fieldExists(objectName, fieldName)) {
                throw new UnitOfWorkException(
                    System.Label.RELATIONSHIP_FIELD_INVALID,
                    new List<String>{fieldName, objectName}
                );
            }
        }
    }

    /**
     * Exception class for the UnitOfWork
     */
    public class UnitOfWorkException extends BaseException {
        public UnitOfWorkException(String message, String[] args) {
            super(message, args);
        }
    }
}