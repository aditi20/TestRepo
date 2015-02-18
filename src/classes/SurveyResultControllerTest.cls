/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
private class SurveyResultControllerTest {
//
//    static Question__c newQuestion(Survey__c survey, Question__c parent, String type, String name, String caption, Integer position){
//        return new Question__c(Survey__c = survey.Id, Parent__c = (parent != null ? parent.Id : null), Type__c = type, Name = name, Caption__c = caption, Position__c = position);
//    }
//
//    static Option__c newOption(Question__c question, String name,Decimal ppiScore, Integer position){
//        return new Option__c(Question__c = question.Id, Name = name, Caption__c = name, PPIScore__c = ppiScore, Position__c = position);
//    }
//
//    static Submission__c newSubmission(Survey__c survey, DateTime startdate, Contact surveyor, Contact interviewee){
//        return new Submission__c(Survey__c = survey.Id, StartDate__c = startdate, Surveyor__c = surveyor.Id, Interviewee__c = interviewee.Id);
//    }
//
//    static Answer__c newTextAnswer(Submission__c sanswer, Question__c question, String value, Integer instance){
//        return new Answer__c(Submission__c = sanswer.Id, Question__c = question.Id,
//            Value__c = value, TextAreaValue__c = value, Instance__c = instance);
//    }
//
//    static Answer__c newBarcodeAnswer(Submission__c sanswer, Question__c question, String value, Integer instance){
//        return new Answer__c(Submission__c = sanswer.Id, Question__c = question.Id,
//            Value__c = value, TextAreaValue__c = value, Instance__c = instance);
//    }
//
//    static Answer__c newOptionAnswer(Submission__c sanswer, Question__c question, Option__c option, Integer instance){
//        return new Answer__c(Submission__c = sanswer.Id, Question__c = question.Id, Value__c = option.Caption__c,
//            TextAreaValue__c = option.Caption__c, Option__c = option.Id, Instance__c = instance);
//    }
//
//    static Answer__c newDateAnswer(Submission__c sanswer, Question__c question, Date value, Integer instance){
//        return new Answer__c(Submission__c = sanswer.Id, Question__c = question.Id,
//            Value__c = String.valueOf(value), DateValue__c = value, Instance__c = instance);
//    }
//
//    static Answer__c newDateTimeAnswer(Submission__c sanswer, Question__c question, DateTime value, Integer instance){
//        return new Answer__c(Submission__c = sanswer.Id, Question__c = question.Id,
//            Value__c = String.valueOf(value), DateTimeValue__c = value, Instance__c = instance);
//    }
//
//    static Answer__c newNumberAnswer(Submission__c sanswer, Question__c question, Decimal value, Integer instance){
//        return new Answer__c(Submission__c = sanswer.Id, Question__c = question.Id,
//            Value__c = String.valueOf(value), NumericValue__c = value, Instance__c = instance);
//    }
//
//    /**
//     * Test that results are shown for large surveys.
//     * Precondition: Have a large survey (100 questions) with large data (1000 submissions)
//     * Assert that all answers are present.
//     */
//    static testMethod void testLargeSurvey(){
//        final Integer NR_OF_QUESTIONS = 60;
//        final Integer NR_OF_SUBMISSION = 130;
//
//        Contact alice = new Contact(FirstName = 'Alice', LastName = 'Alice'); // To use as surveyor
//        Contact bob   = new Contact(FirstName = 'Bob'  , LastName = 'Bob');   // To use as interviewee
//        insert new Contact[]{alice,bob};
//
//        // Create a large survey
//        Survey__c survey = new Survey__c(Name='survey');
//        insert survey;
//
//        Question__c section = new Question__c(
//            Survey__c=survey.Id,Name=QuestionDO.TYPE_SECTION,
//            Type__c=QuestionDO.TYPE_SECTION,Position__c=1);
//        insert section;
//
//        Question__c[] questions = new Question__c[]{};
//        for(Integer i = 1; i <= NR_OF_QUESTIONS; i++)
//            questions.add( newQuestion(survey,section,QuestionDO.TYPE_TEXT_SHORT,'q'+i,'q'+i,i) );
//        insert questions;
//
//        SurveyDO.updateSurveysStatus(new List <Survey__c> {survey}, SurveyDO.STATUS_PUBLISHED);
//
//        // Create submissions
//        Submission__c[] submissions = new Submission__c[]{};
//        for(Integer i = 1; i <= NR_OF_SUBMISSION; i++)
//            submissions.add( new Submission__c( Survey__c = survey.Id,
//                                                StartDate__c = DateTime.now().addMinutes(i*2 - 1000),
//                                                Surveyor__c = alice.Id,
//                                                Interviewee__c = bob.Id)
//            );
//        insert submissions;
//        submissions = [SELECT Id FROM Submission__c WHERE Id IN :submissions]; // Free some memory
//
//        Answer__c[] answers = new Answer__c[]{};
//        for(Submission__c submission : submissions){
//            for(Integer i = 1; i <= NR_OF_QUESTIONS; i++){
//                answers.add( new Answer__c( Submission__c = submission.Id,
//                                            Question__c = questions[i-1].Id,
//                                            TextAreaValue__c = 'a' + i,
//                                            Value__c = submission.Id + 'a' + i)
//                );
//            }
//        }
//        insert answers;
//        answers.clear(); // Free some memory
//
//        SurveyResultController.SubmissionRow[] rows = new SurveyResultController.SubmissionRow[]{};
//
//        // Test the page
//        Test.startTest();
//        Test.setCurrentPage( Page.SurveyResult );
//        ApexPages.currentPage().getParameters().put( 'id', survey.Id );
//        SurveyResultController controller = new SurveyResultController();
//
//        do{
//            ApexPages.currentPage().getParameters().put( 'skipn', String.valueOf( rows.size() ) );
//            controller.fetchMoreRows();
//            rows.addAll(controller.submissionRows);
//        } while (controller.moreRows);
//
//        Test.stopTest();
//
//        // Assert that all submissions have all data
//        final Integer NON_QUESTION_CELLS = 4; // Number of cells at the beginning of each row that do not belong to actual questions
//        system.assertEquals(NR_OF_SUBMISSION, rows.size());
//        for(SurveyResultController.SubmissionRow row : rows){
//            // We'll just assert that the last question of each submission must be filled
//            system.assertEquals(row.submissionId + 'a' + NR_OF_QUESTIONS, row.cells[NON_QUESTION_CELLS + NR_OF_QUESTIONS -1].stringValue, 'Row ' + row.cells[0].stringValue);
//        }
//    }
//
//    // Create a survey with questions of every kind.
//    // Create a couple of survey answers.
//    // Make sure all questions are answered in at least one survey, and unanswered in at least one survey.
//    // Check that the columns and rows were created correctly.
//    static testMethod void testSurveyParsing(){
//
//        Contact alice   = new Contact(FirstName = 'Alice'  , LastName = 'Alice');
//        Contact bob     = new Contact(FirstName = 'Bob'    , LastName = 'Bob');
//        Contact charlie = new Contact(FirstName = 'Charlie', LastName = 'Charlie');
//        insert new Contact[]{alice, bob, charlie};
//
//        //Prepare survey
//        insert new ISO_Country__c(Name='AA',ShortName__c='Test');
//
//        insert new Language__c(Name = 'XX',ShortLanguageName__c = 'XXLanguage');
//
//        LicenseSettings__c license = C.getLicense();
//        license.PPI_Editable__c = true;
//        license.UsePPI__c = true;
//        update license;
//
//        Survey__c survey = new Survey__c(IsPPI__c=true, CountryCode__c='AA', LanguageCode__c='XX', PPIDataYear__c = 2103);
//        insert survey;
//
//        //Inserting lookup tables, data sets and lines
//        PPITable__c tableTest1 = new PPITable__c(Name = 'Table_Test1');
//        insert tableTest1;
//
//        PPITable__c tableTest2 = new PPITable__c(Name = 'Table_Test2');
//        insert tableTest2;
//
//        PPITableDataSet__c dataSetTableTest1 = new PPITableDataSet__c(Survey__c = survey.Id, PPITable__c = tableTest1.Id);
//        insert dataSetTableTest1;
//
//        PPITableDataSet__c dataSetTableTest2 = new PPITableDataSet__c(Survey__c = survey.Id, PPITable__c = tableTest2.Id);
//        insert dataSetTableTest2;
//
//        List<PPITableLine__c> lines = new List<PPITableLine__c>();
//        for(Integer i = 1; i < 10; i++){
//            lines.add(new PPITableLine__c(PPITableDataSet__c = dataSetTableTest1.Id, From__c = i*5, To__c = (i*5)+4, Probability__c = i*5));
//        }
//        for(Integer i=1; i< 10; i++){
//            lines.add(new PPITableLine__c(PPITableDataSet__c = dataSetTableTest2.Id, From__c = i*5, To__c = (i*5)+4, Probability__c = i*6));
//        }
//        insert lines;
//
//        //Inserting Sections
//        Question__c sec1 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
//        Question__c sec2 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2);
//        insert new Question__c[]{sec1, sec2};
//
//        // Prepare a question of each type
//        Question__c stext = newQuestion(survey, sec1, QuestionDO.TYPE_TEXT_SHORT, 'text-short', 'text-short', 1);
//        Question__c qfinal = newQuestion(survey, sec1, QuestionDO.TYPE_FINAL, 'final','end of survey',2);
//        Question__c numbr = newQuestion(survey, sec1, QuestionDO.TYPE_NUMBER, 'number', 'number', 3);
//        Question__c dateq = newQuestion(survey, sec2, QuestionDO.TYPE_DATE, 'date-date', 'date-date', 1);
//        Question__c timeq = newQuestion(survey, sec2, QuestionDO.TYPE_DATETIME, 'date-datetime', 'date-datetime', 2);
//        Question__c radio = newQuestion(survey, sec2, QuestionDO.TYPE_RADIO, 'radio', 'radio', 3);
//        Question__c qstatic = newQuestion(survey, sec2, QuestionDO.TYPE_STATIC, 'static','end of survey',4);
//        Question__c chkbx = newQuestion(survey, sec2, QuestionDO.TYPE_CHECKBOX, 'checkbox', 'checkbox', 5);
//
//        insert new Question__c[]{stext, numbr, dateq, timeq, radio, chkbx,qfinal,qstatic};
//
//        Option__c radio1 = newOption(radio, 'radio-1', 5, 1);
//        Option__c radio2 = newOption(radio, 'radio-2', 10, 2);
//        Option__c radio3 = newOption(radio, 'radio-3', 15, 3);
//        Option__c chkbx1 = newOption(chkbx, 'chkbx-1', null, 1);
//        Option__c chkbx2 = newOption(chkbx, 'chkbx-2', null, 2);
//        Option__c chkbx3 = newOption(chkbx, 'chkbx-3', null, 3);
//        insert new Option__c[]{radio1, radio2, radio3, chkbx1, chkbx2, chkbx3};
//
//        //Insert a couple of submissions
//        Submission__c sans1 = newSubmission(survey, Date.valueOf('2011-01-01'), alice, bob);
//        sans1.PPIScore__c = radio1.PPIScore__c + radio2.PPIScore__c + radio3.PPIScore__c;
//        Submission__c sans2 = newSubmission(survey, Date.valueOf('2011-01-02'), alice, charlie);
//        Submission__c sans3 = newSubmission(survey, Date.valueOf('2011-01-03'), alice, charlie); // will be left empty
//        insert new Submission__c[]{sans1, sans2, sans3};
//        //Checking the PPIScore
//        system.assertEquals(30,sans1.PPIScore__c);
//
//        Answer__c[] sans1Ans = new Answer__c[]{
//            newTextAnswer(sans1, stext, 'stext', null),
//            newNumberAnswer(sans1, numbr, 30, null)
//        };
//        Answer__c[] sans2Ans = new Answer__c[]{
//            newTextAnswer(sans2, stext, 'stext', null),
//            newDateAnswer(sans2, dateq, Date.valueOf('2011-01-01'), null),
//            newDateTimeAnswer(sans2, timeq, DateTime.valueOf('2011-01-01 10:00:00'), null),
//            newOptionAnswer(sans2, chkbx, chkbx1, null),
//            newOptionAnswer(sans2, chkbx, chkbx2, null)
//        };
//           insert sans1Ans;
//           insert sans2Ans;
//        ScoringGroup__c[] sGs = new  ScoringGroup__c[]{
//            new ScoringGroup__c(Survey__c = survey.Id,Caption__c = 'ScoreGroup1'),
//            new ScoringGroup__c(Survey__c = survey.Id,Caption__c = 'ScoreGroup2'),
//            new ScoringGroup__c(Survey__c = survey.Id,Caption__c = 'ScoreGroup3')
//        };
//        insert  sGs;
//        insert new ScoreValue__c[]{
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=100,Option__c = radio1.id),
//            new ScoreValue__c(ScoringGroup__c = sGs[1].Id, Value__c=1000,Option__c = radio2.id)
//        };
//        Answer__c qAns = newOptionAnswer(sans1, radio, radio1, null);
//        insert qAns;
//        insert new SubmissionScore__c(ScoringGroup__c = sGs[0].Id,Submission__c = sans1.Id,TotalScore__c = 100);
//
//        lines = [select Id, PPITableDataSet__c, To__c, From__c, Probability__c from PPITableLine__c where (PPITableDataSet__c = :dataSetTableTest1.Id or PPITableDataSet__c = :dataSetTableTest2.Id)  and (From__c <= :sans1.PPIScore__c and To__c >= :sans1.PPIScore__c)];
//
//        //Inserting associated lines to the submission ppiScore
//        List<SubmissionPPIValue__c> linesAssociated = new List<SubmissionPPIValue__c>();
//        for(PPITableLine__c line : lines){
//             linesAssociated.add(new SubmissionPPIValue__c(Submission__c = sans1.Id, PPITableLine__c = line.Id));
//        }
//        insert linesAssociated;
//
//        test.startTest();
//
//        ApexPages.currentPage().getParameters().put( 'id', survey.Id );
//        SurveyResultController controller = new SurveyResultController();
//        ApexPages.currentPage().getParameters().put( 'skipn', '0' );
//        controller.fetchMoreRows();
//
//        test.stopTest();
//        system.assertEquals( 4 + 6 + sGs.size() + linesAssociated.size() + 1, controller.columnHeaders.size()); // 4 fixed columns, 6 questions, 1 ScoreGroups, 1 line associated, 1 ppi score
//
//        SurveyResultController.SubmissionRow[] rows = controller.submissionRows;
//        system.assertEquals( 3, rows.size() );
//
//        system.assertEquals( 4 + 6 + sGs.size() + linesAssociated.size() + 1, rows[0].cells.size() );
//        system.assertEquals( Date.valueOf('2011-01-01'), rows[0].cells[1].datetimeValue );
//        system.assertEquals( 'Alice Alice', rows[0].cells[2].stringValue );
//        system.assertEquals( 'Bob Bob', rows[0].cells[3].stringValue );
//        system.assertEquals( 'stext', rows[0].cells[4].stringValue );
//        system.assertEquals( 30, rows[0].cells[5].numericValue );
//        system.assertEquals( null, rows[0].cells[6].dateValue );        system.assertEquals( '', rows[0].cells[6].stringValue );
//        system.assertEquals( null, rows[0].cells[7].dateTimeValue );   system.assertEquals( '', rows[0].cells[7].stringValue );
//        system.assertEquals( 'radio-1', rows[0].cells[8].stringValue );
//        system.assertEquals( '', rows[0].cells[9].stringValue );
//        system.assertEquals( 100, rows[0].cells[10].numericValue );
//        system.assertEquals( null, rows[0].cells[11].numericValue );
//        system.assertEquals( lines[0].Probability__c ,rows[0].cells[13].numericValue);
//        system.assertEquals( lines[1].Probability__c ,rows[0].cells[15].numericValue);
//
//        system.assertEquals( 4 + 6 + sGs.size() + linesAssociated.size() + 1, rows[1].cells.size() );
//        system.assertEquals( Date.valueOf('2011-01-02'), rows[1].cells[1].datetimeValue );
//        system.assertEquals( 'Alice Alice', rows[1].cells[2].stringValue );
//        system.assertEquals( 'Charlie Charlie', rows[1].cells[3].stringValue );
//        system.assertEquals( 'stext', rows[1].cells[4].stringValue );
//        system.assertEquals( '', rows[1].cells[5].stringValue );
//        system.assertEquals( Date.valueOf('2011-01-01'), rows[1].cells[6].dateValue );
//        system.assertEquals( DateTime.valueOf('2011-01-01 10:00:00'), rows[1].cells[7].dateTimeValue );
//        system.assertEquals( '', rows[1].cells[8].stringValue );
//        system.assertEquals( 'chkbx-1, chkbx-2', rows[1].cells[9].stringValue );
//        system.assertEquals(null ,rows[1].cells[13].numericValue);
//        system.assertEquals(null ,rows[1].cells[14].numericValue);
//
//        system.assertEquals( 4 + 6 + sGs.size() + linesAssociated.size() + 1, rows[1].cells.size() );
//        system.assertEquals( Date.valueOf('2011-01-03'), rows[2].cells[1].datetimeValue );
//        system.assertEquals( 'Alice Alice', rows[2].cells[2].stringValue );
//        system.assertEquals( 'Charlie Charlie', rows[2].cells[3].stringValue );
//        system.assertEquals(null ,rows[2].cells[13].numericValue);
//        system.assertEquals(null ,rows[2].cells[14].numericValue);
//    }
//
//    /**
//    * Class to load sample data in row structure
//    */
//    private class AnswersLoader{
//
//        public String[] name;
//        public Integer[] age;
//        public Integer numPets;
//        public String [] food;
//
//        public final String GENDER_MALE = 'Male';
//        public final String GENDER_FEMALE = 'Female';
//
//        public AnswersLoader(){
//
//            name = new String [] {'Name1', 'Name2', 'Name3'};
//            food = new String [] {'Meat', 'Vegetals', 'Fruits'};
//            age = new Integer [] {1, 2, 3};
//
//            numPets = 5;
//        }
//    }
//
//
//    /**
//    * Check all cells are completly filled.
//    */
//    static testMethod void testSurveyRepeatAnswersFull(){
//
//        Contact alice   = new Contact(FirstName = 'Alice'  , LastName = 'Alice');
//        Contact bob     = new Contact(FirstName = 'Bob'    , LastName = 'Bob');
//        Contact charlie = new Contact(FirstName = 'Charlie', LastName = 'Charlie');
//        insert new Contact[]{alice, bob, charlie};
//
//        //Prepare survey
//        Survey__c survey = new Survey__c(IsPPI__c=false);
//        insert survey;
//
//        //Inserting Sections
//        Question__c sec1 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section1', 'Section 1', 1);
//        Question__c sec2 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section2', 'Section 2', 2);
//        Question__c sec3 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section3', 'Section 3', 3);
//        insert new Question__c[]{sec1, sec2, sec3};
//
//        // Prepare a question of each type
//        Question__c q_gender = newQuestion(survey, sec1, QuestionDO.TYPE_RADIO, 'radio', 'Gender', 1);
//        Question__c q_name = newQuestion(survey, sec2, QuestionDO.TYPE_TEXT_SHORT, 'text-short', 'Name of Child', 1);
//        Question__c q_age = newQuestion(survey, sec2, QuestionDO.TYPE_NUMBER, 'number', 'Age of Child', 2);
//        Question__c q_num_pets = newQuestion(survey, sec3, QuestionDO.TYPE_NUMBER, 'number', 'Number of Pets', 1);
//
//        insert new Question__c[]{q_gender, q_name, q_age, q_num_pets};
//
//        AnswersLoader answersLoader = new AnswersLoader();
//
//        Option__c radio1 = newOption(q_gender, AnswersLoader.GENDER_MALE, 10, 1);
//        Option__c radio2 = newOption(q_gender, AnswersLoader.GENDER_FEMALE, 15, 2);
//
//        insert new Option__c[]{radio1, radio2};
//
//        //Insert a couple of submissions
//        Submission__c sans1 = newSubmission(survey, Date.valueOf('2011-01-01'), alice, bob);
//
//        Submission__c sans2 = newSubmission(survey, Date.valueOf('2011-01-02'), alice, charlie);
//
//        insert new Submission__c[]{sans1, sans2};
//
//        Answer__c[] sans1Ans = new Answer__c[]{
//
//            newOptionAnswer(sans1, q_gender, radio1, null),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[0], 1),
//            newNumberAnswer(sans1, q_age, answersLoader.age[0], 1),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[1], 2),
//            newNumberAnswer(sans1, q_age, answersLoader.age[1], 2),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[2], 3),
//            newNumberAnswer(sans1, q_age, answersLoader.age[2], 3),
//
//            new Answer__c(Submission__c = sans1.Id, Question__c = sec2.Id, Instance__c = 3),
//
//            newNumberAnswer(sans1, q_num_pets, answersLoader.numPets, null)
//        };
//
//        Answer__c[] sans2Ans = new Answer__c[]{
//
//            newTextAnswer(sans2, q_name, answersLoader.name[0], 1),
//            newNumberAnswer(sans2, q_age, answersLoader.age[0], 1),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[1], 2),
//            newNumberAnswer(sans2, q_age, answersLoader.age[1], 2),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[2], 3),
//            newNumberAnswer(sans2, q_age, answersLoader.age[2], 3),
//
//            new Answer__c(Submission__c = sans2.Id, Question__c = sec2.Id, Instance__c = 3),
//
//            newNumberAnswer(sans2, q_num_pets, answersLoader.numPets, null)
//        };
//
//        insert sans1Ans;
//        insert sans2Ans;
//
//        ScoringGroup__c[] sGs = new  ScoringGroup__c[]{
//            new ScoringGroup__c(Survey__c = survey.Id,Caption__c = 'ScoreGroup1')
//        };
//        insert  sGs;
//        insert new ScoreValue__c[]{
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=10, Option__c = radio1.id),
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=15, Option__c = radio2.id)
//        };
//
//        insert new SubmissionScore__c(ScoringGroup__c = sGs[0].Id,Submission__c = sans1.Id,TotalScore__c = 3);
//
//        ApexPages.currentPage().getParameters().put( 'id', survey.Id );
//        SurveyResultController controller = new SurveyResultController();
//        ApexPages.currentPage().getParameters().put( 'skipn', '0' );
//        controller.fetchMoreRows();
//
//        //check columns of header is equal to number of column of content
//        system.assertEquals( 4 + 8 + sGs.size(), controller.columnHeaders.size()); // 4 fixed columns, 8 questions (include repeat questions), 1 ScoreGroups
//
//        SurveyResultController.SubmissionRow[] rows = controller.submissionRows;
//
//        //check there are two submissions
//        System.assertEquals( 2, rows.size() );
//
//        //for each submission
//        for (SurveyResultController.SubmissionRow row : rows){
//
//            //it has the same number of expected columns
//            System.assertEquals(controller.columnHeaders.size(), row.cells.size(), 'The column number must be tha same of table header and content.');
//
//            //for each colmun
//            for (SurveyResultController.SubmissionCell cell : row.cells){
//
//                //cell content is is full
//                Boolean hasContent =    (cell.stringValue != null) ||
//                                        (cell.dateValue != null) ||
//                                        (cell.datetimeValue != null) ||
//                                        (cell.numericValue != null);
//
//                System.assert(hasContent, 'All cell should have a content.');
//            }
//        }
//    }
//
//    /**
//    * The first row has one repeat question over 2nd.
//    * The corresponding column of table must be empty.
//    */
//    static testMethod void testSurveyRepeatAnswersEmptyCell(){
//
//        Contact alice   = new Contact(FirstName = 'Alice'  , LastName = 'Alice');
//        Contact bob     = new Contact(FirstName = 'Bob'    , LastName = 'Bob');
//        Contact charlie = new Contact(FirstName = 'Charlie', LastName = 'Charlie');
//        insert new Contact[]{alice, bob, charlie};
//
//        //Prepare survey
//
//        Survey__c survey = new Survey__c(IsPPI__c=false);
//        insert survey;
//
//        //Inserting Sections
//        Question__c sec1 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section1', 'Section 1', 1);
//        Question__c sec2 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section2', 'Section 2', 2);
//        Question__c sec3 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section3', 'Section 3', 3);
//        insert new Question__c[]{sec1, sec2, sec3};
//
//        // Prepare a question of each type
//        Question__c q_gender = newQuestion(survey, sec1, QuestionDO.TYPE_RADIO, 'radio', 'Gender', 1);
//        Question__c q_name = newQuestion(survey, sec2, QuestionDO.TYPE_TEXT_SHORT, 'text-short', 'Name of Child', 1);
//        Question__c q_age = newQuestion(survey, sec2, QuestionDO.TYPE_NUMBER, 'number', 'Age of Child', 2);
//        Question__c q_num_pets = newQuestion(survey, sec3, QuestionDO.TYPE_NUMBER, 'number', 'Number of Pets', 1);
//
//        insert new Question__c[]{q_gender, q_name, q_age, q_num_pets};
//
//        AnswersLoader answersLoader = new AnswersLoader();
//
//        Option__c radio1 = newOption(q_gender, AnswersLoader.GENDER_MALE, 10, 1);
//        Option__c radio2 = newOption(q_gender, AnswersLoader.GENDER_FEMALE, 15, 2);
//
//        insert new Option__c[]{radio1, radio2};
//
//        //Insert a couple of submissions
//        Submission__c sans1 = newSubmission(survey, Date.valueOf('2011-01-01'), alice, bob);
//
//        Submission__c sans2 = newSubmission(survey, Date.valueOf('2011-01-02'), alice, charlie);
//
//        insert new Submission__c[]{sans1, sans2};
//
//        Answer__c[] sans1Ans = new Answer__c[]{
//
//            newOptionAnswer(sans1, q_gender, radio1, null),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[0], 1),
//            newNumberAnswer(sans1, q_age, answersLoader.age[0], 1),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[1], 2),
//            newNumberAnswer(sans1, q_age, answersLoader.age[1], 2),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[2], 3),
//            newNumberAnswer(sans1, q_age, answersLoader.age[2], 3),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[2], 4),
//            newNumberAnswer(sans1, q_age, answersLoader.age[2], 4),
//
//            new Answer__c(Submission__c = sans1.Id, Question__c = sec2.Id, Instance__c = 4),
//
//            newNumberAnswer(sans1, q_num_pets, answersLoader.numPets, null)
//
//        };
//
//        Answer__c[] sans2Ans = new Answer__c[]{
//
//            newOptionAnswer(sans2, q_gender, radio2, null),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[0], 1),
//            newNumberAnswer(sans2, q_age, answersLoader.age[0], 1),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[1], 2),
//            newNumberAnswer(sans2, q_age, answersLoader.age[1], 2),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[2], 3),
//            newNumberAnswer(sans2, q_age, answersLoader.age[2], 3),
//
//            new Answer__c(Submission__c = sans2.Id, Question__c = sec2.Id, Instance__c = 3),
//
//            newNumberAnswer(sans2, q_num_pets, answersLoader.numPets, null)
//        };
//
//        insert sans1Ans;
//        insert sans2Ans;
//
//        ScoringGroup__c[] sGs = new  ScoringGroup__c[]{
//            new ScoringGroup__c(Survey__c = survey.Id,Caption__c = 'ScoreGroup1')
//        };
//        insert  sGs;
//        insert new ScoreValue__c[]{
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=10, Option__c = radio1.id),
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=15, Option__c = radio2.id)
//        };
//
//        insert new SubmissionScore__c(ScoringGroup__c = sGs[0].Id,Submission__c = sans1.Id,TotalScore__c = 3);
//
//        ApexPages.currentPage().getParameters().put( 'id', survey.Id );
//        SurveyResultController controller = new SurveyResultController();
//        ApexPages.currentPage().getParameters().put( 'skipn', '0' );
//        controller.fetchMoreRows();
//
//        //check columns of header is equal to number of column of content
//        System.assertEquals( 4 + 10 + sGs.size(), controller.columnHeaders.size()); // 4 fixed columns, 10 questions (include repeat questions), 1 ScoreGroups
//
//        //Verify empty columns
//        System.assertEquals( '', controller.submissionRows[1].cells[8].stringValue, 'This cell for name is not filled for this submission.');
//        System.assertEquals( null, controller.submissionRows[1].cells[12].numericValue, 'This cell for age is not filled for this submission.');
//
//        //check last questions is already responded.
//        System.assertNotEquals( null, controller.submissionRows[1].cells[13].numericValue, 'This cell for age is not filled for this submission.');
//    }
//
//    /**
//    * Create a repetition of question with a number of instance different among submissions.
//    * The submission that has lower instances of answers must leave blank cells.
//    */
//    static testMethod void testSurveyRepeatAnswersBarcode(){
//
//        Contact alice   = new Contact(FirstName = 'Alice'  , LastName = 'Alice');
//        Contact bob     = new Contact(FirstName = 'Bob'    , LastName = 'Bob');
//        Contact charlie = new Contact(FirstName = 'Charlie', LastName = 'Charlie');
//        insert new Contact[]{alice, bob, charlie};
//
//        //Prepare survey
//        Survey__c survey = new Survey__c(IsPPI__c=false);
//        insert survey;
//
//        //Inserting Sections
//        Question__c sec1 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section1', 'Section 1', 1);
//        Question__c sec2 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section2', 'Section 2', 2);
//        Question__c sec3 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section3', 'Section 3', 3);
//        Question__c sec4 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section4', 'Section 4', 4);
//        insert new Question__c[]{sec1, sec2, sec3, sec4};
//
//        // Prepare a question of each type
//        Question__c q_gender = newQuestion(survey, sec1, QuestionDO.TYPE_RADIO, 'radio', 'Gender', 1);
//        Question__c q_name = newQuestion(survey, sec2, QuestionDO.TYPE_TEXT_SHORT, 'text-short', 'Name of Child', 1);
//        Question__c q_age = newQuestion(survey, sec2, QuestionDO.TYPE_NUMBER, 'number', 'Age of Child', 2);
//        Question__c q_num_pets = newQuestion(survey, sec3, QuestionDO.TYPE_NUMBER, 'number', 'Number of Pets', 1);
//        Question__c q_barcode = newQuestion(survey, sec4, QuestionDO.TYPE_BARCODE, 'barcode', 'Barcode', 1);
//
//        insert new Question__c[]{q_gender, q_name, q_age, q_num_pets, q_barcode};
//
//        AnswersLoader answersLoader = new AnswersLoader();
//
//        Option__c radio1 = newOption(q_gender, AnswersLoader.GENDER_MALE, 10, 1);
//        Option__c radio2 = newOption(q_gender, AnswersLoader.GENDER_FEMALE, 15, 2);
//
//        insert new Option__c[]{radio1, radio2};
//
//        //Insert a couple of submissions
//        Submission__c sans1 = newSubmission(survey, Date.valueOf('2011-01-01'), alice, bob);
//
//        Submission__c sans2 = newSubmission(survey, Date.valueOf('2011-01-02'), alice, charlie);
//
//        insert new Submission__c[]{sans1, sans2};
//
//        Answer__c[] sans1Ans = new Answer__c[]{
//
//            newOptionAnswer(sans1, q_gender, radio1, null),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[0], 1),
//            newNumberAnswer(sans1, q_age, answersLoader.age[0], 1),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[1], 2),
//            newNumberAnswer(sans1, q_age, answersLoader.age[1], 2),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[2], 3),
//            newNumberAnswer(sans1, q_age, answersLoader.age[2], 3),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[2], 4),
//            newNumberAnswer(sans1, q_age, answersLoader.age[2], 4),
//
//            new Answer__c(Submission__c = sans1.Id, Question__c = sec2.Id, Instance__c = 4),
//
//            newNumberAnswer(sans1, q_num_pets, answersLoader.numPets, null),
//
//            newBarcodeAnswer(sans1, q_barcode, '77771', 1),
//
//            new Answer__c(Submission__c = sans1.Id, Question__c = sec4.Id, Instance__c = 1)
//
//        };
//
//        Answer__c[] sans2Ans = new Answer__c[]{
//
//            newOptionAnswer(sans2, q_gender, radio1, null),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[0], 1),
//            newNumberAnswer(sans2, q_age, answersLoader.age[0], 1),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[1], 2),
//            newNumberAnswer(sans2, q_age, answersLoader.age[1], 2),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[2], 3),
//            newNumberAnswer(sans2, q_age, answersLoader.age[2], 3),
//
//            new Answer__c(Submission__c = sans2.Id, Question__c = sec2.Id, Instance__c = 3),
//
//            newNumberAnswer(sans2, q_num_pets, answersLoader.numPets, null),
//
//            newBarcodeAnswer(sans2, q_barcode, '77771', 1),
//            newBarcodeAnswer(sans2, q_barcode, '77772', 2),
//
//            new Answer__c(Submission__c = sans2.Id, Question__c = sec4.Id, Instance__c = 2)
//        };
//
//        insert sans1Ans;
//        insert sans2Ans;
//
//        ScoringGroup__c[] sGs = new  ScoringGroup__c[]{
//            new ScoringGroup__c(Survey__c = survey.Id,Caption__c = 'ScoreGroup1')
//        };
//        insert  sGs;
//        insert new ScoreValue__c[]{
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=10, Option__c = radio1.id),
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=15, Option__c = radio2.id)
//        };
//
//        insert new SubmissionScore__c(ScoringGroup__c = sGs[0].Id,Submission__c = sans1.Id,TotalScore__c = 25);
//
//        ApexPages.currentPage().getParameters().put( 'id', survey.Id );
//        SurveyResultController controller = new SurveyResultController();
//        ApexPages.currentPage().getParameters().put( 'skipn', '0' );
//        controller.fetchMoreRows();
//
//        //check columns of header is equal to number of column of content
//        System.assertEquals( 4 + 12 + sGs.size(), controller.columnHeaders.size()); // 4 fixed columns, 12 questions (include repeat questions), 1 ScoreGroups
//
//        //Verify empty columns
//        System.assertEquals( '', controller.submissionRows[0].cells[15].stringValue, 'This cell for barcode is not filled for this submission.');
//
//        //check the same questions was answered in next sbumission
//        System.assertNotEquals( '', controller.submissionRows[1].cells[15].stringValue, 'This cell for barcode is not filled for this submission.');
//    }
//
//    /**
//    * Leave to repetition completly blank for question barcode
//    */
//    static testMethod void testSurveyRepeatAnswersBlank(){
//
//        Contact alice   = new Contact(FirstName = 'Alice'  , LastName = 'Alice');
//        Contact bob     = new Contact(FirstName = 'Bob'    , LastName = 'Bob');
//        Contact charlie = new Contact(FirstName = 'Charlie', LastName = 'Charlie');
//        insert new Contact[]{alice, bob, charlie};
//
//        //Prepare survey
//        Survey__c survey = new Survey__c(IsPPI__c=false);
//        insert survey;
//
//        //Inserting Sections
//        Question__c sec1 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section1', 'Section 1', 1);
//        Question__c sec2 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section2', 'Section 2', 2);
//        Question__c sec3 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section3', 'Section 3', 3);
//        Question__c sec4 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section4', 'Section 4', 4);
//        insert new Question__c[]{sec1, sec2, sec3, sec4};
//
//        // Prepare a question of each type
//        Question__c q_gender = newQuestion(survey, sec1, QuestionDO.TYPE_RADIO, 'radio', 'Gender', 1);
//        Question__c q_name = newQuestion(survey, sec2, QuestionDO.TYPE_TEXT_SHORT, 'text-short', 'Name of Child', 1);
//        Question__c q_age = newQuestion(survey, sec2, QuestionDO.TYPE_NUMBER, 'number', 'Age of Child', 2);
//        Question__c q_num_pets = newQuestion(survey, sec3, QuestionDO.TYPE_NUMBER, 'number', 'Number of Pets', 1);
//        Question__c q_barcode = newQuestion(survey, sec4, QuestionDO.TYPE_BARCODE, 'barcode', 'Barcode', 1);
//
//        insert new Question__c[]{q_gender, q_name, q_age, q_num_pets, q_barcode};
//
//        AnswersLoader answersLoader = new AnswersLoader();
//
//        Option__c radio1 = newOption(q_gender, AnswersLoader.GENDER_MALE, 10, 1);
//        Option__c radio2 = newOption(q_gender, AnswersLoader.GENDER_FEMALE, 15, 2);
//
//        insert new Option__c[]{radio1, radio2};
//
//        //Insert a couple of submissions
//        Submission__c sans1 = newSubmission(survey, Date.valueOf('2011-01-01'), alice, bob);
//
//        Submission__c sans2 = newSubmission(survey, Date.valueOf('2011-01-02'), alice, charlie);
//
//        insert new Submission__c[]{sans1, sans2};
//
//        Answer__c[] sans1Ans = new Answer__c[]{
//
//            newOptionAnswer(sans1, q_gender, radio1, null),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[0], 1),
//            newNumberAnswer(sans1, q_age, answersLoader.age[0], 1),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[1], 2),
//            newNumberAnswer(sans1, q_age, answersLoader.age[1], 2),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[2], 3),
//            newNumberAnswer(sans1, q_age, answersLoader.age[2], 3),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[2], 4),
//            newNumberAnswer(sans1, q_age, answersLoader.age[2], 4),
//
//            new Answer__c(Submission__c = sans1.Id, Question__c = sec2.Id, Instance__c = 4),
//
//            newNumberAnswer(sans1, q_num_pets, answersLoader.numPets, null),
//
//            new Answer__c(Submission__c = sans1.Id, Question__c = sec4.Id, Instance__c = 2)
//
//        };
//
//        Answer__c[] sans2Ans = new Answer__c[]{
//
//            newOptionAnswer(sans2, q_gender, radio2, null),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[0], 1),
//            newNumberAnswer(sans2, q_age, answersLoader.age[0], 1),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[1], 2),
//            newNumberAnswer(sans2, q_age, answersLoader.age[1], 2),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[2], 3),
//            newNumberAnswer(sans2, q_age, answersLoader.age[2], 3),
//
//            new Answer__c(Submission__c = sans2.Id, Question__c = sec2.Id, Instance__c = 3),
//
//            newNumberAnswer(sans2, q_num_pets, answersLoader.numPets, null),
//
//            new Answer__c(Submission__c = sans2.Id, Question__c = sec4.Id, Instance__c = 3)
//        };
//
//        insert sans1Ans;
//        insert sans2Ans;
//
//        ScoringGroup__c[] sGs = new  ScoringGroup__c[]{
//            new ScoringGroup__c(Survey__c = survey.Id,Caption__c = 'ScoreGroup1')
//        };
//        insert  sGs;
//        insert new ScoreValue__c[]{
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=10, Option__c = radio1.id),
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=15, Option__c = radio2.id)
//        };
//
//        insert new SubmissionScore__c(ScoringGroup__c = sGs[0].Id,Submission__c = sans1.Id,TotalScore__c = 3);
//
//        ApexPages.currentPage().getParameters().put( 'id', survey.Id );
//        SurveyResultController controller = new SurveyResultController();
//        ApexPages.currentPage().getParameters().put( 'skipn', '0' );
//        controller.fetchMoreRows();
//
//        //check columns of header is equal to number of column of content
//        System.assertEquals( 4 + 13 + sGs.size(), controller.columnHeaders.size()); // 4 fixed columns, 12 questions (include repeat questions), 1 ScoreGroups
//
//        //Verify empty columns
//        System.assertEquals( '', controller.submissionRows[0].cells[14].stringValue, 'This cell for barcode is not filled for this submission.');
//        System.assertEquals( '', controller.submissionRows[0].cells[15].stringValue, 'This cell for barcode is not filled for this submission.');
//        System.assertEquals( '', controller.submissionRows[0].cells[16].stringValue, 'This cell for barcode is not filled for this submission.');
//
//        System.assertEquals( '', controller.submissionRows[1].cells[14].stringValue, 'This cell for barcode is not filled for this submission.');
//        System.assertEquals( '', controller.submissionRows[1].cells[15].stringValue, 'This cell for barcode is not filled for this submission.');
//        System.assertEquals( '', controller.submissionRows[1].cells[16].stringValue, 'This cell for barcode is not filled for this submission.');
//    }
//
//    /**
//    * Create a column of checkoxes and verify the multiple answers are concatenated.
//    */
//    static testMethod void testSurveyRepeatAnswersCheckboxes(){
//
//        Contact alice   = new Contact(FirstName = 'Alice'  , LastName = 'Alice');
//        Contact bob     = new Contact(FirstName = 'Bob'    , LastName = 'Bob');
//        Contact charlie = new Contact(FirstName = 'Charlie', LastName = 'Charlie');
//        insert new Contact[]{alice, bob, charlie};
//
//        //Prepare survey
//        Survey__c survey = new Survey__c(IsPPI__c=false);
//        insert survey;
//
//        //Inserting Sections
//        Question__c sec1 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section1', 'Section 1', 1);
//        Question__c sec2 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section2', 'Section 2', 2);
//        Question__c sec3 = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section3', 'Section 3', 3);
//        Question__c sec4 = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section4', 'Section 4', 4);
//        insert new Question__c[]{sec1, sec2, sec3, sec4};
//
//        // Prepare a question of each type
//        Question__c q_gender = newQuestion(survey, sec1, QuestionDO.TYPE_RADIO, 'radio', 'Gender', 1);
//        Question__c q_name = newQuestion(survey, sec2, QuestionDO.TYPE_TEXT_SHORT, 'text-short', 'Name of Child', 1);
//        Question__c q_age = newQuestion(survey, sec2, QuestionDO.TYPE_NUMBER, 'number', 'Age of Child', 2);
//        Question__c q_num_pets = newQuestion(survey, sec3, QuestionDO.TYPE_NUMBER, 'number', 'Number of Pets', 1);
//        Question__c q_food = newQuestion(survey, sec4, QuestionDO.TYPE_CHECKBOX, 'food', 'Food', 1);
//
//        insert new Question__c[]{q_gender, q_name, q_age, q_num_pets, q_food};
//
//        AnswersLoader answersLoader = new AnswersLoader();
//
//        Option__c radio1 = newOption(q_gender, AnswersLoader.GENDER_MALE, 10, 1);
//        Option__c radio2 = newOption(q_gender, AnswersLoader.GENDER_FEMALE, 15, 2);
//
//        Option__c chb1 = newOption(q_food, answersLoader.food[0], 1, 1);
//        Option__c chb2 = newOption(q_food, answersLoader.food[1], 2, 2);
//        Option__c chb3 = newOption(q_food, answersLoader.food[2], 3, 3);
//
//        insert new Option__c[]{radio1, radio2, chb1, chb2, chb3};
//
//        //Insert a couple of submissions
//        Submission__c sans1 = newSubmission(survey, Date.valueOf('2011-01-01'), alice, bob);
//
//        Submission__c sans2 = newSubmission(survey, Date.valueOf('2011-01-02'), alice, charlie);
//
//        insert new Submission__c[]{sans1, sans2};
//
//        Answer__c[] sans1Ans = new Answer__c[]{
//
//            newOptionAnswer(sans1, q_gender, radio1, null),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[0], 1),
//            newNumberAnswer(sans1, q_age, answersLoader.age[0], 1),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[1], 2),
//            newNumberAnswer(sans1, q_age, answersLoader.age[1], 2),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[2], 3),
//            newNumberAnswer(sans1, q_age, answersLoader.age[2], 3),
//
//            newTextAnswer(sans1, q_name, answersLoader.name[2], 4),
//            newNumberAnswer(sans1, q_age, answersLoader.age[2], 4),
//
//            new Answer__c(Submission__c = sans1.Id, Question__c = sec2.Id, Instance__c = 4),
//
//            newNumberAnswer(sans1, q_num_pets, answersLoader.numPets, null),
//
//            newOptionAnswer(sans1, q_food, chb1, 1),
//            newOptionAnswer(sans1, q_food, chb2, 1),
//            newOptionAnswer(sans1, q_food, chb3, 1),
//
//            newOptionAnswer(sans1, q_food, chb2, 2),
//            newOptionAnswer(sans1, q_food, chb3, 2),
//
//            new Answer__c(Submission__c = sans1.Id, Question__c = sec4.Id, Instance__c = 2)
//        };
//
//        Answer__c[] sans2Ans = new Answer__c[]{
//
//            newOptionAnswer(sans2, q_gender, radio2, null),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[0], 1),
//            newNumberAnswer(sans2, q_age, answersLoader.age[0], 1),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[1], 2),
//            newNumberAnswer(sans2, q_age, answersLoader.age[1], 2),
//
//            newTextAnswer(sans2, q_name, answersLoader.name[2], 3),
//            newNumberAnswer(sans2, q_age, answersLoader.age[2], 3),
//
//            new Answer__c(Submission__c = sans2.Id, Question__c = sec2.Id, Instance__c = 3),
//
//            newNumberAnswer(sans2, q_num_pets, answersLoader.numPets, null),
//
//            newOptionAnswer(sans2, q_food, chb1, 1),
//            newOptionAnswer(sans2, q_food, chb2, 1),
//
//            new Answer__c(Submission__c = sans2.Id, Question__c = sec4.Id, Instance__c = 2)
//        };
//
//        insert sans1Ans;
//        insert sans2Ans;
//
//        ScoringGroup__c[] sGs = new  ScoringGroup__c[]{
//            new ScoringGroup__c(Survey__c = survey.Id,Caption__c = 'ScoreGroup1')
//        };
//        insert  sGs;
//        insert new ScoreValue__c[]{
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=10, Option__c = radio1.id),
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=15, Option__c = radio2.id),
//
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=1, Option__c = chb1.id),
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=2, Option__c = chb2.id),
//            new ScoreValue__c(ScoringGroup__c = sGs[0].Id, Value__c=3, Option__c = chb3.id)
//        };
//
//        insert new SubmissionScore__c(ScoringGroup__c = sGs[0].Id, Submission__c = sans1.Id, TotalScore__c = (10+25+1+2+3));
//
//        ApexPages.currentPage().getParameters().put( 'id', survey.Id );
//        SurveyResultController controller = new SurveyResultController();
//        ApexPages.currentPage().getParameters().put( 'skipn', '0' );
//        controller.fetchMoreRows();
//
//        //check columns of header is equal to number of column of content
//        System.assertEquals( 4 + 12 + sGs.size(), controller.columnHeaders.size()); // 4 fixed columns, 12 questions (include repeat questions), 1 ScoreGroups
//
//        //Verify cell content
//        System.assertEquals( answersLoader.food[0] + ', ' + answersLoader.food[1] + ', ' + answersLoader.food[2], controller.submissionRows[0].cells[14].stringValue, 'The first submission in repetition number one of food must contain all food.');
//        System.assertEquals( answersLoader.food[1] + ', ' + answersLoader.food[2], controller.submissionRows[0].cells[15].stringValue, 'The first submission in repetition number two of food must contain Vegetals and Fruits.');
//
//        System.assertEquals( answersLoader.food[0] + ', ' + answersLoader.food[1], controller.submissionRows[1].cells[14].stringValue, 'The second submission in repetition number one of food must contain Meat and Vegetals.');
//        System.assertEquals( '', controller.submissionRows[1].cells[15].stringValue, 'The second submission in repetition number two of food must be empty because it was not asked.');
//    }
}