/**
 * Selector class for the PPITable__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class PpiTableSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return PPITable__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            PPITable__c.Id,
            PPITable__c.Name,
            PPITable__c.Identifier__c,
            PPITable__c.PovertyLine__c,
            PPITable__c.PovertyRate__c,
            PPITable__c.RemoteId__c,
            PPITable__c.SurveyLibrary__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get the list of Ppi table records along with PpiTableDataSets
     */
    public List<PPITable__c> getAllWithPpiTableDataSets() {
        this.buildInnerQueryWithPpiTabledataSets();
        return
            (List<PPITable__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the Ppi table record along with PpiTableDataSets
     */
    public PPITable__c getWithPpiTableDataSets(Id ppiTableId) {
        this.buildInnerQueryWithPpiTabledataSets();
        return
            (PPITable__c) getRecordById(ppiTableId);
    }

    /**
     * Get the Ppi table records along with PpiTableDataSets
     *  - Check if records fetched with Id where clause for specified ppiTableIds
     *  - Fetch all PpiTableDataSet records as inner query for each PpiTable records
     */
    public List<PPITable__c> getForIdsWithPpiTableDataSets(Set<Id> ppiTableIds) {
        this.buildInnerQueryWithPpiTabledataSets();
        return
            (List<PPITable__c>) getRecordsById(ppiTableIds);
    }

    /**
     * Get the list of Ppi table records for the specified names
     */
    public List<PPITable__c> getForPpiTableNames(Set<String> tableNames) {
        this.createInWhereClauseForPpiTableNames(tableNames);
        return
            (List<PPITable__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the list of Ppi table records for the specified table name
     */
    public List<PPITable__c> getLikePpiTableNames(String tableName) {
        this.createLikeNameWhereClause(tableName);
        return
            (List<PPITable__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the list of Ppi table records along with PpiTableLines for the specified PpiTable Ids 
     */
    public List<PPITable__c> getWithPpiTableLines(Set<Id> ppiTableIds) {
        this.createInWhereClauseForPpiTableIds(ppiTableIds);
        this.addToMainOrderByClause(
            PPITableLine__c.Id.getDescribe().getName() +
            SObjectSelector.ASCENDING_OPERATOR
        );
        this.buildInnerQueryWithPpiTableLines();
        return
            (List<PPITable__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    public List<PPITable__c> getByTableNames(Set<String> tableNames) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PPITable__c.Name,
                SObjectSelector.IN_OPERATOR,
                tableNames
            )
        );
        this.addToMainOrderByClause(
             PPITable__c.Name.getDescribe().getName() +
             SObjectSelector.ASCENDING_OPERATOR
        );
        return
            (List<PPITable__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    public List<PPITable__c> getPpiTablesForSurveys(List<Id> surveyIds) {

        this.getMainQueryBuilder().initInnerWhereClause(
            PPITable__c.Id,
            SObjectSelector.IN_OPERATOR,
            PPITableDataSet__c.PPITable__c,
            PPITableDataSet__c.sObjectType
        );
        this.getMainQueryBuilder().getInnerWhereClause().getWhereClauseQuery().addToWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PPITableDataSet__c.Survey__c,
                SObjectSelector.IN_OPERATOR,
                surveyIds
            )
        );
        return
            (List<PPITable__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    public Map<String, PPITable__c> getNameMapFromNames(Set<String> tableNamesToFind) {
        Map<String, PPITable__c> tables = new Map<String, PPITable__c>();
        for (PPITable__c table : getByTableNames(tableNamesToFind)) {
            tables.put(table.Name, table);
        }
        return tables;
    }

    /**
     * Build the inner query with PpiTableLines
     */
    private void buildInnerQueryWithPpiTableLines() {
        this.addInnerSelectQuery(
            new SObjectSelector.SoqlQueryBuilder(
                'PPI_Table__r',
                PPITableLine__c.sObjectType.getDescribe().getName(),
                new List<Schema.SObjectField> {
                    PPITableLine__c.Id,
                    PPITableLine__c.From__c,
                    PPITableLine__c.To__c,
                    PPITableLine__c.Probability__c
                },
                PPITableLine__c.From__c.getDescribe().getName()
            )
        );
    }

    /**
     * Create where clause with Ppi Table Names for main query of PpiTable object 
     */
    private void createInWhereClauseForPpiTableNames(Set<String> tableNames) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PPITable__c.Name.getDescribe().getName(),
                SObjectSelector.IN_OPERATOR,
                tableNames
            )
        );
    }

    /**
     * Create where clause with Name Like Ppitable Name for main query of PpiTable object 
     */
    private void createLikeNameWhereClause(String tableName) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateWrappedLikeClause(
                PPITable__c.Name.getDescribe().getName(),
                tableName
            )
        );
    }

    /**
     * Create where clause with Ppi Table Id for main query of PpiTable object
     */
    private void createInWhereClauseForPpiTableIds(Set<Id> ppiTableIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PPITable__c.Id,
                SObjectSelector.IN_OPERATOR,
                ppiTableIds
            )
        );
    }

    /**
     * Build the inner query with PpiTableDataSets
     */
    private void buildInnerQueryWithPpiTabledataSets() {
        SObjectSelector.SoqlQueryBuilder innerQueryWithPpiTableDataSets =
            new SObjectSelector.SoqlQueryBuilder(
                'PPI_Table_Data_Sets__r',
                PPITableDataSet__c.sObjectType.getDescribe().getName(),
                new List<Schema.SObjectField> {
                    PPITableDataSet__c.Id
                },
                PPITableDataSet__c.Id.getDescribe().getName()
            );
        innerQueryWithPpiTableDataSets.setLimitAmount(Limits.getLimitQueryRows());
        this.addInnerSelectQuery(innerQueryWithPpiTableDataSets);
    }
}