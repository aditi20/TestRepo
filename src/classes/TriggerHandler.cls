/**
 * Base class for TriggerHandling. Each Object that needs a Trigger should have a class that
 * extends this one and augments the methods in this class as and when they are needed.
 * This class is part of the Domain layer and therefore throws DomainExceptions
 *
 * Deals with:
 *    TriggerHandling
 *    Data defaults
 *    Data validation
 *    Access Permissions
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * Based on Separation of Concerns concept from Andrew Fawcett so including his copyright banner
 * Copyright (c) 2012, FinancialForce.com, inc
 * All rights reserved.
 */
public virtual with sharing class TriggerHandler {


    // Used just for testing purposes. Allows mock DB for none DML tests and holds error messages
    // to ensure correct trigger handling.
    public static TestFrameWork tests { get; private set; }

    static {
        tests = new TestFrameWork();
    }

    // The SObjectDomain that the trigger will work with
    public SObjectDomain domain;

    /**
     * 0 param constructor
     */
    public TriggerHandler() {}

    public static void triggerHandler(Type domainClass) {

        // Create the Trigger Handler and the domain from the domainClass. This keeps the classes
        // linked so the domain and the trigger handler are for the same object
        String domainClassName = domainClass.getName();
        String namespace = C.getNamespace();
        namespace = (namespace == null) ? '' : namespace;
        String triggerClassName = getTriggerClassName(domainClassName);
        SObjectDomain.IDomainConstructor constructor = getConstructor(
            domainClassName,
            namespace
        );
        SObjectDomain domain = constructor.constructEmpty();
        TriggerHandler triggerHandler = getTriggerHandler(triggerClassName, namespace);
        triggerHandler.domain = domain;

        if (System.Test.isRunningTest() && tests.mockDatabase.hasRecords()) {
            tests.mockDatabase.testTriggerHandler(triggerHandler);
        } else {
            triggerHandler(
                Trigger.new,
                Trigger.oldMap,
                Trigger.isBefore,
                Trigger.isAfter,
                Trigger.isInsert,
                Trigger.isUpdate,
                Trigger.isDelete,
                triggerHandler
            );
        }
    }

    /**
     * The following three methods are needed for backwards compatibility with our old nomenclature
     * Where Domain classes have a DO suffix and Trigger handling classes had TriggerLogic suffix
     * but didn't have the DO in the name
     */
    @TestVisible
    private static String getTriggerClassName(String domainClassName) {

        if (domainClassName.endsWithIgnoreCase('DO')) {
            domainClassName = domainClassName.subString(0, domainClassName.length() - 2);
        } else if (domainClassName.endsWithIgnoreCase('Domain')) {
            domainClassName = domainClassName.subString(0, domainClassName.length() - 6);
        }
        return domainClassName;
    }

    @TestVisible
    private static SObjectDomain.IDomainConstructor getConstructor(
            String domainClassName,
            String namespace
    ) {
        try {
            return loadConstructor(domainClassName, namespace);
        } catch (NullPointerException npe) {
            throw new TriggerHandlerException(
                System.Label.DOMAIN_CLASS_ERR_MSG,
                new List<String>{domainClassName}
            );
        }
    }

    private static SObjectDomain.IDomainConstructor loadConstructor(
            String domainClassName,
            String namespace
    ) {

        Type domainConstructorClass = Type.forName(
            namespace,
            domainClassName + '.Constructor'
        );
        return (SObjectDomain.IDomainConstructor) domainConstructorClass.newInstance();
    }

    @TestVisible
    private static TriggerHandler getTriggerHandler(
            String domainClassName,
            String namespace
    ) {
        try {
            return loadTriggerHandler(domainClassName, namespace);
        } catch (NullPointerException npe) {
            throw new TriggerHandlerException(
                System.Label.TRIGGER_CLASS_ERR_MSG,
                new List<String>{domainClassName}
            );
        }
    }

    private static TriggerHandler loadTriggerHandler(
            String domainClassName,
            String namespace
    ) {
        Type triggerClass = Type.forName(
            namespace,
            domainClassName + 'TH'
        );
        if (triggerClass == null) {
            triggerClass = Type.forName(
                namespace,
                domainClassName + 'TriggerLogic'
            );
        }
        return (TriggerHandler) triggerClass.newInstance();
    }

    private static void triggerHandler(
            List<sObject> newRecords,
            Map<Id, sObject> oldMap,
            Boolean isBefore,
            Boolean isAfter,
            Boolean isInsert,
            Boolean isUpdate,
            Boolean isDelete,
            TriggerHandler triggerHandler
    ) {

        if (isBefore) {
            handleBefore(
                newRecords,
                oldMap,
                isInsert,
                isUpdate,
                isDelete,
                triggerHandler
            );
        } else {
            handleAfter(
                newRecords,
                oldMap,
                isInsert,
                isUpdate,
                isDelete,
                triggerHandler
            );
        }
    }

    private static void handleBefore(
            List<sObject> newRecords,
            Map<Id, sObject> oldMap,
            Boolean isInsert,
            Boolean isUpdate,
            Boolean isDelete,
            TriggerHandler triggerHandler
    ) {

        if (isInsert) {
            triggerHandler.addRecords(newRecords);
            triggerHandler.handleBeforeInsert();
        } else if (isUpdate) {
            triggerHandler.addRecords(newRecords);
            triggerHandler.handleBeforeUpdate(oldMap);
        } else if (isDelete) {
            triggerHandler.addRecords(oldMap.values());
            triggerHandler.handleBeforeDelete();
        }
    }

    private static void handleAfter(
            List<sObject> newRecords,
            Map<Id, sObject> oldMap,
            Boolean isInsert,
            Boolean isUpdate,
            Boolean isDelete,
            TriggerHandler triggerHandler
    ) {

        if (isInsert) {
            triggerHandler.addRecords(newRecords);
            triggerHandler.handleAfterInsert();
        } else if (isUpdate) {
            triggerHandler.addRecords(newRecords);
            triggerHandler.handleAfterUpdate(oldMap);
        } else if (isDelete) {
            triggerHandler.addRecords(oldMap.values());
            triggerHandler.handleAfterDelete();
        }
    }

    public virtual void applyDefaults() {}
    public virtual void validateBefore() {}
    public virtual void validateBefore(Map<Id, sObject> oldMap) {}
    public virtual void validate() {}
    public virtual void validate(Map<Id, sObject> oldMap) {}
    public virtual void onBeforeInsert() {}
    public virtual void onBeforeUpdate(Map<Id, sObject> oldMap) {}
    public virtual void onBeforeDelete() {}
    public virtual void onAfterInsert() {}
    public virtual void onAfterUpdate(Map<Id, sObject> oldMap) {}
    public virtual void onAfterDelete() {}

    public void handleBeforeInsert() {
        applyDefaults();
        validateBefore();
        onBeforeInsert();
    }

    public void handleBeforeUpdate(Map<Id, sObject> oldMap) {
        validateBefore();
        validateBefore(oldMap);
        onBeforeUpdate(oldMap);
    }

    public void handleBeforeDelete() {
        onBeforeDelete();
    }

    public void handleAfterInsert() {
        if (!this.domain.sObjectDescribe.isCreateable()) {
            throw new SObjectDomain.DomainException(
                System.Label.INSERT_DENIED,
                new List<String>{this.domain.sObjectName}
            );
        }
        validate();
        onAfterInsert();
    }

    public void handleAfterUpdate(Map<Id, sObject> oldMap) {
        if (!this.domain.sObjectDescribe.isUpdateable()) {
            throw new SObjectDomain.DomainException(
                System.Label.UPDATE_DENIED,
                new List<String>{this.domain.sObjectName}
            );
        }
        validate();
        validate(oldMap);
        onAfterUpdate(oldMap);
    }

    public void handleAfterDelete() {
        if (!this.domain.sObjectDescribe.isDeletable()) {
            throw new SObjectDomain.DomainException(
                System.Label.DELETE_DENIED,
                new List<String>{this.domain.sObjectName}
            );
        }
        onAfterDelete();
    }

    /**
     * Return the records that are stored in the domain.
     * Helper method for code clarity
     */
    public List<SObject> getRecords() {
        return this.domain.records;
    }

    public void addRecords(List<SObject> records) {
        this.domain.addRecords(records);
    }

    public class TriggerHandlerException extends BaseException {
        public TriggerHandlerException(String message, String[] args) {
            super(message, args);
        }
    }

    // Classes below are for testing purposes only. They are here and not in a test class
    // as it is not possible to instantiate a TestClass from inside none test code as is required
    // in the trigger handling
    /**
     * Class to hold MockDatabase and the Errors that allow for ease of testing
     */
    public class TestFrameWork {

        public MockDatabase mockDatabase { get; private set; }
        public ErrorFactory errorFactory { get; private set; }

        public TestFrameWork() {
            this.mockDatabase = new MockDatabase();
            this.errorFactory = new ErrorFactory();
        }
    }

    /**
     * Mock Database to allow for testing without DML being required
     */
    public class MockDatabase {

        private Boolean isInsert;
        private Boolean isUpdate;
        private Boolean isDelete;
        private Boolean isBefore;
        public List<SObject> newRecords;
        private Map<Id, SObject> oldRecords;

        private Boolean blockInsert;

        public MockDatabase() {
            this.isBefore = true;
            this.newRecords = new List<SObject>();
            this.oldRecords = new Map<Id, SObject>();
        }

        public void testTriggerHandler(TriggerHandler testTriggerHandler) {
            TriggerHandler.triggerHandler(
                newRecords,
                oldRecords,
                isBefore,
                !isBefore,
                isInsert,
                isUpdate,
                isDelete,
                testTriggerHandler
            );
        }

        public void onInsert(List<SObject> records) {
            this.isInsert = true;
            this.isUpdate = false;
            this.isBefore = false;
            this.newRecords = records;
        }

        public void onUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
            this.isInsert = false;
            this.isUpdate = true;
            this.isDelete = false;
            this.newRecords = newRecords;
            this.oldRecords = oldRecords;
        }

        public void onDelete(Map<Id, SObject> oldRecords) {
            this.isInsert = false;
            this.isUpdate = false;
            this.isDelete = true;
            this.oldRecords = oldRecords;
        }

        public void setIsBefore(Boolean value) {
            this.isBefore = value;
        }

        public Boolean hasRecords() {
            return (!newRecords.isEmpty() || !oldRecords.isEmpty());
        }
    }

    public class ErrorFactory {
        public List<Error> errors;

        public ErrorFactory() {
            this.errors = new List<Error>();
        }

        public Boolean hasErrors() {
            return !this.errors.isEmpty();
        }

        public void logError(String message, SObject record) {
            RecordError error = new RecordError(record);
            error.errorMessage = message;
            this.errors.add(error);
        }

        public void logError(String message, SObject record, SObjectField field) {
            FieldError error = new FieldError(record, field);
            error.errorMessage = message;
            this.errors.add(error);
        }
    }

    public abstract class Error {
        public String errorMessage;
    }

    public virtual class RecordError extends Error {
        public SObject record;

        public RecordError(SObject record) {
            this.record = record;
        }
    }

    public class FieldError extends RecordError {
        public SObjectField field;

        public FieldError(SObject record, SObjectField field) {
            super(record);
            this.field = field;
        }
    }
}
