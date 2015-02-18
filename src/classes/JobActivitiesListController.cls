/**
 * Grameen: Salesforce - SF Field Force, SF - Jobs
 * Controller for the JobActivitiesList page
 * TODO - Update class based on SOC
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Sebastian Piazza
 * @author - Claudio Soto csoto@altimetrik.com
 */
public with sharing class JobActivitiesListController {


    transient public List<JobTemplate__c> listJobTemplates {get; set;}
    transient public List<TaskTemplate__c> listTaskTemplates {get; set;}
    transient public String mapTaskJobActivities {get; set;}

    //---------------Constants-----------

    public static final String UNDEFINED_VALUE = '';
    private static String  timeZoneSidKey='';
    //---------------End Constants-------

    /**
     * Constructor of the class
     */
    public JobActivitiesListController() {
        this.obtainRelatedData();
    }

    /**
     *  Obtain list of saved job templates, task templates, and a map of relations of task and jobs.
     */
    public void obtainRelatedData() {
        this.listJobTemplates = JobTemplateDO.obtainJobTemplates();
        this.listTaskTemplates = new TaskTemplateSelector().getAllRecords();
        this.mapTaskJobActivities = JSON.serialize(obtainMapTaskJobs());
    }

    /**
     *  Obtain list of job ativities in the org.
     *  @return List of JobActivity (wrapper of Job__c) saved in the org.
     */
    @RemoteAction
    public static List<JobActivity> getJobActivities() {
        GenericObjectCreator userCreator =
            new GenericObjectCreator(User.SObjectType);
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                User.TimezonesIdKey
            }
        );

        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                JobTemplate__c.Name,
                JobTemplate__c.TasksNumber__c
            }
        );

        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Contact.Name
        });

        GenericObjectCreator jobCreator =
            new GenericObjectCreator(Job__c.SObjectType);
        jobCreator.checkObjectAccessible();
        jobCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Job__c.Assigned__c,
                Job__c.Name,
                Job__c.Contact__c,
                Job__c.CreatedDate,
                Job__c.StartDate__c,
                Job__c.EndDate__c,
                Job__c.JobTemplate__c
            }
        );

        User currentUser = 
            [
                SELECT
                    ID,
                    TimeZoneSidKey
                FROM
                    User
                WHERE
                    ID = :UserInfo.getUserId()
            ];
        timeZoneSidKey = currentUser.TimeZoneSidKey;

        List<JobActivity> jobActivitiesList = new List<JobActivity>();
        for (Job__c job :
                [
                    SELECT
                        Id,
                        Name,
                        Assigned__r.Name,
                        Contact__r.Name,
                        JobTemplate__r.TasksNumber__c,
                        StartDate__c,
                        EndDate__c,
                        CreatedDate,
                        JobTemplate__r.Name,
                        JobTemplate__c
                    FROM
                        Job__c
                        ORDER BY EndDate__c DESC LIMIT :Limits.getLimitQueryRows()
                ]
        ) {
            jobActivitiesList.add(new JobActivity(job));
        }

        return jobActivitiesList;
    }

    /**
     *  Method in charge to retrieve what tasks are associated with what jobs activities.
     *  @return Map with the format: <TaskTemplate__c.Id, Set<Job__c.Id>>.
     */
    public Map<Id, Set<Id>> obtainMapTaskJobs() {
        GenericObjectCreator taskCreator =
            new GenericObjectCreator(Task__c.SObjectType);
        taskCreator.checkObjectAccessible();
        taskCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Task__c.Name,
                Task__c.TaskTemplate__c,
                Task__c.Job__c
            }
        );

        Map<Id, Set<Id>>  mapTasksJobs = new Map<Id, Set<Id>>();
        List<Task__c> listTasksActivities =
            [
                SELECT
                    Id,
                    Name,
                    TaskTemplate__c,
                    Job__c
                FROM
                    Task__c
            ];

        for (Task__c taskActivity : listTasksActivities) {
            Set<Id> listjobActivityIds = ( mapTasksJobs.containsKey(taskActivity.TaskTemplate__c) )
                                            ? mapTasksJobs.get(taskActivity.TaskTemplate__c)
                                            : new Set<Id>();
            listjobActivityIds.add(taskActivity.Job__c);
            mapTasksJobs.put(taskActivity.TaskTemplate__c, listjobActivityIds);
        }
        return mapTasksJobs;
    }


    /**
     * Wrapper class for Job Activity
     */
    public class JobActivity {
        public Id           id {get;set;}
        public String       Name {get;set;}
        public Id           StaffId {get;set;}
        public String       Staff {get;set;}
        public Id           ClientId {get;set;}
        public String       Client {get;set;}
        public Integer      TasksNumber {get;set;}
        public String       Submitted {get;set;}
        public String       Started {get;set;}
        public String       Finished {get;set;}
        public Long         Duration {get;set;}
        public Id           JobTemplateId {get;set;}
        public String       JobTemplateName {get;set;}

        public JobActivity() {
            // Empty constructor for JSON.serialize use.
        }

        public JobActivity(Job__c JobActivity) {
            this.id       = JobActivity.Id;
            this.Name     = JobActivity.Name;
            this.StaffId  = JobActivity.Assigned__c;
            this.Staff    = JobActivity.Assigned__r.Name;
            this.ClientId = JobActivity.Contact__c;
            this.Client   = JobActivity.Contact__r.Name;

            if (JobActivity.JobTemplate__r != null) {
                this.TasksNumber = JobActivity.JobTemplate__r.TasksNumber__c.intValue();
            }
            else {
                this.TasksNumber = 0;
            }


            if (JobActivity.StartDate__c != null) {
                this.Started     = JobActivity.StartDate__c.format('MM/dd/yyyy HH:mm', timezoneSidKey);
            }
            else {
                this.Started     = UNDEFINED_VALUE;
            }

            if (JobActivity.EndDate__c != null) {
                this.Finished    = JobActivity.EndDate__c.format('MM/dd/yyyy HH:mm', timezoneSidKey);
            }
            else {
                this.Finished    = UNDEFINED_VALUE;
            }


            if (JobActivity.CreatedDate != null) {
                this.Submitted   = JobActivity.CreatedDate.format('MM/dd/yyyy HH:mm', timezoneSidKey);
            }
            else {
                this.Submitted   = UNDEFINED_VALUE;
            }

 			if (JobActivity.StartDate__c != null && JobActivity.EndDate__c != null) {
                this.Duration    = JobActivity.EndDate__c.getTime() - JobActivity.StartDate__c.getTime();
            }
            else {
                this.Duration = 0;
            }
            this.JobTemplateId   = JobActivity.JobTemplate__c;
            this.JobTemplateName = JobActivity.JobTemplate__r.Name;
        }
    }
}