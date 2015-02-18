/**
 * Contains the logic for the FFSubmitJobs REST Resource.
 * This is moved into its own class as it is not possible to patch classes
 * in a managed package that is marked as @RestResource
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Ernesto Quesada
 * @author - Owen Davies
 * @author - Aditi Satpute
 */
public with sharing class FFSubmitJobsLogic {

    private static MobileUserLoginLogic.LoginResult loginResult;

    private static Map<Id, JobTemplate__c> jobTemplateNameMapping;
    private static Map<Id, TaskTemplate__c> taskTemplateNameMapping;

    //current user
    private static User currentUser;
    private static String timeZoneSidKey;

    /**
     * Process the request
     */
    public static void processPostRequest() {
        timeZoneSidKey = UserInfo.getTimeZone().getId();

        // Validate session
        loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            RestContext.request.headers.get(C.SESSION_TOKEN_HEADER),
            true
        );
        RestContext.response.statusCode = loginResult.statusCode;
        if (loginResult.hasError) {
            // Add the headers
            for(String header : loginResult.headers.keySet()) {
                RestContext.response.addHeader(header, loginResult.headers.get(header));
            }
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
        }
        else {

            // Init the response
            JobResponses responses = new JobResponses();

            // Create Savepoint to be able to rollback all the DB changes if needed
            Savepoint sp = Database.setSavepoint();
            try {
                createJobs(RestContext.request.requestBody.toString(), responses);
            } catch (GenericObjectCreator.GenericObjectCreatorException genericObjectCreatorException) {
                Database.rollback(sp);
                ErrorHandlingRest.addErrorMsg(
	                ErrorHandlingRest.ERR_CODE_CRUD_FLS,
	                ErrorHandlingRest.CRUD_FLS,
	                System.Label.ERR_PERMISSIONS + '\n\n' + genericObjectCreatorException.getMessage()
	            );
	            ErrorHandlingRest.setStatusCode(C.HTTP_INTERNAL_SERVER_ERROR);
             } catch (DmlException e) {
                Database.rollback(sp);
                if (ErrorHandlingRest.parseDmlException(e)) {
                    throw e;
                }
            }
            RestContext.response.statusCode = ErrorHandlingRest.getStatusCode();
            if (ErrorHandlingRest.checkForErrors()) {
                RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, C.CONTENT_TYPE_JSON_UTF);
                RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
            }
            else {
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responses));
            }
        }
    }

    /**
     * Generates the Job__c and Task__c objects from a Job List and inserted them in the DB.
     *
     * @param requestString - A JSON String that represents the jobs that are being submitted
     */
    private static JobResponses createJobs(String requestString, JobResponses responses) {
        List<Job> jobs = (List<Job>)JSON.deserialize(requestString, List<Job>.class);
        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkObjectUpdateable();
        jobTemplateCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            JobTemplate__c.Name,
            JobTemplate__c.Status__c,
            JobTemplate__c.Hierarchy__c,
            JobTemplate__c.Status__c,
            JobTemplate__c.CloseReason__c
        });

        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkObjectAccessible();
        taskTemplateCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            TaskTemplate__c.Name
        });

        // Get the ids for the task and jobs to get the names
        Set<Id> jobTemplateIds = new Set<Id>();
        Set<Id> taskTemplateIds = new Set<Id>();
        for (Job job : jobs) {
            for (Task task: job.tasks) {
                taskTemplateIds.add(task.taskTemplate);
            }
            jobTemplateIds.add(job.jobTemplate);
        }
        jobTemplateNameMapping = new Map<Id, JobTemplate__c>(
            [
                SELECT
                    Id,
                    Name,
                    Status__c,
                    Hierarchy__c
                FROM
                    JobTemplate__c
                WHERE
                    Id IN :jobTemplateIds
            ]
        );
        taskTemplateNameMapping = new Map<Id, TaskTemplate__c>(
            [
                SELECT
                    Id,
                    Name
                FROM
                    TaskTemplate__c
                WHERE
                    Id IN :taskTemplateIds
            ]
        );

        // Check that all the templates still have their hierarchy intact
        Set<Id> jobsToClose =
            RemovedDataValidation.findJobsWithBrokenHierarchy(
                jobTemplateNameMapping.values()
            );

        // Close the broken jobs
        List<JobTemplate__c> toClose = new List<JobTemplate__c>();
        for (Id jobToClose : jobsToClose) {
            JobTemplate__c job = jobTemplateNameMapping.get(jobToClose);
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

        // Check that the Job and task templates still exist in the DB

        Set<Id> deletedJobTemplates = jobTemplateIds;
        Set<Id> deletedTaskTemplates = taskTemplateIds;
        deletedJobTemplates.removeAll(jobTemplateNameMapping.keySet());
        deletedTaskTemplates.removeAll(taskTemplateNameMapping.keySet());

        List<JobWrapper> jobWrappers = convertAndSaveJobs(
          jobs, jobsToClose, deletedJobTemplates, deletedTaskTemplates
        );
        processJobWrappers(jobWrappers, responses);

        // Update job targets
        jobTemplateIds = jobTemplateNameMapping.keySet();
        jobTemplateIds.removeAll(jobsToClose);

        try {
            PerformanceManagementUtils.updateJobTargets(
                extractSuccessfulJobs(jobWrappers),
                jobTemplateIds,
                loginResult.getContact().Id
            );
        } catch (Exception e) {

          // Set the custom setting to indicate that the jobtargets need recalculating
          ApplicationSettingsUtils.setReCalculateJobTarget(true, true);
        }
        return responses;
    }

    /**
     * Converts a list of Job objects to Job__c.
     * Carries out validation of the Job
     * Inserts the created Job__c  to the DB
     * Populates the jobWrapper
     *
     * @param jobs                - The list of Job objects
     * @param corruptJobTemplates - A set of JobTemplate__c.Ids for the JobTemplates that are corrupt
     * @param deletedJobIds       - A set that contains all the deleted JobTemplate__c.Ids
     * @param deletedTaskIds      - A set that contains all the deleted TaskTemplate__c.Ids
     *
     * @return - List of JobWrappers to be used to save the Task__c
     */
    private static List<JobWrapper> convertAndSaveJobs(
            List<Job> jobs,
            Set<Id> corruptJobTemplates,
            Set<Id> deletedJobIds,
            Set<Id> deletedTaskIds
    ) {
        GenericObjectCreator jobCreator =
            new GenericObjectCreator(Job__c.SObjectType);
        jobCreator.checkObjectAccessible();

        List<Job__c> jobSObjectsToSave = new List<Job__c>();
        List<JobWrapper> jobWrappers = new List<JobWrapper>();
        for (Job job : jobs) {
            JobWrapper newJob = createJobWrapper(
                job, corruptJobTemplates, deletedJobIds, deletedTaskIds
            );
            jobWrappers.add(newJob);

            // Only save the successful jobs
            if (newJob.success) {
              jobSObjectsToSave.add(newJob.job);
            }
        }
        DBFullAccess.InsertSObject(jobSObjectsToSave);
        return jobWrappers;
    }

    /**
     * Process the JobWrappers.
     * This involves adding the Task__r.Job__c and creating the JobResponse for each JobWrapper
     *
     * @param jobWrappers - The JobWrapper list to be processed
     * @param responses   - The JobResponses object being populated
     *
     * @return - The JobResponses object being populated
     */
    private static JobResponses processJobWrappers(
            List<JobWrapper> jobWrappers,
            JobResponses responses
    ) {
        GenericObjectCreator taskCreator =
            new GenericObjectCreator(Task__c.SObjectType);

        List<Task__c> taskSObjectsToSave = new List<Task__c>();
        for (JobWrapper job : jobWrappers) {

            // Create the response objects
            responses.addJob(job);

            if (job.success) {
                for (Task__c task : job.tasks) {
                    taskCreator.populateField(
                        task,
                        Task__c.Job__c,
                        job.job.Id
                    );
                    taskSObjectsToSave.add(task);
                }
            }
        }
        insert taskSObjectsToSave;
        return responses;
    }

    /**
     * Generate the jobWrapper for a given Job. Will catch and suppress any allowable
     * exceptions so that submission of jobs is no longer atomic
     *
     * @param job                 - The raw job instance from the deserialized JSON request
     * @param corruptJobTemplates - A set of JobTemplate__c.Ids for the JobTemplates that are corrupt
     * @param deletedJobIds       - A set that contains all the deleted JobTemplate__c.Ids
     * @param deletedTaskIds      - A set that contains all the deleted TaskTemplate__c.Ids
     *
     * @return - The newly created JobWrapper
     */
    private static JobWrapper createJobWrapper(
        Job job,
        Set<Id> corruptJobTemplates,
        Set<Id> deletedJobIds,
        Set<Id> deletedTaskIds
    ) {

        JobWrapper wrapper = new JobWrapper(job.jobActivityId);
        try {

            // Check that the job the wrapper is for is not corrupt
            if (corruptJobTemplates.contains(job.jobTemplate)) {
              throw new SurveyException(
                ErrorHandlingRest.ERR_CODE_SYNC_SCHEMA_CORRUPT,
                ErrorHandlingRest.SYNC_JOB_DEF_CORRUPT,
                C.HTTP_BAD_REQUEST,
                'A field or object has been removed',
                false
              );
            }
            if (deletedJobIds.contains(job.jobTemplate)) {
              throw new SurveyException(
                ErrorHandlingRest.ERR_CODE_JOB_TEMPLATE_REMOVED,
                ErrorHandlingRest.SYNC_JOB_TEMPLATE_DELETED,
                C.HTTP_BAD_REQUEST,
                'JobTemplate ' + job.jobTemplate + ' has been deleted from the system',
                false
              );
            }

            wrapper.addJob(createJob(job));
            wrapper.addTasks(createTasks(job.tasks, deletedTaskIds));
        }
        catch (SurveyException e) {
            wrapper.success = false;
            wrapper.addError(e);
        }
        return wrapper;
    }

    /**
     * Converts a Job instance into a Job__c object
     *
     * @param  job a job instance
     * @return an individual Job__c record
     * @throws SurveyException
     */
    private static Job__c createJob(Job job) {
        GenericObjectCreator jobCreator =
            new GenericObjectCreator(Job__c.SObjectType);
        jobCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Job__c.Assigned__c,
                Job__c.Name,
                Job__c.Contact__c,
                Job__c.CreationDate__c,
                Job__c.CreationNotes__c,
                Job__c.StartDate__c,
                Job__c.EndDate__c,
                Job__c.CreationSource__c,
                Job__c.JobTemplate__c,
                Job__c.StartLocation__Latitude__s,
                Job__c.StartLocation__Longitude__s,
                Job__c.EndLocation__Latitude__s,
                Job__c.EndLocation__Longitude__s
            }
        );
        Job__c newJob =
            (Job__c) jobCreator.createNewRecord();
        jobCreator.populateFields(
            newJob,
            new Map<Schema.SObjectField, Object>{
                Job__c.Assigned__c => loginResult.getContact().Id,
                Job__c.Contact__c => job.contact,
                Job__c.CreationDate__c => job.creationDate,
                Job__c.CreationNotes__c => '',
                Job__c.StartDate__c => SurveyUtils.valueInGmt(job.startDate),
                Job__c.EndDate__c => SurveyUtils.valueInGmt(job.endDate),
                Job__c.CreationSource__c => C.JOB_CREATION_SOURCE_ADHOC,
                Job__c.JobTemplate__c => job.jobTemplate
            }
        );

        // Get the geolocation and split it. The format should be
        // "latitude longitude altitude aproximation timestamp" but only first two values will be used
        SurveyUtils.GeoLocation startLocation =
            SurveyUtils.parseGeoLocation(
                job.startGeoLocation,
                false
            );

        if (startLocation != null) {
            jobCreator.populateFields(
                newJob,
                new Map<Schema.SObjectField, Object>{
                    Job__c.StartLocation__Latitude__s => startLocation.latitude,
                    Job__c.StartLocation__Longitude__s => startLocation.longitude
                }
            );
        }

        SurveyUtils.GeoLocation endLocation =
            SurveyUtils.parseGeoLocation(
                job.endGeoLocation,
                false
            );

        if (endLocation != null) {
            jobCreator.populateFields(
                newJob,
                new Map<Schema.SObjectField, Object>{
                    Job__c.EndLocation__Latitude__s => endLocation.latitude,
                    Job__c.EndLocation__Longitude__s => endLocation.longitude
                }
            );
        }

        // Default Name for Job Activities: MobileUser_c.Contact.FullName + '' + JobTemplate_c.Name + '' + Job_c.StartTime_c
        String jobName =
            loginResult.getContact().Name + ' ' +
            jobTemplateNameMapping.get(job.jobTemplate).Name + ' ' +
            SurveyUtils.valueInGmt(
              SurveyUtils.convertDateTimeToString(newJob.StartDate__c)
            ).format('yyyy-MM-dd hh:mm a');
        if (jobName.length() > 80) {
            jobName = jobName.substring(0, 79);
        }
        jobCreator.populateField(
            newJob,
            Job__c.Name,
            jobName
        );
        return newJob;
    }

    /**
     * Converts a List of Task instances into a List of Task__c objects
     *
     * @param tasks          - Task list
     * @param deletedTaskIds - A set that contains all the deleted TaskTemplate__c.Ids
     *
     * @return - List of the newly created tasks
     *
     * @throws SurveyException
     */
    private static List<Task__c> createTasks(List<Task> tasks, Set<Id> deletedTaskIds) {

        List<Task__c> newTasks = new List<Task__c>();
        for (Task taskAux : tasks) {

            if (deletedTaskIds.contains(taskAux.taskTemplate)) {
              throw new SurveyException(
                ErrorHandlingRest.ERR_CODE_TASK_TEMPLATE_REMOVED,
                ErrorHandlingRest.SYNC_TASK_TEMPLATE_DELETED,
                C.HTTP_BAD_REQUEST,
                'The task template ' + taskAux.taskTemplate + ' has been deleted from the system',
                false
              );
            }
            Task__c newTask = createTask(taskAux);
            newTasks.add(newTask);
        }
        return newTasks;
    }

    /**
     * Converts a Task instance into a Task__c object
     *
     * @param task - A task instance
     *
     * @return - An individual Task__c record
     *
     * @throws - SurveyException
     */
    private static Task__c createTask(Task task) {
        GenericObjectCreator taskCreator =
            new GenericObjectCreator(Task__c.SObjectType);
        taskCreator.checkObjectAccessible();
        taskCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Task__c.Submission__c,
                Task__c.EndDate__c,
                Task__c.TaskTemplate__c,
                Task__c.StartDate__c,
                Task__c.Name,
                Task__c.Job__c
            }
        );
        Task__c newTask =
            (Task__c) taskCreator.createNewRecord();
        taskCreator.populateFields(
            newTask,
            new Map<Schema.SObjectField, Object>{
                Task__c.Submission__c => task.submissionID,
                Task__c.EndDate__c => SurveyUtils.valueInGmt(task.endDate),
                Task__c.TaskTemplate__c => task.taskTemplate,
                Task__c.StartDate__c => SurveyUtils.valueInGmt(task.startDate)
            }
        );

        // Get the geolocation and split it. The format should be
        // "latitude longitude altitude aproximation timestamp" but only first two values will be used
        SurveyUtils.GeoLocation startLocation =
            SurveyUtils.parseGeoLocation(
                task.startGeoLocation,
                false
            );

        if (startLocation != null) {
            newTask.StartLocation__Latitude__s = startLocation.latitude;
            newTask.StartLocation__Longitude__s = startLocation.longitude;
        }

        SurveyUtils.GeoLocation endLocation =
            SurveyUtils.parseGeoLocation(
                task.endGeoLocation,
                false
            );

        if (endLocation != null) {
            newTask.EndLocation__Latitude__s = endLocation.latitude;
            newTask.EndLocation__Longitude__s = endLocation.longitude;
        }

        // Default Name for Task Activities: MobileUser_c.Contact.FullName + '' + TaskTemplate_c.Name + '' + Task_c.StartTime_c
        String taskName = loginResult.getContact().Name + ' ' + taskTemplateNameMapping.get(task.taskTemplate).Name + ' '
            + newTask.StartDate__c.format('yyyy-MM-dd hh:mm a');
        if (taskName.length() > 80) {
            taskName = taskName.substring(0, 79);
        }
        taskCreator.populateFields(
            newTask,
            new Map<Schema.SObjectField, Object>{
                Task__c.Name => taskName
            }
        );
        return newTask;
    }

    /**
     * Extract the successfully created Job__c from the JobWrappers
     *
     * @param jobWrappers - The wrappers to be checked
     *
     * @return - List of Job__c taken out of the wrappers that were successful
     */
    private static List<Job__c> extractSuccessfulJobs(List<JobWrapper> jobWrappers) {

      List<Job__c> successfulJobs = new List<Job__c>();
      for (JobWrapper jobWrapper : jobWrappers) {
        if (jobWrapper.success) {
          successfulJobs.add(jobWrapper.job);
        }
      }
      return successfulJobs;
    }

    /**
     * Class used to help with the JSON Serialization of the job
     */
    public class Job {
        public String jobActivityId;
        public Id jobTemplate;
        public Id contact;
        public Date creationDate;
        public String startDate;
        public String startGeolocation;
        public String endGeolocation;
        public String endDate;
        public List<Task> tasks;

        public Job(
            String jobActivityId,
            Id jobTemplateId,
            Id contactId,
            Date creationDate,
            String startDate,
            String endDate,
            String startGeolocation,
            String endGeolocation
        ) {
          this.jobActivityId = jobActivityId;
          this.jobTemplate = jobTemplateId;
          this.contact = contactId;
          this.creationDate = creationDate;
          this.startDate = startDate;
          this.endDate = endDate;
          this.startGeolocation = startGeolocation;
          this.endGeolocation = endGeolocation;
          this.tasks = new List<Task>();
        }
    }

    /**
     * Class used to help with the JSON Serialisation of the task
     */
    public class Task {
          public Id submissionID;
          public Id taskTemplate;
          public String startDate;
          public String endDate;
          public String startGeolocation;
          public String endGeolocation;

          public Task(
              Id submissionID,
              Id taskTemplate,
              String startDate,
              String endDate,
              String startGeolocation,
              String endGeolocation
          ) {
            this.submissionID = submissionID;
            this.taskTemplate = taskTemplate;
            this.startDate = startDate;
            this.endDate = endDate;
            this.startGeolocation = startGeolocation;
            this.endGeolocation = endGeolocation;
          }
    }

    /**
     * Class used to help relation Job__c with his tasks
     */
    private class JobWrapper {

        public String deviceSetJobActivityId;
        public Job__c job;
        public List<Task__c> tasks;
        public Boolean success;
        public List<ErrorHandlingRest.ErrorMessage> errors;

        public JobWrapper(String jobActivityId) {
            this.tasks = new List<Task__c>();
            this.success = true;
            this.errors = new List<ErrorHandlingRest.ErrorMessage>();
            this.deviceSetJobActivityId = jobActivityId;
        }

        /**
         * Add the job to the wrapper
         *
         * @param job - The job
         */
        public void addJob(Job__c job) {
            this.job = job;
        }

        /**
         * Add the tasks to the wrapper
         *
         * @param tasks - The list of tasks to be added to the wrapper
         */
        public void addTasks(List<Task__c> tasks) {
            this.tasks = tasks;
        }

        /**
         * Add an error to the JobWrapper if a SurveyException is thrown
         *
         * @param e - The surveyException
         */
        public void addError(SurveyException e) {
            this.errors.add(new ErrorHandlingRest.ErrorMessage(
                e.getTwErrorCode(),
                e.getTwXlationCode(),
                e.getDefaultMessage()
            ));
        }
    }

    /**
     * Class used to help with the JSON serialization of the response
     */
    public class JobResponses {

        public List<JobResponse> jobs;

        public JobResponses() {
            this.jobs = new List<JobResponse>();
        }

        /**
         * Create a response object from the JobWrapper
         */
        public void addJob(JobWrapper job) {
            this.jobs.add(new JobResponse(
                job.success,
                job.deviceSetJobActivityId,
                job.errors
            ));
        }
    }

    /**
     * Class used to help with JSON serialisation for the response for an
     * individual job
     */
    public class JobResponse {
        public Boolean success;
        public String jobActivityId;
        public List<ErrorHandlingRest.ErrorMessage> error;

        public JobResponse(
            Boolean success,
            String jobActivityId,
            List<ErrorHandlingRest.ErrorMessage> error
        ) {
          this.success = success;
          this.jobActivityId = jobActivityId;
          this.error = error;
        }
    }
}