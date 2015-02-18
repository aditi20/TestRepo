/**
 * Data Object class for SObjectFilterCondition__c
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public with sharing class SObjectFilterConditionDO extends SObjectDomain {

    public static final String NOT_EQUALS = 'Not Equals';
    public static final String LESS_THAN = 'Less Than';
    public static final String LESS_THAN_EQUALS = 'Less Than Equals';
    public static final String GREATER_THAN = 'Greater Than';
    public static final String GREATER_THAN_EQUALS = 'Greater Than Equals';
    public static final String EQUALS = 'Equals';

    public static Map<String, String> operatorTranslations = new Map<String, String>{
        NOT_EQUALS => '!=',
        LESS_THAN => '<',
        LESS_THAN_EQUALS => '<=',
        GREATER_THAN => '>',
        GREATER_THAN_EQUALS => '>=',
        EQUALS => '='
    };

    private static Set<Schema.SOAPType> validFieldTypes = new Set<Schema.SOAPType>{
        Schema.SOAPType.Boolean,
        Schema.SOAPType.Double,
        Schema.SOAPType.Integer,
        Schema.SOAPType.String
    };

    private static Map<String, Set<String>> selectQueryStrings = new Map<String, Set<String>>();

    public SObjectFilterConditionDO() {
        super(SObjectFilterCondition__c.SObjectType);
    }

    public SObjectFilterConditionDO(List<SObjectFilterCondition__c> sObjects) {
        super(sObjects);
    }

    /**
     * Add a SELECT query fragment for a given sobject
     *
     * @param filter        - The SObjectFilterCondition__c being added
     * @param objectApiName - The API name of the object being searched for
     */
    public static void addSelectQueryString(SObjectFilterCondition__c filter, String objectApiName) {

        if (!selectQueryStrings.containsKey(objectApiName)) {
            selectQueryStrings.put(objectApiName, new Set<String>());
        }
        selectQueryStrings.get(objectApiName).add(filter.FieldAPIName__c);
    }

    /**
     * Determine if a record passes a filter condition. This method inspects the filter and
     * delegates to the correct method.
     *
     * @param filter - The SObjectFilterCondition__c being added
     * @param record - The record being tested
     *
     * @return - A boolean indicating if the record has passed the filter
     */
    public static Boolean doesRecordPassFilter(SObjectFilterCondition__c filter, sObject record) {

        GenericObjectCreator sObjectFilterConditionCreator =
            new GenericObjectCreator(SObjectFilterCondition__c.SObjectType);
        sObjectFilterConditionCreator.checkObjectAccessible();
        sObjectFilterConditionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            SObjectFilterCondition__c.FieldAPIName__c,
            SObjectFilterCondition__c.Value__c,
            SObjectFilterCondition__c.Operator__c
        });

        Schema.SOAPType fieldSoapType = validateFilter(filter, record);

        if (fieldSoapType.equals(Schema.SOAPType.Boolean)) {
            return doesBooleanFieldPassFilter(filter, record);
        } else if (fieldSoapType.equals(Schema.SOAPType.String)) {
            return doesStringFieldPassFilter(filter, record);
        } else if (
                fieldSoapType.equals(Schema.SOAPType.Double) ||
                fieldSoapType.equals(Schema.SOAPType.Integer)
        ) {
            return doesDoubleFieldPassFilter(filter, record);
        } else {
            throw new SObjectFilterException(
                'Field type is not supported for object filtering',
                true
            );
        }
        return false;
    }

    /**
     * Validate that the filter is valid. Define if the
     *
     * @param filter - The SObjectFilterCondition__c being added
     * @param record - The record being tested
     *
     * @return - The Schema.SOAPType of the field that the filter refers to
     */
    private static Schema.SOAPType validateFilter(SObjectFilterCondition__c filter, sObject record) {

        // Someone has willfully added an unsupported operator to the drop down list so blow up
        if (!operatorTranslations.containsKey(filter.Operator__c)) {
            throw new SObjectFilterException('Operator is invalid', true);
        }

        // Check that the field in the filter still exists
        String objectName = record.getSObjectType().getDescribe().getName();
        if (!DescribeHandler.fieldExists(objectName, filter.FieldAPIName__c)) {
            throw new SObjectFilterException('Field no longer exists', true);
        }
        Schema.SOAPType fieldSoapType = 
            DescribeHandler.getFieldDescribe(objectName, filter.FieldAPIName__c).getSOAPType();

        // Check that the field type is allowed
        if (!validFieldTypes.contains(fieldSoapType)) {
            throw new SObjectFilterException('Invalid field type', true);
        }
        return fieldSoapType;
    }

    /**
     * Determine if a record passes a filter condition for a Boolean field
     *
     * @param filter - The SObjectFilterCondition__c being added
     * @param record - The record being tested
     *
     * @return - A boolean indicating if the record has passed the filter
     */
    private static Boolean doesBooleanFieldPassFilter(
            SObjectFilterCondition__c filter,
            sObject record
    ) {

        // Check the filter value is true|false
        if (
                !filter.Value__c.equals('false') &&
                !filter.Value__c.equals('true')
        ) {
            throw new SObjectFilterException('Filter value is invalid', true);
        }
        Boolean result;
        if (filter.Operator__c.equals(EQUALS)) {
            result = record.get(filter.FieldAPIName__c) == Boolean.valueOf(filter.Value__c);
        }
        else if (filter.Operator__c.equals(NOT_EQUALS)) {
            result = record.get(filter.FieldAPIName__c) != Boolean.valueOf(filter.Value__c);
        }
        else {
            throw new SObjectFilterException('Boolean operator is invalid', true);
        }
        return result;
    }

    /**
     * Determine if a record passes a filter condition for a Double field
     *
     * @param filter - The SObjectFilterCondition__c being added
     * @param record - The record being tested
     *
     * @return - A boolean indicating if the record has passed the filter
     */
    private static Boolean doesDoubleFieldPassFilter(SObjectFilterCondition__c filter, sObject record) {

        // Validate that the test string is a valid number
        String testString = String.valueOf(filter.Value__c);
        if (
                String.isBlank(testString) ||
                !testString.isNumeric()
        ) {
            throw new SObjectFilterException('Field value for test string is invalid', false);
        }
        Double fieldValue = Double.valueOf(record.get(filter.FieldAPIName__c));
        Double testValue = Double.valueOf(testString);
        Boolean result;
        if (filter.Operator__c.equals(EQUALS)) {
            result = fieldValue == testValue;
        }
        else if (filter.Operator__c.equals(LESS_THAN)) {
            result = fieldValue < testValue;
        }
        else if (filter.Operator__c.equals(LESS_THAN_EQUALS)) {
            result = fieldValue <= testValue;
        }
        else if (filter.Operator__c.equals(GREATER_THAN)) {
            result = fieldValue > testValue;
        }
        else if (filter.Operator__c.equals(GREATER_THAN_EQUALS)) {
            result = fieldValue >= testValue;
        }
        else if (filter.Operator__c.equals(NOT_EQUALS)) {
            result = fieldValue != testValue;
        }
        return result;
    }

    /**
     * Determine if a record passes a filter condition for a String field
     *
     * @param filter - The SObjectFilterCondition__c being added
     * @param record - The record being tested
     *
     * @return - A boolean indicating if the record has passed the filter
     */
    private static Boolean doesStringFieldPassFilter(SObjectFilterCondition__c filter, sObject record) {

        Boolean result;
        if (filter.Operator__c.equals(EQUALS)) {
            result = String.valueOf(record.get(filter.FieldAPIName__c)).
                equalsIgnoreCase(filter.Value__c);
        } else if (filter.Operator__c.equals(NOT_EQUALS)) {
            result = !String.valueOf(record.get(filter.FieldAPIName__c)).
                equalsIgnoreCase(filter.Value__c);
        }
        return result;
    }

    /**
     * Exception class for the filters
     */
    public class SObjectFilterException extends Exception {

        private Boolean fatalError;

        public SObjectFilterException(String message, Boolean fatalError) {
            this.fatalError = fatalError;
            this.setMessage(message);
        }

        public Boolean getFatalError() {
            return this.fatalError;
        }
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public SObjectFilterConditionDO constructWithRecords(List<SObject> sObjectList) {
            return new SObjectFilterConditionDO(sObjectList);
        }
        public SObjectFilterConditionDO constructEmpty() {
            return new SObjectFilterConditionDO();
        }
    }
}