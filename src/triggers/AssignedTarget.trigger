/**
 * Trigger for the AssignedTarget__c object
 * It just delegate the beavior to the logic class
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
trigger AssignedTarget on AssignedTarget__c (before insert, before update) {
    if(Trigger.isInsert) {
        AssignedTargetTriggerLogic.beforeInsert(trigger.new, trigger.newMap);
    }
    else {
        AssignedTargetTriggerLogic.beforeUpdate(
            trigger.old,
            trigger.oldMap,
            trigger.new,
            trigger.newMap
        );
    }
}
