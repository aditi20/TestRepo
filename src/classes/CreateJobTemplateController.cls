/**
 * Grameen: Salesforce - SF Field Force, SF - Jobs
 * Controller for the CreateJobTemplate page
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Ernesto Quesada - equesada@altimetrik.com
 * @author Dennys Lopez - dlopez@altimetrik.com
 * @author Sebastian Piazza - spiazza@altimetrik.com
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 * @author Claudio Soto - csoto@altimetrik.com
 */
public with sharing class CreateJobTemplateController {

    public JobTemplate__c job = null;
    private ApexPages.StandardController sController;

    public Map<String, Schema.SObjectType> getGd() {
        return DescribeHandler.getGlobalDescribe();
    }

    public String orgObjects {get;set;}                           // Objects retrieved from the org.
    public String selectedObjectFieldsJson {get;set;}             // Fields of the current Object Hierarchy.
    public String childrenOfCurrentObject {get;set;}              // Children of the current Object Hierarchy.
    public String jsonTasksList {set;get;}                        // List of Task Template in JSON Format, this is used when saving
    public String objectWithDeletedData {get;set;}                // Map of the hierarchies with removed field or object.
    public Boolean shouldButtonsBeDisabled {get;set;}             // Boolean that indicates if the buttons must be disable or not.

    public Map<String, List<SField>> mapSavedObjectFields;        // Map of the fields of the objects retrieved from the org.
    public String getMapSavedObjectFields() {
        return JSON.serialize(mapSavedObjectFields);
    }

    public Map<String, List<ObjectRelation>> mapPotentialObjects; // Map of the potential objects of the objects retrieved from the org.
    public String getMapPotentialObjects() {
        return JSON.serialize(mapPotentialObjects);
    }
    public List<TaskTemplate__c> allTasks;
    public List<TaskTemplate> loadedTasksFromDB;                  // List of Task templates loaded from db, this is used when loading the job template
    public String getLoadedTasksFromDB() {
        return JSON.serialize(loadedTasksFromDB);
    }
    public JobTemplate__c getJob() {
        return job;
    }

    private static final String NOT_MAPPED        = '-1';
    private static final String VALUE_INTEGER     = 'Integer';
    private static final String VALUE_DOUBLE      = 'Double';
    private static final String VALUE_NAME_OBJ    = 'nameObject';
    private static final String VALUE_PARENT_OBJ  = 'parentObject';


    //------------------------------------END CONSTANTS------------------------------------

    /**
     * Constructor of the class
     */
    public CreateJobTemplateController(ApexPages.StandardController stdController) {

        sController = stdController;

        // Load the job when loading the page
        job = (JobTemplate__c) sController.getRecord();
        this.objectWithDeletedData = JSON.serialize(new Map<String, RemovedDataValidation.MissingData>());

        childrenOfCurrentObject = '[]';
        try{
            // Load existing tasks (if any)
            loadTasks();
            // Load existing hierarchy (if any)
            getFieldDataAndPotentialObjectsFromDB();
            // Load the list of all the org objects
            loadObjectSelectList();
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        
        if (!validateTasksForms()){
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                System.Label.JOB_TEMPLATE_FIX_TASK_ERROR));
        }
    }

    /**
     * Validate if some of the collect task was cloned without form 
     * (only happends if the form is closed)
     */
    public boolean validateTasksForms() {
        for (TaskTemplate__c task : this.allTasks) {
            if (task.Type__c == TaskTemplateDO.TYPE_FORM &&
                task.Form__r.Status__c == SurveyDO.STATUS_CLOSED
            ) {
                return false;
            }
        }
        return true;
    }
    /**
     * Saves the jobTemplate.
     * Add an error message in the page if an error occurs
     *
     * @return a page reference to the list of jobs
     */
    public PageReference save() {

        try {
            GenericObjectCreator jobTemplateCreator =
                new GenericObjectCreator(JobTemplate__c.SObjectType);
            jobTemplateCreator.checkObjectAccessible();
            jobTemplateCreator.checkFieldsAccessible(
                new List<Schema.SObjectField> {
                    JobTemplate__c.Name,
                    JobTemplate__c.Instructions__c,
                    JobTemplate__c.Status__c,
                    JobTemplate__c.Hierarchy__c
                    
                }
            );

            Boolean isEdited;
            JobTemplate__c jobTemplateInDB;
            if (job.Id != null) {

                //if the job does not exist anymore it was deleted.show a message
                try {
                    jobTemplateInDB = [SELECT LastModifiedDate FROM JobTemplate__c WHERE Id = :job.Id];
                } catch(DmlException e) {
                    SurveyException.raise(System.Label.JOB_TEMPLATE_DELETED);
                }
            }
            Savepoint sp = Database.setSavepoint();

            //check that the job was saved by another user
            if (job.Id == null || jobTemplateInDB.LastModifiedDate == job.LastModifiedDate) {

                try {
                    jobTemplateCreator.checkObjectCreateable();
                    jobTemplateCreator.checkObjectUpdateable();
                    upsert (JobTemplate__c)sController.getRecord();
                    saveTasks();

                    String listRef = '/' + ('' + sController.getRecord().get('Id')).subString(0, 3) + '/o';
                    return new PageReference(listRef);
                } catch(DmlException e) {

                    //Verify if the error message has already been added, otherwise we show it
                    if (!ApexPages.hasMessages()) {
                        sController.getRecord().addError(e.getDmlMessage(0));
                    }

                    Database.rollback(sp);
                } catch (Exception e) {
                    //Verify if the error message has already been added, otherwise we show it
                    if (!ApexPages.hasMessages()) {
                        sController.getRecord().addError(e.getMessage());
                    }

                    Database.rollback(sp);
                }
            } else {
                SurveyException.raise(System.Label.JOB_TEMPLATE_CANT_MODIFY_CONCURRENT_SAVE);
            }
        } catch (Exception e) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.FATAL, e.getMessage() ) );
        }
        return null;
    }

    /**
    * Save all coming tasks from JobTemplate Page
    * <p>
    * Deserialize the JSON with all tasks associated to this Job. This JSON is converted to a list
    * of Tasks. Create a list of items to insert or edit and save them. Create a List of id deleted tasks
    * and delete them from db. The Action status field determinates the operation to be commited. Untouched tasks
    * are not modified in the database.
    * (Related: IDALMSA-2629)
    */
    private void saveTasks() {

        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkObjectAccessible();
        taskTemplateCreator.checkObjectDeletable();
        taskTemplateCreator.checkObjectUpdateable();
        taskTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                TaskTemplate__c.Name,
                TaskTemplate__c.Type__c,
                TaskTemplate__c.Instructions__c,
                TaskTemplate__c.Position__c,
                TaskTemplate__c.Object__c,
                TaskTemplate__c.Form__c,
                TaskTemplate__c.Mapping__c,
                TaskTemplate__c.JobTemplate__c,
                TaskTemplate__c.ResourceId__c
            }
        );

        List <TaskTemplate> jsonTasks =
            (jsonTasksList.length() == 0)
                ? new List <Tasktemplate>()
                : (List <Tasktemplate>) JSON.deserialize(jsonTasksList, List <Tasktemplate>.class);

        Id jobTemplateId = (Id) sController.getRecord().get('Id');
        List <TaskTemplate__c> tasksAddedAndEdited = new List<Tasktemplate__c>();
        Set <Id> taskIdsToRemove = new Set <Id>();

        for (TaskTemplate task : jsonTasks) {

            task.Name = task.Name.unescapeHtml4();
            task.Instructions = task.Instructions.unescapeHtml4();

            if (task.Id == null) {
                task.JobTemplate = jobTemplateId;
            }
            if (task.Action == TaskTemplateDO.ACTION_EDITED_ADDED) {
                tasksAddedAndEdited.add( task.getTaskTemplate() );
            }
            if (task.Action == TaskTemplateDO.ACTION_DELETED) {
                taskIdsToRemove.add(task.Id);
            }
        }

        delete [
            SELECT
                Id
            FROM
                TaskTemplate__c
            WHERE
                JobTemplate__c = :jobTemplateId
                AND Id IN :taskIdsToRemove
        ];
        upsert tasksAddedAndEdited;
    }

    /**
     * Saves the jobTemplate and set a new empty template.
     * Add an error message in the page if an error occurs
     *
     * @return a page reference to a blank edit page
     */
    public PageReference saveAndNew() {
        this.save();
        if(ApexPages.hasMessages(ApexPages.Severity.ERROR)){
            return null;
        }
        String newRef = '/' + ('' + sController.getRecord().get('Id')).subString(0, 3) + '/e';
        return new PageReference(newRef);
    }

    /**
     * Get the initial data to put the details in the task list (surveys and resources)
     */
    @RemoteAction
    public static DetailsListData generateTaskDetailData() {
        return new DetailsListData();
    }
    
    /**
    * Generate a name list of not Closed Surveys
    * <p>
    * Get the list of Survey names and ids to set these values to a select input control of Task Template
    * Form to associate Surveys as Forms to tasks. (this is a remote action called from JS)
    * (Related: IDALMSA-2629)
    *
    * @return surveys List  Name List of Surveys
    */
    @RemoteAction
    public static List <FormListItem> generateFormsList() {

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Survey__c
            }
        );
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Survey__c.Name
            }
        );

        List <SurveyVersion__c> surveyVersions = [
            SELECT
                Id,
                Survey__r.Name
            FROM
                SurveyVersion__c
            WHERE
                (Status__c != :SurveyDO.STATUS_CLOSED)
                AND Survey__r.IsTemplate__c = false
                ORDER BY Survey__r.Name
        ];

        List <FormListItem> formItems = new List <FormListItem>();

        for (SurveyVersion__c surveyVersion : surveyVersions) {
            FormListItem item = new FormListItem();
            item.id = surveyVersion.Id;
            item.name = surveyVersion.Survey__r.Name;
            formItems.add(item);
        }
        return formItems;
    }
    
    /**
     * generate a List of form list with all the surveys
     */
    public static List<FormListItem> generateAllFormList() {

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Survey__c
            }
        );
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Survey__c.Name
            }
        );

        List <SurveyVersion__c> surveyVersions = [
            SELECT
                Id,
                Survey__r.Name
            FROM 
                SurveyVersion__c
            WHERE
                Survey__r.IsTemplate__c = false
                ORDER BY Survey__r.Name
        ];

        List <FormListItem> formItems = new List <FormListItem>();

        for (SurveyVersion__c surveyVersion : surveyVersions) {
            FormListItem item = new FormListItem();
            item.id = surveyVersion.Id;
            item.name = surveyVersion.Survey__r.Name;
            formItems.add(item);
        }
        return formItems;
    }
    
    /**
     * Generate the form data in a map per Id
     */
    public static Map<Id, FormListItem> generateFormsMap() {
        List <FormListItem> formList = generateAllFormList();
        Map<Id, FormListItem> formMapPerId = new Map<Id, FormListItem>();
        for (FormListItem item:formList) {
            formMapPerId.put(item.id, item);
        }
        return formMapPerId;
    }

    /**
    * Get existing Task associated to the current record
    * <p>
    * Given a jobTemplateId generates the List of wrappers of Task Templates
    * (Related: IDALMSA-2629)
    */
    private void loadTasks() {

        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkObjectAccessible();
        taskTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                TaskTemplate__c.Name,
                TaskTemplate__c.Type__c,
                TaskTemplate__c.Instructions__c,
                TaskTemplate__c.Position__c,
                TaskTemplate__c.Object__c,
                TaskTemplate__c.Form__c,
                TaskTemplate__c.Mapping__c,
                TaskTemplate__c.JobTemplate__c,
                TaskTemplate__c.ResourceId__c
            }
        );
        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Status__c
            }
        );

        List<TaskTemplateDO> listTaskDO = new List<TaskTemplateDO>();
        this.loadedTasksFromDB = new List<TaskTemplate>();
        this.allTasks = [
                        SELECT Id,
                                Type__c,
                                Name,
                                Instructions__c,
                                Position__c,
                                LastModifiedById,
                                LastModifiedBy.Name,
                                LastModifiedDate,
                                Form__c,
                                Form__r.Status__c,
                                Object__c,
                                Mapping__c,
                                JobTemplate__c,
                                ResourceId__c
                         FROM TaskTemplate__c
                         WHERE JobTemplate__c = :(Id) sController.getRecord().get('Id')
                         ORDER BY Position__c
        ];
        for (TaskTemplate__c task : this.allTasks){

            task.Type__c         = task.Type__c;
            task.Name            = task.Name;
            task.Instructions__c = task.Instructions__c;
            task.Form__c         = task.Form__c;

            this.loadedTasksFromDB.add(new TaskTemplate(task));
        }

    }

   /**
    * Get mappable questions from a given survey
    * (Related: IDALMSA-2635)
    *
    * @param versionId String       Version identifier
    * @return question list         Collection of mappable (not section and not readonly) questions belonging to the survey
    */
    @RemoteAction
    public static List<Question> getMappableQuestions(String versionId) {

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Survey__c
            }
        );
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Name,
                Question__c.Type__c,
                Question__c.Caption__c,
                Question__c.Survey__c
            }
        );
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();

        List<Question> questions = new List<Question>();
        String surveyId = [
            SELECT
                Survey__c
            FROM
                SurveyVersion__c
            WHERE
                Id = :versionId][0].Survey__c;

        for (Question__c question : [
                SELECT
                    Id,
                    Type__c,
                    Name,
                    Caption__c,
                    Survey__c
                FROM
                    Question__c
                WHERE
                    Survey__c = :surveyId
                    AND Type__c NOT IN (
                        :QuestionDO.TYPE_SECTION,
                        :QuestionDO.TYPE_REPEAT,
                        :QuestionDO.TYPE_STATIC,
                        :QuestionDO.TYPE_FINAL,
                        :QuestionDO.TYPE_CASCADING_SELECT,
                        :QuestionDO.TYPE_CASCADING_LEVEL
                    )
            ]
        ) {
            questions.add(new Question(question));
        }
        return questions;
    }

    /**
     * Obtain list of resources from the library TaroWorks.
     */
    @RemoteAction
    public static List<ResourceVersion> obtainResourcesFromLibrary() {

        Map<Id, Id> mapContentDocAuthorIds = new Map<Id, Id>();
        Set<Id> setOfDocumentIds = new Set<Id>();

        GenericObjectCreator userCreator =
            new GenericObjectCreator(User.SObjectType);
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                User.Name
            }
        );

        List<ContentWorkspaceDoc> listDataDocuments = [
            SELECT
                ContentDocumentId,
                ContentDocument.OwnerId
            FROM
                ContentWorkspaceDoc
            WHERE
                ContentWorkspace.Name = :C.WORKSPACE_LIBRARY_NAME
                LIMIT 200
        ];

        for (ContentWorkspaceDoc cwd : listDataDocuments) {
            setOfDocumentIds.add(cwd.ContentDocumentId);
            mapContentDocAuthorIds.put(cwd.ContentDocumentId, cwd.ContentDocument.OwnerId);
        }

        Map<Id,User> userMap = new Map<Id, User>([
            SELECT
                Id,
                Name
            FROM
                User
            WHERE
                Id IN :mapContentDocAuthorIds.values()
        ]);
        List<ContentVersion> latestVersions = [
            SELECT
                Id,
                ContentModifiedDate,
                PathOnClient,
                ContentDocumentId,
                ContentSize,
                Title,
                FileType
            FROM
                ContentVersion
            WHERE
                ContentDocumentId IN :setOfDocumentIds
                AND isLatest = true
                ORDER BY Title ASC
                LIMIT :C.STANDARD_LIMIT
        ];

        return returnFilteredVersions(latestVersions, mapContentDocAuthorIds, userMap);
    }

    /**
     * Generate the resource data in a map per Id
     */
    public static Map<Id, ResourceVersion> obtainResourcesMapFromLibrary() {
        List<ResourceVersion> resourceList = obtainResourcesFromLibrary();
        Map<Id, ResourceVersion> resourceMapPerId = new Map<Id, ResourceVersion>();
        for (ResourceVersion resource:resourceList) {
            resourceMapPerId.put(resource.id, resource);
        }
        return resourceMapPerId;
    }
    
    /**
     *  Method in charge of filtering and returning the resources to be displayed in "Resource tasks".
     *
     *  @param latestVersions List of latest versions.
     *  @param mapContentDocAuthorIds Map with the form: <ContentDocument.Id, AuthorId>.
     *  @param userMap Map with the form: <User.Id, User>.
     *  @return List of ResourceVersion that pass the filter, and are ready to be sent to the page.
     */
    public static List<ResourceVersion> returnFilteredVersions(
            List<ContentVersion> latestVersions,
            Map<Id, Id> mapContentDocAuthorIds,
            Map<Id,User> userMap
    ) {
        List<ResourceVersion> listOfResources = new List<ResourceVersion>();

        for (ContentVersion cv : latestVersions) {
            // Check that the type of the content is supported
            if (C.isContentTypeSupported(cv)) {
                // We only add resources that are contained in the set "supportedFileTypes".
                Id authorId = mapContentDocAuthorIds.get(cv.ContentDocumentId);
                String userName = ( userMap.get(authorId) != null ) ? userMap.get(authorId).Name : System.Label.NOT_APPLICABLE;

                ResourceVersion newResource = new ResourceVersion(cv.ContentDocumentId, cv.Title, cv.PathOnClient, cv.ContentSize, userName, cv.ContentModifiedDate);
                listOfResources.add(newResource);
            }
        }
        return listOfResources;
    }

    /**
     * Method that retrieves all objects from the org.
     */
    public void loadObjectSelectList() {
        SFDCEncoder encoder = new SFDCEncoder();
        List<Map<String, String>> objectsFromOrg = new List<Map<String, String>>();
        for (String objectName : DescribeHandler.getGlobalDescribe().KeySet()) {

            // Add all object that are not in the blacklist.
            // Cannot select the mobile-surveys objects to map
            Schema.DescribeSObjectResult obj = DescribeHandler.getObjectDescribeResult(objectName, false);
            GenericObjectCreator creator = new GenericObjectCreator(obj.getName());
            if (creator.isObjectAccessible(false)) {
                if (!C.isInBlacklist(obj) && !C.hasNotLastModifiedDate(obj)) {
                    objectsFromOrg.add(new Map<String,String> {
                        'name' => obj.getName(),
                        'label' => encoder.SFDC_JSINHTMLENCODE((obj.getLabel()))
                    });
                }
            }
        }
        orgObjects = JSON.serialize(objectsFromOrg);
    }

    /**
     *  Method in charge to retrieve fields for each object of the given list (always from the DB).
     *  Also retrieves potential object for each object hierarchy.
     */
    private void getFieldDataAndPotentialObjectsFromDB() {
        String hierarchyJSON = ((JobTemplate__c)sController.getRecord()).Hierarchy__c;
        if (hierarchyJSON != '' && hierarchyJSON != null) {
            List<JobTemplateDO.ObjectHierarchy> objectHiearchiesFromDB =
                (List<JobTemplateDO.ObjectHierarchy>)JSON.deserialize(hierarchyJSON, List<JobTemplateDO.ObjectHierarchy>.class);

            mapSavedObjectFields = new map<String, List<SField>>();  // Map of fields of objects.
            mapPotentialObjects  = new map<String, List<ObjectRelation>>(); // Map of potential objects.

            // Obtain map of missing data.
            Map<String, RemovedDataValidation.MissingData> mapDataMissing = RemovedDataValidation.obtainMissingDataInBulkFromHierarchy(objectHiearchiesFromDB);
            // Set deleted data to be sent, and if buttons should be disabled or not...
            setDeletedData(mapDataMissing, objectHiearchiesFromDB);
            // Create the set of hierarchies that won't be sent.
            Set<String> hierarchiesNotPresent = new Set<String>();

            for(JobTemplateDO.ObjectHierarchy obj : objectHiearchiesFromDB) {
                Boolean hasRemovedData = mapDataMissing.containsKey(obj.objectId);

                if  (!obj.isRelatedTo(hierarchiesNotPresent) && // If is child of a hierarchy that won't be sent, obj neither will be sent
                     (!hasRemovedData ||                        // If has removed data won't be sent...
                      ( mapDataMissing.get(obj.objectId).missingDataType != RemovedDataValidation.OBJECT_DELETED && //... unless has a field deleted...
                       !obj.hasDeletedRelation(mapDataMissing.get(obj.objectId).fieldsDeleted))) //...and is not a relation being used.
                    ) {
                    // If enters here it means that the object will be sent to the page.

                    // First we obtain list field of each object.
                    List<SField> fieldsOfObj = obtainFieldsFromObject(obj.ObjectName);
                    mapSavedObjectFields.put(obj.ObjectName, fieldsOfObj);

                    // Then we proceed to obtain potential object of each object...
                    List<ObjectRelation> potentialObj = obtainChildrenOfGivenObject(obj.ObjectName);
                    // ...then we set the potential object for the object
                    mapPotentialObjects.put(obj.ObjectId, potentialObj);
                }
                else{
                    // Add it to the set of hierarchies that won't be present in the page.
                    hierarchiesNotPresent.add(obj.objectId);
                }
            }
            areTasksRelatedToDeletedHierarchies(hierarchiesNotPresent);
        }
    }

    /**
     *  Method in charge of set the deleted data that will be sent to the page, and if the buttons
     *  should be disabled or not.
     *
     *  @param mapDataMissing Map with deleted data.
     *  @param objectHiearchiesFromDB Hierarchy objects retrieved from the DB.
     */
    public void setDeletedData(Map<String, RemovedDataValidation.MissingData> mapDataMissing, List<JobTemplateDO.ObjectHierarchy> objectHiearchiesFromDB){
        if (!mapDataMissing.isEmpty()) {
            // There is some field or object removed, so....
            // ...create the message to display to the user....
            RemovedDataValidation.createMessageForMissingData(
                mapDataMissing,
                String.format(
                    System.Label.JOB_TEMPLATE_DELETEDOBJECTSORFIELDS,
                    new String[]{'<br />'}
                )
            );
            // ...set the map of deleted data...
            this.objectWithDeletedData = JSON.serialize(mapDataMissing);
            // ... and disable buttons if needed.
            isAbleToSave(mapDataMissing, objectHiearchiesFromDB);
        }
        else{
            this.shouldButtonsBeDisabled = false;
        }
    }

   /**
    *  Method in charge of check if the user can use buttons or not, is not the same that know if there are any errors,
    *  (can have errors but still be allowed to save).
    *
    *  @param mapDataMissing Map with deleted data.
    *  @param objectHiearchiesFromDB Hierarchy objects retrieved from the DB.
    */
    public void isAbleToSave(Map<String, RemovedDataValidation.MissingData> mapDataMissing, List<JobTemplateDO.ObjectHierarchy> objectHiearchiesFromDB){
        Boolean shouldDisableButtons = false;

        for(String key : mapDataMissing.keySet()){
            RemovedDataValidation.MissingData missingObject = mapDataMissing.get(key);
            if (missingObject.missingDataType == RemovedDataValidation.FIELD_DELETED) {
                // Now we know that what is missing is a field, if at least one field that is not a relation is missing, we must block the buttons
                // (if is a relation we don't have to block the buttons, because the child hierarchy of the relation will be gone, therefore
                // the user still can save without problems).
                if (missingObject.fieldsDeleted != null) {
                    for (JobTemplateDO.ObjectHierarchy hierarchy : objectHiearchiesFromDB) {
                        if (hierarchy.hasFieldsSetButNotAsRelation(missingObject.fieldsDeleted)) {
                            // There is at least one field that is in the hierarchy as a "detail" or "field on list" field (but not as a relation).
                            shouldDisableButtons = true;
                        }
                    }
                }
            }
        }
        this.shouldButtonsBeDisabled = shouldDisableButtons;
    }

    /**
     *  Method in charge of check if any task (collect) that will not be present in the page, is referencing a
     *  hierarchy that won't be sent to the page, set if shouldButtonsBeDisabled attribute should be true
     *  (this is only called in the init of the page).
     *
     *  @param Set of hierarchies Id's that won't be sent to the page.
     */
    public void areTasksRelatedToDeletedHierarchies(Set<String> hierarchiesNotPresent){

        for (TaskTemplate task : loadedTasksFromDB) {
            if (task.Mapping != null) {
                // We want to validate for tasks with mapping (if the task is view type is already deleted).
                List<TaskTemplateDO.Mapping> mappings = (List<TaskTemplateDO.Mapping>)JSON.deserialize(task.Mapping, List<TaskTemplateDO.Mapping>.class);
                for (TaskTemplateDO.Mapping mapping : mappings) {
                    if (hierarchiesNotPresent.contains(mapping.objectId)) {
                        this.shouldButtonsBeDisabled = true;
                    }
                }
            }
        }
    }

    /**
    *    Receives the name of an object, and sets an array of SField objects for each field of the given object.
    */
    public void getDataFromObject(){
        String nameObject           = Apexpages.currentPage().getParameters().get(VALUE_NAME_OBJ);
        List<SField> arrayFieldData = obtainFieldsFromObject(nameObject);
        selectedObjectFieldsJson    = JSON.serialize(arrayFieldData);
    }

    /**
     *  Method that obtain the children of the given object, and set it in the String variable childrenOfCurrentObject.
     */
    public void getChildrenOfObject(){
        String parentObjectName            = Apexpages.currentPage().getParameters().get(VALUE_PARENT_OBJ);
        List<ObjectRelation> mapOfChildren = obtainChildrenOfGivenObject(parentObjectName);
        childrenOfCurrentObject            = JSON.serialize(mapOfChildren);
    }

    /**
     * Given an object api name, return a list of ObjectRelation that represents children of given object.
     *
     * @param parentObjectName - Name of the parent object.
     *
     * @return - List of type ObjectRelation that represents children of given object.
     */
    public List<ObjectRelation> obtainChildrenOfGivenObject(String parentObjectName) {
        SFDCEncoder encoder = new SFDCEncoder();
        parentObjectName = encoder.SFDC_JSENCODE(parentObjectName);
        List<ObjectRelation> mapOfChildren = new List<ObjectRelation>();
        if (DescribeHandler.objectExists(parentObjectName)) {
            List<Schema.ChildRelationship> childRelations =
                DescribeHandler.getObjectDescribeResult(parentObjectName, false).getChildRelationships();
            for (Schema.ChildRelationship child : childRelations) {

                DescribeSObjectResult objectDescribe =
                    DescribeHandler.getObjectDescribeResult(child.getChildSObject(), false);
                GenericObjectCreator creator =
                    new GenericObjectCreator(objectDescribe.getName());
                if (creator.isObjectAccessible(false)) {
                    // Add all object that are not in the blacklist.
                    // Can not select the mobile-surveys objects to map
                    if (
                            !C.isInBlacklist(objectDescribe) &&
                            !C.hasNotLastModifiedDate(objectDescribe)
                    ) {
                        ObjectRelation dummyField = new ObjectRelation();
                        dummyField.name =
                            encoder.SFDC_JSENCODE(objectDescribe.getName());
                        dummyField.relationshipName =
                            encoder.SFDC_JSENCODE(child.getRelationshipName());
                        dummyField.relationName =
                            encoder.SFDC_JSENCODE(child.field.getDescribe().getName());
                        dummyField.relationLabel =
                            encoder.SFDC_JSENCODE(child.field.getDescribe().getLabel());
                        mapOfChildren.add(dummyField);
                    }
                }
            }
        }
        return mapOfChildren;
    }

    /**
     * Clone the current job with all it's tasks 
     * and redirect to the job edition page
     */
    public PageReference cloneJob() {
        if (((Map<String, RemovedDataValidation.MissingData>) 
                JSON.deserialize(
                    this.objectWithDeletedData,
                    Map<String, RemovedDataValidation.MissingData>.class
                )
            ).values().size() == 0
        ) {
                save();
                GenericObjectCreator jobTemplateCreator =
                    new GenericObjectCreator(JobTemplate__c.SObjectType);
                jobTemplateCreator.checkObjectCreateable();
                GenericObjectCreator taskTemplateCreator =
                    new GenericObjectCreator(TaskTemplate__c.SObjectType);
                taskTemplateCreator.checkObjectCreateable();

                // If the page has errors, reload the page
                if (ApexPages.hasMessages()) {
                        return null;
                }
                JobTemplate__c clonedJob = job.clone(false, true);
                jobTemplateCreator.populateFields(
                    clonedJob,
                    new Map<Schema.SObjectField, Object> {
                        JobTemplate__c.Status__c => JobTemplateDO.STATUS_DRAFT
                    }
                );
                insert clonedJob;

                List<TaskTemplate__c> clonedTasks = new List<TaskTemplate__c>();
                for (TaskTemplate__c task : allTasks) {
                    TaskTemplate__c clonedTask = task.clone(false, true);
                    // Clone the lookups
                    taskTemplateCreator.populateFields(
                        clonedTask,
                        new Map<Schema.SObjectField, Object> {
                            TaskTemplate__c.Form__c => task.Form__c,
                            TaskTemplate__c.JobTemplate__c => clonedJob.Id
                        }
                    );
                    clonedTasks.add(clonedTask);
                }
                insert clonedTasks;
                return new PageReference('/' + clonedJob.Id);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                System.Label.JOB_TEMPLATE_CANNOT_CLONE_DELETED_FIELD));
            return null;
        }

    }

    /**
    * Given an object name, returns a list of the fields of the object.
    *
    * @param objectName - Name of the object
    *
    * @return - List of fields related to the object.
    */
    private List<SField> obtainFieldsFromObject(String objectName) {
        List<SField> arrayFieldData = new List<SField>();
        SFDCEncoder encoder = new SFDCEncoder();
        if (objectName != NOT_MAPPED) {
            if (DescribeHandler.objectExists(objectName)) {
                for (String fieldName : DescribeHandler.getFieldMap(objectName).keySet()) {
                    if (!SurveyUtils.isGeoLocationComponentField(fieldName)) {
	                    Schema.DescribeFieldResult dField =
	                       DescribeHandler.getFieldDescribe(objectName, fieldName);
	                    if (isValidField(dField)) {
	                        SField field = new SField();
	                        field.type = String.valueOf(dField.getType());
	                        field.name = String.valueOf(dField.getName());
	                        field.id = String.valueOf(dField.getName());
	                        field.label = encoder.SFDC_HTMLENCODE(String.valueOf(dField.getLabel()));
	                        field.isSelected = false;
	                        arrayFieldData.add(field);
	                    }
                    }
                }
            }
        }
        return arrayFieldData;
    }

    /**
     * Returns true is the field is valid to be displayed en list and detail.
     *
     * @param fieldResult - The DescribeFieldResult for the field being validated
     *
     * @return Boolean true is the field is valid to be displayed in list and detail.
     */
    private static boolean isValidField(Schema.DescribeFieldResult fieldResult) {
        return (fieldResult.getReferenceTo() == null || fieldResult.getReferenceTo().size() == 0);
    }

    /**
     *  Method in charge of set shouldButtonsBeDisabled to false (sometimes we need to do this change from the page).
     *  Also removes error messages.
     */
    public void hasNotDeletedData (){
        this.shouldButtonsBeDisabled = false;
        ApexPages.getMessages().clear();
        if (!validateTasksForms()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.JOB_TEMPLATE_FIX_TASK_ERROR));
        }
    }

    /**
     *  Method in charge of close a published survey (and set "Close Reason" attribute to "Automatically Closed")
     *  when a deleted object or field is found.
     */
    public void closeJobBecauseOfDeletedData() {
        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectUpdateable();

        jobTemplateCreator.populateFields(
            this.job,
            new Map<Schema.SObjectField, Object> {
                JobTemplate__c.CloseReason__c => JobTemplateDO.JOB_AUTOMATICALLY_CLOSED,
                JobTemplate__c.Status__c => JobTemplateDO.STATUS_CLOSED
            }
        );

        try {
            update this.job;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }

        Map<String, RemovedDataValidation.MissingData> missingDataMap =
                (Map<String, RemovedDataValidation.MissingData>)JSON.deserialize(this.objectWithDeletedData, Map<String, RemovedDataValidation.MissingData>.class);
        String messageToDisplay = System.Label.JOB_TEMPLATE_CLOSE_JOB_BECAUSE_DELETED_DATA;
        for (String objectId : missingDataMap.keySet()){
            RemovedDataValidation.MissingData currentDeletedData = missingDataMap.get(objectId);
            messageToDisplay += currentDeletedData.rawMessageForDeletedData();
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, messageToDisplay));
    }

    //------------------------------------INNER CLASSES----------------------------------------
    /**
     * Wrapper class for Questions
     * Needed to avoid different naming when on managed packages.
     */
    public class Question {
        public Id       id {get;set;}
        public String   Name {get;set;}
        public String   Type {get;set;}
        public String   Caption {get;set;}
        public Id       Survey {get;set;}

        public Question(){
            // Empty constructor for JSON.serialize use.
        }

        public Question(Question__c question){
            this.id                 = question.Id;
            this.Name               = question.Name;
            this.Type               = question.Type__c;
            this.Caption            = question.Caption__c;
            this.Survey             = question.Survey__c;
        }
    }

    /**
     * Wrapper class for task templates.
     * Needed to avoid different naming when on managed packages.
     */
    public class TaskTemplate{
        public Id           id {get; set; }
        public String       Name {get; set; }
        public String       Type {get; set; }
        public String       Instructions {get; set; }
        public Integer      Position {get; set; }
        public Id           LastModifiedById {get; set; }
        public String       LastModifiedByName {get; set; }
        public Long         LastModifiedDate {get; set; }
        public Id           Form {get; set; }
        public String       objectId {get; set; }
        public Id           JobTemplate {get; set; }
        public String       Action {get; set; }   // status field to determinate what action to commit with record
        public String       Mapping {get; set; }
        public String       selectedResourceId {get; set; }

        public TaskTemplate(){
            // Empty constructor for JSON.serialize use.
        }

        public TaskTemplate(TaskTemplate__c taskTemplate) {
            this.id                 = taskTemplate.Id;
            this.Name               = taskTemplate.Name.escapeHtml4();
            this.Type               = taskTemplate.Type__c;
            this.Instructions       = taskTemplate.Instructions__c == null ? '' : taskTemplate.Instructions__c.escapeHtml4();
            this.Position           = taskTemplate.Position__c.intValue();
            this.LastModifiedById   = taskTemplate.LastModifiedById;
            this.LastModifiedByName = taskTemplate.LastModifiedBy.Name;
            this.LastModifiedDate   = taskTemplate.LastModifiedDate.getTime();
            this.Form               = taskTemplate.Form__c;
            this.objectId           = taskTemplate.Object__c;
            this.JobTemplate        = taskTemplate.JobTemplate__c;
            this.Mapping            = taskTemplate.Mapping__c;
            this.Action             = TaskTemplateDO.ACTION_LOADED;
            this.selectedResourceId    = taskTemplate.ResourceId__c;
        }

        public TaskTemplate__c getTaskTemplate() {
            GenericObjectCreator taskTemplateCreator =
                new GenericObjectCreator(TaskTemplate__c.SObjectType);
            TaskTemplate__c newTaskTemplateInstance =
                (TaskTemplate__c) taskTemplateCreator.createNewRecord();
            taskTemplateCreator.populateFields(
                newTaskTemplateInstance,
                new Map<Schema.SObjectField, Object> {
                    TaskTemplate__c.Name => this.Name,
                    TaskTemplate__c.Type__c => this.Type,
                    TaskTemplate__c.Instructions__c => this.Instructions,
                    TaskTemplate__c.Position__c => this.Position,
                    TaskTemplate__c.Form__c => this.Form,
                    TaskTemplate__c.Object__c => this.objectId,
                    TaskTemplate__c.JobTemplate__c => this.JobTemplate,
                    TaskTemplate__c.Mapping__c => this.Mapping,
                    TaskTemplate__c.ResourceId__c => this.selectedResourceId
                }
            );

            // populateFields() method checks for create and update permissions on field.
            // And it will fail for any System fields. Need to populate same separatly.
            newTaskTemplateInstance.Id = this.Id;
            return newTaskTemplateInstance;
        }
    }

    /**
    *    Class that holds name, type, label of a field, required or not,
    *    relate to what object is, and (in case of been numeric length of the field).
    */
    public class SField{
        String id;
        String name;
        String type;
        String label;
        Boolean isSelected;
    }

    /**
    *    Class that represents an object relation, it holds the name of the child object
    *    and the id field (external Id).
    */
    public class ObjectRelation{
        String name;            // Name of the object.
        String relationshipName;// Actual name of the relationship
        String relationName;    // Name of the field that act as external Id.
        String relationLabel;   // Label of the field that act as external Id.
    }

    /**
    * Wrapper class to send Id, Name of Surveys for list of Task Template form.
    * (Related: IDALMSA-3042)
    */
    public class FormListItem{
        public String id{get;set;}
        public String name{get;set;}

        public FormListItem(){}
    }

    /**
     *  Class that represents a resource from a library.
     */
    public class ResourceVersion {

        public String id {get; set; }                         // Id of the ContentVersion
        public String title {get; set; }                      // Title of the resource.
        public String file {get; set; }                       // Name of the file (with the extension).
        public Integer contentSize {get; set; }               // Size of the file.
        public String author {get; set; }                     // Author of the file (user owner of the document).
        public DateTime contentModifiedDate {get; set; }      // Last modified date of the file.

        public ResourceVersion (String inputId, String inputTitle, String inputFile, Integer inputContentSize, String inputAuthor, Datetime inputContentModifiedDate) {
            this.id                  = inputId;
            this.title               = inputTitle;
            this.file                = inputFile;
            this.contentSize         = inputContentSize;
            this.author              = inputAuthor;
            this.contentModifiedDate = inputContentModifiedDate;
        }
    }

    // Beloved class that doesn't want to be removed.
    public class RelationField{}
    
    /**
     * Data containing a Map of resources and a map of survey per Id
     * This will be used for the details columns in the task list
     */
    public class DetailsListData {
        public Map<Id, ResourceVersion> resources;
        public Map<Id, FormListItem> surveys;
        
        /**
         * Class constructor
         */
        public DetailsListData() {
            surveys = generateFormsMap();
            resources = obtainResourcesMapFromLibrary();
        
        }
    
    }

    //------------------------------------END INNER CLASSES------------------------------------
}
