/**
 * Trigger for the Mobile_User__c object
 * It just delegate the beavior to the logic class
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
trigger MobileUser on Mobile_User__c (after insert, after update, after delete) {
    if(Trigger.isInsert) {
        MobileUserTriggerLogic.afterInsert(Trigger.new, Trigger.newMap);
    }
    else if(Trigger.isUpdate) {
        MobileUserTriggerLogic.afterUpdate(
            Trigger.old,
            Trigger.oldMap,
            Trigger.new,
            Trigger.newMap
        );
    }
    else {
        MobileUserTriggerLogic.afterDelete(Trigger.old);
    }
}
