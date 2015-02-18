/**
 * Trigger for the Score Value object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
trigger ScoreValueTrigger on ScoreValue__c (after insert, after update) {
    TriggerHandler.triggerHandler(ScoreValueDomain.class);
}