/**
 * Selector class for the PPITableLine__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class PpiTableLineSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return PPITableLine__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            PPITableLine__c.Id,
            PPITableLine__c.Name,
            PPITableLine__c.From__c,
            PPITableLine__c.PPITable__c,
            PPITableLine__c.PPITableDataSet__c,
            PPITableLine__c.Probability__c,
            PPITableLine__c.RemoteId__c,
            PPITableLine__c.SurveyLibrary__c,
            PPITableLine__c.To__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get the list of PpiTableLine records for the specified ppi table Ids
     */
    public List<PPITableLine__c> getForPpiTableIds(Set<Id> ppiTableIds) {
        this.createInWhereClauseForPpiTableIds(ppiTableIds);
        return
            (List<PPITableLine__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }


    /**
     * Get the table lines related to PPITable records
     */
    public List<PPITableLine__c> getForPpiTables(List<PPITable__c> ppiTables) {
        Set<String> tableIds = new Set<String>();
        for (PPITable__c table : ppiTables) {
            tableIds.add(table.Id);
        }
        return getForPpiTables(tableIds);
    }

    /**
     * Get the list of PPI table line records for the specified ppi table ids
     */
    public List<PPITableLine__c> getForPpiTables(Set<String> ppiTableIds) {
        this.createPpiTableWhereClause(ppiTableIds);
        return
            (List<PPITableLine__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the list of Ppi table line records for the specified ppi tables names
     */
    public List<PPITableLine__c> getForPpiTableNames(Set<String> ppiTableNames) {
        this.createInWhereClauseForPpiTableNames(ppiTableNames);
        return
            (List<PPITableLine__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the list of PpiTableLine records for the specified table name
     */
    public List<PPITableLine__c> getLikePpiTableNames(String ppiTableName) {
        this.createLikePpiTableNameWhereClause(ppiTableName);
        return
            (List<PPITableLine__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all Ppi Table Line records for specified old Survey ids
     */
    public List<PPITableLine__c> getAllForOldSurveyIds(Set<Id> setSurveyIds) {
        this.getMainQueryBuilder().addRelationshipToSelect(
            new List<Schema.SObjectField> {
                PPITableLine__c.PPITableDataSet__c,
                PPITableDataSet__c.PPITable__c
            }
        );
        this.createInWhereClauseForSurveyIds(setSurveyIds);
        this.setMainLimitAmount(Limits.getLimitQueryRows());
        return
            (List<PPITableLine__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Create where clause with survey ids
     */
    private void createInWhereClauseForSurveyIds(Set<Id> setSurveyIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                createSurveyLookUpUsingPpiTableDataSet(),
                SObjectSelector.IN_OPERATOR,
                setSurveyIds
            )
        );
    }

    /**
     * Create where clause with Ppi Table Ids for main query of PpiTableLine object 
     */
    private void createInWhereClauseForPpiTableIds(Set<Id> ppiTableIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PPITableLine__c.PPITable__c,
                SObjectSelector.IN_OPERATOR,
                ppiTableIds
            )
        );
    }

    /**
     * Create where clause with Ppi Table Names for main query of PpiTableLine object
     */
    private void createInWhereClauseForPpiTableNames(Set<String> ppiTableNames) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        PPITableLine__c.PPITable__c,
                        PPITable__c.Name
                    }
                ),
                SObjectSelector.IN_OPERATOR,
                ppiTableNames
            )
        );
    }

    /**
     * Create where clause with Name Like Ppitable Name for main query of PpiTableLine object
     */
    private void createLikePpiTableNameWhereClause(String tableName) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateWrappedLikeClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        PPITableLine__c.PPITable__c,
                        PPITable__c.Name
                    }
                ),
                tableName
            )
        );
    }

    /**
     * Create PpiTable where claues for main query of PPITableLine object 
     */
    private void createPpiTableWhereClause(Set<String> ppiTableIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PPITableLine__c.PPITable__c,
                SObjectSelector.IN_OPERATOR,
                ppiTableIds
            )
        );
    }

    /**
     * Create relationship lookup for Survey using Ppi Table Data Set
     */
    private String createSurveyLookUpUsingPpiTableDataSet() {
        return this.getMainQueryBuilder().generateLookUp(
            new List<Schema.SObjectField> {
                PPITableLine__c.PPITableDataSet__c,
                PPITableDataSet__c.Survey__c
            }
        );
    }
}