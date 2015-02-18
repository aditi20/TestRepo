/**
 * Test class for validating the functionality of PpiTableDataSetTH
 *
 * (c) Copyright 2015 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class PpiTableDataSetTHTest {

    /**
     * Test method to verify that only data sets related to particular survey are deleted properly
     * if its parent ppiTables are linked to other Survey's dataSets
     */
    static testMethod void testDeleteDataSetsWithoutOrphanPpiTables() {
        List<PPITableDataSet__c> actualPpiDataSets = new List<PPITableDataSet__c>();
        List<PPITableDataSet__c> ppiDataSetsForSurvey1 = new List<PPITableDataSet__c>();
        List<PPITableDataSet__c> ppiDataSetsForSurvey2 = new List<PPITableDataSet__c>();

        Set<Id> ppiTableIds = new Set<Id>();
        Survey__c survey1 = SurveyDOTest.createInsertedPpiTemplate();
        Survey__c survey2 = SurveyDOTest.createInsertedPpiTemplate();
        List<Survey__c> surveyList =
            new SurveySelector().getWithSurveyVersion(new Set<String> {survey1.Id, survey2.Id});

        System.assertEquals(2, surveyList.size());
        survey1 = surveyList[0];
        survey2 = surveyList[1];

        // Verify each survey has fetched Survey Vesion records as well
        System.assert(
            survey1.SurveyVersions__r.size() > 0,
            'Survey Version records not fetched properly'
        );
        System.assert(
            survey2.SurveyVersions__r.size() > 0,
            'Survey Version records not fetched properly'
        );
        SurveyVersion__c surveyVersion1 = survey1.SurveyVersions__r[0];
        SurveyVersion__c surveyVersion2 = survey2.SurveyVersions__r[0];

        // Create data for Ppi related Tables
        List<PPITable__c> ppiTables = PpiTableDomainTest.insertMultiplePpiTables(3);
        System.assertEquals(3, ppiTables.size());

        UnitOfWork unitOfWork = new UnitOfWork();

        // Insert individual data sets for 2 different surveys which are linked to each PpiTable records
        for (PPITable__c table : ppiTables) {
            PPITableDataSet__c dataSet1 = PpiTableDataSetDomainTest.createPpiTableDataSet();
            PPITableDataSet__c dataSet2 = PpiTableDataSetDomainTest.createPpiTableDataSet();
            unitOfWork = PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
                dataSet1,
                table,
                survey1,
                surveyVersion1,
                unitOfWork
            );
            unitOfWork = PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
                dataSet2,
                table,
                survey2,
                surveyVersion2,
                unitOfWork
            );
            ppiDataSetsForSurvey1.add(dataSet1);
            ppiDataSetsForSurvey2.add(dataSet2);
            ppiTableIds.add(table.Id);
        }
        unitOfWork.commitWork();

        System.assertEquals(6, ppiDataSetsForSurvey1.size() + ppiDataSetsForSurvey2.size());

        Test.startTest();

        // Delete only first survey related dataSets
        PpiTableDataSetDomain dataSetDomain =
            new PpiTableDataSetDomain.Constructor().constructWithRecords(ppiDataSetsForSurvey1);
        dataSetDomain.deleteRecords();
        Test.stopTest();

        List<PPITable__c> ppiTableList =
            new PpiTableSelector().getForIdsWithPpiTableDataSets(ppiTableIds);

        // No PpiTable record deleted as it is linked to Survey2 as well
        System.assertEquals(
            3,
            ppiTableList.size()
        );

        // Verify PpiTableDataSet records linked to Survey2 are fetched properly.
        // No dataset records present for Survey1
        for (PPITable__c ppiTableInstance : ppiTableList) {
            actualPpiDataSets.addAll(ppiTableInstance.PPI_Table_Data_Sets__r);
        }

        System.assertEquals(ppiDataSetsForSurvey2.size(), actualPpiDataSets.size());
        System.assertEquals(
            1,
            ppiTableList[0].PPI_Table_Data_Sets__r.size()
        );

        for (Integer i = 0; i < ppiDataSetsForSurvey2.size(); i++) {
            System.assertEquals(
                ppiDataSetsForSurvey2[i].Id,
                ppiTableList[i].PPI_Table_Data_Sets__r[0].Id
            );
        }
    }

    /**
     * Test method to verify that on delete of data sets related to particular survey are deleted properly
     * along with its parent ppiTables if they are not linked to other Survey's dataSets
     */
    static testMethod void testDeleteDataSetsWithOrphanPpiTables() {
        List<PPITableDataSet__c> expectedPpiDataSets = new List<PPITableDataSet__c>();
        List<PPITableDataSet__c> actualPpiDataSets = new List<PPITableDataSet__c>();

        Set<Id> ppiTableIds = new Set<Id>();
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        List<Survey__c> surveyList =
            new SurveySelector().getWithSurveyVersion(new Set<String> {survey.Id});

        System.assertEquals(1, surveyList.size());
        survey = surveyList[0];

        // Verify survey has fetched Survey Vesion record properly
        System.assert(
            survey.SurveyVersions__r.size() > 0,
            'Survey Version records not fetched properly'
        );
        SurveyVersion__c surveyVersion = survey.SurveyVersions__r[0];

        // Create data for Ppi related Tables
        List<PPITable__c> ppiTables = PpiTableDomainTest.insertMultiplePpiTables(3);
        System.assertEquals(3, ppiTables.size());

        UnitOfWork unitOfWork = new UnitOfWork();

        // Insert individual data set and PpiTable line records for each ppiTable records
        for (PPITable__c table : ppiTables) {
            PPITableDataSet__c dataSet = PpiTableDataSetDomainTest.createPpiTableDataSet();

            PPITableLine__c ppiTableLine = PpiTableLineDomainTest.createPpiTableLine();
            unitOfWork = PpiTableLineDomainTest.addPpiTableLineToUnitOfWork(
                ppiTableLine,
                table,
                unitOfWork
            );
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

        // Verify that single PpiTableLine record is present for each PpiTable record
        System.assertEquals(
            3,
            new PpiTableLineSelector().getForPpiTableIds(ppiTableIds).size()
        );

        Test.startTest();

        // Delete all dataSets
        PpiTableDataSetDomain dataSetDomain =
            new PpiTableDataSetDomain.Constructor().constructWithRecords(expectedPpiDataSets);
        dataSetDomain.deleteRecords();
        Test.stopTest();

        // Verify that PpiTable record is deleted properly as all its lined datasets are deleted
        System.assertEquals(
            0,
            new PpiTableSelector().getForIdsWithPpiTableDataSets(ppiTableIds).size()
        );

        // Verify that PpiTableLine records are also deleted properly
        System.assertEquals(
            0,
            new PpiTableLineSelector().getForPpiTableIds(ppiTableIds).size()
        );
    }
}