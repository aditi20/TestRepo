/**
 * This test class is used to unit test ProcessExistingSkipConditionsBatch class
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author : Kaushik Ray
 */
@isTest
private class ProcessExistingSkipConditionsBatchTest {

    /**
     * Test to verify that batch updates all Value__c value properly to SkipValue__c
     */
    static testMethod void testProcessExistingSkipConditions() {
        String skipConditionsQuery = 
            'SELECT ' +
                'Id, ' +
                'Value__c, ' +
                'SkipValue__c ' +
            'FROM ' +
                'SkipCondition__c';

        List<SkipCondition__c> listConditions = TestUtils.createSkipConditions();
        TestUtils.insertSkipConditionRecords(listConditions);

        // Verify that all skip condition records have no data in newly created SkipValue__c
        System.assertEquals(
            listConditions.size(),
            [
                SELECT
                    SkipValue__c
                FROM
                    SkipCondition__c
                WHERE
                    SkipValue__c = null
            ].size()
        );

        Test.startTest();
        ProcessExistingSkipConditionsBatch processExistingSkipConditionsBatchInstance =
            new ProcessExistingSkipConditionsBatch(skipConditionsQuery);
        Database.executeBatch(processExistingSkipConditionsBatchInstance);
        Test.stopTest();

        // Verify that all skip condition record's Value__c data is transferred to SkipValue__c
        System.assertEquals(
            listConditions.size(),
            [
                SELECT
                    SkipValue__c
                FROM
                    SkipCondition__c
                WHERE
                    SkipValue__c != null
            ].size()
        );
    }
}