/**
 * This test class is used to cover ProcessAnswerRecordsBatch class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
private class ProcessAnswerRecordsBatchTest {

    static testMethod void testProcessAnswerRecords() {
        // The query used by the batch job.
        String parentAnswersQuery = 
            'SELECT ' +
                'Instance__c, ' +
                'Question__r.Id, ' +
                'Question__r.MaxInstance__c ' +
            'FROM ' +
                'Answer__c ';

        // Create answer records test data which will need testing
        List<Answer__c> listAnswer = AnswersTriggerTest.createAfterUpdatePreConditions(2, 3);
        insert listAnswer;
        Test.startTest();
        ProcessAnswerRecordsBatch processAnswerRecordsBatchInstance =
            new ProcessAnswerRecordsBatch(parentAnswersQuery);
        Database.executeBatch(processAnswerRecordsBatchInstance);
        Test.stopTest();

        // Verify batch worked properly
        if (listAnswer != null && !listAnswer.isEmpty()) {
            System.assertEquals(
                3, 
                [
                    SELECT
                        Question__r.MaxInstance__c
                    FROM
                        Answer__c
                    WHERE
                        Id = :listAnswer[0].Id
                ].Question__r.MaxInstance__c);
        }
    }
}