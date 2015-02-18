/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 * 
 * Trigger created in order to avoid deletion of a Document if it is related to a task
 */
trigger DeleteResource on ContentDocument (before delete) {

    GenericObjectCreator taskTemplateCreator =
        new GenericObjectCreator(TaskTemplate__c.SObjectType);
    taskTemplateCreator.checkObjectAccessible();
    taskTemplateCreator.checkFieldsAccessible(
        new List<Schema.SObjectField> {
            TaskTemplate__c.ResourceId__c
        }
    );

    GenericObjectCreator jobTemplateCreator =
        new GenericObjectCreator(JobTemplate__c.SObjectType);
    jobTemplateCreator.checkObjectAccessible();
    jobTemplateCreator.checkFieldsAccessible(
        new List<Schema.SObjectField> {
            JobTemplate__c.Status__c
        }
    );

    // Obtain tasks that are related to a triggered ContentDocument.
    List<TaskTemplate__c> listTasks = [SELECT Id, ResourceId__c, JobTemplate__r.Status__c FROM TaskTemplate__c WHERE ResourceId__c IN :Trigger.oldMap.keySet()];

    for (TaskTemplate__c task : listTasks) {
        if (task.JobTemplate__r.Status__c != JobTemplateDO.STATUS_CLOSED) {
            // It is not a closed job, so we should raise an error to each ContentDocument related to these tasks. 
            Trigger.oldMap.get(task.ResourceId__c).addError(System.Label.RESOURCE_CANT_BE_REMOVED_REFERENCED_BY_TASK);
        } 
    }

}