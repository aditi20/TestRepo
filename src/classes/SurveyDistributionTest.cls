/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public class SurveyDistributionTest {

    static void setUpRequest(String id) {
        RestRequest req = new RestRequest();
        req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/getRemoteSurvey';
        if (id != null) {
            req.params.put('id', id);
        }
        req.params.put(C.FORM_TYPE, '');
        req.httpMethod = 'GET';
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;
    }

    static List<Survey__c> generateSurveys(Integer numberOfSurveys) {

        List<Survey__c> surveys = new List<Survey__c>();
        for (Integer i = 0; i < numberOfSurveys; i++) {
            surveys.add( new Survey__c( Name = 'Test Survey ' + String.valueOf(i), Description__c  = 'This is a description', Version__c = 1.0));
        }
        return surveys;
    }

    // Expect a 204 error as no surveys are available
    static testMethod void testGetSurveyEmptyList() {

        setUpRequest(null);
        Test.startTest();
            SurveyDistribution.doGet();
        Test.stopTest();
        System.assertEquals(C.HTTP_NOT_FOUND, RestContext.response.statusCode);
    }

    // Expect to get a 200 response and also one surveyversion
    static testMethod void testGetSurveyList(){

        List<Survey__c> surveys = generateSurveys(3);
        Database.insert(surveys);

        // Only publish two of the surveys but only distriute 1
        SurveyVersion__c v1 = new SurveyVersion__c( Distributed__c = true, Survey__c = surveys[0].Id, Status__c = SurveyDO.STATUS_PUBLISHED);
        SurveyVersion__c v2 = new SurveyVersion__c( Distributed__c = false, Survey__c = surveys[1].Id, Status__c = SurveyDO.STATUS_PUBLISHED);
        SurveyVersion__c v3 = new SurveyVersion__c( Distributed__c = false, Survey__c = surveys[2].Id, Status__c = SurveyDO.STATUS_DRAFT);
        Database.insert( new List<SurveyVersion__c> { v1, v2, v3 });

        setUpRequest(null);
        
        Test.startTest();
            SurveyDistribution.doGet();
        Test.stopTest();
        
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
        List<SurveyVersion__c> parsedVersions = new List<SurveyVersion__c>();
        JSONParser parser = JSON.createParser(RestContext.response.responseBody.toString());
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME
                && parser.getText().equals('results')
            ) {

                // Step past the name and the start of the array
                parser.nextToken();
                parser.nextToken();
                while (parser.getCurrentToken() != JSONToken.END_ARRAY) {
                    parsedVersions.add((SurveyVersion__c)parser.readValueAs(SurveyVersion__c.class));
                    parser.nextToken();
                }
            }
        }
        System.assertEquals(1, parsedVersions.size());
        System.assertEquals(v1.Name, parsedVersions[0].Name);
    }

    static testMethod void testGetSurveyNotThere() {

        setUpRequest('NOID');
        
        Test.startTest();
            SurveyDistribution.doGet();
        Test.stopTest();
        System.assertEquals(C.HTTP_NO_CONTENT, RestContext.response.statusCode);
    }

    static testMethod void testNotAvailableToDistribute() {


        List<Survey__c> surveys = generateSurveys(1);
        Database.insert(surveys);
        SurveyVersion__c v1 = new SurveyVersion__c( Distributed__c = true, Survey__c = surveys[0].Id, Status__c = SurveyDO.STATUS_PUBLISHED);
        Database.insert(v1);

        SurveyUtils util = new SurveyUtils();
        util.generateJsonFile(v1);
        setUpRequest(v1.Id);
        v1.Distributed__c = false;
        Database.update(v1);
        
        Test.startTest();
            SurveyDistribution.doGet();
        Test.stopTest();
        System.assertEquals(C.HTTP_NOT_FOUND, RestContext.response.statusCode);
    }

    static testMethod void testGetSurvey() {

        List<Survey__c> surveys = generateSurveys(1);
        Database.insert(surveys);
        SurveyVersion__c v1 = new SurveyVersion__c( Distributed__c = true, Survey__c = surveys[0].Id, Status__c = SurveyDO.STATUS_PUBLISHED);
        Database.insert(v1);

        SurveyUtils util = new SurveyUtils();
        util.generateJsonFile(v1);
        setUpRequest(v1.Id);
        
        Test.startTest();
            SurveyDistribution.doGet();
        Test.stopTest();
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        SurveyData data;
        JSONParser parser = JSON.createParser(RestContext.response.responseBody.toString());
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME
                && parser.getText().equals('results')
            ) {
                parser.nextToken();
                parser.nextToken();
                data = (SurveyData)parser.readValueAs(SurveyData.class);
            }
        }
        System.assertEquals(data.survey.Id, surveys[0].Id);
    }
}