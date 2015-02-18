/**
 * This Batch class is called after we upgrade package.
 *
 * This batch will process all Skip Condition records and update value from Value__c to SkipValue__c
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author : Kaushik Ray
 */
global class ProcessExistingSkipConditionsBatch implements Database.Batchable<sObject> {

    global final String queryToExecute;

    global ProcessExistingSkipConditionsBatch(String queryToExecute) {
        this.queryToExecute = queryToExecute;
    }

    /**
     * Start method of batch to return all Skip Condition records
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.queryToExecute);
    }

    /**
     * This will populate all Skip Condition records and update SkipValue__c with old Value__c field
     */
    global void execute(Database.BatchableContext BC, List<sObject> skipConditionsToProcess) {
        GenericObjectCreator skipConditionCreator =
            new GenericObjectCreator(SkipCondition__c.SObjectType);
        skipConditionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SkipCondition__c.SkipValue__c,
                SkipCondition__c.Value__c
            }
        );
        List<SkipCondition__c> skipConditionsToUpdate = new List<SkipCondition__c>();
        for (SkipCondition__c skipCondition : (List<SkipCondition__c>)skipConditionsToProcess) {
            if (skipCondition.Value__c != null) {
                skipConditionCreator.populateField(
                    skipCondition,
                    SkipCondition__c.SkipValue__c,
                    skipCondition.Value__c
                );
                skipConditionsToUpdate.add(skipCondition);
            }
        }
        if (skipConditionsToUpdate != null && !skipConditionsToUpdate.isEmpty()) {
            skipConditionCreator.checkObjectUpdateable();
            update skipConditionsToUpdate;
        }
    }

    /**
     * Finish method of batch process.
     */
    global void finish(Database.BatchableContext BC) {
    }
}