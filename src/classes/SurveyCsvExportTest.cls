/*
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*/
@isTest
private class SurveyCsvExportTest {

    /**
     * Wrapper class to hold the survey data being tested
     */
    class TestData {
        public String[] xml;
        public String expected;
        public Id surveyId;
    }

    private static User gmtUser;

    /**
     * This method prepares the data for tests to validate the generated csv
     */
    public static TestData prepareData(TestUtils.Surveyor loggedContact, Boolean testDoubleQuotes) {
        gmtUser = TestUtils.createPartnerUserNotInserted();
        gmtUser.TimezonesIdKey = 'GMT';

        //PREPARING THE DATA FOR THE TEST
        Survey__c survey = new Survey__c(Name='Survey');
        insert survey;
        Question__c qSection = new Question__c(Survey__c=survey.Id, Name='qsect', Caption__c= 'SECTIONNN',Type__c = QuestionDO.TYPE_SECTION);
        insert qSection;
        Question__c q0 = new Question__c(Parent__c= qSection.Id,Survey__c=survey.Id, Name='qstat', Caption__c= 'Static Content',Type__c = QuestionDO.TYPE_STATIC,Position__c=1);
        Question__c qfinal = new Question__c(Parent__c= qSection.Id,Survey__c=survey.Id, Name='qfinal', Caption__c= 'final',Type__c = QuestionDO.TYPE_FINAL,Position__c=2);
        Question__c q1 = new Question__c(Parent__c= qSection.Id,Survey__c=survey.Id, Name='qshrt', Caption__c= 'Age',Type__c = QuestionDO.TYPE_TEXT_SHORT,Position__c=3);
        Question__c q2 = new Question__c(Parent__c= qSection.Id,Survey__c=survey.Id, Name='qlong', Caption__c= 'Last Name',Type__c = QuestionDO.TYPE_TEXT_LONG,Position__c=4);
        Question__c q3 = new Question__c(Parent__c= qSection.Id,Survey__c=survey.Id, Name='qchkx', Caption__c= 'select some',Type__c = QuestionDO.TYPE_CHECKBOX,Position__c=5);
        Question__c q4 = new Question__c(Parent__c= qSection.Id,Survey__c=survey.Id, Name='qnum', Caption__c= 'number',Type__c = QuestionDO.TYPE_NUMBER,Position__c=6);
        Question__c q5 = new Question__c(Parent__c= qSection.Id,Survey__c=survey.Id, Name='qdate', Caption__c= 'date',Type__c = QuestionDO.TYPE_DATE,Position__c=7 );
        Question__c qstatic = new Question__c(Parent__c= qSection.Id,Survey__c=survey.Id, Name='qstatic', Caption__c= 'static',Type__c = QuestionDO.TYPE_STATIC,Position__c=8 );
        Question__c q6 = new Question__c(Parent__c= qSection.Id,Survey__c=survey.Id, Name='qdateTime', Caption__c= 'dateTime',Type__c = QuestionDO.TYPE_DATETIME,Position__c=9);
        insert new Question__c[]{q0,qfinal,q1,q2,q3,q4,q5,qstatic,q6};

        Option__c opA = new Option__c(Name= 'option A',Caption__c='option A',Question__c = q3.Id,Position__c=1);
        Option__c opB = new Option__c(Name= 'option B',Caption__c='option B',Question__c = q3.Id,Position__c=2);
        List<Option__c> options= new List<Option__c>{opA,opB};
        insert options;
        Contact ctc = new Contact(LastName = 'Robert', mobileSurveys_Id__c='ab12');
        insert ctc;
        ctc = [select Id, Name, mobileSurveys_Id__c from Contact where Id = :ctc.Id];
        qSection = [select name from Question__c where id=:qSection.Id][0];

        ScoringGroup__c sGroup = new ScoringGroup__c(Caption__c = 'score1', Survey__c = survey.Id);
        insert sGroup;
        ScoreValue__c sValue1 = new ScoreValue__c(Option__c = opA.Id, ScoringGroup__c = sGroup.Id, Value__c = 1);
        ScoreValue__c sValue2 = new ScoreValue__c(Option__c = opB.Id, ScoringGroup__c = sGroup.Id, Value__c = 2);
        insert new ScoreValue__c[]{sValue1, sValue2};

        SurveyVersion__c surveyVersion = [select Status__c from SurveyVersion__c where Survey__c =:survey.Id];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;
        TestData result = new TestData();

        // XML 1
        result.xml = new String[]{};
        for(integer i=0;i<3;i++){
            result.xml.add('<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + survey.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid />'+
            '<simid />'+
            '<phonenumber />'+
            '<' + qSection.Name + '>' +
                '<'+ q0.Name +' />' +
                '<'+ q1.Name +'>2'+ i +(testDoubleQuotes ? '";TestOtherCharacters' : '') +'</'+ q1.Name +'>'+
                '<'+ q2.Name +'>Martin</'+ q2.Name +'>'+
                '<'+ q3.Name +'>' + opA.Id + ' ' + OpB.Id + ' </'+ q3.Name +'>'+
                '<'+ q4.Name + '>' + 10 + '</' + q4.Name + '>' +
                '<'+ q5.Name + '>' + '2012-02-14' + '</' + q5.Name + '>' +
                '<'+ q6.Name + '>' + '2012-02-14T19:23:53.463' + '</' + q6.Name + '>' +
            '</' + qSection.Name + '>' +
        '</'+ survey.Name + '>');
        }

         result.expected =
        '"startDate","endDate","Date","gps x","gps y","Surveyor",' +
        '"' + q1.Name + '",' +
        '"' + q2.Name + '",' +
        '"' + q3.Name + '",' +
        '"' + q4.Name + '",' +
        '"' + q5.Name + '",' +
        '"' + q6.Name + '",' +
        '"' + sGroup.Caption__c + '",' + '\n' +
        '"' + '2012-02-14 19:23:53+0000' + '",' + '"' + '2012-02-14 19:24:40+0000' + '",' +
        '"2012-02-14",' +
        '"","","'+ loggedContact.theContact.Name + '","20'+ (testDoubleQuotes ? '"";TestOtherCharacters",' : '",')+
        '"Martin","' + opA.Caption__c + ';' + OpB.Caption__c + '",' + '"10",'+ '"2012-02-14",'+ '"2012-02-14 19:23:53.463",' + '3,' + '\n';

        result.surveyId = survey.Id;
        return result;
    }

    /**
     * 1887
     * Prepare the data for test repeated questions.
     * Insert the questions to answer, set the answer xml and the survey to export the csv.
     *
     * @param loggedContact - The surveyor who is submitting the surveys
     * @param moreThanOne   - Indicates more than one submission to be made
     *
     * @return - The data to conduct the test with
     */
    public static TestData prepareDataForRepeated(TestUtils.Surveyor loggedContact, Boolean moreThanOneSubmission) {

        gmtUser = TestUtils.createPartnerUserNotInserted();
        gmtUser.TimezonesIdKey = 'GMT';

        // PREPARING THE DATA FOR THE TEST OF REPEATED QUESTIONS

        Survey__c survey = new Survey__c(Name = 'SurveyWithRepeat');
        insert survey;

        Question__c sectionRepeat1 = new Question__c(
            Survey__c   = survey.Id,
            Name        = 'repeat1',
            Caption__c  = 'section repeated',
            Type__c     = QuestionDO.TYPE_REPEAT,
            Position__c = 1);

        Question__c sectionRepeat2 = new Question__c(
            Survey__c   = survey.Id,
            Name        = 'repeat2',
            Caption__c  = 'section repeated',
            Type__c     = QuestionDO.TYPE_REPEAT,
            Position__c = 2);

        // Insert Section repeat
        insert new List<Question__c>{sectionRepeat1, sectionRepeat2};

        // First Repeated Section
        Question__c qshrt1 = new Question__c(
            Parent__c   = sectionRepeat1.Id,
            Survey__c   = survey.Id,
            Name        = 'qshrt1',
            Caption__c  = 'Name',
            Type__c     = QuestionDO.TYPE_TEXT_SHORT,
            Position__c = 1);

        Question__c qshrt2 = new Question__c(
            Parent__c   = sectionRepeat1.Id,
            Survey__c   = survey.Id,
            Name        = 'qshrt2',
            Caption__c  = 'Last_Name',
            Type__c     = QuestionDO.TYPE_TEXT_SHORT,
            Position__c = 2);

        Question__c qchkx1 = new Question__c(
            Parent__c   = sectionRepeat1.Id,
            Survey__c   = survey.Id,
            Name        = 'qchkx1',
            Caption__c  = 'select some',
            Type__c     = QuestionDO.TYPE_CHECKBOX,
            Position__c = 3);

        Question__c qnum1 = new Question__c(
            Parent__c   = sectionRepeat1.Id,
            Survey__c   = survey.Id,
            Name        = 'qnum1',
            Caption__c  = 'number',
            Type__c     = QuestionDO.TYPE_NUMBER,
            Position__c = 4);

        Question__c qdate1 = new Question__c(
            Parent__c   = sectionRepeat1.Id,
            Survey__c   = survey.Id,
            Name        = 'qdate1',
            Caption__c  = 'date',
            Type__c     = QuestionDO.TYPE_DATE,
            Position__c = 5);

        Question__c qstatic1 = new Question__c(
            Parent__c   = sectionRepeat1.Id,
            Survey__c   = survey.Id,
            Name        = 'qstatic1',
            Caption__c  = 'static',
            Type__c     = QuestionDO.TYPE_STATIC,
            Position__c = 6);

        Question__c qdateTime1 = new Question__c(
            Parent__c   = sectionRepeat1.Id,
            Survey__c   = survey.Id,
            Name        = 'qdateTime1',
            Caption__c  = 'dateTime',
            Type__c     = QuestionDO.TYPE_DATETIME,
            Position__c = 7);

        // Second Repeated Section
        Question__c qshrt3 = new Question__c(
            Parent__c   = sectionRepeat2.Id,
            Survey__c   = survey.Id,
            Name        = 'qshrt3',
            Caption__c  = 'Name',
            Type__c     = QuestionDO.TYPE_TEXT_SHORT,
            Position__c = 1);

        Question__c qshrt4 = new Question__c(
            Parent__c   = sectionRepeat2.Id,
            Survey__c   = survey.Id,
            Name        = 'qshrt4',
            Caption__c  = 'Last_Name',
            Type__c     = QuestionDO.TYPE_TEXT_SHORT,
            Position__c = 2);

        Question__c qchkx2 = new Question__c(
            Parent__c   = sectionRepeat2.Id,
            Survey__c   = survey.Id,
            Name        = 'qchkx2',
            Caption__c  = 'select some',
            Type__c     = QuestionDO.TYPE_CHECKBOX,
            Position__c = 3);

        Question__c qnum2 = new Question__c(
            Parent__c   = sectionRepeat2.Id,
            Survey__c   =survey.Id,
            Name        = 'qnum2',
            Caption__c  = 'number',
            Type__c     = QuestionDO.TYPE_NUMBER,
            Position__c = 4);

        Question__c qdate2 = new Question__c(
            Parent__c   = sectionRepeat2.Id,
            Survey__c   = survey.Id,
            Name        = 'qdate2',
            Caption__c  = 'date',
            Type__c     = QuestionDO.TYPE_DATE,
            Position__c = 5);

        Question__c qstatic2 = new Question__c(
            Parent__c   = sectionRepeat2.Id,
            Survey__c   = survey.Id,
            Name        = 'qstatic2',
            Caption__c  = 'static',
            Type__c     = QuestionDO.TYPE_STATIC,
            Position__c = 6);

        Question__c qdateTime2 = new Question__c(
            Parent__c   = sectionRepeat2.Id,
            Survey__c   = survey.Id,
            Name        = 'qdateTime2',
            Caption__c  = 'dateTime',
            Type__c     = QuestionDO.TYPE_DATETIME,
            Position__c = 7);

        // Insert questions
        insert new List<Question__c>{
            qshrt1, qshrt2, qshrt3, qshrt4, qchkx1,
            qchkx2, qnum1, qnum2, qdate1, qdate2,
            qstatic1, qstatic2, qdateTime1, qdateTime2
        };

        Option__c opA1 = new Option__c(
            Name        = 'option A1',
            Caption__c  = 'option A1',
            Question__c = qchkx1.Id,
            Position__c = 1);

        Option__c opB1 = new Option__c(
            Name        = 'option B1',
            Caption__c  = 'option B1',
            Question__c = qchkx1.Id,
            Position__c = 2);

        Option__c opA2 = new Option__c(
            Name        = 'option A2',
            Caption__c  = 'option A2',
            Question__c = qchkx2.Id,
            Position__c = 1);

        Option__c opB2 = new Option__c(
            Name        = 'option B2',
            Caption__c  = 'option B2',
            Question__c = qchkx2.Id,
            Position__c = 2);

        //Insert options
        insert new List<Option__c>{opA1,opA2,opB1,opB2};

        // Create contact
        Contact ctc = new Contact(LastName = 'Robert', mobileSurveys_Id__c='ab12');
        insert ctc;

        ctc = [SELECT Id, Name, mobileSurveys_Id__c FROM Contact WHERE Id = :ctc.Id];

        // Set status to published
        SurveyVersion__c surveyVersion = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id];
        surveyVersion.Status__c = SurveyDO.STATUS_PUBLISHED;
        update surveyVersion;

        TestData result = new TestData();

        //XML 1
        result.xml = new String[]{};

        // answer1 xml
        result.xml.add( '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + survey.Id + '">'+
                            '<start>2012-02-14T19:23:53.463</start>'+
                            '<end>2012-02-14T19:24:40.816</end>'+
                            '<today>2012-02-14</today>'+
                            '<deviceid />'+
                            '<simid />'+
                            '<phonenumber />'+
                            '<' + sectionRepeat1.Name + '>' +
                               '<'+ qshrt1.Name +'>Lottar</'+ qshrt1.Name +'>'+
                               '<'+ qshrt2.Name +'>Mathaus</'+ qshrt2.Name +'>'+
                               '<'+ qchkx1.Name +'>' + opA1.Id + ' ' + OpB1.Id + '</'+ qchkx1.Name +'>'+
                               '<'+ qnum1.Name +'>' + 1 + '</'+ qnum1.Name +'>'+
                               '<'+ qdate1.Name +'>2012-02-14</'+ qdate1.Name +'>'+
                               '<'+ qdateTime1.Name +'>2012-02-14T19:23:53.463</'+ qdateTime1.Name +'>'+
                            '</' + sectionRepeat1.Name + '>' +
                            '<' + sectionRepeat1.Name + '>' +
                               '<'+ qshrt1.Name +'>Edwin</'+ qshrt1.Name +'>'+
                               '<'+ qshrt2.Name +'>Vandersar</'+ qshrt2.Name +'>'+
                               '<'+ qchkx1.Name +'>' + opA1.Id + '</'+ qchkx1.Name +'>'+
                               '<'+ qnum1.Name +'>' + 2 + '</'+ qnum1.Name +'>'+
                               '<'+ qdate1.Name +'>2012-02-15</'+ qdate1.Name +'>'+
                               '<'+ qdateTime1.Name +'>2012-02-15T19:23:53.463</'+ qdateTime1.Name +'>'+
                            '</' + sectionRepeat1.Name + '>' +
                            '<' + sectionRepeat2.Name + '>' +
                               '<'+ qshrt3.Name +'>Bryan</'+ qshrt3.Name +'>'+
                               '<'+ qshrt4.Name +'>Laudrup</'+ qshrt4.Name +'>'+
                               '<'+ qchkx2.Name +'>' + opA2.Id + ' ' + OpB2.Id + '</'+ qchkx2.Name +'>'+
                               '<'+ qnum2.Name +'>' + 1 + '</'+ qnum2.Name +'>'+
                               '<'+ qdate2.Name +'>2012-02-14</'+ qdate2.Name +'>'+
                               '<'+ qdateTime2.Name +'>2012-02-14T19:23:53.463</'+ qdateTime2.Name +'>'+
                            '</' + sectionRepeat2.Name + '>' +
                            '<' + sectionRepeat2.Name + '>' +
                               '<'+ qshrt3.Name +'>Rud</'+ qshrt3.Name +'>'+
                               '<'+ qshrt4.Name +'>Gullit</'+ qshrt4.Name +'>'+
                               '<'+ qchkx2.Name +'>' + opA2.Id + '</'+ qchkx2.Name +'>'+
                               '<'+ qnum2.Name +'>' + 2 + '</'+ qnum2.Name +'>'+
                               '<'+ qdate2.Name +'>2012-02-15</'+ qdate2.Name +'>'+
                               '<'+ qdateTime2.Name +'>2012-02-15T19:23:53.463</'+ qdateTime2.Name +'>'+
                            '</' + sectionRepeat2.Name + '>' +
                        '</'+ survey.Name + '>');

        // answer2 xml
        result.xml.add( '<?xml version=\'1.0\' ?><'+ survey.Name + ' id="' + survey.Id + '">'+
                            '<start>2012-02-14T19:23:53.463</start>'+
                            '<end>2012-02-14T19:24:40.816</end>'+
                            '<today>2012-02-14</today>'+
                            '<deviceid />'+
                            '<simid />'+
                            '<phonenumber />'+
                            '<' + sectionRepeat1.Name + '>' +
                               '<'+ qshrt1.Name +'></'+ qshrt1.Name +'>'+
                               '<'+ qshrt2.Name +'>Mathaus</'+ qshrt2.Name +'>'+
                               '<'+ qchkx1.Name +'>' + opA1.Id + ' ' + OpB1.Id + '</'+ qchkx1.Name +'>'+
                               '<'+ qnum1.Name +'>' + 1 + '</'+ qnum1.Name +'>'+
                               '<'+ qdate1.Name +'>2012-02-14</'+ qdate1.Name +'>'+
                               '<'+ qdateTime1.Name +'>2012-02-14T19:23:53.463</'+ qdateTime1.Name +'>'+
                            '</' + sectionRepeat1.Name + '>' +
                            '<' + sectionRepeat1.Name + '>' +
                               '<'+ qshrt1.Name +'>Edwin</'+ qshrt1.Name +'>'+
                               '<'+ qshrt2.Name +'>Vandersar</'+ qshrt2.Name +'>'+
                               '<'+ qchkx1.Name +'></'+ qchkx1.Name +'>'+
                               '<'+ qnum1.Name +'>' + 2 + '</'+ qnum1.Name +'>'+
                               '<'+ qdate1.Name +'>2012-02-15</'+ qdate1.Name +'>'+
                               '<'+ qdateTime1.Name +'>2012-02-15T19:23:53.463</'+ qdateTime1.Name +'>'+
                            '</' + sectionRepeat1.Name + '>' +
                            '<' + sectionRepeat2.Name + '>' +
                               '<'+ qshrt3.Name +'>Bryan</'+ qshrt3.Name +'>'+
                               '<'+ qshrt4.Name +'>Laudrup</'+ qshrt4.Name +'>'+
                               '<'+ qchkx2.Name +'>' + opA2.Id + ' ' + OpB2.Id + '</'+ qchkx2.Name +'>'+
                               '<'+ qnum2.Name +'>' + 1 + '</'+ qnum2.Name +'>'+
                               '<'+ qdate2.Name +'></'+ qdate2.Name +'>'+
                               '<'+ qdateTime2.Name +'>2012-02-14T19:23:53.463</'+ qdateTime2.Name +'>'+
                            '</' + sectionRepeat2.Name + '>' +
                            '<' + sectionRepeat2.Name + '>' +
                               '<'+ qshrt3.Name +'>Rud</'+ qshrt3.Name +'>'+
                               '<'+ qshrt4.Name +'></'+ qshrt4.Name +'>'+
                               '<'+ qchkx2.Name +'>' + opA2.Id + '</'+ qchkx2.Name +'>'+
                               '<'+ qnum2.Name +'>' + 2 + '</'+ qnum2.Name +'>'+
                               '<'+ qdate2.Name +'>2012-02-15</'+ qdate2.Name +'>'+
                               '<'+ qdateTime2.Name +'>2012-02-15T19:23:53.463</'+ qdateTime2.Name +'>'+
                            '</' + sectionRepeat2.Name + '>' +
                        '</'+ survey.Name + '>');
        if(moreThanOneSubmission){
            result.expected =
                        // Csv result expected for two submissions
                        '"startDate","endDate","Date","gps x","gps y","Surveyor",' +
                        '"' + qshrt1.Name     + '_1' + '",' +
                        '"' + qshrt1.Name     + '_2' + '",' +
                        '"' + qshrt2.Name     + '_1' + '",' +
                        '"' + qshrt2.Name     + '_2' + '",' +
                        '"' + qchkx1.Name     + '_1' + '",' +
                        '"' + qchkx1.Name     + '_2' + '",' +
                        '"' + qnum1.Name      + '_1' + '",' +
                        '"' + qnum1.Name      + '_2' + '",' +
                        '"' + qdate1.Name     + '_1' + '",' +
                        '"' + qdate1.Name     + '_2' + '",' +
                        '"' + qdateTime1.Name + '_1' + '",' +
                        '"' + qdateTime1.Name + '_2' + '",' +
                        '"' + qshrt3.Name     + '_1' + '",' +
                        '"' + qshrt3.Name     + '_2' + '",' +
                        '"' + qshrt4.Name     + '_1' + '",' +
                        '"' + qshrt4.Name     + '_2' + '",' +
                        '"' + qchkx2.Name     + '_1' + '",' +
                        '"' + qchkx2.Name     + '_2' + '",' +
                        '"' + qnum2.Name      + '_1' + '",' +
                        '"' + qnum2.Name      + '_2' + '",' +
                        '"' + qdate2.Name     + '_1' + '",' +
                        '"' + qdate2.Name     + '_2' + '",' +
                        '"' + qdateTime2.Name + '_1' + '",' +
                        '"' + qdateTime2.Name + '_2' + '",' +'\n' +
                        '"' + '2012-02-14 19:23:53+0000' + '",' + '"' + '2012-02-14 19:24:40+0000' + '",' +
                        '"2012-02-14",' +
                        '"","","'+ loggedContact.theContact.Name + '"' +
                        ',"Lottar","Edwin","Mathaus","Vandersar",' +
                        '"' + opA1.Caption__c + ';' + OpB1.Caption__c + '","' + opA1.Caption__c + '",' +
                        '"1","2","2012-02-14","2012-02-15","2012-02-14 19:23:53.463","2012-02-15 19:23:53.463",' +
                        '"Bryan","Rud","Laudrup","Gullit",' +
                        '"' + opA2.Caption__c + ';' + OpB2.Caption__c + '","' + opA2.Caption__c + '",' +
                        '"1","2","2012-02-14","2012-02-15","2012-02-14 19:23:53.463","2012-02-15 19:23:53.463",' + '\n'+
                        '"' + '2012-02-14 19:23:53+0000' + '",' + '"' + '2012-02-14 19:24:40+0000' + '",' +
                        '"2012-02-14",' +
                        '"","","'+ loggedContact.theContact.Name + '"'+
                        ',,"Edwin","Mathaus","Vandersar",' +
                        '"' + opA1.Caption__c + ';' + OpB1.Caption__c + '",,' +
                        '"1","2","2012-02-14","2012-02-15","2012-02-14 19:23:53.463","2012-02-15 19:23:53.463",' +
                        '"Bryan","Rud","Laudrup",,' +
                        '"' + opA2.Caption__c + ';' + OpB2.Caption__c + '","' + opA2.Caption__c + '",' +
                        '"1","2",,"2012-02-15","2012-02-14 19:23:53.463","2012-02-15 19:23:53.463",' + '\n';
        }else{
            result.expected =
                        // Csv result expected for one submission
                        '"startDate","endDate","Date","gps x","gps y","Surveyor",' +
                        '"' + qshrt1.Name     + '_1' + '",' +
                        '"' + qshrt1.Name     + '_2' + '",' +
                        '"' + qshrt2.Name     + '_1' + '",' +
                        '"' + qshrt2.Name     + '_2' + '",' +
                        '"' + qchkx1.Name     + '_1' + '",' +
                        '"' + qchkx1.Name     + '_2' + '",' +
                        '"' + qnum1.Name      + '_1' + '",' +
                        '"' + qnum1.Name      + '_2' + '",' +
                        '"' + qdate1.Name     + '_1' + '",' +
                        '"' + qdate1.Name     + '_2' + '",' +
                        '"' + qdateTime1.Name + '_1' + '",' +
                        '"' + qdateTime1.Name + '_2' + '",' +
                        '"' + qshrt3.Name     + '_1' + '",' +
                        '"' + qshrt3.Name     + '_2' + '",' +
                        '"' + qshrt4.Name     + '_1' + '",' +
                        '"' + qshrt4.Name     + '_2' + '",' +
                        '"' + qchkx2.Name     + '_1' + '",' +
                        '"' + qchkx2.Name     + '_2' + '",' +
                        '"' + qnum2.Name      + '_1' + '",' +
                        '"' + qnum2.Name      + '_2' + '",' +
                        '"' + qdate2.Name     + '_1' + '",' +
                        '"' + qdate2.Name     + '_2' + '",' +
                        '"' + qdateTime2.Name + '_1' + '",' +
                        '"' + qdateTime2.Name + '_2' + '",' +'\n' +
                        '"' + '2012-02-14 19:23:53+0000' + '",' + '"' + '2012-02-14 19:24:40+0000' + '",' +
                        '"2012-02-14",' +
                        '"","","'+ loggedContact.theContact.Name + '",' +
                        '"Lottar","Edwin","Mathaus","Vandersar",' +
                        '"' + opA1.Caption__c + ';' + OpB1.Caption__c + '","' + opA1.Caption__c + '",' + +
                        '"1","2","2012-02-14","2012-02-15","2012-02-14 19:23:53.463","2012-02-15 19:23:53.463",' +
                        '"Bryan","Rud","Laudrup","Gullit",' +
                        '"' + opA2.Caption__c + ';' + OpB2.Caption__c + '","' + opA2.Caption__c + '",' +
                        '"1","2","2012-02-14","2012-02-15","2012-02-14 19:23:53.463","2012-02-15 19:23:53.463",' + '\n';
        }
        result.surveyId = survey.Id;
        return result;
    }

    /**
     * 1887
     * Validate the csv export of the repeated sections with one submission,
     * and with all questions answered
     */
    static testMethod void validateCsvRepeatedOneSubmission(){

        // PERFORMING THE TEST
        // Create contact
        TestUtils.Surveyor loggedContact = TestUtils.createSurveyor(
            'lastNameSCET',
            'userSCET',
            'passSCET',
            MobileUserDo.STATUS_ACTIVE,
            true
        );

        // Data of the repeated questions
        TestData data = prepareDataForRepeated(loggedContact, false);

        // Make the submission
        Submission sub = TestUtils.submitNewSubmission(data.xml[0], loggedContact.loginResult);

        Test.startTest();
        System.runAs(gmtUser) {

            // Export the csv
            SurveyCsvExport csvCreator = new SurveyCsvExport();
            PageReference downpagePage = Page.downloadCsv;
            Test.setCurrentPage(downpagePage);

            ApexPages.currentPage().getParameters().put('surveyId',data.surveyId);

            // Validate that the expected result is the exported csv
            System.assertEquals(data.expected, csvCreator.getCsvString());
        }
        Test.stopTest();
    }

    /**
     * 1887
     * Validate the csv export of the repeated sections with more than 1 submissions,
     * and with no anwered questions
     */
    static testMethod void validateCsvRepeatedSomeSubmissions(){

        //PERFORMING THE TEST
        // Create contact
        TestUtils.Surveyor loggedContact = TestUtils.createSurveyor(
            'lastNameSCET',
            'userSCET',
            'passSCET',
            MobileUserDo.STATUS_ACTIVE,
            true
        );

        // Data of the repeated questions
        TestData data = prepareDataForRepeated(loggedContact, true);

        // Make the submission
        TestUtils.submitNewSubmission(data.xml[0], loggedContact.loginResult);

        // Make second submission
        TestUtils.submitNewSubmission(data.xml[1], loggedContact.loginResult);

        Test.startTest();
        System.runAs(gmtUser) {

            // Export the csv
            SurveyCsvExport csvCreator = new SurveyCsvExport();
            PageReference downpagePage = Page.downloadCsv;
            Test.setCurrentPage(downpagePage);

            ApexPages.currentPage().getParameters().put('surveyId',data.surveyId);
            system.assertEquals(data.expected, csvCreator.getCsvString());
        }
        Test.stopTest();
    }

    /**
     * Test for a single case of csv Creation
     */
    static testMethod void exportAllSubmissions() {

        //PERFORMING THE TEST
        TestUtils.Surveyor loggedContact = TestUtils.createSurveyor(
            'lastNameSCET',
            'userSCET',
            'passSCET',
            MobileUserDo.STATUS_ACTIVE,
            true
        );

        TestData data = prepareData(loggedContact, false);

        TestUtils.submitNewSubmission(data.xml[0], loggedContact.loginResult);

        Test.startTest();
        System.runAs(gmtUser){
            SurveyCsvExport csvCreator = new SurveyCsvExport();
            PageReference downpagePage = Page.downloadCsv;
            Test.setCurrentPage(downpagePage);
            ApexPages.currentPage().getParameters().put('surveyId',data.surveyId);
            system.assertEquals(data.expected, csvCreator.getCsvString());
        }
        Test.stopTest();
    }

    /**
     * Test for a single case of csv Creation with the " character in text answers, the character should be escaped
     */
     static testMethod void exportDataFailCharacter() {

        //PERFORMING THE TEST
        TestUtils.Surveyor loggedContact = TestUtils.createSurveyor(
            'lastNameSCET',
            'userSCET',
            'passSCET',
            MobileUserDo.STATUS_ACTIVE,
            true
        );
        TestData data = prepareData(loggedContact, true);

        Test.startTest();
        User taroworksUser = TestUtils.generateTaroworksUser();
        taroworksUser.TimezonesIdKey = 'GMT';
        update taroworksUser;

        System.runAs(taroworksUser) {
            ServicesController sc = new ServicesController();
            TestUtils.submitNewSubmission(data.xml[0], loggedContact.loginResult);
            SurveyCsvExport csvCreator = new SurveyCsvExport();
            PageReference downpagePage = Page.downloadCsv;
            Test.setCurrentPage(downpagePage);
            ApexPages.currentPage().getParameters().put('surveyId', data.surveyId);
            System.assertEquals(data.expected, csvCreator.getCsvString());
        }
        Test.stopTest();
     }

    static testMethod void exportSelectedSubmissions() {

        // Add license to create new ppi surveys
        LicenseSettings__c license = C.getLicense();
        license.UsePPI__c = true;
        update license;

        // PERFORMING THE TEST
        TestUtils.Surveyor loggedContact = TestUtils.createSurveyor(
            'lastNameSCET',
            'userSCET',
            'passSCET',
            MobileUserDo.STATUS_ACTIVE,
            true
        );

        TestData data = prepareData(loggedContact, false);

        // Submit three times, but I'm only going to export two of them
        ServicesController sc = new ServicesController();
        for(String xml : data.xml) {
            TestUtils.submitNewSubmission(xml, loggedContact.loginResult);
        }
        Submission__c[] submissions = [select Id,survey__c,
                                            startDate__c ,
                                            endDate__c,
                                            Date__c,
                                            gps_x__c,
                                            gps_y__c,
                                            surveyor__c, surveyor__r.Name
                                            from Submission__c where Survey__c = :data.surveyId];
        system.assertEquals(3, submissions.size());

        Test.startTest();
        SurveyCsvExport csvCreator = new SurveyCsvExport();
        PageReference downpagePage = Page.downloadCsv;
        Test.setCurrentPage(downpagePage);
        ApexPages.currentPage().getParameters().put('selectedSurveysAnswerId',submissions[0].Id + ',' + submissions[1].Id);

        // Assert the result only has three lines (1 header + 2 rows)
        system.assertEquals(3, csvCreator.getCsvString().split('\n',0).size());
        Test.stopTest();
     }

     // Test that PPI probabilities are correctly exported to last columns of CSV file.
     static testMethod void exportSumissionsWithPPIScores(){

        // Add license to create new ppi surveys
        TestUtils.updatePpiLicenseSettings();

        TestUtils.Surveyor loggedContact = TestUtils.createSurveyor(
            'lastNameSCET',
            'userSCET',
            'passSCET',
            MobileUserDo.STATUS_ACTIVE,
            true
        );

        // Prepare survey
        TestUtils.insertCountry('AA', 'Test');
        TestUtils.insertLanguage('XX', 'XXLanguage');

        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate(
            TestUtils.insertLanguage('XX', 'XXLanguage'),
            TestUtils.insertCountry('AA', 'Test'),
            2010
        );

        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(new Set<String> {survey.Id});

        System.assert(
            surveyVersions.size() > 0,
            'Survey Version records not created properly'
        );

        PPITable__c ppiTable = PpiTableDomainTest.createPpiTable('Test PPI Table');
        PpiTableDomain ppiTableDomainInstance = new PpiTableDomain();
        ppiTableDomainInstance.addRecord(ppiTable);
        ppiTableDomainInstance.insertRecords();
        System.assert(ppiTableDomainInstance.records.size() == 1);
        System.assert(ppiTableDomainInstance.records[0].Id != null);

        PPITableDataSet__c ppiTableDataSet = PpiTableDataSetDomainTest.createPpiTableDataSet();
        ppiTableDataSet.PPITable__c = ppiTable.Id;
        ppiTableDataSet.Survey__c = survey.Id;
        ppiTableDataSet.SurveyVersion__c = surveyVersions[0].Id;
        PpiTableDataSetDomain ppiDataSetDomain = new PpiTableDataSetDomain();
        ppiDataSetDomain.addRecord(ppiTableDataSet);
        ppiDataSetDomain.insertRecords();
        System.assert(ppiDataSetDomain.records.size() == 1);
        System.assert(ppiDataSetDomain.records[0].Id != null);

        PPITableLine__c line = PpiTableLineDomainTest.createPpiTableLine(10, 50.0, '', 14);
        line.PPITableDataSet__c = ppiDataSetDomain.records[0].Id;
        PpiTableLineDomain ppiTableLineDomainInstance = new PpiTableLineDomain();
        ppiTableLineDomainInstance.addRecord(line);
        ppiTableLineDomainInstance.insertRecords();
        System.assert(ppiTableLineDomainInstance.records.size() == 1);
        System.assert(ppiTableLineDomainInstance.records[0].Id != null);

        // Inserting Section, Question and options
        Question__c section = QuestionDOTest.createSection(1, 'section');
        section.Caption__c = 'SECTIONTEST';
        section.Survey__c = survey.Id;
        section.RemoteServerId__c = 'Test Id';
        QuestionDO questionDomain = new QuestionDO();
        questionDomain.addRecord(section);
        questionDomain.insertRecords();
        System.assert(questionDomain.records.size() == 1);
        System.assert(questionDomain.records[0].Id != null);

        Question__c question = 
            QuestionDOTest.createQuestion(
                QuestionDO.TYPE_CHECKBOX,
                'CheckBoxQuestion',
                'select some',
                1
            );
        question.Survey__c = survey.Id;
        question.Parent__c = questionDomain.records[0].Id;
        question.RemoteServerId__c = 'Test Id';
        questionDomain = new QuestionDO();
        questionDomain.addRecord(question);
        questionDomain.insertRecords();
        System.assert(questionDomain.records.size() == 1);
        System.assert(questionDomain.records[0].Id != null);

        Option__c option = 
            OptionDomainTest.createRecord(
                'option',
                (Question__c) questionDomain.records[0],
                1
            );
        option.PPIScore__c = 11;
        OptionDomain optionDomainInstance = new OptionDomain();
        optionDomainInstance.addRecord(option);
        optionDomainInstance.insertRecords();
        System.assert(optionDomainInstance.records.size() == 1);
        System.assert(optionDomainInstance.records[0].Id != null);

        // Updating version
        surveyVersions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        SurveyVersionDomain surveyVersionDomainInstance = new SurveyVersionDomain();
        surveyVersionDomainInstance.addRecord(surveyVersions[0]);
        surveyVersionDomainInstance.updateRecords();
        System.assert(surveyVersionDomainInstance.records.size() == 1);
        System.assert(surveyVersionDomainInstance.records[0].Id != null);
        System.assertEquals(SurveyDO.STATUS_PUBLISHED, surveyVersions[0].Status__c);

        TestData result = new TestData();
        result.xml = new String[]{};

        String validSurveyName = survey.Name.replace(' ', '_');
        result.xml.add('<?xml version=\'1.0\' ?><'+ validSurveyName + ' id="' + survey.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid />'+
            '<simid />'+
            '<phonenumber />'+
            '<' + section.Name + '>' +
                '<'+ question.Name +'>' + option.Id + ' </'+ question.Name +'>'+
            '</' + section.Name + '>' +
        '</'+ validSurveyName + '>');

        result.expected =
            '"startDate","endDate","Date","gps x","gps y","Surveyor",' +
            '"' + question.Name + '",' +
            '"PPI Score",'+
            '"' + ppiTable.Name + '",' + '\n' +
            '"' + '2012-02-14 19:23:53+0000' + '",' + '"' + '2012-02-14 19:24:40+0000' + '",' +
            '"2012-02-14",' +
            '"","","' + loggedContact.theContact.Name + '",'+
            '"' + option.Caption__c + '",'+ '11,'+ '50.0,' + '\n';

        result.surveyId = survey.Id;

        gmtUser = TestUtils.createPartnerUserNotInserted();
        gmtUser.TimezonesIdKey = 'GMT';
        Test.startTest();
        System.runAs(gmtUser) {
            ServicesController sc = new ServicesController();
            TestUtils.submitNewSubmission(result.xml[0], loggedContact.loginResult);
            SurveyCsvExport csv = new SurveyCsvExport();
            PageReference downloadCsvPage = Page.downloadCsv;
            Test.setCurrentPage(downloadCsvPage);
            ApexPages.currentPage().getParameters().put('surveyId', result.surveyId);
            System.assertEquals(result.expected, csv.getCsvString());
        }
        Test.stopTest();
    }
}
