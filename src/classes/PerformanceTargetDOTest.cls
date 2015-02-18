/**
 * Test class for the performanceTargetDO.cls
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
@isTest
public with sharing class PerformanceTargetDOTest {

    private static final String BAD_OBJECT_NAME = 'BADOBJECTNAME';
    public static final String ASSET_API_NAME =
        Asset.sObjectType.getDescribe().getName();
    public static final String CONTACT_ID_FIELD =
        Schema.sObjectType.Asset.fields.ContactId.getName();
    public static final String LEAD_API_NAME =
        Lead.sObjectType.getDescribe().getName();
    public static final String CONVERTED_CONTACT_ID_FIELD =
        Schema.sObjectType.Lead.fields.ConvertedContactID.getName();
    public static final String LEAD_NUMBER_OF_EMPLOYEES =
        Schema.sObjectType.Lead.fields.NumberOfEmployees.getName();
    public static final String PRICE_FIELD =
        Schema.sObjectType.Asset.fields.Price.getName();

    /**
     * Create multiple Job targets
     */
    public static List<PerformanceTarget__c> createMultipleJobTargets(
            List<String> jobTemplateIds,
            Integer numberOfTimes
    ) {
        List<PerformanceTarget__c> performanceTargets = new List<PerformanceTarget__c>();
        for (Integer i = 0; i < numberOfTimes; i++) {
            performanceTargets.add(
                createJobTargetRecord(
                    'JobTarget'+i,
                    jobTemplateIds[i],
                    50,
                    PerformanceTargetDO.TIMEFRAME_WEEKLY,
                    PerformanceTargetDO.getPreviousMonday(Date.today()),
                    PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
                    PerformanceTargetDO.TYPE_JOB_TARGET
                )
            );
        }
        return performanceTargets;
    }

    /**
     * Create multiple Performance Indicators
     */
    public static List<PerformanceTarget__c> createMultiplePerformanceIndicators(
            Integer numberOfTimes
    ) {
        List<PerformanceTarget__c> performanceTargets = new List<PerformanceTarget__c>();
        for (Integer i = 0; i < numberOfTimes; i++) {
            performanceTargets.add(
                createPerformanceIndicatorRecord(
                    'PerformanceIndicator'+i,
                    50,
                    PerformanceTargetDO.TIMEFRAME_WEEKLY,
                    PerformanceTargetDO.getPreviousMonday(Date.today()),
                    PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
                    LEAD_API_NAME,
                    PerformanceTargetDO.AGGREGATION_OPERATION_SUM,
                    LEAD_NUMBER_OF_EMPLOYEES,
                    CONVERTED_CONTACT_ID_FIELD
                )
            );
        }
        return performanceTargets;
    }
    
    /**
     * Create an active PerformanceTarget
     *
     * @param targetName    - Name for the target
     * @param jobTemplateId - The Job__c.Id for the target.
     * @param defaultTarget - Value to go in DefaultValue__c
     * @param timeframe     - Timeframe weekly|monthly
     * @param startDate     - Start date for the performance target
     * @param endDate       - End Date for the performance target
     * @param targetType    - The type of the target
     *
     * @return - The new PerformanceTarget__c
     */
    public static PerformanceTarget__c createJobTargetRecord(
            String targetName,
            Id jobTemplateId,
            Integer defaultTarget,
            String timeframe,
            Date startDate,
            Date endDate,
            String targetType
    ) {
            PerformanceTarget__c performanceTarget =
                new PerformanceTarget__c(
                    Name = targetName,
                    DefaultValue__c = defaultTarget,
                    EndDate__c = endDate,
                    JobTemplate__c = jobTemplateId,
                    StartDate__c = startDate,
                    Status__c = PerformanceTargetDO.STATUS_ACTIVE,
                    Timeframe__c = timeframe,
                    Type__c = targetType
                );
        return performanceTarget;
    }

    /**
     * Create a PerformanceTarget for a PerformanceIndicator
     *
     * @param targetName                           - Name for the target
     * @param defaultTarget                        - Value to go in DefaultValue__c
     * @param timeframe                            - Timeframe weekly|monthly
     * @param startDate                            - Start date for the performance target
     * @param endDate                              - End Date for the performance target
     * @param objectApiName                        - Object API Name that the indicator tracks
     * @param aggregationOperation                 - Operation that the indicator performs
     * @param trackedFieldApiName                  - Field API Name that the indicator tracks
     * @param trackedSObjectContactLookupFieldName - Route to Contact
     *
     * @return - The new PerformanceTarget__c
     */
    public static PerformanceTarget__c createPerformanceIndicatorRecord(
            String targetName,
            Integer defaultTarget,
            String timeframe,
            Date startDate,
            Date endDate,
            String objectApiName,
            String aggregationOperation,
            String trackedFieldApiName,
            String trackedSObjectContactLookupFieldName
    ) {

        PerformanceTarget__c performanceIndicator = createJobTargetRecord(
            targetName,
            null,
            defaultTarget,
            timeframe,
            startDate,
            endDate,
            PerformanceTargetDO.TYPE_INDICATOR
        );
        performanceIndicator.TrackedSObjectApiName__c = objectApiName;
        performanceIndicator.AggregationOperation__c = aggregationOperation;
        performanceIndicator.TrackedFieldApiName__c = trackedFieldApiName;
        performanceIndicator.TrackedSObjectContactLookupFieldName__c =
            trackedSObjectContactLookupFieldName;
        return performanceIndicator;
    }

    /**
     * Test getting list of valid Object API names for PerformanceIndicators
     */
    static testMethod void testGetObjectApiName() {

        PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper =
            new PerformanceManagementTest.EndToEndTestWrapper();
        createGoodIndicator(endToEndTestWrapper, 5);
        createBadObjectNamePerformanceIndicators(endToEndTestWrapper);

        Test.startTest();
        List<String> validObjectNames = PerformanceTargetDO.getValidObjectApiNames();
        Test.stopTest();

        System.assertEquals(1, validObjectNames.size());
        System.assertEquals(
            Contact.SObjectType.getDescribe().getName(),
            validObjectNames[0]
        );

        validatePerformanceTargetStillOpen(endToEndTestWrapper, 0);
        validatePerformanceTargetStillOpen(endToEndTestWrapper, 1);
        validatePerformanceTargetStillOpen(endToEndTestWrapper, 2);
        validatePerformanceTargetStillOpen(endToEndTestWrapper, 3);
        validatePerformanceTargetStillOpen(endToEndTestWrapper, 4);
        validatePerformanceTargetClosedAutomatically(endToEndTestWrapper, 5);
    }

    /**
     * Create a good performance indicator for the contact object
     */
    public static void createGoodIndicator(
            PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper,
            Integer amountOfPIsToCreate
    ) {

        String contactApiName = Contact.SObjectType.getDescribe().getName();
        String contactNameField = Contact.Name.getDescribe().getName();
        String contactContactLinkField = Contact.ReportsToId.getDescribe().getName();
        String contactFirstNameField = Contact.FirstName.getDescribe().getName();
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            amountOfPIsToCreate,
            'TestCountOnlyJohn',
            null,
            new Map<Integer, String>{
                0 => contactApiName
            },
            null,
            new Map<Integer, String>{
                0 => contactNameField
            },
            new Map<Integer, String>{
                0 => contactContactLinkField
            },
            new Map<Integer, List<SObjectFilterCondition__c>>{
                0 => new List<SObjectFilterCondition__c>{
                    SObjectFilterConditionDOTest.createRecord(
                        contactFirstNameField,
                        SObjectFilterConditionDO.EQUALS,
                        'John',
                        null
                    )
                }
            }
        );
    }

    /**
     * Create the Performance Indicators with a bad object name
     */
    private static void createBadObjectNamePerformanceIndicators(
            PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper
    ) {

        String contactNameField = Contact.Name.getDescribe().getName();
        String contactContactLinkField = Contact.ReportsToId.getDescribe().getName();
        String contactFirstNameField = Contact.FirstName.getDescribe().getName();
        String contactOptedOutField = Contact.HasOptedOutOfEmail.getDescribe().getName();
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            1,
            'TestBadCountOnlyJohn',
            null,
            new Map<Integer, String>{
                0 => BAD_OBJECT_NAME
            },
            null,
            new Map<Integer, String>{
                0 => contactNameField
            },
            new Map<Integer, String>{
                0 => contactContactLinkField
            },
            new Map<Integer, List<SObjectFilterCondition__c>>{
                0 => new List<SObjectFilterCondition__c>{
                    SObjectFilterConditionDOTest.createRecord(
                        contactFirstNameField,
                        SObjectFilterConditionDO.EQUALS,
                        'John',
                        null
                    )
                }
            }
        );
    }

    /**
     * Validate that a PerformanceTarget at a given index in the endToEndTestWrapper
     * has been automatically closed
     */
    public static void validatePerformanceTargetClosedAutomatically(
            PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper,
            Integer index
    ) {

        PerformanceTarget__c closedTarget =
            (PerformanceTarget__c) new PerformanceTargetSelector().getRecordById(
                endToEndTestWrapper.getPerformanceTargetByCreationIndex(index).Id
            );

        System.assert(closedTarget != null);
        System.assertEquals(PerformanceTargetDO.STATUS_CLOSED, closedTarget.Status__c);
        System.assertEquals(
            PerformanceTargetDO.CLOSE_AUTOMATICALLY, closedTarget.CloseReason__c
        );
    }

    /**
     * Validate that a PerformanceTarget at a given index in the endToEndTestWrapper is still open
     */
    public static void validatePerformanceTargetStillOpen(
            PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper,
            Integer index
    ) {

        PerformanceTarget__c openTarget =
            (PerformanceTarget__c) new PerformanceTargetSelector().getRecordById(
                endToEndTestWrapper.getPerformanceTargetByCreationIndex(index).Id
            );

        System.assert(openTarget != null);
        System.assertEquals(PerformanceTargetDO.STATUS_ACTIVE, openTarget.Status__c);
    }
}