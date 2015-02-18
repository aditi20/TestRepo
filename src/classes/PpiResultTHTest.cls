/**
 * Test class for the PpiResultTH
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
@isTest
public with sharing class PpiResultTHTest {

    /**
     * Test method for validating calculate Probabilities
     */
    static testMethod void testCalculateProbabilities() {
        PpiDataSubmissionServiceTest.setUpTestData();

        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(
                PpiDataSubmissionServiceTest.ppiResultIds,
                false
            );

        System.assertEquals(2, ppiResultList.size());

        Test.startTest();
        List<SubmissionPpiAssociation__c> submissionPpiDataList =
            PpiResultTH.calculateProbabilities(
                ppiResultList[0],
                PpiDataSubmissionServiceTest.tableLines
            );
        Test.stopTest();

        System.assert(
            submissionPpiDataList != null,
            'Submission Ppi records not created properly'
        );
        System.assertEquals(1, submissionPpiDataList.size());
    }

    /**
     * Test method for validating insertion of Submission Ppi Data
     */
    static testMethod void testSaveSubmissionPpiData() {
        PpiDataSubmissionServiceTest.setUpTestData();
        Set<String> ppiResultRecordIds = new Set<String>();
        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(
                PpiDataSubmissionServiceTest.ppiResultIds,
                false
            );

        System.assertEquals(2, ppiResultList.size());

        for (PpiResult__c ppiResult : ppiResultList) {
            ppiResultRecordIds.add(ppiResult.Id);
        }

        Test.startTest();
        PpiResultTH.saveSubmissionPpiData(ppiResultList);
        Test.stopTest();

        List<SubmissionPpiAssociation__c> insertedSubmissionPpiDataList =
            new SubmissionPpiAssociationSelector().getForPpiResult(ppiResultRecordIds);

        System.assert(
            insertedSubmissionPpiDataList != null,
            'Submission Ppi records not created properly'
        );
        System.assertEquals(4, insertedSubmissionPpiDataList.size());
    }

    /**
     * Test method for validating insertion of PpiResult with Unique Key
     */
    static testMethod void testBeforeInsertOnPpiResult() {
        Test.startTest();
        PpiDataSubmissionServiceTest.setUpTestData();
        Test.stopTest();

        Set<String> ppiResultRecordIds = new Set<String>();
        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(
                PpiDataSubmissionServiceTest.ppiResultIds,
                false
            );

        // PpiResult records are inserted properly in database
        System.assertEquals(2, ppiResultList.size());
        System.assert(ppiResultList[0].UniqueKey__c != null, 'UniqueKey not set properly');

    }

    /**
     * Test method for validating insertion of PpiResult with Submission Ppi Data
     */
    static testMethod void testAfterInsertOnPpiResult() {
        Test.startTest();
        PpiDataSubmissionServiceTest.setUpTestData();
        Test.stopTest();

        Set<String> ppiResultRecordIds = new Set<String>();
        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(
                PpiDataSubmissionServiceTest.ppiResultIds,
                false
            );

        // PpiResult records are inserted properly in database
        System.assertEquals(2, ppiResultList.size());

        for (PpiResult__c ppiResult : ppiResultList) {
            ppiResultRecordIds.add(ppiResult.Id);
        }
        List<SubmissionPpiAssociation__c> insertedSubmissionPpiDataList =
            new SubmissionPpiAssociationSelector().getForPpiResult(ppiResultRecordIds);

        System.assert(
            insertedSubmissionPpiDataList != null,
            'Submission Ppi records not created properly'
        );

        // SubmissionPpiAssociation records are inserted properly in database
        System.assertEquals(2, insertedSubmissionPpiDataList.size());
    }
}