/**
 * Contains the logic for the SurveyDistribution REST Resource.
 * This is moved into its own class as it is not possible to patch classes 
 * in a managed package that is marked as @RestResource
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public with sharing class SurveyDistributionLogic {

    /**
     * Process the request.
     * If no id passed in return the list of templates and surveys available
     * If id present then return that template/survey
     */
    public static void processGetRequest() {

        String surveyVersionId = RestContext.request.params.get('id');

        List<String> responseList;
        try {
            if (surveyVersionId == null || surveyVersionId.equals('')) {
                responseList = getAllSurveys();
            } else {

                // Id provided so return that survey
                responseList = getSurvey(surveyVersionId);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Remote Survey Download Error with id: . ' + e.getMessage());
            responseList = new List<String>{ String.valueOf(C.HTTP_INTERNAL_SERVER_ERROR ), '' };
        }
        RestContext.response.addHeader('Content-Type', 'text/plain');
        RestContext.response.responseBody = Blob.valueOf(responseList[1]);
        RestContext.response.statusCode = Integer.valueOf(responseList[0]);
    }

    /**
     * Create a JSON string that represents all the surveys that are published
     *
     * @return - A list that that represents the response
     *              Element 1 = response code
     *              Element 2 = The Json to return that represents the surveys
     */
    private static List<String> getAllSurveys() {
        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<String> {
                'DistributionDate__c',
                'Distributed__c'
            }
        );
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(
            new List<String> {
                'IsPPI__c',
                'IsTemplate__c',
                'Name',
                'Description__c',
                'Version__c'
            }
        );

        // Check the type of form to be displayed
        String typeClause = '';
        String formType = RestContext.request.params.get(C.FORM_TYPE);
        if (formType.equals(C.FORM_TYPE_PPI)) {
            typeClause = 'AND (Survey__r.IsPPI__c = true AND Survey__r.IsTemplate__c = true) ';
        } else if (formType.equals(C.FORM_TYPE_TEMP)) {
            typeClause = 'AND Survey__r.IsTemplate__c = true AND Survey__r.IsPPI__c = false ';
        } else {
            typeClause = 'AND Survey__r.IsTemplate__c = false ';
        }

        // Get all the surveys that are on the system
        String query =
            'SELECT ' +
                'Id, ' +
                'Survey__c, ' +
                'Survey__r.Name, ' +
                'Survey__r.Description__c, ' +
                'Survey__r.Version__c, ' +
                'Survey__r.CreatedDate, ' +
                'Survey__r.LastModifiedDate, ' +
                'Survey__r.CreatedBy.Name ' +
            'FROM ' +
                'SurveyVersion__c ' +
            'WHERE ' +
                'Distributed__c = true ' +
                typeClause +
            'ORDER BY ' +
                'Survey__r.Name, ' +
                'Version__c ASC';
        SurveyVersion__c [] surveyVersions = Database.query(query);

        // Check that any surveys were found
        if (surveyVersions.isEmpty()) {

            // No surveys found so return an empty string
            return new List<String>{ String.valueOf(C.HTTP_NOT_FOUND), '' };
        }

        // Loop through the list to pull out the most recent version of the survey
        Map<String, SurveyVersion__c> versionMap = new Map<String, SurveyVersion__c>();
        for (SurveyVersion__c version : surveyVersions) {
            versionMap.put(version.Survey__r.Name, version);
        }

        // Generate the JSON string for the surveys found
        return new List<String>{ String.valueOf(C.HTTP_OK), '{"results" : ' + JSON.serialize(versionMap.values()) + '}' };
    }

    /**
     * Get the JSON string that represents the survey being requested
     *
     * @param id - The id for the survey version that is being downloaded
     *
     * @return - A list that that represents the response
     *              Element 1 = response code
     *              Element 2 = The Json to return that represents the survey
     */
    public static List<String> getSurvey(String id) {

        // Fetch the attachment from the survey version
        SurveyUtils util = new SurveyUtils();
        Attachment att = util.getJsonFile(id);
        if (att == null || att.body == null) {
            return new List<String>{ String.valueOf(C.HTTP_NO_CONTENT), '' };
        }

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Status__c,
                SurveyVersion__c.Distributed__c
            }
        );

        // Load the version to check that it is still available
        SurveyVersion__c[] version = [
            SELECT
                Status__c,
                Distributed__c
            FROM
                SurveyVersion__c
            WHERE
                Id = :id
        ];
        if (!version[0].Distributed__c || (!version[0].Status__c.equals(SurveyDO.STATUS_PUBLISHED) && isSurvey())) {
            return new List<String>{ String.valueOf(C.HTTP_NOT_FOUND), '' };
        }

        return  new List<String>{ String.valueOf(C.HTTP_OK), '{"results" : ' + att.Body.toString() + '}' };
    }

    // Check to see if this is a survey that is being downloaded
    private static Boolean isSurvey() {

        Boolean success = true;
        if (
            RestContext.request.params.get(C.FORM_TYPE).equals(C.FORM_TYPE_PPI)
            || RestContext.request.params.get(C.FORM_TYPE).equals(C.FORM_TYPE_TEMP)
        ) {
            success = false;
        }
        return success;
    }
}