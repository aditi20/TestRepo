/**
 * Logic class for the trigger on AssignTarget__c
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
public with sharing class AssignedTargetTriggerLogic {

    //--------------------------------------------------------------------------
    // Constants
    //--------------------------------------------------------------------------

    // A map with the assigned targets by status
    public Map<String, Set<AssignedTarget__c>> assignedTargetsByStatus;


    //--------------------------------------------------------------------------
    // Actions carried out before a DML action
    //--------------------------------------------------------------------------

    /**
     * Before Insert
     *
     * Check to be carried out:
     *
     * Actions carried out:
     *  - Close the assigned targets of the previous time period
     *  - Prevents adding a assignedTarget with same contact/performanceTarget/period
     *
     * @param triggerNewList - The list of assigned Targets being inserted by the trigger
     * @param triggerNewMap  - The Map of assigned Targets being inserted by the trigger
     */
    public static void beforeInsert(
            List<AssignedTarget__c> triggerNewList,
            Map<Id, AssignedTarget__c> triggerNewMap
    ) {
        // Close the corresponding assigned targets of the previous time period
        closePreviousAssignedTargets(triggerNewList);
        validateContactPeriodPerformance(triggerNewList, triggerNewMap); 
    }

    /**
     * Before Update
     *
     * Check to be carried out:
     *
     * Actions carried out:
     *
     * @param triggerOldList - The list of the old versions of the surveys.
     * @param triggerOldMap  - A map of the old versions of the surveys.
     * @param triggerNewList - The list of surveys being inserted by the trigger
     * @param triggerMewMap  - A map of the new versions of the surveys.
     */
    public static void beforeUpdate(
            List<AssignedTarget__c> triggerOldList,
            Map<Id, AssignedTarget__c> triggerOldMap,
            List<AssignedTarget__c> triggerNewList,
            Map<Id, AssignedTarget__c> triggerNewMap
    ) {

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
    public static void beforeDelete(List<AssignedTarget__c> triggerOldList) {

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
            List<AssignedTarget__c> triggerNewList,
            Map<Id, AssignedTarget__c> triggerNewMap
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
     * @param triggerMewMap  - A map of the new versions of the surveys.
     */
    public static void afterUpdate(
            List<AssignedTarget__c> triggerNewList,
            Map<Id, AssignedTarget__c> triggerNewMap
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
    public static void afterDelete(List<AssignedTarget__c> triggerOldList) {

    }


    //--------------------------------------------------------------------------
    // Private methods
    //--------------------------------------------------------------------------

    /**
     * Close the corresponding assigned targets of the previous time period
     *
     * @param triggerNewList - The list of surveys being inserted by the trigger
     */
    private static void closePreviousAssignedTargets(List<AssignedTarget__c> triggerNewList) {


        GenericObjectCreator creator = new GenericObjectCreator(AssignedTarget__c.SObjectType);
        creator.checkObjectAccessible();
        creator.checkFieldsAccessible(new List<Schema.SObjectField>{
            AssignedTarget__c.PerformanceTarget__c,
            AssignedTarget__c.EndDate__c,
            AssignedTarget__c.Contact__c,
            AssignedTarget__c.Status__c
        });

        // Store the contacts and performance targets to query the old assigned
        // targets
        List<Id> contacts = new List<Id>();
        List<Id> performanceTargets = new List<Id>();
        Map<Id, Date> endDateByPerformanceTarget = new Map<Id, Date>();
        for (AssignedTarget__c assignedTarget : triggerNewList) {
            if(assignedTarget.Status__c == AssignedTargetDO.STATUS_ACTIVE) {
                contacts.add(assignedTarget.Contact__c);
                performanceTargets.add(assignedTarget.PerformanceTarget__c);
                endDateByPerformanceTarget.put(
                    assignedTarget.PerformanceTarget__c,
                    assignedTarget.EndDate__c
                );
            }
        }

        // Build a map to get the old assigned targets by contact and
        // performance target
        Map<Id, Map<Id, AssignedTarget__c>> aTargetsByContactAndTarget =
                new Map<Id, Map<Id, AssignedTarget__c>>();
        for (
            AssignedTarget__c oldTarget : [
                SELECT Id,
                       Contact__c,
                       PerformanceTarget__c,
                       EndDate__c
                FROM AssignedTarget__c
                WHERE PerformanceTarget__c IN :performanceTargets
                      AND Contact__c IN :contacts
                      AND Status__c = :AssignedTargetDO.STATUS_ACTIVE
            ]
        ) {
            if(
                oldTarget.EndDate__c !=
                    endDateByPerformanceTarget.get(oldTarget.PerformanceTarget__c)
            ) {
                Map<Id, AssignedTarget__c> aTargetByTarget =
                        aTargetsByContactAndTarget.get(oldTarget.Contact__c);
                if(aTargetByTarget == null) {
                    aTargetByTarget = new Map<Id, AssignedTarget__c>();
                    aTargetsByContactAndTarget.put(
                        oldTarget.Contact__c,
                        aTargetByTarget
                    );
                }

                aTargetByTarget.put(oldTarget.PerformanceTarget__c, oldTarget);
            }
        }

        // Build the list of targets to close
        List<AssignedTarget__c> targetsToClose = new List<AssignedTarget__c>();
        for (AssignedTarget__c assignedTarget : triggerNewList) {
            if(assignedTarget.Status__c == AssignedTargetDO.STATUS_ACTIVE) {
                Map<Id, AssignedTarget__c> targetsByTarget =
                    aTargetsByContactAndTarget.get(
                        assignedTarget.Contact__c
                    );
                if(targetsByTarget != null) {
                    targetsToClose.add(
                        targetsByTarget.get(assignedTarget.PerformanceTarget__c)
                    );
                }
            }
        }

        // Close the targets
        for (AssignedTarget__c assignedTarget : targetsToClose) {
            creator.populateField(
                assignedTarget,
                AssignedTarget__c.Status__c,
                AssignedTargetDO.STATUS_CLOSED
            );
        }
        creator.checkObjectUpdateable();
        update targetsToClose;
    }

    /**
    * Validates a valid contact/performanceTarget/period combination active
    *
    * @param triggerNewList - The list of assigned Targets being inserted by the trigger
    * @param triggerNewMap  - The Map of assigned Targets being inserted by the trigger
    */
    public static void validateContactPeriodPerformance(
            List<AssignedTarget__c> triggerNewList,
            Map<Id, AssignedTarget__c> triggerNewMap
    ) {

        Set<Id> usedContacts = new Set<Id>();
        Set<Id> usedPerformances = new Set<Id>();

        GenericObjectCreator creator = new GenericObjectCreator(AssignedTarget__c.SObjectType);
        creator.checkObjectAccessible();
        creator.checkFieldsAccessible(new List<Schema.SObjectField> {
            AssignedTarget__c.PerformanceTarget__c,
            AssignedTarget__c.EndDate__c,
            AssignedTarget__c.Contact__c,
            AssignedTarget__c.Status__c
        });

        // Get all the used contacts and performance
        for (AssignedTarget__c assignedTargetInstance : triggerNewList) {
            usedContacts.add(assignedTargetInstance.Contact__c);
            usedPerformances.add(assignedTargetInstance.PerformanceTarget__c);
        }

        List<AssignedTarget__c> previousAssignedTargets = [
            SELECT
                Id, 
                EndDate__c,
                StartDate__c,
                Contact__c,
                PerformanceTarget__c
            FROM
                AssignedTarget__c 
            WHERE
                Contact__c in :usedContacts 
                AND PerformanceTarget__c in :usedPerformances 
                AND Status__c = :AssignedTargetDO.STATUS_ACTIVE
        ];

        Map<Id, Map<Id, AssignedTarget__c>> AssignmentsPerContact = new Map<Id, Map<Id, AssignedTarget__c>>();

        // Order the assignments per contact and performance 
        // (we consider it should have only one active assigned target per Performance Active))
        for (AssignedTarget__c asignedTarget: previousAssignedTargets){
            if (AssignmentsPerContact.get(asignedTarget.Contact__c) == null){
                AssignmentsPerContact.put(asignedTarget.Contact__c, new Map<Id, AssignedTarget__c>());
            }
            AssignmentsPerContact.get(asignedTarget.Contact__c).put(asignedTarget.PerformanceTarget__c, asignedTarget);
        }
        
        // Validate that there is no invalid assigned Target
        for (AssignedTarget__c asignedTarget:triggerNewList) {
            if (AssignmentsPerContact.get(asignedTarget.Contact__c) != null ){
                if (AssignmentsPerContact.get(asignedTarget.Contact__c).get(asignedTarget.PerformanceTarget__c) != null){
                    AssignedTarget__c currentAssignment = AssignmentsPerContact.get(asignedTarget.Contact__c).get(asignedTarget.PerformanceTarget__c);
                    if(currentAssignment.StartDate__c == asignedTarget.StartDate__c && currentAssignment.EndDate__c == asignedTarget.EndDate__c){
                        asignedTarget.addError(System.Label.ASSIGNED_TARGET_ERR_REPEAT);
                    }
                }
            }
        }
    }
}
