/**
 * Selector class for the Survey__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 * @author - Kaushik Ray
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author - Ketaki Virkar
 */
public with sharing class SurveySelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return Survey__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            Survey__c.Id,
            Survey__c.Name,
            Survey__c.Alias__c,
            Survey__c.CreatedDate,
            Survey__c.Close_Message__c,
            Survey__c.CountryCode__c,
            Survey__c.Description__c,
            Survey__c.Deployment__c,
            Survey__c.IsPPI__c,
            Survey__c.IsTemplate__c,
            Survey__c.LanguageCode__c,
            Survey__c.LastModifiedDate,
            Survey__c.PPIDataYear__c,
            Survey__c.PpiIdentifier__c,
            Survey__c.PublishedDate__c,
            Survey__c.isCloned__c,
            Survey__c.RemoteId__c,
            Survey__c.Status__c,
            Survey__c.Version__c,
            Survey__c.SurveyLibrary__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    public List<Survey__c> getByName(String nameToFetch, String operator) {
        this.addToMainWhereClause(createByNameClause(nameToFetch, operator));
        return (List<Survey__c>)
            runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    public List<Survey__c> getByAlias(String aliasToFetch, String operator) {

        this.getMainQueryBuilder().setSelectClause(
            new List<Schema.SObjectField> {Survey__c.Alias__c}
        );
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Survey__c.Alias__c,
                operator,
                aliasToFetch
            )
        );
        return (List<Survey__c>)
            runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    public List<Survey__c> getNameNotForId(String nameToFetch, Id surveyId) {
        this.addToMainWhereClause(createByNameClause(nameToFetch, SObjectSelector.EQUALS_OPERATOR));
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Survey__c.Id,
                SObjectSelector.NOT_EQUALS_OPERATOR,
                surveyId
            )
        );
        return (List<Survey__c>) runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all Non template Surveys By Alias
     */
    public List<Survey__c> getAllByAlias(Set<String> aliases, Boolean isTemplate) {
        this.createAliasWhereClause(aliases);
        this.createIsTemplateWhereClause(isTemplate);
        return
            (List<Survey__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Parent to child query to get the Survey record with Survey Version
     * for given survey Ids
     */
    public List<Survey__c> getWithSurveyVersion(Set<String> surveyIds) {
        this.createSurveyWhereClause(surveyIds);
        buildInnerQueryWithSurveyVersion();
        return
            (List<Survey__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Parent to child query to get the Survey record with Survey Version and Questions
     * for a given survey Id
     */
    public Survey__c getWithSurveyVersionAndQuestions(Id surveyId) {
        this.buildInnerQueryWithSurveyVersion();
        this.buildInnerQueryWithQuestion();
        return (Survey__c) getRecordById(surveyId);
    }

    /**
     * Get specific Survey Instance with Survey Version based on Survey Id
     */
    public Survey__c getSpecificWithSurveyVersion(Id surveyId) {
        this.mainQueryBuilder.setSelectClauseWithAllFields();
        this.buildInnerQueryWithSurveyVersion();
        return (Survey__c) getRecordById(surveyId);
    }

    /**
     * Get All Surveys
     */
    public List<Survey__c> getAllSurveys() {
        this.setMainLimitAmount(Limits.getLimitQueryRows());
        return (List<Survey__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get Draft Surveys
     */
    public List<Survey__c> getDraftSurveys() {
        this.createStatusWhereClause(SurveyDO.STATUS_DRAFT);
        this.setMainLimitAmount(Limits.getLimitQueryRows());
        return (List<Survey__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all Ppi Templates with all related SurveyVersion.
     */
    public List<Survey__c> getPpiTemplatesWithSurveyVersion() {
        this.buildInnerQueryWithSurveyVersion();
        return getPpiTemplatesWithDbFullAccess();
    }

    /**
     * Get all Ppi Templates
     */
    public List<Survey__c> getPpiTemplatesWithDbFullAccess() {
        this.createIsPpiWhereClause(true);
        this.createIsTemplateWhereClause(true);
        return (List<Survey__c>) runSoqlQueryDbFullAccess(SobjectSelector.AND_OPERATOR, null);
    }

    /**
     * Parent to child query to get the Survey record with Survey Mappings
     * for a given survey Ids
     */
    public List<Survey__c> getWithSurveyMappings(Set<Id> surveyIds) {
        this.buildInnerQueryWithSurveyMapping();
        return
            (List<Survey__c>)
                runSoqlQuery(SObjectSelector.AND_OPERATOR, surveyIds);
    }

    /**
     * Method to add Alias value to where clause
     */
    private void createAliasWhereClause(Set<String> aliases) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                Survey__c.Alias__c,
                SObjectSelector.IN_OPERATOR,
                aliases
            )
        );
    }

    private String createByNameClause(String nameToFetch, String operator) {
        return this.getMainQueryBuilder().generateStandardWhereClause(
            Survey__c.Name,
            operator,
            nameToFetch
        );
    }

    /**
     * Method to add IsTemplate__c value to where clause
     */
    private void createIsTemplateWhereClause(Boolean isTemplate) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Survey__c.IsTemplate__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                isTemplate
            )
        );
    }

    /**
     * Method to add IsPpi__c value to where clause
     */
    private void createIsPpiWhereClause(Boolean isPpi) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Survey__c.IsPpi__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                isPpi
            )
        );
    }

    /**
     * Method to add survey Ids to where clause
     */
    private void createSurveyWhereClause(Set<String> surveyIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                Survey__c.Id,
                SObjectSelector.IN_OPERATOR,
                surveyIds
            )
        );
    }

    /**
     * Method to add survey Status to where clause
     */
    private void createStatusWhereClause(String status) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Survey__c.Status__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                status
            )
        );
    }

    /**
     * Build the inner query with SurveyVersion
     */
    private void buildInnerQueryWithSurveyVersion() {
        SObjectSelector.SoqlQueryBuilder innerQueryWithSurveyVersion =
            new SObjectSelector.SoqlQueryBuilder(
                'SurveyVersions__r',
                SurveyVersion__c.sObjectType.getDescribe().getName(),
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Id,
                    SurveyVersion__c.Name,
                    SurveyVersion__c.Status__c
                },
                SurveyVersion__c.Version__c.getDescribe().getName() +
                SObjectSelector.DESCENDING_OPERATOR
            );
        innerQueryWithSurveyVersion.setLimitAmount(1);
        this.addInnerSelectQuery(innerQueryWithSurveyVersion);
    }

    /**
     * Build the inner query with Question
     */
    private void buildInnerQueryWithQuestion() {
        SObjectSelector.SoqlQueryBuilder innerQueryWithQuestion =
            new SObjectSelector.SoqlQueryBuilder(
                'Questions__r',
                Question__c.sObjectType.getDescribe().getName(),
                new List<Schema.SObjectField> {
                    Question__c.Id,
                    Question__c.Name,
                    Question__c.RemoteServerId__c,
                    Question__c.Type__c
                },
                Question__c.Id.getDescribe().getName()
            );
        innerQueryWithQuestion.addToWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Question__c.RemoteServerId__c.getDescribe().getName(),
                SObjectSelector.NOT_EQUALS_OPERATOR,
                ''
            )
        );
        innerQueryWithQuestion.addToWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Question__c.RemoteServerId__c.getDescribe().getName(),
                SObjectSelector.NOT_EQUALS_OPERATOR,
                SObjectSelector.NULL_VALUE
            )
        );
        this.addInnerSelectQuery(innerQueryWithQuestion);
    }

    /**
     * Build the inner query with SurveyMapping
     */
    private void buildInnerQueryWithSurveyMapping() {
         this.addInnerSelectQuery(
            new SObjectSelector.SoqlQueryBuilder(
                'Survey_Mappings__r',
                SurveyMapping__c.sObjectType.getDescribe().getName(),
                new List<Schema.SObjectField> {
                    SurveyMapping__c.Id,
                    SurveyMapping__c.ObjectApiName__c
                },
                SurveyMapping__c.Id.getDescribe().getName()
            )
        );
    }
}
