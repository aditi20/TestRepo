/**
 * Selector class for the ScoringGroup__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Kaushik Ray
 * @author Ketaki Virkar
 */
public with sharing class ScoringGroupSelector extends SObjectSelector {
    public Schema.SObjectType getSObjectType() {
        return ScoringGroup__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            ScoringGroup__c.Id,
            ScoringGroup__c.Name,
            ScoringGroup__c.Caption__c,
            ScoringGroup__c.IsPPI__c,
            ScoringGroup__c.RemoteId__c,
            ScoringGroup__c.Survey__c,
            ScoringGroup__c.SurveyLibrary__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get all Scoring Groups for specified survey Id, isPpi and order by Created Date
     */
    public List<ScoringGroup__c> getAllForSurveyPpiOrderByCreatedDate(Id surveyId, Boolean isPpi) {
        this.addToMainOrderByClause(ScoringGroup__c.CreatedDate.getDescribe().getName());
        return this.getAllForSurveyPpi(surveyId, isPpi);
    }

    public List<ScoringGroup__c> getAllForSurveyPpi(Id surveyId, Boolean isPpi) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                ScoringGroup__c.IsPPI__c,
                SObjectSelector.EQUALS_OPERATOR,
                isPpi
            )
        );
        return getAllForSurvey(surveyId);
    }

    public List<ScoringGroup__c> getAllForSurvey(Id surveyId) {
        this.createSurveyWhereClause(surveyId);
        return
            (List<ScoringGroup__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Method to add survey Id to where clause
     */
    private void createSurveyWhereClause(Id surveyId) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                ScoringGroup__c.Survey__c,
                SObjectSelector.EQUALS_OPERATOR,
                surveyId
            )
        );
    }
}