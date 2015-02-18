/**
 * Test class for the Remote Survey List Controller
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class RemoteSurveyListControllerTest {

    static RemoteSurveysListController setUpController(SurveyLibrary__c lib) {

        PageReference ref = Page.RemoteSurveyList;
        ref.getParameters().put(C.FORM_TYPE, C.FORM_TYPE_SUR);
        Test.setCurrentPage(ref );
        RemoteSurveysListController controller = new RemoteSurveysListController();
        controller.loadLibrary(lib.Name);
        return controller;
    }

    /**
     * Test loading a library
     */
    static testMethod void testLibraryLoad() {
        SurveyLibrary__c lib = SurveyLibraryDomainTest.addLibraryToDatabase();
        PageReference ref = Page.RemoteSurveyList;
        ref .getParameters().put(C.FORM_TYPE, C.FORM_TYPE_SUR);
        Test.setCurrentPage(ref );
        RemoteSurveysListController controller = new RemoteSurveysListController();
        controller.loadLibrary(lib.Name);
        System.assertEquals(lib.Name, controller.library.Name);
    }

    /**
     * Test downloading a survey
     */
    static testMethod void testSurveyParsing() {

        TestSurveyData testSurvey =
            TestSurveyData.addScoringGroupToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true), false
        );

        SurveyUtils utils = new SurveyUtils();
        Attachment att = utils.generateJsonFile(testSurvey.testSurveyVersion);
        String jsonString = '{"results" : ' + att.Body.toString() + '}';

        HttpResponse res = new HttpResponse();
        res.setBody(jsonString);
        res.setStatusCode(C.HTTP_OK);

        SurveyLibrary__c lib = SurveyLibraryDomainTest.addLibraryToDatabase();

        Test.startTest();
        PageReference ref = Page.RemoteSurveyList;
        ref.getParameters().put(C.FORM_TYPE, C.FORM_TYPE_PPI);
        Test.setCurrentPage(ref);
        RemoteSurveysListController controller = new RemoteSurveysListController();
        controller.library = lib;
        controller.processSurveyDownload(res);
        Test.stopTest();

        String clonedSurveyName = 'CLONE 1 '+ testSurvey.testSurvey.Name;
        System.assertEquals(
            String.format(
                System.Label.SURVEY_LIBRARY_MSG_SUCCESS_TEMPLATE,
                new List<String>{clonedSurveyName}
            ),
            controller.successMessage
        );

        Survey__c clonedSurvey = [
            SELECT
                AllowAnonymousInterviewee__c,
                InterviewMapField__c
            FROM
                Survey__c
            WHERE
                Name = :clonedSurveyName
        ];
        System.assert(!clonedSurvey.AllowAnonymousInterviewee__c);
        System.assertEquals(null, clonedSurvey.InterviewMapField__c);
    }

    /**
     * Test parsing the list of surveys available in a library
     */
    static testMethod void testSurveyListParsing() {

        // Test survey parsing
        List<Survey__c> surveys = new List<Survey__c>();
        Survey__c s1 = new Survey__c( Name = 'Test JSON 1', Description__c  = 'This is a description & % <', Version__c = 1.0);
        surveys.add(s1);
        Database.insert(surveys);
        SurveyVersion__c version = new SurveyVersion__c(Survey__c = s1.id, status__c = SurveyDO.STATUS_PUBLISHED);
        Database.insert(version);
        RemoteSurveysListController controller = setUpController(
            SurveyLibraryDomainTest.addLibraryToDatabase()
        );
        String jsonString = '{"results" :' + JSON.serialize(new List<SurveyVersion__c>{ version }) + '}';

        Test.startTest();
            controller.parseJsonListResponse(jsonString);
        Test.stopTest();
        System.assertEquals(1, controller.parsedSurveys.size());
    }

    /**
     * Test building the request with an id provided
     */
    static testMethod void testBuildRequestNoId() {

        RemoteSurveysListController controller = setUpController(
            SurveyLibraryDomainTest.addLibraryToDatabase()
        );

        Test.startTest();
        HttpRequest req = controller.buildRequest(null);
        Test.stopTest();
        System.assertEquals(req.getMethod(), 'GET');
        System.assertEquals(req.getEndpoint(), controller.library.URL__c + controller.library.RemoteLibraryPath__c + '?formType=sur');
    }

    /**
     * Test building the request with an id provided
     */
    static testMethod void testBuildRequestId() {

        RemoteSurveysListController controller = setUpController(
            SurveyLibraryDomainTest.addLibraryToDatabase()
        );

        // Create and insert a new survey, so we can use it's id on the test.
        Survey__c surv = new Survey__c(Name = 'testBuildRequestId');
        insert surv;
        Test.startTest();
        HttpRequest req = controller.buildRequest(surv.Id);
        Test.stopTest();
        System.assertEquals(req.getEndpoint(), controller.library.URL__c + controller.library.RemoteLibraryPath__c + '?id=' + surv.Id + '&formType=sur');
    }

    /**
     * Test method to verify normal Ppi Template is downloaded properly
     */
    static testMethod void testDownloadNormalPpiTemplate() {

        // Parent Ppi Template
        TestSurveyData testSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedPpiTemplate(), false, false
                )
            );

        SurveyData dataInstance = new SurveyData(testSurvey.testSurvey.Id);
        System.assert(dataInstance != null);
        System.assertEquals(1, dataInstance.tables.size());
        dataInstance.tables[0].Name = 'PpiTable1';

        String jsonString = '{"results" : [' + JSON.serialize(dataInstance) + ']}';

        HttpResponse response = new HttpResponse();
        response.setBody(jsonString);
        response.setStatusCode(C.HTTP_OK);

        SurveyLibrary__c surveyLibrary = SurveyLibraryDomainTest.addLibraryToDatabase();

        Test.startTest();
        PageReference pageReference = Page.RemoteSurveyList;
        pageReference.getParameters().put(C.FORM_TYPE, C.FORM_TYPE_PPI);
        Test.setCurrentPage(pageReference);
        RemoteSurveysListController controller = new RemoteSurveysListController();
        controller.library = surveyLibrary;
        String surveyId = controller.parseJsonSurveyResponse(response.getBody());
        Test.stopTest();

        Survey__c survey =
            new SurveySelector().getWithSurveyVersionAndQuestions(Id.valueOf(surveyId));

        System.assert(survey != null, 'Survey record not found.');
        System.assert(survey.Questions__r.size() > 0, 'No Questions found in survey.');

        for (Integer i = 0; i < survey.Questions__r.size(); i++) {
            System.assert(survey.Questions__r[i].RemoteServerId__c != null);
            if (QuestionDO.isSection(survey.Questions__r[i].Type__c)) {
                System.assert(
                    testSurvey.questionMap.get(
                        survey.Questions__r[i].RemoteServerId__c
                    ) != null
                );
            }
        }
    }

    /**
     * Test method to verify that downloading cloned Ppi Template works properly after 
     * normal PpiTemplate was already downloaded
     */
    static testMethod void testDownloadingParentClonedSurvey() {

        // Parent Ppi Template
        TestSurveyData testParentSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedPpiTemplate(), false, false
                )
            );

        SurveyData dataInstance = new SurveyData(testParentSurvey.testSurvey.Id);
        System.assert(dataInstance != null);
        System.assertEquals(1, dataInstance.tables.size());
        dataInstance.tables[0].Name = 'PpiTable1';

        String jsonString = '{"results" : [' + JSON.serialize(dataInstance) + ']}';

        HttpResponse response = new HttpResponse();
        response.setBody(jsonString);
        response.setStatusCode(C.HTTP_OK);

        SurveyLibrary__c surveyLibrary = SurveyLibraryDomainTest.addLibraryToDatabase();

        Test.startTest();
        System.RunAs(TestUtils.generateTaroworksUser()) {
            // Child Ppi Template
            TestSurveyData testChildSurvey =
                TestSurveyData.addPpiTablesToStandardSurvey(
                    TestSurveyData.createStandardTestSurvey(
                        SurveyDOTest.createInsertedPpiTemplate(), false, false
                    )
                );

            List<PPITable__c> ppiTableForChild =
                new PpiTableSelector().getPpiTablesForSurveys(
                    new List<Id> {testChildSurvey.testSurvey.Id}
                );
            System.assert(ppiTableForChild != null);
            System.assertEquals(1, ppiTableForChild.size());

            // Make child org Ppi Table Name same as parent orgs PpiTable Name so that
            // while downloading cloned PpiTemplate we already have same lookup tables on child org
            ppiTableForChild[0].Name = 'PpiTable1';
            PpiTableDomain ppiTableDomain = new PpiTableDomain();
            ppiTableDomain.addRecords(ppiTableForChild);
            ppiTableDomain.updateRecords();

            PageReference pageReference = Page.RemoteSurveyList;
            pageReference.getParameters().put(C.FORM_TYPE, C.FORM_TYPE_PPI);
            Test.setCurrentPage(pageReference);
            RemoteSurveysListController controller = new RemoteSurveysListController();
            controller.library = surveyLibrary;
            String surveyId = controller.parseJsonSurveyResponse(response.getBody());
            System.assert(surveyId != null, 'Response not parsed properly.');

            // Fetch the downloaded Ppi Template
            SurveySelector surveySelector = new SurveySelector();
            Survey__c survey =
                surveySelector.getWithSurveyVersionAndQuestions(Id.valueOf(surveyId));

            System.assert(survey != null, 'Survey record not found.');
            System.assert(survey.Questions__r.size() > 0, 'No Questions found in survey.');

            for (Integer i = 0; i < survey.Questions__r.size(); i++) { 
                System.assert(survey.Questions__r[i].RemoteServerId__c != null);
                if (QuestionDO.isSection(survey.Questions__r[i].Type__c)) {
                    System.assert(
                        testParentSurvey.questionMap.get(
                            survey.Questions__r[i].RemoteServerId__c
                        ) != null
                    );
                }
            }

            List<PPITable__c> ppiTableForDownloadedSurvey =
                new PpiTableSelector().getPpiTablesForSurveys(
                    new List<Id> {surveyId}
                );
            System.assert(ppiTableForDownloadedSurvey != null);
            System.assertEquals(1, ppiTableForDownloadedSurvey.size());

            // Verify that no new PpiTable is created and the downloaded template also refer to 
            // same table that was present for existing template already present on child org
            System.assertEquals(ppiTableForChild[0].Id, ppiTableForDownloadedSurvey[0].Id);

            // Verify new data set record is created for the downloaded template
            List<PPITableDataSet__c> dataSets =
                new PpiTableDataSetSelector().getAllForSurveys(new List<Id> {surveyId});
            System.assert(dataSets != null);
            System.assertEquals(1, dataSets.size());
        }
        Test.stopTest();
    }

    /**
     * Test method to verify fetching of SurveyVersion records with status not equal to Deprecated
     */
    static testMethod void testLoadTemplates() {

        // Create survey with Status as Draft
        Survey__c surveyWithStatusDraft = SurveyDOTest.createInsertedPpiTemplate();
        System.assert(surveyWithStatusDraft != null, 'Survey record could not be created.');

        // Create survey with Status as Deprecated
        Survey__c surveyWithStatusDeprecated = SurveyDOTest.createInsertedPpiTemplate();
        System.assert(surveyWithStatusDeprecated != null, 'Survey record could not be created.');

        List<SurveyVersion__c> surveyVersionRecords =
            new SurveyVersionSelector().getAllWithSurveyIds(
                new Set<String> {surveyWithStatusDeprecated.Id}
            ); 
        System.assert(
            surveyVersionRecords.size() == 1,
            'SurveyVersion records could not be fetched.'
        );

        surveyVersionRecords[0].Status__c = SurveyDO.STATUS_DEPRECATED;
        SurveyVersionDomain surveyVersionDomain = new SurveyVersionDomain();
        surveyVersionDomain.addRecords(surveyVersionRecords);
        surveyVersionDomain.updateRecords();

        System.assert(surveyVersionDomain.records.size() == 1);
        System.assert(surveyVersionDomain.records[0].Id != null);

        List<Survey__c> surveyRecord =
            (List<Survey__c>) new SurveySelector().getRecordsById(
                new Set<Id> {surveyWithStatusDeprecated.Id}
            );
        System.assert(surveyRecord.size() == 1, 'Survey record could not be fetched properly.');
        System.assertEquals(SurveyDO.STATUS_DEPRECATED, surveyRecord[0].Status__c);

        // Create a SurveyLibrary with Name other than 'Default', 'myLib' and 
        // assign it to both surveys
        SurveyLibrary__c surveyLibrary = SurveyLibraryDomainTest.addLibraryToDatabase();
        System.assert(surveyLibrary != null, 'SurveyLibrary record could not be created.');

        surveyWithStatusDraft.SurveyLibrary__c = surveyLibrary.Id;
        surveyWithStatusDeprecated.SurveyLibrary__c = surveyLibrary.Id;
        SurveyDO surveyDomain = new SurveyDO();
        surveyDomain.addRecords(
            new List<Survey__c> {surveyWithStatusDraft, surveyWithStatusDeprecated}
        );
        surveyDomain.updateRecords();

        List<Survey__c> surveyRecords =
            (List<Survey__c>) new SurveySelector().getRecordsById(
                new Set<Id> {surveyWithStatusDraft.Id, surveyWithStatusDeprecated.Id}
            );
        System.assert(surveyRecords.size() == 2, 'Survey record could not be fetched properly.');
        System.assert(surveyRecords[0].SurveyLibrary__c != null);
        System.assert(surveyRecords[1].SurveyLibrary__c != null);

        Test.startTest();
        RemoteSurveysListController controller = setUpController(surveyLibrary);
        List<SurveyVersion__c> surveyVersionList = controller.loadTemplates();
        Test.stopTest();

        System.assert(
            surveyVersionList.size() == 1,
            'Survey Version records could not be fetched.'
        );
        System.assert(surveyVersionList[0].Survey__r.Status__c != SurveyDO.STATUS_DEPRECATED);
    }
}