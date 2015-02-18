/**
 * Test class to cover unit testing for SerializePpiResultsSchedule class
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved.
 *
 * @author - Kaushik Ray
 */
@isTest
private class SerializePpiResultsScheduleTest {

    static testmethod void testSerializePpiResults() {

        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule(
            'SerializePpiResultsTest',
            SerializePpiResultsSchedule.CRON_EXP,
            new SerializePpiResultsSchedule()
        );

        // Get the information from the CronTrigger API object
        CronTriggerSelector cronTriggerSelector = new CronTriggerSelector();
        cronTriggerSelector.addToMainOrderByClause('Id');
        CronTrigger crontrigger = (CronTrigger)cronTriggerSelector.getRecordById(jobId);
        Test.stopTest();

        System.assertEquals(SerializePpiResultsSchedule.CRON_EXP, crontrigger.CronExpression);
        System.assertEquals(0, crontrigger.TimesTriggered);
    }
}