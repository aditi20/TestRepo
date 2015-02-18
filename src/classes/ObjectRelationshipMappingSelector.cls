/**
 * Selector class for the ObjectRelationshipMapping__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class ObjectRelationshipMappingSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return ObjectRelationshipMapping__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            ObjectRelationshipMapping__c.Id,
            ObjectRelationshipMapping__c.Name,
            ObjectRelationshipMapping__c.ChildSurveyMapping__c,
            ObjectRelationshipMapping__c.FieldApiName__c,
            ObjectRelationshipMapping__c.ParentSurveyMapping__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    public List<ObjectRelationshipMapping__c> getAllForSurvey(Id surveyId) {
        this.mainQueryBuilder.setSelectClauseWithAllFields();
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                new List<Schema.SObjectField>{
                    ObjectRelationshipMapping__c.ParentSurveyMapping__c,
                    SurveyMapping__c.Survey__c
                },
                SObjectSelector.EQUALS_OPERATOR,
                surveyId
            )
        );
        return (List<ObjectRelationshipMapping__c>)
            runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }
}