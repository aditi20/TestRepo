/**
 * Test class for the PPITableLine__c object domain class
 * Deals with:
 *     - Creation of a PPI Table line
 *     - Adding PPI Table line to a UnitOfWork
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class PpiTableLineDomainTest {

    public static final Decimal TEST_FROM_VALUE = 0;
    public static final Decimal TEST_PROBABILITY = 0.05;
    public static final Decimal TEST_TO_VALUE = 4;

    public static PPITableLine__c insertPpiTableLine() {
        UnitOfWork unitOfWork = new UnitOfWork();
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();

        SurveySelector surveySelectorInstance = new SurveySelector();
        survey = surveySelectorInstance.getWithSurveyVersionAndQuestions(survey.Id);

        System.assertEquals(
            1,
            survey.SurveyVersions__r.size()
        );

        // Create data for Ppi related Tables
        PPITable__c ppiTable =
            PpiTableDomainTest.createPpiTable(
                'TableName1_KENYA_2012',
                'TableName1',
                'TableName1',
                '',
                52.3
            );
        insert ppiTable;

        // PpiTable records present in database
        System.assert(
            ((List<PPITable__c>) (
                new PpiTableSelector().getRecordsById(new Set<Id> {ppiTable.Id})
            )).size() == 1,
            'Ppi tables not inserted into database properly'
        );

        PPITableLine__c ppiTableLine = PpiTableLineDomainTest.createPpiTableLine();
        PpiTableLineDomainTest.addPpiTableLineToUnitOfWork(
            ppiTableLine,
            ppiTable,
            unitOfWork
        );
        unitOfWork.commitWork();
        return ppiTableLine;
    }

    public static PPITableLine__c createPpiTableLine() {
        return createPpiTableLine(
            TEST_FROM_VALUE,
            TEST_PROBABILITY,
            '',
            TEST_TO_VALUE
        );
    }

    public static PPITableLine__c createPpiTableLine(
            Decimal fromValue,
            Decimal probability,
            String remoteId,
            Decimal toValue
    ) {
        return createPpiTableLine(new Map<Schema.SObjectField, Object>{
            PPITableLine__c.From__c => fromValue,
            PPITableLine__c.Probability__c => probability,
            PPITableLine__c.RemoteId__c => remoteId,
            PPITableLine__c.To__c => toValue
        });
    }

    public static PPITableLine__c createPpiTableLine(
            Map<Schema.SObjectField, Object> fieldMap
    ) {

        GenericObjectCreator creator =
            new GenericObjectCreator(PPITableLine__c.getSObjectType());
        PPITableLine__c ppiTableLine =
            (PPITableLine__c) creator.createNewRecord();
        creator.populateFields(
            ppiTableLine,
            fieldMap
        );
        return ppiTableLine;
    }

    public static UnitOfWork addPpiTableLineToUnitOfWork(
        PPITableLine__c ppiTableLine,
        PPITable__c ppiTable,
        UnitOfWork unitOfWork
    ) {

        unitOfWork.addToInsertionOrder(PPITableLine__c.getSObjectType(), 1);
        unitOfWork.addToInsertList(
            ppiTableLine,
            PPITableLine__c.PpiTable__c,
            ppiTable,
            1
        );
        return unitOfWork;
    }

    /**
     * Update PPITableDataSet__c field in PPITableLine__c record according to old data model
     */
    public static List<PPITableLine__c> addPpiTableDataSetValueAsOldDataModel(
            Map<Id, List<PPITableLine__c>> mapPpiTableDataSetIdWithTableLine
    ) {
        List<PPITableLine__c> updatedPpiTableLineList = new List<PPITableLine__c>();
        for (Id ppiTableDataSetId : mapPpiTableDataSetIdWithTableLine.keySet()) {
            for (
                    PPITableLine__c ppiTableLineInstance :
                        mapPpiTableDataSetIdWithTableLine.get(ppiTableDataSetId)
            ) {
                ppiTableLineInstance.PPITableDataSet__c = ppiTableDataSetId;
                ppiTableLineInstance.PpiTable__c = null;
                updatedPpiTableLineList.add(ppiTableLineInstance);
            }
        }
        return updatedPpiTableLineList;
    }
}