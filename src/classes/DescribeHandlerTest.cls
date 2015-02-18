/**
 * Test class for the DescribeHandler
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies odavies@grameenfoundation.org
 */
@isTest
public class DescribeHandlerTest {

    /**
     * Test calling getDescribe for the same class twice and esuring the describe Limits
     * only goes up by 1
     */
    static testMethod void testObjectGetDescribeCalledOnlyOnce() {

        // Get the global and the object describes so the do not interfer with the tests
        DescribeHandler.getGlobalDescribe();
        String objectName = Contact.sObjectType.getDescribe().getName();

        Integer initialLimits = Limits.getFieldsDescribes();
        DescribeHandler.getObjectDescribeResult(objectName, true);
        Integer afterFirstCall = Limits.getFieldsDescribes();
        System.assertEquals(initialLimits + 1, afterFirstCall);
        DescribeHandler.getObjectDescribeResult(objectName, true);
        Integer afterSecondCall = Limits.getFieldsDescribes();
        System.assertEquals(afterFirstCall, afterSecondCall);
    }

    /**
     * Test getting an object without initializing the fields doesn't increase limit
     */
    static testMethod void testGettingObjectNoFieldsInit() {

        // Get the global and the object describes so the do not interfer with the tests
        DescribeHandler.getGlobalDescribe();
        String objectName = Contact.sObjectType.getDescribe().getName();

        Integer initialLimits = Limits.getFieldsDescribes();
        DescribeHandler.getObjectDescribeResult(objectName, false);
        Integer afterFirstCall = Limits.getFieldsDescribes();
        System.assertEquals(initialLimits, afterFirstCall);
    }

    /**
     * Test that getting the Contact DescribeSObjectResult gets the correct result
     */
    static testMethod void testGettingObject() {

        String objectName = Contact.sObjectType.getDescribe().getName();
        Schema.DescribeSObjectResult result = DescribeHandler.getObjectDescribeResult(objectName, true);
        System.assertEquals(objectName, result.getName());
    }

    /**
     * Test getting an object from the object type
     */
    static testMethod void testGettingObjectFromObjectType() {
        String objectName = Contact.sObjectType.getDescribe().getName();
        Schema.DescribeSObjectResult result = DescribeHandler.getObjectDescribeResult(
            Contact.sObjectType,
            true
        );
        System.assertEquals(objectName, result.getName());
    }

    /**
     * Test initFields called only once
     */
    static testMethod void testInitFieldsCalledOnce() {

        // Get the global and the object describes so the do not interfer with the tests
        DescribeHandler.getGlobalDescribe();
        String objectName = Contact.sObjectType.getDescribe().getName();
        String fieldName = Contact.LastName.getDescribe().getName();

        Integer initialLimits = Limits.getFieldsDescribes();
        DescribeHandler.getFieldDescribe(objectName, fieldName);
        Integer afterFirstCall = Limits.getFieldsDescribes();
        System.assertEquals(initialLimits + 1, afterFirstCall);
        DescribeHandler.getFieldDescribe(objectName, fieldName);
        Integer afterSecondCall = Limits.getFieldsDescribes();
        System.assertEquals(afterFirstCall, afterSecondCall);
    }

    /**
     * Test getting a bad object returns null
     */
    static testMethod void testBadObjectName() {

        Schema.DescribeSObjectResult result = DescribeHandler.getObjectDescribeResult('BAD NAME', true);
        System.assertEquals(null, result);
    }

    /**
     * Test that getting the Contact.Name DescribeFieldResult gets the correct result
     */
    static testMethod void testGetBadObject() {
        System.assert(!DescribeHandler.objectExists('BAD NAME'));
    }

    /**
     * Test getting a bad field name returns null
     */
    static testMethod void testBadFieldName() {

        String objectName = Contact.sObjectType.getDescribe().getName();
        System.assert(!DescribeHandler.fieldExists(objectName, 'BAD NAME'));
    }

    /**
     * Test getting child relationship doesn't increase the limit
     */
    static testMethod void testGettingChildRelationships() {

        // Get the global and the object describes so the do not interfer with the tests
        DescribeHandler.getGlobalDescribe();
        String objectName = Contact.sObjectType.getDescribe().getName();

        Integer initialLimits = Limits.getFieldsDescribes();
        DescribeHandler.getChildRelationships(objectName);
        Integer afterFirstCall = Limits.getFieldsDescribes();
        System.assertEquals(initialLimits + 1, afterFirstCall);
        DescribeHandler.getChildRelationships(objectName);
        Integer afterSecondCall = Limits.getFieldsDescribes();
        System.assertEquals(afterFirstCall, afterSecondCall);
    }

    /**
     * Test validating a path to a parent object where the path is valid
     */
    static testMethod void validatePathToParentSuccess() {

        String assignedTargetObjectName = AssignedTarget__c.SobjectType.getDescribe().getName();
        String performanceTargetFieldName =
            AssignedTarget__c.PerformanceTarget__c.getDescribe().getName();
        String performanceTargetRelation =
            performanceTargetFieldName.subString(0, performanceTargetFieldName.length() - 1) + 'r';
        String validPath =
            performanceTargetRelation + '.' +
            PerformanceTarget__c.JobTemplate__c.getDescribe().getName();

        System.assert(DescribeHandler.validatePath(assignedTargetObjectName, validPath));
    }

    /**
     * Test validating a path to a parent object where the path is invalid
     */
    static testMethod void validatePathToParentBadField() {

        String assignedTargetObjectName = AssignedTarget__c.SobjectType.getDescribe().getName();
        String performanceTargetFieldName =
            AssignedTarget__c.PerformanceTarget__c.getDescribe().getName();
        String performanceTargetRelation =
            performanceTargetFieldName.subString(0, performanceTargetFieldName.length() - 1) + 'r';
        String invalidPath =
            performanceTargetRelation + '.' +
            'BadObjectName';

        System.assert(!DescribeHandler.validatePath(assignedTargetObjectName, invalidPath));
    }

    /**
     * Test converting field ending in __r
     */
    static testMethod void testConvertFieldEndingR() {
        System.assertEquals('Test__c', DescribeHandler.convertField('Test__r', false));
    }

    /**
     * Test converting field ending in __c
     */
    static testMethod void testConvertFieldEndingC() {
        String toConvert = 'Test__c';
        System.assertEquals(toConvert, DescribeHandler.convertField(toConvert, true));
    }

    /**
     * Test converting field ending in nothing special
     */
    static testMethod void testConvertFieldStandard() {
        System.assertEquals('toConvertId', DescribeHandler.convertField('toConvert', false));
    }

    /**
     * Test getting specific fieldType
     */
    static testMethod void testGettingSpecificFieldType() {
        String fieldName = Contact.Name.getDescribe().getName();
        Schema.SObjectField fieldType = Contact.Name;
        System.assertEquals(fieldType, getFieldType(fieldName));
    }

    /**
     * Test getting a fieldType that doesn't exist
     */
    static testMethod void testGettingSpecificFieldTypeNotExist() {
        System.assertEquals(null, getFieldType('fieldName'));
    }

    private static Schema.SObjectField getFieldType(String fieldName) {
        String objectName = Contact.sObjectType.getDescribe().getName();
        return DescribeHandler.getFieldType(objectName, fieldName);
    }

    /**
     * Test adding a Object describe to the map
     */
    static testMethod void testAddObjectDescribeWhenItIsNotPresent() {

        Schema.DescribeSObjectResult describeResult = Account.sObjectType.getDescribe();
        String objectName = describeResult.getName();

        DescribeHandler.addObjectDescribe(describeResult, objectName, false);
        Integer startingValue = Limits.getFieldsDescribes();

        DescribeHandler.getObjectDescribeResult(objectName, true);
        System.assertEquals(startingValue + 1, Limits.getFieldsDescribes());
    }

    /**
     * Test adding a Object describe to the map when the describe has already been added
     */
    static testMethod void testAddObjectDescribeWhenItIsPresent() {

        Schema.DescribeSObjectResult describeResult = Account.sObjectType.getDescribe();
        String objectName = describeResult.getName();
        DescribeHandler.getObjectDescribeResult(objectName, true);

        Integer startingValue = Limits.getFieldsDescribes();
        DescribeHandler.addObjectDescribe(describeResult, objectName, false);

        DescribeHandler.getObjectDescribeResult(objectName, true);
        System.assertEquals(startingValue, Limits.getFieldsDescribes());
    }

    /**
     * Test getting the object label for an object
     */
    static testMethod void testGettingObjectLabelSuccess() {
        String testObjectLabel = Contact.SobjectType.getDescribe().getLabel();
        String objectName = Contact.SobjectType.getDescribe().getName();
        try {
            String foundLabel = DescribeHandler.getObjectLabel(objectName);
            System.assertEquals(testObjectLabel, foundLabel);
        } catch (DescribeHandler.DescribeHandlerException dhe) {
            System.assert(false, 'No error should be thrown');
        }
    }

    /**
     * Test getting the object label for an object
     */
    static testMethod void testGettingObjectLabelBabObject() {
        String badObjectName = 'BAD_OBJECT_NAME';
        try {
            DescribeHandler.getObjectLabel(badObjectName);
            System.assert(false, 'Exception should be thrown as the object does not exist');
        } catch (DescribeHandler.DescribeHandlerException dhe) {
            System.assertEquals(
                String.format(
                    System.Label.OBJECT_DOES_NOT_EXIST,
                    new List<String>{badObjectName}
                ),
                dhe.getMessage()
            );
        }
    }
}