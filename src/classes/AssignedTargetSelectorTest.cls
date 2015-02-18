/**
 * Test class for the AssignedTargetSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
@isTest
public with sharing class AssignedTargetSelectorTest {

    /**
     * Test method to verify fetching Assigned Targets for partner users
     */
    static testmethod void testFetchingForPartnerUsers() {
        TestUtils.Surveyor activeSurveyor =
            TestUtils.createPartnerSurveyor('partnerContact', true);

        List<PerformanceTarget__c> performanceTargets =
            PerformanceTargetDOTest.createMultiplePerformanceIndicators(1);

        System.assertEquals(1, performanceTargets.size());

        PerformanceTargetDO performanceTargetDomainInstance =
            new PerformanceTargetDO.Constructor().constructWithRecords(performanceTargets);
        performanceTargetDomainInstance.insertRecords();

        // Create the corresponding assigned target for each user
        List<AssignedTarget__c> assignedTargets =
            AssignedTargetDOTest.createMultipleRecords(
                activeSurveyor.partnerUser.ContactId,
                2,
                performanceTargets[0],
                AssignedTargetDO.STATUS_ACTIVE,
                2
            );

        AssignedTargetDO assignedTargetDomainInstance =
            new AssignedTargetDO.Constructor().constructWithRecords(assignedTargets);
        assignedTargetDomainInstance.insertRecords();

        Test.startTest();
        List<AssignedTarget__c> actualAssignedTargets=
            new AssignedTargetSelector().getForPartnerUsers(
                performanceTargets[0].Id,
                PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
                new Set<Id> {activeSurveyor.partnerUser.ContactId}
            );
        Test.stopTest();

        System.assertEquals(2, actualAssignedTargets.size());
    }
}