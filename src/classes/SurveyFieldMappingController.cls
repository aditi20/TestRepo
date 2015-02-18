/**
 * Controller class for maintaining all functionality around field mapping page
 *
 * TODO:
 *    - Refactor code based on SOC architechture
 *    - Use appropriate selector and domain layers and update all queries and DML operations
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class SurveyFieldMappingController {

    // Current survey.
    public Survey__c survey{get; set;}
    public List<QuestionLine> Questions{get;set;}
    public String questionJson {get;set;}
    public String headerColumnsJson {get;set;}
    public String questionsWithColumnsJson {get;set;}
    public String selectedObjectFieldsJson {get;set;}
    public String mappedSurveys {get;set;}
    public String retrievedObjectRelations {get;set;}
    public Boolean isSurveyPPI {get;set;}
    public Boolean readOnly {get;set;}
    public SFDCEncoder encoder;
    public Set<Id> idOfSurveyMappingsToRemove;  // Set of id of survey mappings that have either a removed field or object.
    public Set<Id> idOfRelationsToRemove;       // Set of id of relations with the field removed.
    Transient Savepoint sp;

    //------------------------------------CONSTANTS----------------------------------------

    private static final String NOT_MAPPED = '-1';
    private static final String VALUE_INTEGER   = 'Integer';
    private static final String VALUE_DOUBLE    = 'Double';

    //------------------------------------END CONSTANTS------------------------------------

    public boolean sameOrg{get;set;} // To render the close button just when is in the same org
    public boolean hasApexMessage{get{
                                return (ApexPages.hasMessages(ApexPages.Severity.ERROR) || ApexPages.hasMessages(ApexPages.Severity.FATAL));
                            }set;}
     public Boolean isPublished {
                                get{
                                    return (survey.Status__c == SurveyDO.STATUS_PUBLISHED);
                                }set;}

    /*
     *    Class constructor
     */
    public SurveyFieldMappingController (ApexPages.StandardController stdController) {
        encoder = new SFDCEncoder();
        String comingFromBuilder = Apexpages.currentPage().getParameters().get('b');
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Survey__c.Name,
            Survey__c.Alias__c,
            Survey__c.Status__c,
            Survey__c.isPPI__c,
            Survey__c.IsTemplate__c
        });
        this.survey = (Survey__c)stdController.getRecord();
        if (this.survey.Id != null) {
            this.survey = [
                SELECT
                    Id,
                    Name,
                    Alias__c,
                    Status__c,
                    isPPI__c,
                    LastModifiedDate,
                    IsTemplate__c
                FROM
                    Survey__c
                WHERE
                    Id = :this.survey.Id
                LIMIT 1
            ];
            this.isSurveyPPI = this.survey.isPPI__c;
        } else {
             throw new C.InvalidUrlException(System.Label.BUILDER_ERR_INVALIDURL);
        }

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Name,
                Question__c.Type__c,
                Question__c.Caption__c,
                Question__c.Parent__c,
                Question__c.Hint__c,
                Question__c.Position__c,
                Question__c.CurrentTime__c,
                Question__c.Required__c,
                Question__c.RepeatSourceValue__c
            }
        );

        // Obtain all questions and their options, for this survey.
        Question__c[] allSections = [SELECT Id,
                                            Name,
                                            Type__c,
                                            Parent__c,
                                            Caption__c,
                                            Hint__c,
                                            Position__c,
                                            Required__c,
                                            CurrentTime__c,
                                            RepeatSourceValue__c,
                                            RepeatSourceValue__r.Name
                                     FROM Question__c
                                     WHERE Survey__c = :this.survey.Id
                                         AND (Type__c =:QuestionDO.TYPE_SECTION
                                         OR Type__c = :QuestionDO.TYPE_REPEAT)
                                     ORDER BY Position__c asc];

        Question__c[] allQuestions = [SELECT Id,
                                             Name,
                                             Type__c,
                                             Parent__c,
                                             Parent__r.Parent__c,
                                             Caption__c,
                                             Hint__c,
                                             Position__c,
                                             Required__c,
                                             CurrentTime__c,
                                             RepeatSourceValue__c,
                                             RepeatSourceValue__r.Name
                                      FROM Question__c
                                      WHERE Survey__c = :this.survey.Id
                                          AND Type__c !=:QuestionDO.TYPE_SECTION
                                          AND Type__c != :QuestionDO.TYPE_REPEAT
                                      ORDER BY Position__c asc];

        orderQuestionbySection(allSections,allQuestions);
        //Loads the existents Object Columns(SurveyMapping__c)
        loadObjectSelectList();
        loadMappedObjects();
        // Set to true when is the same org to show the preview.
        sameOrg = Site.getName() == null;
        // Set survey status
        String SurveyStatus = this.survey.Status__c;
        List<ObjectRelationshipMapping__c> listPreviousRelations = obtainObjectRelations();
        retrievedObjectRelations = JSON.serialize(convertObjectRelations(listPreviousRelations));

        // Set read-only mode when...
        readOnly = (comingFromBuilder != '1' && comingFromBuilder != null)  // the page is not reached from the Survey Builder, or
                || SurveyStatus != SurveyDO.STATUS_DRAFT                    // the survey is not in Draft status, or
                || !Survey__c.sObjectType.getDescribe().isUpdateable();     // the user does not have permissions to update Surveys.

        //if the survey is published add an error
        if (survey.Status__c == SurveyDO.STATUS_PUBLISHED && !readOnly){
            ApexPages.message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, system.Label.BUILDER_ERR_SURVEYALREADYPUBLISHED);
            ApexPages.addMessage(myMsg);
        }
    }

    /**
    *   Method that convert a list of ObjectRelationshipMapping__c into a list of ObjectRelation
    *   @param  List of ObjectRelationshipMapping__c
    *   @return List of ObjectRelation.
    */
    private List<ObjectRelation> convertObjectRelations(List<ObjectRelationshipMapping__c> listObjectRelations){
        List<ObjectRelation> listParentObjects = new List<ObjectRelation>();
        for(ObjectRelationshipMapping__c o : listObjectRelations){
            ObjectRelation obj = new ObjectRelation(o);
            if(obj.parentSM != null && obj.parentSM != '' && obj.childSM != null  && obj.childSM != ''
                                  && obj.fieldName != null && obj.fieldName != ''){
                listParentObjects.add(obj);
            }
        }
        return listParentObjects;
    }

    /**
    * Method that retrieves all ObjectRelationshipMapping__c related to SurveyMappings that are related
    * to the current survey (and are not related to a survey mapping that has a removed object or field).
    * 
    * @return - List of ObjectRelationshipMapping__c.
    */
    private List<ObjectRelationshipMapping__c> obtainObjectRelations() {

        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                SurveyMapping__c.ObjectApiName__c
            }
        );

        List<SurveyMapping__c> smRelated = [
            SELECT
                Id
            FROM
                SurveyMapping__c
            WHERE
                Survey__c = :this.survey.Id
        ];

        Set<Id> idsOfSm = new Set<Id>();
        for (SurveyMapping__c sm : smRelated) {
            idsOfSm.add(sm.Id);
        }

        GenericObjectCreator objectRelationshipMappingCreator =
            new GenericObjectCreator(ObjectRelationshipMapping__c.SObjectType);
        objectRelationshipMappingCreator.checkObjectAccessible();
        objectRelationshipMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                ObjectRelationshipMapping__c.FieldApiName__c,
                ObjectRelationshipMapping__c.ParentSurveyMapping__c,
                ObjectRelationshipMapping__c.ChildSurveyMapping__c
            }
        );

        List<ObjectRelationshipMapping__c> listOfRetrievedObjectRelations = [
            SELECT
                Id,
                ChildSurveyMapping__c,
                FieldApiName__c,
                ParentSurveyMapping__c,
                ChildSurveyMapping__r.ObjectApiName__c
             FROM
                ObjectRelationshipMapping__c
             WHERE (
                    ChildSurveyMapping__c IN :idsOfSm
                    OR ParentSurveyMapping__c IN :idsOfSm
                )
                AND (
                    ChildSurveyMapping__c NOT IN :idOfSurveyMappingsToRemove
                    AND ParentSurveyMapping__c NOT IN :idOfSurveyMappingsToRemove
                )
        ];

        // Retrieve objects with object or field removed.
        Map<String, RemovedDataValidation.MissingData> mapDataMissing =
            RemovedDataValidation.obtainMissingDataInBulkFromRelations(
                listOfRetrievedObjectRelations
            );

        if (!mapDataMissing.isEmpty()) {

            // There is some field removed, so....
            // ...create message to display to the user....
            RemovedDataValidation.createMessageForMissingData(
                mapDataMissing, System.Label.SURVEY_MAPPING_DELETEDOBJECTSORFIELDS
            );

            // ...and remove the relations with missing field from the list to be passed to the page.
            listOfRetrievedObjectRelations =
                avoidPassingRelationsWithRemovedData(listOfRetrievedObjectRelations, mapDataMissing);
        }
        return listOfRetrievedObjectRelations;
    }

    /**
     * Given an object name, returns a list of the fields of the object.
     *
     * @param objectName - Name of the object
     *
     * @return - List of fields related to the object
     */
    public List<SField> obtainFieldsFromObject(String objectName) {

        List<SField> arrayFieldData = new List<SField>();
        if (objectName != NOT_MAPPED) {
            if (DescribeHandler.objectExists(objectName)) {

                // Is not null, it means that the object has not been deleted
                // if it was deleted, will be handled later
                SFDCEncoder encode = new SFDCEncoder();
                for (String fieldName : DescribeHandler.getFieldMap(objectName).keySet()) {
                    Schema.DescribeFieldResult fieldResult = DescribeHandler.getFieldDescribe(objectName, fieldName);
                    if (isValidField(fieldResult)) {
                        SField field = new SField();
                        field.type = encode.SFDC_JSENCODE(String.valueOf(fieldResult.getType()));
                        field.name = encode.SFDC_JSENCODE(String.valueOf(fieldResult.getName()));
                        field.label = encode.SFDC_JSENCODE(String.valueOf(fieldResult.getLabel()));
                        if (!String.isEmpty(C.getNamespace())) {
                            if (
                                C.whiteListedObjects.contains(objectName.toLowerCase()) &&
                                field.name.contains(C.getNamespace())
                            ) {
                                continue;
                            }
                        }
                        field.required = !fieldResult.isNillable();
                        field.externalId = fieldResult.isExternalId();
                        field.unique = fieldResult.isUnique();
                        field.nameField = fieldResult.isNameField();
                        field.isAutoNumber = fieldResult.isAutoNumber();
                        if (field.type == VALUE_INTEGER) {
                            field.length = fieldResult.getDigits();
                        } else if (field.type == VALUE_DOUBLE) {
                            field.length = fieldResult.getPrecision() - fieldResult.getScale();
                        }
                        if (fieldResult.getReferenceTo() != null &&  fieldResult.getReferenceTo().size() != 0) {
                            field.relatedTo = new List<RelationField>();
                            for (Schema.SObjectType relatedChild : fieldResult.getReferenceTo()) {
                                RelationField dummyRelationField = new RelationField();
                                dummyRelationField.name = encode.SFDC_JSENCODE(relatedChild.getDescribe().getName());
                                dummyRelationField.label = encode.SFDC_JSENCODE(relatedChild.getDescribe().getLabel());
                                dummyRelationField.relationType =
                                    (fieldResult.isCascadeDelete()) ?
                                    encode.SFDC_JSENCODE(system.Label.MASTER_DETAIL_LABEL) :
                                    encode.SFDC_JSENCODE(system.Label.LOOKUP_LABEL);
                                field.relatedTo.add(dummyRelationField);
                            }
                        }
                        arrayFieldData.add(field);
                    }
                }
            }
        }
        return arrayFieldData;
    }

    /**
     * Check that a field is able to be mapped to
     *
     * @param fieldDescribeResult - The fieldDescribeResult for the field being tested
     *
     * @return - True if able to be mapped to
     */
    private static Boolean isValidField(Schema.DescribeFieldResult fieldDescribeResult) {

        return (
            (
                (
                    fieldDescribeResult.isUpdateable() ||
                    fieldDescribeResult.getType().name() == Schema.DisplayType.Reference.Name()
                ) &&
                fieldDescribeResult.isCreateable() &&
                fieldDescribeResult.getName() != 'OwnerId' &&
                !fieldDescribeResult.getName().contains('Latitude__s') &&
                !fieldDescribeResult.getName().contains('Longitude__s')
            ) ||
            fieldDescribeResult.isAutoNumber() ||
            fieldDescribeResult.getType().name() == 'LOCATION'
        );
    }

    /**
     * Given an object name, returns a list of the required fields of the object.
     *
     * @param objectName - Name of the object
     *
     * @return - List of required fields related to the object.
     */
    private Set<String> obtainRequiredFieldsFromObject(String objectName) {

        Set<String> setFieldData = new Set<String>();
        if (objectName != NOT_MAPPED){
            if (DescribeHandler.objectExists(objectName)) {
                for (String fieldName : DescribeHandler.getFieldMap(objectName).keySet()) {
                    Schema.DescribeFieldResult fieldResult = DescribeHandler.getFieldDescribe(objectName, fieldName);
                    if (isValidField(fieldResult)) {
                        String fieldType = String.valueOf(fieldResult.getType());

                        // This is because we are not consider DATETIME, Id, Boolean, and Reference fields
                        if (
                                !fieldResult.isNillable() &&
                                (
                                    fieldType != 'DATETIME' &&
                                    fieldType != 'ID' &&
                                    fieldType != 'BOOLEAN' &&
                                    fieldType != 'REFERENCE'
                                ) &&
                                !fieldResult.isAutoNumber()
                        ) {
                            setFieldData.add(String.valueOf(fieldResult.getName()));
                        }
                    }
                }
            }
        }
        return setFieldData;
    }

    /**
    *    Receives the name of an object, and sets an array of SField objects for each field of the given object.
    */
    public void getDataFromObject(){
        String nameObject = Apexpages.currentPage().getParameters().get('nameObject');
        List<SField> arrayFieldData = obtainFieldsFromObject(nameObject);
        selectedObjectFieldsJson = JSON.serialize(arrayFieldData);
    }

    /*
    *    Collect data, and insert it to the org.
    */
    public void saveData() {

        // Obtain the map of permissions for needed objects (from PrivilegeHelper).
        String surveyMappingName   = Schema.sObjectType.SurveyMapping__c.getName();
        String questionMappingName = Schema.sObjectType.QuestionMapping__c.getName();
        String questionName        = Schema.sObjectType.Question__c.getName();
        String surveyName          = Schema.sObjectType.Survey__c.getName();
        String objectRelationName  = Schema.sObjectType.ObjectRelationshipMapping__c.getName();

        Set<String> objectList     = new Set<String>{surveyMappingName, questionMappingName, questionName, surveyName, objectRelationName};
        // Obtain profile permissions for the current user.
        Map<String, DescribeSObjectResult> mapPermissions = PrivilegesHelper.obtainObjectPermissions(objectList);

        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(
                DescribeHandler.getGlobalDescribe().get(surveyMappingName)
            );
        surveyMappingCreator.checkObjectCreateable();
        surveyMappingCreator.checkObjectUpdateable();
        surveyMappingCreator.checkObjectDeletable();

        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(
                DescribeHandler.getGlobalDescribe().get(questionMappingName)
            );
        questionMappingCreator.checkObjectCreateable();
        questionMappingCreator.checkObjectDeletable();

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(
                DescribeHandler.getGlobalDescribe().get(questionName)
            );
        questionCreator.checkObjectUpdateable();

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(
                DescribeHandler.getGlobalDescribe().get(surveyName)
            );
        surveyCreator.checkObjectUpdateable();

        GenericObjectCreator objectRelationshipMappingCreator =
            new GenericObjectCreator(
                DescribeHandler.getGlobalDescribe().get(objectRelationName)
            );
        objectRelationshipMappingCreator.checkObjectCreateable();
        objectRelationshipMappingCreator.checkObjectDeletable();

        // If user has not one of the permissions from above we don't allow changing anything in the page (could lead to inconsistencies).
        String jsonDataToSave = Apexpages.currentPage().getParameters().get('jsonData');
        List<SurveyMappingObject> deserializedSurveyList =
            (List<SurveyMappingObject>)JSON.deserialize(
                jsonDataToSave,
                List<SurveyMappingObject>.class
            );
        insertSurveyAndQuestionMappings(deserializedSurveyList);
    }

    /**
    *   Method in charge of delegate responsabilities to the correct method in order to save, update or remove survey mappings,
    *   and question mappings.
    *   @param  List of SurveyMappingObject (as created in client side).
    */
    private void insertSurveyAndQuestionMappings(List<SurveyMappingObject> surveyMappedList){
        List<SurveyMapping__c> listOfNewSurveyMappings      = new List<SurveyMapping__c>();
        List<SurveyMapping__c> listOfSavedSurveyMappings    = new List<SurveyMapping__c>();
        Set<Id> idOfSurveyPrevSaved                         = new Set<Id>();
        Set<Id> idSurveysToDelete                           = new Set<Id>();
        Set<Id> idSurveyChanged                             = new Set<Id>();
        List<ParentObject> listObjectRelation               = new List<ParentObject>();
        map<String, SurveyMapping__c> mapSelClassSM         = new map<String, SurveyMapping__c>();

        //Decide if it is new, already saved, or empty (and ready to delete) survey mapping.
        for(SurveyMappingObject sm : surveyMappedList){
            if(sm.objectMapped != NOT_MAPPED){
                SurveyMapping__c newSM = convertSurveyMappingToSFObject(sm);
                mapSelClassSM.put(sm.classSelected, newSM);
                listObjectRelation.add(sm.objectRelation);
                if(isSalesforceId(sm.classSelected)){
                    if(sm.oldMapping == true){
                        idSurveyChanged.add(sm.classSelected);
                    }
                    listOfSavedSurveyMappings.add(newSM);
                    idOfSurveyPrevSaved.add(sm.classSelected);
                }
                else{
                    listOfNewSurveyMappings.add(newSM);
                }
            }
            else{
                //The Mapping is not set, I have to check if it is a new mapping (which is not saved in the database) or if it is a
                //already saved mapped object (here I have to remove it)
                if(isSalesforceId(sm.classSelected)){
                    // Is a previously saved survey mapping with an empty object related, so we delete it.
                    idSurveysToDelete.add(sm.classSelected);
                }
            }
        }
        sp = Database.setSavepoint();                                   // Setpoint in case there is any problems saving.
        Boolean validRequiredFields      = false;                       // True if all required fields are mapped.
        Boolean anyAutonumberNotIdField  = false;                       // True if an autonumber is not set as id field, fasle otherwise.
        List<ObjectRelationshipMapping__c> previousObjectRelations = obtainObjectRelations(); // Obtain previous object relations.
        try{

            removeDataWithDeletedData();                                // Remove data with deleted fields or objects.
            removeRelationsWithDeletedField();                          // Remove relations with deleted field.
            deleteQuestionMappingsSMChanged(idSurveyChanged);           // Delete Question mappings of changed Surveys.
            deleteSurveyMappings(idSurveysToDelete);                    // Delete surveys mappings with no object mapped.
            updateSavedSurveys(idOfSurveyPrevSaved, mapSelClassSM);     // Updates existing survey mappings.
            insert listOfNewSurveyMappings;                             // Insert new survey mappings.
            insertObjectRelations(listObjectRelation, mapSelClassSM, previousObjectRelations);   // Insert object relations.
            insertQuestionsMapping(surveyMappedList, mapSelClassSM);    // Inserts question mappings.
            validRequiredFields = areAllRequiredFieldsMapped();         // Checks that all required fields are present in question mappings.
            anyAutonumberNotIdField = isAnyAutoNumberNotIdField();      // Checks if there is some autonumber field that is not set as id field.
        }
        catch(Exception e){
            rollBackDataBase(e);
        }
        if (!validRequiredFields) {
            // Should never enter here, this is already validated in client side.
            Exception ex = new AllRequiredFieldsException('Missing required field, error validating in client side.');
            rollBackDataBase(ex);
        }
        if (anyAutonumberNotIdField) {
            // Should never enter here, this is already validated in client side.
            Exception ex = new C.AutonumberNotIdFieldException(System.label.SURVEY_MAPPING_CANT_USE_AN_IF_NOT_IDFIELD_EXCEPTION);
            rollBackDataBase(ex);
        }
        loadMappedObjects();                                                                        // Send new objects to the page.
        List<ObjectRelationshipMapping__c> listPreviousRelations = obtainObjectRelations();         //Retrieves object relations
        retrievedObjectRelations = JSON.serialize(convertObjectRelations(listPreviousRelations));   // Set list of relations.
    }

    /**
    *   Method in charge of remove previous Object relations, and inserts the new ones.
    *   @param listObjectRelation List of object relations (retrieved from the front end).
    *   @param mapSelClassSM Map with the format : <SurveyMapping.Id, SurveyMapping>, the Id can be
    *    a string (the one we use to relate it in the page).
    *   @param previousObjectRelations List of previous object relations.
    */
    private void insertObjectRelations(
            List<ParentObject> listObjectRelation,
            Map<String, SurveyMapping__c> mapSelClassSM,
            List<ObjectRelationshipMapping__c> previousObjectRelations
    ) {
        List<ObjectRelationshipMapping__c> listObjectRelations =
            new List<ObjectRelationshipMapping__c>();
        GenericObjectCreator objectRelationshipMappingCreator =
            new GenericObjectCreator(ObjectRelationshipMapping__c.SObjectType);
        objectRelationshipMappingCreator.checkObjectDeletable();
        
        for (ParentObject po : listObjectRelation) {
        	//Iterate over the data collected in client side.
            if (po != null) {
            	// Set parent Id.
                Id parentId = (isSalesforceId(po.parent)) ? po.parent : mapSelClassSM.get(po.parent).Id;
                for (Relation childObj : po.relationObjects) {
                	// Iterate over the list of child relations.
                    Id childId = (isSalesforceId(childObj.child)) ? childObj.child : mapSelClassSM.get(childObj.child).Id;
                    for (String field : childObj.fieldsRelated) {
                        // Iterate over each field (a parent and a child can have multiple fields related),
                        // and create a ObjectRelationshipMapping__c object.
                        ObjectRelationshipMapping__c newObjectRelation =
                            (ObjectRelationshipMapping__c)
                                objectRelationshipMappingCreator.createNewRecord();
                        objectRelationshipMappingCreator.populateFields(
                            newObjectRelation,
                            new Map<Schema.SObjectField, Object>{
                                ObjectRelationshipMapping__c.ParentSurveyMapping__c => parentId,
                                ObjectRelationshipMapping__c.ChildSurveyMapping__c => childId,
                                ObjectRelationshipMapping__c.FieldApiName__c => field
                            }
                        );
                        listObjectRelations.add(newObjectRelation);
                    }
                }
            }
        }
        delete previousObjectRelations;                                // Remove previous object relations.
        insert listObjectRelations;                                    // Inserts object relations.
    }

    /**
     * Method that deletes question mappings that belong to changed Survey mapping.
     * @param Set of ids of changed survey mappings.
     */
    private void deleteQuestionMappingsSMChanged(Set<Id> idOfSurveysChanged) {
        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(QuestionMapping__c.SObjectType);
        questionMappingCreator.checkObjectAccessible();
        questionMappingCreator.checkObjectDeletable();

        if (idOfSurveysChanged.size() > 0) {
            List<QuestionMapping__c> questionsToDelete = [
                SELECT
                    Id
                FROM
                    QuestionMapping__c
                WHERE
                    SurveyMapping__c IN :idOfSurveysChanged
            ];
            delete questionsToDelete;
        }
    }

    /**
    * Here we update the surveys mappings already saved when the page was loaded.
    * @param idOfSurveyPrevSaved Set of Id's of surveys previously saved.
    * @param mapSelClassSM Map with the format : <SurveyMapping.Id, SurveyMapping>, the Id can be
    * a string (the one we use to relate it in the page).
    */
    private void updateSavedSurveys(
            Set<Id> idOfSurveyPrevSaved,
            Map<String, SurveyMapping__c> mapSelClassSM
    ) {
        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkObjectUpdateable();
        surveyMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyMapping__c.ObjectApiName__c,
                SurveyMapping__c.Survey__c,
                SurveyMapping__c.PPIScoreApiField__c,
                SurveyMapping__c.SubmissionApiField__c,
                SurveyMapping__c.SurveyApiField__c,
                SurveyMapping__c.SurveyVersionApiField__c,
                SurveyMapping__c.SurveyorApiField__c,
                SurveyMapping__c.MatchingField__c,
                SurveyMapping__c.Repeat__c,
                SurveyMapping__c.IsReference__c
            }
        );

        List<SurveyMapping__c> savedSurveyMapFromDB = [
            SELECT
                Id,
                Survey__c,
                ObjectApiName__c
            FROM
                SurveyMapping__c
            WHERE
                Id IN :idOfSurveyPrevSaved
        ];

        for (SurveyMapping__c savedSM : savedSurveyMapFromDB) {
            SurveyMapping__c newSM = mapSelClassSM.get(savedSM.Id);
            surveyMappingCreator.populateFields(
                savedSM,
                new Map<Schema.SObjectField, Object> {
                    SurveyMapping__c.PPIScoreApiField__c => newSM.PPIScoreApiField__c,
                    SurveyMapping__c.SubmissionApiField__c => newSM.SubmissionApiField__c,
                    SurveyMapping__c.SurveyApiField__c => newSM.SurveyApiField__c,
                    SurveyMapping__c.SurveyVersionApiField__c => newSM.SurveyVersionApiField__c,
                    SurveyMapping__c.SurveyorApiField__c => newSM.SurveyorApiField__c,
                    SurveyMapping__c.ObjectApiName__c => newSM.ObjectApiName__c,
                    SurveyMapping__c.MatchingField__c => newSM.MatchingField__c,
                    SurveyMapping__c.Repeat__c => newSM.Repeat__c,
                    SurveyMapping__c.IsReference__c => newSM.IsReference__c
                }
            );
        }
        update savedSurveyMapFromDB;
    }

    /**
    *    Here we remove the Question mappings of the modified questions, and recreate questions mapping for those questions.
    *    @param surveyMappedList List of SurveyMapping objects.
    *    @param mapSelClassSM Map with the format : <SurveyMapping.Id, SurveyMapping>, the Id can be
    *    a string (the one we use to relate it in the page).
    */
    private void insertQuestionsMapping(List<SurveyMappingObject> surveyMappedList, map<String, SurveyMapping__c> mapSelClassSM ){

        List<QuestionMapping__c> listOfNewQuestionsMapping  = new List<QuestionMapping__c>(); // Question mappings to save
        Set<Id> questionMappingsToDelete                    = new Set<Id>(); // Set of Id's of questions (in order to delete related question mappings).
        Set<Id> setIdSurveyMappings                         = new Set<Id>(); // Set of Id's of Survey mappings (in order to delete question mappings related).
        Set<Id> questionsToUpdate                           = new Set<Id>(); // Set of Id's of questions ready to be updated to required.
        Set<String> referenceSMWithRequiredRelation         = SurveyFieldMappingController.obtainListOfSurveyMappingsWithRequiredRelations(new Set<Id>{this.survey.Id}); // Obtain the list of Survey mappings Id related to required fields.

        for(SurveyMappingObject sm : surveyMappedList){
            List<QuestionMappingObject> questMap = sm.questionMapping;
            for(QuestionMappingObject qmo : questMap){
                Id idSurveyMapRelated = null;
                if(isSalesforceId(qmo.relatedHeaderCombo)){
                    idSurveyMapRelated = qmo.relatedHeaderCombo;
                }
                else{
                    if(mapSelClassSM.containsKey(qmo.relatedHeaderCombo)){
                       idSurveyMapRelated = mapSelClassSM.get(qmo.relatedHeaderCombo).Id;
                    }
                }

                if(idSurveyMapRelated != null){
                    setIdSurveyMappings.add(idSurveyMapRelated);
                    questionMappingsToDelete.add(qmo.questionId);

                    if(qmo.mappedFieldName != NOT_MAPPED){
                        QuestionMapping__c newQM = convertQuestionMappingToSFObject(qmo, idSurveyMapRelated);
                        listOfNewQuestionsMapping.add(newQM);

                        if ( (qmo.required && !sm.isReference) ||
                             (!sm.isReference && qmo.mappedFieldName.equals(sm.matchingField) && sm.matchingField != null) ||
                             (sm.isReference && referenceSMWithRequiredRelation.contains(idSurveyMapRelated)) ) {

                            // Question will be required because is mapped to a required field (and is not reference) or because
                            // parent of the relation is a reference object and at least one of the relations is required.
                            questionsToUpdate.add(qmo.questionId);
                        }
                    }
                }
            }
        }
        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(QuestionMapping__c.SObjectType);
        questionMappingCreator.checkObjectCreateable();
        questionMappingCreator.checkObjectUpdateable();
        questionMappingCreator.checkObjectDeletable();
        updateRequiredQuestions(questionsToUpdate);

        List<QuestionMapping__c> qmToDelete = [
            SELECT
                Id
            FROM
                QuestionMapping__c
            WHERE
                Question__c IN :questionMappingsToDelete
                AND SurveyMapping__C in :setIdSurveyMappings
        ];
        delete qmToDelete;

        // FLS checks are carried out in convertQuestionMappingToSFObject
        insert listOfNewQuestionsMapping;
    }

    /**
     * Method in charge of check if some autonumber field is not set as id field.
     *
     * @return - True if there is at least one autonumber field not set as id field, false otherwise.
     */
    public Boolean isAnyAutoNumberNotIdField() {
        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                SurveyMapping__c.MatchingField__c,
                SurveyMapping__c.Survey__c,
                SurveyMapping__c.ObjectApiName__c
            }
        );
        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(QuestionMapping__c.SObjectType);
        questionMappingCreator.checkObjectAccessible();
        questionMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                QuestionMapping__c.FieldApiName__c
            }
        );

        Boolean isAnyAutonumberNotIdField = false;
        List<SurveyMapping__c> surveyMappings = [
            SELECT
                Id,
                MatchingField__c,
                Survey__c,
                ObjectApiName__c,
                (
                    SELECT
                        Id,
                        FieldApiName__c
                    FROM
                        QuestionMappings__r
                  )
             FROM
                SurveyMapping__c
             WHERE
                Survey__c = :survey.Id
            ];

        for (SurveyMapping__c sm : surveyMappings) {

            // Iterate on survey mappings of this survey.
            List<String> fieldsMapped = new List<String>();
            for (QuestionMapping__c qm : sm.QuestionMappings__r) {

                // Collect fields mapped to the survey mapping.
                fieldsMapped.add(qm.FieldApiName__c);
            }
            Map<String, Schema.SObjectField> fieldDescribeForObject = DescribeHandler.getFieldMap(sm.ObjectApiName__c);

            if (
                C.isAutonumberNotIdField(
                    sm.ObjectApiName__c, sm.MatchingField__c, fieldsMapped, fieldDescribeForObject
                )
            ) {

                // This survey mapping has a question mapping related to an autonumber field that is not idfield.
                isAnyAutonumberNotIdField = true;
            }
        }
        return isAnyAutonumberNotIdField;
    }

    /**
    *    Preparing the recently saved survey to check if all required fields are mapped
    */
    private Boolean areAllRequiredFieldsMapped() {
        Map<Id, Set<String>> mapIdSMFieldsRequired = new Map<Id, Set<String>>();
        Map<Id, Set<String>> mapIdSMFieldsPresent  = new Map<Id, Set<String>>();
        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                SurveyMapping__c.ObjectApiName__c,
                SurveyMapping__c.Survey__c,
                SurveyMapping__c.IsReference__c,
                SurveyMapping__c.SurveyApiField__c,
                SurveyMapping__c.SurveyVersionApiField__c,
                SurveyMapping__c.SubmissionApiField__c,
                SurveyMapping__c.SurveyorApiField__c,
                SurveyMapping__c.PPIScoreApiField__c
            }
        );

        SurveyMapping__c[] allSurveyMappings = [
            SELECT
                Id,
                ObjectApiName__c,
                Survey__c,
                IsReference__c,
                SurveyApiField__c,
                SurveyVersionApiField__c,
                SubmissionApiField__c,
                SurveyorApiField__c,
                PPIScoreApiField__c
            FROM
                SurveyMapping__c
            WHERE
                Survey__c = :this.survey.Id
                ORDER BY CreatedDate
        ];

        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(QuestionMapping__c.SObjectType);
        questionMappingCreator.checkObjectAccessible();
        questionMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                QuestionMapping__c.FieldApiName__c,
                QuestionMapping__c.SurveyMapping__c
            }
        );

        QuestionMapping__c[] questionMappings = [
            SELECT
                Id,
                FieldApiName__c,
                SurveyMapping__c
            FROM
                QuestionMapping__c
            WHERE
                SurveyMapping__c in :allSurveyMappings
                ORDER BY SurveyMapping__c
        ];

        for(SurveyMapping__c sm : allSurveyMappings){

            if( sm.IsReference__c ){
                // Is reference so we don't have to validate required fields.
                mapIdSMFieldsRequired.put( sm.Id, new Set<String>() );
            }
            else{
                // Is not reference so we must validate required fields.
                // Set required fields data.
                Set<String> reqFieldsOfRelObject = obtainRequiredFieldsFromObject(sm.ObjectApiName__c);
                mapIdSMFieldsRequired.put(sm.Id, reqFieldsOfRelObject);
            }

            // Set Present fields (from the survey mapping object).
            Set<String> presentFieldsOfRelSurvey = new Set<String>();
            if(sm.PPIScoreApiField__c != null)        presentFieldsOfRelSurvey.add(sm.PPIScoreApiField__c);
            if(sm.SubmissionApiField__c != null)      presentFieldsOfRelSurvey.add(sm.SubmissionApiField__c);
            if(sm.SurveyApiField__c != null)          presentFieldsOfRelSurvey.add(sm.SurveyApiField__c);
            if(sm.SurveyVersionApiField__c != null)   presentFieldsOfRelSurvey.add(sm.SurveyVersionApiField__c);
            if(sm.SurveyorApiField__c != null)        presentFieldsOfRelSurvey.add(sm.SurveyorApiField__c);
            mapIdSMFieldsPresent.put(sm.Id, presentFieldsOfRelSurvey);
        }
        for(QuestionMapping__c qm : questionMappings){
            // Set Present fields (from the question mapping object).
            Set<String> presentFieldsOfRelSurvey = mapIdSMFieldsPresent.get(qm.SurveyMapping__c);
            presentFieldsOfRelSurvey.add(qm.FieldApiName__c);
            mapIdSMFieldsPresent.put(qm.SurveyMapping__c, presentFieldsOfRelSurvey);
        }
        return isMapFullyContained(mapIdSMFieldsRequired, mapIdSMFieldsPresent);
    }

    /**
    *    Given a map<SurveyMapping.Id, Set<RequiredFields>> and a map<SurveyMapping.Id, Set<PresentFields>>,
    *    returns true if all required fields are present for each SurveyMapping.Id.
    *    @param mapIdSMFieldsRequired Map that holds required fields for each survey mapping.
    *    @param mapIdSMFieldsPresent  Map that holds present fields (of related question mappings) for each survey mapping.
    *    @return True if all required fields are present for each SurveyMapping.Id, false otherwise.
    */
    private Boolean isMapFullyContained(Map<Id, Set<String>> mapIdSMFieldsRequired, Map<Id, Set<String>> mapIdSMFieldsPresent){
         for (Id smId : mapIdSMFieldsRequired.keySet()){
             Set<String> requiredFields = mapIdSMFieldsRequired.get(smId);
             Set<String> presentFields  = mapIdSMFieldsPresent.get(smId);
             for(String reqField : requiredFields ){
                 if (presentFields == null || !presentFields.contains(reqField)){
                     return false;
                 }
             }
         }
         return true;
    }

    /**
    *    Method that rollback the database to its last good savepoint, and display exception in the screen.
    *    Is not suposed to enter here, is an extra validation.
    */
    private void rollBackDataBase(Exception e){
        Database.rollback(sp);
        throw e;
    }

    /**
    *    Method that converts a QuestionMappingObject into a QuestionMapping__c.
    *    @param qmo QuestionMappingObject to convert.
    *    @param idSurveyMapRelated Id of the related SurveyMapping__c;
    *    @return QuestionMapping__c created.
    */
    private QuestionMapping__c convertQuestionMappingToSFObject(
            QuestionMappingObject questionMappingObject,
            Id idSurveyMapRelated
    ) {
        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(QuestionMapping__c.SObjectType);
        QuestionMapping__c newQuestionMapping =
            (QuestionMapping__c) questionMappingCreator.createNewRecord();
        questionMappingCreator.populateFields(
            newQuestionMapping,
            new Map<Schema.SObjectField, Object>{
                QuestionMapping__c.Question__c => questionMappingObject.questionId,
                QuestionMapping__c.FieldApiName__c => questionMappingObject.mappedFieldName,
                QuestionMapping__c.SurveyMapping__c => idSurveyMapRelated
            }
        );
        return newQuestionMapping;
    }

    /**
    *    Method that converts a SurveyMappingObject into a SurveyMapping__c.
    *    @param sm SurveyMappingObject to convert.
    *    @return SurveyMapping__c created.
    */
    private SurveyMapping__c convertSurveyMappingToSFObject(SurveyMappingObject sm) {
        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        SurveyMapping__c newSM =
            (SurveyMapping__c) surveyMappingCreator.createNewRecord();

        if (sm.PPIScore != null && sm.PPIScore != NOT_MAPPED) {
            surveyMappingCreator.populateField(
                newSM,
                SurveyMapping__c.PPIScoreApiField__c,
                sm.PPIScore
            );
        }
        if (sm.Submission != null && sm.Submission != NOT_MAPPED) {
            surveyMappingCreator.populateField(
                newSM,
                SurveyMapping__c.SubmissionApiField__c,
                sm.Submission
            );
        }
        if (sm.Survey != null && sm.Survey != NOT_MAPPED) {
            surveyMappingCreator.populateField(
                newSM,
                SurveyMapping__c.SurveyApiField__c,
                sm.Survey
            );
        }
        if (sm.SurveyVersion != null && sm.SurveyVersion != NOT_MAPPED) {
            surveyMappingCreator.populateField(
                newSM,
                SurveyMapping__c.SurveyVersionApiField__c,
                sm.SurveyVersion
            );
        }
        if (sm.Surveyor != null && sm.Surveyor != NOT_MAPPED) {
            surveyMappingCreator.populateField(
                newSM,
                SurveyMapping__c.SurveyorApiField__c,
                sm.Surveyor
            );
        }
        if (sm.matchingField != null && sm.matchingField != '-'
            && sm.matchingField != NOT_MAPPED
        ) {
            surveyMappingCreator.populateField(
                newSM,
                SurveyMapping__c.MatchingField__c,
                sm.matchingField
            );
        }

        surveyMappingCreator.populateFields(
            newSM,
            new Map<Schema.SObjectField, Object>{
                SurveyMapping__c.Survey__c => sm.surveyId,
                SurveyMapping__c.ObjectApiName__c => sm.objectMapped,
                SurveyMapping__c.Repeat__c =>
                    (sm.repeatIdSection != null && sm.repeatIdSection != '')
                        ? sm.repeatIdSection
                        : null
            }
        );

        if (sm.isReference == null) {
            surveyMappingCreator.populateField(
                newSM,
                SurveyMapping__c.IsReference__c,
                false
            );
        } else {
            surveyMappingCreator.populateField(
                newSM,
                SurveyMapping__c.IsReference__c,
                sm.isReference
            );
        }

        return newSM;
    }

    /**
     * Deletes survey mappings from the set of survey Id's.
     */
    private void deleteSurveyMappings(Set<Id> surveyMappingsToDelete) {
        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkObjectDeletable();

        List<SurveyMapping__c> listSM = [
            SELECT
                Id
            FROM
                SurveyMapping__c
            WHERE
                Id IN :surveyMappingsToDelete
        ];
        delete listSM;
    }

    /**
    *   Method that set questions required when related questions mapping has the object field required.
    *   @param  Set of ids of questions changed with required field;
    */
    private void updateRequiredQuestions(Set<Id> questionsToUpdate) {
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkObjectUpdateable();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Required__c,
                Question__c.Type__c,
                Question__c.Parent__c
            }
        );

        Map<Id, Question__c> questionsById = new Map<Id, Question__c> ([
            SELECT
                Id,
                Required__c,
                Type__c,
                Parent__c
            FROM
                Question__c
            WHERE
                Survey__c = :this.survey.Id
        ]);

        Set<Question__c> setQuestionsToUpdate = new Set<Question__c>();

        for (Id qId: questionsToUpdate) {
            Question__c question = questionsById.get(qId);
            setQuestionsToUpdate.add(question);

            // If the question is a cascading level, add all the levels and the cascading select as well
            if(question.Type__c.equals(QuestionDO.TYPE_CASCADING_LEVEL)){
                for (Question__c q:questionsById.values()){
                    if ((q.Parent__c == question.Parent__c || q.Id == question.Parent__c) && !setQuestionsToUpdate.contains(q)){
                        setQuestionsToUpdate.add(q);
                    }
                }
            }
        }

        // For insert a question it must be in a list
        List<Question__c> listQuestionsToUpdate = new List<Question__c>();
        listQuestionsToUpdate.addAll(setQuestionsToUpdate);
        for (Question__c question : listQuestionsToUpdate) {
            questionCreator.populateFields(
                question,
                new Map<Schema.SObjectField, Object>{
                    Question__c.Required__c => true
                }
            );
        }
        update listQuestionsToUpdate;
    }

    /**
    *    Method that validates a salesforce Id.
    *    @param wannabeId Id to be checked.
    *    @return True if it is a valid Salesforce Id.
    */
    private Boolean isSalesforceId(String wannabeId){
        Id MyTestID = null;
        Boolean isId = true;
        try {
            MyTestID = wannabeId;
        }
        catch(StringException ex) {
             isId = false;
        }
        return isId;
    }

    /**
    *    Method that retrieves SurveyMapping__c, and QuestionMapping__c objects related to
    *    current survey. Sets the value retrieved in the variable mappedSurveys.
    */
    private void loadMappedObjects() {
        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            SurveyMapping__c.Survey__c,
            SurveyMapping__c.ObjectApiName__c,
            SurveyMapping__c.MatchingField__c,
            SurveyMapping__c.SurveyApiField__c,
            SurveyMapping__c.SurveyVersionApiField__c,
            SurveyMapping__c.SubmissionApiField__c,
            SurveyMapping__c.SurveyorApiField__c,
            SurveyMapping__c.PPIScoreApiField__c,
            SurveyMapping__c.Repeat__c,
            SurveyMapping__c.IsReference__c
        });
        SurveyMapping__c[] allSurveyMappings = [
            SELECT
                Id,
                MatchingField__c,
                ObjectApiName__c,
                Survey__c,
                SurveyApiField__c,
                SurveyVersionApiField__c,
                SubmissionApiField__c,
                SurveyorApiField__c,
                PPIScoreApiField__c,
                Repeat__c,
                IsReference__c
            FROM
                SurveyMapping__c
            WHERE
                Survey__c=:this.survey.Id
                ORDER BY CreatedDate
        ];
        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(QuestionMapping__c.SObjectType);
        questionMappingCreator.checkObjectAccessible();
        questionMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            QuestionMapping__c.FieldApiName__c,
            QuestionMapping__c.SurveyMapping__c,
            QuestionMapping__c.Question__c
        });

        QuestionMapping__c[] questionMappings = [
            SELECT
                Id,
                FieldApiName__c,
                Question__c,
                SurveyMapping__c
            FROM
                QuestionMapping__c
            WHERE
                SurveyMapping__c in :allSurveyMappings
                ORDER BY SurveyMapping__c
        ];

        map<Id, List<QuestionMapping__c>> mapSurveyQuestionMapping = new map<Id, List<QuestionMapping__c>>();
        for(QuestionMapping__c qm: questionMappings){
            List<QuestionMapping__c> dummyQuestionList = (mapSurveyQuestionMapping.containsKey(qm.SurveyMapping__c)) ? mapSurveyQuestionMapping.get(qm.SurveyMapping__c) : new List<QuestionMapping__c>();
            dummyQuestionList.add(qm);
            mapSurveyQuestionMapping.put(qm.SurveyMapping__c, dummyQuestionList);
        }

        List<ExistentSurveyMapping> existentSurveyMappings = new List<ExistentSurveyMapping>();
        for(SurveyMapping__c sm:allSurveyMappings){
            List<SField> relatedFields = obtainFieldsFromObject(encoder.SFDC_JSENCODE(sm.ObjectApiName__c));
            List<QuestionMapping__c> listQuestionMapping = (mapSurveyQuestionMapping.containsKey(sm.Id))? mapSurveyQuestionMapping.get(sm.Id) : new List<QuestionMapping__c>();
            ExistentSurveyMapping dummySurveyMapping = new ExistentSurveyMapping(sm, relatedFields, listQuestionMapping);
            existentSurveyMappings.add(dummySurveyMapping);
        }

        // Retrieve objects with object or field removed.
        Map<String, RemovedDataValidation.MissingData> mapDataMissing = RemovedDataValidation.obtainMissingDataInBulkFromExistentSM(existentSurveyMappings);

        if (!mapDataMissing.isEmpty()) {
            // There is some field or object removed, so....
            // ...create message to display to the user....
            RemovedDataValidation.createMessageForMissingData(mapDataMissing, System.Label.SURVEY_MAPPING_DELETEDOBJECTSORFIELDS);
            // ...and remove the survey mapping with missing object or field from the list to be passed to the page.
            existentSurveyMappings = avoidPassingMappingsWithRemovedData(existentSurveyMappings, mapDataMissing);
        }
        mappedSurveys = JSON.serialize(existentSurveyMappings);
    }

    /*
     * Grouping the question in the section
     * @param lstSection the list of sections in the survey
     * @param lstQuestion the list of questions in the survey
     */
    private void orderQuestionbySection(Question__c[] lstSections,Question__c[] lstQuestions){
        Map<String,List<QuestionLine>> questionsbySectionId = new Map<String,List<QuestionLine>> ();
        Map<Id, CascadingSelectLine> cascadingLineById = new Map<Id, CascadingSelectLine>();
        List<QuestionLine> cascadingLevels = new List<QuestionLine>();

        //index the questions by Section
        for(Question__c quest:lstQuestions){
            List<QuestionLine> qLst= questionsbySectionId.get(quest.Parent__c);
            if(qLst == null) {
    questionsbySectionId.put(quest.Parent__c, new List<QuestionLine>());
}

if(quest.Type__c == QuestionDO.TYPE_CASCADING_LEVEL){
    cascadingLevels.add(new QuestionLine(quest));
}
else if(quest.Type__c == QuestionDO.TYPE_CASCADING_SELECT){
    CascadingSelectLine cascading = new CascadingSelectLine(quest);
    cascadingLineById.put(quest.Id, cascading);
    questionsbySectionId.get(quest.Parent__c).add(cascading);
}
else {
    questionsbySectionId.get(quest.Parent__c).add(new QuestionLine(quest));
}
        }



        // add the cascading levels to it's cascading select
        for (QuestionLine qsl: cascadingLevels){
            cascadingLineById.get(qsl.Question.Parent__c).addLevel(qsl);
        }

        //index all the sections and question in order.
        Questions = new List<QuestionLine>();
        for(Question__c section:lstSections){
            Questions.add(new QuestionLine(section));
            if(questionsbySectionId.get(section.id) != null)
                Questions.addAll(questionsbySectionId.get(section.id));
        }
        questionJson = JSON.serialize(Questions);
    }

    /**
     * Method that retrieves all objects from the org.
     */
    public void loadObjectSelectList() {
        encoder = new SFDCEncoder();
        Map<String, Schema.SObjectType> objectsMap = DescribeHandler.getGlobalDescribe();
        List<map<String, String>> objectsFromOrg = new List<map<String, String>>();
        
        for (String objectName : objectsMap.keySet()) {
            GenericObjectCreator creator =
                new GenericObjectCreator(objectName);
            if (creator.isObjectAccessible(false)) {
                Map<String, String> dummyObj = new Map<String, String>();

                // Add all object that do not have the manage package prefix
                // Can not select the mobile-surveys objects to map except PpiResult in case of PpiSurvey
                if (!C.hasNameSpacePrefix(objectsMap.get(objectName)) ||
                        (
                            C.whiteListedObjects.contains(objectName.toLowerCase()) &&
                            this.isSurveyPPI
                        )
                ) {
                    dummyObj.put('name', encoder.SFDC_JSENCODE(objectsMap.get(objectName).getDescribe().getName()));
                    dummyObj.put('label', encoder.SFDC_JSENCODE(objectsMap.get(objectName).getDescribe().getLabel()));
                    objectsFromOrg.add(dummyObj);
                }
            }
        }
        headerColumnsJson = JSON.serialize(objectsFromOrg);
    }

    /**
     * Method in charge to obtain the list of reference survey mappings Id's that are related
     * in a Master-Detail or required lookup relation as a parent (static because will be called also from triggers).
     *
     * @param surveyIdList - Set of Survey Id's.
     *
     * @return - Set<String> With the Id's of the survey mapping that meet the conditions.
     */
    public static Set<String> obtainListOfSurveyMappingsWithRequiredRelations(Set<Id> surveyIdList) {

        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                SurveyMapping__c.IsReference__c,
                SurveyMapping__c.Survey__c,
                SurveyMapping__c.ObjectApiName__c
            }
        );

        GenericObjectCreator objectRelationshipMappingCreator =
            new GenericObjectCreator(ObjectRelationshipMapping__c.SObjectType);
        objectRelationshipMappingCreator.checkObjectAccessible();
        objectRelationshipMappingCreator.checkObjectDeletable();
        objectRelationshipMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                ObjectRelationshipMapping__c.ParentSurveyMapping__c,
                ObjectRelationshipMapping__c.ChildSurveyMapping__c,
                ObjectRelationshipMapping__c.FieldApiName__c
            }
        );

        Set<String> smToReturn  = new Set<String>();
        List<ObjectRelationshipMapping__c>
            relationsOfReferenceSm = [
                SELECT
                    Id,
                    FieldApiName__c,
                    ParentSurveyMapping__r.IsReference__c,
                    ParentSurveyMapping__r.Survey__c,
                    ChildSurveyMapping__r.ObjectApiName__c
                FROM
                    ObjectRelationshipMapping__c
                WHERE
                    ParentSurveyMapping__r.Survey__c IN :surveyIdList
                    AND ParentSurveyMapping__r.IsReference__c = true
            ];

        for (ObjectRelationshipMapping__c relation : relationsOfReferenceSm) {

            // Iterate over the list of relations...
            String childObjectName = relation.ChildSurveyMapping__r.ObjectApiName__c;
            String fieldName = relation.FieldApiName__c;

            // Obtain field describe.
            Schema.DescribeFieldResult dfield = DescribeHandler.getFieldDescribe(childObjectName, fieldName);

            if (!dfield.isNillable()) {

                // Field is required so question mapped to survey mapping parent of the relation
                // should be required as well.
                smToReturn.add(relation.ParentSurveyMapping__c);
            }
        }
        return smToReturn;
    }

    /**
     *  Method in charge of remove the ExistentSurveyMappings of the list (that will be
     *  passed to the page) that have the object or a field removed, also add the Id of the survey mappings to be
     *  removed when the user clicks on "Save".
     *
     *  @param listExistentMappings List of ExistentSurveyMapping to check.
     *  @param mapDataMissing map with format Map<String, RemovedDataValidation.MissingData> with missing data.
     *  @return List of ExistentSurveyMapping that have no removed field or object.
     */

    public List<ExistentSurveyMapping> avoidPassingMappingsWithRemovedData(List<ExistentSurveyMapping> listExistentMappings, Map<String, RemovedDataValidation.MissingData> mapDataMissing){

        List<ExistentSurveyMapping> listModified = new List<ExistentSurveyMapping>();
        this.idOfSurveyMappingsToRemove          = new Set<Id>();

        for (ExistentSurveyMapping esm : listExistentMappings) {
            if (!mapDataMissing.containsKey(esm.surveyMap.Id)) {
                // Has not removed data, so it will be passed to the page.
                listModified.add(esm);
            }
            else{
                // Has removed data, so we save those mappings to remove them and its relationships when user clicks on "Save" button.
                idOfSurveyMappingsToRemove.add(esm.surveyMap.Id);
            }
        }
        return listModified;
    }

    /**
     *  Method in charge of remove the ExistentSurveyMappings of the list (that will be
     *  passed to the page) that have the object or a field removed, also add the Id of the relation to be removed
     *  when the user clicks on "Save".
     *
     *  @param listExistentMappings List of ExistentSurveyMapping to check.
     *  @param mapDataMissing map with format Map<String, RemovedDataValidation.MissingData> with missing data.
     *  @return List of ExistentSurveyMapping that have no removed field or object.
     */

    public List<ObjectRelationshipMapping__c> avoidPassingRelationsWithRemovedData(List<ObjectRelationshipMapping__c> listExistentMappings, Map<String, RemovedDataValidation.MissingData> mapDataMissing){

        List<ObjectRelationshipMapping__c> listModified = new List<ObjectRelationshipMapping__c>();
        this.idOfRelationsToRemove                      = new Set<Id>();

        for (ObjectRelationshipMapping__c orm : listExistentMappings) {
            if (!mapDataMissing.containsKey(orm.Id)) {
                // Has not removed data, so it will be passed to the page.
                listModified.add(orm);
            }
            else{
                // Has removed data, so we save those mappings to remove them and its relationships when user clicks on "Save" button.
                idOfRelationsToRemove.add(orm.Id);
            }
        }
        return listModified;
    }

    /**
     * Method in charge of remove those survey mappings and relations that have any field or object removed
     * (called when the user clicks on "Save" button although we save the ids to remove when entering the page).
     * We remove the relations here, in a future the relations should be removed in cascade when the mapping is removed.
     */
    public void removeDataWithDeletedData() {
        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkObjectDeletable();

        GenericObjectCreator objectRelationshipMappingCreator =
            new GenericObjectCreator(ObjectRelationshipMapping__c.SObjectType);
        objectRelationshipMappingCreator.checkObjectAccessible();
        objectRelationshipMappingCreator.checkObjectDeletable();
        objectRelationshipMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                ObjectRelationshipMapping__c.ParentSurveyMapping__c,
                ObjectRelationshipMapping__c.ChildSurveyMapping__c
            }
        );

        // Remove survey mappings and relations.
        List<SurveyMapping__c> listSMToRemove = [
            SELECT
                Id
            FROM
                SurveyMapping__c
            WHERE Id IN :idOfSurveyMappingsToRemove
        ];
        List<ObjectRelationshipMapping__c> relationsToRemove = [
            SELECT
                Id,
                ChildSurveyMapping__c,
                ParentSurveyMapping__c
            FROM
                ObjectRelationshipMapping__c
            WHERE
                ChildSurveyMapping__c  IN :idOfSurveyMappingsToRemove
                OR ParentSurveyMapping__c IN :idOfSurveyMappingsToRemove
        ];
        delete listSMToRemove;
        delete relationsToRemove;
    }

    /**
     * Method in charge of remove those relationshave have the field removed
     * (called when the user clicks on "Save" button although we save the ids to remove when entering the page).
     *
     */
    public void removeRelationsWithDeletedField() {
        GenericObjectCreator objectRelationshipMappingCreator =
            new GenericObjectCreator(ObjectRelationshipMapping__c.SObjectType);
        objectRelationshipMappingCreator.checkObjectAccessible();
        objectRelationshipMappingCreator.checkObjectDeletable();

        // Remove relations.
        List<ObjectRelationshipMapping__c> relationsToRemove = [
            SELECT
                Id
            FROM
                ObjectRelationshipMapping__c
            WHERE
                Id IN :idOfRelationsToRemove
        ];
        delete relationsToRemove;
    }

    /**
    *    Class that represents a question, with data in a easy way to be used in the client side.
    */
    public virtual with sharing class QuestionLine{
        public Question__c Question{get;set;}
        public Id Id {get{return Question.Id;}}
        public Id parentId {get{return Question.Parent__c;}}
        public Boolean Required {get{return Question.Required__c;}}
        public String Type {get{return Question.Type__c;}}
        public String Caption{get{return Question.Caption__c;}}

        public QuestionLine(Question__c q){
            Question = q;
        }
    }
    /**
    *   Class that represents a cascading select question
    **/
    public class CascadingSelectLine extends QuestionLine {
        public List<QuestionLine> CascadingLevels;

        public CascadingSelectLine(Question__c q){
            super(q);
            CascadingLevels = new List<QuestionLine>();
        }

        public void addLevel(QuestionLine level){
            CascadingLevels.add(level);

        }
    }

    /*
    *   Class that represents a survey mapping and related data.
    */
    public class ExistentSurveyMapping{
        public SFDCEncoder encoder;
        public SurveyMappingObject surveyMap {get;set;}    // Survey Mapping related data.
        public List<SField> relatedFields {get; set;}   // Fields of the object related to survey mapping
        public List<QuestionMappingObject> listQuestionMapping {get;set;}  // Question mappings related to the survey mapping object.

        /*
        *   Class constructor.
        */
        public ExistentSurveyMapping(SurveyMapping__c newSurveyMap, List<SField> newRelatedFields, List<QuestionMapping__c> questionMappingOfSurvey){
            encoder = new SFDCEncoder();
            this.surveyMap = new SurveyMappingObject(newSurveyMap);
            this.relatedFields = newRelatedFields;
            this.listQuestionMapping = getListQuestionMappingsFromQuestionAPI(questionMappingOfSurvey);
        }

        /**
        *   Given a List of QuestionMapping__c, returns a list of QuestionMappingObject.
        *   @param List of QuestionMapping__c.
        *   @return List of QuestionMappingObject.
        */
        public List<QuestionMappingObject> getListQuestionMappingsFromQuestionAPI(List<QuestionMapping__c> listApiQuestionMappings){
            List<QuestionMappingObject> listQuestionMappings = new List<QuestionMappingObject>();
            for(QuestionMapping__c qm : listApiQuestionMappings){
                listQuestionMappings.add(new QuestionMappingObject(qm));
            }
            return listQuestionMappings;
        }
    }

    /*
    *   Class that represent a survey mapping.
    */
    public class SurveyMappingObject{
        public String Id {get;set;}
        public String classSelected {get; set;}
        public String objectMapped {get; set;}
        public String surveyId {get; set;}
        public String Surveyor {get; set;}
        public String SurveyVersion {get; set;}
        public String PPIScore {get; set;}
        public String Survey {get; set;}
        public String Submission {get; set;}
        public String matchingField {get; set;}
        public Boolean oldMapping {get;set;}
        public String repeatIdSection {get;set;}
        public Boolean isReference {get;set;}
        public List<QuestionMappingObject> questionMapping {get; set;}

        public ParentObject objectRelation {get;set;}

        /**
        *   Constructor
        */
        public SurveyMappingObject()
        {}

        /**
        *   Constructor from a SurveyMapping__c.
        */
        public SurveyMappingObject(SurveyMapping__c newSM)
        {
            SFDCEncoder encode   = new SFDCEncoder();
            this.Id              = encode.SFDC_JSENCODE(newSM.Id);
            this.PPIScore        = encode.SFDC_JSENCODE(newSM.PPIScoreApiField__c);
            this.Submission      = encode.SFDC_JSENCODE(newSM.SubmissionApiField__c);
            this.Survey          = encode.SFDC_JSENCODE(newSM.SurveyApiField__c);
            this.SurveyVersion   = encode.SFDC_JSENCODE(newSM.SurveyVersionApiField__c);
            this.Surveyor        = encode.SFDC_JSENCODE(newSM.SurveyorApiField__c);
            this.matchingField   = encode.SFDC_JSENCODE(newSM.MatchingField__c);
            this.surveyId        = encode.SFDC_JSENCODE(newSM.Survey__c);
            this.objectMapped    = encode.SFDC_JSENCODE(newSM.ObjectApiName__c);
            this.repeatIdSection = encode.SFDC_JSENCODE(newSM.Repeat__c);
            this.isReference     = newSM.IsReference__c;
        }
    }

    /*
    *   Class that represent a question mapping.
    */
    public class QuestionMappingObject{
        public String Id {get;set;}
        public String mappedFieldName {get;set;}
        public String questionId {get;set;}
        public String relatedHeaderCombo {get;set;}
        public Boolean required {get;set;}

        /**
        *   Constructor.
        */
        public QuestionMappingObject()
        {

        }

        /**
        *   Constructor from a QuestionMapping__c.
        */
        public QuestionMappingObject(QuestionMapping__c q)
        {
            SFDCEncoder encode      = new SFDCEncoder();
            this.Id                 = encode.SFDC_JSENCODE(q.Id);
            this.mappedFieldName    = encode.SFDC_JSENCODE(q.FieldApiName__c);
            this.questionId         = encode.SFDC_JSENCODE(q.Question__c );
            this.relatedHeaderCombo = encode.SFDC_JSENCODE(q.SurveyMapping__c);
        }
    }

    /**
    *    Class that holds name, type, label of a field, required or not,
    *    relate to what object is, and (in case of been numeric length of the field).
    */
    public class SField{
        String name;
        String type;
        String label;
        Boolean unique;
        Boolean externalId;
        Boolean required;
        List<RelationField> relatedTo;
        Integer length;
        Boolean nameField;
        Boolean isAutoNumber;
    }

    /**
    *   Class that represents each parent related object.
    */
    public class ParentObject{
        public String parent {get;set;}
        public List<Relation> relationObjects{get;set;}
    }

    /**
    *   Class that represents each child related object.
    */
    public class Relation {
        public String child {get;set;}
        public List<String> fieldsRelated {get;set;}
    }

    /**
    *   Class that represents each child related field.
    */
    public class RelationField{
    	public String name {get;set;}          // Name of the field.
    	public String label {get;set;}         // Label of the field.
    	public String relationType {get;set;}  // Type of relation (i.e.: Master detail).
    }

    /**
    *   Class that represents each object relationship.
    */
    public class ObjectRelation {
        public String parentSM {get;set;}
        public String childSM {get;set;}
        public String fieldName {get;set;}

        public ObjectRelation(ObjectRelationshipMapping__c o){
            SFDCEncoder encode = new SFDCEncoder();
            this.parentSM      = encode.SFDC_JSENCODE(o.ParentSurveyMapping__c);
            this.childSM       = encode.SFDC_JSENCODE(o.ChildSurveyMapping__c);
            this.fieldName     = encode.SFDC_JSENCODE(o.FieldApiName__c);
        }
    }

    // This class is not able to be deleted.
    private class Enviroment{}

    /**
    *    Exception class that raises when a required field of a survey mapping is not present
    *    in its question mappings related.
    */
    public class AllRequiredFieldsException extends Exception {}
}
