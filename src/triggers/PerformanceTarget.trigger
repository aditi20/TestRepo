/**
 * Trigger for the PerformanceTarget object
 * It just delegate the beavior to the logic class
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 * @author Santiago Blankleider
 */
trigger PerformanceTarget on PerformanceTarget__c (before update, before insert) {
    if(trigger.isUpdate){
        PerformanceTargetTriggerLogic.beforeUpdate(
            trigger.old,
            trigger.oldMap,
            trigger.new,
            trigger.newMap
        );
    }

    else if(trigger.isInsert){
        PerformanceTargetTriggerLogic.beforeInsert(
            trigger.new
        );
    }
}
