/**
 * Infrastructure class that handles describe calls.
 * Ensures that the describe call is only made once per object or field
 * in a single invocation of apex.
 * TODO: When Summer 14 is released most of this can be cleared out. Look
 *         at putting AccessControl into it's own class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies odavies@grameenfoundation.org
 */
public without sharing class DescribeHandler {

    public static final String FIELD_NOT_EXIST =
        'Field with api name: {0} for object with api name: {1} does not exist';

    private static Map<String, Schema.SObjectType> sobjectSchemaMap;

    private static Map<String, ObjectDescribeWrapper> objectDescribe =
        new Map<String, ObjectDescribeWrapper>();

    /**
     * Get the global describe for all objects
     *
     * @return - The globalDescribe Map
     */
    public static Map<String, Schema.SObjectType> getGlobalDescribe() {

        if (sobjectSchemaMap == null) {
            sobjectSchemaMap = Schema.getGlobalDescribe();
        }
        return sobjectSchemaMap;
    }

    /**
     * Method to reset Describe handler to initial state.
     * Useful when we are trying to test using System.runAs()
     */
    public static void resetDescribeHandler() {
        if (Test.isRunningTest()) {
            sobjectSchemaMap = null;
            objectDescribe = new Map<String, ObjectDescribeWrapper>();
        }
    }

    /**
     * Add a ObjectDescribe to the map so it can be used again later.
     *
     * @param objectName     - The API name of the object
     * @param describeResult - A pre-fetched describe result for this object
     * @param initFields     - Indicates if the field map should be fetched.
     *                          Counts towards describeLimit
     */
    public static Schema.DescribeSObjectResult addObjectDescribe(
            Schema.DescribeSObjectResult describeResult,
            String objectName,
            Boolean initFields
    ) {

        if (!objectDescribe.containsKey(objectName)) {
            objectDescribe.put(objectName, new ObjectDescribeWrapper(
                objectName,
                describeResult,
                initFields
            ));
        }
        return getObjectDescribeResult(objectName, initFields);
    }

    /**
     * Get the DescribeSObjectResult for a given object
     * Ensures that the getDescribe method is only called once per invocation of apex for the
     * given object
     *
     * @param objectName  - The API name of the object
     * @param getFieldMap - Initialize the field map at the same time. Counts towards describes limit
     *
     * @return - The DescribeSObjectResult for the object or null if it doesn't exist
     */
    public static Schema.DescribeSObjectResult getObjectDescribeResult(
            String objectName,
            Boolean setUpFieldMap
    ) {

        if (!objectDescribe.containsKey(objectName)) {
            objectDescribe.put(objectName, new ObjectDescribeWrapper(objectName, setUpFieldMap));
        } else if (setUpFieldMap && !objectDescribe.get(objectName).hasInitFields()) {
            objectDescribe.get(objectName).initFields();
        }
        return objectDescribe.get(objectName).getSpecificObjectDescribe();
    }

    /**
     * Add an object describe to the map from an object type
     */
    public static Schema.DescribeSObjectResult getObjectDescribeResult(
            Schema.SObjectType objectType,
            Boolean setUpFieldMap
    ) {
        Schema.DescribeSObjectResult sObjectDescribe = objectType.getDescribe();
        String objectName = sObjectDescribe.getName();
        if (!objectDescribe.containsKey(objectName)) {
            objectDescribe.put(objectName, new ObjectDescribeWrapper(
                objectName,
                sObjectDescribe,
                setUpFieldMap
            ));
        } else if (setUpFieldMap && !objectDescribe.get(objectName).hasInitFields()) {
            objectDescribe.get(objectName).initFields();
        }
        return objectDescribe.get(objectName).getSpecificObjectDescribe();
    }

    /**
     * Get the DescribeFieldResult for a given field of a given object.
     * Ensures that the getDescribe method is only called once per invocation of apex for a given
     * object and field
     *
     * @param objectName - The API name of the object that the field belongs to
     * @param fieldName  - The API name of the field
     *
     * @return - The DescribeFieldResult for the named field or null if it doesn't exist
     */
    public static Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
        if (getObjectDescribeResult(objectName, true) != null) {
            return objectDescribe.get(objectName).getSpecificFieldDescribe(fieldName);
        }
        return null;
    }

    /**
     * Get the field map for a given object
     *
     * @param objectName - The API name of the object that the field belongs to
     *
     * @return - field map for the object or null if it doesn't exist
     */
    public static Map<String, Schema.SObjectField> getFieldMap(String objectName) {
        if (getObjectDescribeResult(objectName, true) != null) {
            return objectDescribe.get(objectName).getSpecificFieldMap();
        }
        return null;
    }

    /**
     * Get the field type for a given field
     *
     * @param objectName - The API name of the object that the field belongs to
     * @param fieldName  - The API name of the field
     *
     * @return - field type for the field or null if it doesn't exist
     */
    public static Schema.SObjectField getFieldType(String objectName, String fieldName) {
        if (fieldExists(objectName, fieldName)) {
            return objectDescribe.get(objectName).getSpecificFieldMap().get(fieldName);
        }
        return null;
    }

    /**
     * Get the list of child relationships
     *
     * @param objectName - The API name of the object
     *
     * @return - the list of the child relationships
     */
    public static List<Schema.ChildRelationship> getChildRelationships(String objectName) {
        if (getObjectDescribeResult(objectName, true) != null) {
            return objectDescribe.get(objectName).getSpecificChildRelationships();
        }
        return null;
    }

    /**
     * Determine if an object exists
     *
     * @param objectName - The API name of the object
     *
     * @return - Boolean indicating if the object exists
     */
    public static Boolean objectExists(String objectName) {
        return getObjectDescribeResult(objectName, false) != null;
    }

    /**
     * Determine if a field exists
     *
     * @param objectName - The API name of the object that the field belongs to
     * @param fieldName  - The API name of the field
     *
     * @return - Boolean indicating if the object exists
     */
    public static Boolean fieldExists(String objectName, String fieldName) {
        return getFieldDescribe(objectName, fieldName) != null;
    }

    /**
     * Get Picklist values for a specific field of the object
     * 
     * @param fieldName - this will give API name of the field
     * 
     * @return - List<Schema.PicklistEntry> values for the field API provided.
     */
    public static List<Schema.PicklistEntry> getFieldPicklist(String objectName, String fieldName) {
        if (getObjectDescribeResult(objectName, true) != null) {
            if (
                    !objectDescribe.get(objectName).getSpecificFieldPicklistMap().containsKey(
                        fieldName
                    )
            ) {
                objectDescribe.get(objectName).getSpecificFieldPicklistMap().put(
                    fieldName, getFieldDescribe(objectName, fieldName).getPickListValues()
                );
            }
            return objectDescribe.get(objectName).getSpecificFieldPicklistMap().get(fieldName);
        }
        return null;
    }

    /**
     * Validate that a SOQL path exists
     */
    public static Boolean validatePath(String objectName, String pathToValidate) {
        List<String> splitPath = pathToValidate.split('\\.');
        String currentField = convertField(splitPath[0], splitPath.size() == 1);
        Boolean isSuccess =
            isPathFieldValid(objectName, currentField, splitPath.size());
        if (isSuccess && splitPath.size() > 1) {
            splitPath.remove(0);
            objectName = getReferencedObjectName(objectName, currentField);
            isSuccess = validatePath(objectName, String.join(splitPath, '.'));
        }
        return isSuccess;
    }

    /**
     * Convert a relation field into the field name
     */
    public static String convertField(String fieldName, Boolean isEndOfPath) {
        if (fieldName.endsWithIgnoreCase('__r')) {
            fieldName = fieldName.subString(0, fieldName.length() - 1) + 'c';
        } else if (!isEndOfPath) {
            fieldName = fieldName + 'Id';
        }
        return fieldName;
    }

    /**
     * Check if field is valid for a path
     */
    public static Boolean isPathFieldValid(
            String objectName,
            String fieldName,
            Integer pathSize
    ) {
        return fieldExists(objectName, fieldName) &&
            (
                pathSize == 1 ||
                getFieldDescribe(objectName, fieldName).getType() ==
                    Schema.DisplayType.REFERENCE
            );
    }

    /**
     * Get the referenced object name in a reference field. For now will only get the first
     * referenced object.
     * TODO - When SoC merged. Add the get describe to the object wrappers using the new methods
     */
    public static String getReferencedObjectName(String objectName, String fieldName) {
        List <Schema.sObjectType> linkedObjects =
            getFieldDescribe(objectName, fieldName).getReferenceTo();
        return linkedObjects[0].getDescribe().getName();
    }

    /**
     * Return the object label for a given object API Name
     */
    public static String getObjectLabel(String objectName) {
        if (!objectExists(objectName)) {
            throw new DescribeHandlerException(
                System.Label.OBJECT_DOES_NOT_EXIST,
                new List<String>{objectName}
            );
        }
        return objectDescribe.get(objectName).getObjectLabel();
    }

    /**
     * Class to contain the object describe and all the fields and field describes
     */
    private class ObjectDescribeWrapper {

        private Schema.DescribeSObjectResult objectDescribeResult;
        private Map<String, Schema.DescribeFieldResult> fieldDescribeResults;
        private Map<String, Schema.SObjectField> fieldMap;
        private Boolean hasInitFields;
        private Map<String, List<Schema.PicklistEntry>> sObjectFieldPicklistMap;

        /**
         * Constructor for the class. Gets the DescribeSObjectResult for the object and if it exists
         * gets the fieldMap for the object as well
         *
         * @param objectName - The API name of the object
         * @param initFields - Indicates if the field map should be fetched. Counts towards describeLimit
         */
        public ObjectDescribeWrapper(String objectName, Boolean initFields) {

            if (getGlobalDescribe().get(objectName) != null) {
                this.objectDescribeResult = getGlobalDescribe().get(objectName).getDescribe();
                if (initFields) {
                    this.fieldMap = this.objectDescribeResult.fields.getMap();
                }
                this.fieldDescribeResults = new Map<String, Schema.DescribeFieldResult>();
                this.sObjectFieldPicklistMap = new Map<String, List<Schema.PicklistEntry>>();
            }
            this.hasInitFields = initFields;
        }

        /**
         * Constructor for the class. Gets the DescribeSObjectResult for the object and if it exists
         * gets the fieldMap for the object as well
         *
         * @param objectName     - The API name of the object
         * @param describeResult - A pre-fetched describe result for this object
         * @param initFields     - Indicates if the field map should be fetched.
         *                          Counts towards describeLimit
         */
        public ObjectDescribeWrapper(
                String objectName,
                Schema.DescribeSObjectResult describeResult,
                Boolean initFields
        ) {
            this.objectDescribeResult = describeResult;
            if (initFields) {
                this.fieldMap = this.objectDescribeResult.fields.getMap();
            }
            this.fieldDescribeResults = new Map<String, Schema.DescribeFieldResult>();
            this.sObjectFieldPicklistMap = new Map<String, List<Schema.PicklistEntry>>();
            this.hasInitFields = initFields;
        }

        /**
         * Get the label for the object
         */
        public String getObjectLabel() {
            return this.objectDescribeResult.getLabel();
        }

        /**
         * Get the DescribeSObjectResult for the object.
         *
         * @return - The DescribeSObjectResult for the object or null if it doesn't exist
         */
        public Schema.DescribeSObjectResult getSpecificObjectDescribe() {
            return this.objectDescribeResult;
        }

        /**
         * Get the DescribeFieldResult for a given field name. Returns null if object or field doesn't exist
         *
         * @param fieldName - The API name of the field
         *
         * @return - The DescribeFieldResult for the named field or null if it doesn't exist
         */
        public Schema.DescribeFieldResult getSpecificFieldDescribe(String fieldName) {

            Schema.DescribeFieldResult fieldDescribe = this.fieldDescribeResults.get(fieldName);
            if (
                    fieldDescribe == null &&
                    this.objectDescribeResult != null &&
                    this.fieldMap.get(fieldName) != null
            ) {
                fieldDescribe = this.fieldMap.get(fieldName).getDescribe();
                this.fieldDescribeResults.put(fieldName, fieldDescribe);
            }
            return fieldDescribe;
        }

        /**
         * Get the field map for the object
         *
         * @return - field map for the object or null if it doesn't exist
         */
        public Map<String, Schema.SObjectField> getSpecificFieldMap() {
            return this.fieldMap;
        }

        /**
         * Get the child relationships for the object
         *
         * @return - alist with the child relationships
         */
        public List<Schema.ChildRelationship> getSpecificChildRelationships() {
            return this.objectDescribeResult.getChildRelationships();
        }

        /**
         * Get the field picklist map for the object
         *
         * @return - list of Schema.PicklistEntry values
         */
        public Map<String, List<Schema.PicklistEntry>> getSpecificFieldPicklistMap() {
            return this.sObjectFieldPicklistMap;
        }

        /**
         * Initiate the field map for the object
         */
        public void initFields() {

            if (this.objectDescribeResult != null) {
                this.fieldMap = this.objectDescribeResult.fields.getMap();
                this.fieldDescribeResults = new Map<String, Schema.DescribeFieldResult>();
                this.hasInitFields = true;
            }
        }

        /**
         * Indicates if the fields have been initialised for the object
         */
        public Boolean hasInitFields() {
            return this.hasInitFields;
        }
    }

    /**
     * TODO - If access control is moved to it's own class then split out a new exception
     */
    public class DescribeHandlerException extends BaseException {
        public DescribeHandlerException(String message, List<String> args) {
            super(message, args);
        }
    }
}