/**
 * Grameen: Salesforce - SF to Mobile Sync
 * Classes tested by this test class:
 *    - JobTemplateDO
 *    - TaskTemplateDO
 *    - TaroRESTJobTemplates
 *    - TaroRESTJobTemplatesLogic
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class TaroRESTJobTemplatesTest {

    // Constants
    private static Boolean OLD_PUBLISHED_JOB = true;
    private static Boolean NEW_PUBLISHED_JOB = false;
    private static Boolean DELETED_FIELD = true;
    private static Boolean DELETED_OBJECT = false;
    private static final String CONTACT_OBJECT_ID = 'ejnm';
    private static final String CASE_OBJECT_ID = 'j8ji';

    // The list of questions for the default survey
    private static List<Question__c> defaultQuestions = new List<Question__c>();

    /**
     * Helper method to create some contacts and cases to use in the tests
     */
    private static void createContactsAndCases() {

        // Create the contacts
        List<Contact> contacts = TestUtils.createContacts(3);

        // Create cases. 2 for each contact
        TestUtils.createCasesForContacts(contacts);
        TestUtils.createCasesForContacts(contacts);
    }

    /**
     * Helper method to change the status of a list of jobs
     *
     * @param jobsToPublish - A list of jobs to publish
     * @param status        - The new status for the jobs
     */
    private static void changeJobsStatus(List<JobTemplate__c> jobsToChange, String status) {

        for(JobTemplate__c job : jobsToChange) {
            job.Status__c = status;
        }
        update jobsToChange;
    }

    /**
     * Helper method to create a job using the page controller
     *
     * @param form         - The survey version to use as a form in the Collect task
     * @param questionName - The name of a question of that survey to use in the mapping of the Collect task
     *
     * @return - A job template with a hierarchy (Contact <- Case) and two tasks,
     *             one Collect with a mapping for the field AssistantName and one
     *             data view related to Contact
     */
    private static JobTemplate__c createJobTemplateWithPage(SurveyVersion__c form, String questionName) {

        // Create enviroment
        JobTemplate__c jobTemplate = new JobTemplate__c();
        ApexPages.Standardcontroller stdController = new ApexPages.StandardController(jobTemplate);
        CreateJobTemplateController controller = new CreateJobTemplateController(stdController);

        // Set the job data
        jobTemplate.Name = 'newJob ' + Crypto.getRandomInteger();
        jobTemplate.Instructions__c = 'Instructions';
        jobTemplate.Hierarchy__c =
            '[{' +
                '"listFields":["Birthdate"], ' +
                '"detailFields":["AssistantName"], ' +
                '"objectName":"Contact", ' +
                '"objectId":"' + CONTACT_OBJECT_ID + '", ' +
                '"label":"Contact"' +
             '}, {'+
                '"listFields":["Id"], ' +
                '"detailFields":["CaseNumber", "Id"], ' +
                '"objectName":"Case", ' +
                '"objectId":"' + CASE_OBJECT_ID + '", ' +
                '"label":"Case", ' +
                '"relations":[{"parent":"' + CONTACT_OBJECT_ID + '", "field":"ContactId"}]' +
            '}]';

        // Set the tasks data
        controller.jsonTasksList =
            '[{' +
                '"Type":"' + TaskTemplateDO.TYPE_FORM + '", ' +
                '"Name":"Task 1 - ' + Crypto.getRandomInteger() + '", ' +
                '"instructions":"Some instructions", ' +
                '"Position":1, ' +
                '"Form":"' + form.Id + '", ' +
                '"Action":"' + TaskTemplateDO.ACTION_EDITED_ADDED + '", ' +
                '"Mapping":"[{' +
                    '\\"objectId\\":\\"' + CONTACT_OBJECT_ID + '\\", ' +
                    '\\"field\\":\\"AssistantName\\", ' +
                    '\\"question\\":\\"' + questionName + '\\"' +
                '}]"' +
             '}, {' +
                '"Type":"' + TaskTemplateDO.TYPE_DATA_VIEW  + '", ' +
                '"Name":"Task 2 - ' + Crypto.getRandomInteger() + '", ' +
                '"instructions":"qwr2",' +
                '"Position":2, ' +
                '"objectId":"' + CASE_OBJECT_ID + '", ' +
                '"Action":"' + TaskTemplateDO.ACTION_EDITED_ADDED + '"' +
             '}]';

        PageReference ref = controller.save();
        return jobTemplate;
    }

    /**
     * Helper method to prepare the needed data for the end-to-end tests
     *
     * @param jobStatus     - Indicates the status for the job templates that will be created, if null will leave some
     *                          jobs in each status
     * @param  previousSync - The date to be sent as the previous sync in the request
     *
     * @return - The list of jobs
     */
    private static List<JobTemplate__c> prepareEndToEndTest(
            String jobStatus,
            DateTime previousSync,
            TestUtils.Surveyor surveyor
    ) {

        // Create a form
        Survey__c survey = TestUtils.createSurvey('Some Survey');
        Question__c section = TestUtils.addSection(survey, 1, 'A section');
        Question__c question = TestUtils.addQuestion(section, 1, 'text1', QuestionDO.TYPE_TEXT_SHORT);

        // Publish the form that will be used
        SurveyVersion__c form = SurveyDO.publishSurvey(survey);

        // Set up some jobs
        List<JobTemplateWrapper> jobTemplateWrappers = new List<JobTemplateWrapper>();
        List<JobTemplate__c> jobTemplates = new List<JobTemplate__c>();
        for (Integer i = 0; i < 5; i ++) {
            JobTemplateWrapper wrapper = new JobTemplateWrapper();
            wrapper.initDefaultJob(null, null, null, null);
            jobTemplates.add(wrapper.getJobTemplate());
        }
        insert jobTemplates;
        List<TaskTemplate__c> taskTemplates = new List<TaskTemplate__c>();
        for (JobTemplate__c jobTemplate : jobTemplates) {
            JobTemplateWrapper wrapper = new JobTemplateWrapper();
            wrapper.setJobTemplate(jobTemplate);
            taskTemplates.add(wrapper.initDataCollectionTemplate(
                form.Id,
                'text1',
                jobTemplate.Id,
                1,
                Crypto.getRandomInteger()
            ));
            taskTemplates.add(wrapper.initDataViewTemplate(CASE_OBJECT_ID, 2));
        }
        insert taskTemplates;

        // Check that the jobs were saved
        System.assertEquals(5, [SELECT Id FROM JobTemplate__c WHERE Id IN :jobTemplates].size());
        if (jobStatus == null) {

            // Publish two jobs
            changeJobsStatus(
                new List<JobTemplate__c>{
                    jobTemplates[1],
                    jobTemplates[2]
                },
                JobTemplateDO.STATUS_PUBLISHED
            );

            // Close two jobs
            changeJobsStatus(
                new List<JobTemplate__c>{
                    jobTemplates[3],
                    jobTemplates[4]
                },
                JobTemplateDO.STATUS_CLOSED
            );
        } else {

            // Change the status of the jobs
            changeJobsStatus(jobTemplates, jobStatus);
        }

        // Fetch the status of the jobs
        jobTemplates = [
            SELECT
                Id,
                Name,
                Status__c,
                Instructions__c,
                Hierarchy__c
            FROM
                JobTemplate__c
            WHERE
                Id IN :jobTemplates
        ];

        // Prepare the request without known jobs
        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody =
            prepareTaroRequest(new List<JobTemplate__c>(), previousSync);

        // Prepare the request
        prepareTestData(surveyor, JSON.serialize(requestBody));

        // Create some contacts and cases
        createContactsAndCases();

        // Relate the contacts as clients of the surveyor
        assignContactToClient(surveyor.partnerUser.ContactId);
        return jobTemplates;
    }

    /**
     * Helper method to prepare the test data
     * It creates the needed objects and sets the request
     *
     * @param surveyorExists - A flag that indicates if a surveyor exists or not
     * @param requestBody    - A string with the content for the request body
     */
    private static TestUtils.Surveyor prepareTestData(
            TestUtils.Surveyor surveyor,
            String requestBody
    ) {

        // Create the Surveyor as needed and log them in
        if (surveyor == null) {
            surveyor = TestUtils.createPartnerSurveyor('lastNameTRJT', true);
            surveyor = TestUtils.partnerLoginDetails(surveyor);
        }

        // Prepare the request data
        String serviceUrl = TestUtils.getServiceUrl('jobtemplates');
        Map<String, String> headersMap = new Map<String, String>{
            C.SESSION_TOKEN_HEADER => surveyor.loginResult.getSessionToken(),
            C.DEVICE_ID_HEADER => 'deviceId'
        };
        TestUtils.prepareRestContext(serviceUrl, Blob.valueOf(requestBody), headersMap);
        return surveyor;
    }

    /**
     * Helper method to build some mappings for a task
     *
     * @param objectHierarchy - A list of JobTemplateDo.ObjectHierarchy
     * @param surveyQuestions - A list of mappable questions
     *
     * @return A JSON string with the mappings
     */
    private static String createMappings(
            List<JobTemplateDo.ObjectHierarchy> objectHierarchy,
            List<Question__c> surveyQuestions
    ) {

        List<TaskTemplateDO.Mapping> mappings = new List<TaskTemplateDO.Mapping>();

        // Loop over the hierarchy objects
        // Assumes that the hierarchy list is smaller than the questions list
        Integer i = 0;
        for (JobTemplateDo.ObjectHierarchy hierarchy : objectHierarchy) {
            mappings.add(
                new TaskTemplateDO.Mapping(hierarchy.objectId, hierarchy.listFields[0], surveyQuestions[i].Name)
            );
            i++;
        }

        return JSON.serialize(mappings);
    }

    /**
     * Generate Job Templates and save them
     *
     * @param amount - The amount of job templates to create
     *
     * @return A list with the created job templates
     */
    private static List<JobTemplate__c> createJobTemplates(Integer amount) {

        String submissionApiName = Submission__c.SObjectType.getDescribe().getName();
        String submissionPpiValueApiName =
            SubmissionPPIValue__c.SObjectType.getDescribe().getName();
        String surveyorFieldApiName = Submission__c.Surveyor__c.getDescribe().getName();
        String submissionFieldApiName =
            SubmissionPPIValue__c.Submission__c.getDescribe().getName();


        // Create job templates
        List<JobTemplate__c> jobTemplates = new List<JobTemplate__c>();

        // Add a hierarchy to the job templates
        // Hierarchy is not chequed since it is checked on the corresponding class.
        // It is included to ake sure that the whole process works correctly
        List<JobTemplateDo.ObjectHierarchy> jobTempHier1 = new List<JobTemplateDo.ObjectHierarchy>();
        JobTemplateDo.ObjectHierarchy oh1 = new JobTemplateDo.ObjectHierarchy('1', 'Field Officer', 'Contact');
        oh1.addListField('Name');
        oh1.addListField('Id');
        JobTemplateDo.ObjectHierarchy oh2 = new JobTemplateDo.ObjectHierarchy('2', 'Submission', submissionApiName);
        oh2.addListField('Name');
        oh2.addDetailField('Name');
        oh2.addDetailField('Id');
        oh2.addDetailField('CreatedDate');
        oh2.addRelation('1', surveyorFieldApiName);
        JobTemplateDo.ObjectHierarchy oh3 = new JobTemplateDo.ObjectHierarchy('3', 'Submission PPI Value', submissionPpiValueApiName);
        oh3.addListField(submissionFieldApiName);
        oh3.addRelation('2', submissionFieldApiName);
        jobTempHier1.add(oh1);
        jobTempHier1.add(oh2);
        jobTempHier1.add(oh3);

        for (Integer i = 0; i < amount - 1; i++) {
            jobTemplates.add(new JobTemplate__c(
                Name = 'JobTemp' + Crypto.getRandomInteger(),
                Status__c = JobTemplateDO.STATUS_DRAFT,
                Hierarchy__c = JSON.serialize(jobTempHier1))
            );
        }

        // Add a job template without hierarchy
        JobTemplate__c jobWithoutHierarchy = new JobTemplate__c(
            Name = 'JobTemp' + Crypto.getRandomInteger(),
            Status__c = JobTemplateDO.STATUS_DRAFT
        );
        jobTemplates.add(jobWithoutHierarchy);
        insert jobTemplates;

        // Create a survey for the form tasks
        Survey__c survey = TestUtils.createSurvey('survey' + Crypto.getRandomInteger());
        Question__c section = TestUtils.addQuestion(survey, 1, 'Section1', QuestionDO.TYPE_SECTION);
        List<Question__c> questions = new List<Question__c>();
        for (Integer i = 1; i < 4; i++) {
            questions.add(TestUtils.addQuestion(section, i, 'Question' + i, QuestionDO.TYPE_TEXT_SHORT));
        }

        // Publish the survey
        SurveyVersion__c version = [SELECT Id FROM SurveyVersion__c WHERE Survey__c = :survey.Id];
        version.Status__c = SurveyDO.STATUS_PUBLISHED;
        update version;

        // Create the tasks for the job templates
        List<TaskTemplate__c> taskTemplates = new List<TaskTemplate__c>();
        for (JobTemplate__c jobTemplate : jobTemplates) {
            if (jobTemplate.Id != jobWithoutHierarchy.Id) {

                // Add a form task
                taskTemplates.add(new TaskTemplate__c(
                    Name = jobTemplate.Name + '_taskForm',
                    JobTemplate__c = jobTemplate.Id,
                    Position__c = 1,
                    Type__c = TaskTemplateDO.TYPE_FORM,
                    Form__c = version.Id,
                    Mapping__c = createMappings(jobTempHier1, questions))
                );

                // Add a view data task
                taskTemplates.add(new TaskTemplate__c(
                    Name = jobTemplate.Name + '_taskView',
                    JobTemplate__c = jobTemplate.Id,
                    Position__c = 2,
                    Type__c = TaskTemplateDO.TYPE_DATA_VIEW,
                    Object__c = '2'
                ));
            }

            // Add a task without mappings
            taskTemplates.add(new TaskTemplate__c(
                Name = jobTemplate.Name + '_taskForm2',
                JobTemplate__c = jobTemplate.Id,
                Position__c = 1,
                Type__c = TaskTemplateDO.TYPE_FORM,
                Form__c = version.Id
            ));
        }
        insert taskTemplates;

        // Publish the job templates
        for (JobTemplate__c jobTemplate : jobTemplates) {
            jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        }
        update jobTemplates;

        return jobTemplates;
    }

    /**
     * Compare job templates objects to the JobTemplateResponse objects created from them
     */
    private static void compareJobTemplates(
        Map<Id, JobTemplate__c> jobTemplatesById,
        Map<Id, TaskTemplate__c> taskTemplatesById,
        List<JobTemplateDO.JobTemplateResponse> jobTemplatesResponses
    ) {
        for (JobTemplateDO.JobTemplateResponse jobTemplates : jobTemplatesResponses) {
            JobTemplate__c originalJobTemplate = jobTemplatesById.get(jobTemplates.jobTemplateId);

            if(originalJobTemplate != null) {
                // Build the error message just in case
                String failMessage = 'Failed comparing JobTemplate__c ' + originalJobTemplate +
                    ' with JobTemplateDO ' + jobTemplates;

                // Check job template values for any response
                System.assertEquals(originalJobTemplate.Id, jobTemplates.jobTemplateId, failMessage);
                System.assertEquals(originalJobTemplate.Status__c, jobTemplates.status, failMessage);

                // If is a full response check the rest of the fields and the tasks
                JobTemplateDO.JobTemplateResponseFull fullResponse;
                try {
                    fullResponse = (JobTemplateDO.JobTemplateResponseFull) jobTemplates;
                    System.assertEquals(originalJobTemplate.Name, fullResponse.name, failMessage);
                    System.assertEquals(originalJobTemplate.Instructions__c, fullResponse.instructions, failMessage);
                    if (fullResponse.hierarchy != null) {
                        System.assertEquals(
                            originalJobTemplate.Hierarchy__c,
                            JSON.serialize(fullResponse.hierarchy),
                            failMessage
                        );
                    }

                    System.assertEquals(taskTemplatesById.size(), fullResponse.taskTemplates.size());

                    // Check task templates values for any task type
                    // There are specific tests for each task type
                    for (TaskTemplateDO.TaskTemplateResponse taskTemplate : fullResponse.taskTemplates) {
                        TaskTemplate__c originalTaskTemplate = taskTemplatesById.get(taskTemplate.taskTemplateId);

                        // Complete the error message info
                        failMessage = failMessage + ' on TaskTemplate__c ' + originalTaskTemplate +
                            ' with TaskTemplateDO ' + taskTemplate;

                        System.assertEquals(originalTaskTemplate.Name, taskTemplate.name, failMessage);
                        System.assertEquals(originalTaskTemplate.Position__c, taskTemplate.position, failMessage);
                        System.assertEquals(originalTaskTemplate.Type__c, taskTemplate.taskTemplateType, failMessage);
                        System.assertEquals(
                            originalTaskTemplate.Instructions__c,
                            taskTemplate.instructions,
                            failMessage
                        );
                    }
                }
                catch(TypeException e) {
                    // Just catching it to avoid an error message
                }
            }
        }
    }

    /**
     * Build the Taro request
     *
     * @param jobTemplates - A list of job templates as the known jobs for the request
     * @param isFirstSync  - Indicates if the request is for the first sync
     *
     * @return An instance of TaroRequestBody
     */
    private static TaroRESTJobTemplatesLogic.TaroRequestBody prepareTaroRequest(List<JobTemplate__c> jobTemplates, DateTime previousSync) {

        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody = new TaroRESTJobTemplatesLogic.TaroRequestBody();
        List<TaroRESTJobTemplatesLogic.KnownJobTemplate> knownJobTemplates = new List<TaroRESTJobTemplatesLogic.KnownJobTemplate>();

        requestBody.lastSync = previousSync;
        for (JobTemplate__c jobTemplate : jobTemplates) {
            knownJobTemplates.add(new TaroRESTJobTemplatesLogic.KnownJobTemplate(jobTemplate.Id, jobTemplate.Status__c));
        }
        requestBody.jobTemplates = knownJobTemplates;
        return requestBody;
    }

    /**
     * Test time stamp with same regional settings
     */
    static testMethod void testSameRegionalSettings() {

        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody =
            prepareTaroRequest(new List<JobTemplate__c>(), DateTime.now().addDays(-1));
        prepareTestData(null, JSON.serialize(requestBody));

        Test.startTest();

        // Parse the body of the request
        TaroRESTJobTemplatesLogic.TaroRequestBody taroBody =
            (TaroRESTJobTemplatesLogic.TaroRequestBody)JSON.deserialize(
                RestContext.request.requestBody.toString(),
                TaroRESTJobTemplatesLogic.TaroRequestBody.class
            );
        Test.stopTest();
        System.assertEquals(requestBody.lastSync, taroBody.lastSync);
    }

    /**
     * Test time stamp with different regional settings
     */
    static testMethod void testDifferentRegionalSettings() {

        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody = prepareTaroRequest(new List<JobTemplate__c>(), DateTime.now().addDays(-1));
        prepareTestData(null, JSON.serialize(requestBody));

        User foreignUser = TestUtils.createPartnerUserNotInserted();

        // Change the timezone settings
        foreignUser.TimezonesIdKey = 'Pacific/Niue';
        Test.startTest();
        System.runAs(foreignUser) {

            // Parse the body of the request
            TaroRESTJobTemplatesLogic.TaroRequestBody taroBody = (TaroRESTJobTemplatesLogic.TaroRequestBody)JSON.deserialize(
                RestContext.request.requestBody.toString(),
                TaroRESTJobTemplatesLogic.TaroRequestBody.class
            );

            System.assertEquals(requestBody.lastSync, taroBody.lastSync);
        }
        Test.stopTest();
    }

    /**
     * Test the status update of jobs
     */
    static testMethod void testStatusUpdate() {

        // Create some job templates
        List<JobTemplate__c> jobTemplates = createJobTemplates(5);

        // Prepare Taro request
        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody = prepareTaroRequest(jobTemplates, DateTime.now().addDays(1));

        // Update the first two job templates
        jobTemplates[0].Status__c = JobTemplateDO.STATUS_CLOSED;
        jobTemplates[1].Status__c = JobTemplateDO.STATUS_CLOSED;
        upsert jobTemplates;

        // Needed set to check the results
        Set<Id> updatedJobTemplates = new Set<Id>{jobTemplates[0].Id, jobTemplates[1].Id};

        // Prepare the request
        TestUtils.Surveyor surveyor = prepareTestData(null, JSON.serialize(requestBody));

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response =
            (TaroRESTJobTemplatesLogic.TaroResponseBody) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                TaroRESTJobTemplatesLogic.TaroResponseBody.class
            );

        System.assertEquals(2, response.jobTemplates.size(), 'This must have only the two changed job templates');

        System.assert(updatedJobTemplates.contains(response.jobTemplates[0].jobTemplateId),
                      'The job template with id ' + response.jobTemplates[0].jobTemplateId +
                      ' was incuded in the response but should not be included.');
        System.assert(updatedJobTemplates.contains(response.jobTemplates[1].jobTemplateId),
                      'The job template with id ' + response.jobTemplates[1].jobTemplateId +
                      ' was incuded in the response but should not be included.');

        // Check job templates values
        System.assertEquals(JobTemplateDO.STATUS_CLOSED, response.jobTemplates[0].status,
                            'The status of the updated job templates must be "Closed"');

        // Since the jobs are only updates, shouldn't be able to
        // cast to JobTemplateDO.JobTemplateResponseFull
        try {
            JobTemplateDO.JobTemplateResponseFull response1 =
                (JobTemplateDO.JobTemplateResponseFull) response.jobTemplates[0];

            System.assert(false, 'This should fail because the jobs shouldn\'t be full');
        }
        catch(TypeException e) {
            System.assert(
                e.getMessage().contains(
                    'Invalid conversion from runtime type ' +
                    JobTemplateDO.JobTemplateResponse.class + ' to ' +
                    JobTemplateDO.JobTemplateResponseFull.class
                )
            );
        }

        System.assertEquals(JobTemplateDO.STATUS_CLOSED, response.jobTemplates[1].status,
                            'The status of the updated job templates must be "Closed"');

        // Since the jobs are only updates, shouldn't be able to
        // cast to JobTemplateDO.JobTemplateResponseFull
        try {
            JobTemplateDO.JobTemplateResponseFull response1 =
                (JobTemplateDO.JobTemplateResponseFull) response.jobTemplates[1];

            System.assert(false, 'This should fail because the jobs shouldn\'t be full');
        }
        catch(TypeException e) {
            System.assert(
                e.getMessage().contains(
                    'Invalid conversion from runtime type ' +
                    JobTemplateDO.JobTemplateResponse.class + ' to ' +
                    JobTemplateDO.JobTemplateResponseFull.class
                )
            );
        }
    }

    /**
     * Test the addition of job templates
     */
    static testMethod void testJobTemplatesAddition() {


        // Create some job templates
        List<JobTemplate__c> jobTemplates = createJobTemplates(2);

        // Prepare Taro request
        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody =
            prepareTaroRequest(jobTemplates, DateTime.now().addDays(-1));

        // Prepare the request
        TestUtils.Surveyor surveyor = prepareTestData(null, JSON.serialize(requestBody));

        // Add two job templates
        List<JobTemplate__c> newJobTemplates = createJobTemplates(2);

        // Needed maps to check the results
        Map<Id, JobTemplate__c> jobTemplatesById = new Map<Id, JobTemplate__c>([
            SELECT
                Id,
                Name,
                Instructions__c,
                Status__c,
                Hierarchy__c,
                CreatedDate
            FROM
                JobTemplate__c
            WHERE
                Id IN :newJobTemplates
        ]);

        Map<Id, TaskTemplate__c> taskTemplatesById = new Map<Id, TaskTemplate__c>([
            SELECT
                Id,
                Name,
                Type__c,
                Position__c,
                Instructions__c,
                Object__c,
                Form__c,
                Form__r.Name,
                Mapping__c
            FROM
                TaskTemplate__c
            WHERE
                JobTemplate__c IN :newJobTemplates
        ]);


        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        System.assertEquals(2, response.jobTemplates.size(), 'This must have only the two new job templates');
        compareJobTemplates(jobTemplatesById, taskTemplatesById, response.jobTemplates);
    }

    /**
     * Test sync with a null lastsync and no existing job ids to test first sync on install
     * This test is for the case where there isn't any job in salesforce
     */
    static testMethod void testFirstSyncNoJobs() {

        // Prepare the request without known jobs
        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody = prepareTaroRequest(new List<JobTemplate__c>(), null);

        // Prepare the request
        prepareTestData(null, JSON.serialize(requestBody));

        User taroWorksPartnerUser = TestUtils.createPartnerUserNotInserted();

        // Run the test
        Test.startTest();
        System.runAs(taroWorksPartnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        System.assertEquals(0, response.jobTemplates.size(), 'No jobs should be fetched: ' + response.jobTemplates);
        System.assertEquals(0, response.metadata.size(), 'No metadata should be fetched: ' + response.metadata);
        System.assertEquals(0, response.removedObjects.size(), 'No removed objects should be fetched: ' + response.removedObjects);
        System.assertEquals(0, response.instances.size(), 'No instances should be fetched: ' + response.instances);
        System.assertEquals('Partner User', response.user.lastName);
    }

    /**
     * Test sync with a null lastsync and no existing job ids to test first sync on install
     * This test is for the case where only draft jobs are in salesforce
     */
    static testMethod void testFirstSyncDraftJobs() {

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('lastNameSCT', true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);
        prepareEndToEndTest(JobTemplateDO.STATUS_DRAFT, null, surveyor);

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        System.assertEquals(0, response.jobTemplates.size(), 'No jobs should be fetched: ' + response.jobTemplates);
        System.assertEquals(0, response.metadata.size(), 'No metadata should be fetched: ' + response.metadata);
        System.assertEquals(0, response.removedObjects.size(), 'No removed objects should be fetched: ' + response.removedObjects);
        System.assertEquals(0, response.instances.size(), 'No instances should be fetched: ' + response.instances);
    }

    /**
     * Test sync with a null lastsync and no existing job ids to test first sync on install
     * This test is for the case where only published jobs are in salesforce
     */
    static testMethod void testFirstSyncPublishedJobs() {

        UserTH.setSkipValidation(true);
        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('lastNameSCT', true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);
        prepareEndToEndTest(JobTemplateDO.STATUS_PUBLISHED, null, surveyor);

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        System.assertEquals(5, response.jobTemplates.size(),'All five jobs should be fetched: ' + response.jobTemplates);
        System.assertEquals(2, response.metaData.size(),
            'The two objects included in the hierarchy must be included: ' + response.metaData
        );
        System.assertEquals(0, response.removedObjects.size(), 'There should not be removed objects: ' + response.removedObjects);
        System.assertEquals(9, response.instances[0].getRecords().size() + response.instances[1].getRecords().size(),
            'There should be 3 contacts with 2 cases each: ' + response.instances
        );
    }

    /**
     * Test sync with a null lastsync and no existing job ids to test first sync on install
     * This test is for the case where only closed jobs are in salesforce
     */
    static testMethod void testFirstSyncClosedJobs() {

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('lastNameSCT', true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);
        prepareEndToEndTest(JobTemplateDO.STATUS_CLOSED, null, surveyor);

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        System.assertEquals(0, response.jobTemplates.size(), 'No jobs should be fetched: ' + response.jobTemplates);
        System.assertEquals(0, response.metadata.size(), 'No metadata should be fetched: ' + response.metadata);
        System.assertEquals(0, response.removedObjects.size(), 'No removed objects should be fetched: ' + response.removedObjects);
        System.assertEquals(0, response.instances.size(), 'No instances should be fetched: ' + response.instances);
    }

    /**
     * Test sync with a null lastsync and no existing job ids to test first sync on install
     * This test is for the case where there are jobs in all of the possible statuses in salesforce
     */
    static testMethod void testFirstSyncAllJobsStatus() {

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('lastNameSCT', true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);
        prepareEndToEndTest(null, null, surveyor);

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        System.assertEquals(2, response.jobTemplates.size(), 'All five jobs should be fetched: ' + response.jobTemplates);
        System.assertEquals(2, response.metaData.size(),
            'The two objects included in the hierarchy must be included: ' + response.metaData
        );
        System.assertEquals(0, response.removedObjects.size(), 'There should not be removed objects: ' + response.removedObjects);
        System.assertEquals(9, response.instances[0].getRecords().size() + response.instances[1].getRecords().size(),
            'There should be 3 contacts with 2 cases each: ' + response.instances
        );
    }

    /**
     * Test sync with some lastsync and no existing job ids to test second sync without data
     * This test is for the case where there isn't any job in salesforce
     */
    static testMethod void testSyncNoJobs() {

        // Prepare the request without known jobs
        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody = prepareTaroRequest(new List<JobTemplate__c>(), DateTime.now().addDays(-1));

        // Prepare the request
        TestUtils.Surveyor surveyor = prepareTestData(null, JSON.serialize(requestBody));

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        System.assertEquals(0, response.jobTemplates.size(), 'No jobs should be fetched: ' + response.jobTemplates);
        System.assertEquals(0, response.metadata.size(), 'No metadata should be fetched: ' + response.metadata);
        System.assertEquals(0, response.removedObjects.size(), 'No removed objects should be fetched: ' + response.removedObjects);
        System.assertEquals(0, response.instances.size(), 'No instances should be fetched: ' + response.instances);
    }

    /**
     * Test sync with some lastsync and no existing job ids to test second sync without data
     * This test is for the case where only draft jobs are in salesforce
     */
    static testMethod void testSyncDraftJobs() {

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('lastNameSCT', true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);
        prepareEndToEndTest(JobTemplateDO.STATUS_DRAFT, DateTime.now().addDays(-1), surveyor);

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        System.assertEquals(0, response.jobTemplates.size(), 'No jobs should be fetched: ' + response.jobTemplates);
        System.assertEquals(0, response.metadata.size(), 'No metadata should be fetched: ' + response.metadata);
        System.assertEquals(0, response.removedObjects.size(), 'No removed objects should be fetched: ' + response.removedObjects);
        System.assertEquals(0, response.instances.size(), 'No instances should be fetched: ' + response.instances);
    }

    /**
     * Test sync with some lastsync and no existing job ids to test the second sync without data
     * Also test to re-sync after another job was published
     * This test is for the case where only published jobs are in salesforce
     */
    static testMethod void testSyncPublishedJobs() {

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('lastNameSCT', true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);
        List<JobTemplate__c> jobTemplates =
            prepareEndToEndTest(JobTemplateDO.STATUS_PUBLISHED, DateTime.now().addDays(-1), surveyor);

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response =
            (TaroRESTJobTemplatesLogic.TaroResponseBody) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                TaroRESTJobTemplatesLogic.TaroResponseBody.class
            );

        System.assertEquals(
            5,
            response.jobTemplates.size(),
            'All five jobs should be fetched: ' + response.jobTemplates
        );
        System.assertEquals(
            2,
            response.metaData.size(),
            'The two objects included in the hierarchy must be included: ' + response.metaData
        );
        System.assertEquals(
            0,
            response.removedObjects.size(),
            'There should not be removed objects: ' + response.removedObjects
        );
        System.assertEquals(
            9,
            response.instances[0].getRecords().size() + response.instances[1].getRecords().size(),
            'There should be 3 contacts with 2 cases each: ' + response.instances
        );


        //-----------------------------------------------
        // Test re-sync after another job was published
        //-----------------------------------------------
        // Create some new jobs and publish them
        List<JobTemplate__c> newJobs = createJobTemplates(2);

        // Prepare Taro request
        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody2 =
            prepareTaroRequest(jobTemplates, DateTime.now().addDays(-1));

        // Add the already downloaded instances to the request
        GenerateInstanceData.KnownInstance contactInstance =
            new GenerateInstanceData.KnownInstance('Contact');
        GenerateInstanceData.KnownInstance caseInstance =
            new GenerateInstanceData.KnownInstance('Case');

        for(Contact client : [SELECT Id, (SELECT Id FROM Cases)
                              FROM Contact
                              WHERE Id NOT IN (SELECT Contact__c FROM Mobile_User__c)]
        ) {
            contactInstance.records.add(client.Id);
            for(Case aCase : client.Cases) {
                caseInstance.records.add(aCase.Id);
            }
        }
        requestBody2.instances = new List<GenerateInstanceData.KnownInstance>{
            contactInstance,
            contactInstance
        };

        // Prepare the request
        prepareTestData(null, JSON.serialize(requestBody2));

        // Run the test
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response2 =
            (TaroRESTJobTemplatesLogic.TaroResponseBody) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                TaroRESTJobTemplatesLogic.TaroResponseBody.class
            );

        System.assertEquals(
            2,
            response2.jobTemplates.size(),
            'Only the new jobs should be fetched: ' + response2.jobTemplates
        );
        System.assertEquals(
            4,
            response2.metaData.size(),
            'No metadata should be included: ' + response2.metaData
        );
        System.assertEquals(
            0,
            response2.removedObjects.size(),
            'There should not be removed objects: ' + response2.removedObjects
        );
        System.assertEquals(
            9,
            response2.instances[0].getRecords().size() +
            response2.instances[1].getRecords().size() +
            response2.instances[2].getRecords().size() +
            response2.instances[3].getRecords().size()
        );
    }

    /**
     * Test sync with some lastsync and no existing job ids to test the second sync without data
     * This test is for the case where only closed jobs are in salesforce
     */
    static testMethod void testSyncClosedJobs() {

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('lastNameSCT', true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);
        prepareEndToEndTest(JobTemplateDO.STATUS_CLOSED, DateTime.now().addDays(-1), surveyor);

        User taroWorksPartnerUser = TestUtils.createPartnerUserNotInserted();

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        System.assertEquals(0, response.jobTemplates.size(), 'No jobs should be fetched: ' + response.jobTemplates);
        System.assertEquals(0, response.metadata.size(), 'No metadata should be fetched: ' + response.metadata);
        System.assertEquals(0, response.removedObjects.size(), 'No removed objects should be fetched: ' + response.removedObjects);
        System.assertEquals(0, response.instances.size(), 'No instances should be fetched: ' + response.instances);
    }

    /**
     * Test sync with some lastsync and no existing job ids to test the second sync without data
     * This test is for the case where there are jobs in all of the possible statuses in salesforce
     */
    static testMethod void testSyncAllJobsStatus() {

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('lastNameSCT', true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);
        prepareEndToEndTest(null, DateTime.now().addDays(-1), surveyor);

        User taroWorksPartnerUser = TestUtils.createPartnerUserNotInserted();

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        System.assertEquals(2, response.jobTemplates.size(), 'All five jobs should be fetched: ' + response.jobTemplates);
        System.assertEquals(2, response.metaData.size(), 'The two objects included in the hierarchy must be included: ' + response.metaData);
        System.assertEquals(0, response.removedObjects.size(), 'There should not be removed objects: ' + response.removedObjects);
        System.assertEquals(9, response.instances[0].getRecords().size() + response.instances[1].getRecords().size(),
            'There should be 3 contacts with 2 cases each: ' + response.instances);
    }

    /**
     * Test sync with some job with missing mapped object, field or relation
     */
    static testMethod void testSyncFailJob() {

        // Create a survey
        Survey__c survey = TestUtils.createSurvey('Some Survey');
        Question__c section = TestUtils.addSection(survey, 1, 'A section');
        Question__c question = TestUtils.addQuestion(section, 1, 'text1', QuestionDO.TYPE_TEXT_SHORT);

        //Publish the version that will be used
        SurveyVersion__c version = [SELECT Id FROM SurveyVersion__c WHERE Survey__c = :survey.Id];
        version.Status__c = SurveyDO.STATUS_PUBLISHED;
        update version;

        // Set up some jobs
        JobTemplate__c job = new JobTemplate__c(
            Name = 'JobTemp2',
            Status__c = JobTemplateDO.STATUS_DRAFT,
            Instructions__c = 'Instructions'
        );
        insert job;

        TaskTemplate__c task = new TaskTemplate__c(
            Name = 'taskTemplate',
            JobTemplate__c = job.Id,
            Type__c = TaskTemplateDO.TYPE_FORM,
            Form__c = version.Id,
            Position__c = 1
        );
        insert task;

        // Publish job
        job.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        update job;

        // Create survey mapping with a fake object name that behave as a deleted object.
        String deletedObject = 'deletedObject';
        SurveyMapping__c sm = TestUtils.mapObject(survey, deletedObject);

        // Prepare the request without known jobs
        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody = prepareTaroRequest(new List<JobTemplate__c>(), DateTime.now().addDays(-1));

        // Prepare the request
        TestUtils.Surveyor surveyor = prepareTestData(null, JSON.serialize(requestBody));

        // Create some contacts and cases
        createContactsAndCases();

        // Relate the contacts as clients of the surveyor
        assignContactToClient(surveyor.partnerUser.ContactId);

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        // Test that the failed job was not sent
        System.assertEquals(0, response.jobTemplates.size(),
            'Jobs with missing objects, fields or relations, were not downloaded by mobile'
        );
    }


    /**
     * Test for the case where a new job uses fields in the hierarchy that were deleted
     * The job must be closed and not sent to the mobile
     */
    static testMethod void testNewJobDeletedFields() {
        testDeletedFieldsOrObjects(NEW_PUBLISHED_JOB, DELETED_FIELD);
    }

    /**
     * Test for the case where a new job uses an object in the hierarchy that was deleted
     * The job must be closed and not sent to the mobile
     */
    static testMethod void testNewJobDeletedObject() {
        testDeletedFieldsOrObjects(NEW_PUBLISHED_JOB, DELETED_OBJECT);
    }

    /**
     * Test for the case where an old job uses fields in the hierarchy that were deleted
     * The job must be closed and sent to the mobile as closed
     */
    static testMethod void testOldJobDeletedFields() {
        testDeletedFieldsOrObjects(OLD_PUBLISHED_JOB, DELETED_FIELD);
    }

    /**
     * Test for the case where an old job uses an object in the hierarchy that was deleted
     * The job must be closed and sent to the mobile as closed
     */
    static testMethod void testOldJobDeletedObject() {
        testDeletedFieldsOrObjects(OLD_PUBLISHED_JOB, DELETED_OBJECT);
    }

    /**
     * Test for the deletion of objects or fields
     *
     * @param  jobStatus         - Indicates what happened with the job before the sync
     * @param  deletionTypeField - Indicates if the deletion was of a field or object
     */
    static void testDeletedFieldsOrObjects(Boolean jobStatus, Boolean deletionTypeField) {
        // Create some job templates
        List<JobTemplate__c> jobTemplates = createJobTemplates(3);
        // Create a job with some field deleted

        // Create a hierarchy for the job
        List<JobTemplateDo.ObjectHierarchy> hierarchy = new List<JobTemplateDo.ObjectHierarchy>();
        JobTemplateDo.ObjectHierarchy oh1 = new JobTemplateDo.ObjectHierarchy('1', 'Field Officer', 'Contact');
        oh1.addListField('Name');
        oh1.addListField('Id');
        if(deletionTypeField) {
            oh1.addDetailField('NonExistentField');
        }
        else {
            JobTemplateDo.ObjectHierarchy oh2 = new JobTemplateDo.ObjectHierarchy(
                '2',
                'NonExistingObject',
                'NonExistentObject'
            );
            oh2.addListField('Name');
            hierarchy.add(oh2);
        }
        hierarchy.add(oh1);

        // Create the job
        JobTemplate__c newJob = new JobTemplate__c(
            Name = 'JobTemp' + Crypto.getRandomInteger(),
            Status__c = JobTemplateDO.STATUS_DRAFT,
            Hierarchy__c = JSON.serialize(hierarchy)
        );
        insert newjob;

        // Create a task for the job
        TaskTemplate__c task = new TaskTemplate__c(
            Name           = newJob.Name + '_taskView',
            JobTemplate__c = newJob.Id,
            Position__c    = 1,
            Type__c        = TaskTemplateDO.TYPE_DATA_VIEW,
            Object__c      = '1'
        );
        insert task;

        // Publish the job
        newJob.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        // Avoid validations on job update
        JobTemplateDO.setSkipUpdateValidation(true);
        update newJob;
        JobTemplateDO.setSkipUpdateValidation(false);

        jobTemplates.add(newJob);

        List<JobTemplate__c> jobsDownloaded = new List<JobTemplate__c>();
        if(jobStatus == OLD_PUBLISHED_JOB) {
            jobsDownloaded.add(newJob);
        }

        // Prepare Taro request
        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody =
            prepareTaroRequest(jobsDownloaded, DateTime.now().addDays(-1));

        // Prepare the request
        TestUtils.Surveyor surveyor =
            prepareTestData(null, JSON.serialize(requestBody));

        // Run the test
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        if (jobStatus == OLD_PUBLISHED_JOB) {

            // Test that the new job was sent
            System.assertEquals(4, response.jobTemplates.size());
            Boolean sent = false;
            for (JobTemplateDO.JobTemplateResponse jobResponse : response.jobTemplates) {
                if (jobResponse.jobTemplateId == newJob.Id) {
                    sent = true;
                }
            }
            System.assert(sent, 'The job should be sent');
        }
        else {

            // Test that the new job was not sent
            System.assertEquals(3, response.jobTemplates.size());
            for (JobTemplateDO.JobTemplateResponse jobResponse : response.jobTemplates) {
                if (jobResponse.jobTemplateId == newJob.Id) {
                    System.assert(false, 'The job with deleted fields shouldn\'t be sent');
                }
            }
        }

        // Test that the job was closed
        JobTemplate__c closedJob = [SELECT Id, Status__c, CloseReason__c FROM JobTemplate__c WHERE Id = :newJob.Id];
        System.assertEquals(JobTemplateDO.STATUS_CLOSED, closedJob.Status__c);
        System.assertEquals(JobTemplateDO.JOB_AUTOMATICALLY_CLOSED, closedJob.CloseReason__c);
    }

    /**
     * Create the default test hierarchy. This is based on Contact < Case objects and
     * sets up a relationship based on the Case.ContactId
     *
     * @param contactListFields   - The fields to include in the list fields for the Contact object.
     *                                Pass null to use defaults
     * @param contactDetailFields - The fields to include in the detail fields for the Contact object.
     *                                Pass null to use defaults
     * @param caseListFields      - The fields to include in the list fields for the Case object.
     *                                Pass null to use defaults
     * @param caseDetailFields    - The fields to include in the detail fields for the Contact object.
     *                                Pass null to use defaults
     *
     * @return - A JSON string representing the hierarchy
     */
    private static String createDefaultHierarchy(
        List<String> contactListFields,
        List<String> contactDetailFields,
        List<String> caseListFields,
        List<String> caseDetailFields
    ) {

        JobTemplateDO.ObjectHierarchy contactOH = new JobTemplateDO.ObjectHierarchy(
            CONTACT_OBJECT_ID, 'Contact', 'Contact'
        );

        // Add the list and detail fields
        contactOH.setListFields(contactListFields == null ? new List<String>{'Birthdate'} : contactListFields);
        contactOH.setDetailFields(contactDetailFields == null ? new List<String>{'AssistantName'} : contactDetailFields);

        JobTemplateDO.ObjectHierarchy caseOH = new JobTemplateDO.ObjectHierarchy(
            CASE_OBJECT_ID, 'Case', 'Case'
        );
        caseOH.setListFields(caseListFields == null ? new List<String>{'Id'} : caseListFields);
        caseOH.setDetailFields(caseDetailFields == null ? new List<String>{'Id', 'CaseNumber'} : caseDetailFields);
        caseOH.addRelation(CONTACT_OBJECT_ID, 'ContactId');

        return JSON.serialize(new List<JobTemplateDO.ObjectHierarchy>{contactOH, caseOH});
    }

    /**
     * Create a JobTemplateWrapper that works on the default hierarchy for Contact and Case.
     * This will have 3 TaskTemplate__c. One for each task type.
     * 1. data-view
     * 2. resource
     * 3. form - Will have a mapping to Case.Id from the created survey
     *
     * @return - The JobTemplateWrapper with default job set up
     */
    private static JobTemplateWrapper createDefaultJob() {

        JobTemplateWrapper jobTemplateWrapper = new JobTemplateWrapper();
        jobTemplateWrapper.createDefaultJob(null, null, null, null);
        jobTemplateWrapper.createDefaultDataViewTaskTemplate(CASE_OBJECT_ID);
        jobTemplateWrapper.createDefaultResourceTaskTemplate(CASE_OBJECT_ID);
        jobTemplateWrapper.createDefaultDataCollectionTask();
        return jobTemplateWrapper;
    }

    /**
     * Retrieve a list of JobTemplate__c based on ids
     *
     * @param ids - A list of the ids for the JobTemplate__c needed
     *
     * @return - A list that contains the JobTemplate__c requested if they exist
     */
    private static List<JobTemplate__c> getJobTemplates(List<Id> ids) {

        return [
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
                Id IN :ids
        ];
    }

    /**
     * Set up the jobTemplate and return the task needed based on type being tested
     *
     * @param taskType - The type of task being tested
     *
     * @return - The task template
     */
    private static TaskResourceWrapper setUpTaskTemplateTest(String taskType) {

        // Create the default JobTemplate
        JobTemplateWrapper createdJobTemplate = createDefaultJob();

        // Dig out the relevant task template
        return new TaskResourceWrapper([
            SELECT
                Id,
                Name,
                Instructions__c,
                JobTemplate__c,
                Mapping__c,
                Object__c,
                Position__c,
                ResourceId__c,
                Form__c,
                Type__c
            FROM
                TaskTemplate__c
            WHERE
                Type__c = :taskType
                AND JobTemplate__c = :createdJobTemplate.getJobTemplate().Id
        ], createdJobTemplate.getResourceMap().values()[0]);
    }

    /**
     * Test the creation of a JobTemplateResponseFull
     */
    static testMethod void testJobTemplateResponseFullCreation() {

        // Create the default JobTemplate
        JobTemplateWrapper createdJobTemplate = createDefaultJob();

        // Get the full JobTemplate__c out of the DB
        JobTemplate__c[] fetchedJobTemplates = getJobTemplates(
            new List<Id>{createdJobTemplate.getJobTemplate().Id}
        );

        System.assertEquals(1, fetchedJobTemplates.size());

        Test.startTest();

        // Create the job response
        JobTemplateDO.JobTemplateResponseFull response =
            JobTemplateDO.createJobTemplateResponseFull(fetchedJobTemplates[0], createdJobTemplate.getResourceMap());
        Test.stopTest();

        // Needed maps to check the results
        Map<Id, JobTemplate__c> jobTemplatesById = new Map<Id, JobTemplate__c> {
            createdJobTemplate.getJobTemplate().Id => createdJobTemplate.getJobTemplate()
        };

        Map<Id, TaskTemplate__c> taskTemplatesById = new Map<Id, TaskTemplate__c>([
            SELECT
                Id,
                Name,
                Type__c,
                Position__c,
                Instructions__c,
                Object__c,
                Form__c,
                Form__r.Name,
                Mapping__c
            FROM
                TaskTemplate__c
            WHERE
                JobTemplate__c = :createdJobTemplate.getJobTemplate().Id
        ]);

        // Compare the response and template
        compareJobTemplates(
            jobTemplatesById,
            taskTemplatesById,
            new List<JobTemplateDO.JobTemplateResponse> {response}
        );
    }

    /**
     * Test creating a TaskTemplateResponseDataView
     */
    static testMethod void testTaskTemplateResponseDataViewCreation() {

        TaskResourceWrapper taskResourceWrapper = setUpTaskTemplateTest(TaskTemplateDO.TYPE_DATA_VIEW);

        Test.startTest();

        // Create the data view response
        TaskTemplateDO.TaskTemplateResponseDataView response =
            (TaskTemplateDO.TaskTemplateResponseDataView)TaskTemplateDO.createTaskTemplateResponse(
                taskResourceWrapper.getTaskTemplate(), taskResourceWrapper.getResource()
            );
        Test.stopTest();

        // Test response
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Id, response.taskTemplateId);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Name, response.name);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Position__c, response.position);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Instructions__c, response.instructions);
        System.assertEquals(TaskTemplateDO.TYPE_DATA_VIEW, response.taskTemplateType);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Type__c, response.taskTemplateType);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Object__c, response.objectId);
    }

    /**
     * Test creation of a TaskTemplateResponseDataCollection
     */
    static testMethod void testTaskTemplateResponseDataCollectionCreation() {

        TaskResourceWrapper taskResourceWrapper = setUpTaskTemplateTest(TaskTemplateDO.TYPE_FORM);

        Test.startTest();

        // Create the data view response
        TaskTemplateDO.TaskTemplateResponseDataCollection response =
            (TaskTemplateDO.TaskTemplateResponseDataCollection)TaskTemplateDO.createTaskTemplateResponse(
                taskResourceWrapper.getTaskTemplate(), taskResourceWrapper.getResource()
            );
        Test.stopTest();

        // Test response
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Id, response.taskTemplateId);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Name, response.name);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Position__c, response.position);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Instructions__c, response.instructions);
        System.assertEquals(TaskTemplateDO.TYPE_FORM, response.taskTemplateType);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Type__c, response.taskTemplateType);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Form__c, response.formId);
    }

    /**
     * Test creation of a TaskTemplateResponseResource
     */
    static testMethod void testTaskTemplateResponseResourceCreation() {

        TaskResourceWrapper taskResourceWrapper = setUpTaskTemplateTest(TaskTemplateDO.TYPE_RESOURCE);

        Test.startTest();

        // Create the data view response
        TaskTemplateDO.TaskTemplateResponseResource response =
            (TaskTemplateDO.TaskTemplateResponseResource)TaskTemplateDO.createTaskTemplateResponse(
                taskResourceWrapper.getTaskTemplate(), taskResourceWrapper.getResource()
            );
        Test.stopTest();

        // Test response
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Id, response.taskTemplateId);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Name, response.name);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Position__c, response.position);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Instructions__c, response.instructions);
        System.assertEquals(TaskTemplateDO.TYPE_RESOURCE, response.taskTemplateType);
        System.assertEquals(taskResourceWrapper.getTaskTemplate().Type__c, response.taskTemplateType);
        System.assertEquals(taskResourceWrapper.getResource().ContentDocumentId, response.resourceId);
        System.assertEquals(taskResourceWrapper.getResource().VersionNumber, response.resourceVersion);
        System.assertEquals(taskResourceWrapper.getResource().Title, response.resourceTitle);
    }

    // Tests for job filtering
    /**
     * Create and publish two jobs. One with one owner and one with another
     *
     * @param publishJobs - Indicate if the created jobs should all be published once they have been created
     *
     * @return - The JobFilterTestWrapper that contains all the objects required to run the JobFilter tests
     */
    private static JobFilterTestWrapper createJobsForFilteringTests(Boolean publishJobs) {

        // Create the wrapper for the job filter tests
        JobFilterTestWrapper filterTestWrapper = new JobFilterTestWrapper();

        // Create a couple of users
        filterTestWrapper.createAdminUser();
        filterTestWrapper.createAdminUser();

        // Create a draft job with for the first user
        filterTestWrapper.createDefaultJobForUser(filterTestwrapper.getUserList()[0]);

        // Create a draft job for the second user
        filterTestWrapper.createDefaultJobForUser(filterTestwrapper.getUserList()[1]);

        // Create a mobile user for the first user
        filterTestWrapper.createPartnerSurveyor(filterTestWrapper.getUserFromMapByIndex(0));

        // Create a mobile user for the second user
        filterTestWrapper.createPartnerSurveyor(filterTestWrapper.getUserFromMapByIndex(1));

        // Publish the jobs if required
        if (publishJobs) {
            filterTestWrapper.forceStatusUpdateOnAllJobTemplates(JobTemplateDO.STATUS_PUBLISHED);
        }
        return filterTestWrapper;
    }

    /**
     * Set up the request for jobfiltering tests. Different from the above as more than one
     * mobile user created.
     *
     * @param surveyor     - The logged in surveyor who is performing the request
     * @param jobTemplates - A list of job templates as the known jobs for the request
     * @param isFirstSync  - Indicates if the request is for the first sync
     */
    private static void setUpJobFilteringRequest(
            TestUtils.Surveyor surveyor,
            List<JobTemplate__c> jobTemplates,
            DateTime previousSync
    ) {

        // Generate the request object
        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody = prepareTaroRequest(
            jobTemplates, previousSync
        );

        // Prepare the request data
        String serviceUrl = TestUtils.getServiceUrl('jobtemplates');
        Map<String, String> headersMap = new Map<String, String>{
            C.SESSION_TOKEN_HEADER => surveyor.loginResult.getSessionToken(),
            C.DEVICE_ID_HEADER => 'deviceId'
        };
        TestUtils.prepareRestContext(serviceUrl, Blob.valueOf(JSON.serialize(requestBody)), headersMap);
    }

    /**
     * Test with job filtering turned off. Should get all the jobs
     */
    static testMethod void testJobFilteringOff() {

        JobFilterTestWrapper filterTestWrapper = createJobsForFilteringTests(true);

        // Log the MobileUser for User 1 in to TaroWorks
        filterTestWrapper.logInPartnerUserForUser(filterTestWrapper.getUserFromMapByIndex(0).Id);
        TestUtils.Surveyor surveyor = filterTestWrapper.getSurveyorForUser(filterTestWrapper.getUserFromMapByIndex(0).Id);

        // Make sure the JobFiltering is turned off
        ApplicationSettingsUtils.setJobFilterSetting(ApplicationSettingsUtils.JOBS_FILTER_ALL);

        // Get the JobTemplates for the logged in Mobile User
        setUpJobFilteringRequest(
            surveyor,
            new List<JobTemplate__c>(),
            DateTime.now().addDays(-1)
        );

        // Run the test
        Test.startTest();

        // Make request
        System.runAs(surveyor.partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check that the response was successful
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        // Check that the response contains 2 published job templates
        System.assertEquals(2, response.jobTemplates.size());
        System.assertEquals(JobTemplateDO.STATUS_PUBLISHED, response.jobTemplates[0].status);
        System.assertEquals(JobTemplateDO.STATUS_PUBLISHED, response.jobTemplates[1].status);
    }

    /**
     * Test with the job filtering turned on. Should only get one record
     */
    static testMethod void testJobFilteringOn() {

        JobFilterTestWrapper filterTestWrapper = createJobsForFilteringTests(true);

        // Log the MobileUser for User 1 in to TaroWorks
        Id user1Id = filterTestWrapper.getUserList()[0];
        filterTestWrapper.logInPartnerUserForUser(user1Id);

        // Make sure the JobFiltering is turned on
        ApplicationSettingsUtils.setJobFilterSetting(ApplicationSettingsUtils.JOBS_FILTER_SF_USER);

        // Get the JobTemplates for the logged in Mobile User
        setUpJobFilteringRequest(
            filterTestWrapper.getSurveyorForUser(filterTestWrapper.getUserFromMapByIndex(0).Id),
            new List<JobTemplate__c>(),
            DateTime.now().addDays(-1)
        );

        // Run the test
        Test.startTest();

        // Make request
        System.runAs(filterTestWrapper.getSurveyorForUser(user1Id).partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check that the response was successful
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        // Check that the response contains 1 published job template
        System.assertEquals(1, response.jobTemplates.size());
        System.assertEquals(JobTemplateDO.STATUS_PUBLISHED, response.jobTemplates[0].status);

        // Check that it is the job that the Mobile User should have access to
        Id expectedFirstJobTempId =
            filterTestWrapper.getWrapperListForUser(user1Id)[0].getJobTemplate().Id;
        Id firstJobId = response.jobTemplates[0].jobTemplateId;
        System.assertEquals(expectedFirstJobTempId, firstJobId);
    }

    /**
     * Test turning the filtering off.
     * First sync should get 1 published job.
     * Second sync should get 1 published job that is different from the first
     */
    static testMethod void testTurningJobFilteringOff() {

        JobFilterTestWrapper filterTestWrapper = createJobsForFilteringTests(true);

        // Log the MobileUser for User 1 in to TaroWorks
        Id user1Id = filterTestWrapper.getUserList()[0];
        filterTestWrapper.logInPartnerUserForUser(user1Id);

        // Make sure the JobFiltering is turned on
        ApplicationSettingsUtils.setJobFilterSetting(ApplicationSettingsUtils.JOBS_FILTER_SF_USER);

        // Get the JobTemplates for the logged in Mobile User
        setUpJobFilteringRequest(
            filterTestWrapper.getSurveyorForUser(filterTestWrapper.getUserFromMapByIndex(0).Id),
            new List<JobTemplate__c>(),
            DateTime.now().addDays(-1)
        );

        // Make first request
        System.runAs(filterTestWrapper.getSurveyorForUser(user1Id).partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }

        // Check that the response was successful
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        // Check that the response contains 1 published job template and that it is the expected one
        Id expectedFirstJobTempId =
            filterTestWrapper.getWrapperListForUser(user1Id)[0].getJobTemplate().Id;
        System.assertEquals(1, response.jobTemplates.size());
        System.assertEquals(JobTemplateDO.STATUS_PUBLISHED, response.jobTemplates[0].status);

        // Check that it is the correct job template
        Id firstJobId = response.jobTemplates[0].jobTemplateId;
        System.assertEquals(expectedFirstJobTempId, firstJobId);

        // Turn job filtering off
        ApplicationSettingsUtils.setJobFilterSetting(ApplicationSettingsUtils.JOBS_FILTER_ALL);

        // Create the new request
        JobTemplate__c[] existingTemplates = [SELECT Id, Status__c FROM JobTemplate__c WHERE Id = :firstJobId];
        setUpJobFilteringRequest(
            filterTestWrapper.getSurveyorForUser(filterTestWrapper.getUserFromMapByIndex(0).Id),
            existingTemplates,
            DateTime.now().addDays(-1)
        );

        Test.startTest();

        // Send request
        System.runAs(filterTestWrapper.getSurveyorForUser(user1Id).partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check that the response was successful
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response2 = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        // Check that the response contains 1 published job template
        System.assertEquals(1, response2.jobTemplates.size());
        System.assertEquals(JobTemplateDO.STATUS_PUBLISHED, response2.jobTemplates[0].status);

        // Check that the job template returned is the correct one and that the id doesn't match
        Id expectedSecondJobTempId =
            filterTestWrapper.getWrapperListForUser(filterTestWrapper.getUserList()[1])[0].getJobTemplate().Id;
        Id secondJobId = response2.jobTemplates[0].jobTemplateId;
        System.assertEquals(expectedSecondJobTempId, secondJobId);
    }

    /**
     * Test turning the filtering on.
     * First sync should get 2 published jobs.
     * Second sync should get 1 published and 1 closed
     */
    static testMethod void testTurningJobFilteringOn() {

        JobFilterTestWrapper filterTestWrapper = createJobsForFilteringTests(true);

        // Log the MobileUser for User 1 in to TaroWorks
        Id user1Id = filterTestWrapper.getUserList()[0];
        filterTestWrapper.logInPartnerUserForUser(user1Id);

        // Make sure the JobFiltering is turned off
        ApplicationSettingsUtils.setJobFilterSetting(ApplicationSettingsUtils.JOBS_FILTER_ALL);

        // Get the JobTemplates for the logged in Mobile User
        setUpJobFilteringRequest(
            filterTestWrapper.getSurveyorForUser(filterTestWrapper.getUserFromMapByIndex(0).Id),
            new List<JobTemplate__c>(),
            DateTime.now().addDays(-1)
        );

        // Make first request
        System.runAs(filterTestWrapper.getSurveyorForUser(user1Id).partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }

        // Check that the response was successful
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        // Check that the response contains 1 published job template and that it is the expected one
        Id expectedFirstJobTempId =
            filterTestWrapper.getWrapperListForUser(user1Id)[0].getJobTemplate().Id;
        System.assertEquals(2, response.jobTemplates.size());
        System.assertEquals(JobTemplateDO.STATUS_PUBLISHED, response.jobTemplates[0].status);
        System.assertEquals(JobTemplateDO.STATUS_PUBLISHED, response.jobTemplates[1].status);

        List<Id> existingJobs = new List<Id>{
            response.jobTemplates[0].jobTemplateId,
            response.jobTemplates[1].jobTemplateId
        };

        // Turn job filtering on
        ApplicationSettingsUtils.setJobFilterSetting(ApplicationSettingsUtils.JOBS_FILTER_SF_USER);

        // Create the new request
        JobTemplate__c[] existingTemplates = [SELECT Id, Status__c FROM JobTemplate__c WHERE Id IN :existingJobs];
        setUpJobFilteringRequest(
            filterTestWrapper.getSurveyorForUser(filterTestWrapper.getUserFromMapByIndex(0).Id),
            existingTemplates,
            DateTime.now().addDays(-1)
        );

        Test.startTest();
        System.runAs(filterTestWrapper.getSurveyorForUser(user1Id).partnerUser) {
            TaroRESTJobTemplatesLogic.generateDataAndMetaData();
        }
        Test.stopTest();

        // Check that the response was successful
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Parse the response
        TaroRESTJobTemplatesLogic.TaroResponseBody response2 = (TaroRESTJobTemplatesLogic.TaroResponseBody)JSON.deserialize(
            RestContext.response.responseBody.toString(),
            TaroRESTJobTemplatesLogic.TaroResponseBody.class
        );

        // Check that the response contains 1 published job template
        System.assertEquals(1, response2.jobTemplates.size());
        System.assertEquals(JobTemplateDO.STATUS_CLOSED, response2.jobTemplates[0].status);

        // Check that the job template returned is the correct one and that the id doesn't match
        Id expectedSecondJobTempId =
            filterTestWrapper.getWrapperListForUser(filterTestWrapper.getUserList()[1])[0].getJobTemplate().Id;
        Id secondJobId = response2.jobTemplates[0].jobTemplateId;
        System.assertEquals(expectedSecondJobTempId, secondJobId);
    }

    /**
     * Assign contacts to the mobile user
     */
    private static void assignContactToClient(Id contactToLinkTo) {

        List<Id> idsToRelate = C.extractIds([SELECT Id FROM Contact WHERE Id != :contactToLinkTo]);
        insert SObjectContactAssociationDO.createNewRecords(
            contactToLinkTo,
            Contact.SObjectType.getDescribe().getName(),
            idsToRelate
        );
    }

    /**
     * Test method to check CRUD-FLS permission check while processing JobTemplate request 
     */
    static testMethod void testGenerateDataAndMetaData() {

        TaroRESTJobTemplatesLogic.TaroRequestBody requestBody =
            prepareTaroRequest(new List<JobTemplate__c> (), null);
        prepareTestData(null, JSON.serialize(requestBody));
        User taroWorksPartnerUser = TestUtils.createPartnerUserNotInserted();

        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        System.RunAs(TestUtils.createChatterExternalUser()) {
            DescribeHandler.resetDescribeHandler();
            try {
                Test.startTest();
                SurveyFormList.doGet();
                Test.stopTest();
                System.assert(false);
            } catch (Exception exe) {
                System.assert(true);
            }
        }

        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        System.assertEquals(1, errors.getErrors().size());
        System.assertEquals(C.HTTP_INTERNAL_SERVER_ERROR, RestContext.response.statusCode);
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assert(
            RestContext.response.responseBody.toString().contains(System.Label.ERR_PERMISSIONS)
        );
        System.assertEquals(
            ErrorHandlingRest.ERR_CODE_CRUD_FLS, errorMessages[0].getErrorCode()
        );
        System.assertEquals(
            ErrorHandlingRest.CRUD_FLS, errorMessages[0].getErrorTranslationCode()
        );
    }

    // Inner classes
    /**
     * Private class to store the data required to carry out the tests for job filtering
     */
    private class JobFilterTestWrapper {

        private Profile adminProfile;

        // A list of User.Id. Allows for recovery of users by creation order
        private List<Id> userList;

        // Map of User.Ids to User
        private Map<Id, User> users;

        // A map that links the JobTemplates to the User that has created them
        private Map<Id, List<JobTemplateWrapper>> userJobTemplatesMap;

        // A map to link mobile users to a given User
        private Map<Id, TestUtils.Surveyor> userMobileUserMap;

        public JobFilterTestWrapper() {

            this.userList = new List<Id>();
            this.users = new Map<Id, User>();
            this.userJobTemplatesMap = new Map<Id, List<JobTemplateWrapper>>();
            this.userMobileUserMap = new Map<Id, TestUtils.Surveyor>();
        }

        /**
         * Get the userList
         *
         * @return - The list of user ids in the order they were created
         */
        private List<Id> getUserList() {
            return this.userList;
        }

        /**
         * Get a specific user from the User map based on the index of the userId in the userList
         *
         * @param idIndex - The index in the userList that the User.Id is stored for a given user
         *
         * @return - The User record for the given User in the userList at the index point
         */
        public User getUserFromMapByIndex(Integer idIndex) {
            return this.users.get(this.userList[idIndex]);
        }

        /**
         * Create a sys admin user and add to the users available in the test
         */
        public void createAdminUser() {

            if (this.adminProfile == null) {
                this.adminProfile = TestUtils.getSysAdminProfile();
            }
            User adminUser = TestUtils.createUser(this.adminProfile.Id);
            this.userList.add(adminUser.Id);
            this.users.put(adminUser.Id, adminUser);
        }

        /**
         * Create a partner user and assign them to the provided User
         */
        public void createPartnerSurveyor(User admin) {

            TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor(
                'LastNameSFLT1',
                true
            );
            surveyor.theContact.OwnerId = admin.Id;
            update surveyor.theContact;
            this.userMobileUserMap.put(admin.Id, surveyor);
        }

        /**
         * Log the partner user that belongs to a given User
         *
         * @param userId - The User.Id for the user who owns the mobile user
         */
        public void logInPartnerUserForUser(Id userId) {

            TestUtils.Surveyor surveyor = this.userMobileUserMap.get(userId);
            surveyor = TestUtils.partnerLoginDetails(surveyor);
        }

        /**
         * Get the mobile user for a given User
         *
         * @param userId - The User.Id for the user who owns the mobile user
         */
        public TestUtils.Surveyor getSurveyorForUser(Id userId) {
            return this.userMobileUserMap.get(userId);
        }

        /**
         * Create a job with the standard object hierarchy and standard 3 tasks for a given user
         */
        public void createDefaultJobForUser(Id userId) {

            JobTemplateWrapper jobTemplateWrapper = new JobTemplateWrapper();
            jobTemplateWrapper.createDefaultJob(null, null, null, null);
            jobTemplateWrapper.createDefaultDataViewTaskTemplate(CASE_OBJECT_ID);
            jobTemplateWrapper.updateOwner(userId);
            addWrapperToUser(userId, jobTemplateWrapper);
        }

        /**
         * Add a JobtemplateWrapper to a given user
         */
        private void addWrapperToUser(Id userId, JobTemplateWrapper wrapper) {

            if (!this.userJobTemplatesMap.containsKey(userId)) {
                this.userJobTemplatesMap.put(userId, new List<JobTemplateWrapper>());
            }
            this.userJobTemplatesMap.get(userId).add(wrapper);
        }

        /**
         * Get JobtemplateWrapper List for a given user
         *
         * @param userId - The User.Id being fetched
         *
         * @return - The List of JobtemplateWrapper for that user
         */
        public List<JobTemplateWrapper> getWrapperListForUser(Id userId) {
            return this.userJobTemplatesMap.get(userId);
        }

        /**
         * Update the JobTemplate__c.Status__c for all the created JobTemplate__c. Will force
         * the status update ignoring validation
         *
         * @param status - The new status for the JobTemplate__c
         */
        private void forceStatusUpdateOnAllJobTemplates(String status) {

            List<JobTemplate__c> templatesToUpdate = new List<JobTemplate__c>();
            for (List<JobTemplateWrapper> jobTemplateWrapperList : this.userJobTemplatesMap.values()) {
                for (JobTemplateWrapper jobTemplateWrapper : jobTemplateWrapperList) {
                    jobTemplateWrapper.getJobTemplate().Status__c = status;
                    templatesToUpdate.add(jobTemplateWrapper.getJobTemplate());
                }
            }
            JobTemplateDO.setSkipUpdateValidation(true);
            update templatesToUpdate;
            JobTemplateDO.setSkipUpdateValidation(false);
            templatesToUpdate.clear();
        }
    }

    /**
     * Wrapper class for a complete job template including its tasks
     */
    private class JobTemplateWrapper {

        private JobTemplate__c jobTemplate;
        private List<TaskTemplate__c> taskTemplates;
        private Map<Id, ContentVersion> resourceMap;
        private Map<Id, Id> taskIdToResourceIdMap;

        public JobTemplateWrapper() {
            this.taskTemplates = new List<TaskTemplate__c>();
            this.resourceMap = new Map<Id, ContentVersion>();
            this.taskIdToResourceIdMap = new Map<Id, Id>();
        }

        public JobTemplate__c getJobTemplate() {
            return this.jobTemplate;
        }

        public void setJobTemplate(JobTemplate__c jobTemplate) {
            this.jobTemplate = jobTemplate;
        }

        public Map<Id, ContentVersion> getResourceMap() {
            return this.resourceMap;
        }

        /**
         * Force a status update of a JobTemplate__c by skipping any data validation
         *
         * @param status - The status that the job should be changed to
         *
         * @return - A boolean indicating if it was possible to change the status as it cannot always be forced
         */
        public Boolean forceJobTemplateStatusChange(String status) {
            if (this.taskTemplates.size() == 0) {
                return false;
            }
            JobTemplateDO.setSkipUpdateValidation(true);
            this.jobTemplate.Status__c = status;
            update this.jobTemplate;
            JobTemplateDO.setSkipUpdateValidation(false);
            return true;
        }

        /**
         * Create a job that uses the default hierarchy of Contact < Case.
         * The job will have no tasks. They can be added afterwards.
         * The job will also be in draft status
         *
         * @param contactListFields   - The fields to include in the list fields for the Contact object.
         *                                Pass null to use defaults
         * @param contactDetailFields - The fields to include in the detail fields for the Contact object.
         *                                Pass null to use defaults
         * @param caseListFields      - The fields to include in the list fields for the Case object.
         *                                Pass null to use defaults
         * @param caseDetailFields    - The fields to include in the detail fields for the Contact object.
         *                                Pass null to use defaults
         */
        public void createDefaultJob(
                List<String> contactListFields,
                List<String> contactDetailFields,
                List<String> caseListFields,
                List<String> caseDetailFields
        ) {
            initDefaultJob(
                contactListFields,
                contactDetailFields,
                caseListFields,
                caseDetailFields
            );
            insert this.jobTemplate;
        }

        /**
         * Initiate a default job
         */
        public void initDefaultJob(
                List<String> contactListFields,
                List<String> contactDetailFields,
                List<String> caseListFields,
                List<String> caseDetailFields
        ) {
            this.jobTemplate = JobTemplateDO.createJobTemplate(
                'DefaultTemplate_' + Crypto.getRandomInteger(),
                JobTemplateDO.STATUS_DRAFT,
                TaroRESTJobTemplatesTest.createDefaultHierarchy(contactListFields, contactDetailFields, caseListFields, caseDetailFields),
                'Instructions'
            );
        }

        /**
         * Set the User who owns the job template
         */
        public void updateOwner(Id userId) {
            this.jobTemplate.OwnerId = userId;
            update this.jobTemplate;
        }

        /**
         * Add a data view task template. It will be positioned at the end of the task list
         * Assumes that the JobTemplate was created using the default hierarchy
         */
        public void createDefaultDataViewTaskTemplate(String objectId) {

            Integer position = this.taskTemplates.size() + 1;
            TaskTemplate__c taskTemplate = initDataViewTemplate(objectId, position);
            insert taskTemplate;
            this.taskTemplates.add(taskTemplate);
        }

        /**
         * Init a data view template
         */
        public TaskTemplate__c initDataViewTemplate(String objectId, Integer position) {
            return TaskTemplateDO.createDataViewTaskTemplate(
                'DataCollectionTask_' + position + '_' + Crypto.getRandomInteger(),
                position,
                this.jobTemplate.Id,
                'View the data number ' + position,
                objectId
            );
        }

        /**
         * Add a data collection task template. It will be positioned at the end of the job
         * Assumes that the JobTemplate was created using the default hierarchy and that the survey
         * is on the CASE object and there is a map to a text field for case.Id
         */
        public void createDefaultDataCollectionTask() {

            Integer position = this.taskTemplates.size() + 1;
            Integer randomNumber = Crypto.getRandomInteger();

            // Create the survey
            Survey__c survey = TestUtils.createSurvey('ContactCaseSurvey_' + position + '_' + randomNumber);

            // Add a section
            Question__c section = TestUtils.addSection(survey, 1, 's1_' + position + '_' + randomNumber);
            defaultQuestions.add(section);

            // Add a couple questions
            Question__c question1 = TestUtils.addQuestion(
                section, 1, 'GetId_' + position + '_' + randomNumber, QuestionDO.TYPE_TEXT_SHORT
            );
            Question__c question2 = TestUtils.addQuestion(
                section, 2, 'GetName_' + position + '_' + randomNumber, QuestionDO.TYPE_TEXT_SHORT
            );

            // Publish the survey
            SurveyDO.publishSurvey(survey);

            // Get the survey version
            SurveyVersion__c[] version = [SELECT Id FROM SurveyVersion__c WHERE Survey__c = :survey.Id LIMIT 1];

            TaskTemplate__c taskTemplate = initDataCollectionTemplate(
                version[0].Id,
                question1.Name,
                this.jobTemplate.Id,
                position,
                randomNumber
            );
            insert taskTemplate;
            this.taskTemplates.add(taskTemplate);
        }

        /**
         * Init the data collection template
         */
        public TaskTemplate__c initDataCollectionTemplate(
                Id surveyVersionId,
                String questionName,
                Id jobTemplateId,
                Integer position,
                Integer randomNumber
        ) {
            return TaskTemplateDO.createDataCollectionTaskTemplate(
                'DataCollectionTask_' + position + '_' + randomNumber,
                position,
                jobTemplateId,
                'Collect the data number ' + position,
                TaroRESTJobTemplatesTest.CASE_OBJECT_ID,
                surveyVersionId,
                new List<TaskTemplateDO.Mapping>{
                    new TaskTemplateDO.Mapping(
                        TaroRESTJobTemplatesTest.CASE_OBJECT_ID,
                        'Id',
                        questionName
                    )
                }
            );
        }

        /**
         * Add a resource view task template. It will be positioned at the end of the job
         * Assumes that the JobTemplate was created using the default hierarchy
         */
        public void createDefaultResourceTaskTemplate(String objectId) {

            Integer position = this.taskTemplates.size() + 1;
            ContentVersion resource = new ContentVersion(
                Title = 'Video_' + position,
                VersionData = Blob.valueOf('someContent_' + position),
                PathOnClient = 'path.mp4'
            );
            insert resource;

            TaskTemplate__c taskTemplate = TaskTemplateDO.createResourceTaskTemplate(
                'DataCollectionTask_' + position + '_' + Crypto.getRandomInteger(),
                position,
                this.jobTemplate.Id,
                'View the resource number ' + position,
                objectId,
                resource.Id
            );
            insert taskTemplate;
            this.taskTemplates.add(taskTemplate);
            this.resourceMap.put(resource.Id, resource);
            this.taskIdToResourceIdMap.put(taskTemplate.Id, resource.Id);
        }
    }

    /**
     * Wrapper for task and resource to allow testing of the TaskTemplateResponses
     */
    private class TaskResourceWrapper {

        private TaskTemplate__c taskTemplate;
        private ContentVersion resource;

        public TaskResourceWrapper(TaskTemplate__c taskTemplate, ContentVersion resource) {
            this.taskTemplate = taskTemplate;
            this.resource = resource;
        }

        /**
         * Get the TaskTemplate__c
         *
         * @return - The TaskTemplate__c in the wrapper
         */
        public TaskTemplate__c getTaskTemplate() {
            return this.taskTemplate;
        }

        /**
         * Get the resource
         *
         * @return - The resource in the wrapper
         */
        public ContentVersion getResource() {
            return this.resource;
        }
    }
}