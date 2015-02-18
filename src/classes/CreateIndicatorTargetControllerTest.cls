/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Ernesto Quesada
 * @author - Aditi Satpute
 */
@isTest
public class CreateIndicatorTargetControllerTest {

    /**
     * Test the edition of the name of an indicator target
     */
    static testMethod void editIndicatorTargetName() {
        // Given a saved indicator target
        CreateIndicatorTargetController controller = createPreconditionsForIndicatorTargets(
            'targetName',
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            50,
            PerformanceTargetDOTest.ASSET_API_NAME,
            PerformanceTargetDOTest.CONTACT_ID_FIELD,
            '',
            true,
            PerformanceTargetDO.AGGREGATION_OPERATION_COUNT
        );

        Test.startTest();
        // When the name is edited and saved
        String newName = 'Some new name';
        controller.performanceTarget.Name = newName;
        controller.save();
        Test.stopTest();

        // Then the name is updated in the record
        System.assertEquals(
            newName,
            [SELECT Name FROM PerformanceTarget__c LIMIT 1][0].Name
        );
    }


    /**
     * Create new performance target with assigned targets with weekly timeframe
     */
    static testMethod void createAWeeklyIndicatorTargetWithDefaultTarget() {

        // Given the controller with an unsaved indicator target
        CreateIndicatorTargetController controller = createPreconditionsForIndicatorTargets(
            'pTarget',
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            50,
            PerformanceTargetDOTest.ASSET_API_NAME,
            PerformanceTargetDOTest.CONTACT_ID_FIELD,
            '',
            false,
            PerformanceTargetDO.AGGREGATION_OPERATION_COUNT
        );

        Test.startTest();
        // When the save action is ran
        controller.save();
        Test.stopTest();

        // Then the indicator target is saved and an assigned target is created
        checkIndicatorTargetWasSaved(PerformanceTargetDO.TIMEFRAME_WEEKLY);
        checkAnAssignedTargetWasCreated();
    }

    /**
     * Create Performance Indicator with Monthly Target
     */
    static testMethod void createAMonthlyIndicatorTargetWithDefaultTarget() {

        // Given the controller with an unsaved indicator target
        CreateIndicatorTargetController controller = createPreconditionsForIndicatorTargets(
            'pTarget',
            PerformanceTargetDO.TIMEFRAME_MONTHLY,
            50,
            PerformanceTargetDOTest.ASSET_API_NAME,
            PerformanceTargetDOTest.CONTACT_ID_FIELD,
            '',
            false,
            PerformanceTargetDO.AGGREGATION_OPERATION_COUNT
        );

        Test.startTest();
        // When the save action is ran
        controller.save();
        Test.stopTest();

        // Then the indicator target is saved and an assigned target is created
        checkIndicatorTargetWasSaved(PerformanceTargetDO.TIMEFRAME_MONTHLY);
        checkAnAssignedTargetWasCreated();
    }

    /**
     * Update a Indicator default value
     */
    static testMethod void updateIndicatorValues() {
        
        // Create preconditions to save
        CreateIndicatorTargetController controller = createPreconditionsForIndicatorTargets(
            'pTarget',
            PerformanceTargetDO.TIMEFRAME_MONTHLY,
            50,
            PerformanceTargetDOTest.ASSET_API_NAME,
            PerformanceTargetDOTest.CONTACT_ID_FIELD,
            '',
            false,
            PerformanceTargetDO.AGGREGATION_OPERATION_COUNT
        );
        // Save
        controller.save();

        PerformanceTarget__c performanceTarget = 
            [SELECT
                Id,
                EndDate__c,
                DefaultValue__c,
                (SELECT
                    PerformanceTarget__r.DefaultValue__c,
                    TargetValue__c,
                    Contact__c
                FROM
                    Assigned_Targets__r
                WHERE
                    EndDate__c = :controller.performanceTarget.EndDate__c)
            FROM
                PerformanceTarget__c
            WHERE
                Name = 'pTarget'];
        
        
        // Create preconditions to edit
        controller = createPreconditionsForIndicatorsEdition(performanceTarget);

        Test.startTest();
        // Save
        controller.save();
        Test.stopTest();

        // Check Target, and Default value is correctly saved on DB after edition
        system.assertEquals(120, Integer.ValueOf([SELECT
                                                        TargetValue__c
                                                    FROM
                                                        AssignedTarget__c LIMIT 1].TargetValue__c),
                                'Target value must be 120 after edition');

        system.assertEquals(200, Integer.ValueOf([SELECT
                                                        DefaultValue__c
                                                    FROM
                                                        PerformanceTarget__c LIMIT 1].DefaultValue__c),
                                'Default value must be 200 after edition');
    }

    /**
     * Test correct path modification
     */
    static testMethod void assertInvalidPath() {

        // get the fields throug the api in the case it has a namespace
        String parentIdField = Schema.sObjectType.Attachment.Fields.ParentId.getName();
        String contactField = Schema.sObjectType.Mobile_User__c.Fields.Contact__c.getName();
        String reportToId = Schema.sObjectType.Contact.Fields.ReportsToId.getName();

        // build the paths
        String fieldLookup = (parentIdField.replace('Id','') +
                '.' + contactField.replace('__c','__r') + '.' + reportToId);
        CreateIndicatorTargetController controller = createPreconditionsForIndicatorTargets(
            'pTarget',
            PerformanceTargetDO.TIMEFRAME_MONTHLY,
            50,
            Attachment.sObjectType.getDescribe().getName(),
            fieldLookup,
            '',
            false,
            PerformanceTargetDO.AGGREGATION_OPERATION_COUNT
        );

        Test.startTest();
        // Save
        controller.save();
        Test.stopTest();

        List<PerformanceTarget__c> performanceTargets = [
            SELECT
                DefaultValue__c,
                Timeframe__c,
                TrackedSObjectApiName__c,
                TrackedSObjectContactLookupFieldName__c,
                Type__c
            FROM
                PerformanceTarget__c
        ];

        // Check error messages
        System.assert(
            !Apexpages.getMessages().isEmpty(),
            'Should have complained that the path was broken'
        );
        // Check performance
        System.assert(
            performanceTargets.isEmpty(),
            'Must be empty since new Performance target was  not created'
        );
    }

    /**
     * Create a new Performance Indicator with default value for Sum
     */
    static testMethod void createIndicatorDefaultValuesForSum() {
        CreateIndicatorTargetController controller = createPreconditionsForIndicatorTargets(
            'pTarget',
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            50,
            PerformanceTargetDOTest.LEAD_API_NAME,
            PerformanceTargetDOTest.CONVERTED_CONTACT_ID_FIELD,
            PerformanceTargetDOTest.LEAD_NUMBER_OF_EMPLOYEES,
            false,
            PerformanceTargetDO.AGGREGATION_OPERATION_SUM
        );

        Test.startTest();
        controller.performanceTarget.AggregationOperation__c =
            PerformanceTargetDO.AGGREGATION_OPERATION_SUM;
        controller.getFieldList();
        controller.save();
        Test.stopTest();

        List<PerformanceTarget__c> performanceTargetList =
            new PerformanceTargetSelector().getAllForAggregationOperation(
                PerformanceTargetDOTest.LEAD_NUMBER_OF_EMPLOYEES,
                PerformanceTargetDO.AGGREGATION_OPERATION_SUM
            );

        System.assertEquals(
            1,
            performanceTargetList.size(),
            'Performance Target record for Sum Operation not inserted properly'
        );
    }

    /**
     * Update Performance Indicator with new default value for Sum
     */
    static testMethod void updateIndicatorValuesForSum() {
        CreateIndicatorTargetController controller = createPreconditionsForIndicatorTargets(
            'pTarget',
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            50,
            PerformanceTargetDOTest.LEAD_API_NAME,
            PerformanceTargetDOTest.CONVERTED_CONTACT_ID_FIELD,
            PerformanceTargetDOTest.LEAD_NUMBER_OF_EMPLOYEES,
            false,
            PerformanceTargetDO.AGGREGATION_OPERATION_SUM
        );
        controller.save();

        // Create preconditions to update Performance Target and Assigned Target
        controller = createPreconditionsForIndicatorsEdition(controller.performanceTarget);

        Test.startTest();
        // Perform update operation for Performance Target and Assignet Target records
        controller.save();
        Test.stopTest();

        PerformanceTarget__c performance =
            new PerformanceTargetSelector().getWithAssignedTargets(
                controller.performanceTarget.Id,
                controller.performanceTarget.EndDate__c
            );

        System.assert(performance != null, 'Performance Target record not found');
        System.assert(
            performance.Assigned_Targets__r.size() > 0,
            'There should be atleast one Assigned target record'
        );

        // Check Target and Default values are correctly saved on DB after performing update
        System.assertEquals(
            120,
            Integer.ValueOf(
                ((AssignedTarget__c) new AssignedTargetSelector().getRecordById(
                    performance.Assigned_Targets__r[0].Id
                )).TargetValue__c
            ),
            'Target value must be 120 after update'
        );

        System.assertEquals(
            200,
            Integer.ValueOf(
                ((PerformanceTarget__c) new PerformanceTargetSelector().getRecordById(
                    performance.Id
                )).DefaultValue__c
            ),
            'Default value must be 200 after update'
        );
    }

    /**
     * Create all preconditions for performance targets test
     *
     * @param targetName                - The performance target name
     * @param timeframe                 - The timeframe for the target
     * @param defaultValue              - The default target value
     * @param objectApiName             - The name of the object related
     * @param trackedContactLookUpField - The field use to track contact look up
     * @param trackedField              - The tracked field used for Sum operation
     * @param areForEdition             - Indicates if the preconditions are for edition
     *
     * @return - Instance of controller
     */
    private static CreateIndicatorTargetController createPreconditionsForIndicatorTargets(
            String targetName,
            String timeframe,
            Integer defaultValue,
            String objectApiName,
            String trackedContactLookUpField,
            String trackedField,
            Boolean areForEdition,
            String aggregationOperation
    ) {

        TestUtils.Surveyor activeSurveyor =
            TestUtils.createPartnerSurveyor('partnerContact', true);

        PerformanceTarget__c indicatorTarget;

        if (areForEdition) {
            PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper =
                new PerformanceManagementTest.EndToEndTestWrapper();
            endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
                timeframe,
                1,
                '',
                null,
                null,
                null,
                null,
                null,
                null
            );
            indicatorTarget = endToEndTestWrapper
                .getPerformanceTargetWrapperByCreationIndex(0).getPerformanceTarget();

            indicatorTarget.Name = targetName;
            indicatorTarget.DefaultValue__c = defaultValue;
            update indicatorTarget;
        } else {
            indicatorTarget = PerformanceTargetDOTest.createPerformanceIndicatorRecord(
                targetName,
                defaultValue,
                timeframe,
                Date.today(),
                Date.today(),
                objectApiName,
                aggregationOperation,
                trackedField,
                trackedContactLookUpField
            );
        }

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(indicatorTarget);
        CreateIndicatorTargetController controller =
            new CreateIndicatorTargetController(stdController);

        // Fill the individual target values
        for (AssignedTargetDO at : controller.assignedTargetWrappers) {
            at.targetValue = 50;
        }

        return controller;
    }

    /**
     * Check the indicator target was saved
     *
     * @param timeframe - The timeframe to check
     */
    private static void checkIndicatorTargetWasSaved(String timeframe) {
        List<PerformanceTarget__c> performanceTargets = [
            SELECT
                DefaultValue__c,
                Timeframe__c,
                TrackedSObjectApiName__c,
                TrackedSObjectContactLookupFieldName__c,
                Type__c
            FROM
                PerformanceTarget__c
        ];

        System.assert(
            !performanceTargets.isEmpty(),
            'Cannot be empty since new Performance target was created'
        );
        System.assertEquals(
            PerformanceTargetDO.TYPE_INDICATOR,
            performanceTargets[0].Type__c
        );
        System.assertEquals(
            timeframe,
            performanceTargets[0].Timeframe__c
        );
        System.assertEquals(50, Integer.ValueOf(performanceTargets[0].DefaultValue__c));
        System.assertEquals(
            PerformanceTargetDOTest.ASSET_API_NAME,
            performanceTargets[0].TrackedSObjectApiName__c
        );
        System.assertEquals(
            PerformanceTargetDOTest.CONTACT_ID_FIELD,
            performanceTargets[0].TrackedSObjectContactLookupFieldName__c
        );
    }

    /**
     * Check an assigned target was created with the given value
     */
    private static void checkAnAssignedTargetWasCreated() {
        List<AssignedTarget__c> assignedTargets = [SELECT TargetValue__c FROM AssignedTarget__c];
        System.assert(
            !assignedTargets.isEmpty(),
            'Cannot be empty since new Assigned target was created'
        );
        System.assertEquals(50, Integer.ValueOf(assignedTargets[0].TargetValue__c));
    }

    /**
     * Preconditions to edit a performance indicator target
     *
     * @param performanceTarget - Performance target to edit
     *
     * @return controller - Instance of controller
     */
    private static CreateIndicatorTargetController 
        createPreconditionsForIndicatorsEdition(PerformanceTarget__c performanceTarget) {

        ApexPages.StandardController stdController = new ApexPages.StandardController(performanceTarget);
        CreateIndicatorTargetController controller = new CreateIndicatorTargetController(stdController);

        // Set new target values for all assigned targets for the current job target
        for(AssignedTargetDO aT : controller.assignedTargetWrappers) {
            aT.targetValue = 120;
        }

        // Set new default value for the current job target
        controller.performanceTarget.DefaultValue__c = 200;

        return controller;
    }
}
