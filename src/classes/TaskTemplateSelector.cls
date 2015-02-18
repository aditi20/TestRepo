/**
 * Selector class for the TaskTemplate object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class TaskTemplateSelector extends SObjectSelector {
    public Schema.SObjectType getSObjectType() {
        return TaskTemplate__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField> {
            TaskTemplate__c.Id,
            TaskTemplate__c.Name,
            TaskTemplate__c.Form__c,
            TaskTemplate__c.JobTemplate__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get all TaskTemplate records for specified Survey Ids
     */
    public List<TaskTemplate__c> getAllForSurveyIds(Set<String> surveyIds) {
        this.mainQueryBuilder.addRelationshipToSelect(
            new List<Schema.SObjectField> {
                TaskTemplate__c.Form__c,
                SurveyVersion__c.Survey__c
            }
        );
        this.createSurveyWhereClause(surveyIds);
        return
            (List<TaskTemplate__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all TaskTemplate records
     */
    public List<TaskTemplate__c> getAllRecords() {
        this.setMainLimitAmount(Limits.getLimitQueryRows());
        return
            (List<TaskTemplate__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Method to add Survey Id to where clause
     */
    private void createSurveyWhereClause(Set<String> surveyIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        TaskTemplate__c.Form__c,
                        SurveyVersion__c.Survey__c
                    }
                ),
                SObjectSelector.IN_OPERATOR,
                surveyIds
            )
        );
    }
}