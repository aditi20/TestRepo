/**
 * Test class for the QuestionSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 * @author Kaushik Ray
 */
@isTest
public with sharing class QuestionSelectorTest {

    private static Survey__c survey1;
    private static Survey__c survey2;

    /**
     * Test method to verify fetching of Question records with specified Ppi survey Id
     */
    static testmethod void testFetchAllForPpiSurveyIds() {
        TestUtils.updatePpiLicenseSettings();

        TestSurveyData kenyaPpiSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(SurveyDOTest.createInsertedPpiTemplate(
                    LanguageWrapperTest.insertRecord('AA', 'Afar'),
                    ISOCountryWrapperTest.insertRecord('KE', 'KENYA'),
                    2011
                ), false)
            );
        TestSurveyData italyPpiSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(SurveyDOTest.createInsertedPpiTemplate(
                    LanguageWrapperTest.insertRecord('LA', 'LATIN'),
                    ISOCountryWrapperTest.insertRecord('IT', 'ITALY'),
                    2013
                ), false)
            );
        italyPpiSurvey.testSurvey.isTemplate__c = false;
        italyPpiSurvey.testSurvey.isPPI__c = false;
        update italyPpiSurvey.testSurvey;

        Test.startTest();
        List<Question__c> kenyaQuestionList =
            new QuestionSelector().getAllForPPISurveyId(kenyaPpiSurvey.testSurvey.Id);
        List<Question__c> italyQuestionList =
            new QuestionSelector().getAllForPPISurveyId(italyPpiSurvey.testSurvey.Id);
        Test.stopTest();

        // Question records are fetched properly for Survey1 having isPPI and isTemplate true
       System.assertEquals(7, kenyaQuestionList.size());

        // Question records are not fetched as Survey2 is having isPPI true and isTemplate false
        System.assertEquals(0, italyQuestionList.size());
    }

    /**
     * Test method to verify fetching of Question records with specified survey Ids
     */
    static testmethod void testFetchAllForSurveyIds() {

        TestSurveyData testSurvey1 = TestSurveyData.createStandardTestSurvey(null, false);
        TestSurveyData testSurvey2 = TestSurveyData.createStandardTestSurvey(null, false);

        Test.startTest();
        List<Question__c> questionsList = new QuestionSelector().getAllForSurveyIds(
            new Set<String> {testSurvey1.testSurvey.Id, testSurvey2.testSurvey.Id},
            1
        );
        Test.stopTest();
    }
    /**
     * Method to test fetching all question records for specified PPI Survey Id
     */
    static testMethod void testGetAllForPpiSurveyId() {
        Id surveyId = addSurvey();
        Test.startTest();
        List<Question__c> questions = new QuestionSelector().getAllForPpiSurveyId(surveyId);
        Test.stopTest();

        System.assertEquals(2, questions.size(), 'Question should get selected properly');
    }

    /**
     * Method to test fetching all question records along with related options
     */
    static testMethod void testGetWithOptions() {
        Id surveyId = addSurvey();

        Test.startTest();
        List<Question__c> questions = new QuestionSelector().getWithOptions(surveyId, 0);
        Test.stopTest();

        System.assertEquals(2, questions.size(), 'Question should get selected properly');
        System.assertEquals(
            5,
            questions[1].Options__r.size(),
            'Options should get selected properly'
        );
    }

    private static Id addSurvey() {
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        survey = new SurveySelector().getSpecificWithSurveyVersion(survey.Id);
        UnitOfWork unitOfWork = new UnitOfWork();

        Question__c section = QuestionDOTest.createSection(0);
        unitOfWork = QuestionDOTest.addQuestionToUnitOfWork(
            section,
            null,
            survey,
            unitOfWork,
            1
        );
        QuestionDOTest.SelectQuestion selectQuestion = new QuestionDOTest.SelectQuestion(
            QuestionDO.TYPE_RADIO,
            section,
            survey
        );
        selectQuestion.generateQuestion(0);
        selectQuestion.createOptions(5);
        unitOfWork = selectQuestion.addQuestionToUnitOfWork(unitOfWork, 2);
        unitOfWork = selectQuestion.addOptionsToUnitOfWork(unitOfWork, 1);

        unitOfWork.commitWork();
        return survey.Id;
    }
}