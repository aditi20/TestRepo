/**
 * Trigger for the Answer__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 */
trigger AnswersTrigger on Answer__c (after insert) {

    AnswerTH.triggerHandler(
                        Trigger.isBefore,
                        Trigger.isAfter,
                        Trigger.isInsert,
                        Trigger.isUpdate,
                        Trigger.isDelete,
                        Trigger.new,
                        Trigger.oldMap
    );
}