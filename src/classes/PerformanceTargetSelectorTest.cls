/**
 * Test class for the PerformanceTargetSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class PerformanceTargetSelectorTest {

    /**
     * Test method to verify fetching Performance Targets for specified type
     */
    static testmethod void testFetchingForType() {
        List<PerformanceTarget__c> performanceTargets =
            PerformanceTargetDOTest.createMultiplePerformanceIndicators(2);

        JobTemplate__c jobTemplate =
            JobTemplateDOTest.createPublishedDataCollectionRecord('job1', 'survey1');

        PerformanceTarget__c performanceTarget3 =
            PerformanceTargetDOTest.createJobTargetRecord(
                'PerformanceTarget3',
                jobTemplate.Id,
                50,
                PerformanceTargetDO.TIMEFRAME_WEEKLY,
                PerformanceTargetDO.getPreviousMonday(Date.today()),
                PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
                PerformanceTargetDO.TYPE_JOB_TARGET
            );
        performanceTargets.add(performanceTarget3);

        System.assertEquals(3, performanceTargets.size());

        PerformanceTargetDO performanceTargetDomainInstance =
            new PerformanceTargetDO.Constructor().constructWithRecords(performanceTargets);
        performanceTargetDomainInstance.insertRecords();

        Test.startTest();
        List<PerformanceTarget__c> actualPerformanceTargets =
            new PerformanceTargetSelector().getAllForType(
                PerformanceTargetDO.TYPE_INDICATOR,
                'LastModifiedDate desc, CreatedDate',
                'desc'
            );
        Test.stopTest();

        // Only 2 records are fetched as third performance target has type as Job_Target
        System.assertEquals(2, actualPerformanceTargets.size());
    }

    /**
     * Test method to verify fetching Performance Targets for specified jobTemplate
     */
    static testmethod void testFetchingForJobTemplate() {
        JobTemplate__c jobTemplate1 =
            JobTemplateDOTest.createPublishedDataCollectionRecord('job1', 'survey1');
        JobTemplate__c jobTemplate2 =
            JobTemplateDOTest.createPublishedDataCollectionRecord('job2', 'survey2');

        List<PerformanceTarget__c> performanceTargets =
            PerformanceTargetDOTest.createMultipleJobTargets(
                new List<String> {
                    jobTemplate1.Id,
                    jobTemplate2.Id
                },
                2
            );

        System.assertEquals(2, performanceTargets.size());

        performanceTargets[1].Status__c = PerformanceTargetDO.STATUS_CLOSED;
        PerformanceTargetDO performanceTargetDomainInstance =
            new PerformanceTargetDO.Constructor().constructWithRecords(performanceTargets);
        performanceTargetDomainInstance.insertRecords();

        Test.startTest();
        List<PerformanceTarget__c> actualPerformanceTargets =
            new PerformanceTargetSelector().getAllForJobTemplates(
                new Set<Id> {jobTemplate1.Id, jobTemplate2.Id},
                new List<String> {PerformanceTargetDO.STATUS_ACTIVE, PerformanceTargetDO.STATUS_CLOSED}
            );
        Test.stopTest();

        System.assertEquals(2, actualPerformanceTargets.size());
    }

    /**
     * Test method to verify fetching Performance Targets for specified status
     */
    static testmethod void testFetchingForStatus() {
        List<PerformanceTarget__c> performanceTargets =
            PerformanceTargetDOTest.createMultiplePerformanceIndicators(2);

        System.assertEquals(2, performanceTargets.size());

        PerformanceTargetDO performanceTargetDomainInstance =
            new PerformanceTargetDO.Constructor().constructWithRecords(performanceTargets);
        performanceTargetDomainInstance.insertRecords();

        performanceTargets[1].Status__c = PerformanceTargetDO.STATUS_CLOSED;
        performanceTargetDomainInstance.updateRecords();

        Test.startTest();
        List<PerformanceTarget__c> actualPerformanceTargets =
            new PerformanceTargetSelector().getAllForStatus(
                PerformanceTargetDO.STATUS_CLOSED
            );
        Test.stopTest();

        System.assertEquals(1, actualPerformanceTargets.size());
    }

    /**
     * Test method to verify fetching Performance Targets for specified object ApiNames
     */
    static testmethod void testFetchingForObjectApiNames() {
        List<PerformanceTarget__c> performanceTargets = new List<PerformanceTarget__c>();

        List<PerformanceTarget__c> performanceIndicators =
            PerformanceTargetDOTest.createMultiplePerformanceIndicators(2);

        System.assertEquals(2, performanceIndicators.size());
        performanceTargets.addAll(performanceIndicators);

        JobTemplate__c jobTemplate1 =
            JobTemplateDOTest.createPublishedDataCollectionRecord('job1', 'survey1');
        JobTemplate__c jobTemplate2 =
            JobTemplateDOTest.createPublishedDataCollectionRecord('job2', 'survey2');

        List<PerformanceTarget__c> jobTargets =
            PerformanceTargetDOTest.createMultipleJobTargets(
                new List<String> {
                    jobTemplate1.Id,
                    jobTemplate2.Id
                },
                2
            );

        System.assertEquals(2, jobTargets.size());
        performanceTargets.addAll(jobTargets);

        System.assertEquals(4, performanceTargets.size());

        PerformanceTargetDO performanceTargetDomainInstance =
            new PerformanceTargetDO.Constructor().constructWithRecords(performanceTargets);
        performanceTargetDomainInstance.insertRecords();

        Test.startTest();
        List<PerformanceTarget__c> actualPerformanceTargets =
            new PerformanceTargetSelector().getAllForObjectApiNames(
                new List<String> {Lead.sObjectType.getDescribe().getName()},
                PerformanceTargetDO.TYPE_INDICATOR,
                PerformanceTargetDO.STATUS_ACTIVE
            );
        Test.stopTest();

        System.assertEquals(2, actualPerformanceTargets.size());
    }

    /**
     * Test method to verify fetching Performance Targets with Assigned Targets
     */
    static testmethod void testFetchingWithAssignedTargets() {
        TestUtils.Surveyor activeSurveyor =
            TestUtils.createPartnerSurveyor('partnerContact', true);

        List<PerformanceTarget__c> performanceTargets =
            PerformanceTargetDOTest.createMultiplePerformanceIndicators(1);

        System.assertEquals(1, performanceTargets.size());

        PerformanceTargetDO performanceTargetDomainInstance =
            new PerformanceTargetDO.Constructor().constructWithRecords(performanceTargets);
        performanceTargetDomainInstance.insertRecords();

        // Create the corresponding assigned target for each user
        AssignedTarget__c assignedTarget1 = 
            AssignedTargetDOTest.createRecord(
                activeSurveyor.partnerUser.ContactId,
                1,
                performanceTargets[0],
                AssignedTargetDO.STATUS_ACTIVE
            );

        AssignedTarget__c assignedTarget2 = 
            AssignedTargetDOTest.createRecord(
                activeSurveyor.partnerUser.ContactId,
                2,
                performanceTargets[0],
                AssignedTargetDO.STATUS_ACTIVE
            );

        AssignedTargetDO assignedTargetDomainInstance =
            new AssignedTargetDO.Constructor().constructWithRecords(
                new List<AssignedTarget__c> {assignedTarget1, assignedTarget2}
            );
        assignedTargetDomainInstance.insertRecords();

        Test.startTest();
        PerformanceTarget__c actualPerformanceTarget =
            new PerformanceTargetSelector().getWithAssignedTargets(
                performanceTargets[0].Id,
                PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6)
            );
        Test.stopTest();

        System.assert(
            actualPerformanceTarget != null,
            'Performance Target reccord not fetched properly'
        );
        System.assertEquals(2, actualPerformanceTarget.Assigned_Targets__r.size());
    }

    /**
     * Test method to verify fetching Performance Targets with SObjectFilterCondition
     */
    static testmethod void testFetchingWithSObjectFilterCondition() {
        TestUtils.Surveyor activeSurveyor =
            TestUtils.createPartnerSurveyor('partnerContact', true);

        List<PerformanceTarget__c> performanceTargets =
            PerformanceTargetDOTest.createMultiplePerformanceIndicators(1);

        System.assertEquals(1, performanceTargets.size());

        PerformanceTargetDO performanceTargetDomainInstance =
            new PerformanceTargetDO.Constructor().constructWithRecords(performanceTargets);
        performanceTargetDomainInstance.insertRecords();

        SObjectFilterCondition__c sObjectFilterCondition1 =
            SObjectFilterConditionDOTest.createRecord(
                Lead.sObjectType.getDescribe().getName(),
                SObjectFilterConditionDO.NOT_EQUALS,
                'Test1',
                performanceTargets[0].Id
            );
        SObjectFilterCondition__c sObjectFilterCondition2 =
            SObjectFilterConditionDOTest.createRecord(
                Contact.sObjectType.getDescribe().getName(),
                SObjectFilterConditionDO.LESS_THAN,
                'Test2',
                performanceTargets[0].Id
            );
        SObjectFilterConditionDO sObjectFilterConditionDomainInstance =
            new SObjectFilterConditionDO.Constructor().constructWithRecords(
                new List<SObjectFilterCondition__c> {
                    sObjectFilterCondition1,
                    sObjectFilterCondition2
                }
            );
        sObjectFilterConditionDomainInstance.insertRecords();

        Test.startTest();
        List<PerformanceTarget__c> actualPerformanceTargets =
            new PerformanceTargetSelector().getAllWithSObjectFilterCondition(
                Lead.sObjectType.getDescribe().getName(),
                PerformanceTargetDO.TYPE_INDICATOR,
                PerformanceTargetDO.STATUS_ACTIVE
            );
        Test.stopTest();

        System.assertEquals(
            1,
            actualPerformanceTargets.size()
        );
        System.assertEquals(2, actualPerformanceTargets[0].SObject_Filter_Conditions__r.size());
    }

    /**
     * Test method to verify fetching Performance Targets for all Active TrackedObjectApiNames
     */
    static testmethod void testFetchingForAllActiveTrackedObjectApiNames() {
        // Create 2 Performance Targets with object Name Lead
        List<PerformanceTarget__c> performanceTargets =
            PerformanceTargetDOTest.createMultiplePerformanceIndicators(2);

        // Create 1 Performance Targets with object Name Asset
        PerformanceTarget__c performanceTarget3 =
            PerformanceTargetDOTest.createPerformanceIndicatorRecord(
                'PerformanceIndicator3',
                50,
                PerformanceTargetDO.TIMEFRAME_WEEKLY,
                PerformanceTargetDO.getPreviousMonday(Date.today()),
                PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
                PerformanceTargetDOTest.ASSET_API_NAME,
                PerformanceTargetDO.AGGREGATION_OPERATION_COUNT,
                '',
                PerformanceTargetDOTest.CONTACT_ID_FIELD
            );

        performanceTargets.add(performanceTarget3);

        System.assertEquals(3, performanceTargets.size());

        PerformanceTargetDO performanceTargetDomainInstance =
            new PerformanceTargetDO.Constructor().constructWithRecords(performanceTargets);
        performanceTargetDomainInstance.insertRecords();

        Test.startTest();
        List<AggregateResult> actualPerformanceTargetsAggregate =
            new PerformanceTargetSelector().getAllTrackedObjectApiNames(
                PerformanceTargetDO.TYPE_INDICATOR,
                PerformanceTargetDO.STATUS_ACTIVE
            );
        Test.stopTest();

        // Only 2 records are fetched as it is grouped by Object Names (Lead and Asset)
        System.assertEquals(2, actualPerformanceTargetsAggregate.size());
    }

    /**
     * Test method to verify PerformanceTarget for specified fieldApiNames and Aggregate Operation
     */
    static testmethod void testGetAllForAggregationOperation() {

        List<PerformanceTarget__c> performanceTargets =
            PerformanceTargetDOTest.createMultiplePerformanceIndicators(2);

        PerformanceTargetDO performanceTargetDomainInstance =
            new PerformanceTargetDO.Constructor().constructWithRecords(performanceTargets);
        performanceTargetDomainInstance.insertRecords();

        performanceTargets[0].TrackedFieldApiName__c = PerformanceTargetDOTest.PRICE_FIELD;
        performanceTargetDomainInstance.updateRecords();

        Test.startTest();
        List<PerformanceTarget__c> actualPerformanceTargets =
            new PerformanceTargetSelector().getAllForAggregationOperation(
                PerformanceTargetDOTest.LEAD_NUMBER_OF_EMPLOYEES,
                PerformanceTargetDO.AGGREGATION_OPERATION_SUM
            );
        Test.stopTest();

        System.assertEquals(1, actualPerformanceTargets.size());
    }
}