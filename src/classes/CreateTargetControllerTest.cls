/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Santiago Blankleider
 */
@isTest
public class CreateTargetControllerTest {
    private static User partnerUser1;
    // Create new performance target with assigned targets with weekly timeframe
    static testMethod void createJobTargetWeeklyDefaultTarget() {
        // Create published job
        JobTemplate__c job = TestUtils.createPublishedDataCollectionJobTemplate('job', 'survey');
        // Create preconditions
        CreateJobTargetController controller = createPreconditionsForTargets(
                                                job.Id,
                                                'pTarget',
                                                'cName1',
                                                'mobileUsername',
                                                PerformanceTargetDO.TIMEFRAME_WEEKLY);

        Test.startTest();
        // Save
        controller.save();
        Test.stopTest();

        List<PerformanceTarget__c> pTs = [SELECT 
                                                DefaultValue__c, 
                                                Timeframe__c, 
                                                Type__c 
                                          FROM PerformanceTarget__c];
        List<AssignedTarget__c> aTs    = [SELECT TargetValue__c FROM AssignedTarget__c];

        // Check performance and assigned target creation
        system.assert(!pTs.isEmpty(), 'Cannot be empty since new Performance target was created');
        system.assertEquals(PerformanceTargetDO.TYPE_JOB_TARGET, 
                pTs[0].Type__c, 
                'The type should be job target');
        system.assert(!aTs.isEmpty(), 'Cannot be empty since new Assigned target was created');
        // Check timeframe
        system.assertEquals(PerformanceTargetDO.TIMEFRAME_WEEKLY, pTs[0].Timeframe__c,
                            'Timeframe must be weekly as default');
        // Check Target, and Default value is correctly saved on DB
        system.assertEquals(70, Integer.ValueOf(aTs[0].TargetValue__c), 'Target value must be 70 as is set');
        system.assertEquals(50, Integer.ValueOf(pTs[0].DefaultValue__c), 'Default value was set as 50');
    }

    // Create new performance target with assigned targets with monthly timeframe
    static testMethod void createJobTargetMonthlyDefaultTarget() {
        // Create published job
        JobTemplate__c job = TestUtils.createPublishedDataCollectionJobTemplate('job', 'survey');
        // Create preconditions
        CreateJobTargetController controller = createPreconditionsForTargets(
                                                job.Id,
                                                'pTarget',
                                                'cName1',
                                                'mobileUsername',
                                                PerformanceTargetDO.TIMEFRAME_MONTHLY);

        Test.startTest();
        // Save
        controller.save();
        Test.stopTest();

        List<PerformanceTarget__c> pTs = [SELECT 
                                                DefaultValue__c, 
                                                Timeframe__c,
                                                Type__c
                                            FROM PerformanceTarget__c];
        List<AssignedTarget__c> aTs    = [SELECT TargetValue__c FROM AssignedTarget__c];

        // Check performance and assigned target creation
        system.assert(!pTs.isEmpty(), 'Cannot be empty since new Performance target was created');
        system.assertEquals(PerformanceTargetDO.TYPE_JOB_TARGET, 
                pTs[0].Type__c, 
                'The type should be job target');
        system.assert(!aTs.isEmpty(), 'Cannot be empty since new Assigned target was created');
        // Check timeframe
        system.assertEquals(PerformanceTargetDO.TIMEFRAME_MONTHLY, pTs[0].Timeframe__c, 'Timeframe must be monthly');
        // Check Target, and Default value is correctly saved on DB
        system.assertEquals(70, Integer.ValueOf(aTs[0].TargetValue__c), 'Target value must be 70 as is set');
        system.assertEquals(50, Integer.ValueOf(pTs[0].DefaultValue__c), 'Default value was set as 50');
    }

    // Job Targets cannot be created without a name
    static testMethod void performanceTargetWithoutName() {
        // Create published job
        JobTemplate__c job = TestUtils.createPublishedDataCollectionJobTemplate('job', 'survey');
        // Create preconditions
        CreateJobTargetController controller = createPreconditionsForTargets(
                                                job.Id,
                                                null,
                                                'cName1',
                                                'mobileUsername',
                                                PerformanceTargetDO.TIMEFRAME_WEEKLY);

        Test.startTest();
        // Save
        controller.save();
        Test.stopTest();

        // Check record was not saved, and page has an error message
        system.assert(!Apexpages.getMessages().isEmpty(),
                        'Should have complained that name is required for performance targets');
        system.assert([SELECT Name FROM PerformanceTarget__c].isEmpty(),
                        'Cannot have a record in DB since performance target name is required');
    }

    // Job Targets cannot be created without a job selected
    static testMethod void performanceTargetWithoutJob() {
        // Create preconditions
        CreateJobTargetController controller = createPreconditionsForTargets(
                                                null,
                                                'pTarget',
                                                'cName1',
                                                'mobileUsername',
                                                PerformanceTargetDO.TIMEFRAME_MONTHLY);

        Test.startTest();
        // Save
        controller.save();
        Test.stopTest();

        // Check record was not saved, and page has an error message
        system.assert(!Apexpages.getMessages().isEmpty(),
                        'Should have complained that job is required for performance targets');
        system.assert([SELECT Name FROM PerformanceTarget__c].isEmpty(),
                        'Cannot have a record in DB since performance target must have a job related');
    }

    // Cannot create a new performance target with same name as another already saved
    static testMethod void performanceTargetRepeatedName() {
        // Create published job
        JobTemplate__c job = TestUtils.createPublishedDataCollectionJobTemplate('job', 'survey');
        // Create preconditions
        CreateJobTargetController controller = createPreconditionsForTargets(
                                                job.Id,
                                                'pTarget',
                                                'cName1',
                                                'mobileUsername1',
                                                PerformanceTargetDO.TIMEFRAME_MONTHLY);
        // Save first performance target
        controller.save();
        // Create published job
        JobTemplate__c job2 = TestUtils.createPublishedDataCollectionJobTemplate('job2', 'survey2');
        // Create another performance target with same name
        controller = createPreconditionsForTargets(
                        job2.Id,
                        'pTarget',
                        'cName2',
                        'mobileUsername2',
                        PerformanceTargetDO.TIMEFRAME_WEEKLY);

        Test.startTest();
        controller.save();
        Test.stopTest();

        // Check record was not saved, and page has an error message
        system.assert(!Apexpages.getMessages().isEmpty(),
                        'Should have complained that name is unique for performance targets');
        system.assert([SELECT Name FROM PerformanceTarget__c].size() == 1,
                        'Must have just 1 record in DB since performance target name is unique');
    }

    // Edit performance target and save
    static testMethod void performanceTargetEdition() {
        // Create published job
        JobTemplate__c job = TestUtils.createPublishedDataCollectionJobTemplate('job', 'survey');
        // Create preconditions to insert
        CreateJobTargetController controller = createPreconditionsForTargets(
                                                job.Id,
                                                'pTarget',
                                                'cName1',
                                                'mobileUsername1',
                                                PerformanceTargetDO.TIMEFRAME_MONTHLY);
        // Save
        controller.save();

        PerformanceTarget__c pT = [SELECT
                                        Id,
                                        EndDate__c,
                                        DefaultValue__c,
                                        (SELECT
                                            PerformanceTarget__r.DefaultValue__c,
                                            TargetValue__c,
                                            Contact__c
                                        FROM
                                            Assigned_Targets__r
                                        WHERE
                                            EndDate__c = :controller.performanceTarget.EndDate__c)
                                    FROM
                                        PerformanceTarget__c
                                    WHERE
                                        Name = 'pTarget'];

        // Create preconditions to edit
        controller = createPreconditionsForTargetsEdition(pT);

        Test.startTest();
        // Save
        controller.save();
        Test.stopTest();

        // Check Target, and Default value is correctly saved on DB after edition
        system.assertEquals(120, Integer.ValueOf([SELECT
                                                        TargetValue__c
                                                    FROM
                                                        AssignedTarget__c LIMIT 1].TargetValue__c),
                                'Target value must be 120 after edition');

        system.assertEquals(200, Integer.ValueOf([SELECT
                                                        DefaultValue__c
                                                    FROM
                                                        PerformanceTarget__c LIMIT 1].DefaultValue__c),
                                'Default value must be 200 after edition');
    }

    /**
    *  Edit performance target with one unexisting assigned target' for a mobile user
    */
    static testMethod void performanceTargetUpdateAndCreate() {

        // Create published job
        JobTemplate__c job = TestUtils.createPublishedDataCollectionJobTemplate('job', 'survey');
        // Create preconditions to insert
        CreateJobTargetController controller = createPreconditionsForTargets(
                                                job.Id,
                                                'pTarget',
                                                'cNameCreateUpdate',
                                                'mobileUsername1',
                                                PerformanceTargetDO.TIMEFRAME_MONTHLY);

        //save and get the contact id
        controller.save();
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'cNameCreateUpdate' LIMIT 1];

        //remove target from contact
         delete [SELECT Id FROM assignedTarget__c
                 WHERE Contact__c = :contact.Id LIMIT 1];


        PerformanceTarget__c pT = [SELECT
                                        Id,
                                        EndDate__c,
                                        DefaultValue__c,
                                        (SELECT
                                            PerformanceTarget__r.DefaultValue__c,
                                            TargetValue__c,
                                            Contact__c
                                        FROM
                                            Assigned_Targets__r
                                        WHERE
                                            EndDate__c = :controller.performanceTarget.EndDate__c)
                                    FROM
                                        PerformanceTarget__c
                                    WHERE
                                        Name = 'pTarget'];

        // Create preconditions to edit
        controller = createPreconditionsForTargetsEdition(pT);

        Test.startTest();
        // Save
        controller.save();
        Test.stopTest();

        // Check Target, and Default value is correctly saved on DB after edition
        system.assertEquals(120, Integer.ValueOf([SELECT
                                                        TargetValue__c
                                                    FROM
                                                        AssignedTarget__c LIMIT 1].TargetValue__c),
                                'Target value must be 120 after edition');

        system.assertEquals(200, Integer.ValueOf([SELECT
                                                        DefaultValue__c
                                                    FROM
                                                        PerformanceTarget__c LIMIT 1].DefaultValue__c),
                                'Default value must be 200 after edition');
        system.assertEquals(1, [SELECT Id
                                FROM assignedTarget__c
                                WHERE Contact__c = :contact.Id].size());
    }

    /**
     * Preconditions to edit a performance target
     *
     * @param performanceTarget - Performance target to edit
     *
     * @return controller - Instance of controller
     */
    private static CreateJobTargetController createPreconditionsForTargetsEdition(PerformanceTarget__c performanceTarget) {

        ApexPages.StandardController stdController = new ApexPages.StandardController(performanceTarget);
        CreateJobTargetController controller = new CreateJobTargetController(stdController);

        // Set new target values for all assigned targets for the current job target
        for(AssignedTargetDO aT : controller.assignedTargetWrappers) {
            aT.targetValue = 120;
        }

        // Set new default value for the current job target
        controller.performanceTarget.DefaultValue__c = 200;

        return controller;
    }



    /**
     * Create all preconditions for performance targets test
     *
     * @param jobId - Job template id related
     * @param pname - Performance target name
     * @param cname - Contact name
     * @param mobileUserName - Username of mobile user
     * @param timeframe - Timeframe
     *
     * @return controller - Instance of controller
     **/
    private static CreateJobTargetController createPreconditionsForTargets(
        String jobId, String pname, String cname, String mobileUsername, String timeframe) {
        // Create Partner Account
        List<Account> partnerAccount = TestUtils.createAccounts(1);
        System.assert(partnerAccount.size() == 1, 'Account not created properly');

        // Create Partner User
        partnerUser1 = TestUtils.createPartnerUser(
            partnerAccount[0],
            cname,
            true
        );

        // Create performance target
        PerformanceTarget__c performanceTarget = PerformanceTargetDOTest.createJobTargetRecord(
            pname,
            jobId,
            50,
            timeframe,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );


        ApexPages.StandardController stdController = new ApexPages.StandardController(performanceTarget);
        CreateJobTargetController controller = new CreateJobTargetController(stdController);

        // Set target values for all assigned targets for the current job target
        for(AssignedTargetDO aT : controller.assignedTargetWrappers) {
            aT.targetValue = 70;
        }

        return controller;
    }

    /**
     * Test to ensure the mobile users related to private contacts are not loaded
     * along with partner users
     */
    static testMethod void testPrivateContacts() {
        Contact privateContact = TestUtils.createContact('PrivateContact');

        // Create mobile users for the contact
        TestUtils.createMobileUser(
            privateContact,
            'user1',
            'pass',
            MobileUserDO.STATUS_ACTIVE
        );

        // Create published job
        JobTemplate__c job = TestUtils.createPublishedDataCollectionJobTemplate('job', 'survey');

        Test.startTest();
        // Create preconditions and initialize the controller
        CreateJobTargetController controller = createPreconditionsForTargets(
            job.Id,
            'pTarget',
            'cName1',
            'mobileUsername',
            PerformanceTargetDO.TIMEFRAME_WEEKLY
        );
        Test.stopTest();

        Map<Id, User> activePartnerUsers = 
            new Map<Id, User>([
                SELECT
                    Id
                FROM
                    User
                WHERE
                    UserType = 'PowerPartner'
                AND
                    Id NOT IN (:partnerUser1.Id)
                AND
                    isActive = true
        ]);
        
        // Check the amount of wrappers
        System.assertEquals(
            1,
            controller.assignedTargetWrappers.size() - activePartnerUsers.size()
        );
    }
}
