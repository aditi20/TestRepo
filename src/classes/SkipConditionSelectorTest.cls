/**
 * Test class for the SkipConditionSelector class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class SkipConditionSelectorTest {

    /**
     * Test get all for a survey
     */
    static testMethod void testGetAllForSurvey() {

        TestSurveyData testSurvey =
            TestSurveyData.addSkipConditionsToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true)
            );
        Test.startTest();
        SkipConditionSelector skipConditionSelector = new SkipConditionSelector();
        List<SkipCondition__c> skipConditions =
            skipConditionSelector.getAllForSurvey(testSurvey.testSurvey.Id);
        Test.stopTest();
        System.assertEquals(1, skipConditions.size());
    }
}