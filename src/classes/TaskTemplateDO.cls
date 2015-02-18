/**
 * Class to store Task Templates Information.
 *
 * TODO:
 *    - Refactor code based on SOC architechture
 *    - Use appropriate selector and domain layers and update all queries and DML operations
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author lcosta@altimetrik.com
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class TaskTemplateDO extends SObjectDomain {

    //-----------------------------------------
    // CONSTANTS
    //-----------------------------------------

    // Task types
    public static final String TYPE_FORM = 'form';
    public static final String TYPE_DATA_VIEW = 'data-view';
    public static final String TYPE_RESOURCE = 'resource';

    public static final String ACTION_EDITED_ADDED = 'edited_added';
    public static final String ACTION_LOADED = 'loaded';
    public static final String ACTION_DELETED = 'deleted';

    public TaskTemplateDO() {
        super(TaskTemplate__c.SObjectType);
    }

    public TaskTemplateDO(List<TaskTemplate__c> sObjects) {
        super(sObjects);
    }

    /**
     * Creates and inserts a data view TaskTemplate__c
     *
     * @param taskName      - Task name
     * @param taskPosition  - Task position.
     * @param jobTemplateId - Related JobTemplate__c.Id
     * @param instructions  - Instructions for the task
     * @param objectId      - The objectId in the hierarchy that the task comes after
     *
     * @return - The TaskTemplate__c
     */
    public static TaskTemplate__c createDataViewTaskTemplate(
            String taskName,
            Integer taskPosition,
            Id jobTemplateId,
            String instructions,
            String objectId
    ) {
        TaskTemplate__c taskTemplate = createStubTaskTemplate(
            taskName,
            taskPosition,
            jobTemplateId,
            instructions,
            objectId
        );
        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            TaskTemplate__c.Type__c
        });

        taskTemplateCreator.populateField(
            taskTemplate,
            TaskTemplate__c.Type__c,
            TaskTemplateDO.TYPE_DATA_VIEW
        );
        return taskTemplate;
    }

    /**
     * Create and insert a data collection TaskTemplate__c
     *
     * @param taskName      - Task name
     * @param taskPosition  - Task position.
     * @param jobTemplateId - Related JobTemplate__c.Id
     * @param instructions  - Instructions for the task
     * @param objectId      - The objectId in the hierarchy that the task comes after
     * @param surveyId      - The Survey__c.Id of the survey that is carried out in this task
     * @param mappings      - The mappins into the survey
     *
     * @return - The TaskTemplate__c
     */
    public static TaskTemplate__c createDataCollectionTaskTemplate(
            String taskName,
            Integer taskPosition,
            Id jobTemplateId,
            String instructions,
            String objectId,
            Id surveyId,
            List<TaskTemplateDO.Mapping> mappings
    ) {
        TaskTemplate__c taskTemplate = createStubTaskTemplate(
            taskName,
            taskPosition,
            jobTemplateId,
            instructions,
            objectId
        );
        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            TaskTemplate__c.Type__c,
            TaskTemplate__c.Form__c,
            TaskTemplate__c.Mapping__c
        });

        taskTemplateCreator.populateFields(
            taskTemplate,
            new Map<Schema.SObjectField, Object>{
                TaskTemplate__c.Type__c => TaskTemplateDO.TYPE_FORM,
                TaskTemplate__c.Form__c => surveyId
            }
        );
        if (mappings != null) {
            taskTemplateCreator.populateField(
                taskTemplate,
                TaskTemplate__c.Mapping__c,
                JSON.serialize(mappings)
            );
        }
        return taskTemplate;
    }

    /**
     * Create and insert a resource TaskTemplate__c
     *
     * @param taskName      - Task name
     * @param taskPosition  - Task position.
     * @param jobTemplateId - Related JobTemplate__c.Id
     * @param instructions  - Instructions for the task
     * @param objectId      - The objectId in the hierarchy that the task comes after
     * @param resourceId    - The Survey__c.Id of the survey that is carried out in this task
     *
     * @return - The TaskTemplate__c
     */
    public static TaskTemplate__c createResourceTaskTemplate(
            String taskName,
            Integer taskPosition,
            Id jobTemplateId,
            String instructions,
            String objectId,
            String resourceId
    ) {
        TaskTemplate__c taskTemplate = createStubTaskTemplate(
            taskName,
            taskPosition,
            jobTemplateId,
            instructions,
            objectId
        );
        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            TaskTemplate__c.Type__c,
            TaskTemplate__c.ResourceId__c
        });

        taskTemplateCreator.populateFields(
            taskTemplate,
            new Map<Schema.SObjectField, Object>{
                TaskTemplate__c.Type__c => TaskTemplateDO.TYPE_RESOURCE,
                TaskTemplate__c.ResourceId__c => resourceId
            }
        );
        return taskTemplate;
    }

    /**
     * Method to create a TaskTemplate__c.
     *
     * @param taskName      - Task name
     * @param taskPosition  - Task position.
     * @param jobTemplateId - Related JobTemplate Id.
     * @param taskType      - Task type.
     * @param resourceId    - The ContentDocumentId for the Content used in the template
     *
     * @return Created Task Template.
     */
    public static TaskTemplate__c createTaskTemplate(
            String taskName,
            Integer taskPosition,
            Id jobTemplateId,
            String taskType,
            Id surveyVersion
    ) {
        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkObjectAccessible();
        taskTemplateCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            TaskTemplate__c.Name,
            TaskTemplate__c.Position__c,
            TaskTemplate__c.JobTemplate__c,
            TaskTemplate__c.Type__c,
            TaskTemplate__c.Form__c
        });

        TaskTemplate__c newTaskTemplate = (TaskTemplate__c)taskTemplateCreator.createNewRecord();
        taskTemplateCreator.populateFields(
            newTaskTemplate,
            new Map<Schema.SObjectField, Object>{
                TaskTemplate__c.Name => taskName,
                TaskTemplate__c.Position__c => taskPosition,
                TaskTemplate__c.JobTemplate__c => jobTemplateId,
                TaskTemplate__c.Type__c => taskType,
                TaskTemplate__c.Form__c => surveyVersion
            }
        );
        return newTaskTemplate;
    }

    /**
     * Create a shell TaskTemplate__c. Will not insert the TaskTemplate__c
     *
     * @param taskName      - Task name
     * @param taskPosition  - Task position.
     * @param jobTemplateId - Related JobTemplate Id
     * @param instructions  - Instructions for the task
     * @param objectId      - The objectId in the hierarchy that the task comes after
     *
     * @return - The TaskTemplate__c
     */
    private static TaskTemplate__c createStubTaskTemplate(
            String taskName,
            Integer taskPosition,
            Id jobTemplateId,
            String instructions,
            String objectId
    ) {
        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkObjectAccessible();
        taskTemplateCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            TaskTemplate__c.Name,
            TaskTemplate__c.Position__c,
            TaskTemplate__c.JobTemplate__c,
            TaskTemplate__c.Instructions__c,
            TaskTemplate__c.Object__c
        });

        TaskTemplate__c newTaskTemplate = (TaskTemplate__c)taskTemplateCreator.createNewRecord();
        taskTemplateCreator.populateFields(
            newTaskTemplate,
            new Map<Schema.SObjectField, Object>{
                TaskTemplate__c.Name => taskName,
                TaskTemplate__c.Position__c => taskPosition,
                TaskTemplate__c.JobTemplate__c => jobTemplateId,
                TaskTemplate__c.Instructions__c => instructions,
                TaskTemplate__c.Object__c => objectId
            }
        );
        return newTaskTemplate;
    }

    /**
     * Create a TaskTemplateResponse from a TaskTemplate__c object.
     * Will create the relevant extension
     *
     * @param task     - The TaskTemplate__c object to create the response instance from
     * @param resource - Optional ContentView
     *
     * @return - The correct extension of a TaskTemplateResponse
     */
    public static TaskTemplateResponse createTaskTemplateResponse(TaskTemplate__c task, ContentVersion resource) {

        // Based on the type of task template passed in create the relevant response
        // I long for a switch statement in apex
        if (task.Type__c.equals(TYPE_DATA_VIEW)) {
            return new TaskTemplateResponseDataView(task);
        }
        else if (task.Type__c.equals(TYPE_FORM)) {
            return new TaskTemplateResponseDataCollection(task);
        }
        else if (task.Type__c.equals(TYPE_RESOURCE)) {

            // If no resource passed in throw an error
            if (resource == null) {
                throw new SurveyException(
                    ErrorHandlingRest.ERR_CODE_SYNC_TASK_RESOURCE_NOT_SPECIFIED,
                    ErrorHandlingRest.SYNC_TASK_WITHOUT_RESOURCE,
                    C.HTTP_INTERNAL_SERVER_ERROR,
                    'The resource for the task ' + task.Name + ' was not specified.',
                    false
                );
            }
            return new TaskTemplateResponseResource(task, resource);
        }
        else {

            // Throw an error as the task template doesn't have a type
            throw new SurveyException(
                ErrorHandlingRest.ERR_CODE_SYNC_TASK_TEMP_BAD_TYPE,
                ErrorHandlingRest.SYNC_BAD_TASK_TYPE,
                C.HTTP_INTERNAL_SERVER_ERROR,
                'The Type__c for task ' + task.Name + ' is unrecognised',
                false
            );
        }
    }

    /**
     * Virtual class to contain all the shared information for a task template so it can be
     * easily serialized and returned to the device
     */
    public virtual class TaskTemplateResponse {

        public String taskTemplateId;
        public String name;
        public Integer position;
        public String instructions;
        public String taskTemplateType;

        /**
         * Required 0 argument constructor
         */
        public TaskTemplateResponse() {}

        public TaskTemplateResponse(TaskTemplate__c taskTemplate) {
            this.taskTemplateId = taskTemplate.Id;
            this.name = taskTemplate.Name;
            this.position = Integer.valueOf(taskTemplate.Position__c);
            this.instructions = taskTemplate.Instructions__c;
            this.taskTemplateType = taskTemplate.Type__c;
        }
    }

    /**
     * Extension for Data View type task templates
     */
    public class TaskTemplateResponseDataView extends TaskTemplateResponse {

        // Matches the objectId field of the refered object in the JobTemplate hierarchy
        public String objectId;

        public TaskTemplateResponseDataView(TaskTemplate__c taskTemplate) {
            super(taskTemplate);
            if (String.isNotBlank(taskTemplate.Object__c)) {
                this.objectId = taskTemplate.Object__c;
            }
        }
    }

    /**
     * Extension for Data Collection type task templates
     */
    public class TaskTemplateResponseDataCollection extends TaskTemplateResponse {

        public Id formId;
        public List<Mapping> mappings;

        public TaskTemplateResponseDataCollection(TaskTemplate__c taskTemplate) {
            super(taskTemplate);
            this.formId = taskTemplate.Form__c;
            if (String.isNotBlank(taskTemplate.Mapping__c)) {
                this.mappings = (List<Mapping>)JSON.deserialize(taskTemplate.Mapping__c, List<Mapping>.class);
            }
        }
    }

    /**
     * Extension for the Resource type task templates
     */
    public class TaskTemplateResponseResource extends TaskTemplateResponse {

        public String resourceId;
        public String resourceVersion;
        public String resourceTitle;

        public TaskTemplateResponseResource(TaskTemplate__c taskTemplate, ContentVersion resource) {
            super(taskTemplate);
            this.resourceId = resource.ContentDocumentId;
            this.resourceVersion = resource.VersionNumber;
            this.resourceTitle = resource.Title;
        }
    }

    /**
     * Class for the mapping structure
     */
    public class Mapping {
        public String objectId {get;set;}
        public String field {get;set;}
        public String question {get;set;}

        public Mapping(String objectId, String field, String question) {
            this.objectId = objectId;
            this.field = field;
            this.question = question;
        }
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public TaskTemplateDO constructWithRecords(List<SObject> sObjectList) {
            return new TaskTemplateDO(sObjectList);
        }
        public TaskTemplateDO constructEmpty() {
            return new TaskTemplateDO();
        }
    }
}