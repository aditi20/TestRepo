/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
private class SurveySettingsControllerTest {
    // Constants
    private static final String TITLE = '__Test__ Title';
    private static final String ANOTHER_TITLE = '__Test__ Another Title';

    //------------------------------
    // Helper methods
    //------------------------------

    private static Survey__c createTestSurvey(Boolean isTemplate) {
        LicenseSettings__c license = newLicense(true, 'Test1');
        insert license;
        String testLangauageName = 'EN';
        insert new Language__c(Name = testLangauageName, ShortLanguageName__c = 'ENLanguage');

        return SurveyDOTest.createInsertedSurvey(
            new Map<Schema.SObjectField, Object>{
                Survey__c.Name => 'Survey To Clone',
                Survey__c.Alias__c => 'Test Alias',
                Survey__c.Description__c => 'Test Description',
                Survey__c.Deployment__c => 'Smartphone',
                Survey__c.Gps_Location_Enabled__c => false,
                Survey__c.Gps_ShowMap__c => true,
                Survey__c.Survey__c.LanguageCode__c => testLangauageName,
                Survey__c.Close_Message__c => 'Test close message',
                Survey__c.Password__c => 'TestPass',
                Survey__c.IsTemplate__c => isTemplate,
                Survey__c.IsPPI__c => false
            }
        );
    }

    // Helper method to compare the cloned surveys
    private static void compareClonedSurveys(Survey__c original, Survey__c cloned) {

        // Assert that all the fields of the survey that should be cloned were cloned
        System.assertNotEquals(original.Id, cloned.Id);
        System.assertEquals(original.PPIDataYear__c, cloned.PPIDataYear__c);
        System.assertEquals(original.Deployment__c, cloned.Deployment__c);
        System.assertEquals(original.IsPPI__c, cloned.IsPPI__c);
        System.assertEquals(original.LanguageCode__c, cloned.LanguageCode__c);
        System.assertEquals(original.CountryCode__c, cloned.CountryCode__c);

        System.assertNotEquals(original.Alias__c, cloned.Alias__c);
    }

    /**
    * Compare the questions of origina and cloned survey
    * <p>
    * Corresponding question must be equals
    *
    * @param original   Original Survey
    * @param cloned     Survey copy from Original Survey
    */
    private static void compareQuestionsClonedSurveys(Survey__c original, Survey__c cloned){

        //retrieve all question from original survey
        Question__c[] originalQuestions=[SELECT
                                            q.Id,
                                            q.Name,
                                            q.Caption__c,
                                            q.Position__c,
                                            q.Type__c
                                          FROM Question__c q
                                          WHERE
                                            q.Survey__c=: original.Id
                                        ];

        //retrieve all questions from cloned survey
        Question__c[] clonedQuestions=[SELECT
                                            q.Id,
                                            q.Name,
                                            q.Caption__c,
                                            q.Position__c,
                                            q.Type__c
                                          FROM Question__c q
                                          WHERE
                                            q.Survey__c=: cloned.Id
                                        ];

        //check the number or questions is the same for both surveys
        System.assertEquals(originalQuestions.size(), clonedQuestions.size(), 'Number of questions of original survey and its clone must be same.');

        //compare questsion in paralel
        for (Integer i=0; i<originalQuestions.size(); i++){

          compareQuestion(originalQuestions[i], clonedQuestions[i]);
        }
    }

    /**
    * Compare two questions from similar surveys
    * <p>
    * All attributes must be equals, except the record Id.
    *
    * @param originalQuestion   Original Question
    * @param clonedQuestion     Copy of question
    */
    private static void compareQuestion(Question__c originalQuestion, Question__c clonedQuestion){

      System.assertNotEquals(originalQuestion.Id, clonedQuestion.Id);
      System.assertEquals(originalQuestion.Name, clonedQuestion.Name);
      System.assertEquals(originalQuestion.Caption__c, clonedQuestion.Caption__c);
      System.assertEquals(originalQuestion.Position__c, clonedQuestion.Position__c);
      System.assertEquals(originalQuestion.Type__c, clonedQuestion.Type__c);
    }

    /**
     * This method delete de original license and create a new one
     */
    static LicenseSettings__c newLicense(Boolean PPIEditable, String licenseName) {
        list<LicenseSettings__c> license =
            [SELECT PPI_Editable__c FROM LicenseSettings__c LIMIT 1];
        delete license;
        LicenseSettings__c newLicense = new LicenseSettings__c(
            PPI_Editable__c = PPIEditable,
            Name = licenseName
        );
        return newLicense;
    }

    /**
     * This method inserts one survey and try to validate another with the same TITLE.
     * expects error message
     */
    static testMethod void testTitleRepeated() {

        LicenseSettings__c testWithLicense = newLicense(false, 'Test1');
        insert testWithLicense;

        Survey__c survey = SurveyDOTest.createInsertedSurvey();
        Survey__c anotherSurvey = SurveyDOTest.createInsertedSurvey(ANOTHER_TITLE);

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id',anotherSurvey.Id);
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(anotherSurvey);
        SurveySettingsController extension =
            new SurveySettingsController(stdController);
        extension.survey.Name = SurveyDOTest.TEST_SURVEY_NAME;
        extension.validateTitleNotRepeated();
        Test.stopTest();

        System.assert(extension.hasError);
        System.assertEquals(extension.saveSettingContinue(), null);
    }

    /**
     * This method inserts one survey and then validates another with different TITLE
     * Expects no error message
     */
    static testMethod void testTitleNotRepeated() {

        LicenseSettings__c testWithLicense = newLicense(false, 'Test1');
        insert testWithLicense;

        Survey__c survey = SurveyDOTest.createInsertedSurvey();
        Survey__c anotherSurvey = SurveyDOTest.createInsertedSurvey(ANOTHER_TITLE);

        Test.startTest();
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(anotherSurvey);
        SurveySettingsController extension = new SurveySettingsController(stdController);
        extension.validateTitleNotRepeated();
        Test.stopTest();

        System.assert(!extension.hasError);
    }

    /**
     * Test the quick save method
     */
    static testMethod void testQuickSave() {

        LicenseSettings__c testWithLicense = newLicense(false, 'Test1');
        insert testWithLicense;
        Survey__c survey = SurveyDOTest.createTestSurveyRecord(TITLE);

        Test.startTest();
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(survey);
        SurveySettingsController extension = new SurveySettingsController(stdController);
        extension.survey.Name = ANOTHER_TITLE;
        extension.quicksave();
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT Name FROM Survey__c WHERE Name = :ANOTHER_TITLE].size()
        );
    }

    /**
     * Test for saveSettingContinue method.
     */
    static testMethod void testSaveSettingContinueTest() {

        LicenseSettings__c testWithLicense = newLicense(false,'Test1');
        insert testWithLicense;

        Survey__c survey = SurveyDOTest.createTestSurveyRecord();

        Test.startTest();

        ApexPages.Standardcontroller stdController = new ApexPages.StandardController(survey);
        SurveySettingsController extension = new SurveySettingsController(stdController);
        PageReference pg = extension.saveSettingContinue();

        Test.stopTest();
        Survey__c newSurvey =
            (Survey__c) new SurveySelector().getRecordById(survey.Id);

        PageReference createdPage = Page.SurveyQuestion;
        System.assertEquals(
            SurveyDO.DEPLOYMENT_VALUE,
            newSurvey.Deployment__c,
            'The Deployment__c Device is saved internally, it is "' +
                SurveyDO.DEPLOYMENT_VALUE + '"'
        );
        System.assert(pg != null, 'There was an error saving the survey.');
        System.assertEquals(pg.getUrl() , createdPage.getUrl() + '?id=' + newSurvey.Id );
    }

    /**
    *   Test for clone survey radio button
    */
    static testMethod void testSaveSettingContinueClone() {

        String testName = 'This is a Test';
        Survey__c surveyToClone = createTestSurvey(false);

        System.currentPageReference().getParameters().put(C.START_FORM, C.CLONE_SURVEY);
        System.currentPageReference().getParameters().put(C.BASE_SURVEY, surveyToClone.Id);

        Test.startTest();

        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(new Survey__c(Name = 'test'));
        SurveySettingsController extension = new SurveySettingsController(stdController);
        extension.survey.Name = testName;
        extension.Survey.Alias__c = 'Different Test Alias';
        extension.saveSettingContinue();
        Test.stopTest();

        if (extension.hasError) {
            System.assert(
                false,
                'Unexpected exception while cloning PPI survey: ' + ApexPages.getMessages()[0]
            );
        }

        // Get the cloned survey
        Survey__c cloned =
            new SurveySelector().getByName(testName, SObjectSelector.EQUALS_OPERATOR)[0];

        System.assertEquals(cloned.Name, testName);

        // Verify normal cloned survey populates isCloned as true
        System.assert(cloned.isCloned__c);
        compareClonedSurveys(surveyToClone, cloned);
        compareQuestionsClonedSurveys(surveyToClone, cloned);
    }

    /**
    * Verify error exists when a Survey to clone is not selected
    */
    static testMethod void testSaveSettingContinueCloneNotSelectedSurvey() {

        String testName = 'This is a Test';
        Survey__c surveyToClone = createTestSurvey(false);

        // Set parameters to indicate the survey that we want to clone
        System.currentPageReference().getParameters().put('group1', 'existingSurvey');
        System.currentPageReference().getParameters().put('baseSurvey', surveyToClone.Id);

        Test.startTest();

        // Prepare the controller
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(new Survey__c(Name = 'test'));
        SurveySettingsController extension = new SurveySettingsController(stdController);

        // Change the name of the survey and save
        extension.Survey.Name = testName;
        extension.Survey.Alias__c = 'Different Test Alias';

        extension.surveyToClone = null;
        extension.saveSettingContinue();
        Test.stopTest();
        System.assert(extension.hasError, 'The survey to clone must exist.');
        System.assertEquals(2, ApexPages.getMessages().size());
        System.assert(
            ApexPages.getMessages()[0].getSummary().contains(
                String.format(
                    System.Label.SURVEY_MANAGER_FAILED_CLONE,
                    new List<String>{'Survey'}
                )
            ),
            'First message should contain: ' +
                String.format(
                    System.Label.SURVEY_MANAGER_FAILED_CLONE,
                    new List<String>{'Survey'}
                ) +
                '. It acutally is: ' + ApexPages.getMessages()[0].getSummary()
        );
        System.assert(
            ApexPages.getMessages()[1].getSummary().contains(
                System.Label.SURVEY_ERR_NOSURVEYSELECTED
            ),
            'First message should contain: ' +
                System.Label.SURVEY_ERR_NOSURVEYSELECTED +
                '. It acutally is: ' + ApexPages.getMessages()[1].getSummary()
        );

    }

    /**
     * Save an already cloned Survey
     *
     * Clone an existing survey and save it again.
     * We expect to be redirected to the settings page with the new Id
     */
    static testMethod void testSaveSettingsOfClonedSurvey() {
        Survey__c surveyToClone = createTestSurvey(false);
        UnitOfWork unitOfWork = new UnitOfWork(
            new List<Schema.SObjectType>{
                Question__c.getSObjectType(),
                Question__c.getSObjectType()
            }
        );

        Question__c section = QuestionDOTest.createSection(0);
        unitOfWork.addToInsertList(section, Question__c.Survey__c, surveyToClone);
        Question__c question =
            QuestionDOTest.createQuestion(QuestionDO.TYPE_TEXT_SHORT,'Question', 'Question', 1);
        unitOfWork.addToInsertList(question, Question__c.Survey__c, surveyToClone, 2);
        unitOfWork.createRelationship(question, Question__c.Parent__c, section, 2);
        unitOfWork.commitWork();

        // Set parameters to indicate the survey that we want to clone
        System.currentPageReference().getParameters().put('group1', C.CLONE_SURVEY);
        System.currentPageReference().getParameters().put('baseSurvey', surveyToClone.Id);

        Test.startTest();

        // Prepare the controller
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(new Survey__c(Name = 'test'));
        SurveySettingsController extension = new SurveySettingsController(stdController);

        // Change the name of the survey and save
        extension.Survey.Name = 'this is a test';
        extension.Survey.Alias__c = 'Different Test Alias';
        PageReference pageref = extension.quicksave();
        Test.stopTest();
        System.assertNotEquals(
            null,
            pageref,
            'User was not redirected to settings page'
        );
        System.assertNotEquals(
            null,
            pageref.getParameters().get('id'),
            'Redirected page did not contain cloned survey id parameter'
        );
    }

    /**
    *   Test for clone from a template
    */
    static testMethod void testSaveSettingContinueCloneTemplate() {

        Survey__c surveyToClone = createTestSurvey(true);

        // Set parameters to indicate the survey that we want to clone
        System.currentPageReference().getParameters().put(C.START_FORM, C.CREATE_FROM_TEMPLATE);
        System.currentPageReference().getParameters().put(C.BASE_TEMPLATES, surveyToClone.Id);

        Test.startTest();
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(new Survey__c(Name = 'test'));
        SurveySettingsController extension = new SurveySettingsController(stdController);

        // Change the name of the survey and save
        String testName = 'this is a test';
        extension.survey.Name = testName;
        extension.Survey.Alias__c = 'Different Test Alias';
        extension.saveSettingContinue();

        Test.stopTest();
        if (extension.hasError) {
            System.assert(
                false,
                'Unexpected exception while cloning template: ' + ApexPages.getMessages()[0]
            );
        }

        Survey__c cloned =
            new SurveySelector().getByName(testName, SObjectSelector.EQUALS_OPERATOR)[0];

        System.assertEquals(cloned.Name, testName);
        System.assert(!cloned.IsTemplate__c);
    }

    /**
    * Test for clone survey radio button with a PPI survey
    */
    static testMethod void testSaveSettingContinueClonePPI() {

        LicenseSettings__c license = C.getLicense();
        license.PPI_Editable__c = true;
        license.UsePPI__c= true;
        update license;

        TestSurveyData testSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedPpiTemplate(),
                    false
                )
            );

        // Reload the survey to get the name
        Survey__c surveyToClone =
            (Survey__c) new SurveySelector().getRecordsByOnlyIdWithAllFields(
                new Set<Id>{testSurvey.testSurvey.Id}
            )[0];

        // Set parameters to indicate the survey that we want to clone
        System.currentPageReference().getParameters().put('group1', 'existingSurvey');
        System.currentPageReference().getParameters().put('baseSurvey', surveyToClone.Id);

        Test.startTest();
        // Prepare the controller
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(new Survey__c(Name = 'test'));
        SurveySettingsController extension = new SurveySettingsController(stdController);

        // Change the year of the PPI survey and save
        Integer newPpiyear = 2014;
        extension.survey.PPIDataYear__c = newPpiyear;
        extension.survey.Name = 'New PPI Survey';
        extension.Survey.Alias__c = 'Different Test Alias';
        extension.saveSettingContinue();
        Test.stopTest();

        if (extension.hasError) {
            System.assert(
                false,
                'Unexpected exception while cloning PPI survey: ' + ApexPages.getMessages()[0]
            );
        }

        // Get the cloned survey
        Survey__c clonedSurvey =
            (Survey__c) new SurveySelector().getRecordsByOnlyIdWithAllFields(
            new Set<Id>{extension.survey.Id}
        )[0];

        // Change the PPI data year to be the same as the cloned one so the comparison can work
        surveyToClone.PPIDataYear__c = newPpiyear;

        compareClonedSurveys(surveyToClone, clonedSurvey);
    }

    /**
     * Test that save and continue fails for surveys with repeated names
     */
    static testMethod void testRepeatedNamesFail(){
        Survey__c survey = new Survey__c(Name='__test1');
        insert survey;
        Survey__c surveyWithError = new Survey__c(Name='__test1');

        Test.startTest();
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(surveyWithError);
        SurveySettingsController extension = new SurveySettingsController(stdController);
        extension.saveSettingContinue();
        Test.stopTest();
        System.assert(extension.hasError);
    }

    /**
     * Test for saveSettingContinue method with survey in the header.
     */
    static testMethod void testSaveSettingContinueSurveyIncludedTest() {

        Survey__c survey = createTestSurvey(false);

        ApexPages.Standardcontroller stdController = new ApexPages.StandardController(survey);
        ApexPages.currentPage().getParameters().put('id', survey.Id);

        Test.startTest();
        SurveySettingsController extension = new SurveySettingsController(stdController);
        PageReference pg = extension.saveSettingContinue();
        PageReference createdPage = new PageReference('/apex/surveyquestion');
        Test.stopTest();
        system.assert(pg != null, 'There was an error saving the survey.');
        system.assertEquals(pg.getUrl() , createdPage.getUrl() + '?id=' + survey.Id );
    }

    /**
     * Test for save a published survey,it should fail
     */
    static testMethod void testSaveFailsSurveyPublished() {

        Survey__c survey = createTestSurvey(false);
        SurveyVersion__c version = [
            SELECT Id, Status__c, Distributed__c, DistributionDate__c
            FROM SurveyVersion__c
            WHERE Survey__c = :survey.Id
        ];
        version.Status__c = SurveyDO.STATUS_PUBLISHED;
        update version;

        Test.startTest();
        ApexPages.Standardcontroller stdController = new ApexPages.StandardController(survey);
        ApexPages.currentPage().getParameters().put('id', survey.Id);
        SurveySettingsController extension = new SurveySettingsController(stdController);
        extension.survey.Description__c = 'SomeDescription';
        Test.stopTest();

        System.assertEquals(
            System.label.BUILDER_ERR_SURVEYALREADYPUBLISHED,
            ApexPages.getMessages()[0].getDetail()
        );
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages()[0].getSeverity()
        );
    }

    /**
     * Test use it Parent Ppi Template populates PpiIdentifier properly
     */
    static testMethod void testUseItParentPpiTemplate() {

        // Create PPI template for Parent
        Survey__c parentPpiTemplate = SurveyDOTest.createInsertedPpiTemplate();

        parentPpiTemplate = (Survey__c) new SurveySelector().getRecordbyId(parentPpiTemplate.Id);
        System.assert(
            parentPpiTemplate != null,
            'Ppi template not fetched properly'
        );
        System.assert(
            parentPpiTemplate.PpiIdentifier__c != null,
            'PPI Identifier is not populated properly for Parent ppi template'
        );

        // Set parameters to indicate the survey that we want to clone
        System.currentPageReference().getParameters().put(C.START_FORM, C.CREATE_FROM_TEMPLATE);
        System.currentPageReference().getParameters().put(C.BASE_TEMPLATES, parentPpiTemplate.Id);

        Test.startTest();
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(new Survey__c());
        SurveySettingsController extension = new SurveySettingsController(stdController);

        // Add the name of the survey and save
        String testName = 'This is a Use It survey for Parent template';
        extension.survey.Name = testName;
        extension.Survey.Alias__c = 'Different Test Alias';
        extension.saveSettingContinue();
        Test.stopTest();

        List<Survey__c> useItSurveyList =
            new SurveySelector().getByName(testName, SObjectSelector.EQUALS_OPERATOR);
        System.assertEquals(1, useItSurveyList.size());

        // Use It Survey has Ppi Identifier populated similar to its parent PPI template
        System.assertEquals(parentPpiTemplate.PpiIdentifier__c, useItSurveyList[0].PpiIdentifier__c);
        System.assertEquals('KENYA_2012', useItSurveyList[0].PpiIdentifier__c);

        // Verify that use It template on parent org populates isCloned as false
        System.assert(!useItSurveyList[0].isCloned__c);
    }

    /**
     * Test use it downloaded Ppi Template populates PpiIdentifier properly
     */
    static testMethod void testUseItDownloadedPpiTemplate() {

        // Create a downloaded Ppi Template on child
        Survey__c childPpiTemplate = SurveyDOTest.createInsertedPpiTemplate();
        childPpiTemplate.RemoteId__c = 'TestId';
        SurveyDO surveyDOInstance = new SurveyDO();
        surveyDOInstance.addRecord(childPpiTemplate);
        surveyDOInstance.updateRecords();

        childPpiTemplate = (Survey__c) new SurveySelector().getRecordbyId(childPpiTemplate.Id);
        System.assert(
            childPpiTemplate != null,
            'Downloaded template not fetched properly'
        );
        System.assert(
            childPpiTemplate.PpiIdentifier__c != null,
            'PPI Identifier is not populated properly for downloaded ppi template'
        );

        // Set parameters to indicate the survey that we want to clone
        System.currentPageReference().getParameters().put(C.START_FORM, C.CREATE_FROM_TEMPLATE);
        System.currentPageReference().getParameters().put(C.BASE_TEMPLATES, childPpiTemplate.Id);

        Test.startTest();
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(new Survey__c());
        SurveySettingsController extension = new SurveySettingsController(stdController);

        // Add the name of the survey and save
        String testName = 'This is a Use It survey';
        extension.survey.Name = testName;
        extension.Survey.Alias__c = 'Different Test Alias';
        extension.saveSettingContinue();
        Test.stopTest();

        List<Survey__c> useItSurveyList =
            new SurveySelector().getByName(testName, SObjectSelector.EQUALS_OPERATOR);
        System.assertEquals(1, useItSurveyList.size());

        // Use It Survey has Ppi Identifier populated similar to its downloaded PPI template
        System.assertEquals(childPpiTemplate.PpiIdentifier__c, useItSurveyList[0].PpiIdentifier__c);
        System.assertEquals('KENYA_2012', useItSurveyList[0].PpiIdentifier__c);

        // Verify that use It survey populates isCloned as false
        System.assert(!useItSurveyList[0].isCloned__c);
    }

    /**
     * Test clone use it Ppi Survey on child org populates PpiIdentifier properly
     */
    static testMethod void testCloneUseItPpiSurvey() {

        // Create a downloaded Ppi Template on child
        Survey__c childPpiUseItSurvey = SurveyDOTest.createInsertedPpiTemplate();
        childPpiUseItSurvey.RemoteId__c = 'TestId';
        childPpiUseItSurvey.IsTemplate__c = false;
        SurveyDO surveyDOInstance = new SurveyDO();
        surveyDOInstance.addRecord(childPpiUseItSurvey);
        surveyDOInstance.updateRecords();

        childPpiUseItSurvey = (Survey__c) new SurveySelector().getRecordbyId(childPpiUseItSurvey.Id);
        System.assert(
            childPpiUseItSurvey != null,
            'Use It template not fetched properly'
        );
        System.assert(
            childPpiUseItSurvey.PpiIdentifier__c != null,
            'PPI Identifier is not populated properly for downloaded ppi template'
        );

        // Set parameters to indicate the survey that we want to clone
        System.currentPageReference().getParameters().put(C.START_FORM, C.CLONE_SURVEY);
        System.currentPageReference().getParameters().put(C.BASE_SURVEY, childPpiUseItSurvey.Id);

        Test.startTest();
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(new Survey__c());
        SurveySettingsController extension = new SurveySettingsController(stdController);

        // Add the name of the survey and save
        String testName = 'This is a Clone Use It survey';
        extension.survey.Name = testName;
        extension.Survey.Alias__c = 'Different Test Alias';
        extension.saveSettingContinue();
        Test.stopTest();

        List<Survey__c> clonedUseItSurveyList =
            new SurveySelector().getByName(testName, SObjectSelector.EQUALS_OPERATOR);

        // Cloned Survey has Ppi Identifier populated similar to its Use it PPI Survey
        System.assertEquals(
            childPpiUseItSurvey.PpiIdentifier__c,
            clonedUseItSurveyList[0].PpiIdentifier__c
        );
        System.assertEquals('KENYA_2012', clonedUseItSurveyList[0].PpiIdentifier__c);

        // Verify that cloned use it survey populates isCloned as true
        System.assert(clonedUseItSurveyList[0].isCloned__c);
    }

    /**
     * Test clone Ppi Template on parent org populates isCloned properly
     */
    static testMethod void testClonePpiTemplate() {

        // Create a Ppi Template on parent
        Survey__c parentPpiTemplate = SurveyDOTest.createInsertedPpiTemplate();
        parentPpiTemplate.IsTemplate__c = false;
        SurveyDO surveyDOInstance = new SurveyDO();
        surveyDOInstance.addRecord(parentPpiTemplate);
        surveyDOInstance.updateRecords();

        parentPpiTemplate = (Survey__c) new SurveySelector().getRecordbyId(parentPpiTemplate.Id);
        System.assert(
            parentPpiTemplate != null,
            'Parent Ppi template not fetched properly'
        );
        System.assert(
            parentPpiTemplate.PpiIdentifier__c != null,
            'PPI Identifier is not populated properly for ppi template'
        );

        // Verify that PPI Template have isCloned as false
        System.assert(!parentPpiTemplate.isCloned__c);

        // Set parameters to indicate the survey that we want to clone
        System.currentPageReference().getParameters().put(C.START_FORM, C.CLONE_PPI_TEMPLATE);
        System.currentPageReference().getParameters().put(C.BASE_SURVEY, parentPpiTemplate.Id);

        Test.startTest();
        ApexPages.Standardcontroller stdController =
            new ApexPages.StandardController(new Survey__c());
        SurveySettingsController extension = new SurveySettingsController(stdController);

        // Add the name of the survey and save
        String testName = 'This is a Clone PPI template';
        extension.survey.Name = testName;
        extension.Survey.Alias__c = 'Different Test Alias';
        extension.saveSettingContinue();
        Test.stopTest();

        List<Survey__c> clonedPpiTemplateList =
            new SurveySelector().getByName(testName, SObjectSelector.EQUALS_OPERATOR);
        System.assertEquals(1, clonedPpiTemplateList.size());

        // Cloned Ppi Template has Ppi Identifier populated similar to its main PPI template
        System.assertEquals(
            parentPpiTemplate.PpiIdentifier__c,
            clonedPpiTemplateList[0].PpiIdentifier__c
        );
        System.assertEquals('KENYA_2012', clonedPpiTemplateList[0].PpiIdentifier__c);

        // Verify that Cloned PPI Template populates isCloned as true
        System.assert(clonedPpiTemplateList[0].isCloned__c);
    }
}