/**
 * Data model class for the Job Templates.
 * Contains:
 *    - Static constants for the Job Templates
 *    - Static methods to fetch Job Templates
 *    - Classes used for JSON serialization of the response to /jobtemplates rest resource
 *    - Classes used to generate and validate the object hierarchy for a job template
 * TODO:
 *    - Refactor code based on SOC architechture
 *    - Use appropriate selector and domain layers and update all queries and DML operations
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Dennys Lopez Dinza
 * @author Claudio Soto - csoto@altimetrik.com
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class JobTemplateDO extends SObjectDomain {

    //-----------------------------------------
    // CONSTANTS
    //-----------------------------------------
    // Job Template status
    public static final String STATUS_DRAFT     = 'Draft';
    public static final String STATUS_PUBLISHED = 'Published';
    public static final String STATUS_CLOSED    = 'Closed';

    // Variable that will be stored in Close_reason__c attribute of Job__c, if it is closed due to deleted data.
    public static final String JOB_AUTOMATICALLY_CLOSED = 'Automatically Closed';

    // Indicates if the validations when updating a job should be skipped
    private static Boolean skipUpdateValidation = false;

    public JobTemplateDO() {
        super(JobTemplate__c.SObjectType);
    }

    public JobTemplateDO(List<JobTemplate__c> sObjects) {
        super(sObjects);
    }

    /**
     * Enable a flag to skip the validations on the update when setting the preconditions of a test
     *
     * @param skip - Indicates if the flag shuold be activated or deactivated
     */
    public static void setSkipUpdateValidation(Boolean skip) {
        skipUpdateValidation = skip;
    }

    /**
     * Check if the update validations on job must be skipped
     *
     * @return - true if the flag is enabled
     */
    public static Boolean skipUpdateValidation() {
        return skipUpdateValidation;
    }

    /**
     * Get the ids of the jobs used by non closed job targets
     *
     * @return - A set with the ids of the jobs
     */
    public static Set<Id> getJobsUsedByNonClosedTargets() {
        Set<Id> jobs = new Set<Id>();
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);
        performanceTargetCreator.checkObjectAccessible();
        performanceTargetCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                PerformanceTarget__c.JobTemplate__c
            }
        );

        List<PerformanceTarget__c> nonClosedJobTargets = [
            SELECT
                JobTemplate__c
            FROM
                PerformanceTarget__c
            WHERE
                Type__c = :PerformanceTargetDO.TYPE_JOB_TARGET
                AND Status__c != :PerformanceTargetDO.STATUS_CLOSED
        ];

        for (PerformanceTarget__c jobTarget : nonClosedJobTargets) {
            jobs.add(jobTarget.JobTemplate__c);
        }
        return jobs;
    }

    /**
     * Get the job for a given mobile user. The templates that are available to the mobile user
     * depend on the settings that the org admin has set up
     *
     * @param userContact - The contact for the user
     * @param status      - The status of job required
     *
     * @return - List of all the job available to the mobile user
     */
    public static List<JobTemplate__c> getMobileUserJobTemplates(
            Contact userContact,
            String status
    ) {
        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkFieldsAccessible(
            new List<String>{
                'Name',
                'Hierarchy__c',
                'Instructions__c',
                'PublishedDate__c',
                'TasksNumber__c',
                'OwnerId',
                'Status__c'
            }
        );
        String baseQuery =
            'SELECT ' +
                'Id, ' +
                'Name, ' +
                'Hierarchy__c, ' +
                'Instructions__c, ' +
                'PublishedDate__c, ' +
                'Status__c, ' +
                'TasksNumber__c ' +
            'FROM ' +
                'JobTemplate__c ' +
            'WHERE ' +
                'Status__c = \'' + String.escapeSingleQuotes(status) + '\'';

        // Check the setting
        if (ApplicationSettingsUtils.isJobFilterEnable()) {
            baseQuery += ' AND OwnerId = \'' + String.escapeSingleQuotes(userContact.OwnerId) + '\'';
        }
        return (List<JobTemplate__c>)DBFullAccess.querySObject(baseQuery);
    }

    /**
     * Get the JobTemplates and their task templates for /jobtemplates endpoint
     * JobFiltering is ignored here and dealt with by the calling method
     *
     * @param existingJobTemplates - The Ids of the JobTemplate__c that the MobileUser
     *                                 knows about already
     * @param lastSyncDate         - The date that the MobileUser last sync'd
     */
    public static Map<Id, JobTemplate__c> getJobTemplatesForSync(
            Set<Id> existingJobTemplates,
            Date lastSyncDate
    ) {
        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Name,
                SurveyVersion__c.Survey__c
            }
        );
        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                JobTemplate__c.Name,
                JobTemplate__c.Status__c,
                JobTemplate__c.Instructions__c,
                JobTemplate__c.Hierarchy__c,
                JobTemplate__c.CreatedDate,
                JobTemplate__c.PublishedDate__c,
                JobTemplate__c.OwnerId
            }
        );
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
                TaskTemplate__c.ResourceId__c
            }
        );
        return new Map<Id, JobTemplate__c>([
            SELECT
                Id,
                Status__c,
                Name,
                Instructions__c,
                Hierarchy__c,
                CreatedDate,
                PublishedDate__c,
                OwnerId,
                (
                    SELECT
                        Id,
                        Name,
                        Type__c,
                        Instructions__c,
                        Position__c,
                        Object__c,
                        Form__c,
                        Form__r.Name,
                        Mapping__c,
                        Form__r.Survey__c,
                        ResourceId__c
                    FROM
                        Task_Templates__r
                )
            FROM
                JobTemplate__c
            WHERE
                PublishedDate__c >= :lastSyncDate
                OR Id IN :existingJobTemplates
        ]);
    }

    /**
     * Create a JobTemplate__c
     *
     * @param templateName         - Template name.
     * @param templateStatus       - Template status.
     * @param templateHierarchy    - Template hierarchy.
     * @param templateInstructions - Template instructions
     *
     * @return Created Job Template.
     */
    public static JobTemplate__c createJobTemplate(
            String templateName,
            String templateStatus,
            String templateHierarchy,
            String templateInstructions
    ) {
        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                JobTemplate__c.Name,
                JobTemplate__c.Status__c,
                JobTemplate__c.Hierarchy__c,
                JobTemplate__c.Instructions__c
            }
        );
        JobTemplate__c newJobTemplate =
            (JobTemplate__c) jobTemplateCreator.createNewRecord();
        jobTemplateCreator.populateFields(
            newJobTemplate,
            new Map<Schema.SObjectField, Object> {
                JobTemplate__c.Name => templateName,
                JobTemplate__c.Status__c => templateStatus,
                JobTemplate__c.Hierarchy__c => templateHierarchy,
                JobTemplate__c.Instructions__c => templateInstructions
            }
        );
        return newJobTemplate;
    }

    /**
     * Method to create a JobTemplate__c.
     *
     * @param templateName      - Template name.
     * @param templateStatus    - Template status.
     * @param templateHierarchy - Template hierarchy.
     *
     * @return Created Job Template.
     */
    public static JobTemplate__c createJobTemplate(
            String templateName,
            String templateStatus,
            String templateHierarchy
    ) {
        return createJobTemplate(templateName, templateStatus, templateHierarchy, '');
    }

    /**
     * Publish a list of job templates
     */
    public static List<JobTemplate__c> setJobTemplatesToPublished(
            List<JobTemplate__c> jobsToPublish
    ) {
        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                JobTemplate__c.Status__c
            }
        );

        for (JobTemplate__c jobToPublish : jobsToPublish) {
            jobTemplateCreator.populateFields(
                jobToPublish,
                new Map<Schema.SObjectField, Object>{
                    JobTemplate__c.Status__c => JobTemplateDO.STATUS_PUBLISHED
                }
            );
        }
        return jobsToPublish;
    }

    /**
     * Create a JobTemplateResponseFull from the JobTemplates__c including the related Task_Templates__r
     *
     * @param jobTemplate - The JobTemplate__c that is being converted to a full response
     * @param resources   - A map of the resources that are available to the Mobile User. Can be empty
     *
     * @return - The JobTemplateResponseFull
     */
    public static JobTemplateResponseFull createJobTemplateResponseFull(
            JobTemplate__c jobTemplate,
            Map<Id, ContentVersion> resources
    ) {

        // Loop through the task templates attached to the job and create the TaskTemplateResponses
        List<TaskTemplateDO.TaskTemplateResponse> taskTemplateResponses = new List<TaskTemplateDO.TaskTemplateResponse>();
        for (TaskTemplate__c taskTemplate : jobTemplate.Task_Templates__r) {
            taskTemplateResponses.add(TaskTemplateDO.createTaskTemplateResponse(
                taskTemplate,
                resources.get(taskTemplate.ResourceId__c)
            ));
        }
        return new JobTemplateResponseFull(jobTemplate, taskTemplateResponses);
    }

    //----------------------- Inner classes section ----------------------------
    /**
     * Virtual stub class for the job template response. This allows for easy JSON serialization
     * in order to make the response to /jobtemplates
     */
    public virtual class JobTemplateResponse {

        public Id jobTemplateId;
        public String status;

        /**
         * Required 0 argument constructor
         */
        public JobTemplateResponse() {}

        public JobTemplateResponse(Id jobTemplateId, String status) {
            this.jobTemplateId = jobTemplateId;
            this.status = status;
        }

        /**
         * Change the status of the JobTemplateDo
         *
         * @param status - The new status
         */
        public void setStatus(String status) {
            this.status = status;
        }
    }

    /**
     * Extension of the JobTemplateResponse class to include the full context of the job
     */
    public class JobTemplateResponseFull extends JobTemplateResponse {

        public String name;
        public String instructions;
        public List<ObjectHierarchy> hierarchy;
        public List<TaskTemplateDO.TaskTemplateResponse> taskTemplates;

        public JobTemplateResponseFull(JobTemplate__c jobTemplate, List<TaskTemplateDO.TaskTemplateResponse> taskTemplates) {
            super(jobTemplate.Id, jobTemplate.Status__c);
            this.name = jobTemplate.Name;
            this.instructions = jobTemplate.Instructions__c;
            this.taskTemplates = taskTemplates;

            // Only set the hierarchy if it is not null
            if(String.isNotBlank(jobTemplate.Hierarchy__c)){
                this.hierarchy = (List<ObjectHierarchy>)JSON.deserialize(jobTemplate.Hierarchy__c, List<ObjectHierarchy>.class);
            }
        }
    }

     /**
     * Classes used to help with the JSON Serialization of the jobs hierarchy
     */
    public class ObjectHierarchy {

        public String objectId;
        public String label;
        public String objectName;
        public List<Relation> relations = new List<Relation>();
        public List<String> listFields = new List<String>();
        public List<String> detailFields = new List<String>();

        /**
         * Constructor of the class
         *
         * @param objectId   - JSON Id for the object in the hierarchy. This is not a Salesforce Id
         * @param label      - Label of the object, which is displayed to the user.
         * @param objectName - API Name of the object, as it appears in SOQL queries.
         */
        public ObjectHierarchy(String objectId, String label, String objectName) {
            this.objectId = objectId;
            this.label = label;
            this.objectName = objectName;
            this.relations = new List<Relation>();
            this.listFields = new List<String>();
            this.detailFields = new List<String>();
        }

        /**
         * Add a new Relation to the Object Hierarchy
         *
         * @param parent - JSON Id for the hierarchy object that is parent of this object in the relationship.
         * @param field  - API Name of the field that relates the objects (in the child object).
         */
        public void addRelation(String parent, String field) {
            this.relations.add(new Relation(parent, field));
        }

        /**
         * Add a new List Field to the Object Hierarchy
         *
         * @param field - API Name of the field.
         */
        public void addListField(String field) {
            listFields.add(field);
        }

        /**
         * Set the list fields
         *
         * @param fields - A list of the field API names
         */
        public void setListFields(List<String> fields) {
            this.listFields = fields;
        }

        /**
         * Add a new Detail Field to the Object Hierarchy
         *
         * @param field - API Name of the field.
         */
        public void addDetailField(String field) {
            detailFields.add(field);
        }

        /**
         * Set the detail fields
         *
         * @param fields - A list of the field API names
         */
        public void setDetailFields(List<String> fields) {
            this.detailFields = fields;
        }


        /**
         * Method in charge of validate that given a list of fields (deleted) at least one of those fields
         * is present in {this} as a detail or list field and there is no relation in the given list
         * (if is set as a relation the object won't be in the page).
         *
         * @param deletedFieldNames - List of Api names of deleted fields.
         *
         * @return - True if at least one of the fields is present as detail or list field and there si no relation
         *            in the given list, false otherwise.
         */
        public Boolean hasFieldsSetButNotAsRelation(List<String> deletedFieldNames) {

            Boolean isFieldPresent      = false;
            Boolean isFieldInRelation   = false;

            for (String fieldName : deletedFieldNames) {

                // Check if is in the list of fields (on list).
                if (this.listFields != null) {
                    for (String field : this.listFields) {
                        if (field == fieldName) {
                            isFieldPresent = true;
                        }
                    }
                }

                // Check if is in the list of fields (detail list).
                if (this.detailFields != null) {
                    for (String field : this.detailFields) {
                        if (field == fieldName) {
                            isFieldPresent = true;
                        }
                    }
                }

                // Now we check if the field is in a relation.
                if (this.relations != null) {
                    for (Relation relation : this.relations) {
                        if (relation.field == fieldName) {
                            isFieldInRelation = true;
                        }
                    }
                }
            }
            return isFieldPresent && !isFieldInRelation;
        }

        /**
         * Method in charge of check if {this} has a deleted relation (reference to a parent).
         *
         * @param deletedFields - List of Api names of deleted fields.
         *
         * @return - True if has a relation removed, false otherwise.
         */
        public Boolean hasDeletedRelation(List<String> deletedFields) {

            Boolean isFieldInRelation = false;
            if (this.relations != null) {
                for (Relation relation : this.relations) {
                    for (String fieldName : deletedFields) {
                        if (relation.field == fieldName) {
                            isFieldInRelation = true;
                        }
                    }
                }
            }
            return isFieldInRelation;
        }

        /**
         * Method in charge of retrieve all fields of {this}
         *
         * @return - List of fields.
         */
        public List<String> obtainFields() {

            List<String> listOfFields = new List<String>();

            // Obtain detail fields.
            for (String detailFieldName : this.detailFields) {

                // Obtain detail fields.
                listOfFields.add(detailFieldName);
            }

            // Obtain list field (required).
            listOfFields.add(this.listFields[0]);

            if (this.relations != null) {

                // Obtain list of relations (for now is only one field per hierarchy, but in the future could be more than one).
                for (Relation relationField : this.relations) {

                    // Obtain fields that act as lookups.
                    listOfFields.add(relationField.field);
                }
            }
            return listOfFields;
        }

        /**
         * Method in charge of check if {this} is related to any of the hierarchies Id of the set .
         *
         * @param setIdHierarchies - Set of Ids of the hierarchies.
         *
         * @return - True if {this} is related to any of the given Id's, false otherwise.
         */
        public Boolean isRelatedTo(Set<String> setIdHierarchies) {

            Boolean isRelatedToAny = false;
            if (this.relations != null) {
                for (Relation relation : this.relations) {
                    if (setIdHierarchies.contains(relation.parent)) {
                        isRelatedToAny = true;
                    }
                }
            }
            return isRelatedToAny;
        }
    }

    /**
     * Defines a relationship between two objects on the hierarchy.
     */
    public class Relation {

        public String parent;
        public String field;

        /**
         * Constructor of the class
         *
         * @param parent - JSON Id for the hierarchy object that is parent of this object in the relationship.
         * @param field  - API Name of the field that relates the objects (in the child object).
         */
        public Relation(String parent, String field) {
            this.parent = parent;
            this.field = field;
        }
    }

    /**
     *  Represents a mapping inside a Task.
     *  Defines how fields from objects in the hierarchy are mapped to questions on the form
     */
    public class TaskMapping {
        public String objectId;
        public String field;
        public String question;
    }
    //--------------------------------------------------------------------

    //----------------------- Queries section ----------------------------

    /**
     *  Obtain list of JobTemplates
     *  @return List of Job templates.
     */
    public static List<JobTemplate__c> obtainJobTemplates() {
        return [SELECT Id, Name FROM JobTemplate__c ORDER BY Name];
    }

    //----------------------- End Queries section ------------------------

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public JobTemplateDO constructWithRecords(List<SObject> sObjectList) {
            return new JobTemplateDO(sObjectList);
        }
        public JobTemplateDO constructEmpty() {
            return new JobTemplateDO();
        }
    }
}