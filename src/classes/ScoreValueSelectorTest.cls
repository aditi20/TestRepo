/**
 * Test class for the ScoreValueSelector class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray  
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class ScoreValueSelectorTest {

    /**
     * Test method to verify fetching all score value records for specified question Ids
     */
    static testmethod void testGetForQuestionIds() {
        TestSurveyData testSurvey = TestSurveyData.addScoringGroupToStandardSurvey(
            TestSurveyData.createStandardTestSurvey(null, false, false), true
        );

        Test.startTest();
        List<ScoreValue__c> scoreValueList =
            new ScoreValueSelector().getForQuestionIds(
                new Set<Id> {testSurvey.getQuestion(0, 2).Id}
            );
        Test.stopTest();

        System.assertEquals(5, scoreValueList.size(), 'Score Value records should get selected');
    }

    /**
     * Test method to verify fetching all score value records along with relationship fields
     */
    static testmethod void testGetWithParentFields() {
        TestSurveyData testSurvey = TestSurveyData.addScoringGroupToStandardSurvey(
            TestSurveyData.createStandardTestSurvey(null, false, false), true
        );
        Test.startTest();
        List<ScoreValue__c> actualScoreValueList =
            new ScoreValueSelector().getWithParentFields(
                new Set<Id> {
                    testSurvey.getScoreValue(0, 0).Id,
                    testSurvey.getScoreValue(0, 1).Id
                }
            );
        Test.stopTest();
        System.assertEquals(
            2,
            actualScoreValueList.size(),
            'Score Value records should get selected'
        );

        System.assert(
            actualScoreValueList[0].ScoringGroup__r.isPPI__c,
            'Field isPPI_c should be true. Relationship field not properly fetched'
        );
    }

    /**
     * Test get all for a survey
     */
    static testMethod void testGetAllForSurvey() {

        TestSurveyData testSurvey =
            TestSurveyData.addScoringGroupToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true), false
            );
        Test.startTest();
        ScoreValueSelector scoreValueSelector = new ScoreValueSelector();
        List<ScoreValue__c> scoreValues =
            scoreValueSelector.getAllForSurvey(testSurvey.testSurvey.Id);
        Test.stopTest();
        System.assertEquals(5, scoreValues.size());
    }
}