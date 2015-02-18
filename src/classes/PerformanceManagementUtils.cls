/**
 * Utility class for performance management
 *
 * This class has several Inner classes that are here until we decide upon our new architecture structure
 *    - AssignedTargetDataForDML - This is a class that holds the records that need to have DML carried out on them
 *                                    It will be extracted from here and made to be generic
 *    - AssignedTargetActualValueWrapper - Wrapper that hold data needed whilst updating an individual AssignedTarget
 *                                           Can probably stay here
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public without sharing class PerformanceManagementUtils {

    /**
     * Converts a date into a string that is in the format YYYY-MM-dd.
     *
     * @param dateToConvert - The date to convert
     *
     * @return - The formated String
     */
    public static String convertDateToTimePeriod(Date dateToConvert) {
        return DateTime.newInstance(dateToConvert, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
    }

    /**
     * Update the assigned targets for a MobileUser when they submit JobActivities
     *
     * @param completedJobs - The Job__c records that have been successfully saved to the DB
     * @param jobTemplates  - A list of Ids for the JobTemplate__c that the Contact carried out
     * @param contactId     - The Contact.Id for the person that the completed jobs were done by
     */
    public static void updateJobTargets(List<Job__c> completedJobs, Set<Id> jobTemplates, Id contactId) {

        // Get the Active PerformanceTargets
        Map<Id, PerformanceTarget__c> activePerformanceTargets = PerformanceTargetDO.getPerformanceTargetsForJobTemplates(
            jobTemplates,
            new List<String>{PerformanceTargetDO.STATUS_ACTIVE}
        );

        calculateJobTargets(completedJobs, activePerformanceTargets, contactId, false).storeData();
    }

    /**
     * Calculate the 
     *
     * @param completedJobs - The Job__c records that have been successfully saved to the DB
     * @param jobTemplates  - A list of Ids for the JobTemplate__c that the Contact carried out
     * @param contactId     - The Contact.Id for the person that the completed jobs were done by
     * @param overWrite     - Pass true if the original AssignedTarget__c.ActualValue__c should be overWritten.
     *                          False will update the ActualValue
     *
     * @return - A wrapper object that contains a list of AssignedTargets to update and one for insert
     */
    public static AssignedTargetDataForDML calculateJobTargets(
            List<Job__c> completedJobs,
            Map<Id, PerformanceTarget__c> activePerformanceTargets,
            Id contactId,
            Boolean overWrite
    ) {

        // Key to outer map is PerformanceTarget__c.Id. Key to inner map is the start date of the required time periods
        Map<Id, Map<Date, AssignedTargetActualValueWrapper>> assignedTargetsActualValueWrappers =
            new Map<Id, Map<Date, AssignedTargetActualValueWrapper>>();
        Map<Id, PerformanceTarget__c> jobTemplateToPerformanceTargetLookUp = new Map<Id, PerformanceTarget__c>();
        for (PerformanceTarget__c performanceTarget : activePerformanceTargets.values()) {

            // Create a mapping for JobTemplate__c.Id to PerformanceTarget__c
            jobTemplateToPerformanceTargetLookUp.put(performanceTarget.JobTemplate__c, performanceTarget);

            // Init map for JobTarget to AssignedTargets by date
            Map<Date, AssignedTargetActualValueWrapper> aMap = new Map<Date, AssignedTargetActualValueWrapper>();
            assignedTargetsActualValueWrappers.put(
                performanceTarget.Id, aMap
            );
        }

        // Loop through the completed jobs and create the AssignedTargetActualValueWrapper needed
        Date earliestFoundDate = countCompletedJobs(
            completedJobs,
            assignedTargetsActualValueWrappers,
            jobTemplateToPerformanceTargetLookUp
        );

        // Make sure that the earliest date found is back a full previous time period so we get all the previous targets
        earliestFoundDate = PerformanceTargetDO.getStartOfPreviousTimePeriod(earliestFoundDate, PerformanceTargetDO.TIMEFRAME_MONTHLY);

        // Get the Assigned Targets
        List<AssignedTarget__c> previousAssignedTargets = AssignedTargetDO.getAssignedTargetsForContacts(
            activePerformanceTargets.keySet(),
            earliestFoundDate,
            new List<Id>{ contactId }
        );

        // Loop through the found Assigned Targets and add to the AssignedTargetWrappers. Create the wrappers if they are missing
        for (AssignedTarget__c previousAssignedTarget : previousAssignedTargets) {
            Map<Date, AssignedTargetActualValueWrapper> wrapperMap = assignedTargetsActualValueWrappers.get(previousAssignedTarget.PerformanceTarget__c);
            AssignedTargetActualValueWrapper wrapper = wrapperMap.get(previousAssignedTarget.StartDate__c);
            if (wrapper == null) {
                wrapper = new AssignedTargetActualValueWrapper(previousAssignedTarget.StartDate__c);
            }
            wrapper.addAssignedTarget(previousAssignedTarget);
            wrapperMap.put(previousAssignedTarget.StartDate__c, wrapper);
            assignedTargetsActualValueWrappers.put(previousAssignedTarget.PerformanceTarget__c, wrapperMap);
        }

        AssignedTargetDataForDML dataForDML = convertAssignedTargetWrapperToSobject(
            assignedTargetsActualValueWrappers,
            activePerformanceTargets,
            contactId,
            overWrite
        );
        return dataForDML;
    }

    /**
     * Count the completed JobActivities
     * Also extracts the earliest date that a JobActivity was completed
     */
    private static Date countCompletedJobs(
            List<Job__c> completedJobs,
            Map<Id, Map<Date, AssignedTargetActualValueWrapper>> assignedTargetsActualValueWrappers,
            Map<Id, PerformanceTarget__c> jobTemplateToPerformanceTargetLookUp
    ) {
        Date earliestFoundDate = Date.today().toStartOfMonth();
        if (completedJobs == null) {
            return earliestFoundDate;
        }
        for (Job__c completedJob : completedJobs) {
            PerformanceTarget__c performanceTarget =
                jobTemplateToPerformanceTargetLookUp.get(completedJob.JobTemplate__c);
            if (performanceTarget == null) {
                continue;
            }
            updateAssignedTargetWrapper(
                assignedTargetsActualValueWrappers.get(performanceTarget.Id),
                completedJob,
                performanceTarget
            );
            if (earliestFoundDate.daysBetween(completedJob.StartDate__c.date()) < 0) {
                earliestFoundDate = completedJob.StartDate__c.date();
            }
        }
        return earliestFoundDate;
    }

    /**
     * Increase the AssignedTargetActualValueWrapper.
     * This will init the map if needed
     *
     * @param assignedTargetsActualValueWrappers - The map of Assigned targets by PerformanceTarget and Date
     * @param jobActivity                        - The jobActivity to be add to an AssignedTarget
     * @param performanceTarget                  - The performance target that the assigned target is for
     */
    private static void updateAssignedTargetWrapper(
            Map<Date, AssignedTargetActualValueWrapper> assignedTargetsActualValueWrappers,
            Job__c jobActivity,
            PerformanceTarget__c performanceTarget
    ) {
        Date timePeriodStartDate = PerformanceTargetDO.getStartOfCurrentTimePeriod(jobActivity.StartDate__c.date(), performanceTarget.Timeframe__c);
        AssignedTargetActualValueWrapper wrapper = assignedTargetsActualValueWrappers.get(timePeriodStartDate);
        if (wrapper == null) {
            wrapper = new AssignedTargetActualValueWrapper(timePeriodStartDate);
        }
        wrapper.incrementValueToIncrementActualValueBy(1);
        assignedTargetsActualValueWrappers.put(timePeriodStartDate, wrapper);
    }

    /**
     * Convert wrapper to sObject.
     * Will create the AssignedTarget if needed and set the ActualValue
     *
     * @param assignedTargetsActualValueWrappers - Wrappers that are being updated for the MobileUser
     * @param activePerformanceTargets           - The PerformanceTargets that are available to the MobileUser.
     *                                               PerformanceTarget.Id is the key
     * @param contactId                          - Contact.Id for the MobileUser being processed
     * @param overWrite                          - Pass true if the original AssignedTarget__c.ActualValue__c should
     *                                               be overWritten. False will update the ActualValue
     *
     * @return - Wrapper object with the records for DML actions
     */
    private static AssignedTargetDataForDML convertAssignedTargetWrapperToSobject(
        Map<Id, Map<Date, AssignedTargetActualValueWrapper>> assignedTargetsActualValueWrappers,
        Map<Id, PerformanceTarget__c> activePerformanceTargets,
        Id contactId,
        Boolean overWrite
    ) {

        AssignedTargetDataForDML dataForDML = new AssignedTargetDataForDML();
        for (Id performanceTargetId : assignedTargetsActualValueWrappers.keySet()) {
            PerformanceTarget__c performanceTarget = activePerformanceTargets.get(performanceTargetId);

            for (Date assignedTargetWrapperKey : assignedTargetsActualValueWrappers.get(performanceTargetId).keySet()) {
                AssignedTargetActualValueWrapper assignedTargetActualValueWrapper =
                    assignedTargetsActualValueWrappers.get(performanceTargetId).get(assignedTargetWrapperKey);
                if (!overWrite && assignedTargetActualValueWrapper.checkRequiresUpdate()) {
                    continue;
                }
                if (assignedTargetActualValueWrapper.checkAssignedTargetExists()) {
                    AssignedTargetActualValueWrapper previousAssignedTargetActualValueWrapper =
                        assignedTargetsActualValueWrappers.get(performanceTargetId).get(
                            PerformanceTargetDO.getStartOfPreviousTimePeriod(assignedTargetWrapperKey, performanceTarget.Timeframe__c)
                        );

                    // Previous target may not exist if there has been an error with the device time
                    AssignedTarget__c previousTarget;
                    if (previousAssignedTargetActualValueWrapper != null ) {
                        previousTarget = previousAssignedTargetActualValueWrapper.getAssignedTarget();
                    }

                    // Create the new AssignedTarget__c
                    dataForDML.addToInsert(
                        assignedTargetActualValueWrapper.createNewAssignedTarget(
                            previousTarget,
                            contactId,
                            performanceTarget,
                            overWrite
                        )
                    );
                } else {

                    // Update the AssignedTarget__c
                    dataForDML.addToUpdate(assignedTargetActualValueWrapper.updateActualValue(overWrite));
                }

            }
        }
        return dataForDML;
    }

    /**
     * Wrapper class for the AssignedTarget__c objects that need inserting into the DB
     */
    public class AssignedTargetDataForDML {

        List<AssignedTarget__c> assignedTargetsToInsert;
        List<AssignedTarget__c> assignedTargetsToUpdate;

        public AssignedTargetDataForDML() {
            this.assignedTargetsToInsert = new List<AssignedTarget__c>();
            this.assignedTargetsToUpdate = new List<AssignedTarget__c>();
        }

        /**
         * Add an AssignedTarget__c record to the list of records to be inserted
         *
         * @param assignedTarget - The AssignedTarget__c to be inserted to the DB
         */
        public void addToInsert(AssignedTarget__c assignedTarget) {
            this.assignedTargetsToInsert.add(assignedTarget);
        }

        /**
         * Getter for the insert list
         *
         * @return - The insert list
         */
        public List<AssignedTarget__c> getInsert() {
            return this.assignedTargetsToInsert;
        }

        /**
         * Getter for the update list
         *
         * @return - The update list
         */
        public List<AssignedTarget__c> getUpdate() {
            return this.assignedTargetsToUpdate;
        }

        /**
         * Add an AssignedTarget__c record to the list of records to be updated
         *
         * @param assignedTarget - The AssignedTarget__c to be updated
         */
        public void addToUpdate(AssignedTarget__c assignedTarget) {
            this.assignedTargetsToUpdate.add(assignedTarget);
        }

        /**
         * Carry out the DML actions for the AssignedTargets
         */
        public void storeData() {
            GenericObjectCreator assignedTargetCreator =
                new GenericObjectCreator(AssignedTarget__c.SObjectType);
            if (!this.assignedTargetsToInsert.isEmpty()) {
                assignedTargetCreator.checkObjectCreateable();
                DBFullAccess.insertSObject(this.assignedTargetsToInsert);
            }
            if (!this.assignedTargetsToUpdate.isEmpty()) {
                assignedTargetCreator.checkObjectUpdateable();
                DBFullAccess.updateSobject(this.assignedTargetsToUpdate);
            }
        }

        /**
         * Combine another AssignedTargetDataForDML with this one
         *
         * @param assignedTargetDataForDML - The AssignedTargetDataForDML to combine
         */
        public void combineAssignedTargetDataForDML(AssignedTargetDataForDML toCombine) {
            this.assignedTargetsToInsert.addAll(toCombine.getInsert());
            this.assignedTargetsToUpdate.addAll(toCombine.getUpdate());
        }
    }

    /**
     * Wrapper class that holds the AssignedTarget and the value that the ActualValue__c needs to be
     * incremented by
     */
    private class AssignedTargetActualValueWrapper {

        private Integer valueToIncrementActualValueBy;
        private AssignedTarget__c assignedTarget;
        private Date startDate;

        /**
         * Constructor
         * Inits valueToIncrementActualValueBy to 0
         *
         * @param startDate - The date that the AssignedTarget should start on
         */
        public AssignedTargetActualValueWrapper(Date startDate) {
            this.valueToIncrementActualValueBy = 0;
            this.startDate = startDate;
        }

        /**
         * Add an assigned target
         *
         * @param assignedTarget - The AssignedTarget__c record for the wrapper
         */
        public void addAssignedTarget(AssignedTarget__c assignedTarget) {
            this.assignedTarget = assignedTarget;
        }

        /**
         * Get assigned target
         *
         * @return - The AssignedTarget__c wrapper
         */
        public AssignedTarget__c getAssignedTarget() {
            return this.assignedTarget;
        }

        /**
         * Create a new AssignedTarget__c
         *
         * @param previousAssignedTarget - The previous assignedTarget that the TargetValue is copied from
         * @param contactId              - The Contact.Id for the owner of the assigned target
         * @param performanceTarget      - The PerformanceTarget__c that the AssignedTarget__c is for
     * @param overWrite                  - Pass true if the original AssignedTarget__c.ActualValue__c should be overWritten.
     *                                       False will update the ActualValue
         */
        public AssignedTarget__c createNewAssignedTarget(
                AssignedTarget__c previousAssignedTarget,
                Id contactId,
                PerformanceTarget__c performanceTarget,
                Boolean overWrite
        ) {

            Date startDateToUse = previousAssignedTarget == null ? this.startDate : previousAssignedTarget.EndDate__c.addDays(1);
            Decimal target = previousAssignedTarget == null ? performanceTarget.DefaultValue__c : previousAssignedTarget.TargetValue__c;
            String status = performanceTarget.StartDate__c.isSameDay(startDateToUse) ? AssignedTargetDO.STATUS_ACTIVE : AssignedTargetDO.STATUS_CLOSED;
            this.assignedTarget = AssignedTargetDO.createAssignedTarget(
                performanceTarget,
                contactId,
                0,
                target.intValue(),
                PerformanceTargetDO.getStartOfCurrentTimePeriod(startDateToUse, performanceTarget.Timeframe__c),
                PerformanceTargetDO.getEndOfCurrentTimePeriod(startDateToUse, performanceTarget.Timeframe__c),
                status
            );
            return updateActualValue(overWrite);
        }

        /**
         * Update the ActualValue__c and return the assignedTarget
         * @param overWrite - Pass true if the original AssignedTarget__c.ActualValue__c should be overWritten.
         *                      False will update the ActualValue
         *
         * @return - The assigned target with the new ActualValue
         */
        public AssignedTarget__c updateActualValue(Boolean overWrite) {

            if (overWrite) {
                this.assignedTarget.ActualValue__c = valueToIncrementActualValueBy;
            } else {
                this.assignedTarget.ActualValue__c += valueToIncrementActualValueBy;
            }
            return this.assignedTarget;
        }

        /**
         * Increment the valueToIncrementActualValueBy
         *
         * @param value - The value to increase valueToIncrementActualValueBy by
         */
        public void incrementValueToIncrementActualValueBy(Integer value) {
            this.valueToIncrementActualValueBy += value;
        }

        /**
         * Check that the assignedTarget exists
         *
         * @return - Boolean indicating if the assigned target exists
         */
        public Boolean checkAssignedTargetExists() {
            if (this.assignedTarget == null) {
                return true;
            }
            return false;
        }

        /**
         * Check if the assignedTarget needs updating
         *
         * @return - Boolean indicating that the valueToIncrementActualValueBy > 0
         */
        public Boolean checkRequiresUpdate() {
            return this.valueToIncrementActualValueBy == 0;
        }
    }
}
