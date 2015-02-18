/**
 * This class will test:
 *     -Proper display of the question List.
 *     -Proper Load of the objects dropdown lists.
 *     -Proper Load of the Field dropdown lists.
 *     -Proper Save of the chosen data.
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
private class SurveyFieldMappingControllerTest {
    static final string OBJ_CONTACT = 'Contact';
    static final string OBJ_ACCOUNT = 'Account';

    /**
     * Main test
     */
    static testMethod void mainTest() {
        LicenseSettings__c testWithLicense = newLicense(false,'Test1');
        insert testWithLicense;

        // Needed enviroment
        Survey__c survey1 = TestUtils.createSurvey('FirstSurvey');
        Question__c sec1 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
        Question__c sec2 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2);
        insert new Question__c[]{sec1,sec2};

        Question__c qlname = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'lname','Last name',1);
        Question__c qbday = newQuestion(survey1,sec1,QuestionDO.TYPE_DATE,'bday','Birthdate',2);
        Question__c qdept = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'dept','Department',3);
        Question__c qdesc = newQuestion(survey1,sec2,QuestionDO.TYPE_TEXT_SHORT,'desc','Description',1);
        Question__c qasst = newQuestion(survey1,sec2,QuestionDO.TYPE_TEXT_SHORT,'asst','Assistant Name',2);
        Question__c qcurr = newQuestion(survey1,sec2,QuestionDO.TYPE_NUMBER_INTEGER,'curr','Currency',3);
        insert new Question__c[]{qlname,qbday,qdept,qdesc,qasst,qcurr};

        //This List is right ordered, sections by positions and the corresponding questions after each section.
        //Section1 -> sectionQ1 - sectionQ2... | Section2 -> section2Q1 - section2Q2 ....
        Question__c[] testQuestions =  new Question__c[]{sec1,qlname,qbday,qdept,sec2,qdesc,qasst,qcurr};

        SelectOption[] fields = new SelectOption[]{};
        for (String fieldName : DescribeHandler.getFieldMap(OBJ_CONTACT).keySet()) {
            Schema.DescribeFieldResult fieldResult =
                DescribeHandler.getFieldDescribe(OBJ_CONTACT, fieldName);
            fields.add(new SelectOption(fieldResult.getName(),fieldResult.getLabel()));
        }

        Test.startTest();
        SurveyFieldMappingController controller = new SurveyFieldMappingController( new ApexPages.StandardController(survey1) );

        // Check if the controller have load all the nedded data to create the new mappings.
        System.assertEquals(testQuestions.size(),controller.questions.size());
        for (Integer i = 0; i<controller.questions.size(); i++) {

            // Check if the questions in the controller are well ordered
            System.assertEquals(testQuestions[i].Caption__c, controller.questions[i].question.Caption__c);
        }
        Test.stopTest();
    }

    /**
     * test method to verify loadObjectSelectList method is working correctly
     * must create a json object and then serialize it to a json string
     * this json object stores all the information from the objects from the org
     */
    static testmethod void testLoadObjectSelectListForNonPpiSurvey() {

        Survey__c newSurvey = initSurvey();
        ApexPages.StandardController stdController = new ApexPages.StandardController(newSurvey);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        Test.startTest();
        controller.loadObjectSelectList();
        String jsonHeaderCols = controller.headerColumnsJson;

        List<Map <String, String>> objects = (List<Map<String, String>>)
            JSON.deserialize(jsonHeaderCols, List<Map<String, String>>.class);
        Test.stopTest();

        List<Schema.SObjectType> objectsWithoutPrefix = new List<Schema.SObjectType>();
        List<Schema.SObjectType> objectsWithPrefix = new List<Schema.SObjectType>();
        for (Schema.sObjectType objectType : DescribeHandler.getGlobalDescribe().values()) {
            GenericObjectCreator creator =
                new GenericObjectCreator(objectType.getDescribe().getName());
            if (creator.isObjectAccessible(false)) {
                if (!C.hasNameSpacePrefix(objectType) ||
                        (
                            C.whiteListedObjects.contains(
                                objectType.getDescribe().getName().toLowerCase()
                            ) &&
                            controller.isSurveyPPI
                        )
                ) {
                    objectsWithoutPrefix.add(objectType);
                }
            }
        }

        System.assert(objects.size() > 0,'There object list should not be empty');
        System.assertEquals(objectsWithoutPrefix.size(), objects.size());

        Integer i = 0;
        SFDCEncoder encoder = new SFDCEncoder();
        Boolean containsPpiResultObject = false;
        for (Schema.SObjectType field : objectsWithoutPrefix) {
            Map<String, String> mapOfObjectDetails = objects[i];
            System.assertEquals(
                mapOfObjectDetails.get('name'),
                encoder.SFDC_JSENCODE(field.getDescribe().getName())
            );
            System.assertEquals(
                mapOfObjectDetails.get('label'),
                encoder.SFDC_JSENCODE(field.getDescribe().getLabel())
            );
            if (
                C.hasNameSpacePrefix((mapOfObjectDetails.get('name'))) &&
                    (mapOfObjectDetails.get('name')).equalsIgnoreCase(
                        PpiResult__c.sObjectType.getDescribe().getName()
                    )
            ) {
                containsPpiResultObject = true;
            }
            i++;
        }

        System.assert(
            !containsPpiResultObject,
            'PpiResult object should not be present for Non Ppi Survey'
        );
    }

    /**
     * Test method to verify objects are loaded properly along with PpiResult object for PPI Survey
     */
    static testmethod void testLoadObjectSelectListForPpiSurvey() {
        // Create a PPI related survey
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        Test.startTest();
        controller.loadObjectSelectList();
        String jsonHeaderCols = controller.headerColumnsJson;

        List<Map <String, String>> objects = (List<Map<String, String>>)
            JSON.deserialize(jsonHeaderCols, List<Map<String, String>>.class);
        Test.stopTest();

        List<Schema.SObjectType> objectList = new List<Schema.SObjectType>();
        for (Schema.sObjectType objectType : DescribeHandler.getGlobalDescribe().values()) {
            GenericObjectCreator creator =
                new GenericObjectCreator(objectType.getDescribe().getName());
            if (creator.isObjectAccessible(false)) {
                if (!C.hasNameSpacePrefix(objectType) ||
                        (
                            C.whiteListedObjects.contains(
                                objectType.getDescribe().getName().toLowerCase()
                            ) &&
                            controller.isSurveyPPI
                        )
                ) { 
                    objectList.add(objectType);
                }
            }
        }

        System.assert(objects.size() > 0, 'There object list should not be empty');
        System.assertEquals(objectList.size(), objects.size());

        Integer i = 0;
        Boolean containsPpiResultObject = false;
        for (Schema.SObjectType objectDetails : objectList) {
            Map<String, String> mapOfObjectDetails = objects[i];
            if (
                (mapOfObjectDetails.get('name')).equalsIgnoreCase(
                    PpiResult__c.sObjectType.getDescribe().getName()
                )
            ) {
                containsPpiResultObject = true;
            }
            i++;
        }

        System.assert(
            containsPpiResultObject,
            'PpiResult object should be present for a Ppi Survey'
        );
    }

    /**
     * Test method to verify loadObjectSelectList method is working correctly with permissions
     */
    static testmethod void testLoadObjectSelectListWithPermissionCheck(){

        Survey__c newSurvey = initSurvey();
        ApexPages.StandardController stdController = new ApexPages.StandardController(newSurvey);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        List<map<String, String>> objects;

        String jsonHeaderCols;
        String orgObjects = '';

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }

        List<Schema.SObjectType> objectsWithOutPrefix = new List<Schema.SObjectType>();
        System.runAs(chatterExternalUser) {
            Test.startTest();
            controller.loadObjectSelectList();
            jsonHeaderCols = controller.headerColumnsJson;

            objects = (List<Map<String, String>>)
                JSON.deserialize(jsonHeaderCols, List<Map<String, String>>.class);
            Test.stopTest();

            for (Schema.sObjectType objectType : DescribeHandler.getGlobalDescribe().values()) {
                GenericObjectCreator creator =
                    new GenericObjectCreator(objectType.getDescribe().getName());
                if (creator.isObjectAccessible(false)) {
                    if (!C.hasNameSpacePrefix(objectType) ||
                            (
                                C.whiteListedObjects.contains(
                                    objectType.getDescribe().getName().toLowerCase()
                                ) &&
                                controller.isSurveyPPI
                            )
                    ) {
                        objectsWithOutPrefix.add(objectType);
                    }
                }
            }
        }

        System.assert(objects.size() > 0,'There object list should not be empty');
        System.assertEquals(objectsWithOutPrefix.size(), objects.size());
    }

    /**
     * wrapping class to store values of an SField when the json string value is deserialized on the testGetDataFromObject() test method
     */
    private class SFieldTest{
        String name;
        String type;
        String label;
        Boolean required;
        List<RelatedTo> relatedTo;
        Integer length;
    }

    private class RelatedTo {
        String relationType;
        String name;
        String label;
    }
    /**
     * test method to verify getDataFromObject method is working correctly
     * given a class passed as parameter on the 'nameObject' to the page
     * it must return the fields of that particular class
     */
    static testmethod void testGetDataFromObject() {

        SFDCEncoder encode = new SFDCEncoder();

        Survey__c newSurvey = initSurvey();

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);

        ApexPages.StandardController stdController = new ApexPages.StandardController(newSurvey);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        String name = 'Contact';
        Contact testContact=null;

        ApexPages.currentPage().getParameters().put('nameObject', name);
        ApexPages.currentPage().getParameters().put('selectClass', '');

        Test.startTest();
        controller.getDataFromObject();
        List<SFieldTest>  objectFields = (List<SFieldTest>)JSON.deserialize(
            controller.selectedObjectFieldsJson,
            List<SFieldTest>.class
        );
        Test.stopTest();

        Map<String, Schema.SobjectField> fieldsMap = Schema.SObjectType.Contact.fields.getMap();
        System.assert(!objectFields.isEmpty(),'The objectFields list should not be empty');

        // Count field that can be mapped and assert they are all in the list.
        // Fields can be mapped if they are both updateable and createable
        // and are not the OwnerId field
        Integer mappableFieldsCount = 0;
        for (Schema.SobjectField field : fieldsMap.values()) {
            DescribeFieldResult f = field.getDescribe();
            if ((f.isUpdateable() && f.isCreateable() && f.getName() != 'OwnerId' && 
               !f.getName().contains('Latitude__s') && !f.getName().contains('Longitude__s')) || 
               f.getType().name() == 'LOCATION') {
                mappableFieldsCount++;
            }
        }
        System.assertEquals(mappableFieldsCount, objectFields.size());

        String query = 'SELECT ';
        for (SFieldTest field : objectFields) {
            Schema.SObjectField sfield = fieldsMap.get(field.name);
            query += field.name + ',';
            System.assertEquals(
                encode.SFDC_JSENCODE(String.valueOf(sfield.getDescribe().getType())),
                field.type
            );
            System.assertEquals(
                encode.SFDC_JSENCODE(String.valueOf(sfield.getDescribe().getName())),
                field.name
            );
            System.assertEquals(
                encode.SFDC_JSENCODE(String.valueOf(sfield.getDescribe().getLabel())),
                field.label
            );

            if (field.type == 'Integer') {
                system.assertEquals(field.length, sfield.getDescribe().getDigits());
            }

            if (field.type == 'Reference') {
                system.assertNotEquals(null, field.relatedTo);
            }
        }

        query = query.substring(0, query.lastIndexOf(','));
        query += ' FROM '+ name + ' LIMIT 1';
        try {
            List<Contact> testQueryResult = Database.query(query);
        }
        catch (Exception ex) {
            System.assert(
                false,
                'The database query should not fail, that means the fields are invalid'
            );
        }
    }

    /**
     * Test method to verify fields of PpiResult object should not contain any namespace fields
     */
    static testmethod void testFetchPpiResultFields() {
        Survey__c newSurvey = initSurvey();

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(newSurvey);
        SurveyFieldMappingController controller =
            new SurveyFieldMappingController(stdController);

        String name = PpiResult__c.sObjectType.getDescribe().getName();

        ApexPages.currentPage().getParameters().put('nameObject', name);
        ApexPages.currentPage().getParameters().put('selectClass', '');

        Test.startTest();
        controller.getDataFromObject();
        List<SFieldTest>  objectFields = (List<SFieldTest>) JSON.deserialize(
            controller.selectedObjectFieldsJson,
            List<SFieldTest>.class
        );
        Test.stopTest();

        for (SFieldTest fieldInstance : objectFields) {
            System.assert(
                !fieldInstance.name.contains(name.split('_')[0]),
                'Fields with namespace should not be displayed'
            );
        }
    }

    /**
     * testMethod to verify the saveData shows an error when not all required fields are mapped
     */
    static testmethod void testNotAllRequiredFieldsMapped() {

        String expectedErrorMessage = 'Missing required field, error validating in client side.';

        // Create a test survey with 2 sections and some questions
        Survey__c survey1 = TestUtils.createSurvey('SurveyTestSaveData');
        Question__c sec1 =
            newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
        Question__c sec2 =
            newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2);
        insert new Question__c[]{sec1, sec2};

        Question__c qlname =
            newQuestion(survey1, sec1, QuestionDO.TYPE_TEXT_SHORT, 'lname', 'Last name', 1);
        Question__c qbday =
            newQuestion(survey1, sec1, QuestionDO.TYPE_DATETIME, 'bday', 'Birthdate', 2);
        Question__c qdept =
            newQuestion(survey1, sec1, QuestionDO.TYPE_TEXT_SHORT, 'dept', 'Department', 3);

        Question__c qasst =
            newQuestion(survey1, sec2, QuestionDO.TYPE_TEXT_SHORT, 'asst', 'Assistant Name', 1);
        Question__c qcurr =
            newQuestion(survey1, sec2, QuestionDO.TYPE_NUMBER_INTEGER,'curr','Currency',2);
        Question__c qgender =
            newQuestion(survey1, sec2, QuestionDO.TYPE_RADIO, 'gender', 'Gender', 3);
        insert new Question__c[]{qlname, qbday, qdept, qasst, qcurr, qgender};

        Option__c op1 = new Option__c(
            Name = 'Male',
            Caption__c = 'Male',
            Question__c = qgender.Id,
            Position__c = 1
        );
        Option__c op2 = new Option__c(
            Name = 'Female',
            Caption__c = 'Female',
            Question__c = qgender.Id,
            Position__c = 2
        );
        insert new Option__c[]{op1, op2};

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);

        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        String sid = survey1.id;

        SurveyFieldMappingController.SurveyMappingObject[] mappings =
            new SurveyFieldMappingController.SurveyMappingObject[] {
                newSurveyMapping('sc1', 'User', '-', sid, false),
                newSurveyMapping('sc2', 'Vote', '-', sid, false)
            };

        mappings[0].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{ 
            newQuestionMapping('City', qdept.id, 'sc1',false)
        };
        mappings[1].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[] {
            newQuestionMapping('Type', qgender.id, 'sc2',true),
            newQuestionMapping('CreatedDate', qbday.id, 'sc2',true)
        };

        String jsonToSend = JSON.serialize(mappings);

        String jsonDataToSave =
            Apexpages.currentPage().getParameters().put('jsonData', jsonToSend);

        Test.startTest();
        try {
            controller.saveData();
            System.assert(false);
        } catch (SurveyFieldMappingController.AllRequiredFieldsException ex) {
            System.assertEquals(expectedErrorMessage, ex.getMessage());
        }
        Test.stopTest();
    }

    /**
     * Test verify the saveData method is working correctly with related objects
     */
    static testmethod void testSaveDataWithRelatedObjects() {

        // create a test survey with 2 sections and some questions
        Survey__c survey1 = TestUtils.createSurvey('SurveyTestSaveData');
        Question__c sec1 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
        Question__c sec2 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2);
        insert new Question__c[]{sec1,sec2};

        Question__c qlname = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'lname','Last name',1);
        Question__c qbday = newQuestion(survey1,sec1,QuestionDO.TYPE_DATETIME,'bday','Birthdate',2);
        Question__c qdate = newQuestion(survey1,sec1,QuestionDO.TYPE_DATE,'qdate','Another Date',3);
        Question__c qdept = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'dept','Department',4);
        Question__c qbcode = newQuestion(survey1,sec1,QuestionDO.TYPE_BARCODE,'bcode','Bar Code',5);

        Question__c qdesc = newQuestion(survey1,sec2,QuestionDO.TYPE_TEXT_LONG,'desc','Description',1);
        Question__c qasst = newQuestion(survey1,sec2,QuestionDO.TYPE_TEXT_SHORT,'asst','Assistant Name',2);
        Question__c qcurr = newQuestion(survey1,sec2,QuestionDO.TYPE_NUMBER_DECIMAL,'curr','Currency',3);
        Question__c qnumber = newQuestion(survey1,sec2,QuestionDO.TYPE_NUMBER_INTEGER,'numb','Number',4);
        Question__c qcheck = newQuestion(survey1,sec2,QuestionDO.TYPE_CHECKBOX,'qcheck','Checkbox',5);

        Question__c qgender = newQuestion(survey1,sec2,QuestionDO.TYPE_RADIO,'gender','Gender',6);
        Question__c qstatus = newQuestion(survey1,sec2,QuestionDO.TYPE_RADIO,'status','Status',7);

        insert new Question__c[]{qlname,qbday,qdept,qdesc,qasst,qcurr,qgender,qdate,qcheck,qbcode,qnumber,qstatus};

        Option__c op1 = new Option__c(Name = 'Male', Caption__c = 'Male', Question__c = qgender.Id, Position__c = 1);
        Option__c op2 = new Option__c(Name = 'Female', Caption__c = 'Female', Question__c = qgender.Id, Position__c = 2);
        insert new Option__c[]{op1,op2};

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        String sid = survey1.id;

        SurveyFieldMappingController.SurveyMappingObject[] mappings =
            new SurveyFieldMappingController.SurveyMappingObject[]{
                newSurveyMapping('sc1', 'Task', '-', sid, false),
                newSurveyMapping('sc2', 'Vote', '-', sid, false),
                newSurveyMapping('sc3', 'Contact', '-', sid, false),
                newSurveyMapping('sc4', 'Asset', '-', sid, false)
        };

        mappings[0].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
                newQuestionMapping('Priority', qgender.id, 'sc1',true),
                newQuestionMapping('Status', qstatus.id, 'sc1',true)
        };
        mappings[1].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
                newQuestionMapping('Type', qgender.id, 'sc2',true),
                newQuestionMapping('CreatedDate', qbday.id, 'sc2',true)
        };
        mappings[2].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
                newQuestionMapping('AssistantName', qcurr.id, 'sc3',false),
                newQuestionMapping('Name', qlname.id, 'sc3',true),
                newQuestionMapping('LastName', qdept.id, 'sc3',true)
        };
        mappings[3].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
                newQuestionMapping('InstallDate', qdate.id, 'sc4',false),
                newQuestionMapping('Status', qgender.id, 'sc4',false),
                newQuestionMapping('Name', qdept.id, 'sc4',true)
        };

        SurveyFieldMappingController.Relation childTask = new SurveyFieldMappingController.Relation();
        childTask.child = 'sc1';
        childTask.fieldsRelated = new List<String>();
        childTask.fieldsRelated.add('WhoId');

        List<SurveyFieldMappingController.Relation> contactChilds= new List<SurveyFieldMappingController.Relation>();
        contactChilds.add(childTask);

        SurveyFieldMappingController.ParentObject parentContact = new SurveyFieldMappingController.ParentObject();
        parentContact.parent = 'sc3';
        parentContact.relationObjects = contactChilds;

        mappings[0].objectRelation = parentContact; // set task as child of contact

        String jsonToSend = JSON.serialize(mappings);

        String jsonDataToSave = Apexpages.currentPage().getParameters().put('jsonData',jsonToSend);

        Test.startTest();
        controller.saveData();
        Test.stopTest();

        SurveyMapping__c surveyContact = [
            SELECT
                Id
            FROM
                SurveyMapping__c
            WHERE
                Survey__c = :survey1.Id
                AND ObjectApiName__c = 'Contact'
            LIMIT 1
        ];
        SurveyMapping__c surveyTask = [
            SELECT
                Id
            FROM
                SurveyMapping__c
            WHERE
                Survey__c = :survey1.id
                AND ObjectApiName__c = 'Task'
            LIMIT 1
        ];

        System.assertEquals(
            1,
            [
                SELECT
                    ParentSurveyMapping__c,
                    FieldApiName__c,
                    ChildSurveyMapping__c
                FROM
                    ObjectRelationshipMapping__c
                WHERE
                    ParentSurveyMapping__c = :surveyContact.Id
                    AND FieldApiName__c = 'WhoId'
                    AND ChildSurveyMapping__c = :surveyTask.id
            ].size()
        );
    }

    /**
     * Test to verify the saveData method is working correctly,
     * this method takes as a parameter on the request the survey and question mappings in json format
     * and it stores this mappings with the survey referenced on the jsonData
     */
    static testmethod void testSimpleSaveData(){

        // create a test survey with 2 sections and some questions
        Survey__c survey1 = TestUtils.createSurvey('SurveyTestSaveData');
        Question__c sec1 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
        Question__c sec2 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2);
        insert new Question__c[]{sec1,sec2};

        Question__c qlname = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'lname','Last name',1);
        Question__c qbday = newQuestion(survey1,sec1,QuestionDO.TYPE_DATETIME,'bday','Birthdate',2);
        Question__c qdept = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'dept','Department',3);

        Question__c qdesc = newQuestion(survey1,sec2,QuestionDO.TYPE_TEXT_LONG,'desc','Description',1);
        Question__c qasst = newQuestion(survey1,sec2,QuestionDO.TYPE_TEXT_SHORT,'asst','Assistant Name',2);
        Question__c qcurr = newQuestion(survey1,sec2,QuestionDO.TYPE_NUMBER_INTEGER,'curr','Currency',3);

        Question__c qgender = newQuestion(survey1,sec2,QuestionDO.TYPE_RADIO,'gender','Gender',4);
        Question__c qstatus = newQuestion(survey1,sec2,QuestionDO.TYPE_RADIO,'status','Status',5);

        insert new Question__c[]{qlname,qbday,qdept,qdesc,qasst,qcurr,qgender,qstatus};

        Option__c op1 = new Option__c(Name = 'Male', Caption__c = 'Male', Question__c = qgender.Id, Position__c = 1);
        Option__c op2 = new Option__c(Name = 'Female', Caption__c = 'Female', Question__c = qgender.Id, Position__c = 2);
        insert new Option__c[]{op1,op2};

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        String sid = survey1.id;

        SurveyFieldMappingController.SurveyMappingObject[] mappings =
            new SurveyFieldMappingController.SurveyMappingObject[]{
                newSurveyMapping('sc1', 'Task', '-', sid, false),
                newSurveyMapping('sc2', 'Vote', '-', sid, false)
        };

        mappings[0].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
                newQuestionMapping('Description', qdesc.id, 'sc1',false),
                newQuestionMapping('Priority', qgender.id, 'sc1',true),
                newQuestionMapping('Status', qstatus.id, 'sc1',true)
        };
        mappings[1].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
                newQuestionMapping('Type', qgender.id, 'sc2',true),
                newQuestionMapping('CreatedDate', qbday.id, 'sc2',true)
        };

        String jsonToSend = JSON.serialize(mappings);

        String jsonDataToSave = Apexpages.currentPage().getParameters().put('jsonData',jsonToSend);

        Test.startTest();
        controller.saveData();
        Test.stopTest();

        //verify survey mappings are correcttly associated to the current survey 'survey1'
        SurveyMapping__c[] surveyMapping1=[Select Id From SurveyMapping__c where Survey__c = :survey1.id and ObjectApiName__c= 'Task'];
        SurveyMapping__c[] surveyMapping2=[Select Id From SurveyMapping__c where Survey__c = :survey1.id and ObjectApiName__c= 'Vote'];
        system.assertEquals(1,surveyMapping1.size());
        system.assertEquals(1,surveyMapping2.size());

        //verify question mappings are correctly associated to the surveyMapping, the corresponding questions and the fieldApiName is what is suppose to
        QuestionMapping__c[] questionMap11 = [Select Id From QuestionMapping__c where SurveyMapping__c =:surveyMapping1[0].id and Question__c=:qgender.id and FieldApiName__c='Priority'];
        QuestionMapping__c[] questionMap12 = [Select Id From QuestionMapping__c where SurveyMapping__c =:surveyMapping1[0].id and Question__c=:qstatus.id and FieldApiName__c='Status'];
        QuestionMapping__c[] questionMap13 = [Select Id From QuestionMapping__c where SurveyMapping__c =:surveyMapping1[0].id and Question__c=:qdesc.id and FieldApiName__c='Description'];

        QuestionMapping__c[] questionMap21 = [Select Id From QuestionMapping__c where SurveyMapping__c =:surveyMapping2[0].id and Question__c=:qgender.id and FieldApiName__c='Type'];
        QuestionMapping__c[] questionMap22 = [Select Id From QuestionMapping__c where SurveyMapping__c =:surveyMapping2[0].id and Question__c=:qbday.id and FieldApiName__c='CreatedDate'];

        system.assertEquals(1,questionMap11.size());
        system.assertEquals(1,questionMap12.size());
        system.assertEquals(1,questionMap13.size());
        system.assertEquals(1,questionMap21.size());
        system.assertEquals(1,questionMap22.size());
    }

    /**
     * Test to verify the saveData method throws an exception when the json mapping is invalid
     */
    static testmethod void testSaveDataInvalidMapping(){

        // create a test survey with 2 sections and some questions
        Survey__c survey1 = TestUtils.createSurvey('SurveyTestSaveData');
        Question__c sec1 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
        Question__c sec2 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2);
        insert new Question__c[]{sec1,sec2};

        Question__c qlname = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'lname','Last name',1);
        Question__c qbday = newQuestion(survey1,sec1,QuestionDO.TYPE_DATE,'bday','Birthdate',2); // question_type_date for invalid mapping
        Question__c qdept = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'dept','Department',3);

        Question__c qdesc = newQuestion(survey1,sec2,QuestionDO.TYPE_TEXT_LONG,'desc','Description',1);
        Question__c qasst = newQuestion(survey1,sec2,QuestionDO.TYPE_TEXT_SHORT,'asst','Assistant Name',2);
        Question__c qcurr = newQuestion(survey1,sec2,QuestionDO.TYPE_NUMBER_INTEGER,'curr','Currency',3);

        Question__c qgender = newQuestion(survey1,sec2,QuestionDO.TYPE_RADIO,'gender','Gender',4);
        Question__c qstatus = newQuestion(survey1,sec2,QuestionDO.TYPE_RADIO,'status','Status',5);

        insert new Question__c[]{qlname,qbday,qdept,qdesc,qasst,qcurr,qgender,qstatus};

        Option__c op1 = new Option__c(Name = 'Male', Caption__c = 'Male', Question__c = qgender.Id, Position__c = 1);
        Option__c op2 = new Option__c(Name = 'Female', Caption__c = 'Female', Question__c = qgender.Id, Position__c = 2);
        insert new Option__c[]{op1,op2};

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        String sid = survey1.id;

        SurveyFieldMappingController.SurveyMappingObject[] mappings =
            new SurveyFieldMappingController.SurveyMappingObject[]{
                newSurveyMapping('sc1', 'Task', '-', sid, false),
                newSurveyMapping('sc2', 'Vote', '-', sid, false)
        };

        mappings[0].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
                newQuestionMapping('Description', qdesc.id, 'sc1',false),
                newQuestionMapping('Priority', qgender.id, 'sc1',true),
                newQuestionMapping('Status', qstatus.id, 'sc1',true)
        };
        mappings[1].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
                newQuestionMapping('Type', qgender.id, 'sc2',true),
                newQuestionMapping('CreatedDate', qbday.id, 'sc2',true) //since createDate is of type datetime this is an invalid mapping
        };

        String jsonToSend = JSON.serialize(mappings);

        String jsonDataToSave = Apexpages.currentPage().getParameters().put('jsonData',jsonToSend);


        //      START TEST

        boolean error = false;

        Test.startTest();
            try {
                controller.saveData();
            }
            catch (Exception e){
                error = true;
            }
        Test.stopTest();
        //      VERIFYING

        system.assert(error,'The saveData method should fail since an invalid mapping was passed as parameter');
    }

    /**
     * Test to verify the saveData method is working correctly,
     * This test method inserts more survey mappings and more question mappings, and calls several times to saveData,
     * and then verifies the result of savedata is what is suppose to be
     */
    static testmethod void testSaveDataComplex() {

        // Create a test survey with 2 sections and some questions
        Survey__c survey1 = TestUtils.createSurvey('SurveyTestSaveData');
        Question__c sec1 = newQuestion(
            survey1, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1
        );
        Question__c sec2 = newQuestion(
            survey1, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2
        );
        insert new List<Question__c>{sec1, sec2};

        Question__c qlname = newQuestion(
            survey1, sec1, QuestionDO.TYPE_TEXT_SHORT, 'lname', 'Last name', 1
        );
        Question__c qbday = newQuestion(
            survey1, sec1, QuestionDO.TYPE_DATETIME, 'bday', 'Birthdate', 2
        );
        Question__c qdate = newQuestion(
            survey1, sec1, QuestionDO.TYPE_DATE, 'qdate', 'Another Date', 3
        );
        Question__c qdept = newQuestion(
            survey1, sec1, QuestionDO.TYPE_TEXT_SHORT, 'dept','Department', 4
        );
        Question__c qbcode = newQuestion(
            survey1, sec1, QuestionDO.TYPE_BARCODE, 'bcode', 'Bar Code', 5
        );

        Question__c qdesc = newQuestion(
            survey1, sec2, QuestionDO.TYPE_TEXT_LONG, 'desc', 'Description', 1
        );
        Question__c qasst = newQuestion(
            survey1, sec2, QuestionDO.TYPE_TEXT_SHORT, 'asst', 'Assistant Name', 2
        );
        Question__c qcurr = newQuestion(
            survey1, sec2, QuestionDO.TYPE_NUMBER_DECIMAL, 'curr', 'Currency', 3
        );
        Question__c qnumber = newQuestion(
            survey1, sec2, QuestionDO.TYPE_NUMBER_INTEGER, 'numb', 'Number', 4
        );
        Question__c qcheck = newQuestion(
            survey1, sec2, QuestionDO.TYPE_CHECKBOX, 'qcheck', 'Checkbox', 5
        );

        Question__c qgender = newQuestion(
            survey1, sec2, QuestionDO.TYPE_RADIO, 'gender', 'Gender', 6
        );
        Question__c qstatus = newQuestion(
            survey1, sec2, QuestionDO.TYPE_RADIO, 'status', 'Status', 7
        );

        insert new List<Question__c>{
            qlname, qbday, qdept, qdesc, qasst, qcurr, qgender,
            qdate, qcheck, qbcode, qnumber, qstatus
        };

        Option__c op1 = new Option__c(
            Name = 'Male', Caption__c = 'Male', Question__c = qgender.Id, Position__c = 1
        );
        Option__c op2 = new Option__c(
            Name = 'Female', Caption__c = 'Female', Question__c = qgender.Id, Position__c = 2
        );
        insert new List<Option__c>{op1, op2};

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        String sid = survey1.id;

        SurveyFieldMappingController.SurveyMappingObject[] mappings =
            new SurveyFieldMappingController.SurveyMappingObject[]{
                newSurveyMapping('sc1', 'Task', '-', sid, false),
                newSurveyMapping('sc2', 'Vote', '-', sid, false),
                newSurveyMapping('sc3', 'Contact', '-', sid, false),
                newSurveyMapping('sc4', 'Asset', '-', sid, false)
            };

        mappings[0].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
            newQuestionMapping('Priority', qgender.id, 'sc1',true),
            newQuestionMapping('Status', qstatus.id, 'sc1',true)
        };
        mappings[1].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
            newQuestionMapping('Type', qgender.id, 'sc2',true),
            newQuestionMapping('CreatedDate', qbday.id, 'sc2',true)
        };
        mappings[2].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
            newQuestionMapping('AssistantName', qcurr.id, 'sc3',false),
            newQuestionMapping('Name', qlname.id, 'sc3',true),
            newQuestionMapping('LastName', qdept.id, 'sc3',true)
        };
        mappings[3].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
            newQuestionMapping('InstallDate', qdate.id, 'sc4',false),
            newQuestionMapping('Status', qgender.id, 'sc4',false),
            newQuestionMapping('Name', qdept.id, 'sc4',true)
        };

        String jsonToSend = JSON.serialize(mappings);

        Apexpages.currentPage().getParameters().put('jsonData',jsonToSend);

        List<SurveyFieldMappingController.SurveyMappingObject> mappingsToVerify =
            new List<SurveyFieldMappingController.SurveyMappingObject>();

        Test.startTest();

        // First call to save data to insert some mappings
        controller.saveData();

        for (SurveyFieldMappingController.SurveyMappingObject mapping : mappings) {
            mappingsToVerify.add(mapping);
        }

        SurveyFieldMappingController.SurveyMappingObject[] mappings2 =
            new List<SurveyFieldMappingController.SurveyMappingObject>{
                newSurveyMapping('sc5', 'Solution', '-', sid, false)
            };
        mappings2[0].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[]{
            newQuestionMapping('SolutionNote', qbcode.id, 'sc5', true),
            newQuestionMapping('TimesUsed', qnumber.id, 'sc5', true),
            newQuestionMapping('Status', qgender.id, 'sc5', true),
            newQuestionMapping('SolutionName', qdept.id, 'sc5', true)
        };

        for (SurveyFieldMappingController.SurveyMappingObject mapping : mappings2) {
            mappingsToVerify.add(mapping);
        }

        Apexpages.currentPage().getParameters().put('jsonData', JSON.serialize(mappings2));

        // Second call is to insert new mappings
        controller.saveData();
        Test.stopTest();

        // Parse the result
        String jsonResult2= controller.mappedSurveys;
        JSONParser parser2 = JSON.createParser(jsonResult2);
        List<SurveyFieldMappingController.ExistentSurveyMapping> result2 =
            (List<SurveyFieldMappingController.ExistentSurveyMapping>)
        parser2.readValueAs(List<SurveyFieldMappingController.ExistentSurveyMapping>.class);

        System.assert(result2.size() > 0, 'ExistentSurveyMapping list should not be empty');

        // Verify the new mappings have been added
        SurveyMapping__c[] surveyMapping1 = [
            SELECT
                Id
            FROM
                SurveyMapping__c
            WHERE
                Survey__c = :survey1.id
                AND ObjectApiName__c = 'Solution'
            ];
        System.assertEquals(1, surveyMapping1.size());

        // Verify question mappings are correctly associated to the surveyMapping,
        // the corresponding questions and the fieldApiName is what is suppose to
        QuestionMapping__c[] questionMap11 = [
            SELECT
                Id
            FROM
                QuestionMapping__c
            WHERE
                SurveyMapping__c = :surveyMapping1[0].id
                AND Question__c = :qbcode.id
                AND FieldApiName__c = 'SolutionNote'
        ];
        System.assertEquals(1, questionMap11.size());
        QuestionMapping__c[] questionMap12 = [
            SELECT
                Id
            FROM
                QuestionMapping__c
            WHERE
                SurveyMapping__c = :surveyMapping1[0].id
                AND Question__c = :qnumber.id
                AND FieldApiName__c = 'TimesUsed'
        ];
        System.assertEquals(1, questionMap12.size());
        System.assertEquals(mappingsToVerify.size(), result2.size());

        // Verify the final result is correct
        Integer okMappings = 0;
        Set<Id> surveyMapsIds = new Set<Id>();
        Set<Id> questionMappingsIds = new Set<Id>();

        for (Integer i = 0; i < result2.size(); i++) {
            surveyMapsIds.add(result2[i].surveyMap.id);
            for(Integer k = 0; k < result2[i].listQuestionMapping.size(); k++) {
                questionMappingsIds.add(result2[i].listQuestionMapping[k].Id);
            }
        }

        SurveyMapping__c[] surveyMappings = [
            SELECT
                Id
            FROM
                SurveyMapping__c
            WHERE
                Id in :surveyMapsIds
        ];
        QuestionMapping__c[] questionMappings = [
            SELECT
                Id
            FROM
                QuestionMapping__c
            WHERE
                Id in :questionMappingsIds
        ];
        System.assertEquals(surveyMapsIds.size(), surveyMappings.size());
        System.assertEquals(questionMappingsIds.size(), questionMappings.size());
    }

    /**
     * Test to verify the saveData method is working correctly,
     * This test method inserts more survey mappings and more question mappings, then modifies the existent mappings
     * and then verifies the result of savedata is what is suppose to be
     */
     static testmethod void testSaveDataModifyMapping() {

        // Create a test survey with 2 sections and some questions
        Survey__c survey1 = TestUtils.createSurvey('SurveyTestSaveData');
        Question__c sec1 =
            newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
        Question__c sec2 =
            newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2);
        Question__c sec3 =
            newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section3', 'section3', 3);
        insert new List<Question__c>{sec1, sec2, sec3};

        Question__c qlname =
            newQuestion(survey1, sec1, QuestionDO.TYPE_TEXT_SHORT, 'lname', 'Last Name', 1);
        Question__c qbday =
            newQuestion(survey1, sec1, QuestionDO.TYPE_DATETIME, 'bday', 'Birthdate', 2);
        Question__c qdate =
            newQuestion(survey1, sec1, QuestionDO.TYPE_DATE, 'qdate', 'Another Date', 3);
        Question__c qdept =
            newQuestion(survey1, sec1,QuestionDO.TYPE_TEXT_SHORT,'dept', 'Department', 4);
        Question__c qdesc =
            newQuestion(survey1, sec1, QuestionDO.TYPE_TEXT_LONG, 'desc', 'Description', 15);
        Question__c qbcode =
            newQuestion(survey1, sec1, QuestionDO.TYPE_BARCODE, 'bcode', 'Bar Code', 5);

        Question__c qasst =
            newQuestion(survey1, sec2, QuestionDO.TYPE_TEXT_SHORT, 'asst', 'Assistant Name', 2);
        Question__c qcurr =
            newQuestion(survey1, sec2, QuestionDO.TYPE_NUMBER_DECIMAL, 'curr', 'Currency', 3);
        Question__c qnumber =
            newQuestion(survey1, sec2, QuestionDO.TYPE_NUMBER_INTEGER, 'numb', 'Number', 4);
        Question__c qcheck =
            newQuestion(survey1, sec1, QuestionDO.TYPE_CHECKBOX, 'qcheck', 'Checkbox', 16);
        Question__c qstatus =
            newQuestion(survey1, sec2, QuestionDO.TYPE_RADIO, 'status', 'Status', 7);

        // Add the cascading and its corresponding questions
        Question__c qgender =
            newQuestion(survey1, sec2, QuestionDO.TYPE_RADIO, 'gender', 'Gender', 6);
        insert new List<Question__c>{
            qbday,
            qdept,
            qasst,
            qcurr,
            qgender,
            qdate,
            qbcode,
            qnumber,
            qstatus,
            qcheck,
            qlname,
            qdesc
        };
        Option__c op1 = new Option__c(
            Name = 'Male',
            Caption__c = 'Male',
            Question__c = qgender.Id,
            Position__c = 1
        );
        Option__c op2 = new Option__c(
            Name = 'Female',
            Caption__c = 'Female',
            Question__c = qgender.Id,
            Position__c = 2
        );
        insert new List<Option__c>{op1, op2};

        CascadingSelect__c cascadingSelect = TestUtils.createCascadingSelect('cascadingSelect');
        Question__c parentCascading = new Question__c(
            Survey__c = survey1.Id,
            Parent__c = sec1.Id,
            Name = 'cascadingQuestion',
            Caption__c = 'cascadingQuestion',
            Position__c = 8,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            CascadingSelect__c  = cascadingSelect.Id
        );
        insert parentCascading;
        List<CascadingLevel__c> cascadingLevels =
            TestUtils.createCascadingLevels(cascadingSelect, 5);

        List<Question__c> cascadingLevelsQuestions =
            TestUtils.createQuestionsforCascading(survey1.Id, parentCascading, cascadingLevels);

        TestUtils.createCascadingValues(cascadingLevels, 5);

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        String sid = survey1.id;

        SurveyFieldMappingController.SurveyMappingObject[] mappings =
            new List<SurveyFieldMappingController.SurveyMappingObject> {
                newSurveyMapping('sc1', 'Task', '-', sid, false),
                newSurveyMapping('sc2', 'Vote', '-', sid, false),
                newSurveyMapping('sc3', 'Contact', '-', sid, false),
                newSurveyMapping('sc4', 'Asset', '-', sid, false)
            };

        mappings[0].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[] {
                newQuestionMapping('Priority', qgender.id, 'sc1',true),
                newQuestionMapping('Status', qstatus.id, 'sc1',true)
        };
        mappings[1].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[] {
                newQuestionMapping('Type', qgender.id, 'sc2',true),
                newQuestionMapping('CreatedDate', qbday.id, 'sc2',true)
        };
        mappings[2].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[] {
                newQuestionMapping('AssistantName', qcurr.id, 'sc3',false),
                newQuestionMapping('Name', qlname.id, 'sc3',true),
                newQuestionMapping('LastName', qdept.id, 'sc3',true),
                newQuestionMapping('Department', cascadingLevelsQuestions[0].Id, 'sc3',true),
                newQuestionMapping('Description', cascadingLevelsQuestions[1].Id, 'sc3',true)
        };
        mappings[3].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[] {
                newQuestionMapping('InstallDate', qdate.id, 'sc4',false),
                newQuestionMapping('Status', qgender.id, 'sc4',false),
                newQuestionMapping('Name', qdept.id, 'sc4',true)
        };

        String jsonToSend = JSON.serialize(mappings);

        Apexpages.currentPage().getParameters().put('jsonData',jsonToSend);

        List<SurveyFieldMappingController.SurveyMappingObject> mappingsToVerify =
            new List<SurveyFieldMappingController.SurveyMappingObject>();

        // First call to save data to insert some mappings
        Test.startTest();
        controller.saveData();
        String jsonResult1 = controller.mappedSurveys;

        //parse the result
        JSONParser parser1 = JSON.createParser(jsonResult1);
        List<SurveyFieldMappingController.ExistentSurveyMapping> result1 =
            (List<SurveyFieldMappingController.ExistentSurveyMapping>)
        parser1.readValueAs(List<SurveyFieldMappingController.ExistentSurveyMapping>.class);

        system.assertEquals(4,result1.size());

        //modify existing mappings
        SurveyFieldMappingController.SurveyMappingObject[] mappingsToModify =
            new SurveyFieldMappingController.SurveyMappingObject[]{
                newSurveyMapping(result1[0].surveyMap.id, 'Task', '-', sid, false),
                newSurveyMapping(result1[1].surveyMap.id, '-1', '-', sid, false),
                newSurveyMapping(result1[2].surveyMap.id, 'Contact', '-', sid, false),
                newSurveyMapping(result1[3].surveyMap.id, 'Asset', '-', sid, false)
        };

        mappingsToModify[0].questionMapping =
            new List<SurveyFieldMappingController.QuestionMappingObject>{
                newQuestionMapping('Description', qdesc.id, result1[0].surveyMap.id, false),
                newQuestionMapping(
                    'RecurrenceStartDateOnly',
                    qdate.id,
                    result1[0].surveyMap.id,
                    false
                ),
                newQuestionMapping('Priority', qgender.id, result1[0].surveyMap.id,true),
                newQuestionMapping('Status', qstatus.id, result1[0].surveyMap.id,true)
            };
        mappingsToModify[1].questionMapping =
            new List<SurveyFieldMappingController.QuestionMappingObject>{
                newQuestionMapping('-1', qgender.id, result1[1].surveyMap.id,true),
                newQuestionMapping('-1', qbday.id, result1[1].surveyMap.id,true)
            };
        mappingsToModify[2].questionMapping =
            new List<SurveyFieldMappingController.QuestionMappingObject>{
                newQuestionMapping('MailingCity', qcurr.id, result1[2].surveyMap.id,false),
                newQuestionMapping(
                    'mobilesurveys_Id__c ',
                    qcheck.id,
                    result1[2].surveyMap.id,
                    false
                ),
                newQuestionMapping(
                    'Description',
                    cascadingLevelsQuestions[0].Id,
                    result1[2].surveyMap.id,
                    true
                ),
                newQuestionMapping(
                    'Department',
                    cascadingLevelsQuestions[1].Id,
                    result1[2].surveyMap.id,
                    true
                ),
                newQuestionMapping('Name', qlname.id, result1[2].surveyMap.id,true),
                newQuestionMapping('LastName', qdept.id, result1[2].surveyMap.id,true)
            };
        mappingsToModify[3].questionMapping =
            new List<SurveyFieldMappingController.QuestionMappingObject>{
                newQuestionMapping('PurchaseDate', qdate.id, result1[3].surveyMap.id, false),
                newQuestionMapping('-1', qgender.id, result1[3].surveyMap.id,false),
                newQuestionMapping('Name', qdept.id, result1[3].surveyMap.id,true)
            };

        Apexpages.currentPage().getParameters().put('jsonData', JSON.serialize(mappingsToModify));

        // Second call is to modify existing mappings
        controller.saveData();

        //parse the result
        String jsonResult2= controller.mappedSurveys;
        JSONParser parser2 = JSON.createParser(jsonResult2);
        Test.stopTest();

        List<SurveyFieldMappingController.ExistentSurveyMapping> finalResult =
            (List<SurveyFieldMappingController.ExistentSurveyMapping>)
            parser2.readValueAs(List<SurveyFieldMappingController.ExistentSurveyMapping>.class);

        // Verify the survey mapping for Vote has been deleted
        System.assertEquals(0, [
            SELECT
                Id
            FROM
                SurveyMapping__c
            WHERE
                Survey__c = :survey1.Id
                AND ObjectApiName__c = 'Vote'
        ].size());

        System.assert(
            finalResult.size() > 0,
            'The final result from modifying the original mapping should not be empty'
        );

        // Verify the result of the calls to saveData is what is suppose to be
        System.assertEquals(
            mappings.size() - 1,
            finalResult.size()
        );

        // Verify the question mappings had been modified and/or deleted
        List<SurveyMapping__c> smTask = getSurveyMappings(result1[0].surveyMap.Id);
        List<SurveyMapping__c> smContact = getSurveyMappings(result1[2].surveyMap.Id);
        List<SurveyMapping__c> smAsset = getSurveyMappings(result1[3].surveyMap.Id);

        System.assertEquals(1, smTask.size());
        System.assertEquals(1, smContact.size());
        System.assertEquals(1, smAsset.size());

        List<QuestionMapping__c> qmTask1 =
            getQuestionMappings(smTask[0].Id, qdesc.Id, 'Description');
        List<QuestionMapping__c> qmTask2 =
            getQuestionMappings(smTask[0].Id, qdate.Id, 'RecurrenceStartDateOnly');

        System.assertEquals(1, qmTask1.size());
        System.assertEquals(1, qmTask2.size());

        List<QuestionMapping__c> qmContact1 =
            getQuestionMappings(smContact[0].Id, qcurr.Id, 'MailingCity');
        List<QuestionMapping__c> qmContact2 =
            getQuestionMappings(smContact[0].Id, qcheck.Id, 'mobilesurveys_Id__c');
        List<QuestionMapping__c> qmContact3 =
            getQuestionMappings(smContact[0].Id, cascadingLevelsQuestions[0].Id, 'Description');
        List<QuestionMapping__c> qmContact4 =
            getQuestionMappings(smContact[0].Id, cascadingLevelsQuestions[1].Id, 'Department');


        System.assertEquals(1, qmContact1.size());
        System.assertEquals(1, qmContact2.size());
        System.assertEquals(1, qmContact3.size());
        System.assertEquals(1, qmContact4.size());

        List<QuestionMapping__c> qmAsset1 =
            getQuestionMappings(smAsset[0].Id, qdate.Id, 'PurchaseDate');
        List<QuestionMapping__c> qmAsset2 = [
            SELECT
                Id
            FROM
                QuestionMapping__c
            WHERE
                SurveyMapping__c =: smAsset[0].id
                AND Question__c = :qgender.id
        ];

        System.assertEquals(1, qmAsset1.size());

        // The field mapping for question gender associated with the asset
        // survey mapping has been deleted
        System.assertEquals(0, qmAsset2.size());

        QuestionMapping__c qm = [
            SELECT
                Id,
                FieldApiName__c,
                Question__c,
                SurveyMapping__c
            FROM
                QuestionMapping__c WHERE Id = :finalResult[0].listQuestionMapping[0].Id
            LIMIT 1
        ];

        // Verify QuestionMappingObject constructor
        SurveyFieldMappingController.QuestionMappingObject qmo =
            new SurveyFieldMappingController.QuestionMappingObject(qm);
        System.assertEquals(qm.FieldApiName__c, qmo.mappedFieldName);
        System.assertEquals(qm.Question__c, qmo.questionId);
        System.assertEquals(qm.SurveyMapping__c, qmo.relatedHeaderCombo);
    }

    /**
     * Utility Method to create a list of 980 questions associated to a survey
     * with their correspondent sections sec1 and sec2
     */
    static private List<Question__c> initQuestionsToInsert(
            Survey__c survey,
            List<Question__c> sections
    ) {

        List<Question__c> result = new List<Question__c>();
        Integer indexPosition = 1;
        for (Question__c section : sections) {
            for (Integer i = 0; i < 140; i++) {
                result.add(
                    newQuestion(
                        survey,
                        section,
                        QuestionDO.TYPE_TEXT_SHORT,
                        'TextShort_' + indexPosition,
                        'TextShort_' + indexPosition,
                        indexPosition++
                    )
                );
            }
        }
        return result;
    }

    /**
     * Test to verify the saveData method is working correctly with more than 1000 questions,
     * This test method inserts more than 1000 questions
     * and then verifies the result of savedata is what is suppose to be
     */
    static testmethod void testSaveData1000Questions() {

        // Create a test survey with 2 sections and some questions
        Survey__c survey1 = TestUtils.createSurvey('SurveyTestSaveData');
        Question__c sec1 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
        Question__c sec2 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2);
        Question__c sec3 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section3', 'section3', 3);
        Question__c sec4 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section4', 'section4', 4);
        Question__c sec5 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section5', 'section5', 5);
        Question__c sec6 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section6', 'section6', 6);
        Question__c sec7 = newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section7', 'section7', 7);

        insert new Question__c[]{sec1,sec2,sec3,sec4,sec5,sec6,sec7};

        // Insert 980 questions
        List<Question__c> toInsert = initQuestionsToInsert(
            survey1,
            new Question__C[]{
               sec1, sec2, sec3, sec4, sec5, sec6, sec7
            }
        );
        insert toInsert;

        String sid = survey1.id;

        Set<ID> questionsToVerify  = new Set<Id>();

        List<SurveyFieldMappingController.SurveyMappingObject> mappings =
        new List<SurveyFieldMappingController.SurveyMappingObject>();

        // Try to map the most numbers of questions
        Integer mappingsIndex = 0;
        Integer globalQMIndex = 0;

        Integer txtIndexStart = 0; // index pointer to text type questions
        Integer dateIndexStart = 250; // index pointer to date type questions
        Integer numberIndexStart = 500; // index pointer to number type questions
        Integer dateTimeIndexStart = 750; // index pointer to dateTime type questions
        Integer numberDecimalIndexStart = 1000; // index pointer to number decimal type questions
        Integer pickListIndexStart = 1250; // index pointer to picklist type questions
        Integer txtLongIndexStart = 1500; // index pointer to text-long type questions

        //multiple global describes to contact
        List<String> objectsToMap = new List<String>{};
        Schema.DescribeSObjectResult oDescribe = Account.SObjectType.getDescribe();

        Map<String, String> questionIdNameMap = new Map<String, String>();

        Integer unmappedObjects = 0;
        Integer mappedObjects = 0;

        while (mappingsIndex < objectsToMap.size() && globalQMIndex < 1000) {
            Integer indexM = mappings.size();
            String classSel = 'sc'+(indexM+1);

            String objectToMap = oDescribe.getName();
            // The field BODY is of type BASE64 which cannot be mapped with anything and it's required
            // We exclude this because it cannot be mapped with anything.
            if (objectToMap.toLowerCase() != 'mailmergetemplate') {

                mappings.add(newSurveyMapping(classSel, objectToMap, '', sid, false));
                Map<String, Schema.SObjectField> objectFields =
                    DescribeHandler.getFieldMap(objectsToMap[mappingsIndex]);
                mappings[indexM].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[objectFields.size()];

                Integer indexQM = 0;
                for(Schema.SObjectField sfield : objectFields.Values())
                {
                    schema.describefieldresult dfield = sfield.getDescribe();

                    String type  = String.valueOf(dfield.getType()).toLowerCase();
                    String name  = String.valueOf(dfield.getName());
                    String label = String.valueOf(dfield.getLabel());
                    Boolean required = !dfield.isNillable();
                    String relatedTo='';

                     if(dfield.getReferenceTo() != null &&  dfield.getReferenceTo().size()!=0)
                        relatedTo = String.valueOf(dfield.getReferenceTo()[0].getDescribe().getName());

                        if ((type == 'string') ){ // mapped string types
                            mappings[indexM].questionMapping[indexQM] = newQuestionMapping(name, toInsert[txtIndexStart].id, classSel,required);
                            questionsToVerify.add(toInsert[txtIndexStart].id);
                            txtIndexStart++;
                            mappedObjects++;
                        }
                        else
                            if (type == 'date'){ //mapped date types
                                mappings[indexM].questionMapping[indexQM] = newQuestionMapping(name, toInsert[dateIndexStart].id, classSel,required);
                                questionsToVerify.add(toInsert[dateIndexStart].id);
                                dateIndexStart++;
                                mappedObjects++;
                            }
                            else
                            if (type == 'datetime'){ //mapped datetime types
                                mappings[indexM].questionMapping[indexQM] = newQuestionMapping(name, toInsert[dateTimeIndexStart].id, classSel,required);
                                questionsToVerify.add(toInsert[dateTimeIndexStart].id);
                                dateTimeIndexStart++;
                                mappedObjects++;
                            }

                            else if (type == 'picklist'){ //mapped picklist types
                                mappings[indexM].questionMapping[indexQM] = newQuestionMapping(name, toInsert[pickListIndexStart].id,classSel,required);
                                questionsToVerify.add(toInsert[pickListIndexStart].id);
                                pickListIndexStart++;
                                mappedObjects++;
                            }
                            else if ( (type == 'textarea') ) {
                                mappings[indexM].questionMapping[indexQM] = newQuestionMapping(name, toInsert[txtLongIndexStart].id, classSel,required);
                                questionsToVerify.add(toInsert[txtLongIndexStart].id);
                                txtLongIndexStart++;
                                mappedObjects++;
                            }
                            else if (new Set<String>{'_int','percent','_double','currency','integer','double','base64'}.contains(type)) {
                                mappings[indexM].questionMapping[indexQM] = newQuestionMapping(name, toInsert[numberIndexStart].id, classSel,required);
                                questionsToVerify.add(toInsert[numberIndexStart].id);
                                numberIndexStart++;
                                mappedObjects++;
                            }
                            else {
                                mappings[indexM].questionMapping[indexQM] = newQuestionMapping('-1', toInsert[txtIndexStart].id, classSel,required);
                                questionsToVerify.add(toInsert[txtIndexStart].id);
                                txtIndexStart++;
                                unmappedObjects++;
                            }

                    globalQMIndex++;
                    indexQM++;
                }
            }
            mappingsIndex++;
        }

        String jsonToSend = JSON.serialize(mappings);

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        Apexpages.currentPage().getParameters().put('jsonData',jsonToSend);
        //      STARTING TEST
        test.startTest();
          controller.saveData();
        test.stopTest();

        //verify question mappings have been inserted into the database
        system.assertEquals(mappedObjects,[Select q.Id From QuestionMapping__c q where q.Question__c in :questionsToVerify].size());


    }

    /**
     * Test to check errors are displaying correctly on surveymappingcontroller constructor
     */
    static testmethod void testSurveyFieldMappingControllerConstructorErrors(){
        //      TEST INITIALIZATION
        Survey__c newSurvey = new Survey__c();

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);

        ApexPages.StandardController stdController = new ApexPages.StandardController(newSurvey);

        //      STARTING TEST
        boolean error =false;

        Test.startTest();
            try {
                SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);
            }
            catch (C.InvalidUrlException exx){
                error = true;
            }
        Test.stopTest();

        //      VERIFYING
        system.assert(error,'An exception should be trown when the survey passed to the controller is not initialized');

    }
    /**
    * Test validation rule that restrict the map of the different repeated sections to the same object
    */
    static testMethod void validateDiffRepeatSectionsSameObject(){
        // create a test survey with 2 sections and some questions
        Survey__c survey = TestUtils.createSurvey('SurveyTestSaveData');
        // Insert repeated sections
        Question__c sec1 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section1', 'section1', 1);
        Question__c sec2 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section2', 'section2', 2);
        insert new List<Question__c>{sec1, sec2};
        // Insert one question by repeated section
        Question__c q1   = newQuestion(survey, sec1, QuestionDO.TYPE_TEXT_SHORT, 'question1', 'question1', 1);
        Question__c q2   = newQuestion(survey, sec2, QuestionDO.TYPE_TEXT_SHORT, 'question2', 'question2', 1);
        insert new List<Question__c>{q1, q2};
        // Insert survey mapping with sec1 as repeated section
        SurveyMapping__c sm = new SurveyMapping__c(Survey__c = survey.Id, Repeat__c = sec1.Id, ObjectApiName__c = 'Contact');
        insert sm;

        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c = 'LastName', Question__c = q1.Id, SurveyMapping__c = sm.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c = 'Name', Question__c = q2.Id, SurveyMapping__c = sm.Id);

        try{
            insert new List<QuestionMapping__c>{qm1, qm2};
            system.assert(false,'should fail since is trying to map 2 question from 2 different sections to the same object');
        }catch(Exception e){
            system.assert(e.getMessage().contains('This repeated question is not child of its mapped objects associated repeated section.'));
        }

    }

    /**
    * Test to validate the map to the same object with different sections types
    */
    static testMethod void validateMapSameObject(){
        // create a test survey with 2 sections and some questions
        Survey__c survey = TestUtils.createSurvey('SurveyTestSaveData');
        // Insert repeated sections
        Question__c sec1 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section1', 'section1', 1);
        Question__c sec2 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2);
        insert new List<Question__c>{sec1, sec2};
        // Insert one question by repeated section
        Question__c q1   = newQuestion(survey, sec1, QuestionDO.TYPE_TEXT_SHORT, 'question1', 'question1', 1);
        Question__c q2   = newQuestion(survey, sec2, QuestionDO.TYPE_TEXT_SHORT, 'question2', 'question2', 1);
        insert new List<Question__c>{q1, q2};
        // Insert survey mapping with sec1 as repeated section
        SurveyMapping__c sm = new SurveyMapping__c(Survey__c = survey.Id, Repeat__c = sec1.Id, ObjectApiName__c = 'Contact');
        insert sm;
        // Insert question mappings to the same object
        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c = 'LastName', Question__c = q1.Id, SurveyMapping__c = sm.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c = 'Name', Question__c = q2.Id, SurveyMapping__c = sm.Id);
        insert new List<QuestionMapping__c>{qm1, qm2};
        // Testing if the mappings were saved in data base
        List<QuestionMapping__c> maps = [SELECT FieldApiName__c, Question__c, SurveyMapping__c
                                         FROM QuestionMapping__c
                                         WHERE Id IN (:qm1.Id, :qm2.Id)];
        // Asserts
        system.assertEquals(maps.size(), 2);
        system.assertEquals(maps[0].Question__c, q1.Id);
        system.assertEquals(maps[1].Question__c, q2.Id);
        system.assertEquals(maps[0].FieldApiName__c, 'LastName');
        system.assertEquals(maps[1].FieldApiName__c, 'Name');
        system.assertEquals(maps[0].SurveyMapping__c, sm.Id);
        system.assertEquals(maps[1].SurveyMapping__c, sm.Id);
    }

    //------------------- Map and relations with removed objects or fields --------------------------------

    /**
     *  General consideration:
     *  We cannot remove a field or object in a test case, so what we do in order to simulate a removed object or field
     *  is to create a field or object with a wrong name (i.e. an object or field name cannot start with a number)
     *  so we are sure that no field or object is going to be named like that.
     *  When we look for that field or object will behave as a removed field or object.
     */

    /**
     *  Test that an object that is mapped to an object that is now deleted should raise an error.
     */
    static testMethod void mapDeletedObjectTest(){
        Survey__c newSurvey = TestUtils.createSurvey('SurveyTestSaveData1');

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);

        // Create two correct survey mappings.
        SurveyMapping__c sm1 = TestUtils.mapObject(newSurvey, Contact.SObjectType.getDescribe().getName());
        SurveyMapping__c sm2 = TestUtils.mapObject(newSurvey, Account.SObjectType.getDescribe().getName());

        // And a survey mapping with a fake object name that behave as a deleted object.
        String deletedObject = '1deletedObject';
        SurveyMapping__c sm3 = TestUtils.mapObject(newSurvey, deletedObject);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(newSurvey);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        Test.stopTest();

        // Validate that only one message is attached to the page (the one with the deletedObject).
        System.assertEquals(1, msgList.size());
        // Validate that the message has the name of the variable deletedObject.
        System.assert(msgList[0].getSummary().contains(deletedObject), 'DeletedObject variable is not the one that triggers the error');
    }

    /**
     *  Test that if a relation was created with a field that now is deleted, should also raise an error.
     */
    static testMethod void mapDeletedRelationTest(){

        Survey__c newSurvey = TestUtils.createSurvey('SurveyTestSaveData1');

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);

        // Create four correct survey mappings.
        SurveyMapping__c sm1 = TestUtils.mapObject(newSurvey, Contact.SObjectType.getDescribe().getName());
        SurveyMapping__c sm2 = TestUtils.mapObject(newSurvey, Account.SObjectType.getDescribe().getName());
        SurveyMapping__c sm3 = TestUtils.mapObject(newSurvey, Contact.SObjectType.getDescribe().getName());
        SurveyMapping__c sm4 = TestUtils.mapObject(newSurvey, Account.SObjectType.getDescribe().getName());

        // Also I create a relationship where the field behaves as a deleted field).
        String deletedFieldForRelation = '1fakeRelation';
        ObjectRelationshipMapping__c deletedRelation = TestUtils.relateObjects(sm1, sm2, deletedFieldForRelation);

        // And create a correct relation.
        String correctFieldForRelation  = Contact.SObjectType.getDescribe().fields.getMap().Values()[0].getDescribe().getName();
        ObjectRelationshipMapping__c correctRelation = TestUtils.relateObjects(sm3, sm4, deletedFieldForRelation);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(newSurvey);
        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        Test.stopTest();

        // Validate that only one message is attached to the page (the one with the deletedRelation).
        System.assertEquals(1, msgList.size());
        // Validate that the message has the name of the variable deletedRelation (the relation is the one that is triggering the error).
        System.assert(msgList[0].getSummary().contains(deletedFieldForRelation), 'DeletedObject variable is not the one that triggers the error');
    }

    /**
     *  Test that if a survey mapping has an id field autonumber, and we remove that id field (or change it) should raise an exception.
     */
    static testMethod void autonumberNotIdFieldTest(){

        // Create the survey.
        Survey__c survey = TestUtils.createSurvey('Survey1');

        // Create Field mapping controller.
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey);
        SurveyFieldMappingController controller    = new SurveyFieldMappingController(stdController);

        // Create the sections and questions.
        Question__c sec1       = TestUtils.addSection(survey, 1, 'Section1');
        Question__c q1         = TestUtils.addQuestion(sec1, 1, 'Question1', QuestionDO.TYPE_TEXT_SHORT);
        Question__c q2         = TestUtils.addQuestion(sec1, 2, 'Question2', QuestionDO.TYPE_TEXT_SHORT);
        //  Create survey mapping.
        SurveyMapping__c sm1   = TestUtils.mapObject(survey, 'Case', false, 'CaseNumber');
        // Create question mapping (with the autonumber field (CaseNumber) that will be its id field).
        QuestionMapping__c qm1 = TestUtils.mapQuestion(sm1, q1, 'CaseNumber');
        // Create another question mapping.
        QuestionMapping__c qm2 = TestUtils.mapQuestion(sm1, q2, 'Subject');

        // Change the id field of the survey mapping.
        sm1.MatchingField__c   = 'Subject';
        update sm1;

        Test.startTest();
        Boolean isAutonumberNotIdField = controller.isAnyAutoNumberNotIdField();
        Test.stopTest();
        System.assert (isAutonumberNotIdField, 'The autonumber field that was not id field, is not present');
    }

    //------------------- End of Map and relations with removed objects or fields --------------------------------

    /**
     * Test to verify that when using a cascading level to map a required field,
     * the cascading select and cascading levels must be required as well
     */
    static testmethod void testRequiredFieldsCascading() {

        // Create survey data
        Survey__c survey1 = TestUtils.createSurvey('SurveyTestSaveData');
        Question__c sec1 =
            newQuestion(survey1, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
        insert sec1;

        Question__c qbday =
            newQuestion(survey1, sec1, QuestionDO.TYPE_DATETIME, 'bday', 'Birthdate', 2);
        Question__c qdept =
            newQuestion(survey1, sec1, QuestionDO.TYPE_TEXT_SHORT, 'dept', 'Department', 3);

        // Add the cascading and its corresponding questions
        CascadingSelect__c cascadingSelect = TestUtils.createCascadingSelect('cascadingSelect');
        Question__c parentCascading = new Question__c(
            Survey__c = survey1.Id,
            Parent__c = sec1.Id,
            Name = 'cascadingQuestion',
            Caption__c = 'cascadingQuestion',
            Position__c = 4,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            CascadingSelect__c  = cascadingSelect.Id
        );

        insert new Question__c[]{qbday,qdept,parentCascading};
        List<CascadingLevel__c> cascadingLevels =
            TestUtils.createCascadingLevels(cascadingSelect, 5);

        List<Question__c> cascadingLevelsQuestions =
            TestUtils.createQuestionsforCascading(survey1.Id, parentCascading, cascadingLevels);

        TestUtils.createCascadingValues(cascadingLevels, 5);

        PageReference surveyFieldMappingPage = Page.SurveyFieldMapping;
        Test.setCurrentPage(surveyFieldMappingPage);
        ApexPages.StandardController stdController = new ApexPages.StandardController(survey1);

        SurveyFieldMappingController controller = new SurveyFieldMappingController(stdController);

        String sid = survey1.id;

        SurveyFieldMappingController.SurveyMappingObject[] mappings =
            new SurveyFieldMappingController.SurveyMappingObject[] {
                newSurveyMapping('sc1', 'Contact', '-', sid, false)
            };

        mappings[0].questionMapping = new SurveyFieldMappingController.QuestionMappingObject[] {
            newQuestionMapping('LastName', cascadingLevelsQuestions[3].id, 'sc1', true)
        };

        String jsonToSend = JSON.serialize(mappings);

        String jsonDataToSave = Apexpages.currentPage().getParameters().put('jsonData',jsonToSend);

        Test.startTest();
                controller.saveData();
        Test.stopTest();
        // Check that the cascading select and all the cascading levels are required fields

        List <Question__c> cascadingSelectAndLevels = [
            SELECT
                Id,
                Required__c
            FROM
                Question__c
            WHERE
                Survey__c = :survey1.Id
                AND (
                    Type__c = :QuestionDO.TYPE_CASCADING_LEVEL
                    OR Type__c = :QuestionDO.TYPE_CASCADING_SELECT
                )
        ];

        // Assert all the questions are required
        for (Question__c q: cascadingSelectAndLevels){
            system.Assert(q.Required__c,'The question should be required' + q);
        }
    }

    /**
     * Utility method to create a new QuestionMappingObject
     */
    static private SurveyFieldMappingController.QuestionMappingObject newQuestionMapping(String field,String questionId,String relHeaderCombo,
            boolean required) {
        SurveyFieldMappingController.QuestionMappingObject qm = new SurveyFieldMappingController.QuestionMappingObject();
        qm.mappedFieldName = field;
        qm.questionId = questionId;
        qm.relatedHeaderCombo = relHeaderCombo;
        qm.required = required;
        return qm;
    }

    /**
     * Utility method to create a new SurveyMappingObject
     */
    static private SurveyFieldMappingController.SurveyMappingObject newSurveyMapping(
            String classSel,
            String objectM,
            String matchingField,
            String surveyId,
            Boolean isReference
    ) {
        SurveyFieldMappingController.SurveyMappingObject s =
            new SurveyFieldMappingController.SurveyMappingObject();
        s.classSelected = classSel;
        s.objectMapped = objectM;
        s.surveyId = surveyId;
        s.matchingField = matchingField;
        s.isReference = isReference;
        return s;
    }

    /**
     * Init a test survey with some questions and some mappings.
     */
    private static Survey__c initSurvey() {
        Survey__c newSurvey = new Survey__c (Name = 'SurveyTest');
        insert newSurvey;

        Question__c section1 = newQuestion (
            newSurvey,
            null,
            QuestionDO.TYPE_SECTION,
            'section1',
            'section1',
            1
        );
        insert section1;
        Question__c freeTextQuestion = newQuestion (
            newSurvey,
            section1,
            QuestionDO.TYPE_TEXT_SHORT,
            'Text1',
            'Text1',
            1
        );
        Question__c gpsQuestion = newQuestion (
            newSurvey,
            section1,
            QuestionDO.TYPE_GPS,
            'gps',
            'gps',
            2
        );

        List<Question__c> questions = new List<Question__c>{freeTextQuestion, gpsQuestion};
        insert questions;

        SurveyMapping__c surveyMapping = new SurveyMapping__c (
            ObjectApiName__c = 'Contact',
            Survey__c = newSurvey.Id
        );
        insert surveyMapping;

        QuestionMapping__c questionMapping = new QuestionMapping__c (
            Question__c = freeTextQuestion.Id,
            SurveyMapping__c = surveyMapping.Id,
            FieldApiName__c = 'LastName'
        );
        insert questionMapping;

        return newSurvey;
    }

    static Question__c newQuestion(
            Survey__c survey,
            Question__c parent,
            String type,
            String name,
            String caption,
            Integer position
    ) {
        return new Question__c(
            Survey__c = survey.Id,
            Parent__c = (parent != null ? parent.Id : null),
            Type__c = type,
            Name = name,
            Caption__c = caption,
            Position__c = position
        );
    }

    static LicenseSettings__c newLicense(Boolean PPIEditable, String licName){
        list<LicenseSettings__c> lS = [SELECT PPI_Editable__c FROM LicenseSettings__c limit 1];
        delete lS;
        LicenseSettings__c li = new LicenseSettings__c(PPI_Editable__c = PPIEditable, Name = licName);
        return li;
    }

    /**
     *  Get a Set of strings from a set of selectOption
     *
     * @param optionList List of SelectOption source list
     * @return return a set of the selectedOption converted to strings
     */
    private static Set<String> selectOptionToString(List<SelectOption> optionList){
        Set<String> stringOptionSet = new Set<String>();
        for (SelectOption opt:optionList){
            stringOptionSet.add(opt.getValue());
        }
        return stringOptionSet;
    }

    /**
     * Inizializate a Map with the Field types
     *
     * @return map with a list of fields name as values,and their type as key
     */
    private static Map<String, Set<String>> contactFieldsMap() {
        return new Map<String, Set<String>>{
            'String' => new Set<String>{
                'AssistantName','Jigsaw','Department','LastName','FirstName','Title'
            },
            'Number' => new Set<String>(),
            'Contact' => new Set<String>{
                'ReportsToId'
            },
            'Others' => new Set<String>{
                'DoNotCall','CreatedBy','LastModifiedBy','Birthdate','Owner','Email','HasOptedOutOfEmail','Fax','HasOptedOutOfFax'
                ,'HomePhone','LastCURequestDate','LastCUUpdateDate','LeadSource','MailingAddress','MobilePhone','OtherPhone','OtherAddress','Phone'
            }
        };
    }

    /**
     * Get survey mappings
     * TODO: Move for SoC
     */
    static List<SurveyMapping__c> getSurveyMappings(Id mappingId) {
        return [
            SELECT
                Id
            FROM
                SurveyMapping__c
            WHERE
                Id = :mappingId
        ];
    }

    /**
     * Get Question Mappings
     * TODO: Move for SoC
     */
    static List<QuestionMapping__c> getQuestionMappings(
            Id surveyMappingId,
            Id questionId,
            String fieldApiName
    ) {
        return [
            SELECT
                Id
            FROM
                QuestionMapping__c
            WHERE
                SurveyMapping__c = :surveyMappingId
                AND Question__c = :questionId
                AND FieldApiName__c = :fieldApiName
        ];
    }
}
