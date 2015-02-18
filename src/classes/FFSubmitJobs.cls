/**
 * Grameen: Field Force - Submit Job Service
 * Service to submit jobs and tasks
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Ernesto Quesada
 */
@RestResource(urlMapping='/jobs/*')
global with sharing class FFSubmitJobs {

    /**
     * Method in charge of processing the requests
     */
    @HttpPost
    global static void processJobSubmission() {
        FFSubmitJobsLogic.processPostRequest();
    }
}
