/**
 * Controller for the fieldFilter component
 * Used in the component to get the fields for the filter
 * and send in in json format.
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Ernesto Quesada
 */     
public with sharing class FieldFilterController {

    /**
     * Get the string fields for a certain object
     * 
     * @param selectedObject - The object from which the field must be getted
     */
    private static List<FieldData> getStringFields(String selectedObject) {
        List<FieldData> arrayFieldData = new List<FieldData>();
        if (DescribeHandler.objectExists(selectedObject)) {
            
            // Order the fieldsObject
            List<String> orderedFieldNames = new List<String>();
            orderedFieldNames.addAll(DescribeHandler.getFieldMap(selectedObject).keySet());
            orderedFieldNames.sort();
            for (String fieldName : orderedFieldNames) {
                Schema.DescribeFieldResult fieldResult = 
                    DescribeHandler.getFieldDescribe(selectedObject, fieldName);
                String fieldType = String.valueOf(fieldResult.getSOAPType());
                if (fieldType == Schema.SOAPType.String.name()) {
                    FieldData field = new FieldData(fieldResult);
                    arrayFieldData.add(field);
                }
            }
        }
        return arrayFieldData;
    }
    
    /**
     * Remote Action to get the data of the fields
     * of an object
     */
    @RemoteAction
    public static String getStringFieldsSerialized(String selectedObject) {
        return JSON.serialize(getStringFields(selectedObject));
    }
    
    /**
     * Wrapper class to get all the object information from the remoting
     */
    public class FieldData {
        public String name;
        public String label;
        
        public FieldData(Schema.DescribeFieldResult fieldResult) {
            this.name = String.valueOf(fieldResult.getName());
            this.label  = String.valueOf(fieldResult.getLabel());
        }
    }
}
