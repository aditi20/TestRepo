/**
 * Selector class for Option__c
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class OptionSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return Option__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            Option__c.Id,
            Option__c.Name,
            Option__c.Caption__c,
            Option__c.Position__c,
            Option__c.PPIScore__c,
            Option__c.Question__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    public List<Option__c> getAllForSurvey(Id surveyId) {
        this.mainQueryBuilder.setSelectClauseWithAllFields();
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                new List<Schema.SObjectField>{
                    Option__c.Question__c,
                    Question__c.Survey__c
                },
                SObjectSelector.EQUALS_OPERATOR,
                surveyId
            )
        );
        return (List<Option__c>)
            runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    public List<Option__c> getAllForSurveyOrdered(Id surveyId) {
        this.addToMainOrderByClause(
            this.mainQueryBuilder.generateOrderByClause(
                new List<SObjectSelector.OrderByBuilder> {
                    new SObjectSelector.OrderByBuilder(
                        'Question__r.Position__c',
                        SObjectSelector.ASCENDING_OPERATOR
                    ),
                    new SObjectSelector.OrderByBuilder(
                        'Position__c',
                        SObjectSelector.ASCENDING_OPERATOR
                    )
                }
            )
        );
        return getAllForSurvey(surveyId);
    }
}