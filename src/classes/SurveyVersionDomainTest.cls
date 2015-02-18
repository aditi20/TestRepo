/**
 * Test class for the SurveyVersionDomain
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
@isTest
public with sharing class SurveyVersionDomainTest {

    /**
     * Create SurveyVersion record
     */
    public static SurveyVersion__c createRecord(Survey__c survey, String status) {
        return new SurveyVersion__c(
            Survey__c = survey.id,
            Status__c = status
        );
    }

    /**
     * Method to test fetching Map of SurveyVersion records
     */
    static testmethod void testFetchSurveyVersionIdToInstanceMap() {
        Survey__c survey1 = SurveyDOTest.createInsertedSurvey('SurveyTest1');
        Survey__c survey2 = SurveyDOTest.createInsertedSurvey('SurveyTest');

        List<SurveyVersion__c> surveyVersionList =
            new SurveyVersionSelector().getAllWithSurveyIds(
                new Set<String> {survey1.Id, survey2.Id}
            );

        System.assertEquals(2, surveyVersionList.size());

        Test.startTest();
        Map<String, SurveyVersion__c> mapSurveyVersionIdToInstance =
            SurveyVersionDomain.getSurveyVersionIdToInstanceMap(
                new Set<Id> {
                    surveyVersionList[0].Id,
                    surveyVersionList[1].Id
                }
            );
        Test.stopTest();

        System.assertEquals(2, mapSurveyVersionIdToInstance.size());
    }
}