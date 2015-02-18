/**
 * Test class for the ScoreValue__c object domain class
 * Deals with:
 *     - Creation of score values
 *     - Adding a created score value to a UnitOfWork
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Kaushik Ray
 */
@isTest
public class ScoreValueDomainTest {

    /**
     * Create a score value with a given score
     */
    public static ScoreValue__c createScoreValue(Integer score) {
        return createScoreValues(
            new Map<Schema.SObjectField, Object>{
                ScoreValue__c.Value__c => score
            }
        );
    }

    /**
     * Create a score value
     */
    public static ScoreValue__c createScoreValues(Map<Schema.SObjectField, Object> fieldMap) {
        GenericObjectCreator creator = new GenericObjectCreator(ScoreValue__c.getSObjectType());
        ScoreValue__c scoreValue = (ScoreValue__c) creator.createNewRecord();
        creator.populateFields(
            scoreValue,
            fieldMap
        );
        return scoreValue;
    }

    /**
     * Create multiple score values
     */
    public static List<ScoreValue__c> createMultipleScoreValues(Integer amountNeeded) {
        List<ScoreValue__c> scoreValues = new List<ScoreValue__c>();
        for (Integer i = 1; i <= amountNeeded; i++) {
            scoreValues.add(createScoreValues(new Map<Schema.SObjectField, Object>{
                ScoreValue__c.Value__c => i
            }));
        }
        return scoreValues;
    }

    /**
     * Adds the passed in ScoreValue__c to a unit of work.
     * Assumes that the option list is in the same order as the scoreValues
     */
    public static UnitOfWork addScoreValuesToUnitOfWork(
            ScoringGroup__c scoringGroup,
            List<ScoreValue__c> scoreValues,
            List<Option__c> options,
            UnitOfWork unitOfWork,
            Integer level
    ) {
        unitOfWork.addToInsertionOrder(ScoreValue__c.getSObjectType(), level);
        for (Integer i = 0; i < scoreValues.size(); i++) {
            unitOfWork.addToInsertList(
                scoreValues[i],
                ScoreValue__c.ScoringGroup__c,
                scoringGroup,
                level
            );
            unitOfWork.createRelationship(
                scoreValues[i],
                ScoreValue__c.Option__c,
                options[i],
                level
            );
        }
        return unitOfWork;
    }

    /**
     * Method to test score values are saved properly
     */
    static testMethod void testSaveScoringValues() {
        TestSurveyData testSurvey = TestSurveyData.addScoringGroupToStandardSurvey(
            TestSurveyData.createStandardTestSurvey(
                SurveyDOTest.createInsertedPpiTemplate(),
                false,
                false
            ),
            false
        );

        List<ScoringGroupDomain.ScoringGroup> listGroups =
            SurveyScoringService.loadScoringGroups(
                testSurvey.testSurvey,
                new List<ScoringGroupDomain.ScoringGroup>()
            );
        List<ScoringGroup__c> actualScoringGroups =
            new ScoringGroupDomain().saveGroups(
                listGroups,
                testSurvey.testSurvey,
                testSurvey.testSurveyVersion.Id
            );
        Map<String, Id> mapNameId = SurveyScoringService.getMapNameIdGroups(actualScoringGroups);
        String scoringGroupStr = '[{"caption":"PPI"}]';
        String scoringValuesJson  =
            '[{"optionId":"' +
                testSurvey.getOption(0, 2, 0).Id +
                '","groupName":"PPI","value":"-1"}]';
        JSONParser parserValue = JSON.createParser(scoringValuesJson);
        List<ScoreValueDomain.ScoringValue> scoringValues =
            SurveyScoringService.parserScoringValues(parserValue);

        Test.startTest();
        new ScoreValueDomain().saveScoringValues(scoringValues, mapNameId);
        Test.stopTest();

        // Should have the 5 original scores created in the test set up plus the extra one
        // created for the new pPI group
        System.assertEquals(
            6,
            new ScoreValueSelector().getForQuestionIds(
                new Set<Id> {testSurvey.getQuestion(0, 2).Id}
            ).size(),
            'Score Value records should get populated properly'
        );
    }
}