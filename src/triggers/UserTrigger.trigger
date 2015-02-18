/**
 * Trigger for the User object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 *
 * @author - Aditi Satpute
 */
trigger UserTrigger on User (after insert, after update) {
    UserTH.triggerHandler(
        Trigger.isBefore,
        Trigger.isAfter,
        Trigger.isInsert,
        Trigger.isUpdate,
        Trigger.isDelete,
        Trigger.new,
        Trigger.oldMap
    );
}