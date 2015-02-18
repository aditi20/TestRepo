/**
* Grameen: Salesforce - Jobs Template
* This is the test class for the Job Trigger class.
* This trigger avoid to publish a Job with tasks where at least one task has
* a Survey Status Draft.
* (Related IDALMSA-2640)
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
* @author  Dennys Lopez Dinza
*/
@isTest
private class JobTemplateTriggerTest{

    /*
    * Avoid to publish a Job with associated Form Status Draft
    */
    static testMethod void testAvoidPublishJobTemplateWithDraftForms(){

        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;

        SurveyVersion__c surveyVersion = [SELECT id
                                          FROM SurveyVersion__c
                                          WHERE Survey__c = :survey.id];

        JobTemplate__c jobTemplate = new JobTemplate__c(Name = 'Job Template 2', Status__c = JobTemplateDO.STATUS_DRAFT);
        insert jobTemplate;

        TaskTemplate__c task =  new TaskTemplate__c(Name = 'Task 1',
                                                    Position__c  = 1,
                                                    JobTemplate__c = jobTemplate.Id,
                                                    Type__c = TaskTemplateDO.TYPE_FORM,
                                                    Form__c = surveyVersion.Id);
        insert task;

        Test.startTest();
            try{
                jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
                update jobTemplate;
                System.assert(false, 'The new task should not have been updated because the Job Template has related ' +
									 'Tasks with Survey Status draft.');
            }
            catch(System.DmlException e){
                System.assertEquals(System.Label.AVOID_PUBLISH_JOB_TEMPLATE_WITH_NONE_PUBLISHED_SURVEYS, e.getDmlMessage(0));
            }
        Test.stopTest();

        JobTemplate__c jobTemplateLoaded = [SELECT Id, Status__c FROM JobTemplate__c WHERE Id =: jobTemplate.Id];

        System.assertEquals(JobTemplateDO.STATUS_DRAFT, jobTemplateLoaded.Status__c);
    }

    /*
    * Avoid to publish a Job with associated Form Status Closed
    */
    static testMethod void testAvoidPublishJobTemplateWithClosedForms(){

        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;

        SurveyVersion__c surveyVersion = [SELECT id
                                          FROM SurveyVersion__c
                                          WHERE Survey__c = :survey.id];

        SurveyManagerController controller =  new SurveyManagerController(new ApexPages.Standardcontroller(new Survey__c()));
        controller.doAction = 'Close';
        controller.surveyIdAction = survey.Id;
        controller.doMoreAction();

        JobTemplate__c jobTemplate = new JobTemplate__c(Name = 'Job Template 3', Status__c = JobTemplateDO.STATUS_DRAFT);
        insert jobTemplate;

        TaskTemplate__c task =  new TaskTemplate__c(Name = 'Task 1',
                                                    Position__c  = 1,
                                                    JobTemplate__c = jobTemplate.Id,
                                                    Type__c = TaskTemplateDO.TYPE_FORM,
                                                    Form__c = surveyVersion.Id);
        insert task;

        Test.startTest();
        try {
            jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
            update jobTemplate;
            System.assert(
                false,
                'The new task should not have been updated because the Job Template has related Tasks with Survey Status closed.'
            );
        } catch(System.DmlException e) {
            System.assertEquals(
                System.Label.JOB_TEMPLATE_CANNOT_PUBLISH_CLOSED_SURVEY,
                e.getDmlMessage(0)
            );
        }
        Test.stopTest();

        JobTemplate__c jobTemplateLoaded = [SELECT Id, Status__c FROM JobTemplate__c WHERE Id =: jobTemplate.Id];

        System.assertEquals(JobTemplateDO.STATUS_DRAFT, jobTemplateLoaded.Status__c);
    }

    /**
     * Success publishing Job with any associated Forms Status Publish
     */
    static testMethod void testPublishJobTemplateWithPublishedForms(){

        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;

		SurveyVersion__c surveyVersion = [SELECT id
                                          FROM SurveyVersion__c
                                          WHERE Survey__c = :survey.id];

        JobTemplate__c jobTemplate = new JobTemplate__c(Name = 'Job Template 4', Status__c = JobTemplateDO.STATUS_DRAFT);
        insert jobTemplate;

        TaskTemplate__c task =  new TaskTemplate__c(Name = 'Task 1',
                                                    Position__c  = 1,
                                                    JobTemplate__c = jobTemplate.Id,
                                                    Type__c = TaskTemplateDO.TYPE_FORM,
                                                    Form__c = surveyVersion.Id);
        insert task;

        Question__c section1 = new Question__c( Name = 's1',
                                                Caption__c = 's1',
                                                Hint__c = 's1',
                                                Survey__c = survey.Id,
                                                Type__c = QuestionDO.TYPE_SECTION,
                                                Position__c = 1);
        insert section1;

        //insert questions for mapped
        Question__c mappedQuestion1 = new Question__c(Survey__c = survey.Id,
                                                      Name = 'q1',
                                                      Caption__c = 'text',
                                                      Type__c = QuestionDO.TYPE_TEXT_SHORT,
                                                      Parent__c = section1.Id,
                                                      Position__c = 1);
        Question__c mappedQuestion2 = new Question__c(Survey__c = survey.Id,
                                                      Name = 'q2',
                                                      Caption__c = 'text',
                                                      Type__c = QuestionDO.TYPE_TEXT_SHORT,
                                                      Parent__c = section1.Id,
                                                      Position__c = 2);
        Question__c mappedQuestion3 = new Question__c(Survey__c = survey.Id,
                                                      Name = 'q3',
                                                      Caption__c = 'text',
                                                      Type__c = QuestionDO.TYPE_TEXT_SHORT,
                                                      Parent__c = section1.Id,
                                                      Position__c = 3);
        insert new List<Question__c>{mappedQuestion1, mappedQuestion2};

        SurveyManagerController controller =  new SurveyManagerController(new ApexPages.Standardcontroller(new Survey__c()));
        controller.surveyToPublish = survey.Id;
        controller.doPublish();

        String jsonMappings = '[{'+
                                    '"objectId":"k87t", '+
                                    '"field":"Id", '+
                                    '"question":"q1"'+
                                '}, {'+
                                    '"objectId":"4rt6", '+
                                    '"field":"Name", '+
                                    '"question":"q2"'+
                                '}, {'+
                                    '"objectId":"96y5", '+
                                    '"field":"Id", '+
                                    '"question":"q3"'+
                                '}]';

        jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        Test.startTest();
            update jobTemplate;
        Test.stopTest();

        JobTemplate__c jobTemplateLoaded = [SELECT Id, Status__c FROM JobTemplate__c WHERE Id = : jobTemplate.Id];

        System.assertEquals(JobTemplateDO.STATUS_PUBLISHED, jobTemplateLoaded.Status__c);
    }

    /**
     * Verify a published Job Template cannot not be deleted.
     */
    static testMethod void testAvoidDeletePublishedJobTemplate(){

        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;

        SurveyVersion__c surveyVersion = [SELECT id
                                          FROM SurveyVersion__c
                                          WHERE Survey__c = :survey.id];


        JobTemplate__c jobTemplate = new JobTemplate__c(Name = 'Job Template 4', Status__c = JobTemplateDO.STATUS_DRAFT);
        insert jobTemplate;

        TaskTemplate__c task =  new TaskTemplate__c(Name = 'Task 1',
                                                    Position__c  = 1,
                                                    JobTemplate__c = jobTemplate.Id,
                                                    Type__c = TaskTemplateDO.TYPE_FORM,
                                                    Form__c = surveyVersion.Id);
        insert task;

        Question__c section1 = new Question__c( Name = 's1',
                                                Caption__c = 's1',
                                                Hint__c = 's1',
                                                Survey__c = survey.Id,
                                                Type__c = QuestionDO.TYPE_SECTION,
                                                Position__c = 1);

        //insert questions for mapped
        insert section1;

        Question__c mappedQuestion1 = new Question__c(Survey__c = survey.Id,
                                                      Name = 'q1',
                                                      Caption__c = 'text',
                                                      Type__c = QuestionDO.TYPE_TEXT_SHORT,
                                                      Parent__c = section1.Id,
                                                      Position__c = 1);
        Question__c mappedQuestion2 = new Question__c(Survey__c = survey.Id,
                                                      Name = 'q2',
                                                      Caption__c = 'text',
                                                      Type__c = QuestionDO.TYPE_TEXT_SHORT,
                                                      Parent__c = section1.Id,
                                                      Position__c = 2);
        Question__c mappedQuestion3 = new Question__c(Survey__c = survey.Id,
                                                      Name = 'q3',
                                                      Caption__c = 'text',
                                                      Type__c = QuestionDO.TYPE_TEXT_SHORT,
                                                      Parent__c = section1.Id,
                                                      Position__c = 3);

        insert new List<Question__c>{mappedQuestion1, mappedQuestion2};

        SurveyManagerController controller =  new SurveyManagerController(new ApexPages.Standardcontroller(new Survey__c()));
        controller.surveyToPublish = survey.Id;
        controller.doPublish();

        String jsonMappings = '[{'+
                                    '"objectId":"k87t", '+
                                    '"field":"Id", '+
                                    '"question":"q1"'+
                                '}, {'+
                                    '"objectId":"4rt6", '+
                                    '"field":"Name", '+
                                    '"question":"q2"'+
                                '}, {'+
                                    '"objectId":"96y5", '+
                                    '"field":"Id", '+
                                    '"question":"q3"'+
                                '}]';

        jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        update jobTemplate;

        JobTemplate__c jobTemplateLoaded = [SELECT Id, Status__c FROM JobTemplate__c WHERE Id = : jobTemplate.Id];

        System.assertEquals(JobTemplateDO.STATUS_PUBLISHED, jobTemplateLoaded.Status__c);

        Test.startTest();
            //try to delete the Job Template
            try{
                delete jobTemplateLoaded;
                System.assert(false, 'The JobTemplate should not be deleted because its status is "PUBLISHED"');
            }
            catch(System.DmlException e){
                System.assert(e.getMessage().contains(System.Label.ERR_DELETE_NON_DRAFT_JOB_TEMPLATE));
            }
        Test.stopTest();
        System.assertEquals(1, [SELECT Id FROM JobTemplate__c WHERE Id = :jobTemplate.Id].size(),
							   'The Job Template must exist.');
    }

    /**
    * Verify a closed Job Template in Draft status deletes successfully.
    */
    static testMethod void testAvoidDeleteClosedJobTemplate(){

        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;

        SurveyVersion__c surveyVersion = [SELECT id
                                          FROM SurveyVersion__c
                                          WHERE Survey__c = :survey.id];


        JobTemplate__c jobTemplate = new JobTemplate__c(Name = 'Job Template 4', Status__c = JobTemplateDO.STATUS_DRAFT);
        insert jobTemplate;

        TaskTemplate__c task =  new TaskTemplate__c(Name = 'Task 1',
                                                    Position__c  = 1,
                                                    JobTemplate__c = jobTemplate.Id,
                                                    Type__c = TaskTemplateDO.TYPE_FORM,
                                                    Form__c = surveyVersion.Id);
        insert task;

        jobTemplate.Status__c = JobTemplateDO.STATUS_CLOSED;
        update jobTemplate;

        JobTemplate__c jobTemplateLoaded = [SELECT Id, Status__c FROM JobTemplate__c WHERE Id = : jobTemplate.Id];

        System.assertEquals(JobTemplateDO.STATUS_CLOSED, jobTemplateLoaded.Status__c);

        Test.startTest();
            //try to delete the Job Template
            try{
                delete jobTemplateLoaded;
                System.assert(false, 'The JobTemplate should not be deleted because its status is "CLOSED"');
            }
            catch(System.DmlException e){
                System.assert(e.getMessage().contains(System.Label.ERR_DELETE_NON_DRAFT_JOB_TEMPLATE));
            }
        Test.stopTest();
        System.assertEquals(1, [SELECT Id FROM JobTemplate__c WHERE Id = :jobTemplate.Id].size(),
							   'The Job Template must exist.');
    }

    /**
    * Verify only Job Template cannot not be deleted.
    */
    static testMethod void testDeleteDraftJobTemplate(){

        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;

        SurveyVersion__c surveyVersion = [SELECT id
                                          FROM SurveyVersion__c
                                          WHERE Survey__c = :survey.id];


        JobTemplate__c jobTemplate = new JobTemplate__c(Name = 'Job Template 4', Status__c = JobTemplateDO.STATUS_DRAFT);
        insert jobTemplate;

        TaskTemplate__c task =  new TaskTemplate__c(Name = 'Task 1',
                                                    Position__c  = 1,
                                                    JobTemplate__c = jobTemplate.Id,
                                                    Type__c = TaskTemplateDO.TYPE_FORM,
                                                    Form__c = surveyVersion.Id);
        insert task;

        JobTemplate__c jobTemplateLoaded = [SELECT Id, Status__c FROM JobTemplate__c WHERE Id = : jobTemplate.Id];

        System.assertEquals(JobTemplateDO.STATUS_DRAFT, jobTemplateLoaded.Status__c, 'The Job Template must be draft.');

        Test.startTest();
            //try to delete the Job Template
            delete jobTemplateLoaded;
        Test.stopTest();
        System.assertEquals(0, [SELECT Id FROM JobTemplate__c WHERE Id = :jobTemplate.Id].size(),
						 	   'The Job Template must not exist.');
    }

    /**
    * Try to publish a jobTemplate with deleted mapped questions
    */
    static testMethod void testPublishJobTemplateWithUnexistingQuestions(){

        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;


        Question__c section1 = new Question__c( Name = 's1',
                                                Caption__c = 's1',
                                                Hint__c = 's1',
                                                Survey__c = survey.Id,
                                                Type__c = QuestionDO.TYPE_SECTION,
                                                Position__c = 1);


        //insert questions for mapped
        insert section1;

        Question__c mappedQuestion1 = new Question__c(Survey__c = survey.Id,
                                                      Name = 'q1',
                                                      Caption__c = 'text',
                                                      Type__c = QuestionDO.TYPE_TEXT_SHORT,
                                                      Parent__c = section1.Id,
                                                      Position__c = 1);
        Question__c mappedQuestion2 = new Question__c(Survey__c = survey.Id,
                                                      Name = 'q2',
                                                      Caption__c = 'text',
                                                      Type__c = QuestionDO.TYPE_TEXT_SHORT,
                                                      Parent__c = section1.Id,
                                                      Position__c = 2);
        Question__c mappedQuestion3 = new Question__c(Survey__c = survey.Id,
                                                      Name = 'q3',
                                                      Caption__c = 'text',
                                                      Type__c = QuestionDO.TYPE_TEXT_SHORT,
                                                      Parent__c = section1.Id,
                                                      Position__c = 3);

        insert new List<Question__c>{mappedQuestion1, mappedQuestion2};

        // Create the list of Hierarchies.
        List<JobTemplateDo.ObjectHierarchy> listHierarchies = new List<JobTemplateDo.ObjectHierarchy>();

        JobTemplateDo.ObjectHierarchy hierarchy = new JobTemplateDo.ObjectHierarchy('k87t', 'Contact', 'Contact');
        hierarchy.addListField('Email');

        JobTemplateDo.ObjectHierarchy hierarchy2 = new JobTemplateDo.ObjectHierarchy('4rt6', 'Contact', 'Contact');
        hierarchy2.addListField('Email');

        JobTemplateDo.ObjectHierarchy hierarchy3 = new JobTemplateDo.ObjectHierarchy('96y5', 'Contact', 'Contact');
        hierarchy3.addListField('Email');

        listHierarchies.add(hierarchy);
        listHierarchies.add(hierarchy2);
        listHierarchies.add(hierarchy3);

        String hierarchies = JSON.serialize(listHierarchies);
        String jsonMappings = '[{'+
                                    '"objectId":"k87t", '+
                                    '"field":"Id", '+
                                    '"question":"q1"'+
                                '}, {'+
                                    '"objectId":"4rt6", '+
                                    '"field":"Name", '+
                                    '"question":"q2"'+
                                '}, {'+
                                    '"objectId":"96y5", '+
                                    '"field":"other", '+
                                    '"question":"q3"'+
                                '}]';




        JobTemplate__c jobTemplate = new JobTemplate__c(Name = 'Job Template 5',
                                                        Status__c = JobTemplateDO.STATUS_DRAFT,
                                                        Hierarchy__c = hierarchies);
        insert jobTemplate;

        SurveyVersion__c version = [SELECT ID
                                    FROM SurveyVersion__c
                                    WHERE Survey__c = :survey.Id][0];

        TaskTemplate__c task =  new TaskTemplate__c(Name = 'Task 1',
                                                    Position__c  = 1,
                                                    JobTemplate__c = jobTemplate.Id,
                                                    Type__c = TaskTemplateDO.TYPE_FORM,
                                                    Form__c = version.Id,
                                                    Mapping__c = jsonMappings);
        insert task;

        delete mappedQuestion2;
        //try to publish the job template with a deleted question

        SurveyManagerController controller =  new SurveyManagerController(new ApexPages.Standardcontroller(new Survey__c()));
        controller.surveyToPublish = survey.Id;
        controller.doPublish();

        Test.startTest();
            try{
                jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
                update jobTemplate;
                system.assert(false);
            }catch (Exception e){
                //system.assertEquals(System.Label.JOB_TEMPLATE_WITH_INVALID_TASKS_TEMPLATES_ERR,e.getMessage());
                system.assert(e.getMessage().contains(System.Label.JOB_TEMPLATE_WITH_INVALID_TASKS_TEMPLATES_ERR));

            }
        Test.stopTest();
    }

	/*
     * Validate that if there is a Task that is related to an Object (or a mapping) that is not in the Hierarchy,
     * will raise a page error.
     */
    static testMethod void testJobTemplateValidateConsistency(){

        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;
        Question__c sec1        = TestUtils.addSection (survey, 1, 'section1');
        Question__c auxQuestion = TestUtils.addQuestion (sec1, 1, 'Text1', QuestionDO.TYPE_TEXT_SHORT);

        SurveyManagerController controller = new SurveyManagerController(new ApexPages.Standardcontroller(new Survey__c()));
        controller.surveyToPublish = survey.Id;
        controller.doPublish();

        // Create the list of Hierarchies.
        List<JobTemplateDo.ObjectHierarchy> listHierarchies = new List<JobTemplateDo.ObjectHierarchy>();

        JobTemplateDo.ObjectHierarchy hierarchy = new JobTemplateDo.ObjectHierarchy('207a', 'Contact', 'Contact');
        hierarchy.addListField('Email');
        hierarchy.addDetailField('OtherPostalCode');

        listHierarchies.add(hierarchy);

        // Create the current Job Template and set the Hierarchy created.
        String hierarchyJson       = JSON.serialize(listHierarchies);
        JobTemplate__c jobTemplate = new JobTemplate__c(Name = 'Job Template 6',
                                                        Status__c = JobTemplateDO.STATUS_DRAFT,
                                                        Hierarchy__c = hierarchyJson);
        insert jobTemplate;

        // Create the mapping of the task (different objectId of the current Job Template).
        List<JobTemplateDo.TaskMapping> listMappings = new List<JobTemplateDo.TaskMapping>();

        JobTemplateDo.TaskMapping mapping = new JobTemplateDo.TaskMapping();
        mapping.objectId = 'k87t';
        mapping.field = 'Id';
        mapping.question = 'Text1';

        listMappings.add(mapping);

        SurveyVersion__c version = [SELECT ID
                                    FROM SurveyVersion__c
                                    WHERE Survey__c = :survey.Id][0];

        //  Create a TaskTemplate of form type with a mapping with different objectId that the Job template.
        String mappingsJson  = JSON.serialize(listMappings);
        TaskTemplate__c task = new TaskTemplate__c(Name = 'Task 1',
                                                   Position__c  = 1,
                                                   JobTemplate__c = jobTemplate.Id,
                                                   Type__c = TaskTemplateDO.TYPE_FORM,
                                                   Form__c = version.Id,
                                                   Mapping__c = mappingsJson);

        try{
            // Should trigger an error on the task, containing the messages:
            // There is a mapping which related object is not part of the hierarchy in the task and the name of the task...
            insert task;
            system.assert(false);
        }
        catch(Exception e){
            system.assert(e.getMessage().contains(system.Label.JOB_TEMPLATE_INCONSISTENT_MAPPING)
                          && e.getMessage().contains(task.Name));
        }

        // Now try with data-view type (Different Object__c).
        task = new TaskTemplate__c(Name = 'Task 1',
                                   Position__c  = 1,
                                   JobTemplate__c = jobTemplate.Id,
                                   Type__c = TaskTemplateDO.TYPE_DATA_VIEW,
                                   Object__c = 'k84t');
        try{
            // Should trigger an error on the task, containing the messages:
            // The related object is not part of the hierarchy in the task and the name of the task...
            insert task;
            system.assert(false);
        }
        catch(Exception e){
            system.assert(e.getMessage().contains(system.Label.JOB_TEMPLATE_INCONSISTENT_OBJECT)
                          && e.getMessage().contains(task.Name));
        }
    }

    /*
     * Validate that if there is a Task that is related to an Object (or a mapping) that is not in the Hierarchy,
     * will raise a page error.
     */
    static testMethod void testHierarchyHasLastModifiedDate(){

        Survey__c survey = new Survey__c(Name = 'Survey 1');
        insert survey;

        SurveyManagerController controller = new SurveyManagerController(new ApexPages.Standardcontroller(new Survey__c()));
        controller.surveyToPublish = survey.Id;
        controller.doPublish();

        // Create the list of Hierarchies.
        List<JobTemplateDo.ObjectHierarchy> listHierarchies = new List<JobTemplateDo.ObjectHierarchy>();

        JobTemplateDo.ObjectHierarchy hierarchy = new JobTemplateDo.ObjectHierarchy('207a',
                                                                                    'AccountHistory',
                                                                                    'AccountHistory');

        listHierarchies.add(hierarchy);

        // Create the current Job Template and set the Hierarchy created.
        String hierarchyJson       = JSON.serialize(listHierarchies);
        JobTemplate__c jobTemplate = new JobTemplate__c(Name = 'Job Template 1',
                                                        Status__c = JobTemplateDO.STATUS_DRAFT,
                                                        Hierarchy__c = hierarchyJson);

        Test.startTest();
            try {
                insert jobTemplate;
                system.assert(false);
            } catch (Exception e) {
                system.assert(true);
                system.assert(e.getMessage().contains(System.Label.JOB_TEMPLATE_ERROR_LASTMODIFIEDDATE));
            }
        Test.stopTest();
    }

    /**
     *  Test method for validate that if a question that cannot be mapped in a task is mapped,
     *  should raise an error.
     */
    static testMethod void testMappingUnavailableQuesionsInTasks(){

        // Prepare the data.
        TaskTemplate__c task = createTaskWithIncorrectMapping();

        Test.startTest();
            try {
                insert task;
                system.assert(false, 'Should fail here since it was created a wrong mapping to the test');
            } catch (Exception e) {
                system.assert(e.getMessage().contains(System.Label.TASK_INCORRECT_MAPPING), e.getMessage());
            }
        Test.stopTest();
    }

    /**
     *  Method in charge of prepare the survey and job, and return the task that will be used to assert.
     *
     *  @return Task that will be mapped to an incorrect question.
     */
    private static TaskTemplate__c createTaskWithIncorrectMapping(){

        // Prepare the survey.
        Survey__c survey                = new Survey__c(Name = 'Survey 1');
        insert survey;
        Question__c sec1                = TestUtils.addSection (survey, 1, 'section1');
        Question__c auxQuestion         = TestUtils.addQuestion (sec1, 1, 'Text1', QuestionDO.TYPE_TEXT_SHORT);
        Question__c questionNotAllowed  = TestUtils.addQuestion (sec1, 2, 'Static', QuestionDO.TYPE_STATIC);

        // Obtain the version.
        SurveyVersion__c version = [SELECT ID FROM SurveyVersion__c WHERE Survey__c = :survey.Id][0];

        // Create the list of Hierarchies.
        List<JobTemplateDo.ObjectHierarchy> listHierarchies = new List<JobTemplateDo.ObjectHierarchy>();

        // Create the Job.
        JobTemplateDo.ObjectHierarchy hierarchy = new JobTemplateDo.ObjectHierarchy('207a', 'Contact', 'Contact');
        hierarchy.addListField('Email');
        hierarchy.addDetailField('OtherPostalCode');
        listHierarchies.add(hierarchy);

        // Create the current Job Template and set the Hierarchy created.
        String hierarchyJson       = JSON.serialize(listHierarchies);
        JobTemplate__c jobTemplate = new JobTemplate__c(Name         = 'Job Template 1',
                                                        Status__c    = JobTemplateDO.STATUS_DRAFT,
                                                        Hierarchy__c = hierarchyJson);
        insert jobTemplate;

        // Create the mapping of the task (mapped to a question that I know I cannot map).
        List<JobTemplateDo.TaskMapping> listMappings = new List<JobTemplateDo.TaskMapping>();

        JobTemplateDo.TaskMapping mapping   = new JobTemplateDo.TaskMapping();
        mapping.objectId                    = '207a';
        mapping.field                       = 'Email';
        mapping.question                    = 'Static';
        listMappings.add(mapping);

        //  Insert the task with the incorrect mapped question.
        String mappingsJson  = JSON.serialize(listMappings);
        TaskTemplate__c task = new TaskTemplate__c(Name = 'Task 1',
                                                   Position__c  = 1,
                                                   JobTemplate__c = jobTemplate.Id,
                                                   Type__c = TaskTemplateDO.TYPE_FORM,
                                                   Form__c = version.Id,
                                                   Mapping__c = mappingsJson);

        return task;
    }

    /*
    * Close all related performance Target when closing jobs
    */
    static testMethod void testCloseJobClosePerformanceTarget() {
        JobTemplate__c jobTemplate1 = TestUtils.createPublishedDataCollectionJobTemplate('job1', 'survey 1');
        JobTemplate__c jobTemplate2 = TestUtils.createPublishedDataCollectionJobTemplate('job2', 'survey 2');
        JobTemplate__c[] jobs = new JobTemplate__c[]{jobTemplate1, jobTemplate2};

        // Create a performance target
        PerformanceTarget__c performanceTarget1 = PerformanceTargetDOTest.createJobTargetRecord(
            'PerformanceTarget1',
            jobTemplate1.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            PerformanceTargetDO.getPreviousMonday(Date.today()),
            PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        PerformanceTarget__c performanceTarget2 = PerformanceTargetDOTest.createJobTargetRecord(
            'PerformanceTarget2',
            jobTemplate2.Id,
            50,
            PerformanceTargetDO.TIMEFRAME_WEEKLY,
            PerformanceTargetDO.getPreviousMonday(Date.today()),
            PerformanceTargetDO.getPreviousMonday(Date.today()).addDays(6),
            PerformanceTargetDO.TYPE_JOB_TARGET
        );
        insert new List<PerformanceTarget__c> {performanceTarget1, performanceTarget2};

        Test.startTest();
        jobTemplate1.Status__c = JobTemplateDO.STATUS_CLOSED;
        update jobTemplate1;
        Test.stopTest();

        List<PerformanceTarget__c> performanceTargets = [SELECT
                                                                Id,
                                                                Status__c,
                                                                Type__c,
                                                                CloseReason__c
                                                        FROM PerformanceTarget__c
                                                        WHERE
                                                            JobTemplate__c in :jobs ORDER BY Name];
        system.AssertEquals(PerformanceTargetDO.STATUS_CLOSED, performanceTargets.get(0).Status__c, 'The status should be closed');
        system.AssertEquals(PerformanceTargetDO.CLOSE_AUTOMATICALLY, performanceTargets.get(0).CloseReason__c, 'The close reason must be automatically');
        system.AssertEquals(PerformanceTargetDO.STATUS_ACTIVE, performanceTargets.get(1).Status__c, 'The status should be active');
    }
}
