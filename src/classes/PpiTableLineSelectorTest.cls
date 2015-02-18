/**
 * Test class for the PpiTableLineSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class PpiTableLineSelectorTest {

    private static PPITable__c ppiTable;

    /**
     * Test method for fetching Ppi table lines for specified Ppi table Ids
     */
    static testmethod void testFetchDataForPpiTableIds() {

        PpiTableDomainTest.PpiTableWrapper table1 =
            new PpiTableDomainTest.PpiTableWrapper();
        table1.createDefaultTable('_T1');
        PpiTableDomainTest.PpiTableWrapper table2 =
            new PpiTableDomainTest.PpiTableWrapper();
        table2.createDefaultTable('_T2');
        Test.startTest();
        PpiTableLineSelector tableLineSelectorInstance = new PpiTableLineSelector();
        List<PPITableLine__c> tableLines =
            tableLineSelectorInstance.getForPpiTableIds(new Set<Id> {
                table1.table.Id,
                table2.table.Id
        });
        Test.stopTest();

        // PpiTableLine records are fetched properly
        System.assertEquals(4, tableLines.size());
    }

    /**
     * Test method for fetching Ppi table lines for specified Ppi table Names
     */
    static testmethod void testFetchDataForPpiTableNames() {
        createTestData();

        Test.startTest();
        List<PPITableLine__c> tableLines =
            new PpiTableLineSelector().getForPpiTableNames(
                new Set<String> {ppiTable.Name}
            );
        Test.stopTest();

        // PpiTableLine records are fetched properly
        System.assertEquals(
            2,
            tableLines.size()
        );
    }

    /**
     * Test method for fetching Ppi table lines for specified PpiTable Name
     */
    static testmethod void testLikePpiTableNames() {
        createTestData();

        Test.startTest();
        List<PPITableLine__c> tableLines =
            new PpiTableLineSelector().getLikePpiTableNames(ppiTable.Name);
        Test.stopTest();

        // PpiTableLine records are fetched properly
        System.assertEquals(
            2,
            tableLines.size()
        );
    }

    /**
     * Test method for fetching all Ppi Table Line records for specified Survey Ids
     */
    static testMethod void testGetPpiTableLineForSurveyIds() {

        // Create Survey
        SurveyDO surveyDomainInstance =
            new SurveyDO.Constructor().constructWithRecords(
                new List<Survey__c> {
                    SurveyDOTest.createPpiTemplate(),
                    SurveyDOTest.createPpiTemplate()
                }
            );
        surveyDomainInstance.insertRecords();
        System.assertEquals(2, surveyDomainInstance.records.size());
        for (Survey__c surveyInstance : (List<Survey__c>) surveyDomainInstance.records) {
            System.assert(surveyInstance.Id != null);
        }

        // Create Survey Version
        SurveyVersionDomain surveyVersionDomainInstance =
            new SurveyVersionDomain.Constructor().constructWithRecords(
                new List<SurveyVersion__c> {
                    SurveyVersionDomainTest.createRecord(
                        (Survey__c) surveyDomainInstance.records[0],
                        SurveyDO.STATUS_DRAFT
                    ),
                    SurveyVersionDomainTest.createRecord(
                        (Survey__c) surveyDomainInstance.records[0],
                        SurveyDO.STATUS_PUBLISHED
                    )
                }
            );
        surveyVersionDomainInstance.insertRecords();
        System.assertEquals(2, surveyVersionDomainInstance.records.size());
        for (
                SurveyVersion__c surveyVersionInstance :
                (List<SurveyVersion__c>) surveyVersionDomainInstance.records
        ) {
            System.assert(surveyVersionInstance.Id != null);
        }

        PpiTableDomainTest.PpiTableWrapper tableWrapper = new PpiTableDomainTest.PpiTableWrapper();
        tableWrapper.createDefaultTable();

        // Update Ppi Table name since it should be unique 
        tableWrapper.table.Name = 'test table 1';
        PpiTableDomain ppiTableDomainInstance =
            new PpiTableDomain.Constructor().constructWithRecords(
                new List<PPITable__c> {
                    tableWrapper.table
                }
            );
        ppiTableDomainInstance.updateRecords();

        PpiTableDomainTest.PpiTableWrapper otherTableWrapper = new PpiTableDomainTest.PpiTableWrapper();
        otherTableWrapper.createDefaultTable();
        otherTableWrapper.addLines(1);

        // Create Ppi Table DataSet record
        PpiTableDataSetDomain ppiTableDataSetDomainInstance =
            new PpiTableDataSetDomain.Constructor().constructWithRecords(
                PpiTableDataSetDomainTest.createMultipleRecords(2)
            );
        UnitOfWork unitOfWorkInstance = PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
            (PPITableDataSet__c) ppiTableDataSetDomainInstance.records[0],
            tableWrapper.table,
            (Survey__c) surveyDomainInstance.records[0],
            (SurveyVersion__c) surveyVersionDomainInstance.records[0],
            new UnitOfWork()
        );
        unitOfWorkInstance.commitWork();

        unitOfWorkInstance = PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
            (PPITableDataSet__c) ppiTableDataSetDomainInstance.records[1],
            otherTableWrapper.table,
            (Survey__c) surveyDomainInstance.records[1],
            (SurveyVersion__c) surveyVersionDomainInstance.records[1],
            new UnitOfWork()
        );
        unitOfWorkInstance.commitWork();

        System.assertEquals(2, ppiTableDataSetDomainInstance.records.size());
        for (
                PPITableDataSet__c ppiTableDataSetInstance :
                    (List<PPITableDataSet__c>) ppiTableDataSetDomainInstance.records
        ) {
            System.assert(ppiTableDataSetInstance.Id != null);
        }

        // Update PpiTableDataSet and PpiTable fields in PpiTableLine records
        PpiTableLineDomain ppiTableLineDomainInstance =
            new PpiTableLineDomain.Constructor().constructWithRecords(
                PpiTableLineDomainTest.addPpiTableDataSetValueAsOldDataModel(
                    new Map<Id, List<PPITableLine__c>> {
                        ppiTableDataSetDomainInstance.records[0].Id =>
                            tableWrapper.tableLines,
                        ppiTableDataSetDomainInstance.records[1].Id =>
                            otherTableWrapper.tableLines
                    }
                )
            );
        ppiTableLineDomainInstance.upsertRecords();
        System.assertEquals(5, ppiTableLineDomainInstance.records.size());

        Test.startTest();
        List<PPITableLine__c> tableLinesForFirstSurvey =
            new PpiTableLineSelector().getAllForOldSurveyIds(
                new Set<Id> {surveyDomainInstance.records[0].Id}
            );
        List<PPITableLine__c> tableLinesForSecondSurvey =
            new PpiTableLineSelector().getAllForOldSurveyIds(
                new Set<Id> {surveyDomainInstance.records[1].Id}
            );
        List<PPITableLine__c> tableLinesForAllSurvey =
            new PpiTableLineSelector().getAllForOldSurveyIds(
                new Set<Id> {
                    surveyDomainInstance.records[0].Id,
                    surveyDomainInstance.records[1].Id
                }
            );
        Test.stopTest();

        System.assertEquals(2, tableLinesForFirstSurvey.size());
        System.assertEquals(3, tableLinesForSecondSurvey.size());
        System.assertEquals(5, tableLinesForAllSurvey.size());
    }

    /**
     * Method to create all Look Up Tables related data
     */
    private static void createTestData() {

        PpiTableDomainTest.PpiTableWrapper tableWrapper =
            new PpiTableDomainTest.PpiTableWrapper();
        tableWrapper.createDefaultTable();
        ppiTable = tableWrapper.table;
    }
}