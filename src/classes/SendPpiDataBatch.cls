/**
 * This batch will be called from scheduled job to process all data to be sent to parent Ppi org.
 * Deals with - 
 *      Get all necessary data to be sent to Ppi parent org, JSON serialize same to send it.
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved.
 *
 * @author - Kaushik Ray
 */
global with sharing class SendPpiDataBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    global List<PpiDataSubmissionService.PpiDataResponse> ppiDataResponseListFinal;
    global final String query;

    /**
     * Batch constructor to assign query
     */
    global SendPpiDataBatch(String queryToExecute) {
        // Batch Constructor
        this.query = queryToExecute;
        this.ppiDataResponseListFinal = new List<PpiDataSubmissionService.PpiDataResponse>();
    }

    /**
     * Start method of batch to return all Ppi result records
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }

    /**
     * Execute method will call Service layer to process Ppi result records.
     * Send data to parent Ppi org and process results.
     */
    global void execute(Database.BatchableContext BC, List<sObject> ppiResultsToProcess) {
        // TODO - Error handling as part of IDALMSA-5802. Errors in PpiDataResponseListFinal
        // Batch can be time taking process and so passing Ids to Service layer,
        // So that latest records can be retreived and processed
        ppiDataResponseListFinal.addAll(
            SendPpiDataService.processPpiDataToSend(
                new Map<Id,SObject>(ppiResultsToProcess).keySet()
            )
        );
    }

    /**
     * Finish method of batch process.
     */
    global void finish(Database.BatchableContext BC) {
        // TODO - send error details to be covered in 5802 
        sendFailedProcessingDetails(ppiDataResponseListFinal);
    }

    /**
     * Process all error message for all batches and send email for same
     */
    private void sendFailedProcessingDetails(
            List<PpiDataSubmissionService.PpiDataResponse> ppiDataResponseListFinal
    ) {
        // TODO - send error details to be covered in 5802
    }
}