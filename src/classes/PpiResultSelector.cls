/**
 * Selector class for the Ppi result object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 * @author - Aditi Satpute
 */
public with sharing class PpiResultSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return PpiResult__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField> {
            PpiResult__c.Id,
            PpiResult__c.Name,
            PpiResult__c.AnswerOne__c,
            PpiResult__c.AnswerTwo__c,
            PpiResult__c.AnswerThree__c,
            PpiResult__c.AnswerFour__c,
            PpiResult__c.AnswerFive__c,
            PpiResult__c.AnswerSix__c,
            PpiResult__c.AnswerSeven__c,
            PpiResult__c.AnswerEight__c,
            PpiResult__c.AnswerNine__c,
            PpiResult__c.AnswerTen__c,
            PpiResult__c.PpiScore__c,
            PpiResult__c.ClientId__c,
            PpiResult__c.Geolocation__latitude__s,
            PpiResult__c.Geolocation__longitude__s,
            PpiResult__c.Age__c,
            PpiResult__c.CreatedDate,
            PpiResult__c.Gender__c,
            PpiResult__c.HouseholdSize__c,
            PpiResult__c.JoinedDate__c,
            PpiResult__c.RetrievedByParent__c,
            PpiResult__c.UniqueKey__c,
            PpiResult__c.PPITemplate__c,
            PpiResult__c.OrganizationName__c,
            PpiResult__c.PpiCollectionDate__c,
            PpiResult__c.CreatedDate
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Method to get all data for Survey Version Ids
     */
    public List<PpiResult__c> getAllForSurveyVersionIds(Set<Id> surveyVersionIds) {
        this.createInWhereClauseForSurveyVersionId(surveyVersionIds);
        return
            (List<PpiResult__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all the ppi results for a given client
     */
    public List<PpiResult__c> getByClientId(Id clientId) {
        this.createClientIdFilter(clientId);
        return
            (List<PpiResult__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Method to get all data with RetrievedByParent__c as false based on passed set of Ids
     */
    public List<PpiResult__c> getAllWithSyncFalse(Set<Id> ppiIdList) {
        return this.getAllWithSyncValue(ppiIdList, false);
    }

    /**
     * Method to get all data with RetrievedByParent__c as true based on passed set of Ids
     */
    public List<PpiResult__c> getAllWithSyncTrue(Set<Id> ppiIdList) {
        return this.getAllWithSyncValue(ppiIdList, true);
    }

    /**
     * Method to get all data based on RetrievedByParent__c and set of ids
     */
    @TestVisible
    private List<PpiResult__c> getAllWithSyncValue(Set<Id> ppiIdList, Boolean syncValue) {
        assignSyncQueryDetails(syncValue);
        return (List<PpiResult__c>) getRecordsById(ppiIdList);
    }

    /**
     * Create SOQL query based on RetrievedByParent__c value
     */
    public String generateSyncQuery(Boolean syncValue) {
        assignSyncQueryDetails(syncValue);
        return this.mainQueryBuilder.generateSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the list of PpiResult records for specified UniqueKeys
     */
    public List<PpiResult__c> getForUniqueKey(Set<String> setUniqueKeys) {
        this.createUniqueKeyWhereClause(setUniqueKeys);
        return
            (List<PpiResult__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Method to create parameters to be used with Sync query
     */
    private void assignSyncQueryDetails(Boolean syncValue) {
        this.mainQueryBuilder.addRelationshipToSelect(
            this.createAnswersRemoteIdRelation()
        );
        this.createRetrievedByParentWhereClause(syncValue);
    }

    /**
     * Create relationship fields to be used in query
     */
    @TestVisible
    private List<List<Schema.SObjectField>> createAnswersRemoteIdRelation() {
        return new List<List<Schema.SObjectField>> {
            new List<Schema.SObjectField> {
                PpiResult__c.AnswerOne__c,
                Option__c.RemoteId__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.AnswerTwo__c,
                Option__c.RemoteId__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.AnswerThree__c,
                Option__c.RemoteId__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.AnswerFour__c,
                Option__c.RemoteId__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.AnswerFive__c,
                Option__c.RemoteId__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.AnswerSix__c,
                Option__c.RemoteId__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.AnswerSeven__c,
                Option__c.RemoteId__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.AnswerEight__c,
                Option__c.RemoteId__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.AnswerNine__c,
                Option__c.RemoteId__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.AnswerTen__c,
                Option__c.RemoteId__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.PpiTemplate__c,
                SurveyVersion__c.Survey__c,
                Survey__c.PpiIdentifier__c
            },
            new List<Schema.SObjectField> {
                PpiResult__c.PpiTemplate__c,
                SurveyVersion__c.Survey__c,
                Survey__c.RemoteId__c
            }
        };
    }

    /**
     * Create where clause for RetrievedByParent__c field
     */
    private void createRetrievedByParentWhereClause(Boolean value) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                PpiResult__c.RetrievedByParent__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                value
            )
        );
    }

    /**
     * Create where clause for RetrievedByParent__c field
     */
    private void createClientIdFilter(String clientId) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                PpiResult__c.ClientId__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                clientId
            )
        );
    }

    /**
     * Create where clause for UniqueKey__c field
     */
    private void createUniqueKeyWhereClause(Set<String> setUniqueKeys) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PpiResult__c.UniqueKey__c,
                SObjectSelector.IN_OPERATOR,
                setUniqueKeys
            )
        );
    }

    /**
     * Create where clause for SurveyVersion__c field
     */
    private void createInWhereClauseForSurveyVersionId(Set<Id> surveyVersionIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PpiResult__c.PpiTemplate__c,
                SObjectSelector.IN_OPERATOR,
                surveyVersionIds
            )
        );
    }
}