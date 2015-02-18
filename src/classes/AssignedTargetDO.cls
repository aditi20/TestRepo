/**
 * Data Object class for AssignedTarget__c
 *
 * NOTE: This class was changed to be the wrapper itself because of an issue
 *       with the visualforce component of the issue IDALMSA-4983. We are not
 *       sure if this is the way to go with the new architecture.
 *       TODO: Review this decision
 * TODO:
 *    - Refactor code based on SOC architechture
 *    - Use appropriate selector and domain layers and update all queries and DML operations
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 * @author - Santiago Blankleider
 * @author - Alejandro De Gregorio
 * @author - Aditi Satpute
 */
public with sharing class AssignedTargetDO extends SObjectDomain {

    public Id id {get;set;}
    public Decimal targetValue {get;set;}
    public String partnerUserId {get;set;}
    public String partnerUserName {get;set;}
    public String contact;
    public User partnerUser;

    // Status
    public static final String STATUS_ACTIVE   = 'Active';
    public static final String STATUS_CLOSED   = 'Closed';
    public static final String STATUS_INACTIVE = 'Inactive';

    public AssignedTargetDO() {
        super(AssignedTarget__c.SObjectType);
    }

    public AssignedTargetDO(List<AssignedTarget__c> sObjects) {
        super(sObjects);
    }

    /**
     * Constructor
     *
     * @param partnerUser       - Active Partner User to assign target
     * @param contactToTargets  - Map that relates contact to targets
     */
    public AssignedTargetDO(
        User partnerUser,
        Map<String, AssignedTarget__c> contactToTargets
    ) {
        this.targetValue = contactToTargets.get(partnerUser.ContactId) != null
            ? Integer.ValueOf(contactToTargets.get(partnerUser.ContactId).TargetValue__c)
            : null;
        this.partnerUserId = partnerUser.Id;
        this.partnerUserName = partnerUser.Contact.Name;
        this.contact = partnerUser.ContactId;
        this.partnerUser = partnerUser;
    }

    /**
     * Create an Acitve AssignedTarget using the default settings from the PerformanceTarget__c
     *
     * @param performanceTarget - The parent performance target
     * @param contactId         - The id for the contact that the AssignedTarget is for
     * @param actualValue       - The actual value to init with the target
     *
     * @return - The created assigned target
     */
    public static AssignedTarget__c createDefaultActiveAssignedTarget(
            PerformanceTarget__c performanceTarget,
            Id contactId,
            Integer actualValue
    ) {

        return createAssignedTarget(
            performanceTarget,
            contactId,
            actualValue,
            (Integer) performanceTarget.DefaultValue__c,
            performanceTarget.StartDate__c,
            performanceTarget.EndDate__c,
            STATUS_ACTIVE
        );
    }

    /**
     * Create an AssignedTarget
     *
     * @param performanceTarget - The parent performance target
     * @param contactId         - The id for the contact that the AssignedTarget is for
     * @param actualValue       - The actual value to init with the target
     * @param targetValue       - The target for the AssignedTarget
     * @param startDate         - The start date for the AssignedTarget
     * @param endDate           - The end date for the AssignedTarget
     * @param status            - The status for the AssignedTarget
     *
     * @return - The created assigned target
     */
    public static AssignedTarget__c createAssignedTarget(
            PerformanceTarget__c performanceTarget,
            Id contactId,
            Integer actualValue,
            Integer targetValue,
            Date startDate,
            Date endDate,
            String status
    ) {

        GenericObjectCreator creator = new GenericObjectCreator(AssignedTarget__c.getSObjectType());
        AssignedTarget__c assignedTarget =
            (AssignedTarget__c) creator.createNewRecord();
        creator.populateFields(
            assignedTarget,
            new Map<Schema.SObjectField, Object>{
                AssignedTarget__c.Contact__c => contactId,
                AssignedTarget__c.PerformanceTarget__c => performanceTarget.Id,
                AssignedTarget__c.ActualValue__c => actualValue,
                AssignedTarget__c.TargetValue__c => targetValue,
                AssignedTarget__c.StartDate__c => startDate,
                AssignedTarget__c.EndDate__c => endDate,
                AssignedTarget__c.Status__c => status
            }
        );
        return assignedTarget;
    }

    /**
     * Create an AssignedTarget for each active partner user for a given PerformanceTarget__c
     * using the default settings on the PerformanceTarget__c for start and end date and Target
     * Takes into account JobFiltering
     *
     * @param target - The performance target that the AssignedTargets belong to
     *
     * @return - List of assigned targets
     */
    public static List<AssignedTarget__c> createDefaultAssignedTargetsForAllMobileUsers(
            PerformanceTarget__c target
    ) {
        // Fetch all active Partner users
        List<User> partnerUsers = MobileUserDO.getPartnerUsersStatusWise(true);
        return createDefaultAssignedTargetsForMobileUsers(target, partnerUsers);
    }

    /**
     * Create an AssignedTarget for the selected mobile users for a given PerformanceTarget__c
     * using the default settings on the PerformanceTarget__c for start and end date and Target
     * Takes into account JobFiltering
     *
     * @param performanceTarget - The performance target that the AssignedTargets belong to
     * @param mobileUsers       - The list of mobile users for assigning targets
     *
     * @return - List of assigned targets
     */
    public static List<AssignedTarget__c> createDefaultAssignedTargetsForMobileUsers(
        PerformanceTarget__c target,
        List<User> users
    ) {
        List<AssignedTarget__c> assignedTargets = new List<AssignedTarget__c>();
        for (User user : users) {
            assignedTargets.add(createDefaultActiveAssignedTarget(target, user.ContactId, 0));
        }
        return assignedTargets;
    }

    /**
     * Get the current Active AssignedTargets for a given contact.
     * The PerformanceTargets must be active too.
     * Query uses DBFullAccess so that Contacts without attached accounts do not show up as null
     *
     * @param contactId - Id of the contact being searched for
     * @param ownerId   - Id of owner of the contact
     *
     * @return - The list of AssignedTargets found. Empty list if none
     */
    public static List<AssignedTarget__c> getCurrentActiveAssignedTargets(
            Id contactId,
            Id ownerId
    ) {

        GenericObjectCreator contactCreator = new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(new List<String>{
            'Name'
        });
        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        assignedTargetCreator.checkObjectAccessible();
        assignedTargetCreator.checkFieldsAccessible(new List<String>{
            'Name',
            'ActualValue__c',
            'EndDate__c',
            'TargetValue__c',
            'LastModifiedDate'
        });
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);
        performanceTargetCreator.checkObjectAccessible();
        performanceTargetCreator.checkFieldsAccessible(new List<String>{
            'Name',
            'Timeframe__c',
            'Type__c',
            'Status__c'
        });


        String queryString =
            'SELECT ' +
                'Id, ' +
                'Name, ' +
                'ActualValue__c, ' +
                'EndDate__c, ' +
                'TargetValue__c, ' +
                'LastModifiedDate, ' +
                'PerformanceTarget__r.Timeframe__c, ' +
                'PerformanceTarget__r.Type__c, ' +
                'PerformanceTarget__r.Name, ' +
                'Contact__r.Name ' +
            'FROM ' +
                'AssignedTarget__c ' +
            'WHERE ' +
                'Contact__c = \'' + contactId + '\'' +
                'AND Status__c = \'' + STATUS_ACTIVE + '\'' +
                'AND PerformanceTarget__r.Status__c = \'' + PerformanceTargetDO.STATUS_ACTIVE + '\'';

        // Filter by PerformanceTarget owner if JobFiltering is on
        if (ApplicationSettingsUtils.isJobFilterEnable()) {
            performanceTargetCreator.checkFieldsAccessible(new List<String>{'OwnerId'});
            queryString += ' AND PerformanceTarget__r.OwnerId = \'' + ownerId + '\'';
        }
        return (List<AssignedTarget__c>)DBFullAccess.QuerySObject(queryString);
    }

    /**
     * Generates the assigned targets for the next period
     *
     * @param targetsById - The performance targets with the next period set
     */
    public static void generateNextPeriodTargets(
            Map<Id, PerformanceTarget__c> targetsById
    ) {
        // Store a is with the assigned targets to insert or update
        List<AssignedTarget__c> newAssignedTargets = new List<AssignedTarget__c>();

        // Build a set with the dates of the considered performance targets to
        // limit the query on assigned target
        Set<Date> performanceDates = new Set<Date>();
        for (PerformanceTarget__c performanceTarget : targetsById.values()) {
            performanceDates.add(performanceTarget.EndDate__c);
        }

        // Get the contacts of inactive mobile/partner users to filter the
        // query on assigned targets
        List<Id> inactiveContacts = MobileUserDO.getMobileUserContactIds(
            new List<String> {MobileUserDO.STATUS_INACTIVE}
        );
        
        inactiveContacts.addAll(MobileUserDO.getPartnerUserContactIds(
            new List<Boolean> {false}
        ));
        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        assignedTargetCreator.checkObjectAccessible();
        assignedTargetCreator.checkObjectUpdateable();
        assignedTargetCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            AssignedTarget__c.TargetValue__c,
            AssignedTarget__c.Contact__c,
            AssignedTarget__c.PerformanceTarget__c,
            AssignedTarget__c.Status__c,
            AssignedTarget__c.EndDate__c
        });

        // Loop over the old assigned targets to create the new ones
        for (
            AssignedTarget__c assignedTarget : [
                SELECT Id,
                       TargetValue__c,
                       Contact__c,
                       PerformanceTarget__c
                FROM AssignedTarget__c
                WHERE Status__c = :STATUS_ACTIVE
                      AND PerformanceTarget__c IN :targetsById.keySet()
                      AND EndDate__c NOT IN :performanceDates
            ]
        ) {
            PerformanceTarget__c parentTarget =
                    targetsById.get(assignedTarget.PerformanceTarget__c);
            newAssignedTargets.add(
                createAssignedTarget(
                    parentTarget,
                    assignedTarget.Contact__c,
                    0,
                    Integer.valueOf(assignedTarget.TargetValue__c),
                    parentTarget.StartDate__c,
                    parentTarget.EndDate__c,
                    STATUS_ACTIVE
                )
            );
        }

        // Loop over the already created assigned targets
        for (
            AssignedTarget__c assignedTarget : [
                SELECT Id,
                       Contact__c
                FROM AssignedTarget__c
                WHERE Status__c = :STATUS_CLOSED
                      AND PerformanceTarget__c IN :targetsById.keySet()
                      AND EndDate__c IN :performanceDates
                      AND Contact__c NOT IN :inactiveContacts
            ]
        ) {
            assignedTargetCreator.populateFields(
                assignedTarget,
                new Map<Schema.SObjectField, Object>{
                    AssignedTarget__c.Status__c => STATUS_ACTIVE
                }
            );
            newAssignedTargets.add(assignedTarget);
        }
        upsert newAssignedTargets;
    }

    /**
     * Buid a map with the assigned targets for each performance target
     *
     * @param performanceTargets - A set with the ids of the performance targets
     *
     * @return - A map with the assigned targets for each performance target
     */
    public static Map<Id, List<AssignedTarget__c>> getActiveAssignedTargetsByPerformanceTarget(
            Set<Id> performanceTargets
    ) {
        List<AssignedTarget__c> performanceAssignment = getAssignedTargetsForPerformanceTargets(
                performanceTargets,
                AssignedTargetDO.STATUS_ACTIVE
        );

        // Group the assignments by performance target
        Map<Id, List<AssignedTarget__c>> assignedTargetByPerformance =
                new Map<Id, List<AssignedTarget__c>>();
        for (AssignedTarget__c assignedTarget : performanceAssignment) {
            if (assignedTargetByPerformance.get(assignedTarget.PerformanceTarget__c) == null) {
                assignedTargetByPerformance
                    .put(assignedTarget.PerformanceTarget__c, new List<AssignedTarget__c>());
            }
            assignedTargetByPerformance
                .get(assignedTarget.PerformanceTarget__c).add(assignedTarget);
        }
        return assignedTargetByPerformance;
    }


    /**
     * Returns the list of the Assigned targets childs of the performance targets
     *
     * @param performanceTargets - The ids of the performance targets
     * @param status             - The status of the performance
     *
     * @return - The result list of assignned targets of the performanceTargets
     */
    public static List<AssignedTarget__c> getAssignedTargetsForPerformanceTargets(
            Set<Id> performanceTargets,
            String status
    ) {
        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        assignedTargetCreator.checkObjectAccessible();
        assignedTargetCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            AssignedTarget__c.Status__c,
            AssignedTarget__c.PerformanceTarget__c
        });
        return [
            SELECT
                Id,
                Status__c,
                PerformanceTarget__c
            FROM
                AssignedTarget__c
            WHERE
                PerformanceTarget__c IN :performanceTargets
                AND Status__c = :status
        ];
    }

    /**
     * Get assignedTargets filtered by the parameters
     *
     * @param performanceTargets - The ids of the performance targets
     * @param earliestFoundDate  - The earliest date that the assignedTargets start
     * @param contacts           - List of contacts that the AssignedTargets belong too
     *
     * @return - The result list of assignned targets of the performanceTargets
     */
    public static List<AssignedTarget__c> getAssignedTargetsForContacts(
            Set<Id> performanceTargets,
            Date earliestFoundDate,
            List<Id> contacts
    ) {
    
        List<Id> contactsList = new List<Id>();
        List<Id> performanceList = new List<Id>();
        contactsList.addAll(contacts);
        performanceList.addAll(performanceTargets);
        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        assignedTargetCreator.checkObjectAccessible();
        assignedTargetCreator.checkFieldsAccessible(new List<String>{
            'Name',
            'ActualValue__c',
            'EndDate__c',
            'StartDate__c',
            'StartDate__c',
            'PerformanceTarget__c',
            'Contact__c'
        });
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);
        performanceTargetCreator.checkObjectAccessible();
        performanceTargetCreator.checkFieldsAccessible(new List<String>{
            'Timeframe__c',
            'DefaultValue__c'
        });
        String queryString =
            'SELECT ' +
                'Name, ' +
                'Id, ' +
                'ActualValue__c, ' +
                'TargetValue__c, ' +
                'PerformanceTarget__c, ' +
                'PerformanceTarget__r.Timeframe__c, ' +
                'PerformanceTarget__r.DefaultValue__c, ' +
                'StartDate__c, ' +
                'EndDate__c ' +
            'FROM ' +
                'AssignedTarget__c ' +
            'WHERE ' +
                'PerformanceTarget__c IN (\'' + String.join(performanceList, '\',\'') + '\')' +
                ' AND StartDate__c >= ' + String.valueOf(earliestFoundDate)  +
                ' AND Contact__c IN (\'' + String.join(contactsList, '\',\'') + '\')' ;
            return DBFullAccess.querySObject(queryString);
    }

    /**
     * Get Assigned Targets for a given set of performance targets that no earlier than a
     * given weekley or monthly date
     *
     * @param performanceTargets - The performanceTargets whose AssignedTargets are being fetched
     * @param weeklyStartDate    - The earliest startDate for a weekly target
     * @param monthlyStartDate   - The earliest startDate for a monthly target
     *
     * @return - A list of the found assignedTargets
     */
    public static List<AssignedTarget__c> getRecentAssignedTargetsForPerformanceTargets(
            Set<Id> performanceTargets,
            Date weeklyStartDate,
            Date monthlyStartDate
    ) {
        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        assignedTargetCreator.checkObjectAccessible();
        assignedTargetCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            AssignedTarget__c.TargetValue__c,
            AssignedTarget__c.ActualValue__c,
            AssignedTarget__c.RecordCount__c,
            AssignedTarget__c.Contact__c,
            AssignedTarget__c.PerformanceTarget__c,
            AssignedTarget__c.Status__c,
            AssignedTarget__c.StartDate__c,
            AssignedTarget__c.EndDate__c
        });
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);
        performanceTargetCreator.checkObjectAccessible();
        performanceTargetCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            PerformanceTarget__c.Timeframe__c
        });

        return [
            SELECT
                Id,
                Name,
                StartDate__c,
                EndDate__c,
                PerformanceTarget__c,
                Contact__c,
                ActualValue__c,
                RecordCount__c,
                TargetValue__c
            FROM
                AssignedTarget__c
            WHERE
                PerformanceTarget__c IN :performanceTargets
                AND
                (
                    (
                        PerformanceTarget__r.Timeframe__c = :PerformanceTargetDO.TIMEFRAME_WEEKLY
                        AND StartDate__c >= :weeklyStartDate
                    )
                    OR
                    (
                        PerformanceTarget__r.Timeframe__c = :PerformanceTargetDO.TIMEFRAME_MONTHLY
                        AND StartDate__c >= :monthlyStartDate
                    )
                )
        ];
    }

    /**
     * Update the ActualValue__c based on the AggregationOperation of the PerformanceTarget
     *
     * @param assignedTarget       - The AssignedTarget__c being updated
     * @param aggregationOperation - The operator to be applied for the PerformanceTarget
     * @param valueToAdd           - The value that could be added to the ActualValue
     */
    public static void increaseActualValue(
            AssignedTarget__c assignedTarget,
            String aggregationOperation,
            Double valueToAdd
    ) {

        if (
                aggregationOperation.equals(PerformanceTargetDO.AGGREGATION_OPERATION_COUNT) ||
                aggregationOperation.equals(PerformanceTargetDO.AGGREGATION_OPERATION_PERCENTAGE)
        ) {
            assignedTarget.ActualValue__c++;
        } else if (
                aggregationOperation.equals(PerformanceTargetDO.AGGREGATION_OPERATION_AVG) ||
                aggregationOperation.equals(PerformanceTargetDO.AGGREGATION_OPERATION_SUM)
        ) {
            assignedTarget.ActualValue__c += valueToAdd;
        }
    }

    /**
     * Creates a Map with all assigned target records linked to particular contact records
     *
     * @param  oldestStartPeriodDate  - oldest start period date required to fetch limited assigned
     *                                  target records
     * @param  contacts               - list of contacts related to active Partner User
     *
     * @return Map of all assigned targets related to particular contacts.
     */
    public static Map<Id, Map<Id, AssignedTarget__c>> createContactIdToAssignedTargetMap(
        Date oldestStartPeriodDate,
        List<Contact> contacts
    ) {
        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        assignedTargetCreator.checkObjectAccessible();
        assignedTargetCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            AssignedTarget__c.TargetValue__c,
            AssignedTarget__c.Contact__c,
            AssignedTarget__c.PerformanceTarget__c,
            AssignedTarget__c.EndDate__c
        });
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);
        performanceTargetCreator.checkObjectAccessible();
        performanceTargetCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            PerformanceTarget__c.Status__c
        });
        Map<Id, Map<Id, AssignedTarget__c>> mapContactToAssignedTargets =
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
                AND PerformanceTarget__r.Status__c = :STATUS_ACTIVE
                AND EndDate__c > :oldestStartPeriodDate
                ORDER BY EndDate__c ASC
            ]
        ) {
            Map<Id, AssignedTarget__c> mapIdToAssignedTarget =
                mapContactToAssignedTargets.get(assignedTarget.Contact__c);

            if (mapIdToAssignedTarget == null) {
                mapIdToAssignedTarget = new Map<Id, AssignedTarget__c>();
                mapContactToAssignedTargets.put(
                    assignedTarget.Contact__c,
                    mapIdToAssignedTarget
                );
            }

            mapIdToAssignedTarget.put(
                assignedTarget.PerformanceTarget__c,
                assignedTarget
            );
        }
        return mapContactToAssignedTargets;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public AssignedTargetDO constructWithRecords(List<SObject> sObjectList) {
            return new AssignedTargetDO(sObjectList);
        }
        public AssignedTargetDO constructEmpty() {
            return new AssignedTargetDO();
        }
    }
}