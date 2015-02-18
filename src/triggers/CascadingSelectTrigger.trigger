/*
* Trigger to avoid deletion of used cascading Selects and cascadingNode
* that are currently processing
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
* @author Ernesto Quesada
*/
trigger CascadingSelectTrigger on CascadingSelect__c (before delete) {

    // if it's delete
    if (Trigger.isDelete) {
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.CascadingSelect__c
            }
        );

        // Questions that uses the cascading selects that are gonna be deleted
        Question__c[] questionsUsedByCascadings = [SELECT Id,CascadingSelect__c
                                                   FROM Question__c
                                                   WHERE CascadingSelect__c in :Trigger.oldMap.values()];
        Set<Id> usedCascadings = new Set<Id>();
        
        // put all the used cascading selects into the variable
        for (Question__c q:questionsUsedByCascadings){
            usedCascadings.add(q.CascadingSelect__c);
        }
        
        // check if any of the cascading selects is in processing status or is being used in a survey
        for (CascadingSelect__c cascading:Trigger.oldMap.values()){
            if(cascading.Status__c.equals(C.CASCADING_STATUS_PROCESSING)){
                cascading.addError(system.Label.CASCADING_ERR_DELETE_PROCESSING);
            }
            
            if (usedCascadings.contains(cascading.Id)){
                cascading.addError(system.Label.CASCADING_ERR_DELETE_USED);
            }
            
        }
    }
}
