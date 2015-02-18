/*
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*/
public with sharing class SurveyCsvExport {

    private transient Map<Id, Integer> maxInstanceByQuestionId = new Map<Id, Integer>(); // Map to get the max instance of the answer
    private Map<Id, Contact> contacts = null;

    public String getUserLanguage() {
      return C.getUserLanguage();
    }
    /**
     * For each answer of the submission, get the max instance of the question.
     * IDALMSA-1887
     *
     * @param List of submissions
     * @return Map of max instance (Integer) by question id.
     */
    public Map<Id, Integer> loadMaxInstanceMap(Submission__c[] submissions) {
        maxInstanceByQuestionId = new Map<Id, Integer>();
        for (Submission__c submission : submissions) {
            for (Answer__c answer : submission.Answers__r) {
                // 1887. Only for those answers for a question within a repeated section
                if (answer.Instance__c != null) {
                    if (
                        maxInstanceByQuestionId.get(answer.Question__c) == null ||
                        maxInstanceByQuestionId.get(answer.Question__c) < answer.Instance__c
                    ) {
                        maxInstanceByQuestionId.put(
                            answer.Question__c,
                            Integer.ValueOf(answer.Instance__c)
                        );
                    }
                }
            }
        }
        return maxInstanceByQuestionId;
    }

    /**
     * Allow the process to get the name of the contacts involved in submissions,
     * even if the current user does not have access to them.
     * This is needed because if the 'without sharing' rule is applied to the
     * whole class, then the process may have access to submission records that
     * the current user should not have access.
     * @param submissions the list of submissions from which to take contact ids
     * @return a map of contacts by their Id, containing their name
     */
    private Map<Id, Contact> getContacts(List<Submission__c> submissions) {
        Set<Id> contactIds = new Set<Id>();
        for (Submission__c submission : submissions) {
            contactIds.add(submission.Surveyor__c);
        }
        contactIds.remove(null);
        GenericObjectCreator contactCreator = new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(new List<String>{'Name'});
        StringBuilder.CommaSeparatedBuilder commaSeparatedBuilder =
            new StringBuilder.CommaSeparatedBuilder(contactIds);
        commaSeparatedBuilder.setShouldEscapeSingleQuotes(true);
        if (contactIds.size() > 0) {
            StringBuilder.InClauseBuilder inClauseBuilder = new StringBuilder.InClauseBuilder();
            inClauseBuilder.addAll(contactIds);
            List<Contact> contactList =
                DBFullAccess.querySObject(
                    'SELECT ' +
                        'Id, ' +
                        'Name ' +
                    'FROM ' +
                        'Contact ' +
                    'WHERE ' +
                        'Id IN (' + inClauseBuilder.generateString() + ')'
                );
            Map<Id, Contact> contacts = new Map<Id, Contact>(contactList);
            return contacts;
        }
        return new Map<Id, Contact>();
    }

    /**
     * Generates the content of a CSV file containing the submissions
     * for the given survey, or the given submissions.
     * @return A string which is the content of the CSV file.
     */
    public String getCsvString(){
        String surveyId = ApexPages.currentPage().getParameters().get('surveyid');
        String stringSubmissions =
            ApexPages.currentPage().getParameters().get('selectedSurveysAnswerId');

        String[] answerIdsParam;

        if (stringSubmissions != null && stringSubmissions != '') {
            answerIdsParam = stringSubmissions.split(',',0);
        } else {
            answerIdsParam = new String[]{};
        }

        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectAccessible();
        submissionCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Submission__c.Survey__c,
            Submission__c.StartDate__c,
            Submission__c.EndDate__c,
            Submission__c.Date__c,
            Submission__c.Gps_x__c,
            Submission__c.Gps_y__c,
            Submission__c.PPIScore__c,
            Submission__c.Surveyor__c
        });
        GenericObjectCreator answerCreator =
            new GenericObjectCreator(Answer__c.SObjectType);
        answerCreator.checkObjectAccessible();
        answerCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Answer__c.Question__c,
                Answer__c.Option__c,
                Answer__c.Instance__c,
                Answer__c.Value__c
            }
        );
        GenericObjectCreator optionCreator =
            new GenericObjectCreator(Option__c.SObjectType);
        optionCreator.checkObjectAccessible();
        optionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Option__c.Name,
            Option__c.Caption__c
        });
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Question__c.Name,
            Question__c.Type__c,
            Question__c.Caption__c,
            Question__c.Parent__c
        });
        GenericObjectCreator submissionScoreCreator =
            new GenericObjectCreator(SubmissionScore__c.SObjectType);
        submissionScoreCreator.checkObjectAccessible();
        submissionScoreCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            SubmissionScore__c.TotalScore__c,
            SubmissionScore__c.ScoringGroup__c
        });
        GenericObjectCreator ppiTableLineCreator =
            new GenericObjectCreator(PPITableLine__c.SObjectType);
        ppiTableLineCreator.checkObjectAccessible();
        ppiTableLineCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            PPITableLine__c.Probability__c,
            PPITableLine__c.PPITableDataSet__c
        });

        GenericObjectCreator submissionPpiValueCreator =
            new GenericObjectCreator(SubmissionPPIValue__c.SObjectType);
        submissionPpiValueCreator.checkObjectAccessible();
        submissionPpiValueCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            SubmissionPPIValue__c.PPITableLine__c
        });

        Submission__c[] submissions = [
            SELECT
                Id,
                Survey__c,
                StartDate__c,
                EndDate__c,
                Date__c,
                Gps_x__c,
                Gps_y__c,
                PPIScore__c,
                Surveyor__c,
                (
                    SELECT
                        Id,
                        Value__c,
                        Instance__c,
                        Question__r.Name,
                        Question__r.Type__c,
                        Option__r.Name,
                        Option__r.Caption__c
                    FROM
                        Answers__r
                        ORDER BY Instance__c, Option__r.Position__c
                ),
                (
                    SELECT
                        Id,
                        TotalScore__c,
                        ScoringGroup__c
                    FROM
                        SubmissionScore__r
                        ORDER BY ScoringGroup__c
                ),
                (
                    SELECT
                        Id,
                        PPITableLine__c,
                        PPITableLine__r.Probability__c,
                        PPITableLine__r.PPITableDataSet__c
                    FROM
                        Submition_PPI_Values__r
                )
            FROM
                Submission__c
            WHERE
                Id IN :answerIdsParam OR Survey__c = :surveyId
                ORDER BY StartDate__c, Id
        ];

        contacts = getContacts(submissions);

        if (surveyId == null) {
            surveyId = submissions.isEmpty() ? null : submissions[0].Survey__c;
        }

        return exportToCsv(surveyId, submissions);
    }

    /**
     * Creates the content of the CSV file
     * @param surveyId The Id of the survey to export.
     * @param submissions The list of submissions that will be exported in the file, including their children.
     * @return A string which is the content of the CSV file.
     */
    private String exportToCsv(Id surveyId, Submission__c[] submissions){

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Survey__c.IsPPI__c
        });
        GenericObjectCreator scoringGroupCreator =
            new GenericObjectCreator(ScoringGroup__c.SObjectType);
        scoringGroupCreator.checkObjectAccessible();
        scoringGroupCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            ScoringGroup__c.Caption__c
        });
        GenericObjectCreator ppiTableDataSetCreator =
            new GenericObjectCreator(PPITableDataSet__c.SObjectType);
        ppiTableDataSetCreator.checkObjectAccessible();
        ppiTableDataSetCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                PPITableDataSet__c.PPITable__c
            }
        );
        GenericObjectCreator ppiTableCreator =
            new GenericObjectCreator(PPITable__c.SObjectType);
        ppiTableCreator.checkObjectAccessible();
        ppiTableCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                PPITable__c.Name
            }
        );

        // Get information from the survey
        Survey__c survey = [
            SELECT
                Id,
                IsPPI__c,
                (
                    SELECT
                        Id,
                        Name,
                        Caption__c,
                        Type__c,
                        Parent__r.Type__c
                    FROM
                        Questions__r
                    WHERE
                        Type__c NOT IN (
                            :QuestionDO.TYPE_SECTION,
                            :QuestionDO.TYPE_REPEAT,
                            :QuestionDO.TYPE_STATIC,
                            :QuestionDO.TYPE_FINAL
                        )
                    ORDER BY Parent__r.Position__c, Position__c
                ),
                (
                    SELECT
                        Id,
                        Caption__c
                    FROM
                        Scoring_Groups__r
                        ORDER BY Id
                ),
                (
                    SELECT
                        PPITable__c,
                        PPITable__r.Name
                    FROM
                        PPI_Table_Data_Sets__r
                        ORDER BY Name ASC
                )
            FROM
                Survey__c
            WHERE
                Id = :surveyId
        ];

        String content = '';

        // Generate the content of the CSV file
        content = createHeaderRow(survey, submissions);

        GenericObjectCreator userCreator =
            new GenericObjectCreator(User.SObjectType);
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                User.TimeZoneSidKey
            }
        );

        User currentUser = [
            SELECT
                Id,
                TimeZoneSidKey
            FROM
                User
            WHERE
                Id = :UserInfo.getUserId()
        ];
        for (Submission__c submission : submissions) {
            content += createSubmissionRow(survey, submission, currentUser.TimeZoneSidKey);
        }

        return content;
    }

    /**
     * Sets the header row for the csv file, only need to be called once.
     * IDALMSA-1887
     *
     * @param Survey
     * @param List of submissions
     * @return String result of the header to export
     */
    private String createHeaderRow(Survey__c survey, Submission__c[] submissions){
        Map<String, Schema.SobjectField> fieldsMap = Schema.SObjectType.Submission__c.fields.getMap();
        String startDateLabel   = fieldsMap.get('startDate__c').getDescribe().getLabel();
        String endDateLabel     = fieldsMap.get('endDate__c').getDescribe().getLabel();
        String dateLabel        = fieldsMap.get('Date__c').getDescribe().getLabel();
        String gpsXLabel        = fieldsMap.get('gps_x__c').getDescribe().getLabel();
        String gpsYLabel        = fieldsMap.get('gps_y__c').getDescribe().getLabel();
        String surveyorLabel    = fieldsMap.get('Surveyor__c').getDescribe().getLabel();

        String header_subm_data = '"'
            + startDateLabel + '","'
            + endDateLabel + '","'
            + dateLabel + '","'
            + gpsXLabel + '","'
            + gpsYLabel + '","'
            + surveyorLabel + '",';

        String result = header_subm_data;
        // 1887. Fill map with max instances to use it
        maxInstanceByQuestionId = loadMaxInstanceMap(submissions);

        // Questions query does not fetch sections and static questions, so I know all questions are to be output.
        for (Question__c question : survey.Questions__r) {
            // 1887. Header for repeated questions. Add instance to question name.
            if (question.Parent__r.Type__c == QuestionDO.TYPE_REPEAT) {
                for (Integer i = 1; i <= maxInstanceByQuestionId.get(question.Parent__c); i++) {
                    result += '"' +  question.Name + '_' + i + '",';
                }
            } else {
                result += '"' +  question.Name + '",';
            }
        }

        for (ScoringGroup__c sg : survey.Scoring_Groups__r) {
            result += '"'+ sg.Caption__c + '",';
        }

        if (survey.IsPPI__c) {
            result += '"' + System.Label.SUBMISSION_PPISCORE + '",';
        }

        for (PPITableDataSet__c dataSets : survey.PPI_Table_Data_Sets__r) {
            result += '"' + dataSets.PPITable__r.Name + '",';
        }

        return result + '\n';
    }

    /**
     * Generates a row that contains the answers, scores and PPI probabilities for the given submission.
     * Precondition: createHeaderRow must be previosly called to generate Columns.
     *
     * @param survey         - the survey that the submission is related to
     * @param submission     - the submission to use as a source for the row
     * @param timeZoneSidKey - the timezone of the current user to format the dates
     * @return a tring with the row for the given submission
     */
    private String createSubmissionRow(Survey__c survey, Submission__c submission, String timeZoneSidKey){
        String rowString = '"'
            + (submission.startDate__c   != null ? submission.startDate__c.format('yyyy-MM-dd HH:mm:ssZ', timeZoneSidKey) : '') + '","'
            + (submission.endDate__c     != null ? submission.endDate__c.format('yyyy-MM-dd HH:mm:ssZ', timeZoneSidKey)   : '') + '","'
            + (submission.Date__c        != null ? String.valueOf(submission.Date__c)                                     : '') + '","'
            + (submission.gps_x__c       != null ? String.valueOf(submission.gps_x__c)                                    : '') + '","'
            + (submission.gps_y__c       != null ? String.valueOf(submission.gps_y__c)                                    : '') + '","'
            + (submission.Surveyor__c    != null ? contacts.get(submission.Surveyor__c).Name                              : '') + '",';

        rowString += getAnswers(survey, submission);
        rowString += getScores(survey, submission);
        rowString += getPPITotalScore(survey, submission);
        rowString += getPPIScores(survey, submission);

        return rowString + '\n';
    }

    /**
     * Returns the total submission score for the submission.
     * IDALMSA-2939
     *
     * @param Survey
     * @param Submission to get the answers
     * @return String result to export
     */

    private String getPPITotalScore(Survey__c survey, Submission__c submission) {
        String result = '';
        if (survey.IsPPI__c) {
            if (submission.PPIScore__c == null) {
                result = 0 + ',';
            } else if (submission.PPIScore__c < 0 || submission.PPIScore__c > 100) {
                result = ',';
            } else {
                result = submission.PPIScore__c + ',';
            }
        }
        return result;
    }

    /**
     * Returns a comma-separated list of answers from the submission,
     * sorted as the questions in the survey.
     * IDALMSA-1887
     *
     * @param Survey
     * @param Submission to get the answers
     * @return String result to export
     */
    private String getAnswers(Survey__c survey, Submission__c submission) {
        String result = '';
        Map<Id,Answer__c[]> answersByQuestionId = new Map<Id,Answer__c[]>();
        for (Answer__c answer : submission.Answers__r) {
            if (answer != null && QuestionDO.isMedia(answer.Question__r.Type__c)) {
                answer.Value__c = 
                    URL.getSalesforceBaseUrl().toExternalForm()
                    +'/servlet/servlet.FileDownload?file='
                    + answer.Value__c;
            }

            Answer__c[] answerList = answersByQuestionId.get(answer.Question__c);

            if (answerList == null) {
                answersByQuestionId.put(answer.Question__c, new Answer__c[]{answer});
            } else {
                answerList.add(answer);
            }
        }
        for (Question__c question : survey.Questions__r) {
            Answer__c[] answers = answersByQuestionId.get(question.Id);
            Map<Integer,Answer__c[]> answerByInstance = new Map<Integer,Answer__c[]>();
            // IDALMSA-1887. If parent is repeated, need to list the answers by instance
            if (question.Parent__r.Type__c == QuestionDO.TYPE_REPEAT) {
                if (answers != null) {
                    for (Answer__c ans : answers) {
                        Answer__c[] answerByInstanceList =
                            answerByInstance.get(Integer.ValueOf(ans.Instance__c));

                        if (answerByInstanceList == null) {
                            answerByInstance.put(Integer.ValueOf(ans.Instance__c), new Answer__c[]{ans});
                        } else {
                            answerByInstanceList.add(ans);
                        }
                    }
                }
                for (Integer i=1; i <= maxInstanceByQuestionId.get(question.Parent__c); i++) {
                    // IDALMSA-1887. Filling blanks spaces for each instance of question that was not answered
                    if (answerByInstance.get(i) == null) {
                        result +=',';
                    } else {
                        // IDALMSA-1887. For each answer of that instance fill the cell with data
                        result += '"' + joinAnswers(answerByInstance.get(i)).replace('"','""') + '",';
                    }
                }
            }
            // IDALMSA-1887. Question not repeated
            else {
                // IDALMSA-1887. If it was answered fill the cell with data
                if (answers != null)
                    result += '"' + joinAnswers(answers).replace('"','""') + '",';
                // IDALMSA-1887. Fill with blank space
                else
                    result +=',';
            }
        }
        return result;
    }

    /**
     * Returns a comma-separated list of the submission's score in different groups,
     * sorted in the same order as the groups were retrieved.
     */
    private String getScores(Survey__c survey, Submission__c submission) {
        String result = '';
        Map<Id,Decimal> scores = new Map<Id,Decimal>();
        for (SubmissionScore__c score : submission.SubmissionScore__r) {
            scores.put(score.ScoringGroup__c, score.TotalScore__c);
        }
        for (ScoringGroup__c scoringGroup : survey.Scoring_Groups__r) {
            Decimal score = scores.get(scoringGroup.Id);
            result += (score == null ? 0 : score) + ',';
        }
        return result;
    }

    /**
     * Returns a comma-separated list of PPI probabilities from the submission,
     * sorted in the same order as the PPI tables were retrieved.
     */
    private String getPPIScores(Survey__c survey, Submission__c submission) {
        String result = '';
        Map<Id,Decimal> ppiScores = new Map<Id,Decimal>();
        for (SubmissionPPIValue__c ppiScore : submission.Submition_PPI_Values__r) {
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
     * Return an array of awnswers into a single, semicolon separated string,
     * when is a repeated section.
     * IDALMSA-1887
     *
     * @param List of answers to format
     * @return String result to export
     */
    private String joinAnswers(Answer__c[] answers) {
        String result = '';
        Integer remaining = answers.size();
        for (Answer__c answer : answers) {
            if (answer.Question__r.Type__c == QuestionDO.TYPE_CHECKBOX) {
                result += answer.Value__c + (--remaining > 0 ? ';' : '');
            } else {
                result += answer.Value__c + (--remaining > 0 ? '","' : '');
            }
        }
        return result;
    }
}
