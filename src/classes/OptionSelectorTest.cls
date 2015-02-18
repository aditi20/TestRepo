/**
 * Test class for the option selector class
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class OptionSelectorTest {

    /**
     * Test get all for a survey
     */
    static testMethod void testGetAllForSurvey() {
        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, true);
        OptionSelector questionSelector = new OptionSelector();
        List<Option__c> options =
            questionSelector.getAllForSurvey(testSurvey.testSurvey.Id);
        System.assertEquals(5, options.size());
    }

    /**
     * Test method to verify fetching of survey's data ordered by Question's Position
     */
    static testMethod void testGetAllForSurveyOrdered() {
        TestSurveyData testSurvey =  TestSurveyData.createFullPpiTemplate();

        Test.startTest();
        OptionSelector questionSelector = new OptionSelector();
        List<Option__c> options =
            questionSelector.getAllForSurveyOrdered(testSurvey.testSurvey.Id);
        Test.stopTest();
        System.assertEquals(42, options.size());

        List<Question__c> questions =
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id);

        for (Integer i = 1; i < 10 ; i++) {
            System.assertEquals(i, questions[i-1].Position__c);
            List<Option__c> optionList = testSurvey.optionMap.get(questions[i].Id);
            for (Integer j = 1; j < 4; j++) {
                System.assertEquals(j, optionList[j-1].Position__c);
            }
        }
    }
}