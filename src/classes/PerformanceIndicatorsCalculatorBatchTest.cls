/**
 * Test class for PerformanceIndicatorsCalculatorBatch_V2
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
@isTest
public class PerformanceIndicatorsCalculatorBatchTest {

    private static PerformanceManagementTest.EndToEndTestWrapper endToEndTestWrapper;

    /**
     * Pointless test for code coverage
     */
    static testMethod void testCodeCoverageOfDeprecatedClass() {
        PerformanceIndicatorsCalculatorBatch batch = new PerformanceIndicatorsCalculatorBatch(
            new List<String>{},
            0,
            0
        );

        Test.startTest();
        Database.executeBatch(batch, 50);
        Test.stopTest();
    }

    /**
     * Test creation of PerformanceIndicatorCategory.
     * This mocks the batch re-starting itself to test that it moves successfully on to the
     * next object
     */
    static testMethod void testPerformanceIndicatorCategoryCreation() {

        String contactApiName = Contact.SObjectType.getDescribe().getName();
        String accountApiName = Account.SObjectType.getDescribe().getName();

        String contactNameField = Contact.Name.getDescribe().getName();
        String contactIdField = Contact.Id.getDescribe().getName();
        String contactContactLinkField = Contact.ReportsToId.getDescribe().getName();
        String accountNameField = Account.Name.getDescribe().getName();
        String accountIdField = Account.Id.getDescribe().getName();
        String accountContactLinkField = Account.Site.getDescribe().getName();
        List<String> objectApiNames = new List<String>{contactApiName, accountApiName};

        // Init the EndToEndTestWrapper
        endToEndTestWrapper = new PerformanceManagementTest.EndToEndTestWrapper();

        endToEndTestWrapper.createPartnerSurveyor(true);
        TestUtils.Surveyor mobileUser = endToEndTestWrapper.getSurveyor();

        // Set up some PerformanceIndicators for both the object API Name used
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            2,
            'TestBatchCreationWEEKLY',
            null,
            new Map<Integer, String>{
                0 => contactApiName,
                1 => accountApiName
            },
            new Map<Integer, String>{
                0 => PerformanceTargetDO.AGGREGATION_OPERATION_SUM,
                1 => PerformanceTargetDO.AGGREGATION_OPERATION_SUM
            },
            new Map<Integer, String>{
                0 => contactNameField,
                1 => accountNameField
            },
            new Map<Integer, String>{
                0 => contactContactLinkField,
                1 => accountContactLinkField
            },
            null
        );
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_MONTHLY,
            2,
            'TestBatchCreationMONTHLY',
            null,
            new Map<Integer, String>{
                0 => contactApiName,
                1 => accountApiName
            },
            new Map<Integer, String>{
                0 => PerformanceTargetDO.AGGREGATION_OPERATION_SUM,
                1 => PerformanceTargetDO.AGGREGATION_OPERATION_SUM
            },
            new Map<Integer, String>{
                0 => contactIdField,
                1 => accountIdField
            },
            new Map<Integer, String>{
                0 => contactContactLinkField,
                1 => accountContactLinkField
            },
            null
        );
        insert endToEndTestWrapper.createDefaultAssignedTargets();

        // Create the batch process with 0 index
        PerformanceIndicatorsCalculatorBatch_V2 batch = new PerformanceIndicatorsCalculatorBatch_V2(
            objectApiNames,
            0,
            0
        );

        // Inspect the PerformanceIndicatorCategory created by the batch process
        System.assertEquals(contactApiName, batch.performanceIndicatorCategory.objectApiName);
        System.assertEquals(
            2,
            batch.performanceIndicatorCategory.performanceTargets.values().size()
        );
        System.assertEquals(
            5,
            batch.performanceIndicatorCategory.getSelectClauseFields().size()
        );
        System.assert(
            batch.performanceIndicatorCategory.getSelectClauseFields().contains(contactNameField),
            contactNameField + ' Field is not in the ' + contactApiName + ' batch select clause'
        );
        System.assert(
            batch.performanceIndicatorCategory.getSelectClauseFields().contains(contactIdField),
            contactIdField + ' Field is not in the ' + contactApiName + ' batch select clause'
        );
        System.assert(
            batch.performanceIndicatorCategory.getSelectClauseFields().contains(
                contactContactLinkField
            ),
            contactContactLinkField + ' Field is not in the ' + contactApiName +
                ' batch select clause'
        );
        List<AssignedTarget__c> allExistingUsersAssignedTargets = [
            SELECT
                Id,
                Contact__c
            FROM
                AssignedTarget__c
            WHERE
                Contact__c != :mobileUser.theContact.Id
            AND
                PerformanceTarget__c IN :batch.performanceIndicatorCategory.performanceTargets.values()
        ];
        System.assertEquals(
            2,
            batch.assignedTargets.values().size() - allExistingUsersAssignedTargets.size()
        );

        // Create the batch process with 1 index
        batch = new PerformanceIndicatorsCalculatorBatch_V2(
            objectApiNames,
            1,
            0
        );

        // Inspect the PerformanceIndicatorCategory created by the batch process
        System.assertEquals(accountApiName, batch.performanceIndicatorCategory.objectApiName);
        System.assertEquals(
            2,
            batch.performanceIndicatorCategory.performanceTargets.values().size()
        );
        System.assertEquals(
            5,
            batch.performanceIndicatorCategory.getSelectClauseFields().size()
        );
        System.assert(
            batch.performanceIndicatorCategory.getSelectClauseFields().contains(accountNameField),
            accountNameField + ' Field is not in the ' + contactApiName + ' batch select clause'
        );
        System.assert(
            batch.performanceIndicatorCategory.getSelectClauseFields().contains(accountIdField),
            accountIdField + ' Field is not in the ' + contactApiName + ' batch select clause'
        );
        System.assert(
            batch.performanceIndicatorCategory.getSelectClauseFields().contains(
                accountContactLinkField
            ),
            accountContactLinkField + ' Field is not in the ' + contactApiName +
                ' batch select clause'
        );
        System.assertEquals(
            2,
            batch.assignedTargets.values().size() - allExistingUsersAssignedTargets.size()
        );
    }

    /**
     * Test running of the batch
     */
    static testMethod void testBatchExecution() {

        List<String> objectApiNames = new List<String>{
            Contact.SObjectType.getDescribe().getName()
        };

        // Init the EndToEndTestWrapper
        endToEndTestWrapper = new PerformanceManagementTest.EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        createContactsForMainBatchTest();
        createPerformanceIndicatorsForMainBatchTest();
        insert endToEndTestWrapper.createDefaultAssignedTargets();

        PerformanceIndicatorsCalculatorBatch_V2 batch = new PerformanceIndicatorsCalculatorBatch_V2(
            objectApiNames,
            0,
            0
        );

        Test.startTest();
        Database.executeBatch(batch, 50);
        Test.stopTest();

        validateUpdatedAssignedTarget(0, PerformanceTargetDO.TIMEFRAME_WEEKLY, 5);
        validateUpdatedAssignedTarget(1, PerformanceTargetDO.TIMEFRAME_WEEKLY, 1);
        validateUpdatedAssignedTarget(2, PerformanceTargetDO.TIMEFRAME_MONTHLY, 10);
    }

    /**
     * Test running of batch job when a performance indicator has a bad filter
     */
    static testMethod void testCatchingBadIndictorFilter() {

        List<String> objectApiNames = new List<String>{
            Contact.SObjectType.getDescribe().getName()
        };

        // Init the EndToEndTestWrapper
        endToEndTestWrapper = new PerformanceManagementTest.EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        createContactsForMainBatchTest();
        createBadFilterPerformanceIndicators();
        insert endToEndTestWrapper.createDefaultAssignedTargets();

        PerformanceIndicatorsCalculatorBatch_V2 batch = new PerformanceIndicatorsCalculatorBatch_V2(
            objectApiNames,
            0,
            0
        );

        Test.startTest();
        Database.executeBatch(batch, 50);
        Test.stopTest();

        validateUpdatedAssignedTarget(0, PerformanceTargetDO.TIMEFRAME_WEEKLY, 5);
        validateUpdatedAssignedTarget(1, PerformanceTargetDO.TIMEFRAME_WEEKLY, 0);
        PerformanceTargetDOTest.validatePerformanceTargetStillOpen(endToEndTestWrapper, 0);
        PerformanceTargetDOTest.validatePerformanceTargetClosedAutomatically(
            endToEndTestWrapper, 
            1
        );
    }

    /**
     * Test running of batch job when a performance indicator has a bad contact look up
     */
    static testMethod void testCatchingBadContactLookup() {

        List<String> objectApiNames = new List<String>{
            Contact.SObjectType.getDescribe().getName()
        };

        // Init the EndToEndTestWrapper
        endToEndTestWrapper = new PerformanceManagementTest.EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        createContactsForMainBatchTest();
        createBadContactLookupPerformanceIndicators();
        insert endToEndTestWrapper.createDefaultAssignedTargets();

        PerformanceIndicatorsCalculatorBatch_V2 batch = new PerformanceIndicatorsCalculatorBatch_V2(
            objectApiNames,
            0,
            0
        );

        Test.startTest();
        Database.executeBatch(batch, 50);
        Test.stopTest();

        validateUpdatedAssignedTarget(0, PerformanceTargetDO.TIMEFRAME_WEEKLY, 5);
        validateUpdatedAssignedTarget(1, PerformanceTargetDO.TIMEFRAME_WEEKLY, 0);
        PerformanceTargetDOTest.validatePerformanceTargetStillOpen(endToEndTestWrapper, 0);
        PerformanceTargetDOTest.validatePerformanceTargetClosedAutomatically(
            endToEndTestWrapper,
            1
        );
    }

    /**
     * Test running of batch job when a performance indicator has a bad contact look up
     */
    static testMethod void testCatchingBadTrackingField() {

        List<String> objectApiNames = new List<String>{
            Contact.SObjectType.getDescribe().getName()
        };

        // Init the EndToEndTestWrapper
        endToEndTestWrapper = new PerformanceManagementTest.EndToEndTestWrapper();
        endToEndTestWrapper.createPartnerSurveyor(true);
        createContactsForMainBatchTest();
        createBadTrackedFieldPerformanceIndicators();
        insert endToEndTestWrapper.createDefaultAssignedTargets();

        PerformanceIndicatorsCalculatorBatch_V2 batch = new PerformanceIndicatorsCalculatorBatch_V2(
            objectApiNames,
            0,
            0
        );

        Test.startTest();
        Database.executeBatch(batch, 50);
        Test.stopTest();

        validateUpdatedAssignedTarget(0, PerformanceTargetDO.TIMEFRAME_WEEKLY, 5);
        validateUpdatedAssignedTarget(1, PerformanceTargetDO.TIMEFRAME_WEEKLY, 0);
        PerformanceTargetDOTest.validatePerformanceTargetStillOpen(endToEndTestWrapper, 0);
        PerformanceTargetDOTest.validatePerformanceTargetClosedAutomatically(
            endToEndTestWrapper,
            1
        );
    }

    /**
     * Add contacts required for main batch test
     */
    private static void createContactsForMainBatchTest() {

        TestUtils.Surveyor mobileUser = endToEndTestWrapper.getSurveyor();
        insert new List<Contact>{
            new Contact(
                LastName = 'LastName', FirstName = 'John', IsClient__c = true,
                ReportsToId = mobileUser.theContact.Id
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'Paul', IsClient__c = true,
                ReportsToId = mobileUser.theContact.Id
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'John', IsClient__c = false,
                ReportsToId = mobileUser.theContact.Id
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'Frank', IsClient__c = true,
                ReportsToId = mobileUser.theContact.Id
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'John', IsClient__c = false,
                ReportsToId = mobileUser.theContact.Id
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'Boris', IsClient__c = true,
                ReportsToId = mobileUser.theContact.Id
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'John', IsClient__c = false,
                ReportsToId = mobileUser.theContact.Id
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'Horace', IsClient__c = true,
                ReportsToId = mobileUser.theContact.Id
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'John', IsClient__c = false,
                ReportsToId = mobileUser.theContact.Id
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'Mike', IsClient__c = true,
                ReportsToId = mobileUser.theContact.Id
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'John', IsClient__c = true
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'Mike', IsClient__c = true
            ),
            new Contact(
                LastName = 'LastName', FirstName = 'Mike', IsClient__c = true
            )
        };
    }

    /**
     * Create Performance Indicators required for the main batch test
     */
    private static void createPerformanceIndicatorsForMainBatchTest() {

        String contactApiName = Contact.SObjectType.getDescribe().getName();
        String contactNameField = Contact.Name.getDescribe().getName();
        String contactIdField = Contact.Id.getDescribe().getName();
        String contactContactLinkField = Contact.ReportsToId.getDescribe().getName();
        String contactFirstNameField = Contact.FirstName.getDescribe().getName();
        String contactIsClient = Contact.IsClient__c.getDescribe().getName();

        // Create a weekly target that only counts the Contacts with first name John
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            1,
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

        // Create a weekly target that only counts the Contacts with first name John and
        // has opted out of email
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            1,
            'TestCountOnlyJohnOptedOut',
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
                    ),
                    SObjectFilterConditionDOTest.createRecord(
                        contactIsClient,
                        SObjectFilterConditionDO.EQUALS,
                        'true',
                        null
                    )
                }
            }
        );

        // Create a monthly target that counts all the contacts
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_MONTHLY,
            1,
            'TestCountAll',
            null,
            new Map<Integer, String>{
                0 => contactApiName
            },
            null,
            new Map<Integer, String>{
                0 => contactIdField
            },
            new Map<Integer, String>{
                0 => contactContactLinkField
            },
            null
        );
    }

    /**
     * Create the Performance Indicators with a bad filter
     */
    private static void createBadFilterPerformanceIndicators() {

        String contactApiName = Contact.SObjectType.getDescribe().getName();
        String contactNameField = Contact.Name.getDescribe().getName();
        String contactContactLinkField = Contact.ReportsToId.getDescribe().getName();
        String contactFirstNameField = Contact.FirstName.getDescribe().getName();
        String contactIsClient = Contact.IsClient__c.getDescribe().getName();

        PerformanceTargetDOTest.createGoodIndicator(endToEndTestWrapper, 1);
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            1,
            'TestCountOnlyJohnOptedOut',
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
                    ),
                    SObjectFilterConditionDOTest.createRecord(
                        contactIsClient,
                        'BAD OPERATOR',
                        'true',
                        null
                    )
                }
            }
        );
    }

    /**
     * Create the Performance Indicators with a bad lookup to contact field
     */
    private static void createBadContactLookupPerformanceIndicators() {

        String contactApiName = Contact.SObjectType.getDescribe().getName();
        String contactNameField = Contact.Name.getDescribe().getName();
        String contactContactLinkField = Contact.ReportsToId.getDescribe().getName();
        String contactFirstNameField = Contact.FirstName.getDescribe().getName();
        String contactIsClient = Contact.IsClient__c.getDescribe().getName();

        PerformanceTargetDOTest.createGoodIndicator(endToEndTestWrapper, 1);
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            1,
            'TestBadCountOnlyJohn',
            null,
            new Map<Integer, String>{
                0 => contactApiName
            },
            null,
            new Map<Integer, String>{
                0 => contactNameField
            },
            new Map<Integer, String>{
                0 => 'BADFIELDNAME'
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
     * Create the Performance Indicators with a bad lookup to contact field
     */
    private static void createBadTrackedFieldPerformanceIndicators() {

        String contactApiName = Contact.SObjectType.getDescribe().getName();
        String contactNameField = Contact.Name.getDescribe().getName();
        String contactContactLinkField = Contact.ReportsToId.getDescribe().getName();
        String contactFirstNameField = Contact.FirstName.getDescribe().getName();
        String contactIsClient = Contact.IsClient__c.getDescribe().getName();

        PerformanceTargetDOTest.createGoodIndicator(endToEndTestWrapper, 1);
        endToEndTestWrapper.initPerfomanceIndicatorPerformanceTargetWrappers(
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            1,
            'TestBadCountOnlyJohn',
            null,
            new Map<Integer, String>{
                0 => contactApiName
            },
            new Map<Integer, String>{
                0 => PerformanceTargetDO.AGGREGATION_OPERATION_SUM
            },
            new Map<Integer, String>{
                0 => 'BADFIELDNAME'
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
     * Validate that the updated AssignedTarget is correct
     */
    private static void validateUpdatedAssignedTarget(
            Integer index,
            String timeframe,
            Integer actualValue
    ) {

        Map<Id, Map<Date, AssignedTarget__c>> updatedAssignedTargets =
            endToEndTestWrapper.getAllAssignedTargets();
        Id performanceTargetId =
            endToEndTestWrapper.getPerformanceTargetByCreationIndex(index).Id;
        Date startDate = PerformanceTargetDO.getStartOfCurrentTimePeriod(
            Date.today(),
            timeframe
        );
        System.assert(updatedAssignedTargets.containsKey(performanceTargetId));
        System.assertEquals(
            actualValue,
            updatedAssignedTargets.get(performanceTargetId).get(startDate).ActualValue__c
        );
    }
}