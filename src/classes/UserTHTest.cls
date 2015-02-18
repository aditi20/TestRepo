/**
 * Test class for UserTH
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 *
 * @author - Aditi Satpute
 */
@isTest
public with sharing class UserTHTest {
    private static PerformanceTarget__c currentPerformanceTarget;
    private static User partnerUser1;
    private static User partnerUser2;
    private static User partnerUser3;

    /**
     * Test assigned target creation for job target when an active user is inserted
     */
   static testMethod void testTargetCreationForJobTargetOnActiveUserInsert() {
        createAJobTarget();
        Test.startTest();
        createPartnerUsers();
        Test.stopTest();
        checkAssignedTargetIsCreated(partnerUser1);
    }

    /**
     * Test assigned target updation for job target when an active user is updated
     */
    static testMethod void testTargetCreationForJobTargetOnActiveUserUpdate() {
        createAJobTarget();
        createPartnerUsers();

        // Fetch active user for logging in
        User activeLoginPartnerUser = [
            SELECT 
                Id,
                isActive
            FROM
                User
            WHERE
                Contact.Name = 'activeUsersContact'
        ];

        // Fetch active user for updating
        User activeUpdatePartnerUser = [
            SELECT
                Id,
                isActive
            FROM
                User
            WHERE
                Contact.Name = 'activeUsersContact1'
        ];
        System.RunAs(activeLoginPartnerUser) {
            Test.startTest();
            activeUpdatePartnerUser.isActive = false;
            update activeUpdatePartnerUser;
            Test.stopTest();
        }
        // Check assigned target record is updated
        checkAssignedTargetIsCreated(activeUpdatePartnerUser);
    }

    /**
     * Test assigned target creation for job target when an active user is updated
     */
    static testMethod void testTargetCreationForJobTargetOnInActiveUserUpdate() {
        createAJobTarget();
        createPartnerUsers();

        // Fetch active user for logging in
        User activeLoginPartnerUser = [
            SELECT
                Id,
                isActive
            FROM
                User
            WHERE
                Contact.Name = 'activeUsersContact'
        ];

        // Fetch inActive user for updating
        User inActivePartnerUser = [
            SELECT
                Id,
                isActive
            FROM
                User
            WHERE
                Contact.Name = 'inActiveUsersContact'
        ];

        System.RunAs(activeLoginPartnerUser) {
            Test.startTest();
            inActivePartnerUser.isActive = true;
            update inActivePartnerUser;
            Test.stopTest();
        }
        checkAssignedTargetIsCreated(inActivePartnerUser);
    }

    /**
     * Create a job target for the preconditions
     */
    private static void createPartnerUsers() {
        // Create Partner Account
        List<Account> partnerAccount = TestUtils.createAccounts(1);
        System.assert(partnerAccount.size() == 1, 'Account not created properly');

        // Create Active Partner Users
        partnerUser1 = TestUtils.createPartnerUser(
            partnerAccount[0],
            'activeUsersContact',
            true
        );
        System.assert(partnerUser1 != null, 'Partner User not created properly');
        partnerUser2 = TestUtils.createPartnerUser(
            partnerAccount[0],
            'activeUsersContact1',
            true
        );
        System.assert(partnerUser2 != null, 'Partner User not created properly');

        // Create InActive Partner User
        partnerUser3 = TestUtils.createPartnerUser(
            partnerAccount[0],
            'inActiveUsersContact',
            false
        );
        System.assert(partnerUser3 != null, 'Partner User not created properly');
    }

    /**
     * Create a job target for the preconditions
     */
    private static void createAJobTarget() {
        PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper =
                new PerformanceManagementTest.EndToEndTestWrapper();
        endToEndTestWrapper.initJobPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            1,
            ''
        );
        currentPerformanceTarget = endToEndTestWrapper
                .getPerformanceTargetWrapperByCreationIndex(0).getPerformanceTarget();
    }

    /**
     * Check the creation of assigned targets for the given user
     *
     * @param partnerUser - The partner user to verify
     */
    private static void checkAssignedTargetIsCreated(User partnerUser) {
        List<AssignedTarget__c> assignedTargets = new List<AssignedTarget__c>([
            SELECT Id,
                   TargetValue__c,
                   StartDate__c,
                   EndDate__c,
                   Status__c,
                   Contact__c
            FROM AssignedTarget__c
            WHERE PerformanceTarget__c = :currentPerformanceTarget.Id
            AND Contact__c = :partnerUser.ContactId
        ]);

        // Check an assigned target was created for the active user
        System.assertEquals(1, assignedTargets.size());
        System.assertEquals(partnerUser.ContactId, assignedTargets[0].Contact__c);

        // Check the assigned target has the default value and the right dates
        System.assertEquals(
            currentPerformanceTarget.DefaultValue__c,
            assignedTargets[0].TargetValue__c
        );
        System.assertEquals(
            currentPerformanceTarget.StartDate__c,
            assignedTargets[0].StartDate__c
        );
        System.assertEquals(
            currentPerformanceTarget.EndDate__c,
            assignedTargets[0].EndDate__c
        );

        // Check the status of Assigned targets based on Partner User insertion/updation
        if (partnerUser.IsActive) {
            System.assertEquals(
                AssignedTargetDO.STATUS_ACTIVE,
                assignedTargets[0].Status__c
            );
        } else {
            System.assertEquals(
                AssignedTargetDO.STATUS_CLOSED,
                assignedTargets[0].Status__c
            );
        }
    }
}