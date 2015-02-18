/**
 * Test class for the PPITableDataSet__c object domain class
 * Deals with:
 *     - Creation of a PPI Table Data Set
 *     - Adding PPI Table Data Set to a UnitOfWork
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 * @author - Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class PpiTableDataSetDomainTest {

    /**
     * Create multiple PpiTableDataSet records
     */
    public static List<PPITableDataSet__c> createMultipleRecords(Integer amount) {
        List<PPITableDataSet__c> ppiDataSets = new List<PPITableDataSet__c>();
        for (Integer i = 0; i < amount; i ++) {
            ppiDataSets.add(createPpiTableDataSet());
        }
        return ppiDataSets;
    }

    public static PPITableDataSet__c createPpiTableDataSet() {
        GenericObjectCreator creator =
            new GenericObjectCreator(PPITableDataSet__c.getSObjectType());
        PPITableDataSet__c ppiTableDataSet =
            (PPITableDataSet__c) creator.createNewRecord();
        return ppiTableDataSet;
    }

    public static UnitOfWork addPpiTableDataSetToUnitOfWork(
        PPITableDataSet__c ppiTableDataSet,
        PPITable__c ppiTable,
        Survey__c parentSurvey,
        SurveyVersion__c parentSurveyVersion,
        UnitOfWork unitOfWork
    ) {

        unitOfWork.addToInsertionOrder(PPITableDataSet__c.getSObjectType(), 1);
        unitOfWork.addToInsertList(
            ppiTableDataSet,
            PPITableDataSet__c.PPITable__c,
            ppiTable,
            1
        );
        unitOfWork.createRelationship(
            ppiTableDataSet,
            PPITableDataSet__c.Survey__c,
            parentSurvey,
            1
        );
        unitOfWork.createRelationship(
            ppiTableDataSet,
            PPITableDataSet__c.SurveyVersion__c,
            parentSurveyVersion,
            1
        );
        return unitOfWork;
    }

    /**
     * Set up some quick test data
     */
    private static Survey__c setUpBasicTestData() {
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        SurveyVersion__c surveyVersion = new SurveyVersionSelector().getLatestSurveyVersion(
            new List<Survey__c>{survey}
        ).get(survey.Id);
        List<PPITable__c> tables = PpiTableDomainTest.insertMultiplePpiTables(3);
        PpiTableDataSetDomain domain = new PpiTableDataSetDomain();
        UnitOfWork unitOfWork = new UnitOfWork();
        unitOfWork = domain.addRecordsForPpiTables(
            tables,
            unitOfWork,
            survey,
            surveyVersion
        );
        unitOfWork.commitWork();
        return new SurveySelector().getWithSurveyVersion(new Set<String>{survey.Id})[0];
    }

    /**
     * Test creating DataSets from tables
     */
    static testMethod void testCreatingDataSetsForTables() {

        Survey__c survey = setUpBasicTestData();
        List<PPITableDataSet__c> createdPpiTableDataSets =
            new PpiTableDataSetSelector().getAllForSurveys(new List<Id>{survey.Id});
        System.assertEquals(3, createdPpiTableDataSets.size());
    }

    /**
     * Test method for fetching a map of data Set with PpiTable PovertyLine Name as Key
     */
    static testmethod void testGetPpiTablePovertyLineToDataSetMap() {

        Survey__c survey = setUpBasicTestData();

        // Create data for Ppi related Tables
        List<PPITable__c> ppiTables =
            new PpiTableSelector().getPpiTablesForSurveys(
                new List<Id>{survey.Id}
            );
        Test.startTest();
        Map<Id, PPITableDataSet__c> mapPpiTableWithDataSets =
            PpiTableDataSetDomain.getPpiTablePovertyLineToDataSetMap(
                fetchPpiTablePovertyLineNames(ppiTables), survey
        );
        Test.stopTest();

        System.assertEquals(
            fetchPpiTablePovertyLineNames(ppiTables).size(),
            mapPpiTableWithDataSets.size()
        );
    }

    /**
     * Fetch PpiTabledataSets for respective Ppi Tables and SurveyVersion
     */
    static List<PPITableDataSet__c> fetchDataSetsWithSurveyVersion(
            List<PPITable__c> ppiTables,
            Id surveyVersionId
    ) {
        return new PpiTableDataSetSelector().getForSurveyVersionAndPovertyLineNames(
            surveyVersionId,
            fetchPpiTablePovertyLineNames(ppiTables)
        );
    }

    /**
     * Create Set of PpiTable PovertyLineNames
     */
    static Set<String> fetchPpiTablePovertyLineNames(List<PPITable__c> ppiTables) {
        Set<String> ppiTablePovertyLineNames = new Set<String>();
        for (PPITable__c ppiTable : ppiTables) {
            ppiTablePovertyLineNames.add(ppiTable.PovertyLine__c);
        }
        return ppiTablePovertyLineNames;
    }

    /**
     * Create Set of PpiTable Ids
     */
    static Set<Id> fetchPpiTableIds(List<PPITable__c> ppiTables) {
        Set<Id> ppiTableIds = new Set<Id>();
        for (PPITable__c ppiTable : ppiTables) {
            ppiTableIds.add(ppiTable.Id);
        }
        return ppiTableIds;
    }
}