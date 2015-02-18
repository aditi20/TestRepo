/*
 * Trigger to avoid modifying tasks when related the Job Status is different to Draft
 * <p>
 * When events before to insert, update or delete any task launch it verify the related Job Status is Draft.
 * If it's true an error message is shown avoiding execution of required action.
 * (Related IDALMSA-2640)
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Dennys Lopez Dinza
 */
trigger TaskTemplate on TaskTemplate__c (before insert, before update, before delete){

    if (Trigger.isBefore){
        // Iterate over the correct list of records
        TaskTemplate__c[] tasks = (Trigger.isDelete) ? Trigger.old : Trigger.new;

        Set<Id> taskJobsIds = new Set<Id>();
        for(TaskTemplate__c task : tasks){
            taskJobsIds.add(task.JobTemplate__c);
        }

        Map <Id, JobTemplate__c> jobTemplatesMap = new Map <Id, JobTemplate__c> ([ SELECT Id
                                                                                    FROM JobTemplate__c
                                                                                    WHERE Id IN :taskJobsIds
                                                                                    AND Status__c != :JobTemplateDO.STATUS_DRAFT ]);

        for (TaskTemplate__c task : tasks){
            if (jobTemplatesMap.containsKey(task.JobTemplate__c)){
                task.addError(System.Label.AVOID_EDIT_DELETE_TASK_PUBLISHED_JOB_TEMPLATE_MSG);
            }
        }
    }
}