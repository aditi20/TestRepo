/**
 * Contains the logic for PpiDataSubmission REST Resource.
 * Deals with
 *   - Parsing of child Ppi org data and creating new PpiResult records
 *     along with duplicate check on Parent org.
 *   - Calculate probabilities and create Ppi Submission data accordingly
 *   - Send response back to child org based on success or failure of data insertion
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class PpiDataSubmissionService {

    public static String organizationName;
    public static Map<String, Survey__c> mapSurveyIdToInstance;
    public static Map<String, PpiResult__c> mapUniqueKeyToPpiResult;

    /**
     * Process the request
     */
    public static void processPpiResultsData() {
        PpiDataResponses responses = new PpiDataResponses();
        mapSurveyIdToInstance = new Map<String, Survey__c>();
        mapUniqueKeyToPpiResult = new Map<String, PpiResult__c>();
        organizationName = '';

        // Create Savepoint to be able to rollback all the database changes if needed
        Savepoint sp = Database.setSavepoint();
        try {
            responses = processPpiData(RestContext.request.requestBody.toString());
        } catch (DMLException dmlException) {
            Database.rollback(sp);
            if (ErrorHandlingRest.parseDmlException(dmlException)) {
                ErrorHandlingRest.addErrorMsg(
                    ErrorHandlingRest.DML_EXCEPTION,
                    ErrorHandlingRest.GENERAL_ERROR,
                    dmlException.getMessage()
                );
                ErrorHandlingRest.setStatusCode(C.HTTP_INTERNAL_SERVER_ERROR);
            }
        } catch (Exception generalException) {
            Database.rollback(sp);
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.GENERAL_EXCEPTION,
                ErrorHandlingRest.GENERAL_ERROR,
                generalException.getMessage()
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_INTERNAL_SERVER_ERROR);
        }

        RestContext.response.statusCode = ErrorHandlingRest.getStatusCode();
        if (ErrorHandlingRest.checkForErrors()) {
            RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, C.CONTENT_TYPE_JSON_UTF);
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
        } else {
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responses));
        }
    }

    /**
     * Process PpiResult records to insert them in the database.
     *
     * @param requestString - A JSON String that represents the Ppi data that is retrieved
     *                        from child org
     * @return - A response wrapper that is sent back to child org
     */
    @TestVisible
    private static PpiDataResponses processPpiData(String requestString) {

        List<PpiDataResponse> ppiResponseList = new List<PpiDataResponse>();
        List<PpiResult__c> ppiResultListToInsert = new List<PpiResult__c>();

        SendPpiDataService.PpiDataWrapper ppiData =
            (SendPpiDataService.PpiDataWrapper) JSON.deserialize(
                requestString, SendPpiDataService.PpiDataWrapper.class
            );

        setParentSurveyMap(ppiData.ppiResultList);
        processDeserializedData(
            ppiData,
            ppiResultListToInsert,
            ppiResponseList
        );

        return
            processSavedPpiResult(
                savePpiResultData(ppiResultListToInsert),
                new PpiDataResponses(ppiResponseList)
            );
    }

    /**
     * Method to create a map with parent survey's Id as key along with its instance
     */
    @TestVisible
    private static void setParentSurveyMap(
            List<SendPpiDataService.PpiResultDetailWrapper> ppiResultDetailList
    ) {
        Set<String> surveyIds = fetchRemoteSurveyIdsFromReceivedData(ppiResultDetailList);

        if (surveyIds != null || !surveyIds.isEmpty()) {
            for (Survey__c surveyInstance : new SurveySelector().getWithSurveyVersion(surveyIds)) {
                mapSurveyIdToInstance.put(
                    StringBuilder.convertID(surveyInstance.Id),
                    surveyInstance
                );
            }
        } else {
            throw new PpiDataSubmissionServiceException(Label.ERR_SURVEY_REMOTE_ID_NOT_FOUND);
        }
    }

    /**
     * Method to fetch remote SurveyIds from child org's Ppi data sent to parent org
     */
    @TestVisible
    private static Set<String> fetchRemoteSurveyIdsFromReceivedData(
            List<SendPpiDataService.PpiResultDetailWrapper> ppiResultDetailList
    ) {
        Set<String> surveyIds = new Set<String>();
        for (SendPpiDataService.PpiResultDetailWrapper ppiResultDetail : ppiResultDetailList) {
            String surveyRemoteId =
                StringBuilder.convertID(
                    ppiResultDetail.ppiResult.PpiTemplate__r.Survey__r.RemoteId__c
                );
            if (surveyRemoteId != null) {
                surveyIds.add(surveyRemoteId);
            }
        }
        return surveyIds;
    }

    /**
     * Method to process deserialized data
     */
    @TestVisible
    private static void processDeserializedData(
            SendPpiDataService.PpiDataWrapper ppiData,
            List<PpiResult__c> ppiResultListToInsert,
            List<PpiDataResponse> ppiResponseList
    ) {
        for (SendPpiDataService.PpiResultDetailWrapper ppiResultDetail : ppiData.ppiResultList) {
            try {
                ppiResultListToInsert.add(createPpiResults(
                    ppiResultDetail.ppiResult,
                    ppiData
                ));
            } catch (PpiDataSubmissionServiceException serviceException) {
                // Add error to response list if any error found while PpiResult data creation
                // on Parent org
                ppiResponseList.add(
                    new PpiDataResponse(
                        false,
                        ppiResultDetail.ppiResult.Id,
                        new List<ErrorHandlingRest.ErrorMessage> {
                            new ErrorHandlingRest.ErrorMessage(
                                ErrorHandlingRest.INVALID_DATA,
                                ErrorHandlingRest.GENERAL_ERROR,
                                serviceException.getMessage()
                            )
                        }
                    )
                );
            }
        }
    }

    /**
     * Method to save PpiResults on parent org
     */
    @TestVisible
    private static Database.SaveResult[] savePpiResultData(
            List<PpiResult__c> ppiResultListToInsert
    ) {
        PpiResultTH.isMigration = true;
        PpiResultDomain ppiResultDomain =
            new PpiResultDomain.Constructor().constructWithRecords(ppiResultListToInsert);
        Database.SaveResult[] saveResultList = ppiResultDomain.insertRecords(false);
        return saveResultList;
    }

    /**
     * Method to process saved PpiResults on parent org to send response for each
     */
    @TestVisible
    private static PpiDataResponses processSavedPpiResult(
            Database.SaveResult[] saveResultList,
            PpiDataResponses responses
    ) {
        // Fetch PpiResult records from parent org database having uniqueKey
        List<PpiResult__c> ppiResultListWithUniqueKey =
            new PpiResultSelector().getForUniqueKey(mapUniqueKeyToPpiResult.keySet());

        for (Integer i = 0; i < saveResultList.size(); i++) {
            Database.SaveResult saveResultInstance = saveResultList[i];
            PpiDataResponse individualResponse;
            if (saveResultInstance.isSuccess()) {
                if (mapUniqueKeyToPpiResult.containsKey(ppiResultListWithUniqueKey[i].UniqueKey__c)) {
                    individualResponse = new PpiDataResponse(
                        true,
                        mapUniqueKeyToPpiResult.get(ppiResultListWithUniqueKey[i].UniqueKey__c).Id,
                        new List<ErrorHandlingRest.ErrorMessage>()
                    );
                 }
            } else {
                Boolean isSuccess = false;
                List<ErrorHandlingRest.ErrorMessage> errorList =
                    new List<ErrorHandlingRest.ErrorMessage>();
                for (Database.Error error : saveResultInstance.getErrors()) {
                    if (String.valueOf(error.getStatusCode()) == ErrorHandlingRest.DUPLICATE_VALUE) {
                        isSuccess = true;
                    }
                    errorList.add(new ErrorHandlingRest.ErrorMessage(
                        String.valueOf(error.getStatusCode()),
                        ErrorHandlingRest.GENERAL_ERROR,
                        error.getMessage()
                    ));
                }
                if (mapUniqueKeyToPpiResult.containsKey(ppiResultListWithUniqueKey[i].UniqueKey__c)) {
                    individualResponse = new PpiDataResponse(
                        isSuccess,
                        mapUniqueKeyToPpiResult.get(ppiResultListWithUniqueKey[i].UniqueKey__c).Id,
                        errorList
                    );
                }
            }
            responses.ppiDataResponseList.add(individualResponse);
        }
        return responses;
    }

    /**
     * Method to create Ppi Result record on Parent org
     */
    @TestVisible
    private static PpiResult__c createPpiResults(
            PpiResult__c ppiResult,
            SendPpiDataService.PpiDataWrapper ppiData
    ) {
        PpiResult__c newPpiResultInstance = new PpiResult__c();
        Map<Integer, String> ppiResultSequenceOptionRemoteIds = new Map<Integer, String>();
        try {
            String ppiIdentifier = '';
            organizationName = ppiData.organizationName;
            List<SurveyVersion__c> surveyVersionList = new List<SurveyVersion__c>();
            String surveyRemoteId =
                StringBuilder.convertID(ppiResult.PpiTemplate__r.Survey__r.RemoteId__c);

            if (String.isBlank(surveyRemoteId)) {
                throw
                    new PpiDataSubmissionServiceException(
                        Label.ERR_SURVEY_REMOTE_ID_NOT_SENT
                    );
            }

            if (mapSurveyIdToInstance.containsKey(surveyRemoteId)) {
                Survey__c surveyInstance = mapSurveyIdToInstance.get(surveyRemoteId);
                ppiIdentifier = surveyInstance.PpiIdentifier__c;
                if (!surveyInstance.SurveyVersions__r.isEmpty()) {
                    surveyVersionList = surveyInstance.SurveyVersions__r;
                }
            } else {
                throw
                    new PpiDataSubmissionServiceException(
                        Label.ERR_SURVEY_NOT_FOUND_ON_PARENT
                    );
            }

            if (surveyVersionList.isEmpty()) {
                throw
                    new PpiDataSubmissionServiceException(
                        Label.ERR_SURVEYVERSION_NOT_FOUND_ON_PARENT
                    );
            }

            // Get ppiResult record's option remote Ids sent from child org along with its sequence
            ppiResultSequenceOptionRemoteIds =
                PpiResultDomain.populateSequenceOptionRemoteIdsMap(ppiResult);

            // Create encoded unique Identifier
            String encodedUniqueKey =
                PpiResultDomain.encodePpiUniqueKey(
                    PpiResultDomain.createPpiResultUniqueKey(
                        ppiResult,
                        ppiIdentifier,
                        ppiResultSequenceOptionRemoteIds
                    )
                );

            // Create a map with unique identifier as key along with child orgs Ppi Result instance
            mapUniqueKeyToPpiResult.put(encodedUniqueKey, ppiResult);

            newPpiResultInstance =
                PpiResultDomain.createRecord(
                    ppiResultSequenceOptionRemoteIds,
                    ppiResult.ClientId__c,
                    ppiResult.Gender__c,
                    ppiResult.HouseholdSize__c,
                    ppiResult.JoinedDate__c,
                    ppiResult.Age__c,
                    populateGeolocationString(ppiResult),
                    ppiData.organizationName,
                    surveyVersionList[0].Id,
                    null,
                    ppiResult.PpiCollectionDate__c
                );
        } catch (Exception e) {
            throw new PpiDataSubmissionServiceException(e.getMessage());
        }
        return newPpiResultInstance;
    }

    /**
     * Method to populate Geolocation string from latitude and lngitude fields
     */
    @TestVisible
    private static String populateGeolocationString(PpiResult__c ppiResult) {
        String geoLocationString = '';

        if (ppiResult.GeoLocation__Latitude__s != null && ppiResult.GeoLocation__Longitude__s != null) {
            geoLocationString =
                ppiResult.GeoLocation__Latitude__s.setScale(6) + ' ' +
                ppiResult.GeoLocation__Longitude__s.setScale(6) + ' 0.0 0.0';
        }

        return geoLocationString;
    }

    /**
     * Method to populate 18 digit Id
     */
    public static String convertID(String idValue) {
        if (idValue == null || String.isEmpty(idValue) || idValue.length() == 18) {
            return idValue;
        }

        return  String.valueOf(Id.valueOf(idValue));
    }

    /**
     * Class used to help with the JSON serialization of the response list
     */
    public class PpiDataResponses {

        public List<PpiDataResponse> ppiDataResponseList;

        public PpiDataResponses() {
            this.ppiDataResponseList = new List<PpiDataResponse>();
        }

        public PpiDataResponses(List<PpiDataResponse> ppiDataResponseList) {
            this.ppiDataResponseList = ppiDataResponseList;
        }
    }

    /**
     * Class used to help with JSON serialisation of the response for an
     * individual Ppi Result data
     */
    public class PpiDataResponse {
        public Boolean success;
        public String ppiResultId;
        public List<ErrorHandlingRest.ErrorMessage> errorList;

        public PpiDataResponse(
                Boolean success,
                String ppiResultId,
                List<ErrorHandlingRest.ErrorMessage> errorList
        ) {
            this.success = success;
            this.ppiResultId = ppiResultId;
            this.errorList = errorList;
        }
    }

    /**
     * Exception class for errors found in Service layer
     */
    public class PpiDataSubmissionServiceException extends BaseException {
        public PpiDataSubmissionServiceException(String message, String[] args) {
            super(message, args);
        }
    }
}