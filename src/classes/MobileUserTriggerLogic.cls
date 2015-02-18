/**
 * Logic class for the trigger on Mobile_User__c
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
public with sharing class MobileUserTriggerLogic {

    //--------------------------------------------------------------------------
    // Actions carried out before a DML action
    //--------------------------------------------------------------------------
    /**
     * Before Insert
     *
     * Check to be carried out:
     *
     * Actions carried out:
     *
     * @param triggerNewList - The list of surveys being inserted by the trigger
     * @param triggerMewMap  - A map of the new versions of the surveys.
     */
    public static void beforeInsert(
            List<Mobile_User__c> triggerNewList
    ) {
        // PLACE HOLDER FOR THE TRIGGERS FRAMEWORK
    }

    /**
     * Before Update
     *
     * Check to be carried out:
     *
     * Actions carried out:
     *  - Create the assigned targets for the next time period
     *
     * @param triggerOldList - The list of the old versions of the surveys.
     * @param triggerOldMap  - A map of the old versions of the surveys.
     * @param triggerNewList - The list of surveys being inserted by the trigger
     * @param triggerMewMap  - A map of the new versions of the surveys.
     */
    public static void beforeUpdate(
            List<Mobile_User__c> triggerOldList,
            Map<Id, Mobile_User__c> triggerOldMap,
            List<Mobile_User__c> triggerNewList,
            Map<Id, Mobile_User__c> triggerNewMap
    ) {
        // PLACE HOLDER FOR THE TRIGGERS FRAMEWORK
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
    public static void beforeDelete(List<Mobile_User__c> triggerOldList) {
        // PLACE HOLDER FOR THE TRIGGERS FRAMEWORK
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
            List<Mobile_User__c> triggerNewList,
            Map<Id, Mobile_User__c> triggerNewMap
    ) {
        // Build a list with only the active users
        List<Mobile_User__c> activeUsers = new List<Mobile_User__c>();
        for (Mobile_User__c mUser : triggerNewList) {
            if(mUser.Status__c == MobileUserDO.STATUS_ACTIVE) {
                activeUsers.add(mUser);
            }
        }

        // Create the assigned targets
        addOrReopenAssignedTargets(activeUsers);
    }

    /**
     * After Update
     *
     * Checks to be carried out:
     *
     * Actions carried out:
     *
     * @param triggerOldList - The list of the old versions of the surveys.
     * @param triggerOldMap  - A map of the old versions of the surveys.
     * @param triggerNewList - The list of surveys being inserted by the trigger
     * @param triggerMewMap  - A map of the new versions of the surveys.
     */
    public static void afterUpdate(
            List<Mobile_User__c> triggerOldList,
            Map<Id, Mobile_User__c> triggerOldMap,
            List<Mobile_User__c> triggerNewList,
            Map<Id, Mobile_User__c> triggerNewMap
    ) {
        // Build a list with only the active users
        List<Mobile_User__c> activatedUsers = new List<Mobile_User__c>();
        // And another one with the deactivated users
        List<Mobile_User__c> deactivatedUsers = new List<Mobile_User__c>();
        for (Mobile_User__c mUser : triggerNewList) {
            if(
                mUser.Status__c == MobileUserDO.STATUS_ACTIVE
                && triggerOldMap.get(mUser.Id).Status__c == MobileUserDO.STATUS_INACTIVE
            ) {
                activatedUsers.add(mUser);
            } else if (
                mUser.Status__c == MobileUserDO.STATUS_INACTIVE
                && triggerOldMap.get(mUser.Id).Status__c == MobileUserDO.STATUS_ACTIVE
            ) {
                deactivatedUsers.add(mUser);
            }
        }

        // Create the assigned targets
        if(!activatedUsers.isEmpty()) {
            addOrReopenAssignedTargets(activatedUsers);
        }

        // Close the assigned targets of the deactivated users
        if(!deactivatedUsers.isEmpty()) {
            closeAssignedTargets(deactivatedUsers);
        }
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
    public static void afterDelete(List<Mobile_User__c> triggerOldList) {
        // Close the active assigned targets for these users
        closeAssignedTargets(triggerOldList);
    }




    //--------------------------------------------------------------------------
    // Helper methods
    //--------------------------------------------------------------------------

    /**
     * Add or reopen assigned targets for each mobile user
     *
     * @param   users   the list of the users being inserted or updated
     */
    private static void addOrReopenAssignedTargets(List<Mobile_User__c> users) {
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();
        mobileUserCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Mobile_User__c.Contact__c
            }
        );
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.OwnerId
            }
        );
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);
        performanceTargetCreator.checkObjectAccessible();
        performanceTargetCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                PerformanceTarget__c.StartDate__c,
                PerformanceTarget__c.EndDate__c,
                PerformanceTarget__c.DefaultValue__c,
                PerformanceTarget__c.OwnerId
            }
        );
        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        assignedTargetCreator.checkObjectAccessible();
        assignedTargetCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                AssignedTarget__c.TargetValue__c,
                AssignedTarget__c.Contact__c,
                AssignedTarget__c.PerformanceTarget__c,
                AssignedTarget__c.EndDate__c,
                AssignedTarget__c.Status__c
            }
        );

        // Get all the contacts related to the users
        Set<Id> contactIds = new Set<Id>();
        for (Mobile_User__c user : users) {
            contactIds.add(user.Contact__c);
        }

        List<Contact> contacts = new List<Contact>([
            SELECT
                Id,
                OwnerId
            FROM
                Contact
            WHERE
                Id IN :contactIds
        ]);

        // A date for the queries
        Date today = Date.today();
        Date oldestStartPeriodDate =
            today.toStartOfMonth() < PerformanceTargetDO.getPreviousMonday(today)
            ? today.toStartOfMonth()
            : PerformanceTargetDO.getPreviousMonday(today);

        // Build a map with the assigned targets by contact and performance
        // target
        Map<Id, Map<Id, AssignedTarget__c>> aTargetsByContactAndTarget =
                new Map<Id, Map<Id, AssignedTarget__c>>();
        for (
            AssignedTarget__c assignedTarget : [
                SELECT
                    Id,
                    EndDate__c,
                    Contact__c,
                    PerformanceTarget__c
                FROM
                    AssignedTarget__c
                WHERE
                    Contact__c IN :contacts
                    AND PerformanceTarget__r.Status__c = :PerformanceTargetDO.STATUS_ACTIVE
                    AND EndDate__c > :oldestStartPeriodDate
                    ORDER BY EndDate__c ASC
            ]
        ) {
            Map<Id, AssignedTarget__c> aTargetByTarget =
                aTargetsByContactAndTarget.get(assignedTarget.Contact__c);
            if(aTargetByTarget == null) {
                aTargetByTarget = new Map<Id, AssignedTarget__c>();
                aTargetsByContactAndTarget.put(
                    assignedTarget.Contact__c,
                    aTargetByTarget
                );
            }

            aTargetByTarget.put(
                assignedTarget.PerformanceTarget__c,
                assignedTarget
            );
        }

        // Get the related performance targets
        List<PerformanceTarget__c> performanceTargets = [
            SELECT
                Id,
                StartDate__c,
                EndDate__c,
                DefaultValue__c,
                OwnerId
            FROM
                PerformanceTarget__c
            WHERE
                Status__c = :PerformanceTargetDO.STATUS_ACTIVE
        ];

        // Build the lists of targets to insert or update
        List<AssignedTarget__c> newOrUpdatedTargets = new List<AssignedTarget__c>();

        // Get if JobFiltering is turned on
        Boolean filterJobs = ApplicationSettingsUtils.isJobFilterEnable();

        // Loop over the contacts
        for (Contact contact : contacts) {
            Map<Id, AssignedTarget__c> aTargetByTarget =
                aTargetsByContactAndTarget.get(contact.Id);

            // Loop over the performance targets
            for (PerformanceTarget__c pTarget : performanceTargets) {
                // Add or update the assigned targets
                if(
                    aTargetByTarget == null
                    || aTargetByTarget.get(pTarget.Id) == null
                    || aTargetByTarget.get(pTarget.Id).EndDate__c
                        != pTarget.EndDate__c
                ) {
                    if (
                        !filterJobs
                        || (
                            filterJobs
                            && pTarget.OwnerId == contact.OwnerId
                        )
                    ) {
                        newOrUpdatedTargets.add(
                            AssignedTargetDO.createDefaultActiveAssignedTarget(
                                pTarget,
                                contact.Id,
                                0
                            )
                        );
                    }
                }
                else {
                    assignedTargetCreator.populateFields(
                        aTargetByTarget.get(pTarget.Id),
                        new Map<Schema.SObjectField, Object> {
                            AssignedTarget__c.Status__c => AssignedTargetDO.STATUS_ACTIVE
                        }
                    );
                    newOrUpdatedTargets.add(aTargetByTarget.get(pTarget.Id));
                }
            }
        }
        assignedTargetCreator.checkObjectCreateable();
        assignedTargetCreator.checkObjectUpdateable();
        upsert newOrUpdatedTargets;
    }

    /**
     * Close the active assigned targets for each user
     *
     * @param   users   the list of the users being deleted
     */
    private static void closeAssignedTargets(List<Mobile_User__c> users) {
        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        assignedTargetCreator.checkObjectAccessible();
        assignedTargetCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                AssignedTarget__c.Status__c
            }
        );

        // Get all the contacts related to the users
        Set<Id> contacts = new Set<Id>();
        for (Mobile_User__c user : users) {
            contacts.add(user.Contact__c);
        }

        // Build a list with the assigned targets to close
        List<AssignedTarget__c> targetsToClose = new List<AssignedTarget__c>();

        // Loop over the active assigned targets and close them
        for (
            AssignedTarget__c aTarget : [
                SELECT
                    Id,
                    Status__c
                FROM
                    AssignedTarget__c
                WHERE
                    Contact__c IN :contacts
                    AND Status__c = :AssignedTargetDO.STATUS_ACTIVE
            ]
        ) {
            assignedTargetCreator.populateFields(
                aTarget,
                new Map<Schema.SObjectField, Object> {
                    AssignedTarget__c.Status__c => AssignedTargetDO.STATUS_CLOSED
                }
            );
            targetsToClose.add(aTarget);
        }
        assignedTargetCreator.checkObjectUpdateable();
        update targetsToClose;
    }
}

