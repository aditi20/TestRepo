/**
 * Test class for the QuestionMappingSelector class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class QuestionMappingSelectorTest {

    /**
     * Test get all for a survey
     */
    static testMethod void testGetAllForSurvey() {

        TestSurveyData testSurvey =
            TestSurveyData.addObjectMappingToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, false)
            );
        Test.startTest();
        QuestionMappingSelector questionMappingSelector = new QuestionMappingSelector();
        List<QuestionMapping__c> questionMappings =
            questionMappingSelector.getAllForSurvey(testSurvey.testSurvey.Id);
        Test.stopTest();
        System.assertEquals(2, questionMappings.size());
    }
}