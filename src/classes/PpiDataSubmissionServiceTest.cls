/**
 * Test class for the PpiDataSubmissionService
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
@isTest
public with sharing class PpiDataSubmissionServiceTest {

    public static List<PPITableLine__c> tableLines;
    public static SendPpiDataService.PpiDataWrapper ppiData;
    public static Set<Id> ppiResultIds;


    public static TestSurveyData parentSurvey;
    public static TestSurveyData childSurvey;
    public static Organization organizationInstance;

    /**
     * Test method for processing post request 
     */
    static testMethod void testProcessPostRequest() {
        setUpTestData();

        Test.startTest();
        PpiDataSubmissionService.processPpiResultsData();
        Test.stopTest();

        // Assert success
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
    }

    /**
     * Test method for processing valid Ppi data
     */
    static testMethod void testProcessPpiData() {
        PpiDataSubmissionService.mapSurveyIdToInstance =
            new Map<String, Survey__c>();
        PpiDataSubmissionService.mapUniqueKeyToPpiResult =
            new Map<String, PpiResult__c>();
        PpiDataSubmissionService.PpiDataResponses responses =
            new PpiDataSubmissionService.PpiDataResponses();

        setUpTestData();

        Test.startTest();
        responses = PpiDataSubmissionService.processPpiData(
            RestContext.request.requestBody.toString()
        );
        Test.stopTest();

        System.assertEquals(2, responses.ppiDataResponseList.size());
        System.assert(
            responses.ppiDataResponseList[0].success,
            'Data not processed properly'
        );
    }

    /**
     * Test method for fetching survey Remote Ids from Child org
     */
    static testMethod void testFetchRemoteSurveyIds() {
        setUpTestData();

        Test.startTest();
        Set<String> surveyIds =
            PpiDataSubmissionService.fetchRemoteSurveyIdsFromReceivedData(
                ppiData.ppiResultList
            );
        Test.stopTest();

        System.assertEquals(1, surveyIds.size());
    }

    /**
     * Test method for processing valid deserialized Ppi data
     */
    static testMethod void testProcessDeserializedPpiData() {
        PpiDataSubmissionService.mapSurveyIdToInstance =
            new Map<String, Survey__c>();
        PpiDataSubmissionService.mapUniqueKeyToPpiResult =
            new Map<String, PpiResult__c>();
        List<PpiDataSubmissionService.PpiDataResponse> ppiResponseList =
            new List<PpiDataSubmissionService.PpiDataResponse>();
        List<PpiResult__c> ppiResultListToInsert = new List<PpiResult__c>();
        setUpTestData();

        System.assertEquals(2, ppiData.ppiResultList.size());
        PpiDataSubmissionService.setParentSurveyMap(ppiData.ppiResultList);

        Test.startTest();
        PpiDataSubmissionService.processDeserializedData(
            ppiData,
            ppiResultListToInsert,
            ppiResponseList
        );
        Test.stopTest();

        System.assertEquals(2, ppiResultListToInsert.size());
    }

    /**
     * Test method for validating Id conversion
     */
    static testMethod void testIdConversion() {
        setUpTestData();

        String expectedSurveyId = String.valueOf(Id.valueOf(parentSurvey.testSurvey.Id));
        System.assertEquals(18, expectedSurveyId.length());

        Test.startTest();
        String actualConvertedId =
            StringBuilder.convertID(expectedSurveyId.subString(0, 15));
        Test.stopTest();

        System.assertEquals(expectedSurveyId, actualConvertedId);
    }

    /**
     * Test method for validating populate for Geolocation String
     */
    static testMethod void testPopulateGeolocationString() {
        setUpTestData();

        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(ppiResultIds, false);

        System.assertEquals(2, ppiResultList.size());

        Test.startTest();
        String actualGeoLocationString =
            PpiDataSubmissionService.populateGeolocationString(ppiResultList[0]);
        Test.stopTest();

        String expectedGeoLocationString = ppiResultList[0].GeoLocation__Latitude__s
            + ' ' + ppiResultList[0].GeoLocation__Longitude__s + ' 0.0 0.0';
 
        System.assertEquals(
            expectedGeoLocationString,
            actualGeoLocationString
        );
    }

    /**
     * Test method for validating PpiResultCreation
     */
    static testMethod void testPpiResultRecordCreation() {
        setUpTestData();

        PpiDataSubmissionService.mapSurveyIdToInstance = new Map<String, Survey__c>();
        PpiDataSubmissionService.mapUniqueKeyToPpiResult = new Map<String, PpiResult__c>();
        PpiDataSubmissionService.setParentSurveyMap(ppiData.ppiResultList);

        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(ppiResultIds, false);

        System.assertEquals(2, ppiResultList.size());

        Test.startTest();
        PpiResult__c ppiResult =
            PpiDataSubmissionService.createPpiResults(
                ppiResultList[0],
                ppiData
            );
        Test.stopTest();

        System.assert(ppiResult != null, 'PpiResult record not created properly');
    }

    /**
     * Test method for validating insertion of PpiResult Record
     */
    static testMethod void testSavePpiResultData() {
        setUpTestData();

        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(ppiResultIds, false);

        System.assertEquals(2, ppiResultList.size());

        PpiDataSubmissionService.mapSurveyIdToInstance = new Map<String, Survey__c>();
        PpiDataSubmissionService.mapUniqueKeyToPpiResult = new Map<String, PpiResult__c>();
        PpiDataSubmissionService.setParentSurveyMap(ppiData.ppiResultList);
        PpiDataSubmissionService.mapUniqueKeyToPpiResult =
            new Map<String, PpiResult__c>();
        PpiDataSubmissionService.mapUniqueKeyToPpiResult.put(
            ppiResultList[0].UniqueKey__c,
            ppiResultList[0]
        );

        PpiResult__c ppiResult =
            PpiDataSubmissionService.createPpiResults(
                ppiResultList[0],
                ppiData
            );

        Test.startTest();
        PpiDataSubmissionService.savePpiResultData(
            new List<PpiResult__c> {ppiResult}
        );
        Test.stopTest();

        List<PpiResult__c> insertedPpiResultList =
            new PpiResultSelector().getAllWithSyncValue(new Set<Id> {ppiResult.Id}, false);

        System.assert(
            insertedPpiResultList != null,
            'Ppi result records not inserted properly'
        );
        System.assertEquals(1, insertedPpiResultList.size());
    }

    /**
     * Test method for validating proccessing of valid PpiResult Record
     */
    static testMethod void testProcessPpiResultData() {
        setUpTestData();

        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(ppiResultIds, false);

        System.assertEquals(2, ppiResultList.size());

        PpiDataSubmissionService.mapSurveyIdToInstance = new Map<String, Survey__c>();
        PpiDataSubmissionService.mapUniqueKeyToPpiResult = new Map<String, PpiResult__c>();
        PpiDataSubmissionService.setParentSurveyMap(ppiData.ppiResultList);
        PpiDataSubmissionService.mapUniqueKeyToPpiResult =
            new Map<String, PpiResult__c>();
        PpiDataSubmissionService.mapUniqueKeyToPpiResult.put(
            ppiResultList[0].UniqueKey__c,
            ppiResultList[0]
        );

        PpiResult__c ppiResult =
            PpiDataSubmissionService.createPpiResults(
                ppiResultList[0],
                ppiData
            );

        PpiDataSubmissionService.PpiDataResponses responses =
            new PpiDataSubmissionService.PpiDataResponses();

        Database.SaveResult[] saveResultList =
            PpiDataSubmissionService.savePpiResultData(
                new List<PpiResult__c> {ppiResult}
            );

        Test.startTest();
        PpiDataSubmissionService.processSavedPpiResult(
            saveResultList,
            responses
        );
        Test.stopTest();

        // No error generated for valid PpiResult record insertion
        System.assertEquals(
            0,
            responses.ppiDataResponseList[0].errorList.size()
        );
    }

    /**
     * Test method for validating processing of PpiResult Record with duplicate data
     */
    static testMethod void testProcessPpiResultDataWithDuplicate() {
        setUpTestData();

        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(ppiResultIds, false);

        System.assertEquals(2, ppiResultList.size());

        PpiDataSubmissionService.mapSurveyIdToInstance = new Map<String, Survey__c>();
        PpiDataSubmissionService.mapUniqueKeyToPpiResult = new Map<String, PpiResult__c>();
        PpiDataSubmissionService.setParentSurveyMap(ppiData.ppiResultList);
        PpiDataSubmissionService.mapUniqueKeyToPpiResult =
            new Map<String, PpiResult__c>();
        PpiDataSubmissionService.mapUniqueKeyToPpiResult.put(
            ppiResultList[0].UniqueKey__c,
            ppiResultList[0]
        );

        // Create Ppi data on Parent org
        PpiResult__c ppiResultParent =
            PpiDataSubmissionService.createPpiResults(
                ppiResultList[0],
                ppiData
            );
        PpiResultDomain ppiDomainInstance =
            new PpiResultDomain.Constructor().constructWithRecords(
                new List<PpiResult__c> {ppiResultParent}
            );
        ppiDomainInstance.insertRecords();

        // Create duplicate Ppi data on Parent org
        PpiResult__c ppiResultDuplicateParent =
            PpiDataSubmissionService.createPpiResults(
                ppiResultList[0],
                ppiData
            );

        PpiDataSubmissionService.PpiDataResponses responses =
            new PpiDataSubmissionService.PpiDataResponses();

        Database.SaveResult[] saveResultList =
            PpiDataSubmissionService.savePpiResultData(
                new List<PpiResult__c> {ppiResultDuplicateParent}
            );

        Test.startTest();
        PpiDataSubmissionService.processSavedPpiResult(
            saveResultList,
            responses
        );
        Test.stopTest();

        System.assertEquals(
            ErrorHandlingRest.DUPLICATE_VALUE,
            String.valueOf(responses.ppiDataResponseList[0].errorList[0].getErrorCode())
        );
    }

    /**
     * Method for setting test ppi data including Parent and child org
     */
    public static void setUpTestData() {
        tableLines = new List<PPITableLine__c>();
        setUpParentPpiData();

        List<PpiResult__c> ppiChildResultList = setUpChildPpiData();

        ppiResultIds = new Set<Id>();

        for (PpiResult__c ppiResult : ppiChildResultList) {
            ppiResultIds.add(ppiResult.Id);
        }

        setUpRequest(setPpiDataWrapper(
            new PpiResultSelector().getAllWithSyncValue(ppiResultIds, false)
        ));
    }

    /**
     * Method for setting child ppi data wrapper 
     */
    private static SendPpiDataService.PpiDataWrapper setPpiDataWrapper(
            List<PpiResult__c> ppiResultList
    ) {
        List<SendPpiDataService.PpiResultDetailWrapper> ppiResultWrapperList =
            new List<SendPpiDataService.PpiResultDetailWrapper>();

        for (PpiResult__c ppiResult : ppiResultList) {
            ppiResultWrapperList.add(
                new SendPpiDataService.PpiResultDetailWrapper(
                    ppiResult,
                    childSurvey.testSurvey.PpiIdentifier__c
                )
            );
        }

        System.assert(
            organizationInstance != null,
            'Organization data not fetched properly'
        );

        ppiData = new SendPpiDataService.PpiDataWrapper(
            organizationInstance.Name,
            organizationInstance.Id,
            ppiResultWrapperList
        );
        return ppiData;
    }

    /**
     * Method for setting Ppi data for child org
     */
    private static List<PpiResult__c> setUpChildPpiData() {
        childSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedPpiTemplate(), false
                )
            );
        for (List<PPITableLine__c> values : childSurvey.ppiTableLines.values()) {
            tableLines.addAll(values);
        }

        List<PpiResult__c> ppiResultList = PpiResultDomainTest.createMultipleRecords(
            2,
            childSurvey.testSurveyVersion,
            childSurvey.optionMap.get(
                childSurvey.questionMap.get(childSurvey.topLevelSections[0].Id)[2].Id
            ),
            false
        );
        System.assertEquals(2, ppiResultList.size());

        List<Organization> organizationList =
            new OrganizationSelector().getDefault();
        System.assertEquals(1, organizationList.size());

        organizationInstance = organizationList[0];
        PpiDataSubmissionService.organizationName = organizationInstance.Name;
        ppiResultList[0].OrganizationName__c = organizationInstance.Name;
        ppiResultList[1].OrganizationName__c = organizationInstance.Name;

        PpiResultTH.isMigration = true;
        PpiResultDomain ppiDomainInstance =
            new PpiResultDomain.Constructor().constructWithRecords(
                ppiResultList
            );
        ppiDomainInstance.insertRecords();

        setRemoteIdForChildOrg();
        return ppiResultList;
    }

    /**
     * Method for setting Remote Ids on child org
     */
    private static void setRemoteIdForChildOrg() {

        // Set remoteId for child Survey
        childSurvey.testSurvey.RemoteId__c = parentSurvey.testSurvey.Id;
        update childSurvey.testSurvey;

        // Set RemoteId for child options
        Integer index = 0;
        List<Option__c> childOptions = childSurvey.optionMap.get(
                childSurvey.questionMap.get(childSurvey.topLevelSections[0].Id)[2].Id
            );
        List<Option__c> parentOptions = parentSurvey.optionMap.get(
                parentSurvey.questionMap.get(parentSurvey.topLevelSections[0].Id)[2].Id
            );
        for (Option__c childOption : childOptions) {
            childOption.RemoteId__c = parentOptions[index].Id;
            index++;
        }
        update childOptions;
    }

    /**
     * Method for setting Ppi data for parent org
     */
    private static void setUpParentPpiData() {
        parentSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedPpiTemplate(), false
                )
            );
    }

    /**
     * Method for setting up data for calling webservice
     */
    static void setUpRequest(SendPpiDataService.PpiDataWrapper ppiDataWrapper) {
        String ppiResultJSON = JSON.serialize(ppiDataWrapper);
        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('ppiData/'),
            Blob.valueOf(ppiResultJSON),
            new Map<String, String>()
        );
    }
}