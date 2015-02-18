/**
 * Service to retrieve and submit Ppi data to Parent Ppi Org
 * 
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
@RestResource(urlMapping='/ppiData/*')
global with sharing class PpiDataSubmission {

    /**
     * Method in charge of processing the requests
     */
    @HttpPost
    global static void processPostRequest() {
        PpiDataSubmissionService.processPpiResultsData();
    }
}