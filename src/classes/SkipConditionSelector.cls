/**
 * Selector class for the SkipCondition__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class SkipConditionSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return SkipCondition__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            SkipCondition__c.Id,
            SkipCondition__c.Name,
            SkipCondition__c.Condition__c,
            SkipCondition__c.Negate__c,
            SkipCondition__c.Parent__c,
            SkipCondition__c.SourceQuestion__c,
            SkipCondition__c.Value__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    public List<SkipCondition__c> getAllForSurvey(Id surveyId) {
        this.mainQueryBuilder.setSelectClauseWithAllFields();
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                new List<Schema.SObjectField>{
                    SkipCondition__c.SourceQuestion__c,
                    Question__c.Survey__c
                },
                SObjectSelector.EQUALS_OPERATOR,
                surveyId
            )
        );
        return (List<SkipCondition__c>)
            runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }
}