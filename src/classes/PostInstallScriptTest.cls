/**
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved.
 *
 */
@isTest
private class PostInstallScriptTest {

    /**
     * Create and login a MobileUser
     */
    static TestUtils.Surveyor initMobileUser() {

        return TestUtils.createSurveyor(
            'lastNamePIS',
            'userPIS',
            'passPIS',
            MobileUserDo.STATUS_ACTIVE,
            true
        );
    }

    /**
     * Test method to verify that maxinstance for existing Question will get populated after post install method
     */
    static testMethod void testQuestionMaxInstance() {
        // Create Question - Answers pre data
        Test.startTest();
        List<Answer__c> listAnswer = AnswersTriggerTest.createAfterUpdatePreConditions(2, 3);
        insert listAnswer;
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, new Version(2, 27));
        Test.stopTest();
        if (listAnswer != null && !listAnswer.isEmpty()) {
            System.assertEquals(
                3, 
                [
                    SELECT
                        Question__r.MaxInstance__c
                    FROM
                        Answer__c
                    WHERE
                        Id = :listAnswer[0].Id
                ].Question__r.MaxInstance__c);
        }
    }

    /**
     * Test method to verify that data of Value__c field is transferred to newly created
     * SkipValue__c field for existing Skip conditions
     */
    static testMethod void testExistingSkipCondition() {
        // Fetch skip condition records related to multiple types of questions
        List<SkipCondition__c> listConditions = TestUtils.createSkipConditions();
        TestUtils.insertSkipConditionRecords(listConditions);

        // Verify the all skip condition records have no data in newly created SkipValue__c
        System.assertEquals(
            listConditions.size(),
            [
                SELECT
                    SkipValue__c
                FROM
                    SkipCondition__c
                WHERE
                    SkipValue__c = null
            ].size()
        );

        Test.startTest();
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, new Version(2, 27));
        Test.stopTest();

        // Verify the all skip condition record's Value__c data is transferred to SkipValue__c
        System.assertEquals(
            listConditions.size(),
            [
                SELECT
                    SkipValue__c
                FROM
                    SkipCondition__c
                WHERE
                    SkipValue__c != null
            ].size()
        );
    }

    /**
     * Test creating default Settings__c
     */
    static testMethod void testDefaultSettings() {

        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, new Version(2,21,0));
        System.assertEquals(
            ApplicationSettingsUtils.JOBS_FILTER_ALL,
            ApplicationSettingsUtils.getDefaultSetting(false).FilterJobsBySalesforceUser__c
        );
    }

    static testMethod void testFreshInstall() {
        delete [SELECT Id FROM ISO_Country__c];
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, null);
        Map<String, ISO_Country__c> currentcountries  = ISO_Country__c.getAll();
        System.assert(!currentcountries.isEmpty(), 'List of countries was not set up');
        System.assertEquals(PostInstallScript.allCountryCodes.size(), currentcountries.size());
    }

    static testMethod void testCheckOrphanMappings(){
        // Create an oprphan survey mapping
        SurveyMapping__c sm = new SurveyMapping__c(Survey__c = null, ObjectApiName__c = 'Account');
        // Insert the mapping
        insert sm;
        // Check that the mapping was inserted
        system.assert(![SELECT Id FROM SurveyMapping__c WHERE Survey__c = null].isEmpty(), 'Should be at least one element');
        // Run the post install script
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, new Version(1,1,0));
        // Check that does not exist orphan survey mappings after the install
        system.assert([SELECT Id FROM SurveyMapping__c WHERE Survey__c = null].isEmpty(), 'Should be empty since when install there is a script that remove all the orphan survey mappings');
    }

    static testMethod void testPPILicenseOnFreshInstall() {
        // Run the post install script
        Test.testInstall(new PostInstallScript(), null);
        LicenseSettings__c license = C.getLicense();
        System.assertEquals(false, license.Can_Distribute__c);
        System.assertEquals(false, license.PPI_Editable__c);
        System.assertEquals(true , license.DownloadPPI__c);
        System.assertEquals(true , license.UsePPI__c);
        System.assertEquals(false, license.CreateTemplates__c);
        System.assertEquals(false, license.DeleteTemplates__c);
        System.assertEquals(false, license.DownloadTemplates__c);
        System.assertEquals(false, license.EditTemplates__c);
        System.assertEquals(false, license.UseTemplates__c);
    }

    static testMethod void testMoveAnswerTextValue(){
        // This method tests absolutely nothing.
        // It's here just to get code coverage for the moveAnswerTextValue method.
        // The actual logic for the process is tested in PostInstallScript_011000MoveAnswerText.cls
        insert new Settings__c(Name = C.TEST_ANSWER_TEXT_VALUE);
        PostInstallScript postinstall = new PostInstallScript();
        postinstall.setVersion(1,10,0);
    }

    /**
     * Test method to verify new Application Version Custom Setting record
     * is created on package installation.
     */
    static testMethod void testAddApplicationVersionSetting() {
        runApplicationVersionTest(ApplicationVersionSettingsSelectorTest.setUpTestData());
    }

    /**
     * Test method to verify application version Settings record is not created
     * if it already exists
     */
    static testMethod void testNotAddingApplicationVersionSetting() {

        ApplicationVersionSettingsSelectorTest.TestData testData =
            ApplicationVersionSettingsSelectorTest.setUpTestData();

        ApplicationVersionSettings__c applicationVersionSettingInstance =
            ApplicationVersionSettingsSelectorTest.createRecord(
                DateTime.now(),
                testData.versionNumber,
                testData.downloadUrl,
                true,
                testData.mobileAPKVersion
            );
        insert applicationVersionSettingInstance;
        runApplicationVersionTest(testData);
    }

    /**
     * Test method to verify application version Settings record is created
     * with isActive = false if version is upgrading to 3.0
     */
    static testMethod void testVersionThreePackageUpgrade() {
        ApplicationVersionSettingsSelectorTest.TestData testData =
            new ApplicationVersionSettingsSelectorTest.TestData(
                '30000',
                '3.0',
                '3.0',
                'downloadUrl',
                '30000'
            );

        Test.startTest();
        PostInstallScript postinstall = new PostInstallScript();
        postinstall.setUpApplicationVersion(
            testData.versionNumber,
            testData.compatibleVersion,
            testData.oldestVersion,
            testData.downloadUrl,
            testData.mobileApkVersion
        );
        Test.testInstall(postinstall, new Version(2, 28, 0));
        Test.stopTest();

        ApplicationVersionSettings__c applicationSettingsInstance =
            ApplicationVersionSettingsSelector.getInstanceWithVersionNumber(
                testData.versionNumber
            );
        System.assert(
            applicationSettingsInstance != null,
            'Application Settings record should be created'
        );
        System.assert(
            !applicationSettingsInstance.isActive__c,
            'For version 3.0 upgrade, isActive should be false'
        );
    }

    /**
     * Test method to verify application version Settings record is created
     * with isActive = true if new version installed to 3.0
     */
    static testMethod void testVersionThreePackageInstall() {
        ApplicationVersionSettingsSelectorTest.TestData testData =
            new ApplicationVersionSettingsSelectorTest.TestData(
                '30000',
                '3.0',
                '3.0',
                'downloadUrl',
                '30000'
            );

        Test.startTest();
        PostInstallScript postinstall = new PostInstallScript();
        postinstall.setUpApplicationVersion(
            testData.versionNumber,
            testData.compatibleVersion,
            testData.oldestVersion,
            testData.downloadUrl,
            testData.mobileApkVersion
        );
        Test.testInstall(postinstall, null);
        Test.stopTest();

        ApplicationVersionSettings__c applicationSettingsInstance =
            ApplicationVersionSettingsSelector.getInstanceWithVersionNumber(
                testData.versionNumber
            );
        System.assert(
            applicationSettingsInstance != null,
            'Application Settings record should be created'
        );
        System.assert(
            applicationSettingsInstance.isActive__c,
            'For version 3.0 install, isActive should be true'
        );
    }

    /**
     * Carry out the tests for adding application version settings
     */
    static void runApplicationVersionTest(
            ApplicationVersionSettingsSelectorTest.TestData testData
    ) {

        Test.startTest();
        PostInstallScript postinstall = new PostInstallScript();
        postinstall.setUpApplicationVersion(
            testData.versionNumber,
            testData.compatibleVersion,
            testData.oldestVersion,
            testData.downloadUrl,
            testData.mobileApkVersion
        );
        Test.testInstall(postinstall, new Version(2,28,0));
        Test.stopTest();

        ApplicationVersionSettings__c applicationSettingsInstance =
            ApplicationVersionSettingsSelector.getInstanceWithVersionNumber(
                testData.versionNumber
            );
        System.assert(
            applicationSettingsInstance != null,
            'Application Settings record should be created'
        );
        System.assertEquals(
            0,
            new ApplicationVersionSelector().getRecords().size(),
            'There should be no Application Version records left'
        );
    }

    /**
     * Test method to verify old Application version records are migrated 
     * to Application Version Custom Settings
     */
    static testMethod void testMigrateToApplicationVersionSettings() {
        ApplicationVersion__c applicationVersion =
            ApplicationVersionDomainTest.createRecord(
                DateTime.now(),
                '1000',
                'downloadUrl',
                true
            );

        ApplicationVersionDomain applicationVersionDomain =
            new ApplicationVersionDomain.Constructor().constructWithRecords(
                new List<ApplicationVersion__c> {applicationVersion}
            );
        applicationVersionDomain.insertRecords();

        Test.startTest();
        PostInstallScript.migrateToApplicationVersionSettings();
        List<ApplicationVersionSettings__c> applicationVersionSettings =
            ApplicationVersionSettingsSelector.getRecords();
        Test.stopTest();

        System.assertEquals(
            1,
            applicationVersionSettings.size()
        );

        ApplicationVersionSettingsSelectorTest.TestData testData = 
            new ApplicationVersionSettingsSelectorTest.TestData(
                applicationVersionSettings[0].Name,
                applicationVersionSettings[0].CompatibleVersion__c,
                applicationVersionSettings[0].OldestConfirmedVersion__c,
                applicationVersionSettings[0].DownloadURL__c,
                applicationVersionSettings[0].MobileAPKVersion__c
            );

        // Verify test data with Appropriate asserts
        ApplicationVersionSettingsSelectorTest.verifyTestData(testData);
        System.assertEquals(
            0,
            new ApplicationVersionSelector().getRecords().size(),
            'There should be no Application Version records left'
        );
    }

    static testMethod void testAddGroupToSubmission() {
        // Prepare test data
        Survey__c survey = new Survey__c(Name = 'Survey', Status__c = SurveyDO.STATUS_PUBLISHED);
        insert survey;
        Question__c qSection = new Question__c(Name = 's1', Survey__c = survey.Id, Caption__c = 'section', Type__c = QuestionDO.TYPE_SECTION, Position__c = 1);
        insert qSection;

        Question__c q1 = new Question__c(Name = 'q1', Position__c = 1, Parent__c = qSection.Id, survey__c = survey.Id, Caption__c = 'Long Text', Type__c = QuestionDO.TYPE_TEXT_LONG);
        insert q1;

        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c DESC];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;


        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + survey.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<' + qSection.Name + '>' +
            '<'+ q1.Name +'>some answer</'+ q1.Name +'>'+
            '</' + qSection.Name + '>' +
            '</'+ survey.Name + '>';

        TestUtils.Surveyor surveyor = initMobileUser();

        // Create groups and assignments
        ServicesControllerTest.assignContactToSurvey(surveyor.theContact, survey.Id, C.GROUP_STATUS_ACTIVE);

        // Submit the answers
        Submission sub = new Submission(xml, surveyor.theContact.Id);
        sub.validateNewSubmission();
        ServicesController sc = new ServicesController();
        sc.submit(surveyor.loginResult, sub);

        // Check that the submission was successful
        List<Submission__c> submissions = [SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id];
        for(Submission__c submission : submissions) {
            submission.Assignment__c = null;
        }
        update submissions;

        // PREFORMING THE TEST
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, new Version(2,17,0));

        System.assertEquals(0, [SELECT Id FROM Submission__c WHERE Assignment__c = null].size());
    }

    /**
     * Check that the batch move the value of the TextValue__c field for those answer that have one.
     */
    static testMethod void testMoveValue() {
        Contact contactInst =  TestUtils.createContact();

        // Insert Survey and related submission
        Survey__c survey = TestUtils.createSurvey('TestSurvey');
        SurveyVersion__c version =  [SELECT
                                            Id
                                        FROM
                                            SurveyVersion__c
                                        WHERE
                                            Survey__c = :survey.Id
                                        LIMIT 1
                                    ];
        Submission__c submission = TestUtils.createSubmission(survey.Id, version.Id, contactInst.Id);
        insert submission;

        // Create Question related data
        Question__c sectionRegular = TestUtils.addQuestion(
            survey,
            1,
            'Section',
            QuestionDO.TYPE_SECTION
        );
        Question__c questionTextLong = TestUtils.addQuestion(
            sectionRegular,
            1,
            'QuestionLongText',
            QuestionDO.TYPE_TEXT_LONG
        );
        Question__c questionNumber = TestUtils.addQuestion(
            sectionRegular,
            2,
            'QuestionNumber',
            QuestionDO.TYPE_NUMBER
        );
        
        List<Answer__c> answers = new List<Answer__c>();
        // Insert some answers with a null text value
        for (Integer i = 0; i < 4; i ++) {
            answers.add(
                new Answer__c(
                Submission__c = submission.Id,
                Question__c = questionNumber.Id
                )
            );
        }
        // Insert some answers with an empty string as the text value
        for (Integer i = 0; i < 4; i ++) {
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    TextValue__c = '',
                    Question__c = questionNumber.Id
                )
            );
        }
        // Insert some answers with a text as the text value
        for (Integer i = 0; i < 4; i ++) {
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    TextValue__c = 'Some text ' + i,
                    Question__c = questionNumber.Id
                )
            );
        }
        // Insert some answers for the question text long
        for (Integer i = 0; i < 4; i ++) {
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    Value__c = 'Some text ' + i,
                    Question__c = questionTextLong.Id
                )
            );
        }
        insert answers;

        // Run the batch
        Test.startTest();
        Database.executeBatch(new PostInstallScript_011000MoveAnswerText());
        Test.stopTest();

        // Check that the value was moved for the non text long questions
        List<Answer__c> updatedAnswers = [SELECT
                                                 Id,
                                                 TextValue__c,
                                                 TextAreaValue__c
                                             FROM
                                                 Answer__c
                                             WHERE
                                                 Submission__c = :submission.Id
                                             AND
                                                 Question__c = :questionNumber.Id
                                         ];
        System.assertEquals(12, updatedAnswers.size());
        for (Integer i = 0; i < 12; i ++) {
            System.assertEquals(updatedAnswers[i].TextValue__c, updatedAnswers[i].TextAreaValue__c);
        }

        // Check that the value was moved for the text long questions
        updatedAnswers = [SELECT 
                                 Id,
                                 Value__c,
                                 TextAreaValue__c
                             FROM
                                 Answer__c
                             WHERE
                                 Submission__c = :submission.Id
                             AND
                                 Question__c = :questionTextLong.Id
                         ];
        System.assertEquals(4, updatedAnswers.size());
        for (Integer i = 0; i < 4; i ++) {
            System.assertEquals(updatedAnswers[i].Value__c, updatedAnswers[i].TextAreaValue__c);
        }
    }

    /**
     * Test method to check that AllowAnonymousInterviewee__c is set to false
     */
    static testMethod void testAllowAnonymousIntervieweeSetFalse() {

        create225SurveyPreConditions();
        run225Tests();
        List<Survey__c> testSurveys = [SELECT AllowAnonymousInterviewee__c FROM Survey__c];
        System.assertEquals(3, testSurveys.size());
        for (Survey__c survey : testSurveys) {
            System.assertEquals(false, survey.AllowAnonymousInterviewee__c);
        }
    }

    /**
     * Test method to check that InterviewMapField__c is set to null
     */
    static testMethod void testInterviwewMapFieldIsNulled() {

        create225SurveyPreConditions();
        run225Tests();
        List<Survey__c> testSurveys = [SELECT InterviewMapField__c FROM Survey__c];
        System.assertEquals(3, testSurveys.size());
        for (Survey__c survey : testSurveys) {
            System.assertEquals(null, survey.InterviewMapField__c);
        }
     }

     /**
      * Test the update of all SurveyMapping__c.IntervieweeApiField__c set to null
      */
     static testMethod void testIntervieweeApiFieldSetNull() {

        create225SurveyMappingPreConditions();
        run225Tests();
        List<SurveyMapping__c> testMappings =
            [SELECT IntervieweeApiField__c FROM SurveyMapping__c];
        for (SurveyMapping__c testMapping : testMappings) {
            System.assertEquals(null, testMapping.IntervieweeApiField__c);
        }
     }

     /**
      * Test the update of all SurveyMapping__c.UseAsInterviewee__c set to false
      */
     static testMethod void testUseAsIntervieweeSetFalse() {

        create225SurveyMappingPreConditions();
        run225Tests();
        List<SurveyMapping__c> testMappings =
            [SELECT UseAsInterviewee__c FROM SurveyMapping__c];
        for (SurveyMapping__c testMapping : testMappings) {
            System.assertEquals(false, testMapping.UseAsInterviewee__c);
        }
     }

     /**
      * Test new validation rule that stops a surveyMapping having UseAsInterviewee__c
      * set to true
      */
     static testMethod void testCatchingUseAsIntervieweeSetTrueValidation() {

        Survey__c testSurvey = TestUtils.createSurvey('TestSurvey');
        SurveyMapping__c newMapping = TestUtils.mapObject(testSurvey, 'Contact');
        newMapping.UseAsInterviewee__c = true;
        try {
            update newMapping;
            System.assert(false, 'This should not be reached as an error should have been thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(
                'Use As Interviewee has been deprecated. Please do not set this field to true'
            ));
        }
     }

     /**
      * Test new validation rule that stops a surveyMapping having IntervieweeApiField__c
      * not null
      */
     static testMethod void testCatchingIntervieweeApiFieldSetNotNullValidation() {

        Survey__c testSurvey = TestUtils.createSurvey('TestSurvey');
        SurveyMapping__c newMapping = TestUtils.mapObject(testSurvey, 'Contact');
        newMapping.IntervieweeApiField__c = 'Contact';
        try {
            update newMapping;
            System.assert(false, 'This should not be reached as an error should have been thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Interviewee Api Field must be null'));
        }
     }

    /**
     * Test move the clients assignments to the new object model
     */
    static testMethod void testMoveClientAssignments() {
        // Given some mobile users with assigned clients
        List<TestUtils.Surveyor> surveyors = TestUtils.createSurveyors(5);
        Map<TestUtils.Surveyor, Set<Id>> clientsBySurveyor = assignClients(surveyors, 5);

        Test.startTest();
        // When the post install script run
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, new Version(2,25,0));
        Test.stopTest();

        // Then the client assignments were moved to the new object model
        checkClientAssignationsWereMoved(clientsBySurveyor);
    }

    /**
     * Test mobile users without clients assigned don't get assignations
     */
    static testMethod void testMobileUsersWithoutClients() {

        // Given a mobile user without clients assigned
        TestUtils.Surveyor surveyor = initMobileUser();

        Test.startTest();
        // When the post install script run
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, new Version(2,25,0));
        Test.stopTest();

        // Then the contact doesn't have assignations
        System.assertEquals(0, [
            SELECT
                Id
            FROM
                SObjectContactAssociation__c
            WHERE
                Contact__c = :surveyor.theContact.Id
        ].size());
    }

    /**
     * Assign clients to the surveyors
     *
     * @param surveyors       - The surveyors to add the clients
     * @param amountOfClients - The amount of clients to create
     *
     * @return - A map with the clients for each surveyor
     */
    private static Map<TestUtils.Surveyor, Set<Id>> assignClients(
            List<TestUtils.Surveyor> surveyors,
            Integer amountOfClients
    ) {
        Map<TestUtils.Surveyor, Set<Id>> clientsBySurveyor = new Map<TestUtils.Surveyor, Set<Id>>();
        List<Client_Assignation__c> assignations = new List<Client_Assignation__c>();
        Id clientForAll;

        for (TestUtils.Surveyor surveyor : surveyors) {
            Set<Id> clients = new Set<Id>();

            if (clientForAll != null) {
                Client_Assignation__c assignation = new Client_Assignation__c(
                    Mobile_User__c = surveyor.user.Id,
                    Client__c = clientForAll
                );
                assignations.add(assignation);
                clients.add(clientForAll);
            }

            for (Integer i = 0; i < amountOfClients; i++) {
                Contact client = TestUtils.createContact();
                Client_Assignation__c assignation = new Client_Assignation__c(
                    Mobile_User__c = surveyor.user.Id,
                    Client__c = client.Id
                );
                assignations.add(assignation);
                clients.add(client.Id);

                if (clientForAll == null) {
                    clientForAll = client.Id;
                }
            }
            clientsBySurveyor.put(surveyor, clients);
        }
        insert assignations;

        return clientsBySurveyor;
    }

    /**
     * Check that the client assignations were moved to the new object model
     */
    private static void checkClientAssignationsWereMoved(
            Map<TestUtils.Surveyor, Set<Id>> clientsBySurveyor
    ) {
        System.assertEquals(0, [SELECT Id FROM Client_Assignation__c].size());

        for (TestUtils.Surveyor surveyor : clientsBySurveyor.keySet()) {
            List<SObjectContactAssociation__c> newAssociations = [
                SELECT
                    Id,
                    AssociatedIds__c
                FROM
                    SObjectContactAssociation__c
                WHERE
                    Contact__c = :surveyor.theContact.Id
            ];
            Set<Id> clients = clientsBySurveyor.get(surveyor);
            List<String> associatedIds = newAssociations[0].AssociatedIds__c.split(',', 0);

            System.assertEquals(clients.size(), associatedIds.size());

            for (Id associatedId : associatedIds) {
                System.assert(
                    clients.remove(associatedId),
                    'The client association wasn\'t there before'
                );
            }
            System.assertEquals(0, clients.size());
        }
    }

     private static void create225SurveyPreConditions() {

        List<Survey__c> testSurveys = new List<Survey__c>();
        Survey__c closedSurvey = TestUtils.createSurvey('ClosedTestSurvey');
        testSurveys.add(closedSurvey);
        Question__c closedSection = TestUtils.addSection(closedSurvey, 1, 'Section1');
        TestUtils.addQuestion(closedSection, 1, 'LastName', QuestionDO.TYPE_TEXT_SHORT);
        TestUtils.addQuestion(closedSection, 2, 'FirstName', QuestionDO.TYPE_TEXT_SHORT);

        Survey__c publishedSurvey = TestUtils.createSurvey('PublishedTestSurvey');
        testSurveys.add(publishedSurvey);
        Question__c publishedSection = TestUtils.addSection(publishedSurvey, 1, 'Section1');
        TestUtils.addQuestion(publishedSection, 1, 'LastName', QuestionDO.TYPE_TEXT_SHORT);
        TestUtils.addQuestion(publishedSection, 2, 'FirstName', QuestionDO.TYPE_TEXT_SHORT);

        Survey__c draftSurvey = TestUtils.createSurvey('DraftTestSurvey');
        testSurveys.add(draftSurvey);
        Question__c draftSection = TestUtils.addSection(draftSurvey, 1, 'Section1');
        TestUtils.addQuestion(draftSection, 1, 'LastName', QuestionDO.TYPE_TEXT_SHORT);
        TestUtils.addQuestion(draftSection, 2, 'FirstName', QuestionDO.TYPE_TEXT_SHORT);

        SurveyDO.publishSurvey(publishedSurvey);
        SurveyDO.publishSurvey(closedSurvey);
        SurveyDO.updateSurveysStatus(new List<Survey__c>{closedSurvey}, SurveyDO.STATUS_CLOSED);
    }

    private static void create225SurveyMappingPreConditions() {

        // Create a Survey
        Survey__c testSurvey = TestUtils.createSurvey('TestSurvey');

        // Add 3 field mappings
        List<SurveyMapping__c> testSurveyMappings = new List<SurveyMapping__c>();
        testSurveyMappings.add(TestUtils.mapObject(testSurvey, 'Contact'));
        testSurveyMappings.add(TestUtils.mapObject(testSurvey, 'Account'));
        testSurveyMappings.add(TestUtils.mapObject(testSurvey, 'Lead'));
    }

    private static void run225Tests() {

        Test.startTest();
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, new Version(2,24));
        Test.stopTest();
    }

    /**
     * Test class to check Ppi results end point getting set properly
     */
    static testMethod void validateAddGrameenSurveyLibrary() {
        Test.startTest();
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, null);
        Test.stopTest();
        SurveyLibrarySelector surveyLibrarySelector = new SurveyLibrarySelector();
        List<SurveyLibrary__c> surveyLibraries =
            surveyLibrarySelector.getRecordsByName(C.GRAMEEN_LIBRARY);
        System.assert(
            1 == surveyLibraries.size(),
            'Grameen Foundation Library should get inserted'
        );
        System.assertEquals(
            'https://grameen-foundation.secure.force.com/surveys',
            surveyLibraries[0].URL__c,
            'Survey Library url field populated properly'
        );
        System.assertEquals(
            'Testing Url. Need to change once decided',
            surveyLibraries[0].PpiResultsEndpoint__c
        );
    }

    /**
     * Test method to check whether Ppi Templates are getting updated properly or not
     */
    static testMethod void testUpdateChildPpiTemplates() {
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

        Map<String, Survey__c> mapSurvey = new Map<String, Survey__c>();
        for (Survey__c surveyInstance : (List<Survey__c>) surveyDomainInstance.records) {
            System.assert(surveyInstance.Id != null);
            mapSurvey.put(surveyInstance.Id, surveyInstance);
        }

        // Check Survey Versions
        System.assertEquals(2, new SurveySelector().getPpiTemplatesWithSurveyVersion().size());
        for (Survey__c surveyInstance : new SurveySelector().getPpiTemplatesWithSurveyVersion()) {
            for (SurveyVersion__c surveyVersionInstance : surveyInstance.SurveyVersions__r) {
                System.assertEquals(SurveyDO.STATUS_DRAFT, surveyVersionInstance.Status__c);
            }
        }

        Test.startTest();
        new PostInstallScript().updateChildPpiTemplates();
        Test.stopTest();

        List<Survey__c> listSurveyUpdated =
            new SurveySelector().getWithSurveyVersion(mapSurvey.keySet());
        System.assertEquals(4, listSurveyUpdated.size());

        for (Survey__c surveyInstance : listSurveyUpdated) {
            for (SurveyVersion__c surveyVersionInstance : surveyInstance.SurveyVersions__r) {
                if (surveyInstance.IsPPI__c && surveyInstance.IsTemplate__c) {
                    System.assertEquals(
                        mapSurvey.get(surveyInstance.Id).Name + '_DEPRECATED',
                        surveyInstance.Name
                    );
                    System.assertEquals(
                        SurveyDO.STATUS_DEPRECATED,
                        surveyVersionInstance.Status__c
                    );
                } else {
                    System.assertEquals(
                        mapSurvey.get(surveyInstance.Id).Name,
                        surveyInstance.Name
                    );
                    System.assertEquals(SurveyDO.STATUS_DRAFT, surveyVersionInstance.Status__c);
                }
            }
        }
    }

    /**
     * Test method to check whether all old lookup table records are getting deleted or not.
     */
    static testMethod void testUpdateExistingParentPpiTemplates() {

        // Create test data
        TestSurveyData testSurveyFirst = TestSurveyData.createFullPpiTemplate();
        System.assert(testSurveyFirst.testSurvey != null);
        System.assertEquals(1, testSurveyFirst.ppiTables.size());

        // Update Ppi Table name since it should be unique 
        testSurveyFirst.ppiTables[0].Name = 'test table 1';
        PpiTableDomain ppiTableDomainInstance =
            new PpiTableDomain.Constructor().constructWithRecords(
                testSurveyFirst.ppiTables
            );
        ppiTableDomainInstance.updateRecords();
        
        // Test data
        TestSurveyData testSurveySecond = TestSurveyData.createFullPpiTemplate();

        // Make PpiIdentifier__c field null for survey records
        SurveyDO surveyDomainInstance =
            new SurveyDO.Constructor().constructWithRecords(
                new List<Survey__c> {
                    testSurveyFirst.testSurvey,
                    testSurveySecond.testSurvey
                }
            );
        for (Survey__c surveyInstance : (List<Survey__c>) surveyDomainInstance.records) {
            surveyInstance.PpiIdentifier__c = null;
        }
        surveyDomainInstance.updateRecords();

        // Make Distributed as true for a survey version
        testSurveySecond.testSurveyVersion.Distributed__c = true;
        testSurveySecond.testSurveyVersion.DistributionDate__c = Date.today();
        SurveyVersionDomain surveyVersionDomainInstance =
            new SurveyVersionDomain.Constructor().constructWithRecords(
                new List<SurveyVersion__c> {
                    testSurveySecond.testSurveyVersion
                }
            );
        surveyVersionDomainInstance.updateRecords();

        // After releasing the template, create a survey.json file and store as an attachment
        Attachment firstSurveyJsonAttachment =
            new SurveyUtils().generateJsonFile(testSurveyFirst.testSurveyVersion);
        Attachment secondSurveyJsonAttachment =
            new SurveyUtils().generateJsonFile(testSurveyFirst.testSurveyVersion);

        System.assert(firstSurveyJsonAttachment.Id != null);
        System.assert(secondSurveyJsonAttachment.Id != null);

        List<Attachment> attachments =
            new AttachmentSelector().getAllWithParentId(
                new Set<Id> {
                    testSurveyFirst.testSurveyVersion.Id,
                    testSurveySecond.testSurveyVersion.Id
                },
                C.SURVEY_FILE_JSON
            );
        System.assertEquals(2, attachments.size());

        System.assert(
            ((SurveyVersion__c) surveyVersionDomainInstance.records[0]).Distributed__c == true
        );
        System.assert(
            ((SurveyVersion__c) surveyVersionDomainInstance.records[0]).DistributionDate__c != null
        );

        // Create Ppi Table DataSet record
        PpiTableDataSetDomain ppiTableDataSetDomainInstance =
            new PpiTableDataSetDomain.Constructor().constructWithRecords(
                PpiTableDataSetDomainTest.createMultipleRecords(2)
            );
        UnitOfWork unitOfWorkInstance = PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
            (PPITableDataSet__c) ppiTableDataSetDomainInstance.records[0],
            testSurveyFirst.ppiTables[0],
            testSurveyFirst.testSurvey,
            testSurveyFirst.testSurveyVersion,
            new UnitOfWork()
        );
        unitOfWorkInstance.commitWork();

        unitOfWorkInstance = PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
            (PPITableDataSet__c) ppiTableDataSetDomainInstance.records[1],
            testSurveySecond.ppiTables[0],
            testSurveySecond.testSurvey,
            testSurveySecond.testSurveyVersion,
            new UnitOfWork()
        );
        unitOfWorkInstance.commitWork();

        System.assertEquals(2, ppiTableDataSetDomainInstance.records.size());
        for (
                PPITableDataSet__c ppiTableDataSetInstance :
                    (List<PPITableDataSet__c>) ppiTableDataSetDomainInstance.records
        ) {
            System.assert(ppiTableDataSetInstance.Id != null);
        }

        // Update PpiTableDataSet and PpiTable fields in PpiTableLine records
        PpiTableLineDomain ppiTableLineDomainInstance =
            new PpiTableLineDomain.Constructor().constructWithRecords(
                PpiTableLineDomainTest.addPpiTableDataSetValueAsOldDataModel(
                    new Map<Id, List<PPITableLine__c>> {
                        ppiTableDataSetDomainInstance.records[0].Id =>
                            testSurveyFirst.ppiTableLines.get(testSurveyFirst.ppiTables[0].Id),
                        ppiTableDataSetDomainInstance.records[1].Id =>
                            testSurveySecond.ppiTableLines.get(testSurveySecond.ppiTables[0].Id)
                    }
                )
            );
        ppiTableLineDomainInstance.updateRecords();
        System.assertEquals(40, ppiTableLineDomainInstance.records.size());

        Set<Id> setPpiTableLineIds = new Set<Id>();
        for (
                PPITableLine__c ppiTableLineInstance :
                    (List<PPITableLine__c>) ppiTableLineDomainInstance.records
        ) {
            System.assert(ppiTableLineInstance.PPITableDataSet__c != null);
            System.assert(ppiTableLineInstance.PPITableDataSet__c != null);
            setPpiTableLineIds.add(ppiTableLineInstance.Id);
        }

        Test.startTest();
        new PostInstallScript().updateExistingParentPpiTemplates();
        Test.stopTest();

        // Fetch SurveyVersion records with Survey
        List<SurveyVersion__c> listSurveyVersion =
            (List<SurveyVersion__c>) new SurveyVersionSelector().getAllWithSurveyDetails(
                new Set<Id> {
                    testSurveyFirst.testSurveyVersion.Id,
                    testSurveySecond.testSurveyVersion.Id
                }
            );
        System.assertEquals(2, listSurveyVersion.size());
        for (SurveyVersion__c surveyVersionInstance : listSurveyVersion) {
            System.assertEquals(false, surveyVersionInstance.Distributed__c);
            System.assertEquals(null, surveyVersionInstance.DistributionDate__c);
            System.assertEquals('KENYA_2012', surveyVersionInstance.Survey__r.PpiIdentifier__c);
        }

        // Fetch PpiTable records
        List<PPITable__c> listPpiTable = (List<PPITable__c>) new PpiTableSelector().getRecordsById(
            new Set<Id> {testSurveyFirst.ppiTables[0].Id, testSurveySecond.ppiTables[0].Id}
        );
        System.assertEquals(0, listPpiTable.size());

        // Fetch PpiTableDataSet records
        List<PPITableDataSet__c> listPpiTableDataSet =
            (List<PPITableDataSet__c>) new PpiTableDataSetSelector().getRecordsById(
                new Set<Id> {
                    ppiTableDataSetDomainInstance.records[0].Id,
                    ppiTableDataSetDomainInstance.records[1].Id
                }
            );
        System.assertEquals(0, listPpiTableDataSet.size());

        // Fetch PpiTableLine records
        List<PPITableLine__c> listPpiTableLine =
            (List<PPITableLine__c>) new PpiTableLineSelector().getRecordsById(setPpiTableLineIds);
        System.assertEquals(0, listPpiTableLine.size());

        // Verify Attachment records are deleted properly
        List<Attachment> listAttachment =
            new AttachmentSelector().getAllWithParentId(
                new Set<Id> {
                    testSurveyFirst.testSurveyVersion.Id,
                    testSurveySecond.testSurveyVersion.Id
                },
                C.SURVEY_FILE_JSON
            );
        System.assertEquals(0, listAttachment.size());
    }

    /**
     * Test method to check whether all attachment records linked to Ppi Templates are deleted
     */
    static testMethod void testDeleteOldTemplateJsonAttachment() {

        TestSurveyData testSurvey = TestSurveyData.createFullPpiTemplate();
        System.assert(testSurvey.testSurvey != null);
        System.assert(testSurvey.testSurvey.Id != null);
        System.assert(testSurvey.testSurveyVersion != null);
        System.assertEquals(1, testSurvey.ppiTables.size());

        // Make Distributed as true for a survey version to release the template 
        testSurvey.testSurveyVersion.Distributed__c = true;
        SurveyVersionDomain surveyVersionDomainInstance =
            new SurveyVersionDomain.Constructor().constructWithRecords(
                new List<SurveyVersion__c> {
                    testSurvey.testSurveyVersion
                }
            );
        surveyVersionDomainInstance.updateRecords();
        System.assertEquals(1, surveyVersionDomainInstance.records.size());
        System.assert(surveyVersionDomainInstance.records[0].Id != null);

        // After releasing the template, create a survey.json file and store as an attachment
        Attachment surveyJsonAttachment =
            new SurveyUtils().generateJsonFile(testSurvey.testSurveyVersion);

        System.assert(surveyJsonAttachment.Id != null);

        // Attachment record present in database
        List<Attachment> attachments =
            new AttachmentSelector().getAllWithParentId(
                new Set<Id> {
                    testSurvey.testSurveyVersion.Id
                },
                C.SURVEY_FILE_JSON
            );
        System.assertEquals(1, attachments.size());

        Test.startTest();
        new PostInstallScript().deleteOldTemplateJsonAttachment(
            new Set<Id> {testSurvey.testSurveyVersion.Id}
        );
        Test.stopTest();

        // Verify Attachment record not present in database
        attachments =
            new AttachmentSelector().getAllWithParentId(
                new Set<Id> {
                    testSurvey.testSurveyVersion.Id
                },
                C.SURVEY_FILE_JSON
            );
        System.assertEquals(0, attachments.size());
    }
}