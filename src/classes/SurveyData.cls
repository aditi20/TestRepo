/**
 * Class to represent the data model for an entire survey.
 * This allows for easy JSON serialising for remote distribution.
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class SurveyData {

    public Survey__c survey { get; set; }
    public List<Question__c> questions { get; set; }
    public List<Option__c> options { get; set; }
    public List<ScoringGroup__c> scoreGroups { get; set; }
    public List<ScoreValue__c> scoreValues { get; set; }
    public List<SkipCondition__c> skipConditions { get; set; }
    public List<PPITableDataSet__c> tableDataSets { get; set; }
    public List<PPITableLine__c> allLines { get; set; }
    public List<PPITable__c> tables { get; set; }

    public Survey__c newSurvey { get; set; }

    public SurveyData(Id surveyId) {
        this.survey = (Survey__c) new SurveySelector().getRecordById(surveyId);

        this.questions = new QuestionSelector().getAllForSurveyIds(
            new Set<String>{surveyId}
        );
        this.options = new OptionSelector().getAllForSurvey(surveyId);
        this.scoreGroups = new ScoringGroupSelector().getAllForSurvey(surveyId);

        this.scoreValues = new ScoreValueSelector().getAllForSurvey(surveyId);
        this.skipConditions = new SkipConditionSelector().getAllForSurvey(surveyId);

        if (survey.IsPPI__c) {
            this.tables =
                new PpiTableSelector().getPpiTablesForSurveys(new List<Id>{surveyId});
            this.allLines =
                new PpiTableLineSelector().getForPpiTables(this.tables);
        }
    }
}