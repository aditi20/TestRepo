/**
 * Domain class for the Survey Library object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 */
public with sharing class SurveyLibraryDomain extends SObjectDomain {

    public SurveyLibraryDomain() {
        super(SurveyLibrary__c.SObjectType);
    }

    public SurveyLibraryDomain(List<SurveyLibrary__c> sObjects) {
        super(sObjects);
    }

    public List<SurveyLibrary__c> insertRecords(List<SurveyLibrary__c> surveyLibraryList) {
        this.addRecords(surveyLibraryList);
        this.insertRecords();
        return this.records;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public SurveyLibraryDomain constructWithRecords(List<SObject> sObjectList) {
            return new SurveyLibraryDomain(sObjectList);
        }
        public SurveyLibraryDomain constructEmpty() {
            return new SurveyLibraryDomain();
        }
    }
}