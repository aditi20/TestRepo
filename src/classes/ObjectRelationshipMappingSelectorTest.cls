/**
 * Test class for the ObjectRelationshipMappingSelector class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class ObjectRelationshipMappingSelectorTest {

    /**
     * Test get all for a survey
     */
    static testMethod void testGetAllForSurvey() {

        TestSurveyData testSurvey =
            TestSurveyData.addObjectMappingToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true)
            );
        Test.startTest();
        ObjectRelationshipMappingSelector objectRelationshipMappingSelector =
            new ObjectRelationshipMappingSelector();
        List<ObjectRelationshipMapping__c> objectRelationshipMappings =
            objectRelationshipMappingSelector.getAllForSurvey(testSurvey.testSurvey.Id);
        Test.stopTest();
        System.assertEquals(1, objectRelationshipMappings.size());
    }
}