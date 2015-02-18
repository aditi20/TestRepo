/**
 * Selector class for the AssignedTarget object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class AssignedTargetSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return AssignedTarget__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            AssignedTarget__c.Id,
            AssignedTarget__c.TargetValue__c,
            AssignedTarget__c.EndDate__c,
            AssignedTarget__c.Contact__c,
            AssignedTarget__c.LastModifiedDate,
            AssignedTarget__c.ActualValue__c,
            AssignedTarget__c.Status__c,
            AssignedTarget__c.Name,
            AssignedTarget__c.PerformanceTarget__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Method to get all Assignedtarget records for partner users based on specified
     * performance target Id and end date
     */
    public List<AssignedTarget__c> getForPartnerUsers(
            Id performanceTargetId,
            Date endDate,
            Set<Id> partnerUsersSet
    ) {
        this.createPerformanceTargetWhereClause(performanceTargetId);
        this.createEndDateWhereClause(endDate);
        this.createInWhereClauseForContact(partnerUsersSet);
        return
            (List<AssignedTarget__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Method to add PerformanceTarget Id to where clause
     */
    private void createPerformanceTargetWhereClause(Id performanceTargetId) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                AssignedTarget__c.PerformanceTarget__c,
                SObjectSelector.EQUALS_OPERATOR,
                performanceTargetId
            )
        );
    }

    /**
     * Method to add EndDate to where clause
     */
    private void createEndDateWhereClause(Date endDate) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                AssignedTarget__c.EndDate__c,
                SObjectSelector.EQUALS_OPERATOR,
                endDate
            )
        );
    }

    /**
     * Method to add Contact to where clause
     */
    private void createInWhereClauseForContact(Set<Id> partnerUsersSet) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                AssignedTarget__c.Contact__c,
                SObjectSelector.IN_OPERATOR,
                partnerUsersSet
            )
        );
    }
}