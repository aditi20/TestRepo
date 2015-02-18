/**
 * Trigger for Survey__c database operations. Acts as dispatcher to SurveyTriggerLogic class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 * @author - Aditi Satpute
 */
trigger SetPPISurveyName on Survey__c (
        before insert,
        after insert,
        before update,
        after update,
        before delete,
        after delete
) {
    TriggerHandler.triggerHandler(SurveyDO.class);
}