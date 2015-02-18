/**
 * Test class for the SurveyMappingSelector class
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class SurveyMappingSelectorTest {

    /**
     * Test get all for a survey
     */
    static testMethod void testGetAllForSurvey() {

        TestSurveyData testSurvey =
            TestSurveyData.addObjectMappingToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true)
            );
        Test.startTest();
        SurveyMappingSelector surveyMappingSelector = new SurveyMappingSelector();
        List<SurveyMapping__c> surveyMappings =
            surveyMappingSelector.getAllForSurveyIds(
                new Set<String>{testSurvey.testSurvey.Id}
            );
        Test.stopTest();
        System.assertEquals(2, surveyMappings.size());
    }
}