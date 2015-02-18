/**
 * Domain class for the SurveyMapping__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Aditi Satpute
 */
public with sharing class SurveyMappingDomain extends SObjectDomain {

    public SurveyMappingDomain() {
        super(SurveyMapping__c.SObjectType);
    }

    public SurveyMappingDomain(List<SurveyMapping__c> sObjects) {
        super(sObjects);
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public SurveyMappingDomain constructWithRecords(List<SObject> sObjectList) {
            return new SurveyMappingDomain(sObjectList);
        }
        public SurveyMappingDomain constructEmpty() {
            return new SurveyMappingDomain();
        }
    }
}
