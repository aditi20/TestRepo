/**
 * Selector class for the ScoreValue__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Kaushik Ray
 */
public with sharing class ScoreValueSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return ScoreValue__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField> {
            ScoreValue__c.Id,
            ScoreValue__c.Name,
            ScoreValue__c.Value__c,
            ScoreValue__c.ScoringGroup__c,
            ScoreValue__c.Option__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    public List<ScoreValue__c> getAllForSurveyPpi(Id surveyId, Boolean isPpi) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                new List<Schema.SObjectField> {
                    ScoreValue__c.ScoringGroup__c,
                    ScoringGroup__c.IsPpi__c
                },
                SObjectSelector.EQUALS_OPERATOR,
                isPpi
            )
        );
        return getAllForSurvey(surveyId);
    }

    public List<ScoreValue__c> getAllForSurvey(Id surveyId) {
        this.mainQueryBuilder.setSelectClauseWithAllFields();
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                new List<Schema.SObjectField> {
                    ScoreValue__c.ScoringGroup__c,
                    ScoringGroup__c.Survey__c
                },
                SObjectSelector.EQUALS_OPERATOR,
                surveyId
            )
        );
        return (List<ScoreValue__c>)
            runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get records corresponding to specific Question Ids
     */
    public List<ScoreValue__c> getForQuestionIds(Set<Id> questionIds) {
        this.mainQueryBuilder.addRelationshipToSelect(
            new List<Schema.SObjectField> {
                ScoreValue__c.ScoringGroup__c,
                ScoringGroup__c.Caption__c
            }
        );
        this.addToMainOrderByClause(ScoreValue__c.Id.getDescribe().getName());
        this.createInWhereClauseForQuestionIds(questionIds);
        return (List<ScoreValue__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get records with relationship fields
     */
    public List<ScoreValue__c> getWithParentFields(Set<Id> scoreValueIds) {
        this.mainQueryBuilder.addRelationshipToSelect(
            new List<List<Schema.SObjectField>> {
                new List<Schema.SObjectField> {
                    ScoreValue__c.ScoringGroup__c,
                    ScoringGroup__c.SurveyVersion__c,
                    SurveyVersion__c.Survey__c
                },
                new List<Schema.SObjectField> {
                    ScoreValue__c.ScoringGroup__c,
                    ScoringGroup__c.IsPPI__c
                },
                new List<Schema.SObjectField> {
                    ScoreValue__c.ScoringGroup__c,
                    ScoringGroup__c.Caption__c
                },
                new List<Schema.SObjectField> {
                    ScoreValue__c.Option__c,
                    Option__c.PPIScore__c
                }
            }
        );
        return this.getRecordsById(scoreValueIds);
    }

    /**
     * Method to add Option__r.Question__c value to where clause
     */
    private void createInWhereClauseForQuestionIds(Set<Id> questionIds) {

        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        ScoreValue__c.Option__c,
                        Option__c.Question__c
                    }
                ),
                SObjectSelector.IN_OPERATOR,
                questionIds
            )
        );
    }
}