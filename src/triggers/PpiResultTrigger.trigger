/**
 * Trigger for PpiResult__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
trigger PpiResultTrigger on PpiResult__c (before insert, after insert) {
    TriggerHandler.triggerHandler(PpiResultDomain.class);
}