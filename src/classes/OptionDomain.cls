/**
 * Domain class for the Option__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 * @author - Aditi Satpute
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class OptionDomain extends SObjectDomain {

    public OptionDomain() {
        super(Option__c.SObjectType);
    }

    public OptionDomain(List<Option__c> sObjects) {
        super(sObjects);
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public OptionDomain constructWithRecords(List<sObject> sObjectList) {
            return new OptionDomain(sObjectList);
        }

        public OptionDomain constructEmpty() {
            return new OptionDomain();
        }
    }
}