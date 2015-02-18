/**
 * This class contains test methods for validating the behavior of PpiResultSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 * @author - Aditi Satpute
 */
@isTest
public with sharing class PpiResultSelectorTest {

    /**
     * Test method to fetch PpiResult records based on Survey Version Ids
     */
    static testMethod void testGetAllForSurveyVersionIds() {

        List<PpiResult__c> createdPpiResultList =
            PpiResultDomainTest.createSamplePpiResultData(1, false);
        System.assert(createdPpiResultList.size() == 1, 'No records created.');

        Test.startTest();
        List<PpiResult__c> ppiResultList = 
            new PpiResultSelector().getAllForSurveyVersionIds(
                new Set<Id> {createdPpiResultList[0].PPITemplate__c}
            );
        Test.stopTest();

        // PpiResult records fetched properly from database
        System.assert(ppiResultList.size() == 1, 'No records found');
    }

    /**
     * Test method to fetch PpiResult records based on RetrievedByParent is false
     */
    static testMethod void testGetAllWithSyncFalse() {

        List<PpiResult__c> createdPpiResultList =
            PpiResultDomainTest.createSamplePpiResultData(1, false);
        System.assert(createdPpiResultList.size() == 1, 'No records created.');

        Test.startTest();
        List<PpiResult__c> ppiResultList = 
            new PpiResultSelector().getAllWithSyncFalse(new Set<Id> {createdPpiResultList[0].Id});
        Test.stopTest();

        System.assert(ppiResultList.size() == 1, 'No records found');
    }

    /**
     * Test method to fetch PpiResult records based on RetrievedByParent is true
     */
    static testMethod void testGetAllWithSyncTrue() {

        List<PpiResult__c> createdPpiResultList =
            PpiResultDomainTest.createSamplePpiResultData(1, true);
        System.assert(createdPpiResultList.size() == 1, 'No records created.');

        Test.startTest();
        List<PpiResult__c> ppiResultList = 
            new PpiResultSelector().getAllWithSyncTrue(new Set<Id> {createdPpiResultList[0].Id});
        Test.stopTest();

        System.assert(ppiResultList.size() == 1, 'No records found');
    }

    /**
     * Test method to fetch PpiResult records based on any value of RetrievedByParent 
     */
    static testMethod void testGetAllWithSyncValue() {

        List<PpiResult__c> createdPpiResultListWithSyncTrue =
            PpiResultDomainTest.createSamplePpiResultData(1, true);

        System.assert(createdPpiResultListWithSyncTrue.size() == 1, 'No records created.');

        Test.startTest();
        List<PpiResult__c> ppiResultList = 
            new PpiResultSelector().getAllWithSyncValue(
                new Set<Id> {
                    createdPpiResultListWithSyncTrue[0].Id
                },
                true
            );
        Test.stopTest();

        System.assert(ppiResultList.size() == 1, 'No records found');
    }

    /**
     * Test method to fetch PpiResult records based on UniqueKey 
     */
    static testMethod void testGetForUniqueKey() {

        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, false);

        PpiResult__c ppiResult = PpiResultDomainTest.createRecord(
            testSurvey.testSurveyVersion,
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[2].Id
            )[0],
            false
        );
        ppiResult.PpiCollectionDate__c = Datetime.newInstance(2014, 12, 1);
        PpiResultDomain ppiDomainInstance =
            new PpiResultDomain.Constructor().constructWithRecords(
                new List<PpiResult__c> {ppiResult}
            );
        ppiDomainInstance.insertRecords();

        // Fetch record from database as unique Key is created by trigger
        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncFalse(new Set<Id> {ppiResult.Id});
        System.assert(ppiResultList.size() == 1, 'Ppiresult record not found');

        Test.startTest();
        ppiResultList =
            new PpiResultSelector().getForUniqueKey(
                new Set<String> {ppiResultList[0].UniqueKey__c}
            );
        Test.stopTest();

        System.assert(ppiResultList.size() == 1, 'Ppiresult record not fetched properly');
        System.assert(ppiResultList[0] != null, 'Record with unique key not fetched properly');
    }

    /**
     * Test method to fetch PpiResult records based on client Id 
     */
    static testMethod void testGetByClientId() {
        TestSurveyData testSurvey = TestSurveyData.createFullPpiTemplate();
        Contact client = new Contact(LastName = 'TestClient');
        insert client;

        PpiResult__c ppiResult = PpiResultDomainTest.createRecord(
            testSurvey.testSurveyVersion,
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[0].Id
            )[0],
            false
        );

        ppiResult.ClientId__c = client.Id;
        PpiResultDomain domain = new PpiResultDomain();
        domain.addRecord(ppiResult);
        domain.insertRecords();

        PpiResultSelector resultSelector = new PpiResultSelector();
        Test.startTest();
        List<PpiResult__c> ppiResults = resultSelector.getByClientId(client.Id);
        Test.stopTest();
        System.assertEquals(1, ppiResults.size(), 'PpiResult not created properly.');
    }
}