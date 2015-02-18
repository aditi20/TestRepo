/**
 * Test class for the trigger on PerformanceTarget__c
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
@isTest
public with sharing class PerformanceTargetTriggerTest {

    /**
     * Test the creation of new assigned targets when the EndDate is changed
     */
    static testMethod void createAssignedTargetsOnDateChange() {
        // Add some mobile users
        List<TestUtils.Surveyor> surveyors = new List<TestUtils.Surveyor>();
        for (Integer i = 1; i <= 5; i++) {
            surveyors.add(
                TestUtils.createSurveyor(
                    'Contact_' + i,
                    'user' + i,
                    'pass',
                    MobileUserDo.STATUS_ACTIVE
                )
            );
        }

        // Add a Job wth a collect data task
        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;

        SurveyVersion__c surveyVersion = SurveyDO.publishSurvey(survey);

        JobTemplate__c jobTemplate = new JobTemplate__c(
            Name = 'Job Template 2',
            Status__c = JobTemplateDO.STATUS_DRAFT
        );
        insert jobTemplate;

        TaskTemplate__c task = new TaskTemplate__c(
            Name = 'Task 1',
            Position__c  = 1,
            JobTemplate__c = jobTemplate.Id,
            Type__c = TaskTemplateDO.TYPE_FORM,
            Form__c = surveyVersion.Id
        );
        insert task;

        jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        update jobTemplate;

        // Create a performance target
        PerformanceTarget__c performanceTarget = PerformanceTargetDOTest.createJobTargetRecord(
            'PerformanceTarget',
            jobTemplate.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            PerformanceTargetDO.getPreviousMonday(Date.today()),
            PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        insert performanceTarget;

        // Create the corresponding assigned target for each user
        List<AssignedTarget__c> assignedTargets =
                AssignedTargetDO.createDefaultAssignedTargetsForAllMobileUsers(
                    performanceTarget
                );
        insert assignedTargets;

        // Change the EndDate of the performance target
        Test.startTest();
        performanceTarget.EndDate__c = performanceTarget.EndDate__c.addDays(7);
        update performanceTarget;
        Test.stopTest();

        // Get the performance target as it is in the database
        PerformanceTarget__c performaceTargetUpdated = [
            SELECT Id,
                   Name,
                   JobTemplate__c,
                   DefaultValue__c,
                   Timeframe__c,
                   EndDate__c,
                   StartDate__c,
                   Type__c
            FROM PerformanceTarget__c
            WHERE Id = :performanceTarget.Id
        ];

        // Check the StartDate was chaged
        System.assertEquals(
            performanceTarget.StartDate__c + 7,
            performaceTargetUpdated.StartDate__c
        );

        // Check the type was not chaged
        System.assertEquals(
            PerformanceTargetDO.TYPE_JOB_TARGET,
            performaceTargetUpdated.Type__c
        );
        // Check the new assigned target were created
        List<AssignedTarget__c> newAssignedTargets = new List<AssignedTarget__c> ([
            SELECT Id,
                   TargetValue__c,
                   StartDate__c,
                   EndDate__c
            FROM AssignedTarget__c
            WHERE PerformanceTarget__c = :performanceTarget.Id
                 AND Status__c = :AssignedTargetDO.STATUS_ACTIVE
        ]);

        System.assertEquals(assignedTargets.size(), newAssignedTargets.size());
        for (AssignedTarget__c assignedT : newAssignedTargets) {
            System.assertEquals(
                performaceTargetUpdated.StartDate__c,
                assignedT.StartDate__c
            );
            System.assertEquals(
                performaceTargetUpdated.EndDate__c,
                assignedT.EndDate__c
            );
            System.assertEquals(
                performaceTargetUpdated.DefaultValue__c,
                assignedT.TargetValue__c
            );
        }

        // Check the status of the old assigned targets was changed
        Set<Id> oldAssignedTargets = new Set<Id>();
        for (AssignedTarget__c assignedT : assignedTargets) {
            oldAssignedTargets.add(assignedT.Id);
        }

        Set<Id> updatedAssignedTargets = new Set<Id>();
        for (
            AssignedTarget__c assignedT : [
                SELECT Id
                FROM AssignedTarget__c
                WHERE Id IN :assignedTargets
                      AND Status__c = :AssignedTargetDO.STATUS_CLOSED
            ]
        ) {
            updatedAssignedTargets.add(assignedT.Id);
        }

        System.assertEquals(oldAssignedTargets.size(), updatedAssignedTargets.size());
        updatedAssignedTargets.removeAll(oldAssignedTargets);
        System.assertEquals(0, updatedAssignedTargets.size());

    }

    /**
     * Test the creation of new assigned targets does not create duplicates if already exists
     */
    static testMethod void testAssignedTargetCreationDoesNotCreateDuplicated() {
        // Add some partner users
        List<TestUtils.Surveyor> surveyors = new List<TestUtils.Surveyor>();

        // Block the user trigger from creating the assigned targets.
        // As the test creates them ecplicitly
        UserTH.setSkipValidation(true);
        for (Integer i = 1; i <= 5; i++) {
            surveyors.add(
                TestUtils.createPartnerSurveyor(
                    'Contact_' + i,
                    true
                )
            );
        }

        // Add a Job wth a collect data task
        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;

        SurveyVersion__c surveyVersion = SurveyDO.publishSurvey(survey);

        JobTemplate__c jobTemplate = new JobTemplate__c(
            Name = 'Job Template 2',
            Status__c = JobTemplateDO.STATUS_DRAFT
        );
        insert jobTemplate;

        TaskTemplate__c task =  new TaskTemplate__c(
            Name = 'Task 1',
            Position__c  = 1,
            JobTemplate__c = jobTemplate.Id,
            Type__c = TaskTemplateDO.TYPE_FORM,
            Form__c = surveyVersion.Id
        );
        insert task;

        jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        update jobTemplate;

        // Create a performance target
        PerformanceTarget__c performanceTarget = PerformanceTargetDOTest.createJobTargetRecord(
            'PerformanceTarget',
            jobTemplate.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            PerformanceTargetDO.getPreviousMonday(Date.today()),
            PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        insert performanceTarget;

        // Create the corresponding assigned target for each user
        List<AssignedTarget__c> assignedTargets =
            AssignedTargetDO.createDefaultAssignedTargetsForAllMobileUsers(
                performanceTarget
            );
        insert assignedTargets;

        // Add some assigned target for the next timeframe
        AssignedTarget__c newAssigned1 = AssignedTargetDO.createDefaultActiveAssignedTarget(
            performanceTarget,
            surveyors[0].theContact.Id,
            50
        );
        newAssigned1.StartDate__c = performanceTarget.StartDate__c.addDays(7);
        newAssigned1.EndDate__c = performanceTarget.EndDate__c.addDays(7);
        newAssigned1.Status__c = AssignedTargetDO.STATUS_ACTIVE;

        AssignedTarget__c newAssigned2 = AssignedTargetDO.createDefaultActiveAssignedTarget(
            performanceTarget,
            surveyors[1].theContact.Id,
            50
        );
        newAssigned2.StartDate__c = performanceTarget.StartDate__c.addDays(7);
        newAssigned2.EndDate__c = performanceTarget.EndDate__c.addDays(7);
        newAssigned2.Status__c = AssignedTargetDO.STATUS_ACTIVE;
        insert new List<AssignedTarget__c>{newAssigned1, newAssigned2};

        // Change the EndDate of the performance target
        Test.startTest();
        performanceTarget.EndDate__c = performanceTarget.EndDate__c.addDays(7);
        update performanceTarget;
        Test.stopTest();

        // Get the performance target as it is in the database
        PerformanceTarget__c performaceTargetUpdated = [
            SELECT Id,
                   Name,
                   JobTemplate__c,
                   DefaultValue__c,
                   Timeframe__c,
                   EndDate__c,
                   StartDate__c
            FROM PerformanceTarget__c
            WHERE Id = :performanceTarget.Id
        ];

        // Check the StartDate was chaged
        System.assertEquals(
            performanceTarget.StartDate__c + 7,
            performaceTargetUpdated.StartDate__c
        );

        // Check the new assigned target were created
        List<AssignedTarget__c> newAssignedTargets = new List<AssignedTarget__c> ([
            SELECT Id,
                   TargetValue__c,
                   StartDate__c,
                   EndDate__c,
                   Contact__c
            FROM AssignedTarget__c
            WHERE PerformanceTarget__c = :performanceTarget.Id
                 AND Status__c = :AssignedTargetDO.STATUS_ACTIVE
        ]);

        System.assertEquals(assignedTargets.size(), newAssignedTargets.size());
        for (AssignedTarget__c assignedT : newAssignedTargets) {
            System.assertEquals(
                performaceTargetUpdated.StartDate__c,
                assignedT.StartDate__c
            );
            System.assertEquals(
                performaceTargetUpdated.EndDate__c,
                assignedT.EndDate__c
            );
            System.assertEquals(
                performaceTargetUpdated.DefaultValue__c,
                assignedT.TargetValue__c
            );
        }

        // Check the status of the old assigned targets was changed
        Set<Id> oldAssignedTargets = new Set<Id>();
        for (AssignedTarget__c assignedT : assignedTargets) {
            oldAssignedTargets.add(assignedT.Id);
        }

        Set<Id> updatedAssignedTargets = new Set<Id>();
        for (
            AssignedTarget__c assignedT : [
                SELECT Id
                FROM AssignedTarget__c
                WHERE Id IN :assignedTargets
                      AND Status__c = :AssignedTargetDO.STATUS_CLOSED
            ]
        ) {
            updatedAssignedTargets.add(assignedT.Id);
        }

        System.assertEquals(oldAssignedTargets.size(), updatedAssignedTargets.size());
        updatedAssignedTargets.removeAll(oldAssignedTargets);
        System.assertEquals(0, updatedAssignedTargets.size());
    }

    /**
     * Test creation of performance target with an invalid job
     */
    static testMethod void insertPerformanceTargetWithAlreadyUsedJob() {
        // Create job
        JobTemplate__c job = TestUtils.createPublishedDataCollectionJobTemplate('job1', 'Survey 1');
        // Create performance target
        PerformanceTarget__c pT = PerformanceTargetDOTest.createJobTargetRecord(
            'target1',
            job.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        insert pT;

        // Create another performance target with same job as before
        PerformanceTarget__c pT2 = PerformanceTargetDOTest.createJobTargetRecord(
            'target2',
            job.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        Test.startTest();
        try {
            insert pT2;
            System.assert(false, 'Should be fail here since there is another active job target with same job related');
        } catch(DMLException e) {
            System.assert(e.getDmlMessage(0).contains(System.Label.JOB_TARGET_ERR_JOB_USED));
        }
        Test.stopTest();
    }

    /**
     * Test update of performance target with an invalid job
     */
    static testMethod void updatePerformanceTargetWithAlreadyUsedJob() {
        // Create job
        JobTemplate__c job1 = TestUtils.createPublishedDataCollectionJobTemplate('job1', 'Survey 1');
        // Create job
        JobTemplate__c job2 = TestUtils.createPublishedDataCollectionJobTemplate('job2', 'Survey 2');
        // Create performance target
        PerformanceTarget__c pT = PerformanceTargetDOTest.createJobTargetRecord(
            'target1',
            job1.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        insert pT;

        // Create another performance target
        PerformanceTarget__c pT2 = PerformanceTargetDOTest.createJobTargetRecord(
            'target2',
            job2.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );

        insert pT2;

        // Change to an invalid job
        pT2.JobTemplate__c = job1.Id;

        Test.startTest();
        try {
            update pT2;
            System.assert(false, 'Should be fail here since there is another active job target with same job related');
        } catch(DMLException e) {
            System.assert(e.getDmlMessage(0).contains(System.Label.JOB_TARGET_ERR_JOB_USED));
        }
        Test.stopTest();
    }

    /**
     * Test insert of performance targets with no published job
     */
    static testMethod void insertPerformanceTargetWithNonPublishedJob() {
        // Create draft job
        JobTemplate__c job = new JobTemplate__c(
            Name = 'jobName',
            Status__c = JobTemplateDO.STATUS_DRAFT
        );
        insert job;

        // Create performance target
        PerformanceTarget__c pT = PerformanceTargetDOTest.createJobTargetRecord(
            'target1',
            job.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        Test.startTest();
        try {
            insert pT;
            System.assert(false, 'Should be fail here since the job is not published');
        } catch(DMLException e) {
            System.assert(e.getDmlMessage(0).contains(System.Label.JOB_TARGET_ERR_JOB_NOT_PUBLISHED));
        }
        Test.stopTest();
    }

    /**
     * Test the creation of new assigned targets does not create duplicates if already exists
     */
    static testMethod void testClosePerformance() {

        // Add some contacts
        List<TestUtils.Surveyor> surveyors = new List<TestUtils.Surveyor>();
        Contact con1 = new Contact(LastName = 'con1');
        Contact con2 = new Contact(LastName = 'con2');
        Contact con3 = new Contact(LastName = 'con3');
        insert new List<Contact>{con1, con2, con3};

        // Create Job data
        JobTemplate__c job1 = TestUtils.createPublishedDataCollectionJobTemplate('job1', 'survey 1');
        JobTemplate__c job2 = TestUtils.createPublishedDataCollectionJobTemplate('job2', 'survey 2');

        // Create a performance target
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
        insert new List<PerformanceTarget__c>{performanceTarget1, performanceTarget2};

        // Create the corresponding assigned target for each user
        AssignedTarget__c assignedTarget = new AssignedTarget__c(
            Contact__c = con1.Id,
            ActualValue__c = 1,
            PerformanceTarget__c = performanceTarget1.Id,
            StartDate__c = performanceTarget1.StartDate__c,
            EndDate__c = performanceTarget1.EndDate__c,
            TargetValue__c = performanceTarget1.DefaultValue__c,
            Status__c = AssignedTargetDO.STATUS_ACTIVE
        );

        AssignedTarget__c assignedTarget2 = new AssignedTarget__c(
            Contact__c = con2.Id,
            ActualValue__c = 1,
            PerformanceTarget__c = performanceTarget2.Id,
            StartDate__c = performanceTarget2.StartDate__c,
            EndDate__c = performanceTarget2.EndDate__c,
            TargetValue__c = performanceTarget2.DefaultValue__c,
            Status__c = AssignedTargetDO.STATUS_ACTIVE
        );

        AssignedTarget__c assignedTarget3 = new AssignedTarget__c(
            Contact__c = con3.Id,
            ActualValue__c = 1,
            PerformanceTarget__c = performanceTarget2.Id,
            StartDate__c = performanceTarget2.StartDate__c,
            EndDate__c = performanceTarget2.EndDate__c,
            TargetValue__c = performanceTarget2.DefaultValue__c,
            Status__c = AssignedTargetDO.STATUS_ACTIVE
        );
        insert new List<AssignedTarget__c>{assignedTarget, assignedTarget2, assignedTarget3};
        performanceTarget2.Status__c = PerformanceTargetDO.STATUS_CLOSED;
        update performanceTarget2;

        List<AssignedTarget__c> assignedTargets = [SELECT Id, Status__c, Contact__c, PerformanceTarget__c FROM AssignedTarget__c];

        // Assert the assigned targets of performance2 are closed
        System.AssertEquals(3, assignedTargets.size(), 'There should be 3 assigned targets');
        for (AssignedTarget__c assigned: assignedTargets) {
            if (assigned.PerformanceTarget__c == performanceTarget2.Id) {
                System.AssertEquals(AssignedTargetDO.STATUS_CLOSED, assigned.Status__c, 'Status should be closed');
            } else {
                System.AssertEquals(AssignedTargetDO.STATUS_ACTIVE, assigned.Status__c, 'Status should be closed');
            }
        }
    }

    /**
     * Test update of performance targets with no published job
     */
    static testMethod void updatePerformanceTargetWithNonPublishedJob() {
        // Create published job
        JobTemplate__c job = TestUtils.createPublishedDataCollectionJobTemplate('job1', 'Survey 1');

        // Create draft job
        JobTemplate__c jobDraft = new JobTemplate__c(
            Name = 'jobName',
            Status__c = JobTemplateDO.STATUS_DRAFT
        );
        insert jobDraft;

        // Create performance target
        PerformanceTarget__c pT = PerformanceTargetDOTest.createJobTargetRecord(
            'target1',
            job.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        // Insert performance target
        insert pT;

        // Try to update job related to a non published job
        pT.JobTemplate__c = jobDraft.Id;

        Test.startTest();
        try {
            update pT;
            System.assert(false, 'Should be fail here since the job is not published');
        } catch(DMLException e) {
            System.assert(e.getDmlMessage(0).contains(System.Label.JOB_TARGET_ERR_JOB_NOT_PUBLISHED));
        }
        Test.stopTest();
    }

    /**
     * Test that the timeframe cannot be updated
     */
    static testMethod void preventTimeframeUpdate() {
        // Given an indicator target with certain timeframe
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
        PerformanceTarget__c currentPerformanceTarget = endToEndTestWrapper
                .getPerformanceTargetWrapperByCreationIndex(0).getPerformanceTarget();

        Test.startTest();
        // When the timeframe is updated
        currentPerformanceTarget.Timeframe__c = PerformanceTargetDO.TIMEFRAME_MONTHLY;
        try {
            update currentPerformanceTarget;
            System.assert(false, 'It should fail because the timeframe cannot be updated.');
        } catch (DMLException e) {
            // Then an error must be shown
            System.assert(
                e.getDmlMessage(0).contains(
                    System.Label.PERFORMANCE_TARGET_TIMEFRAME_CANNOT_CHANGE
                )
            );
        }
        Test.stopTest();
    }
    
    /**
     * Test that the Repeated name can exist if there is no active performance
     */
    static testMethod void allowRepeatedNameNotActive() {
         // Create jobs
        JobTemplate__c job1 = TestUtils.createPublishedDataCollectionJobTemplate('job1', 'Survey 1');
        JobTemplate__c job2 = TestUtils.createPublishedDataCollectionJobTemplate('job2', 'Survey 2');

        // Create performance target
        PerformanceTarget__c performance = PerformanceTargetDOTest.createJobTargetRecord(
            'target1',
            job1.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        performance.Status__c = PerformanceTargetDO.STATUS_CLOSED;
        
        // Insert performance target
        insert performance;
        
        // Create performance target
        PerformanceTarget__c performance2 = PerformanceTargetDOTest.createJobTargetRecord(
            'target1',
            job2.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        Test.startTest();
        try {
            insert performance2;
            System.assert(true);
        } catch(DMLException e) {
            System.assert(false, 'the target should be inserted' + e.getDmlMessage(0));
        }
        Test.stopTest();
    }
    
        /**
     * Test that the timeframe cannot be updated
     */
    static testMethod void notAllowRepeatedNameNotActive() {
        
        // Create jobs
        JobTemplate__c job1 = TestUtils.createPublishedDataCollectionJobTemplate('job1', 'Survey 1');
        JobTemplate__c job2 = TestUtils.createPublishedDataCollectionJobTemplate('job2', 'Survey 2');

        // Create performance target
        PerformanceTarget__c performance = PerformanceTargetDOTest.createJobTargetRecord(
            'target1',
            job1.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        
        // Insert performance target
        insert performance;
        
        // Create performance target
        PerformanceTarget__c performance2 = PerformanceTargetDOTest.createJobTargetRecord(
            'target1',
            job2.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            Date.today(),
            Date.today(),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        
        // Insert a active performance target with same name should fail
        Test.startTest();
        try {
            insert performance2;
            System.assert(false, 'Should be fail here since the job is not published');
        } catch(DMLException e) {
            System.assert(
                e.getDmlMessage(0).contains(
                    System.Label.PERFORMANCE_TARGET_ERROR_NAME_EXIST),
                e.getDmlMessage(0)
            );
        }
        Test.stopTest();
    }
}
