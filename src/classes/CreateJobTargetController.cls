/*
 * Controller for the CreateJobTarget page
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Santiago Blankleider
 */
public with sharing class CreateJobTargetController extends CreateTargetController {

    // List of all jobs
    public List<SelectOption> jobOptions {get; set;}

    /**
     * Constructor of the class
     *
     * @param stdController - An instance of the standard controller
     */
    public CreateJobTargetController(ApexPages.StandardController stdController) {
        super(stdController);
        this.jobOptions = new List<SelectOption>();
        Set<Id> alreadyUsedJobs = new Set<Id>();

        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);
        performanceTargetCreator.checkObjectAccessible();
        performanceTargetCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                PerformanceTarget__c.JobTemplate__c,
                PerformanceTarget__c.Type__c,
                PerformanceTarget__c.Status__c
            }
        );
        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                JobTemplate__c.Name,
                JobTemplate__c.Status__c
            }
        );

        // New record
        if (this.isEditing) {
            // Adding selected job to show on page
            this.jobOptions.add(
                new SelectOption(
                    this.performanceTarget.JobTemplate__c,
                    this.performanceTarget.JobTemplate__r.Name
                )
            );
        } else {
            // Fill set of job templates that are related to a non-closed performance target
            for (PerformanceTarget__c notClosedPt : [
                    SELECT
                        JobTemplate__c,
                        Type__c
                    FROM
                        PerformanceTarget__c
                    WHERE
                        Status__c != :PerformanceTargetDO.STATUS_CLOSED
                        AND JobTemplate__c != :this.performanceTarget.JobTemplate__c
            ]) {
                alreadyUsedJobs.add(notClosedPt.JobTemplate__c);
            }

            // Fill select options list to show into the select jobs list
            for (JobTemplate__c job : [
                    SELECT
                        Id,
                        Name
                    FROM
                        JobTemplate__c
                    WHERE
                        Status__c = :JobTemplateDO.STATUS_PUBLISHED
                        AND Id NOT IN :alreadyUsedJobs
            ]) {
                this.jobOptions.add(new SelectOption(job.Id, job.Name));
            }
        }
    }

    /**
     * Save performance target with assigned targets to data base
     *
     * @return - The raference of the page to redirect to
     */
    public PageReference save() {
        return this.saveTarget(PerformanceTargetDO.TYPE_JOB_TARGET);
    }
}
