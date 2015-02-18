/**
 * Contains the logic for the TaroRESTJobTemplates REST Resource.
 * This is moved into its own class as it is not possible to patch classes
 * in a managed package that is marked as @RestResource
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Laureano Costa
 * @author - Owen Davies
 */
global with sharing class TaroRESTJobTemplatesLogic {

    public static void generateDataAndMetaData() {

        // Get request data
        String sessionId = RestContext.request.headers.get(C.SESSION_TOKEN_HEADER);
        String requestBody = RestContext.request.requestBody.toString();

        // Parse the body of the request
        TaroRequestBody taroBody = (TaroRequestBody)JSON.deserialize(requestBody, TaroRequestBody.class);

        // Check the session and device
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            sessionId,
            true
        );
        if (loginResult.hasError) {
            // Add the headers
            for(String header : loginResult.headers.keySet()) {
                RestContext.response.addHeader(header, loginResult.headers.get(header));
            }
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
            Restcontext.response.statusCode = loginResult.statusCode;
            return;
        }

        // Create Savepoint to be able to rollback all the DB changes if needed
        Savepoint sp = Database.setSavepoint();
        try {
            // Build a map with the status of each job template by id
            Map<Id, String> knownJobTempaltesById = new Map<Id, String>();
            for (KnownJobTemplate knownJobTemplate : taroBody.jobTemplates){
                knownJobTempaltesById.put(knownJobTemplate.jobTemplateId, knownJobTemplate.status);
            }

            // Set the new sync time stamp
            DateTime newSync = DateTime.now();

            // Get the job templates for the response
            List<JobTemplateDO.JobTemplateResponse> jobTemplates = getJobTemplatesForSync(
                knownJobTempaltesById,
                taroBody.lastSync,
                loginResult.getContact()
            );

            // Get the hierarchy metadata for the Job Templates available to the mobile user
            Map<String, GenerateMetaData.HierarchyObjectDefinitions> objectMetaData =
                GenerateMetaData.getHierarchyMetadata(JobTemplateDO.getMobileUserJobTemplates(
                    loginResult.getContact(),
                    JobTemplateDO.STATUS_PUBLISHED
                )
            );

            // Get the metadata delta for the response
            GenerateMetaData.MetaDataDelta metaDataDelta = GenerateMetaData.getMetaDataDelta(
                loginResult.getAttachmentParentId(),
                RestContext.request.headers.get(C.DEVICE_ID_HEADER),
                taroBody.lastSync,
                newSync,
                objectMetaData
            );

            // Process the reveived instances and get the instances of the data
            List<GenerateInstanceData.ObjectInstanceDataDefinition> instances = GenerateInstanceData.generateInstanceData(
                loginResult.getContact().Id,
                taroBody.instances,
                taroBody.lastSync,
                objectMetaData
            );

            // Build the response body
            TaroResponseBody response = new TaroResponseBody(
                metaDataDelta,
                jobTemplates,
                instances,
                newSync,
                loginResult.getContact()
            );

            // Set the response
            RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, C.CONTENT_TYPE_JSON_UTF);
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
            Restcontext.response.statusCode = loginResult.statusCode;
        } catch (GenericObjectCreator.GenericObjectCreatorException genericObjectCreatorException) {
            Database.rollback(sp);
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_CRUD_FLS,
                ErrorHandlingRest.CRUD_FLS,
                System.Label.ERR_PERMISSIONS + '\n\n' + genericObjectCreatorException.getMessage()
            );
            RestContext.response.statusCode = C.HTTP_INTERNAL_SERVER_ERROR;
        } catch (DmlException e) {
            Database.rollback(sp);
            if (ErrorHandlingRest.parseDmlException(e)) {
                throw e;
            }
            RestContext.response.statusCode = ErrorHandlingRest.getStatusCode();
        }

        if (ErrorHandlingRest.checkForErrors()) {
            RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, C.CONTENT_TYPE_JSON_UTF);
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
        }
    }

    /**
     * Gets all the JobTemplates for the response.
     * This method build a list containing the new job templates (not included in the request) and
     * the job templates included in the request that the status changed from last sync.
     * For the last ones, only id and status is included.
     *
     * @param jobStatusById - A map with the status for the jobs in the request
     * @param lastSync      - The date of last synchronization
     * @param userContact   - The contact for the user that is getting the jobs
     *
     * @return - A list of JobTemplateResponse to include in the response
     */
    private static List<JobTemplateDO.JobTemplateResponse> getJobTemplatesForSync(
            Map<Id, String> jobStatusById,
            DateTime lastSync,
            Contact userContact
    ) {

        // Check to see if the last sync is null
        // If it is set it to sensible previous date to make sure we get everything
        if (lastSync == null) {
            lastSync = DateTime.newInstance(2010, 1, 1, 0, 0, 0);
        }

        List<JobTemplateDO.JobTemplateResponse> jobTemplateResponse = new List<JobTemplateDO.JobTemplateResponse>();
        Set<Id> jobTemplateIds = new Set<Id>();
        Map<Id, List<Id>> jobsBySurveyId = new Map<Id, List<Id>>();

        // Get the jobs to sync
        Map<Id, JobTemplate__c> jobTemplates =
            JobTemplateDO.getJobTemplatesForSync(jobStatusById.keySet(), lastSync.date());

        // Add list of job templates to a set to handle jobs that have been closed due to bad field mapping
        jobTemplateIds.addAll(jobTemplates.keySet());

        Set<Id> jobsToClose = RemovedDataValidation.findJobsWithBrokenHierarchy(jobTemplates.values());

        // Build a set with the id of the resources so we can load the resources info into a map
        Set<Id> resourceIds = new Set<Id>();

        // Build a set with the id of the surveys used in the jobs
        // so we can check if there are some broken ones to close
        Set<Id> surveyIds = new Set<Id>();

        for (JobTemplate__c jobTemplate : jobTemplates.values()) {
            for(TaskTemplate__c task : jobTemplate.Task_Templates__r) {
                resourceIds.add(task.ResourceId__c);
                surveyIds.add(task.Form__r.Survey__c);

                // Fill map for Id of survey to job templates
                if(jobsBySurveyId.get(task.Form__r.Survey__c) != null) {
                    jobsBySurveyId.get(task.Form__r.Survey__c).add(jobTemplate.Id);
                }
                else {
                    jobsBySurveyId.put(task.Form__r.Survey__c, new List<Id>{jobTemplate.Id});
                }
            }
        }

        // Take out the null resource that will most likely have been added
        resourceIds.remove(null);

        GenericObjectCreator contentVersionCreator =
            new GenericObjectCreator(ContentVersion.SObjectType);
        contentVersionCreator.checkObjectAccessible();
        contentVersionCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            ContentVersion.VersionNumber,
            ContentVersion.Title,
            ContentVersion.ContentDocumentId
        });

        // A map with the resources info to build the JSON
        Map<Id, ContentVersion> resources = new Map<Id, ContentVersion>();
        for (ContentVersion resource : [
                SELECT
                    Id,
                    VersionNumber,
                    Title,
                    ContentDocumentId
                FROM
                    ContentVersion
                WHERE
                    ContentDocumentId IN :resourceIds
                    AND isLatest = true
        ]) {
            resources.put(resource.ContentDocumentId, resource);
        }
        resourceIds.clear();


        // Check surveys to close due to missing mapped object, field or relation
        Set<Id> surveysToClose = RemovedDataValidation.mappingsWithMissingObjectOrField(surveyIds);

        // Close failed surveys
        if (!surveysToClose.isEmpty()) {
            SurveyUtils.closeFailedSurveysAndUserInfo(surveysToClose, false);

            // Add the jobs related to failed surveys to the list of jobs to close
            for(Id surveyIdToClose : surveysToClose) {
                jobsToClose.addAll(jobsBySurveyId.get(surveyIdToClose));
            }
        }

        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                JobTemplate__c.Name,
                JobTemplate__c.Status__c,
                JobTemplate__c.CloseReason__c
            }
        );
        // Close the broken jobs
        List<JobTemplate__c> toClose = new List<JobTemplate__c>();
        for (Id jobToClose : jobsToClose) {
            JobTemplate__c job = jobTemplates.get(jobToClose);
            jobTemplateCreator.populateFields(
                job,
                new Map<Schema.SObjectField, Object>{
                    JobTemplate__c.Status__c => JobTemplateDO.STATUS_CLOSED,
                    JobTemplate__c.CloseReason__c => JobTemplateDO.JOB_AUTOMATICALLY_CLOSED
                }
            );
            toClose.add(job);
        }
        update toClose;

        // Remove the Id of the Job Template from the list of available valid jobs
        jobTemplateIds.removeAll(jobsToClose);

        // Get the filter setting
        Boolean filterJobs = ApplicationSettingsUtils.isJobFilterEnable();

        // Loop through all of the available JobTemplates and create the response
        for (JobTemplate__c jobTemplate : jobTemplates.values()) {

            String existingStatus = jobStatusById.get(jobTemplate.Id);

            // Check that the job is still available to the Mobile User
            if (!jobTemplateIds.contains(jobTemplate.Id)) {

                // Check if the device knew about the job and it wasn't already closed. If so close it
                if (String.isNotBlank(existingStatus) && !existingStatus.equals(JobTemplateDO.STATUS_CLOSED)) {
                    jobTemplateResponse.add(
                        new JobTemplateDO.JobTemplateResponse(jobTemplate.Id, JobTemplateDO.STATUS_CLOSED)
                    );
                }
                continue;
            }

            // Check that the job templates should be filtered based on owner
            if (filterJobs) {

                if (String.isNotBlank(existingStatus)) {

                    // If the mobile user already downloaded a job that is not available to them then close it
                    if (jobTemplate.OwnerId != userContact.OwnerId) {
                        jobTemplateResponse.add(
                            new JobTemplateDO.JobTemplateResponse(jobTemplate.Id, JobTemplateDO.STATUS_CLOSED)
                        );
                        continue;
                    }
                    else if (
                            !existingStatus.equals(jobTemplate.Status__c) &&
                            jobTemplate.OwnerId == userContact.OwnerId
                    ) {

                        // If the status of a job that is available to the user has changed then change the status
                        jobTemplateResponse.add(
                            new JobTemplateDO.JobTemplateResponse(jobTemplate.Id, jobTemplate.Status__c)
                        );
                        continue;
                    }
                }
                else if (
                        String.isBlank(existingStatus) &&
                        jobTemplate.Status__c.equals(JobTemplateDO.STATUS_PUBLISHED) &&
                        jobTemplate.OwnerId == userContact.OwnerId
                ) {

                    // If the device doesn't know about the job and they should see it add to the device
                    jobTemplateResponse.add(JobTemplateDO.createJobTemplateResponseFull(jobTemplate, resources));
                    continue;
                }

                // Job template filtered out
                continue;
            }

            // If the job templates status has changed from the status on the device update the status
            if (String.isNotBlank(existingStatus) && !existingStatus.equals(jobTemplate.Status__c)) {

                // Change the status on the device
                jobTemplateResponse.add(
                    new JobTemplateDO.JobTemplateResponse(jobTemplate.Id, jobTemplate.Status__c)
                );
                continue;
            }

            // If the job template is published and uknown to the device send the entire context for the template
            if (String.isBlank(existingStatus) && jobTemplate.Status__c.equals(JobTemplateDO.STATUS_PUBLISHED)) {
                jobTemplateResponse.add(JobTemplateDO.createJobTemplateResponseFull(jobTemplate, resources));
            }
        }
        return JobTemplateResponse;
    }

    /**
     * Classes to parse the Request Body
     */
    global class TaroRequestBody {
        public DateTime lastSync;
        public List<GenerateInstanceData.KnownInstance> instances;
        public List<KnownJobTemplate> jobTemplates;
    }

    global class KnownJobTemplate {
        public Id jobTemplateId;
        public String status;

        public KnownJobTemplate(Id jobTemplateId, String status){
            this.jobTemplateId = jobTemplateId;
            this.status = status;
        }
    }

    /**
     * Wrapper class for the response body
     */
    public class TaroResponseBody {
        public DateTime timeStamp;
        public UserData user;
        public List<GenerateMetaData.ObjectDefinitionDelta> metaData;
        public List<String> removedObjects;
        public List<GenerateInstanceData.ObjectInstanceDataDefinition> instances;
        public List<JobTemplateDO.JobTemplateResponse> jobTemplates;

        public TaroResponseBody(
            GenerateMetaData.MetaDataDelta metaDataDelta,
            List<JobTemplateDO.JobTemplateResponse> jobTemplates,
            List<GenerateInstanceData.ObjectInstanceDataDefinition> instances,
            DateTime newSync,
            Contact aContact
        ) {
            this.metaData = metaDataDelta.metadata;
            this.removedObjects = metaDataDelta.removedObjects;
            this.jobTemplates = jobTemplates;
            this.instances = instances;
            this.timeStamp = newSync;
            this.user = new UserData(aContact);
        }
    }

    /**
     * Wrapper class for the user data
     */
    public class UserData {
        public String lastName;

        public UserData(Contact aContact) {
            this.lastName = aContact.LastName;
        }
    }
}
