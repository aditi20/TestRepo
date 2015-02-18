/**
 * Service layer to implement logic for Ppi data to send to Parent Ppi org
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved.
 *
 * @author - Kaushik Ray
 */
public with sharing class SendPpiDataService {

    /**
     * Main method that will initiate processing of Ppi data to send
     */
    public static List<PpiDataSubmissionService.PpiDataResponse> processPpiDataToSend(
            Set<Id> ppiIdList
    ) {

        PpiDataWrapper ppiDataWrapperInstance =
            populatePpiDataWrapper(
                populatePpiResultDetailWrapper(
                    new PpiResultSelector().getAllWithSyncFalse(ppiIdList)
                )
            );

        HttpResponse response;

        // Set up mock response based on test data created to test web service
        if (Test.isRunningTest()) {
            response = createMockResponse(ppiDataWrapperInstance);
        } else {
            response = getSerializedPpiData(ppiDataWrapperInstance);
        }

        // If error, then pass it to batch class
        if (response.getStatusCode() != C.HTTP_OK) {
            throw new SendPpiDataServiceException(response.getBody());
        }
        return parsePpiResultResponse(response);
    }

    /**
     * Method to create dummy response to be used in test class response creation
     */
    private static HttpResponse createMockResponse(PpiDataWrapper ppiDataWrapperInstance) {
        SendPpiDataServiceTest.MockHttpResponseGenerator mockGenerator =
            new SendPpiDataServiceTest.MockHttpResponseGenerator();

        // Select the test Ppi result record created in test method
        List<PpiResult__c> ppiResultsTestDataList =
            new PpiResultSelector().runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
        if (ppiResultsTestDataList != null && !ppiResultsTestDataList.isEmpty()) {
            mockGenerator.ppiResultId = ppiResultsTestDataList[0].Id;
        }
        return mockGenerator.respond(buildPpiRequest(ppiDataWrapperInstance));
    }

    /**
     * Method to parse response and accordingly update Ppi result records
     */
    @TestVisible
    private static List<PpiDataSubmissionService.PpiDataResponse> parsePpiResultResponse(
            HttpResponse response
    ) {
        PpiDataSubmissionService.PpiDataResponses ppiDataResponses =
            (PpiDataSubmissionService.PpiDataResponses)
                JSON.deserialize(
                    response.getBody(),
                    PpiDataSubmissionService.PpiDataResponses.class
                );

        return processPpiResultResponse(ppiDataResponses);
    }

    /**
     * Method to perform actual processing of Ppi result records based on response received
     */
    @TestVisible
    private static List<PpiDataSubmissionService.PpiDataResponse> processPpiResultResponse(
            PpiDataSubmissionService.PpiDataResponses ppiDataResponses
    ) {
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

        updatePpiResultResponse(
            ppiResultDomainInstance,
            mapPpiDataResponse
        );

        return mapPpiDataResponse.values();
    }

    /**
     * Method to update Ppi result records and update them accordingly
     */
    @TestVisible
    private static void updatePpiResultResponse(
            PpiResultDomain ppiResultDomainInstance,
            Map<Id, PpiDataSubmissionService.PpiDataResponse> mapPpiDataResponse
    ) {
        for (
            PpiResult__c ppiResultInstance :
                (List<PpiResult__c>) ppiResultDomainInstance.records
        ) {
            ppiResultInstance.RetrievedByParent__c = true;
        }

        // Verify that all data update is successful. If not then accordingly update the wrapper
        List<Database.SaveResult> updateSaveResults = ppiResultDomainInstance.updateRecords(false);
        validatePpiResultUpdate(updateSaveResults, mapPpiDataResponse);
     }

    /**
     * Validate and update response based on any errors encountered
     */
    private static void validatePpiResultUpdate(
            List<Database.SaveResult> updateSaveResults,
            Map<Id, PpiDataSubmissionService.PpiDataResponse> mapPpiDataResponse
    ) {
        // Database.SaveResult always keeps the sequence in which list was updated / inserted
        // On failure SaveResult.getId() returns null, so need initial list to get record id
        for (Integer count = 0; count < updateSaveResults.size(); count++) {
            if (!updateSaveResults[count].isSuccess()) {
                PpiDataSubmissionService.PpiDataResponse failedPpiResult =
                    mapPpiDataResponse.values().get(count);

                failedPpiResult.errorList = new List<ErrorHandlingRest.ErrorMessage>();
                List<ErrorHandlingRest.ErrorMessage> errorDetailsList =
                    new List<ErrorHandlingRest.ErrorMessage>();
                for (Database.Error error : updateSaveResults[count].getErrors()) {
                    errorDetailsList.add(new ErrorHandlingRest.ErrorMessage(
                        String.valueOf(error.getStatusCode()),
                        ErrorHandlingRest.GENERAL_ERROR,
                        error.getMessage()
                    ));
                }
                failedPpiResult.errorList.addAll(errorDetailsList);
            }
        }
    }

    /**
     * Method to send serialized Ppi related data to Parent Ppi org.
     * This will use web service to send required data
     */
    @TestVisible
    private static HttpResponse getSerializedPpiData(PpiDataWrapper ppiDataWrapperInstance) {
        Http http = new Http();
        return http.send(buildPpiRequest(ppiDataWrapperInstance));
    }

    /**
     * Build request for HTTP callout
     */
    @TestVisible
    private static HttpRequest buildPpiRequest(PpiDataWrapper ppiDataWrapperInstance) {
        HttpRequest request = new HttpRequest();
        request.setMethod(C.POST_REQUEST_METHOD);
        request.setHeader(C.CONTENT_TYPE_HEADER, C.CONTENT_TYPE_JSON_UTF);
        List<SurveyLibrary__c> surveyLibraryList =
            new SurveyLibrarySelector().getRecordsByName(C.GRAMEEN_LIBRARY);
        if (surveyLibraryList != null && !surveyLibraryList.isEmpty()) {
            request.setEndpoint(surveyLibraryList[0].PpiResultsEndpoint__c);
            String ppiResultJSON = JSON.serialize(ppiDataWrapperInstance);
            request.setBody(ppiResultJSON);
            request.setTimeout(120000);
        } else {
            throw new SendPpiDataServiceException('Survey Library not present. Please verify.');
        }
        return request;
    }

    /**
     * Method to populate PpiDataWrapper based on PpiResultDetailWrapper list 
     */
    @TestVisible
    private static PpiDataWrapper populatePpiDataWrapper(
            List<PpiResultDetailWrapper> ppiResultDetailWrapperList
    ) {
        List<Organization> organizationList = new OrganizationSelector().getDefault();
        if (organizationList == null || organizationList.isEmpty()) {
            throw new SendPpiDataServiceException('No Organization related records present. Please verify');
        }
        return new PpiDataWrapper(organizationList[0].Name, organizationList[0].Id, ppiResultDetailWrapperList);
    }

    /**
     * Method to populate PpiResultDetailWrapper based on Ppi result records
     */
    @TestVisible
    private static List<PpiResultDetailWrapper> populatePpiResultDetailWrapper(
            List<PpiResult__c> ppiResultsToProcess
    ) {
        List<PpiResultDetailWrapper> ppiResultDetailWrapperList =
            new List<PpiResultDetailWrapper>();
        for (PpiResult__c ppiResultInstance : ppiResultsToProcess) {
            ppiResultDetailWrapperList.add(
                new PpiResultDetailWrapper(
                    ppiResultInstance,
                    ppiResultInstance.PpiTemplate__r.Survey__r.PpiIdentifier__c
                )
            );
        }
        return ppiResultDetailWrapperList;
    }

    /**
     * Inner wrapper to populate final ppi data to send
     */
    public class PpiDataWrapper {
        public String organizationName {get; set;}
        public String organizationId {get; set;}
        public List<PpiResultDetailWrapper> ppiresultList {get; set;}

        public PpiDataWrapper(
            String organizationName,
            String organizationId,
            List<PpiResultDetailWrapper> ppiresultList
        ) {
            this.organizationName = organizationName;
            this.organizationId = organizationId;
            this.ppiresultList = ppiresultList;
        }
    }

    /**
     * Inner wrapper to populate Ppi results along with Ppi identifier
     */
    public class PpiResultDetailWrapper {
        public PpiResult__c ppiResult {get; set;}
        public String ppiIdentifier {get; set;}

        public PpiResultDetailWrapper(PpiResult__c ppiResult, String ppiIdentifier) {
            this.ppiResult = ppiResult;
            this.ppiIdentifier = ppiIdentifier;
        }
    }

    /**
     * Exception class for errors found in Service layer
     */
    public class SendPpiDataServiceException extends BaseException {
        public SendPpiDataServiceException(String message, String[] args) {
            super(message, args);
        }
    }
}