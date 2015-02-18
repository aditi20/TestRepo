/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@RestResource(urlMapping='/getRemoteSurvey')
global class SurveyDistribution {

    @HttpGet
    global static void doGet() {
        SurveyDistributionLogic.processGetRequest();
    }
}