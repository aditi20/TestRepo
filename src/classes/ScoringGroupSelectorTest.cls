/**
 * Test class for the ScoringGroupSelector class
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Ketaki Virkar
 */
@isTest
public with sharing class ScoringGroupSelectorTest {

    /**
     * Method to test fetching all scoring group records for specified Survey__c.Id
     */
    static testMethod void testGetAllForSurvey() {

        TestSurveyData testSurvey =
            TestSurveyData.addScoringGroupToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true), false
            );
        Test.startTest();
        List<ScoringGroup__c> scoringGroupList =
            new ScoringGroupSelector().getAllForSurvey(testSurvey.testSurvey.Id);
        Test.stopTest();
        System.assertEquals(
            1,
            scoringGroupList.size(),
            'Scoring Group should get selected properly'
        );
    }

    /**
     * Test Method to fetch all scoring groups for specified Survey id, ppi order by Created Date
     */
    static testMethod void testGetAllForSurveyPpiOrderByCreatedDate() {
        TestSurveyData testSurvey =
            TestSurveyData.addScoringGroupToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true), true
            );

        ScoringGroupDomain scoringGroupDomainInstance =
            new ScoringGroupDomain.Constructor().constructWithRecords(
                new List<ScoringGroup__c> {
                    ScoringGroupDomainTest.createRecord('grpCap1', testSurvey.testSurvey.Id, false)
                }
            );
        scoringGroupDomainInstance.insertRecords();
        System.assertEquals(1, scoringGroupDomainInstance.records.size());
        for (ScoringGroup__c scoringGroupInstance :
                (List<ScoringGroup__c>) scoringGroupDomainInstance.records) {
            System.assert(scoringGroupInstance.Id != null);
        }

        // added 5 secods delay for checking Order By Created Date
        C.wait(5);

        scoringGroupDomainInstance =
            new ScoringGroupDomain.Constructor().constructWithRecords(
                new List<ScoringGroup__c> {
                    ScoringGroupDomainTest.createRecord('grpCap2', testSurvey.testSurvey.Id, false)
                }
            );
        System.assertEquals(1, scoringGroupDomainInstance.records.size());
        scoringGroupDomainInstance.insertRecords();
        System.assert(scoringGroupDomainInstance.records[0].Id != null);

        Test.startTest();
        List<ScoringGroup__c> listScoringGroup =
            new ScoringGroupSelector().getAllForSurveyPpiOrderByCreatedDate(
                testSurvey.testSurvey.Id,
                false
            );
        Test.stopTest();
        System.assertEquals(2, listScoringGroup.size());
        System.assertEquals('grpCap1', listScoringGroup[0].Caption__c);
        System.assertEquals('grpCap2', listScoringGroup[1].Caption__c);
    }
}