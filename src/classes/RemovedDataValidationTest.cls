/**
 * Test code for RemovedDataValidation class.
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Claudio Soto (csoto@altimetrik.com)
 */
 @isTest
public class RemovedDataValidationTest {

    /**
     * General consideration:
     * We cannot remove a field or object in a test case, so what we do in order to simulate a removed object or field
     * is to create a field or object with a wrong name (i.e. an object or field name cannot start with a number)
     * so we are sure that no field or object is going to be named like that.
     * When we look for that field or object will behave as a removed field or object.
     */

    /**
     * Method in charge to test obtainMissingData method for deleted objects.
     */
    public static testMethod void obtainMissingDataObjectTest() {

        // Will test it with an object that starts with a number (an object can't start with a number), so it will behave as a deleted object.
        String deletedObject = '1fakeObject';

        test.startTest();

        // Obtain the map with a deleted object.
        RemovedDataValidation.MissingData deletedDataObject =
            RemovedDataValidation.obtainMissingData(deletedObject, new List<String>());

        test.stopTest();

        // Check if there is a MissingData Object (if no deleted field or object is found returns null).
        System.assert(
            deletedDataObject != null, 'If deletedDataObject is null, it means that an object is called "1fakeObject"'
        );

        // Validate that the type of error is deleted-object.
        System.assertEquals(RemovedDataValidation.OBJECT_DELETED, deletedDataObject.missingDataType);

        //Validate that the object delete is '1fakeObject'.
        System.assertEquals(deletedObject, deletedDataObject.objectDeleted);
    }

    /**
     * Method in charge to test obtainMissingData method for deleted fields.
     */
    public static testMethod void obtainMissingDataFieldTest() {

        // Obtain a map with Contact fields.
        Map<String, Schema.SObjectField> objectFields = DescribeHandler.getFieldMap('Contact');

        // Object will be "Contact".
        String objectName = Contact.SObjectType.getDescribe().getName();

        // A couple of fields that we know are not deleted (because we are retrieving them from describe).
        String firstField = String.valueOf(objectFields.values()[0].getDescribe().getName());
        String secondField = String.valueOf(objectFields.values()[1].getDescribe().getName());

        // A fake field that will act as a deleted field.
        String deletedField = '1fakefield';

        // Create the list of fields...
        List<String> listFields = new List<String>();

        // ... and add the fields.
        listFields.add(firstField);
        listFields.add(secondField);
        listFields.add(deletedField);

        test.startTest();

        RemovedDataValidation.MissingData deletedData =
            RemovedDataValidation.obtainMissingData(objectName, listFields);
        String errorMessage = deletedData.toString('');

        test.stopTest();

        // Check if there is a MissingData Object (if no deleted field or object is found returns null).
        System.assert(deletedData != null, 'If deletedData is null, it means that a field is called "1fakefield"');

        // Validate that the type of error is deleted-field.
        System.assertEquals(RemovedDataValidation.FIELD_DELETED, deletedData.missingDataType);

        // Validate that the object is "Contact"
        System.assertEquals(objectName, deletedData.objectDeleted);

        // Validate that there is one field in the list of deleted fields ('1fakefield').
        System.assertEquals(1, deletedData.fieldsDeleted.size());

        // Validate that the field that is not in the object ('1fakefield') is the one in the MissingData object.
        System.assertEquals(deletedField, deletedData.fieldsDeleted[0]);

        // Also validate that the message generated is correct.
        // First: Contact is named (beacuse is the object with a field removed).
        System.assert(errorMessage.contains(objectName), 'The message does not contain the object with the removed field');

        // Second: Names the field that is deleted.
        System.assert(
            errorMessage.contains(deletedData.fieldsDeleted[0]),
            'The field supposed to be removed is not removed, or another of the mapped fields is also removed'
        );
    }

    /**
     * Method in charge of test obtainMissingDataInBulkFromRelations method.
     */
    public static testMethod void obtainMissingDataInBulkFromRelationsTest() {

        // Create the survey...
        Survey__c survey     = TestUtils.createSurvey('surveyName');

        // Create the survey mappings.
        SurveyMapping__c sm1 = TestUtils.mapObject(survey, Contact.SObjectType.getDescribe().getName());
        SurveyMapping__c sm2 = TestUtils.mapObject(survey, Contact.SObjectType.getDescribe().getName());

        // Create a fake field that will act as a deleted field.
        String deletedField  = '1fakeField';
        // Obtain a real field (that I know it won't be removed).
        String realField     = String.valueOf(Contact.SObjectType.getDescribe().fields.getMap().Values()[0].getDescribe().getName());

        // Relate the previous mappings with a fake field (that will behave as a removed field).
        ObjectRelationshipMapping__c relationFake = TestUtils.relateObjects(sm1, sm2, deletedField);
        // And create a real relationship.
        ObjectRelationshipMapping__c relationReal = TestUtils.relateObjects(sm1, sm2, realField);

        List<ObjectRelationshipMapping__c> listRelations = [SELECT Id, ChildSurveyMapping__c, FieldApiName__c,
                                                                   ParentSurveyMapping__c,
                                                                   ChildSurveyMapping__r.ObjectApiName__c
                                                            FROM ObjectRelationshipMapping__c
                                                            WHERE Id = :relationFake.Id
                                                               OR Id = :relationReal.Id ];

        test.startTest();

        // Obtain the map with deleted object or fields.
        Map<String, RemovedDataValidation.MissingData> mapDeletedData =
            RemovedDataValidation.obtainMissingDataInBulkFromRelations(listRelations);

        test.stopTest();

        // First we make sure that mapDeletedData has one element (1fakeField is the deleted field)...
        System.assertEquals (1, mapDeletedData.size());
        // ... after that, we make sure that relationFake is the one with a missing value (1fakeField field).
        System.assert (mapDeletedData.containsKey(relationFake.Id), 'Fake relation has not a deleted value.');

        RemovedDataValidation.MissingData missingDataFakeRelation = mapDeletedData.get(relationFake.Id);
        // And we must validate that the found field is the fake field.
        System.assertEquals (deletedField, missingDataFakeRelation.fieldsDeleted[0]);
    }

    /**
     *  Method in charge of test obtainMissingDataInBulkFromExistentSM method.
     */
    public static testMethod void obtainMissingDataInBulkFromExistentSMTest() {

        // Create the survey...
        Survey__c survey             = TestUtils.createSurvey ('surveyName');

        ApexPages.StandardController
                       stdController = new ApexPages.StandardController(survey);
        SurveyFieldMappingController
                          controller = new SurveyFieldMappingController(stdController);

        // Create the questions.
        Question__c section1         = TestUtils.addQuestion (survey, 1, 'Section1', QuestionDO.TYPE_SECTION);
        Question__c question1        = TestUtils.addQuestion (section1, 1, 'Question1', QuestionDO.TYPE_TEXT_SHORT);
        Question__c question2        = TestUtils.addQuestion (section1, 2, 'Question2', QuestionDO.TYPE_TEXT_SHORT);

        // Create a fake name for an object that will act as a deleted object.
        String deletedObject         = '1fakeObject';

        // Create the survey mappings.
        SurveyMapping__c sm1         = TestUtils.mapObject (survey, Contact.SObjectType.getDescribe().getName());
        SurveyMapping__c sm2         = TestUtils.mapObject (survey, deletedObject);

        // Obtain the list of survey and question mappings of the given survey.
        List<SurveyFieldMappingController.ExistentSurveyMapping> existentSurveyMappings = obtainMappingData(controller);

        test.startTest();

        // Retrieve data with object or field removed.
        Map<String, RemovedDataValidation.MissingData> mapDataMissing =
            RemovedDataValidation.obtainMissingDataInBulkFromExistentSM(existentSurveyMappings);

        test.stopTest();

        // Must validate that only one MissingData object is created.
        system.assertEquals(1, mapDataMissing.size());
        // Also must validate that the key of the object is sm2.Id
        system.assert(mapDataMissing.containsKey(sm2.Id), 'Sm2 has an object name named as the variable: deletedObject');
        // And must validate that the object in the MissingData object is the same that deletedObject.
        system.assertEquals(deletedObject, mapDataMissing.get(sm2.Id).objectDeleted);

        // Obtain error message...
        String errorMessage = mapDataMissing.get(sm2.Id).toString('');

        // Validate that the message generated is correct.
        // deletedObject is named in the error message (because is the deleted object).
        System.assert (errorMessage.contains(deletedObject));
    }

    /**
     * Method in charge of simulate the way the controller retrieve and send data to the page.
     *
     * @param SurveyMappinController
     *
     * @return List of SurveyFieldMappingController.ExistentSurveyMapping
     *           with the data of the given survey.
     */
    static private List<SurveyFieldMappingController.ExistentSurveyMapping> obtainMappingData(
            SurveyFieldMappingController cont
    ) {

        SurveyMapping__c[] allSurveyMappings = [
            SELECT
                Id,
                MatchingField__c,
                ObjectApiName__c,
                Survey__c,
                SurveyApiField__c,
                SurveyVersionApiField__c,
                SubmissionApiField__c,
                SurveyorApiField__c,
                PPIScoreApiField__c,
                Repeat__c,
                IsReference__c
            FROM
                SurveyMapping__c
            WHERE
                Survey__c = :cont.survey.Id
            ORDER BY
                CreatedDate
        ];
        QuestionMapping__c[] questionMappings = [
            SELECT
                Id,
                FieldApiName__c,
                Question__c,
                SurveyMapping__c
            FROM
                QuestionMapping__c
            WHERE
                SurveyMapping__c IN :allSurveyMappings
            ORDER BY
                SurveyMapping__c
        ];

        Map<Id, List<QuestionMapping__c>> mapSurveyQuestionMapping =
            new Map<Id, List<QuestionMapping__c>>();
        for(QuestionMapping__c qm: questionMappings) {
            List<QuestionMapping__c> dummyQuestionList =
                (mapSurveyQuestionMapping.containsKey(qm.SurveyMapping__c))
                    ? mapSurveyQuestionMapping.get(qm.SurveyMapping__c)
                    : new List<QuestionMapping__c>();
            dummyQuestionList.add(qm);
            mapSurveyQuestionMapping.put(qm.SurveyMapping__c, dummyQuestionList);
        }

        // Now we simulate the controller behavior:
        List<SurveyFieldMappingController.ExistentSurveyMapping> existentSurveyMappings =
            new List<SurveyFieldMappingController.ExistentSurveyMapping>();
        for (SurveyMapping__c sm:allSurveyMappings) {
            List<SurveyFieldMappingController.SField> relatedFields =
                cont.obtainFieldsFromObject(sm.ObjectApiName__c);
            List<QuestionMapping__c> listQuestionMapping =
                (mapSurveyQuestionMapping.containsKey(sm.Id))
                    ? mapSurveyQuestionMapping.get(sm.Id)
                    : new List<QuestionMapping__c>();
            SurveyFieldMappingController.ExistentSurveyMapping dummySurveyMapping =
                new SurveyFieldMappingController.ExistentSurveyMapping(
                    sm, relatedFields, listQuestionMapping
                );
            existentSurveyMappings.add(dummySurveyMapping);
        }
        return existentSurveyMappings;
    }

    /**
     *  Test method for obtainMissingDataInBulkFromHierarchy method.
     *
     *  @param  SurveyMappinController
     *  @return List of SurveyFieldMappingController.ExistentSurveyMapping with the data of the given survey.
     */
    public static testMethod void obtainMissingDataInBulkFromHierarchyTest(){

        // First we create an object with a fake name (will act as a deleted object).
        String fakeObjectName  = '1FakeObject';
        String fakeObjectLabel = 'Object Label';
        String fakeObjectId    = '1fgh';

        JobTemplateDO.ObjectHierarchy oh1 = new JobTemplateDO.ObjectHierarchy(fakeObjectId, fakeObjectLabel, fakeObjectName);
        oh1.addListField('1fakeField');

        // Then we create a hierarchy with real object
        String objectName  = Contact.SObjectType.getDescribe().getName();
        String objectLabel = 'Contact';
        String objectId    = '2erf';

        JobTemplateDO.ObjectHierarchy oh2 = new JobTemplateDO.ObjectHierarchy(objectId, objectLabel, objectName);
        oh2.addListField(String.valueOf(Contact.SObjectType.getDescribe().fields.getMap().Values()[0].getDescribe().getName()));

        List<JobTemplateDO.ObjectHierarchy> listHierarchies = new List<JobTemplateDO.ObjectHierarchy>();
        listHierarchies.add(oh1);
        listHierarchies.add(oh2);

        test.startTest();

        // Retrieve hierarchies with object or field removed.
        Map<String, RemovedDataValidation.MissingData> mapDeletedData =
            RemovedDataValidation.obtainMissingDataInBulkFromHierarchy(listHierarchies);
        test.stopTest();

        // Must validate that only one MissingData object is created.
        system.assertEquals(1, mapDeletedData.size());
        // Also must validate that the key of the object is oh1.Id
        system.assert(mapDeletedData.containsKey(oh1.objectId), 'oh1 has an object name named as the variable: 1FakeObject');
        // Also must validate that the deleted data is the object
        system.assertEquals(fakeObjectName, mapDeletedData.get(oh1.objectId).objectDeleted);
    }

    // Test survey that has some missing mapped object
    public static testMethod void mappingsWithMissingObject(){
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

        // Must return true because there is at least one deleted mapped object
        system.assert(RemovedDataValidation.mappingsWithMissingObjectOrField(survey.Id).contains(survey.Id));
    }

    // Test survey that has some missing mapped field
    public static testMethod void mappingsWithMissingField(){
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

        // Create survey mapping
        SurveyMapping__c sm = TestUtils.mapObject(survey, Contact.SObjectType.getDescribe().getName());

        // Create question mappings to a non existent field
        QuestionMappingTH.skipValidation = true;
        QuestionMapping__c qm = TestUtils.mapQuestion(sm, questions[1], 'deletedField', true);
        QuestionMappingTH.skipValidation = false;

        // Must return true because there is at least one deleted mapped field
        system.assert(RemovedDataValidation.mappingsWithMissingObjectOrField(survey.Id).contains(survey.Id));
    }

    // Test survey that has some missing mapped relation
    public static testMethod void mappingsWithMissingRelation(){
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

        // Create survey mapping
        SurveyMapping__c sm1 = TestUtils.mapObject(survey, Contact.SObjectType.getDescribe().getName());
        SurveyMapping__c sm2 = TestUtils.mapObject(survey, Account.SObjectType.getDescribe().getName());

        // Create a relationship where the field behaves as a deleted field).
        ObjectRelationshipMapping__c deletedRelation = TestUtils.relateObjects(sm1, sm2, 'fakeRelation');

        // Must return true because there is at least one deleted mapped relation
        system.assert(RemovedDataValidation.mappingsWithMissingObjectOrField(survey.Id).contains(survey.Id));
    }

    // Utility methods
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

}
