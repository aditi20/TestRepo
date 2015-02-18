/**
 * Test the RestResource for submitting surveys
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public with sharing class SurveySubmissionServicesTest {

    // Headers map for a request
    static Map<String, String> headersMap;

    /**
     * Prepare the request
     *
     * @param xml         - The XML for the submission
     * @param lastHeader  - The value for the last header
     * @param stageHeader - The value for the stage header
     */
    public static TestUtils.Surveyor setUpRequest(String xml, String lastHeader, String stageHeader) {

        // Create a partner user and log them into TaroWorks
        UserTH.setSkipValidation(true);
        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor(
            'LastName_SSST',
            true
        );
        surveyor = TestUtils.partnerLoginDetails(surveyor);

        // Prepare the headers
        headersMap = new Map<String, String>{
            C.SESSION_TOKEN_HEADER => surveyor.loginResult.getSessionToken(),
            C.LAST_HEADER => lastHeader,
            C.STAGE_HEADER => stageHeader
        };

        // Prepare the request
        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('surveysubmission/'),
            Blob.valueOf(xml),
            headersMap
        );
        return surveyor;
    }

    /**
     * Create and publish a survey
     *
     * @param surveyName - The name of the survey being created
     */
    private static Survey__c createAndPublishSurvey(String surveyName) {

        // Create survey
        Survey__c survey = new Survey__c(
            Name = surveyName,
            Status__c = SurveyDO.STATUS_DRAFT
        );
        insert survey;

        // Create questions
        List<Question__c> questions = createQuestions(survey);

        SurveyVersion__c[] versions = [
            SELECT
                Status__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c = :survey.Id
            ORDER BY
                Version__c DESC
        ];

        // Publish survey
        versions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        update versions;
        return survey;
    }

    /**
     * Create questions for the test survey
     *
     * @param survey - The survey the questions belong to
     *
     * @return - List of the created questions
     */
    static List<Question__c> createQuestions(Survey__c survey) {
        Question__c section = TestUtils.addSection(survey, 1, 'section');

        Question__c q1 = TestUtils.addQuestion(section, 1, 'q1', QuestionDO.TYPE_TEXT_SHORT);
        return new List<Question__c>{section, q1};
    }

    /**
     * Create a job and a task for the survey to be published to
     *
     * @param version - The SurveyVersion__c that will belong to the created task
     */
    static void createJobsAndTasks(SurveyVersion__c version) {

        // Create the job
        JobTemplate__c job = JobTemplateDO.createJobTemplate(
            'JobTemp2', JobTemplateDO.STATUS_DRAFT, '', 'Instructions'
        );
        insert job;

        // Add the data collection task
        TaskTemplate__c task = TaskTemplateDO.createTaskTemplate(
            'taskTemplate', 1, job.Id, TaskTemplateDO.TYPE_FORM, version.id
        );
        insert task;

        // Publish job
        job.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        update job;
    }

    /**
     * Test that the error code returned by closing due to a broken field mapping is the correct one
     */
    static void checkFieldMappingFailureClose() {

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_SUB_CORRUPT_FIELD_MAP, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.SURVEY_SUB_BROKEN_FIELD_MAPPING, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test successful submission of a survey that contains no media
     */
    static testMethod void processSubmissionTest() {
        Contact ctc = new Contact(LastName = 'Robert',mobilesurveys_Id__c='4321');
        insert ctc;
        Survey__c survey = new Survey__c(Name='Survey',Gps_Location_Enabled__c=true);
        insert survey;
        Question__c qSection = new Question__c(Survey__c=survey.Id,Caption__c= 'SECTIONNN',Type__c = QuestionDO.TYPE_SECTION, Name = 'section1');
        insert qSection;
        Question__c q1 = new Question__c(Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Username',Type__c = QuestionDO.TYPE_TEXT_SHORT, Name= 'q1', Position__c = 1);
        Question__c q2 = new Question__c(Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Last Name',Type__c = QuestionDO.TYPE_TEXT_SHORT, Name= 'q2', Position__c = 2);
        insert q1;insert q2;
        SurveyVersion__c surveyVersion = [select Status__c from SurveyVersion__c where Survey__c =:survey.Id];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;
        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + survey.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + qSection.Name + '>' +
                    '<'+ q1.Name +'>User</'+ q1.Name +'>'+
                    '<'+ q2.Name +'>Martin</'+ q2.Name +'>'+
                '</' + qSection.Name + '>' +
            '</'+ survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        Id submissionId = RestContext.response.headers.get(C.SUBMISSION_ID_HEADER);

        List<Submission__c> resultSA = [
            SELECT
                Id,
                Name,
                Survey__c,
                Date__c,
                Status__c,
                GPS_x__c,
                GPS_y__c
            FROM
                Submission__c
            WHERE
                Id = :submissionId
        ];

        System.assertEquals(1, resultSA.size());
        System.assertEquals(survey.Id, resultSA[0].survey__c);
        System.assertEquals(80.0, resultSA[0].gps_x__c);
        System.assertEquals(Date.valueOf('2012-02-14'), resultSA[0].Date__c);
    }

    /**
     * Test successful submission of a survey with images
     */
    public static testMethod void processSubmissionWithImagesTest() {

        Contact ctc = new Contact(LastName = 'Robert', mobilesurveys_Id__c = '4321');
        insert ctc;

        Survey__c survey = new Survey__c(Name = 'Survey', Gps_Location_Enabled__c = true);
        insert survey;

        Question__c qSection = new Question__c(Survey__c = survey.Id, Caption__c = 'SECTIONNN', Type__c = QuestionDO.TYPE_SECTION, Name = 'section1');
        insert qSection;

        Question__c q1 = new Question__c(Parent__c = qSection.Id, survey__c = survey.Id, Caption__c = 'Username', Name= 'Username', Type__c = QuestionDO.TYPE_TEXT_SHORT, Position__c = 1);
        Question__c q2 = new Question__c(Parent__c = qSection.Id, survey__c = survey.Id, Caption__c = 'Last_Name', Name= 'Last_Name', Type__c = QuestionDO.TYPE_TEXT_SHORT, Position__c = 2);
        Question__c qImage1 = new Question__c(Parent__c = qSection.Id, survey__c = survey.Id, Caption__c = 'image1', Name= 'image1', Type__c = QuestionDO.TYPE_MEDIA_IMAGE, Position__c = 3);
        Question__c qImage2 = new Question__c(Parent__c = qSection.Id, survey__c = survey.Id, Caption__c = 'image2', Name= 'image2', Type__c = QuestionDO.TYPE_MEDIA_IMAGE, Position__c = 4);
        insert new Question__c[]{q1, q2, qImage1, qImage2};

        // Create necessary mappings
        SurveyMapping__c mapcontact = TestUtils.mapObject(survey, 'Contact');
        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c='mobilesurveys_Id__c',Question__c=q1.Id,SurveyMapping__c=mapcontact.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c='LastName',Question__c=q2.Id,SurveyMapping__c=mapcontact.Id);
        QuestionMapping__c qm3 = new QuestionMapping__c(FieldApiName__c='Description',Question__c=qImage1.Id,SurveyMapping__c=mapcontact.Id);
        insert new QuestionMapping__c[]{qm1, qm2, qm3};


        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;
        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + survey.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + qSection.Name + '>' +
                    '<'+ q1.Name +'>User</'+ q1.Name +'>'+
                    '<'+ q2.Name +'>Thierry</'+ q2.Name +'>'+
                    '<'+ qImage1.Name +'>image1.jpg</'+ qImage1.Name +'>'+
                    '<'+ qImage2.Name +'>image2.jpg</'+ qImage2.Name +'>'+
                '</' + qSection.Name + '>' +
            '</'+ survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, 'false', C.SUBMISSION_STAGE_INIT);

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }

        // Get the generated id
        Id submissionId = RestContext.response.headers.get(C.SUBMISSION_ID_HEADER);
        System.assertNotEquals(null, submissionId);

        //Check Data of the submission in the init Stage
        Submission__c currentSubmission =
            [SELECT
                Status__c,
                Surveyor__c,
                SubmissionXMLMD5__c,
                SurveyVersion__c
            FROM
                Submission__c
            WHERE Id = :submissionId
            ][0];
        System.assertNotEquals(null, currentSubmission.SurveyVersion__c);
        System.assertNotEquals(null, currentSubmission.Surveyor__c);
        System.assertNotEquals(null, currentSubmission.SubmissionXMLMD5__c);
        System.assertEquals(C.SUBMISSION_STATUS_UPLOADING, currentSubmission.Status__c);

        // Create some images
        Blob image1  = Blob.valueOf('someimage1Blob');
        Blob image2  = Blob.valueOf('someimage2Blob');

        // Update the headers
        headersMap.put(C.STAGE_HEADER, C.SUBMISSION_STAGE_MEDIA);
        headersMap.put(C.FILENAME_HEADER, 'image1.jpg');
        headersMap.put(C.SUBMISSION_ID_HEADER, submissionId);

        // Send some images to the server
        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('surveysubmission/'),
            image1,
            headersMap
        );
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
        System.assertEquals(C.SUBMISSION_STATUS_UPLOADING, [SELECT Status__c FROM Submission__c WHERE Id = :submissionId][0].Status__c);

        // Update the headers
        headersMap.put(C.FILENAME_HEADER, 'image2.jpg');
        headersMap.put(C.LAST_HEADER, String.valueOf(true));

        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('surveysubmission/'),
            image2,
            headersMap
        );
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
        System.assertEquals(C.SUBMISSION_STATUS_UPLOADED, [SELECT Status__c FROM Submission__c WHERE Id = :submissionId][0].Status__c);

        // Check the submission and the answers were correctly created
        List<Submission__c> resultSA = [SELECT id, name, survey__c, Date__c, Status__c, gps_x__c, gps_y__c FROM Submission__c WHERE survey__c = :survey.Id];
        System.assertEquals(1,resultSA.size());
        System.assertEquals(survey.Id, resultSA[0].survey__c);
        System.assertEquals(80.0, resultSA[0].gps_x__c);
        System.assertEquals(Date.valueOf('2012-02-14'), resultSA[0].Date__c);

        // Check only one xml is inserted
        List<Attachment> xmlFiles = [SELECT id, Body FROM Attachment WHERE ParentId = :submissionId AND Name = :C.SURVEY_ANSWER_ATTACHMENT_NAME ORDER BY Name];
        System.assertEquals(1, xmlFiles.size());

        // Check tha the insertion of the images as attached files
        List<Attachment> images = [SELECT id, Body, Name FROM Attachment WHERE ParentId = :submissionId AND Name in ('image1.jpg', 'image2.jpg') ORDER BY Name];
        System.assertEquals(2, images.size());
        System.assertEquals(image1.toString(), images[0].Body.toString());
        System.assertEquals(image2.toString(), images[1].Body.toString());

        // Check insertion of the answers
        List<Answer__c> answers = [
            SELECT
                Id,
                Value__c,
                Question__r.Name
            FROM
                Answer__c
            WHERE
                Submission__c = :submissionId
            ORDER BY
                Question__r.Name
        ];

        System.assertEquals(4, answers.size());
        System.assertEquals(images[0].Id, answers[0].Value__c);
        System.assertEquals(images[1].Id, answers[1].Value__c);

        // Check correct mapping of the images
        List<Contact> contacts = [SELECT Id, Description, LastName, mobilesurveys_Id__c FROM Contact WHERE LastName = 'Thierry' ];
        System.assertEquals(1, contacts.size());
        System.assertEquals(C.SALESFORCE_INSTANCE + C.DOWNLOAD_ATT_URL + images[0].Id, contacts[0].Description);
        System.assertEquals('User', contacts[0].mobilesurveys_Id__c);
    }

    /**
     * Tests MD5 functionality to catch duplicate XML submissions.
     */
    static testmethod void testDuplicateSubmission() {

        Survey__c survey = createAndPublishSurvey('DuplicateSubmissionTest');

        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id, new List<String>{ 'Pepe', 'Heisenberg' });

        TestUtils.Surveyor surveyor = setUpRequest(xmlToSend, '', '');

        Test.startTest();

        // Submit once
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }

        // Check success of first submission
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Submit twice
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Check success of second submission
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_SUB_DUPLICATE, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.SURVEY_SUB_DUPLICATE_SUBMISSION, errorMessages[0].getErrorTranslationCode());

        // Although there were two submission only one should have been created.
        List<Submission__c> resultSA = [SELECT Id FROM Submission__c WHERE survey__c = :survey.Id];
        System.assertEquals(1, resultSA.size());
    }

    /**
     * Test invalid submission error when submitting media
     */
    static testMethod void testInvalidSubmissionId() {

        Survey__c survey = createAndPublishSurvey('DuplicateSubmissionTest');
        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id, new List<String>{ 'Pepe', 'Heisenberg' });
        TestUtils.Surveyor surveyor = setUpRequest(xmlToSend, 'false', C.SUBMISSION_STAGE_INIT);

        // Submit the XML
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }

        // Update the headers
        headersMap.put(C.FILENAME_HEADER, 'image1.jpg');
        headersMap.put(C.SUBMISSION_ID_HEADER, survey.Id);
        headersMap.put(C.STAGE_HEADER, C.SUBMISSION_STAGE_MEDIA);
        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('surveysubmission/'),
            Blob.valueOf(EncodingUtil.base64Encode(Blob.valueOf('someimage1Blob'))),
            headersMap
        );

        // Submit the media but with a bad Id for the submission
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Check the status of the response
        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_SUB_INVALID_SUBMISSION_ID, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.SURVEY_SUB_INVALID_SUBMISSION_ID, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test missing submissionId error when submitting media
     */
    static testMethod void testMissingSubmissionId() {

        Survey__c survey = createAndPublishSurvey('DuplicateSubmissionTest');
        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id, new List<String>{ 'Pepe', 'Heisenberg' });
        TestUtils.Surveyor surveyor = setUpRequest(xmlToSend, 'false', C.SUBMISSION_STAGE_INIT);

        // Submit the XML
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }

        // Update the headers
        headersMap.put(C.FILENAME_HEADER, 'image1.jpg');
        headersMap.put(C.SUBMISSION_ID_HEADER, null);
        headersMap.put(C.STAGE_HEADER, C.SUBMISSION_STAGE_MEDIA);
        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('surveysubmission/'),
            Blob.valueOf(EncodingUtil.base64Encode(Blob.valueOf('someimage1Blob'))),
            headersMap
        );

        // Submit the media but with a bad Id for the submission
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Check the status of the response
        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_SUB_ID_MISSING, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.SURVEY_SUB_MISSING_SURVEY_ID, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test submitting last media when the submission XML was not saved as an attachment
     */
    static testMethod void testMissingAttachment() {

        Survey__c survey = createAndPublishSurvey('DuplicateSubmissionTest');
        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id, new List<String>{ 'Pepe', 'Heisenberg' });
        TestUtils.Surveyor surveyor = setUpRequest(xmlToSend, 'false', C.SUBMISSION_STAGE_INIT);

        // Submit the XML
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }

        Id submissionId = RestContext.response.headers.get(C.SUBMISSION_ID_HEADER);
        System.assertNotEquals(null, submissionId);

        // Update the headers
        headersMap.put(C.FILENAME_HEADER, 'image1.jpg');
        headersMap.put(C.SUBMISSION_ID_HEADER, submissionId);
        headersMap.put(C.STAGE_HEADER, C.SUBMISSION_STAGE_MEDIA);
        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('surveysubmission/'),
            Blob.valueOf(EncodingUtil.base64Encode(Blob.valueOf('someimage1Blob'))),
            headersMap
        );

        // Remove the attachment
        delete [
            SELECT
                Body
            FROM
                Attachment
            WHERE
                ParentId = :submissionId
                AND Name = :C.SURVEY_ANSWER_ATTACHMENT_NAME
            LIMIT
                1
        ];

        // Submit the media
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Check the status of the response
        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_SUB_MISSING_XML, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.SURVEY_SUB_MISSING_XML, errorMessages[0].getErrorTranslationCode());

        // Check that the submission was deleted
        Submission__c[] submissions = [SELECT Id FROM Submission__c WHERE Id = :submissionId];
        System.assert(submissions.isEmpty());
    }

    /**
     * Test that the correct error is returned when the submission XMl is empty
     */
    static testMethod void testEmptyXml() {

        TestUtils.Surveyor surveyor = setUpRequest('', '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Check the status of the response
        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_SURVEY_BLANK_XFORM, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.SURVEY_FORMLIST_XFORM_EMPTY, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test that the correct error is returned when the SurveyVersion doesn't exist
     */
    static testMethod void testMissingSurveyVersion() {

        TestUtils.Surveyor surveyor = setUpRequest('<sub>SOME TEXT</sub>', '', '');


        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }

        // Check the status of the response
        System.assertEquals(C.HTTP_NOT_FOUND, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_SURVEY_ID_NOT_EXIST, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.SURVEY_FORMLIST_ID_INVALID, errorMessages[0].getErrorTranslationCode());
    }

    //------------------- Submission with Map and relations with removed objects or fields --------------------------------
    /**
     *  General consideration:
     *  We cannot remove a field or object in a test case, so what we do in order to simulate a removed object or field
     *  is to create a field or object with a wrong name (i.e. an object or field name cannot start with a number)
     *  so we are sure that no field or object is going to be named like that.
     *  When we look for that field or object will behave as a removed field or object.
     */

    /**
     * Submission with missing object will close the survey and save the answer as attachment
     */
    static testMethod void submissionWithMapDeletedObjectTest(){

        // Create survey
        Survey__c survey = new Survey__c(Name = 'SubmissionTestMissingObject', Status__c = SurveyDO.STATUS_DRAFT);
        insert survey;

        // Create questions
        List<Question__c> questions = createQuestions(survey);

        SurveyVersion__c[] versions = [
            SELECT
                Status__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c = :survey.Id
            ORDER BY
                Version__c DESC
        ];

        // Publish survey
        versions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        update versions;

        // Create jobs and tasks
        createJobsAndTasks(versions[0]);

        // Create survey mapping with a fake object name that behaves as a deleted object.
        String deletedObject = 'deletedObject';
        SurveyMapping__c sm = TestUtils.mapObject(survey, deletedObject);

        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id, new List<String>{ 'Pepe', 'Heisenberg' });

        TestUtils.Surveyor surveyor = setUpRequest(xmlToSend, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Survey was closed after the submission
        System.assertEquals(surveyDO.STATUS_CLOSED, [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c DESC LIMIT 1].Status__c);

        // Submission was made anyway
        System.assertEquals(1, [SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id].size());

        // Answer was saved as submission attachment
        System.assertEquals(1, [SELECT Id FROM Attachment WHERE ParentId IN (SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id)].size());

        // Submission new status
        System.assertEquals(C.SUBMISSION_STATUS_UPLOADED_AUTO, [SELECT Status__c FROM Submission__c WHERE Survey__c = :survey.Id].Status__c);

        // Check the response
        checkFieldMappingFailureClose();
    }

    /**
     * Submission with missing field will close the survey and save the answer as attachment
     */
    static testMethod void submissionWithMapDeletedFieldTest() {

        // Create survey
        Survey__c survey = new Survey__c(Name = 'SubmissionTestMissingObject', Status__c = SurveyDO.STATUS_DRAFT);
        insert survey;

        // Create questions
        List<Question__c> questions = createQuestions(survey);

        SurveyVersion__c[] versions = [
            SELECT
                Status__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c = :survey.Id
            ORDER BY
                Version__c DESC
        ];

        // Publish survey
        versions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        update versions;

        // Create jobs and tasks
        createJobsAndTasks(versions[0]);

        // Create survey mapping
        SurveyMapping__c sm = TestUtils.mapObject(survey, Contact.SObjectType.getDescribe().getName());

        // Create question mappings to a non existent field
        QuestionMappingTH.skipValidation = true;
        QuestionMapping__c qm = TestUtils.mapQuestion(sm, questions[1], 'deletedField', true);
        QuestionMappingTH.skipValidation = true;

        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id, new List<String>{ 'Pepe', 'Heisenberg' });

        TestUtils.Surveyor surveyor = setUpRequest(xmlToSend, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Survey was closed after the submission
        System.assertEquals(surveyDO.STATUS_CLOSED, [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c DESC LIMIT 1].Status__c);

        // Submission was made anyway
        System.assertEquals(1, [SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id].size());

        // Answer was saved as submission attachment
        System.assertEquals(1, [SELECT Id FROM Attachment WHERE ParentId IN (SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id)].size());

        // Submission new status
        System.assertEquals(C.SUBMISSION_STATUS_UPLOADED_AUTO, [SELECT Status__c FROM Submission__c WHERE Survey__c = :survey.Id].Status__c);

        // Check the response
        checkFieldMappingFailureClose();
    }

    /**
     * Submission with missing relation will close the survey and save the answer as attachment
     */
    static testMethod void submissionWithMapDeletedRelationTest() {

        // Create survey
        Survey__c survey = new Survey__c(Name = 'SubmissionTestMissingObject', Status__c = SurveyDO.STATUS_DRAFT);
        insert survey;

        // Create questions
        List<Question__c> questions = createQuestions(survey);

        SurveyVersion__c[] versions = [
        SELECT
            Status__c
        FROM
            SurveyVersion__c
        WHERE
            Survey__c = :survey.Id
        ORDER BY
            Version__c DESC
        ];

        // Publish survey
        versions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        update versions;

        // Create jobs and tasks
        createJobsAndTasks(versions[0]);

        // Create survey mapping
        SurveyMapping__c sm1 = TestUtils.mapObject(survey, Contact.SObjectType.getDescribe().getName());
        SurveyMapping__c sm2 = TestUtils.mapObject(survey, Account.SObjectType.getDescribe().getName());

        // Create a relationship where the field behaves as a deleted field).
        ObjectRelationshipMapping__c deletedRelation = TestUtils.relateObjects(sm1, sm2, 'fakeRelation');

        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id, new List<String>{ 'Pepe', 'Heisenberg' });

        TestUtils.Surveyor surveyor = setUpRequest(xmlToSend, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Survey was closed after the submission
        System.assertEquals(surveyDO.STATUS_CLOSED, [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c DESC LIMIT 1].Status__c);

        // Submission was made anyway
        System.assertEquals(1, [SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id].size());

        // Answer was saved as submission attachment
        System.assertEquals(1, [SELECT Id FROM Attachment WHERE ParentId IN (SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id)].size());

        // Submission new status
        System.assertEquals(C.SUBMISSION_STATUS_UPLOADED_AUTO, [SELECT Status__c FROM Submission__c WHERE Survey__c = :survey.Id].Status__c);
    }

    /**
     * Test that a submission for a closed survey is saved correctly and the submission
     * has the correct status
     */
    static testMethod void testSubmissionWithMapDeletedRelationAndClosedBeforeSubmit() {

        // Create survey
        Survey__c survey = new Survey__c(Name = 'SubmissionTestMissingObject', Status__c = SurveyDO.STATUS_DRAFT);
        insert survey;

        // Create questions
        List<Question__c> questions = createQuestions(survey);

        SurveyVersion__c[] versions = [
            SELECT
                Status__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c = :survey.Id
            ORDER BY
                Version__c DESC
        ];

        // Publish survey
        versions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        update versions;

        // Create jobs and tasks
        createJobsAndTasks(versions[0]);

        // Create survey mapping
        SurveyMapping__c sm1 = TestUtils.mapObject(survey, Contact.SObjectType.getDescribe().getName());
        SurveyMapping__c sm2 = TestUtils.mapObject(survey, Account.SObjectType.getDescribe().getName());

        // Create a relationship where the field behaves as a deleted field).
        ObjectRelationshipMapping__c deletedRelation = TestUtils.relateObjects(sm1, sm2, 'fakeRelation');

        // Clone survey must close this one
        SurveyManagerController smc = new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
        smc.doAction = 'Clone';
        smc.surveyIdAction = survey.Id;
        smc.doMoreAction();

        // The survey was closed because it had some missing relation
        System.AssertEquals(surveyDO.STATUS_CLOSED, [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c DESC LIMIT 1].Status__c);

        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id, new List<String>{ 'Pepe', 'Heisenberg' });

        TestUtils.Surveyor surveyor = setUpRequest(xmlToSend, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Submission was made anyway
        System.assertEquals(1, [SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id].size());

        // Answer was saved as submission attachment
        System.assertEquals(1, [SELECT Id FROM Attachment WHERE ParentId IN (SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id)].size());

        // Submission new status
        System.assertEquals(C.SUBMISSION_STATUS_UPLOADED_AUTO, [SELECT Status__c FROM Submission__c WHERE Survey__c = :survey.Id].Status__c);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_SUB_SURVEY_CLOSED, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.SURVEY_SUB_SURVEY_CLOSED, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test deprecation of /submission/ endpoint. It should return a 404 error
     * at all times. Even with valid submission
     */
    static testMethod void testDeprecatedSubmissionEndpoint() {

        Survey__c survey = createAndPublishSurvey('VAlidSubmissionTest');

        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id, new List<String>{ 'Pepe', 'Heisenberg' });

        TestUtils.Surveyor surveyor = setUpRequest(xmlToSend, '', '');

        Test.startTest();

        // Submit to old endpoint
        System.runAs(surveyor.partnerUser) {
            SurveySubmissionService.processSubmission();
        }

        // Check for the 404 error
        System.assertEquals(C.HTTP_NOT_FOUND, RestContext.response.statusCode);
    }

    //---------------------------- CASCADING SELECT ----------------------------

    /**
     * Basic submission of a survey with a cascading select question
     */
    public static testMethod void testBasicSubmissionWithCascading() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'SurveyName');
        insert survey;

        SurveyVersion__c ver = [SELECT Id
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect('Cascading Select', levelsData);

        // Create a section
        Question__c section = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert section;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = section.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        ver.Status__c = SurveyDO.STATUS_PUBLISHED;
        update ver;

        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + ver.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + section.Name + '>' +
                    '<' + cascadingParentQuestion.Name + '>' +
                        '<' + makeQuestion.Name + '>Audi</' + makeQuestion.Name + '>' +
                        '<' + modelQuestion.Name + '>A3</' + modelQuestion.Name + '>' +
                        '<' + yearQuestion.Name + '>2001</' + yearQuestion.Name + '>' +
                    '</'+ cascadingParentQuestion.Name + '>' +
                '</' + section.Name + '>' +
            '</' + survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
        // Get the generated id
        Id submissionId = RestContext.response.headers.get(C.SUBMISSION_ID_HEADER);
        System.assertNotEquals(null, submissionId);
        System.assertEquals(
            C.SUBMISSION_STATUS_UPLOADED,
            [SELECT Status__c FROM Submission__c WHERE Id = :submissionId][0].Status__c
        );

        // Check the submission and the answers were correctly created
        List<Submission__c> resultSA = [SELECT Id,
                                               Name,
                                               Survey__c,
                                               Date__c,
                                               Status__c,
                                               gps_x__c,
                                               gps_y__c
                                        FROM Submission__c
                                        WHERE Survey__c = :survey.Id];

        System.assertEquals(1, resultSA.size());
        System.assertEquals(survey.Id, resultSA[0].survey__c);
        System.assertEquals(80.0, resultSA[0].gps_x__c);
        System.assertEquals(Date.valueOf('2012-02-14'), resultSA[0].Date__c);

        // Check only one xml is inserted
        List<Attachment> xmlFiles = [SELECT Id,
                                            Body
                                     FROM Attachment
                                     WHERE ParentId = :submissionId
                                           AND Name = :C.SURVEY_ANSWER_ATTACHMENT_NAME
                                     ORDER BY Name];
        System.assertEquals(1, xmlFiles.size());

        // Check insertion of the answers
        List<Answer__c> answers = [SELECT Id,
                                          Value__c,
                                          Question__r.Name
                                   FROM Answer__c
                                   WHERE Submission__c = :submissionId
                                   ORDER BY Question__r.Position__c];

        System.assertEquals(3, answers.size());
        System.assertEquals('Audi', answers[0].Value__c);
        System.assertEquals('A3', answers[1].Value__c);
        System.assertEquals('2001', answers[2].Value__c);
    }

    /**
     * Submission with no response of a cascading select
     */
    public static testMethod void testSubmissionWithCascadingEmpty() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'SurveyName');
        insert survey;

        SurveyVersion__c ver = [SELECT Id
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect('Cascading Select', levelsData);

        // Create a section
        Question__c section = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert section;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = section.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        ver.Status__c = SurveyDO.STATUS_PUBLISHED;
        update ver;

        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + ver.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + section.Name + '>' +
                    '<' + cascadingParentQuestion.Name + '>' +
                        '<' + makeQuestion.Name + ' />' +
                        '<' + modelQuestion.Name + ' />' +
                        '<' + yearQuestion.Name + ' />' +
                    '</'+ cascadingParentQuestion.Name + '>' +
                '</' + section.Name + '>' +
            '</' + survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
        // Get the generated id
        Id submissionId = RestContext.response.headers.get(C.SUBMISSION_ID_HEADER);
        System.assertNotEquals(null, submissionId);
        System.assertEquals(
            C.SUBMISSION_STATUS_UPLOADED,
            [SELECT Status__c FROM Submission__c WHERE Id = :submissionId][0].Status__c
        );

        // Check the submission and the answers were correctly created
        List<Submission__c> resultSA = [SELECT Id,
                                               Name,
                                               Survey__c,
                                               Date__c,
                                               Status__c,
                                               gps_x__c,
                                               gps_y__c
                                        FROM Submission__c
                                        WHERE Survey__c = :survey.Id];

        System.assertEquals(1, resultSA.size());
        System.assertEquals(survey.Id, resultSA[0].survey__c);
        System.assertEquals(80.0, resultSA[0].gps_x__c);
        System.assertEquals(Date.valueOf('2012-02-14'), resultSA[0].Date__c);

        // Check only one xml is inserted
        List<Attachment> xmlFiles = [SELECT Id,
                                            Body
                                     FROM Attachment
                                     WHERE ParentId = :submissionId
                                           AND Name = :C.SURVEY_ANSWER_ATTACHMENT_NAME
                                     ORDER BY Name];
        System.assertEquals(1, xmlFiles.size());

        // Check insertion of the answers
        List<Answer__c> answers = [SELECT Id,
                                          Value__c,
                                          Question__r.Name
                                   FROM Answer__c
                                   WHERE Submission__c = :submissionId
                                   ORDER BY Question__r.Position__c];

        System.assertEquals(0, answers.size());
    }

    /**
     * Submission with mapping in a cascading select question
     */
    public static testMethod void testSubmissionCascadingMapped() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'SurveyName');
        insert survey;

        SurveyVersion__c ver = [SELECT Id
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'},
            new List<String> {'Audi', 'A5', '2003'},
            new List<String> {'Dodge', 'Charger', '2006'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect('Cascading Select', levelsData);

        // Create a section
        Question__c section = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert section;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = section.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        // Add some mappings
        SurveyMapping__c surveyMapping = new SurveyMapping__c(
            ObjectApiName__c = 'Contact',
            Survey__c = survey.Id
        );
        insert surveyMapping;

        QuestionMapping__c questionMapping1 = new QuestionMapping__c(
            Question__c = makeQuestion.Id,
            SurveyMapping__c = surveyMapping.Id,
            FieldApiName__c = 'LastName'
        );
        QuestionMapping__c questionMapping2 = new QuestionMapping__c(
            Question__c = modelQuestion.Id,
            SurveyMapping__c = surveyMapping.Id,
            FieldApiName__c = 'FirstName'
        );
        QuestionMapping__c questionMapping3 = new QuestionMapping__c(
            Question__c = yearQuestion.Id,
            SurveyMapping__c = surveyMapping.Id,
            FieldApiName__c = 'AssistantName'
        );
        List<QuestionMapping__c> questionMappings = new List<QuestionMapping__c> {
            questionMapping1,
            questionMapping2,
            questionMapping3
        };
        insert questionMappings;

        ver.Status__c = SurveyDO.STATUS_PUBLISHED;
        update ver;

        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + ver.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + section.Name + '>' +
                    '<' + cascadingParentQuestion.Name + '>' +
                        '<' + makeQuestion.Name + '>Audi</' + makeQuestion.Name + '>' +
                        '<' + modelQuestion.Name + '>A3</' + modelQuestion.Name + '>' +
                        '<' + yearQuestion.Name + '>2001</' + yearQuestion.Name + '>' +
                    '</'+ cascadingParentQuestion.Name + '>' +
                '</' + section.Name + '>' +
            '</' + survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Check the contact created with the mapping
        List<Contact> newContacts = [SELECT Id,
                                            LastName,
                                            FirstName,
                                            AssistantName
                                     FROM Contact
                                     WHERE LastName = 'Audi'];

        System.assertEquals(1, newContacts.size());
        System.assertEquals('Audi', newContacts[0].LastName);
        System.assertEquals('A3', newContacts[0].FirstName);
        System.assertEquals('2001', newContacts[0].AssistantName);
    }

    /**
     * Submission with mapping in a cascading select question and id field selected
     */
    public static testMethod void testSubmissionCascadingMappedWithId() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'SurveyName');
        insert survey;

        SurveyVersion__c ver = [SELECT Id
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'},
            new List<String> {'Audi', 'A5', '2003'},
            new List<String> {'Dodge', 'Charger', '2006'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect('Cascading Select', levelsData);

        // Create a section
        Question__c section = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert section;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = section.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        // Add some mappings
        SurveyMapping__c surveyMapping = new SurveyMapping__c(
            ObjectApiName__c = 'Contact',
            MatchingField__c = 'LastName',
            Survey__c = survey.Id
        );
        insert surveyMapping;

        QuestionMapping__c questionMapping1 = new QuestionMapping__c(
            Question__c = makeQuestion.Id,
            SurveyMapping__c = surveyMapping.Id,
            FieldApiName__c = 'LastName'
        );
        QuestionMapping__c questionMapping2 = new QuestionMapping__c(
            Question__c = modelQuestion.Id,
            SurveyMapping__c = surveyMapping.Id,
            FieldApiName__c = 'FirstName'
        );
        QuestionMapping__c questionMapping3 = new QuestionMapping__c(
            Question__c = yearQuestion.Id,
            SurveyMapping__c = surveyMapping.Id,
            FieldApiName__c = 'AssistantName'
        );
        List<QuestionMapping__c> questionMappings = new List<QuestionMapping__c> {
            questionMapping1,
            questionMapping2,
            questionMapping3
        };
        insert questionMappings;

        ver.Status__c = SurveyDO.STATUS_PUBLISHED;
        update ver;

        // Add a contact with the id field to update
        Contact aContact = new Contact(
            LastName = 'Audi',
            FirstName = 'SomeName',
            AssistantName = 'AssisName'
        );
        insert aContact;

        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + ver.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + section.Name + '>' +
                    '<' + cascadingParentQuestion.Name + '>' +
                        '<' + makeQuestion.Name + '>Audi</' + makeQuestion.Name + '>' +
                        '<' + modelQuestion.Name + '>A3</' + modelQuestion.Name + '>' +
                        '<' + yearQuestion.Name + '>2001</' + yearQuestion.Name + '>' +
                    '</'+ cascadingParentQuestion.Name + '>' +
                '</' + section.Name + '>' +
            '</' + survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Check the contact updated with the mapping
        List<Contact> newContacts = [SELECT Id,
                                            LastName,
                                            FirstName,
                                            AssistantName
                                     FROM Contact
                                     WHERE LastName = 'Audi'];

        System.assertEquals(1, newContacts.size());
        System.assertEquals(aContact.Id, newContacts[0].Id);
        System.assertEquals('Audi', newContacts[0].LastName);
        System.assertEquals('A3', newContacts[0].FirstName);
        System.assertEquals('2001', newContacts[0].AssistantName);
    }

    /**
     * Submission with multiple mappings in a cascading select question
     */
    public static testMethod void testSubmissionCascadingMultipleMappings() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'SurveyName');
        insert survey;

        SurveyVersion__c ver = [SELECT Id
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'},
            new List<String> {'Audi', 'A5', '2003'},
            new List<String> {'Dodge', 'Charger', '2006'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect('Cascading Select', levelsData);

        // Create a section
        Question__c section = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert section;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = section.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        // Add some mappings
        SurveyMapping__c surveyMapping = new SurveyMapping__c(
            ObjectApiName__c = 'Contact',
            Survey__c = survey.Id
        );
        SurveyMapping__c surveyMapping1 = new SurveyMapping__c(
            ObjectApiName__c = 'Account',
            Survey__c = survey.Id
        );
        insert new List<SurveyMapping__c> {surveyMapping, surveyMapping1};

        QuestionMapping__c questionMapping1 = new QuestionMapping__c(
            Question__c = makeQuestion.Id,
            SurveyMapping__c = surveyMapping.Id,
            FieldApiName__c = 'LastName'
        );
        QuestionMapping__c questionMapping2 = new QuestionMapping__c(
            Question__c = modelQuestion.Id,
            SurveyMapping__c = surveyMapping.Id,
            FieldApiName__c = 'FirstName'
        );
        QuestionMapping__c questionMapping3 = new QuestionMapping__c(
            Question__c = yearQuestion.Id,
            SurveyMapping__c = surveyMapping1.Id,
            FieldApiName__c = 'Name'
        );
        List<QuestionMapping__c> questionMappings = new List<QuestionMapping__c> {
            questionMapping1,
            questionMapping2,
            questionMapping3
        };
        insert questionMappings;

        ver.Status__c = SurveyDO.STATUS_PUBLISHED;
        update ver;

        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + ver.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + section.Name + '>' +
                    '<' + cascadingParentQuestion.Name + '>' +
                        '<' + makeQuestion.Name + '>Audi</' + makeQuestion.Name + '>' +
                        '<' + modelQuestion.Name + '>A3</' + modelQuestion.Name + '>' +
                        '<' + yearQuestion.Name + '>2001</' + yearQuestion.Name + '>' +
                    '</'+ cascadingParentQuestion.Name + '>' +
                '</' + section.Name + '>' +
            '</' + survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Check the contact created with the mapping
        List<Contact> newContacts = [SELECT Id,
                                            LastName,
                                            FirstName,
                                            AssistantName
                                     FROM Contact
                                     WHERE LastName = 'Audi'];

        System.assertEquals(1, newContacts.size());
        System.assertEquals('Audi', newContacts[0].LastName);
        System.assertEquals('A3', newContacts[0].FirstName);

        // Check the account created with the mapping
        List<Account> accounts = [SELECT Id
                                  FROM Account
                                  WHERE Name = '2001'];

        System.assertEquals(1, accounts.size());
    }

    /**
     * Submission with non-existent values for a cascading select question
     */
    public static testMethod void testSubmissionCascadingNonExistentValues() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'SurveyName');
        insert survey;

        SurveyVersion__c ver = [SELECT Id
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect(
            'Cascading Select',
            levelsData
        );

        //create a section
        Question__c section = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert section;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = section.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        ver.Status__c = SurveyDO.STATUS_PUBLISHED;
        update ver;

        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + ver.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + section.Name + '>' +
                    '<' + cascadingParentQuestion.Name + '>' +
                        '<' + makeQuestion.Name + '>Wrong value</' + makeQuestion.Name + '>' +
                        '<' + modelQuestion.Name + '>Another Wrong Value</' + modelQuestion.Name + '>' +
                        '<' + yearQuestion.Name + '>Last Wrong Value</' + yearQuestion.Name + '>' +
                    '</'+ cascadingParentQuestion.Name + '>' +
                '</' + section.Name + '>' +
            '</' + survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(
            ErrorHandlingRest.ERR_CODE_SUB_INVALID_CASCADING,
            errorMessages[0].getErrorCode()
        );
        System.assertEquals(
            ErrorHandlingRest.SURVEY_SUB_INVALID_CASCADING,
            errorMessages[0].getErrorTranslationCode()
        );
    }

    /**
     * Submit survey with 1st level's answer empty and the other levels answers not empty
     */
    public static testMethod void testSubmissionCascadingFirstLevelEmpty() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'SurveyName');
        insert survey;

        SurveyVersion__c ver = [SELECT Id
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect(
            'Cascading Select',
            levelsData
        );

        //create a section
        Question__c section = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert section;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = section.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        ver.Status__c = SurveyDO.STATUS_PUBLISHED;
        update ver;

        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + ver.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + section.Name + '>' +
                    '<' + cascadingParentQuestion.Name + '>' +
                        '<' + makeQuestion.Name + ' />' +
                        '<' + modelQuestion.Name + '>A3</' + modelQuestion.Name + '>' +
                        '<' + yearQuestion.Name + '>2001</' + yearQuestion.Name + '>' +
                    '</'+ cascadingParentQuestion.Name + '>' +
                '</' + section.Name + '>' +
            '</' + survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(
            ErrorHandlingRest.ERR_CODE_SUB_INVALID_CASCADING,
            errorMessages[0].getErrorCode()
        );
        System.assertEquals(
            ErrorHandlingRest.SURVEY_SUB_INVALID_CASCADING,
            errorMessages[0].getErrorTranslationCode()
        );
    }

    /**
     * Submit survey answering skipped levels
     */
    public static testMethod void testSubmissionCascadingSkippedLevels() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'SurveyName');
        insert survey;

        SurveyVersion__c ver = [SELECT Id
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year', '0KM'},
            new List<String> {'Audi', 'A3', '2001', 'Yes'},
            new List<String> {'Audi', 'A4', '2002', 'No'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect(
            'Cascading Select',
            levelsData
        );

        //create a section
        Question__c section = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert section;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = section.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        Question__c kmQuestion = new Question__c(
            Caption__c = levels[3].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'km',
            Position__c = 4,
            CascadingLevel__c = levels[3].Id,
            ControllingQuestion__c = yearQuestion.Id
        );
        insert kmQuestion;

        ver.Status__c = SurveyDO.STATUS_PUBLISHED;
        update ver;

        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + ver.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + section.Name + '>' +
                    '<' + cascadingParentQuestion.Name + '>' +
                        '<' + makeQuestion.Name + ' />' +
                        '<' + modelQuestion.Name + '>A3</' + modelQuestion.Name + '>' +
                        '<' + yearQuestion.Name + '/>' +
                        '<' + kmQuestion.Name + '>Yes</' + kmQuestion.Name + '>' +
                    '</'+ cascadingParentQuestion.Name + '>' +
                '</' + section.Name + '>' +
            '</' + survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(
            ErrorHandlingRest.ERR_CODE_SUB_INVALID_CASCADING,
            errorMessages[0].getErrorCode()
        );
        System.assertEquals(
            ErrorHandlingRest.SURVEY_SUB_INVALID_CASCADING,
            errorMessages[0].getErrorTranslationCode()
        );
    }

    /**
     * Submit survey answering with exchanged levels
     */
    public static testMethod void testSubmissionCascadingExchangedLevels() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'SurveyName');
        insert survey;

        SurveyVersion__c ver = [SELECT Id
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year', '0KM'},
            new List<String> {'Audi', 'A3', '2001', 'Yes'},
            new List<String> {'Citroen', 'ZX', '1998', 'No'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect(
            'Cascading Select',
            levelsData
        );

        //create a section
        Question__c section = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert section;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = section.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        Question__c kmQuestion = new Question__c(
            Caption__c = levels[3].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'km',
            Position__c = 4,
            CascadingLevel__c = levels[3].Id,
            ControllingQuestion__c = yearQuestion.Id
        );
        insert kmQuestion;

        ver.Status__c = SurveyDO.STATUS_PUBLISHED;
        update ver;

        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + ver.Id + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<location>70.0 80.0 0.0 1400.0</location>'+
                '<phonenumber />'+
                '<' + section.Name + '>' +
                    '<' + cascadingParentQuestion.Name + '>' +
                        '<' + makeQuestion.Name + '>Audi</' + makeQuestion.Name + '>' +
                        '<' + modelQuestion.Name + '>ZX</' + modelQuestion.Name + '>' +
                        '<' + yearQuestion.Name + '>1998</' + yearQuestion.Name + '>' +
                        '<' + kmQuestion.Name + '>Yes</' + kmQuestion.Name + '>' +
                    '</'+ cascadingParentQuestion.Name + '>' +
                '</' + section.Name + '>' +
            '</' + survey.Name + '>';

        TestUtils.Surveyor surveyor = setUpRequest(xml, '', '');

        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(
            ErrorHandlingRest.ERR_CODE_SUB_INVALID_CASCADING,
            errorMessages[0].getErrorCode()
        );
        System.assertEquals(
            ErrorHandlingRest.SURVEY_SUB_INVALID_CASCADING,
            errorMessages[0].getErrorTranslationCode()
        );
    }

    /**
     * Test submitting a PPI survey and the creation of a PpiResult__c record
     */
    static testMethod void testPpiSubmission() {
        TestSurveyData testSurvey = TestSurveyData.createFullPpiTemplate();
        Contact interviewee = new Contact(LastName = 'TestLastName');
        insert interviewee;
        String submissionXml = buildPpiTemplateSubmissionXml(testSurvey, interviewee);
        TestUtils.Surveyor surveyor = setUpRequest(submissionXml, '', '');
        System.runAs(surveyor.partnerUser) {
            Test.startTest();
            SurveySubmissions.processSubmission();
            Test.stopTest();
        }

        // Test that the PPI Result object was created correctly
        PpiResultSelector resultSelector = new PpiResultSelector();
        resultSelector.mainQueryBuilder.addRelationshipToSelect(
            resultSelector.createAnswersRemoteIdRelation()
        );
        List<PpiResult__c> ppiResults = resultSelector.getByClientId(interviewee.Id);
        System.assertEquals(1, ppiResults.size(), 'One PpiResult should have been created');

        // Check success of the submission
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
        Id submissionId = RestContext.response.headers.get(C.SUBMISSION_ID_HEADER);
        Submission__c submission = (Submission__c) new SubmissionSelector().getRecordById(
            submissionId
        );
        System.assertEquals(
            10,
            submission.PPIScore__c,
            'PPI Score should be 10'
        );
    }

    /**
     * Build the submission xml for a PPI Template
     */
    private static String buildPpiTemplateSubmissionXml(
            TestSurveyData testSurvey,
            Contact interviewee
    ) {
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode xmlRoot = doc.createRootElement('data', null, null);
        xmlRoot.setAttribute('id', testSurvey.testSurveyVersion.Id);

        // Create header
        Dom.XmlNode startNode = xmlRoot.addChildElement('start', null, null);
        startNode.addTextNode('2014-09-17T16:54:02.315+05:30');
        Dom.XmlNode endNode = xmlRoot.addChildElement('end', null, null);
        endNode.addTextNode('2014-09-17T16:59:02.315+05:30');
        Dom.XmlNode todayNode = xmlRoot.addChildElement('today', null, null);
        todayNode.addTextNode('2014-09-17');
        Dom.XmlNode deviceIdNode = xmlRoot.addChildElement('deviceid', null, null);
        Dom.XmlNode simIdNode = xmlRoot.addChildElement('simid', null, null);
        simIdNode.addTextNode('8991272162526858221');
        Dom.XmlNode phoneNumberNode = xmlRoot.addChildElement('phonenumber', null, null);

        // Create client id section
        Dom.XmlNode clientIdSection = xmlRoot.addChildElement(
            testSurvey.topLevelSections[0].Name.replace(' ', '_'),
            null,
            null
        );
        Dom.XmlNode clientIdQuestion = clientIdSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[0].Name.replace(' ', '_'),
            null,
            null
        );
        clientIdQuestion.addTextNode(interviewee.Id);


        // Create demographic section
        Dom.XmlNode clientDemographicSection = xmlRoot.addChildElement(
            testSurvey.topLevelSections[1].Name.replace(' ', '_'),
            null,
            null
        );
        Dom.XmlNode genderQuestion = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[1].Id)[0].Name.replace(' ', '_'),
            null,
            null
        );
        genderQuestion.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[1].Id)[0].Id
            )[0].Id
        );
        Dom.XmlNode ageQuestion = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[1].Id)[1].Name.replace(' ', '_'),
            null,
            null
        );
        ageQuestion.addTextNode('39');
        Dom.XmlNode householdSizeQuestion = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[1].Id)[2].Name.replace(' ', '_'),
            null,
            null
        );
        householdSizeQuestion.addTextNode('5');
        Dom.XmlNode joinedDate = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[1].Id)[3].Name.replace(' ', '_'),
            null,
            null
        );
        joinedDate.addTextNode('2012-09-17');
        Dom.XmlNode geoLocationQuestion = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[1].Id)[4].Name.replace(' ', '_'),
            null,
            null
        );
        geoLocationQuestion.addTextNode('18.55226 73.8045989 0.0 797.0');

        // Create ppi answers section
        Dom.XmlNode ppiQuestionSection = xmlRoot.addChildElement(
            testSurvey.topLevelSections[2].Name.replace(' ', '_'),
            null,
            null
        );
        Dom.XmlNode ppiQuestion1 = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[0].Name.replace(' ', '_'),
            null,
            null
        );
        ppiQuestion1.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[0].Id
            )[0].Id
        );
        Dom.XmlNode ppiQuestion2 = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[1].Name.replace(' ', '_'),
            null,
            null
        );
        ppiQuestion2.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[1].Id
            )[0].Id
        );
        Dom.XmlNode ppiQuestion3 = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[2].Name.replace(' ', '_'),
            null,
            null
        );
        ppiQuestion3.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[2].Id
            )[0].Id
        );
        Dom.XmlNode ppiQuestion4 = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[3].Name.replace(' ', '_'),
            null,
            null
        );
        ppiQuestion4.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[3].Id
            )[0].Id
        );
        Dom.XmlNode ppiQuestion5 = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[4].Name.replace(' ', '_'),
            null,
            null
        );
        ppiQuestion5.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[4].Id
            )[0].Id
        );
        Dom.XmlNode ppiQuestion6 = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[5].Name.replace(' ', '_'),
            null,
            null
        );
        ppiQuestion6.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[5].Id
            )[0].Id
        );
        Dom.XmlNode ppiQuestion7 = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[6].Name.replace(' ', '_'),
            null,
            null
        );
        ppiQuestion7.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[6].Id
            )[0].Id
        );
        Dom.XmlNode ppiQuestion8 = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[7].Name.replace(' ', '_'),
            null,
            null
        );
        ppiQuestion8.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[7].Id
            )[0].Id
        );
        Dom.XmlNode ppiQuestion9 = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[8].Name.replace(' ', '_'),
            null,
            null
        );
        ppiQuestion9.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[8].Id
            )[0].Id
        );
        Dom.XmlNode ppiQuestion10 = clientDemographicSection.addChildElement(
            testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[9].Name.replace(' ', '_'),
            null,
            null
        );
        ppiQuestion10.addTextNode(
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(testSurvey.topLevelSections[2].Id)[9].Id
            )[0].Id
        );
        return doc.toXmlString();
    }
}