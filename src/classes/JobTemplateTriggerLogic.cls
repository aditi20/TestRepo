/**
 * Logic class for the trigger on JobTemplate__c
 * TODO - Update class based on SOC
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Ernesto Quesada
 */
public with sharing class JobTemplateTriggerLogic {

    //--------------------------------------------------------------------------
    // Actions carried out before a DML action
    //--------------------------------------------------------------------------
    /**
     * Before Insert
     *
     * Check to be carried out:
     *
     * Actions carried out:
     *  - validate Last Modified Date field in the hierarchy
     *
     * @param triggerOldList - The list of the old versions of the jobTemplates.
     * @param triggerOldMap  - A map of the old versions of the jobTemplates.
     * @param triggerNewList - The list of jobTemplates being inserted by the trigger
     * @param triggerNewMap  - A map of the new versions of the jobTemplates.
     */
    public static void beforeInsert(
            List<JobTemplate__c> triggerOldList,
            Map<Id, JobTemplate__c> triggerOldMap,
            List<JobTemplate__c> triggerNewList,
            Map<Id, JobTemplate__c> triggerNewMap
    ) {
        validateLastModifiedDateFieldInHierarchy(triggerNewList);
    }

    /**
     * Before Update
     *
     * Check to be carried out:
     *
     * Actions carried out:
     *  - Create the assigned targets for the next time period
     *  - Close the assigned targets of a performance target that is being closed
     *
     * @param triggerOldList - The list of the old versions of the jobTemplates.
     * @param triggerOldMap  - A map of the old versions of the jobTemplates.
     * @param triggerNewList - The list of jobTemplates being inserted by the trigger
     * @param triggerNewMap  - A map of the new versions of the jobTemplates.
     */
    public static void beforeUpdate(
            List<JobTemplate__c> triggerOldList,
            Map<Id, JobTemplate__c> triggerOldMap,
            List<JobTemplate__c> triggerNewList,
            Map<Id, JobTemplate__c> triggerNewMap
    ) {
        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Status__c
            }
        );
        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkObjectAccessible();
        taskTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                TaskTemplate__c.Type__c,
                TaskTemplate__c.JobTemplate__c,
                TaskTemplate__c.Mapping__c,
                TaskTemplate__c.Form__c
            }
        );
        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                JobTemplate__c.Status__c,
                JobTemplate__c.Hierarchy__c,
                JobTemplate__c.PublishedDate__c
            }
        );
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);
        performanceTargetCreator.checkObjectAccessible();
        performanceTargetCreator.checkObjectUpdateable();
        performanceTargetCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                PerformanceTarget__c.JobTemplate__c,
                PerformanceTarget__c.CloseReason__c,
                PerformanceTarget__c.Status__c
            }
        );
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Name,
                Question__c.Survey__c
            }
        );

        // Get an associated Survey with Draft Status related to any task of Job Template
        TaskTemplate__c[] tasks =
            [
                SELECT
                    Id,
                    JobTemplate__c,
                    Form__r.Status__c,
                    Type__c
                FROM
                    TaskTemplate__c
                WHERE
                    Type__c = :TaskTemplateDO.TYPE_FORM
                    AND Form__r.Status__c != :JobTemplateDO.STATUS_PUBLISHED
                    AND JobTemplate__c IN :triggerNewList
            ];
                                         
        // Get the performance target of the jobs and create a map of job Id with
        // its active performance (can have 1 as max)
        PerformanceTarget__c[] jobTargets =
            [
                SELECT
                    Id,
                    JobTemplate__c,
                    Status__c
                FROM
                    PerformanceTarget__c
                WHERE
                    JobTemplate__c in :triggerNewList 
                    AND Status__c = :PerformanceTargetDO.STATUS_ACTIVE
                    AND Type__c = :PerformanceTargetDO.TYPE_JOB_TARGET
            ];
        Map<Id, PerformanceTarget__c> jobTargetPerJobTemplate =
            new Map<Id, PerformanceTarget__c>();
        for (PerformanceTarget__c jobTarget: jobTargets) {
            jobTargetPerJobTemplate.put(jobTarget.JobTemplate__c, jobTarget);
        }

        // Close the related job target of the closing job templates 
        boolean closedTarget = false;
        for (JobTemplate__c jobTemplate: triggerNewList) {
            if (triggerOldMap.get(jobTemplate.Id).Status__c != jobTemplate.Status__c
                    && triggerNewMap.get(jobTemplate.Id).Status__c == JobTemplateDO.STATUS_CLOSED
                    && jobTargetPerJobTemplate.get(jobTemplate.Id) != null
            ) {
                performanceTargetCreator.populateFields(
                    jobTargetPerJobTemplate.get(jobTemplate.Id),
                    new Map<Schema.SObjectField, Object> {
                        PerformanceTarget__c.Status__c => PerformanceTargetDO.STATUS_CLOSED,
                        PerformanceTarget__c.CloseReason__c =>
                            PerformanceTargetDO.CLOSE_AUTOMATICALLY
                    }
                );
                closedTarget = true;
            }
        }
        if (closedTarget) {
            update jobTargetPerJobTemplate.values();
        }

        for (TaskTemplate__c task : tasks) {
            if (triggerOldMap.get(task.JobTemplate__c).Status__c == JobTemplateDO.STATUS_DRAFT
                    && triggerNewMap.get(task.JobTemplate__c).Status__c == JobTemplateDO.STATUS_PUBLISHED
            ) {
                if (task.Form__r.Status__c == SurveyDO.STATUS_CLOSED) {
                    triggerNewMap.get(task.JobTemplate__c).addError(
                        System.Label.JOB_TEMPLATE_CANNOT_PUBLISH_CLOSED_SURVEY
                    );
                } else {
                    triggerNewMap.get(task.JobTemplate__c).addError(
                        System.Label.AVOID_PUBLISH_JOB_TEMPLATE_WITH_NONE_PUBLISHED_SURVEYS
                    );
                }
            }
        }

        // Check if any task has a deleted or unexisting question
        // get all the tasks of the job templates
        List<JobTemplate__c> updatedTemplatesWithTasks =
            [
                SELECT
                    Id,
                    Hierarchy__c,
                    PublishedDate__c,
                    (
                        SELECT
                            Id,
                            Mapping__c,
                            Form__c,
                            Form__r.Survey__c
                        FROM
                            Task_Templates__r
                    )
                FROM
                    JobTemplate__c
                WHERE
                    Id IN : triggerNewList
            ];

        Set<Id>  allSurveys = new Set<Id>();

        // Get all the survey ids
        for (JobTemplate__c jobTemplate: updatedTemplatesWithTasks) {
            for (TaskTemplate__c taskTemplate: jobTemplate.Task_Templates__r) {
                allSurveys.add(taskTemplate.Form__r.Survey__c);
            }
        }

        // Get all the questions ordered by survey
        Map<Id,Survey__c>  surveys = new Map<Id,Survey__c>(
            [
                SELECT
                    Id,
                    (
                        SELECT
                            Id,
                            Name
                        FROM Questions__r
                    )
                FROM
                    Survey__c
                WHERE Id IN :allSurveys
            ]
        );

        // Avoid validations when setting preconditions from the tests
        if (!JobTemplateDO.skipUpdateValidation()) {
            for (JobTemplate__c jobTemplate: updatedTemplatesWithTasks) {
                if (
                    triggerOldMap.get(jobTemplate.Id).Status__c == JobTemplateDO.STATUS_DRAFT
                    && triggerNewMap.get(jobTemplate.Id).Status__c == JobTemplateDO.STATUS_PUBLISHED
                ) {
                    //check that the hierarchy objects and fields exists in the org
                    //only execute when publish date different from null to avoid double execution as the WF update again when publishing
                    if (
                        (jobTemplate.Hierarchy__c != null && jobTemplate.Hierarchy__c != '')
                        && (
                            triggerNewMap.get(jobTemplate.Id).PublishedDate__c == null
                            || triggerNewMap.get(jobTemplate.Id).PublishedDate__c == null
                        )
                    ) {
                        Map<String, RemovedDataValidation.MissingData> deletedData = 
                                RemovedDataValidation.obtainMissingDataInBulkFromHierarchy(
                            (List<JobTemplateDo.ObjectHierarchy>)JSON.deserialize(
                                jobTemplate.Hierarchy__c,
                                List<JobTemplateDo.ObjectHierarchy>.class
                            )
                        );

                        if (deletedData != null && !deletedData.isEmpty()){
                            String errorMsg = '';
                            for (String obj:deletedData.keySet()){
                                errorMsg += deletedData.get(obj).toString('Job');
                            }
                            triggerNewMap.get(jobTemplate.Id).Hierarchy__c.addError(errorMsg);
                        }
                    }
                    //check all the task templates
                    for (TaskTemplate__c taskTemplate:jobTemplate.Task_Templates__r){
                        Survey__c taskForm = surveys.get(taskTemplate.Form__r.Survey__c);
                        List<TaskMapping> taskMappings;
                        if (taskTemplate.Mapping__c != null && taskTemplate.Mapping__c != ''){
                            taskMappings= (List<TaskMapping>)JSON.deserialize(taskTemplate.Mapping__c, List<TaskMapping>.class);

                            //check all the mapped questions
                            for(TaskMapping taskMapping:taskMappings){
                                boolean QuestionExists = false;
                                for(Question__c question:taskForm.Questions__r){
                                    if(question.Name == taskMapping.question){
                                        QuestionExists = true;
                                        break;
                                    }

                                }
                                //if some question does not exist, add an error in the jobTemplate
                                if (!QuestionExists){
                                    triggerNewMap.get(jobTemplate.Id).addError(System.Label.JOB_TEMPLATE_WITH_INVALID_TASKS_TEMPLATES_ERR);
                                }
                            }
                        }
                    }
                }
            }
            validateLastModifiedDateFieldInHierarchy(triggerNewList);
        }
    }

    /**
     * Before Delete
     *
     * Checks to be carried out:
     *
     * Actions carried out: 
     *  - Prevents deleting jobs that are not in draft (unless a "delete Job flag" is set)
     *
     * @param triggerOldList - The list of jobTemplates being deleted by the trigger
     * @param triggerOldMap - The Map of jobTemplates being deleted by the trigger
     */
    public static void beforeDelete(
            List<JobTemplate__c> triggerOldList,
            Map<Id, JobTemplate__c> triggerOldMap
    ) {

        // Avoid to delete any Job Template with non Draft status
        Settings__c flagSetting = ApplicationSettingsUtils.getInstanceWithName(C.JOB_DELETE);

        //check if the flag to delete jobs is true, avoid this validation
        if (flagSetting == null) {
            for (JobTemplate__c jobTemplate : triggerOldList) {
                if (jobTemplate.Status__c != JobTemplateDO.STATUS_DRAFT){
                    jobTemplate.addError(System.Label.ERR_DELETE_NON_DRAFT_JOB_TEMPLATE);
                }
            }
        }
    }

    //--------------------------------------------------------------------------
    // Actions carried out after a DML action
    //--------------------------------------------------------------------------
    /**
     * After Insert
     *
     * Checks to be carried out:
     *
     * Actions carried out:
     *
     * @param triggerNewList - The list of jobTemplates being inserted by the trigger
     * @param triggerNewMap  - A map of the new versions of the jobTemplates.
     */
    public static void afterInsert(
            List<JobTemplate__c> triggerNewList,
            Map<Id, JobTemplate__c> triggerNewMap
    ) {

    }

    /**
     * After Update
     *
     * Checks to be carried out:
     *
     * Actions carried out:
     *
     * @param triggerNewList - The list of jobTemplates being inserted by the trigger
     * @param triggerNewMap  - A map of the new versions of the jobTemplates.
     */
    public static void afterUpdate(
            List<JobTemplate__c> triggerNewList,
            Map<Id, JobTemplate__c> triggerNewMap
    ) {

    }

    /**
     * After Delete
     *
     * Checks to be carried out:
     *
     * Actions carried out:
     *
     * @param triggerOldList - The list of jobTemplates being deleted by the trigger
     */
    public static void afterDelete(List<JobTemplate__c> triggerOldList) {

    }
    
    /**
     * Private classes used to help with the JSON Serialization of the job template hierarchy
     */
    public class TaskMapping {

        public String objectId;
        public String field;
        public String question;

        /**
         * Constructor of the class
         *
         * @param objectId   -  id (in the job's JSON hierarchy) of the object to retrieve
         * @param field      - name of the field that contains the value to put on the question
         * @param questionName - name of the question that will be filled with the value on the object's field
         */
        public TaskMapping(String objectId, String field, String questionName) {
            this.objectId = objectId;
            this.field = field;
            this.question = questionName;
        }
    }
    
    /**
     * Validate that the objects in the hierarchies have the last Modified Date Field
     *
     * @param jobs - the jobs to check
     */
    private static void validateLastModifiedDateFieldInHierarchy(List<JobTemplate__c> jobs) {
        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkObjectCreateable();
        jobTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                JobTemplate__c.Hierarchy__c
            }
        );
        for (JobTemplate__c job : jobs) {
            if (job.Hierarchy__c != null && job.Hierarchy__c != '') {

                // Obtain Hierarchy objects of the JobTemplate.
                List<JobTemplateDo.ObjectHierarchy> objectHierarchies =
                    (List<JobTemplateDo.ObjectHierarchy>)JSON.deserialize(
                        job.Hierarchy__c,
                        List<JobTemplateDo.ObjectHierarchy>.class
                    );

                // Check all the objects have the LastModifiedDate field
                for (JobTemplateDo.ObjectHierarchy objectHierarchy : objectHierarchies) {
                    if (
                            DescribeHandler.objectExists(objectHierarchy.objectName) &&
                            !DescribeHandler.fieldExists(objectHierarchy.objectName, C.FIELD_NAME_LASTMODIFIEDDATE)
                    ) {
                      job.Hierarchy__c.addError(System.Label.JOB_TEMPLATE_ERROR_LASTMODIFIEDDATE);
                    }
                }
            }
        }
    }
}