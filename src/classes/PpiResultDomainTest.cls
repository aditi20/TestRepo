/**
 * This class contains unit tests for validating the behavior of PpiResultDomain
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 * @author - Aditi Satpute
 */
@isTest
public with sharing class PpiResultDomainTest {

    public static final String ACCOUNT_API_NAME =
        Account.sObjectType.getDescribe().getName();

    /**
     * Create sample Ppi records with all data necessary
     */
    public static List<PpiResult__c> createSamplePpiResultData(
            Integer numberOfRecords,
            Boolean isRetrievedByParent
    ) {

        Survey__c survey = SurveyDOTest.createInsertedSurvey();
        Set<String> surveyIdSet = new Set<String>{survey.Id};

        List<SurveyVersion__c> surveyVersionList =
            new SurveyVersionSelector().getAllWithSurveyIds(surveyIdSet);

        List<Question__c> sectionList =
            new List<Question__c>{
                QuestionDOTest.createSection(1),
                QuestionDOTest.createSection(2)
            };
        sectionList[0].Survey__c = survey.Id;
        sectionList[1].Survey__c = survey.Id;
        insert sectionList;
        System.assertEquals(2, sectionList.size());

        List<Question__c> questionList = new List<Question__C>{};
        for (Question__c section : sectionList) {
            Question__c newSelect = QuestionDOTest.createQuestion(
                QuestionDO.TYPE_RADIO,
                'SelectQuestion',
                'Caption',
                1
            );
            newSelect.Survey__c = section.Survey__c;
            newSelect.Parent__c = section.Id;
            questionList.add(newSelect);
        }
        insert questionList;

        List<Option__c> optionList =
            OptionDomainTest.createOptionsForQuestions(
                questionList,
                'Option_Name',
                'Option_caption',
                numberOfRecords
        );
        System.assertEquals(numberOfRecords * 2, optionList.size());
        insert optionList;

        List<PpiResult__c> ppiResultList = createMultipleRecords(
            numberOfRecords,
            surveyVersionList[0],
            optionList,
            isRetrievedByParent
        );

        PpiResultDomain ppiDomainInstance =
            new PpiResultDomain.Constructor().constructWithRecords(
                ppiResultList
            );
        ppiDomainInstance.insertRecords();

        return ppiResultList;
    }

    /**
     * Create multiple records for PpiResult 
     */
     public static List<PpiResult__c> createMultipleRecords(
            Integer numberOfRecords,
            SurveyVersion__c surveyVersion,
            List<Option__c> optionList,
            Boolean isRetrievedByParent
    ) {
        List<PpiResult__c> ppiResultList = new List<PpiResult__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            PpiResult__c ppiResult =
                createRecord(
                    surveyVersion,
                    optionList[i],
                    isRetrievedByParent
                );
            ppiResultList.add(ppiResult);
        }
        return ppiResultList;
    }

    /**
     * Create record for PpiResult 
     */
    public static PpiResult__c createRecord(
            SurveyVersion__c surveyVersion,
            Option__c option,
            Boolean isRetrievedByParent
    ) {
        PpiResult__c ppiResult = new PpiResult__c(
            PpiTemplate__c = surveyVersion.Id,
            AnswerOne__c = option.Id,
            RetrievedByParent__c = isRetrievedByParent,
            GeoLocation__Latitude__s = 17.345,
            GeoLocation__Longitude__s = 75.342
        );
        return ppiResult;
    }

    /**
     * Test method for setCollectionDatePpiResults
     */
    static testMethod void testSetCollectionDatePpiResults() {
        List<PpiResult__c> ppiResultList = createSamplePpiResultData(10, false);

        Test.startTest();
        new PpiResultDomain().setCollectionDatePpiResults(ppiResultList, false);
        Test.stopTest();

        for (PpiResult__c ppiResult : ppiResultList) {
            System.assert(
                ppiResult.PpiCollectionDate__c != null,
                'Collection Date should not be null'
            );
        }
    }

    /**
     * Test method to verify set uniqueKey
     */
    static testMethod void testSetUniqueKey() {

        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, false);

        Map<Integer, String> optionIdsWithSequenceMap = new Map<Integer, String>();
        Integer countValue = 0;
        for (
                Option__c option :
                    testSurvey.optionMap.get(
                        testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[2].Id
                    )
        ) {
            optionIdsWithSequenceMap.put(countValue++, option.Id);
        }

        PpiResult__c ppiResult = PpiResultDomain.createRecord(
            optionIdsWithSequenceMap,
            'clientId',
            'Female',
            32,
            Date.valueOf('2014-11-11'),
            12,
            '17.345 75.342 0 0',
            'organisation',
            testSurvey.testSurveyVersion.Id,
            null,
            Datetime.newInstance(2014, 12, 1)
        );
        PpiDataSubmissionService.organizationName = ppiResult.OrganizationName__c;

        Test.startTest();
        new PpiResultDomain().setUniqueKeys(new List<PpiResult__c> {ppiResult});
        Test.stopTest();

        System.assert(ppiResult != null, 'PpiResult not created properly');

        String expectedUniqueKey =
            PpiResultDomain.encodePpiUniqueKey(
                getExpectedUniqueKey(
                    ppiResult,
                    testSurvey.testSurvey.PpiIdentifier__c,
                    optionIdsWithSequenceMap
                )
            );
        System.assertEquals(
            expectedUniqueKey,
            ppiResult.UniqueKey__c
        );
    }

    /**
     * Test method for validating uniqueKey Creation
     */
    static testMethod void testUniqueKeyCreation() {
        PpiDataSubmissionServiceTest.setUpTestData();

        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(
                PpiDataSubmissionServiceTest.ppiResultIds,
                false
            );
        System.assertEquals(2, ppiResultList.size());

        Map<Integer, String> ppiResultOptionRemoteIdsWithSequenceMap =
            PpiResultDomain.populateSequenceOptionRemoteIdsMap(ppiResultList[0]);

        Test.startTest();
        String actualUniqueKey =
            PpiResultDomain.createPpiResultUniqueKey(
                ppiResultList[0],
                PpiDataSubmissionServiceTest.childSurvey.testSurvey.PpiIdentifier__c,
                ppiResultOptionRemoteIdsWithSequenceMap
            );
        Test.stopTest();

        System.assertEquals(
            getExpectedUniqueKey(
                ppiResultList[0],
                PpiDataSubmissionServiceTest.childSurvey.testSurvey.PpiIdentifier__c,
                ppiResultOptionRemoteIdsWithSequenceMap
            ),
            actualUniqueKey
        );
    }

    /**
     * Test method for validating encoding of uniqueKey
     */
    static testmethod void testUniqueKeyEncoding() {
        PpiDataSubmissionServiceTest.setUpTestData();

        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(
                PpiDataSubmissionServiceTest.ppiResultIds,
                false
            );

        System.assertEquals(2, ppiResultList.size());

        Map<Integer, String> ppiResultOptionRemoteIdsWithSequenceMap =
            PpiResultDomain.populateSequenceOptionRemoteIdsMap(ppiResultList[0]);

        Test.startTest();
        String actualEncodedUniqueKey =
            PpiResultDomain.encodePpiUniqueKey(
                getExpectedUniqueKey(
                    ppiResultList[0],
                    PpiDataSubmissionServiceTest.childSurvey.testSurvey.PpiIdentifier__c,
                    ppiResultOptionRemoteIdsWithSequenceMap
                )
            );
        Test.stopTest();

        String expectedEncodedUniqueKey =
            EncodingUtil.base64Encode(
                Crypto.generateDigest(
                    'MD5',
                    Blob.valueof(
                        getExpectedUniqueKey(
                            ppiResultList[0],
                            PpiDataSubmissionServiceTest.childSurvey.testSurvey.PpiIdentifier__c,
                            ppiResultOptionRemoteIdsWithSequenceMap
                        )
                    )
                )
            );
 
        System.assertEquals(
            expectedEncodedUniqueKey,
            actualEncodedUniqueKey
        );
    }

    /**
     * Method to test fetching of PpiResult's SurveyVersionIds
     */
    static testmethod void testFetchPpiResultSurveyIds() {

        Survey__c survey = SurveyDOTest.createInsertedSurvey();

        List<SurveyVersion__c> surveyVersionList =
            new SurveyVersionSelector().getAllWithSurveyIds(
                new Set<String> {survey.Id}
            );

        System.assertEquals(1, surveyVersionList.size());

        PpiResult__c ppiResult = createRecord(surveyVersionList[0], new Option__c(), false);
        PpiResultDomain ppiResultDomainInstance = new PpiResultDomain();
        ppiResultDomainInstance.addRecord(ppiResult);
        ppiResultDomainInstance.insertRecords();

        System.assert(ppiResult != null, 'Ppi Result not created properly');

        Test.startTest();
        Set<Id> surveyVersionIds =
            PpiResultDomain.fetchPpiResultSurveyVersionIds(new List<PpiResult__c> {ppiResult});
        Test.stopTest();

        System.assertEquals(1, surveyVersionIds.size());
        System.assert(
            surveyVersionIds.contains(ppiResult.PpiTemplate__c),
            'SurveyVersion Ids not fetched properly'
        );
    }

    /**
     * Method to populate a map with Sequence of OptionRemoteIds
     */
    static testmethod void testPopulateSequenceOptionRemoteIdsMap() {

        Set<String> parentOptionIds = new Set<String>();
        Boolean isRemoteIdSet = false;
        PpiDataSubmissionServiceTest.setUpTestData();

        List<PpiResult__c> ppiResultList =
            new PpiResultSelector().getAllWithSyncValue(
                PpiDataSubmissionServiceTest.ppiResultIds, false
            );

        System.assertEquals(2, ppiResultList.size());

        Test.startTest();
        Map<Integer, String> ppiResultSequenceOptionRemoteIdsMap =
            PpiResultDomain.populateSequenceOptionRemoteIdsMap(ppiResultList[0]);
        Test.stopTest();

        System.assertEquals(10, ppiResultSequenceOptionRemoteIdsMap.size());
        System.assertEquals(2, PpiDataSubmissionServiceTest.parentSurvey.topLevelSections.size());
        List<Question__c> questionList =
            PpiDataSubmissionServiceTest.parentSurvey.questionMap.get(
                PpiDataSubmissionServiceTest.parentSurvey.topLevelSections[0].Id
            );
        System.assertEquals(3, questionList.size());
        List<Option__c> parentOptions =
            PpiDataSubmissionServiceTest.parentSurvey.optionMap.get(
                questionList[2].Id
            );

        for (Option__c option : parentOptions) {
            parentOptionIds.add(option.Id);
        }

        for (String optionRemoteIds : ppiResultSequenceOptionRemoteIdsMap.values()) {
            // Remote Ids should match with parent option Ids
            if (parentOptionIds.contains(optionRemoteIds)) {
                isRemoteIdSet = true;
            }
        }
        System.assert(isRemoteIdSet, 'Remote Ids should set with respect to parent option Ids');
    }

    /**
     * Test method to verify ppi result wrapper data is populated for missing demograhic data
     */
    static testMethod void testUpdateDemographicFieldsWithExistingData() {
        PpiSettings__c ppiSettings = createPpiSettingsRecord();
        Account accountRecord = createAccountRecord();

        PpiResultDomain.PpiResultWrapper wrapperInstance =
            new PpiResultDomain.PpiResultWrapper('Test Template');
        wrapperInstance.clientId = Schema.sObjectType.Account.fields.Site.getName();

        System.assert(wrapperInstance.clientId != null);

        Test.startTest();
        wrapperInstance.updateDemographicFieldsWithExistingData(
            ppiSettings,
            accountRecord
        );
        Test.stopTest();

        System.assertEquals(accountRecord.AccountNumber, wrapperInstance.gender);
        System.assertEquals(null, wrapperInstance.householdSize);
        System.assertEquals(accountRecord.CreatedDate, wrapperInstance.joinedDate);
        System.assertEquals(accountRecord.NumberOfEmployees, wrapperInstance.age);
    }

    /**
     * Test method to verify ppi result wrapper data is not populated if ClientId is null
     */
    static testMethod void testUpdateDemographicFieldsWithNullClientId() {
        PpiSettings__c ppiSettings = createPpiSettingsRecord();
        Account accountRecord = createAccountRecord();

        PpiResultDomain.PpiResultWrapper wrapperInstance =
            new PpiResultDomain.PpiResultWrapper('Test Template');

        Test.startTest();
        wrapperInstance.updateDemographicFieldsWithExistingData(
            ppiSettings,
            accountRecord
        );
        Test.stopTest();

        System.assert(wrapperInstance.gender == null);
        System.assert(wrapperInstance.householdSize == null);
        System.assert(wrapperInstance.joinedDate == null);
        System.assert(wrapperInstance.age == null);
    }

    /**
     * Method for creating Ppi Settings
     */
    public static PpiSettings__c createPpiSettingsRecord() {

        PpiSettings__c ppiSettingsRecord = PpiSettingsWrapper.insertRecord(
            ACCOUNT_API_NAME,
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Site.getName(),
            Schema.sObjectType.Account.fields.CreatedDate.getName(),
            Schema.sObjectType.Account.fields.AccountNumber.getName(),
            ''
        );
        PpiSettings__c ppiSettings =
            PpiSettingsWrapper.getRecordForName(ACCOUNT_API_NAME);
        System.assert(
            ppiSettings != null,
            'PpiSettings record not found for : ' + ACCOUNT_API_NAME
        );
        return ppiSettings;
    }

    /**
     * Method for creating and verifying Account record
     */
    public static Account createAccountRecord() {
        Account accountRecord =
            AccountDomainTest.createRecord(
                'Test Account',
                15,
                'Test Site',
                'ACC-001'
            );

        AccountDomain accountDomain = new AccountDomain();
        accountDomain.addRecord(accountRecord);
        accountDomain.insertRecords();
        System.assert(accountDomain.records.size() > 0);
        System.assert(accountDomain.records[0].Id != null);

        return (Account) accountDomain.records[0];
    }

    /**
     * Method for generating expected unique key
     */
    public static String getExpectedUniqueKey(
            PpiResult__c ppiResult,
            String ppiIdentifier,
            Map<Integer, String> optionIdsWithSequenceMap
    ) {
        List<String> uniqueKeyDataList = new List<String>();
        String ppiScore = null;
        uniqueKeyDataList.add(ppiIdentifier);
        uniqueKeyDataList.add(ppiResult.OrganizationName__c);
        uniqueKeyDataList.add(String.valueOf(ppiResult.PpiCollectionDate__c));
        uniqueKeyDataList.add(String.valueOf(
            ppiResult.PpiScore__c != null
            ? ppiResult.PpiScore__c.setScale(1)
            : ppiResult.PpiScore__c
        ));
        uniqueKeyDataList.add(ppiResult.ClientId__c);
        uniqueKeyDataList.add(ppiResult.Gender__c);
        uniqueKeyDataList.add(String.valueOf(ppiResult.Age__c));
        uniqueKeyDataList.add(String.valueOf(ppiResult.HouseholdSize__c));
        uniqueKeyDataList.add(String.valueOf(ppiResult.JoinedDate__c));
        uniqueKeyDataList.add(String.valueOf(ppiResult.GeoLocation__Latitude__s));
        uniqueKeyDataList.add(String.valueOf(ppiResult.GeoLocation__Longitude__s));
        uniqueKeyDataList.add(optionIdsWithSequenceMap.get(1));
        uniqueKeyDataList.add(optionIdsWithSequenceMap.get(2));
        uniqueKeyDataList.add(optionIdsWithSequenceMap.get(3));
        uniqueKeyDataList.add(optionIdsWithSequenceMap.get(4));
        uniqueKeyDataList.add(optionIdsWithSequenceMap.get(5));
        uniqueKeyDataList.add(optionIdsWithSequenceMap.get(6));
        uniqueKeyDataList.add(optionIdsWithSequenceMap.get(7));
        uniqueKeyDataList.add(optionIdsWithSequenceMap.get(8));
        uniqueKeyDataList.add(optionIdsWithSequenceMap.get(9));
        uniqueKeyDataList.add(optionIdsWithSequenceMap.get(10));

        StringBuilder stringBuilderInstance = new StringBuilder(uniqueKeyDataList);
        stringBuilderInstance.setJoiner(PpiResultDomain.SPLITTER);

        return stringBuilderInstance.generateString();
    }
}