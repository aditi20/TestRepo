/**
 * Test class for the TaskTemplateSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class TaskTemplateSelectorTest {

    private static Survey__c survey1;
    private static Survey__c survey2;

    /**
     * Test method to verify fetching of TaskTemplate records for specified SurveyIds
     */
    static testmethod void testFetchAllForSurveyIds() {
        setUpTestData();

        Test.startTest();
        List<TaskTemplate__c> taskTemplateList =
            new TaskTemplateSelector().getAllForSurveyIds(
                new Set<String> {survey1.Id, survey2.Id}
            );

        // Only one record fetched as Survey2 doesn't have any taskTemplate records
        System.assertEquals(
            1,
            taskTemplateList.size()
        );
        Test.stopTest();
    }

    /**
     * Test method to verify fetching of all TaskTemplate records
     */
    static testmethod void testFetchAllRecords() {
        setUpTestData();

        Test.startTest();
        List<TaskTemplate__c> taskTemplateList =
            new TaskTemplateSelector().getAllRecords();
        Test.stopTest();

        System.assertEquals(
            1,
            taskTemplateList.size()
        );
    }

    /**
     * Method to set up test data for Task Template
     */
    private static void setUpTestData() {
        survey1 = SurveyDOTest.createInsertedSurvey('Survey1');
        survey2 = SurveyDOTest.createInsertedSurvey('Survey2');

        //Publish the version that will be used
        List<SurveyVersion__c> versions =
            new SurveyVersionSelector().getAllWithSurveyIds(
                new Set<String> {survey1.Id, survey2.Id}
            );
        versions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        SurveyVersionDomain surveyVersionDomainInstance =
            new SurveyVersionDomain.Constructor().constructWithRecords(versions);
        surveyVersionDomainInstance.updateRecords();

        // Set up some jobs
        JobTemplate__c job = JobTemplateDOTest.createRecord(
            'JobTemp2',
            JobTemplateDO.STATUS_DRAFT,
            'Instructions'
        );
        JobTemplateDO jobTemplateDomainInstance =
            new JobTemplateDO.Constructor().constructWithRecords(
                new List<JobTemplate__c> {job}
            );
        jobTemplateDomainInstance.insertRecords();

        TaskTemplate__c task = TaskTemplateDOTest.createRecord(
            'taskTemplate',
            job,
            TaskTemplateDO.TYPE_FORM,
            versions[0],
            1
        );
        TaskTemplateDO taskTemplateDomainInstance =
            new TaskTemplateDO.Constructor().constructWithRecords(
                new List<TaskTemplate__c> {task}
            );
        taskTemplateDomainInstance.insertRecords();
    }
}