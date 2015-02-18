/**
 * Test class for SurveyScoringService
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray  
 */
@isTest
public class SurveyScoringServiceTest {

    /**
     * Test method to verify loading of Scoring values
     */
    static testMethod void testLoadScoringGroups() {
        TestSurveyData testSurvey = TestSurveyData.addScoringGroupToStandardSurvey(
            TestSurveyData.createStandardTestSurvey(
                SurveyDOTest.createInsertedPpiTemplate(), false, false
            ),
            true
        );

        List<ScoringGroupDomain.ScoringGroup> listGroups =
            new List<ScoringGroupDomain.ScoringGroup>();

        Test.startTest();
        SurveyScoringService.loadScoringGroups(testSurvey.testSurvey, listGroups);
        Test.stopTest();

        System.assertEquals(1, listGroups.size(), 'List Groups should have records');
        System.assertEquals(listGroups[0].Caption, 'PPI', 'PPI Scoring Group');
    }

    /**
     * Test method to verify parsing of Scoring values
     */
    static testMethod void testParseSurveyScoring() {
        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(
            SurveyDOTest.createInsertedPpiTemplate(),
            false
        );

        Survey__c survey =
            new SurveySelector().getSpecificWithSurveyVersion(testSurvey.testSurvey.Id);
        DateTime currentLastModifiedDate = survey.LastModifiedDate;

        String scoringGroupStr = '[{"caption":"PPI"}]';
        String scoringValuesJson  =
            '[{"optionId":"' + testSurvey.getOption(0, 2, 0).Id +
                '","groupName":"PPI","value":"-1"}]';
        C.wait(1);

        Test.startTest();
        survey =
            SurveyScoringService.parseSurveyScoring(survey, scoringGroupStr, scoringValuesJson);
        Test.stopTest();

        System.assert(
            !(
                ApexPages.hasMessages(ApexPages.Severity.FATAL) ||
                ApexPages.hasMessages(ApexPages.Severity.ERROR)
            )
        );

        System.assertNotEquals(currentLastModifiedDate, survey.LastModifiedDate);
    }
}