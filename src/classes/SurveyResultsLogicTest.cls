/**
 * Test class for the logic that generates the results data.
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
@isTest
public with sharing class SurveyResultsLogicTest {

    private static Question__c newQuestion(
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

    private static Option__c newOption(
        Question__c question,
        String name,
        Decimal ppiScore,
        Integer position
    ) {
        return new Option__c(
            Question__c = question.Id,
            Name = name,
            Caption__c = name,
            PPIScore__c = ppiScore,
            Position__c = position
        );
    }

    private class TestData {
        public Survey__c survey;
        public Map<Id, Question__c> questionsData;
        public List<Submission__c> submissions;
        public String pageHeader;
        public String csvHeader;
        public Map<Submission__c, String> expectedPageResult;
        public Map<Submission__c, String> expectedCsvResult;

        public TestData() {
            this.expectedPageResult = new Map<Submission__c, String>();
            this.expectedCsvResult = new Map<Submission__c, String>();
        }

        public String getExpectedPageResult() {
            String result = '';
            for(Submission__c submission : this.submissions) {
                result += expectedPageResult.get(submission) + '\n';
            }

            return result.replaceFirst('\n$', '');
        }

        public String getExpectedCsvResult() {
            String result = '';
            for(Submission__c submission : this.submissions) {
                result += expectedCsvResult.get(submission) + '\n';
            }

            return result.replaceFirst('\n$', '');
        }
    }

    /**
     * Prepare the data for the test
     *
     * @param  questionsCount   the amount of questions
     * @param  submissionsCount the amount of submissions
     * @return                  the data created
     */
    private static TestData prepareTestData(Integer questionsCount, Integer submissionsCount) {
        TestData data = new TestData();

        // Start building headers
        data.pageHeader = getFieldsHeaders(true);
        data.csvHeader = getFieldsHeaders(false);

        // Define content variables
        String pageContent = '';
        String csvContent = '';

        // Insert the neede contacts
        Contact surveyor = new Contact(LastName = 'Surveyor', FirstName = 'Name');
        insert new Contact[] {surveyor};

        // Create a survey
        Survey__c survey = new Survey__c(Name = 'survey');
        insert survey;

        // Add a section
        Question__c section = new Question__c(
            Survey__c = survey.Id,
            Name = QuestionDO.TYPE_SECTION,
            Caption__c = QuestionDO.TYPE_SECTION,
            Type__c = QuestionDO.TYPE_SECTION,
            Position__c = 1
        );
        insert section;

        // Create the questions
        Question__c[] questions = new Question__c[] {};
        for(Integer i = 1; i <= questionsCount; i++) {
            questions.add(
                newQuestion(
                    survey,
                    section,
                    QuestionDO.TYPE_TEXT_SHORT,
                    'qName' + i,
                    'qCaption' + i,
                    i
                )
            );

            // Add the headers for the expected results
            data.pageHeader += 'qCaption' + i + ',';
            data.csvHeader += 'qName' + i + ',';
        }

        questions.add (
            newQuestion (
                survey,
                section,
                QuestionDO.TYPE_GPS,
                'gpsLocation',
                'gpsLocation',
                questionsCount + 1
            )
        );

        // Add the headers for the expected results
        data.pageHeader += 'gpsLocation' + ',';
        data.csvHeader += 'gpsLocation latitude and longitude' + ',';
        data.csvHeader += 'gpsLocation altitude' + ',';
        data.csvHeader += 'gpsLocation accuracy' + ',';
        insert questions;

        // Remove the trailing comma
        data.pageHeader = data.pageHeader.replaceFirst(',$', '');
        data.csvHeader = data.csvHeader.replaceFirst(',$', '');

        // Publish the survey
        SurveyDO.updateSurveysStatus(new List <Survey__c> {survey}, SurveyDO.STATUS_PUBLISHED);

        // Create submissions
        Submission__c[] submissions = new Submission__c[] {};
        for(Integer i = 1; i <= submissionsCount; i++) {
            submissions.add(
                new Submission__c(
                    Survey__c = survey.Id,
                    StartDate__c = DateTime.now().addMinutes(i * 2 - 1000),
                    Surveyor__c = surveyor.Id
                )
            );
        }
        insert submissions;
        // Free some memory
        submissions = [SELECT Id,
                              Survey__c,
                              StartDate__c,
                              EndDate__c,
                              Date__c,
                              Gps_x__c,
                              Gps_y__c,
                              PPIScore__c,
                              Surveyor__c,
                              Surveyor__r.Name,
                              (SELECT Id, TotalScore__c, ScoringGroup__c
                               FROM   SubmissionScore__r
                               ORDER BY ScoringGroup__c),
                              (SELECT Id,
                                      PPITableLine__c,
                                      PPITableLine__r.Probability__c,
                                      PPITableLine__r.PPITableDataSet__c
                               FROM   Submition_PPI_Values__r)
                       FROM Submission__c
                       WHERE Survey__c = :survey.Id
                       ORDER BY StartDate__c, Id];

        // Create the answers
        Answer__c[] answers = new Answer__c[] {};
        for(Submission__c submission : submissions) {
            // Add the submission fields data
            pageContent = getFieldsData(submission, true);
            csvContent = getFieldsData(submission, false);

            for(Integer i = 1; i <= questionsCount; i++) {
                answers.add(
                    new Answer__c(
                        Submission__c = submission.Id,
                        Question__c = questions[i-1].Id,
                        TextAreaValue__c = submission.Id + 'answer' + i,
                        Value__c = submission.Id + 'answer' + i
                    )
                );

                // Add the data for the expected results
                pageContent += submission.Id + 'answer' + i + ',';
                csvContent += submission.Id + 'answer' + i + ',';
            }
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    Question__c = questions[questionsCount].Id,
                    Value__c = '18.5472615 73.8180623 0.0 25.0'
                )
            );

            // Add the data for the expected results
            pageContent += 'gps-location~18.547262|73.818062' + ',';
            csvContent += '"18.547262, 73.818062"' + ',';
            csvContent += '0.000000' + ',';
            csvContent += '25.000000' + ',';

            // Remove the trailing comma
            data.expectedPageResult.put(submission, pageContent.replaceAll(',$', ''));
            data.expectedCsvResult.put(submission, csvContent.replaceAll(',$', ''));
        }
        insert answers;
        // Free some memory
        answers.clear();

        data.survey = SurveyDO.getSurveyDataForResults(survey.Id);
        data.questionsData = SurveyDO.getQuestionsDataForResults(survey.Id);
        data.submissions = submissions;

        return data;
    }

    /**
     * Create data based on new Ppi template type of survey
     */
    static TestData preparePpiSurveyTestData(Integer submissionsCount) {
        TestSurveyData testSurveyDataInstance = TestSurveyData.createFullPpiTemplate();
        TestData data = new TestData();
        Survey__c survey = testSurveyDataInstance.testSurvey;

        // Start building headers
        data.pageHeader = getFieldsHeaders(true);
        data.csvHeader = getFieldsHeaders(false);

        // Define content variables
        String pageContent = '';
        String csvContent = '';

        // Insert the needed contacts
        Contact surveyor = new Contact(LastName = 'Surveyor', FirstName = 'Name');
        insert new Contact[] {surveyor};

        // Publish the survey
        SurveyDO.updateSurveysStatus(new List <Survey__c> {survey}, SurveyDO.STATUS_PUBLISHED);

        // Create submissions
        Submission__c[] submissions = new Submission__c[] {};
        for (Integer i = 1; i <= submissionsCount; i++) {
            submissions.add(
                new Submission__c(
                    Survey__c = survey.Id,
                    StartDate__c = DateTime.now().addMinutes(i * 2 - 1000),
                    Surveyor__c = surveyor.Id,
                    PpiScore__c = 10
                )
            );
        }
        insert submissions;

        // Add Submission Ppi Association records based on submission
        List<SubmissionPpiAssociation__c> submissionPpiAssociations =
            new List<SubmissionPpiAssociation__c>();
        List<PpiResult__c> listPpiResult = PpiResultDomainTest.createSamplePpiResultData(1, false);
        System.assert(listPpiResult != null);
        System.assertEquals(1, listPpiResult.size());

        for (Submission__c submission : submissions) {
            SubmissionPpiAssociation__c submissionPpiAssociation =
                SubmissionPpiAssociationDomainTest.createRecord(
                    listPpiResult[0],
                    PpiTableLineDomainTest.insertPpiTableLine(),
                    submission
                );
            submissionPpiAssociations.add(submissionPpiAssociation);
        }
        SubmissionPpiAssociationDomain submissionPpiAssociationDomainInstance =
            new SubmissionPpiAssociationDomain.Constructor().constructWithRecords(
                submissionPpiAssociations
            );
        submissionPpiAssociationDomainInstance.insertRecords();

        submissions =
            [SELECT
                Id,
                Survey__c,
                StartDate__c,
                EndDate__c,
                Date__c,
                Gps_x__c,
                Gps_y__c,
                PPIScore__c,
                Surveyor__c,
                Surveyor__r.Name,
                (SELECT
                    Id,
                    TotalScore__c,
                    ScoringGroup__c
                FROM
                    SubmissionScore__r
                ORDER BY ScoringGroup__c),
                (SELECT
                    Id,
                    PPITableLine__c,
                    PPITableLine__r.Probability__c,
                    PPITableLine__r.PPITableDataSet__c
                FROM
                    Submition_PPI_Values__r),
                (SELECT
                    Id,
                    PPITableLine__c,
                    PPITableLine__r.Probability__c,
                    PPITableLine__r.PPITableDataSet__c
                FROM
                    Submission_Ppi_Associations__r)
            FROM
                Submission__c
            WHERE
                Survey__c = :survey.Id
            ORDER BY
                StartDate__c, Id
            ];

        QuestionSelector selector = new QuestionSelector();
        List<Question__c> questionsList =  selector.getAllForPpiSurveyId(survey.Id);
        List<Question__c > validQuestions = new List<Question__c>();
        for (Question__c question : questionsList) {
            if (question.Parent__c != null) {
                validQuestions.add(question);
                data.pageHeader += question.Caption__c + ',';
                if (question.Type__c == QuestionDO.TYPE_GPS) {
	                data.csvHeader += question.Name + ' latitude and longitude,';
	                data.csvHeader += question.Name + ' altitude,';
	                data.csvHeader += question.Name + ' accuracy,';
	            } else {
	                data.csvHeader += question.Name + ',';
	            }
            }
        }
        data.pageHeader += System.Label.SUBMISSION_PPISCORE.escapeCsv() + ',';
        data.pageHeader += 'Test Table Name';
        data.csvHeader += System.Label.SUBMISSION_PPISCORE.escapeCsv() + ',';
        data.csvHeader += 'Test Table Name';

        // Create the answers
        Answer__c[] answers = new Answer__c[] {};
        for (Submission__c submission : submissions) {
            // Add the submission fields data
            pageContent = getFieldsData(submission, true);
            csvContent = getFieldsData(submission, false);

            for (Integer i = 1; i <= validQuestions.size(); i++) {
                if (validQuestions[i-1].Type__c != 'gps-location') {
	                answers.add(
	                    new Answer__c(
	                        Submission__c = submission.Id,
	                        Question__c = validQuestions[i-1].Id,
	                        TextAreaValue__c = submission.Id + 'answer' + i,
	                        Value__c = submission.Id + 'answer' + i
	                    )
	                );

	                // Add the data for the expected results
	                pageContent += submission.Id + 'answer' + i + ',';
	                csvContent += submission.Id + 'answer' + i + ',';
                } else {
	                // Add the data for the blank results - GPS in this case
	                pageContent += ',';
	                csvContent += ',,,';
                }
            }

            // Scoring value is 10, while default probability added is 0.05
            pageContent += '10,0.05,';
            csvContent += '10,0.05';

            // Remove the trailing comma
            data.expectedPageResult.put(submission, pageContent.replaceAll(',$', ''));
            data.expectedCsvResult.put(submission, csvContent.replaceAll(',$', ''));
        }
        insert answers;

        data.survey = SurveyDO.getSurveyDataForResults(testSurveyDataInstance.testSurvey.Id);
        data.questionsData =
            SurveyDO.getQuestionsDataForResults(testSurveyDataInstance.testSurvey.Id);
        data.submissions = submissions;

        return data;
    }

    /**
     * Gets the fields headers
     *
     * @param  forPage indicates if the header is for the page
     * @return         a csv string with the headers
     */
    private static String getFieldsHeaders(Boolean forPage) {
        // Get the submission fileds labels for the header row
        Map<String, Schema.SobjectField> fieldsMap =
            Schema.SObjectType.Submission__c.fields.getMap();
        String startDateLabel   = fieldsMap.get('startDate__c').getDescribe().getLabel();
        String endDateLabel     = fieldsMap.get('endDate__c').getDescribe().getLabel();
        String dateLabel        = fieldsMap.get('Date__c').getDescribe().getLabel();
        String gpsXLabel        = fieldsMap.get('gps_x__c').getDescribe().getLabel();
        String gpsYLabel        = fieldsMap.get('gps_y__c').getDescribe().getLabel();
        String surveyorLabel    = fieldsMap.get('Surveyor__c').getDescribe().getLabel();

        // Add the submission fields labels to the header
        String header = '';

        // Add headers only for the CSV
        if(!forPage) {
            header += startDateLabel.escapeCsv() + ','
                      + endDateLabel.escapeCsv() + ','
                      + dateLabel.escapeCsv() + ','
                      + gpsXLabel.escapeCsv() + ','
                      + gpsYLabel.escapeCsv() + ',';
        }

        header += surveyorLabel.escapeCsv() + ',';

        return header;
    }

    /**
     * Gets the submission fields data
     *
     * @param  submission the current submission
     * @param  forPage    indicates if the header is for the page
     * @return            a csv string with the data
     */
    private static String getFieldsData(Submission__c submission, Boolean forPage) {
        // Add the submission data to the row
        String rowString = '';

        if(!forPage) {
            rowString +=
                (submission.startDate__c != null
                    ? submission.startDate__c.format('yyyy-MM-dd HH:mm:ssZ', UserInfo.getTimeZone().GetId()).escapeCsv()
                    : ''
                ) + ',' +
                (submission.endDate__c != null
                    ? submission.endDate__c.format('yyyy-MM-dd HH:mm:ssZ', UserInfo.getTimeZone().getId()).escapeCsv()
                    : ''
                ) + ',' +
                (submission.Date__c != null
                    ? String.valueOf(submission.Date__c).escapeCsv()
                    : ''
                ) + ',' +
                (submission.gps_x__c != null
                    ? String.valueOf(submission.gps_x__c).escapeCsv()
                    : ''
                ) + ',' +
                (submission.gps_y__c != null
                    ? String.valueOf(submission.gps_y__c).escapeCsv()
                    : ''
                ) + ',';
        }

        rowString +=
            (submission.Surveyor__c != null
                ? submission.Surveyor__r.Name.escapeCsv()
                : ''
            ) + ',';

        return rowString;
    }

    /**
     * Adds questions of almost all the posible types.
     * Types not added: checkbox, static-content, end_of_survey and any media question.
     * There are specific tests for some of those type of questions, others are not
     * used in results.
     *
     * @param  data the previously added data
     * @return      the data with the new questions added
     */
    private static TestData addAllTypeOfQuestions(TestData data) {

        // Add a section
        Question__c section = new Question__c(
            Survey__c = data.survey.Id,
            Name = QuestionDO.TYPE_SECTION + '_AllType',
            Caption__c = QuestionDO.TYPE_SECTION + '_AllType',
            Type__c = QuestionDO.TYPE_SECTION,
            Position__c = 2
        );
        insert section;

        List<String> types = new String[] {
            QuestionDO.TYPE_TEXT_SHORT,
            QuestionDO.TYPE_TEXT_LONG,
            QuestionDO.TYPE_NUMBER_INTEGER,
            QuestionDO.TYPE_NUMBER_DECIMAL,
            QuestionDO.TYPE_DATE,
            QuestionDO.TYPE_DATETIME,
            QuestionDO.TYPE_BARCODE,
            QuestionDO.TYPE_RADIO,
            QuestionDO.TYPE_GPS
        };


        // Create the questions
        Map<String, Question__c> questions = new Map<String, Question__c>();
        for(Integer i = 0; i < types.size(); i++) {
            questions.put(
                types.get(i),
                newQuestion(
                    data.survey,
                    section,
                    types.get(i),
                    'qName' + types.get(i),
                    'qCaption' + types.get(i),
                    i
                )
            );

            // Add the headers for the expected results
            data.pageHeader += ',qCaption' + types.get(i);
            if (types.get(i) == QuestionDO.TYPE_GPS) {
                data.csvHeader += ',qName' + types.get(i) + ' latitude and longitude';
                data.csvHeader += ',qName' + types.get(i) + ' altitude';
                data.csvHeader += ',qName' + types.get(i) + ' accuracy';
            } else {
                data.csvHeader += ',qName' + types.get(i);
            }
        }
        insert questions.values();

        // Add the options to the radio question
        List<Option__c> options = new List<Option__c>();
        options.add(newOption(questions.get(QuestionDO.TYPE_RADIO), 'Option1', 0, 1));
        options.add(newOption(questions.get(QuestionDO.TYPE_RADIO), 'Option2', 0, 2));
        options.add(newOption(questions.get(QuestionDO.TYPE_RADIO), 'Option3', 0, 3));
        insert options;

        // Publish the survey
        SurveyDO.updateSurveysStatus(new List <Survey__c> {data.survey}, SurveyDO.STATUS_PUBLISHED);

        // Create the answers
        Answer__c[] answers = new Answer__c[] {};
        for(Submission__c submission : data.submissions) {
            String expectedPageResult = data.expectedPageResult.get(submission);
            String expectedCsvResult = data.expectedCsvResult.get(submission);

            // Answer for the text-short
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    Question__c = questions.get(QuestionDO.TYPE_TEXT_SHORT).Id,
                    TextAreaValue__c = submission.Id + 'answer' + QuestionDO.TYPE_TEXT_SHORT,
                    Value__c = submission.Id + 'answer' + QuestionDO.TYPE_TEXT_SHORT
                )
            );
            // Add the data for the expected results
            expectedPageResult += ',' + submission.Id + 'answer' + QuestionDO.TYPE_TEXT_SHORT;
            expectedCsvResult += ',' + submission.Id + 'answer' + QuestionDO.TYPE_TEXT_SHORT;

            // Answer for the text-long
            answers.add(
                //TODO: Build a long string
                new Answer__c(
                    Submission__c = submission.Id,
                    Question__c = questions.get(QuestionDO.TYPE_TEXT_LONG).Id,
                    TextAreaValue__c = submission.Id + 'answer' + QuestionDO.TYPE_TEXT_LONG,
                    Value__c = submission.Id + 'answer' + QuestionDO.TYPE_TEXT_LONG
                )
            );
            // Add the data for the expected results
            expectedPageResult += ',' + submission.Id + 'answer' + QuestionDO.TYPE_TEXT_LONG;
            expectedCsvResult += ',' + submission.Id + 'answer' + QuestionDO.TYPE_TEXT_LONG;

            // Answer for the number-integer
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    Question__c = questions.get(QuestionDO.TYPE_NUMBER_INTEGER).Id,
                    NumericValue__c = 1000,
                    Value__c = '1000'
                )
            );
            // Add the data for the expected results
            expectedPageResult += ',' + '1000';
            expectedCsvResult += ',' + '1000';

            // Answer for the number-decimal
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    Question__c = questions.get(QuestionDO.TYPE_NUMBER_DECIMAL).Id,
                    NumericValue__c = 1000.02,
                    Value__c = '1000.02'
                )
            );
            // Add the data for the expected results
            expectedPageResult += ',' + '1000.02';
            expectedCsvResult += ',' + '1000.02';

            // Answer for the date-date
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                Question__c = questions.get(QuestionDO.TYPE_DATE).Id,
                    DateValue__c = Date.valueOf('2012-02-14'),
                    Value__c = '2012-02-14'
                )
            );
            // Add the data for the expected results
            expectedPageResult += ',' + '2012-02-14';
            expectedCsvResult += ',' + '2012-02-14';

            // Answer for the date-datetime
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    Question__c = questions.get(QuestionDO.TYPE_DATETIME).Id,
                    DateTimeValue__c = SurveyUtils.valueInGmt('2012-02-14T19:23:53.463'),
                    Value__c = '2012-02-14 19:23:53.463'
                )
            );
            // Add the data for the expected results
            expectedPageResult += ',' + '2012-02-14 19:23:53.463';
            expectedCsvResult += ',' + '2012-02-14 19:23:53.463';

            // Answer for the barcode
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    Question__c = questions.get(QuestionDO.TYPE_BARCODE).Id,
                    Value__c = submission.Id + 'answer' + QuestionDO.TYPE_BARCODE
                )
            );
            // Add the data for the expected results
            expectedPageResult += ',' + submission.Id + 'answer' + QuestionDO.TYPE_BARCODE;
            expectedCsvResult += ',' + submission.Id + 'answer' + QuestionDO.TYPE_BARCODE;

            // Answer for the radio
            answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    Question__c = questions.get(QuestionDO.TYPE_RADIO).Id,
                    TextAreaValue__c = options[0].Id,
                    Value__c = options[0].Id
                )
            );
            // Add the data for the expected results
            expectedPageResult += ',' + options[0].Id;
            expectedCsvResult += ',' + options[0].Id;

           // Answer for GPS Question
           answers.add(
                new Answer__c(
                    Submission__c = submission.Id,
                    Question__c = questions.get(QuestionDO.TYPE_GPS).Id,
                    Value__c = '18.5472615 73.8180623 0.0 25.0'
                )
            );
            // Add the data for the expected results
            expectedPageResult += ',' + 'gps-location~18.547262|73.818062';
            expectedCsvResult += ',' + '"18.547262, 73.818062"';
            expectedCsvResult += ',' + '0.000000';
            expectedCsvResult += ',' + '25.000000';

            data.expectedPageResult.put(submission, expectedPageResult);
            data.expectedCsvResult.put(submission, expectedCsvResult);
        }
        insert answers;
        // Free some memory
        answers.clear();

        data.survey = SurveyDO.getSurveyDataForResults(data.survey.Id);
        data.questionsData = SurveyDO.getQuestionsDataForResults(data.survey.Id);

        data.submissions = [SELECT Id,
                                   Survey__c,
                                   StartDate__c,
                                   EndDate__c,
                                   Date__c,
                                   Gps_x__c,
                                   Gps_y__c,
                                   PPIScore__c,
                                   Surveyor__c,
                                   Surveyor__r.Name,
                                   (SELECT Id, TotalScore__c, ScoringGroup__c
                                    FROM   SubmissionScore__r
                                    ORDER BY ScoringGroup__c),
                                   (SELECT Id,
                                           PPITableLine__c,
                                           PPITableLine__r.Probability__c,
                                           PPITableLine__r.PPITableDataSet__c
                                    FROM   Submition_PPI_Values__r)
                            FROM Submission__c
                            WHERE Survey__c = :data.survey.Id
                            ORDER BY StartDate__c, Id];

        return data;
    }

    /**
     * Add cascading a select question in a new section
     *
     * @param   data            the previously added data
     * @param   sectionType     the type of the section that will contain the questions
     * @param   cascadingData   a matrix with the cascading data
     * @param   answersData     a matrix with the answers for submission
     * @return                  the data with the new questions added
     */
    private static TestData addCascadingSelectQuestions(
        TestData data,
        String sectionType,
        List<List<String>> cascadingData,
        List<List<String>> answersData
    ) {
        // Add a section
        Question__c section = new Question__c(
            Survey__c = data.survey.Id,
            Name = sectionType + '_Cascading',
            Caption__c = sectionType + '_Cascading',
            Type__c = sectionType,
            Position__c = 2
        );
        insert section;

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels = TestUtils.createCascadingSelect(
            'Cascading Select',
            cascadingData
        );

        // Create the questions for the cascading select
        List<Question__c> questions = TestUtils.addCascadingSelectQuestion(
            'new_cascading',
            'New Cascading',
            'Some hint',
            data.survey,
            section,
            1,
            levels
        );

        // Publish the survey
        SurveyDO.updateSurveysStatus(new List <Survey__c> {data.survey}, SurveyDO.STATUS_PUBLISHED);

        Question__c cascadingParent = questions[0];

        Integer instancesCount = 0;
        if(sectionType == QuestionDO.TYPE_REPEAT) {

            instancesCount = answersData[0].size() / levels.size();
            // Add the headers for the expected results
            for(Integer j = 1; j < questions.size(); j++) {
                for(Integer i = 0; i < instancesCount; i++) {
                    data.pageHeader += ',' + cascadingParent.Caption__c + ' ' +
                                       questions[j].Caption__c + ' ' + (i + 1);
                    data.csvHeader += ',' + cascadingParent.Name + '_' +
                                      questions[j].Caption__c.replace(' ', '_').toLowerCase() + '_' + (i + 1);
                }
            }

            List<Answer__c> instanceAnswers = new List<Answer__c>();
            // Create the answers for the repeated instances
            for(Submission__c submission : data.submissions) {
                for(Integer i = 0; i < instancesCount; i++) {
                    instanceAnswers.add(
                        new Answer__c(
                            Submission__c = submission.Id,
                            Question__c = section.Id,
                            Instance__c = i + 1
                        )
                    );
                }
            }
            insert instanceAnswers;
        }
        else {
            // Add the headers for the expected results
            for(Integer i = 1; i < questions.size(); i++) {
                data.pageHeader += ',' + cascadingParent.Caption__c + ' ' + questions[i].Caption__c;
                data.csvHeader += ',' + cascadingParent.Name + '_' + questions[i].Caption__c.replace(' ', '_').toLowerCase();
            }
        }

        // Create the answers
        Answer__c[] answers = new Answer__c[] {};
        for(Integer i = 0; i < answersData.size(); i++) {
            Submission__c submission = data.submissions[i];

            String expectedPageResult = data.expectedPageResult.get(submission);
            String expectedCsvResult = data.expectedCsvResult.get(submission);
            Map<Integer, String> answersByQuestionPosition = new Map<Integer, String>();

            Integer instance = 0;
            for(Integer j = 0; j < answersData[i].size(); j++) {
                if(sectionType == QuestionDO.TYPE_REPEAT) {
                    if(Math.mod(j, levels.size()) == 0) {
                        instance ++;
                    }
                }

                // The answer object is created only for those values that have an answer
                if(String.isNotBlank(answersData[i][j])) {
                    // Answer for the cascading level
                    answers.add(
                        new Answer__c(
                            Submission__c = submission.Id,
                            Question__c = questions[Math.mod(j, levels.size()) + 1].Id,
                            Instance__c = sectionType == QuestionDO.TYPE_REPEAT ? instance : null,
                            TextAreaValue__c = answersData[i][j],
                            Value__c = answersData[i][j]
                        )
                    );
                }
                // Add the data for the expected results
                // Consider the position for the repeated questions
                if(sectionType == QuestionDO.TYPE_REPEAT) {
                    if(answersByQuestionPosition.get(Math.mod(j, levels.size()) + 1) != null) {
                        answersByQuestionPosition.put(
                            Math.mod(j, levels.size()) + 1,
                            answersByQuestionPosition.get(Math.mod(j, levels.size()) + 1) + ',' + answersData[i][j]
                        );
                    }
                    else {
                        answersByQuestionPosition.put(Math.mod(j, levels.size()) + 1, ',' + answersData[i][j]);
                    }
                }
                else {
                    expectedPageResult += ',' + answersData[i][j];
                    expectedCsvResult += ',' + answersData[i][j];
                }
            }

            // Build the expected results for the repeated questions
            if(sectionType == QuestionDO.TYPE_REPEAT) {
                for(Integer position = 1; position <= levels.size(); position++) {
                    expectedPageResult += answersByQuestionPosition.get(position);
                    expectedCsvResult += answersByQuestionPosition.get(position);
                }
            }
            data.expectedPageResult.put(submission, expectedPageResult);
            data.expectedCsvResult.put(submission, expectedCsvResult);
        }
        insert answers;
        // Free some memory
        answers.clear();

        data.survey = SurveyDO.getSurveyDataForResults(data.survey.Id);
        data.questionsData = SurveyDO.getQuestionsDataForResults(data.survey.Id);

        data.submissions = [SELECT Id,
                                   Survey__c,
                                   StartDate__c,
                                   EndDate__c,
                                   Date__c,
                                   Gps_x__c,
                                   Gps_y__c,
                                   PPIScore__c,
                                   Surveyor__c,
                                   Surveyor__r.Name,
                                   (SELECT Id, TotalScore__c, ScoringGroup__c
                                    FROM   SubmissionScore__r
                                    ORDER BY ScoringGroup__c),
                                   (SELECT Id,
                                           PPITableLine__c,
                                           PPITableLine__r.Probability__c,
                                           PPITableLine__r.PPITableDataSet__c
                                    FROM   Submition_PPI_Values__r)
                            FROM Submission__c
                            WHERE Survey__c = :data.survey.Id
                            ORDER BY StartDate__c, Id];

        return data;
    }

    /**
     * Basic test for results logic with only text questions
     */
    static testMethod void testOnlyTextQuestions() {
        TestData data = prepareTestData(5, 5);
        Map<Id, Integer> maxInstanceById = SurveyResultsLogic.getMaxInstanceMap(data.survey.Id);

        Test.startTest();
        String resultForPage = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            true
        );
        String resultForCsv = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            false
        );


        Map<Id, Contact> contactsMap = SurveyResultsLogic.getContacts(data.submissions);
        Map<Id, List<SubmissionPPIValue__c>> ppiValuesBySubmission =
                SubmissionDO.getSubmissionsPPIValues(data.submissions);

        Set<Id> submissionIds = new Map<Id, Submission__c>(data.submissions).keySet();
        for (Submission__c submission : data.submissions) {
            resultForPage += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                true
            );
            resultForCsv += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                false
            );
        }
        Test.stopTest();

        System.assertEquals(data.pageHeader + '\n' + data.getExpectedPageResult(), resultForPage);
        System.assertEquals(data.csvHeader + '\n' + data.getExpectedCsvResult(), resultForCsv);
    }

    /**
     * Test that csv and page result works for new Ppi submissions as well
     */
    static testMethod void testPpiSurveyResultsPage() {

        TestData data = preparePpiSurveyTestData(1);
        Map<Id, Integer> maxInstanceById = SurveyResultsLogic.getMaxInstanceMap(data.survey.Id);

        Test.startTest();
        String resultForPage = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            true
        );
        String resultForCsv = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            false
        );


        Map<Id, Contact> contactsMap = SurveyResultsLogic.getContacts(data.submissions);
        Map<Id, List<SubmissionPPIAssociation__c>> ppiValuesBySubmission =
            SubmissionDO.getSubmissionPpiAssociations(data.submissions);

        Set<Id> submissionIds = new Map<Id, Submission__c>(data.submissions).keySet();
        for (Submission__c submission : data.submissions) {
            resultForPage += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                true
            );
            resultForCsv += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                false
            );
        }
        Test.stopTest();

        System.assertEquals(data.pageHeader + '\n' + data.getExpectedPageResult(), resultForPage);
        System.assertEquals(data.csvHeader + '\n' + data.getExpectedCsvResult(), resultForCsv);
    }

    /**
     * Basic test for results logic with only cascading select questions
     */
    static testMethod void testOnlyCascadingSelectQuestions() {
        TestData data = prepareTestData(1, 1);

        // Create setting to change the survey status
        SurveyTriggerLogic.setOverrideDeleteChecks(true);
        insert new Settings__c(Name = 'FLAG_SKIP_SURVEY_STATUS_VALIDATION');
        data.survey.Status__c = SurveyDO.STATUS_DRAFT;
        update data.survey;

        // Create the data for the cascading select
        List<List<String>> cascadingData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'}
        };

        // Create the data for the answers
        List<List<String>> answersData = new List<List<String>> {
            new List<String> {'Audi', 'A3', '2001'}
        };

        data = addCascadingSelectQuestions(data, QuestionDO.TYPE_SECTION, cascadingData, answersData);

        Map<Id, Integer> maxInstanceById = SurveyResultsLogic.getMaxInstanceMap(data.survey.Id);

        Map<Id, Question__c> cascadingQuestions = new Map<Id, Question__c>(
            [SELECT Id,
                    Parent__r.Type__C
             FROM Question__c
             WHERE Type__c = :QuestionDO.TYPE_CASCADING_SELECT]
        );

        Test.startTest();
        String resultForPage = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            true
        );
        String resultForCsv = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            false
        );

        Map<Id, Contact> contactsMap = SurveyResultsLogic.getContacts(data.submissions);
        Map<Id, List<SubmissionPPIValue__c>> ppiValuesBySubmission =
                SubmissionDO.getSubmissionsPPIValues(data.submissions);

        for(Submission__c submission : data.submissions) {
            resultForPage += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                true
            );
            resultForCsv += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                false
            );
        }
        Test.stopTest();

        System.assertEquals(data.pageHeader + '\n' + data.getExpectedPageResult(), resultForPage);
        System.assertEquals(data.csvHeader + '\n' + data.getExpectedCsvResult(), resultForCsv);
    }

    /**
     * Test for results logic with a cascading select question in a repeated section
     *
    static testMethod void testCascadingSelectQuestionInRepeated() {
        TestData data = prepareTestData(1, 1);

        // Create setting to change the survey status
        SurveyTriggerLogic.setOverrideDeleteChecks(true);
        insert new Settings__c(Name = 'FLAG_SKIP_SURVEY_STATUS_VALIDATION');
        data.survey.Status__c = SurveyDO.STATUS_DRAFT;
        update data.survey;

        // Create the data for the cascading select
        List<List<String>> cascadingData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'},
            new List<String> {'Audi', 'A5', '2003'},
            new List<String> {'Dodge', 'Charger', '2006'}
        };

        // Create the data for the answers
        List<List<String>> answersData = new List<List<String>> {
            new List<String> {'Audi', 'A3', '2001',
                              'Dodge', 'Charger', '2006',
                              '', '', '',
                              'Audi', 'A3', '2001',
                              'Audi', 'A5', '2003'
            }
        };

        data = addCascadingSelectQuestions(data, QuestionDO.TYPE_REPEAT, cascadingData, answersData);

        Map<Id, Integer> maxInstanceById = SurveyResultsLogic.getMaxInstanceMap(data.survey.Id);

        Map<Id, Question__c> cascadingQuestions = new Map<Id, Question__c>(
            [SELECT Id,
                    Parent__r.Type__C
             FROM Question__c
             WHERE Type__c = :QuestionDO.TYPE_CASCADING_SELECT]
        );

        Test.startTest();
        String resultForPage = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            true
        );
        String resultForCsv = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            false
        );

        Map<Id, Contact> contactsMap = SurveyResultsLogic.getContacts(data.submissions);
        Map<Id, List<SubmissionPPIValue__c>> ppiValuesBySubmission =
                SubmissionDO.getSubmissionsPPIValues(data.submissions);

        for(Submission__c submission : data.submissions) {
            resultForPage += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                true
            );
            resultForCsv += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                false
            );
        }
        Test.stopTest();

        System.assertEquals(data.pageHeader + '\n' + data.getExpectedPageResult(), resultForPage);
        System.assertEquals(data.csvHeader + '\n' + data.getExpectedCsvResult(), resultForCsv);
    }

    /**
     * Test for results logic with an unanswered cascading select
     */
    static testMethod void testUnansweredCascadingSelectQuestion() {
        TestData data = prepareTestData(1, 1);

        // Create setting to change the survey status
        SurveyTriggerLogic.setOverrideDeleteChecks(true);
        insert new Settings__c(Name = 'FLAG_SKIP_SURVEY_STATUS_VALIDATION');
        data.survey.Status__c = SurveyDO.STATUS_DRAFT;
        update data.survey;

        // Create the data for the cascading select
        List<List<String>> cascadingData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2001'}
        };

        // Create the data for the answers
        List<List<String>> answersData = new List<List<String>> {
            new List<String> {'', '', ''}
        };

        data = addCascadingSelectQuestions(data, QuestionDO.TYPE_SECTION, cascadingData, answersData);

        Map<Id, Integer> maxInstanceById = SurveyResultsLogic.getMaxInstanceMap(data.survey.Id);

        Map<Id, Question__c> cascadingQuestions = new Map<Id, Question__c>(
            [SELECT Id,
                    Parent__r.Type__C
             FROM Question__c
             WHERE Type__c = :QuestionDO.TYPE_CASCADING_SELECT]
        );

        Test.startTest();
        String resultForPage = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            true
        );
        String resultForCsv = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            false
        );

        Map<Id, Contact> contactsMap = SurveyResultsLogic.getContacts(data.submissions);
        Map<Id, List<SubmissionPPIValue__c>> ppiValuesBySubmission =
                SubmissionDO.getSubmissionsPPIValues(data.submissions);

        for(Submission__c submission : data.submissions) {
            resultForPage += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                true
            );
            resultForCsv += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                false
            );
        }
        Test.stopTest();

        System.assertEquals(data.pageHeader + '\n' + data.getExpectedPageResult(), resultForPage);
        System.assertEquals(data.csvHeader + '\n' + data.getExpectedCsvResult(), resultForCsv);
    }

    /**
     * Test with all kind of questions
     */
    static testMethod void testCompleteSurvey () {
        TestData data = prepareTestData(5, 5);

        // Create setting to change the survey status
        SurveyTriggerLogic.setOverrideDeleteChecks(true);
        insert new Settings__c(Name = 'FLAG_SKIP_SURVEY_STATUS_VALIDATION');
        data.survey.Status__c = SurveyDO.STATUS_DRAFT;
        update data.survey;

        data = addAllTypeOfQuestions(data);

        Map<Id, Integer> maxInstanceById = SurveyResultsLogic.getMaxInstanceMap(data.survey.Id);

        Map<Id, Question__c> cascadingQuestions = new Map<Id, Question__c>(
            [SELECT Id,
                    Parent__r.Type__C
             FROM Question__c
             WHERE Type__c = :QuestionDO.TYPE_CASCADING_SELECT]
        );

        Test.startTest();
        String resultForPage = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            true
        );
        String resultForCsv = SurveyResultsLogic.createHeaderRow(
            data.survey,
            data.questionsData,
            maxInstanceById,
            false
        );

        Map<Id, Contact> contactsMap = SurveyResultsLogic.getContacts(data.submissions);
        Map<Id, List<SubmissionPPIValue__c>> ppiValuesBySubmission =
                SubmissionDO.getSubmissionsPPIValues(data.submissions);

        for(Submission__c submission : data.submissions) {
            resultForPage += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                true
            );
            resultForCsv += '\n' + SurveyResultsLogic.createSubmissionRow(
                data.survey,
                data.questionsData,
                submission,
                maxInstanceById,
                ppiValuesBySubmission.get(submission.Id),
                contactsMap,
                UserInfo.getTimeZone().getId(),
                false
            );
        }
        Test.stopTest();

        System.assertEquals(data.pageHeader + '\n' + data.getExpectedPageResult(), resultForPage);
        System.assertEquals(data.csvHeader + '\n' + data.getExpectedCsvResult(), resultForCsv);
    }


}
