/**
 * Class that contains the logic to generate the survey results.
 * It will be used for the Results page, CSV Export and CSV Batch process
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 * @author - Aditi Satpute
 */
public with sharing class SurveyResultsLogic {

    /**
     * Gets the header row for the survey results
     * (Related to IDALMSA-1887)
     *
     * @param  survey                  the survey record
     * @param  questionsData           a map with the data of all the questions in the survey
     * @param  maxInstanceByQuestionId a map with the max instance answer for the repeated questions
     * @param  forPage                 indicates if the header is for the page to use the caption of the questions
     * @return                         a string with the header in CSV format
     */
    public static String createHeaderRow(
        Survey__c survey,
        Map<Id, Question__c> questionsData,
        Map<Id, Integer> maxInstanceByQuestionId,
        Boolean forPage
    ) {
        // Get the submission fileds labels for the header row
        Map<String, Schema.SobjectField> fieldsMap = Schema.SObjectType.Submission__c.fields.getMap();
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

        header += getQuestionsHeaders(survey.Questions__r, questionsData, maxInstanceByQuestionId, null, forPage);

        // Add headers for scoring
        for (ScoringGroup__c scoringGroup : survey.Scoring_Groups__r) {
            if (!scoringGroup.isPpi__c) {
                header += scoringGroup.Caption__c.escapeCsv() + ',';
            }
        }

        // Add score and likelihood headers for PPI surveys
        if (survey.IsPPI__c) {
            header += System.Label.SUBMISSION_PPISCORE.escapeCsv() + ',';

            for (PPITableDataSet__c tableDataSet : survey.PPI_Table_Data_Sets__r) {
                header += tableDataSet.PPITable__r.Name.escapeCsv() + ',';
            }
        }

        // Return removing the trailing comma
        return header.substring(0, header.length() - 1);
    }

    /**
     * Create the headers for the questions.
     * It supports cascading select questions and nested sections
     *
     * @param  questions               a list with the questions of the first level
     * @param  questionsData           a map with the data of all the questions in the survey
     * @param  maxInstanceByQuestionId a map with the max instance answer for the repeated questions
     * @param  isRepeated              indicates if the given list of questions is within a repeated section
     * @param  forPage                 indicates if the header is for the page to use the caption of the questions
     */
    private static String getQuestionsHeaders(
        List<Question__c> questions,
        Map<Id, Question__c> questionsData,
        Map<Id, Integer> maxInstanceByQuestionId,
        Id repeatedQuestionId,
        Boolean forPage
    ) {
        String header = '';

        // Add the headers for the questions
        // Questions query does not fetch sections and static questions, so all questions must be added
        for(Question__c question : questions) {
            // If the question has children dig in
            // This is done for cascading select questions but will be useful in the future for nested sections
            if(!QuestionDO.isLeaf(question)) {
                Id repeatedId = null;
                if(repeatedQuestionId == null && question.Type__c == QuestionDO.TYPE_REPEAT) {
                    repeatedId = question.Id;
                }

                header += getQuestionsHeaders(
                    questionsData.get(question.Id).Questions__r,
                    questionsData,
                    maxInstanceByQuestionId,
                    repeatedId,
                    forPage
                );
            }
            else {

                // Build a prefix for the question header if the question is a cascascading level
                String currentHeader = '';
                if(question.Type__c == QuestionDO.TYPE_CASCADING_LEVEL) {
                    currentHeader  = forPage
                        ? question.Parent__r.Caption__c + ' ' + question.Caption__c
                        : question.Parent__r.Name + '_' + question.Caption__c.replace(' ', '_').toLowerCase();
                } else {
                    if (forPage) {
                        currentHeader = question.Caption__c;
                    } else {
                        // Split header into 3 columns for GPS type of question
                        if (question.Type__c == QuestionDO.TYPE_GPS) {
                            currentHeader = question.Name + ' latitude and longitude;' + 
                                            question.Name + ' altitude;' + 
                                            question.Name + ' accuracy';
                        } else {
                            currentHeader = question.Name;
                        }
                    }
                }

                // 1887. Header for repeated questions. Add instance to question name.
                if (repeatedQuestionId != null) {
                    for (Integer i = 1; i <= maxInstanceByQuestionId.get(repeatedQuestionId); i ++) {
                        String instanceHeader = currentHeader + (forPage ? ' ' : '_') + i;
                        if (question.Type__c == QuestionDO.TYPE_GPS && !forPage) {
                            for (String gpsColumns : currentHeader.split(';', 0)) {
                                header += gpsColumns.escapeCsv() + ',';
                            }
                        } else {
                            header += instanceHeader.escapeCsv() + ',';
                        }
                    }
                } else {
                    if (question.Type__c == QuestionDO.TYPE_GPS && !forPage) {
                        for (String gpsColumns : currentHeader.split(';', 0)) {
                            header += gpsColumns.escapeCsv() + ',';
                        }
                    } else {
                        header += currentHeader.escapeCsv() + ',';
                    }
                }
            }
        }

        return header;
    }


    /**
     * Generates a row that contains the answers, scores and PPI probabilities for the given submission.
     *
     * @param  survey                  the survey record
     * @param  questionsData           a map with the data of all the questions in the survey
     * @param  submission              the submission to use as a soursrc/classes/SurveyResultsLogic.cls
     * @param  maxInstanceByQuestionId a map with the max instance answer for the repeated questions
     * @param  ppiValues               a list with the ppivalues for the submission
     * @param  contacts                a map with the contacts to get the data of the surveyors
     * @param  timeZoneSidKey          the time zone of the current user to format the dates
     * @param  forPage                 indicates if the row is for the page to prevent adding unneeded fields
     * @return                         a string with the row for the given submission in CSV format
     */
    public static String createSubmissionRow(
            Survey__c survey,
            Map<Id, Question__c> questionsData,
            Submission__c submission,
            Map<Id, Integer> maxInstanceByQuestionId,
            List<SubmissionPPIValue__c> ppiValues,
            Map<Id, Contact> contacts,
            String timeZoneSidKey,
            Boolean forPage
    ) {
        // Add the submission data to the row
        String rowString = '';

        // Add the data for the CSV
        if (!forPage) {
            rowString +=
                (submission.startDate__c != null
                    ? submission.startDate__c.format('yyyy-MM-dd HH:mm:ssZ', timeZoneSidKey).escapeCsv()
                    : ''
                ) + ',' +
                (submission.endDate__c != null
                    ? submission.endDate__c.format('yyyy-MM-dd HH:mm:ssZ', timeZoneSidKey).escapeCsv()
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
                ? contacts.get(submission.Surveyor__c).Name.escapeCsv()
                : ''
            ) + ',';

        // Add the answers
        rowString += getAnswers(
            survey.Questions__r,
            questionsData,
            submission,
            maxInstanceByQuestionId,
            forPage
        );

        // Add the score related data
        rowString += getScores(survey, submission);
        if (survey.IsPPI__c) {
            rowString += getPPITotalScore(survey, submission);
            rowString += getPPIScores(survey, ppiValues);
        }

        // Return removing the trailing comma
        return rowString.substring(0, rowString.length() - 1);
    }

    /**
     * Generates a row that contains the answers, scores and PPI probabilities for the given submission.
     *
     * @param  survey                  the survey record
     * @param  questionsData           a map with the data of all the questions in the survey
     * @param  submission              the submission to use as a soursrc/classes/SurveyResultsLogic.cls
     * @param  maxInstanceByQuestionId a map with the max instance answer for the repeated questions
     * @param  ppiAssociations         a list with the ppi associations for the submission
     * @param  contacts                a map with the contacts to get the data of the surveyors
     * @param  timeZoneSidKey          the time zone of the current user to format the dates
     * @param  forPage                 indicates if the row is for the page to prevent adding unneeded fields
     * @return                         a string with the row for the given submission in CSV format
     */
    public static String createSubmissionRow(
            Survey__c survey,
            Map<Id, Question__c> questionsData,
            Submission__c submission,
            Map<Id, Integer> maxInstanceByQuestionId,
            List<SubmissionPpiAssociation__c> ppiAssociations,
            Map<Id, Contact> contacts,
            String timeZoneSidKey,
            Boolean forPage
    ) {
        // Add the submission data to the row
        String rowString = '';

        // Add the data for the CSV
        if (!forPage) {
            rowString +=
                (submission.startDate__c != null
                    ? submission.startDate__c.format('yyyy-MM-dd HH:mm:ssZ', timeZoneSidKey).escapeCsv()
                    : ''
                ) + ',' +
                (submission.endDate__c != null
                    ? submission.endDate__c.format('yyyy-MM-dd HH:mm:ssZ', timeZoneSidKey).escapeCsv()
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
                ? contacts.get(submission.Surveyor__c).Name.escapeCsv()
                : ''
            ) + ',';

        // Add the answers
        rowString += getAnswers(
            survey.Questions__r,
            questionsData,
            submission,
            maxInstanceByQuestionId,
            forPage
        );

        // Add the score related data
        rowString += getScores(survey, submission);
        if (survey.IsPPI__c) {
            rowString += getPPITotalScore(survey, submission);
            rowString += getPPIScores(survey, ppiAssociations);
        }

        // Return removing the trailing comma
        return rowString.substring(0, rowString.length() - 1);
    }

    /**
     * Gets a map with the contacts related to the submissions
     *
     * @param  submissions a list of the submissions to process
     * @return             a map of contacts by its id
     */
    public static Map<Id, Contact> getContacts(List<Submission__c> submissions) {

        GenericObjectCreator contactCreator = new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(new List<String>{
            'Name'
        });

        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectAccessible();
        submissionCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Submission__c.Surveyor__c
        });

        // Build the query for the surveyors
        String query = 'SELECT Id, Name ' +
                       'FROM Contact ' +
                       'WHERE Id IN (SELECT Surveyor__c ' +
                                    'FROM Submission__c ' +
                                    'WHERE Id IN :listToFilter)';

        // Add the surveyors to the map
        Map<Id, Contact> contactsMap = new Map<Id, Contact>(
            (List<Contact>)DBFullAccess.querySObject(query, submissions)
        );
        return contactsMap;
    }

    /**
     * Generates the string with the answers for the row of the given submission
     * (Related to IDALMSA-1887)
     *
     * @param  questions               a list with the questions to get the data
     * @param  questionsData           a map with the data of all the questions in the survey
     * @param  submission              a submission to get the answers
     * @param  maxInstanceByQuestionId a map with the max instance answer for the repeated questions
     * @param  isInvokedFromPage       a boolean variable having true value when called from page and
                                       false value when called from csv
     * @return                         a comma-separated string with the answers sorted as the questions
     */
    private static String getAnswers(
        List<Question__c> questions,
        Map<Id, Question__c> questionsData,
        Submission__c submission,
        Map<Id, Integer> maxInstanceByQuestionId,
        Boolean isInvokedFromPage
    ) {
        GenericObjectCreator answerCreator =
            new GenericObjectCreator(Answer__c.SObjectType);
        answerCreator.checkObjectAccessible();
        answerCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Answer__c.Value__c,
                Answer__c.Instance__c
            }
        );

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Name,
                Question__c.Type__c
            }
        );

        GenericObjectCreator optionCreator =
            new GenericObjectCreator(Option__c.SObjectType);
        optionCreator.checkObjectAccessible();
        optionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Option__c.Name,
            Option__c.Caption__c
        });

        // Get the answers from the database
        List<Answer__c> theAnswers = [SELECT Id,
                                             Value__c,
                                             Instance__c,
                                             Question__r.Name,
                                             Question__r.Type__c,
                                             Option__r.Name,
                                             Option__r.Caption__c
                                      FROM   Answer__c
                                      WHERE  Submission__c = :submission.Id
                                      ORDER BY Instance__c, Option__r.Position__c];

        String result = '';

        // Build a map of the answers by question id
        Map<Id, Answer__c[]> answersByQuestionId = new Map<Id, Answer__c[]>();
        for(Answer__c answer : theAnswers) {
            // Generate the link for the answers of a media question
            if(answer != null && QuestionDO.isMedia(answer.Question__r.Type__c)) {
                answer.Value__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + C.DOWNLOAD_ATT_URL + answer.Value__c;
            }

            Answer__c[] answerList = answersByQuestionId.get(answer.Question__c);
            if (answerList == null) {
                answersByQuestionId.put(answer.Question__c, new Answer__c[] {answer});
            }
            else {
                answerList.add(answer);
            }
        }

        result += getAnswersData(
            questions,
            questionsData,
            submission,
            answersByQuestionId,
            maxInstanceByQuestionId,
            null,
            isInvokedFromPage
        );

        return result;
    }

    /**
     * Generates the string with the answers for the row of the given submission
     *
     * @param  questions               a list with the questions to get the data
     * @param  questionsData           a map with the data of all the questions in the survey
     * @param  submission              a submission to get the answers
     * @param  answersByQuestionId     a map with the answers for each question
     * @param  maxInstanceByQuestionId a map with the max instance answer for the repeated questions
     * @param  repeatedQuestionId      the id of the ancestor of type repeat if there is one
     * @param  isInvokedFromPage       a boolean variable having true value when called from page and
                                       false value when called from csv
     * @return                         a comma-separated string with the answers sorted as the questions
     */
    private static String getAnswersData(
        List<Question__c> questions,
        Map<Id, Question__c> questionsData,
        Submission__c submission,
        Map<Id, Answer__c[]> answersByQuestionId,
        Map<Id, Integer> maxInstanceByQuestionId,
        Id repeatedQuestionId,
        Boolean isInvokedFromPage
    ) {
        String result = '';

        // Iterate over the questions
        for(Question__c question : questions) {
            // If the question is not a leaf dig in
            // This is done for cascading select questions but will be useful in the future for nested sections
            if(!QuestionDO.isLeaf(question)) {
                Id repeatedId = null;
                if(repeatedQuestionId == null && question.Type__c == QuestionDO.TYPE_REPEAT) {
                    repeatedId = question.Id;
                }

                result += getAnswersData(
                    questionsData.get(question.Id).Questions__r,
                    questionsData,
                    submission,
                    answersByQuestionId,
                    maxInstanceByQuestionId,
                    repeatedId,
                    isInvokedFromPage
                );
            }
            else {
                // Get the answers for the current question
                Answer__c[] answers = answersByQuestionId.get(question.Id);

                Map<Integer, Answer__c[]> answerByInstance = new Map<Integer, Answer__c[]>();

                // IDALMSA-1887. If parent is repeated, need to list the answers by instance
                if(repeatedQuestionId != null) {
                    // Group the answers by instance
                    // This is needed for the multiselect questions where
                    // we can have more than one answer for an instance
                    if(answers != null) {
                        for(Answer__c ans : answers) {
                            Answer__c[] answerByInstanceList = answerByInstance.get(Integer.ValueOf(ans.Instance__c));

                            if(answerByInstanceList == null) {
                                answerByInstance.put(Integer.ValueOf(ans.Instance__c), new Answer__c[] {ans});
                            }
                            else {
                                answerByInstanceList.add(ans);
                            }
                        }
                    }

                    for(Integer i = 1; i <= maxInstanceByQuestionId.get(repeatedQuestionId); i ++) {
                        // IDALMSA-1887. Filling blanks spaces for each instance of question that was not answered
                        if (answerByInstance.get(i) == null) {
                            result += (
                                question.Type__c == QuestionDO.TYPE_GPS && 
                                !isInvokedFromPage
                            ) ? ',,,' : ',';
                        } else {
                            // IDALMSA-1887. For each answer of that instance fill the cell with data
                            if (question.Type__c == QuestionDO.TYPE_GPS && !isInvokedFromPage) {
                                // Split GPS submitted value into 3 columns for repeated GPS question
                                result += splitGPSForCsv(answerByInstance.get(i)[0].Value__c);
                            } else {
                                result += joinAnswers(
                                    answerByInstance.get(i),
                                    isInvokedFromPage
                                ).escapeCsv() + ',';
                            }
                        }
                    }
                }
                // IDALMSA-1887. Question not repeated
                else {
                    // IDALMSA-1887. If it was answered fill the cell with data
                    if (answers != null) {
                        if (question.Type__c == QuestionDO.TYPE_GPS && !isInvokedFromPage) {
                            // Split GPS submitted value into 3 columns for regular GPS question
                            result += splitGPSForCsv(answers[0].Value__c);
                        } else {
                            result += joinAnswers(answers, isInvokedFromPage).escapeCsv() + ',';
                        }
                    }
                    // IDALMSA-1887. Fill with blank space
                    else {
                        result += (
                            question.Type__c == QuestionDO.TYPE_GPS &&
                            !isInvokedFromPage
                        ) ? ',,,' : ',';
                    }
                }
            }
        }
        return result;
    }

    /**
     * Distributes the submitted GPS answer into three different columns
     *
     * @param  gpsValue contains a space separated string with submitted values of latitude longitude
                        altitude approximation 
     * @return          a comma separated string of latitude and longitude,altitude,approximation
     */
    private static String splitGPSForCsv(String gpsValue) {
        String splitResult = '';
        SurveyUtils.GeoLocation parsedLocationField = 
            SurveyUtils.parseGeoLocation(gpsValue, true);
        splitResult += (
                parsedLocationField.latitude + ', ' +
                parsedLocationField.longitude
            ).escapeCsv() + ',' +
            parsedLocationField.altitude + ',' +
            parsedLocationField.aproximation  + ',' ;
        return splitResult;
    }

    /**
     * Gets the PPI total score to add to the submission row
     * (Related to IDALMSA-2939)
     *
     * @param  submission a submission to get the PPI total score
     * @return            a string with the PPI score
     */
    private static String getPPITotalScore(Survey__c survey, Submission__c submission) {
        String result = '';
        if(submission.PPIScore__c == null) {
            result = 0 + ',';
        }
        else if(submission.PPIScore__c < 0 || submission.PPIScore__c > 100) {
            result = ',';
        }
        else {
            result = submission.PPIScore__c + ',';
        }

        return result;
    }

    /**
     * Gets the scores to add to the submission row
     * sorted in the same order as the groups were retrieved.
     *
     * @param  submission a submission to get the scores
     * @return            a comma-separated string with the scores sorted in the same order as the scoring groups
     */
    private static String getScores(Survey__c survey, Submission__c submission) {
        String result = '';
        Map<Id,Decimal> scores = new Map<Id,Decimal>();
        for (SubmissionScore__c score : submission.SubmissionScore__r) {
            scores.put(score.ScoringGroup__c, score.TotalScore__c);
        }
        for (ScoringGroup__c scoringGroup : survey.Scoring_Groups__r) {
            if (!scoringGroup.IsPPi__c) {
                Decimal score = scores.get(scoringGroup.Id);
                result += (score == null ? 0 : score) + ',';
            }
        }
        return result;
    }

    /**
     * Gets the PPI score for each PPI table
     * Returns a comma-separated list of PPI probabilities from the submission,
     * sorted in the same order as the PPI tables were retrieved.
     *
     * @param  ppiValues a list with the Submission PPI Values of the submission
     * @return           a comma-separated string with the PPI likelihood for each PPI table
     */
    private static String getPPIScores(Survey__c survey, List<SubmissionPPIValue__c> ppiValues) {
        String result = '';
        Map<Id, Decimal> ppiScores = new Map<Id, Decimal>();
        for (SubmissionPPIValue__c ppiScore : ppiValues) {
            ppiScores.put(
                ppiScore.PPITableLine__r.PPITableDataSet__c,
                ppiScore.PPITableLine__r.Probability__c
            );
        }

        for (PPITableDataSet__c dataset : survey.PPI_Table_Data_Sets__r) {
            Decimal score = ppiScores.get(dataset.Id);
            result += (score == null ? 0 : score) + ',';
        }

        return result;
    }

    /**
     * Gets the PPI score for each PPI table
     * Returns a comma-separated list of PPI probabilities from the submission,
     * sorted in the same order as the PPI tables were retrieved.
     *
     * @param  ppiAssociations a list with the Submission PPI Associations of the submission
     * @return           a comma-separated string with the PPI likelihood for each PPI table
     */
    private static String getPPIScores(
            Survey__c survey,
            List<SubmissionPpiAssociation__c> ppiAssociations
    ) {
        String result = '';
        Map<Id, Decimal> ppiScores = new Map<Id, Decimal>();
        for (SubmissionPpiAssociation__c ppiScore : ppiAssociations) {
            Decimal score = ppiScore.PPITableLine__r.Probability__c;
            result += (score == null ? 0 : score) + ',';
        }
        return result;
    }

    /**
     * Converts an array of awnswers into a single, semicolon separated string.
     * Used for repeated sections.
     * (Related to IDALMSA-1887)
     *
     * @param  answers           a list of answers to format
     * @param  isInvokedFromPage a boolean variable having true value when called from page and
                                 false value when called from csv
     * @return                   a semicolon-separated string with the answers
     */
    private static String joinAnswers(Answer__c[] answers, Boolean isInvokedFromPage) {
        String result = '';
        Integer remaining = answers.size();
        for(Answer__c answer : answers) {
            if(answer.Question__r.Type__c == QuestionDO.TYPE_CHECKBOX) {
                result += answer.Value__c + (--remaining > 0 ? ';' : '');
            } else if (answer.Question__r.Type__c == QuestionDO.TYPE_GPS && isInvokedFromPage) {
                SurveyUtils.GeoLocation parsedLocationField = 
                    SurveyUtils.parseGeoLocation(answer.Value__c, true);
                if (parsedLocationField != null) {
                    // Append question type for GPS question to distinguish on Page
                    result += answer.Question__r.Type__c + '~' + parsedLocationField.latitude + 
                        '|' + parsedLocationField.longitude + (--remaining > 0 ? ';' : '');
                }
            } else {
                result += answer.Value__c + (--remaining > 0 ? ',' : '');
            }
        }
        return result;
    }

    /**
     * Generates a map with the max instance answer for the repeated questions.
     * This is used to know the amount of columns for the repeated questions.
     *
     * @param  surveyId the id of the current survey
     * @return          a map with the max instance for each repeated question
     */
    public static Map<Id, Integer> getMaxInstanceMap(Id surveyId) {
        Map<Id, Integer> resultMap = new Map<Id, Integer>();
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.MaxInstance__c
            }
        );
        for (Question__c questionInstance : [
	                                            SELECT
	                                                Id,
	                                                MaxInstance__c
	                                            FROM
	                                                Question__c
	                                            WHERE
	                                                Survey__c = :surveyId
	                                            AND
	                                                Type__c = :QuestionDO.TYPE_REPEAT
                                            ]
        ) {
            resultMap.put(questionInstance.Id, (Integer)questionInstance.MaxInstance__c);
        }
        return resultMap;
    }
}