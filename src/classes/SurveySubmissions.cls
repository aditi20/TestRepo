/**
 * REST Resource for submitting surveys.
 * This class replaces the now deprecated /submission/ endpoint found in SurveySubmissionService.cls
 * The test code for this is in SurveySubmissionServiceTest.cls
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@RestResource(urlMapping='/surveysubmission/*')
global with sharing class SurveySubmissions {

    /**
     * POST endpoint
     */
    @HttpPost
    global static void processSubmission() {
        SurveySubmissionServiceLogic.processSubmission();
    }
}