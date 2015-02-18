/**
 * Test class for the PpiTableSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public with sharing class PpiTableSelectorTest {

    /**
     * Test method to verify fetching of SurveyVersion object with specified survey Ids
     */
    static testMethod void testGetTableByName() {
        List<PPITable__c> ppiTables = PpiTableDomainTest.insertMultiplePpiTables(3);

        Test.startTest();
        List<PPITable__c> foundPpiTables =
            new PpiTableSelector().getByTableNames(
                new Set<String>{
                    ppiTables[0].Name,
                    ppiTables[1].Name
                }
            );
        Test.stopTest();

        System.assertEquals(2, foundPpiTables.size());
        for (Integer i = 0; i < foundPpiTables.size(); i++) {
            System.assertEquals(ppiTables[i].Name, foundPpiTables[i].Name);
        }
    }

    /**
     * Test method to verify the fetching of PPI Tables that are related to a given survey
     */
    static testMethod void testGetTablesBySurvey() {

        TestSurveyData testSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedPpiTemplate(), false
                )
            );

        // Create a standalone PPI tables
        List<PPITable__c> ppiTables = PpiTableDomainTest.insertMultiplePpiTables(3);

        Test.startTest();
        List<PPITable__c> foundPpiTables =
            new PpiTableSelector().getPpiTablesForSurveys(
                new List<Id>{testSurvey.testSurvey.Id}
            );
        Test.stopTest();
        System.assertEquals(1, foundPpiTables.size());
    }

    /**
     * Test method to verify fetching of PpiTable records with Data sets
     */
    static testMethod void testFetchAllWithDataSets() {

        TestSurveyData testSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedPpiTemplate(),
                    false
                )
            );

        Test.startTest();
        List<PPITable__c> ppiTables = new PpiTableSelector().getAllWithPpiTableDataSets();

        // PpiTable records are fetched properly
        System.assertEquals(1, ppiTables.size());

        // PpiTableDataSet records are fetched properly
        System.assertEquals(1, ppiTables[0].PPI_Table_Data_Sets__r.size());

        Test.stopTest();
    }

    /**
     * Test method for fetching Ppi tables with specified names
     */
    static testMethod void testFetchDataForPpiTableNames() {
        PpiTableDomainTest.PpiTableWrapper tableWrapper =
            new PpiTableDomainTest.PpiTableWrapper();
        tableWrapper.createDefaultTable();

        Test.startTest();
        List<PPITable__c> ppiTables =
            new PpiTableSelector().getForPpiTableNames(
                new Set<String> {tableWrapper.table.Name}
            );
        Test.stopTest();

        // PpiTable records are fetched properly
        System.assertEquals(
            1,
            ppiTables.size()
        );
    }

    /**
     * Test method for fetching Ppi tables with specified Ppitable name
     */
    static testMethod void testLikePpiTableNames() {

        // Create data for Ppi related Tables
        List<PPITable__c> ppiTablesList = PpiTableDomainTest.insertMultiplePpiTables(3);

        Test.startTest();
        List<PPITable__c> ppiTables =
            new PpiTableSelector().getLikePpiTableNames(PpiTableDomainTest.TEST_TABLE_NAME);
        Test.stopTest();

        // PpiTable records are fetched properly
        System.assertEquals(
            3,
            ppiTables.size()
        );
    }

    /**
     * Test method for fetching Ppi tables along with Table Lines with specified Ppi table Ids
     */
    static testMethod void testFetchDataWithTableLines() {
        PpiTableDomainTest.PpiTableWrapper tableWrapper =
            new PpiTableDomainTest.PpiTableWrapper();
        tableWrapper.createDefaultTable();

        Test.startTest();
        List<PPITable__c> ppiTables =
            new PpiTableSelector().getWithPpiTableLines(
                new Set<Id> {tableWrapper.table.Id}
            );
        Test.stopTest();

        // PpiTable records are fetched properly
        System.assertEquals(
            1,
            ppiTables.size()
        );

        // PpiTableLine records are fetched properly
        System.assertEquals(
            2,
            ppiTables[0].PPI_Table__r.size()
        );
    }

    /**
     * Test method for fetching Ppi tables along with data sets for specified Ppi table Ids
     */
    static testMethod void testFetchDataForIdsWithDataSets() {
        List<PPITableDataSet__c> expectedPpiDataSets = new List<PPITableDataSet__c>();
        List<PPITableDataSet__c> actualPpiDataSets = new List<PPITableDataSet__c>();
        Set<Id> ppiTableIds = new Set<Id>();
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        survey = new SurveySelector().getWithSurveyVersionAndQuestions(survey.Id);

        System.assert(
            survey.SurveyVersions__r.size() > 0,
            'Survey Version records not fetched properly'
        );
        SurveyVersion__c surveyVersion = survey.SurveyVersions__r[0];

        // Create data for Ppi related Tables
        List<PPITable__c> ppiTables = PpiTableDomainTest.insertMultiplePpiTables(3);
        System.assertEquals(3, ppiTables.size());

        UnitOfWork unitOfWork = new UnitOfWork();
        for (PPITable__c table : ppiTables) {
            PPITableDataSet__c dataSet = PpiTableDataSetDomainTest.createPpiTableDataSet();
            unitOfWork = PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
                dataSet,
                table,
                survey,
                surveyVersion,
                unitOfWork
            );
            expectedPpiDataSets.add(dataSet);
            ppiTableIds.add(table.Id);
        }
        unitOfWork.commitWork();

        System.assertEquals(3, expectedPpiDataSets.size());

        Test.startTest();
        List<PPITable__c> ppiTableList =
            new PpiTableSelector().getForIdsWithPpiTableDataSets(ppiTableIds);
        Test.stopTest();

        // PpiTable records are fetched properly
        System.assertEquals(
            3,
            ppiTableList.size()
        );

        // PpiTableDataSet records are fetched properly
        for (PPITable__c ppiTableInstance : ppiTableList) {
            actualPpiDataSets.addAll(ppiTableInstance.PPI_Table_Data_Sets__r);
        }

        System.assertEquals(expectedPpiDataSets.size(), actualPpiDataSets.size());
        System.assertEquals(
            1,
            ppiTableList[0].PPI_Table_Data_Sets__r.size()
        );
    }
}