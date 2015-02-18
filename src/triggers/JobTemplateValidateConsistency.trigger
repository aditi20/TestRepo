/*
* Trigger that validates that all Hierarchies related to Tasks are in the Database.
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*/
trigger JobTemplateValidateConsistency on TaskTemplate__c ( before insert, before update ) {

    List<TaskTemplate__c> listTaskTemplates              = trigger.new;                 // Obtain tasks that are being inserted or updated.  
    Set<Id> setVersions                                  = new Set<Id>();               // Set of version Id's of collect data tasks.
    Map<Id, Set<String>> mapVersionUnavailableQuestions  = new Map<Id, Set<String>>();  // Map relating versions and questions that cannot be mapped.
    Map<Id, Id> mapVersionSurvey                         = new Map<Id, Id>();           // Map relating versions and surveys, with the format: <version,Id, survey.Id>.
    
    // Obtain Set of JobTemplate Ids parents from selected Task Templates.
    Set<Id> taskTemplateIds = new Set<Id>(); 
    for (TaskTemplate__c task : listTaskTemplates) {
        taskTemplateIds.add(task.JobTemplate__c);

        if(task.Type__c == TaskTemplateDO.TYPE_FORM) {
            // Obtain versions of tasks with mappings.
            setVersions.add(task.Form__c);
        }
    }

    GenericObjectCreator surveyVersionCreator =
        new GenericObjectCreator(SurveyVersion__c.SObjectType);
    surveyVersionCreator.checkObjectAccessible();
    surveyVersionCreator.checkFieldsAccessible(
        new List<Schema.SObjectField> {
            SurveyVersion__c.Survey__c
        }
    );

    // Obtain map of versions related to surveys.
    for (SurveyVersion__c sv : [SELECT Id, Survey__c FROM SurveyVersion__c WHERE Id = :setVersions]) {
        mapVersionSurvey.put(sv.Id, sv.Survey__c);
    }

    GenericObjectCreator questionCreator =
        new GenericObjectCreator(Question__c.SObjectType);
    questionCreator.checkObjectAccessible();
    questionCreator.checkFieldsAccessible(
        new List<Schema.SObjectField> {
            Question__c.Name,
            Question__c.Type__c,
            Question__c.Caption__c,
            Question__c.Survey__c
        }
    );

    // Obtain map of questions (of the survey related to collect tasks) that cannot be mapped, with the format: <Survey.Id, Set<String> (question names)>. 
    for (Question__c question : [SELECT Id, Type__c, Name, Caption__c, Survey__c
                                 FROM Question__c
                                 WHERE Survey__c IN :mapVersionSurvey.values()
                                    AND Type__c IN (:QuestionDO.TYPE_SECTION,
                                                    :QuestionDO.TYPE_REPEAT,
                                                    :QuestionDO.TYPE_STATIC,
                                                    :QuestionDO.TYPE_FINAL,
                                                    :QuestionDO.TYPE_CASCADING_SELECT,
                                                    :QuestionDO.TYPE_CASCADING_LEVEL)]){

        if (!mapVersionUnavailableQuestions.containsKey(question.Survey__c)) {
            mapVersionUnavailableQuestions.put(question.Survey__c, new Set<String>{question.Name});
        }
        else {
            mapVersionUnavailableQuestions.get(question.Survey__c).add(question.Name);
        }
    }

    GenericObjectCreator jobTemplateCreator =
        new GenericObjectCreator(JobTemplate__c.SObjectType);
    jobTemplateCreator.checkObjectAccessible();
    jobTemplateCreator.checkFieldsAccessible(
        new List<Schema.SObjectField> {
            JobTemplate__c.Hierarchy__c
        }
    );

    // Obtain map of JobTemplates related to all tasks in the trigger.
    Map<Id,JobTemplate__c> jobTemplateMap = new Map<Id,JobTemplate__c>( [select Id, Hierarchy__c 
                                                                             from JobTemplate__c 
                                                                             where Id in :taskTemplateIds]);
                                                 
    // Iterate over tasks to see if all objectId data saved in tasks have object Id in the list of Hierarchies.
    for(TaskTemplate__c task : listTaskTemplates){

        // Obtain JobTemplate of this task.
        JobTemplate__c parentJobTemplate = jobTemplateMap.get(task.JobTemplate__c);

        //Obtain Hierarchy objects of the parent JobTemplate.
        List<JobTemplateDo.ObjectHierarchy> 
                          objectHierarchies = (parentJobTemplate.Hierarchy__c != null && parentJobTemplate.Hierarchy__c != '')  
                                                    ? (List<JobTemplateDo.ObjectHierarchy>)
                                                         JSON.deserialize(parentJobTemplate.Hierarchy__c,
                                                         List<JobTemplateDo.ObjectHierarchy>.class)
                                                    : new List<JobTemplateDo.ObjectHierarchy>();

        // Obtain Set of objectId of the Hierarchy of the JobTemplate.
        Set<String> setObjectIds = new Set<String>(); 
        for (JobTemplateDo.ObjectHierarchy objectHierarchy : objectHierarchies) {
            setObjectIds.add(objectHierarchy.objectId);
        }

        // After we obtain the Set of Object Ids of the hierarchies we validates it with the data in the TaskTemplate.   
        if(task.Type__c == TaskTemplateDO.TYPE_FORM) {
            // Validate Mappings in tasks of type "form".
            if( task.Mapping__c != null ){
                Id surveyId                                      = mapVersionSurvey.get(task.Form__c); // Survey Id Related to this task.
                Set<String> setUnavailableQuestions              = mapVersionUnavailableQuestions.get(surveyId); // Set of question names that cannot be mapped.        
                List<JobTemplateDo.TaskMapping> listTaskMappings = (List<JobTemplateDo.TaskMapping>)JSON.deserialize(task.Mapping__c, List<JobTemplateDo.TaskMapping>.class);
                
                for (JobTemplateDo.TaskMapping taskMapping : listTaskMappings) {
                    if( !setObjectIds.contains(taskMapping.objectId) ){
                        // Found a TaskMapping that doesn't have a Hierarchy object with its objectId.
                        task.addError(system.Label.JOB_TEMPLATE_INCONSISTENT_MAPPING + ' ' + task.Name);
                    }
                    if (setUnavailableQuestions.contains(taskMapping.question)) {
                        // It is incorrectly mapped to a question that is not available to be mapped.
                        task.addError(task.Name + ' ' + System.Label.TASK_INCORRECT_MAPPING);
                    }
                }
            }
        }
        else if(task.Type__c == TaskTemplateDO.TYPE_DATA_VIEW){
            // Validate Object in tasks of type "data-view".  
            if( !setObjectIds.contains(task.Object__c) ){
                // Found a Task in which Object__c is not contained in the Hierarchies.
                task.addError(system.Label.JOB_TEMPLATE_INCONSISTENT_OBJECT + ' ' + task.Name);
            }
        }
        // If another type is added we just add an "else if" with the logic inside. 
    }
}