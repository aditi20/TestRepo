/**
 * Test class for the JobTemplateDO
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
@isTest
public with sharing class JobTemplateDOTest {

    /**
     * Create Job Template record
     */
    public static JobTemplate__c createRecord(
            String name,
            String status,
            String instructions
    ) {
        return new JobTemplate__c(
            Name = name,
            Status__c = status,
            Instructions__c = instructions
        );
    }

    /**
     * Create Published Job Template record with collect data task
     */
    public static JobTemplate__c createPublishedDataCollectionRecord(
            String jobName,
            String surveyName
    ) {
        // Add a Job wth a collect data task
        Survey__c survey = SurveyDOTest.createInsertedSurvey(surveyName);

        SurveyVersion__c surveyVersion = SurveyDO.publishSurvey(survey);

        JobTemplate__c jobTemplate = JobTemplateDOTest.createRecord(
            jobName,
            JobTemplateDO.STATUS_DRAFT,
            ''
        );
        JobTemplateDO jobTemplateDomainInstance =
            new JobTemplateDO.Constructor().constructWithRecords(
                new List<JobTemplate__c> {jobTemplate}
            );
        jobTemplateDomainInstance.insertRecords();

        TaskTemplate__c task = TaskTemplateDOTest.createRecord(
            'taskName',
            jobTemplate,
            TaskTemplateDO.TYPE_FORM,
            surveyVersion,
            1
        );
        TaskTemplateDO taskTemplateDomainInstance =
            new TaskTemplateDO.Constructor().constructWithRecords(
                new List<TaskTemplate__c> {task}
            );
        taskTemplateDomainInstance.insertRecords();

        // Publish job
        jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        jobTemplateDomainInstance.updateRecords();

        return jobTemplate;
    }
}