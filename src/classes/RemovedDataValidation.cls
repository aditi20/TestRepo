/*
 *  Class in charge to validate that a given object or fields are still present (not removed by the user).
 *
 *
 *  (c) Copyright 2013 Grameen Foundation USA. All rights reserved.
 *
 *  @author Claudio Soto csoto@altimetrik.com
 */
public with sharing class RemovedDataValidation {

    public static final String OBJECT_DELETED = 'Object-deleted';
    public static final String FIELD_DELETED  = 'Fields-deleted';

    public static Set<Id> idOfSurveyMappingsToRemove;
    public static List<ObjectRelationshipMapping__c> relationsToRemove;
    public static Set<Id> childrenToUpdateId;

    /**
     * Method in charge of validate that given an object name and a list of field names,
     * the object and all fields are still available (are not removed).
     * If the object or some field is removed, returns a map with the object or fields missing, null otherwise.
     *
     * @param objectName       - Name of the object.
     * @param listMappedFields - List<String> of the fields.
     *
     * @return - MissingData object, or null if no object or field is missing.
     */
    public static MissingData obtainMissingData(String objectName, List<String> listMappedFields) {

        MissingData missingData;

        if (!DescribeHandler.objectExists(objectName)) {

            // Object no longer exists in the org.
            missingData = new MissingData(OBJECT_DELETED, objectName, null);
        } else{
            List<String> missingFields = new List<String>();
            for (String fieldName : listMappedFields) {
                if (!String.isEmpty(fieldName) && !DescribeHandler.fieldExists(objectName, fieldName)) {

                    // This field is not present in the object anymore.
                    missingFields.add(fieldName);
                }
            }
            if (!missingFields.isEmpty()) {

                // Object exists, but at least one field is missing.
                missingData = new MissingData(FIELD_DELETED, objectName, missingFields);
            }
        }
        return missingData;
    }

    /**
     * Method that receives a List of ObjectRelationshipMapping__c, and call obtainMissingData method
     * in order to return a map with the form: Map<ObjectRelation.Id, RemovedDataValidation.MissingData> of the relation
     * with a missing attribute.
     *
     * @param listRelations - List of ObjectRelationshipMapping__c.
     *
     * @return - Map with the form: Map<ObjectRelation.Id, RemovedDataValidation.MissingData> of each relation with a missing value.
     */
    public static Map<String, MissingData> obtainMissingDataInBulkFromRelations(List<ObjectRelationshipMapping__c> listRelations) {

        Map<String, MissingData> mapMissingData = new Map<String, MissingData>();
        for (ObjectRelationshipMapping__c orm : listRelations) {

            // Obtain field name.
            List<String> listFields = new List<String>();
            listFields.add(orm.FieldApiName__c);

            // Obtain name of the object and create MissingData object.
            String objectName = orm.ChildSurveyMapping__r.ObjectApiName__c;
            MissingData currentMissingData = obtainMissingData(objectName, listFields);

            if (currentMissingData != null) {

                // Has a missing object or field, so we add it to the map to return.
                mapMissingData.put(orm.Id, currentMissingData);
            }
        }
        return mapMissingData;
    }

    /**
     * Method that receives a List of ExistentSurveyMapping, and call obtainMissingData method
     * in order to return a map with the form: Map<SurveyMapping.Id, MissingData> of the survey mappings
     * with any missing attribute.
     *
     * @param listExistentSm - List of SurveyFieldMappingController.ExistentSurveyMapping.
     *
     * @return - Map with the form: Map<SurveyMapping.Id, MissingData> with each object with a missing value.
     */
    public static Map<String, MissingData> obtainMissingDataInBulkFromExistentSM(
            List<SurveyFieldMappingController.ExistentSurveyMapping> listExistentSm
    ) {

        Map<String, MissingData> mapMissingData = new Map<String, MissingData>();
        for (SurveyFieldMappingController.ExistentSurveyMapping esm : listExistentSm) {

            List<String> listQM = new List<String>();
            for (SurveyFieldMappingController.QuestionMappingObject fieldObject : esm.listQuestionMapping) {

                // Obtain mapped fields.
                listQM.add(fieldObject.mappedFieldName);
            }

            // I must obtain the fields mapped to a fixed questions, such as surveyor
            // etc (are not question mappings, but behave as question mappings).
            listQM.add(esm.surveyMap.Surveyor);
            listQM.add(esm.surveyMap.PPIScore);
            listQM.add(esm.surveyMap.Submission);
            listQM.add(esm.surveyMap.Survey);
            listQM.add(esm.surveyMap.SurveyVersion);

            // Obtain name of the object and create MissingData object.
            String objectName = esm.surveyMap.objectMapped;
            MissingData currentMissingData = obtainMissingData(objectName, listQM);

            if (currentMissingData != null) {

                // Has a missing object or field, so we add it to the map to return.
                mapMissingData.put(esm.surveyMap.Id, currentMissingData);
            }
        }
        return mapMissingData;
    }

    /**
     * Method that receives a List of JobTemplateDo.ObjectHierarchy, and call obtainMissingData method
     * in order to return a map with the form: Map<ObjectHierarchy.Id, MissingData> of the Hierarchy objects
     * with any missing attribute.
     *
     * @param listHierarchies - List of JobTemplateDo.ObjectHierarchy.
     *
     * @return - Map with the form: Map<ObjectHierarchy.Id, MissingData> with each object with a missing value.
     */
    public static Map<String, MissingData> obtainMissingDataInBulkFromHierarchy(List<JobTemplateDo.ObjectHierarchy> listHierarchies) {
        Map<String, MissingData> mapMissingData = new Map<String, MissingData>();
        for (JobTemplateDo.ObjectHierarchy hierarchy : listHierarchies) {

            // Obtain fields.
            List<String> listOfFields = hierarchy.obtainFields();

            // Obtain name of the object and create MissingData object.
            String objectName = hierarchy.objectName;
            MissingData currentMissingData = obtainMissingData(objectName, listOfFields);

            if (currentMissingData != null) {

                // Has a missing object or field...
                // ...first we check if is a hierarchy with a relation removed (if is we must to customize the message)...
                currentMissingData.hasDeletedRelation = (currentMissingData.fieldsDeleted != null)
                    ? hierarchy.hasDeletedRelation(currentMissingData.fieldsDeleted)
                    : false;

                // ...then we add it to the map to return.
                mapMissingData.put(hierarchy.objectId, currentMissingData);
            }
        }
        return mapMissingData;
    }

    /**
     * Given a Map<String, MissingData> with missing data, creates a text error to display to the user.
     * The error is added to the page
     *
     * @param mapMissingData    - Map of missing data.
     * @param prefixLabel       - Name of the object that has an object or field deleted.
     * @param fromSurveyMapping - Indicates if it was called form the survey mapping page.
     */
    public static void createMessageForMissingData(Map<String, MissingData> mapMissingData, String prefixLabel) {

        ApexPages.getMessages().clear();
        String messageString = prefixLabel + '<br /><br />';
        for (MissingData mData : mapMissingData.values()) {

            // Add the object
            messageString += '&nbsp;&nbsp;&nbsp;&nbsp;' + mData.objectDeleted;

            // Add the fields if exists
            if(mData.fieldsDeleted != null && mData.fieldsDeleted.size() > 0) {
                messageString += ': ' + String.join(mData.fieldsDeleted, ', ') + '<br />';
            }
        }

        // Remove the trailing br tag
        messageString = messageString.replaceFirst('<br />$', '');
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, messageString));
    }

    /**
     * Method that recieve a survey id and returns a list of surveys to close, if it has some missing mapped object or field
     *
     * @param surveyId - The Survey__c.Id being checked
     *
     * @return - True if there is some missing mapped object, otherwise false
     */
    public static Set<Id> mappingsWithMissingObjectOrField(Id surveyId) {

        Set<Id> surveyIds = new Set<Id>();
        surveyIds.add(surveyId);
        return mappingsWithMissingObjectOrField(surveyIds);
    }

    /**
     * Method that recieve a list of survey ids and returns a list of surveys to close, if it has some missing mapped object or field
     *
     * @param surveyIds - List of Survey Ids
     * @return - True if there is some missing mapped object, otherwise false
     */
    public static Set<Id> mappingsWithMissingObjectOrField(Set<Id> surveyIds) {
        Set<Id> idsOfSm  = new Set<Id>();
        Set<Id> surveysToClose = new Set<Id>();
        idOfSurveyMappingsToRemove = new Set<Id>();
        List<SurveyMapping__c> surveyMapps = new List<SurveyMapping__c>();

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Survey__c.Status__c
            }
        );
        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(QuestionMapping__c.SObjectType);
        questionMappingCreator.checkObjectAccessible();
        questionMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                QuestionMapping__c.FieldApiName__c,
                QuestionMapping__c.SurveyMapping__c
            }
        );
        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyMapping__c.ObjectApiName__c,
                SurveyMapping__c.Survey__c
            }
        );

        if (!surveyIds.isEmpty()) {
            surveyMapps = [
                SELECT
                    Id,
                    ObjectApiName__c,
                    Survey__c,
                    Survey__r.Status__c,
                    (SELECT Id, FieldApiName__c FROM QuestionMappings__r)
                FROM
                    SurveyMapping__c
                WHERE
                    Survey__c IN :surveyIds
            ];
        }

        if (!surveyMapps.isEmpty()) {
            for (SurveyMapping__c sm : surveyMapps) {
                List<String> listMappedFields = new List<String>();
                idsOfSm.add(sm.Id);

                for (QuestionMapping__c qm : sm.QuestionMappings__r) {
                    listMappedFields.add(qm.FieldApiName__c);
                }

                MissingData currentMissingData =
                    obtainMissingData(sm.ObjectApiName__c, listMappedFields);

                if (currentMissingData != null) {
                    idOfSurveyMappingsToRemove.add(sm.Id);
                    surveysToClose.add(sm.Survey__c);
                }
            }
        }

        // Check relations
        surveysToClose.addAll(relationWithNoMissingSM(idsOfSm));
        return surveysToClose;
    }

    /**
     * Method that receives a set of survey ids and returns a list of surveys to close, if it has some missing relation
     *
     * @param surveyId - Id of the survey being looked at
     *
     * @return - True if there is some missing relation, otherwise false
     */
    public static Set<Id> relationWithNoMissingSM(Set<Id> idsOfSm) {

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Survey__c.Status__c
            }
        );
        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyMapping__c.ObjectApiName__c,
                SurveyMapping__c.Survey__c,
                SurveyMapping__c.Repeat__c
            }
        );
        GenericObjectCreator objectRelationshipMappingCreator =
            new GenericObjectCreator(ObjectRelationshipMapping__c.SObjectType);
        objectRelationshipMappingCreator.checkObjectAccessible();
        objectRelationshipMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                ObjectRelationshipMapping__c.ChildSurveyMapping__c,
                ObjectRelationshipMapping__c.FieldApiName__c,
                ObjectRelationshipMapping__c.ParentSurveyMapping__c
            }
        );

        Set<Id> surveysToClose = new Set<Id>();
        if (!idsOfSm.isEmpty()) {
            List<ObjectRelationshipMapping__c> objRelated = [
                SELECT
                    Id,
                    ChildSurveyMapping__c,
                    FieldApiName__c,
                    ParentSurveyMapping__c,
                    ParentSurveyMapping__r.Survey__r.Status__c,
                    ParentSurveyMapping__r.Survey__c,
                    ParentSurveyMapping__r.ObjectApiName__c,
                    ChildSurveyMapping__r.Repeat__c,
                    ChildSurveyMapping__r.ObjectApiName__c
                FROM
                    ObjectRelationshipMapping__c
                WHERE
                    (
                        ChildSurveyMapping__c IN  :idsOfSm
                        OR ParentSurveyMapping__c IN :idsOfSm
                    )
                    AND (
                        ChildSurveyMapping__c NOT IN :idOfSurveyMappingsToRemove
                        AND ParentSurveyMapping__c NOT IN :idOfSurveyMappingsToRemove
                    )
            ];

            if (!objRelated.isEmpty()) {
                Map<Id, Id> mapRelIdSurveyId = new Map<Id, Id>();
                for (ObjectRelationshipMapping__c orm : objRelated) {

                    // Obtain field name.
                    List<String> listFields = new List<String>();
                    listFields.add(orm.FieldApiName__c);

                    // Obtain name of the object and create MissingData object.
                    String objectName = orm.ChildSurveyMapping__r.ObjectApiName__c;
                    MissingData currentMissingData = obtainMissingData(objectName, listFields);
                    if (currentMissingData != null) {

                        // Has a missing object or field, so we add it to the map to return.
                        mapRelIdSurveyId.put(orm.Id, orm.ParentSurveyMapping__r.Survey__c);
                    }
                }
                surveysToClose.addAll(mapRelIdSurveyId.values());
            }
        }
        return surveysToClose;
    }

    /**
     * Check the jobs hierarchy and return the ones with deleted fields or objects
     *
     * @param jobs - A set of ids of the jobs to check
     *
     * @return - A set with the ids of the jobs with a broken hierarchy
     */
    public static Set<Id> findJobsWithBrokenHierarchy(List<JobTemplate__c> jobs) {

        Set<Id> brokenJobs = new Set<Id>();
        for (JobTemplate__c job : jobs) {

            // Check only the published jobs
            if (job.Status__c == JobTemplateDo.STATUS_PUBLISHED && job.Hierarchy__c != null) {

                // Get the missing data and if there is some, put the job in the set
                Map<String, MissingData> mData = obtainMissingDataInBulkFromHierarchy(
                    (List<JobTemplateDO.ObjectHierarchy>)JSON.deserialize(
                        job.Hierarchy__c,
                        List<JobTemplateDO.ObjectHierarchy>.class
                    )
                );
                if (!mData.isEmpty()) {
                    brokenJobs.add(job.Id);
                }
            }
         }

         return brokenJobs;
    }

    /**
     * Inner class that represents a generic object with a removed object or field.
     */
    public class MissingData{

        // Type of missing data (object or field).
        public String missingDataType { get; set; }

        // Api Name of the removed object (or the object that has a missing field if is of type GENERAL_DELETED_OBJECT)
        public String objectDeleted { get; set; }

        // Api Name of the missing field or fields.
        public List<String> fieldsDeleted { get; set; }

        // True if a deleted field was a relation (mostly used in hierarchies).
        public Boolean hasDeletedRelation { get; set; }

        /**
         * Class constructor
         *
         * @param missingType - Type of data removed.
         * @param objectName  - Api name of the object removed (or the object that has a missing field).
         * @param listFields  - Api Name of the missing field or fields.
         */
        public MissingData(String missingType, String objectName, List<String> listFields) {
            SFDCEncoder encoder = new SFDCEncoder();
            this.missingDataType = encoder.SFDC_JSENCODE(missingType);
            this.objectDeleted = encoder.SFDC_JSENCODE(objectName);
            this.fieldsDeleted = listFields;
            this.hasDeletedRelation = false;
        }

        /**
         * Method in charge of create an error message for {this}.
         *
         * @param orgObjectName - String with the type of object related, i.e: "Survey Mapping", "Object Relation", etc.
         *
         * @return String displaying what object or field/s are removed.
         */
        public String toString(String orgObjectName){

            String missingDataString = '';
            if (this.missingDataType == OBJECT_DELETED) {
                missingDataString = String.format(
                    System.label.GENERAL_DELETED_OBJECT, new List<String>{orgObjectName, this.objectDeleted}
                );
            } else if (this.missingDataType == FIELD_DELETED) {
                String removedFieldsString = '';
                for (Integer i = 0; i < this.fieldsDeleted.size(); i++) {
                    String strAfterField = (i < this.fieldsDeleted.size() - 1) ? '", ' : '" ';
                    removedFieldsString += '"' + this.fieldsDeleted[i]  + strAfterField;
                }
                missingDataString = String.format(
                    System.label.GENERAL_DELETED_FIELD, new List<String>{
                        orgObjectName, this.objectDeleted, removedFieldsString
                    }
                );
            }
            return missingDataString;
        }

        /**
         * Method in charge of create an error message for {this} (only deleted data is included).
         *
         * @return - String displaying what object or field/s are removed (without any formatting).
         */
        public String rawMessageForDeletedData() {

            String missingDataString = '';
            if (this.missingDataType == OBJECT_DELETED) {
                missingDataString = '"' + this.objectDeleted + '" ';
            } else if (this.missingDataType == FIELD_DELETED) {
                for (Integer i = 0; i < this.fieldsDeleted.size(); i++) {
                    missingDataString += '"' + this.fieldsDeleted[i]  + '" ' ;
                }
            }
            return missingDataString;
        }
    }
}