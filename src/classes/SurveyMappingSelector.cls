/**
 * Selector class for the SurveyMapping__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Aditi Satpute
 */
public with sharing class SurveyMappingSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return SurveyMapping__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            SurveyMapping__c.Id,
            SurveyMapping__c.Name,
            SurveyMapping__c.IsReference__c,
            SurveyMapping__c.MatchingField__c,
            SurveyMapping__c.ObjectApiName__c,
            SurveyMapping__c.PPIScoreApiField__c,
            SurveyMapping__c.Repeat__c,
            SurveyMapping__c.SubmissionApiField__c,
            SurveyMapping__c.Survey__c,
            SurveyMapping__c.SurveyorApiField__c,
            SurveyMapping__c.SurveyApiField__c,
            SurveyMapping__c.SurveyVersionApiField__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get all SurveyMapping records for specified Survey Ids
     */
    public List<SurveyMapping__c> getAllForSurveyIds(Set<String> surveyIds) {
        this.mainQueryBuilder.setSelectClauseWithAllFields();
        this.createSurveyWhereClause(surveyIds);
        return
            (List<SurveyMapping__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Method to add Survey value to where clause
     */
    private void createSurveyWhereClause(Set<String> surveyIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                SurveyMapping__c.Survey__c,
                SObjectSelector.IN_OPERATOR,
                surveyIds
            )
        );
    }
}