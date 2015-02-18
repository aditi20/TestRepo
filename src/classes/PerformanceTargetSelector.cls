/**
 * Selector class for the PerformanceTarget object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class PerformanceTargetSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return PerformanceTarget__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField> {
            PerformanceTarget__c.Id,
            PerformanceTarget__c.Name,
            PerformanceTarget__c.DefaultValue__c,
            PerformanceTarget__c.EndDate__c,
            PerformanceTarget__c.JobTemplate__c,
            PerformanceTarget__c.StartDate__c,
            PerformanceTarget__c.Status__c,
            PerformanceTarget__c.CloseReason__c,
            PerformanceTarget__c.Timeframe__c,
            PerformanceTarget__c.Type__c,
            PerformanceTarget__c.OwnerId,
            PerformanceTarget__c.CreatedById,
            PerformanceTarget__c.LastModifiedById,
            PerformanceTarget__c.LastModifiedDate,
            PerformanceTarget__c.CreatedDate,
            PerformanceTarget__c.AggregationOperation__c,
            PerformanceTarget__c.TrackedSObjectApiName__c,
            PerformanceTarget__c.TrackedFieldApiName__c,
            PerformanceTarget__c.TrackedSObjectContactLookupFieldName__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get AggregateResults of all the TrackedObjectApiNames based on performance type and status
     */
    public List<AggregateResult> getAllTrackedObjectApiNames(
            String performanceType,
            String performanceStatus
    ) {
        this.mainQueryBuilder.setSelectClause(
            new List<String> {
                'COUNT(Id)',
                'TrackedSObjectApiName__c'
            }
        );
        this.addToMainOrderByClause('');
        this.createTypeWhereClause(performanceType);
        this.createStatusWhereClause(performanceStatus);
        this.addToMainGroupByClause('TrackedSObjectApiName__c');
        return
            (List<AggregateResult>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all the performanceTargets for Type
     */
    public List<PerformanceTarget__c> getAllForType(
            String performanceType,
            String tableOrderColumn,
            String sortOrder
    ) {
        this.mainQueryBuilder.addRelationshipToSelect(
            new List<Schema.SObjectField> {
                PerformanceTarget__c.JobTemplate__c,
                JobTemplate__c.Name
            }
        );
        this.createTypeWhereClause(performanceType);
        this.addToMainOrderByClause(tableOrderColumn + ' ' + sortOrder);
        return
            (List<PerformanceTarget__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all the performanceTargets for JobTemplates based on specified status
     */
    public List<PerformanceTarget__c> getAllForJobTemplates(
            Set<Id> jobTemplates,
            List<String> requiredStatus
    ) {
        this.createInWhereClauseForJobTemplate(jobTemplates);
        this.createInWhereClauseForStatus(requiredStatus);
        return
            (List<PerformanceTarget__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all the performanceTargets for a given Status
     */
    public List<PerformanceTarget__c> getAllForStatus(String performanceTargetStatus) {
        this.createStatusWhereClause(performanceTargetStatus);
        return
            (List<PerformanceTarget__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all the performanceTargets along with SObjectFilterCondition records
     * for given objectApiName, performance Type and Status
     */
    public List<PerformanceTarget__c> getAllWithSObjectFilterCondition(
            String objectApiName,
            String performanceType,
            String performanceStatus
    ) {
        this.addInnerSelectQuery(buildInnerQueryWithSObjectFilterCondition());
        this.createTrackedSObjectApiWhereClause(objectApiName);
        this.createTypeWhereClause(performanceType);
        this.createStatusWhereClause(performanceStatus);
        return
            (List<PerformanceTarget__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all the performanceTargets for given list of objectApiNames, performance 
     * Type and Status
     */
    public List<PerformanceTarget__c> getAllForObjectApiNames(
            List<String> objectApiNames,
            String performanceType,
            String performanceStatus
    ) {
        this.createInWhereClauseForTrackedSObjectApi(objectApiNames);
        this.createTypeWhereClause(performanceType);
        this.createStatusWhereClause(performanceStatus);
        return
            (List<PerformanceTarget__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all the performanceTargets for a given TrackedFieldApiName and AggregationOperation
     */
    public List<PerformanceTarget__c> getAllForAggregationOperation(
            String fieldApiName,
            String aggregationOperation
    ) {
        this.createTrackedFieldApiWhereClause(fieldApiName);
        this.createOperationWhereClause(aggregationOperation);
        return
            (List<PerformanceTarget__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Method with parent to child query to get the PerformanceTarget record with AssignedTarget
     * records for given PerformanceTarget Id and end date
     */
    public PerformanceTarget__c getWithAssignedTargets(Id performanceTargetId, Date endDate) {
        this.mainQueryBuilder.addRelationshipToSelect(
            new List<Schema.SObjectField> {
                PerformanceTarget__c.JobTemplate__c,
                JobTemplate__c.Name
            }
        );
        this.addInnerSelectQuery(buildInnerQueryWithAssignedTarget(endDate));
        return (PerformanceTarget__c) getRecordById(performanceTargetId);
    }

    /**
     * Build the inner query with SObjectFilterCondition
     */
    private SObjectSelector.SoqlQueryBuilder buildInnerQueryWithSObjectFilterCondition() {
        SObjectSelector.SoqlQueryBuilder innerQueryWithSObjectFilterCondition =
            new SObjectSelector.SoqlQueryBuilder(
                'SObject_Filter_Conditions__r',
                SObjectFilterCondition__c.sObjectType.getDescribe().getName(),
                new List<Schema.SObjectField> {
                    SObjectFilterCondition__c.Id,
                    SObjectFilterCondition__c.FieldAPIName__c,
                    SObjectFilterCondition__c.Operator__c,
                    SObjectFilterCondition__c.Value__c
                },
                SObjectFilterCondition__c.Id.getDescribe().getName() + ASCENDING_OPERATOR
            );
        return innerQueryWithSObjectFilterCondition;
    }

    /**
     * Build the inner query with Assigned Target
     */
    private SObjectSelector.SoqlQueryBuilder buildInnerQueryWithAssignedTarget(Date endDate) {
        SObjectSelector.SoqlQueryBuilder innerQueryWithAssignedTarget =
            new SObjectSelector.SoqlQueryBuilder(
                'Assigned_Targets__r',
                AssignedTarget__c.sObjectType.getDescribe().getName(),
                new List<Schema.SObjectField> {
                    AssignedTarget__c.Id,
                    AssignedTarget__c.Contact__c,
                    AssignedTarget__c.TargetValue__c,
                    AssignedTarget__c.EndDate__c
                },
                AssignedTarget__c.Id.getDescribe().getName() + ASCENDING_OPERATOR
            );
        innerQueryWithAssignedTarget.addToWhereClause(
            innerQueryWithAssignedTarget.generateStandardWhereClause(
                AssignedTarget__c.EndDate__c,
                SObjectSelector.EQUALS_OPERATOR,
                endDate
            )
        );
        return innerQueryWithAssignedTarget;
    }

    /**
     * Method to add JobTemplate to where clause
     */
    private void createInWhereClauseForJobTemplate(Set<Id> jobTemplates) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PerformanceTarget__c.JobTemplate__c,
                SObjectSelector.IN_OPERATOR,
                jobTemplates
            )
        );
    }

    /**
     * Method to add TrackedSObjectApiName to where clause
     */
    private void createTrackedSObjectApiWhereClause(String objectApiName) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                PerformanceTarget__c.TrackedSObjectApiName__c,
                SObjectSelector.EQUALS_OPERATOR,
                objectApiName
            )
        );
    }

    /**
     * Method to add TrackedSObjectApiName to where clause
     */
    private void createInWhereClauseForTrackedSObjectApi(List<String> objectApiNames) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PerformanceTarget__c.TrackedSObjectApiName__c,
                SObjectSelector.IN_OPERATOR,
                objectApiNames
            )
        );
    }

    /**
     * Method to add Type to where clause
     */
    private void createTypeWhereClause(String performanceTargetType) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                PerformanceTarget__c.Type__c,
                SObjectSelector.EQUALS_OPERATOR,
                performanceTargetType
            )
        );
    }

    /**
     * Method to add AggregationOperation to where clause
     */
    private void createOperationWhereClause(String aggregateOperation) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                PerformanceTarget__c.AggregationOperation__c,
                SObjectSelector.EQUALS_OPERATOR,
                aggregateOperation
            )
        );
    }

    /**
     * Method to add TrackedFieldApiName to where clause
     */
    private void createTrackedFieldApiWhereClause(String fieldApiName) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                PerformanceTarget__c.TrackedFieldApiName__c,
                SObjectSelector.EQUALS_OPERATOR,
                fieldApiName
            )
        );
    }

    /**
     * Method to add Status to where clause
     */
    private void createStatusWhereClause(String performanceTargetStatus) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                PerformanceTarget__c.Status__c,
                SObjectSelector.EQUALS_OPERATOR,
                performanceTargetStatus
            )
        );
    }

    /**
     * Method to add Status to where clause
     */
    private void createInWhereClauseForStatus(List<String> performanceTargetStatus) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                PerformanceTarget__c.Status__c,
                SObjectSelector.IN_OPERATOR,
                performanceTargetStatus
            )
        );
    }
}