/**
 * Test class for object mapping from a survey submission
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public class MappedObjectsCreatorTest {

    // Login details for the surveyor
    static String USERNAME = 'userMOCT';
    static String PASSWORD = 'passMOCT';
    static String LASTNAME = 'lastNameMOC';
    static Survey__c gpsSurvey;

    /**
     * Prepare the request context
     *
     * @param doc - The XML document for the submission
     */
    private static TestUtils.Surveyor generateRequest(DOM.Document doc){

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor(LASTNAME, true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);

        // Prepare the headers
        Map<String, String> headersMap = new Map<String, String>{
            C.SESSION_TOKEN_HEADER  => surveyor.loginResult.getSessionToken()
        };

        // Prepare the request
        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('surveysubmission/'),
            Blob.valueOf(doc.toXmlString()),
            headersMap
        );
        return surveyor;
    }

    /**
     * Create a survey and a corresponding submission to test reference surveys
     *
     * @param - accountName      - Name for the account
     * @param - contactFirstName - First name for the contact
     * @param - contactLastName  - Last name for the contact
     *
     * @return - The xml document to be used for the submission
     */
    private static DOM.Document createReferenceSurvey(String accountName, String contactFirstName, String contactLastName) {

        // Create the survey
        Survey__c survey = TestUtils.createSurvey('survey');
        Question__c section = TestUtils.addQuestion(survey , 1, 'section' , QuestionDO.TYPE_SECTION);
        Question__c accountNameQ = TestUtils.addQuestion(section, 1, 'accountName', QuestionDO.TYPE_TEXT_SHORT);
        Question__c firstNameQ = TestUtils.addQuestion(section, 2, 'firstName', QuestionDO.TYPE_TEXT_SHORT);
        Question__c lastNameQ = TestUtils.addQuestion(section, 3, 'lastName', QuestionDO.TYPE_TEXT_SHORT);

        // Create the Survey Mapping
        SurveyMapping__c mapAccount = TestUtils.mapObject(survey, 'Account', true, 'Name');
        TestUtils.mapQuestion(mapAccount, accountNameQ, 'Name');

        // Create the survey mapping for the contact object
        SurveyMapping__c mapContact = TestUtils.mapObject(survey, 'Contact', false, 'LastName');
        TestUtils.mapQuestion(mapContact, firstNameQ, Schema.sObjectType.Contact.fields.FirstName.getName());
        TestUtils.mapQuestion(mapContact, lastNameQ, Schema.sObjectType.Contact.fields.LastName.getName());

        // Add the object relation
        insert( new ObjectRelationshipMapping__c(ChildSurveyMapping__c = mapContact.Id, FieldApiName__c = 'AccountId', ParentSurveyMapping__c = mapAccount.Id));

        // Create submission
        DOM.Document doc = TestUtils.createSubmissionDataNode(survey);
        DOM.XMLNode root = doc.getRootElement();
        DOM.XMLNode sectionNode = root.getChildElement('section',null);
        sectionNode.getChildElement('accountName',null).addTextNode(accountName);
        sectionNode.getChildElement('firstName',null).addTextNode(contactFirstName);
        sectionNode.getChildElement('lastName',null).addTextNode(contactLastName);
        return doc;
    }

    /**
     * Test that when mapping a multiselect question to a
     * simple text field, the selected values are concatenated
     * in the order of the options, separated by a semicolon,
     * and that there's no trailing semicolon.
     */
    static testMethod void testSelectMapToTextField() {

        // Create a survey
        Survey__c survey = TestUtils.createSurvey('survey');
        Question__c section = TestUtils.addQuestion(survey , 1, 'section' , QuestionDO.TYPE_SECTION);
        Question__c name    = TestUtils.addQuestion(section, 1, 'lastname', QuestionDO.TYPE_TEXT_SHORT);
        Question__c radio   = TestUtils.addQuestion(section, 2, 'radio'   , QuestionDO.TYPE_RADIO);
        Question__c check   = TestUtils.addQuestion(section, 3, 'check'   , QuestionDO.TYPE_CHECKBOX);

        Option__c[] radio_op = TestUtils.addOptions(radio, new String[]{'a','b','c','d'});
        Option__c[] check_op = TestUtils.addOptions(check, new String[]{'a','b','c','d'});

        // Create necessary mappings
        SurveyMapping__c mapcontact = TestUtils.mapObject(survey, 'Contact');
        TestUtils.mapQuestion(mapcontact, name, 'LastName');
        TestUtils.mapQuestion(mapcontact, radio, 'AssistantName');
        TestUtils.mapQuestion(mapcontact, check, 'Department');

        // Create submission
        DOM.Document doc = TestUtils.createSubmissionDataNode(survey);
        DOM.XMLNode root = doc.getRootElement();
        DOM.XMLNode sectionNode = root.getChildElement('section',null);
        sectionNode.getChildElement('lastname',null).addTextNode('testselectmap');
        sectionNode.getChildElement('radio',null).addTextNode(radio_op[0].Id);
        sectionNode.getChildElement('check',null).addTextNode(check_op[0].Id + ' ' + check_op[1].Id + ' ' + check_op[3].Id);

        TestUtils.Surveyor surveyor = generateRequest(doc);

        // Submit the completed survey
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Assert mapped values don't have a trailing semicolon
        Contact contact = [
            SELECT
                Id, LastName, AssistantName, Department
            FROM
                Contact
            WHERE
                LastName = 'testselectmap'
        ];
        System.assertEquals('a', contact.AssistantName);
        System.assertEquals('a;b;d', contact.Department);
    }

    /**
     * Test the creation of a record from a submission that is linked to a referenced record
     * The referenced records must remain unchanged
     */
    static testMethod void testReferencedSurveyMapping() {

        // Create the reference record
        String accountName = 'ACME';
        String contactLastName = 'RefMapLastName';
        String contactFirstName = 'RefMapFirstName';

        Account referenceRecord = new Account( Name = accountName );
        insert(referenceRecord);

        DOM.Document doc = createReferenceSurvey(accountName, contactFirstName, contactLastName);
        TestUtils.Surveyor surveyor = generateRequest(doc);

        // Submit the completed survey
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Get the reference object
        Account ref = [SELECT Id FROM Account WHERE Name = :accountName];
        System.assertEquals(referenceRecord.Id, ref.Id);

        // Check that the contact has been created
        Contact c = [
            SELECT
                FirstName,
                LastName,
                AccountId
            FROM
                Contact
            WHERE
                LastName = :contactLastName
        ];
        System.assertEquals(referenceRecord.Id, c.AccountId);
        System.assertEquals(contactFirstName, c.FirstName);
    }

    /**
     * Test that correct error is generated when trying to map to a reference field for a record
     * that doesn't exist
     */
    static testMethod void catchMissingReferencedRecord() {

        // Create the reference record
        String accountName = 'ACME';
        String contactLastName = 'RefMapLastName';
        String contactFirstName = 'RefMapFirstName';

        DOM.Document doc = createReferenceSurvey(accountName, contactFirstName, contactLastName);
        TestUtils.Surveyor surveyor = generateRequest(doc);

        // Submit the completed survey
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        RestResponse response = RestContext.response;

        System.assertEquals(C.HTTP_INTERNAL_SERVER_ERROR, response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_SUB_MISSING_REF_OBJECT, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.SURVEY_SUB_MISSING_REF_OBJECT, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test a Mapping with Id field set in the survey Data
     */
    static testMethod void testIdFieldMapInSurveyData() {

        // Create a survey
        Survey__c survey = TestUtils.createSurvey('survey');
        Question__c section = TestUtils.addQuestion(survey , 1, 'section' , QuestionDO.TYPE_SECTION);
        Question__c assistant = TestUtils.addQuestion(section, 1, 'assistant', QuestionDO.TYPE_TEXT_SHORT);

        // Create a Contact to update in submission,( use the full name of the surveyor )
        // Create necessary mappings
        SurveyMapping__c mapcontact = new SurveyMapping__c(
            Survey__c = survey.Id,
            ObjectApiName__c = 'Contact',
            SurveyorApiField__c = 'LastName',
            MatchingField__c = 'LastName'
        );
        insert mapcontact;
        TestUtils.mapQuestion(mapcontact, assistant, 'AssistantName');

        // Create submission
        DOM.Document doc = TestUtils.createSubmissionDataNode(survey);
        DOM.XMLNode root = doc.getRootElement();
        DOM.XMLNode sectionNode = root.getChildElement('section',null);
        sectionNode.getChildElement('assistant',null).addTextNode('assistantName');

        // Submit the completed survey
        TestUtils.Surveyor surveyor = generateRequest(doc);
        Test.startTest();
        System.runAs(surveyor.partnerUser) {
            SurveySubmissions.processSubmission();
        }
        Test.stopTest();

        // Assert mapped values in the contact
        Contact contact = [SELECT Id, LastName, AssistantName FROM Contact WHERE LastName = :LASTNAME];
        System.assertEquals(LASTNAME, contact.LastName);
        System.assertEquals('assistantName', contact.AssistantName);
    }
}