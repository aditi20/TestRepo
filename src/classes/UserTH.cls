/**
 * Logic for trigger handling for the User object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 *
 * @author - Aditi Satpute
 */
public with sharing class UserTH {

    private static Boolean skipValidation = false;

    public static void setSkipValidation(Boolean value) {
        skipValidation = value;
    }

    /**
     * Main trigger handling logic to be called from User trigger
     */
    public static void triggerHandler (
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete,
        List<User> newRecords,
        Map<Id, User> oldRecordsMap
    ) {
        if (isAfter && !skipValidation) {
            afterHandler(isInsert, isUpdate, newRecords, oldRecordsMap);
        }
    }

    /**
     * After trigger handler to redirect properly based on insert or update
     *
     * @param isInsert      - Boolean flag to indicate whether insert trigger is fired
     * @param isUpdate      - Boolean flag to indicate whether update trigger is fired
     * @param newRecords    - List of new Users being inserted / updated
     * @param oldRecordsMap - Map of old Users required during updation
     */
    private static void afterHandler (
        Boolean isInsert,
        Boolean isUpdate,
        List<User> newRecords,
        Map<Id, User> oldRecordsMap
    ) {
        if (isInsert) {
            afterInsertLogic(newRecords);
        } else if (isUpdate) {
            afterUpdateLogic(newRecords, oldRecordsMap);
        }
    }

    /**
     * After insert logic
     *
     * @param newRecords    - List of new Users being inserted
     */
    private static void afterInsertLogic (List<User> newRecords) {
        List<Id> activeUsersContactId = new List<Id>();
        for (User partnerUser : newRecords) {

            if (partnerUser.isActive && partnerUser.UserType == 'PowerPartner') {
                activeUsersContactId.add(partnerUser.ContactId);
            }
        }

        // Create the assigned targets with default value for newly inserted User
        if (!activeUsersContactId.isEmpty()) {
            addOrReopenAssignedTargets(activeUsersContactId);
        }
    }

    /**
     * After update logic
     *
     * @param newRecords    - List of new Users being inserted
     * @param oldRecordsMap - Map of old Users required to check updated value
     */
    private static void afterUpdateLogic (List<User> newRecords, Map<Id, User> oldRecordsMap) {
        // List for only active partner users
        List<Id> activatedUsersContactId = new List<Id>();
        // List for only inActive partner users
        List<Id> deactivatedUsersContactId = new List<Id>();

        for (User partnerUser : newRecords) {
            if (partnerUser.UserType == 'PowerPartner') {
                if (!oldRecordsMap.get(partnerUser.Id).isActive && partnerUser.isActive) {
                    activatedUsersContactId.add(partnerUser.ContactId);
                } else if (oldRecordsMap.get(partnerUser.Id).isActive && !partnerUser.isActive) {
                    deactivatedUsersContactId.add(partnerUser.ContactId);
                }
            }
        }

        // Create the assigned targets with default value when Users are activated
        if (!activatedUsersContactId.isEmpty()) {
            addOrReopenAssignedTargets(activatedUsersContactId);
        }

        // Close the assigned targets for all deactivated users
        if (!deactivatedUsersContactId.isEmpty()) {
            closeAssignedTargets(deactivatedUsersContactId);
        }
    }

    /**
     * Add default or update assigned targets for each active partner user
     *
     * @param  activeUsersContactId  - The list of all active User's Contact Id
     */
    @future
    private static void addOrReopenAssignedTargets(List<Id> activeUsersContactId) {

        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.getSObjectType());
        contactCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Contact.OwnerId
        });

        // Build the lists of targets to insert or update
        List<AssignedTarget__c> newOrUpdatedTargets = new List<AssignedTarget__c>();

        // Get all the contacts related to active Partner users
        List<Contact> contacts = new List<Contact>([
            SELECT
                Id,
                OwnerId
            FROM
                Contact
            WHERE Id IN :activeUsersContactId
        ]);

        // Date used for fetching assigned target records
        Date oldestStartPeriodDate = fetchOldestStartPeriodDate();

        // Build a map with the assigned targets by contact and performance target
        Map<Id, Map<Id, AssignedTarget__c>> mapContactToAssignedTargets =
            AssignedTargetDO.createContactIdToAssignedTargetMap(
                oldestStartPeriodDate,
                contacts
            );

        // Get the related performance targets
        List<PerformanceTarget__c> performanceTargets =
            PerformanceTargetDO.getActivePerformanceTargetsByName().values();

        newOrUpdatedTargets = createOrUpdateAssignedTargetRecords(
            mapContactToAssignedTargets,
            performanceTargets,
            contacts
        );

        if (!newOrUpdatedTargets.isEmpty()) {
            assignedTargetCreator.checkObjectUpdateable();
            upsert newOrUpdatedTargets;
        }
    }

    /**
     * Fetch the oldest Start Period Date required for retrieving all Assigned targets based on it.
     *
     * @return  - oldest start period date which retrieves all Assigned targets based on it
     */
    public static Date fetchOldestStartPeriodDate() {
        Date currentDate = Date.today();
        Date oldestStartPeriodDate =
            currentDate.toStartOfMonth() < PerformanceTargetDO.getPreviousMonday(currentDate)
            ? currentDate.toStartOfMonth()
            : PerformanceTargetDO.getPreviousMonday(currentDate);
        return oldestStartPeriodDate;
    }

    /**
     * Assigned targets records for newly created Partner Users
     *
     * @param  mapContactToAssignedTargets - map of Assigned target records related to particular contact
     * @param  performanceTargets          - list of all Active performace target records
     * @param  contacts                    - list of contacts related to active Partner User
     *
     * @return List of assigned target records to be created/updated for newly created Partner Users
     */
    private static List<AssignedTarget__c> createOrUpdateAssignedTargetRecords(
        Map<Id, Map<Id, AssignedTarget__c>> mapContactToAssignedTargets,
        List<PerformanceTarget__c> performanceTargets,
        List<Contact> contacts
    ) {
        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);

        // Build the lists of targets to insert or update
        List<AssignedTarget__c> newOrUpdatedTargets = new List<AssignedTarget__c>();

        // Get if JobFiltering is turned on
        Boolean filterJobs = ApplicationSettingsUtils.isJobFilterEnable();

        // Loop over the contacts of active Partner Users
        for (Contact contact : contacts) {
            Map<Id, AssignedTarget__c> aTargetByTarget =
                mapContactToAssignedTargets.get(contact.Id);

            // Loop over the performance targets
            for (PerformanceTarget__c pTarget : performanceTargets) {
                // Add or update the assigned targets
                if (
                    aTargetByTarget == null ||
                    aTargetByTarget.get(pTarget.Id) == null ||
                    aTargetByTarget.get(pTarget.Id).EndDate__c
                        != pTarget.EndDate__c
                ) {
                    if (
                        !filterJobs ||
                        (
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
                } else {
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
        return newOrUpdatedTargets;
    }

    /**
     * Close the active assigned targets for each deactivated User
     *
     * @param   activeUsersContactId  - The list of deactivated users contact Id
     */
    @future
    private static void closeAssignedTargets(List<Id> activeUsersContactId) {
        // List for the assigned targets to close
        List<AssignedTarget__c> targetsToClose = new List<AssignedTarget__c>();

        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        assignedTargetCreator.checkObjectAccessible();
        assignedTargetCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            AssignedTarget__c.Status__c
        });

        // Loop over the active assigned targets to be closed
        for (
            AssignedTarget__c aTarget : [
                SELECT
                    Id,
                    Status__c
                FROM
                    AssignedTarget__c
                WHERE
                    Contact__c IN :activeUsersContactId
                AND
                    Status__c = :AssignedTargetDO.STATUS_ACTIVE
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

        // Close the Assigned targets if Partner User is deactivated
        if (!targetsToClose.isEmpty()) {
            assignedTargetCreator.checkObjectUpdateable();
            update targetsToClose;
        }
    }
}