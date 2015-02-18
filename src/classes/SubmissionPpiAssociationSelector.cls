/**
 * Selector class for the SubmissionPpiAssociation object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class SubmissionPpiAssociationSelector  extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return SubmissionPpiAssociation__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            SubmissionPpiAssociation__c.Id,
            SubmissionPpiAssociation__c.PpiTableLine__c,
            SubmissionPpiAssociation__c.PpiResult__c,
            SubmissionPpiAssociation__c.Submission__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get all Submission ppi associations for submission ids
     */
    public List<SubmissionPpiAssociation__c> getForSubmissionIds(Set<Id> submissionIds) {
        this.createInWhereClauseForSubmissions(submissionIds);
        this.getMainQueryBuilder().addRelationshipToSelect(
            new List<Schema.Sobjectfield> {
                SubmissionPpiAssociation__c.PpiTableLine__c,
                PpiTableLine__c.Probability__c
            }
        );
        return
            (List<SubmissionPpiAssociation__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get the list of SubmissionPpiAssociation records for specified Ppi result Ids
     */
    public List<SubmissionPpiAssociation__c> getForPpiResult(Set<String> ppiResultIds) {
        this.createPpiResultWhereClause(ppiResultIds);
        return
            (List<SubmissionPpiAssociation__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Create submissions IN clause
     */
    private void createInWhereClauseForSubmissions(Set<Id> submissionIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                SubmissionPpiAssociation__c.Submission__c,
                SObjectSelector.IN_OPERATOR,
                submissionIds
            )
        );
    }

    /**
     * Create PpiResult where clause for main query of SubmissionPpiAssociation object
     */
    private void createPpiResultWhereClause(Set<String> ppiResultIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                SubmissionPpiAssociation__c.PpiResult__c,
                SObjectSelector.IN_OPERATOR,
                ppiResultIds
            )
        );
    }
}