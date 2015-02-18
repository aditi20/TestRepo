/**
 * Domain class for the Application Version object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class ApplicationVersionDomain extends SObjectDomain {
    public ApplicationVersionDomain() {
        super(ApplicationVersion__c.SObjectType);
    }

    public ApplicationVersionDomain(List<ApplicationVersion__c> sObjects) {
        super(sObjects);
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public ApplicationVersionDomain constructWithRecords(List<SObject> sObjectList) {
            return new ApplicationVersionDomain(sObjectList);
        }
        public ApplicationVersionDomain constructEmpty() {
            return new ApplicationVersionDomain();
        }
    }
}