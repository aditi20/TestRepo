/**
*   Grameen: Salesforce - SF Field Force, SF - Jobs
*   Test for the controller of JobActivitiesList.
*   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*   @author Sebastian Piazza
*   @author Claudio Soto csoto@altimetrik.com
*/
@isTest
private class JobActivitiesListControllerTest {

     /**
     * Test method to verify loadObjectSelectList method is working correctly
     * must create a json object and then serialize it to a json string
     * this json object stores all the information from the objects from the org
     **/
    static testmethod  void getJobActivitiesTest(){

        // Create contact...
        Contact newContact  = new Contact();
        newContact.LastName = 'Last Name';
        insert newContact;

        // Create JobTemplate...
        JobTemplate__c newJobTemplate = new JobTemplate__c(Name = 'NameJobTemplate',
                                                        Status__c = JobTemplateDO.STATUS_DRAFT,
                                                        Hierarchy__c = '[]');
        insert newJobTemplate;

        // Job template with empty values...
        Job__c emptyJob         = new Job__c();
        emptyJob.Name           = 'emptyJob';
        emptyJob.Assigned__c    = newContact.Id;
        emptyJob.Contact__c     = newContact.Id;
        emptyJob.JobTemplate__c = newJobTemplate.Id;
        emptyJob.StartDate__c   = null;
        emptyJob.EndDate__c     = null;
        insert emptyJob;

        List<JobActivitiesListController.JobActivity>  listActivities = (List <JobActivitiesListController.JobActivity>) JobActivitiesListController.getJobActivities();

        system.assertEquals( JobActivitiesListController.UNDEFINED_VALUE, listActivities[0].Started );
        system.assertEquals( JobActivitiesListController.UNDEFINED_VALUE, listActivities[0].Finished );

        Job__c irrelevantJob         = new Job__c();
        irrelevantJob.Name           = 'irrelevantJob';
        irrelevantJob.Assigned__c    = newContact.Id;
        irrelevantJob.Contact__c     = newContact.Id;
        irrelevantJob.JobTemplate__c = newJobTemplate.Id;
        irrelevantJob.StartDate__c   = null;
        irrelevantJob.EndDate__c     = null;
        insert irrelevantJob;

        Job__c newJob         = new Job__c();
        newJob.Name           = 'nameJob';
        newJob.Assigned__c    = newContact.Id;
        newJob.Contact__c     = newContact.Id;
        newJob.JobTemplate__c = newJobTemplate.Id;
        newJob.StartDate__c   = Datetime.now();
        newJob.EndDate__c     = Datetime.now();
        insert newJob;

        Test.startTest();
            // Obtain the list of JobActivity from that variable.
            listActivities = JobActivitiesListController.getJobActivities();
        Test.stopTest();
        // Assert that three Job activities were created.
        system.assertEquals ( 3, listActivities.size() );

        // Obtain the last created JobActivity.
        JobActivitiesListController.JobActivity lastJobActivity;
        for(JobActivitiesListController.JobActivity jobAct : listActivities){
            if(jobAct.id == newJob.Id){
                lastJobActivity = jobAct;
            }
        }

        // And assert data of recently created Job.
        system.assertEquals ( newContact.Id, lastJobActivity.ClientId );
        system.assertEquals ( newContact.Id, lastJobActivity.StaffId );
        system.assertEquals ( newJobTemplate.Id, lastJobActivity.JobTemplateId );
        system.assertEquals ( newJob.StartDate__c.format('MM/dd/yyyy HH:mm'), lastJobActivity.Started);
        system.assertEquals ( newJob.EndDate__c.format('MM/dd/yyyy HH:mm'), lastJobActivity.Finished);
    }

    /**
     *  Test method for obtainMapTaskJobs method.
     */
    static testmethod void obtainMapTaskJobsTest(){

        // Set data...

        // Set survey data.
        Survey__c survey = TestUtils.createSurvey('Survey 1');

        SurveyVersion__c surveyVersion =[SELECT id FROM SurveyVersion__c WHERE Survey__c = :survey.id];

        // Create contact...
        Contact newContact = TestUtils.createContact('Last Name');

        // Create JobTemplate...
        JobTemplate__c newJobTemplate =
            JobTemplateDO.createJobTemplate('NameJobTemplate', JobTemplateDO.STATUS_DRAFT, '[]');
        insert newJobTemplate;

        // Create two tasks for that job template.
        TaskTemplate__c firstTask =
            TaskTemplateDO.createTaskTemplate(
                'Task 1', 1 , newJobTemplate.Id, TaskTemplateDO.TYPE_FORM, surveyVersion.Id
            );
        TaskTemplate__c secondTask =
            TaskTemplateDO.createTaskTemplate(
                'Task 2', 2 , newJobTemplate.Id, TaskTemplateDO.TYPE_FORM, surveyVersion.Id
            );
        insert new List<TaskTemplate__c>{firstTask, secondTask};

        // Create job activities.
        Job__c jobActivity =
            TestUtils.createJobActivity(
                'Job activity 1',
                newJobTemplate.Id,
                newContact.Id,
                newContact.Id,
                Datetime.now(),
                Datetime.now()
            );
        Job__c anotherJobActivity =
            TestUtils.createJobActivity(
                'Job activity 2',
                newJobTemplate.Id,
                newContact.Id,
                newContact.Id,
                Datetime.now(),
                Datetime.now()
            );
        Job__c yetAnotherJobActivity =
            TestUtils.createJobActivity(
                'Job activity 3',
                newJobTemplate.Id,
                newContact.Id,
                newContact.Id,
                Datetime.now(),
                Datetime.now()
            );

        // Create tasks activities (here is related Job__c and TaskTemplate__c).
        Task__c taskActivity =
            TestUtils.createTaskActivity(
                jobActivity.Id, Datetime.now(), Datetime.now(), firstTask.Id
            );
        Task__c secondTaskActivity =
            TestUtils.createTaskActivity(
                anotherJobActivity.Id, Datetime.now(), Datetime.now(), firstTask.Id
            );
        Task__c thirdTaskActivity =
            TestUtils.createTaskActivity(
                yetAnotherJobActivity.Id, Datetime.now(), Datetime.now(), secondTask.Id
            );

        JobActivitiesListController controller  = new JobActivitiesListController();
        Map<Id, Set<Id>> mapTasksJobs = controller.obtainMapTaskJobs();

        // Expected map:
        // firstTask  => [jobActivity.Id, anotherJobActivity.Id]
        // secondTask => [yetAnotherJobActivity.Id]
        Set<Id> jobsRelatedToFirstTask  = mapTasksJobs.get(firstTask.Id);

        // Contains jobActivity Id...
        system.assert( jobsRelatedToFirstTask.contains(jobActivity.Id), 'Should contain jobActivity Id...' );
        // Contains anotherJobActivity Id...
        system.assert( jobsRelatedToFirstTask.contains(anotherJobActivity.Id), 'Should anotherJobActivity Id...' );
        // Doesn't contains yetAnotherJobActivity Id.
        system.assert( !jobsRelatedToFirstTask.contains(yetAnotherJobActivity.Id), 'Should not contain yetAnotherJobActivity Id...');

        Set<Id> jobsRelatedToSecondTask = mapTasksJobs.get(secondTask.Id);
        // Contains yetAnotherJobActivity Id...
        system.assert( jobsRelatedToSecondTask.contains(yetAnotherJobActivity.Id), 'Should contain yetAnotherJobActivity Id...');
        // Doesn't contains jobActivity Id.
        system.assert( !jobsRelatedToSecondTask.contains(jobActivity.Id), 'Should not contain jobActivity Id...' );
        // Doesn't contains anotherJobActivity Id.
        system.assert( !jobsRelatedToSecondTask.contains(anotherJobActivity.Id), 'Should not contain anotherJobActivity Id...' );

    }
}