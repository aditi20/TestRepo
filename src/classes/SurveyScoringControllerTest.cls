/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public class SurveyScoringControllerTest{

    /**
     * Test for Scoring controller apex error messages when name of the scoring value has no
     * related group name.
     */
    static testMethod void testScoringErrorsGroupName() {
        Survey__c survey1 = newSurvey('FirstSurvey');
        Question__c question1 =
            newQuestion(survey1.Id, 'Name', 'Caption1', QuestionDO.TYPE_SECTION);
        Option__c option1 = newOption(question1.Id, 'NameOption', 1);
        setPPILicenseSetting(false);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
        SurveyScoringController controller = new SurveyScoringController(stdController);

        // Fails because the name of the scoring value has no related group name.
        controller.scoringGroupStr = '[{"caption":"ScoringGroup2"}]';
        controller.scoringValuesJson  =
            '[{"optionId":"' + option1.Id + '","groupName":"ScoringGroup1","value":"1"}]';
        controller.saveScoring();
        Test.stopTest();
        System.assertEquals(1, Apexpages.getMessages().size());
    }

    /**
     *    Test for Scoring controller apex error messages when the survey is not SurveyDO.STATUS_DRAFT;
     */
    static testMethod void testScoringErrorsStatusClosed(){
        Survey__c survey1 = newSurvey('FirstSurvey');
        Question__c question1 = newQuestion(survey1.Id, 'Name', 'Caption1', QuestionDO.TYPE_SECTION);
        Option__c option1 = newOption(question1.Id, 'NameOption', 1);
        setPPILicenseSetting(false);
        
        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
            SurveyScoringController controller = new SurveyScoringController(stdController);

            SurveyDO.updateSurveysStatus(new List <Survey__c> {survey1}, SurveyDO.STATUS_CLOSED);
            System.assertEquals(SurveyDO.STATUS_CLOSED, [SELECT Id, Status__c FROM Survey__c WHERE Id =: survey1.Id].Status__c, 'The status must be closed.');
            controller.saveScoring();
        Test.stopTest();
        // Returns 1 error message.
        System.assertEquals(1, Apexpages.getMessages().size());
    }

    /**
     *    Test for Scoring controller apex error messages when the group has no valid name.
     */
    static testMethod void testScoringErrorsInvalidGroupName(){
        Survey__c survey1 = newSurvey('FirstSurvey');
        Question__c question1 = newQuestion(survey1.Id, 'Name', 'Caption1', QuestionDO.TYPE_SECTION);
        Option__c option1 = newOption(question1.Id, 'NameOption', 1);
        setPPILicenseSetting(false);
        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
            SurveyScoringController controller = new SurveyScoringController(stdController);

            // Fails because group has no valid name.
            survey1.Status__c = SurveyDO.STATUS_DRAFT;
            update survey1;
            controller = new SurveyScoringController(stdController);
            controller.scoringGroupStr = '[{"caption":""}]';
            controller.scoringValuesJson  = '[{"optionId":"' + option1.Id + '","groupName":"ScoringGroup4","value":"-1"}]';
            controller.saveScoring();
        Test.stopTest();
        System.assertEquals(1, Apexpages.getMessages().size());
    }

    /**
     *    Test for Scoring controller
     */
    static testMethod void testScoring(){
        Test.startTest();
            testScoringSimple(QuestionDO.TYPE_SECTION);
        Test.stopTest();
    }

    /**
     *    Test for Scoring controller for controls in a repeated section
     */
    static testMethod void testScoringRepeated(){
        Test.startTest();
            testScoringSimple(QuestionDO.TYPE_REPEAT);
        Test.stopTest();
    }

    // Test for Render Scoring
    static testMethod void testRendering(){
        Survey__c survey1 = newSurvey('FirstSurvey');
        Question__c question1 = newQuestion(survey1.Id, 'Name', 'Caption1', QuestionDO.TYPE_SECTION);
        Option__c option1 = newOption(question1.Id, 'NameOption', 1);
        ScoringGroup__c group1 = newScoringGroup('FirstGroup', survey1.Id);
        ScoreValue__c scoreValue1 = newScoreValue(5, group1.Id, option1.Id);
        setPPILicenseSetting(false);
        
        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
            SurveyScoringController controller = new SurveyScoringController(stdController);
            System.assertEquals(1, controller.listScoreValues.size());
        Test.stopTest();
    }

    /**
     * This test the proper throw an error when i try to make changes in the Field mapping for this survey mean while the survey is been update.
     * This should not let me save the changes since the survey was modified.
     */
    static testMethod void testOutofSyncUpdateError(){
        Survey__c survey1 = newSurvey('FirstSurvey');
        Question__c question1 = newQuestion(survey1.Id, 'Name', 'Caption1', QuestionDO.TYPE_SECTION);
        Option__c option1 = newOption(question1.Id, 'NameOption', 1);
        ScoringGroup__c group1 = newScoringGroup('FirstGroup', survey1.Id);
        ScoreValue__c scoreValue1 = newScoreValue(5, group1.Id, option1.Id);
        
        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
            SurveyScoringController controller = new SurveyScoringController(stdController);

            //Update the survey directly(this is not using the controller.)
            survey1.Alias__c = 'as';

            C.wait(1);
            update survey1;
            survey1 = [Select LastModifiedDate FROM Survey__c WHERE Id=:survey1.Id limit 1];
            DateTime currentLastModifiedDate = survey1.LastModifiedDate;
            //If i try to save the survey from the controller it shouldnt be posible.
            controller.saveScoring();
             //It should throw an error popup to refresh the page
            System.assert(controller.concurrentSave, 'Should throw an error popup to refresh the page');
            //And it shouldn't update the survey.
            survey1 = [Select LastModifiedDate FROM Survey__c WHERE Id=:survey1.Id limit 1];
            System.assertEquals(currentLastModifiedDate,survey1.LastModifiedDate);
        Test.stopTest();
    }

    /**
     * This test if mean while im updating the field mapping no body is updating the survey. So all should be right.
     */
    static testMethod void testOutofSyncUpdateRight(){
        Survey__c survey = newSurvey('FirstSurvey');
        Question__c question1 = newQuestion(survey.Id, 'Name', 'Caption1', QuestionDO.TYPE_SECTION);
        Option__c option1 = newOption(question1.Id, 'NameOption', 1);
        ScoringGroup__c group1 = newScoringGroup('FirstGroup', survey.Id);
        ScoreValue__c scoreValue1 = newScoreValue(5, group1.Id, option1.Id);
        
        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(survey);
            SurveyScoringController controller = new SurveyScoringController(stdController);
            // The following json is an array that includes one object(ScoreValue), with the following attributes: option.Id, GroupScore name, and Value.
            // Given this data I'll try to insert it in the database.
            controller.scoringGroupStr = '[{"caption":"ScoringGroup1"}]';
            controller.scoringValuesJson  = '[{"optionId":"' + option1.Id + '","groupName":"ScoringGroup1","value":"1"}]';
            controller.continueAfterwards = 'true';

            C.wait(1);
            survey = [Select LastModifiedDate FROM Survey__c WHERE Id=:survey.Id limit 1];
            DateTime currentLastModifiedDate = survey.LastModifiedDate;
            //If i try to save the survey from the controller it should be posible.
            controller.saveScoring();

            //It should throw no error
            System.assert(!(ApexPages.hasMessages(ApexPages.Severity.FATAL) || ApexPages.hasMessages(ApexPages.Severity.ERROR)));

            //And it should update the survey.
            survey = [SELECT LastModifiedDate FROM Survey__c WHERE Id = :survey.Id];
            System.assertNotEquals(currentLastModifiedDate,survey.LastModifiedDate);
        Test.stopTest();
    }

    static testMethod void editDistributedPPIScore(){
        // Add license to create new ppi surveys
        LicenseSettings__c license = C.getLicense();
        license.PPI_Editable__c = true;
        license.UsePPI__c = true;
        update license;

        ISO_Country__c countryCode = new ISO_Country__c(Name='AA',ShortName__c='Test');
        insert countryCode;
        Language__c language = new Language__c(Name = 'XX',ShortLanguageName__c = 'XXLanguage');
        insert language;
        // Insert Survey to test
        Survey__c survey = new Survey__c(IsPPI__c=true,CountryCode__c='AA',LanguageCode__c='XX',PPIDataYear__c = 2003, Status__c = 'Draft');
        insert survey;
        // Setting license to true
        setPPILicenseSetting(true);
        // Insert Question in the sruvey
        Question__c question = newQuestion(survey.Id, 'QTest', 'Caption1',QuestionDO.TYPE_SECTION);
        // Insert Option for that question
        Option__c option1 = newOption(question.Id, 'OTest1', 1);
        Option__c option2 = newOption(question.Id, 'OTest2', 2);
        Option__c option3 = newOption(question.Id, 'OTest3', 3);
        // Setting ppi scores values
        option1.PPIScore__c = 1;
        option2.PPIScore__c = 2;
        option3.PPIScore__c = 3;
        update new List<Option__c>{option1, option2, option3};
        // Setting origin id != null to trigger test
        question.RemoteServerId__c = '1234';
        update question;
        
        Test.startTest();
            // Testing if it is a distributed survey
            ApexPages.StandardController stdController = new ApexPages.StandardController(survey);
            SurveyScoringController controller = new SurveyScoringController(stdController);
            System.assert(controller.wasDownloaded, 'Must be true since origin id is not null');
            // Edit some ppi score value to test the trigger
            option2.PPIScore__c = 25;
            try{
                update option2;
                System.assert(false,'Should fail since option2 change ppi score and is a distributed survey');
            }catch(Exception e){
                System.assert(e.getMessage().contains(System.label.SCORE_ERR_CANTEDITDISTRUBUTEDPPISCORE));
            }
        Test.stopTest();
    }

    /**
     *    Auxiliary method to test scoring, passing the section type as parameter
     *    @param sectionType Type of the section to create
     */
    static void testScoringSimple(String sectionType){
        Survey__c survey1 = newSurvey('FirstSurvey');
        Question__c question1 = newQuestion(survey1.Id, 'Name', 'Caption1', sectionType);
        Option__c option1 = newOption(question1.Id, 'NameOption', 1);
        setPPILicenseSetting(false);

        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
        SurveyScoringController controller = new SurveyScoringController(stdController);
        String questionString = controller.getQuestions();
        String lGroupsString = controller.getListGroups();
        String lScoresValues = controller.getListScoreValues();

        controller.scoringGroupStr = '[{"caption":"ScoringGroup1"}]';
        // The following json is an array that includes one object(ScoreValue), with the following attributes: option.Id, GroupScore name, and Value.
        // Given this data I'll try to insert it in the database.
        controller.scoringValuesJson  = '[{"optionId":"' + option1.Id + '","groupName":"ScoringGroup1","value":"1"}]';
        controller.continueAfterwards = 'true';
        controller.saveScoring();
        ScoringGroup__c myGroup = [select Id, Caption__c from ScoringGroup__c where Caption__c = 'ScoringGroup1'][0];
        ScoreValue__c myScoreValue = [select Id, Value__c, ScoringGroup__c from ScoreValue__c where ScoringGroup__c = :myGroup.Id][0];
        // After this I'll compare the harcoded value (from the json array) with the retrieved value.
        System.assertEquals(1, myScoreValue.Value__c);
    }

    /**
     * Utility Methods. TODO - Move to SoC architecture
     */

    private static void setPPILicenseSetting(Boolean value){
        LicenseSettings__c l = C.getLicense();
        l.PPI_Editable__c = value;
        l.UsePPI__c = true;
        l.Can_Distribute__c = value;
        update l;
    }

    static Survey__c newSurvey(String surveyName){
        Survey__c v = new Survey__c(Status__c = SurveyDO.STATUS_DRAFT, Name = surveyName);
        insert v;
        return v;
    }
    static Question__c newQuestion(Id surveyId, String name, String caption, String type){
        Question__c q = new Question__c(Name = name, Survey__c = surveyId, Caption__c = caption, Type__c = type);
        insert q;
        return q;
    }
    static Option__c newOption(Id questionId, String name, Integer position){
        Option__c o = new Option__c(Name = name, Position__c = position, Question__c = questionId);
        insert o;
        return o;
    }
    static ScoringGroup__c newScoringGroup(String caption, Id surveyId){
        ScoringGroup__c sg = new ScoringGroup__c (Caption__c = caption, Survey__c = surveyId);
        insert sg;
        return sg;
    }
    static ScoreValue__c newScoreValue(Decimal val, Id groupId, Id optionId){
        ScoreValue__c sv = new ScoreValue__c(Value__c = val, ScoringGroup__c = groupId, Option__c = optionId);
        insert sv;
        return sv;
    }
}
