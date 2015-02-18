/**
 * Batchable class that will re-calculate all the AssignedTargets for all the
 * Active JobTargets for the current time period.
 * Will only run if Setting__c.ReCalculateJobTargets__c == true
 * The maximum batch size for this is 150 as it loops through the contacts and runs a quesry for each one
 * 
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
global without sharing class JobTargetCleanUpBatch implements Database.Batchable<Id>, Database.Stateful {

    global Map<Id, PerformanceTarget__c> weeklyTargets;
    global Set<Id> weeklyJobTemplates;
    global Map<Id, PerformanceTarget__c> monthlyTargets;
    global Set<Id> monthlyJobTemplates;

    public static final Integer MAX_BATCH_SIZE = 95;

    /**
     * Constructor that just initialises the variables
     */
    global JobTargetCleanUpBatch() {
        this.weeklyTargets = new Map<Id, PerformanceTarget__c>();
        this.weeklyJobTemplates = new Set<Id>();
        this.monthlyTargets = new Map<Id, PerformanceTarget__c>();
        this.monthlyJobTemplates = new Set<Id>();
    }

    /**
     * Start method for the batch.
     * Fetches the performance targets, divides them by timeframe and gets the jobTemplates they are for
     * Also digs out the Contact.Id of the MobileUsers to pass into the execute method of the batch
     */
    global List<Id> start(Database.batchableContext batchableContext) {
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);
        performanceTargetCreator.checkObjectAccessible();
        performanceTargetCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            PerformanceTarget__c.Timeframe__c,
            PerformanceTarget__c.StartDate__c,
            PerformanceTarget__c.EndDate__c,
            PerformanceTarget__c.DefaultValue__c,
            PerformanceTarget__c.Status__c,
            PerformanceTarget__c.JobTemplate__c,
            PerformanceTarget__c.CreatedDate
        });

        List<PerformanceTarget__c> jobTargets;
        // If the flag is set as true run the query of all the performance Targets, else
        // get the ones from the previous day
        if ((ApplicationSettingsUtils.getDefaultSetting(true).ReCalculateJobTargets__c)) {
                jobTargets = [
                    SELECT
                        Id,
                        Timeframe__c,
                        StartDate__c,
                        EndDate__c,
                        DefaultValue__c,
                        Status__c,
                        JobTemplate__c
                    FROM
                        PerformanceTarget__c
                    WHERE
                        Status__c = :PerformanceTargetDO.STATUS_ACTIVE
                    ];
        } else {
            DateTime lastDay = DateTime.now().addDays(-1);
            jobTargets = [
                    SELECT
                        Id,
                        Timeframe__c,
                        StartDate__c,
                        EndDate__c,
                        DefaultValue__c,
                        Status__c,
                        JobTemplate__c
                    FROM
                        PerformanceTarget__c
                    WHERE
                        Status__c = :PerformanceTargetDO.STATUS_ACTIVE
                        AND CreatedDate > :lastDay
                    ];
        }
        
        // if there are no results to process, end the process
        if (jobTargets.size() == 0) {
            return new List<Id>();
        }
        for (PerformanceTarget__c performanceTarget : jobTargets) {
            if (performanceTarget.Timeframe__c.equals(PerformanceTargetDO.TIMEFRAME_WEEKLY)) {
                this.weeklyTargets.put(performanceTarget.Id, performanceTarget);
                this.weeklyJobTemplates.add(performanceTarget.JobTemplate__c);
            } else {
                this.monthlyTargets.put(performanceTarget.Id, performanceTarget);
                this.monthlyJobTemplates.add(performanceTarget.JobTemplate__c);
            }
        }
        return MobileUserDO.getMobileUserContactIds(new List<String>{MobileUserDO.STATUS_ACTIVE});
    }

    /**
     *  Execute method
     */
    global void execute(Database.BatchableContext BC, List<Id> batch) {

        PerformanceManagementUtils.AssignedTargetDataForDML assignedTargetDataForDML =
            new PerformanceManagementUtils.AssignedTargetDataForDML();

        if (!this.weeklyTargets.isEmpty()) {
            calculateTargets(assignedTargetDataForDML, batch, PerformanceTargetDO.TIMEFRAME_WEEKLY,
                this.weeklyJobTemplates, this.weeklyTargets
            );
        }
        if (!this.monthlyTargets.isEmpty()) {
            calculateTargets(
                assignedTargetDataForDML, batch, PerformanceTargetDO.TIMEFRAME_MONTHLY,
                this.monthlyJobTemplates, this.monthlyTargets
            );
        }
        assignedTargetDataForDML.storeData();
    }

    /**
     * Finish method for the batch. Set the controlling flag to false
     */
    global void finish(Database.BatchableContext BC) {
        ApplicationSettingsUtils.setReCalculateJobTarget(false, false);
    }

    /**
     * Re-calculate targets
     *
     * @param assignedTargetDataForDML - Wrapper object that contains the AssignedTargets for DML
     * @param batch                    - Contact.Id of the MobileUsers that are having the targets recalculated
     * @param timeframe                - WEEKLY | MONTHLY - The time frame being looked at
     * @param jobTemplates             - JobTemplate__c.Id that are available to the Mobile Users
     * @param targets                  - The targets that are being recalculated
     *
     * @return - The wrapper object containing the AssignedTargets that need updateing/inserting
     */
    private void calculateTargets(
            PerformanceManagementUtils.AssignedTargetDataForDML assignedTargetDataForDML,
            List<Id> batch,
            String timeframe,
            Set<Id> jobTemplates,
            Map<Id, PerformanceTarget__c> targets
    ) {
        GenericObjectCreator jobCreator =
            new GenericObjectCreator(Job__c.SObjectType);
        jobCreator.checkObjectAccessible();
        jobCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Job__c.Assigned__c,
            Job__c.JobTemplate__c,
            Job__c.StartDate__c
        });

        Map<Id, List<Job__c>> jobsByContact = new Map<Id, List<Job__c>>();
        for (Job__c job : [
                SELECT
                    Assigned__c,
                    JobTemplate__c,
                    StartDate__c
                FROM 
                    Job__c
                WHERE 
                    Assigned__c IN :batch
                    AND JobTemplate__c IN :jobTemplates
                    AND StartDate__c >= :PerformanceTargetDO.getStartOfPreviousTimePeriod(
                        Date.today(), timeframe
                    )
        ]) {
            List<Job__c> contactJobList = jobsByContact.get(job.Assigned__c);
            if (contactJobList == null) {
                contactJobList = new List<Job__c>();
            }
            contactJobList.add(job);
            jobsByContact.put(job.Assigned__c, contactJobList);
        }

        for (Id contactId : batch) {
            assignedTargetDataForDML.combineAssignedTargetDataForDML(
                PerformanceManagementUtils.calculateJobTargets(
                    jobsByContact.get(contactId),
                    targets,
                    contactId,
                    true
                )
            );
        }
    }
}
