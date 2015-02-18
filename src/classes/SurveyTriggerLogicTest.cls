/**
 * Test class for SurveyTriggerLogic.
 *
 * @author Owen Davies
 * @author Alejandro De Gregorio
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
private class SurveyTriggerLogicTest {

    /**
     * Test that the xforms are cleaned properly
     */
    static testMethod void testCleanXForm() {

        // Needed objects to test
        Survey__c survey = new Survey__c(Name = 'TestSurvey');

        insert survey;
        SurveyVersion__c version = [SELECT Id,Survey__c,Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id];

        Attachment att = new Attachment(
            Name = XFormCreator.XFORM_ATTACHMENT,
            ParentId = version.Id,
            body = Blob.valueOf('test')
            );

        insert att;

        // Update the survey
        update survey;

        List<Attachment> xformAttachments = [select Id from Attachment where ParentId = :version.Id and name = :XFormCreator.XFORM_ATTACHMENT];
        System.assertEquals(0, xformAttachments.size());

        Attachment att2 = new Attachment(
            Name = XFormCreator.XFORM_ATTACHMENT,
            ParentId = version.Id,
            body = Blob.valueOf('test')
            );

        insert att2;

        // Update a Survey with a different status doesn't delete the xform
        Test.startTest();
            version.Status__c = SurveyDO.STATUS_CLOSED;
            update version;
        Test.stopTest();
        xformAttachments = [select Id from Attachment where ParentId = :version.Id and name = :XFormCreator.XFORM_ATTACHMENT];
        System.assertEquals(1, xformAttachments.size());
    }

    /**
     * Test that it is possible to have many surveys with an empty alias
     */
    static testMethod void removeSurveyAlias() {

        // Add survey with empty alias
        Survey__c emptyAlias = new Survey__c( Name = 'empty' );
        insert emptyAlias;

        // Add survey with an alias
        Survey__c survey = new Survey__c( Name = 'survey', Alias__c = 'Test Alias' );
        insert survey;

        // Set the alias to empty
        survey.Alias__c = '';

        Test.startTest();
            upsert survey;
        Test.stopTest();
        system.assert(String.isEmpty([SELECT Alias__c FROM Survey__c WHERE Id = :survey.Id].Alias__c));
    }

    /**
     * Test that a SurveyVersion is created when a survey is inserted.
     * Ensure that the version number is updated when a survey is taken back into draft
     * status
     */
    static testMethod void testVersionCreationTest() {

        // Create a new Survey
        Survey__c survey = new Survey__c( Name='survey' );
        insert survey;

        // Refresh survey
        survey = [SELECT Name, Status__c, Version__c FROM Survey__c WHERE Id = :survey.Id];

        // Check the Version number assignment and Status(before insert)
        system.assertEquals(SurveyDO.STATUS_DRAFT, survey.Status__c);
        system.assertEquals(1, Survey.Version__c);

        // Check if a Survey Version was inserted
        List<SurveyVersion__c> versions = [SELECT Version__c, Status__c, Name FROM SurveyVersion__c WHERE Survey__r.Id = :survey.Id];
        system.assertEquals(1, versions.size());
        system.assertEquals(1, versions[0].Version__c);
        system.assertEquals(SurveyDO.STATUS_DRAFT, versions[0].Status__c);

        Test.startTest();
            // Update surveyVersion to Published, this way the survey will be Published as well
            SurveyDO.updateSurveysStatus(new List<Survey__c>{ survey }, SurveyDO.STATUS_PUBLISHED);

            // Update a survey from published to draft. It's version number must increase.
            // Also, a new version must be created, and the previous version must remain published
            SurveyDO.reopenSurveys(new List<Survey__c>{ survey });
        Test.stopTest();

        system.assertEquals(2, [SELECT Version__c FROM Survey__c WHERE Id = :survey.Id].Version__c);

        versions = [
            SELECT
                Version__c,
                Status__c,
                Name
            FROM
                SurveyVersion__c
            WHERE
                Survey__r.Id = :survey.Id
            ORDER BY
                Version__c ASC
        ];

        system.assertEquals(2, versions.size());
        system.assertEquals(1, versions[0].Version__c);
        system.assertEquals(SurveyDO.STATUS_PUBLISHED, versions[0].Status__c);
        system.assertEquals(2, versions[1].Version__c);
        system.assertEquals(SurveyDO.STATUS_DRAFT, versions[1].Status__c);
    }

    /**
     * Test only the latest version must update the survey's status.
     */
    static testMethod void testOldVersionsDontUpdateSurveyStatus() {

        // Create a survey (sill be draft). Publish it, then change it back to draft (a new version will be created)
        Survey__c survey = new Survey__c(Name='survey');
        insert survey;

        SurveyVersion__c version1 = [SELECT Id, Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id];

        Test.startTest();
            SurveyDO.updateSurveysStatus(new List<Survey__c>{ survey }, SurveyDO.STATUS_PUBLISHED);

            survey = [SELECT Id, Status__c FROM Survey__c WHERE Id = :survey.Id];
            SurveyDO.reopenSurveys(new List<Survey__c>{ survey });

            // Assert that initial information is right
            survey = [SELECT Id, Status__c, Version__c FROM Survey__c WHERE Id = :survey.Id];
            system.assertEquals(2, survey.Version__c);
            system.assertEquals(SurveyDO.STATUS_DRAFT, survey.Status__c);

            SurveyVersion__c[] versions = [SELECT Id, Version__c, Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c];
            system.assertEquals(2, versions.size());
            system.assertEquals(SurveyDO.STATUS_PUBLISHED, versions[0].Status__c);
            system.assertEquals(SurveyDO.STATUS_DRAFT, versions[1].Status__c);

            // Change the status of the first version. The status of the survey must remain in Draft
            insert new Settings__c(Name = C.FLAG_SKIP_QUESTION_POSITION_VALIDATION);
            version1 = versions[0];
            version1.Status__c = SurveyDO.STATUS_CLOSED;
            update version1;
        Test.stopTest();
        // Assert that final information is right
        survey = [SELECT Id, Status__c, Version__c FROM Survey__c WHERE Id = :survey.Id];
        system.assertEquals(2, survey.Version__c);
        system.assertEquals(SurveyDO.STATUS_DRAFT, survey.Status__c);

        versions = [SELECT Id, Version__c, Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c];
        system.assertEquals(2, versions.size());
        system.assertEquals(SurveyDO.STATUS_CLOSED, versions[0].Status__c);
        system.assertEquals(SurveyDO.STATUS_DRAFT, versions[1].Status__c);
    }

     /**
      * Test inserting two surveys with the same alias
      */
     static testMethod void testInsertingWithSameAlias() {

        //INITIALIZATION
        Survey__c survey1 = new Survey__c(Name='survey1',Alias__c = 'RepeatedAlias');
        insert survey1;

        Survey__c survey2 = new Survey__c(Name='survey2',Alias__c = 'RepeatedAlias');

        //START TEST
        Test.startTest();
            try {
                insert survey2;
                system.assert(false,'Should have failed since there are two survey with the same alias');
            }
            catch (Exception e) {
                system.assert(e.getMessage().contains(system.label.SURVEY_ERR_DUPLICATE_ALIAS));
            }
        Test.stopTest();
     }

     /**
      * Test inserting a template and a survey with the same alias as the template
      */
     static testMethod void testWithTemplateAlias() {

        //INITIALIZATION
        Survey__c survey1 = new Survey__c(Name='survey1',Alias__c = 'TemplateAlias',IsTemplate__c = true);
        insert survey1;

        Survey__c survey2 = new Survey__c(Name='survey2', Alias__c = 'TemplateAlias');

        //START TEST
        Test.startTest();
            insert survey2;
        Test.stopTest();
        system.assertEquals(2, [SELECT Id FROM Survey__c WHERE Alias__c = 'TemplateAlias'].size());
     }

     /**
      * Test updating an alias of a survey with an alias of an existing survey
      */
     static testMethod void testUpatingWithSameAlias() {

        String repeatedAlias = 'RepeatedAlias';

        //INITIALIZATION
        Survey__c survey1 = new Survey__c(Name='survey1', Alias__c = repeatedAlias);
        Survey__c survey2 = new Survey__c(Name='survey2', Alias__c = 'NotRepeatedAlias');
        insert new List<Survey__c>{ survey1, survey2 };

        Survey__c surveyToUpdate = [SELECT Id FROM Survey__c WHERE Id = :survey2.Id LIMIT 1];
        surveyToUpdate.Alias__c = repeatedAlias;

        Test.startTest();
            // START TEST
            try {
                update surveyToUpdate;
                system.assert(false, 'Should have failed since we are trying to update a survey with an existing survey alias');
            }
            catch (Exception e) {
                system.assert(e.getMessage().contains(system.label.SURVEY_ERR_DUPLICATE_ALIAS));
            }
        Test.stopTest();
     }

    /**
     * Test that updating so two survey Aliases swap is allowed
     */
    static testMethod void testSwitchingAliases() {

        String alias1 = 'Alias_1';
        String alias2 = 'Alias_2';

        // Set up tests
        Survey__c survey1 = new Survey__c(Name='survey1', Alias__c = alias1);
        Survey__c survey2 = new Survey__c(Name='survey2', Alias__c = alias2);
        List<Survey__c> surveys = new List<Survey__c>{ survey1, survey2 };
        insert surveys;
        System.assertEquals(alias1, survey1.Alias__c);
        System.assertEquals(alias2, survey2.Alias__c);

        // Switch the aliases around
        survey1.Alias__c = alias2;
        survey2.Alias__c = alias1;

        // Conduct test
        Test.startTest();
            try {
                update surveys;
                System.assertEquals(alias2, survey1.Alias__c);
                System.assertEquals(alias1, survey2.Alias__c);
            }
            catch (Exception e) {
                system.assert(false, 'Switching survey aliases is perfectly allowable');
            }
        Test.stopTest();
    }

     /**
      * Test inserting multiple surveys with the same alias
      */
     static testMethod void testInsertMultipleWithSameAlias() {

        //INITIALIZATION
        Survey__c survey1 = new Survey__c(Name='survey1',Alias__c = 'RepeatedAlias');
        Survey__c survey2 = new Survey__c(Name='survey2',Alias__c = 'RepeatedAlias');

        Test.startTest();
            //START TEST
            try {
                insert new Survey__c[]{ survey1, survey2 };
                system.assert(false,'Should have failed since there are two survey with the same alias');
            }
            catch (Exception e) {
                system.assert(e.getMessage().contains(system.label.SURVEY_ERR_DUPLICATE_ALIAS));
            }
        Test.stopTest();
     }

    /**
     * Test that the trigger block the question insertion with repeated positions
     */
    static testMethod void triggerQuestionsTest() {

        // Create a survey
        Survey__c survey = new Survey__c();
        insert survey;
        Question__c section1  = TestUtils.addQuestion(survey, 1, 'section1', QuestionDO.TYPE_SECTION);
        Question__c question1 = TestUtils.addQuestion(section1, 1, 'question1', QuestionDO.TYPE_TEXT_SHORT);
        Question__c question2 = TestUtils.addQuestion(section1, 2, 'question2', QuestionDO.TYPE_TEXT_SHORT);
        Question__c question3 = TestUtils.addQuestion(section1, 3, 'question3', QuestionDO.TYPE_TEXT_SHORT);

        // Making a position repeated
        question2.Position__c = 1;
        update question2;

        Test.startTest();
            try {
                update survey;
                system.assert(false, 'Should have failed here since exists two questions with same position');
            }
            catch(Exception e) {
                // IDALMSA-4597 added two possible orders of the questions in the message to avoid failure in some orgs
                system.assert(
                e.getMessage().contains( 'Question question1 Id = '+ question1.Id + ' and Question question2 Id = ' + question2.Id + ' Share parent Id= ' + section1.Id + ' and Position 1') ||
                e.getMessage().contains( 'Question question2 Id = '+ question2.Id + ' and Question question1 Id = ' + question1.Id + ' Share parent Id= ' + section1.Id + ' and Position 1'),
                e.getMessage());
            }

            // Reseting question2 order
            question2.Position__c = 2;
            update question2;

            // Inserting a new queston with same position than existing one
            try{
                Question__c question4 = TestUtils.addQuestion(section1, 2, 'question4', QuestionDO.TYPE_TEXT_SHORT);
                system.assert(false, 'Should have failed here since exist another question with same position in this section');
            }
            catch(Exception e) {
                system.assert(true);
            }
        Test.stopTest();
    }

    /**
     * Test that the trigger block the secttion insertion with repeated positions
     */
    static testMethod void triggerSectionsTest() {

        // Create a survey
        Survey__c survey = new Survey__c();
        insert survey;
        List<Question__c> quests = new List<Question__c>();
        Question__c section1 =  TestUtils.addQuestion(survey, 1, 'section1', QuestionDO.TYPE_SECTION);
        Question__c section2 =  TestUtils.addQuestion(survey, 2, 'section2', QuestionDO.TYPE_SECTION);

        // Making a position repeated
        section2.Position__c = 1;
        update section2;
        try {
            update survey;
            system.assert(false, 'Should have failed here since exists two sections with same position');
        }
        catch(Exception e) {
            system.assert(
            e.getMessage().contains( 'Question section2 Id = '+ section2.Id + ' and Question section1 Id = ' + section1.Id + ' Share parent Id= ' + null + ' and Position 1') ||
            e.getMessage().contains( 'Question section1 Id = '+ section1.Id + ' and Question section2 Id = ' + section2.Id + ' Share parent Id= ' + null + ' and Position 1')
            );
        }

        // Reseting question2 order
        section2.Position__c = 2;
        update section2;

        Test.startTest();
            //Inserting a new section with same position than existing one
            try {
                Question__c section3 = TestUtils.addQuestion(survey, 2, 'section3', QuestionDO.TYPE_TEXT_SHORT);
                system.assert(false, 'Should have failed here since exist another section with same position ');
            }
            catch(Exception e) {
                system.assert(true);
            }
        Test.stopTest();
    }

    /**
     * Test that deleting the survey also deletes the PPI data sets and the PPI table lines
     */
    static testMethod void triggerDeleteTest() {

        // Add license to create new ppi surveys
        LicenseSettings__c license = C.getLicense();
        license.UsePPI__c = true;
        update license;

        // Inserting required objects
        insert new ISO_Country__c( Name='AA', ShortName__c='Test' );
        insert new Language__c( Name = 'XX', ShortLanguageName__c = 'XXLanguage' );

        // Inserting survey
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();

        // Inserting questions for that survey
        Question__c section = TestUtils.addQuestion(survey, 1, 'testsec1', QuestionDO.TYPE_SECTION );
        Question__c q1 = TestUtils.addQuestion(section, 1, 'testquest1', QuestionDO.TYPE_TEXT_SHORT);
        Question__c q2 = TestUtils.addQuestion(section, 2, 'testquest2', QuestionDO.TYPE_TEXT_SHORT);

        // Inserting options for those questions
        Option__c option1 = new Option__c(Question__c = q1.Id,Name = 'NameOption1',Position__c = 1);
        Option__c option2 = new Option__c(Question__c = q1.Id,Name = 'NameOption2',Position__c = 2);
        insert new List<Option__c>{option1,option2};

        // Inserting scoring group for that survey
        ScoringGroup__c group1 = new ScoringGroup__c(Caption__c = 'FirstGroup',Survey__c = survey.Id);
        insert group1;

        // Inserting score values for that scoring group
        ScoreValue__c scoreValue1 = new ScoreValue__c(Value__c = 5,ScoringGroup__c = group1.Id,Option__c = option1.Id);
        insert scoreValue1;

        // Inserting skip condition for the selected questions
        insert new SkipCondition__c(
            Condition__c = SkipConditionDO.CONDITION_EQUAL,
            Parent__c = q1.Id,
            SourceQuestion__c = q2.Id,
            SkipValue__c = 'Value'
        );

        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(new Set<String> {survey.Id});

        System.assert(
            surveyVersions.size() > 0,
            'Survey Version records not created properly'
        );

        // Inserting Ppi tables
        PpiTableDomainTest.PpiTableWrapper tableWrapper =
            new PpiTableDomainTest.PpiTableWrapper();
        tableWrapper.createDefaultTable();
        tableWrapper.addToSurvey(true, survey, surveyVersions[0]);
        tableWrapper.commitWork();

        // Inserting Survey mapping
        SurveyMapping__c surveyMapping =
            new SurveyMapping__c(Survey__c = survey.Id, ObjectApiName__c = 'Contact');
        insert surveyMapping;

        Test.startTest();

        // Delete the survey and check that is correctly deleted
        delete survey;
        System.assertEquals(0, [SELECT Id FROM Survey__c WHERE Id = :survey.Id].size());
        System.assertEquals(0, [SELECT Id FROM PPITableDataSet__c WHERE Survey__c = :survey.Id].size());
        System.assertEquals(0, [SELECT Id FROM SurveyMapping__c WHERE Survey__c = :survey.Id].size());

        // Testing delete published survey (should raise an exception)
        // Inserting a survey
        Survey__c publishedSurvey = new Survey__c(
            isPPI__c = true,
            CountryCode__c = 'AA',
            LanguageCode__c = 'XX',
            PPIDataYear__c = 2103,
            PublishedDate__c = Date.today() - 1
        );
        insert publishedSurvey;

        // Publish survey
        SurveyVersion__c version = [SELECT Id, Status__c FROM SurveyVersion__c WHERE Survey__c = :publishedSurvey.Id];
        version.Status__c = SurveyDO.STATUS_PUBLISHED;
        update version;

        // Try to delete the survey
        try {
            delete publishedSurvey;
            System.assert(false,'should have failed here since the survey is already published and it cannot be deleted');
        }
        catch(Exception e) {
            System.assert(e.getMessage().contains(system.label.SURVEY_ERR_CANNOTDELETEPUBLISHED));
        }

        // Try to delete the version
        try {
            delete version;
            System.assert(false,'should have failed here since the version is already published and it cannot be deleted');
        }
        catch(Exception e) {
            System.assert(e.getMessage().contains(system.label.SURVEY_ERR_CANNOTDELETEPUBLISHED));
        }
        Test.stopTest();
    }

    /**
     * Test to check that the Survey Status cannot be changed manually.
     * (Related IDALMSA-2800)
     */
    static testMethod void testAvoidEditSurveyStatusManually() {

        // Prepare the survey
        Survey__c survey = new Survey__c(Name='survey');
        insert survey;

        survey = [SELECT Status__c,Version__c FROM Survey__c WHERE Id = :survey.Id];
        System.assertEquals(1, survey.Version__c, 'The survey version must be 1.');
        System.assertEquals(SurveyDO.STATUS_DRAFT, survey.Status__c, 'The status must be draft.');

        Test.startTest();
            // Try to change status manually from DRAFT to PUBLISHED, CLOSED
            survey.Status__c = SurveyDO.STATUS_PUBLISHED;
            assertUpdateSurveyChangeStatusManually(survey);
            survey.Status__c = SurveyDO.STATUS_CLOSED;
            assertUpdateSurveyChangeStatusManually(survey);

            // Get survey versions to publish the survey
            SurveyDO.updateSurveysStatus(new List<Survey__c>{ survey }, SurveyDO.STATUS_PUBLISHED);

            // Verify the survey is already published
            System.assertEquals(SurveyDO.STATUS_PUBLISHED, [SELECT Status__c FROM Survey__c WHERE Id =: survey.Id].Status__c, 'The survey must published.');

            // Reopen the survey to create a new version
            SurveyDO.reopenSurveys(new List<Survey__c>{ survey });

            SurveyVersion__c[] versions = [SELECT Version__c,Status__c FROM SurveyVersion__c WHERE Survey__r.Id = :survey.Id ORDER BY Version__c];

            // There should 1 more version
            System.assertEquals(2, versions.size(), 'There must 2 versions.');
            System.assertEquals(2, [SELECT Version__c FROM Survey__c WHERE Id = :survey.Id].Version__c, 'The survey version must be 2.');

            // Close the survey through its version
            SurveyDO.updateSurveysStatus(new List<Survey__c>{ survey }, SurveyDO.STATUS_CLOSED);

            survey = [SELECT Status__c FROM Survey__c WHERE Id =: survey.Id];

            // Try to publish the survey manually
            survey.Status__c = SurveyDO.STATUS_PUBLISHED;
            assertUpdateSurveyChangeStatusManually(survey);
        Test.stopTest();
        // The status didn't change
        System.assertEquals(SurveyDO.STATUS_CLOSED, [SELECT Status__c FROM Survey__c WHERE Id =: survey.Id].Status__c, 'The survey must still be closed.');

        // The old version was registered as published and current version is closed
        versions = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__r.Id = :survey.Id ORDER BY Version__c];
        System.assertEquals(SurveyDO.STATUS_CLOSED, versions[1].Status__c);
        System.assertEquals(SurveyDO.STATUS_PUBLISHED, versions[0].Status__c);
    }

    /**
    * Assertion to check a survey status cannot be changed manually.
    *
    * @param survey - Target survey to change the status.
    */
    static void assertUpdateSurveyChangeStatusManually(Survey__c survey) {

        try {
            update survey;
            System.assert(false, 'This should fail because the cannot be changed manually.');
        }
        catch(DMLException e) {
            System.assert(e.getMessage().contains(System.Label.ERR_AVOID_EDIT_SURVEY_STATUS_MANUALLY));
        }
    }

    /**
     * Test to check that the Ppi Template creates Ppi Identifier on Insert
     */
    static testMethod void testSetPpiIdentifierOnInsert() {

        Test.startTest();
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        Test.stopTest();

        // The Identifier is inserted properly
        System.assertEquals(
            'KENYA_2012',
             fetchExpectedPpiIdentifier(survey.Id)
        );
    }

    /**
     * Test to check that the Ppi Template creates Ppi Identifier on Update of Country / Year
     */
    static testMethod void testSetPpiIdentifierOnUpdate() {

        ISOCountryWrapperTest.insertRecord('IT', 'ITALY');

        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();

        Test.startTest();
        survey.CountryCode__c = 'IT';
        survey.PPIDataYear__c = 2022;
        update survey;
        Test.stopTest();

        // The Identifier should get updated with new value
        System.assertEquals(
            'ITALY_2022',
             fetchExpectedPpiIdentifier(survey.Id)
        );
    }

    /**
     * Test to check that the Ppi Template doesn't update Ppi Identifier if Template
     * is released to library and downloaded by any child org.
     */
    static testMethod void testSetPpiIdentifierAfterReleasingToLibrary() {

        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        ISOCountryWrapperTest.insertRecord('IT', 'ITALY');
        survey.CountryCode__c = 'IT';
        survey.PPIDataYear__c = 2022;
        survey.RemoteId__c = 'test';

        Test.startTest();
        update survey;
        Test.stopTest();

        // The Identifier shouldn't get updated and persist old value
        System.assertEquals(
            'KENYA_2012',
            fetchExpectedPpiIdentifier(survey.Id)
        );
    }

    /**
     * Fetch PpiIdentifier from database for specified Survey Id
     */
    public static String fetchExpectedPpiIdentifier(Id surveyId) {
        Survey__c surveyInstance =
            (Survey__c) new SurveySelector().getRecordById(surveyId);
        return surveyInstance.PpiIdentifier__c;
    }
}
