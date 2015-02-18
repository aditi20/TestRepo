/**
 * This class contains all the logic that is carried out by a
 * trigger on PpiResult__c object.
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class PpiResultTH extends TriggerHandler {

    // Boolean to check if any migration is going on
    public static Boolean isMigration;

    static {
        // Set false only if this variable is not explicitly set from any other places
        if (isMigration == null) {
            isMigration = false;
        }
    }

    private PpiResultDomain getTriggerDomain() {
        return (PpiResultDomain) this.domain;
    }

    /**
     * Defaults to apply before insert
     */
    public override void applyDefaults() {
        // Set PpiCollection Date first as it is used while creation of Unique Key for ppi Results
        getTriggerDomain().setCollectionDatePpiResults((List<PpiResult__c>) getRecords(), isMigration);
        getTriggerDomain().setUniqueKeys((List<PpiResult__c>) getRecords());
    }

    /**
     * After Insert
     *
     * Check to be carried out:-
     *     - Check that PpiScore lies in valid probabilities
     *
     * Actions carried out:-
     *     - Calculate probabilities based on recieved PpiResult record
     *     - Create Submission Ppi Association records
     */
    public override void onAfterInsert() {
        saveSubmissionPpiData((List<PpiResult__c>) getRecords());
    }

    /**
     * Method to save Submission Ppi data on parent org
     */
    @TestVisible
    private static void saveSubmissionPpiData(List<PpiResult__c> insertedPpiResultList) {
        try {
            List<SubmissionPpiAssociation__c> submissionPpiData =
                new List<SubmissionPpiAssociation__c>();
            Map<Id, List<PPITableDataSet__c>> mapPpiTableIdToDataSetList =
                new Map<Id,List<PPITableDataSet__c>>();
            Map<Id, List<PPITableLine__c>> mapSurveyVersionIdtoTableLines =
                new Map<Id, List<PPITableLine__c>>();
            Map<Id, List<PPITableLine__c>> mapPpiTableIdToLines =
                new Map<Id, List<PPITableLine__c>>();
            Set<Id> surveyVersionIds = new Set<Id>();
            Set<Id> insertedPpiResultIds = new Set<Id>();

            for (PpiResult__c ppiResult : insertedPpiResultList) {
                surveyVersionIds.add(ppiResult.PpiTemplate__c);
                insertedPpiResultIds.add(ppiResult.Id);
            }

            List<PPITableDataSet__c> ppiTableDataSetList =
                new PpiTableDataSetSelector().getForSurveyVersion(surveyVersionIds);

            // Create map with PpiTable Id and list of associated PpiTableDataSets
            setPpiTableIdToDataSetListMap(ppiTableDataSetList, mapPpiTableIdToDataSetList);

            // Create map with PpiTable Id and list of associated Table lines
            setPpiTableIdToLinesMap(mapPpiTableIdToDataSetList.keySet(), mapPpiTableIdToLines);

            // Create map with SurveyVersion Id and list of Table lines
            setSurveyVersionIdToLinesMap(
                ppiTableDataSetList,
                mapPpiTableIdToLines,
                mapSurveyVersionIdtoTableLines
            );

            // Create submission ppi records only for successfully inserted Ppi Result records
            // Fetch the ppiResult records again as formula field can only be used when queried
            for (PpiResult__c ppiResult :
                    (List<PpiResult__c>)
                        new PpiResultSelector().getRecordsById(insertedPpiResultIds)) {
                if (mapSurveyVersionIdtoTableLines.containsKey(ppiResult.PpiTemplate__c)) {
                    submissionPpiData.addAll(calculateProbabilities(
                        ppiResult,
                        mapSurveyVersionIdtoTableLines.get(ppiResult.PpiTemplate__c)
                    ));
                }
            }

            // Insert SubmissionPpi data in database
            if (!submissionPpiData.isEmpty()) {
                SubmissionPpiAssociationDomain submissionPpiAssociationDomainInstance =
                    new SubmissionPpiAssociationDomain.Constructor().constructWithRecords(
                        submissionPpiData
                    );
                submissionPpiAssociationDomainInstance.insertRecords();
            }
        } catch (Exception genericException) {
            throw new PpiResultTHException(genericException.getMessage());
        }
    }

    /**
     * Method to create a map with parent PpiTable's Id as key along with its linked dataset list
     */
    @TestVisible
    private static void setPpiTableIdToDataSetListMap(
            List<PPITableDataSet__c> ppiTableDataSetList,
            Map<Id, List<PPITableDataSet__c>> mapPpiTableIdToDataSetList
    ) {
        for (PPITableDataSet__c dataSet : ppiTableDataSetList) {
            List<PPITableDataSet__c> dataSetsList =
                mapPpiTableIdToDataSetList.get(dataSet.PPITable__c);

            if (dataSetsList == null) {
                dataSetsList = new List<PPITableDataSet__c>();
                mapPpiTableIdToDataSetList.put(
                    dataSet.PPITable__c,
                    dataSetsList
                );
            }
            dataSetsList.add(dataSet);
        }
    }

    /**
     * Method to create a map with parent PpiTable's Id as key along with list of its
     * linked table lines
     */
    @TestVisible
    private static void setPpiTableIdToLinesMap(
            Set<Id> ppiTableIds,
            Map<Id, List<PPITableLine__c>> mapPpiTableIdToLines
    ) {
        for (PPITableLine__c ppiTableLine :
                new PpiTableLineSelector().getForPpiTableIds(ppiTableIds)
        ) {
            List<PPITableLine__c> tableLines =
                mapPpiTableIdToLines.get(ppiTableLine.PPITable__c);

            if (tableLines == null) {
                tableLines = new List<PPITableLine__c>();
                mapPpiTableIdToLines.put(
                    ppiTableLine.PPITable__c,
                    tableLines
                );
            }
            tableLines.add(ppiTableLine);
        }
    }

    /**
     * Method to create a map with parent SurveyVersion's Id as key along with list of its
     * linked table lines
     */
    @TestVisible
    private static void setSurveyVersionIdToLinesMap(
            List<PPITableDataSet__c> ppiTableDataSetList,
            Map<Id, List<PPITableLine__c>> mapPpiTableIdToLines,
            Map<Id, List<PPITableLine__c>> mapSurveyVersionIdtoTableLines
    ) {
        for (PPITableDataSet__c dataSet : ppiTableDataSetList) {
            List<PPITableLine__c> tableLines =
                mapSurveyVersionIdtoTableLines.get(dataSet.SurveyVersion__c);

            if (tableLines == null) {
                tableLines = new List<PPITableLine__c>();
                mapSurveyVersionIdtoTableLines.put(
                    dataSet.SurveyVersion__c,
                    tableLines
                );
            }
            tableLines.addAll(mapPpiTableIdToLines.get(dataSet.PPITable__c));
        }
    }

    /**
     * Method to calculate probabilities and create Submission Ppi data accordingly
     */
    @TestVisible
    private static List<SubmissionPpiAssociation__c> calculateProbabilities(
            PpiResult__c ppiResult,
            List<PPITableLine__c> ppiTableLines
    ) {
        List<SubmissionPpiAssociation__c> submissionPpiDataList =
            new List<SubmissionPpiAssociation__c>();

        for (PPITableLine__c tableLine : ppiTableLines) {
            if (ppiResult.Ppiscore__c >= tableLine.From__c &&
                    ppiResult.Ppiscore__c <= tableLine.To__c
            ) {
                submissionPpiDataList.add(
                    SubmissionPpiAssociationDomain.createRecord(
                        ppiResult,
                        tableLine
                    )
                );
            }
        }
        return submissionPpiDataList;
    }

    /**
     * Exception class for errors found in trigger handler
     */
    public class PpiResultTHException extends BaseException {
        public PpiResultTHException(String message, String[] args) {
            super(message, args);
        }
    }
}