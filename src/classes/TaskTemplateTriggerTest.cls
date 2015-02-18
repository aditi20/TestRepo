/**
 * Grameen: Salesforce - Task Template
 * This is the test class for the Task Template Trigger class.
 * The trigger avoid inserting, deleting or updating a task
 * if its Job Template Status is not Draft.
 * (Related IDALMSA-2640)
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author  Dennys Lopez Dinza
 */
@isTest
private class TaskTemplateTriggerTest {

    /**
     * Helper method to create a TaskTemplate
     *
     * @param name          - Name of the task
     * @param position      - Position of the task in the job template
     * @param jobTemplateId - Id of the jobtemplate asociated to this task
     * @param type          - Type of the task to be created
     * @param objectId      - Id of the object asociated to the object hierarchy on the job template, this is valid in case of view data task
     *
     * @return created tasktemplate
     */
    private static TaskTemplate__c createTask(String name, Integer position, Id jobTemplateId, String type, String objectId){
        TaskTemplate__c task = new TaskTemplate__c(Name = name, Position__c = position,
                JobTemplate__c = jobTemplateId, Type__c = type);

        if (type == TaskTemplateDO.TYPE_DATA_VIEW) {
            task.Object__c = objectId;
        }

        return task;
    }

    /**
     * Helper method to create a JobTemplate with a small object hierarchy associated
     *
     * @param name  - Name of the job template to be created
     * @param satus - Status of the job template
     *
     * @return - Created job template
     */
    private static JobTemplate__c createJobTemplateWithHierarchy(String name, String status) {
        List<JobTemplateDo.ObjectHierarchy> jobTempHier = new List<JobTemplateDo.ObjectHierarchy>();
        JobTemplateDo.ObjectHierarchy oh1 = new JobTemplateDo.ObjectHierarchy('1', 'Contact', 'Contact');
        oh1.addListField('Name');
        oh1.addDetailField('Id');
        oh1.addDetailField('CreatedDate');
        jobTempHier.add(oh1);
        JobTemplate__c jobTemplate = new JobTemplate__c(
            Name = name,
            Status__c = status,
            Hierarchy__c = JSON.serialize(jobTempHier)
        );
        insert jobTemplate;
        return jobTemplate;
    }

    /**
     * Helper method to prepare test data
     *
     * @return list of task templates created for test
     */
    private static List<TaskTemplate__c> prepareTestData() {

        JobTemplate__c jobTemplate =
           createJobTemplateWithHierarchy('Job Template 1', JobTemplateDO.STATUS_DRAFT);

        List <TaskTemplate__c> tasks = new TaskTemplate__c[]{
            createTask('Task 1', 1, jobTemplate.Id, TaskTemplateDO.TYPE_DATA_VIEW, '1'),
            createTask('Task 2', 2, jobTemplate.Id, TaskTemplateDO.TYPE_DATA_VIEW, '1')
        };
        insert tasks;
        return tasks;
    }

    /**
     * Positive: Edit a Task that belongs to a Job Template with Status Draft.
     */
    static testMethod void testEditTaskTemplateDraftJobTemplate() {

        Test.startTest();
        List <TaskTemplate__c> tasks = prepareTestData();

        tasks.get(0).Name = 'Task 1 changed';
        update tasks.get(0);
        Test.stopTest();
        TaskTemplate__c taskLoaded  = [SELECT Id, Name FROM TaskTemplate__c WHERE Id =: tasks.get(0).Id];
        System.assertEquals(
            tasks.get(0).Name, taskLoaded.Name,
            'The new name of modified task must be "' + tasks.get(0).Name + '"'
        );
    }

    /**
     * Positive: Delete a Task that belongs to a Job with Status Draft.
     */
    static testMethod void testDeleteTaskTemplateDraftJobTemplate() {

        Test.startTest();
        List <TaskTemplate__c> tasks = prepareTestData();
        Integer initialCounter = tasks.size();
        System.assertEquals(2, initialCounter, 'There must be 2 saved tasks.');
        delete tasks.get(0);
        Test.stopTest();

        List <TaskTemplate__c> taskLoaded  = [SELECT Id, Name FROM TaskTemplate__c];
        System.assert(
            initialCounter > taskLoaded.size(), 'There must be a low number of tasks because any task has been deleted.'
        );
    }

    /**
     * Negative: Avoid Inserting a Task that belongs to a Published Job.
     */
    static testMethod void testAvoidInsertingTaskPublishedJobTemplate() {

        List <TaskTemplate__c> tasks = prepareTestData();
        JobTemplate__c jobTemplate = [SELECT Status__c FROM JobTemplate__c WHERE Id =:tasks[0].JobTemplate__c];

        jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        update jobTemplate;

        String errMsg;

        Test.startTest();
        try {
            TaskTemplate__c newTask = createTask('Task 3', 3, jobTemplate.Id, TaskTemplateDO.TYPE_DATA_VIEW, '1');
            insert newTask;
            System.assert(
                false,
                'The new task should not have been inserted because the Job Template Status is Published.'
            );
        }
        catch (System.DmlException e) {

            System.assertEquals(System.Label.AVOID_EDIT_DELETE_TASK_PUBLISHED_JOB_TEMPLATE_MSG, e.getDmlMessage(0));
        }
        Test.stopTest();
        List <TaskTemplate__c> tasksLoaded  = [SELECT Id FROM TaskTemplate__c WHERE JobTemplate__c =: jobTemplate.Id];

        System.assertEquals(tasks.size(), tasksLoaded.size(), 'The number of saved task must be ' + tasks.size());
    }

    /**
     * Negative: Avoid Inserting a Task that belongs to a Closed Job.
     */
    static testMethod void testAvoidInsertingTaskClosedJobTemplate() {

        List <TaskTemplate__c> tasks = prepareTestData();
        JobTemplate__c jobTemplate = [SELECT Status__c FROM JobTemplate__c WHERE Id =:tasks[0].JobTemplate__c];

        jobTemplate.Status__c = JobTemplateDO.STATUS_CLOSED;
        update jobTemplate;
        Integer initialCounter = tasks.size();
        Test.startTest();
        try {
            TaskTemplate__c newTask = createTask('Task 3', 3, jobTemplate.Id, TaskTemplateDO.TYPE_DATA_VIEW, '1');
            insert newTask;
            System.assert(false, 'The new task should not have been inserted because the Job Status is Closed.');
        }
        catch (System.DmlException e) {
            System.assertEquals(System.Label.AVOID_EDIT_DELETE_TASK_PUBLISHED_JOB_TEMPLATE_MSG, e.getDmlMessage(0));
        }
        Test.stopTest();
        List<TaskTemplate__c> tasksLoaded  = [SELECT Id FROM TaskTemplate__c WHERE JobTemplate__c =: jobTemplate.Id];
        System.assertEquals(initialCounter, tasksLoaded.size(), 'The number of saved task must be ' + initialCounter);
    }

    /**
     * Negative: Avoid Editing a Task that belongs to a Published Job.
     */
    static testMethod void testAvoidEditingTaskPublishedJobTemplate() {

        List <TaskTemplate__c> tasks = prepareTestData();
        JobTemplate__c jobTemplate = [SELECT Status__c FROM JobTemplate__c WHERE Id =:tasks[0].JobTemplate__c];

        jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        update jobTemplate;

        String originalName = tasks.get(0).Name;

        Test.startTest();
        try {
            tasks.get(0).Name = originalName  + ' changed';
            update tasks;
            System.assert(false, 'The new task should not have been updated because the Job Status is Published.');
        }
        catch (Exception e) {
            System.assertEquals(System.Label.AVOID_EDIT_DELETE_TASK_PUBLISHED_JOB_TEMPLATE_MSG, e.getDmlMessage(0));
        }
        Test.stopTest();
        TaskTemplate__c taskLoaded  = [SELECT Id, Name FROM TaskTemplate__c WHERE Id =: tasks.get(0).Id];
        System.assertEquals(originalName, taskLoaded.Name, 'The new name of modified task must be "' + originalName + '"');
    }

    /**
     * Negative: Avoid Editing a Task that belongs to a Closed Job.
     */
    static testMethod void testAvoidEditingTaskClosedJobTemplate() {

        List<TaskTemplate__c> tasks = prepareTestData();
        JobTemplate__c jobTemplate = [SELECT Status__c FROM JobTemplate__c WHERE Id =:tasks[0].JobTemplate__c];

        jobTemplate.Status__c = JobTemplateDO.STATUS_CLOSED;
        update jobTemplate;

        String originalName = tasks.get(0).Name;
        Test.startTest();
        try {
            tasks.get(0).Name = originalName  + ' changed';
            update tasks;
            System.assert(false, 'The new task should not have been updated because the Job Template Status is Closed.');
        }
        catch (System.DmlException e) {
            System.assertEquals(System.Label.AVOID_EDIT_DELETE_TASK_PUBLISHED_JOB_TEMPLATE_MSG, e.getDmlMessage(0));
        }
        Test.stopTest();
        TaskTemplate__c taskLoaded  = [SELECT Id, Name FROM TaskTemplate__c WHERE Id =: tasks.get(0).Id];
        System.assertNotEquals(
            originalName + ' changed' ,
            taskLoaded.Name,
            'The new name of modified task must be "' + originalName + '"'
        );
    }

    /**
     * Negative: Avoid Deleting a Task that belongs to a Published Job.
     */
    static testMethod void testAvoidDeleteTaskPublishedJobTemplate() {

        List <TaskTemplate__c> tasks = prepareTestData();
        JobTemplate__c jobTemplate = [SELECT Status__c FROM JobTemplate__c WHERE Id =:tasks[0].JobTemplate__c];

        Integer initialCounter = tasks.size();

        System.assertEquals(2, initialCounter, 'There must be 2 saved tasks.');
        jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        update jobTemplate;
        Test.startTest();
        try {
            delete tasks.get(0);
            System.assert(false, 'The new task should not have been deleted because the Job Status is Published.');
        }
        catch (System.DmlException e){
            System.assertEquals(System.Label.AVOID_EDIT_DELETE_TASK_PUBLISHED_JOB_TEMPLATE_MSG, e.getDmlMessage(0));
        }
        Test.stopTest();
        List <TaskTemplate__c> taskLoaded  = [SELECT Id, Name FROM TaskTemplate__c];
        System.assertEquals(
            initialCounter,
            taskLoaded.size(),
            'There must be same number of records because none was deleted.'
        );
    }

    /**
     * Negative: Avoid Deleting a Task that belongs to a Closed Job.
     */
    static testMethod void testAvoidDeleteTaskClosedJobTemplate() {

        List <TaskTemplate__c> tasks = prepareTestData();
        JobTemplate__c jobTemplate = [SELECT Status__c FROM JobTemplate__c WHERE Id =:tasks[0].JobTemplate__c];

        Integer initialCounter = tasks.size();

        System.assertEquals(2, initialCounter, 'There must be 2 saved tasks.');

        jobTemplate.Status__c = JobTemplateDO.STATUS_CLOSED;
        update jobTemplate;

        String errMsg;

        Test.startTest();
        try{
            delete tasks.get(0);
            System.assert(false, 'The new task should not have been deleted because the Job Status is Closed.');
        }
        catch (System.DmlException e){
            System.assertEquals(System.Label.AVOID_EDIT_DELETE_TASK_PUBLISHED_JOB_TEMPLATE_MSG, e.getDmlMessage(0));
        }
        Test.stopTest();
        List<TaskTemplate__c> taskLoaded  = [SELECT Id, Name FROM TaskTemplate__c];
        System.assertEquals(
            initialCounter,
            taskLoaded.size(),
            'There must be same number of records because none was deleted.'
        );
    }
}