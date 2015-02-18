/**
 * Generic object creator.
 * Deals with:
 *    - Generic creation of a record
 *    - Object and field CRUD/FLS permissions
 *    - Population and validation of fields
 *
 * TODO:
 *    - Move thrown errors to translatable error messages
 *    - Look at moving access controls when SoC and UoW architecture fully implemented
 *        This is being done after the security review.
 *
 * Note that this class is without sharing as it only deals with CRUD/FLS checks and record
 * population. No SOQL or DML should ever be done in this class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public without sharing class GenericObjectCreator {

    private static final String ACCESSIBLE = 'Accessible';
    private static final String CREATEABLE = 'Createable';
    private static final String UPDATEABLE = 'Updateable';

    // Map of already used GenericObjectCreators. Stops wasted time by stopping re-creation 
    // a creator each time it is used
    private static Map<String, GenericObjectCreator> creators =
        new Map<String, GenericObjectCreator>();

    /**
     * Fetch a generic object creator. Will initiate it if it doesn't already exist
     * Use this version to fetch the creator that has initiated the object describe result
     */
    public static GenericObjectCreator fetchObjectsCreator(Schema.SObjectType objectType) {
        String objectName = objectType.getDescribe().getName();
        GenericObjectCreator creatorToReturn = fetchObjectsCreator(objectName);
        if (creatorToReturn == null) {
            creatorToReturn = new GenericObjectCreator(objectType);
            creators.put(objectName, creatorToReturn);
        }
        creatorToReturn.ensureFieldsLoaded();
        return creatorToReturn;
    }

    /**
     * Fetch a generic object creator. Will initiate it if it doesn't already exist
     * Use this version to fetch the creator that has not initiated the object describe result
     */
    public static GenericObjectCreator fetchObjectsCreator(String objectName) {
        GenericObjectCreator creatorToReturn = creators.get(objectName);
        if (creatorToReturn == null) {
            creatorToReturn = new GenericObjectCreator(objectName);
            creators.put(objectName, creatorToReturn);
        }
        return creatorToReturn;
    }

    public Schema.SObjectType objectType;
    public Schema.DescribeSObjectResult sObjectDescribe;
    private String sObjectName;
    private Boolean skipBlanks;
    private Boolean hasInitiatedDescribe;

    // Use this constructor if you want to populate fields details
    public GenericObjectCreator(Schema.SObjectType objectType) {
        this(objectType.getDescribe().getName());
        DescribeHandler.getObjectDescribeResult(this.sObjectName, true);
        this.hasInitiatedDescribe = true;
    }

    // Use this constructor if you want to populate only Object details
    public GenericObjectCreator(String objectName) {
        this.objectType = DescribeHandler.getGlobalDescribe().get(objectName);
        this.sObjectDescribe = objectType.getDescribe();
        this.sObjectName = sObjectDescribe.getName();
        this.skipBlanks = false;
        this.hasInitiatedDescribe = false;
    }

    /**
     * There are cases when skipping blanks is valid. When a survey has a question that is left
     * empty and it maps to a nillable field
     */
    public void setSkipBlanks(Boolean value) {
        this.skipBlanks = value;
    }

    /**
     * Make sure that the Object Describe has been initiated in the DescribeHandler
     */
    public void ensureFieldsLoaded() {
        if (!this.hasInitiatedDescribe) {
            DescribeHandler.getObjectDescribeResult(this.sObjectName, true);
            this.hasInitiatedDescribe = true;
        }
    }

    /**
     * Create an individual record
     */
    public SObject createNewRecord() {
        checkObjectCreateable();
        return objectType.newSObject();
    }

    /**
     * Access controls. The CRUD access controls will be superseeded by the check in
     * the UoW and TriggerHandler. When that new architecture is full implemented these
     * can be removed (except checkObjectCreatable() as that allows us to bail out much
     * earlier in the process without having to wait for a DML action)
     */
    public void checkObjectAccessible() {
        if (!isObjectAccessible(true)) {
            throw new GenericObjectCreatorException(
                System.Label.OBJECT_CAN_NOT_BE_ACCESSED,
                new List<String>{this.sObjectName}
            );
        }
    }

    public Boolean isObjectAccessible(Boolean initFields) {
        if (DescribeHandler.getObjectDescribeResult(this.sObjectName, initFields).isAccessible()) {
            return true;
        } else {
            return false;
        }
    }

    public void checkObjectCreateable() {
        if (!DescribeHandler.getObjectDescribeResult(this.sObjectName, true).isCreateable()) {
            throw new GenericObjectCreatorException(
                System.Label.OBJECT_CAN_NOT_BE_CREATED,
                new List<String>{this.sObjectName}
            );
        }
    }

    public void checkObjectUpdateable() {
        if (!DescribeHandler.getObjectDescribeResult(this.sObjectName, true).isUpdateable()) {
            throw new GenericObjectCreatorException(
                System.Label.OBJECT_CAN_NOT_BE_UPDATE,
                new List<String>{this.sObjectName}
            );
        }
    }

    public void checkObjectDeletable() {
        if (!DescribeHandler.getObjectDescribeResult(this.sObjectName, true).isDeletable()) {
            throw new GenericObjectCreatorException(
                System.Label.OBJECT_CAN_NOT_BE_DELETED,
                new List<String>{this.sObjectName}
            );
        }
    }

    public void checkFieldsAccessible(List<Schema.SObjectField> fieldList) {
        for (Schema.SObjectField field : fieldList) {
            canAccess(field.getDescribe().getName());
        }
    }

    public void checkFieldsAccessible(List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            if (fieldName.contains('.')) {
                validatePathPermissions(this.sObjectName, fieldName, ACCESSIBLE);
            } else {
                canAccess(fieldName);
            }
        }
    }

    public void checkFieldsCreateable(List<Schema.SObjectField> fieldList) {
        for (Schema.SObjectField field : fieldList) {
            canCreate(field.getDescribe().getName());
        }
    }

    public void checkFieldsCreateable(List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            if (fieldName.contains('.')) {
                validatePathPermissions(this.sObjectName, fieldName, CREATEABLE);
            } else {
                canCreate(fieldName);
            }
        }
    }

    public void checkFieldsUpdateable(List<Schema.SObjectField> fieldList) {
        for (Schema.SObjectField field : fieldList) {
            canUpdate(field.getDescribe().getName());
        }
    }

    public void checkFieldsUpdateable(List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            if (fieldName.contains('.')) {
                validatePathPermissions(this.sObjectName, fieldName, UPDATEABLE);
            } else {
                canUpdate(fieldName);
            }
        }
    }

    /**
     * This method check permissions for reference fields
     */
    private void validatePathPermissions(
            String objectName,
            String pathToValidate,
            String checkPermission
    ) {
        List<String> splitPath = pathToValidate.split('\\.');
        String currentField =
            DescribeHandler.convertField(splitPath[0], splitPath.size() == 1);
        GenericObjectCreator creator =
            new GenericObjectCreator(DescribeHandler.getGlobalDescribe().get(objectName));

        // Verify permissions based on type of action to be performed
        if (checkPermission.equalsIgnoreCase(ACCESSIBLE)) {
            creator.checkObjectAccessible();
            creator.canAccess(currentField);
        } else if (checkPermission.equalsIgnoreCase(CREATEABLE)) {
            creator.checkObjectCreateable();
            creator.canCreate(currentField);
        } else if (checkPermission.equalsIgnoreCase(UPDATEABLE)) {
            creator.checkObjectUpdateable();
            creator.canUpdate(currentField);
        }

        if (splitPath.size() > 1) {
            splitPath.remove(0);
            objectName =
                DescribeHandler.getReferencedObjectName(objectName, currentField);
            validatePathPermissions(objectName, String.join(splitPath, '.'), checkPermission);
        }
    }

    /**
     * Populate a bunch of fields for a record
     */
    public void populateFields(Sobject record, Map<Schema.SObjectField, Object> newFields) {
        for (Schema.SObjectField newField : newFields.keySet()) {
            populateField(record, newField, newFields.get(newField));
        }
    }

    public void populateFields(Sobject record, Map<String, Object> newFields) {
        for (String fieldName : newFields.keySet()) {
            if (!DescribeHandler.fieldExists(this.sObjectName, fieldName)) {
                throw new GenericObjectCreatorException(
                    System.Label.FIELD_DOES_NOT_EXIST,
                    new List<String>{fieldName, this.sObjectName}
                );
            }
            populateField(
                record,
                DescribeHandler.getFieldType(this.sObjectName, fieldName),
                newFields.get(fieldName)
            );
        }
    }

    /**
     * Populate a field for all the records in the list
     */
    public void populateFieldForAllRecords(
            List<SObject> records,
            Schema.SObjectField field,
            Object value
    ) {
        for (SObject record : records) {
            populateField(record, field, value);
        }
    }

    public void populateField(SObject record, Schema.SObjectField field, Object value) {
        validateField(record, field);
        setFieldValue(record, field, value);
    }

    private void setFieldValue(SObject record, Schema.SObjectField field, Object value) {
        if (record.getSObjectType() != objectType) {
            throw new GenericObjectCreatorException(
                System.Label.TYPE_MISMATCH,
                new List<String>{
                    record.getSObjectType().getDescribe().getName(),
                    sObjectDescribe.getName()
                }
            );
        }
        if ((Object)value instanceOf String) {
            setFieldValueFromString(record, field, (String) value);
        } else {
            setFieldValueFromObject(record, field, value);
        }
    }

    /**
     * This method will primarily be used from the field mapping. It will validate that the field
     * type is valid to be mapped to
     */
    private void setFieldValueFromString(SObject record, Schema.SObjectField field, String value) {
        validateField(record, field);
        Schema.DescribeFieldResult fieldDescribe =
            field.getDescribe();
        Schema.SOAPType fieldSoapType =
            fieldDescribe.getSOAPType();
        if (String.isNotBlank(value)) {
            if (
                (fieldSoapType == Schema.SOAPType.STRING || fieldSoapType == Schema.SOAPType.ID) &&
                !fieldDescribe.isAutoNumber()
            ) {
                record.put(field, value);
            } else if (fieldSoapType == Schema.SOAPType.DATETIME) {
                record.put(field, SurveyUtils.valueInGmt(value));
            } else if (fieldSoapType == Schema.SOAPType.DATE) {
                record.put(field, Date.valueOf(value));
            } else if (fieldSoapType == Schema.SOAPType.DOUBLE) {
                record.put(field, Double.valueOf(value));
            } else if (fieldSoapType == Schema.SOAPType.INTEGER) {
                record.put(field, Integer.valueOf(value));
            } else if (fieldSoapType == Schema.SOAPType.BOOLEAN) {
                record.put(field, (value.toLowerCase()=='true' || value=='1'));
            } else if (fieldSoapType == Schema.SOAPType.LOCATION) {
                parseLocation(record, fieldDescribe.getName(), value);
            } else {
                throwFieldTypeNotSupported(
                    String.valueOf(fieldDescribe.getType()),
                    fieldDescribe.getName()
                );
            }
        } else if (!skipBlanks) {
            if (fieldDescribe.isNillable()) {
                if (fieldSoapType == Schema.SOAPType.LOCATION) {
                    List<String> geoLocationFieldsList =
                        distributeLocationField(fieldDescribe.getName());
                    for (String geoLocationField : geoLocationFieldsList) {
                        record.put(geoLocationField, null);
                    }
                } else {
                    record.put(field, null);
                }
            } else {
                throw new GenericObjectCreatorException(
                    System.Label.FIELD_CANNOT_BE_NULLED,
                    new List<String>{
                        fieldDescribe.getName()
                    }
                );
            }
        }
    }

    private void setFieldValueFromObject(SObject record, Schema.SObjectField field, Object value) {
        validateField(record, field);
        record.put(field, value);
    }

    private void parseLocation(SObject record, String field, String value) {
        SurveyUtils.GeoLocation parsedLocationField =
            SurveyUtils.parseGeoLocation(value, true);
        List<String> geoLocationFieldsList = distributeLocationField(field);
        if (geoLocationFieldsList != null) {
            for (String geoLocationField : geoLocationFieldsList) {
                 record.put(
                     geoLocationField,
                     parsedLocationField.validGeoLocationValue(
                         geoLocationField,
                         parsedLocationField
                     )
                 );
            }
        }
    }

    /**
     * Create latitude and longitude fields for a Geolocation Field
     */
    @TestVisible
    private List<String> distributeLocationField(String mappedFieldName) {
        String fieldApi = mappedFieldName.substring(0, mappedFieldName.length() - 1);
        List<String> geoLocationFieldsList = new List<String> {
            fieldApi + 'Latitude__s',
            fieldApi + 'Longitude__s'
        };
        return geoLocationFieldsList;
    }

    private void throwFieldTypeNotSupported(String fieldType, String fieldName) {
        throw new GenericObjectCreatorException(
            System.Label.FIELD_TYPE_NOT_SUPPORTED,
            new List<String>{
                fieldType,
                fieldName
            }
        );
    }

    /**
     * Validate that the field exists and that the user has permission to manipulate it
     */
    private void validateField(SObject record, Schema.SObjectField field) {
        validateField(record, field.getDescribe().getName());
    }

    private void validateField(SObject record, String fieldName) {
        if (!DescribeHandler.fieldExists(this.sObjectName, fieldName)) {
            throw new GenericObjectCreatorException(
                System.Label.FIELD_DOES_NOT_EXIST,
                new List<String>{fieldName, this.sObjectName}
            );
        }
        if (record.Id != null) {
            canUpdate(fieldName);
        } else {
            canCreate(fieldName);
        }
    }

    private void canAccess(String fieldName) {
        if (!DescribeHandler.getFieldDescribe(this.sObjectName, fieldName).isAccessible()) {
            throw new GenericObjectCreatorException(
                System.Label.FIELD_CAN_NOT_BE_ACCESSED,
                new List<String>{fieldName, this.sObjectName}
            );
        }
    }

    private void canCreate(String fieldName) {
        if (String.valueOf(DescribeHandler.getFieldDescribe(
                this.sObjectName, fieldName).getType()
            ).equalsIgnoreCase('LOCATION')
        ) {
            List<String> geoLocationFieldsList = distributeLocationField(fieldName);
            if (geoLocationFieldsList != null) {
                for (String geoLocationField : geoLocationFieldsList) {
                    if (!DescribeHandler.getFieldDescribe(
                            this.sObjectName, geoLocationField
                        ).isCreateable()
                    ) {
                        throw new GenericObjectCreatorException(
                            System.Label.FIELD_CAN_NOT_BE_CREATED,
                            new List<String>{fieldName, this.sObjectName}
                        );
                    }
                }
            }
        } else {
            if (!DescribeHandler.getFieldDescribe(this.sObjectName, fieldName).isCreateable()) {
                throw new GenericObjectCreatorException(
                    System.Label.FIELD_CAN_NOT_BE_CREATED,
                    new List<String>{fieldName, this.sObjectName}
                );
            }
        }
    }

    private void canUpdate(String fieldName) {
        if (String.valueOf(DescribeHandler.getFieldDescribe(
                this.sObjectName, fieldName).getType()
            ).equalsIgnoreCase('LOCATION')
        ) {
            List<String> geoLocationFieldsList = distributeLocationField(fieldName);
            if (geoLocationFieldsList != null) {
                for (String geoLocationField : geoLocationFieldsList) {
                    if (!DescribeHandler.getFieldDescribe(
                            this.sObjectName, geoLocationField
                        ).isUpdateable()
                    ) {
                        throw new GenericObjectCreatorException(
                            System.Label.FIELD_CAN_NOT_BE_UPDATED,
                            new List<String>{fieldName, this.sObjectName}
                        );
                    }
                }
            }
        } else {
            if (!DescribeHandler.getFieldDescribe(this.sObjectName, fieldName).isUpdateable()) {
                throw new GenericObjectCreatorException(
                    System.Label.FIELD_CAN_NOT_BE_UPDATED,
                    new List<String>{fieldName, this.sObjectName}
                );
            }
        }
    }

    public class GenericObjectCreatorException extends BaseException {
        public GenericObjectCreatorException(String message, String[] args) {
            super(message, args);
        }
    }
}