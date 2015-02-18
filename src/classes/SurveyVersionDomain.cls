/**
 * Domain class for the SurveyVersion__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class SurveyVersionDomain extends SObjectDomain {

    public SurveyVersionDomain() {
        super(SurveyVersion__c.SObjectType);
    }

    public SurveyVersionDomain(List<SurveyVersion__c> sObjects) {
        super(sObjects);
    }

    /**
     * Method used to create map of Survey Version records with Id as key
     */
    public static Map<String, SurveyVersion__c> getSurveyVersionIdToInstanceMap(
            Set<Id> surveyVersionIds
    ) {
        Map<String, SurveyVersion__c> mapSurveyVersionIdToInstance =
            new Map<String, SurveyVersion__c>();

        for (SurveyVersion__c surveyVersion :
                (List<SurveyVersion__c>)
                    new SurveyVersionSelector().getAllWithSurveyDetails(surveyVersionIds)
        ) {
            mapSurveyVersionIdToInstance.put(surveyVersion.Id, surveyVersion);
        }

        return mapSurveyVersionIdToInstance;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public SurveyVersionDomain constructWithRecords(List<SObject> sObjectList) {
            return new SurveyVersionDomain(sObjectList);
        }
        public SurveyVersionDomain constructEmpty() {
            return new SurveyVersionDomain();
        }
    }
}