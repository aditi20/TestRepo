/**
 * Test class for the TaskTemplateDO
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class TaskTemplateDOTest {

    /**
     * Create Task Template record
     */
    public static TaskTemplate__c createRecord(
            String name,
            JobTemplate__c job,
            String taskType,
            SurveyVersion__c version,
            Integer position
    ) {
        return new TaskTemplate__c(
            Name = name,
            JobTemplate__c = job.Id,
            Type__c = taskType,
            Form__c = version.Id,
            Position__c = position
        );
    }
}