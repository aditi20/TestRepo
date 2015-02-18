/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@RestResource(urlMapping='/submission/*')
global with sharing class SurveySubmissionService {

    @HttpPost
    global static String processSubmission() {
        RestContext.response.statusCode = C.HTTP_NOT_FOUND;
        return '';
    }
}