/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public class SurveyManagerControllerTest {

    /**
     * Helper method to build the error message when a list is not contained in the map
     */
    private static String notContainedError(Map<Id, sObject> containerMap, sObject objectToTest){
        return String.format('This failed because some objects was not contained in the map. ' +
                             'Object type: {0}. Map: {1}. Object: {2}.',
                             new String[]{String.ValueOf(objectToTest.getSObjectType()),
                                          String.ValueOf(containerMap),
                                          String.ValueOf(objectToTest)});
    }

    // Helper method to test empty strings
    private static Boolean empty(String s){
        return s == null || s.length() == 0;
    }

    public static Survey__c[] createSurveyList(){
        Survey__c[] surveys = new Survey__c[]{};
        for (Integer i = 1; i <= 25; i++) {
            surveys.add(new Survey__c(Name = 'TestSurvey' + i));
        }
        insert surveys;
        return surveys;
    }

    // Helper method that creates the needed data for the Distribute action tests
    private static Survey__c prepareDistributionData() {
        TestSurveyData testSurvey = createPPISurvey();
        LicenseSettings__c license = C.getLicense();
        license.PPI_Editable__c = true;
        license.Can_Distribute__c = true;
        license.UsePPI__c = true;
        update license;

        SurveyDO.publishSurvey(testSurvey.testSurvey);
        return testSurvey.testSurvey;
    }

    // Helper method that creates a PPI survey
    private static TestSurveyData createPPISurvey() {

        TestSurveyData testSurvey = TestSurveyData.addPpiTablesToStandardSurvey(
            TestSurveyData.createStandardTestSurvey(
                SurveyDOTest.createInsertedPpiTemplate(),
                false,
                false
            )
        );
        return testSurvey;
    }

    /**
     * This method is to validate the status filter.
     */
    static testMethod void testValidateStatusFilter(){
        Survey__c[] surveys = createSurveyList();

        Test.startTest();
            SurveyManagerController controller = new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
            controller.filter='all';
            controller.doFilterStatus();

            system.assert(controller.resultSize >1);

            List<SelectOption> statusList = controller.statusList;
            surveys[0].status__c = SurveyDO.STATUS_PUBLISHED;
            controller.filter = SurveyDO.STATUS_PUBLISHED;
            controller.doFilterStatus();
        Test.stopTest();
    }

    /**
     * This method is to validate the column sort
     */
    static testMethod void testSortColumn() {
        Survey__c[] surveys = createSurveyList();
        SurveyDO.updateSurveysStatus(
            new List<Survey__c>{surveys[0]},
            SurveyDO.STATUS_PUBLISHED
        );

        Test.startTest();
        SurveyManagerController controller = new SurveyManagerController(
            new ApexPages.StandardController(new Survey__c())
        );
        controller.previousSortField = null;
        controller.columnOrder = 'Survey__r.Status__c';
        controller.stringOrder = 'asc';
        controller.doSort();
        Survey__c  firstPlaceSurveyFilterNull = controller.surveyList[0].Survey__r;
        controller.columnOrder = 'Survey__r.Status__c';
        controller.doSort();
        Survey__c  firstPlaceSurveyFilterStatus = controller.surveyList[0].Survey__r;
        System.assertNotEquals(firstPlaceSurveyFilterNull, firstPlaceSurveyFilterStatus);
        Test.stopTest();
    }

    /**
     * This method is to validate publish a null survey.
     */
    static testMethod void testDoPublishNullSurveys(){
        Survey__c[] surveys = createSurveyList();

        Test.startTest();
            SurveyManagerController controller =  new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
            controller.surveyToPublish = null;
            controller.doPublish();
        Test.stopTest();
        system.assert(ApexPages.getMessages().size() > 0, 'There should be an apex message since it cannot publish a null survey');
        system.assert(ApexPages.getMessages()[0].getDetail().contains(system.label.SURVEY_ERR_NULLREFERENCE), 'Wrong apex message shown');
    }

    /**
     * Validate publish a non-existent id survey.
     */
    static testMethod void testDoPublishFakeId(){
        Survey__c[] surveys = createSurveyList();

        Test.startTest();
            SurveyManagerController controller =  new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
            controller.surveyToPublish = surveys[0].Id;//a non-existent survey ID
            delete surveys;
            controller.doPublish();
        Test.stopTest();
        system.assert(ApexPages.hasMessages(ApexPages.severity.ERROR), 'There has to be a page error since the survey id is non-existent');
        system.assertEquals(ApexPages.getMessages()[0].getDetail(),system.label.SURVEY_ERR_ID_NOT_FOUND);

    }
    /**
     * Validate publish an already published survey.
     */
    static testMethod void testDoPublishAlreadyPublished(){
        Survey__c[] surveys = createSurveyList();
        Survey__c sur = new Survey__c(Name = 'Test Do Publish');
        insert sur;
        SurveyVersion__c surveyVersion = [select Id,Status__c from SurveyVersion__c where Survey__c =:sur.Id];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        Test.startTest();
            SurveyManagerController controller =  new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
            controller.surveyToPublish = sur.Id;
            controller.doPublish();
        Test.stopTest();
        system.assert(ApexPages.hasMessages(ApexPages.severity.ERROR),
                                        'There has to be a page error since the survey is Published');
        system.assertEquals(String.format(system.label.SURVEY_ERR_CANTPUBLISHWITHSTATUS,new String[]{'Published'}),
                                            ApexPages.getMessages()[0].getDetail());

    }
    /**
     * Validate that when publishing a survey:
     *  - The status of the survey is changed to published'
     *  - An xform document is created for the survey.
     */
    static testMethod void testDoPublishCorrect(){
        SurveyManagerController controller =  new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
        Survey__c survey = new Survey__c(Name = 'Test1', Status__c = SurveyDO.STATUS_DRAFT);
        insert survey;
        // Create one section and one question
        Question__c s1 = new Question__c(Name = 's1', Survey__c = survey.Id, Position__c =1, Parent__c = null, Type__c=QuestionDO.TYPE_SECTION );
        insert s1;
        insert new Question__c(Name = 'q1', Survey__c = survey.Id, Position__c = 1, Parent__c = s1.Id, Type__c = QuestionDO.TYPE_TEXT_SHORT );

        Test.startTest();
            // Publish the survey
            controller.contactGroupsOfSurvey = new List<ContactGroupSurveyAssignment__c>();
            controller.surveyToPublish = survey.Id;
            controller.doPublish();
        Test.stopTest();
        SurveyVersion__c sursVersion = [SELECT Id,Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id];
        system.assertEquals(SurveyDO.STATUS_PUBLISHED, sursVersion.Status__c);

        //an xform should be created on publish
        system.assertEquals(1, [SELECT Id FROM Attachment
                                WHERE ParentId = :sursVersion.Id
                                      AND Name = :XformCreator.XFORM_ATTACHMENT].size());
    }

    /**
     * Test to avoid publishing a survey with an empty section
     */
    static testMethod void testAvoidPublishSurveyEmptySection(){

        Survey__c survey = new Survey__c(Name = 'Empty Section Survey');
        insert survey;

        Question__c s1 = new Question__c(Name = 's1', Survey__c = survey.Id, Position__c =1, Parent__c = null, Type__c=QuestionDO.TYPE_SECTION );
        Question__c s2 = new Question__c(Name = 's2', Survey__c = survey.Id, Position__c =2, Parent__c = null, Type__c=QuestionDO.TYPE_SECTION );
        insert new List <Question__c> {s1, s2};

        Question__c q1 = new Question__c(Name = 'q2.1',Survey__c = survey.Id, Position__c =1, Parent__c = s2.Id, Type__c=QuestionDO.TYPE_TEXT_SHORT );
        insert q1;

        Test.startTest();
            SurveyManagerController controller =  new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));

            controller.surveyToPublish = survey.Id;
            controller.doPublish();
        Test.stopTest();

        System.assert(ApexPages.hasMessages(ApexPages.severity.ERROR), 'The should be a generated error.');
        System.assertEquals(ApexPages.getMessages()[0].getDetail(), System.Label.ERR_SURVEY_PUBLISH_EMPTY_SECTION);

        System.assertEquals(SurveyDO.STATUS_DRAFT, [SELECT Id, Status__c FROM Survey__c WHERE Id =: survey.Id].Status__c, 'The survey must still keep in DRAFT status.');
    }

    /**
    *    This method tests the change of contact group assignments on publishing
    *    It will do the following:
    *      - Leave one of the previously assigned groups selected
    *      - Deselect the other previously assigned groups
    *      - Select another groups to assign
    */
    static testMethod void testChangeAssignments(){

        // Needed objects for the test
        //-----------------------------------------------
        // The survey to publish
        Survey__c survey = new Survey__c(Name = '__Test__ Survey to publish');
        insert survey;

        // All the contact groups
        List<ContactGroup__c> contactGroups = new List<ContactGroup__c>();
        for(Integer i=0; i<6; i++){
            contactGroups.add(new ContactGroup__c(Name = '__Test__ Group' + i));
        }
        insert contactGroups;

        // Assignments previous to the publishing
        ContactGroupSurveyAssignment__c cgAssignment1 = new ContactGroupSurveyAssignment__c(Survey__c = survey.Id, ContactGroup__c = contactGroups[0].Id);
        ContactGroupSurveyAssignment__c cgAssignment2 = new ContactGroupSurveyAssignment__c(Survey__c = survey.Id, ContactGroup__c = contactGroups[1].Id);
        ContactGroupSurveyAssignment__c cgAssignment3 = new ContactGroupSurveyAssignment__c(Survey__c = survey.Id, ContactGroup__c = contactGroups[2].Id);
        insert new ContactGroupSurveyAssignment__c[]{cgAssignment1, cgAssignment2, cgAssignment3};


        // Prepare the test
        //-----------------------------------------------
        Test.startTest();
            SurveyManagerController controller =  new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
            controller.surveyToPublish = survey.Id;
            controller.showGroupPopup();

            // Run the test
            //-----------------------------------------------
            controller.doPublish();
        Test.stopTest();
        // Survey is assigened to three groups
        System.assertEquals(3, [SELECT Id FROM ContactGroupSurveyAssignment__c WHERE Survey__c = :survey.Id].size());
    }

    /**
     * This method is to validate the popup to publish surveys to an inactive groups
     */
    static testMethod void publishToAnInactiveGroup(){
        // Insert survey to publish
        Survey__c survey = new Survey__c(Name = '__Test__ Survey to publish');
        insert survey;

        // Contact groups
        List<ContactGroup__c> contactGroups = new List<ContactGroup__c>();
        for(Integer i=0; i<6; i++){
            contactGroups.add(new ContactGroup__c(Name = 'TestGroup_' + i));
        }
        // Insert the groups
        insert contactGroups;

        // Make some groups inactive
        contactGroups[0].Status__c = C.GROUP_STATUS_INACTIVE;
        contactGroups[1].Status__c = C.GROUP_STATUS_INACTIVE;
        contactGroups[3].Status__c = C.GROUP_STATUS_INACTIVE;
        contactGroups[5].Status__c = C.GROUP_STATUS_INACTIVE;

        // Update groups
        update contactGroups;

        // Assignments previous to the publishing
        ContactGroupSurveyAssignment__c cgAssignment1 = new ContactGroupSurveyAssignment__c(Survey__c = survey.Id, ContactGroup__c = contactGroups[0].Id);
        insert cgAssignment1;

        Test.startTest();
            SurveyManagerController cont =  new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
            cont.surveyToPublish = survey.Id;
        	cont.contactGroupsOfSurvey = new List<ContactGroupSurveyAssignment__c>{cgAssignment1};

            // Execute the test
            cont.doPublish();
        Test.stopTest();
        // Should show the error message
        system.assert(ApexPages.hasMessages(ApexPages.severity.ERROR), system.label.BUILDER_ERR_INACTIVEGROUP + '  ' +
                                                                       new List<String>{contactGroups[0].Name});

    }

    /**
     * This method is to validate moreActions/Close
     */
    static testMethod void testClose(){
        Survey__c[] surveys = createSurveyList();
        Test.startTest();
            SurveyManagerController controller =  new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
            //change the filter to see al surveys
            controller.filter='all';
            controller.doFilterStatus();

            controller.doAction = 'Close';
            controller.surveyIdAction = null;

            try{
                controller.doMoreAction();
                system.assert(false, 'Should have failed since no survey is set for action.');
            }catch (SurveyException e){
                system.assert(e.getMessage().equals(system.label.SURVEY_ERR_NULLREFERENCE));
            }

            controller.surveyIdAction = surveys[0].Id;//a fake survey ID
            delete surveys;
            controller.doMoreAction();
            system.assert(ApexPages.hasMessages(ApexPages.severity.ERROR), 'There has to be a page error since the survey id is fake');


            Survey__c surs = new Survey__c(Name = 'Test1');
            insert surs;
            controller.surveyIdAction = surs.id;
            controller.doMoreAction();
            //change the filter to see al surveys
            controller.filter='all';
            controller.doFilterStatus();
            surs.Status__c = controller.surveyList[0].Survey__r.Status__c;
        Test.stopTest();
        system.assertEquals('Closed', surs.Status__c);
    }

    /**
     * This method is to validate moreActions/Trash
     */
    static testMethod void testTrash(){
        Survey__c[] surveys = createSurveyList();
        Test.startTest();
            SurveyManagerController controller = new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));

            controller.doAction = 'Delete';
            controller.surveyIdAction = null;

            try{
                controller.doMoreAction();
                system.assert(false, 'Should have failed since no survey is set for action.');
            }catch (SurveyException e){
                system.assert(e.getMessage().equals(system.label.SURVEY_ERR_NULLREFERENCE));
            }

            controller.surveyIdAction = surveys[0].Id;//a fake survey ID
            delete surveys;

            controller.doMoreAction();
            system.assert(ApexPages.hasMessages(ApexPages.severity.ERROR));
            Survey__c surs = new Survey__c(Name = 'Test1');
            insert surs;

            //set the id of the survey to be trashed
            controller.surveyIdAction = surs.Id;
            //stores the survey to which the survey belongs
            string surveyId = surs.Id;

            controller.doMoreAction();
            list<Survey__c> listSurveysAfter = [Select Id from Survey__c where Id=: surveyId];
            //the survey should be deleted
            system.assertEquals(0, listSurveysAfter.size());

            Survey__c[] moreSurveys = createSurveyList();

            //set the id of the survey to be trashed
            controller.surveyIdAction = moreSurveys[5].id;

            //stores the survey to which the survey belongs
            String surveySpeId = moreSurveys[5].Id;

            controller.doMoreAction();
        Test.stopTest();
        list<Survey__c> listSurveysAfterForId = [Select Id from Survey__c where Id=: surveySpeId];
        //the survey should be deleted
        system.assertEquals(0, listSurveysAfterForId.size());

    }

    /**
     * This method is to validate moreActions/Trash with a PPI survey
     */
    static testMethod void testTrashPPI() {
        Test.startTest();
        SurveyManagerController controller =
        new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));

        controller.doAction = 'Delete';
        TestSurveyData testSurvey = createPPISurvey();

        // Set the id of the survey to be trashed adn execute the action
        controller.surveyIdAction = testSurvey.testSurvey.Id;
        controller.doMoreAction();
        Test.stopTest();

        // The survey should be deleted
        System.assertEquals(
            0,
            new SurveySelector().getWithSurveyVersion(
                new Set<String>{testSurvey.testSurvey.Id}
            ).size()
        );

        // The dataset and the lines should be deletes as well
        System.assertEquals(
            0,
            new PpiTableDataSetSelector().getAllForSurveyVersion(
                testSurvey.testSurveyVersion.Id
            ).size()
        );
    }

    /**
     *   This method is to validate the Distribute action when the survey Id is null
     */
    static testMethod void testDistributeNull(){
        Test.startTest();
            // Create the controller
            SurveyManagerController controller = new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));

            // If no survey was selected it shows an error
            controller.doAction = 'Distribute';
            controller.surveyIdAction = null;

            try{
                controller.doMoreAction();
                system.assert(false, 'Should have failed since no survey is set for action.');
            }catch (SurveyException e){
                system.assert(e.getMessage().equals(system.label.SURVEY_ERR_NULLREFERENCE));
            }
        Test.stopTest();
    }

    /**
     *   This method is to validate the Distribute action when the survey Id doesn't exists
     */
    static testMethod void testDistributeFake(){
        Test.startTest();
            // Create the controller
            SurveyManagerController controller = new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));

            // If a fake id was provided it should fail and show the salesforce message
            controller.doAction = 'Distribute';
            controller.surveyIdAction = '__Test__FakeId';
            try{
                controller.doMoreAction();
                system.assert(false,'This action should have failed');
            }
            catch(Exception e){
                system.assert(true);
            }
        Test.stopTest();
    }

    /**
     * This method is to validate the Distribute action with a valid survey
     */
    static testMethod void testDistributeValid(){
        // Create needed objects
        Survey__c survey = prepareDistributionData();

        Test.startTest();
            // Create the controller
            SurveyManagerController controller = new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));

            // When a survey is distributed the flag on the version should be set to "true"
            // Also the distributed date should be set
            controller.doAction = 'Distribute';
            controller.surveyIdAction = survey.Id;
            controller.doMoreAction();
        Test.stopTest();

        SurveyVersion__c version = [SELECT Id, Status__c, Distributed__c, DistributionDate__c
                                    FROM SurveyVersion__c
                                    WHERE Survey__c = :survey.Id];
        system.assert(version.Distributed__c, 'The distributed field should be set to \'true\'');
        system.assertNotEquals(null, version.DistributionDate__c);
        system.assertEquals(Date.today(), version.DistributionDate__c.date());
    }

    /**
     * This method is to validate the Distribution of a survey with a not valid license
     */
    static testMethod void testDistrubteNotLicense(){
        // Create needed objects
        Survey__c survey = prepareDistributionData();

        // Setting license to false
        LicenseSettings__c license = C.getLicense();
        license.Can_Distribute__c = false;
        update license;

        // Create the controller
        SurveyManagerController controller = new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));

        Test.startTest();
            controller.doAction = 'Distribute';
            controller.surveyIdAction = survey.Id;
            try{
                controller.doMoreAction();
                System.assert(false, 'This should trow an exception');
            }
            catch(SurveyException e){
                System.assert(e.getMessage().contains(System.label.SYSTEM_ERR_NOLICENSEPERMISSION));
            }
        Test.stopTest();

        // Select the actual version
        SurveyVersion__c version = [select Distributed__c, Survey__c from SurveyVersion__c where Survey__c = :survey.Id ORDER BY Version__c DESC LIMIT 1];

        // When a survey is not distributed the flag on the version should be set to "false"
        system.assertEquals(false, version.Distributed__c);

        //Select the json
        List<Attachment> att = [SELECT Id, Name, ParentId, Body
                                FROM Attachment
                                WHERE ParentId = :version.Id
                                      AND Name = :C.SURVEY_FILE_JSON];
        // Check if the json was not created
        system.assertEquals(0,att.size());
    }

    /**
     * Test the pagination of the surveys
     */
    static testMethod void testPagination(){
        Survey__c[] surveys = createSurveyList();

        Test.startTest();
            SurveyManagerController controller = new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
            system.assert(controller.pageSize == controller.MAX_ROWS_PER_PAGE);
            system.assert(controller.resultSize>0);

            system.assert(controller.hasNext);
            Integer actualPage = controller.pageNumber;
            controller.next();
            Integer nextPage = controller.pageNumber;
            system.assertNotEquals(actualPage, nextPage);
            system.assert(controller.hasPrevious);
            controller.previous();
        Test.stopTest();
        system.assertEquals(actualPage, controller.pageNumber);

    }

    /**
     * This method test the doMoreAction method for the "Clone" action of normal survey
     */
    static testMethod void testCloneAction() {

        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, true);
        Survey__c surveyToClone =
            (Survey__c) new SurveySelector().getRecordsByOnlyIdWithAllFields(
                new Set<Id>{testSurvey.testSurvey.Id}
            )[0];
        SurveyManagerController smc =
            new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
        smc.doAction = 'Clone';
        smc.surveyIdAction = surveyToClone.Id;
        smc.doMoreAction();
        Survey__c cloned =
            (Survey__c) new SurveySelector().getByName(
                System.label.CLONE_SURVEY_NAME + ' 1 ' + surveyToClone.Name,
                SObjectSelector.EQUALS_OPERATOR
            )[0];
        System.assertEquals(surveyToClone.PPIDataYear__c, cloned.PPIDataYear__c);
        System.assertEquals(surveyToClone.Deployment__c, cloned.Deployment__c);
        System.assertEquals(surveyToClone.IsPPI__c, cloned.IsPPI__c);
        System.assertEquals(surveyToClone.LanguageCode__c, cloned.LanguageCode__c);
        System.assertEquals(surveyToClone.Description__c, cloned.Description__c);
        System.assertEquals(surveyToClone.CountryCode__c, cloned.CountryCode__c);
        System.assertEquals(surveyToClone.Close_Message__c, cloned.Close_Message__c);

        // Verify normal cloned survey populates isCloned as true
        System.assert(cloned.isCloned__c);
    }

    /**
     * This method test the doMoreAction method for the "Clone" action of Use It
     * Draft Ppi Survey from Old Ppi Template
     */
    static testMethod void testCloneActionForOldUseItDraftPpiSurvey() {

        TestSurveyData childPpiUseItSurvey = TestSurveyData.createPpiTemplateWithoutDemographic();
        childPpiUseItSurvey.testSurvey.RemoteId__c = 'TestId';
        childPpiUseItSurvey.testSurvey.IsTemplate__c = false;
        SurveyDO surveyDOInstance = new SurveyDO();
        surveyDOInstance.addRecord(childPpiUseItSurvey.testSurvey);
        surveyDOInstance.updateRecords();

        Survey__c surveyToClone =
            (Survey__c) new SurveySelector().getRecordById(childPpiUseItSurvey.testSurvey.Id);

        System.assert(surveyToClone != null, 'Survey record not fetched properly');

        Test.startTest();
        SurveyManagerController surveyManager =
            new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
        surveyManager.doAction = 'Clone';
        surveyManager.surveyIdAction = surveyToClone.Id;
        surveyManager.doMoreAction();
        Test.stopTest();

        List<Survey__c> clonedSurveyList =
            (List<Survey__c>) new SurveySelector().getByName(
                System.label.CLONE_SURVEY_NAME + ' 1 ' + surveyToClone.Name,
                SObjectSelector.EQUALS_OPERATOR
            );

        // Page should have an error to indicate that old draft surveys cannot be cloned as it 
        // is linked to deprecated Ppi Templates
        System.assert(ApexPages.getMessages().size() > 0, 'Page sould contain an error message');
        System.assert(
            String.valueOf(
                ApexPages.getMessages()[0]).contains(
                    System.Label.ERR_CANNOT_CLONE_SURVEY_WITH_DEPRECATED_PPI_TEMPLATE
                )
            );
        System.assertEquals(0, clonedSurveyList.size());
    }

    /**
     * This method test the doMoreAction method for the "Clone" action of Use It
     * Published Ppi Survey from Old Ppi Template
     */
    static testMethod void testCloneActionForOldUseItPublishedPpiSurvey() {

        TestSurveyData childPpiUseItSurvey = TestSurveyData.createPpiTemplateWithoutDemographic();
        childPpiUseItSurvey.testSurvey.RemoteId__c = 'TestId';
        childPpiUseItSurvey.testSurvey.IsTemplate__c = false;
        SurveyDO surveyDOInstance = new SurveyDO();
        surveyDOInstance.addRecord(childPpiUseItSurvey.testSurvey);
        surveyDOInstance.updateRecords();

        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(
                new Set<String> {childPpiUseItSurvey.testSurvey.Id}
            );

        System.assert(surveyVersions.size() > 0, 'Survey Version should be fetched properly');

        // Updating version to Publish a survey
        surveyVersions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        SurveyVersionDomain surveyVersionDomainInstance = new SurveyVersionDomain();
        surveyVersionDomainInstance.addRecord(surveyVersions[0]);
        surveyVersionDomainInstance.updateRecords();

        Survey__c surveyToClone =
            (Survey__c) new SurveySelector().getRecordById(childPpiUseItSurvey.testSurvey.Id);

        System.assert(surveyToClone != null, 'Survey record not fetched properly');

        Test.startTest();
        SurveyManagerController surveyManager =
            new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
        surveyManager.doAction = 'Clone';
        surveyManager.surveyIdAction = surveyToClone.Id;
        surveyManager.doMoreAction();
        Test.stopTest();

        List<Survey__c> clonedSurveyList =
            (List<Survey__c>) new SurveySelector().getByName(
                System.label.CLONE_SURVEY_NAME + ' 1 ' + surveyToClone.Name,
                SObjectSelector.EQUALS_OPERATOR
            );

        // Page should have an error to indicate that old published surveys cannot be cloned as it 
        // is linked to deprecated Ppi Templates
        System.assert(ApexPages.getMessages().size() > 0, 'Page sould contain an error message');
        System.assert(
            String.valueOf(
                ApexPages.getMessages()[0]).contains(
                    System.Label.ERR_CANNOT_CLONE_SURVEY_WITH_DEPRECATED_PPI_TEMPLATE
                )
            );
        System.assertEquals(0, clonedSurveyList.size());
    }

    /**
     * This method test the doMoreAction method for the "Clone" action of Use It
     * PpiSurvey from New PPi Templates
     */
    static testMethod void testCloneActionForNewUseItPpiSurvey() {
        TestSurveyData childPpiUseItSurvey = TestSurveyData.createFullPpiTemplate();
        childPpiUseItSurvey.testSurvey.RemoteId__c = 'TestId';
        childPpiUseItSurvey.testSurvey.IsTemplate__c = false;
        SurveyDO surveyDOInstance = new SurveyDO();
        surveyDOInstance.addRecord(childPpiUseItSurvey.testSurvey);
        surveyDOInstance.updateRecords();

        Survey__c surveyToClone =
            (Survey__c) new SurveySelector().getRecordById(childPpiUseItSurvey.testSurvey.Id);

        System.assert(surveyToClone != null, 'Survey record not fetched properly');

        Test.startTest();
        SurveyManagerController surveyManager =
            new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
        surveyManager.doAction = 'Clone';
        surveyManager.surveyIdAction = surveyToClone.Id;
        surveyManager.doMoreAction();
        Test.stopTest();

        List<Survey__c> clonedSurveyList =
            (List<Survey__c>) new SurveySelector().getByName(
                System.label.CLONE_SURVEY_NAME + ' 1 ' + surveyToClone.Name,
                SObjectSelector.EQUALS_OPERATOR
            );

        System.assertEquals(1, clonedSurveyList.size());
        System.assertEquals(surveyToClone.PPIDataYear__c, clonedSurveyList[0].PPIDataYear__c);
        System.assertEquals(surveyToClone.Deployment__c, clonedSurveyList[0].Deployment__c);
        System.assertEquals(surveyToClone.IsPPI__c, clonedSurveyList[0].IsPPI__c);
        System.assertEquals(surveyToClone.LanguageCode__c, clonedSurveyList[0].LanguageCode__c);
        System.assertEquals(surveyToClone.Description__c, clonedSurveyList[0].Description__c);
        System.assertEquals(surveyToClone.CountryCode__c, clonedSurveyList[0].CountryCode__c);
        System.assertEquals(surveyToClone.Close_Message__c, clonedSurveyList[0].Close_Message__c);
    }

    /**
     * This method is to validate the creation of the json to distrubte when the survey is published
     */
    static testMethod void testUtilJsonSerialize() {

        //Preparing Survey to distribute
        SurveyUtils su = new SurveyUtils();
        SurveyManagerController smc =
            new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));

        // Setting license
        LicenseSettings__c license = C.getLicense();
        license.Can_Distribute__c = true;
        license.PPI_Editable__c = true;
        license.UsePPI__c = true;
        update license;

        TestSurveyData testSurvey = createPPISurvey();

        Test.startTest();

        //Indicate wich survey will be distributed
        smc.surveyIdAction = testSurvey.testSurvey.Id;
        smc.doAction = 'Distribute';
        smc.doMoreAction();
        Test.stopTest();

        //Selecting the json file to test
        List<Attachment> att = [
            SELECT
                Id, Name, ParentId, Body
            FROM
                Attachment
            WHERE
                ParentId = :testSurvey.testSurveyVersion.Id
                AND Name = :C.SURVEY_FILE_JSON
        ];

        // Testing json file
        System.assertEquals(1, att.size());
        System.assertEquals(
            att[0].Body.toString(),
            su.generateJsonFile(testSurvey.testSurveyVersion).Body.toString()
        );
    }

    /**
     * Test correct pages messages when doing some action on deleted surveys
     */
    static testMethod void testDoActionOnDeletedSurvey(){
        //Create a survey
        Survey__c survey = new Survey__c(Name = 'Test On Delete');
        insert survey;
        SurveyVersion__c surveyVersion = [select Id from SurveyVersion__c where Survey__c =:survey.Id];

        //delete the survey
        delete surveyVersion;
        delete survey;

        Test.startTest();
            //trying to do some action from the manager
            SurveyManagerController controller =  new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
            controller.surveyIdAction = survey.Id;
            controller.doAction = 'Clone';
            controller.doMoreAction();
        Test.stopTest();
        system.assert(ApexPages.hasMessages(ApexPages.severity.ERROR), 'There has to be a page error since the survey id is fake');
    }

    //------------------- Survey with Map and relations with removed objects or fields --------------------------------
    /**
     *  General consideration:
     *  We cannot remove a field or object in a test case, so what we do in order to simulate a removed object or field
     *  is to create a field or object with a wrong name (i.e. an object or field name cannot start with a number)
     *  so we are sure that no field or object is going to be named like that.
     *  When we look for that field or object will behave as a removed field or object.
     */

    /**
     * Test publish a survey that has some missing mapped object
     */
    static testMethod void publishSurveyWithMissingMappedObject() {
        // Create survey
        Survey__c survey = new Survey__c(Name = 'SubmissionTestMissingObject', Status__c = SurveyDO.STATUS_DRAFT);
        insert survey;

        // Create questions
        List<Question__c> questions = createQuestions(survey);

        SurveyVersion__c[] versions = [SELECT
                                            Status__c
                                        FROM
                                            SurveyVersion__c
                                        WHERE
                                            Survey__c = :survey.Id
                                        ORDER BY
                                            Version__c DESC];

        // Create survey mapping with a fake object name that behave as a deleted object.
        SurveyMapping__c sm = TestUtils.mapObject(survey, 'deletedObject');

        Test.startTest();
            SurveyManagerController smc = new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
            smc.surveyToPublish = survey.Id;
            smc.doPublish();
        Test.stopTest();

        // Remains in draft status and show info message to fix the survey.
        system.AssertEquals(surveyDO.STATUS_DRAFT, [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c DESC LIMIT 1].Status__c);
        system.AssertEquals(ApexPages.getMessages()[0].getDetail(), system.Label.ERR_SURVEY_PUBLISH_WRONGMAP);
    }

    /**
     * Test preview a survey that has some missing mapped object
     */
    static testMethod void previewSurveyWithMissingMappedObject(){
        // Create survey
        Survey__c survey = new Survey__c(Name = 'SubmissionTestMissingObject', Status__c = SurveyDO.STATUS_DRAFT);
        insert survey;

        // Create questions
        List<Question__c> questions = createQuestions(survey);

        SurveyVersion__c[] versions = [SELECT
                                            Status__c
                                        FROM
                                            SurveyVersion__c
                                        WHERE
                                            Survey__c = :survey.Id
                                        ORDER BY
                                            Version__c DESC];
        // Publish survey
        versions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        update versions;

        // Create survey mapping with a fake object name that behave as a deleted object.
        SurveyMapping__c sm = TestUtils.mapObject(survey, 'deletedObject');

        Test.startTest();
            SurveyManagerController smc = new SurveyManagerController();
            smc.goToPreview(survey.Id);
        Test.stopTest();

        // The survey was closed
        system.AssertEquals(surveyDO.STATUS_CLOSED, [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c DESC LIMIT 1].Status__c);
    }

    /**
     * To test deletion of cloned survey created from published survey
     */
    static testMethod void testDeletingClonedSurveyFromPublishedSurvey() {

        // Create new survey
        SurveyDO surveyDomainInstance =
            new SurveyDO.Constructor().constructWithRecords(
                new List<Survey__c> {
                    SurveyDOTest.createTestSurveyRecord()
                }
            );
        surveyDomainInstance.insertRecords();
        System.assertEquals(1, surveyDomainInstance.records.size());
        System.assert(surveyDomainInstance.records[0].Id != null);

        Survey__c surveyToClone = (Survey__c) surveyDomainInstance.records[0];
        System.assert(surveyToClone.Id != null);

        // Publish survey
        SurveyDO.publishSurvey(surveyToClone);
        surveyToClone = (Survey__c) new SurveySelector().getRecordById(surveyToClone.Id);
        System.assertEquals(SurveyDO.STATUS_PUBLISHED, surveyToClone.Status__c);
        System.assert(surveyToClone.PublishedDate__c != null);

        Test.startTest();
        SurveyManagerController controller =
            new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));

        // Clone survey
        controller.doAction = 'Clone';
        controller.surveyIdAction = surveyToClone.Id;
        controller.doMoreAction();
        Survey__c clonedSurvey =
            (Survey__c) new SurveySelector().getByName(
                System.label.CLONE_SURVEY_NAME + ' 1 ' + surveyToClone.Name,
                SObjectSelector.EQUALS_OPERATOR
            )[0];

        System.assert(clonedSurvey.Id != null);
        System.assertEquals(SurveyDO.STATUS_DRAFT, clonedSurvey.Status__c);
        System.assertEquals(null, clonedSurvey.PublishedDate__c);

        // Delete cloned survey
        controller.doAction = 'Delete';
        controller.surveyIdAction = clonedSurvey.Id;
        controller.doMoreAction();
        Test.stopTest();

        System.assertEquals(null, new SurveySelector().getRecordById(clonedSurvey.Id));
        System.assert(ApexPages.getMessages().size() == 0);
    }

    // Create questions to use in to the test cases
    static List<Question__c> createQuestions(Survey__c survey){
        Question__c qSection = new Question__c( Survey__c   = survey.Id,
                                                Name = 'section',
                                                Caption__c  = 'section',
                                                Type__c     = QuestionDO.TYPE_SECTION,
                                                Position__c = 1 );
        insert qSection;

        Question__c q1 = new Question__c( Survey__c   = survey.Id,
                                          Name        = 'q1',
                                          Caption__c  = 'q1',
                                          Type__c     = QuestionDO.TYPE_TEXT_SHORT,
                                          Position__c = 1,
                                          Parent__c   = qSection.Id );
        insert q1;

        return new List<Question__c>{qSection, q1};

    }

    // Utility method to compare two objects by the given fields
    static void compareObjectsFields(sObject object1, sObject object2, List<String> listOfFields){
        for(String field :listOfFields){
            system.assertEquals(object1.get(field), object2.get(field));
        }
    }
}