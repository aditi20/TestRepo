/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public class SurveyPreviewControllerTest{

    // Test for preview controller
    static testMethod void testPreview(){

        // Set data
        Survey__c survey1 = newSurvey('FirstSurvey');

        Question__c section = newQuestion(survey1.Id, 'Section', 'Caption1', QuestionDO.TYPE_SECTION, 1, null);
        Question__c question1 = newQuestion(survey1.Id, 'Name', 'Caption1', QuestionDO.TYPE_TEXT_SHORT, 1, section.Id);
        Question__c question2 = newQuestion(survey1.Id, 'Name2', 'Caption2', QuestionDO.TYPE_TEXT_SHORT, 2, section.Id);

        Option__c option1 = newOption(question1.Id, 'NameOption', 1);

        SkipCondition__c skipCondition1 = newSkipCondition(question1.Id, question2.Id, 'val1', 'Is');

        ScoringGroup__c scoringGroup1 = newScoringGroup(survey1.Id, 'captionScoring');
        ScoreValue__c scoreValue1 = newScoreValue(scoringGroup1.Id, option1.Id, 7);

        //load controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
        SurveyPreviewController controller = new SurveyPreviewController(stdController);

        PageReference pg = new PageReference('/apex/SurveyPreview');
        Test.setCurrentPage(pg);

        String previousPage = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/apex/SurveyManager';

        ApexPages.currentPage().getHeaders().put('Referer', previousPage );

        Test.startTest();
            controller.setDataForPreview();

            String serializedQuestions = controller.getLastBatchOfquestions();
        Test.stopTest();

        String expectedString  = '[{'
                    +'"type":"' + QuestionDO.TYPE_SECTION + '",'
                    +'"skipLogicOperator":"All",'
                    +'"skipLogicBehavior":"Show",'
                    +'"skipconditions":[],'
                    +'"scoreValues":null,'
                    +'"samePage":false,'
                    +'"required":false,'
                    +'"remoteEditable":false,'
                    +'"qhint":null,'
                    +'"prevSourceQuestionName":null,'
                    +'"prevSourceQuestion":null,'
                    +'"position":1,'
                    +'"parent":null,'
                    +'"originId":null,'
                    +'"options":[],'
                    +'"name":"Section",'
                    +'"minimum":null,'
                    +'"maximum":null,'
                    +'"id":"' + section.id + '",'
                    +'"doBefore":null,'
                    +'"doAfter":null,'
                    +'"deletedOptions":[],'
                    +'"cascadingName":null,'
                    +'"cascadingId":null,'
                    +'"caption":"Caption1"'
            +'},'
            +'{'
                    +'"type":"' + QuestionDO.TYPE_TEXT_SHORT + '",'
                    +'"skipLogicOperator":"All",'
                    +'"skipLogicBehavior":"Show",'
                    +'"skipconditions":[{'
                                            +'"value":"val1",'
                                            +'"sourceQuestionId":"' + question2.Id + '",'
                                            +'"parent":"' + question1.Id + '",'
                                            +'"negate":false,'
                                            +'"id":"' + skipCondition1.Id +'",'
                                            +'"condition":"Is"'
                                    +'}],'
                    +'"scoreValues":null,'
                    +'"samePage":false,'
                    +'"required":false,'
                    +'"remoteEditable":false,'
                    +'"qhint":null,'
                    +'"prevSourceQuestionName":null,'
                    +'"prevSourceQuestion":null,'
                    +'"position":1,'
                    +'"parent":"' + section.Id + '",'
                    +'"originId":null,'
                    +'"options":[{'
                                    +'"scoreValues":[{'
                                            +'"value":7,'
                                            +'"ScoringGroupId":"' + scoringGroup1.Id + '",'
                                            +'"optionId":"' + option1.Id +'",'
                                            +'"id":"' + scoreValue1.Id  + '"'
                                    +'}],'
                                    +'"ppiScore":null,'
                                    +'"position":1,'
                                    +'"name":"NameOption",'
                                    +'"id":"' + option1.Id + '",'
                                    +'"hasScoreValues":false,'
                                    +'"hasPPIScoreValues":false,'
                                    +'"caption":"NameOption"'
                            +'}],'
                    +'"name":"Name",'
                    +'"minimum":null,'
                    +'"maximum":null,'
                    +'"id":"' + question1.Id +'",'
                    +'"doBefore":null,'
                    +'"doAfter":null,'
                    +'"deletedOptions":[],'
                    +'"cascadingName":null,'
                    +'"cascadingId":null,'
                    +'"caption":"Caption1"'
            +'},'
            +'{'
                    +'"type":"' + QuestionDO.TYPE_TEXT_SHORT + '",'
                    +'"skipLogicOperator":"All",'
                    +'"skipLogicBehavior":"Show",'
                    +'"skipconditions":[],'
                    +'"scoreValues":null,'
                    +'"samePage":false,'
                    +'"required":false,'
                    +'"remoteEditable":false,'
                    +'"qhint":null,'
                    +'"prevSourceQuestionName":null,'
                    +'"prevSourceQuestion":null,'
                    +'"position":2,'
                    +'"parent":"' + section.Id + '",'
                    +'"originId":null,'
                    +'"options":[],'
                    +'"name":"Name2",'
                    +'"minimum":null,'
                    +'"maximum":null,'
                    +'"id":"' + question2.Id + '",'
                    +'"doBefore":null,'
                    +'"doAfter":null,'
                    +'"deletedOptions":[],'
                    +'"cascadingName":null,'
                    +'"cascadingId":null,'
                    +'"caption":"Caption2"'
            +'}]';

        system.assertEquals(expectedString, serializedQuestions);
    }

    /**
     * Test method to verify fetching of Scoring Group other than PPI while preview 
     */
    static testMethod void testScoringGroupFetchedOnPreview() {
        TestSurveyData testSurvey =  TestSurveyData.createFullPpiTemplate();

        ScoringGroupDomain scoringGroupDomain =
            new ScoringGroupDomain.Constructor().constructWithRecords(
                new List<ScoringGroup__c> {
                    ScoringGroupDomainTest.createRecord(
                        'Test Scoring Group 1',
                        testSurvey.testSurvey.Id,
                        false
                    ),
                    ScoringGroupDomainTest.createRecord(
                        'Test Scoring Group 2',
                        testSurvey.testSurvey.Id,
                        false
                    )
                }
            );
        scoringGroupDomain.insertRecords();
        System.assertEquals(2, scoringGroupDomain.records.size());
        for (ScoringGroup__c scoringGroup : (List<ScoringGroup__c>) scoringGroupDomain.records) {
            System.assert(scoringGroup.Id != null);
        }

        Test.startTest();
        ApexPages.StandardController stdController =
            new ApexPages.StandardController(testSurvey.testSurvey);
        SurveyPreviewController controller = new SurveyPreviewController(stdController);
        Test.stopTest();

        System.assert(controller.scoringGroups.size() == 2);
    }

    //----------Utility methods------------
    static Survey__c newSurvey(String surveyName){
        Survey__c sur = new Survey__c(Status__c = SurveyDO.STATUS_DRAFT, Name = surveyName);
        insert sur;
        return sur;
    }
    static Question__c newQuestion(Id surveyId, String name, String caption, String type, Integer position, Id parent) {
        Question__c question = new Question__c(Name = name, Survey__c = surveyId, Caption__c = caption, Type__c = type, Position__c = position, Parent__c = parent);
        insert question;
        return question;
    }
    static Option__c newOption(Id questionId, String name, Integer position){
        Option__c option = new Option__c(Name = name, Caption__c = name, Position__c = position, Question__c = questionId);
        insert option;
        return option;
    }

    static SkipCondition__c newSkipCondition(Id questionParent, Id questionSrc, String val, String condition){
        SkipCondition__c sc = new SkipCondition__c(
            Parent__c = questionParent,
            SourceQuestion__c = questionSrc,
            SkipValue__c = val,
            Condition__c = condition
        );
        insert sc;
        return sc;
    }

    static ScoringGroup__c newScoringGroup(Id surveyId, String caption){
        ScoringGroup__c sg = new ScoringGroup__c (Survey__c = surveyId, Caption__c = caption);
        insert sg;
        return sg;
    }

    static ScoreValue__c newScoreValue( Id scoreGroupId, Id optionScoreId, Integer value ){
        ScoreValue__c sv = new ScoreValue__c (ScoringGroup__c = scoreGroupId, Option__c = optionScoreId, Value__c = value);
        insert sv;
        return sv;
    }
}
