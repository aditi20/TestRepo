/**
 * This class contains unit tests for validating the behavior of SendPpiDataService class
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved.
 *
 * @author Kaushik Ray
 */
@isTest
public with sharing class SendPpiDataServiceTest {

    /**
     * Testdata for PpiResult object
     */
    public static List<PpiResult__c> createTestData() {
        List<PpiResult__c> ppiResultList =
            PpiResultDomainTest.createSamplePpiResultData(1, false);
        SurveyLibraryDomainTest.addLibraryToDatabase(C.GRAMEEN_LIBRARY);
        return ppiResultList;
    }

    /**
     * Test method for checking the processing of ppi data sent to a callout
     */
    public static testMethod void testProcessPpiDataToSend() {

        List<PpiResult__c> ppiResultList = createTestData();
        List<PpiDataSubmissionService.PpiDataResponse> responses ;
        Set<Id> ppiResultIds = new Set<Id>();
        for(Integer i=0; i<ppiResultList.size(); i++ ){
            ppiResultIds.add(ppiResultList[i].Id);
        }
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        responses = SendPpiDataService.processPpiDataToSend(ppiResultIds);
        Test.stopTest();

        System.assert(responses != null, 'No reponse returned from callout');
    }

    /**
     * Test method for verifying PpiResultDetailWrapper data for specified PpiResult
     */
    static testMethod void testPpiResultDetailWrapper() {
        List<PpiResult__c> ppiResultList = createTestData();

        Test.startTest();
        List<SendPpiDataService.PpiResultDetailWrapper> ppiResultDetailWrapper =
            SendPpiDataService.populatePpiResultDetailWrapper(
                ppiResultList
            );
        Test.stopTest();

        System.assert(
            ppiResultDetailWrapper.size() == 1,
            'No records found in PpiResultDetailWrapper.'
        );
    }

    /**
     * Test method for verifying PpiDataWrapper data for specified PpiResultDetailWrapper
     */
    static testMethod void testPpiDataWrapper() {
        List<PpiResult__c> ppiResultList = createTestData();
        List<SendPpiDataService.PpiResultDetailWrapper> ppiResultDetailWrapper = 
            SendPpiDataService.populatePpiResultDetailWrapper(
                ppiResultList
            );

        Test.startTest();
        SendPpiDataService.PpiDataWrapper ppiDataWrapper = 
            SendPpiDataService.populatePpiDataWrapper(ppiResultDetailWrapper);
        Test.stopTest();

        System.assert(ppiDataWrapper != null, 'No records found in PpiDataWrapper.');
    }

    /**
     * Test method to verify Request parameter
     */
    static testMethod void testBuildPpiRequest() {
        List<PpiResult__c> ppiResultList = createTestData();
        List<SendPpiDataService.PpiResultDetailWrapper> ppiResultDetailWrapper = 
            SendPpiDataService.populatePpiResultDetailWrapper(
                ppiResultList
            );
        SendPpiDataService.PpiDataWrapper ppiDataWrapper = 
            SendPpiDataService.populatePpiDataWrapper(ppiResultDetailWrapper);

        Test.startTest();
        HttpRequest request = SendPpiDataService.buildPpiRequest(ppiDataWrapper);
        Test.stopTest();

        System.assert(request != null, 'Request data could not be set.');
    }

    /**
     * Test method to invoke callout
     */
    static testMethod void testGetSerializedPpiData() {
        List<PpiResult__c> ppiResultList = createTestData();
        List<SendPpiDataService.PpiResultDetailWrapper> ppiResultDetailWrapper = 
            SendPpiDataService.populatePpiResultDetailWrapper(
                ppiResultList
            );
        SendPpiDataService.PpiDataWrapper ppiDataWrapper = 
            SendPpiDataService.populatePpiDataWrapper(ppiResultDetailWrapper);
        HttpRequest request = SendPpiDataService.buildPpiRequest(ppiDataWrapper);
        HttpResponse response;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        response = SendPpiDataService.getSerializedPpiData(ppiDataWrapper);
        Test.stopTest();

        System.assert(response != null, 'Response data could not be generated.');
    }

    /**
     * Test method to verify parsing of response generated from callout
     */
    static testMethod void testParsePpiResultResponse() {
        List<PpiResult__c> ppiResultList = createTestData();
        System.assertEquals(1, ppiResultList.size());
        List<SendPpiDataService.PpiResultDetailWrapper> ppiResultDetailWrapper = 
            SendPpiDataService.populatePpiResultDetailWrapper(
                ppiResultList
            );
        SendPpiDataService.PpiDataWrapper ppiDataWrapper = 
            SendPpiDataService.populatePpiDataWrapper(ppiResultDetailWrapper);
        HttpRequest request = SendPpiDataService.buildPpiRequest(ppiDataWrapper);
        List<PpiDataSubmissionService.PpiDataResponse> parsedResponse;

        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator();
        mockResponse.ppiResultId = ppiResultList[0].Id;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockResponse);
        HttpResponse response = SendPpiDataService.getSerializedPpiData(ppiDataWrapper);
        parsedResponse = SendPpiDataService.parsePpiResultResponse(response);
        Test.stopTest();

        System.assert(parsedResponse != null, 'Could not parse the generated response.');
    }

    /**
     * Test method to verify processing of Ppi result records based on response received
     */
    static testMethod void testProcessPpiResultResponse() {
        List<PpiResult__c> ppiResultList = createTestData();
        System.assertEquals(1, ppiResultList.size());

        List<SendPpiDataService.PpiResultDetailWrapper> ppiResultDetailWrapper = 
            SendPpiDataService.populatePpiResultDetailWrapper(
                ppiResultList
            );
        SendPpiDataService.PpiDataWrapper ppiDataWrapper = 
            SendPpiDataService.populatePpiDataWrapper(ppiResultDetailWrapper);
        HttpRequest request = SendPpiDataService.buildPpiRequest(ppiDataWrapper);
        List<PpiDataSubmissionService.PpiDataResponse> processedResponse;

        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator();
        mockResponse.ppiResultId = ppiResultList[0].Id;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockResponse);
        HttpResponse response = SendPpiDataService.getSerializedPpiData(ppiDataWrapper);
        PpiDataSubmissionService.PpiDataResponses ppiDataResponses =
            (PpiDataSubmissionService.PpiDataResponses)
                JSON.deserialize(
                    response.getBody(),
                    PpiDataSubmissionService.PpiDataResponses.class
                );
        processedResponse = SendPpiDataService.processPpiResultResponse(ppiDataResponses);
        Test.stopTest();

        System.assert(processedResponse != null, 'Could not process the generated response.');
    }

    /**
     * Test method to verify update in case of error
     */
    static testMethod void testUpdatePpiResultResponse() {
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }

        List<PpiResult__c> ppiResultList = createTestData();
        System.assertEquals(1, ppiResultList.size());

        List<SendPpiDataService.PpiResultDetailWrapper> ppiResultDetailWrapper = 
            SendPpiDataService.populatePpiResultDetailWrapper(
                ppiResultList
            );
        SendPpiDataService.PpiDataWrapper ppiDataWrapper = 
            SendPpiDataService.populatePpiDataWrapper(ppiResultDetailWrapper);
        HttpRequest request = SendPpiDataService.buildPpiRequest(ppiDataWrapper);
        List<PpiDataSubmissionService.PpiDataResponse> processedResponse;

        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator();
        mockResponse.ppiResultId = ppiResultList[0].Id;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockResponse);
        HttpResponse response = SendPpiDataService.getSerializedPpiData(ppiDataWrapper);
        PpiDataSubmissionService.PpiDataResponses ppiDataResponses =
            (PpiDataSubmissionService.PpiDataResponses)
                JSON.deserialize(
                    response.getBody(),
                    PpiDataSubmissionService.PpiDataResponses.class
                );
        List<Id> successPpiResultIdList = new List<Id>();

        // Map that will be used for processing error related details
        Map<Id, PpiDataSubmissionService.PpiDataResponse> mapPpiDataResponse =
            new Map<Id, PpiDataSubmissionService.PpiDataResponse>();
        for (
            PpiDataSubmissionService.PpiDataResponse ppiDataResponseInstance :
                ppiDataResponses.ppiDataResponseList
        ) {
            mapPpiDataResponse.put(ppiDataResponseInstance.ppiResultId, ppiDataResponseInstance);
            if (ppiDataResponseInstance.success) {
                successPpiResultIdList.add(ppiDataResponseInstance.ppiResultId);
            }
        }

        List<PpiResult__c> successPpiResultRecords =
            (List<PpiResult__c>)
                new PpiResultSelector().getRecordsById(new Set<Id>(successPpiResultIdList));
        PpiResultDomain ppiResultDomainInstance =
            new PpiResultDomain.Constructor().constructWithRecords(successPpiResultRecords);

        for (PpiResult__c ppiResult : (List<PpiResult__c>) ppiResultDomainInstance.records) {
            ppiResult.Age__c  = 1000;
        }

        System.runAs(chatterExternalUser) {
            SendPpiDataService.updatePpiResultResponse(ppiResultDomainInstance, mapPpiDataResponse);
        }
        Test.stopTest();

        List<PpiResult__c> successPpiResultRecordsNew =
            (List<PpiResult__c>)
                new PpiResultSelector().getRecordsById(new Set<Id>(successPpiResultIdList));

        System.assertEquals(1, successPpiResultRecordsNew.size());
        System.assertEquals(false, successPpiResultRecordsNew[0].RetrievedByParent__c);
    }

    /**
     * Inner class to generate mock web service response
     */
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public Id ppiResultId {get; set;}
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            System.assertEquals(
                SurveyLibraryDomainTest.PPI_ENDPOINT,
                request.getEndpoint()
            );
            System.assertEquals(C.POST_REQUEST_METHOD, request.getMethod());
            response.setStatusCode(200);
            response.setBody(
                '{"ppiDataResponseList":[{"success":true,"ppiResultId":"' +
                this.ppiResultId +
                '","errorList":[]}]}'
            );
            return response;
        }
    }
}