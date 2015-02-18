/**
 * Class to be inherited by the target creation controllers
 * 
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 * @author - Aditi Satpute
 */
public abstract with sharing class CreateTargetController {

    private static final String TRACKED_OBJECT_NAME = 'trackedObjectName';

    // List of assigned target wrapper class
    public List<AssignedTargetDO> assignedTargetWrappers {get; set;}

    // Map targets by contact id
    private Map<String, AssignedTarget__c> assignedTargetByContact;

    // The Current Performance target
    public PerformanceTarget__c performanceTarget {get; set;}

    // Current monthly period
    public String monthlyPeriod {get; set;}

    // Current weekly period
    public String weeklyPeriod {get; set;}

    // Boolean to disable timeframe if is edition
    public Boolean isEditing {get; set;}

    // Boolean to indicate if there are individual targets
    public Boolean hasIndividualTargets {get; set;}

    // Set of all active Partner Users
    public Set<Id> partnerUsersSet {get; set;}

    // Properties for the timeframe values
    public String performanceWeekly {
        get {
            return PerformanceTargetDO.TIMEFRAME_WEEKLY;
        }
        set;
    }
    public String performanceMonthly {
        get {
            return PerformanceTargetDO.TIMEFRAME_MONTHLY;
        }
        set;
    }

    /**
     * Constructor of the class
     *
     * @param stdController - An instance of the standard controller
     */
    public CreateTargetController(ApexPages.StandardController stdController) {
        this.performanceTarget = (PerformanceTarget__c)stdController.getRecord();
        this.assignedTargetByContact = new Map<String, AssignedTarget__c>();
        this.assignedTargetWrappers = new List<AssignedTargetDO>();
        this.isEditing = this.performanceTarget.Id != null;
        this.hasIndividualTargets = false;
        this.partnerUsersSet = new Set<Id>();
        this.performanceTarget.AggregationOperation__c =
            PerformanceTargetDO.AGGREGATION_OPERATION_COUNT;

        // If record already exists load it from DB
        if (this.isEditing) {
            this.performanceTarget =
                new PerformanceTargetSelector().getWithAssignedTargets(
                    this.performanceTarget.Id,
                    performanceTarget.EndDate__c
                );

            // Fill map to use in the AssignedTarget wrapper class
            for (AssignedTarget__c at : this.performanceTarget.Assigned_Targets__r) {
                this.assignedTargetByContact.put(at.Contact__c, at);
            }
        }

        // Fetch all Active partner Users
        List<User> partnerUsers = MobileUserDO.getPartnerUsersStatusWise(true);

        // Create list of AssignedTargets wrapper to display only for Active partner Users
        for (User partnerUser : partnerUsers) {
            AssignedTargetDO assignedTarget = new AssignedTargetDO(
                partnerUser,
                this.assignedTargetByContact
            );
            this.assignedTargetWrappers.add(assignedTarget); 
            if (assignedTarget.targetValue != this.performanceTarget.DefaultValue__c) {
                this.hasIndividualTargets = true;
            }
            partnerUsersSet.add(partnerUser.ContactId);
        }

        // Set monthly period to show on page
        this.monthlyPeriod = buildPeriodString(
            Date.today().toStartOfMonth(),
            PerformanceTargetDO.getLastDayOfMonth(Date.today())
        );
        // Set weekly period to show on page
        this.weeklyPeriod = buildPeriodString(
            PerformanceTargetDO.getPreviousMonday(Date.today()),
            PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6)
        );
    }

    /**
     * Format dates to show selectable timeframe on page
     *
     * @param startDate - The start date of the period
     * @param endDate   - The end date of the period
     *
     * @return - A String formatted to show on page
     */
    private String buildPeriodString(Date startDate, Date endDate) {
        String formattedStartDate = DateTime.newInstance(
            startDate.year(),
            startDate.month(),
            startDate.day()
        ).format('dd MMM yyyy');

        String formattedEndDate = DateTime.newInstance(
            endDate.year(),
            endDate.month(),
            endDate.day()
        ).format('dd MMM yyyy');

        return String.format(
            System.label.ASSIGNED_TARGET_CURRENT_PERIOD,
            new String[] {formattedStartDate, formattedEndDate}
        );
    }

    /**
     * Save performance target with assigned targets to data base
     *
     * @param targetType - The type of the performance target
     *
     * @return - The raference of the page to redirect to
     */
    protected PageReference saveTarget(String targetType) {
        Savepoint sp = Database.setSavepoint();
        Map<String, Decimal> contactToTargetValue = new Map<String, Decimal>();
        List<AssignedTarget__c> assignedTargets = new List<AssignedTarget__c>();

        GenericObjectCreator assignedTargetCreator =
            new GenericObjectCreator(AssignedTarget__c.SObjectType);
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);

        // Create map to get target values by contact
        for (AssignedTargetDO assignedTargetWrapper :
                this.assignedTargetWrappers
        ) {
            contactToTargetValue.put(
                assignedTargetWrapper.contact,
                assignedTargetWrapper.targetValue
            );
        }

        // New record
        if (isEditing) {

            // Is editing
            assignedTargets =
                new AssignedTargetSelector().getForPartnerUsers(
                    this.performanceTarget.Id,
                    this.performanceTarget.EndDate__c,
                    partnerUsersSet
                );

            Set<Id> contactsWithAssignedTarget = new Set<Id>();

            // Get the contacts with assigned targets
            for (AssignedTarget__c aT : assignedTargets) {
                contactsWithAssignedTarget.add(aT.Contact__c);
            }

            // List to find the partner users without assigned target
            List<User> contactsWithoutAssignment = new List<User>();

            for (AssignedTargetDO assignedTarget : assignedTargetWrappers) {
                if (!contactsWithAssignedTarget.contains(assignedTarget.contact)) {
                    contactsWithoutAssignment.add(assignedTarget.partnerUser);
                }
            }

            // Add the missing Assigned Targets
            assignedTargets.addAll(AssignedTargetDO.createDefaultAssignedTargetsForMobileUsers(
                                            performanceTarget, contactsWithoutAssignment));

            try {
                // Update performance target
                PerformanceTargetDO performanceTargetDomainInstance =
                    new PerformanceTargetDO.Constructor().constructWithRecords(
                        new List<PerformanceTarget__c> {this.performanceTarget}
                    );
                performanceTargetDomainInstance.updateRecords();
            } catch(DmlException e) {
                Apexpages.addMessage(
                    new ApexPages.Message(ApexPages.Severity.FATAL, e.getDmlMessage(0))
                );
                Database.rollback(sp);
                return null;
            }
        } else {

            // Set timeframe, status and type
            performanceTargetCreator.populateFields(
                this.performanceTarget,
                new Map<Schema.SObjectField, Object>{
                    PerformanceTarget__c.Status__c => PerformanceTargetDO.STATUS_ACTIVE,
                    PerformanceTarget__c.EndDate__c => Date.today(),
                    PerformanceTarget__c.Type__c => targetType
                }
            );
            // Insert performance target
            try {
                PerformanceTargetDO performanceTargetDomainInstance =
                    new PerformanceTargetDO.Constructor().constructWithRecords(
                        new List<PerformanceTarget__c> {this.performanceTarget}
                    );
                performanceTargetDomainInstance.insertRecords();
            } catch(DMLException e) {
                Apexpages.addMessage(
                    new ApexPages.Message(ApexPages.Severity.FATAL, e.getDmlMessage(0))
                );
                Database.rollback(sp);
                return null;
            }

            // Selecting performance target for DB, after the execution of the trigger
            this.performanceTarget =
                (PerformanceTarget__c) new PerformanceTargetSelector().getRecordById(
                    this.performanceTarget.Id
                );

            // Create assigned targets for performance target
            assignedTargets = AssignedTargetDO.createDefaultAssignedTargetsForAllMobileUsers(
                this.performanceTarget
            );
        }

        // Add target values to each assigned target of the list
        for (AssignedTarget__c assignedTarget : assignedTargets) {
            assignedTargetCreator.populateFields(
                assignedTarget,
                new Map<Schema.SObjectField, Object>{
                    AssignedTarget__c.TargetValue__c =>
                        contactToTargetValue.get(AssignedTarget.Contact__c)
                }
            );
        }

        try {
            // Insert/Update target values and redirect to manager
            AssignedTargetDO assignedTargetDomainInstance =
                new AssignedTargetDO.Constructor().constructWithRecords(assignedTargets);
            assignedTargetDomainInstance.upsertRecordsDbFullAccess();

            return targetType == PerformanceTargetDO.TYPE_JOB_TARGET
                    ? Page.PerformanceTargetManager
                    : Page.PerformanceIndicatorManager;
        } catch(DMLException e) {
            Apexpages.addMessage(
                new ApexPages.Message(ApexPages.Severity.FATAL, e.getDmlMessage(0))
            );
            Database.rollback(sp);
            return null;
        }
    }

    /**
     * Display list of fields for selected tracked object
     */
    public List<selectOption> getFieldList() {
        List<selectOption> options = new List<selectOption>();
        options.add(new selectOption('', '-'));

        if (ApexPages.currentPage().getParameters().get(TRACKED_OBJECT_NAME) != null) {
            this.performanceTarget.TrackedSObjectApiName__c =
                ApexPages.currentPage().getParameters().get(TRACKED_OBJECT_NAME);
        }

        if (this.performanceTarget.TrackedSObjectApiName__c != null) {
            Map<String, Schema.SObjectField> fieldList =
                DescribeHandler.getFieldMap(this.performanceTarget.TrackedSObjectApiName__c);
            for (Schema.SObjectField fieldInstance : fieldList.values()) {
                if (
                    (
                        String.valueOf(fieldInstance.getDescribe().getType()) == 'DOUBLE' ||
                        String.valueOf(fieldInstance.getDescribe().getType()) == 'CURRENCY' ||
                        String.valueOf(fieldInstance.getDescribe().getType()) == 'PERCENT' ||
                        String.valueOf(fieldInstance.getDescribe().getType()) == 'INTEGER'
                    ) &&
                    (
                        !SurveyUtils.isGeoLocationComponentField(fieldInstance.getDescribe().getName())
                    )
                ) {
                    options.add(
                        new selectOption(
                            fieldInstance.getDescribe().getName(),
                            fieldInstance.getDescribe().getLabel()
                        )
                    );
                }
            }
        }
        return options;
    }
}
