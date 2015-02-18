/**
 * Controller for the PerformanceTrackedObjectSelect component
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */     
public with sharing class TrackedObjectController {

    /**
     * Load the contact objects for the select value
     *
     * @param objectName - The name of the object whos children must be loaded
     * @return Map of the object name to the wrapper object containing all it's data
     */
    private static Map<String, ObjectData> loadChildObjects(String objectName) {
        Map<String, ObjectData>  objectNameToObjectData = new Map<String, ObjectData>();
        for (
                Schema.ChildRelationship child :
                DescribeHandler.getChildRelationships(objectName)
        ) {
            DescribeSObjectResult objDesc =
                DescribeHandler.getObjectDescribeResult(child.getChildSObject(), false);
            GenericObjectCreator creator =
                new GenericObjectCreator(objDesc.getName());

            if (creator.isObjectAccessible(false)) {
                DescribeFieldResult fieldDescribe = child.getField().getDescribe();
                if (objectNameToObjectData.get(objDesc.getName()) == null) {
                    ObjectData obj = new ObjectData(objDesc);
                    objectNameToObjectData.put(objDesc.getName(), obj);
                }

                FieldData field = new FieldData(fieldDescribe);
                objectNameToObjectData.get(objDesc.getName()).addField(field);
            }
        }
        return objectNameToObjectData;
    }
    
    /**
     * get the objects of the corresponding path and base objectApiName
     * 
     * @param path The complete path with the field name
     * @param trackedObject the name of the base object
     */
    private static List<ObjectSelectData> getObjectsFromPath(String path, String trackedObject) {
        List<ObjectSelectData> objectList = new List<ObjectSelectData>();
        List<String> fieldList  = path.split('\\.');
        String currentObjectName = trackedObject;
        for (String currentField:fieldList){
            String currentObjectLabel =
                DescribeHandler.getObjectDescribeResult(currentObjectName, true).getLabel();
            Schema.DescribeFieldResult fieldDescribe =
                DescribeHandler.getFieldDescribe(currentObjectName, currentField);
            String relationshipLabel = fieldDescribe.isCascadeDelete() 
                ? System.Label.MASTER_DETAIL_LABEL
                : System.Label.LOOKUP_LABEL;
            objectList.add(
                new ObjectSelectData(
                    currentObjectLabel,
                    fieldDescribe.getLabel(),
                    relationshipLabel
                )
            );
            currentObjectName = fieldDescribe.getReferenceTo()[0].getDescribe().getName();
        }
        return objectList;
    }
    /**
     * Remote Action to get the data of the related childs
     * of an object
     */
    @RemoteAction
    public static String loadSerializedChildObjects(String parentObject){
        return JSON.serialize(loadChildObjects(parentObject));
    }
    
    /**
     * Get the serialized object data from a path and objectApiName
     * @param pathDataJson serialized pathData string
     * @return the object data serialized
     */
    @RemoteAction
    public static String getSerializedObjectsFromPath(String pathDataJson) {
        PathData pathDataObject = (PathData) Json.deserialize(pathDataJson, PathData.class);
        return JSON.serialize(getObjectsFromPath(pathDataObject.path, pathDataObject.trackedObject));
    }
    
    /**
     * Wrapper to contain the object information 
     * used as JSON in frontend
     */
    public class ObjectData {
        public String name;
        public String label;
        public Map<String, FieldData> fields;
        
        /**
         * Class constructor
         */
        public ObjectData(DescribeSObjectResult objDesc){
            this.name = objDesc.getName();
            this.label = objDesc.getLabel();
            this.fields = new Map<String, FieldData>();
        }
        
        /**
         * add a field to the map
         *
         * @param - the field to add
         */
        public void addField(FieldData field){
            fields.put(field.name, field);
        }
    }
    
    /**
     * Wrapper class that contains information about a field
     * used as JSON in frontend
     */
    public class FieldData {
        public String label;
        public String name;
        public boolean isRequiered;
        public String type;
        public String relationType;
        
        public FieldData(DescribeFieldResult fieldDescribe) {
            SFDCEncoder encoder = new SFDCEncoder();
            this.name = fieldDescribe.getName();
            this.label = encoder.SFDC_JSENCODE(fieldDescribe.getLabel());
            this.isRequiered = fieldDescribe.isNillable();
            this.type = fieldDescribe.getType().name();
            this.relationType = (fieldDescribe.isCascadeDelete()) ?
                                System.Label.MASTER_DETAIL_LABEL :
                                System.Label.LOOKUP_LABEL;
        }
    }
    
    /**
     * Wrapper class to get all the object information from the remoting
     */
    public class PathData {
        public String trackedObject;
        public String path;
        
        public PathData(String trackedObject, String path) {
            this.trackedObject = trackedObject;
            this.path  = path;
        }
    }
    
    /**
     * Wrapper class to use in the page to load the existing data (on update)
     */
     public class ObjectSelectData {
        public String objectLabel;
        public String fieldLabel;
        public String relationType;
        
        /**
         * Class Constructor
         **/
        public ObjectSelectData(String objectLabel, String fieldLabel, String relationType) {
            this.objectLabel  = objectLabel;
            this.fieldLabel = fieldLabel;
            this.relationType = relationType;
        }
     }
}
