/**
 * Test class for the SurveySelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author - Ketaki Virkar
 */
@isTest
public class SurveySelectorTest {

    static final string OBJ_CONTACT = 'Contact';
    static final string OBJ_ACCOUNT = 'Account';
    static final string SURVEY_NAME = 'Test Survey';

    /**
     * Test method to verify fetching of Survey records by its alias
     */
    static testMethod void testFetchAllByAlias() {
        String suffix1 = '_Survey1';
        String suffix2 = '_Survey2';
        SurveyDO surveyDomainInstance =
            new SurveyDO.Constructor().constructWithRecords(
                new List<Survey__c> {
                    SurveyDOTest.createTestSurveyRecordWithAlias(suffix1),
                    SurveyDOTest.createTestSurveyRecordWithAlias(suffix2)
                }
            );
        surveyDomainInstance.insertRecords();

        Test.startTest();
        List<Survey__c> surveyList =
            new SurveySelector().getAllByAlias(
                new Set<String> {
                    SurveyDOTest.TEST_SURVEY_ALIAS + suffix1,
                    SurveyDOTest.TEST_SURVEY_ALIAS + suffix2
                },
                false
            );

        // Survey records are fetched properly
        System.assertEquals(2, surveyList.size());
    }

    /**
     * Test method for fetching survey with SurveyVersion records for specified Survey Ids
     */
    static testMethod void testFetchingSurveyWithSurveyVersion() {
        Survey__c survey = SurveyDOTest.createInsertedSurvey();

        SurveyVersion__c surveyVersion =
            SurveyVersionDomainTest.createRecord(
                survey,
                SurveyDO.STATUS_DRAFT
            );
        SurveyVersionDomain surveyVersionDomainInstance =
            new SurveyVersionDomain.Constructor().constructWithRecords(
                new List<SurveyVersion__c> {surveyVersion}
            );
        surveyVersionDomainInstance.insertRecords();

        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(new Set<String> {survey.Id});

        // There are 2 surveyVersion records for a single Survey
        System.assertEquals(2, surveyVersions.size());

        Test.startTest();
        // Fetches survey record with single survey version record
        List<Survey__c> surveyRecords =
            new SurveySelector().getWithSurveyVersion(new Set<String> {survey.Id});
        Test.stopTest();

        System.assert(
            surveyRecords.size() == 1,
            'Survey record with Survey version Record is not fetched properly'
        );

        System.assertEquals(1, surveyRecords[0].SurveyVersions__r.size());

        System.assertEquals(
            surveyVersions[0].Id,
            surveyRecords[0].SurveyVersions__r[0].Id
        );
    }

    /**
     * Test fetching a survey by name
     */
    static testMethod void testFetchSurveyByName() {

        Survey__c testSurvey = SurveyDOTest.createTestSurveyRecord();
        insert testSurvey;

        SurveySelector selector = new SurveySelector();
        List<Survey__c> fetchedSurveys = selector.getByName(
            SurveyDOTest.TEST_SURVEY_NAME,
            SObjectSelector.EQUALS_OPERATOR
        );
        System.assertEquals(1, fetchedSurveys.size());
    }
    /**
     * Test class for fetching ppiTableDataSets with specified SurveyVersionId
     */
    static testMethod void testDataSetsWithSurveyVersionId() {
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();

        Question__c sectionRegular =
            TestUtils.addQuestion(
                survey,
                1,
                'section',
                QuestionDO.TYPE_SECTION
            );
        Question__c numberQuestion =
            TestUtils.addQuestion(
                sectionRegular,
                1,
                'numberQuestion',
                QuestionDO.TYPE_NUMBER_INTEGER
            );

        Test.startTest();
        SurveySelector surveySelectorInstance = new SurveySelector();
        Survey__c surveyRecord =
            surveySelectorInstance.getWithSurveyVersionAndQuestions(survey.Id);
        Test.stopTest();

        System.assert(
            surveyRecord != null,
            'Survey record with Survey version and Question Records is not fetched properly'
        );

        System.assertEquals(1, surveyRecord.SurveyVersions__r.size());

        System.assertEquals(0, surveyRecord.Questions__r.size());
    }

    /**
     * Test method for fetching survey record along with Survey mappings
     */
    static testMethod void testFetchingWithSurveyMappings() {
        Survey__c survey = SurveyDOTest.createInsertedSurvey(SURVEY_NAME);

        SurveyMapping__c surveyMapping1 =
            SurveyMappingDomainTest.createSurveyMapping('', OBJ_CONTACT);
        SurveyMapping__c surveyMapping2 =
            SurveyMappingDomainTest.createSurveyMapping('', OBJ_ACCOUNT);
        UnitOfWork unitOfWork = new UnitOfWork();
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping1,
            survey,
            null,
            unitOfWork
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping2,
            survey,
            null,
            unitOfWork
        );
        unitOfWork.commitWork();

        Test.startTest();
        SurveySelector surveySelectorInstance = new SurveySelector();
        List<Survey__c> surveyList =
            surveySelectorInstance.getWithSurveyMappings(new Set<Id> {survey.Id});
        Test.stopTest();

        System.assert(
            surveyList != null,
            'Survey record with Survey mappings is not fetched properly'
        );

        System.assertEquals(
            1,
            surveyList.size()
        );

        System.assertEquals(
            2,
            surveyList[0].Survey_Mappings__r.size()
        );
    }

    /**
     * Test getting a survey with its version
     */
    static testMethod void testGetSpecificWithSurveyVersion() {
        Survey__c surveyInstance = SurveyDOTest.createInsertedSurvey('TestSurvey');

        Test.startTest();
        Survey__c survey =
            new SurveySelector().getSpecificWithSurveyVersion(surveyInstance.Id);
        Test.stopTest();

        System.assert(survey != null, 'Survey List should not be null');
    }

    /**
     * Test getting a draft survey
     */
    static testMethod void testGetDraftSurveys() {

        Survey__c surveyPublishedInstance = SurveyDOTest.createInsertedSurvey('TestSurvey');
        Survey__c surveyDraftInstance = SurveyDOTest.createInsertedSurvey('TestDraftSurvey');
        SurveyManagerController smc =
            new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
        smc.surveyToPublish = surveyPublishedInstance.Id;
        smc.doPublish();

        Test.startTest();
        List<Survey__c> listSurveyDraft =
            new SurveySelector().getDraftSurveys();
        Test.stopTest();

        System.assert(listSurveyDraft != null, 'Survey List should not be null');
        System.assertEquals(1, listSurveyDraft.size(), 'Survey List should have only 1 Draft Survey');
    }

    /**
     * Test method for fetching all Ppi Templates with SurveyVersion records
     */
    static testMethod void testFetchingPpiTemplateWithSurveyVersion() {
        SurveyDo surveyDomainInstance =
            new SurveyDo.Constructor().constructWithRecords(
                new List<Survey__c> {
                    SurveyDOTest.createPpiTemplate(
                        LanguageWrapperTest.insertRecord('EN', 'English'),
                        ISOCountryWrapperTest.insertRecord('IN', 'INDIA'),
                        2015
                    ),
                    SurveyDOTest.createPpiTemplate(
                        LanguageWrapperTest.insertRecord('AA', 'Afar'),
                        ISOCountryWrapperTest.insertRecord('KE', 'KENYA'),
                        2014
                    ),
                    SurveyDOTest.createTemplate(),
                    SurveyDOTest.createTestSurveyRecord()
                }
            );
        surveyDomainInstance.insertRecords();
        System.assertEquals(4, surveyDomainInstance.records.size());

        List<Survey__c> listPpiTemplates;
        Test.startTest();
        listPpiTemplates = new SurveySelector().getPpiTemplatesWithSurveyVersion();
        Test.stopTest();

        System.assertEquals(2, listPpiTemplates.size());
        for (Survey__c surveyInstance : listPpiTemplates) {
            System.assert(surveyInstance.SurveyVersions__r.size() > 0);
        }
    }

     /**
     * Verify fetching all surveys
     */
    static testMethod void testGetAllSurveys() {

        Survey__c surveyPublishedInstance = SurveyDOTest.createInsertedSurvey('TestPublishedSurvey');
        Survey__c surveyDraftInstance = SurveyDOTest.createInsertedSurvey('TestDraftSurvey');
        Survey__c ppiTemplateInstance = SurveyDOTest.createInsertedPpiTemplate();
        Survey__c useItPpiTemplateInstance = SurveyDOTest.createInsertedPpiTemplate();
        useItPpiTemplateInstance.RemoteId__c = 'Test';
        useItPpiTemplateInstance.isTemplate__c = false;
        SurveyDO surveyDomainInstance =
            new SurveyDO.Constructor().constructWithRecords(
                new List<Survey__c> {useItPpiTemplateInstance}
            );
        surveyDomainInstance.updateRecords();

        SurveyManagerController surveyManager =
            new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
        surveyManager.surveyToPublish = surveyPublishedInstance.Id;
        surveyManager.doPublish();

        Test.startTest();
        List<Survey__c> allSurveyList = new SurveySelector().getAllSurveys();
        Test.stopTest();

        System.assert(allSurveyList != null, 'Survey List should not be null');
        System.assertEquals(4, allSurveyList.size(), 'Survey List should have only 1 Draft Survey');
    }
}