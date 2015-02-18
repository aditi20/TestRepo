/*
 * Survey Scoring Service class
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author : Kaushik Ray
 */
public with sharing class SurveyScoringService {

    public static Savepoint databaseSavepoint;
    public static Boolean errorValues = false;

    /**
     * Load existing Scoring Groups
     */
    public static List<ScoringGroupDomain.ScoringGroup> loadScoringGroups(
            Survey__c survey,
            List<ScoringGroupDomain.ScoringGroup> listGroups
    ) {

        GenericObjectCreator scoringGroupCreator =
            new GenericObjectCreator(ScoringGroup__c.SObjectType);
        if (!scoringGroupCreator.isObjectAccessible(false)) {
            throw new SurveyScoringServiceException(
                String.format(
                    System.Label.ERR_INSUFFICIENT_PERMISSION,
                    new String[]{ScoringGroup__c.sObjectType.getDescribe().getLabel()}
                )
            );
        }

        // Add an additional scoring group for PPI surveys
        if (survey.IsPPI__c) {
            listGroups.add(
                new ScoringGroupDomain.ScoringGroup(
                    SurveyScoringController.PPI_ID,
                    SurveyScoringController.PPI_LABEL
                )
            );
        }

        // Load scoring groups
        ScoringGroupSelector scoringGroupSelector = new ScoringGroupSelector();
        for (ScoringGroup__c scoringGroup : scoringGroupSelector.getAllForSurvey(survey.Id)) {
            if (!scoringGroup.IsPPI__c) {
                ScoringGroupDomain.ScoringGroup newScoring =
                    new ScoringGroupDomain.ScoringGroup(scoringGroup);
                listGroups.add(newScoring);
            }
        }
        return listGroups;
    }

    /**
     * This method will be used to parse Scoring Groups and Scoring values for a Survey
     * @param : survey - Main survey instance
     * @param : scoringGroupStr - ScoringGroup Json string to be parsed
     * @param : scoringValuesJson - ScoreValue Json string to be parsed
     *
     * @return : Updated Survey instance
     */
    public static Survey__c parseSurveyScoring(
        Survey__c survey,
        String scoringGroupStr,
        String scoringValuesJson
    ) {
        PageReference returnPage = null;
        ScoringGroupDomain scoringGroupDomain = new ScoringGroupDomain();
        ScoreValueDomain scoreValueDomain = new ScoreValueDomain();
        try {
            // Create JSON parser for Scoring groups and perform database insert for same
            JSONParser parserGroups = JSON.createParser(scoringGroupStr);
            List<ScoringGroupDomain.ScoringGroup> customGroups = parserScoringGroup(parserGroups);
            List<ScoringGroup__c> savedGroups;
            savedGroups = scoringGroupDomain.saveGroups(customGroups, survey);

            // Create Scoring Group parser for Scoring groups and perform database opertations for same
            JSONParser parserValue = JSON.createParser(scoringValuesJson);
            List<ScoreValueDomain.ScoringValue> scoringValues =
                parserScoringValues(parserValue);
            map<String, Id> mapNameId = getMapNameIdGroups(savedGroups);
            scoreValueDomain.saveScoringValues(scoringValues, mapNameId);
        } catch(Exception e) {
            Database.rollback(databaseSavepoint);
            throw new SurveyScoringServiceException(System.Label.SURVEY_SCORING_ERR_SAVING);
        }

        try{
            SurveyDO surveyDomainInstance =
                new SurveyDO(); 
            surveyDomainInstance.addRecord(survey);
            surveyDomainInstance.updateRecords();

            SurveySelector selector = new SurveySelector();
            survey = selector.getSpecificWithSurveyVersion(survey.id);
        } catch(DmlException e) {
            // Do not add an apex error message because the trigger does
            Database.rollback(databaseSavepoint);
        }
        return survey;
    }

    /*
     * Given a parser of scoringGroups, returns a List<ScoringGroup> .
     */
    public static List<ScoringGroupDomain.ScoringGroup> parserScoringGroup(JSONParser parser){
        List<ScoringGroupDomain.ScoringGroup> listOfScoringGroup =
            new List<ScoringGroupDomain.ScoringGroup>();
        while (parser.nextToken() != null) {
            // Start at the array of ScoringGroup.
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    // Advance to the start object marker to
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        // Read entire ScoringGroup object
                        ScoringGroupDomain.ScoringGroup sg =
                            (ScoringGroupDomain.ScoringGroup)parser.readValueAs(
                                ScoringGroupDomain.ScoringGroup.class
                            );
                        listOfScoringGroup.add(sg);
                    }
                }
            }
        }
        return listOfScoringGroup;
    }

    /*
     * Given a parser of scoringValues, returns a List<ScoringValue>.
     */
    public static List<ScoreValueDomain.ScoringValue> parserScoringValues(JSONParser parser){
        List<ScoreValueDomain.ScoringValue> listOfScoringValues =
            new List<ScoreValueDomain.ScoringValue>();
        while (parser.nextToken() != null) {
            // Start at the array of ScoringValues.
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    // Advance to the start object marker to
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        // Read entire ScoringValue object
                        ScoreValueDomain.ScoringValue scoringValue =
                            (ScoreValueDomain.ScoringValue)parser.readValueAs(
                                ScoreValueDomain.ScoringValue.class
                            );
                        listOfScoringValues.add(scoringValue);
                    }
                }
            }
        }
        return listOfScoringValues;
    }

    /*
     * From list of ScoringGroup__c,
     * return a map with the form: <ScoringGroup__c.Value, ScoringGroup__c.Id>.
     */
    public static Map<String, Id> getMapNameIdGroups(List<ScoringGroup__c> scoringGroups) {

        Map<String, Id> mapScoringGroupCaptionId = new Map<String, Id>();
        if (scoringGroups != null && scoringGroups.size() > 0) {
            for (ScoringGroup__c scoringGroup : scoringGroups) {
                mapScoringGroupCaptionId.put(scoringGroup.Caption__c, scoringGroup.Id);
            }
        }
        return mapScoringGroupCaptionId;
    }

    public class SurveyScoringServiceException extends BaseException {
        public SurveyScoringServiceException(String message, String[] args) {
            super(message, args);
        }
    }
}