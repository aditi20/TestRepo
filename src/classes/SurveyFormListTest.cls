/**
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Sebastian Piazza
 */
@isTest
public class SurveyFormListTest {

    // List of created test surveys
    static List<Survey__c> surveys;

    // List of created test contact groups
    static List<ContactGroup__c> ctGroups;

    // Map of survey version id as string and survey id
    static Map<String,Id> mapSurveys;

    // List of survey versions
    static List<SurveyVersion__c> surveyVersions;

    // List of surveyors
    static List<TestUtils.Surveyor> surveyors;
    static List<Contact> contacts;

    /**
     * Create a set of test data
     *
     * @param numberofSurveys - Number of surveys to be created along with their related groups
     */
    static void prepareData(Integer numberOfSurveys) {

        // Create surveys and groups
        surveys = new List<Survey__c>();
        ctGroups = new List<ContactGroup__c>();
        mapSurveys = new Map<String,Id>();
        surveyors = new List<TestUtils.Surveyor>();
        contacts = new List<Contact>();

        for (Integer i = 0; i < numberOfSurveys; i++) {
            surveys.add(new Survey__c(
                Status__c = SurveyDO.STATUS_PUBLISHED, Name = '__test__' + String.valueOf(i),
                Description__c  = 'This is a description', Version__c = 1.0
            ));
        }
        insert surveys;

        ctGroups.add(new ContactGroup__c(Name = 'GroupTest'+0, Status__c = C.GROUP_STATUS_ACTIVE));
        ctGroups.add(new ContactGroup__c(Name = 'GroupTest'+1, Status__c = C.GROUP_STATUS_ACTIVE));
        insert ctGroups;

        // Publish all the versions of the Active Surveys
        surveyVersions = [select Status__c from SurveyVersion__c where Survey__c in :surveys];
        for (SurveyVersion__c version:surveyVersions) {
            version.Status__c = SurveyDO.STATUS_PUBLISHED;
            mapSurveys.put(String.valueOf(version.Id),version.Survey__c);
        }
        update surveyVersions;

        // Create a Contact with valid credentials
        TestUtils.Surveyor surveyor =
            TestUtils.createPartnerSurveyor(
                'LastNameSFLT1',
                true
            );
        surveyors.add(surveyor);
        contacts.add(surveyor.theContact);

        // Create assigments based on surveys and groups previously created
        assignContactsToSurveys();
    }

    /**
     * Given created surveys and created groups, this creates assignments for the survey, the groups and the given surveyors
     */
    static void assignContactsToSurveys() {

        List<ContactGroupSurveyAssignment__c> ctGroupAssigns=new List<ContactGroupSurveyAssignment__c>();
        List<ContactGroupMember__c> ctGroupMembers =new List<ContactGroupMember__c>();

        for (Integer i = 0; i < surveys.size()/2; i++) {
            ContactGroupSurveyAssignment__c ctGroupAssign =
                new ContactGroupSurveyAssignment__c(ContactGroup__c = ctGroups[0].Id, Survey__c = surveys[i].Id);
            ContactGroupMember__c ctGroupMember =
                new ContactGroupMember__c(ContactGroup__c = ctGroups[0].Id, Contact__c = contacts[0].Id);

            ctGroupAssigns.add(ctGroupAssign);
            ctGroupMembers.add(ctGroupMember);
        }

        // Create group assignment of the surveys
        insert ctGroupAssigns;

        // Create contact group member in the group
        DBFullAccess.InsertSObject(ctGroupMembers);
    }

    /**
     * Setup the request with parameters according to the prepareData method
     *
     * @param surveyVersionId - Survey version id in case we are requesting only 1 form
     * @param attachment      - Indicates if an attachment should be automatically generated
     * @param sessionId       - The session id for the mobile user generated from the login
     * @param documentBody    - String to put in the attachment
     */
    static void setUpRequest(
            String surveyVersionId,
            boolean atachment,
            String sessionId,
            String documentBody
    ) {

        // Init the headers map
        Map<String, String> headersMap = new Map<String, String>{
            C.SESSION_TOKEN_HEADER => sessionId

        };

        // Prepare the request
        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('formList'),
            null,
            headersMap
        );

        // Set up the survey if needed
        if (surveyVersionId != null) {
            RestContext.request.params.put('id', surveyVersionId);
            if (atachment) {

                // In case we are requesting by surveyVersionId we need to have an atachment associated to this survey version
                Attachment att = new Attachment(
                Name = XformCreator.XFORM_ATTACHMENT,
                ParentId = surveyVersionId,
                Body = blob.valueOf(documentBody));
                insert att;
            }
        }
    }

    /**
     * Test the get form list with survey version id as a parameter
     */
    static testMethod void testGetSurvey() {

        // INITIALIZE TEST
        // Prepare test data
        prepareData(2);

        // Log in the Mobile User
        surveyors[0] = TestUtils.partnerLoginDetails(surveyors[0]);

        // Setup rest request
        setUpRequest(
            surveyVersions[0].Id,
            true,
            surveyors[0].loginResult.getSessionToken(),
            'Body of Document'
        );

        // START TEST
        Test.startTest();
        System.runAs(surveyors[0].partnerUser) {
            SurveyFormList.doGet();
        }
        Test.stopTest();

        // VALIDATE
        // verify if request has been successful
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
        String xml = RestContext.response.responseBody.toString();
        System.assertEquals('Body of Document', xml);
    }

    /**
     * Test to check that correct error is returned when no survey id is passed in
     * TODO - Add this back in 3.0 too close to release to refactor this code now
     *
    static testMethod void testSurveyIdMissing() {

        // INITIALIZE TEST
        // Prepare test data
        prepareData(2);

        // Log in the Mobile User
        surveyors[0] = TestUtils.partnerLoginDetails(surveyors[0]);

        // Setup rest request
        setUpRequest(
            null,
            true,
            surveyors[0].loginResult.getSessionToken(),
            'Body of Document'
        );

        // START TEST
        Test.startTest();
        System.runAs(surveyors[0].partnerUser) {
            SurveyFormList.doGet();
        }
        Test.stopTest();

        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(
            ErrorHandlingRest.ERR_CODE_SURVEY_ID_MISSING,
            errorMessages[0].getErrorCode()
        );
        System.assertEquals(
            ErrorHandlingRest.SURVEY_FORMLIST_ID_MISSING,
            errorMessages[0].getErrorTranslationCode()
        );
    }
    */

    /**
     * Test get form list with a survey version id as parameter without an atachment it should fail
     */
    static testMethod void testGetSurveyWithoutAtachment() {

        // INITIALIZE TEST
        // Prepare test data
        prepareData(2);

        // Log in the Mobile User
        surveyors[0] = TestUtils.partnerLoginDetails(surveyors[0]);

        // Setup rest request
        setUpRequest(
            surveyVersions[0].Id,
            false,
            surveyors[0].loginResult.getSessionToken(),
            ''
        );

        // START TEST
        Test.startTest();
        System.runAs(surveyors[0].partnerUser) {
            SurveyFormList.doGet();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_NOT_FOUND, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_SURVEY_MISSING_XFORM, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.SURVEY_FORMLIST_NO_XFORM, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test get form list with a survey version with an empty attachment
     */
    static testMethod void testGetSurveyWithEmptyAttachment() {

        // INITIALIZE TEST
        // Prepare test data
        prepareData(2);

        // Log in the Mobile User
        surveyors[0] = TestUtils.partnerLoginDetails(surveyors[0]);

        // Setup rest request
        setUpRequest(
            surveyVersions[0].Id,
            true,
            surveyors[0].loginResult.getSessionToken(),
            ''
        );

        // START TEST
        Test.startTest();
        System.runAs(surveyors[0].partnerUser) {
            SurveyFormList.doGet();
        }
        Test.stopTest();

        // Check the results
        System.assertEquals(C.HTTP_NOT_FOUND, RestContext.response.statusCode);

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
     * Test get form list with an invalid survey version id as parameter it should fail
     */
    static testMethod void testGetSurveyInvalidId() {

        // INITIALIZE TEST
        // Prepare test data
        prepareData(2);

        // Log in the Mobile User
        surveyors[0] = TestUtils.partnerLoginDetails(surveyors[0]);

        // Setup rest request
        setUpRequest(
            surveyVersions[0].Id,
            true,
            surveyors[0].loginResult.getSessionToken(),
            'Body of Document'
        );

         // Create setting to enable the deletion of published versions
        insert new Settings__c(Name = C.FLAG_SKIP_SURVEY_STATUS_VALIDATION);
        delete surveys[0];

        // START TEST
        Test.startTest();
        System.runAs(surveyors[0].partnerUser) {
            SurveyFormList.doGet();
        }
        Test.stopTest();

        // Check the results
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

    /**
     * Test method to check CRUD-FLS permission check while processing Survey Form List request 
     */
    static testMethod void testDoGet() {

        prepareData(2);
        System.assert(surveyors.size() > 0, 'surveyors size should be greater than zero');
        surveyors[0] = TestUtils.partnerLoginDetails(surveyors[0]);

        setUpRequest(
            surveyVersions[0].Id,
            true,
            surveyors[0].loginResult.getSessionToken(),
            'Body of Document'
        );
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
}