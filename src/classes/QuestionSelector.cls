/**
 * Selector class for the Question__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class QuestionSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return Question__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField> {
            Question__c.Id,
            Question__c.Name,
            Question__c.Caption__c,
            Question__c.CascadingLevel__c,
            Question__c.CascadingSelect__c,
            Question__c.ControllingQuestion__c,
            Question__c.CurrentTime__c,
            Question__c.DoAfter__c,
            Question__c.DoBefore__c,
            Question__c.FromVersion__c,
            Question__c.Hint__c,
            Question__c.IsDraft__c,
            Question__c.IsRemoteEditable__c,
            Question__c.MaxInstance__c,
            Question__c.Maximum__c,
            Question__c.Minimum__c,
            Question__c.Parent__c,
            Question__c.Position__c,
            Question__c.RemoteId__c,
            Question__c.PpiResultsField__c,
            Question__c.PreviousVersionQuestion__c,
            Question__c.RemoteServerId__c,
            Question__c.RepeatSourceValue__c,
            Question__c.RepeatTimes__c,
            Question__c.Required__c,
            Question__c.SamePage__c,
            Question__c.SkipLogicBehavior__c,
            Question__c.SkipLogicOperator__c,
            Question__c.Survey__c,
            Question__c.ToVersion__c,
            Question__c.Type__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Return the default order by clause
     */
    public override String getDefaultOrderByClause() {
        StringBuilder.FieldListBuilder fieldListBuilder = new StringBuilder.FieldListBuilder(
            new List<Schema.SObjectField> {
                Question__c.Parent__c,
                Question__c.Position__c
            }
        );
        fieldListBuilder.processFieldList();
        return fieldListBuilder.generateString() + ' ' + SObjectSelector.ASCENDING_OPERATOR;
    }

    /**
     * Get all the questions for a given survey
     * TODO: Convert to use SurveyVersion__c when VERSIONING is done
     */
    public List<Question__c> getAllForSurveyIds(Set<String> surveyIds) {
        this.createSurveyWhereClause(surveyIds);
        return
            (List<Question__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all Questions related to specified SurveyIds
     */
    public List<Question__c> getAllForSurveyIds(Set<String> surveyIds, Integer isDraftSurvey) {
        this.createIsDraftWhereClause(isDraftSurvey);
        this.mainQueryBuilder.addRelationshipToSelect(
            new List<Schema.SObjectField> {
                Question__c.Survey__c,
                Survey__c.Status__c
            }
        );
        this.addToMainOrderByClause(
            this.mainQueryBuilder.generateOrderByClause(
                createOrderByClause()
            )
        );
        return getAllForSurveyIds(surveyIds);
    }

    /**
     * Create list of Order by clauses
     */
    private List<SObjectSelector.OrderByBuilder> createOrderByClause() {
        return new List<SObjectSelector.OrderByBuilder> {
            new SObjectSelector.OrderByBuilder(
                Question__c.Position__c,
                SObjectSelector.ASCENDING_OPERATOR
            ),
            new SObjectSelector.OrderByBuilder(
                Question__c.Parent__c,
                SObjectSelector.ASCENDING_OPERATOR
            ),
            new SObjectSelector.OrderByBuilder(
                Question__c.Survey__c,
                SObjectSelector.ASCENDING_OPERATOR
            )
        };
    }

    /**
     * Method to add survey Ids to where clause
     */
    private void createSurveyWhereClause(Set<String> surveyIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                Question__c.Survey__c.getDescribe().getName(),
                SObjectSelector.IN_OPERATOR,
                surveyIds
            )
        );
    }

    /**
     * Method to add isDraft to where clause
     */
    private void createIsDraftWhereClause(Integer isDraftSurvey) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Question__c.IsDraft__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                isDraftSurvey
            )
        );
    }

    /**
     * Get all Questions related to a Survey and is PPI and Template
     */
    public List<Question__c> getAllForPpiSurveyId(Id surveyId) {
        this.createSurveyWhereClause(surveyId);
        this.createIsPPIWhereClause(true);
        this.createIsTemplateWhereClause(true);
        this.createIsDraftWhereClause(1);
        this.createNotCascadingSelectWhereClause(QuestionDO.TYPE_CASCADING_LEVEL);
        this.createRemoteIdNullWhereClause();
        this.addToMainOrderByClause(
            this.mainQueryBuilder.generateOrderByClause(
                generateOrderByClause()
            )
        );
        return
            (List<Question__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get Question records with option records inner query
     * TODO: Convert to use SurveyVersion__c when VERSIONING is done
     */
    public List<Question__c> getWithOptions(Id surveyId, Integer offset) {
        this.mainQueryBuilder.setSelectClauseWithAllFields();
        this.mainQueryBuilder.addRelationshipToSelect(
            new List<List<Schema.SObjectField>> {
                new List<Schema.SObjectField> {
                    Question__c.RepeatSourceValue__c,
                    Question__c.Name
                },
                new List<Schema.SObjectField> {
                    Question__c.CascadingSelect__c,
                    CascadingSelect__c.Name
                }
            }
        );
        this.createSurveyWhereClause(surveyId);
        this.createIsDraftWhereClause(1);
        this.setOffsetAmount(offset);
        this.addToMainOrderByClause(
            this.mainQueryBuilder.generateOrderByClause(
                generateOrderByClause()
            )
        );
        this.addOptionsInnerQuery();
        return (List<Question__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Create list of Order by clauses
     */
    private List<SObjectSelector.OrderByBuilder> generateOrderByClause() {
        return new List<SObjectSelector.OrderByBuilder> {
            new SObjectSelector.OrderByBuilder(
                Question__c.Survey__c,
                SObjectSelector.ASCENDING_OPERATOR
            ),
            new SObjectSelector.OrderByBuilder(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField>{
                        Question__c.Parent__c,
                        Question__c.Position__c
                    }
                ),
                SObjectSelector.ASCENDING_OPERATOR
            ),
            new SObjectSelector.OrderByBuilder(
                Question__c.Position__c,
                SObjectSelector.ASCENDING_OPERATOR
            )
        };
    }

    /**
     * Method to add inner query for Option records
     */
    private void addOptionsInnerQuery() {
        this.addInnerSelectQuery(
            new SobjectSelector.SoqlQueryBuilder(
                'Options__r',
                Option__c.sObjectType.getDescribe().getName(),
                new OptionSelector().getDefaultSelectFields(),
                Option__c.Position__c.getDescribe().getName()
            )
        );
    }

    /**
     * Method to add Survey Remote Id where clause
     */
    private void createRemoteIdNullWhereClause() {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField>{
                        Question__c.Survey__c,
                        Survey__c.RemoteId__c
                    }
                ),
                SObjectSelector.EQUALS_OPERATOR,
                SObjectSelector.NULL_VALUE
            )
        );
    }

    /**
     * Method to add Cascading Select type to where clause
     */
    private void createNotCascadingSelectWhereClause(String cascadingSelect) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Question__c.Type__c.getDescribe().getName(),
                SObjectSelector.NOT_EQUALS_OPERATOR,
                cascadingSelect
            )
        );
    }

    /**
     * Method to add survey Id to where clause
     */
    private void createSurveyWhereClause(Id surveyId) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Question__c.Survey__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                surveyId
            )
        );
    }

    /**
     * Method to add Survey__r.isPPI__c value to where clause
     */
    private void createIsPPIWhereClause(Boolean isPPI) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        Question__c.Survey__c,
                        Survey__c.IsPPI__c
                    }
                ),
                SObjectSelector.EQUALS_OPERATOR,
                isPPI
            )
        );
    }

    /**
     * Method to add Survey__r.IsTemplate__c value to where clause
     */
    private void createIsTemplateWhereClause(Boolean isTemplate) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        Question__c.Survey__c,
                        Survey__c.IsTemplate__c
                    }
                ),
                SObjectSelector.EQUALS_OPERATOR,
                isTemplate
            )
        );
    }

    /**
     * Method to add isDraft value to where clause
     */
    private void createIsDraftWhereClause(Double isDraft) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Question__c.IsDraft__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                isDraft
            )
        );
    }
}