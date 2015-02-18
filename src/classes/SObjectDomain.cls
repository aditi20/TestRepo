/**
 * Base class for the DomainLayer of the application
 * Domain base class to deal with generic data handling. Each standard and custom sObject should
 * have a class that extends this class.
 * The extending classes deal with Object Specific logic by fleshing out and adding to
 * the methods in this class.
 * Business logic that deals with multiple objects should be in the service layer
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * Based on Separation of Concerns concept from Andrew Fawcett so including his copyright banner
 * Copyright (c) 2012, FinancialForce.com, inc
 * All rights reserved.
 */
public virtual with sharing class SObjectDomain {

    public List<SObject> records { get; private set; }

    public String sObjectName { get; private set; }

    public Schema.SObjectType objectType { get; private set; }

    public Schema.DescribeSObjectResult sObjectDescribe { get; private set; }

    public Map<String, Schema.SObjectField> sObjectFieldMap {get; private set;}

    public GenericObjectCreator genericObjectCreator {get; private set;}

    public SObjectDomain() {}

    public SObjectDomain(Schema.SObjectType objectType) {
        this.objectType = objectType;
        this.sObjectDescribe = objectType.getDescribe();
        this.sObjectName = sObjectDescribe.getName();
        this.sObjectFieldMap = sObjectDescribe.fields.getMap();
        DescribeHandler.getObjectDescribeResult(this.sObjectName, true);
        this.records = new List<SObject>();
        this.genericObjectCreator = new GenericObjectCreator(objectType);
    }

    public SObjectDomain(List<SObject> sObjectList) {
        this(sObjectList.getSObjectType());
        this.records = sObjectList.clone();
    }

    /**
     * Add a new record to the Domain
     */
    public void addRecord(SObject record) {
        if (record.getSObjectType() == this.objectType) {
            this.records.add(record);
        } else {
            throw new DomainException();
        }
    }

    /**
     * Add multiple records to the domain
     */
    public void addRecords(List<SObject> records) {
        if (records.getSObjectType() == this.objectType) {
            this.records.addAll(records);
        } else {
            throw new DomainException();
        }
    }

    /**
     * Insert records
     * DO NOT USE THE DML METHODS HERE IN THE FUTURE. USE THE UoW
     */
    public void insertRecords() {
        genericObjectCreator.checkObjectCreateable();
        insert records;
    }

	/**
     * Insert records.
     * TODO: RETURNING THE SAVERESULT NEEDS TO BE ADDED TO UoW
     */
    public List<Database.SaveResult> insertRecords(Boolean insertNoneOnError) {
        genericObjectCreator.checkObjectCreateable();
        return Database.insert(records, insertNoneOnError);
    }

    /**
     * Update records
     */
    public void updateRecords() {
        genericObjectCreator.checkObjectUpdateable();
        update records;
    }

    /**
     * Upsert records with database full access
     */
    public void upsertRecordsDbFullAccess() {
        DBFullAccess.upsertSObject(records);
    }

    /**
     * Delete records
     */
    public List<Database.SaveResult> updateRecords(Boolean updateNoneOnError) {
        genericObjectCreator.checkObjectUpdateable();
        return Database.update(records, updateNoneOnError);
    }

    /**
     * Upsert records
     */
    public void upsertRecords() {
        genericObjectCreator.checkObjectCreateable();
        genericObjectCreator.checkObjectUpdateable();
        upsert records;
    }

    /**
     * Delete records
     */
    public void deleteRecords() {
        genericObjectCreator.checkObjectDeletable();
        delete records;
    }

    /**
     * Delete records with database full access
     */
    public void deleteRecordsDbFullAccess() {
        DBFullAccess.deleteSObject(records);
    }

    /**
     * Get all of the values for a given field
     */
    public List<String> getValues(Schema.SObjectField field) {
        // TODO - Use the describe handler and expand to use dynamic data types based on field
        // passed in
        List<String> foundValues = new List<String>();
        for (SObject obj : this.records) {
            foundValues.add(String.valueOf(obj.get(field.getDescribe().getName())));
        }
        return foundValues;
    }

    /**
     * Interface to construct an instance of the domain
     */
    public interface IDomainConstructor {
        SObjectDomain constructWithRecords(List<sObject> sObjectList);
        SObjectDomain constructEmpty();
    }

    public class DomainException extends BaseException {
        public DomainException(String message, String[] args) {
            super(message, args);
        }
    }
}
