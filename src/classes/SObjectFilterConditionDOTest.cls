/**
 * Test class for SObjectFilterConditionDO class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
@isTest
public class SObjectFilterConditionDOTest {

    /**
     * Create a SObjectFilterCondition record
     *
     * @param fieldApiName        - fieldApiName of the field that is being tested
     * @param operator            - Operator used in test formula
     * @param value               - Value for the filter to test for
     * @param performanceTargetId - PerformanceTarget__c.Id that the filter is for
     *
     * @return - The newly created SObjectFilterCondition record
     */
    public static SObjectFilterCondition__c createRecord(
            String fieldApiName,
            String operator,
            String value,
            Id performanceTargetId
    ) {
        return new SObjectFilterCondition__c(
            FieldAPIName__c = fieldApiName,
            Operator__c = operator,
            Value__c = value,
            PerformanceTarget__c = performanceTargetId
        );
    }

    /**
     * Test invalid field type
     */
    static testMethod void testReferenceInvalidFieldType() {

        Contact testRecord = new Contact(
            LastName = 'LASTNAMESOFCDT',
            DoNotCall = true
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'Id', SObjectFilterConditionDO.EQUALS, 'someId', null
            );
        insert filter;
        try {
            SObjectFilterConditionDO.doesRecordPassFilter(filter, testRecord);
            System.assert(
                false,
                'This should throw an error as the field in the filter is of the wrong type'
            );
        }
        catch (SObjectFilterConditionDO.SObjectFilterException se) {
            System.assertEquals(
                'Invalid field type',
                se.getMessage()
            );

        }
    }

    /**
     * Test filter referencing a field that doesn't exist
     */
    static testMethod void testReferenceMissingField() {

        Contact testRecord = new Contact(
            LastName = 'LASTNAMESOFCDT',
            DoNotCall = true
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'AMISSINGFIELD', SObjectFilterConditionDO.EQUALS, 'INVALID', null
            );
        insert filter;
        try {
            SObjectFilterConditionDO.doesRecordPassFilter(filter, testRecord);
            System.assert(
                false,
                'This should throw an error as the field in the filter is not a valid API name'
            );
        }
        catch (SObjectFilterConditionDO.SObjectFilterException se) {
            System.assertEquals('Field no longer exists', se.getMessage());
            System.assert(se.getFatalError());
        }
    }

    /**
     * Test Boolean Equals Success
     */
    static testMethod void testBooleanEqualsSuccess() {

        Contact testRecord = new Contact(
            LastName = 'LASTNAMESOFCDT',
            DoNotCall = true
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'DoNotCall', SObjectFilterConditionDO.EQUALS, 'true', null
            );
        insert filter;
        System.assert(
            SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record failed to pass the Boolean equals filter'
        );
    }

    /**
     * Test Boolean Equals Failure
     */
    static testMethod void testBooleanEqualsFail() {

        Contact testRecord = new Contact(
            LastName = 'LASTNAMESOFCDT',
            DoNotCall = false
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'DoNotCall', SObjectFilterConditionDO.EQUALS, 'true', null
            );
        insert filter;
        System.assert(
            !SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record passed Boolean equals filter when it should have failed'
        );
    }

    /**
     * Test Boolean not equals Success
     */
    static testMethod void testBooleanNotEqualsSuccess() {

        Contact testRecord = new Contact(
            LastName = 'LASTNAMESOFCDT',
            DoNotCall = false
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'DoNotCall', SObjectFilterConditionDO.NOT_EQUALS, 'true', null
            );
        insert filter;
        System.assert(
            SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record failed to pass the Boolean not equals filter'
        );
    }

    /**
     * Test Boolean not equals failure
     */
    static testMethod void testBooleanNotEqualsFail() {

        Contact testRecord = new Contact(
            LastName = 'LASTNAMESOFCDT',
            DoNotCall = true
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'DoNotCall', SObjectFilterConditionDO.NOT_EQUALS, 'true', null
            );
        insert filter;
        System.assert(
            !SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record passed Boolean not equals filter when it should have failed'
        );
    }

    /**
     * Test Boolean invalid operator
     */
    static testMethod void testInvalidOperatorBoolean() {

        Contact testRecord = new Contact(
            LastName = 'LASTNAMESOFCDT',
            DoNotCall = true
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'DoNotCall', SObjectFilterConditionDO.GREATER_THAN, 'false', null
            );
        insert filter;
        try {
            SObjectFilterConditionDO.doesRecordPassFilter(filter, testRecord);
            System.assert(
                false,
                'Should throw an exception as greater than is not allowed as a Boolean filter'
            );
        }
        catch (SObjectFilterConditionDO.SObjectFilterException se) {
            System.assertEquals('Boolean operator is invalid', se.getMessage());
        }
    }

    /**
     * Test Boolean filter value is invalid
     */
    static testMethod void testInvalidFilterValue() {

        Contact testRecord = new Contact(
            LastName = 'LASTNAMESOFCDT',
            DoNotCall = true
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'DoNotCall', SObjectFilterConditionDO.EQUALS, 'INVALID', null
            );
        insert filter;
        try {
            SObjectFilterConditionDO.doesRecordPassFilter(filter, testRecord);
            System.assert(
                false,
                'Should throw an exception as filter value is invalid'
            );
        }
        catch (SObjectFilterConditionDO.SObjectFilterException se) {
            System.assertEquals('Filter value is invalid', se.getMessage());
        }
    }

    /**
     * Test double equals success
     */
    static testMethod void testDoubleInvalidFilter() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 10
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.EQUALS, 'INVALID', null
            );
        insert filter;
        try {
            SObjectFilterConditionDO.doesRecordPassFilter(filter, testRecord);
            System.assert(
                false,
                'Should throw an exception as as filter value is invalid'
            );
        }
        catch (SObjectFilterConditionDO.SObjectFilterException se) {
            System.assertEquals('Field value for test string is invalid', se.getMessage());
        }
    }

    /**
     * Test double equals success
     */
    static testMethod void testDoubleEqualsSuccess() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 10
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.EQUALS, '10', null
            );
        insert filter;
        System.assert(
            SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record failed Double equals filter when it should have passed'
        );
    }

    /**
     * Test double equals failure
     */
    static testMethod void testDoubleEqualsFailure() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 10
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.EQUALS, '20', null
            );
        insert filter;
        System.assert(
            !SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record passed Double equals filter when it should have failed'
        );
    }

    /**
     * Test double not equals success
     */
    static testMethod void testDoubleNotEqualsSuccess() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 10
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.NOT_EQUALS, '20', null
            );
        insert filter;
        System.assert(
            SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record failed Double not equals filter when it should have passed'
        );
    }

    /**
     * Test double not equals failure
     */
    static testMethod void testDoubleNotEqualsFailure() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 10
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.NOT_EQUALS, '10', null
            );
        insert filter;
        System.assert(
            !SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record passed Double not equals filter when it should have failed'
        );
    }

    /**
     * Test double Less Than success
     */
    static testMethod void testDoubleLessThanSuccess() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 10
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.LESS_THAN, '11', null
            );
        insert filter;
        System.assert(
            SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record failed Double Less than filter when it should have passed'
        );
    }

    /**
     * Test double Less Than failure
     */
    static testMethod void testDoubleLessThanFailure() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 10
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.LESS_THAN, '10', null
            );
        insert filter;
        System.assert(
            !SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record passed Double Less than filter when it should have failed'
        );
    }

    /**
     * Test double Less Than Equals success
     */
    static testMethod void testDoubleLessThanEqualsSuccess() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 10
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.LESS_THAN_EQUALS, '10', null
            );
        insert filter;
        System.assert(
            SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record failed Double Less than equals filter when it should have passed'
        );
    }

    /**
     * Test double Less Than Equals failure
     */
    static testMethod void testDoubleLessThanEqualsFailure() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 10
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.LESS_THAN_EQUALS, '9', null
            );
        insert filter;
        System.assert(
            !SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record passed Double Less than equals filter when it should have failed'
        );
    }

    /**
     * Test double Greater Than success
     */
    static testMethod void testDoubleGreaterThanSuccess() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 11
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.GREATER_THAN, '10', null
            );
        insert filter;
        System.assert(
            SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'failed passed Double greater than filter when it should have passed'
        );
    }

    /**
     * Test double Greater Than failure
     */
    static testMethod void testDoubleGreaterThanFailure() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 8
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.GREATER_THAN, '9', null
            );
        insert filter;
        System.assert(
            !SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record passed Double Greater than filter when it should have failed'
        );
    }

    /**
     * Test double Greater Than success
     */
    static testMethod void testDoubleGreaterThanEqualsSuccess() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 10
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.GREATER_THAN_EQUALS, '10', null
            );
        insert filter;
        System.assert(
            SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record failed Double Greater than equals filter when it should have passed'
        );
    }

    /**
     * Test double Greater Than failure
     */
    static testMethod void testDoubleGreaterThanEqualsFailure() {

        Account testRecord = new Account(
            Name = 'TestAccount',
            NumberOfEmployees = 8
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'NumberOfEmployees', SObjectFilterConditionDO.GREATER_THAN_EQUALS, '9', null
            );
        insert filter;
        System.assert(
            !SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record passed Double Greater than equals filter when it should have failed'
        );
    }

    /**
     * Test String Equals Success
     */
    static testMethod void testStringEqualsSuccess() {

        Account testRecord = new Account(
            Name = 'TestAccount'
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'Name', SObjectFilterConditionDO.EQUALS, 'TestAccount', null
            );
        insert filter;
        System.assert(
            SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record failed String equals filter when it should have passed'
        );
    }

    /**
     * Test String Equals failure
     */
    static testMethod void testStringEqualsFailure() {

        Account testRecord = new Account(
            Name = 'TestAccount'
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'Name', SObjectFilterConditionDO.EQUALS, 'Test', null
            );
        insert filter;
        System.assert(
            !SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record passed String equals filter when it should have failed'
        );
    }

    /**
     * Test String Not Equals Success
     */
    static testMethod void testStringNotEqualsSuccess() {

        Account testRecord = new Account(
            Name = 'TestAccount'
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'Name', SObjectFilterConditionDO.NOT_EQUALS, 'Test', null
            );
        insert filter;
        System.assert(
            SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record failed String not equals filter when it should have passed'
        );
    }

    /**
     * Test String Not Equals failure
     */
    static testMethod void testStringNotEqualsFailure() {

        Account testRecord = new Account(
            Name = 'TestAccount'
        );
        insert testRecord;
        SObjectFilterCondition__c filter =
            createRecord(
                'Name', SObjectFilterConditionDO.NOT_EQUALS, 'TestAccount', null
            );
        insert filter;
        System.assert(
            !SObjectFilterConditionDO.doesRecordPassFilter(
                filter, testRecord
            ),
            'Record passed String not equals filter when it should have failed'
        );
    }
}