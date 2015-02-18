/**
 * Test class for the PpiTableDataSetSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
@isTest
public with sharing class PpiTableDataSetSelectorTest {

    private static Survey__c survey;
    private static SurveyVersion__c surveyVersion;
    private static List<PPITable__c> ppiTables;
    private static List<PPITableDataSet__c> ppiDataSets;

    /**
     * Test class for fetching ppiTableDataSets for specified SurveyVersionIds
     */
    static testMethod void testDataSetsForSurveyVersionIds() {
        TestSurveyData testSurvey1 = TestSurveyData.createStandardTestSurvey(null, false);
        TestSurveyData testSurvey2 = TestSurveyData.createStandardTestSurvey(null, false);

        // Create data for PPI related Tables
        List<PPITable__c> ppiTablesList = PpiTableDomainTest.createMultiplePpiTables(3);
        UnitOfWork unitOfWork = new UnitOfWork();
        for (PPITable__c ppiTable : ppiTablesList) {
            PpiTableDomainTest.addPpiTableToUnitOfWork(
                ppiTable,
                null,
                unitOfWork
            );
        }
        PpiTableDataSetDomain domain = new PpiTableDataSetDomain();
        unitOfWork = domain.addRecordsForPpiTables(
            ppiTablesList,
            unitOfWork,
            testSurvey1.testSurvey,
            testSurvey1.testSurveyVersion
        );
        unitOfWork = domain.addRecordsForPpiTables(
            ppiTablesList,
            unitOfWork,
            testSurvey2.testSurvey,
            testSurvey2.testSurveyVersion
        );
        unitOfWork.commitWork();
        Test.startTest();
        PpiTableDataSetSelector dataSetSelectorInstance = new PpiTableDataSetSelector();
        List<PPITableDataSet__c> dataSets = dataSetSelectorInstance.getForSurveyVersion(
            new Set<Id> {
                testSurvey1.testSurveyVersion.Id,
                testSurvey2.testSurveyVersion.Id
            }
        );
        Test.stopTest();

        // PpiTableDataSet records are fetched properly
        System.assertEquals(6, dataSets.size());
    }

    /**
     * Test method for fetching PpiTableDataSets with specified SurveyVersionId
     * and PpiTablePovertyLine Names
     */
    static testMethod void testFetchDataForSurveyVersionIdAndTablePovertyLineNames() {
        createTestData();

        Test.startTest();
        PpiTableDataSetSelector dataSetSelectorInstance = new PpiTableDataSetSelector();
        List<PPITableDataSet__c> dataSets =
            dataSetSelectorInstance.getForSurveyVersionAndPovertyLineNames(
                surveyVersion.Id,
                new Set<String> {
                    ppiTables[0].PovertyLine__c,
                    ppiTables[1].PovertyLine__c,
                    ppiTables[2].PovertyLine__c
                }
            );
        Test.stopTest();

        // PpiTableDataSet records are fetched properly
        System.assertEquals(
            3,
            dataSets.size(),
            '3 Data sets should be found'
        );
    }

    /**
     * Test method for fetching PpiTableDataSets with specified PpiTable Names
     */
    static testMethod void testFetchDataForTableNames() {
        createTestData();

        Test.startTest();
        List<PPITableDataSet__c> dataSets =
            new PpiTableDataSetSelector().getForPpiTableNames(
                new Set<String> {
                    ppiTables[0].Name,
                    ppiTables[1].Name,
                    ppiTables[2].Name
                }
            );
        Test.stopTest();

        // PpiTableDataSet records are fetched properly
        System.assertEquals(
            3,
            dataSets.size()
        );
    }

    /**
     * Test method for fetching PpiTableDataSets with specified PpiTable name
     */
    static testMethod void testLikePpiTableNames() {
        createTestData();

        Test.startTest();
        List<PPITableDataSet__c> dataSets =
            new PpiTableDataSetSelector().getLikePpiTableNames(
                PpiTableDomainTest.TEST_TABLE_NAME
            );
        Test.stopTest();

        // PpiTableDataSet records are fetched properly
        System.assertEquals(
            3,
            dataSets.size()
        );
    }

    /**
     * Method to create all Look Up Tables related data
     */
    private static void createTestData() {
        ppiDataSets = new List<PPITableDataSet__c>();
        survey = SurveyDOTest.createInsertedPpiTemplate();
        survey = new SurveySelector().getWithSurveyVersionAndQuestions(survey.Id);

        System.assert(
            survey.SurveyVersions__r.size() > 0,
            'Survey Version records not fetched properly'
        );
        surveyVersion = survey.SurveyVersions__r[0];

        // Create data for Ppi related Tables
        ppiTables = PpiTableDomainTest.insertMultiplePpiTables(3);

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
            ppiDataSets.add(dataSet);
        }
        unitOfWork.commitWork();
    }
}