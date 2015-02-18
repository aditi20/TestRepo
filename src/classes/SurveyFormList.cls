/**
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *  Wrapper class to get the form list in a rest context
 *
 * @author Sebastian Piazza
 */
@RestResource(urlMapping='/formList')
global class SurveyFormList {


    /**
     * Method retrieve the form list in a rest context
     */
    @HttpGet
    global static void doGet() {
        SurveyFormListLogic.processGetRequest();
    }
}
