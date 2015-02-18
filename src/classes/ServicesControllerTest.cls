/**
 * This class test the services controller class
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public class ServicesControllerTest {

    /**
     * Helper method to generate a long string
     *
     * @param length the length to be overcome
     * @return a string with more than the specified length
     */
    private static String getLongString(Integer length) {
        String longStr = '1234567890';
        while(longStr.length() < length){
            longStr += longStr;
        }
        return longStr;
    }

    /**
     * Create and login a MobileUser
     */
    public static TestUtils.Surveyor initMobileUser() {

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('lastNameSCT', true);
        return TestUtils.partnerLoginDetails(surveyor);
    }

    /**
     * Test for the ParseSubmissionHeader method without group assignments to contact
     */
    static testMethod void parseSubmissionWithoutGroupAssignments() {
        parseSubmission(false);
    }

    /**
     * Auxiliary test to verify the ParseSubmissionHeader method
     * @param assignGroups WHERE or not to create groups and assignments for the surveyor contact
     */
    static void parseSubmission(boolean assignGroups) {

        //PREPARING THE TEST
        //For PPI surveys
        Contact interviewee = new Contact(LastName ='TestintervieweeMAP');
        insert interviewee;
        interviewee = [SELECT Name FROM Contact WHERE Id=:interviewee.Id limit 1];
        Survey__c survey = new Survey__c(
            Name='Survey',
            Status__c = SurveyDO.STATUS_PUBLISHED,
            Gps_Location_Enabled__c = true
        );
        insert survey;

        Question__c qSection = new Question__c(Survey__c = survey.Id, Name = 'section',Caption__c= 'section',Type__c = QuestionDO.TYPE_SECTION, Position__c = 1);
        insert new Question__c[]{qSection};

        Integer pos = 1;
        Question__c q1 = new Question__c(Position__c = pos++, Parent__c= qSection.Id,survey__c=survey.Id, Caption__c= 'Username', Name = 'Username', Type__c = QuestionDO.TYPE_TEXT_SHORT);
        Question__c q2 = new Question__c(Position__c = pos++, Parent__c= qSection.Id,survey__c=survey.Id, Caption__c= 'Last Name', Name = 'LastName', Type__c = QuestionDO.TYPE_TEXT_SHORT);
        Question__c qContactDateTime = new Question__c(Position__c = pos++, Name = 'dateTimeQuestion',Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Datetime',Type__c = QuestionDO.TYPE_DATETIME);
        Question__c q3 = new Question__c(Position__c = pos++, Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'SELECT some',Type__c = QuestionDO.TYPE_CHECKBOX);
        Question__c qCurrency = new Question__c(Position__c = pos++, Name = 'Currency', Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Currency',Type__c = QuestionDO.TYPE_NUMBER);
        Question__c qOpName = new Question__c(Position__c = pos++, Name = 'OppName',Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Opportunity Name',Type__c = QuestionDO.TYPE_TEXT_SHORT);
        Question__c qOpCloseDate = new Question__c(Position__c = pos++, Name = 'OppCloseDate',Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Opportunity Date',Type__c = QuestionDO.TYPE_DATE);
        Question__c qTotalOpportunityQuantity = new Question__c(Position__c = pos++, Name = 'OppQuantity',Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Opportunity Number',Type__c = QuestionDO.TYPE_NUMBER);
        Question__c qOpStageName = new Question__c(Position__c = pos++, Name = 'OppStageName',Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Opportunity Picklist',Type__c = QuestionDO.TYPE_RADIO);
        Question__c qOpProbability = new Question__c(Position__c = pos++, Name = 'OppProbability',Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Opportunity Percent',Type__c = QuestionDO.TYPE_NUMBER);
        List<Question__c> questions = new List<Question__c>{q1,q2,q3,qTotalOpportunityQuantity,qCurrency,qOpStageName,qOpCloseDate,qOpName,qOpProbability,qContactDateTime};
        insert questions;

        Option__c opStageName = new Option__c(Name= 'Picklist',Caption__c = 'Picklist',Question__c = qOpStageName.Id,Position__c=1);
        Option__c opA = new Option__c(Name= 'opcion A', Caption__c = 'option A', Question__c = q3.Id,Position__c=4);
        Option__c opB = new Option__c(Name= 'opcion B', Caption__c = 'option A', Question__c = q3.Id,Position__c=5);
        List<Option__c> options= new List<Option__c>{opA,opB,opStageName};
        insert options;

        Contact ctc = new Contact(LastName = 'Robert',mobilesurveys_Id__c='4321');
        insert ctc;

        ScoringGroup__c sGroup1 = new ScoringGroup__c(Caption__c = 'Test#Scoring#Group',Survey__c=survey.id);
        ScoringGroup__c sGroup2 = new ScoringGroup__c(Caption__c = 'Test#Scoring#Group#2',Survey__c=survey.id);
        insert sGroup1;
        insert sGroup2;

        ScoreValue__c sValue1 = new ScoreValue__c(Option__c = opA.Id,ScoringGroup__c = sGroup1.Id, Value__c = 20);
        ScoreValue__c sValue2 = new ScoreValue__c(Option__c = opB.Id,ScoringGroup__c = sGroup1.Id, Value__c = 200);

        ScoreValue__c sValue3 = new ScoreValue__c(Option__c = opA.Id,ScoringGroup__c = sGroup2.Id, Value__c = 200);
        ScoreValue__c sValue4 = new ScoreValue__c(Option__c = opB.Id,ScoringGroup__c = sGroup2.Id, Value__c = 2000);

        insert new ScoreValue__c[]{sValue1,sValue2,sValue3,sValue4};

        // Mapped object fields
        Account ac = new Account(Name = 'TheAccount',AccountNumber ='User');
        insert ac;
        Opportunity op = new Opportunity(Name='TheOp',StageName='Prospecting',TotalOpportunityQuantity=12.82,   CloseDate=date.today());
        insert op;

        // Survey Mapping,new Contact
        SurveyMapping__c sm1 = new SurveyMapping__c(Survey__c=survey.Id,ObjectApiName__c='Contact');

        // Survey Mapping with Matching field(Account already in DB)
        SurveyMapping__c sm2 = new SurveyMapping__c(Survey__c=survey.Id,ObjectApiName__c='Account',MatchingField__c='AccountNumber');

        // Survey Mapping opportunities
        SurveyMapping__c smOpportunity = new SurveyMapping__c(Survey__c=survey.Id,ObjectApiName__c='Opportunity',MatchingField__c='Name');
        insert new SurveyMapping__c[]{sm1,sm2,smOpportunity};

        // Question mapping for the contact
        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c='LastName',Question__c=q2.Id,SurveyMapping__c=sm1.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c='mobilesurveys_Username__c',Question__c=q1.Id,SurveyMapping__c=sm1.Id);
        QuestionMapping__c qmDateTime = new QuestionMapping__c(FieldApiName__c='mobilesurveys_LastCheckInDate__c',Question__c=qContactDateTime.Id,SurveyMapping__c=sm1.Id);

        // Question mapping for the Account
        QuestionMapping__c qm3 = new QuestionMapping__c(FieldApiName__c='AccountNumber',Question__c=q1.Id,SurveyMapping__c=sm2.Id);
        QuestionMapping__c qm4 = new QuestionMapping__c(FieldApiName__c='Description',Question__c=q2.Id,SurveyMapping__c=sm2.Id);
        QuestionMapping__c qm5 = new QuestionMapping__c(FieldApiName__c='AnnualRevenue',Question__c=qCurrency.Id,SurveyMapping__c=sm2.Id);

        // Question mappings for opportunity
        QuestionMapping__c qmOpName = new QuestionMapping__c(FieldApiName__c='Name',Question__c=qOpName.Id,SurveyMapping__c=smOpportunity.Id);
        QuestionMapping__c qmOpTotalOpportunityQuantity = new QuestionMapping__c(FieldApiName__c='TotalOpportunityQuantity',Question__c=qTotalOpportunityQuantity.Id,SurveyMapping__c=smOpportunity.Id);
        QuestionMapping__c qmOpStageName = new QuestionMapping__c(FieldApiName__c='StageName',Question__c=qOpStageName.Id,SurveyMapping__c=smOpportunity.Id);
        QuestionMapping__c qmOpCloseDate = new QuestionMapping__c(FieldApiName__c='CloseDate',Question__c=qOpCloseDate.Id,SurveyMapping__c=smOpportunity.Id);
        QuestionMapping__c qmOpProbability = new QuestionMapping__c(FieldApiName__c='Probability',Question__c=qOpProbability.Id,SurveyMapping__c=smOpportunity.Id);
        insert new QuestionMapping__c[]{qm1,qm2,qm3,qm4,qm5,qmDateTime,qmOpName,qmOpTotalOpportunityQuantity,qmOpStageName,qmOpCloseDate,qmOpProbability};

        q1 = [SELECT name FROM Question__c WHERE id=:q1.Id][0];
        q2 = [SELECT name FROM Question__c WHERE id=:q2.Id][0];
        q3 = [SELECT name FROM Question__c WHERE id=:q3.Id][0];

        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c desc];
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
                '<'+ q3.Name +'>' + opA.Id + ' ' + OpB.Id + ' </'+ q3.Name +'>'+
                '<'+ qContactDateTime.Name +'>2012-02-14T19:23:53.463</'+ qContactDateTime.Name +'>'+
                '<'+ qOpName.Name +'>TheOp</'+ qOpName.Name +'>'+
                '<'+ qOpCloseDate.Name +'>2012-02-14</'+ qOpCloseDate.Name +'>'+
                '<'+ qTotalOpportunityQuantity.Name +'>9</'+ qTotalOpportunityQuantity.Name +'>'+
                '<'+ qOpStageName.Name +'>'+ opStageName.Id+ ' </'+ qOpStageName.Name +'>'+
                '<'+ qOpProbability.Name +'>30</'+ qOpProbability.Name +'>'+
            '</' + qSection.Name + '>' +
        '</'+ survey.Name + '>';

        // PERFORMING THE TEST
        // Published Survey case
        TestUtils.Surveyor surveyor = initMobileUser();
        Test.startTest();
        if (assignGroups) {

            // Create groups and assignments
            assignContactToSurvey(surveyor.theContact, survey.Id, C.GROUP_STATUS_ACTIVE);
        }

        Submission sub =
            TestUtils.submitNewSubmission(xml, surveyor.loginResult);

        Test.stopTest();
        List<Submission__c> resultSA = [
            SELECT
                Id,
                Name,
                Survey__c,
                Date__c,
                Status__c,
                Gps_x__c,
                Gps_y__c
            FROM
                Submission__c
            WHERE
                Survey__c = :survey.Id
        ];
        List<SubmissionScore__c> surveyTotalsScores = [SELECT Id,TotalScore__c FROM SubmissionScore__c WHERE  Submission__c =:resultSA[0].id ORDER BY TotalScore__c asc];

        // ASSERTIONS
        // Correct insert of the Submission
        system.assertNotEquals(0, resultSA.size());
        system.assertEquals(resultSA[0].survey__c,survey.Id);
        system.assertEquals(resultSA[0].gps_x__c ,80.0 );
        system.assertEquals(resultSA[0].gps_y__c ,70.0);
        system.assertEquals(resultSA[0].Date__c,Date.valueOf('2012-02-14'));
        system.assertEquals(resultSA[0].Id, sub.getExistingSubmissionId());
        system.assertEquals(resultSA[0].Status__c,'Uploaded');

        // Correct insertion of the Answer and validations of the data
        List<Answer__c> resultQA = [SELECT id,Question__c,Submission__c,Value__c, TextAreaValue__c FROM Answer__c WHERE Question__c = :q1.Id];
        system.assertNotEquals(0,resultQA.size());
        system.assertEquals(resultQA[0].Question__c,q1.Id);
        system.assertEquals(resultQA[0].Value__c,'User');
        system.assertEquals(resultQA[0].TextAreaValue__c,'User');
        system.assertEquals(resultQA[0].Submission__c,resultSA[0].Id);
        List<Answer__c> resultQA1 = [SELECT id,Question__c,Submission__c,Value__c, TextAreaValue__c FROM Answer__c WHERE Question__c = :q2.Id];
        system.assertEquals(resultQA1[0].Value__c,'Martin');
        system.assertEquals(resultQA1[0].TextAreaValue__c,'Martin');
        system.assertNotEquals(0,resultQA1.size());
        system.assertEquals(resultQA1[0].Question__c,q2.Id);
        system.assertEquals(resultQA1[0].Submission__c,resultSA[0].Id);
        List<Answer__c> resultQA2 = [SELECT id,Question__c,Submission__c,Value__c FROM Answer__c WHERE Question__c = :q3.Id];

        // Correct insert of SubmissionScore
        system.assertEquals(surveyTotalsScores.size(),2);
        system.assertEquals(surveyTotalsScores[0].TotalScore__c, 220);
        system.assertEquals(surveyTotalsScores[1].TotalScore__c, 2200);
        system.assertEquals(2,resultQA2.size());

        //---------Validate Answers fields depending Question Types
        List<Answer__c> resultQA3 = [SELECT id,Question__c,Submission__c,Value__c, DateValue__c, DateTimeValue__c FROM Answer__c WHERE Question__c = :qContactDateTime.Id];//Date Time
        List<Answer__c> resultQA5 = [SELECT id,Question__c,Submission__c,Value__c, DateValue__c FROM Answer__c WHERE Question__c = :qOpCloseDate.Id];//Date
        List<Answer__c> resultQA6 = [SELECT id,Question__c,Submission__c,Value__c, NumericValue__c FROM Answer__c WHERE Question__c = :qTotalOpportunityQuantity.Id];//Number
        List<Answer__c> resultQA7 = [SELECT id,Question__c,Submission__c,Value__c, TextAreaValue__c FROM Answer__c WHERE Question__c = :qOpStageName.Id];//Radio

        // Date Time
        system.assertEquals(dateTime.valueOfGmt('2012-02-14 19:23:53.463'),resultQA3[0].DateTimeValue__c);
        system.assertEquals(resultQA3[0].DateValue__c, date.valueOf('2012-02-14 19:23:53.463'));
        system.assertEquals(resultQA3[0].value__c, '2012-02-14 19:23:53.463');

        // Date
        system.assertEquals(resultQA5[0].DateValue__c, date.valueOf('2012-02-14'));
        system.assertEquals(resultQA5[0].Value__c, '2012-02-14');

        // Number
        system.assertEquals(resultQA6[0].NumericValue__c, 9.000000);
        system.assertEquals(resultQA6[0].Value__c,'9');

        // Radio
        system.assertEquals(resultQA7[0].TextAreaValue__c,  opStageName.Name);

        //----------------
        List<Contact> mappedContacts = [SELECT LastName,mobilesurveys_Username__c,Contact.mobilesurveys_LastCheckInDate__c FROM Contact WHERE LastName = 'Martin'];

        // Correct insertion of mapped fields
        system.assertEquals(1,mappedContacts.size());
        system.assertEquals('User',mappedContacts[0].mobilesurveys_Username__c);
        system.assertEquals(Datetime.valueofGmt('2012-02-14 19:23:53.463'),mappedContacts[0].mobilesurveys_LastCheckInDate__c);
        List<Account> mappedAccount = [SELECT Name,AccountNumber,Description FROM Account WHERE AccountNumber = 'User'];
        List<Opportunity> mappedOpportunity = [SELECT Name,IsPrivate,StageName,CloseDate,Probability,TotalOpportunityQuantity FROM Opportunity WHERE Name='TheOp'];

        // Correct insertion of mapped fields(with matching field)
        system.assertEquals(1,mappedOpportunity.size());
        system.assertEquals(mappedOpportunity[0].Id, Op.Id);
        system.assertEquals(date.valueof('2012-02-14'),mappedOpportunity[0].CloseDate);
        system.assertEquals(9,mappedOpportunity[0].TotalOpportunityQuantity);
        system.assertEquals(30,mappedOpportunity[0].Probability);
    }

    /** Test for the ParseSubmission method, to verify when updating mapped objects ownership must not be changed
     *  IDALMSA-2702
     */
    static testMethod void ParseSubmissionOwnershipUpdateTest() {

        // PREPARING THE TEST
        Survey__c survey = new Survey__c(Name='Survey',
            Status__c = SurveyDO.STATUS_PUBLISHED, Gps_Location_Enabled__c = false
        );

        User standardUser = TestUtils.getStandardUser();
        insert standardUser;

        survey.OwnerId =standardUser.Id;
        insert survey;

        Question__c qSection = new Question__c(Survey__c=survey.Id, Name = 'section',Caption__c= 'section',Type__c = QuestionDO.TYPE_SECTION, Position__c = 1);
        insert new Question__c[]{qSection};

        Integer pos = 1;
        Question__c q1 = new Question__c(Position__c = pos++, Parent__c= qSection.Id,survey__c=survey.Id, Caption__c= 'FirstName', Name = 'FirstName', Type__c = QuestionDO.TYPE_TEXT_SHORT);
        Question__c q2 = new Question__c(Position__c = pos++, Parent__c= qSection.Id,survey__c=survey.Id, Caption__c= 'Last Name', Name = 'LastName', Type__c = QuestionDO.TYPE_TEXT_SHORT);
        List<Question__c> questions= new List<Question__c>{q1,q2};
        insert questions;

        User anotherStandardUser = TestUtils.getStandardUser();
        insert anotherStandardUser;
        Contact contact = new Contact(LastName = 'Heisenberg',FirstName='Julio',OwnerId=anotherStandardUser.Id);
        insert contact;

        // Survey Mapping, new Contact
        SurveyMapping__c sm1 = new SurveyMapping__c(Survey__c=survey.Id,ObjectApiName__c='Contact');
        sm1.MatchingField__c = 'LastName';
        insert sm1;

        // Question mapping for the contact
        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c='LastName',Question__c=q2.Id,SurveyMapping__c=sm1.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c='FirstName',Question__c=q1.Id,SurveyMapping__c=sm1.Id);
        insert new QuestionMapping__c[]{qm1,qm2};

        q1 = [SELECT name FROM Question__c WHERE id=:q1.Id][0];
        q2 = [SELECT name FROM Question__c WHERE id=:q2.Id][0];
        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c desc];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id,new String[]{'Pepe','Heisenberg'});

        TestUtils.Surveyor surveyor = initMobileUser();

        Test.startTest();

        // Create groups and assignments
        assignContactToSurvey(surveyor.theContact, survey.Id, C.GROUP_STATUS_ACTIVE);

        // Send submission
        Submission sub =
            TestUtils.submitNewSubmission(xmlToSend, surveyor.loginResult);
        Test.stopTest();

        //----------------
        List<Contact> mappedContacts = [SELECT LastName,FirstName,OwnerId,Contact.mobilesurveys_LastCheckInDate__c FROM Contact WHERE LastName = 'Heisenberg'];

        // Correct insertion of mapped fields
        system.assertEquals(1, mappedContacts.size());

        // The survey owner must not be changed since the contact already existed on the database
        system.assertNotEquals(survey.OwnerId, mappedContacts[0].OwnerId);

        // However the first name must change
        system.assertEquals('Pepe', mappedContacts[0].FirstName);
    }

    /**
     * Test for the ParseSubmission method, to verify mapped objects ownership is assigned as current survey creator
     *  IDALMSA-2702
     */
    static testMethod void ParseSubmissionOwnershipTest() {

        // PREPARING THE TEST
        Survey__c survey = new Survey__c(
            Name='Survey',
            Status__c = SurveyDO.STATUS_PUBLISHED, Gps_Location_Enabled__c = false
        );

        User standardUser = TestUtils.getStandardUser();
        insert standardUser;

        survey.OwnerId =standardUser.Id;
        insert survey;

        Question__c qSection = new Question__c(Survey__c=survey.Id, Name = 'section',Caption__c= 'section',Type__c = QuestionDO.TYPE_SECTION, Position__c = 1);
        insert new Question__c[]{qSection};

        Integer pos = 1;
        Question__c q1 = new Question__c(Position__c = pos++, Parent__c= qSection.Id,survey__c=survey.Id, Caption__c= 'FirstName', Name = 'FirstName', Type__c = QuestionDO.TYPE_TEXT_SHORT);
        Question__c q2 = new Question__c(Position__c = pos++, Parent__c= qSection.Id,survey__c=survey.Id, Caption__c= 'Last Name', Name = 'LastName', Type__c = QuestionDO.TYPE_TEXT_SHORT);
        List<Question__c> questions= new List<Question__c>{q1,q2};
        insert questions;

        Contact ctc = new Contact(LastName = 'Robert',mobilesurveys_Id__c='4321');
        insert ctc;

        // Mapped object fields
        // Survey Mapping, new Contact
        SurveyMapping__c sm1 = new SurveyMapping__c(Survey__c=survey.Id,ObjectApiName__c='Contact');
        sm1.OwnerId = survey.OwnerId;
        insert sm1;

        // Question mapping for the contact
        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c='LastName',Question__c=q2.Id,SurveyMapping__c=sm1.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c='FirstName',Question__c=q1.Id,SurveyMapping__c=sm1.Id);
        insert new QuestionMapping__c[]{qm1,qm2};

        q1 = [SELECT name FROM Question__c WHERE id=:q1.Id][0];
        q2 = [SELECT name FROM Question__c WHERE id=:q2.Id][0];
        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c desc];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        String xmlToSend =
            TestUtils.getTestSubmissionXML(survey.Id,new String[]{'Pepe','Heisenberg'});

        TestUtils.Surveyor surveyor = initMobileUser();

        // Send submission
        Test.startTest();
        Submission sub =
            TestUtils.submitNewSubmission(xmlToSend, surveyor.loginResult);
        Test.stopTest();

        List<Contact> mappedContacts = [SELECT LastName,mobilesurveys_Username__c,OwnerId,Contact.mobilesurveys_LastCheckInDate__c FROM Contact WHERE LastName = 'Heisenberg'];

        // Correct insertion of mapped fields
        system.assertEquals(1, mappedContacts.size());

        // The survey owner must be the same as the created contact owner
        system.assertEquals(survey.OwnerId, mappedContacts[0].OwnerId);
    }

    /**
     * Test a submission with an answer with more than 255 chars
     */
    static testMethod void testLongTextAnswer(){

        Survey__c survey = new Survey__c(Name = 'Survey', Status__c = SurveyDO.STATUS_PUBLISHED);
        insert survey;
        Question__c qSection = new Question__c(Name = 's1', Survey__c = survey.Id, Caption__c = 'section', Type__c = QuestionDO.TYPE_SECTION, Position__c = 1);
        insert qSection;

        Question__c q1 = new Question__c(Name = 'q1', Position__c = 1, Parent__c = qSection.Id, survey__c = survey.Id, Caption__c = 'Long Text', Type__c = QuestionDO.TYPE_TEXT_LONG);
        insert q1;

        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c DESC];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        String longString = getLongString(300);

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
            '<'+ q1.Name +'>' + longString + '</'+ q1.Name +'>'+
            '</' + qSection.Name + '>' +
            '</'+ survey.Name + '>';

        // PREPARE THE CONTEXT TO SUBMIT THE XML
        TestUtils.Surveyor surveyor = initMobileUser();
        Test.startTest();

        // Create groups and assignments
        assignContactToSurvey(surveyor.theContact, survey.Id, C.GROUP_STATUS_ACTIVE);

        // PERFORMING THE TEST
        Submission sub =
            TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        Test.stopTest();

        // Check that the submission was successful
        List<Submission__c> submissions = [SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id];
        System.assertEquals(1, submissions.size());

        // Check the answer was saved with the right values
        List<Answer__c> answers = [SELECT Id, Question__c, Value__c, TextAreaValue__c FROM Answer__c WHERE Submission__c = :submissions[0].Id];
        System.assertEquals(1, answers.size());
        System.assertEquals(longString, answers[0].TextAreaValue__c);
        System.assertEquals(longString.substring(0,254), answers[0].Value__c);
    }

    /**
     * Test submissions with questions that have skip logic and are mapped to required fields
     *
     * @param showQuestion       - Flag that determines if is showing the question or not in the xml
     * @param mappedObjectExists - flag that indicates if the mappedObject should exist
     */
    private static void executeTestSubmitWithSkipLogic(Boolean showQuestion, Boolean mappedObjectExists){
        Survey__c survey = new Survey__c(Name='Survey', Status__c = SurveyDO.STATUS_PUBLISHED);
        insert survey;

        Question__c qSection = new Question__c(Survey__c = survey.Id, Caption__c = 'section',  Name = 'new_section', Type__c = QuestionDO.TYPE_SECTION, Position__c = 1);
        insert qSection;

        Question__c q1 = new Question__c(Position__c = 1, Parent__c = qSection.Id, survey__c = survey.Id, Caption__c = 'New contact?', Name = 'new_contact', Type__c = QuestionDO.TYPE_RADIO);
        Question__c q2 = new Question__c(Position__c = 2, Parent__c = qSection.Id, survey__c = survey.Id, Caption__c = 'Last Name',  Name = 'last_name', Type__c = QuestionDO.TYPE_TEXT_SHORT);
        Question__c q3 = new Question__c(Position__c = 3, Parent__c = qSection.Id, survey__c = survey.Id, Caption__c = 'Username',  Name = 'user_name', Type__c = QuestionDO.TYPE_TEXT_SHORT);
        insert new List<Question__c>{q1, q2, q3};

        Option__c op1Q1 = new Option__c(Name = 'Yes', Caption__c = 'yes', Question__c = q1.Id, Position__c = 1);
        Option__c op2Q1 = new Option__c(Name = 'No', Caption__c = 'no', Question__c = q1.Id, Position__c = 2);
        insert new List<Option__c>{op1Q1, op2Q1};

        insert new SkipCondition__c (
            Parent__c = q2.Id,
            SourceQuestion__c = q1.Id,
            Condition__c = 'Is',
            Negate__c = false,
            SkipValue__c = op1Q1.Id
        );

        SurveyMapping__c sm1 = new SurveyMapping__c(Survey__c = survey.Id, ObjectApiName__c='Contact', MatchingField__c = 'AssistantName');
        insert sm1;

        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c = 'LastName', Question__c = q2.Id, SurveyMapping__c = sm1.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c = 'AssistantName', Question__c = q3.Id, SurveyMapping__c = sm1.Id);
        insert new List<QuestionMapping__c> {qm1, qm2};

        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c desc];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        // Add the objects to be mapped if should exist fot the test
        if (mappedObjectExists) {
            Contact con = TestUtils.createContact();
            con.AssistantName = 'Assistant Name';
            update con;
        }

        TestUtils.Surveyor surveyor = initMobileUser();

        String xml =
            '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + survey.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid/>'+
            '<simid>8959801011430427812</simid>'+
            '<location/>'+
            '<phonenumber />'+
            '<' + qSection.Name + '>' +
                '<'+ q1.Name +'>'+ (showQuestion ? op1Q1.Id : op2Q1.Id) +'</'+ q1.Name +'>' +
                (showQuestion ? '<'+ q2.Name +'> </'+ q2.Name +'>' : '') +
                '<'+ q3.Name +'>Assistant Name</'+ q3.Name +'>' +
            '</' + qSection.Name + '>' +
        '</'+ survey.Name + '>';

        Test.startTest();
        SavePoint sp = Database.setSavePoint();
        try {
            Submission sub =
                TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        }
        catch (SurveyException e) {
            Database.rollBack(sp);
            e.convertToErrorMessage();
        }
        Test.stopTest();
        List<Submission__c> resultSA = [SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id];

        // Assert when submission fails due to missing required field. The exception would have
        // been caught above
        if (!mappedObjectExists) {
            System.assertEquals(0, resultSA.size());

            // Check success of the submission and the error code generated
            System.assertEquals(C.HTTP_INTERNAL_SERVER_ERROR, ErrorHandlingRest.getStatusCode());

            List<ErrorHandlingRest.ErrorMessage> errorMessages = ErrorHandlingRest.getAllErrors();
            System.assertEquals(1, errorMessages.size());
            System.assertEquals(ErrorHandlingRest.ERR_CODE_SUB_BAD_FIELD_MAP, errorMessages[0].getErrorCode());
            System.assertEquals(ErrorHandlingRest.SURVEY_SUB_FIELD_MAPPING_ERROR, errorMessages[0].getErrorTranslationCode());
        }
        else {
            System.assertEquals(1, resultSA.size());
        }
    }

    /**
     * Test The submission with skip logic in a mapped required field and with an space like answer
     */
    static testMethod void testSkipRequiredMappedField() {
        executeTestSubmitWithSkipLogic(false, true);
    }
    static testMethod void newObjectSpaceAsRequiredFieldValue() {
        executeTestSubmitWithSkipLogic(true, false);
    }
    static testMethod void existingObjectSpaceAsRequiredFieldValue() {
        executeTestSubmitWithSkipLogic(true, true);
    }

    /**
     * Test that score calculation is working properly in repeated questions
     */
    static testMethod void testGenerateScoreRepeatedQuestions(){
        // Create license to insert new survey
        LicenseSettings__c license = C.getLicense();
        license.UsePPI__c = true;
        update license;

        // Create a survey
        Survey__c survey = new Survey__c(
            Name         = 'SurveyScoreRepeatTest');
        insert survey;

        // Insert repeat section
        Question__c repeat = new Question__c(
            Survey__c      = survey.Id,
            Name           = 'repeated',
            Caption__c     = 'repeated',
            Type__c        = QuestionDO.TYPE_REPEAT,
            Position__c    = 1);

        // Insert regular section
        Question__c regular = new Question__c(
            Survey__c      = survey.Id,
            Name           = 'regular',
            Caption__c     = 'regular',
            Type__c        = QuestionDO.TYPE_SECTION,
            Position__c    = 2);

        insert new Question__c[]{regular,repeat};

        // Insert repeat question
        Question__c questionRepeat = new Question__c(
            Position__c = 1,
            Name        = 'questionRepeat',
            Caption__c  = 'questionRepeat',
            Parent__c   = repeat.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_CHECKBOX);

        // Insert regular question
        Question__c questionRegular = new Question__c(
            Position__c = 1,
            Name        = 'questionRegular',
            Caption__c  = 'questionRegular',
            Parent__c   = regular.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_CHECKBOX);

        insert new Question__c[]{questionRepeat,questionRegular};

        // Insert options for repeated question
        Option__c option1 = new Option__c(
            Name          = 'a',
            Question__c   = questionRepeat.Id,
            Position__c   = 1);

        Option__c option2 = new Option__c(
            Name          = 'b',
            Question__c   = questionRepeat.Id,
            Position__c   = 2);

        // Insert options for repeated question
        Option__c option3 = new Option__c(
            Name          = 'c',
            Question__c   = questionRegular.Id,
            Position__c   = 1);

        Option__c option4 = new Option__c(
            Name          = 'd',
            Question__c   = questionRegular.Id,
            Position__c   = 2);
        insert new Option__c[]{option1, option2, option3, option4};

        // Insert scoring groups
        ScoringGroup__c sGroup1 = new ScoringGroup__c(
            Caption__c          = 'ScoreTestRepeat1',
            Survey__c           = survey.id);

        ScoringGroup__c sGroup2 = new ScoringGroup__c(
            Caption__c          = 'ScoreTestRepeat2',
            Survey__c           = survey.id);
        insert new ScoringGroup__c[]{sGroup1, sGroup2};

        // Insert score values
        ScoreValue__c sValue1 = new ScoreValue__c(
            Option__c         = option1.Id,
            ScoringGroup__c   = sGroup1.Id,
            Value__c          = 10);

        ScoreValue__c sValue2 = new ScoreValue__c(
            Option__c         = option2.Id,
            ScoringGroup__c   = sGroup1.Id,
            Value__c          = 20);

        ScoreValue__c sValue3 = new ScoreValue__c(
            Option__c         = option3.Id,
            ScoringGroup__c   = sGroup1.Id,
            Value__c          = 30);

        ScoreValue__c sValue4 = new ScoreValue__c(
            Option__c         = option1.Id,
            ScoringGroup__c   = sGroup2.Id,
            Value__c          = 40);

        ScoreValue__c sValue5 = new ScoreValue__c(
            Option__c         = option2.Id,
            ScoringGroup__c   = sGroup2.Id,
            Value__c          = 50);

        ScoreValue__c sValue6 = new ScoreValue__c(
            Option__c         = option4.Id,
            ScoringGroup__c   = sGroup2.Id,
            Value__c          = 60);

        insert new ScoreValue__c[]{sValue1, sValue2, sValue3, sValue4, sValue5, sValue6};

        // Create contact
        Contact ctc = new Contact(LastName = 'Robert', mobileSurveys_Id__c = 'ab12');
        insert ctc;

        ctc = [SELECT Id, Name, mobileSurveys_Id__c FROM Contact WHERE Id = :ctc.Id];

        // Insert survey version and publish
        SurveyVersion__c surveyVersion = [SELECT Status__c
                                          FROM SurveyVersion__c WHERE Survey__c = :survey.Id
                                          ORDER BY Version__c DESC];

        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        // Make a submission for the tested survey
        String xml =
        '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + survey.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid/>'+
            '<simid />'+
            '<phonenumber />'+
            '<' + repeat.Name + '>' +
                '<'+ questionRepeat.Name +'>' + option1.Id + '</'+ questionRepeat.Name +'>'+
            '</' + repeat.Name + '>' +
            '<' + repeat.Name + '>' +
                '<'+ questionRepeat.Name +'>' + option2.Id + '</'+ questionRepeat.Name +'>'+
            '</' + repeat.Name + '>' +
            '<' + regular.Name + '>' +
                '<'+ questionRegular.Name +'>' + option3.Id + '</'+ questionRegular.Name +'>'+
            '</' + regular.Name + '>' +
        '</'+ survey.Name + '>';

        TestUtils.Surveyor surveyor = initMobileUser();
        Test.startTest();
        Submission sub =
            TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        Test.stopTest();

        Submission__c submission = [SELECT Id FROM Submission__c WHERE Survey__c = :survey.Id];
        List<SubmissionScore__c> surveyTotalScores = [SELECT Id,
                                                             TotalScore__c
                                                       FROM SubmissionScore__c
                                                       WHERE  Submission__c = :submission.id
                                                           ORDER BY TotalScore__c ASC];

        // Check scoring for repeated questions
        system.assertEquals(surveyTotalScores[0].TotalScore__c, 60);
        system.assertEquals(surveyTotalScores[1].TotalScore__c, 90);
    }

    private static Survey__c prepareRetrievalTest() {

        Survey__c survey = new Survey__c(
            Name = 'Survey');
        insert survey;

        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c =:survey.Id];

        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        Attachment att = new Attachment(
            Name = XformCreator.XFORM_ATTACHMENT,
            ParentId = surveyVersion.Id,
            Body = blob.valueOf('Body of Document'));
        insert att;

        return survey;
    }

    static testMethod void correctRetrieval() {

        // Param provided and document exists
        Survey__c survey = prepareRetrievalTest();
        SurveyVersion__c version = [SELECT Id FROM SurveyVersion__c WHERE Survey__c = :survey.Id];
        PageReference pageRef = Page.formList;
        Test.setCurrentPageReference(pageRef);

        Test.startTest();
        ServicesController sc = new ServicesController();
        Apexpages.currentPage().getParameters().put('id',version.Id);

        // Test of a correct Id with a correct document
        String form = sc.getSurvey(version.Id);
        Test.stopTest();
        system.assertEquals(form, 'Body of Document' );
    }

    static testMethod void missingParam(){

        // No id provided to retrieve
        prepareRetrievalTest();

        PageReference pageRef = Page.formList;
        ServicesController sc = new ServicesController();

        Test.startTest();

        // Run the process without id param
        sc.process();
        Test.stopTest();
        system.assertNotEquals('Body of Document',sc.Form);
    }

    static testMethod void tooManyDocuments(){

        // There are more than one document for this id
        Survey__c survey = prepareRetrievalTest();

        Attachment att2 = new Attachment(
            Name = XformCreator.XFORM_ATTACHMENT,
            ParentId = survey.Id,
            Body = blob.valueOf('Body of Second Document'));
        insert att2;
        SurveyVersion__c version = [SELECT Id FROM SurveyVersion__c WHERE Survey__c = :survey.Id];
        Test.startTest();
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor('LastName', 'user1','thePass', MobileUserDO.STATUS_ACTIVE);
        TestUtils.preparePageHeaders(surveyor.user.Username__c, surveyor.user.Password__c, null, null, true);

        Apexpages.currentPage().getParameters().put('id', version.Id);
        PageReference pageRef = Page.formList;
        ServicesController sc = new ServicesController();
        sc.process();
        Test.stopTest();
        String docName = survey.Id + '.xml';
        Attachment[] atts = [SELECT Id FROM Attachment WHERE ParentId = :survey.Id and Name = :XformCreator.XFORM_ATTACHMENT];
        system.assertEquals(1,atts.size());
    }

    //test submit a survey with differents surveyor-interviewee, private contact
    static testMethod void testPrivateSurveyor() {

        PermissionData prepareData = preparePermission();
        permissionTest(
            prepareData.xml,
            prepareData.privateSurveyor,
            prepareData.taroworksUser,
            prepareData.survey.Id
        );

        System.assertEquals(1, [
            SELECT
                Id
            FROM
                Submission__c
            WHERE
                Survey__c = :prepareData.survey.Id
                AND Surveyor__c = :prepareData.privateSurveyor.theContact.Id
        ].size());
    }

    static testMethod void testNormalSurveyor() {

        PermissionData prepareData = preparePermission();
        permissionTest(
            prepareData.xml,
            prepareData.normalSurveyor,
            prepareData.taroworksUser,
            prepareData.survey.Id
        );
        System.assertEquals(1, [
            SELECT
                Id,
                Surveyor__c
            FROM
                Submission__c
            WHERE
                Survey__c = :prepareData.survey.Id
                AND Surveyor__c = :prepareData.normalSurveyor.theContact.Id
        ].size());
    }

    // Method to prepare the data for executing the permissions tests
    private static PermissionData preparePermission() {

        User taroworksUser =  TestUtils.generateTaroworksUser();

        // Create private conctact and a normal one(with account)
        Account ac = new Account(Name = 'TheAccount',AccountNumber ='User');
        insert ac;

        TestUtils.Surveyor privateSurveyor =
            TestUtils.createSurveyor(
                'test__privateSurveyor',
                'pSurveyor',
                'pass',
                MobileUserDO.STATUS_ACTIVE,
                true
            );

        TestUtils.Surveyor normalSurveyor =
            TestUtils.createSurveyor(
                'test__normalSurveyor',
                'nSurveyor',
                'pass',
                MobileUserDO.STATUS_ACTIVE,
                true
            );

        normalSurveyor.theContact.Account = ac;

        Survey__c survey = new Survey__c(
            Name = 'Survey',
            Status__c = SurveyDO.STATUS_DRAFT
        );
        insert survey;

        Question__c qSection = TestUtils.addSection(survey, 1 , 'section');

        Question__c q1 =
            TestUtils.addQuestion(qSection, 1, 'question1', QuestionDO.TYPE_TEXT_SHORT);

        SurveyVersion__c version = SurveyDO.publishSurvey(survey);

        String xml =
        '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + survey.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>'+ String.valueOf(Math.random()) + '</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<' + qSection.Name + '>' +
                '<'+ q1.Name +'>'+ String.valueOf(Math.random()) +'</'+ q1.Name +'>'+
            '</' + qSection.Name + '>' +
        '</'+ survey.Name + '>';

        PermissionData permissionData =new PermissionData();
        permissionData.normalSurveyor = normalSurveyor;
        permissionData.privateSurveyor = privateSurveyor;
        permissionData.xml = xml;
        permissionData.survey = survey;
        permissionData.taroworksUser = taroworksUser;
        return permissionData;
    }

    //class used to return all the data from the preparePermissionTest method
    private class PermissionData {
        public TestUtils.Surveyor privateSurveyor;
        public TestUtils.Surveyor normalSurveyor;
        public User taroworksUser;
        public Survey__c survey;
        public String xml;
    }

    private static void permissionTest(
            String xml,
            TestUtils.Surveyor surveyor,
            User user,
            Id surveyId
    ) {

        System.runAs(user) {
            Test.startTest();
            Submission  sub =
                TestUtils.submitNewSubmission(xml, surveyor.loginResult);
            Test.stopTest();
        }
    }

    /*
    * Check the Contact information is updated when proccess a submission from regular section questions
    * and mapped survey id using LastName field of Contact as Id Field.
    */
    static testMethod void testSubmissionRegularQuestionWithID(){
        Survey__c survey = new Survey__c(
            Name='Survey',
            Status__c = SurveyDO.STATUS_PUBLISHED,
            Gps_Location_Enabled__c = true
        );
        insert survey;

        Question__c qSection = new Question__c(Survey__c=survey.Id, Name = 'section_1', Caption__c= 'Section 1',Type__c = QuestionDO.TYPE_SECTION, Position__c = 1);
        insert qSection;

        Question__c q1 = new Question__c(Name = 'q1', Position__c = 1, Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Last Name',Type__c = QuestionDO.TYPE_TEXT_SHORT);
        Question__c q2 = new Question__c(Name = 'q2', Position__c = 2, Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Mail Street',Type__c = QuestionDO.TYPE_TEXT_SHORT);
        insert new Question__c[]{q1,q2};

        // Survey Mapping, new Contact
        SurveyMapping__c sm1 = new SurveyMapping__c(Survey__c=survey.Id, ObjectApiName__c='Contact', MatchingField__c='LastName');
        insert sm1;

        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c='LastName',Question__c=q1.Id,SurveyMapping__c=sm1.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c='MailingStreet',Question__c=q2.Id,SurveyMapping__c=sm1.Id);
        insert new QuestionMapping__c[]{qm1,qm2};

        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c desc];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        String q1_result = 'contact 1';
        String orig_result = 'Origin Address';
        String q2_result = 'Fake Address 123';

        Contact contact = new Contact(LastName = q1_result, MailingStreet = orig_result);
        insert contact;

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
                '<'+ q1.Name +'>' + q1_result + '</'+ q1.Name +'>'+
                '<'+ q2.Name +'>' + q2_result + '</'+ q2.Name +'>'+
            '</' + qSection.Name + '>' +
        '</'+ survey.Name + '>';

        TestUtils.Surveyor surv = initMobileUser();

        Test.startTest();

        // Submit a survey that will create a contact and assign it as interviewee
        Submission  sub =
            TestUtils.submitNewSubmission(xml, surv.loginResult);
        Test.stopTest();

        // Select current contact
        List<Contact> contacts = [SELECT Id, LastName, MailingStreet FROM Contact WHERE LastName =: q1_result];

        List<Submission__c> resultSA = [SELECT id FROM Submission__c WHERE survey__c = :survey.Id];

        //ASSERTIONS
        //a contact must be created and a submission should exist
        system.assertEquals(1, contacts.size());
        system.assertEquals(1, resultSA.size());

        //ASSERTIONS
        //a contact must be updated and a submission should exist
        system.assertEquals(1, contacts.size());
        system.assertEquals(1, resultSA.size());

        system.assertEquals(q1_result, contacts[0].LastName, 'LastName must be ' + q1_result);
        system.assertEquals(q2_result,contacts[0].MailingStreet, 'The updated Mailing Street must be ' + q2_result);
    }

    /*
    * Check the Contact information is updated when proccess a submission from repeat section questions
    * and mapped survey id using LastName field of Contact as Id Field.
    */
    static testMethod void testSubmissionRepeatQuestionWithID(){
        Survey__c survey = new Survey__c(
            Name='Survey',
            Status__c = SurveyDO.STATUS_PUBLISHED,
            Gps_Location_Enabled__c = true
        );
        insert survey;

        Question__c qSection = new Question__c(Survey__c=survey.Id, Name = 'section_1', Caption__c= 'Section 1',Type__c = QuestionDO.TYPE_REPEAT, Position__c = 1);
        insert qSection;

        Question__c q1 = new Question__c(Name = 'q1', Position__c = 1, Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Last Name',Type__c = QuestionDO.TYPE_TEXT_SHORT);
        Question__c q2 = new Question__c(Name = 'q2', Position__c = 2, Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Mail Street',Type__c = QuestionDO.TYPE_TEXT_SHORT);
        insert new Question__c[]{q1,q2};

        //Survey Mapping,new Contact
        SurveyMapping__c sm1 = new SurveyMapping__c(
            Survey__c = survey.Id,
            ObjectApiName__c = 'Contact',
            MatchingField__c = 'LastName',
            Repeat__c = qSection.Id
        );
        insert sm1;

        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c='LastName',Question__c=q1.Id,SurveyMapping__c=sm1.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c='MailingStreet',Question__c=q2.Id,SurveyMapping__c=sm1.Id);
        insert new QuestionMapping__c[]{qm1,qm2};

        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c desc];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        String q1_result = 'contact 1';
        String orig_result = 'Origin Address';
        String q2_result = 'Fake Address 123';

        Contact contact = new Contact(LastName = q1_result, MailingStreet = orig_result);
        insert contact;

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
                '<'+ q1.Name +'>' + q1_result + '</'+ q1.Name +'>'+
                '<'+ q2.Name +'>' + q2_result + '</'+ q2.Name +'>'+
            '</' + qSection.Name + '>' +
        '</'+ survey.Name + '>';

        TestUtils.Surveyor surv = initMobileUser();

        // Submit a survey that will create a contact and assign it as interviewee
        Test.startTest();
        Submission  sub = TestUtils.submitNewSubmission(xml, surv.loginResult);
        Test.stopTest();

        // Select current contact
        List<Contact> contacts = [SELECT Id, LastName, MailingStreet FROM Contact WHERE LastName =: q1_result];

        List<Submission__c> resultSA = [SELECT id FROM Submission__c WHERE survey__c = :survey.Id];

        //ASSERTIONS
        //a contact must be updated and a submission should exist
        system.assertEquals(1,contacts.size());
        system.assertEquals(1,resultSA.size());

        system.assertEquals(q1_result, contacts[0].LastName, 'LastName must be ' + q1_result);
        system.assertEquals(q2_result,contacts[0].MailingStreet, 'The updated Mailing Street must be ' + q2_result);
    }

    /**
     * Create a contact group and associates it with the contact and the survey, so that
     * the contact can download and submit results for that survey.
     * @param ctc The contact to associate with the group.
     * @param surveyId The Id of the survey to associate with the group.
     * @param status Status of the contact group. {'Active'|'Inactive'}
     */
    public static void assignContactToSurvey(Contact ctc, Id surveyId, String status){
        // Create contact group
        ContactGroup__c ctGroup = new ContactGroup__c(Name = 'GroupTest', Status__c = status);
        insert ctGroup;
        // Create contact group member in the group
        DBFullAccess.InsertSObject(new ContactGroupMember__c(ContactGroup__c = ctGroup.Id, Contact__c = ctc.Id));
        // Assing the survey to the group
        insert new ContactGroupSurveyAssignment__c (ContactGroup__c = ctGroup.Id, Survey__c = surveyId);
    }

    /*
     * Test the correct mapping of the submission data for a survey mapping
     */
    static testMethod void testSubmissionDataMapping() {

        Survey__c survey = new Survey__c(
            Name = 'Survey',
            Status__c = SurveyDO.STATUS_PUBLISHED,
            Gps_Location_Enabled__c = true
        );
        insert survey;

        Question__c section = TestUtils.addSection(
            survey, 1, 'Section1'
        );
        Question__c q1 = TestUtils.addQuestion(
            section, 1, 'q1', QuestionDO.TYPE_CHECKBOX
        );
        Question__c contactIdQuestion = TestUtils.addQuestion(
            section, 2, 'contactId', QuestionDO.TYPE_TEXT_SHORT
        );
        Question__c leadNameQuestion = TestUtils.addQuestion(
            section, 3, 'leadLastName', QuestionDO.TYPE_TEXT_SHORT
        );

        List<Option__c> options = TestUtils.addOptions(
            q1,
            new List<String>{ 'a', 'b' },
            new List<Integer>{ 10, 5 }
        );

        Contact interviewee = new Contact(LastName = 'SomeInterviewee');
        insert interviewee;

        SurveyMapping__c leadSurveyMapping = new SurveyMapping__c(
            Survey__c = survey.Id,
            ObjectApiName__c = 'Lead',
            SurveyVersionApiField__c = '',
            SurveyorApiField__c = 'Company',
            PPIScoreApiField__c ='NumberOfEmployees'
        );

        SurveyMapping__c caseToSurveyorSurveyMapping = new SurveyMapping__c(
            Survey__c = survey.Id,
            ObjectApiName__c = 'Case',
            SurveyorApiField__c = 'ContactID'
        );

        SurveyMapping__c intervieweeToCaseSurveyMapping = TestUtils.mapObject(
            survey, 'Case'
        );

        SurveyMapping__c contactMapping = TestUtils.mapObject(
            survey, 'Contact', true, 'LastName'
        );
        insert new List<SurveyMapping__c>{
            leadSurveyMapping,
            caseToSurveyorSurveyMapping
        };

        QuestionMapping__c leadTitleQuestionMapping = TestUtils.mapQuestion(
            leadSurveyMapping, q1, 'Title'
        );
        QuestionMapping__c leadNameQuestionMapping = TestUtils.mapQuestion(
            leadSurveyMapping, leadNameQuestion, 'LastName'
        );
        QuestionMapping__c contactNameQuestionMapping = TestUtils.mapQuestion(
            contactMapping, contactIdQuestion, 'LastName'
        );

        ObjectRelationshipMapping__c caseToContactMapping = TestUtils.relateObjects(
            intervieweeToCaseSurveyMapping, contactMapping, 'ContactID'
        );

        SurveyVersion__c surveyVersion = SurveyDO.publishSurvey(survey);

        String xml =
        '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + surveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<' + section.Name + '>' +
                '<'+ q1.Name +'>' + options[0].Id+ '</'+ q1.Name +'>'+
                '<'+ contactIdQuestion.Name +'>' + interviewee.LastName +
                    '</'+ contactIdQuestion.Name +'>'+
                '<'+ leadNameQuestion.Name +'>' + interviewee.LastName +
                    '</'+ leadNameQuestion.Name +'>'+
            '</' + section.Name + '>' +
        '</'+ survey.Name + '>';

        TestUtils.Surveyor surveyor = initMobileUser();

        Test.startTest();
        Submission  sub = TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        Test.stopTest();

        List<Lead> leads = [
            SELECT
                Id,
                Name,
                Company,
                NumberOfEmployees
            FROM
                Lead
            WHERE
                LastName = 'SomeInterviewee'
        ];
        List<Submission__c> submissions = [
            SELECT
                Id,
                Surveyor__c,
                PPIScore__c
            FROM
                Submission__c
            WHERE
                survey__c = :survey.Id
        ];

        List<Case> cases = [
            SELECT
                Id,
                ContactID
            FROM
                Case
            WHERE
                ContactID = :interviewee.Id
                OR ContactID = :surveyor.theContact.Id
        ];
        System.assertEquals(2, cases.size());
        System.assertEquals(1, leads.size());
        System.assertEquals(1, submissions.size());

        Map<Id,Contact> contactsInvolvedInSubmission = new Map<Id,Contact>([
            SELECT
                Id,
                Name
            FROM
                Contact
            WHERE
                Id = :submissions[0].Surveyor__c
                OR Id = :interviewee.Id
        ]);

        System.assertEquals(
            contactsInvolvedInSubmission.get(interviewee.Id).Name,
            leads[0].Name
        );
        System.assertEquals(
            contactsInvolvedInSubmission.get(submissions[0].Surveyor__c).Name,
            leads[0].Company
        );
        System.assertEquals(submissions[0].PPIScore__c, leads[0].NumberOfEmployees);
    }

    /*
     * Test blank answer of a question mapped to an existing field.
     * When update the object the blank field do not execute the update and remains as before.
     *
     */
    static testMethod void testBlankAnswerDoNotUpdateField() {

        Survey__c survey = new Survey__c(Name = 'Survey',
                                         Status__c = SurveyDO.STATUS_PUBLISHED,
                                         Gps_Location_Enabled__c = true);
        insert survey;

        Question__c section = new Question__c(Survey__c=survey.Id,
                                              Name='s',
                                              Caption__c='s',
                                              Type__c=QuestionDO.TYPE_SECTION,
                                              Position__c=1);
        insert section;
        Question__c q1 = new Question__c(
            Position__c = 1,
            Name        = 'q1',
            Caption__c  = 'First Name',
            Parent__c   = section.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT);

        Question__c q2 = new Question__c(
            Position__c = 2,
            Name        = 'q2',
            Caption__c  = 'Last Name',
            Parent__c   = section.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT);

        insert new List<Question__c>{q1,q2};

        //Survey Mapping,new Contact
        SurveyMapping__c sm1 =
            new SurveyMapping__c(
                Survey__c = survey.Id,
                ObjectApiName__c = 'Contact',
                MatchingField__c = 'LastName'
            );
        insert sm1;

        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c='FirstName',Question__c=q1.Id,SurveyMapping__c=sm1.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c='LastName',Question__c=q2.Id,SurveyMapping__c=sm1.Id);
        insert new QuestionMapping__c[]{qm1,qm2};

        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c desc];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        String testLastName = 'Owen';

        String xml =
        '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + surveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<' + section.Name + '>' +
                '<'+ q1.Name +'>Michael</'+ q1.Name +'>'+
                '<'+ q2.Name +'>' + testLastName + '</'+ q2.Name +'>'+
            '</' + section.Name + '>' +
        '</'+ survey.Name + '>';

        TestUtils.Surveyor surveyor = initMobileUser();

        Test.startTest();

        // Submit a survey that will create a contact named Michael Owen
        Submission sub = TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        List<Submission__c> submissions = [
            SELECT
                Id
            FROM
                Submission__c
            WHERE
                Survey__c = :survey.Id
        ];


        // ASSERTIONS
        System.assertEquals(1,submissions.size());

        // Get the contacts of the submission
        List<Contact> contacts = new List<Contact>([
            SELECT
                Id,
                Name
            FROM
                Contact
            WHERE
                LastName = :testLastName
        ]);

        // Map only contains the new contact
        System.assertEquals(1, contacts.size());

        // Insert the new contact
        System.assertEquals('Michael ' + testLastName, contacts[0].Name);

        // Do the answer with an empty answer
        xml =
        '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + surveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<' + section.Name + '>' +
                '<'+ q1.Name +'></'+ q1.Name +'>'+
                '<'+ q2.Name +'>' + testLastName + '</'+ q2.Name +'>'+
            '</' + section.Name + '>' +
        '</'+ survey.Name + '>';

        // Submit a survey that will update a contact named Michael Owen
        sub = TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        Test.stopTest();
        submissions = [SELECT Id FROM Submission__c WHERE survey__c = :survey.Id];

        //ASSERTIONS
        system.assertEquals(2,submissions.size());

        //get the contacts of the submission
        contacts = new List<Contact>([
            SELECT
                Id,
                Name
            FROM
                Contact
            WHERE
                LastName = :testLastName
        ]);

        // Map contains the updated contact
        System.assertEquals(1, contacts.size());

        // After update the contact with an empty anwser in name question, the name is the same
        System.assertEquals('Michael Owen', contacts[0].Name);
    }

    /*
     * Test the correct mapping of related objects
     * different order of the input list
     *
     */
     static testMethod void testSubmissionRelatedObjectsOrderOne(){
         testSubmissionRelatedObjects(1);
     }
     static testMethod void testSubmissionRelatedObjectsOrderTwo(){
         testSubmissionRelatedObjects(2);
     }
     static testMethod void testSubmissionRelatedObjectsOrderThree(){
         testSubmissionRelatedObjects(3);
     }

    /**
     * Base test to check the related objects mapping, assigning
     * different types of orders, according to the parameter.
     *
     * @param orderType
     */
    static void testSubmissionRelatedObjects(Integer orderType) {

        Survey__c survey = new Survey__c(
            Name = 'Survey',
            Status__c = SurveyDO.STATUS_PUBLISHED,
            Gps_Location_Enabled__c = true
        );
        insert survey;

        String intervieweeLastName = 'SomeInterviewee';
        Contact interviewee = new Contact(LastName = intervieweeLastName);
        insert interviewee;

        Question__c section = TestUtils.addSection(survey, 1, 's1');
        Question__c q1 = new Question__c(
            Position__c = 1,
            Name        = 'q1',
            Caption__c  = 'q1',
            Parent__c   = section.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT
        );
        Question__c q2 = new Question__c(
            Position__c = 2,
            Name        = 'q2',
            Caption__c  = 'q2',
            Parent__c   = section.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT
        );
        Question__c q3 = new Question__c(
            Position__c = 3,
            Name        = 'q3',
            Caption__c  = 'q3',
            Parent__c   = section.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT
        );
         Question__c qCaseOrigin = new Question__c(
            Position__c = 4,
            Name        = 'qCaseOrigin',
            Caption__c  = 'q3',
            Parent__c   = section.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_RADIO
        );
         Question__c qCaseStatus = new Question__c(
            Position__c = 5,
            Name        = 'qCaseStatus',
            Caption__c  = 'q4',
            Parent__c   = section.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_RADIO
        );
        Question__c contactLastName = new Question__c(
            Position__c = 6,
            Name        = 'LastName',
            Caption__c  = 'LastName',
            Parent__c   = section.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT
        );
        insert new List<Question__c>{
            q1,
            q2,
            q3,
            qCaseOrigin,
            qCaseStatus,
            contactLastName
        };

        Option__c optionOrigin = new Option__c(Name='Phone',Caption__c='Phone',Question__c=qCaseOrigin.Id,Position__c=1);
        Option__c optionStatus = new Option__c(Name='Working',Caption__c='Working',Question__c=qCaseOrigin.Id,Position__c=1);
        insert new Option__c[]{optionOrigin,optionStatus};

        SurveyMapping__c smContact = new SurveyMapping__c(
            Survey__c = survey.Id,
            ObjectApiName__c = 'Contact',
            MatchingField__c = 'LastName'
        );

        SurveyMapping__c smCase1 = new SurveyMapping__c(
            Survey__c = survey.Id,
            ObjectApiName__c = 'Case'
        );

        SurveyMapping__c smCase2 = new SurveyMapping__c(
            Survey__c = survey.Id,
            ObjectApiName__c = 'Case'
        );

        SurveyMapping__c smAsset = new SurveyMapping__c(
            Survey__c = survey.Id,
            ObjectApiName__c = 'Asset'
        );

        SurveyMapping__c smAccount = new SurveyMapping__c(
            Survey__c = survey.Id,
            ObjectApiName__c = 'Account'
        );

        // Insert the survey mapping according to the order parameter
        if (orderType == 1) {
            insert new List<SurveyMapping__c>{smContact, smCase1, smCase2, smAsset, smAccount};
        }
        else if (orderType == 2) {
            insert new List<SurveyMapping__c>{smAsset, smAccount, smCase2, smContact, smCase1};
        }
        else if (orderType == 3) {
            insert new List<SurveyMapping__c>{smCase1, smCase2, smAccount, smContact, smAsset};
        }

        // Insert the mappings of the required fields
        QuestionMapping__c qmAssetName = new QuestionMapping__c(
            FieldApiName__c = 'Name', Question__c = q2.Id, SurveyMapping__c = smAsset.Id
        );
        QuestionMapping__c qmContactName = new QuestionMapping__c(
            FieldApiName__c = 'LastName',
            Question__c = contactLastName.Id,
            SurveyMapping__c = smContact.Id
        );
        QuestionMapping__c qmCase1Origin = new QuestionMapping__c(
            FieldApiName__c ='Origin', Question__c = qCaseOrigin.Id, SurveyMapping__c = smCase1.Id
        );
        QuestionMapping__c qmCase1Status = new QuestionMapping__c(
            FieldApiName__c ='Status', Question__c = qCaseStatus.Id, SurveyMapping__c = smCase1.Id
        );
        QuestionMapping__c qmCase2Origin = new QuestionMapping__c(
            FieldApiName__c ='Origin', Question__c = qCaseOrigin.Id, SurveyMapping__c = smCase2.Id
        );
        QuestionMapping__c qmCase2Status = new QuestionMapping__c(

            FieldApiName__c ='Status', Question__c = qCaseStatus.Id, SurveyMapping__c = smCase2.Id
        );
        QuestionMapping__c qmAccountName = new QuestionMapping__c(
            FieldApiName__c ='Name', Question__c = q2.Id, SurveyMapping__c = smAccount.Id
        );

        insert new List<QuestionMapping__c>{
            qmAssetName,
            qmContactName,
            qmCase1Origin,
            qmCase1Status,
            qmCase2Origin,
            qmCase2Status,
            qmAccountName
        };

        // Insert the relationship mappings
        ObjectRelationshipMapping__c rAccountContact = new ObjectRelationshipMapping__c(
            ParentSurveyMapping__c = smAccount.Id,
            ChildSurveyMapping__c = smContact.Id,
            FieldApiName__c = 'AccountId'
        );
        ObjectRelationshipMapping__c rContactCase1 = new ObjectRelationshipMapping__c(
            ParentSurveyMapping__c = smContact.Id,
            ChildSurveyMapping__c = smCase1.Id,
            FieldApiName__c = 'ContactId'
        );
        ObjectRelationshipMapping__c rAssetCase2 = new ObjectRelationshipMapping__c(
            ParentSurveyMapping__c = smAsset.Id,
            ChildSurveyMapping__c = smCase2.Id,
            FieldApiName__c = 'AssetId'
        );
        ObjectRelationshipMapping__c rContactCase2 = new ObjectRelationshipMapping__c(
            ParentSurveyMapping__c = smContact.Id,
            ChildSurveyMapping__c = smCase2.Id,
            FieldApiName__c = 'ContactId'
        );
        ObjectRelationshipMapping__c rContactAsset = new ObjectRelationshipMapping__c(
            ParentSurveyMapping__c = smContact.Id,
            ChildSurveyMapping__c = smAsset.Id,
            FieldApiName__c = 'ContactId'
        );
        insert new List<ObjectRelationshipMapping__c>{
            rAccountContact,
            rContactCase1,
            rAssetCase2,
            rContactCase2,
            rContactAsset
        };

        SurveyVersion__c surveyVersion = SurveyDO.publishSurvey(survey);

        String xml =
        '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + surveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<' + section.Name + '>' +
                '<'+ q1.Name +'>' + 'Answer1' + '</'+ q1.Name +'>'+
                '<'+ q2.Name +'>' + 'Answer2' + '</'+ q2.Name +'>'+
                '<'+ q3.Name +'>' + 'Answer2' + '</'+ q3.Name +'>'+
                '<'+ qCaseOrigin.Name +'>' + optionOrigin.Id + '</'+ qCaseOrigin.Name +'>'+
                '<'+ qCaseStatus.Name +'>' + optionStatus.Id + '</'+ qCaseStatus.Name +'>'+
                '<'+ contactLastName.Name +'>LastName</'+ contactLastName.Name +'>'+
            '</' + section.Name + '>' +
        '</'+ survey.Name + '>';

        TestUtils.Surveyor surveyor = initMobileUser();

        Test.startTest();

        // Submit a survey that will create a contact and assign it as interviewee
        Submission  sub = TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        Test.stopTest();

        // A submission should exist
        List<Submission__c> submissions = [
            SELECT
                Id,
                Surveyor__c,
                PPIScore__c
            FROM
                Submission__c
            WHERE
                Survey__c = :survey.Id
        ];
        System.assertEquals(1, submissions.size());

        // An Account should be created
        List<Account> newAccounts = [
            SELECT
                Id,
                Name
            FROM
                Account
            WHERE
                Name = 'Answer2'
        ];
        System.assertEquals(1, newAccounts.size());

        // A Contact Should be created and related to the account
        List<Contact> newContact = [
            SELECT
                Id,
                Name,
                AccountId
            FROM
                Contact WHERE AccountID = :newAccounts[0].Id
        ];
        System.assertEquals(1, newContact.size());

        // An asset related to the case should exist
        List<Asset> newAssets = [SELECT Id FROM Asset WHERE Name = 'Answer2'];
        System.assertEquals(1,newAssets.size());

        // 2 cases should be created related with the contact
        List<Case> newCases = [
            SELECT
                Id,
                ContactID,
                AssetId
            FROM
                Case
            WHERE
                ContactID = :newContact[0].Id
            ORDER BY
                AssetId
        ];
        System.assertEquals(2, newCases.size());

        // Created case should have an asset set
        System.assertEquals(newAssets[0].Id, newCases[1].AssetId);
    }

    /**
     * Test that the repeated questions are correctly parsed and
     * related to their parent section
     */
    static testMethod void testSubmissionRepeatedQuestion(){

        // Create a contact to use as interviewee
        Contact interviewee = new Contact(LastName ='Terry',mobilesurveys_Id__c='4321');
        insert interviewee;
        interviewee = [SELECT Name, mobilesurveys_Id__c FROM Contact WHERE Id = :interviewee.Id LIMIT 1];

        Survey__c survey = new Survey__c(
            Name                    = 'SurveyName',
            Status__c = SurveyDO.STATUS_PUBLISHED,
            Gps_Location_Enabled__c = true,
            PPIDataYear__c = 2011
        );
        insert survey;

        Question__c section = new Question__c(Survey__c=survey.Id,
                                              Name='s1',
                                              Caption__c='s',
                                              Type__c=QuestionDO.TYPE_SECTION,
                                              Position__c=1);
        Question__c sectionRepeat1 = new Question__c(Survey__c=survey.Id,
                                                    Name='repeated1',
                                                    Caption__c='repeated1',
                                                    Type__c=QuestionDO.TYPE_REPEAT,
                                                    Position__c=2);
        Question__c sectionRepeat2 = new Question__c(Survey__c=survey.Id,
                                                    Name='repeated2',
                                                    Caption__c='repeated2',
                                                    Type__c=QuestionDO.TYPE_REPEAT,
                                                    Position__c=3);

        // Create a nested section repeat with answers
        Question__c sectionRepeatParent = new Question__c(Survey__c=survey.Id,
                                                    Name='repeatedParent',
                                                    Caption__c='repeatedParent',
                                                    Type__c=QuestionDO.TYPE_REPEAT,
                                                    Position__c=4);
        insert new Question__c[]{section,sectionRepeat1,sectionRepeat2,sectionRepeatParent};
        Question__c questionAccountName = new Question__c(Survey__c=survey.Id,
                                                    Name='NameAccount',
                                                    Caption__c='NameAccount',
                                                    Parent__c   = sectionRepeatParent.Id,
                                                    Type__c=QuestionDO.TYPE_TEXT_SHORT,
                                                    Position__c=1);
        Question__c sectionRepeatChild = new Question__c(Survey__c=survey.Id,
                                                    Name='repeatedChild',
                                                    Caption__c='repeatedChild',
                                                    Parent__c   = sectionRepeatParent.Id,
                                                    Type__c=QuestionDO.TYPE_REPEAT ,
                                                    Position__c=3);
        Question__c questionContactDescription = new Question__c(Survey__c=survey.Id,
                                                    Name='DescriptionContact',
                                                    Caption__c='DescriptionContact',
                                                    Parent__c   = sectionRepeatParent.Id,
                                                    Type__c=QuestionDO.TYPE_TEXT_SHORT,
                                                    Position__c=2);

        insert new Question__c[] {sectionRepeatChild, questionAccountName, questionContactDescription};

        Question__c question1 = new Question__c(
            Position__c = 1,
            Name        = 'q1',
            Caption__c  = 'q1',
            Parent__c   = section.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT);
       Question__c question2 = new Question__c(
            Position__c = 1,
            Name        = 'q2',
            Caption__c  = 'q2',
            Parent__c   = sectionRepeat1.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_RADIO);
       Question__c question3 = new Question__c(
            Position__c = 2,
            Name        = 'q3',
            Caption__c  = 'q3',
            Parent__c   = sectionRepeat1.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT);
       Question__c question4 = new Question__c(
            Position__c = 1,
            Name        = 'q4',
            Caption__c  = 'q4',
            Parent__c   = sectionRepeat2.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT);
       Question__c question5 = new Question__c(
            Position__c = 1,
            Name        = 'q5',
            Caption__c  = 'q5',
            Parent__c   = sectionRepeatChild.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT);
        insert new Question__c[]{question1,question2,question3,question4,question5};

        Option__c option  = new Option__c(Name = 'a', Caption__c = 'a', Question__c = question2.Id,Position__c = 1);
        Option__c option2 = new Option__c(Name = 'b', Caption__c = 'b', Question__c = question2.Id,Position__c = 2);
        insert new Option__c[] {option,option2};

        // Insert Survey Mappings for the nested repeated section
        SurveyMapping__c smAccount = new SurveyMapping__c(Survey__c=survey.Id,ObjectApiName__c='Account',Repeat__c=sectionRepeatParent.Id);

        // Survey Mapping of a Contact
        SurveyMapping__c smContact = new SurveyMapping__c(Survey__c=survey.Id,ObjectApiName__c='Contact',Repeat__c=sectionRepeatChild.Id);

        // Survey Mapping
        SurveyMapping__c smCase = new SurveyMapping__c(Survey__c=survey.Id,ObjectApiName__c='Case',Repeat__c=sectionRepeatParent.Id);
        insert new SurveyMapping__c[]{smAccount,smContact,smCase};

        // Insert the relationship mappings
        // Relation of parent-child repeated
        ObjectRelationshipMapping__c rAccountContact = new ObjectRelationshipMapping__c(ParentSurveyMapping__c = smAccount.Id,
                                                                                        ChildSurveyMapping__c=smContact.Id,
                                                                                        FieldApiName__c='AccountId');
        // Relation of a object of the same Repeat-section
        ObjectRelationshipMapping__c rAccountCase = new ObjectRelationshipMapping__c(ParentSurveyMapping__c = smAccount.Id,
                                                                                        ChildSurveyMapping__c=smCase.Id,
                                                                                        FieldApiName__c='AccountId');
        insert new ObjectRelationshipMapping__c[] {rAccountContact,rAccountCase};
        // Insert question Mappings for the new elements

        // Question mapping for the contact
        QuestionMapping__c qm1 = new QuestionMapping__c(FieldApiName__c='LastName',Question__c=question5.Id,SurveyMapping__c=smContact.Id);
        QuestionMapping__c qm3 = new QuestionMapping__c(FieldApiName__c='FirstName',Question__c=questionContactDescription.Id,SurveyMapping__c=smContact.Id);
        QuestionMapping__c qm2 = new QuestionMapping__c(FieldApiName__c='Name',Question__c=questionAccountName.Id,SurveyMapping__c=smAccount.Id);
        QuestionMapping__c qm4 = new QuestionMapping__c(FieldApiName__c='Subject',Question__c=questionAccountName.Id,SurveyMapping__c=smCase.Id);
        insert new QuestionMapping__c[]{qm1,qm2,qm3,qm4};
        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c DESC];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        // Make a submission for the tested survey
        String xml =
        '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + survey.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<phonenumber />'+
            '<' + section.Name + '>' +
                '<'+ question1.Name +'>' + '' + '</'+ question1.Name +'>'+
            '</' + section.Name + '>' +
            '<' + sectionRepeat1.Name + '>' +
                '<'+ question2.Name +'>' + option.Id + '</'+ question2.Name +'>'+
                '<'+ question3.Name +'>' + 'someAnswer1' + '</'+ question3.Name +'>'+
            '</' + sectionRepeat1.Name + '>' +
            '<' + sectionRepeat1.Name + '>' +
                '<'+ question2.Name +'>' + option2.Id + '</'+ question2.Name +'>'+
                '<'+ question3.Name +'>' + 'someAnswer2' + '</'+ question3.Name +'>'+
            '</' + sectionRepeat1.Name + '>' +
            '<' + sectionRepeat1.Name + '>' +
                '<'+ question2.Name +'>' + option.Id + '</'+ question2.Name +'>'+
                '<'+ question3.Name +'>' + 'someAnswer3' + '</'+ question3.Name +'>'+
            '</' + sectionRepeat1.Name + '>' +
            '<' + sectionRepeat2.Name + '>' +
                '<'+ question4.Name +'>' + 'someAnswer4' + '</'+ question4.Name +'>'+
            '</' + sectionRepeat2.Name + '>' +
            '<' + sectionRepeatParent.Name + '>' +
                '<'+ questionAccountName.Name +'>' + 'Account1' + '</'+ questionAccountName.Name +'>'+
                '<'+ questionContactDescription.Name +'>' + 'Contact12' + '</'+ questionContactDescription.Name +'>'+
                '<' + sectionRepeatChild.Name + '>' +
                    '<'+ question5.Name +'>' + 'someAnswerChild1' + '</'+ question5.Name +'>'+
                '</' + sectionRepeatChild.Name + '>' +
                '<' + sectionRepeatChild.Name + '>' +
                    '<'+ question5.Name +'>' + 'someAnswerChild2' + '</'+ question5.Name +'>'+
                '</' + sectionRepeatChild.Name + '>' +
            '</' + sectionRepeatParent.Name + '>' +
            '<' + sectionRepeatParent.Name + '>' +
                '<'+ questionAccountName.Name +'>' + 'Account2' + '</'+ questionAccountName.Name +'>'+
                '<'+ questionContactDescription.Name +'>' + 'Contact34' + '</'+ questionContactDescription.Name +'>'+
                '<' + sectionRepeatChild.Name + '>' +
                    '<'+ question5.Name +'>' + 'someAnswerChild3' + '</'+ question5.Name +'>'+
                '</' + sectionRepeatChild.Name + '>' +
                '<' + sectionRepeatChild.Name + '>' +
                    '<'+ question5.Name +'>' + 'someAnswerChild4' + '</'+ question5.Name +'>'+
                '</' + sectionRepeatChild.Name + '>' +
            '</' + sectionRepeatParent.Name + '>' +
        '</'+ survey.Name + '>';

        // Set up Mobile User
        TestUtils.Surveyor surveyor = initMobileUser();

        Test.startTest();

        Submission  sub = TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        Test.stopTest();

        // Assert the submission was correctly created
        Submission__c[]  submissions = [SELECT Id, Name, Survey__c, Date__c, Status__c, PPIScore__c FROM Submission__c WHERE Survey__c = :survey.Id];
        system.assertEquals(1, submissions.size());

        // Assert the correct creation of the Answers of the repeated questions
        Answer__c[]  RepeatAnswer = [SELECT Id, Value__c, Instance__c,Parent__c, Question__c FROM Answer__c WHERE Submission__c = :submissions[0].Id AND Question__c = :sectionRepeat1.Id];
        system.assertEquals(3,RepeatAnswer.size());

        // Check answer instances number
        system.assertEquals(1,RepeatAnswer[0].Instance__c);
        system.assertEquals(2,RepeatAnswer[1].Instance__c);
        system.assertEquals(3,RepeatAnswer[2].Instance__c);

        Answer__c[]  RepeatAnswer2 = [SELECT Id, Value__c, Instance__c,Parent__c, Question__c FROM Answer__c WHERE Submission__c = :submissions[0].Id AND Question__c = :sectionRepeat2.Id];
        system.assertEquals(1,RepeatAnswer2.size());

        // Check answer instances number
        system.assertEquals(1,RepeatAnswer2[0].Instance__c);

        // Check the answers of the sections
        Answer__c[] answersRepeated1 = [SELECT Id, Value__c, Instance__c,Parent__c, Question__c FROM Answer__c WHERE Submission__c = :submissions[0].Id AND Parent__c in :RepeatAnswer ORDER BY Instance__c,Question__r.Name];
        Answer__c[] answersRepeated2 = [SELECT Id, Value__c, Instance__c,Parent__c, Question__c FROM Answer__c WHERE Submission__c = :submissions[0].Id AND Parent__c in :RepeatAnswer2 ORDER BY Instance__c,Question__r.Name];

        // First repeated section
        system.assertEquals(6, answersRepeated1.size());

        // Assert correct generation of the Answers
        system.assertEquals(1, answersRepeated1[0].Instance__c);
        system.assertEquals(option.Caption__c, answersRepeated1[0].Value__c);
        system.assertEquals(1, answersRepeated1[1].Instance__c);
        system.assertEquals('someAnswer1', answersRepeated1[1].Value__c);
        system.assertEquals(2, answersRepeated1[2].Instance__c);
        system.assertEquals(option2.Caption__c, answersRepeated1[2].Value__c);
        system.assertEquals(2, answersRepeated1[3].Instance__c);
        system.assertEquals('someAnswer2', answersRepeated1[3].Value__c);
        system.assertEquals(3, answersRepeated1[4].Instance__c);
        system.assertEquals(option.Caption__c, answersRepeated1[4].Value__c);
        system.assertEquals(3, answersRepeated1[5].Instance__c);
        system.assertEquals('someAnswer3', answersRepeated1[5].Value__c);

        // Second repeated section
        system.assertEquals(1, answersRepeated2.size());
        system.assertEquals(1, answersRepeated2[0].Instance__c);
        system.assertEquals('someAnswer4', answersRepeated2[0].Value__c);

        // Assert correct creation of nested repeated answers
        // Assert the correct creation of the Answers of the repeated questions
        Answer__c[]  ParentRepeatAnswer = [SELECT Id, Value__c, Instance__c,Parent__c, Question__c FROM Answer__c WHERE Submission__c = :submissions[0].Id AND Question__c = :sectionRepeatParent.Id];

        system.assertEquals(2,ParentRepeatAnswer.size());

        Answer__c[]  ChildRepeatAnswer = [SELECT Id, Value__c, Instance__c,Parent__c, Question__c FROM Answer__c WHERE Submission__c = :submissions[0].Id AND Question__c = :sectionRepeatChild.Id AND Parent__c in :ParentRepeatAnswer];
        Answer__c[]  ChildAnswer = [SELECT Id, Value__c, Instance__c,Parent__c, Question__c FROM Answer__c WHERE Submission__c = :submissions[0].Id AND Question__c = :question5.Id AND Parent__c in :ChildRepeatAnswer];

        system.assertEquals(4,ChildRepeatAnswer.size());
        system.assertEquals(4,ChildAnswer.size());

        // Assertions from mapping
        Account[] newAccounts = [SELECT Id,AccountNumber FROM Account WHERE Name IN ('Account1','Account2') ORDER BY Name];
        Contact[] newContacts = [SELECT Id,LastName,AccountId FROM Contact WHERE AccountId IN :newAccounts AND FirstName IN ('Contact12','Contact34') AND LastName IN ('someAnswerChild1','someAnswerChild2','someAnswerChild3','someAnswerChild4') ORDER BY LastName];
        system.assertEquals(2,newAccounts.size());
        system.assertEquals(4,newContacts.size());

        // Assert correct assignment of the case/account
        system.assertEquals(1,[SELECT Id,Subject,AccountID FROM Case WHERE Subject = 'Account1' AND AccountID = :newAccounts[0].Id ].size());
        system.assertEquals(1, [SELECT Id,Subject,AccountID FROM Case WHERE Subject = 'Account2' AND AccountID = :newAccounts[1].Id].size() );
    }

    /**
     * This considers scenario of demographic data overriding null values recieved from submission
     */
    static testMethod void testGeneratePpiScoreWithDemographicOverride() {
        TestSurveyData testSurvey =
            TestSurveyData.createFullPpiTemplate();
        String xml =
        '<?xml version=\'1.0\' ?><data id="' + testSurvey.testSurveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<new_section><name>' + 
            testSurvey.getSection(0).Name + '</name>' +
                '<'+ testSurvey.getQuestion(0, 0).Name +'>' +
                    'Respondant' +
                '</'+ testSurvey.getQuestion(0, 0).Name +'>'+
            '</new_section>' +
            '<new_section><name>' + 
            testSurvey.getSection(1).Name + '</name>' +
                '<'+ testSurvey.getQuestion(1, 0).Name +'>' +
                    testSurvey.getOption(1, 0, 0).Id +
                '</'+ testSurvey.getQuestion(1, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 2).Name +'>' +
                    '4' +
                '</'+ testSurvey.getQuestion(1, 2).Name +'>' +
                '<'+ testSurvey.getQuestion(1, 3).Name +'>' +
                    Datetime.newInstanceGMT(2000, 01, 02, 00, 00, 00) +
                '</'+ testSurvey.getQuestion(1, 3).Name +'>' +
            '</new_section>' +
            '<new_section><name>' +
            testSurvey.getSection(2).Name + '</name>' +
                '<'+ testSurvey.getQuestion(2, 0).Name +'>' +
                testSurvey.getOption(2, 0, 0).Id + '</'+ testSurvey.getQuestion(2, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 1).Name +'>' +
                testSurvey.getOption(2, 1, 0).Id + '</'+ testSurvey.getQuestion(2, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 2).Name +'>' +
                testSurvey.getOption(2, 2, 0).Id + '</'+ testSurvey.getQuestion(2, 2).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 3).Name +'>' +
                testSurvey.getOption(2, 3, 0).Id + '</'+ testSurvey.getQuestion(2, 3).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 4).Name +'>' +
                testSurvey.getOption(2, 4, 0).Id + '</'+ testSurvey.getQuestion(2, 4).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 5).Name +'>' +
                testSurvey.getOption(2, 5, 0).Id + '</'+ testSurvey.getQuestion(2, 5).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 6).Name +'>' +
                testSurvey.getOption(2, 6, 0).Id + '</'+ testSurvey.getQuestion(2, 6).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 7).Name +'>' +
                testSurvey.getOption(2, 7, 0).Id + '</'+ testSurvey.getQuestion(2, 7).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 8).Name +'>' +
                testSurvey.getOption(2, 8, 0).Id + '</'+ testSurvey.getQuestion(2, 8).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 9).Name +'>' +
                testSurvey.getOption(2, 9, 0).Id + '</'+ testSurvey.getQuestion(2, 9).Name +'>'+
            '</new_section>' +
        '</data>';
        PpiSettings__c ppiSettings = PpiSettingsWrapper.insertRecord(
            'Account',
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Name.getName(),
            '',
            '',
            ''
        );
        PpiSettings__c ppiSettingsRecord = PpiSettingsWrapper.getRecordForName('Account');
        System.assert(
            ppiSettingsRecord != null,
            'PpiSettings record not found for Account object'
        );

        Account accountRecord =
            AccountDomainTest.createRecord(
                'Respondant',
                15,
                'Test Site',
                'ACC-001'
            );
        AccountDomain accountDomain = new AccountDomain();
        accountDomain.addRecord(accountRecord);
        accountDomain.insertRecords();
        System.assert(accountDomain.records.size() > 0);
        System.assert(accountDomain.records[0].Id != null);

        Test.startTest();
        TestUtils.Surveyor surveyor = initMobileUser();
        System.runAs(surveyor.partnerUser) {
            Submission submissionInstance =
                TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        }
        Test.stopTest();

        List<PpiResult__c> ppiResults =
            new PpiResultSelector().getAllForSurveyVersionIds(
                new Set<Id> {testSurvey.testSurveyVersion.Id}
            );
        System.assertEquals(1, ppiResults.size());
        System.assertEquals(15, ppiResults[0].Age__c);
    }

    /**
     * This considers data present in both submission as well as demographic record
     * It takes data from submission to populate Ppi result record
     */
    static testMethod void testGeneratePpiScoreWithDemographicSubmissionOverride() {
        TestSurveyData testSurvey =
            TestSurveyData.createFullPpiTemplate();
        String xml =
        '<?xml version=\'1.0\' ?><data id="' + testSurvey.testSurveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<new_section><name>' + 
            testSurvey.getSection(0).Name + '</name>' +
                '<'+ testSurvey.getQuestion(0, 0).Name +'>' +
                    'Respondant' +
                '</'+ testSurvey.getQuestion(0, 0).Name +'>'+
            '</new_section>' +
            '<new_section><name>' + 
            testSurvey.getSection(1).Name + '</name>' +
                '<'+ testSurvey.getQuestion(1, 0).Name +'>' +
                    testSurvey.getOption(1, 0, 0).Id +
                '</'+ testSurvey.getQuestion(1, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 1).Name +'>' +
                    '12' +
                '</'+ testSurvey.getQuestion(1, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 2).Name +'>' +
                    '4' +
                '</'+ testSurvey.getQuestion(1, 2).Name +'>' +
                '<'+ testSurvey.getQuestion(1, 3).Name +'>' +
                    Datetime.newInstanceGMT(2000, 01, 02, 00, 00, 00) +
                '</'+ testSurvey.getQuestion(1, 3).Name +'>' +
            '</new_section>' +
            '<new_section><name>' +
            testSurvey.getSection(2).Name + '</name>' +
                '<'+ testSurvey.getQuestion(2, 0).Name +'>' +
                testSurvey.getOption(2, 0, 0).Id + '</'+ testSurvey.getQuestion(2, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 1).Name +'>' +
                testSurvey.getOption(2, 1, 0).Id + '</'+ testSurvey.getQuestion(2, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 2).Name +'>' +
                testSurvey.getOption(2, 2, 0).Id + '</'+ testSurvey.getQuestion(2, 2).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 3).Name +'>' +
                testSurvey.getOption(2, 3, 0).Id + '</'+ testSurvey.getQuestion(2, 3).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 4).Name +'>' +
                testSurvey.getOption(2, 4, 0).Id + '</'+ testSurvey.getQuestion(2, 4).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 5).Name +'>' +
                testSurvey.getOption(2, 5, 0).Id + '</'+ testSurvey.getQuestion(2, 5).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 6).Name +'>' +
                testSurvey.getOption(2, 6, 0).Id + '</'+ testSurvey.getQuestion(2, 6).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 7).Name +'>' +
                testSurvey.getOption(2, 7, 0).Id + '</'+ testSurvey.getQuestion(2, 7).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 8).Name +'>' +
                testSurvey.getOption(2, 8, 0).Id + '</'+ testSurvey.getQuestion(2, 8).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 9).Name +'>' +
                testSurvey.getOption(2, 9, 0).Id + '</'+ testSurvey.getQuestion(2, 9).Name +'>'+
            '</new_section>' +
        '</data>';
        PpiSettings__c ppiSettings = PpiSettingsWrapper.insertRecord(
            'Account',
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Name.getName(),
            '',
            '',
            ''
        );
        PpiSettings__c ppiSettingsRecord = PpiSettingsWrapper.getRecordForName('Account');
        System.assert(
            ppiSettingsRecord != null,
            'PpiSettings record not found for Account object'
        );

        Account accountRecord =
            AccountDomainTest.createRecord(
                'Respondant',
                15,
                'Test Site',
                'ACC-001'
            );
        AccountDomain accountDomain = new AccountDomain();
        accountDomain.addRecord(accountRecord);
        accountDomain.insertRecords();
        System.assert(accountDomain.records.size() > 0);
        System.assert(accountDomain.records[0].Id != null);

        Test.startTest();
        TestUtils.Surveyor surveyor = initMobileUser();
        System.runAs(surveyor.partnerUser) {
            Submission submissionInstance =
                TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        }
        Test.stopTest();

        List<PpiResult__c> ppiResults =
            new PpiResultSelector().getAllForSurveyVersionIds(
                new Set<Id> {testSurvey.testSurveyVersion.Id}
            );
        System.assertEquals(1, ppiResults.size());
        System.assertEquals(12, ppiResults[0].Age__c);
    }

    /**
     * This considers no data present in demographic record, but Ppi Settings present
     * It takes data from submission to populate Ppi result record
     */
    static testMethod void testGeneratePpiScoreWithoutDemographic() {
        TestSurveyData testSurvey =
            TestSurveyData.createFullPpiTemplate();
        String xml =
        '<?xml version=\'1.0\' ?><data id="' + testSurvey.testSurveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<new_section><name>' + 
            testSurvey.getSection(0).Name + '</name>' +
                '<'+ testSurvey.getQuestion(0, 0).Name +'>' +
                    'Respondant' +
                '</'+ testSurvey.getQuestion(0, 0).Name +'>'+
            '</new_section>' +
            '<new_section><name>' + 
            testSurvey.getSection(1).Name + '</name>' +
                '<'+ testSurvey.getQuestion(1, 0).Name +'>' +
                    testSurvey.getOption(1, 0, 0).Id +
                '</'+ testSurvey.getQuestion(1, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 1).Name +'>' +
                    '12' +
                '</'+ testSurvey.getQuestion(1, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 2).Name +'>' +
                    '4' +
                '</'+ testSurvey.getQuestion(1, 2).Name +'>' +
                '<'+ testSurvey.getQuestion(1, 3).Name +'>' +
                    Datetime.newInstanceGMT(2000, 01, 02, 00, 00, 00) +
                '</'+ testSurvey.getQuestion(1, 3).Name +'>' +
            '</new_section>' +
            '<new_section><name>' +
            testSurvey.getSection(2).Name + '</name>' +
                '<'+ testSurvey.getQuestion(2, 0).Name +'>' +
                testSurvey.getOption(2, 0, 0).Id + '</'+ testSurvey.getQuestion(2, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 1).Name +'>' +
                testSurvey.getOption(2, 1, 0).Id + '</'+ testSurvey.getQuestion(2, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 2).Name +'>' +
                testSurvey.getOption(2, 2, 0).Id + '</'+ testSurvey.getQuestion(2, 2).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 3).Name +'>' +
                testSurvey.getOption(2, 3, 0).Id + '</'+ testSurvey.getQuestion(2, 3).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 4).Name +'>' +
                testSurvey.getOption(2, 4, 0).Id + '</'+ testSurvey.getQuestion(2, 4).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 5).Name +'>' +
                testSurvey.getOption(2, 5, 0).Id + '</'+ testSurvey.getQuestion(2, 5).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 6).Name +'>' +
                testSurvey.getOption(2, 6, 0).Id + '</'+ testSurvey.getQuestion(2, 6).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 7).Name +'>' +
                testSurvey.getOption(2, 7, 0).Id + '</'+ testSurvey.getQuestion(2, 7).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 8).Name +'>' +
                testSurvey.getOption(2, 8, 0).Id + '</'+ testSurvey.getQuestion(2, 8).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 9).Name +'>' +
                testSurvey.getOption(2, 9, 0).Id + '</'+ testSurvey.getQuestion(2, 9).Name +'>'+
            '</new_section>' +
        '</data>';
        PpiSettings__c ppiSettings = PpiSettingsWrapper.insertRecord(
            'Account',
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Name.getName(),
            '',
            '',
            ''
        );

        PpiSettings__c ppiSettingsRecord = PpiSettingsWrapper.getRecordForName('Account');
        System.assert(
            ppiSettingsRecord != null,
            'PpiSettings record not found for Account object'
        );

        // Demographic Settings is present but no matching records found so consider submisison data
        Test.startTest();
        TestUtils.Surveyor surveyor = initMobileUser();
        System.runAs(surveyor.partnerUser) {
            Submission submissionInstance =
                TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        }
        Test.stopTest();

        List<PpiResult__c> ppiResults =
            new PpiResultSelector().getAllForSurveyVersionIds(
                new Set<Id> {testSurvey.testSurveyVersion.Id}
            );
        System.assertEquals(1, ppiResults.size());
        System.assertEquals(12, ppiResults[0].Age__c);
    }

    static testMethod void testGeneratePpiScoresComplete() {
        TestSurveyData testSurvey =
            TestSurveyData.createFullPpiTemplate();
        String xml =
        '<?xml version=\'1.0\' ?><data id="' + testSurvey.testSurveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<new_section><name>' + 
            testSurvey.getSection(1).Name + '</name>' +
                '<'+ testSurvey.getQuestion(1, 0).Name +'>' +
                    testSurvey.getOption(1, 0, 0).Id +
                '</'+ testSurvey.getQuestion(1, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 1).Name +'>' +
                    '3' +
                '</'+ testSurvey.getQuestion(1, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 2).Name +'>' +
                    '4' +
                '</'+ testSurvey.getQuestion(1, 2).Name +'>' +
                '<'+ testSurvey.getQuestion(1, 3).Name +'>' +
                    Datetime.newInstanceGMT(2000, 01, 02, 00, 00, 00) +
                '</'+ testSurvey.getQuestion(1, 3).Name +'>' +
            '</new_section>' +
            '<new_section><name>' +
            testSurvey.getSection(2).Name + '</name>' +
                '<'+ testSurvey.getQuestion(2, 0).Name +'>' +
                testSurvey.getOption(2, 0, 0).Id + '</'+ testSurvey.getQuestion(2, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 1).Name +'>' +
                testSurvey.getOption(2, 1, 0).Id + '</'+ testSurvey.getQuestion(2, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 2).Name +'>' +
                testSurvey.getOption(2, 2, 0).Id + '</'+ testSurvey.getQuestion(2, 2).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 3).Name +'>' +
                testSurvey.getOption(2, 3, 0).Id + '</'+ testSurvey.getQuestion(2, 3).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 4).Name +'>' +
                testSurvey.getOption(2, 4, 0).Id + '</'+ testSurvey.getQuestion(2, 4).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 5).Name +'>' +
                testSurvey.getOption(2, 5, 0).Id + '</'+ testSurvey.getQuestion(2, 5).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 6).Name +'>' +
                testSurvey.getOption(2, 6, 0).Id + '</'+ testSurvey.getQuestion(2, 6).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 7).Name +'>' +
                testSurvey.getOption(2, 7, 0).Id + '</'+ testSurvey.getQuestion(2, 7).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 8).Name +'>' +
                testSurvey.getOption(2, 8, 0).Id + '</'+ testSurvey.getQuestion(2, 8).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 9).Name +'>' +
                testSurvey.getOption(2, 9, 0).Id + '</'+ testSurvey.getQuestion(2, 9).Name +'>'+
            '</new_section>' +
        '</data>';

        Test.startTest();
        TestUtils.Surveyor surveyor = initMobileUser();
        System.runAs(surveyor.partnerUser) {
            Submission submissionInstance =
                TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        }
        Test.stopTest();

        List<PpiResult__c> ppiResults =
            new PpiResultSelector().getAllForSurveyVersionIds(
                new Set<Id> {testSurvey.testSurveyVersion.Id}
            );
        System.assertEquals(1, ppiResults.size());

        List<SubmissionPpiAssociation__c> submissionPpiAssociations =
            new SubmissionPpiAssociationSelector().getForPpiResult(
                new Set<String> {ppiResults[0].Id}
            );

        System.assert(submissionPpiAssociations != null);
        System.assertEquals(1, submissionPpiAssociations.size());
        assertDemographicSubmission(testSurvey, ppiResults[0]);
        assertPpiSubmission(testSurvey, ppiResults[0]);
        System.assertEquals(10, ppiResults[0].PpiScore__c);
    }

    static testMethod void testGeneratePpiScoresPartial() {
        TestSurveyData testSurvey =
            TestSurveyData.createFullPpiTemplate();
        String xml =
        '<?xml version=\'1.0\' ?><data id="' + testSurvey.testSurveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<new_section><name>' + 
            testSurvey.getSection(1).Name + '</name>' +
                '<'+ testSurvey.getQuestion(1, 0).Name +'>' +
                testSurvey.getOption(1, 0, 0).Id + '</'+
                testSurvey.getQuestion(1, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 2).Name +'>' +
                '4' + '</'+ testSurvey.getQuestion(1, 2).Name +'>' +
                '<'+ testSurvey.getQuestion(1, 3).Name +'>' +
                Datetime.newInstanceGMT(2000, 01, 02, 00, 00, 00) +
                '</'+ testSurvey.getQuestion(1, 3).Name +'>' +
            '</new_section>' +
            '<new_section><name>' +
            testSurvey.getSection(2).Name + '</name>' +
                '<'+ testSurvey.getQuestion(2, 1).Name +'>' +
                testSurvey.getOption(2, 1, 0).Id + '</'+
                testSurvey.getQuestion(2, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 2).Name +'>' +
                testSurvey.getOption(2, 2, 0).Id + '</'+
                testSurvey.getQuestion(2, 2).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 5).Name +'>' +
                testSurvey.getOption(2, 5, 0).Id + '</'+
                testSurvey.getQuestion(2, 5).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 6).Name +'>' +
                testSurvey.getOption(2, 6, 0).Id + '</'+
                testSurvey.getQuestion(2, 6).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 8).Name +'>' +
                testSurvey.getOption(2, 8, 0).Id + '</'+
                testSurvey.getQuestion(2, 8).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 9).Name +'>' +
                testSurvey.getOption(2, 9, 0).Id + '</'+
                testSurvey.getQuestion(2, 9).Name +'>'+
            '</new_section>' +
        '</data>';

        Test.startTest();
        TestUtils.Surveyor surveyor = initMobileUser();
        Submission submissionInstance =
            TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        Test.stopTest();

        List<PpiResult__c> ppiResults =
            new PpiResultSelector().getAllForSurveyVersionIds(
                new Set<Id> {testSurvey.testSurveyVersion.Id}
            );
        System.assertEquals(1, ppiResults.size());

        List<SubmissionPpiAssociation__c> submissionPpiAssociations =
            new SubmissionPpiAssociationSelector().getForPpiResult(
                new Set<String> {ppiResults[0].Id}
            );

        System.assert(submissionPpiAssociations != null);
        System.assertEquals(1, submissionPpiAssociations.size());
        assertPpiSubmission(testSurvey, ppiResults[0]);
        System.assertEquals(6, ppiResults[0].PpiScore__c);
    }

    /**
     * Test method to verify ppi Score is generated correctly after moving the Ppi question's
     * to other sections and adding new single select question in PpiSection
     */
    static testMethod void testGeneratePpiScoresForChangedPositionOfPpiQuestions() {
        TestSurveyData testSurvey =
            TestSurveyData.createFullPpiTemplate();
        System.assert(testSurvey != null, 'Survey data could not be created properly.');

        // Create new section
        Question__c additionalSection = QuestionDOTest.createSection(4, 'Additional Section');
        additionalSection.Survey__c = testSurvey.testSurvey.Id;
        System.assert(additionalSection != null, 'Section question could not be created.');

        QuestionDO questionDoInstance = new QuestionDO();
        questionDoInstance.addRecord(additionalSection);
        questionDoInstance.insertRecords();
        System.assert(questionDoInstance.records.size() == 1);
        System.assert(questionDoInstance.records[0].Id != null);
        testSurvey.addQuestion(additionalSection);

        // Move 3rd question to new section
        Question__c questionToMove = testSurvey.getQuestion(2, 3);
        questionToMove.Parent__c = additionalSection.Id;
        questionToMove.Position__c = 1;
        questionDoInstance = new QuestionDO();
        questionDoInstance.addRecord(questionToMove);
        questionDoInstance.updateRecords();
        System.assert(questionDoInstance.records.size() == 1);
        System.assert(questionDoInstance.records[0].Id != null);

        testSurvey.addToQuestionMap(questionToMove);

        // Add additional Single select question in Ppi Section
        Question__c ppiSection = testSurvey.getSection(2);
        Question__c singleSelectTypeQuestion =
            QuestionDOTest.createQuestion(
                QuestionDO.TYPE_RADIO,
                'TestQuestion',
                'Testquestion',
                4
            );
        singleSelectTypeQuestion.Parent__c = ppiSection.Id;
        singleSelectTypeQuestion.Survey__c = testSurvey.testSurvey.Id;

        questionDoInstance = new QuestionDO();
        questionDoInstance.addRecord(singleSelectTypeQuestion);
        questionDoInstance.insertRecords();
        System.assert(questionDoInstance.records.size() == 1);
        System.assert(questionDoInstance.records[0].Id != null);

        List<Option__c> options =
            OptionDomainTest.createOptionsForQuestions(
                new List<Question__c> {(Question__c) questionDoInstance.records[0]},
                'option_',
                'option_',
                2
            );
        OptionDomain optionDomainInstance = new OptionDomain();
        optionDomainInstance.addRecords(options);
        optionDomainInstance.insertRecords();
        System.assert(optionDomainInstance.records.size() == 2);
        System.assert(optionDomainInstance.records[0].Id != null);
        System.assert(optionDomainInstance.records[1].Id != null);

        testSurvey.addToQuestionMap(singleSelectTypeQuestion);
        testSurvey.optionMap.put(singleSelectTypeQuestion.Id, optionDomainInstance.records);

        String xml =
        '<?xml version=\'1.0\' ?><data id="' + testSurvey.testSurveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<new_section><name>' + 
            testSurvey.getSection(1).Name + '</name>' +
                '<'+ testSurvey.getQuestion(1, 0).Name +'>' +
                    testSurvey.getOption(1, 0, 0).Id +
                '</'+ testSurvey.getQuestion(1, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 1).Name +'>' +
                    '3' +
                '</'+ testSurvey.getQuestion(1, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 2).Name +'>' +
                    '4' +
                '</'+ testSurvey.getQuestion(1, 2).Name +'>' +
                '<'+ testSurvey.getQuestion(1, 3).Name +'>' +
                    Datetime.newInstanceGMT(2000, 01, 02, 00, 00, 00) +
                '</'+ testSurvey.getQuestion(1, 3).Name +'>' +
            '</new_section>' +
            '<new_section><name>' +
            testSurvey.getSection(2).Name + '</name>' +
                '<'+ testSurvey.getQuestion(2, 0).Name +'>' +
                testSurvey.getOption(2, 0, 0).Id + '</'+ testSurvey.getQuestion(2, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 1).Name +'>' +
                testSurvey.getOption(2, 1, 0).Id + '</'+ testSurvey.getQuestion(2, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 2).Name +'>' +
                testSurvey.getOption(2, 2, 0).Id + '</'+ testSurvey.getQuestion(2, 2).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 10).Name +'>' +
                testSurvey.getOption(2, 10, 0).Id + '</'+ testSurvey.getQuestion(2, 10).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 4).Name +'>' +
                testSurvey.getOption(2, 4, 0).Id + '</'+ testSurvey.getQuestion(2, 4).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 5).Name +'>' +
                testSurvey.getOption(2, 5, 0).Id + '</'+ testSurvey.getQuestion(2, 5).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 6).Name +'>' +
                testSurvey.getOption(2, 6, 0).Id + '</'+ testSurvey.getQuestion(2, 6).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 7).Name +'>' +
                testSurvey.getOption(2, 7, 0).Id + '</'+ testSurvey.getQuestion(2, 7).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 8).Name +'>' +
                testSurvey.getOption(2, 8, 0).Id + '</'+ testSurvey.getQuestion(2, 8).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 9).Name +'>' +
                testSurvey.getOption(2, 9, 0).Id + '</'+ testSurvey.getQuestion(2, 9).Name +'>'+
            '</new_section>' +
            '<new_section><name>' +
            testSurvey.getSection(3).Name + '</name>' +
            '<'+ testSurvey.getQuestion(3, 0).Name +'>' +
                testSurvey.getOption(3, 0, 0).Id + '</'+ testSurvey.getQuestion(3, 0).Name +'>'+
            '</new_section>' +
        '</data>';

        Test.startTest();
        TestUtils.Surveyor surveyor = initMobileUser();
        System.runAs(surveyor.partnerUser) {
            Submission submissionInstance =
                TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        }
        Test.stopTest();

        List<PpiResult__c> ppiResults =
            new PpiResultSelector().getAllForSurveyVersionIds(
                new Set<Id> {testSurvey.testSurveyVersion.Id}
            );
        System.assertEquals(1, ppiResults.size());

        List<SubmissionPpiAssociation__c> submissionPpiAssociations =
            new SubmissionPpiAssociationSelector().getForPpiResult(
                new Set<String> {ppiResults[0].Id}
            );

        System.assert(submissionPpiAssociations != null);
        System.assertEquals(1, submissionPpiAssociations.size());
        assertDemographicSubmission(testSurvey, ppiResults[0]);
        assertPpiSubmission(testSurvey, ppiResults[0]);
        System.assertEquals(10, ppiResults[0].PpiScore__c);
    }

    /**
     * Test method to verify ppi Score is generated correctly after moving the Ppi question's
     * to other sections and adding new single select question in PpiSection with partial submission
     */
    static testMethod void testGeneratePpiScoresForChangedQuestionPosition_PartialSubmission() {

        TestSurveyData testSurvey =
            TestSurveyData.createFullPpiTemplate();
        System.assert(testSurvey != null, 'Survey data could not be created properly.');

        // Create new section
        Question__c additionalSection = QuestionDOTest.createSection(4, 'Additional Section');
        additionalSection.Survey__c = testSurvey.testSurvey.Id;
        System.assert(additionalSection != null, 'Section question could not be created.');

        QuestionDO questionDoInstance = new QuestionDO();
        questionDoInstance.addRecord(additionalSection);
        questionDoInstance.insertRecords();
        System.assert(questionDoInstance.records.size() == 1);
        System.assert(questionDoInstance.records[0].Id != null);
        testSurvey.addQuestion(additionalSection);

        // Move 2nd question to new section
        Question__c questionToMove = testSurvey.getQuestion(2, 2);
        questionToMove.Parent__c = additionalSection.Id;
        questionToMove.Position__c = 1;
        questionDoInstance = new QuestionDO();
        questionDoInstance.addRecord(questionToMove);
        questionDoInstance.updateRecords();
        System.assert(questionDoInstance.records.size() == 1);
        System.assert(questionDoInstance.records[0].Id != null);

        testSurvey.addToQuestionMap(questionToMove);

        // Add additional Single select question in Ppi Section
        Question__c ppiSection = testSurvey.getSection(2);
        Question__c singleSelectTypeQuestion =
            QuestionDOTest.createQuestion(
                QuestionDO.TYPE_RADIO,
                'TestQuestion',
                'Testquestion',
                3
            );
        singleSelectTypeQuestion.Parent__c = ppiSection.Id;
        singleSelectTypeQuestion.Survey__c = testSurvey.testSurvey.Id;

        questionDoInstance = new QuestionDO();
        questionDoInstance.addRecord(singleSelectTypeQuestion);
        questionDoInstance.insertRecords();
        System.assert(questionDoInstance.records.size() == 1);
        System.assert(questionDoInstance.records[0].Id != null);

        List<Option__c> options =
            OptionDomainTest.createOptionsForQuestions(
                new List<Question__c> {(Question__c) questionDoInstance.records[0]},
                'option_',
                'option_',
                2
            );
        OptionDomain optionDomainInstance = new OptionDomain();
        optionDomainInstance.addRecords(options);
        optionDomainInstance.insertRecords();
        System.assert(optionDomainInstance.records.size() == 2);
        System.assert(optionDomainInstance.records[0].Id != null);
        System.assert(optionDomainInstance.records[1].Id != null);

        testSurvey.addToQuestionMap(singleSelectTypeQuestion);
        testSurvey.optionMap.put(singleSelectTypeQuestion.Id, optionDomainInstance.records);

        String xml =
        '<?xml version=\'1.0\' ?><data id="' + testSurvey.testSurveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<new_section><name>' + 
            testSurvey.getSection(1).Name + '</name>' +
                '<'+ testSurvey.getQuestion(1, 0).Name +'>' +
                testSurvey.getOption(1, 0, 0).Id + '</'+
                testSurvey.getQuestion(1, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 2).Name +'>' +
                '4' + '</'+ testSurvey.getQuestion(1, 2).Name +'>' +
                '<'+ testSurvey.getQuestion(1, 3).Name +'>' +
                Datetime.newInstanceGMT(2000, 01, 02, 00, 00, 00) +
                '</'+ testSurvey.getQuestion(1, 3).Name +'>' +
            '</new_section>' +
            '<new_section><name>' +
            testSurvey.getSection(2).Name + '</name>' +
                '<'+ testSurvey.getQuestion(2, 1).Name +'>' +
                testSurvey.getOption(2, 1, 0).Id + '</'+
                testSurvey.getQuestion(2, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 10).Name +'>' +
                testSurvey.getOption(2, 10, 0).Id + '</'+
                testSurvey.getQuestion(2, 10).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 5).Name +'>' +
                testSurvey.getOption(2, 5, 0).Id + '</'+
                testSurvey.getQuestion(2, 5).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 6).Name +'>' +
                testSurvey.getOption(2, 6, 0).Id + '</'+
                testSurvey.getQuestion(2, 6).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 8).Name +'>' +
                testSurvey.getOption(2, 8, 0).Id + '</'+
                testSurvey.getQuestion(2, 8).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 9).Name +'>' +
                testSurvey.getOption(2, 9, 0).Id + '</'+
                testSurvey.getQuestion(2, 9).Name +'>'+
            '</new_section>' +
            '<new_section><name>' +
            testSurvey.getSection(3).Name + '</name>' +
            '<'+ testSurvey.getQuestion(3, 0).Name +'>' +
            testSurvey.getOption(3, 0, 0).Id + '</'+ testSurvey.getQuestion(3, 0).Name +'>'+
            '</new_section>' +
        '</data>';

        Test.startTest();
        TestUtils.Surveyor surveyor = initMobileUser();
        Submission submissionInstance =
            TestUtils.submitNewSubmission(xml, surveyor.loginResult);
        Test.stopTest();

        List<PpiResult__c> ppiResults =
            new PpiResultSelector().getAllForSurveyVersionIds(
                new Set<Id> {testSurvey.testSurveyVersion.Id}
            );
        System.assertEquals(1, ppiResults.size());

        List<SubmissionPpiAssociation__c> submissionPpiAssociations =
            new SubmissionPpiAssociationSelector().getForPpiResult(
                new Set<String> {ppiResults[0].Id}
            );

        System.assert(submissionPpiAssociations != null);
        System.assertEquals(1, submissionPpiAssociations.size());
        assertPpiSubmission(testSurvey, ppiResults[0]);
        System.assertEquals(6, ppiResults[0].PpiScore__c);
    }

    static void assertDemographicSubmission(
            TestSurveyData testSurvey,
            PpiResult__c ppiResult
    ) {
        System.assertEquals(
            testSurvey.getOption(1, 0, 0).Caption__c,
            ppiResult.Gender__c
        );
        System.assertEquals(
            3,
            ppiResult.Age__c
        );
        System.assertEquals(
            4,
            ppiResult.HouseholdSize__c
        );
        System.assertEquals(
            Datetime.newInstanceGMT(2000, 01, 02, 00, 00, 00),
            ppiResult.JoinedDate__c
        );
    }

    static void assertPpiSubmission(
            TestSurveyData testSurvey,
            PpiResult__c ppiResult
    ) {
        List<Schema.PicklistEntry> picklistEntries = DescribeHandler.getFieldPicklist(
                Question__c.getSObjectType().getDescribe().getName(),
                Question__c.PpiResultsField__c.getDescribe().getName()
        );
        for (Integer count = 0; count < picklistEntries.size(); count++) {
            if (picklistEntries[count].getValue().contains('answer')) {
                if (testSurvey.getOption(2, count, 0) != null) {
                    System.assertEquals(
                        testSurvey.getOption(2, count, 0).Id,
                        ppiResult.get(picklistEntries[count].getValue())
                    );
                } else {
                    System.assertEquals(null, ppiResult.get(picklistEntries[count].getValue()));
                }
            }
        }
    }
}