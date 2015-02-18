/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
private class SurveyQuestionLogicControllerTest {

//------------
// Utility
//------------

    /**
     * Auxiliary method to create a new survey, and an instance of the controller and sets the current page for testing with the needed parameter
     * @param sectionType type of the section to create
     * @return SurveyQuestionLogicController instance
     */
    public static SurveyQuestionLogicController getNewController(String sectionType){

        Survey__c newSurvey = new Survey__c(Status__c = SurveyDO.STATUS_DRAFT); insert newSurvey;
        Question__c section = new Question__c(Survey__c = newSurvey.Id, Caption__c = QuestionDO.TYPE_SECTION, Name = QuestionDO.TYPE_SECTION, Type__c = sectionType );
        insert section;
        getQuestionsList(newSurvey.Id, section.Id,'Q');
        ApexPages.StandardController stdController = new ApexPages.StandardController(newSurvey);

        PageReference currentPage = Page.SurveyQuestionLogic;
        Test.setCurrentPage(currentPage);
        currentPage.getParameters().put('id', newSurvey.Id);

        return new SurveyQuestionLogicController(stdController);
    }

  // creates a list of 5 new questions and inserts them
  // also creates options and conditions for them
  public static list<Question__c> getQuestionsList(string surveyId, string parentId,string prefix){

    list<Question__c> listReturn = new list<Question__c>();
    Question__c auxQuestion;
    for (integer i = 0; i < 5; i++){
        auxQuestion = new Question__c (Survey__c = surveyId, Caption__c = prefix + i, Name = prefix + i, Parent__c = parentId,Type__c = 'Text', Position__c = i+1);
        listReturn.add(auxQuestion);
    }
    insert listReturn;

    Option__c auxOption;
    list<Option__c> listOptions = new list<Option__c>();
    SkipCondition__c auxCondition;
    list<SkipCondition__c> listConditions = new list<SkipCondition__c>();
    for (integer i = 0; i < 5; i++){
        auxOption = new Option__c (Question__c = listReturn[i].Id, Name = prefix + i, Position__c = i+1);
        listOptions.add(auxOption);
        if (i != 0) {
            auxCondition = new SkipCondition__c (
                Parent__c = listReturn[i].Id,
                SourceQuestion__c = listReturn[0].Id,
                Condition__c = 'Is',
                Negate__c = false,
                SkipValue__c = 'Test'
            );
            listConditions.add(auxCondition);
        }
    }
    insert listOptions;
    insert listConditions;

    return listReturn;
  }

    /**
     * Auxiliary method to generalize testing for section type with a simple skipLogic
     * @param sectionType type of the section to create
     */
    static void testSectionSimpleSkipLogic(String sectionType){
        LicenseSettings__c testLicense = newLicense(false,'Test');
        insert testLicense;
        SurveyQuestionLogicController controller = getNewController(sectionType);

        // test with values
        Question__c sectionQuestion = [SELECT Id, Caption__c, Name, Type__c FROM Question__c WHERE Type__c =:sectionType][0];
        Question__c theQuestion = [SELECT Id, Caption__c, Name, Type__c FROM Question__c WHERE Type__c='Text'][0];

        // generate the json string with skip logic on "theQuestion" asociated to "sectionQuestion"
        string jsonSkipLogic =
        '[{'+
            '"type":"'+sectionQuestion.Type__c+'",'+
            '"id":"'+sectionQuestion.Id+'",'+
            '"caption":"'+sectionQuestion.Caption__c+'",'+
            '"skipLogicOperator":"All",'+
            '"skipLogicBehavior":"Show",'+
            '"skipconditions":[{"id":"ha1elfu9","sourceQuestionId":"'+theQuestion.Id+'","condition":"Is","value":"1","negate":false}]'+
        '}]';

        PageReference currentPage = Page.SurveyQuestionLogic;
        currentPage.getParameters().put('questions', jsonSkipLogic);
        currentPage.getParameters().put('quicksave', 'true');
        Test.setCurrentPage(currentPage);

        system.assertEquals(null, controller.save());
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.FATAL) && !ApexPages.hasMessages(ApexPages.Severity.ERROR),
            'Should not have failed since the survey status is draft');

        // Verify skip condition is correctly associated with the repeated section
        System.assertEquals(
            1,
            [
                SELECT
                    Name
                FROM
                    SkipCondition__c
                WHERE
                    Condition__c = 'Is'
                    AND Negate__c = false
                    AND Parent__c =: sectionQuestion.Id
                    AND SourceQuestion__c=:theQuestion.Id
                    AND SkipValue__c='1'
            ].size()
        );
    }


    /**
     * Test method for repeated section with skip logic
     */
    static testMethod void saveTestRepeatedSection(){
        Test.startTest();
            testSectionSimpleSkipLogic(QuestionDO.TYPE_REPEAT);
        Test.stopTest();
    }


    /**
     * Test method for section with skip logic
     */
    static testMethod void saveTestSection(){
        Test.startTest();
            testSectionSimpleSkipLogic(QuestionDO.TYPE_SECTION);
        Test.stopTest();
    }

    /**
     * Simple test method for skip conditions
     */
    static testMethod void saveTest(){
        LicenseSettings__c testLicense = newLicense(false,'Test');
        insert testLicense;

        SurveyQuestionLogicController controller = getNewController(QuestionDO.TYPE_SECTION);

        // test with values
        Question__c firstQuestion = [SELECT Id, Caption__c, Name, Type__c FROM Question__c][1];
        Question__c theQuestion   = [SELECT Id, Caption__c, Name, Type__c FROM Question__c][2];
        
        string newQuestion = '[{'
            +'"id":"' + theQuestion.Id + '",'
            +'"caption":"' + theQuestion.Caption__c + '",'
            +'"type":"' + theQuestion.Type__c + '",'
            +'"options":[{"id":"a","name":"a-orig","position":"1"},{"id":"b","name":"b","position":"2"}],'
            +'"skipconditions":[{"id":"123","sourceQuestionId":"' + firstQuestion.Id + '","condition":"Is","value":"Test","negate":true},{"id":"456","sourceQuestionId":"' + firstQuestion.Id + '","condition":"Is","value":"OtherTest","negate":true}]'
            +'}]';

        PageReference currentPage = Page.SurveyQuestionLogic;
        currentPage.getParameters().put('questions', newQuestion);
        currentPage.getParameters().put('quicksave', 'true');
        Test.setCurrentPage(currentPage);

        system.assertEquals(null, controller.save());
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.FATAL) && !ApexPages.hasMessages(ApexPages.Severity.ERROR));


        // test with non-draft survey
        Survey__c theSurvey = [SELECT id, Status__c FROM Survey__c];
        SurveyDO.updateSurveysStatus(new List <Survey__c> {theSurvey}, SurveyDO.STATUS_PUBLISHED);
        
        Test.startTest();
            controller.save();
        Test.stopTest();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.FATAL) || ApexPages.hasMessages(ApexPages.Severity.ERROR),
                    'Should have failed since the survey is non-draft');
    }

    /**
     * Test case that test skip condition for GPS Question depending on previous question and future question
     */
    static testMethod void saveGPSQuestionLogic() {
        // Create a survey record
        Survey__c survey = TestUtils.createSurvey('survey');

        // Create a new section
        Question__c sectionQuestion = TestUtils.addQuestion(survey , 1, 'section' , QuestionDO.TYPE_SECTION);

        // Create questions
        Question__c freeTextQuestion = TestUtils.addQuestion(sectionQuestion, 1, 'freeText', QuestionDO.TYPE_TEXT_SHORT);
        Question__c gpsQuestion = TestUtils.addQuestion(sectionQuestion, 2, 'gps', QuestionDO.TYPE_GPS);
        Question__c staticQuestion = TestUtils.addQuestion(sectionQuestion, 3,'static', QuestionDO.TYPE_STATIC);

        // Verify questions are inserted properly
        System.assertEquals(true, freeTextQuestion != null);
        System.assertEquals(true, gpsQuestion != null);
        System.assertEquals(true, staticQuestion != null);

        String newQuestion = '[{'
            +'"id":"' + gpsQuestion.Id + '",'
            +'"caption":"' + gpsQuestion.Caption__c + '",'
            +'"type":"' + gpsQuestion.Type__c + '",'
            +'"skipconditions":[{"id":"previousGPS","sourceQuestionId":"' + freeTextQuestion.Id + '","condition":"Is","value":"Test","negate":false}]'
            +'},{'
            +'"id":"' + staticQuestion.Id + '",'
            +'"caption":"' + staticQuestion.Caption__c + '",'
            +'"type":"' + staticQuestion.Type__c + '",'
            +'"skipconditions":[{"id":"futureGPS","sourceQuestionId":"' + gpsQuestion.Id + '","condition":"ANSWERED","negate":true}]'
            +'}]';

        ApexPages.StandardController stdController = new ApexPages.StandardController(survey);
        PageReference currentPage = Page.SurveyQuestionLogic;
        currentPage.getParameters().put('id', survey.Id);
        currentPage.getParameters().put('questions', newQuestion);
        currentPage.getParameters().put('quicksave', 'true');
        Test.setCurrentPage(currentPage);

        SurveyQuestionLogicController controller = new SurveyQuestionLogicController(stdController);
        Test.startTest();
        controller.save();
        Test.stopTest();

        // Verify skip condition is correctly associated with the GPS question dependent on previous question
        System.assertEquals(
            1,
            [
                SELECT
                    Name
                FROM
                    SkipCondition__c
                WHERE
                    Condition__c = 'Is'
                    AND Negate__c = false
                    AND Parent__c = :gpsQuestion.Id
                    AND SourceQuestion__c = :freeTextQuestion.Id
                    AND SkipValue__c = 'Test'
            ].size()
        );

        // Verify skip condition is correctly associated with the future question dependent on GPS question
        System.assertEquals(
            1,
            [
                SELECT
                    Name
                FROM
                    SkipCondition__c
                WHERE
                    Condition__c = 'ANSWERED'
                    AND Negate__c = true
                    AND Parent__c = :staticQuestion.Id
                    AND SourceQuestion__c = :gpsQuestion.Id
            ].size()
        );
    }

    static LicenseSettings__c newLicense(Boolean PPIEditable, String licName){
        list<LicenseSettings__c> lS = [SELECT PPI_Editable__c FROM LicenseSettings__c limit 1];
        delete lS;
        LicenseSettings__c li = new LicenseSettings__c(PPI_Editable__c = PPIEditable, Name = licName);
        return li;
    }

    /**
     * This test the proper throw an error when I try to make changes in the Field mapping
     * for this survey mean while the survey is been update.
     * This should not let me save the changes since the survey was modified.
     */
    static testMethod void testOutofSyncSaveError(){

        // PREPARE: Create a base survey that will be edited
        Survey__c survey = new Survey__c(Name='survey');
        insert survey;
        Question__c section = new Question__c(Survey__c=survey.Id,Name=QuestionDO.TYPE_SECTION,Caption__c=QuestionDO.TYPE_SECTION,Position__c=1,Type__c=QuestionDO.TYPE_SECTION);
        insert section;
        Question__c sourceq = new Question__c(Survey__c=survey.Id,Name='source',Parent__c=section.Id, Caption__c='source',Position__c=1,Type__c=QuestionDO.TYPE_TEXT_SHORT);
        Question__c targetq = new Question__c(Survey__c=survey.Id,Name='target',Parent__c=section.Id, Caption__c='target',Position__c=2,Type__c=QuestionDO.TYPE_TEXT_SHORT);
        insert new Question__c[]{sourceq,targetq};

        // TEST: Have someone else edit the survey, and try to edit the skip condition
        string newQuestion = '[{'
            +'"id":"' + section.Id + '",'
            +'"caption":"' + section.Caption__c + '",'
            +'"type":"' + section.Type__c + '",'
            +'"skipconditions":[]'
            +'},{'
            +'"id":"' + sourceq.Id + '",'
            +'"caption":"' + sourceq.Caption__c + '",'
            +'"type":"' + sourceq.Type__c + '",'
            +'"skipconditions":[]'
            +'},{'
            +'"id":"' + targetq.Id + '",'
            +'"caption":"' + targetq.Caption__c + '",'
            +'"type":"' + targetq.Type__c + '",'
            +'"skipconditions":['
                +'{'
                +'"id":"qwerty",'
                +'"sourceQuestionId":"' + sourceq.Id + '",'
                +'"condition":"' + SkipConditionDO.CONDITION_ISANSWERED + '",'
                +'"value":"Test",'
                +'"negate":true}]'
            +'}]';

        PageReference currentPage = Page.SurveyQuestionLogic;
        currentPage.getParameters().put('id', survey.Id);
        Test.setCurrentPage(currentPage);
        SurveyQuestionLogicController controller = new SurveyQuestionLogicController(new ApexPages.StandardController(survey));

        Test.startTest();
            // Edit the survey outside the controller
            C.wait(1);
            survey = [SELECT Id, Alias__c FROM Survey__c WHERE Id = :survey.Id];
            survey.Alias__c = 'Changed';
            update survey;

            currentPage.getParameters().put('questions', newQuestion);
            currentPage.getParameters().put('quicksave', 'true');
            controller.save();
        Test.stopTest();

        //It should throw an error popup to refresh the page
        System.assert(controller.concurrentSave, 'Should throw an error popup to refresh the page');
    }

    /**
     * Validate the insertion of a skip condition with an invalid source question
     */
    static testMethod void validateInsertionOfConditionWithNonValidQuestionAsSourceQuestion(){
        // Try to insert
        prepareInsertAndUpdateInvalidQuestionAsSourceQuestion(true);
        
    }

    /**
     * Validate the update of a skip condition with an invalid source question
     */
    static testMethod void validateUpdateOfConditionWithNonValidQuestionAsSourceQuestion(){
        // Try to update
        prepareInsertAndUpdateInvalidQuestionAsSourceQuestion(false);
        
    }

    /**
     * Auxiliary test that prepares the conditions to execute the test of:
     * 1- Try to insert a skip condition with a cascading as a source question.
     * 2- Try to update an existent valid skip condition changing actual source question for a cascading question.
     */
    public static void prepareInsertAndUpdateInvalidQuestionAsSourceQuestion(Boolean isInsertingWrong){
        LicenseSettings__c testLicense = newLicense(false,'Test');
        insert testLicense;

        Survey__c newSurvey = new Survey__c(Name = 'Test source logic');
        insert newSurvey;
        
        PageReference currentPage = Page.SurveyQuestionLogic;
        currentPage.getParameters().put('id', newSurvey.Id);
        Test.setCurrentPage(currentPage);

        ApexPages.StandardController stdController = new ApexPages.StandardController(newSurvey);
        SurveyQuestionLogicController controller   = new SurveyQuestionLogicController(stdController);
        


        Question__c section = new Question__c(Name       = 'section1', 
                                              Caption__c = 'Section1',
                                              Type__c    = QuestionDO.TYPE_SECTION,
                                              Survey__c  = newSurvey.Id);
        insert section;
        
        // Create cascading select library
        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect('Cascading Select', levelsData);

        Question__c cascading = new Question__c(Name               = 'cascading', 
                                                Caption__c         = 'cascading',
                                                Survey__c          = newSurvey.Id, 
                                                Parent__c          = section.Id, 
                                                Position__c        = 1,
                                                Type__c            = QuestionDO.TYPE_CASCADING_SELECT,
                                                CascadingSelect__c = levels[0].CascadingSelect__r.Id);

        Question__c freeText  = new Question__c(Name        = 'freeText', 
                                                Caption__c  = 'freeText', 
                                                Survey__c   = newSurvey.Id, 
                                                Parent__c   = section.Id,
                                                Position__c = 2,
                                                Type__c     = QuestionDO.TYPE_TEXT_SHORT);
        
        Question__c freeText2 = new Question__c(Name        = 'freeText2', 
                                                Caption__c  = 'freeText2', 
                                                Survey__c   = newSurvey.Id, 
                                                Parent__c   = section.Id,
                                                Position__c = 3,
                                                Type__c     = QuestionDO.TYPE_TEXT_SHORT);
        insert new List<Question__c>{cascading, freeText, freeText2};

        if (isInsertingWrong) {
            SkipCondition__c logic = new SkipCondition__c(
                SourceQuestion__c = cascading.Id,
                Condition__c = '',
                Parent__c = freeText.Id,
                SkipValue__c = ''
            );
            Test.startTest();
                try{
                    insert logic;
                    system.assert(false, 'This condition cannot be inserted cause source question is type cascading');
                }catch(Exception e){
                    system.assert(e.getMessage().contains(String.format(System.Label.SKIP_CONDITION_INVALID_SOURCEQUESTION, new String[]{cascading.Name, ' '}) + System.Label.SKIP_CONDITION_INVALID_SOURCEQUESTIONFINALMESSAGE), 'This condition cannot be inserted cause source question is type cascading');
                }
            Test.stopTest();
        } else {
            SkipCondition__c logic = new SkipCondition__c(
                SourceQuestion__c = freeText.Id,
                Condition__c = '',
                Parent__c = freeText2.Id,
                SkipValue__c = ''
            );
            insert logic;

            // Change source question to cascading
            logic.SourceQuestion__c = cascading.Id;

            Test.startTest();
                try{
                    update logic;
                    system.assert(false, 'This condition cannot be updated cause source question is type cascading');
                }catch(Exception e){
                    system.assert(e.getMessage().contains(String.format(System.Label.SKIP_CONDITION_INVALID_SOURCEQUESTION, new String[]{cascading.Name, ' '}) + System.Label.SKIP_CONDITION_INVALID_SOURCEQUESTIONFINALMESSAGE), 'This condition cannot be updated cause source question is type cascading');
                }
            Test.stopTest();
        }
    }
}