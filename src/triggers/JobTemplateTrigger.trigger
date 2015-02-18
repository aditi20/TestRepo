/*
* Trigger to avoid publishing Job Template with related Form Status Draft and Delete non Draft Job Templates
* <p>
* - When event before to update task launchs to Publish a Job Template it verify if any Survey Form Status Draft exists.
* If it's true an error message is shown avoiding execution of required action.
* When try to delete check the status is draft, otherwise launch an error.
* - When closing a Job check if it has some Job Target related and close them
* (Related IDALMSA-2640, IDALMSA-3114)
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
* @author Dennys Lopez Dinza
* @author Ernesto Quesada
*/
trigger JobTemplateTrigger on JobTemplate__c (before update, before delete, before insert) {

    if (Trigger.isInsert) {

        JobTemplateTriggerLogic.beforeInsert(trigger.old,
                                            trigger.oldMap,
                                            trigger.new,
                                            trigger.newMap);
    } else if (Trigger.isUpdate) {
        JobTemplateTriggerLogic.beforeUpdate(trigger.old,
                                            trigger.oldMap,
                                            trigger.new,
                                            trigger.newMap); 
    } else if (Trigger.isDelete){
        JobTemplateTriggerLogic.beforeDelete(trigger.old,
                                            trigger.oldMap);
    }

}
