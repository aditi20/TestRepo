/**
 * This test class is used to cover test cases for ScoreValueTH class
 * 
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Kaushik Ray
 */
@isTest
public class ScoreValueTHTest {

    /**
     * Test that creating a PPI score value updates the PPI score on the Option
     */
    static testMethod void testAddPpiScoringDetails() {

        Test.startTest();
        TestSurveyData testSurvey = TestSurveyData.addPpiTablesToStandardSurvey(
            TestSurveyData.addScoringGroupToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedPpiTemplate(), true
                ),
                true
            )
        );
        Test.stopTest();
        Map<Id, ScoreValue__c> createScoreValues = new Map<Id, ScoreValue__c>(
            testSurvey.getScoreValues(0)
        );
        System.assertEquals(5, createScoreValues.size());
        List<ScoreValue__c> updatedScoreValueList =
            new ScoreValueSelector().getWithParentFields(createScoreValues.keySet());
        for (ScoreValue__c scoreValue : updatedScoreValueList) {
            System.assertEquals(
                scoreValue.Value__c,
                scoreValue.Option__r.PPIScore__c,
                'Trigger should update Ppi score'
            );
        }
    }
}