/**
 * Test class for AssignedTargetDo
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 * @author - Aditi Satpute
 */
@isTest
public class AssignedTargetDOTest {

    /**
     * Method to create multiple AssignedTarget records
     */
    public static List<AssignedTarget__c> createMultipleRecords(
            Id contactId,
            Integer actualValue,
            PerformanceTarget__c performanceTarget,
            String status,
            Integer noOfRecords
    ) {
        List<AssignedTarget__c> assignedTargets = new List<AssignedTarget__c>();
        for (Integer i = 0; i < noOfRecords; i++) {
            assignedTargets.add(new AssignedTarget__c(
                Contact__c = contactId,
                ActualValue__c = actualValue,
                PerformanceTarget__c = performanceTarget.Id,
                StartDate__c = performanceTarget.StartDate__c,
                EndDate__c = performanceTarget.EndDate__c,
                TargetValue__c = performanceTarget.DefaultValue__c,
                Status__c = status
            ));
        }

        return assignedTargets;
    }

    /**
     * Method to create AssignedTarget record
     */
    public static AssignedTarget__c createRecord(
            Id contactId,
            Integer actualValue,
            PerformanceTarget__c performanceTarget,
            String status
    ) {
        AssignedTarget__c assignedTarget = new AssignedTarget__c(
            Contact__c = contactId,
            ActualValue__c = actualValue,
            PerformanceTarget__c = performanceTarget.Id,
            StartDate__c = performanceTarget.StartDate__c,
            EndDate__c = performanceTarget.EndDate__c,
            TargetValue__c = performanceTarget.DefaultValue__c,
            Status__c = status
        );
        return assignedTarget;
    }

    /**
     * Check if assigned targets are inserted correctly with job filtering OFF
     */
    static testMethod void checkAssignedTargetsJobFilteringOff() {
        Set<String> usersContactSet = new Set<String>();
        // Create Partner Account
        List<Account> partnerAccount = TestUtils.createAccounts(1);
        System.assert(partnerAccount.size() == 1, 'Account not created properly');

        // Create Active Partner User
        User partnerUser1 = TestUtils.createPartnerUser(
            partnerAccount[0],
            'activeUsersContact',
            true
        );
        System.assert(partnerUser1 != null, 'Partner User not created properly');
        
        // Create InActive Partner User
        User partnerUser2 = TestUtils.createPartnerUser(
            partnerAccount[0],
            'inActiveUsersContact',
            false
        );
        System.assert(partnerUser2 != null, 'Partner User not created properly');

        // Create job template
        JobTemplate__c jobTemplate = 
            TestUtils.createPublishedDataCollectionJobTemplate('job', 'survey');

        // Create target
        PerformanceTarget__c target = PerformanceTargetDOTest.createJobTargetRecord(
            'PerformanceTarget1',
            jobTemplate.id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today().addDays(7),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        insert target;

        // Set job filtering
        ApplicationSettingsUtils.setJobFilterSetting(ApplicationSettingsUtils.JOBS_FILTER_ALL);

        Test.startTest();
        insert AssignedTargetDO.createDefaultAssignedTargetsForAllMobileUsers(target);
        Test.stopTest();
        // Retrieve all partner users entered in test case
        List<User> partnerUsers = [
            SELECT
                Id,
                ContactId
            FROM
                User
            WHERE
                UserType = 'PowerPartner'
            AND Id IN (:partnerUser1.Id, :partnerUser2.Id)
        ];

        // Retrieve all User's Contact inserted in test case
        for (User userInstance : partnerUsers) {
            usersContactSet.add(userInstance.ContactId);
        }
 
        // Check if there is one assigned target for active partner user
        System.assertEquals(
            1,
            [
                SELECT
                    Id
                FROM
                    AssignedTarget__c
                WHERE
                    Contact__c = :usersContactSet
                AND
                    Status__c = 'Active'
            ].size()
        );
    }

    /**
     * Check if assigned targets are inserted correctly with job filtering ON
     */
    static testMethod void checkAssignedTargetsJobFilteringOn() {
        Set<String> usersContactSet = new Set<String>();
        List<AssignedTarget__c> assignedTargets = new List<AssignedTarget__c>();
        Profile adminProfile = TestUtils.getSysAdminProfile();

        // Create two users
        User adminUser1 = TestUtils.createUser(adminProfile.Id);
        User adminUser2 = TestUtils.createUser(adminProfile.Id);

        // Create Partner Account
        List<Account> partnerAccount = TestUtils.createAccounts(1);
        System.assert(partnerAccount.size() == 1, 'Account not created properly');

        // Create Active Partner User for Admin User 1
        User partnerUser1 = TestUtils.createPartnerUser(
            partnerAccount[0],
            'activeUsersContact',
            true
        );
        partnerUser1.Contact.OwnerId = adminUser1.Id;
        update partnerUser1.Contact;
        System.assert(partnerUser1 != null, 'Partner User not created properly');
        
        // Create Active Partner User for Admin User 2
        User partnerUser2 = TestUtils.createPartnerUser(
            partnerAccount[0],
            'inActiveUsersContact',
            true
        );
        partnerUser2.Contact.OwnerId = adminUser2.Id;
        update partnerUser2.Contact;
        System.assert(partnerUser2 != null, 'Partner User not created properly');

        // Create a Job templates and assign them a user
        JobTemplate__c jobTemplate = 
            TestUtils.createPublishedDataCollectionJobTemplate('job', 'survey');

        jobTemplate.OwnerId = adminUser1.Id;
        update jobTemplate;

        // Create target
        PerformanceTarget__c target = PerformanceTargetDOTest.createJobTargetRecord(
            'PerformanceTarget1',
            jobTemplate.id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today().addDays(7),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        insert target;
        target.OwnerId = adminUser1.Id;
        update target;

        // Set job filtering
        ApplicationSettingsUtils.setJobFilterSetting(ApplicationSettingsUtils.JOBS_FILTER_SF_USER);

        // Retrieve all partner users entered in test case
        List<User> partnerUsers = [
            SELECT
                Id,
                ContactId
            FROM
                User
            WHERE
                UserType = 'PowerPartner'
            AND
                Id IN (:partnerUser1.Id, :partnerUser2.Id)
        ];

        // Retrieve all User's Contact inserted in test case
        for (User userInstance : partnerUsers) {
            usersContactSet.add(userInstance.ContactId);
        }

        Test.startTest();
        // Login as Admin 1
        System.runAs(adminUser1) {
            assignedTargets = 
                AssignedTargetDO.createDefaultAssignedTargetsForAllMobileUsers(target);
            System.assert(!assignedTargets.isEmpty(), 'Default targets not assigned properly');
        }
        Test.stopTest();
        // Check if there is just one assigned target related to the partner user that owns the job
        System.assertEquals(
            assignedTargets.size(),
            [
                SELECT
                    Id
                FROM
                    AssignedTarget__c
                WHERE
                    Contact__c IN :usersContactSet
            ].size()
        );

        // Inserted Users count doesn't match with the targets assigned to its particular contact
        System.assertNotEquals(
            partnerUsers.size(),
            [
                SELECT
                    Id
                FROM
                    AssignedTarget__c
                WHERE
                    Contact__c IN :usersContactSet
            ].size()
        );
    }

    /**
     * Test Performance Indicator Assigned Targets have performance of 100 when target is 0
     */
    static testMethod void testPerformance100WhenTarget0() {

        TestUtils.Surveyor surveyor = createDefaultProgressData();

        List<AssignedTarget__c> newAssignedTargets =
            AssignedTargetDO.getCurrentActiveAssignedTargets(
                surveyor.theContact.Id,
                null
            );
        System.assertEquals(0, newAssignedTargets.size());
        for (AssignedTarget__c newAssignedTarget : newAssignedTargets) {
            System.assertEquals(0, newAssignedTarget.TargetValue__c);
            System.assertEquals(1, newAssignedTarget.Progress__c);
        }
    }

    /**
     * Create a standard Surveyor and add a performance indicator with a target of 0
     * This creates a default Assignedtarget for that surveyor
     */
    private static TestUtils.Surveyor createDefaultProgressData() {

        TestUtils.Surveyor surveyor = TestUtils.createSurveyor(
            'FirstName', 'LastName', 'UserName',
            MobileUserDo.STATUS_ACTIVE, false
        );
        PerformanceTarget__c indicator = PerformanceTargetDOTest.createPerformanceIndicatorRecord(
            'TestIndicator', 0, PerformanceTargetDO.TIMEFRAME_WEEKLY, Date.today(),
            Date.today(), Contact.SObjectType.getDescribe().getName(),
            PerformanceTargetDO.AGGREGATION_OPERATION_COUNT,
            Contact.Name.getDescribe().getName(),
            Contact.ReportsToId.getDescribe().getName()
        );
        insert indicator;
        return surveyor;
    }
}