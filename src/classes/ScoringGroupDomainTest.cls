/**
 * Test class for the ScoringGroup__c object domain class
 * Deals with:
 *     - Creation of a scoring group
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Kaushik Ray  
 */
@isTest
public class ScoringGroupDomainTest {

    public static final String TEST_SCORING_GROUP_CAPTION = 'testScoringGroup';
    /**
     * Method to create Scoring Group record
     */
    public static ScoringGroup__c createRecord(String caption, Id surveyId, Boolean isPPI) {
        ScoringGroup__c scoringGroupInstance =
            new ScoringGroup__c(
                Caption__c = caption,
                Survey__c = surveyId,
                isPPI__c = isPPI
            );
        return scoringGroupInstance; 
    }

    public static ScoringGroup__c createScoringGroup() {
        return createScoringGroup(TEST_SCORING_GROUP_CAPTION);
    }

    public static ScoringGroup__c createScoringGroup(String caption) {
        return createScoringGroup(new Map<Schema.SObjectField, Object> {
            ScoringGroup__c.Caption__c => caption
        });
    }

    public static ScoringGroup__c createScoringGroup(Id surveyId) {
        return createScoringGroup(surveyId, false);
    }

    public static ScoringGroup__c createScoringGroup(Id surveyId, Boolean isPpi) {
        return createScoringGroup(new Map<Schema.SObjectField, Object> {
            ScoringGroup__c.Caption__c => TEST_SCORING_GROUP_CAPTION,
            ScoringGroup__c.Survey__c => surveyId,
            ScoringGroup__c.IsPPI__c => isPpi
        });
    }
    public static ScoringGroup__c createPpiScoringGroup(Id surveyId) {
        return createScoringGroup(new Map<Schema.SObjectField, Object> {
            ScoringGroup__c.Caption__c => TEST_SCORING_GROUP_CAPTION,
            ScoringGroup__c.Survey__c => surveyId,
            ScoringGroup__c.IsPPI__c => true
        });
    }

    public static ScoringGroup__c createScoringGroup(Map<Schema.SObjectField, Object> fieldMap) {
        GenericObjectCreator creator = new GenericObjectCreator(ScoringGroup__c.getSObjectType());
        ScoringGroup__c scoringGroup = (ScoringGroup__c) creator.createNewRecord();
        creator.populateFields(
            scoringGroup,
            fieldMap
        );
        return scoringGroup;
    }

    public static UnitOfWork addScoringGroupToUnitOfWork(
            ScoringGroup__c scoringGroup,
            UnitOfWork unitOfWork
    ) {
        Integer level = unitOfWork.addToInsertionOrder(ScoringGroup__c.getSObjectType());
        unitOfWork.addToInsertList(scoringGroup, level);
        return unitOfWork;
    }

    /**
     * Test method to verify save functionality for scoring groups
     */
    static testMethod void testSaveGroups() {
        TestSurveyData testSurvey = TestSurveyData.addScoringGroupToStandardSurvey(
            TestSurveyData.createStandardTestSurvey(null, false, false), false
        );

        List<ScoringGroupDomain.ScoringGroup> listGroups =
            new List<ScoringGroupDomain.ScoringGroup>();
        SurveyScoringService.loadScoringGroups(testSurvey.testSurvey, listGroups);
        ScoringGroupDomain scoringGroupDomain = new ScoringGroupDomain();

        Test.startTest();
        List<ScoringGroup__c> actualScoringGroups = scoringGroupDomain.saveGroups(
            listGroups,
            testSurvey.testSurvey,
            testSurvey.testSurveyVersion.Id
        );
        Test.stopTest();

        System.assert(
            actualScoringGroups.size() > 0,
            'Scoring Groups should get inserted properly'
        );
    }
}