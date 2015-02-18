/**
 * Selector class for the PPITableDataSet__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class PpiTableDataSetSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return PPITableDataSet__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField> {
            PPITableDataSet__c.Id,
            PPITableDataSet__c.Name,
            PPITableDataSet__c.PPITable__c,
            PPITableDataSet__c.Survey__c,
            PPITableDataSet__c.SurveyVersion__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get the list of PPI table data set records for specified survey version Ids
     */
    public List<PPITableDataSet__c> getForSurveyVersion(Set<Id> surveyVersionIds) {
        this.createSurveyVersionWhereClause(surveyVersionIds);
        return
            (List<PPITableDataSet__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all the data sets for a list of surveys
     */
    public List<PPITableDataSet__c> getAllForSurveys(List<Id> surveyIds) {
        this.createSurveyIdsWhereClause(surveyIds);
        return
            (List<PPITableDataSet__c>)
                runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the list of PpiTableDataSet records for given survey version Id
     */
    public List<PPITableDataSet__c> getAllForSurveyVersion(Id surveyVersionId) {
        this.createSurveyVersionWhereClause(surveyVersionId);
        return
            (List<PPITableDataSet__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the list of PpiTableDataSet records for given survey version Id and PpiTable Poverty Lines
     */
    public List<PPITableDataSet__c> getForSurveyVersionAndPovertyLineNames(
            Id surveyVersionId,
            Set<String> ppiTablePovertyLineNames
    ) {
        this.getMainQueryBuilder().addRelationshipToSelect(
            new List<List<Schema.SObjectField>> {
               new List<Schema.SObjectField> {
                    PPITableDataSet__c.PPITable__c,
                    PPITable__c.Name
                },
                new List<Schema.SObjectField> {
                    PPITableDataSet__c.PPITable__c,
                    PPITable__c.PovertyLine__c
                }
            }
        );
        this.createSurveyVersionWhereClause(surveyVersionId);
        this.createInWhereClauseForPpiTablePovertyLineNames(ppiTablePovertyLineNames);
        return
            (List<PPITableDataSet__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the list of PpiTableDataSet records for PpiTable names
     */
    public List<PPITableDataSet__c> getForPpiTableNames(Set<String> ppiTableNames) {
        this.createInWhereClauseForPpiTableNames(ppiTableNames);
        return
            (List<PPITableDataSet__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the list of PpiTableDataSet records for the specified ppi table name
     */
    public List<PPITableDataSet__c> getLikePpiTableNames(String ppiTableName) {
        this.getMainQueryBuilder().addRelationshipToSelect(
            new List<List<Schema.SObjectField>> {
                new List<Schema.SObjectField> {
                    PPITableDataSet__c.PPITable__c,
                    PPITable__c.Name
                },
                new List<Schema.SObjectField> {
                    PPITableDataSet__c.PPITable__c,
                    PPITable__c.PovertyRate__c
                },
                new List<Schema.SObjectField> {
                    PPITableDataSet__c.PPITable__c,
                    PPITable__c.Identifier__c
                }
            }
        );
        this.createLikePpiTableNameWhereClause(ppiTableName);
        this.addToMainOrderByClause(
            this.getMainQueryBuilder().generateLookUp(
                new List<Schema.SObjectField> {
                    PPITableDataSet__c.PPITable__c,
                    PPITable__c.Name
                }
            ) +
            SObjectSelector.ASCENDING_OPERATOR
        );

        return
            (List<PPITableDataSet__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Create SurveyVersion where clause for main query of PPITableDataSet object
     */
    private void createSurveyVersionWhereClause(Set<Id> surveyVersionIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PPITableDataSet__c.SurveyVersion__c,
                SObjectSelector.IN_OPERATOR,
                surveyVersionIds
            )
        );
    }

    private void createSurveyIdsWhereClause(List<Id> surveyIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PPITableDataSet__c.Survey__c,
                SObjectSelector.IN_OPERATOR,
                surveyIds
            )
        );
    }

    /**
     * Create where clause for main query of PpiTableDataSet object
     */
    private void createSurveyVersionWhereClause(Id surveyVersionId) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                PPITableDataSet__c.SurveyVersion__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                surveyVersionId
            )
        );
    }

    /**
     * Create where clause with PpiTable Poverty Lines for main query of PpiTableDataSet object
     */
    private void createInWhereClauseForPpiTablePovertyLineNames(
            Set<String> ppiTablePovertyLineNames
    ) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        PPITableDataSet__c.PPITable__c,
                        PPITable__c.PovertyLine__c
                    }
                ),
                SObjectSelector.IN_OPERATOR,
                ppiTablePovertyLineNames
            )
        );
    }

    /**
     * Create where clause with PpiTable Names for main query of PpiTableDataSet object
     */
    private void createInWhereClauseForPpiTableNames(Set<String> ppiTableNames) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        PPITableDataSet__c.PPITable__c,
                        PPITable__c.Name
                    }
                ),
                SObjectSelector.IN_OPERATOR,
                ppiTableNames
            )
        );
    }

    /**
     * Create where clause with Name Like Ppitable Name for main query of PpiTableDataSet object
     */
    private void createLikePpiTableNameWhereClause(String tableName) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateWrappedLikeClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        PPITableDataSet__c.PPITable__c,
                        PPITable__c.Name
                    }
                ),
                tableName
            )
        );
    }
}
