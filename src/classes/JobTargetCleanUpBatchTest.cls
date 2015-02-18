/**
 * Test class for JobTargetCleanUpBatch
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
@isTest
public class JobTargetCleanUpBatchTest {

    /**
     * Test that the Assigned Targets are updated correctly.
     * One Mobile User has an AssignedTarget already. The other doesn't
     */
    static testMethod void testBatchUpdate() {

        // Create a contacts
        TestUtils.Surveyor testMobileUser1 = TestUtils.createSurveyor(
            'TESTJTCUBT1', 'username1', 'passsword1', MobileUserDO.STATUS_ACTIVE, false
        );
        TestUtils.Surveyor testMobileUser2 = TestUtils.createSurveyor(
            'TESTJTCUBT2', 'username2', 'passsword2', MobileUserDO.STATUS_ACTIVE, false
        );

        // Create a PerformanceTargetWrapper
        PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper = new PerformanceManagementTest.EndToEndTestWrapper();
        endToEndTestWrapper.initJobPerformanceTargetWrappers(PerformanceTargetDO.TIMEFRAME_WEEKLY, 1, 'WEEKLY');
        endToEndTestWrapper.initJobPerformanceTargetWrappers(PerformanceTargetDO.TIMEFRAME_MONTHLY, 1, 'MONTHLY');

        // Create some JobActivities for the JobTemplate
        PerformanceManagementTest.PerformanceTargetWrapper performanceTargetWrapper1 =
            endToEndTestWrapper.getPerformanceTargetWrapperByCreationIndex(0);
        PerformanceManagementTest.JobTemplateWrapper jobTemplateWrapper1 = performanceTargetWrapper1.getJobTemplateWrapper();

        PerformanceManagementTest.PerformanceTargetWrapper performanceTargetWrapper2 =
            endToEndTestWrapper.getPerformanceTargetWrapperByCreationIndex(1);
        PerformanceManagementTest.JobTemplateWrapper jobTemplateWrapper2 = performanceTargetWrapper2.getJobTemplateWrapper();

        DateTime testDate = DateTime.now().addDays(-1);

        insert new List<Job__c>{
            new Job__c(
                Name = 'Job1', JobTemplate__c = jobTemplateWrapper1.jobTemplate.Id,
                Assigned__c = testMobileUser1.theContact.Id, StartDate__c = testDate, EndDate__c = testDate
            ),
            new Job__c(
                Name = 'Job2', JobTemplate__c = jobTemplateWrapper1.jobTemplate.Id,
                Assigned__c = testMobileUser2.theContact.Id, StartDate__c = testDate, EndDate__c = testDate
            ),
            new Job__c(
                Name = 'Job3', JobTemplate__c = jobTemplateWrapper2.jobTemplate.Id,
                Assigned__c = testMobileUser1.theContact.Id, StartDate__c = testDate, EndDate__c = testDate
            ),
            new Job__c(
                Name = 'Job4', JobTemplate__c = jobTemplateWrapper2.jobTemplate.Id,
                Assigned__c = testMobileUser1.theContact.Id, StartDate__c = testDate, EndDate__c = testDate
            )
        };

        // Add an AssingedTarget for mobile user 1 for both targets. Do not add weekly one if it is a Monday
        List<AssignedTarget__c> initialAssignedTargets = new List<AssignedTarget__c>();
        if (
                (
                    performanceTargetWrapper1.getPerformanceTarget().Timeframe__c.equals(
                        PerformanceTargetDO.TIMEFRAME_WEEKLY
                    ) &&
                    !PerformanceTargetDO.isMonday(Date.today())
                ) ||
                (performanceTargetWrapper1.getPerformanceTarget().Timeframe__c.equals(
                    PerformanceTargetDO.TIMEFRAME_MONTHLY
                    ) && Date.today().day() != 1)
        ) {
            initialAssignedTargets.add(AssignedTargetDO.createDefaultActiveAssignedTarget(
                performanceTargetWrapper1.getPerformanceTarget(), testMobileUser1.theContact.Id, 3
            ));
        }
        if (
                (
                    performanceTargetWrapper2.getPerformanceTarget().Timeframe__c.equals(
                        PerformanceTargetDO.TIMEFRAME_WEEKLY
                    ) &&
                    !PerformanceTargetDO.isMonday(Date.today())
                ) ||
                (performanceTargetWrapper2.getPerformanceTarget().Timeframe__c.equals(
                    PerformanceTargetDO.TIMEFRAME_MONTHLY
                ) && Date.today().day() != 1)
        ) {
            initialAssignedTargets.add(AssignedTargetDO.createDefaultActiveAssignedTarget(
                performanceTargetWrapper2.getPerformanceTarget(), testMobileUser1.theContact.Id, 2
            ));
        }
        if (initialAssignedTargets.size() > 0) {
            insert initialAssignedTargets;
        }

        ApplicationSettingsUtils.setReCalculateJobTarget(true, true);

        // Run the batch
        Test.startTest();
        Id batchInstanceId = Database.executeBatch(new JobTargetCleanUpBatch(), 5);
        Test.stopTest();

        // Check that the AssignedTarget have been updated
        AssignedTarget__c[] testTargets = [
            SELECT
                Id,
                ActualValue__c,
                Contact__c,
                PerformanceTarget__c
            FROM
                AssignedTarget__c
        ];
        System.assertEquals(3, testTargets.size());
        for (AssignedTarget__c testTarget : testTargets) {
            if (testTarget.Contact__c == testMobileUser1.theContact.Id) {
                if (testTarget.PerformanceTarget__c == performanceTargetWrapper1.getPerformanceTarget().Id) {

                    //Test Mobile User 1 with JobTarget 1
                    System.assertEquals(1, testTarget.ActualValue__c);
                } else {

                    //Test Mobile User 1 with JobTarget 2
                    System.assertEquals(2, testTarget.ActualValue__c);
                }
            } else {

                //Test Mobile User 2 with JobTarget 1
                System.assertEquals(1, testTarget.ActualValue__c);
            }
        }
    }
}
