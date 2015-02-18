/**
 * Batchable class to export CSV in a background process
 *
 * TODO - Convert this class based on SOC and UOW
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio
 * @author Kaushik Ray
 */
global class ExportCsvBatch implements Database.Batchable<sObject>, Database.Stateful {

    // Max size of email attachment (5 MB)
    private static final Integer EMAIL_MAX_ATT_SIZE = 5242880;
    // Amount of queries needed to finish the process
    private static final Integer LIMIT_QUERIES = 5;
    // Amount of rows needed to finish the process
    private static final Integer LIMIT_QUERY_ROWS = 5;
    // Amount of emails needed to finish the process
    private static final Integer LIMIT_EMAIL_INVOCATIONS = 5;
    // Max amount of query rows
    private static final Integer MAX_QUERY_ROWS = 40000;

    // The record of the survey that the submissions belong
    global final Survey__c survey;
    // The questions data
    global final Map<Id, Question__c> questionsData;
    // A list with the ids of the submissions selected by the user
    global final List<String> selectedSubmissions;
    // The email address to send the CSV file
    global final String email;
    // The timezone sid key for the user that requested the CSV
    // Used to format the datetime fields
    global final String timeZoneSidKey;
    // A map with the max instance answer for the repeated questions
    // This is used to know the amount of columns for the repeated questions
    global final Map<Id, Integer> maxInstanceByQuestionId;
    // The header row for the CSV file
    global final String headerRow;
    // The content of the CSV file
    global String content;
    // Amount of sent records
    global Integer sentRecords;
    // Amount of processedrecords in the last execution
    global Integer processedRecords;
    // Submissions that were not processed because of limits issues
    global List<Submission__c> unprocessedSubmissions;

    /**
     * Constructor of the class
     */
    global ExportCsvBatch(String survey, List<String> submissions, String userTimeZoneSidKey) {
        // Save the received parameters
        this.selectedSubmissions = submissions;
        this.timeZoneSidKey = userTimeZoneSidKey;
        this.sentRecords = 0;
        this.processedRecords = 0;
        this.unprocessedSubmissions = new List<Submission__c>();

        // Initialize the map with the max instance for the repeated questions
        this.maxInstanceByQuestionId = SurveyResultsLogic.getMaxInstanceMap(survey);

        // Get information from the survey
        // Survey + Question + ScoringGroup + PPITableDataSet
        this.survey = SurveyDO.getSurveyDataForResults(survey);
        this.questionsData = SurveyDO.getQuestionsDataForResults(survey);

        // Save the header row
        this.headerRow = SurveyResultsLogic.createHeaderRow(
            this.survey,
            this.questionsData,
            this.maxInstanceByQuestionId,
            false
        );
        // Add the header to the content
        this.content = this.headerRow;
    }

    // IDALMSA-4759 need to keep this constructor because it's already packaged.
    global ExportCsvBatch(String survey, List<String> submissions, String userEmail, String userTimeZoneSidKey) {}

    global Database.QueryLocator start(Database.BatchableContext BC) {
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Contact.Name
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

        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectAccessible();
        submissionCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Submission__c.Survey__c,
            Submission__c.StartDate__c,
            Submission__c.EndDate__c,
            Submission__c.Date__c,
            Submission__c.Device__c,
            Submission__c.Gps_x__c,
            Submission__c.Gps_y__c,
            Submission__c.PPIScore__c,
            Submission__c.Surveyor__c,
            Submission__c.Interviewee__c,
            Submission__c.Status__c,
            Submission__c.AnswersCount__c
        });

        return (this.selectedSubmissions != null && this.selectedSubmissions.size() > 0)
            ? Database.getQueryLocator(
                [
                    SELECT
                        Id,
                        Survey__c,
                        StartDate__c,
                        EndDate__c,
                        Date__c,
                        Device__c,
                        Gps_x__c,
                        Gps_y__c,
                        PPIScore__c,
                        Surveyor__c,
                        Surveyor__r.Name,
                        Interviewee__c,
                        Interviewee__r.Name,
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
                       ),
                       (
                            SELECT
                                Id,
                                PPITableLine__c,
                                PPITableLine__r.Probability__c,
                                PPITableLine__r.PPITableDataSet__c
                            FROM
                                Submission_Ppi_Associations__r
                       )
                 FROM
                    Submission__c
                 WHERE
                    Id IN :this.selectedSubmissions
                    ORDER BY StartDate__c, Id
                ]
            ) : Database.getQueryLocator(
                    [
                        SELECT
                            Id,
                            Survey__c,
                            StartDate__c,
                            EndDate__c,
                            Date__c,
                            Device__c,
                            Gps_x__c,
                            Gps_y__c,
                            PPIScore__c,
                            Surveyor__c,
                            Surveyor__r.Name,
                            Interviewee__c,
                            Interviewee__r.Name,
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
                            ),
                            (
                                SELECT
                                    Id,
                                    PPITableLine__c,
                                    PPITableLine__r.Probability__c,
                                    PPITableLine__r.PPITableDataSet__c
                                FROM
                                    Submission_Ppi_Associations__r
                           )
                        FROM
                            Submission__c
                        WHERE
                            Survey__c = :this.survey.Id
                            AND (Status__c = :C.SUBMISSION_STATUS_UPLOADED
                            OR Status__c = :C.SUBMISSION_STATUS_UPLOADED_AUTO)
                            ORDER BY StartDate__c, Id]
              );
    }

    global void execute(Database.BatchableContext BC, List<Submission__c> batch) {
        this.unprocessedSubmissions.addAll(batch);
        processRecords(false);
    }

    global void finish(Database.BatchableContext BC) {
        Boolean allRecordsProcessed = true;
        // If there are unprocessed records, process them
        if(!this.unprocessedSubmissions.isEmpty()) {
            allRecordsProcessed = processRecords(true);
        }

        // If there is some content, send it by email
        if(allRecordsProcessed && this.content.length() > 0) {
            sendCsvEmail(this.sentRecords + 1, this.sentRecords + this.processedRecords, true);
        }
    }

    /**
     * Process submission records
     *
     * @param  lastBatch indicates if this is the last call for processing
     *                   records to send proper email
     * @return           true if the process finished succesfully, or false
     *                   if aborted because of limits issues
     */
    private Boolean processRecords(Boolean lastBatch) {
        // Fetch the contacts data
        Map<Id, Contact> contactsById = SurveyResultsLogic.getContacts(this.unprocessedSubmissions);
        Integer submissionsToProcess = this.unprocessedSubmissions.size();
        Map<Id, List<SubmissionPPIValue__c>> ppiValuesBySubmission;
        Map<Id, List<SubmissionPPIAssociation__c>> ppiAssociationsBySubmission;
        if (this.survey.IsPPI__c) {
            if (SurveyDO.isNewPpiSurvey(this.survey)) {
                ppiAssociationsBySubmission =
                    SubmissionDO.getSubmissionPpiAssociations(this.unprocessedSubmissions);
            } else {
                ppiValuesBySubmission =
                    SubmissionDO.getSubmissionsPPIValues(this.unprocessedSubmissions);
            }
        } else {
            ppiValuesBySubmission = new Map<Id, List<SubmissionPPIValue__c>>();
        }

        // Generate the rows for the given submissions
        // Also if there are pending submissions, they are processed too
        for (Integer i = 0; i < submissionsToProcess; i ++) {
            // Check Salesforce limits
            if (!tooCloseToTheLimits()) {
                Submission__c submission = this.unprocessedSubmissions.remove(0);

                String tmpRow = '';
                if (SurveyDO.isNewPpiSurvey(survey)) {
                    tmpRow = SurveyResultsLogic.createSubmissionRow(
                        this.survey,
                        this.questionsData,
                        submission,
                        this.maxInstanceByQuestionId,
                        ppiAssociationsBySubmission.get(submission.Id),
                        contactsById,
                        this.timeZoneSidKey,
                        false
                    );
                } else {
                    tmpRow = SurveyResultsLogic.createSubmissionRow(
                        this.survey,
                        this.questionsData,
                        submission,
                        this.maxInstanceByQuestionId,
                        ppiValuesBySubmission.get(submission.Id),
                        contactsById,
                        this.timeZoneSidKey,
                        false
                    );
                }
                

                // If the content plus the current row exceeds the attachment limit send the
                // content and continue with the process
                if(sizeInBytes(this.content + tmpRow) > EMAIL_MAX_ATT_SIZE) {
                    sendCsvEmail(this.sentRecords + 1, this.sentRecords + this.processedRecords, false);
                    // Reset the content for the next email
                    this.content = this.headerRow;
                    this.sentRecords += this.processedRecords;
                    this.processedRecords = 0;
                }

                this.content += '\n' + tmpRow;
                this.processedRecords ++;
            }
            else {
                if(lastBatch) {
                    // If some records still unprocessed and the limits were hit send an error to the user
                    sendLimitsErrorEmail(
                        this.sentRecords + 1,
                        this.sentRecords + this.processedRecords,
                        this.unprocessedSubmissions.size()
                    );
                }
                else {
                    sendCsvEmail(this.sentRecords + 1, this.sentRecords + this.processedRecords, false);
                }

                // Reset the content for the next email
                this.content = this.headerRow;
                this.sentRecords += this.processedRecords;
                this.processedRecords = 0;
                return false;
            }
        }

        return true;
    }

    /**
     * Checks the Salesforce limits.
     * Limits: Queries
     *         Query rows
     *         Email invocations
     *
     * @return true if the limits are too close
     */
    private Boolean tooCloseToTheLimits() {
        return Limits.getLimitQueries() - Limits.getQueries() < LIMIT_QUERIES
            || Limits.getLimitQueryRows() - Limits.getQueryRows() < LIMIT_QUERY_ROWS
            || Limits.getLimitEmailInvocations() - Limits.getEmailInvocations() < LIMIT_EMAIL_INVOCATIONS;
    }

    /**
     * Sends an email with the error of the limits being hit
     *
     * @param   firstRecord      the first record included
     * @param   lastRecord       the last record included
     * @param   penidingRecords  the amount of unprocessed records
     */
    private void sendLimitsErrorEmail(
        Integer firstRecord,
        Integer lastRecord,
        Integer pendingRecords
    ) {

        Messaging.SingleEmailMessage mail = EmailUtils.createSingleEmailForCurrentUser();
        mail.setSenderDisplayName(System.label.SURVEY_CSV_EMAILSENDERNAME);
        mail.setSubject(System.Label.SURVEY_CSV_LIMITSEMAILSUBJECT);
        mail.setPlainTextBody(
            String.format(
                System.Label.SURVEY_CSV_LIMITSEMAILBODY,
                new String[] {
                    this.survey.Name,
                    String.valueOf(firstRecord), String.valueOf(lastRecord),
                    String.valueOf(lastRecord + 1), String.valueOf(lastRecord + pendingRecords),
                    String.valueOf(Limits.getQueries()), String.valueOf(Limits.getLimitQueries()),
                    String.valueOf(Limits.getQueryRows()), String.valueOf(Limits.getLimitQueryRows()),
                    String.valueOf(Limits.getEmailInvocations()), String.valueOf(Limits.getLimitEmailInvocations())
                }
            ) + '\n\n' + System.label.SURVEY_CSV_EMAILSIGNATURE.unescapeEcmaScript()
        );

        // Create the email attachment
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(this.survey.Name + '_' + firstRecord + '_' + lastRecord + '.csv');
        efa.setBody(Blob.valueOf(this.content));

        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }

    /**
     * Calculates the optimum batch size for the export CSV process
     *
     * 1) To avoid hitting the query rows limit, the total of answers for all
     * the submissions should be less than MAX_QUERY_ROWS.
     * So batchSize = MAX_QUERY_ROWS / maxAmountOfAnswers.
     *
     * 2) To avoid hitting the query limit, no more than 200 submissions can
     * be processed per batch. So, considering some extra queries, the max
     * optimum value is 195.
     *
     * 3) Besides the queries in the process itself, there is an extra query to
     * fetch the contacts data. So, we decrease the optimum value in one.
     *
     * @param  surveyId the id of the current survey
     * @return          the optimum batch size
     */
    public static Integer getCsvBatchSize(String surveyId) {
        // Define the max batch size
        Integer maxBatchSize = Limits.getLimitQueries() * 2 - LIMIT_QUERIES;

        // Find the max amount of answers for the submissions
        Integer maxAmountOfAnswers = Integer.valueOf([SELECT MAX(AnswersCount__c) maxAmount
                                                      FROM Submission__c
                                                      WHERE Survey__c = :surveyId][0].get('maxAmount'));

        Integer optimumBatchSize = maxAmountOfAnswers > 0
            ? MAX_QUERY_ROWS / maxAmountOfAnswers
            : maxBatchSize;

        // Anyway the batch size cannot exceed the queries limit
        return (maxBatchSize > optimumBatchSize) ? optimumBatchSize - 1 : maxBatchSize - 1;
    }

    /**
     * Sends an email with the CSV as an attachment
     */
    private void sendCsvEmail(Integer firstRecord, Integer lastRecord, Boolean lastEmail) {

        Messaging.SingleEmailMessage mail = EmailUtils.createSingleEmailForCurrentUser();
        mail.setSenderDisplayName(System.label.SURVEY_CSV_EMAILSENDERNAME);
        mail.setSubject(
            String.format(
                System.label.SURVEY_CSV_EMAILSUBJECT,
                new String[] {
                    this.survey.Name,
                    String.valueOf(firstRecord),
                    String.valueOf(lastRecord)
                }
            )
        );
        mail.setPlainTextBody(
            String.format(
                lastEmail ? System.label.SURVEY_CSV_LASTEMAILBODY : System.label.SURVEY_CSV_EMAILBODY,
                new String[] {
                    this.survey.Name,
                    String.valueOf(firstRecord),
                    String.valueOf(lastRecord)
                }
            ) + '\n\n' + System.label.SURVEY_CSV_EMAILSIGNATURE.unescapeEcmaScript()
        );

        // Create the email attachment
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(this.survey.Name + '_' + firstRecord + '_' + lastRecord + '.csv');
        efa.setBody(Blob.valueOf(this.content));

        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }

    /**
     * Gets the size in bytes of a string
     *
     * @param  someString a string to calculate the size
     * @return            the size in bytes of the given string
     */
    private Integer sizeInBytes(String someString) {
        return someString.length();
    }
}
