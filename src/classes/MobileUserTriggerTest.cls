/**
 * Test class for the trigger for Mobile_User__c
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
@isTest
public with sharing class MobileUserTriggerTest {

    private static PerformanceTarget__c currentPerformanceTarget;

    /**
     * Test assigned target creation for job target when an active user is inserted
     */
    static testMethod void testTargetCreationForJobTargetOnActiveUserInsert() {
        // Given a job target
        createAJobTarget();

        Test.startTest();
        // When an active mobile user is inserted
        TestUtils.Surveyor activeSurveyor =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);
        Test.stopTest();

        // Then an assigned target is created
        checkAssignedTargetIsCreated(activeSurveyor);
    }

    /**
     * Test assigned target creation for indicator target when an active user is inserted
     */
    static testMethod void testTargetCreationForIndicatorTargetOnActiveUserInsert() {
        // Given an indicator target
        createPerformanceIndicatorTarget();

        Test.startTest();
        // When an active mobile user is inserted
        TestUtils.Surveyor activeSurveyor =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);
        Test.stopTest();

        // Then an assigned target is created
        checkAssignedTargetIsCreated(activeSurveyor);
    }

    /**
     * Test assigned target not created for a job target when an inactive user is inserted
     */
    static testMethod void testTargetNotCreatedForJobTargetOnInactiveUserInsert() {
        // Given a job target
        createAJobTarget();

        Test.startTest();
        // When an inactive mobile used is inserted
        TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_INACTIVE);
        Test.stopTest();

        // Then no assigned target is created
        System.assertEquals(0, [
            SELECT Id
            FROM AssignedTarget__c
            WHERE PerformanceTarget__c = :currentPerformanceTarget.Id
        ].size());
    }

    /**
     * Test assigned target not created for an indicator target when an inactive user is inserted
     */
    static testMethod void testTargetNotCreatedForIndicatorTargetOnInactiveUserInsert() {
        // Given an indicator target
        createPerformanceIndicatorTarget();

        Test.startTest();
        // When an inactive mobile used is inserted
        TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_INACTIVE);
        Test.stopTest();

        // Then no assigned target is created
        System.assertEquals(0, [
            SELECT Id
            FROM AssignedTarget__c
            WHERE PerformanceTarget__c = :currentPerformanceTarget.Id
        ].size());
    }

    /**
     * Test assigned target creation for job target when an inactive user becomes active
     */
    static testMethod void testTargetCreationForJobTargetOnUserActivate() {
        // Given a job target and an inactive mobile user
        createAJobTarget();
        TestUtils.Surveyor inactiveSurveyor =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_INACTIVE);

        Test.startTest();
        // When the mobile user is activated
        TestUtils.Surveyor activatedSurveyor = TestUtils.changeSurveyorStatus(
            inactiveSurveyor,
            MobileUserDO.STATUS_ACTIVE
        );
        Test.stopTest();

        // Then an assigned target is created
        checkAssignedTargetIsCreated(activatedSurveyor);
    }

    /**
     * Test assigned target creation for indicator target when an inactive user becomes active
     */
    static testMethod void testTargetCreationForIndicatorTargetOnUserActivate() {
        // Given an indicator target and an inactive mobile user
        createPerformanceIndicatorTarget();
        TestUtils.Surveyor inactiveSurveyor =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_INACTIVE);

        Test.startTest();
        // When the mobile user is activated
        TestUtils.Surveyor activatedSurveyor = TestUtils.changeSurveyorStatus(
            inactiveSurveyor,
            MobileUserDO.STATUS_ACTIVE
        );
        Test.stopTest();

        // Then an assigned target is created
        checkAssignedTargetIsCreated(activatedSurveyor);
    }

    /**
     * Test reopen an assigned target for a job target when an inactive user becomes active
     */
    static testMethod void testReopenTargetForJobTargetOnUserActivate() {
        // Given a job target and an inactive mobile user with a closed assigned target
        createAJobTarget();
        TestUtils.Surveyor inactiveSurveyor =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_INACTIVE);
        AssignedTarget__c closedTarget = createClosedAssignedTargetFor(inactiveSurveyor);

        Test.startTest();
        // When the mobile used is activated
        TestUtils.Surveyor activatedSurveyor = TestUtils.changeSurveyorStatus(
            inactiveSurveyor,
            MobileUserDO.STATUS_ACTIVE
        );
        Test.stopTest();

        // Then the same assigned target is reopened
        checkAssignedTargetIsReopened(closedTarget);
    }

    /**
     * Test reopen an assigned target for an indicator target when an inactive user becomes active
     */
    static testMethod void testReopenTargetForIndicatorTargetOnUserActivate() {
        // Given an indicator target and an inactive mobile user with a closed assigned target
        createPerformanceIndicatorTarget();
        TestUtils.Surveyor inactiveSurveyor =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_INACTIVE);
        AssignedTarget__c closedTarget = createClosedAssignedTargetFor(inactiveSurveyor);

        Test.startTest();
        // When the mobile used is activated
        TestUtils.Surveyor activatedSurveyor = TestUtils.changeSurveyorStatus(
            inactiveSurveyor,
            MobileUserDO.STATUS_ACTIVE
        );
        Test.stopTest();

        // Then the same assigned target is reopened
        checkAssignedTargetIsReopened(closedTarget);
    }

    /**
     * Test close assigned target of job target when user is deleted
     */
    static testMethod void testCloseTargetOfJobTargetOnDelete() {
        // Given a job target and an active mobile user
        createAJobTarget();
        TestUtils.Surveyor activeSurveyor =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);

        Test.startTest();
        // When the mobile user is deleted
        delete activeSurveyor.user;
        Test.stopTest();

        // Then the assigned target for this user is closed
        System.assertEquals(
            AssignedTargetDO.STATUS_CLOSED,
            [SELECT Status__c
             FROM AssignedTarget__c
             WHERE Contact__c = :activeSurveyor.theContact.Id].Status__c
        );
    }

    /**
     * Test close assigned target of indicator target when user is deleted
     */
    static testMethod void testCloseTargetOfIndicatorTargetOnDelete() {
        // Given an indicator target and an active mobile user
        createPerformanceIndicatorTarget();
        TestUtils.Surveyor activeSurveyor =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);

        Test.startTest();
        // When the mobile user is deleted
        delete activeSurveyor.user;
        Test.stopTest();

        // Then the assigned target for this user is closed
        System.assertEquals(
            AssignedTargetDO.STATUS_CLOSED,
            [SELECT Status__c
             FROM AssignedTarget__c
             WHERE Contact__c = :activeSurveyor.theContact.Id].Status__c
        );
    }

    /**
     * Test close assigned target of job target when user becomes inactive
     */
    static testMethod void testCloseTargetOfJobTargetOnDeactivate() {
        // Given a job target and an active mobile user
        createAJobTarget();
        TestUtils.Surveyor activeSurveyor =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);

        Test.startTest();
        // When the mobile user is deactivated
        TestUtils.Surveyor deactivatedSurveyor = TestUtils.changeSurveyorStatus(
            activeSurveyor,
            MobileUserDO.STATUS_INACTIVE
        );
        Test.stopTest();

        // Then the assigned target for this user is closed
        System.assertEquals(
            AssignedTargetDO.STATUS_CLOSED,
            [SELECT Status__c
             FROM AssignedTarget__c
             WHERE Contact__c = :activeSurveyor.theContact.Id].Status__c
        );
    }

    /**
     * Test close assigned target of indicator target when user becomes inactive
     */
    static testMethod void testCloseTargetOfIndicatorTargetOnDeactivate() {
        // Given a indicator target and an active mobile user
        createAJobTarget();
        TestUtils.Surveyor activeSurveyor =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);

        Test.startTest();
        // When the mobile user is deactivated
        TestUtils.Surveyor deactivatedSurveyor = TestUtils.changeSurveyorStatus(
            activeSurveyor,
            MobileUserDO.STATUS_INACTIVE
        );
        Test.stopTest();

        // Then the assigned target for this user is closed
        System.assertEquals(
            AssignedTargetDO.STATUS_CLOSED,
            [SELECT Status__c
             FROM AssignedTarget__c
             WHERE Contact__c = :activeSurveyor.theContact.Id].Status__c
        );
    }

    /**
     * Test the creation of assigned targets with the job filter on
     */
    static testMethod void testAssignedTargetCreationWithJobFilter() {
        // Create two users
        Profile sysAdmin = TestUtils.getSysAdminProfile();
        User user1 = TestUtils.createUser(sysAdmin.Id);
        User user2 = TestUtils.createUser(sysAdmin.Id);

        // Create two contacts
        Contact contact1 = new Contact(LastName = 'contact1');
        Contact contact2 = new Contact(LastName = 'contact2');
        insert new List<Contact> {contact1, contact2};

        // Create two job templates
        JobTemplate__c job1 = TestUtils.createPublishedDataCollectionJobTemplate('job1', 'Survey 1');
        JobTemplate__c job2 = TestUtils.createPublishedDataCollectionJobTemplate('job2', 'Survey 2');

        // Change the ownership
        contact1.OwnerId = user1.Id;
        contact2.OwnerId = user2.Id;
        update new List<Contact> {contact1, contact2};

        job1.OwnerId = user1.Id;
        job2.OwnerId = user2.Id;
        update new List<JobTemplate__c> {job1, job2};

        // Set the job filter on
        ApplicationSettingsUtils.setJobFilterSetting(
            ApplicationSettingsUtils.JOBS_FILTER_SF_USER
        );

        // Create two performance targets
        PerformanceTarget__c performanceTarget1 = PerformanceTargetDOTest.createJobTargetRecord(
            'PerformanceTarget1',
            job1.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            PerformanceTargetDO.getPreviousMonday(Date.today()),
            PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        PerformanceTarget__c performanceTarget2 = PerformanceTargetDOTest.createJobTargetRecord(
            'PerformanceTarget2',
            job2.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            PerformanceTargetDO.getPreviousMonday(Date.today()),
            PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        insert new List<PerformanceTarget__c> {
            performanceTarget1,
            performanceTarget2
        };
        performanceTarget1.OwnerId = user1.Id;
        performanceTarget2.OwnerId = user2.Id;
        update new List<PerformanceTarget__c> {
            performanceTarget1,
            performanceTarget2
        };

        // Insert two mobile users
        Mobile_User__c mUser1 = new Mobile_User__c(
            Username__c = 'user1',
            Password__c = 'pass1',
            Contact__c = contact1.Id,
            Status__c = MobileUserDO.STATUS_ACTIVE
        );
        Mobile_User__c mUser2 = new Mobile_User__c(
            Username__c = 'user2',
            Password__c = 'pass2',
            Contact__c = contact2.Id,
            Status__c = MobileUserDO.STATUS_ACTIVE
        );

        Test.startTest();
        System.runAs(user1) {
            insert mUser1;
        }
        System.runAs(user2) {
            insert mUser2;
        }
        Test.stopTest();

        // Check the first mobile user has an assigned target for the first job
        List<AssignedTarget__c> targets = new List<AssignedTarget__c> ([
            SELECT Id,
                   PerformanceTarget__r.JobTemplate__c
            FROM AssignedTarget__c
            WHERE Contact__c = :contact1.Id
        ]);
        System.assertEquals(1, targets.size());
        System.assertEquals(
            job1.Id,
            targets[0].PerformanceTarget__r.JobTemplate__c
        );

        // Check the second mobile user has an assigned target for the second job
        targets = new List<AssignedTarget__c> ([
            SELECT Id,
                   PerformanceTarget__r.JobTemplate__c
            FROM AssignedTarget__c
            WHERE Contact__c = :contact2.Id
        ]);
        System.assertEquals(1, targets.size());
        System.assertEquals(
            job2.Id,
            targets[0].PerformanceTarget__r.JobTemplate__c
        );
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
     * Check the creation o assigned targets for the given user
     *
     * @param activeSurveyor - The user to verify
     */
    private static void checkAssignedTargetIsCreated(TestUtils.Surveyor activeSurveyor) {
        List<AssignedTarget__c> assignedTargets = new List<AssignedTarget__c>([
            SELECT Id,
                   TargetValue__c,
                   StartDate__c,
                   EndDate__c,
                   Status__c,
                   Contact__c
            FROM AssignedTarget__c
            WHERE PerformanceTarget__c = :currentPerformanceTarget.Id
        ]);

        // Check an assigned target was created for the active user
        System.assertEquals(1, assignedTargets.size());
        System.assertEquals(activeSurveyor.theContact.Id, assignedTargets[0].Contact__c);

        // Check the assigned target has the default value and the right dates
        System.assertEquals(
            currentPerformanceTarget.DefaultValue__c,
            assignedTargets[0].TargetValue__c
        );
        System.assertEquals(
            currentPerformanceTarget.StartDate__c,
            assignedTargets[0].StartDate__c
        );
        System.assertEquals(currentPerformanceTarget.EndDate__c, assignedTargets[0].EndDate__c);
        System.assertEquals(AssignedTargetDO.STATUS_ACTIVE, assignedTargets[0].Status__c);
    }

    /**
     * Set preconditions for indicator target tests
     */
    private static void createPerformanceIndicatorTarget() {
        PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper =
                new PerformanceManagementTest.EndToEndTestWrapper();
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            1,
            '',
            null,
            null,
            null,
            null,
            null,
            null
        );
        currentPerformanceTarget = endToEndTestWrapper
                .getPerformanceTargetWrapperByCreationIndex(0).getPerformanceTarget();
    }

    /**
     * Check the assigned target was reopened
     *
     * @param oldTarget - The old assigned target
     */
    private static void checkAssignedTargetIsReopened(AssignedTarget__c oldTarget) {
        List<AssignedTarget__c> assignedTargets = new List<AssignedTarget__c>([
            SELECT Id,
                   TargetValue__c,
                   StartDate__c,
                   EndDate__c,
                   Status__c
            FROM AssignedTarget__c
            WHERE PerformanceTarget__c = :currentPerformanceTarget.Id
        ]);

        // Check the assigned target was activated
        System.assertEquals(1, assignedTargets.size());
        System.assertEquals(oldTarget.Id, assignedTargets[0].Id);
        System.assertEquals(AssignedTargetDO.STATUS_ACTIVE, assignedTargets[0].Status__c);

        // Check the assigned target has the same value and dates
        System.assertEquals(oldTarget.TargetValue__c, assignedTargets[0].TargetValue__c);
        System.assertEquals(oldTarget.StartDate__c, assignedTargets[0].StartDate__c);
        System.assertEquals(oldTarget.EndDate__c, assignedTargets[0].EndDate__c);
    }

    /**
     * Create a closed assigned target for the given surveyor
     *
     * @param surveyor - The surveyor to create the assigned target for
     *
     * @return - The created assigned target
     */
    private static AssignedTarget__c createClosedAssignedTargetFor(TestUtils.Surveyor surveyor) {
        AssignedTarget__c closedTarget = AssignedTargetDO.createAssignedTarget(
            currentPerformanceTarget,
            surveyor.theContact.Id,
            0,
            Integer.valueOf(currentPerformanceTarget.DefaultValue__c),
            currentPerformanceTarget.StartDate__c,
            currentPerformanceTarget.EndDate__c,
            AssignedTargetDO.STATUS_CLOSED
        );
        insert closedTarget;

        return closedTarget;
    }
}

