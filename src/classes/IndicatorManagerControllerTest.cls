/**
 *  Grameen: Salesforce - Performance Indicator Manager Controller Test
 *  Test for the PerformanceIndicatorManager
 *
 *  (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 *  @author Ernesto Quesada
 */
@isTest
private class IndicatorManagerControllerTest {

    /**
     * Test to check only the Indicators Targets are being shown
     */
    static testMethod void testCorrectFilteringJobTargets() {

        // Test Data wrapper
        PerformanceManagementTest.EndToEndTestWrapper testData = new PerformanceManagementTest.EndToEndTestWrapper();

        // Insert 10 job Performance Targets
        testData.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            10,
            'surveyIndicator',
            null,
            null,
            null,
            null,
            null,
            null
        );
        // Insert 15 Indicator Performance Targets (with no job template)
        testData.initJobPerformanceTargetWrappers(
                                                PerformanceTargetDO.TIMEFRAME_WEEKLY,
                                                15,
                                                'surveyJob1');

        // Initialize the page
        Test.startTest();
        IndicatorManagerController page = new IndicatorManagerController();
        Test.stopTest();

        // Assert correct creation of the list
        System.AssertEquals(10, page.targetList.size(), 'There should be 10 Indicators Target');

    }

    /**
     * Test to verify correct order of the manager at page load
     */
    static testMethod void testCorrectInitialOrder() {

        PerformanceTarget__c target1 = new PerformanceTarget__c(Name = 'target1',
                                                    Timeframe__c = PerformanceTargetDO.TIMEFRAME_MONTHLY,
                                                    DefaultValue__c = 50,
                                                    Type__c = PerformanceTargetDO.TYPE_INDICATOR,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        // Insert and wait
        insert target1;
        C.wait(1);

        PerformanceTarget__c target2 = new PerformanceTarget__c(Name = 'target2',
                                                    Timeframe__c = PerformanceTargetDO.TIMEFRAME_MONTHLY,
                                                    DefaultValue__c = 50,
                                                    Type__c = PerformanceTargetDO.TYPE_INDICATOR,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        // Insert and wait
        insert target2;
        C.wait(1);
        PerformanceTarget__c target3 = new PerformanceTarget__c(Name = 'target3',
                                                    Timeframe__c = PerformanceTargetDO.TIMEFRAME_MONTHLY,
                                                    DefaultValue__c = 50,
                                                    Type__c = PerformanceTargetDO.TYPE_INDICATOR,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        // Insert and wait
        insert target3;
        C.wait(1);

        Test.startTest();
        IndicatorManagerController page = new IndicatorManagerController();
        Test.stopTest();
        // Assert correct creation of the list
        System.AssertEquals(3,page.targetList.size(), 'There should be 3 Indicators Target');

        // Assert the order of the targets
        system.AssertEquals(target3.Id, page.targetList[0].Id, 'The order is not correct');
        system.AssertEquals(target2.Id, page.targetList[1].Id, 'The order is not correct');
        system.AssertEquals(target1.Id, page.targetList[2].Id, 'The order is not correct');

    }

    /**
     * Test to verify correct close of the performance indicator
     */
    static testMethod void testClosePerformance() {
        // Create test data

        PerformanceTarget__c target1 = new PerformanceTarget__c(Name = 'target1',
                                                    Timeframe__c = 'monthly',
                                                    Status__c = PerformanceTargetDO.STATUS_ACTIVE,
                                                    DefaultValue__c = 50,
                                                    Type__c = PerformanceTargetDO.TYPE_INDICATOR,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        PerformanceTarget__c target2 = new PerformanceTarget__c(Name = 'target2',
                                                    Timeframe__c = 'monthly',
                                                    Status__c = PerformanceTargetDO.STATUS_ACTIVE,
                                                    DefaultValue__c = 50,
                                                    Type__c = PerformanceTargetDO.TYPE_INDICATOR,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        PerformanceTarget__c target3 = new PerformanceTarget__c(Name = 'target3',
                                                    Timeframe__c = 'monthly',
                                                    Status__c = PerformanceTargetDO.STATUS_ACTIVE,
                                                    DefaultValue__c = 50,
                                                    Type__c = PerformanceTargetDO.TYPE_INDICATOR,
                                                    StartDate__c = Date.today(),
                                                    EndDate__c = Date.today());
        // Insert performance
        insert new List<PerformanceTarget__c>{target1, target2, target3};
        Test.startTest();
        IndicatorManagerController page = new IndicatorManagerController();

        page.currentTargetId = target1.Id;
        page.closeTarget();
        Test.stopTest();
        List<PerformanceTarget__c> performanceTargets =
                                         [SELECT Id,
                                                 Status__c,
                                                 CloseReason__c
                                          FROM
                                                PerformanceTarget__c];
        system.assertEquals(3, performanceTargets.size(), 'There should be 3 performance targets');
        for (PerformanceTarget__c target: performanceTargets) {
            if (target.Id == target1.Id) {
                system.assertEquals(PerformanceTargetDO.STATUS_CLOSED,
                                        target.Status__c, 'the target should be closed');
                system.assertEquals(PerformanceTargetDO.CLOSE_MANUALLY, target.CloseReason__c,
                                        'the target should be closed manually');
            } else {
                system.assertEquals(PerformanceTargetDO.STATUS_ACTIVE, target.Status__c,
                                        'the target should be active');
            }
        }
    }
}
