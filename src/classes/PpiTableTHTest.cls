/**
 * Test class for the PpiTableTH
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class PpiTableTHTest {

    /**
     * Test method to verify deleting PpiTableDataSets and PpiTableLines on
     * delete specifie PpiTable.
     */
    static testmethod void testDeletionOfPpiTables() {
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();

        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(new Set<String> {survey.Id});

        System.assert(
            surveyVersions.size() > 0,
            'Survey Version records not created properly'
        );

        // Create data for Ppi related Tables
        PpiTableDomainTest.PpiTableWrapper tableWrapper =
            new PpiTableDomainTest.PpiTableWrapper();
        tableWrapper.createDefaultTable();
        PPITable__c ppiTable = tableWrapper.refetchTable();

        // Ppi Table records present in database
        System.assert(ppiTable != null, 'Ppi tables not inserted into database properly');

        System.assertEquals(
            2,
            new PpiTableLineSelector().getForPpiTableIds(
                new Set<Id> {ppiTable.Id}
            ).size()
        );

        PpiTableDomain ppiTableDomainInstance =
            new PpiTableDomain.Constructor().constructWithRecords(
                new List<PPITable__c>{ppiTable}
            );

        Test.startTest();
        ppiTableDomainInstance.deleteRecords();
        Test.stopTest();

        // Ppi Table record is deleted
        System.assert(
            (PPITable__c) (
                new PpiTableSelector().getRecordById(
                    ppiTable.Id
                )
            ) == null,
            'Ppi tables not deleted from database properly'
        );

        // Ppi Table Data Set record is deleted
        System.assertEquals(
            0,
            new PpiTableDataSetSelector().getForSurveyVersionAndPovertyLineNames(
                surveyVersions[0].Id,
                new Set<String> {ppiTable.PovertyLine__c}
            ).size()
        );

        // Ppi Table Line records are deleted
        System.assertEquals(
            0,
            new PpiTableLineSelector().getForPpiTableIds(
                new Set<Id> {ppiTable.Id}
            ).size()
        );
    }

    /**
     * Test method to verify validation of unique PpiTable name check on insert/update of Ppitable
     */
    static testmethod void testValidatePpitableUniqueNameCheck() {
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();

        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(new Set<String> {survey.Id});

        System.assert(
            surveyVersions.size() > 0,
            'Survey Version records not created properly'
        );

        // Create data for Ppi related Tables

        PpiTableDomainTest.PpiTableWrapper tableWrapper =
            new PpiTableDomainTest.PpiTableWrapper();
        tableWrapper.createDefaultTable();
        PPITable__c ppiTable1 = tableWrapper.table;

        // Ppi Table records present in database
        System.assert(
            (PPITable__c) (
                new PpiTableSelector().getRecordById(
                    ppiTable1.Id
                )
            ) != null,
            'Ppi tables not inserted into database properly'
        );

        Test.startTest();
        try {
            // Insert same name Ppitable record
            PpiTableDomainTest.PpiTableWrapper tableWrapperWithNameClash =
                new PpiTableDomainTest.PpiTableWrapper();
            tableWrapperWithNameClash.createDefaultTable();
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains('The table name must be unique for the survey.'),
                'Error message should be displayed'
            );
        }
        Test.stopTest();
    }
}