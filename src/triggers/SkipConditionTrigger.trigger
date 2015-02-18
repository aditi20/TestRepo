/**
 * Trigger for SkipCondition__c database operations. Acts as dispatcher to SkipConditionTriggerLogic class
 *
 * @author Santiago Blankleider
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 */
trigger SkipConditionTrigger on SkipCondition__c (before insert, before update) {
    if(trigger.isBefore){
        if (trigger.isInsert) {
            SkipConditionTriggerLogic.beforeInsert(trigger.new);
        }
        if(trigger.isUpdate){
            SkipConditionTriggerLogic.beforeUpdate(trigger.new);
        }
    }
}