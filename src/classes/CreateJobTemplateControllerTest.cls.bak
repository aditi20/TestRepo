/**
*   Grameen: Salesforce - SF Field Force, SF - Jobs
*   Test for the CreateJobTemplateController
*   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*   @author Ernesto Quesada - equesada@altimetrik.com
*   @author Dennys Lopez - dlopez@altimetrik.com
*   @author Sebastian Piazza - spiazza@altimetrik.com
*   @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
*   @author Claudio Soto - csoto@altimetrik.com
*/
@isTest
public with sharing class CreateJobTemplateControllerTest {

    private static JobTemplate__c currentJobTemplate;

    static private CreateJobTemplateController prepareSaveTest() {

        // Create enviroment
        JobTemplate__c jobTemplate = new JobTemplate__c();
        ApexPages.Standardcontroller stdController = new ApexPages.StandardController(jobTemplate);
        CreateJobTemplateController controller = new CreateJobTemplateController(stdController);

        // Adding data
        jobTemplate.Name = 'newJob';
        jobTemplate.Instructions__c = 'Instructions';

        return controller;
    }

    static private TaskTemplate__c createTask(String name, Id form,Id jobTemplate,
        String mapping, String type, integer position) {
        TaskTemplate__c tsk1 = new TaskTemplate__c();
        tsk1.Form__c = form;
        tsk1.JobTemplate__c = jobTemplate;
        tsk1.Mapping__c = mapping;
        tsk1.Name = name;
        tsk1.Type__c= type;
        tsk1.Position__c = position;

        insert tsk1;

        return tsk1;
    }

    static private CreateJobTemplateController prepareEditTest(){
        //create enviroment
        currentJobTemplate = new JobTemplate__c();
        //adding data
        currentJobTemplate.Name = 'newJob';
        currentJobTemplate.Instructions__c = 'Instructions';
        currentJobTemplate.Hierarchy__c =
        '['+
        '{"listFields":["Birthdate"],"detailFields":["AssistantName"],"objectName":"Contact","objectId":"ejnm","label":"Contact"},'+
        '{"listFields":["Id"],"detailFields":["CaseNumber","Id"],"objectName":"Case","objectId":"j8ji","label":"Case","relations":[{"parent":"ejnm","field":"ContactId"}]}'+
        ']';
        insert currentJobTemplate;

        //create a test survey
        Survey__c surv = createTestSurvey('TestSurvey11');
        SurveyVersion__c version = [SELECT Id,Survey__c,Status__c FROM SurveyVersion__c WHERE Survey__c = :surv.Id];

        createTask('Task1',version.Id, currentJobTemplate.Id,
            '[{\"objectId\":\"ejnm\",\"field\":\"AssistantName\",\"question\":\"text1\"}]',TaskTemplateDO.TYPE_FORM,1);

        ApexPages.Standardcontroller stdController = new ApexPages.StandardController(currentJobTemplate);
        CreateJobTemplateController controller = new CreateJobTemplateController(stdController);

        return controller;
    }

    /**
     * Test the save methods of the controller
     */
    static testMethod void saveAndNewTest() {
        Test.startTest();
        CreateJobTemplateController controller = prepareSaveTest();
        controller.jsonTasksList = '';
        PageReference ref = controller.saveAndNew();
        Test.stopTest();

        System.assertEquals(1, [
            SELECT
                Id,
                Name,
                Instructions__c
            FROM
                JobTemplate__c
            WHERE
                Name = 'newJob'].size()
        );
        System.assert(ref.getUrl().endsWith('/e'));
    }

    /**
     * Test the save methods of the controller
     */
    static testMethod void saveTest(){
        Test.startTest();
            CreateJobTemplateController controller = prepareSaveTest();
            controller.jsonTasksList='';
            PageReference ref = controller.save();
        Test.stopTest();

        //assertions
        System.assertEquals(1, [SELECT Id,
                                       Name,
                                       Instructions__c
                                FROM JobTemplate__c
                                WHERE Name='newJob'].size());
        System.assert(ref.getUrl().endsWith('/o'));
    }

    public static Survey__c[] createSurveyList(){
        Survey__c[] surveys = new Survey__c[]{};
        SurveyVersion__c[] surveyVersions = new SurveyVersion__c[]{};
        for (Integer i = 1; i <= 25; i++){
            surveys.add(new Survey__c(Name = 'TestSurvey' + i));
        }
        insert surveys;

        return surveys;
    }

    /**
     * Test the save method with tasks
     */
    static testMethod void saveWithTasksTest() {

        CreateJobTemplateController controller = prepareSaveTest();

        // Create some forms
        SurveyManagerControllerTest.createSurveyList();

        SurveyVersion__c[] forms =
            [SELECT Id FROM SurveyVersion__c WHERE Survey__r.Name like 'TestSurvey%'];

        Test.startTest();
        controller.jsonTasksList='['+
            '{"Type":"' + TaskTemplateDO.TYPE_FORM + '","Name":"Task 1","instructions":"qwr","Position":1,'+
            '"Form":"'+forms[0].Id+'","Action":"' + TaskTemplateDO.ACTION_EDITED_ADDED + '"},'+
            '{"Type":"' + TaskTemplateDO.TYPE_FORM + '","Name":"Task 2","instructions":"qwr2","Position":2,'+
            '"Form":"'+forms[1].Id+'","Action":"' + TaskTemplateDO.ACTION_EDITED_ADDED + '"}]';

        PageReference ref = controller.save();
        Test.stopTest();

        JobTemplate__c[] jobT= [SELECT Id FROM JobTemplate__c WHERE Name ='newJob'];

        System.assertEquals(1, jobT.size());
        List<TaskTemplate__c> tasks = [
            SELECT
                Id,
                Type__c,
                Name,
                Instructions__c,
                Position__c,
                LastModifiedById,
                LastModifiedBy.Name,
                LastModifiedDate,
                Form__c
            FROM
                TaskTemplate__c
            WHERE
                JobTemplate__c = :jobT[0].Id
        ];

         System.assertEquals(2, tasks.size());

         System.assertEquals(TaskTemplateDO.TYPE_FORM, tasks[0].Type__c);
         System.assertEquals('Task 1', tasks[0].Name);
         System.assertEquals('qwr', tasks[0].Instructions__c);
         System.assertEquals(1, tasks[0].Position__c);
         System.assertEquals(forms[0].Id, tasks[0].Form__c);

         System.assertEquals(TaskTemplateDO.TYPE_FORM, tasks[1].Type__c);
         System.assertEquals('Task 2', tasks[1].Name);
         System.assertEquals('qwr2', tasks[1].Instructions__c);
         System.assertEquals(2, tasks[1].Position__c);
         System.assertEquals(forms[1].Id, tasks[1].Form__c);
    }

    /**
     * Test the save method with an invalid json of tasks, the job template should not be created
     */
    static testMethod void saveWithTasksInvalidJsonTest(){
        CreateJobTemplateController controller = prepareSaveTest();
        Test.startTest();
            //pass a json with an invalid form id
            controller.jsonTasksList='['+
            '{"Type":"' + TaskTemplateDO.TYPE_FORM + '","Name":"Task 1","Instructions":"qwr","Position":1,'+
            '"Form":"ajsldjflkasdjfj"}]';

            try{
                PageReference ref = controller.save();
                JobTemplate__c[] jobT= [SELECT Id FROM JobTemplate__c WHERE Name='newJob'];

                //since the tasklist have an error the job template should not be created
                System.assertEquals(0, jobT.size());
            }catch(Exception e){
                System.assert(true); // Invalid JSON failed
            }
        Test.stopTest();
    }

    /**
     * test method to verify loadObjectSelectList method is working correctly
     * must create a json object and then serialize it to a json string
     * this json object stores all the information from the objects from the org
     */
    static testMethod void testLoadObjectSelectList() {

        CreateJobTemplateController controller = prepareSaveTest();

        List<Map<String, String>> objects;

        Test.startTest();
        controller.loadObjectSelectList();
        String orgObjects = controller.orgObjects;
        Test.stopTest();

        objects = (List<Map<String, String>>) JSON.deserialize(
            orgObjects,
            List<Map<String, String>>.class
        );

        Set<String> expectedObjects = new Set<String>();
        for (String objectName : DescribeHandler.getGlobalDescribe().keySet()) {
            GenericObjectCreator creator = new GenericObjectCreator(objectName);
            if (creator.isObjectAccessible(false)) {
                if (
                        !C.forbiddenObjects.contains(objectName.toLowerCase()) &&
                        !C.objectsWithoutLastModifiedDateField.contains(objectName.toLowerCase())
                ) {
                    expectedObjects.add(objectName.toLowerCase());
                }
            }
        }
        System.assert(!objects.isEmpty(),'The object list should not be empty');
        if (expectedObjects.size() != objects.size()){
            Set<String> actualObjects = new Set<String>();
            Set<String> extraObjects = new Set<String>();
            Set<String> missingObjects = new Set<String>();

            // Find out what's the difference between the lists
            for(Map<String,String> orgObject : objects){
                String objectName = orgObject.get('name');
                actualObjects.add(objectName.toLowerCase());
            }

            extraObjects = actualObjects.clone();
            extraObjects.removeAll(expectedObjects);

            missingObjects = expectedObjects.clone();
            missingObjects.removeAll(actualObjects);

            System.assert(
                false,
                'Extra objects ' + extraObjects + ', missing objects ' + missingObjects
            );
        }
    }

    /**
     * Test method to verify loadObjectSelectList method is working correctly with permissions
     * It should not return object which is not accessible to user
     */
    static testMethod void testLoadObjectSelectListWithPermissionCheck() {

        CreateJobTemplateController controller = prepareSaveTest();

        List<Map<String, String>> objects;

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }

        Set<String> expectedObjects = new Set<String>();
        String orgObjects = '';
        System.runAs(chatterExternalUser) {
            Test.startTest();
            controller.loadObjectSelectList();
            orgObjects = controller.orgObjects;
            Test.stopTest();
            
            for (String objectName : DescribeHandler.getGlobalDescribe().keySet()) {
                GenericObjectCreator creator = new GenericObjectCreator(objectName);
                if (creator.isObjectAccessible(false)) {
                    if (
                            !C.forbiddenObjects.contains(objectName.toLowerCase()) &&
                            !C.objectsWithoutLastModifiedDateField.contains(objectName.toLowerCase())
                    ) {
                        expectedObjects.add(objectName.toLowerCase());
                    }
                }
            }
        }

        objects = (List<Map<String, String>>) JSON.deserialize(
            orgObjects,
            List<Map<String, String>>.class
        );

        System.assert(!objects.isEmpty(),'The object list should not be empty');
        if (expectedObjects.size() != objects.size()){
            Set<String> actualObjects = new Set<String>();
            Set<String> extraObjects = new Set<String>();
            Set<String> missingObjects = new Set<String>();

            // Find out what's the difference between the lists
            for(Map<String,String> orgObject : objects){
                String objectName = orgObject.get('name');
                actualObjects.add(objectName.toLowerCase());
            }

            extraObjects = actualObjects.clone();
            extraObjects.removeAll(expectedObjects);

            missingObjects = expectedObjects.clone();
            missingObjects.removeAll(actualObjects);

            System.assert(
                false,
                'Extra objects ' + extraObjects + ', missing objects ' + missingObjects
            );
        }
    }

    /**
     * test method to verify getDataFromObject method is working correctly
     * given a class passed as parameter on the 'nameObject' to the page
     * it must return the fields of that particular class
     */
    static testMethod  void testGetDataFromObject(){

        CreateJobTemplateController controller = prepareSaveTest();

        String name = 'Contact';
        Contact testContact=null;

        ApexPages.currentPage().getParameters().put('nameObject', name);

        List<SFieldTest> objectFields;
        String jsonStr;
        String orgObjectFields = '';

        Test.startTest();
            controller.getDataFromObject();
            jsonStr = controller.selectedObjectFieldsJson;
        Test.stopTest();

        JSONParser parser = JSON.createParser(jsonStr);
        objectFields = (List<SFieldTest>)parser.readValueAs(List<SFieldTest>.class);

        Map<String, Schema.SobjectField> fieldsMap = Schema.SObjectType.Contact.fields.getMap();


        System.assert(!objectFields.isEmpty(),'The objectFields list should not be empty');

        // Count field that can be mapped and assert they are all in the list.
        // Fields can be mapped if they are both updateable and createable, and not the OwnerId field
        Integer mappableFieldsCount = 0;
        for (Schema.SobjectField field : fieldsMap.values()){
            DescribeFieldResult f = field.getDescribe();
            if (!SurveyUtils.isGeoLocationComponentField(f.getName())) {
                if (f.getReferenceTo() == null || f.getReferenceTo().size() == 0){
                    mappableFieldsCount++;
                }
            }
        }
        System.assertEquals(mappableFieldsCount, objectFields.size());
    }

     /**
     * find an object hierarchy by object name
     * @param objectHiearchies list of object hierarchies
     * @param objectName
     * @return wheter the object hierarchy by the name "objectName" is in the collection or not
     */
    static boolean findInHierarchyByName(List<JobTemplateDO.ObjectHierarchy> objectHiearchies, String objectName){
        boolean found = false;
        integer i=0;
        while (i < objectHiearchies.size() && !found) {
            found = objectHiearchies[i].ObjectName == objectName;
            i++;
        }

        return found;
    }

    /**
     * find an object hierarchy by object id
     * @param objectHiearchies list of object hierarchies
     * @param objectId
     * @return wheter the object hierarchy by the id "objectId" is in the collection or not
     */
    static boolean findInHierarchyById(List<JobTemplateDO.ObjectHierarchy> objectHiearchies,
        String objectId){
        boolean found = false;
        integer i=0;
        while (i < objectHiearchies.size() && !found) {
            found = objectHiearchies[i].ObjectId == objectId;
            i++;
        }

        return found;
    }

    /**
     *  Test method to test an edition of a job template with previously loaded data
     */
    static testMethod  void testEditJobTemplate(){
        //prepare test data
        CreateJobTemplateController controller = prepareEditTest();

        //VERIFY LOADED DATA ON THE CONTROLLER

        // Verify object hierarchy
        Map<String, List<CreateJobTemplateController.SField>> mapSavedObjectFields = controller.mapSavedObjectFields;
        Map<String, List<CreateJobTemplateController.ObjectRelation>> mapPotentialObjects = controller.mapPotentialObjects;

        System.assert(!mapSavedObjectFields.isEmpty(), 'The mapSavedObjectFields list should not be empty');
        System.assert(!mapPotentialObjects.isEmpty(), 'The mapPotentialObjects list should not be empty');

        List<JobTemplateDO.ObjectHierarchy> objectHiearchies =
                 (List<JobTemplateDO.ObjectHierarchy>) JSON.deserialize(currentJobTemplate.Hierarchy__c, List<JobTemplateDO.ObjectHierarchy>.class);

        //verify mapppings were corrrectly generated for the objects in the hierarchies
        for(String objectName : mapSavedObjectFields.keySet()){
            System.assert(findInHierarchyByName(objectHiearchies, objectName),
              'Object ' + objectName + ' not found on the hierarchy');
            System.assert(!mapSavedObjectFields.get(objectName).isEmpty(),
                          'The list of fields for object "' + objectName + '" should not be empty');
        }

        for(String objectId : mapPotentialObjects.keySet()){
            System.assert(findInHierarchyById(objectHiearchies, objectId),
              'Object ' + objectId + ' not found on the hierarchy');
            System.assert(!mapPotentialObjects.get(objectId).isEmpty(),
                      'The list of object relation for object with id "' + objectId + '" should not be empty');
        }

        Test.startTest();
            //verify if task were correctly loaded
            List<CreateJobTemplateController.TaskTemplate> loadedTasksFromDB = controller.loadedTasksFromDB;
        Test.stopTest();

        System.assert(!loadedTasksFromDB.isEmpty(), 'The loadedTasksFromDB list should not be empty');

        List<TaskTemplate__c> tasks = [SELECT Type__c,
                                              Name,
                                              Instructions__c,
                                              Position__c,
                                              Form__c,
                                              Mapping__c,
                                              JobTemplate__c
                                        FROM TaskTemplate__c
                                        WHERE JobTemplate__c = :currentJobTemplate.Id];

        System.assertEquals(tasks[0].Name,loadedTasksFromDB[0].Name);
        System.assertEquals(tasks[0].Type__c,loadedTasksFromDB[0].Type);
        System.assertEquals(tasks[0].Instructions__c == null ? '' : tasks[0].Instructions__c,loadedTasksFromDB[0].Instructions);
        System.assertEquals(tasks[0].Position__c,loadedTasksFromDB[0].Position);
        System.assertEquals(tasks[0].Form__c,loadedTasksFromDB[0].Form);
        System.assertEquals(tasks[0].JobTemplate__c,loadedTasksFromDB[0].JobTemplate);
        System.assertEquals(tasks[0].Mapping__c,loadedTasksFromDB[0].Mapping);
    }

    /**
     *  Test method of getChildrenOfObject method.
     */
    static testMethod  void testGetChildrenOfObject(){
        CreateJobTemplateController controller = prepareSaveTest();

        String contactObject = 'Contact';
        Apexpages.currentPage().getParameters().put('parentObject', contactObject);

        Test.startTest();
        controller.getChildrenOfObject();
        List<TestObjectRelation> actualChildren =
            (List<TestObjectRelation>)JSON.deserialize(
                controller.childrenOfCurrentObject,
                List<TestObjectRelation>.class
            );
        Test.stopTest();

        Schema.DescribeSObjectResult contactDescribe = DescribeHandler.getObjectDescribeResult(contactObject, false);
        List<Schema.ChildRelationship> allChildren   = contactDescribe.getChildRelationships();
        Set<Schema.ChildRelationship> expectedChildren = new Set<Schema.ChildRelationship>();
        for (Schema.ChildRelationship rel : allChildren){
            if (
                    !C.isInBlacklist(rel.getChildSObject().getDescribe()) &&
                    !C.hasNotLastModifiedDate(rel.getChildSObject().getDescribe())
            ) {
                expectedChildren.add(rel);
            }
        }

        if (actualChildren.size() != expectedChildren.size()){
            Set<String> actualNames = new Set<String>();
            for (TestObjectRelation rel : actualChildren){
                actualNames.add(rel.relationshipName);
            }

            Set<String> expectedNames = new Set<String>();
            for (Schema.ChildRelationship rel : expectedChildren){
                expectedNames.add(rel.getRelationshipName());
            }

            Set<String> extraChildren = new Set<String>();
            Set<String> missingChildren = new Set<String>();

            extraChildren.addAll(actualNames);
            extraChildren.removeAll(expectedNames);

            missingChildren.addAll(expectedNames);
            missingChildren.removeAll(actualNames);

            System.assert(false, 'Extra objects ' + extraChildren + ', missing objects ' + missingChildren);
        }
        System.assertEquals(actualChildren.size(), expectedChildren.size());  // This test that the method return at least one
    }

    /**
     * wrapping class to store values of an SField when the json string value is deserialized on the testGetDataFromObject() test method
     **/
    private class SFieldTest{
        String name;
        String type;
        String label;
        String id;
        Boolean isSelected;
    }

    /**
     * Auxiliary method to create a test survey with diferent types of questions and sections
     * @param name Name of the test survey to be created
     * @return survey created.
     */
    private static Survey__c createTestSurvey(String name){
        Survey__c survey = TestUtils.createSurvey(name);

        //section1 1 question
        Question__c  section = TestUtils.addQuestion(survey,1,'s1',QuestionDO.TYPE_SECTION);
        TestUtils.addQuestion(section,1,'whole1',QuestionDO.TYPE_NUMBER_INTEGER);

        //section2 1 question
        Question__c  section2 = TestUtils.addQuestion(survey,2,'s2',QuestionDO.TYPE_REPEAT);
        TestUtils.addQuestion(section2,1,'text1',QuestionDO.TYPE_TEXT_SHORT);

        //section3 6 questions
        Question__c  section3 = TestUtils.addQuestion(survey,3,'s3',QuestionDO.TYPE_SECTION);

        TestUtils.addQuestion(section3, 1, 'whole', QuestionDO.TYPE_NUMBER_INTEGER);
        TestUtils.addQuestion(section3, 2, 'decimal', QuestionDO.TYPE_NUMBER_DECIMAL);
        TestUtils.addQuestion(section3, 3, 'text', QuestionDO.TYPE_TEXT_SHORT);
        TestUtils.addQuestion(section3, 4, 'time0', QuestionDO.TYPE_DATETIME);
        TestUtils.addQuestion(section3, 5, 'static', QuestionDO.TYPE_STATIC);
        TestUtils.addQuestion(section3, 6, 'final1', QuestionDO.TYPE_FINAL);
        TestUtils.addQuestion(section3, 7, 'gpsQuestion', QuestionDO.TYPE_GPS);

        return survey;
    }

    /**
    *    Class that represents an object relation in the test, it holds the name of the child object
    *    and the id field (external Id).
    */
    private class TestObjectRelation{
        String name;            // Name of the object.
        String relationshipName;// Actual name of the relationship
        String relationName;    // Name of the field that act as external Id.
        String relationLabel;   // Label of the field that act as external Id.
    }

    /**
     *  Method in charge of test setDeletedData and isAbleToSave methods.
     */
    static testMethod void setDeletedDataTest(){

        CreateJobTemplateController controller = prepareSaveTest();

        // We create a hierarchy with a real object but a fake field.
        String objectName      = Contact.SObjectType.getDescribe().getName();
        String objectLabel     = Contact.SObjectType.getDescribe().getLabel();
        String objectId        = '2erf';
        String listField       = String.valueOf(Contact.SObjectType.getDescribe().fields.getMap().Values()[0].getDescribe().getName());
        String fakeDetailField = String.valueOf('1fakeField');

        JobTemplateDO.ObjectHierarchy oh1 = new JobTemplateDO.ObjectHierarchy(objectId, objectLabel, objectName);
        oh1.addListField(listField);
        oh1.addDetailField(fakeDetailField);

        List<JobTemplateDO.ObjectHierarchy> listHierarchies = new List<JobTemplateDO.ObjectHierarchy>();
        listHierarchies.add(oh1);

        // Now we create the map of missing data.
        Map<String, RemovedDataValidation.MissingData> mapDataMissing =
            RemovedDataValidation.obtainMissingDataInBulkFromHierarchy(listHierarchies);

        test.startTest();
            controller.setDeletedData(mapDataMissing, listHierarchies);
        test.stopTest();

        // We must check that the deleted data is the fakeDetailField
        System.assert(ApexPages.getMessages()[0].getSummary().contains(fakeDetailField), 'The field was not the deleted data');
        // Also because the deleted field is not the relation, shouldButtonsBeDisabled attribute should be true
        // (user shouldn't be able to save or make changes).
        System.assert(controller.shouldButtonsBeDisabled, 'The field was a relation');
    }

    /**
     *  Method in charge of test hasNotDeletedData methods.
     */
    static testMethod void hasNotDeletedDataTest(){

        CreateJobTemplateController controller = prepareSaveTest();

        controller.shouldButtonsBeDisabled = true;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Message'));

        test.startTest();
            controller.hasNotDeletedData();
        test.stopTest();

        // Validate that shouldButtonsBeDisabled attribute is set to false;
        System.assert(!controller.shouldButtonsBeDisabled, 'The attribute "shouldButtonsBeDisabled" is true');
    }

    /**
     *  Method in charge of test hasDeletedRelation methods (JobTemplateDO).
     */
    static testMethod void hasDeletedRelationTest(){
        // We create a hierarchy with a real object and fields, but a fake relation.
        String objectName      = Contact.SObjectType.getDescribe().getName();
        String objectLabel     = Contact.SObjectType.getDescribe().getLabel();
        String objectId        = '2erf';
        String listField       = String.valueOf(Contact.SObjectType.getDescribe().fields.getMap().Values()[0].getDescribe().getName());
        String detailField     = String.valueOf(Contact.SObjectType.getDescribe().fields.getMap().Values()[1].getDescribe().getName());
        String fakeRelation    = String.valueOf('1fakeField');
        String fakeParentId    = '3rfd';

        JobTemplateDO.ObjectHierarchy oh1 = new JobTemplateDO.ObjectHierarchy(objectId, objectLabel, objectName);
        oh1.addListField(listField);
        oh1.addDetailField(detailField);
        oh1.addRelation(fakeParentId, fakeRelation);

        List<String> deletedFields = new List<String>{fakeRelation};

        test.startTest();
             Boolean isRelationDeleted = oh1.hasDeletedRelation(deletedFields);
        test.stopTest();

        System.assert(isRelationDeleted, 'The relation was not deleted');
    }

    /**
     *  Method in charge of test closeJobBecauseOfDeletedData methods.
     */
    static testMethod void closeJobBecauseOfDeletedDataTest(){

        CreateJobTemplateController controller = prepareSaveTest();

        // Create the hierarchy with the deleted data.
        String objectName      = Contact.SObjectType.getDescribe().getName();
        String objectLabel     = Contact.SObjectType.getDescribe().getLabel();
        String objectId        = '2erf';
        String listField       = '1fakeField';

        JobTemplateDO.ObjectHierarchy oh1 = new JobTemplateDO.ObjectHierarchy(objectId, objectLabel, objectName);
        oh1.addListField(listField);

        // Set the hierarchy to the job.
        List<JobTemplateDO.ObjectHierarchy> listHierarchies = new List<JobTemplateDO.ObjectHierarchy>{oh1};
        controller.job.Hierarchy__c = JSON.serialize(listHierarchies);

        // Assign it to the map of deleted data.
        controller.objectWithDeletedData =
            JSON.serialize(RemovedDataValidation.obtainMissingDataInBulkFromHierarchy(listHierarchies));

        test.startTest();
            controller.closeJobBecauseOfDeletedData();
        test.stopTest();

        // Validate that the job of the controller has JOB_AUTOMATICALLY_CLOSED as CloseReason__c
        System.assertEquals(controller.job.CloseReason__c, JobTemplateDO.JOB_AUTOMATICALLY_CLOSED);
        // Also validate that the job is closed.
        System.assertEquals(controller.job.Status__c, JobTemplateDO.STATUS_CLOSED);
    }

    /**
     *  Method in charge of test returnFilteredVersions methods.
     */
    static testMethod void returnFilteredVersionsTest(){

        List<CreateJobTemplateController.ResourceVersion> resourceList = CreateJobTemplateController.obtainResourcesFromLibrary();

        Id currentUserId     = UserInfo.getUserId();    // Obtain user Id.
        Id contentDocumentId = UserInfo.getUserId();    // Obtain ContentDocumentId (is not used in the test).

        // Obtain map of Content Document Id and User Id.
        Map<Id, Id> mapContentDocAuthor      = new Map<Id, Id>{contentDocumentId => currentUserId};
        // Obtain the map with format: <User.Id, User>.
        Map<Id,User> userMap                 = new Map<Id, User>([SELECT Id, Name From User WHERE Id = :currentUserId]);
        // Create a list of ContentVersion (with the following file names: "someFile.mp4", "some.Fi.Le.3gp" and "someFile." ).
        List<ContentVersion> contentVersions = TestUtils.createListContentVersion();

        List<CreateJobTemplateController.ResourceVersion> secondResourceList = CreateJobTemplateController.returnFilteredVersions(contentVersions, mapContentDocAuthor, userMap);

        // ------ Assert section-------

        System.assertEquals(0, resourceList.size());        // Cannot retrieve Versions because cannot create Workspaces on tests.
        System.assertEquals(2, secondResourceList.size());  // Retrieve two versions (the one with the dot at the end does not passes the filter).
        // First retrieved object has one of the files that passed the filter.
        System.assert(secondResourceList[0].file.contains('someFile.mp4'), 'The first Content version has some other file name' );
        // Second retrieved object has one of the files that passed the filter.
        System.assert(secondResourceList[1].file.contains('some.Fi.Le.3gp'), 'The second Content version has some other file name' );

        // ------ /Assert section-------
    }

    /**
     *  Test method to test a cloning of an existing job
     */
    static testMethod  void testCloneJobTemplate() {
        // Prepare test data
        CreateJobTemplateController controller = prepareSaveTest();
        controller.jsonTasksList = '';
        Test.startTest();
        controller.cloneJob();
        Test.stopTest();

        List<JobTemplate__c> jobs = [
            SELECT
                Id,
                Status__c,
                Name,
                Instructions__c,
                Hierarchy__c,
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
                        Form__r.Status__c,
                        Mapping__c,
                        Form__r.Survey__c,
                        ResourceId__c
                    FROM
                        Task_Templates__r
                )
            FROM
                JobTemplate__c
            WHERE
                Name = 'newJob'
            ORDER BY Id
        ];

        // Assert Job values
        System.assertEquals(2, jobs.size());
        System.assertEquals(
            jobs[0].Name,
            jobs[1].Name,
            'the field value should be the same'
        );
        System.assertEquals(
            jobs[0].Instructions__c,
            jobs[1].Instructions__c,
            'the field value should be the same'
        );
        System.assertEquals(jobs[0].Hierarchy__c,
            jobs[1].Hierarchy__c,
            'the field value should be the same'
        );
        System.assertEquals(
            jobs[0].Status__c,
            JobTemplateDO.STATUS_DRAFT,
            'the field value should be Draft'
        );

        for (TaskTemplate__c task:jobs[0].Task_Templates__r) {
            System.assertEquals(task.Name, jobs[1]. Task_Templates__r[0].Name);
            System.assertEquals(task.Type__c, jobs[1]. Task_Templates__r[0].Type__c);
            System.assertEquals(task.Instructions__c, jobs[1]. Task_Templates__r[0].Instructions__c);
            System.assertEquals(task.Position__c, jobs[1]. Task_Templates__r[0].Position__c);
            System.assertEquals(task.Object__c, jobs[1]. Task_Templates__r[0].Object__c);
            System.assertEquals(task.Form__c, jobs[1]. Task_Templates__r[0].Form__c);
            System.assertEquals(task.Mapping__c, jobs[1]. Task_Templates__r[0].Mapping__c);
        }
    }
}