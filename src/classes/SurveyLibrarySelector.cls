/**
 * Selector class for the SurveyLibrary object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
public with sharing class SurveyLibrarySelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return SurveyLibrary__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            SurveyLibrary__c.Id,
            SurveyLibrary__c.Name,
            SurveyLibrary__c.URL__c,
            SurveyLibrary__c.SurveyPreviewPath__c,
            SurveyLibrary__c.RemoteLibraryPath__c,
            SurveyLibrary__c.PpiResultsEndpoint__c,
            SurveyLibrary__c.Description__c,
            SurveyLibrary__c.Active__c,
            SurveyLibrary__c.IsPPI__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /** 
     * Get all records for isSurvey with specified Active status
     *  - Check if SurveyLibrary is active
     *  - Check if isSurvey is true
     */
    public List<SurveyLibrary__c> getAllForIsSurveyWithActiveStatus(Boolean isActive) {
        this.createIsActiveWhereClause(isActive);
        this.createIsSurveyWhereClause(true);
        return (List<SurveyLibrary__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /** 
     * Get records of specified name
     */
    public List<SurveyLibrary__c> getRecordsByName(String name) {
        this.getNameWhereClause(name);
        return (List<SurveyLibrary__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /** 
     * Create Name where clause
     */
    private void getNameWhereClause(String name) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                SurveyLibrary__c.Name.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                name
            )
        );
    }

    /** 
     * Create isActive where clause
     */
    private void createIsActiveWhereClause(Boolean isActive) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                SurveyLibrary__c.Active__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                isActive
            )
        );
    }

    /** 
     * Create isSurvey where clause
     */
    private void createIsSurveyWhereClause(Boolean isSurvey) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                SurveyLibrary__c.isSurvey__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                isSurvey
            )
        );
    }
}