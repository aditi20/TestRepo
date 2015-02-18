/**
 * Test class for the trigger on AssignedTarget__c
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
@isTest
public with sharing class AssignedTargetTriggerTest {
    /**
     * Test that the insertion of new assigned targets close the previous ones
     */
    static testMethod void testClosePreviousTargetsOnInsert() {
        // Add some mobile users
        List<TestUtils.Surveyor> surveyors = new List<TestUtils.Surveyor>();
        for(Integer i = 1; i <= 5; i++) {
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

        // Create the new assigned targets
        List<AssignedTarget__c> newAssignedTargets = new List<AssignedTarget__c>();
        for (AssignedTarget__c assignedTarget : assignedTargets) {
            newAssignedTargets.add(
                AssignedTargetDO.createAssignedTarget(
                    performanceTarget,
                    assignedTarget.Contact__c,
                    0,
                    Integer.valueOf(assignedTarget.TargetValue__c),
                    assignedTarget.StartDate__c.addDays(7),
                    assignedTarget.EndDate__c.addDays(7),
                    AssignedTargetDO.STATUS_ACTIVE
                )
            );
        }

        Test.startTest();
        insert newAssignedTargets;
        Test.stopTest();

        List<AssignedTarget__c> closedTargets = [
            SELECT Id,
                   Status__c
            FROM AssignedTarget__c
            WHERE Id IN :assignedTargets
        ];

        for (AssignedTarget__c target : closedTargets) {
            System.assertEquals(AssignedTargetDO.STATUS_CLOSED, target.Status__c);
        }
    }

    static testMethod void testNotAllowRepeatedAssignment() {

        TestUtils.Surveyor surveyor = TestUtils.createSurveyor(
                    'Contact_1',
                    'user1',
                    'pass',
                    MobileUserDo.STATUS_ACTIVE
                );

        JobTemplate__c jobTemplate = TestUtils.createPublishedDataCollectionJobTemplate('job1', 'survey1');

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

        // try to create an existing Assigned Target
        AssignedTarget__c assignedTarget = new AssignedTarget__c( Contact__c = surveyor.theContact.Id, StartDate__c = Date.today(), EndDate__c = Date.today().addDays(6));

        try {
            insert assignedTarget;
            system.Assert(false, 'the assigned Target should have not been inserted');
        } catch (Exception e){
            system.Assert(true);
        }
    }

}
