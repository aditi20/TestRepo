/**
 * Class to handle the tests for Performance management
 * Contains EndToEndTestWrapper class that can be used to implement tests for PerformanceManagement
 * Allows for:
 *    Easy set up of preconditions including:
 *        Surveyor
 *        PerformanceIndicators
 *        JobTargets
 *        Creating AssignedTargets for the PerformanceTargets
 *        JobActivities
 *    Set up of RestContext for both /performance/ and /jobs
 *    Validates response to /performance
 * This class uses the other inner classes to this file:
 *    PerformanceTargetWrapper - Contains information about a PerformanceTarget needed for tests
 *    JobTemplateWrapper       - Contains information about a JobTemplate needed for tests
 *                               Includes TaskTemplates
 *    AssignedTargetWrapper    - Maps Date to AssignedTarget for easy access to AssignedTarget
 *                               based on StartDate
 *
 * @author - Owen Davies (odavies@grameenfoundation.org)
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved.
 */
@isTest
public with sharing class PerformanceManagementTest {

    static final String LASTNAME = 'last';
    static final String USERNAME = 'user';
    static final String PASSWORD = 'pass';


    /**
     * Test getting AssignedTargets when no previous assigned targets and all PerformanceTarget__c are open
     */
    static testMethod void testGettingCurrentAssignedTargetsBasic() {

        EndToEndTestWrapper endToEndTestWrapper = new EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        endToEndTestWrapper.initPerformanceRequest(null);
        endToEndTestWrapper.initJobPerformanceTargetWrappers(PerformanceTargetDO.TIMEFRAME_WEEKLY, 3, '');
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY, 3, '', null, null, null, null, null, null
        );
        insert endToEndTestWrapper.createAssignedTargetsForGivenDate(Date.today(), 10, null, 'ALL');

        // Get all the created Assigned Targets
        Map<Id, AssignedTarget__c> referenceAssignedTargets =
            new Map<Id, AssignedTarget__c>([SELECT Id, Contact__r.Name FROM AssignedTarget__c]);

        Test.startTest();
        System.runAs(endToEndTestWrapper.getPartnerUser()) {
            PerformanceManagementEndpoint.doGet();
        }
        Test.stopTest();
        PerformanceManagementLogic.PerformanceManagementResponse response =
            endToEndTestWrapper.validateRequest(RestContext.response.responseBody.toString());

        // Check the return AssignedTargets are correct
        endToEndTestWrapper.validatePerformanceResponse(response.getTargets(), 3, referenceAssignedTargets);
        endToEndTestWrapper.validatePerformanceResponse(response.getIndicators(), 3, referenceAssignedTargets);
    }

    /**
     * Test getting AssignedTargets for the current time period when there are previous AssignedTarget__c records
     */
    static testMethod void testGettingCurrentWhenPreviousExist() {

        EndToEndTestWrapper endToEndTestWrapper = new EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        endToEndTestWrapper.initPerformanceRequest(null);
        endToEndTestWrapper.initJobPerformanceTargetWrappers(PerformanceTargetDO.TIMEFRAME_WEEKLY, 3, '');
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY, 3, '', null, null, null, null, null, null
        );
        List<AssignedTarget__c> assignedTargets =
            endToEndTestWrapper.createAssignedTargetsForGivenDate(Date.today(), 10, null, 'ALL');
        assignedTargets.addAll(
            endToEndTestWrapper.createAssignedTargetsForGivenDate(
                Date.today().addDays(-8), 20, 50, 'ALL'
            )
        );
        insert assignedTargets;

        // Get all the created Assigned Targets
        Map<Id, AssignedTarget__c> referenceAssignedTargets =
            new Map<Id, AssignedTarget__c>([SELECT Id, Contact__r.Name FROM AssignedTarget__c]);

        Test.startTest();
        System.runAs(endToEndTestWrapper.getPartnerUser()) {
            PerformanceManagementEndpoint.doGet();
        }
        Test.stopTest();
        PerformanceManagementLogic.PerformanceManagementResponse response =
            endToEndTestWrapper.validateRequest(RestContext.response.responseBody.toString());

        // Check the return AssignedTargets are correct
        endToEndTestWrapper.validatePerformanceResponse(response.getTargets(), 3, referenceAssignedTargets);
        endToEndTestWrapper.validatePerformanceResponse(response.getIndicators(), 3, referenceAssignedTargets);
    }

    /**
     * Test when one of the PerformanceTarget__c are closed and there are previous AssignedTargets
     */
    static testMethod void testWithClosedPerformanceTarget() {

        EndToEndTestWrapper endToEndTestWrapper = new EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        endToEndTestWrapper.initPerformanceRequest(null);
        endToEndTestWrapper.initJobPerformanceTargetWrappers(PerformanceTargetDO.TIMEFRAME_WEEKLY, 3, '');
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY, 3, '', null, null, null, null, null, null
        );
        List<AssignedTarget__c> assignedTargets =
            endToEndTestWrapper.createAssignedTargetsForGivenDate(Date.today(), 10, null, 'ALL');
        assignedTargets.addAll(
            endToEndTestWrapper.createAssignedTargetsForGivenDate(
                Date.today().addDays(-8), 20, 50, 'ALL'
            )
        );
        insert assignedTargets;

        // Close the first Job Target and the first Performance Indicator
        endToEndTestWrapper.getPerformanceTargetWrapperByCreationIndex(0).closePerformanceTarget();
        endToEndTestWrapper.getPerformanceTargetWrapperByCreationIndex(3).closePerformanceTarget();

        // Get all the created Assigned Targets
        Map<Id, AssignedTarget__c> referenceAssignedTargets =
            new Map<Id, AssignedTarget__c>([SELECT Id, Contact__r.Name FROM AssignedTarget__c]);

        Test.startTest();
        System.runAs(endToEndTestWrapper.getPartnerUser()) {
            PerformanceManagementEndpoint.doGet();
        }
        Test.stopTest();
        PerformanceManagementLogic.PerformanceManagementResponse response =
            endToEndTestWrapper.validateRequest(RestContext.response.responseBody.toString());

        // Check the return AssignedTargets are correct
        endToEndTestWrapper.validatePerformanceResponse(response.getTargets(), 2, referenceAssignedTargets);
        endToEndTestWrapper.validatePerformanceResponse(response.getIndicators(), 2, referenceAssignedTargets);
    }

    /**
     * Test submitting a job activity and updating AssignedTargets for the current time period.
     * Where the AssignedTarget already exists
     * WEEKLY TimePeriod
     */
    static testMethod void testSubmittingJobActivitiesWhenAssignedTargetExistsWeekly() {

        // Create the End To End Test objects
        EndToEndTestWrapper endToEndTestWrapper = new EndToEndTestWrapper();

        // Create Partner User Surveyor
        endToEndTestWrapper.createPartnerSurveyor(true);

        // Retrieve Partner login Surveyor details
        TestUtils.partnerLoginDetails(endToEndTestWrapper.getSurveyor());
        endToEndTestWrapper.initJobsRequest();
        endToEndTestWrapper.initJobPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            2,
            ''
        );
        insert endToEndTestWrapper.createDefaultAssignedTargets();

        // Assert that the AssignedTargets have been created for this time period
        Map<Id, Map<Date, AssignedTarget__c>> initialAssignedTargets =
            endToEndTestWrapper.getAllAssignedTargets();
        System.assertEquals(
            endToEndTestWrapper.getPerformanceTargets().keySet().size(),
            initialAssignedTargets.keySet().size(),
            'Initial target maps should be the same size as the number of performance targets'
        );

        // Create the job activities for the request. Should be 1 per target
        for (Id performanceTarget : endToEndTestWrapper.getPerformanceTargets().keySet()) {
            endToEndTestWrapper.createJobActivityForPerformanceTarget(
                performanceTarget,
                Date.today()
            );
        }

        User partnerLoginUser = [
            SELECT
                Id,
                ContactId,
                Contact.Name
            FROM
                User
            WHERE
                Contact.Name = :LASTNAME
        ];
        System.runAs(partnerLoginUser) {

            // Submit the request and validate the response
            endToEndTestWrapper.addJsonToJobsRequest();
            endToEndTestWrapper.sendJobsRequest();

            // Get the assigned targets for the performance targets for the current time period
            Map<Id, Map<Date, AssignedTarget__c>> finalAssignedTargets =
                endToEndTestWrapper.getAllAssignedTargets();
            System.assertEquals(
                endToEndTestWrapper.getPerformanceTargets().keySet().size(),
                finalAssignedTargets.keySet().size(),
                'Should have the same number of assigned target maps as there are test PerformanceTargets'
            );

            // Validate each of the assigned targets
            for (Id performanceTargetId : endToEndTestWrapper.getPerformanceTargets().keySet()) {
                Map<Date, AssignedTarget__c>  assignedTargetsForOnePT =
                    finalAssignedTargets.get(performanceTargetId);
                System.assertEquals(1, assignedTargetsForOnePT.keyset().size());
                AssignedTarget__c updatedAssignedTarget = assignedTargetsForOnePT.get(
                    PerformanceTargetDO.getStartOfCurrentTimePeriod(
                        Date.today(),
                        PerformanceTargetDO.TIMEFRAME_WEEKLY
                    )
                );
                System.assert(
                    updatedAssignedTarget != null,
                    'AssignedTarget should be for current time period'
                );
                System.assertEquals(1, updatedAssignedTarget.ActualValue__c);
                System.assertEquals(
                    endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().Name,
                    updatedAssignedTarget.PerformanceTarget__r.Name
                );
                System.assertEquals(
                    endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().DefaultValue__c,
                    updatedAssignedTarget.TargetValue__c
                );
                System.assertEquals(
                    endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().Status__c,
                    updatedAssignedTarget.Status__c
                );
                System.assertEquals(
                    endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().StartDate__c,
                    updatedAssignedTarget.StartDate__c
                );
                System.assertEquals(
                    endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().EndDate__c,
                    updatedAssignedTarget.EndDate__c
                );
            }
        }
    }

    /**
     * Test that when JobFiltering is on the correct PerformanceTargets are filtered
     */
    static testMethod void testJobFilteringOn() {

        String correctTargetPrefix = 'user1';
        String jobTargetName = 'JobTarget';
        String indicatorTargetName = 'IndicatorTarget';

        // Create 2 Users
        Profile adminProfile = TestUtils.getSysAdminProfile();
        User user1 = TestUtils.createUser(adminProfile.Id);
        User user2 = TestUtils.createUser(adminProfile.Id);

        // Create 2 job templates
        JobTemplate__c user1Job = TestUtils.createPublishedDataCollectionJobTemplate(
            'User1Job',
            'survey 1'
        );
        JobTemplate__c user2Job = TestUtils.createPublishedDataCollectionJobTemplate(
            'User2Job',
            'survey 2'
        );

        // Update the ownership of the jobs
        user1Job.OwnerId = user1.Id;
        user2Job.OwnerId = user2.Id;
        update new List<JobTemplate__c>{user1Job, user2Job};

        // Create 2 Performance Targets
        PerformanceTarget__c user1JobTarget = PerformanceTargetDOTest.createJobTargetRecord(
            correctTargetPrefix + jobTargetName,
            user1Job.Id,
            0,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        PerformanceTarget__c user2JobTarget = PerformanceTargetDOTest.createJobTargetRecord(
            jobTargetName,
            user2Job.Id,
            0,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        PerformanceTarget__c user1IndicatorTarget =
            PerformanceTargetDOTest.createPerformanceIndicatorRecord(
                correctTargetPrefix + indicatorTargetName,
                50,
                PerformanceTargetDO.TIMEFRAME_WEEKLY,
                Date.today(),
                Date.today(),
                'Contact',
                PerformanceTargetDO.AGGREGATION_OPERATION_COUNT,
                '',
                'ReportsTo'
            );
        PerformanceTarget__c user2IndicatorTarget =
            PerformanceTargetDOTest.createPerformanceIndicatorRecord(
                indicatorTargetName,
                50,
                PerformanceTargetDO.TIMEFRAME_WEEKLY,
                Date.today(),
                Date.today(),
                'Contact',
                PerformanceTargetDO.AGGREGATION_OPERATION_COUNT,
                '',
                'ReportsTo'
            );
        insert new List<PerformanceTarget__c>{
            user1JobTarget,
            user2JobTarget,
            user1IndicatorTarget,
            user2IndicatorTarget
        };

        // Update the ownership of the targets
        user1JobTarget.OwnerId = user1.Id;
        user2JobTarget.OwnerId = user2.Id;
        user1IndicatorTarget.OwnerId = user1.Id;
        user2IndicatorTarget.OwnerId = user2.Id;
        update new List<PerformanceTarget__c>{
            user1JobTarget,
            user2JobTarget,
            user1IndicatorTarget,
            user2IndicatorTarget
        };

        // Create a Mobile User and update owner
        EndToEndTestWrapper endToEndTestWrapper = new EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        endToEndTestWrapper.getSurveyor().theContact.OwnerId = user1.Id;
        update endToEndTestWrapper.getSurveyor().theContact;
        endToEndTestWrapper.initJobsRequest();

        // Force trigger to create assigned targets to run
        UserTH.setSkipValidation(false);
        UserTH.triggerHandler(
            false,
            true,
            true,
            false,
            false,
            new List<User>{endToEndTestWrapper.getSurveyor().partnerUser},
            new Map<Id, User>{}
        );

        // Turn ON job filtering
        ApplicationSettingsUtils.setJobFilterSetting(ApplicationSettingsUtils.JOBS_FILTER_SF_USER);

        // Force the @future job that creates the Assigned Targets to complete
        Test.startTest();
        Test.stopTest();
        System.runAs(endToEndTestWrapper.getPartnerUser()) {
            PerformanceManagementEndpoint.doGet();
        }

        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
        PerformanceManagementLogic.PerformanceManagementResponse response =
            (PerformanceManagementLogic.PerformanceManagementResponse)JSON.deserialize(
                RestContext.response.responseBody.toString(),
                PerformanceManagementLogic.PerformanceManagementResponse.class
            );

        System.assertEquals(1, response.getTargets().size());
        System.assertEquals(
            correctTargetPrefix + jobTargetName,
            response.getTargets()[0].getTargetName()
        );
        System.assertEquals(1, response.getIndicators().size());
        System.assertEquals(
            correctTargetPrefix + indicatorTargetName,
            response.getIndicators()[0].getTargetName()
        );
    }

    /**
     * Test submitting a job activity and updating AssignedTargets for the current time period.
     * Where the AssignedTarget doesn't already exist
     * WEEKLY TimePeriod
     */
    static testMethod void testAssignedTargetsCreatedWhenJobActivitySubmitted() {

        // Create the End To End Test objects
        EndToEndTestWrapper endToEndTestWrapper = new EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        endToEndTestWrapper.initJobsRequest();
        endToEndTestWrapper.initJobPerformanceTargetWrappers(PerformanceTargetDO.TIMEFRAME_WEEKLY, 2, '');

        // Assert that the AssignedTargets have not been created for this time period
        Map<Id, Map<Date, AssignedTarget__c>> initialAssignedTargets = endToEndTestWrapper.getAllAssignedTargets();
        System.assertEquals(
            0,
            initialAssignedTargets.keySet().size(),
            'There should be no initial assigned targets set'
        );

        // Create the job activities for the request. Should be 1 per target
        for (Id performanceTarget : endToEndTestWrapper.getPerformanceTargets().keySet()) {
            endToEndTestWrapper.createJobActivityForPerformanceTarget(performanceTarget, Date.today());
        }

        // Submit the request and validate the response
        endToEndTestWrapper.addJsonToJobsRequest();
        endToEndTestWrapper.sendJobsRequest();

        // Get the assigned targets for the performance targets for the current time period
        Map<Id, Map<Date, AssignedTarget__c>> finalAssignedTargets = endToEndTestWrapper.getAllAssignedTargets();
        System.assertEquals(
            endToEndTestWrapper.getPerformanceTargets().keySet().size(),
            finalAssignedTargets.keySet().size(),
            'Should have the same number of assigned target maps as there are test PerformanceTargets'
        );

        // Validate each of the assigned targets
        for (Id performanceTargetId : endToEndTestWrapper.getPerformanceTargets().keySet()) {
            Map<Date, AssignedTarget__c>  assignedTargetsForOnePT = finalAssignedTargets.get(performanceTargetId);
            System.assertEquals(1, assignedTargetsForOnePT.keyset().size());
            AssignedTarget__c updatedAssignedTarget = assignedTargetsForOnePT.get(
                PerformanceTargetDO.getStartOfCurrentTimePeriod(Date.today(), PerformanceTargetDO.TIMEFRAME_WEEKLY)
            );
            System.assert(updatedAssignedTarget != null, 'AssignedTarget should be for current time period');
            System.assertEquals(1, updatedAssignedTarget.ActualValue__c);
            System.assertEquals(
                endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().Name,
                updatedAssignedTarget.PerformanceTarget__r.Name
            );
            System.assertEquals(
                endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().DefaultValue__c,
                updatedAssignedTarget.TargetValue__c
            );
            System.assertEquals(
                endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().Status__c,
                updatedAssignedTarget.Status__c
            );
            System.assertEquals(
                endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().StartDate__c,
                updatedAssignedTarget.StartDate__c
            );
            System.assertEquals(
                endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().EndDate__c,
                updatedAssignedTarget.EndDate__c
            );
        }
    }

    /**
     * Test submitting a job activity and updating AssignedTargets for a previous time period.
     * Where the AssignedTarget already exists
     * WEEKLY TimePeriod
     */
    static testMethod void testPreviousTimePeriodUpdates() {

        // Set the start date back a week
        Date startDate = Date.today().addDays(-7);

        // Create the End To End Test objects
        EndToEndTestWrapper endToEndTestWrapper = new EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        endToEndTestWrapper.initJobsRequest();
        endToEndTestWrapper.initJobPerformanceTargetWrappers(PerformanceTargetDO.TIMEFRAME_WEEKLY, 2, '');
        insert endToEndTestWrapper.createAssignedTargetsForGivenDate(startDate, 0, null, 'ALL');

        // Assert that the AssignedTargets have been created for this time period
        Map<Id, Map<Date, AssignedTarget__c>> initialAssignedTargets = endToEndTestWrapper.getAllAssignedTargets();
        System.assertEquals(
            endToEndTestWrapper.getPerformanceTargets().keySet().size(),
            initialAssignedTargets.keySet().size(),
            'Initial target maps should be the same size as the number of performance targets'
        );

        // Create the job activities for the request. Should be 1 per target
        for (Id performanceTarget : endToEndTestWrapper.getPerformanceTargets().keySet()) {
            endToEndTestWrapper.createJobActivityForPerformanceTarget(performanceTarget, startDate);
        }

        // Submit the request and validate the response
        endToEndTestWrapper.addJsonToJobsRequest();
        endToEndTestWrapper.sendJobsRequest();

        // Get the assigned targets for the performance targets for the current time period
        Map<Id, Map<Date, AssignedTarget__c>> finalAssignedTargets = endToEndTestWrapper.getAllAssignedTargets();
        System.assertEquals(
            endToEndTestWrapper.getPerformanceTargets().keySet().size(),
            finalAssignedTargets.keySet().size(),
            'Should have the same number of assigned target maps as there are test PerformanceTargets'
        );

        // Validate each of the assigned targets
        for (Id performanceTargetId : endToEndTestWrapper.getPerformanceTargets().keySet()) {
            Map<Date, AssignedTarget__c>  assignedTargetsForOnePT = finalAssignedTargets.get(performanceTargetId);
            System.assertEquals(1, assignedTargetsForOnePT.keyset().size());
            AssignedTarget__c updatedAssignedTarget = assignedTargetsForOnePT.get(
                PerformanceTargetDO.getStartOfCurrentTimePeriod(startDate, PerformanceTargetDO.TIMEFRAME_WEEKLY)
            );
            System.assert(updatedAssignedTarget != null, 'AssignedTarget should be found');
            System.assertEquals(1, updatedAssignedTarget.ActualValue__c);
            System.assertEquals(
                endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().Name,
                updatedAssignedTarget.PerformanceTarget__r.Name
            );
            System.assertEquals(
                endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().DefaultValue__c,
                updatedAssignedTarget.TargetValue__c
            );
            System.assertEquals(AssignedTargetDO.STATUS_CLOSED, updatedAssignedTarget.Status__c);
            System.assertEquals(
                PerformanceTargetDO.getStartOfCurrentTimePeriod(startDate, updatedAssignedTarget.PerformanceTarget__r.Timeframe__c),
                updatedAssignedTarget.StartDate__c
            );
            System.assertEquals(
                PerformanceTargetDO.getEndOfCurrentTimePeriod(startDate, updatedAssignedTarget.PerformanceTarget__r.Timeframe__c),
                updatedAssignedTarget.EndDate__c
            );
        }
    }

    /**
     * Test submitting a job activity and updating AssignedTargets for a previous time period.
     * Where the AssignedTarget doesn't already exist
     * WEEKLY TimePeriod
     */
    static testMethod void testPreviousTimePeriodCreates() {

        // Set the start date back a week
        Date startDate = Date.today().addDays(-7);

        // Create the End To End Test objects
        EndToEndTestWrapper endToEndTestWrapper = new EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        endToEndTestWrapper.initJobsRequest();
        endToEndTestWrapper.initJobPerformanceTargetWrappers(PerformanceTargetDO.TIMEFRAME_WEEKLY, 2, '');

        // Assert that the AssignedTargets have not been created for this time period
        Map<Id, Map<Date, AssignedTarget__c>> initialAssignedTargets =
            endToEndTestWrapper.getAllAssignedTargets();
        System.assertEquals(
            0,
            initialAssignedTargets.keySet().size(),
            'There should be no initial assigned targets set'
        );

        // Create the job activities for the request. Should be 1 per target
        for (Id performanceTarget : endToEndTestWrapper.getPerformanceTargets().keySet()) {
            endToEndTestWrapper.createJobActivityForPerformanceTarget(performanceTarget, startDate);
        }

        // Submit the request and validate the response
        endToEndTestWrapper.addJsonToJobsRequest();
        endToEndTestWrapper.sendJobsRequest();

        // Get the assigned targets for the performance targets for the current time period
        Map<Id, Map<Date, AssignedTarget__c>> finalAssignedTargets =
            endToEndTestWrapper.getAllAssignedTargets();
        System.assertEquals(
            endToEndTestWrapper.getPerformanceTargets().keySet().size(),
            finalAssignedTargets.keySet().size(),
            'Should have the same number of assigned target maps as there are test PerformanceTargets'
        );

        // Validate each of the assigned targets
        for (Id performanceTargetId : endToEndTestWrapper.getPerformanceTargets().keySet()) {
            Map<Date, AssignedTarget__c>  assignedTargetsForOnePT =
                finalAssignedTargets.get(performanceTargetId);
            System.assertEquals(1, assignedTargetsForOnePT.keyset().size());
            AssignedTarget__c updatedAssignedTarget = assignedTargetsForOnePT.get(
                PerformanceTargetDO.getStartOfCurrentTimePeriod(
                    startDate,
                    PerformanceTargetDO.TIMEFRAME_WEEKLY
                )
            );
            System.assert(updatedAssignedTarget != null, 'AssignedTarget should be found');
            System.assertEquals(1, updatedAssignedTarget.ActualValue__c);
            System.assertEquals(
                endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().Name,
                updatedAssignedTarget.PerformanceTarget__r.Name
            );
            System.assertEquals(
                endToEndTestWrapper.getPerformanceTargets().get(performanceTargetId).getPerformanceTarget().DefaultValue__c,
                updatedAssignedTarget.TargetValue__c
            );
            System.assertEquals(AssignedTargetDO.STATUS_CLOSED, updatedAssignedTarget.Status__c);
            System.assertEquals(
                PerformanceTargetDO.getStartOfCurrentTimePeriod(startDate, updatedAssignedTarget.PerformanceTarget__r.Timeframe__c),
                updatedAssignedTarget.StartDate__c
            );
            System.assertEquals(
                PerformanceTargetDO.getEndOfCurrentTimePeriod(
                    startDate,
                    updatedAssignedTarget.PerformanceTarget__r.Timeframe__c
                ),
                updatedAssignedTarget.EndDate__c
            );
        }
    }


    /**
     * Test the name update of a target is sent to the mobile
     */
    static testMethod void testTargetNameUpdate() {
        // Given a performance target previously synced
        PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper =
            new PerformanceManagementTest.EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        endToEndTestWrapper.initPerformanceRequest(null);
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            1,
            'Some name',
            null,
            null,
            null,
            null,
            null,
            null
        );
        PerformanceTarget__c performanceTarget = endToEndTestWrapper
            .getPerformanceTargetWrapperByCreationIndex(0).getPerformanceTarget();
        insert endToEndTestWrapper.createAssignedTargetsForGivenDate(
            Date.today(),
            10,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY
        );
        System.runAs(endToEndTestWrapper.getPartnerUser()) {
            PerformanceManagementEndpoint.doGet();
        }

        Test.startTest();
        // When the name is updated and sync take place
        String newName = 'New name';
        performanceTarget.Name = newName;
        update performanceTarget;
        System.runAs(endToEndTestWrapper.getPartnerUser()) {
            PerformanceManagementEndpoint.doGet();
        }
        Test.stopTest();

        // Then the response send the new name
        PerformanceManagementLogic.PerformanceManagementResponse response =
            endToEndTestWrapper.validateRequest(RestContext.response.responseBody.toString());
        System.assertEquals(newName, response.getIndicators()[0].getTargetName());
    }

    /**
     * Test method to check CRUD-FLS permission check while processing Performance Endpoint request
     */
    static testMethod void testDoGetPermissionDenied() {

        EndToEndTestWrapper endToEndTestWrapper = new EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        endToEndTestWrapper.initPerformanceRequest(null);

        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        System.RunAs(TestUtils.createChatterExternalUser()) {
            DescribeHandler.resetDescribeHandler();
            Test.startTest();
            PerformanceManagementEndpoint.doGet();
            Test.stopTest();
        }

        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        System.assertEquals(1, errors.getErrors().size());
        System.assertEquals(C.HTTP_INTERNAL_SERVER_ERROR, RestContext.response.statusCode);
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assert(
            RestContext.response.responseBody.toString().contains(System.Label.ERR_PERMISSIONS)
        );
        System.assertEquals(
            ErrorHandlingRest.ERR_CODE_CRUD_FLS, errorMessages[0].getErrorCode()
        );
        System.assertEquals(
            ErrorHandlingRest.CRUD_FLS, errorMessages[0].getErrorTranslationCode()
        );
    }

    /**
     * Test submitting muliple JobActivites for multiple JobTargets over current and previous time periods
     */
    public class PerformanceTargetWrapper {

        private PerformanceTarget__c performanceTarget;
        private Map<Id, AssignedTargetWrapper> contactAssignedTargets;
        private JobTemplateWrapper jobTemplateWrapper;

        public PerformanceTargetWrapper(PerformanceTarget__c performanceTarget) {
            this.performanceTarget = performanceTarget;
            this.contactAssignedTargets = new Map<Id, AssignedTargetWrapper>();
        }

        public PerformanceTargetWrapper(PerformanceTarget__c performanceTarget, JobTemplate__c jobTemplate) {
            this.performanceTarget = performanceTarget;
            this.jobTemplateWrapper = new jobTemplateWrapper(jobTemplate);
            this.contactAssignedTargets = new Map<Id, AssignedTargetWrapper>();
        }

        /**
         * Add an AssignedTarget__c for the current time period
         *
         * @param actualValue - The actual value for the AssignedTarget
         * @param contactId   - The Id for the contact that the AssignedTarget is for
         */
        public void addCurrentDefaultAssignedTargetWrapper(
                Integer actualValue,
                Id contactId
        ) {
            AssignedTargetWrapper assignedTargetWrapper = this.contactAssignedTargets.get(contactId);
            if (assignedTargetWrapper == null) {
                assignedTargetWrapper = new AssignedTargetWrapper();
            }
            AssignedTarget__c assignedTargetSObject = AssignedTargetDO.createDefaultActiveAssignedTarget(
                this.performanceTarget,
                contactId,
                actualValue
            );
            insert assignedTargetSObject;
            assignedTargetWrapper.addAssignedTargetForDate(this.performanceTarget.StartDate__c, assignedTargetSObject);
            this.contactAssignedTargets.put(contactId, assignedTargetWrapper);
        }

        /**
         * Close the PerformanceTarget__c record
         */
        public void closePerformanceTarget() {

            this.performanceTarget.Status__c = PerformanceTargetDO.STATUS_CLOSED;
            update this.performanceTarget;
        }

        /**
         * Add an AssignedTarget__c for any time period
         *
         * @param actualValue - The actual value for the AssignedTarget
         * @param contactId   - The Id for the contact that the AssignedTarget is for
         * @param targetValue - The target for the AssignedTarget
         * @param startDate   - The start date for the AssignedTarget
         * @param endDate     - The end date for the AssignedTarget
         * @param status      - The status for the AssignedTarget
         */
        public void addAssignedTargetWrapper(
                Integer actualValue,
                Id contactId,
                Integer targetValue,
                Date startDate,
                Date endDate,
                String status
        ) {
            AssignedTargetWrapper assignedTargetWrapper = this.contactAssignedTargets.get(contactId);
            if (assignedTargetWrapper == null) {
                assignedTargetWrapper = new AssignedTargetWrapper();
            }
            AssignedTarget__c assignedTargetSObject = AssignedTargetDO.createAssignedTarget(
                this.performanceTarget,
                contactId,
                actualValue,
                targetValue,
                startDate,
                endDate,
                status
            );
            insert assignedTargetSObject;
            assignedTargetWrapper.addAssignedTargetForDate(startDate, assignedTargetSObject);
            this.contactAssignedTargets.put(contactId, assignedTargetWrapper);
        }

        /**
         * Get the AssignedTargetWrapper for a give contact on a given date
         *
         * @param contactId - The Contact.Id being searched for
         * @param startDate - The date the assigned target started on as this is the key in the
         *                      AssignedTargetWrapper.assignedTargets Map
         */
        public AssignedTarget__c getSpecificAssignedTarget(Id contactId, Date startDate) {
            return this.contactAssignedTargets.get(contactId).getAssignedTarget(startDate);
        }

        /**
         * Getter method for the jobTemplateWrapper
         *
         * @return - The JobTemplateWrapper
         */
        public JobTemplateWrapper getJobTemplateWrapper() {
            return this.jobTemplateWrapper;
        }

        /**
         * Get the PerformanceTarget__c
         */
        public PerformanceTarget__c getPerformanceTarget() {
            return this.performanceTarget;
        }

        /**
         * Create default AssignedTargets for the current time period
         */
        public List<AssignedTarget__c> createDefaultAssignedTargets() {
            return AssignedTargetDO.createDefaultAssignedTargetsForAllMobileUsers(this.performanceTarget);
        }
    }

    public class JobTemplateWrapper {

        public JobTemplate__c jobTemplate;
        public Map<Decimal, TaskTemplate__c> taskTemplates;

        public JobTemplateWrapper(JobTemplate__c jobTemplate) {
            this.jobTemplate = jobTemplate;
            this.taskTemplates = new Map<Decimal, TaskTemplate__c>();
        }

        /**
         * Adds a task template to the wrapper.
         *
         * @param taskTemplate - The task template being added
         */
        public void addTaskTemplate(TaskTemplate__c taskTemplate) {
            this.taskTemplates.put(taskTemplate.Position__c, taskTemplate);
        }

        /**
         * Getter for all the task templates
         *
         * @return - All the task templates
         */
        public List<TaskTemplate__c> getAllTaskTemplates() {
            return this.taskTemplates.values();
        }

    }

    public class AssignedTargetWrapper {

        private Map<Date, AssignedTarget__c> assignedTargets;

        /**
         * Constructor
         */
        public AssignedTargetWrapper() {
            this.assignedTargets = new Map<Date, AssignedTarget__c>();
        }

        /**
         * Add an assigned target for a given date
         *
         * @param startDate      - The date the assigned target started on as this is the key in the
         *                            AssignedTargetWrapper.assignedTargets Map
         * @param assignedTarget - The AssignedTarget__c being added
         */
        public void addAssignedTargetForDate(Date startDate, AssignedTarget__c assignedTarget) {
            this.assignedTargets.put(startDate, assignedTarget);
        }

        /**
         * Get an assigned target for a given date
         */
        public AssignedTarget__c getAssignedTarget(Date startDate) {
            return this.assignedTargets.get(startDate);
        }
    }

    /**
     * Class that sets up full test data for the Testing of submitting Jobs and testing
     * the targets for the jobs
     */
    public class EndToEndTestWrapper {

        // Map of the performance target wrappers with the PerformanceTarget__c.Id as the key
        private Map<Id, PerformanceTargetWrapper> performanceTargetsById;

        // Map the Name of the PerformanceTarget__c to it's Id
        private Map<String, Id> performanceTargetsByName;

        // A list of the Ids of the PerformanceTarget__c in the order they were created
        private List<Id> performanceTargetCreationOrder;

        private TestUtils.Surveyor surveyor;
        private List<FFSubmitJobsLogic.Job> jobs;

        public EndToEndTestWrapper() {
            this.performanceTargetsById = new Map<Id, PerformanceTargetWrapper>();
            this.performanceTargetsByName = new Map<String, Id>();
            this.performanceTargetCreationOrder = new List<Id>();
            this.jobs = new List<FFSubmitJobsLogic.Job>();
        }

        /**
         * Getter for the performanceTargets
         *
         * @return - The map of all the performanceTargets in the test
         */
        public Map<Id, PerformanceTargetWrapper> getPerformanceTargets() {
            return this.performanceTargetsById;
        }

        /**
         * Getter for the surveyor
         *
         * @return - The surveyor for the tests
         */
        public TestUtils.Surveyor getSurveyor() {
            return this.surveyor;
        }

        /**
         * Create performance indicators wrappers. They are for the current time period
         * The maps that can be passed in allow specific values to be set for each field
         * Pass in a null map to use default for all. Leave a key/value pair out to default just
         * that target. The key to the map is the number that it will be created. 0 ordered.
         *
         * @param timeFrame                             - The timeframe for the performance targets
         * @param amount                                - The number of targets to create
         * @param appendChars                           - Characters to add to the end of the
         *                                                 jobTemplate to keep it unique
         * @param targetValues                          - Target Values map
         * @param objectApiNames                        - Object API Name map
         * @param aggregationOperations                 - Aggregation Operation map
         * @param trackedFieldApiNames                  - Tracked Field Api Name map
         * @param trackedSObjectContactLookupFieldNames - Path to contact map
         * @param recordFilters                         - Map of record filters
         */
        public void initPerfomanceIndicatorPerformanceTargetWrappers(
                String timeFrame,
                Integer amount,
                String appendChars,
                Map<Integer, Integer> targetValues,
                Map<Integer, String> objectApiNames,
                Map<Integer, String> aggregationOperations,
                Map<Integer, String> trackedFieldApiNames,
                Map<Integer, String> trackedSObjectContactLookupFieldNames,
                Map<Integer, List<SObjectFilterCondition__c>> recordFilters
        ) {

            Map<Integer, PerformanceTarget__c> performanceTargetSObjects =
                new Map<Integer, PerformanceTarget__c>();
            for (Integer i = 0; i < amount; i++) {
                String objectApiName = (objectApiNames != null && objectApiNames.containsKey(i))
                    ? objectApiNames.get(i)
                    : 'Contact';
                String aggregationOperation =
                    (aggregationOperations != null && aggregationOperations.containsKey(i))
                        ? aggregationOperations.get(i)
                        : 'COUNT';
                String trackedFieldApiName =
                    (trackedFieldApiNames != null && trackedFieldApiNames.containsKey(i))
                        ? trackedFieldApiNames.get(i)
                        : 'Name';
                String trackedSObjectContactLookupFieldName =
                    (
                            trackedSObjectContactLookupFieldNames != null &&
                            trackedSObjectContactLookupFieldNames.containsKey(i)
                    )
                        ? trackedSObjectContactLookupFieldNames.get(i)
                        : 'Id';
                performanceTargetSObjects.put(
                    i,
                    PerformanceTargetDOTest.createPerformanceIndicatorRecord(
                        'Performance_Indicator_Target' + i + '_' + appendChars,
                        50,
                        timeFrame,
                        PerformanceTargetDO.getStartOfCurrentTimePeriod(Date.today(), timeFrame),
                        PerformanceTargetDO.getEndOfCurrentTimePeriod(Date.today(), timeFrame),
                        objectApiName,
                        aggregationOperation,
                        trackedFieldApiName,
                        trackedSObjectContactLookupFieldName
                    )
                );
            }
            insert performanceTargetSObjects.values();

            // Create the wrappers and add any SObjectFilters
            List<SObjectFilterCondition__c> filters = new List<SObjectFilterCondition__c>();
            for (Integer i = 0; i < amount; i++) {

                PerformanceTarget__c performanceTargetSObject = performanceTargetSObjects.get(i);
                if (recordFilters != null && recordFilters.get(i) != null) {
                    for (SObjectFilterCondition__c filter : recordFilters.get(i)) {
                        filter.PerformanceTarget__c = performanceTargetSObject.Id;
                        filters.add(filter);
                    }
                }

                // Generate the performance target wrapper
                PerformanceTargetWrapper performanceTargetWrapper =
                    new PerformanceTargetWrapper(performanceTargetSObject);
                addPerformanceTargetWrapper(performanceTargetWrapper);
            }
            insert filters;
        }

        /**
         * Initiate the JobTemplates and their performance targets
         *
         * @param timeFrame   - The timeframe for the performance targets
         * @param amount      - The number of targets to create
         * @param appendChars - Characters to add to the end of the jobTemplate to keep it unique
         */
        public void initJobPerformanceTargetWrappers(String timeFrame, Integer amount, String appendChars) {

            // Create a couple of JobTemplate__c
            List<JobTemplate__c> jobTemplateSObjects = new List<JobTemplate__c>();
            for (Integer i = 0; i < amount; i++) {
                jobTemplateSObjects.add(new JobTemplate__c(
                    Name = 'JobTemplate_' + i + '_' + appendChars,
                    Status__c = JobTemplateDO.STATUS_DRAFT,
                    Hierarchy__c = generateBasicHierarchy(),
                    Instructions__c = 'instructions'
                ));
            }
            insert jobTemplateSObjects;

            // Create a task and a PerformanceTarget for each JobTemplate__c
            Map<Id, PerformanceTarget__c> performanceTargetSObjects = new Map<Id, PerformanceTarget__c>();
            Map<Id, TaskTemplate__c> taskTempateSObjects = new Map<Id, TaskTemplate__c>();
            for (JobTemplate__c jobTemplateSObject : jobTemplateSObjects) {

                // Create a performance target
                performanceTargetSObjects.put(
                    jobTemplateSObject.Id,
                    PerformanceTargetDOTest.createJobTargetRecord(
                        jobTemplateSObject.Name + '_target',
                        jobTemplateSObject.Id,
                        50,
                        timeFrame,
                        PerformanceTargetDO.getStartOfCurrentTimePeriod(Date.today(), timeFrame),
                        PerformanceTargetDO.getEndOfCurrentTimePeriod(Date.today(), timeFrame),
                        PerformanceTargetDO.TYPE_JOB_TARGET
                    )
                );

                taskTempateSObjects.put(jobTemplateSObject.Id, new TaskTemplate__c(
                    Name = jobTemplateSObject.Name + '_dataView',
                    JobTemplate__c = jobTemplateSObject.Id,
                    Position__c = 1,
                    Type__c = TaskTemplateDO.TYPE_DATA_VIEW,
                    Object__c = '1'
                ));
            }
            insert taskTempateSObjects.values();

            // Publish the jobs
            for (JobTemplate__c jobTemplateSObject : jobTemplateSObjects) {
                jobTemplateSObject.Status__c = JobTemplateDO.STATUS_PUBLISHED;
            }
            update jobTemplateSObjects;
            insert performanceTargetSobjects.values();

            for (JobTemplate__c jobTemplateSObject : jobTemplateSObjects) {

                // Generate the performance target wrapper
                PerformanceTargetWrapper performanceTargetWrapper = new PerformanceTargetWrapper(
                    performanceTargetSobjects.get(jobTemplateSObject.Id),
                    jobTemplateSObject
                );
                performanceTargetWrapper.getJobTemplateWrapper().addTaskTemplate(taskTempateSObjects.get(jobTemplateSObject.Id));
                addPerformanceTargetWrapper(performanceTargetWrapper);
            }
        }

        /**
         * Add a PerformanceTargetWrapper to the object
         *
         * @param performanceTargetWrapper - The wrapper being added
         */
        public void addPerformanceTargetWrapper(PerformanceTargetWrapper performanceTargetWrapper) {

            this.performanceTargetsById.put(
                performanceTargetWrapper.getPerformanceTarget().Id,
                performanceTargetWrapper
            );
            this.performanceTargetsByName.put(
                performanceTargetWrapper.getPerformanceTarget().Name,
                performanceTargetWrapper.getPerformanceTarget().Id
            );
            this.performanceTargetCreationOrder.add(performanceTargetWrapper.getPerformanceTarget().Id);
        }

        /**
         * Get a performanceTargetWrapper from the index number that relates to the order it was created
         *
         * @param index - The position in the list that the wrapper sits
         *
         * @return - The performanceWrapper
         */
        public PerformanceTargetWrapper getPerformanceTargetWrapperByCreationIndex(Integer index) {
            return this.performanceTargetsById.get(this.performanceTargetCreationOrder.get(index));
        }

        /**
         * Get a performanceTargetWrapper by name
         *
         * @param performanceTargetName - The name of the performanceTarget
         *
         * @return - The performanceTargetWrapper
         */
        public PerformanceTargetWrapper getPerformanceTargetWrapperByName(String performanceTargetName) {

            Id performanceTargetId = this.performanceTargetsByName.get(performanceTargetName);
            if (performanceTargetId == null) {
                return null;
            }
            return this.performanceTargetsById.get(performanceTargetId);
        }

        /**
         * Get the Performance Target from the creation index of the PerfromanceTargetWrapper
         */
        public PerformanceTarget__c getPerformanceTargetByCreationIndex(Integer index) {
            return
                this.getPerformanceTargetWrapperByCreationIndex(index).getPerformanceTarget();
        }

        /**
         * Create default current assigned targets for all the performanceTargets
         *
         * @return - The create AssignedTarget__c records
         */
        public List<AssignedTarget__c> createDefaultAssignedTargets() {

            List<AssignedTarget__c> assignedTargets = new List<AssignedTarget__c>();
            for (PerformanceTargetWrapper performanceTargetWrapper : this.performanceTargetsById.values()) {
                assignedTargets.addAll(performanceTargetWrapper.createDefaultAssignedTargets());
            }
            return assignedTargets;
        }

        /**
         * Create default AssignedTargets for all the performanceTargets
         *
         * @param startDate             - The date that the AssignedTargets should start on
         * @param value                 - The value to give to the ActualValue__c
         * @param targetValue           - The value for the Target__c field. Pass null to use
         *                                  the PerformanceTarget default
         * @param timePeriodToCreateFor - Which time period PerformanceTargets should this be
         *                                  WEEKLY|MONTHLY|ALL.
         *                                  This allows the method to ignore PerformanceTargets
         *                                  of a different time period
         *
         * @return - The created AssignedTarget__c objects
         */
        public List<AssignedTarget__c> createAssignedTargetsForGivenDate(
                    Date startDate,
                    Integer value,
                    Integer targetValue,
                    String timePeriodToCreateFor
        ) {

            List<AssignedTarget__c> assignedTargets = new List<AssignedTarget__c>();
            for (PerformanceTargetWrapper performanceTargetWrapper : this.performanceTargetsById.values()) {
                PerformanceTarget__c performanceTarget = performanceTargetWrapper.getPerformanceTarget();

                // Check that this is the right timeperiod performanceTarget
                if (
                    (
                        timePeriodToCreateFor.equals(PerformanceTargetDO.TIMEFRAME_WEEKLY) &&
                        !performanceTarget.Timeframe__c.equals(
                            PerformanceTargetDO.TIMEFRAME_WEEKLY
                        )
                    ) ||
                    (
                        timePeriodToCreateFor.equals(PerformanceTargetDO.TIMEFRAME_MONTHLY) &&
                        !performanceTarget.Timeframe__c.equals(
                            PerformanceTargetDO.TIMEFRAME_MONTHLY
                        )
                    )
                ) {
                    continue;
                }

                AssignedTargetWrapper assignedTargetWrapper =
                    performanceTargetWrapper.contactAssignedTargets.get(this.surveyor.theContact.Id);
                if (assignedTargetWrapper == null) {
                    assignedTargetWrapper = new AssignedTargetWrapper();
                }

                startDate = PerformanceTargetDO.getStartOfCurrentTimePeriod(startDate, performanceTarget.Timeframe__c);
                String status = performanceTarget.StartDate__c.isSameDay(startDate)
                    ? AssignedTargetDO.STATUS_ACTIVE
                    : AssignedTargetDO.STATUS_CLOSED;
                AssignedTarget__c assignedTarget = AssignedTargetDO.createAssignedTarget(
                    performanceTarget,
                    this.surveyor.theContact.Id,
                    value,
                    targetValue == null ? performanceTarget.DefaultValue__c.intValue() : targetValue,
                    startDate,
                    PerformanceTargetDO.getEndOfCurrentTimePeriod(startDate, performanceTarget.Timeframe__c),
                    status
                );

                assignedTargetWrapper.addAssignedTargetForDate(startDate, assignedTarget);
                assignedTargets.add(assignedTarget);
                performanceTargetWrapper.contactAssignedTargets.put(
                    this.surveyor.theContact.Id,
                    assignedTargetWrapper
                );
            }
            return assignedTargets;
        }

        /**
         * Creates a basic hierarchy for the JobTemplates that use data-view tasks.
         * Allows all the tasks to have an objectId of 1
         *
         * @return - The JSON serialized string of the hierarchy
         */
        private  String generateBasicHierarchy() {

            List<JobTemplateDo.ObjectHierarchy> jobTempHier = new List<JobTemplateDo.ObjectHierarchy>();
            JobTemplateDO.ObjectHierarchy oh = new JobTemplateDO.ObjectHierarchy(
                '1',
                'Contact',
                'Contact'
            );
            oh.addListField('Name');
            oh.addDetailField('Name');
            jobTempHier.add(oh);
            return JSON.serialize(jobTempHier);
        }

        /**
         * Create a JobActivity for a given PerformanceTarget for the Surveyor
         * Assumption is that all tasks are for the moment just data view. Can add other types
         * when we add the code to allow for easy building of surveys, submissions, etc
         *
         * @param performanceTargetId - The Id for the performance target the the
         *                                job activity is going to count towards
         * @param completionDate    - The date that the activity was completed
         */
        public void createJobActivityForPerformanceTarget(Id performanceTargetId, Date completionDate) {

            PerformanceTargetWrapper performanceTargetWrapper = this.performanceTargetsById.get(performanceTargetId);
            if (performanceTargetWrapper == null) {
                return;
            }
            JobTemplateWrapper jobTemplateWrapper = performanceTargetWrapper.getJobTemplateWrapper();
            DateTime baseDateTime = DateTime.newInstance(completionDate, Time.newInstance(12, 0, 0,0));
            FFSubmitJobsLogic.Job job = FFSubmitJobsTest.createJobActivity(
                jobTemplateWrapper.jobTemplate.Name + Crypto.getRandomLong(),
                jobTemplateWrapper.jobTemplate.Id,
                this.surveyor.theContact.Id,
                completionDate,
                baseDateTime,
                baseDateTime.addMinutes(jobTemplateWrapper.getAllTaskTemplates().size() * 5),
                '-122.0 80.0 0 1000',
                '-120.0 90.0 0 1000'
            );

            Integer i = 0;
            for (TaskTemplate__c taskTemplate : jobTemplateWrapper.getAllTaskTemplates()) {
                FFSubmitJobsTest.createTaskAndAddToJob(
                    job,
                    null,
                    taskTemplate.Id,
                    baseDateTime.addMinutes(i * 5),
                    baseDateTime.addMinutes(i + 1 * 5),
                    '-122.0 80.0 0 1000',
                    '-120.0 90.0 0 1000'
                );
                i++;
            }
            this.jobs.add(job);
        }

        /**
         * Create the test surveyor
         *
         * @param status - Create a surveyor with active partner user
         */
        public void createPartnerSurveyor(Boolean status) {
            UserTH.setSkipValidation(true);
            this.surveyor = TestUtils.createPartnerSurveyor(
                LASTNAME,
                status
            );
            this.surveyor = TestUtils.partnerLoginDetails(this.surveyor);
        }

        public User getPartnerUser() {
            return this.surveyor.partnerUser;
        }

        /**
         * Init the request for getting performance
         *
         * @param overrideSessionToken - SessionId to use if overriding surveyor.loginResult.getSessionToken()
         */
        public void initPerformanceRequest(String overrideSessionToken) {

            // Prepare the request data
            String serviceUrl = TestUtils.getServiceUrl('performance');
            Map<String, String> headersMap = new Map<String, String>{
                C.SESSION_TOKEN_HEADER =>
                    String.isEmpty(overrideSessionToken) ? this.surveyor.loginResult.getSessionToken()
                        : overrideSessionToken
            };
            TestUtils.prepareRestContext(serviceUrl, null, headersMap);
        }

        /**
         * Init the request for submitting the job activities
         */
        public void initJobsRequest() {

            // Set up the request
            String serviceUrl = TestUtils.getServiceUrl('jobs/');
            Map<String, String> headersMap = new Map<String, String>{
                C.SESSION_TOKEN_HEADER => this.surveyor.loginResult.getSessionToken()
            };
            TestUtils.prepareRestContext(serviceUrl, null, headersMap);
        }

        /**
         * Set the JSON string for the request
         */
        public void addJsonToJobsRequest() {
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(this.jobs));
        }

        /**
         * Submit the request and check that the response was good
         */
        public void sendJobsRequest() {
            Test.startTest();
            System.runAs(this.getPartnerUser()) {
                FFSubmitJobs.processJobSubmission();
            }
            Test.stopTest();

            System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

            // Check that the response is of the correct format
            FFSubmitJobsLogic.JobResponses responses = (FFSubmitJobsLogic.JobResponses)JSON.deserialize(
                RestContext.response.responseBody.toString(),
                FFSubmitJobsLogic.JobResponses.class
            );
            System.assertEquals(this.jobs.size(), responses.jobs.size());
        }

        /**
         * Get all the AssignedTargets for the surveyor and create an easily accessible map for them
         *
         * @return - A map of maps with the PerformanceTarget__c
         */
        public Map<Id, Map<Date, AssignedTarget__c>> getAllAssignedTargets() {

            Map<Id, Map<Date, AssignedTarget__c>> allAssignedTargets = new Map<Id, Map<Date, AssignedTarget__c>>();
            for (AssignedTarget__c assignedTarget : [
                    SELECT
                        ActualValue__c,
                        StartDate__c,
                        EndDate__c,
                        Status__c,
                        TargetValue__c,
                        PerformanceTarget__c,
                        PerformanceTarget__r.DefaultValue__c,
                        PerformanceTarget__r.Timeframe__c,
                        PerformanceTarget__r.StartDate__c,
                        PerformanceTarget__r.EndDate__c,
                        PerformanceTarget__r.Name
                    FROM
                        AssignedTarget__c
                    WHERE
                        Contact__c = :this.surveyor.theContact.Id
            ]) {
                Map<Date, AssignedTarget__c> assignedTargetMap =
                    allAssignedTargets.get(assignedTarget.PerformanceTarget__c);
                if (assignedTargetMap == null) {
                    assignedTargetMap = new Map<Date, AssignedTarget__c>();
                }

                // Should never happen as a time period should only ever have 1 AssignedTarget
                System.assert(!assignedTargetMap.containsKey(assignedTarget.StartDate__c));
                assignedTargetMap.put(assignedTarget.StartDate__c, assignedTarget);
                allAssignedTargets.put(assignedTarget.PerformanceTarget__c, assignedTargetMap);
            }
            return allAssignedTargets;
        }

        /**
         * Validate that the request was successfull
         *
         * @param responseString - The string returned by the request
         *
         * @return - The deSerialized PerformanceManagementLogic.PerformanceManagementResponse object
         */
        public PerformanceManagementLogic.PerformanceManagementResponse validateRequest(String responseString) {

            System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
            return (PerformanceManagementLogic.PerformanceManagementResponse)JSON.deserialize(
                responseString,
                PerformanceManagementLogic.PerformanceManagementResponse.class
            );
        }


        /**
         * Validate a response
         *
         * @param returnedPerformanceTargets - A list of PerformanceManagementLogic.PerformanceTarget returned by the
         *                                       request to /performance/
         * @param expectedNumberOfTargets    - The expected number of PerformanceManagementLogic.PerformanceTarget
         *                                       in the response
         * @param referenceAssignedTargets   - The assignedTarget__c as they were created before the test was run
         */
        public void validatePerformanceResponse(
                List<PerformanceManagementLogic.PerformanceTarget> returnedPerformanceTargets,
                Integer expectedNumberOfTargets,
                Map<Id, AssignedTarget__c> referenceAssignedTargets
        ) {

            System.assertEquals(expectedNumberOfTargets, returnedPerformanceTargets.size());
            for (PerformanceManagementLogic.PerformanceTarget target : returnedPerformanceTargets) {
                PerformanceTargetWrapper testTarget =
                    this.getPerformanceTargetWrapperByName(target.getTargetName());
                System.assert(testTarget != null, 'Target: ' + target.getTargetName() + ' doesn\'t exist');

                // Check that everything in the PerformanceManagementLogic.PerformanceTarget matches the
                // PerformanceTargetWrapper
                Date startDate = testTarget.performanceTarget.StartDate__c;
                System.assertEquals(testTarget.performanceTarget.Timeframe__c, target.getTimeFrame());
                System.assertEquals(
                    PerformanceManagementUtils.convertDateToTimePeriod(testTarget.performanceTarget.EndDate__c),
                    target.getTimePeriodEndDate()
                );

                // Then check that the rank position is 0
                System.assertEquals(0, target.getRankPosition());

                // Check that the rank matches the AssignedTarget from the performanceWrapper
                List<PerformanceManagementLogic.PerformanceRank> performanceRank = target.getPerformanceRank();
                System.assertEquals(1, performanceRank.size());
                System.assertEquals(
                    testTarget.getSpecificAssignedTarget(this.getSurveyor().theContact.Id, startDate).ActualValue__c,
                    performanceRank[0].getActualValue()
                );
                System.assertEquals(testTarget.performanceTarget.DefaultValue__c, performanceRank[0].getTargetValue());

                // Must use the reference map of Assigned targets in this test as the saved assigned target won't have the
                // value for the Contact.Name in it as that must be fetched out of the DB
                System.assertEquals(
                    referenceAssignedTargets.get(
                        testTarget.getSpecificAssignedTarget(
                            this.getSurveyor().theContact.Id, startDate
                        ).Id).Contact__r.Name,
                    performanceRank[0].getContactName(),
                    'Contact Name on rank for target: ' + target.getTargetName() + ' is wrong'
                );
            }
        }
    }
}