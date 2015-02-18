/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public class TemplateManagerTest {

    static Question__c newQuestion(
            Survey__c survey,
            Question__c parent,
            String type,
            String name,
            String caption,
            Integer position
    ) {
        return new Question__c(
            Survey__c = survey.Id,
            Parent__c = (parent != null ? parent.Id : null),
            Type__c = type,
            Name = name,
            Caption__c = caption,
            Position__c = position
        );
    }

    /**
     * Test getting the new templates
     * Test getting a new ppi template from grameen
     */
    static testMethod void testNewGetPPI() {

        PageReference templateManager = Page.TemplateManager;
        templateManager.getParameters().put(C.TEMPLATE_ACTION, C.GET_PPI_ACTION);
        Test.setCurrentPageReference(templateManager);

        Test.startTest();
        TemplateManagerController controller =
            new TemplateManagerController(new ApexPages.StandardController(new Survey__c()));
        PageReference newPage = controller.newTemplate();
        String expectedUrl = newPage.getUrl().subString(0, newPage.getUrl().indexOf('?'));
        Test.stopTest();
        System.assertEquals(expectedUrl, Page.RemoteSurveyList.getUrl());
        System.assertEquals(newPage.getParameters().get(C.LIBRARY_NAME), C.GRAMEEN_LIBRARY);
        System.assertEquals(newPage.getParameters().get(C.FORM_TYPE), C.FORM_TYPE_PPI);
    }

    /**
     * Test downloading a new template
     */
    static testMethod void  testDownloadTemplate() {

        String libraryName = 'Lobster';
        PageReference templateManager = Page.TemplateManager;
        templateManager.getParameters().put(C.TEMPLATE_ACTION, C.DOWNLOAD_ACTION);
        templateManager.getParameters().put(C.LIBRARY_NAME, libraryName);
        Test.setCurrentPageReference(templateManager);

        Test.startTest();
        TemplateManagerController controller =
            new TemplateManagerController(new ApexPages.StandardController(new Survey__c()));
        PageReference newPage = controller.newTemplate();
        String expectedUrl = newPage.getUrl().subString(0, newPage.getUrl().indexOf('?'));
        Test.stopTest();
        System.assertEquals(expectedUrl, Page.RemoteSurveyList.getUrl());
        System.assertEquals(newPage.getParameters().get(C.LIBRARY_NAME), libraryName);
        System.assertEquals(newPage.getParameters().get(C.FORM_TYPE), C.FORM_TYPE_TEMP);
    }

    /**
     * Test creating a new template
     */
    static testMethod void testNewTemplate() {

        PageReference templateManager = Page.TemplateManager;
        templateManager.getParameters().put(C.TEMPLATE_ACTION, C.CREATE_NEW_TEMPLATE);
        Test.setCurrentPageReference(templateManager);

        Test.startTest();
        TemplateManagerController controller =
            new TemplateManagerController(new ApexPages.StandardController(new Survey__c()));
        PageReference newPage = controller.newTemplate();
        String expectedUrl = newPage.getUrl().subString(0, newPage.getUrl().indexOf('?'));
        Test.stopTest();
        System.assertEquals(expectedUrl, Page.SurveySetting.getUrl());
        System.assertEquals(newPage.getParameters().get(C.START_FORM), C.CREATE_NEW_TEMPLATE);
    }

    /**
     * Test a non-existing action
     */
    static testMethod void testWrongAction() {

        PageReference templateManager = Page.TemplateManager;
        templateManager.getParameters().put(C.TEMPLATE_ACTION, 'Great');
        Test.setCurrentPageReference(templateManager);

        Test.startTest();
        TemplateManagerController controller =
            new TemplateManagerController(new ApexPages.StandardController(new Survey__c()));
        PageReference newPage = controller.newTemplate();
        Test.stopTest();
        System.assertEquals(newPage, null);
    }

    /**
     * Test use it
     */
    static testMethod void testUseIt() {

        PageReference templateManager = Page.TemplateManager;

        Survey__c survey = SurveyDOTest.createPpiTemplate();
        survey.Version__c = 2;
        survey.RemoteId__c = null;
        insert survey;
        TestSurveyData testSurvey = TestSurveyData.createSamplePPITemplateQuestions(survey);
        templateManager.getParameters().put(C.BASE_TEMPLATES, testSurvey.testSurvey.Id);
        Test.setCurrentPageReference(templateManager);

        Test.startTest();
        TemplateManagerController controller =
            new TemplateManagerController(new ApexPages.StandardController(new Survey__c()));
        PageReference newPage = controller.useIt();
        String expectedUrl = newPage.getUrl().subString(0, newPage.getUrl().indexOf('?'));
        Test.stopTest();
        System.assertEquals(expectedUrl, Page.SurveySetting.getUrl());
        System.assertEquals(newPage.getParameters().get(C.START_FORM), C.CREATE_FROM_TEMPLATE);
        System.assertEquals(newPage.getParameters().get(C.BASE_TEMPLATES), testSurvey.testSurvey.Id);
        QuestionDo questionDomain = new QuestionDo();
        assertQuestionPPIResults(testSurvey.testSurvey, questionDomain);
    }

    /**
     * Test Distribute
     */
    static testMethod void testDistribute() {
        Survey__c survey = SurveyDOTest.createPpiTemplate();
        survey.Version__c = 2;
        survey.RemoteId__c = null;
        insert survey;
        TestSurveyData testSurvey = TestSurveyData.createSamplePPITemplateQuestions(survey);
        PageReference templateManager = Page.TemplateManager;
        templateManager.getParameters().put(C.BASE_TEMPLATES, testSurvey.testSurvey.Id);
        Test.setCurrentPageReference(templateManager);
        Test.startTest();
        TemplateManagerController controller =
            new TemplateManagerController(new ApexPages.StandardController(new Survey__c()));
        PageReference newPage = controller.distributeIt();
        Test.stopTest();
        QuestionDo questionDomain = new QuestionDo();
        assertQuestionPPIResults(testSurvey.testSurvey, questionDomain);
    }

    /**
     * Test edit it
     */
    static testMethod void testEditIt() {

        PageReference templateManager = Page.TemplateManager;
        templateManager.getParameters().put(C.BASE_TEMPLATES, 'North');
        Test.setCurrentPageReference(templateManager);

        Test.startTest();
        TemplateManagerController controller =
            new TemplateManagerController(new ApexPages.StandardController(new Survey__c()));
        PageReference newPage = controller.editIt();
        String expectedUrl = newPage.getUrl().subString(0, newPage.getUrl().indexOf('?'));
        Test.stopTest();
        System.assertEquals(expectedUrl, Page.SurveySetting.getUrl());
        System.assertEquals(newPage.getParameters().get(C.START_FORM), C.EDIT_TEMPLATE);
        System.assertEquals(newPage.getParameters().get('id'), 'North');
    }

    /**
     * Test delete it
     */
    static testMethod void testDeleteIt() {

        List<Survey__c> surveys = new List<Survey__c>();
        Survey__c s1 = new Survey__c(
            Name = 'Test Template',
            Description__c  = 'This is a description & % <',
            Version__c = 1.0
        );
        surveys.add(s1);
        Database.insert(surveys);

        // Add Questions, Skip Logic, etc
        Question__c q1 = newQuestion(s1, null, 'section', 'q1', 'Caption1', 1);
        Database.insert(q1);
        Question__c q2 = newQuestion(s1, q1, 'text', 'q2', 'Caption2', 2);
        Database.insert(q2);

        PageReference templateManager = Page.TemplateManager;
        templateManager.getParameters().put(C.BASE_TEMPLATES, s1.id);
        Test.setCurrentPageReference(templateManager);

        Test.startTest();
        TemplateManagerController controller =
            new TemplateManagerController(new ApexPages.StandardController(new Survey__c()));
        controller.surveyIdToDelete = s1.id;
        controller.deleteIt();
        Test.stopTest();
        Survey__c[] deletedSurveys = [SELECT Id FROM Survey__c WHERE id = :s1.Id];
        System.assert(deletedSurveys.isEmpty());
    }

    /**
     * Test filter display
     */
    static testMethod void testFilter() {

        // Add license to insert new survey
        LicenseSettings__c license = C.getLicense();
        license.PPI_Editable__c = true;
        license.UsePPI__c = true;
        license.UseTemplates__c = true;
        update license;

        // Create a country code and a language
        Database.insert(new Language__c( Name='JJ', ShortLanguageName__c = 'TEST' ));
        Database.insert(new ISO_Country__c( Name='JJ', ShortName__c = 'TEST' ));

        List<Survey__c> surveys = new List<Survey__c>();
        Survey__c s1 = new Survey__c(
            Name = 'Test Filter 1',
            Description__c  = 'This is a description & % <',
            Version__c = 1.0,
            PPIDataYear__c = 2012,
            CountryCode__c = 'JJ',
            LanguageCode__c = 'JJ',
            IsPPI__c = true,
            IsTemplate__c = true
        );
        surveys.add(s1);
        Survey__c s2= new Survey__c(
            Name = 'Test Filter 2',
            Description__c  = 'This is a description & % <',
            Version__c = 1.0,
            IsTemplate__c = true
        );
        surveys.add(s2);
        Database.insert(surveys);

        PageReference templateManager = Page.TemplateManager;
        Test.setCurrentPageReference(templateManager);
        Test.startTest();
        TemplateManagerController controller =
            new TemplateManagerController(new ApexPages.StandardController(new Survey__c()));

        // Test set up
        System.assertEquals(controller.getTemplates().size(), 2);

        // Test get template only
        templateManager.getParameters().put(C.LIBRARY_NAME, 'default');
        templateManager.getParameters().put('showPpi', 'false');
        templateManager.getParameters().put('showAll', 'false');
        controller.filterDisplay();
        System.assertEquals(controller.getTemplates().size(), 1);

        // Test get PPPI only
        templateManager.getParameters().put('showPpi', 'true');
        templateManager.getParameters().put('showAll', 'false');
        controller.filterDisplay();
        System.assertEquals(controller.getTemplates().size(), 1);

        // Test get all
        templateManager.getParameters().put('showPpi', 'true');
        templateManager.getParameters().put('showAll', 'true');
        controller.filterDisplay();
        System.assertEquals(controller.getTemplates().size(), 2);
        Test.stopTest();
    }

    /**
     * Test method to verify fetching of SurveyVersion records with status not equal to Deprecated
     */
    static testMethod void testFetchingOfSurveyVersionRecords() {

        // Create survey with Status Draft
        Survey__c surveyWithStatusDraft = SurveyDOTest.createInsertedPpiTemplate();
        System.assert(surveyWithStatusDraft != null, 'Survey record could not be created.');

        // Create survey with Status Deprecated
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
        TemplateManagerController controller =
            new TemplateManagerController(new ApexPages.StandardController(new Survey__c()));
        controller.setUpPagination(true);
        Test.stopTest();

        System.assert(controller.paginator != null, 'Records are not assigned properly.');
        List<SurveyVersion__c> surveyVersionList =
            (List<SurveyVersion__c>) controller.paginator.getRecords();
        System.assert(
            surveyVersionList.size() == 1,
            'Survey Version records could not be fetched.'
        );
        System.assert(surveyVersionList[0].Survey__r.Status__c != SurveyDO.STATUS_DEPRECATED);
    }

    /**
     * Method to verify asserts for all Questions that have their PPIResults field populated
     */
    public static void assertQuestionPPIResults(Survey__c testSurvey, QuestionDo questionDomain) {
        // Prepare for values so that we can provide proper system asserts.
        String namespace = C.getClassNameSpace(QuestionDO.class.getName());
        namespace = (namespace == null) ? '' : namespace + '__';
        List<Schema.PicklistEntry> picklistValuesPPIResults =
            DescribeHandler.getFieldPicklist(questionDomain.sObjectName, namespace + 'PpiResultsField__c');
        QuestionSelector selector = new QuestionSelector();
        Integer recordCount = 0;
        for (Question__c questionInstance : selector.getAllForPpiSurveyId(testSurvey.Id)) {
            if (questionInstance.get(namespace + 'Parent__c') != null) {
                System.assertEquals(
                    picklistValuesPPIResults[recordCount].getValue(),
                    String.valueOf(questionInstance.get(namespace + 'PpiResultsField__c')),
                    'Field API and PPIResults field value does not match'
                );
                recordCount++;
            }
        }
    }
}