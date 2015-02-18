/**
 * Logic class for the trigger on PerformanceTarget__c
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 * @author Ernesto Quesada
 */
public with sharing class PerformanceTargetTriggerLogic {

    // Jobs related to the performance targets
    private static Map<Id, JobTemplate__c> relatedJobs;
    // Jobs already related to a performance target
    private static Set<Id> alreadyUsedJobs;


    //--------------------------------------------------------------------------
    // Actions carried out before a DML action
    //--------------------------------------------------------------------------
    /**
     * Before Insert
     *
     * Check to be carried out:
     *  - Check the related jobs are valid
     *
     * Actions carried out:
     *  - Correct dates are set acording to the timeframe
     *
     * @param triggerNewList - The list of surveys being inserted by the trigger
     */
    public static void beforeInsert(
            List<PerformanceTarget__c> triggerNewList
    ) {
        relatedJobs = getRelatedJobsMap(triggerNewList);
        alreadyUsedJobs = JobTemplateDO.getJobsUsedByNonClosedTargets();
        Map<String,PerformanceTarget__c> activePerformancesByName =
            performanceTargetDO.getActivePerformanceTargetsByName();
        for (PerformanceTarget__c performanceTarget : triggerNewList) {

            // Check if the name can be used
            if (activePerformancesByName.get(performanceTarget.Name) != null) {
                performanceTarget.addError(System.Label.PERFORMANCE_TARGET_ERROR_NAME_EXIST);
            }

            // Set the correct dates acording to the timeframe
            PerformanceTargetDO.setPeriodDates(performanceTarget);

            if (performanceTarget.Type__c == PerformanceTargetDO.TYPE_JOB_TARGET) {
                validateRelatedJob(performanceTarget, null);
            }
        }
    }

    /**
     * Before Update
     *
     * Check to be carried out:
     *  - The timeframe cannot be changed
     *  - The related job must be published and not used by another target
     *
     * Actions carried out:
     *  - Create the assigned targets for the next time period
     *  - Close the assigned targets of a performance target that is being closed
     *
     * @param triggerOldList - The list of the old versions of the surveys.
     * @param triggerOldMap  - A map of the old versions of the surveys.
     * @param triggerNewList - The list of surveys being inserted by the trigger
     * @param triggerNewMap  - A map of the new versions of the surveys.
     */
    public static void beforeUpdate(
            List<PerformanceTarget__c> triggerOldList,
            Map<Id, PerformanceTarget__c> triggerOldMap,
            List<PerformanceTarget__c> triggerNewList,
            Map<Id, PerformanceTarget__c> triggerNewMap
    ) {
        relatedJobs = getRelatedJobsMap(triggerNewList);
        alreadyUsedJobs = JobTemplateDO.getJobsUsedByNonClosedTargets();

        List <AssignedTarget__c> assignmentsToUpdate = new List<AssignedTarget__c>();

        Map<Id, List<AssignedTarget__c>> assignedTargetByPerformance =
            AssignedTargetDO.getActiveAssignedTargetsByPerformanceTarget(
                triggerOldMap.keyset()
            );

        // A map by id, with the active performance targets with a new end date
        Map<Id, PerformanceTarget__c> targetsWithNewDate = new Map<Id, PerformanceTarget__c>();

        Map<String,PerformanceTarget__c> activePerformancesByName =
            performanceTargetDO.getActivePerformanceTargetsByName();

        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        for (PerformanceTarget__c target : triggerNewList) {

             // Check if the name can be used
            if (
                    activePerformancesByName.get(target.Name) != null && 
                    activePerformancesByName.get(target.Name).Id != target.Id
            ) {
                target.addError(System.Label.PERFORMANCE_TARGET_ERROR_NAME_EXIST);
            }

            // Check if timeframe was changed
            if (target.Timeframe__c != triggerOldMap.get(target.Id).Timeframe__c) {
                target.addError(System.Label.PERFORMANCE_TARGET_TIMEFRAME_CANNOT_CHANGE);
            }

            // Check if the end date was changed
            if (
                target.Status__c == PerformanceTargetDO.STATUS_ACTIVE
                && target.EndDate__c != triggerOldMap.get(target.Id).EndDate__c
            ) {
                // Set the correct dates acording to the timeframe
                PerformanceTargetDO.setPeriodDates(target);
                targetsWithNewDate.put(target.Id, target);
            }

            // Check if the target is being closed and if it has any assigned targets, close them
            if (
                    !target.Status__c.equals(triggerOldMap.get(target.Id).Status__c)
                    && target.Status__c.equals(PerformanceTargetDO.STATUS_CLOSED)
                    && assignedTargetByPerformance.get(target.Id) != null
            ) {
                for (AssignedTarget__c assignedTarget : assignedTargetByPerformance.get(target.Id)) {
                    assignedTargetCreator.populateFields(
                        assignedTarget,
                        new Map<Schema.SObjectField, Object>{
                            AssignedTarget__c.Status__c => AssignedTargetDO.STATUS_CLOSED
                        }
                    );
                    assignmentsToUpdate.add(assignedTarget);
                }
            }

            if (target.Type__c == (PerformanceTargetDO.TYPE_JOB_TARGET)) {
                validateRelatedJob(target, triggerOldMap);
            }
        }
        assignedTargetCreator.checkObjectUpdateable();
        update assignmentsToUpdate;

        // Close the old assigned targets and generate the new ones
        AssignedTargetDO.generateNextPeriodTargets(targetsWithNewDate);
    }

    /**
     * Before Delete
     *
     * Checks to be carried out:
     *
     * Actions carried out:
     *
     * @param triggerOldList - The list of surveys being deleted by the trigger
     */
    public static void beforeDelete(List<PerformanceTarget__c> triggerOldList) {

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
     * @param triggerNewList - The list of surveys being inserted by the trigger
     */
    public static void afterInsert(
            List<PerformanceTarget__c> triggerNewList,
            Map<Id, PerformanceTarget__c> triggerNewMap
    ) {

    }

    /**
     * After Update
     *
     * Checks to be carried out:
     *
     * Actions carried out:
     *
     * @param triggerNewList - The list of surveys being inserted by the trigger
     * @param triggerNewMap  - A map of the new versions of the surveys.
     */
    public static void afterUpdate(
            List<PerformanceTarget__c> triggerNewList,
            Map<Id, PerformanceTarget__c> triggerNewMap
    ) {

    }

    /**
     * After Delete
     *
     * Checks to be carried out:
     *
     * Actions carried out:
     *
     * @param triggerOldList - The list of surveys being deleted by the trigger
     */
    public static void afterDelete(List<PerformanceTarget__c> triggerOldList) {

    }

    //--------------------------------------------------------------------------
    // Helper methods
    //--------------------------------------------------------------------------

    /**
     * Check that the related job is valid for the given performance target
     *
     * @param jobTarget - The job target to validate
     * @param triggerOldMap - The map of the old records
     */
    private static void validateRelatedJob(
            PerformanceTarget__c jobTarget,
            Map<Id, PerformanceTarget__c> triggerOldMap
    ) {
        if (!jobIsPublished(jobTarget.JobTemplate__c)) {
            jobTarget.addError(System.Label.JOB_TARGET_ERR_JOB_NOT_PUBLISHED);
        } else if (relatedJobIsAlreadyUsed(jobTarget, triggerOldMap)) {
            jobTarget.addError(System.Label.JOB_TARGET_ERR_JOB_USED);
        }
    }

    /**
     * Check the status of the related job
     *
     * @param jobId - The id of the job to validate
     *
     * @return - True if the related job is not published
     */
    private static Boolean jobIsPublished(Id jobId) {
        return relatedJobs.get(jobId).Status__c == JobTemplateDO.STATUS_PUBLISHED;
    }

    /**
     * Check if the related job is in use by another performance target
     *
     * @param jobTarget     - The job target to check
     * @param triggerOldMap - The map of the old records
     *
     * @return - True if the related job is used by another job target
     */
    private static Boolean relatedJobIsAlreadyUsed(
            PerformanceTarget__c jobTarget,
            Map<Id, PerformanceTarget__c> triggerOldMap
    ) {
        return (
            alreadyUsedJobs.contains(jobTarget.JobTemplate__c) &&
            (
                triggerOldMap == null ||
                jobTarget.JobTemplate__c != triggerOldMap.get(jobTarget.Id).JobTemplate__c
            )
        );
    }

    /**
     * Build a set with the related jobs
     *
     * @param triggerNewList - The list of performance targets being inserted/updated by the trigger
     *
     * @return - A set with the related jobs
     */
    private static Map<Id, JobTemplate__c> getRelatedJobsMap(
            List<PerformanceTarget__c> triggerNewList
    ) {
        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            JobTemplate__c.Status__c
        });
        Set<Id> jobs = new Set<Id>();
        for (PerformanceTarget__c target : triggerNewList) {
            jobs.add(target.JobTemplate__c);
        }
        return new Map<Id, JobTemplate__c>([
            SELECT
                Status__c
            FROM
                JobTemplate__c
            WHERE
                Id IN :jobs
        ]);
    }
}
