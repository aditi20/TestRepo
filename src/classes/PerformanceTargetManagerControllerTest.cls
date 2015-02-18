/**
*  Grameen: Salesforce - Performance Target Manager Controller
*  Controller for the PerformanceTargetManager page
*  (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*  @author Ernesto Quesada
*/
@isTest
private class PerformanceTargetManagerControllerTest {

    /**
    * Test to check only the job Targets are being shown (performance target with job template)
    */
    static testMethod void testCorrectFilteringJobTargets() {

        // Create test data
        JobTemplate__c job = TestUtils.createPublishedDataCollectionJobTemplate('job', 'survey');

        // Insert 10 job Performance Targets
        createPerformanceTarget(10, 'surveyJob1', job.Id, PerformanceTargetDO.TYPE_JOB_TARGET);

        // Insert 15 Indicator Performance Targets (with no job template)
        createPerformanceTarget(15, 'surveyJob2', null, PerformanceTargetDO.TYPE_INDICATOR);

        // Initialize the page
        PerformanceTargetManagerController page = new PerformanceTargetManagerController();

        // Assert correct creation of the list
        System.AssertEquals(10, page.targetList.size(), 'There should be 10 job Performance Target');

    }

    /**
    * Test to verify correct order of the manager at page load
    */
    static testMethod void testCorrectInitialOrder() {

        // Create test data
        List<JobTemplate__c>  JobTemplates = TestUtils.createPublishedDataCollectionJobTemplates('job', 'survey', 3);
        JobTemplate__c job1 = JobTemplates.get(0);
        JobTemplate__c job2 = JobTemplates.get(1);
        JobTemplate__c job3 = JobTemplates.get(2);

        PerformanceTarget__c target1 = new PerformanceTarget__c(Name = 'target1',
                                                    Timeframe__c = PerformanceTargetDO.TIMEFRAME_MONTHLY,
                                                    DefaultValue__c = 50,
                                                    JobTemplate__c = job1.Id,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        // Insert and wait
        insert target1;
        C.wait(1);

        PerformanceTarget__c target2 = new PerformanceTarget__c(Name = 'target2',
                                                    Timeframe__c = PerformanceTargetDO.TIMEFRAME_MONTHLY,
                                                    DefaultValue__c = 50,
                                                    JobTemplate__c = job2.Id,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        // Insert and wait
        insert target2;
        C.wait(1);
        PerformanceTarget__c target3 = new PerformanceTarget__c(Name = 'target3',
                                                    Timeframe__c = PerformanceTargetDO.TIMEFRAME_MONTHLY,
                                                    DefaultValue__c = 50,
                                                    JobTemplate__c = job3.Id,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        // Insert and wait
        insert target3;
        C.wait(1);

        Test.startTest();
        PerformanceTargetManagerController page = new PerformanceTargetManagerController();
        Test.stopTest();
        // Assert correct creation of the list
        System.AssertEquals(3,page.targetList.size(),'There should be 3 job Performance Target');

        // Assert the order of the targets
        system.AssertEquals(target3.Id, page.targetList[0].Id, 'The order is not correct');
        system.AssertEquals(target2.Id, page.targetList[1].Id, 'The order is not correct');
        system.AssertEquals(target1.Id, page.targetList[2].Id, 'The order is not correct');

    }

    /**
    * Test to verify correct order of the manager at page load
    */
    static testMethod void testClosePerformance() {
        // Create test data
        // Create test data
        List<JobTemplate__c>  JobTemplates = TestUtils.createPublishedDataCollectionJobTemplates('job', 'survey', 3);
        JobTemplate__c job1 = JobTemplates.get(0);
        JobTemplate__c job2 = JobTemplates.get(1);
        JobTemplate__c job3 = JobTemplates.get(2);

        PerformanceTarget__c target1 = new PerformanceTarget__c(Name = 'target1',
                                                    Timeframe__c = 'monthly',
                                                    Status__c = PerformanceTargetDO.STATUS_ACTIVE,
                                                    DefaultValue__c = 50,
                                                    JobTemplate__c = job1.Id,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        PerformanceTarget__c target2 = new PerformanceTarget__c(Name = 'target2',
                                                    Timeframe__c = 'monthly',
                                                    Status__c = PerformanceTargetDO.STATUS_ACTIVE,
                                                    DefaultValue__c = 50,
                                                    JobTemplate__c = job2.Id,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        PerformanceTarget__c target3 = new PerformanceTarget__c(Name = 'target3',
                                                    Timeframe__c = 'monthly',
                                                    Status__c = PerformanceTargetDO.STATUS_ACTIVE,
                                                    DefaultValue__c = 50,
                                                    JobTemplate__c = job3.Id,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        // Insert performance
        insert new List<PerformanceTarget__c>{target1, target2, target3};

        PerformanceTargetManagerController page = new PerformanceTargetManagerController();

        page.currentTargetId = target1.Id;
        page.closeTarget();
        List<PerformanceTarget__c> performanceTargets= [SELECT Id, Status__c, CloseReason__c FROM PerformanceTarget__c];
        system.assertEquals(3, performanceTargets.size(), 'There should be 3 performance targets');
        for (PerformanceTarget__c target: performanceTargets) {
            if (target.Id == target1.Id) {
                system.assertEquals(PerformanceTargetDO.STATUS_CLOSED, target.Status__c, 'the target should be closed');
                system.assertEquals(PerformanceTargetDO.CLOSE_MANUALLY, target.CloseReason__c, 'the target should be closed manually');
            } else {
                system.assertEquals(PerformanceTargetDO.STATUS_ACTIVE, target.Status__c, 'the target should be active');
            }
        }


    }

    /**
    * Create a List of Performance Target and insert them into db,
    * @param rows          Number of PerformanceTarget__c to be inserted
    * @param baseName      Base name for the Performance Targets (the name will be generated
    *                        With this name with a counter number))
    * @param jobTemplate   The job template id to set
    */
    private static List<PerformanceTarget__c> createPerformanceTarget(Integer rows, String baseName, Id jobTemplate, String type) {
        Integer i;
        List<PerformanceTarget__c> allTargets = new List<PerformanceTarget__c>();
        for (i=0; i < rows; i++) {
            allTargets.add(new PerformanceTarget__c(Name = baseName + i,
                                                    Type__c = type,
                                                    Timeframe__c = PerformanceTargetDO.TIMEFRAME_MONTHLY,
                                                    DefaultValue__c = 50,
                                                    JobTemplate__c = jobTemplate,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today()));
        }
        insert allTargets;
        return allTargets;
    }
}
