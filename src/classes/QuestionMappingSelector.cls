/**
 * Selector class for the QuestionMapping__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class QuestionMappingSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return QuestionMapping__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            QuestionMapping__c.Id,
            QuestionMapping__c.Name,
            QuestionMapping__c.FieldApiName__c,
            QuestionMapping__c.SurveyMapping__c,
            QuestionMapping__c.Question__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    public List<QuestionMapping__c> getAllForSurvey(Id surveyId) {
        this.mainQueryBuilder.setSelectClauseWithAllFields();
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                new List<Schema.SObjectField>{
                    QuestionMapping__c.SurveyMapping__c,
                    SurveyMapping__c.Survey__c
                },
                SObjectSelector.EQUALS_OPERATOR,
                surveyId
            )
        );
        return (List<QuestionMapping__c>)
            runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    public List<QuestionMapping__c> getAllForSurveyMappings(Set<Id> surveyMappingIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                QuestionMapping__c.SurveyMapping__c,
                SObjectSelector.IN_OPERATOR,
                surveyMappingIds
            )
        );
        return (List<QuestionMapping__c>)
            runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }
}