/**
 * Controller class for the Results page
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
public with sharing class SurveyResultController {

    //------------------------------------------------
    // Constants
    //------------------------------------------------
    // A map with the max instance answer each repeated question
    // Used to know the amount of columns for the repeated questions
    private final Map<Id, Integer> maxInstanceByQuestionId;
    // A map of questions with the data needed for the results logic
    public Map<Id, Question__c> questionsData;
    // Amount of submissions to process per page
    private static final Integer SUBMISSIONS_PER_PAGE = 50;
    // Amount of CPU time needed to finish the process
    private static final Integer LIMIT_CPU_TIME = 1000;
    // Amount of free memory in the heap to abort the process
    private static final Integer LIMIT_HEAP = 10000;
    // Amount of queries needed to finish the process
    private static final Integer LIMIT_QUERIES = 5;
    // Amount of rows needed to finish the process
    private static final Integer LIMIT_QUERY_ROWS = 5;
    //------------------------------------------------


    //------------------------------------------------
    // Private variables
    //------------------------------------------------
    // Pager to fetch the submission records
    private ApexPages.StandardSetController pager;
    // The amount of procesed records in the current page
    private Integer processedCount = 0;
    //------------------------------------------------


    //------------------------------------------------
    // Public properties
    //------------------------------------------------
    // The record of the current survey
    public Survey__c survey { get; set; }
    // The current user data
    public final User currentUser { get; set; }
    // Name of the selected Survey
    public String actualSurveyName {
        get {
            return String.isNotBlank(survey.Alias__c) ? survey.Alias__c : survey.Name;
        }
        set;
    }
    // A list with the headers
    public List<String> headers { get; set; }
    // Indicates if there are more rows to load
    public Boolean moreRows { get; set; }
    // List of SelectOption with the surveys that have submissions
    public transient List<SelectOption> surveyItems { get; set; }
    // Submissions data to be shown in the page
    public transient List<SubmissionRow> submissionRows { get; set; }
    // The selecteed submissions to export to CSV
    public String slectedSubmissions { get; set; }
    // Total amount of submissions loaded to the pager
    public String submissionsCount {
        get {
            return String.valueOf(this.pager.getResultSize());
        }
        set;
    }
    // The amount of prcessed records
    public Integer processedRows { get; set; }
    //------------------------------------------------


    /**
     * Class constructor
     */
    public SurveyResultController() {
        // Initialize variables
        this.surveyItems = getSurveyOptions();
        this.processedRows = 1;

        Id surveyId = ApexPages.currentPage().getParameters().get('id');
        if(surveyId != null) {
            // Load the survey data
            this.survey = SurveyDO.getSurveyDataForResults(surveyId);
            this.questionsData = SurveyDO.getQuestionsDataForResults(surveyId);

            // Initialize the map with the max instance for the repeated questions
            this.maxInstanceByQuestionId = SurveyResultsLogic.getMaxInstanceMap(this.survey.Id);

            // Get the header row
            this.headers = getHeaders(this.survey, this.questionsData, this.maxInstanceByQuestionId);

            GenericObjectCreator userCreator = new GenericObjectCreator(User.SObjectType);
            userCreator.checkObjectAccessible();
            userCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                User.Email,
                User.TimeZoneSidKey
            });

            // Get the user timezone
            this.currentUser = [SELECT Id, Email, TimeZoneSidKey
                                FROM User
                                WHERE ID = :UserInfo.getUserId()];

            // Initialize the pager
            initSubmissionsPager();

            // Load the first page of submissions
            fetchMoreRows();
        }
        else {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.INFO,
                    System.Label.SURVEY_ERR_NOSURVEYSELECTED
                )
            );
        }
    }


    //------------------------------------------------
    // Page actions
    //------------------------------------------------

    /**
     * Redirect to the export CSV page
     */
    public void exportAll() {
        Integer batchSize = ExportCsvBatch.getCsvBatchSize(this.survey.Id);
        if(batchSize > 0) {
            Id batchInstanceId = Database.executeBatch(
                new ExportCsvBatch(
                    this.survey.Id,
                    null,
                    this.currentUser.TimeZoneSidKey
                ),
                batchSize
            );
        }
        else {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.ERROR,
                    System.Label.SURVEY_CSV_BATCHSIZEERROR
                )
            );
        }
    }

    /**
     * Export the selected submissions to CSV
     *
     * @param  surveyId            the id of the suvey to export
     * @param  selectedSubmissions a list of submissions to export
     * @param  email               the email of the user to send the exported CSV
     * @param  timeZoneSidKey      the time zone of the user to format the
     *                             datetime fields
     * @return                     true if the export process was started
     */
    @RemoteAction
    public static Boolean exportSelected(
        Id surveyId,
        String selectedSubmissions,
        String timeZoneSidKey
    ) {
        if(String.isNotBlank(selectedSubmissions)) {
            List<String> submissions = selectedSubmissions.split(',');
            Integer batchSize = ExportCsvBatch.getCsvBatchSize(surveyId);
            if(batchSize > 0) {
                Id batchInstanceId = Database.executeBatch(
                    new ExportCsvBatch(
                        surveyId,
                        submissions,
                        timeZoneSidKey
                    ),
                    batchSize
                );
            }
            else {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.severity.ERROR,
                        System.Label.SURVEY_CSV_BATCHSIZEERROR
                    )
                );
            }
            return true;
        }
        else {
            return false;
        }
    }


    /**
     * Fetch a batch of submissions to load them to the page
     */
    public void fetchMoreRows() {
        // Reset the submission rows that the page already processed
        this.submissionRows = new List<SubmissionRow>();

        // Get the submission records
        List<Submission__c> submissions = this.pager.getRecords();
        Map<Id, List<SubmissionPPIValue__c>> ppiValuesBySubmission;
        Map<Id, List<SubmissionPpiAssociation__c>> ppiAssociationsBySubmission;
        if (survey.IsPPI__c) {
            // Currently we will be supporting result for both old and new Ppi data model
            // Loop based on whether it is old or new Ppi Data model
            if (SurveyDO.isNewPpiSurvey(survey)) {
                ppiAssociationsBySubmission =
                    SubmissionDO.getSubmissionPpiAssociations(submissions);
            } else {
                ppiValuesBySubmission = SubmissionDO.getSubmissionsPPIValues(submissions);
            }
        } else {
            ppiValuesBySubmission = new Map<Id, List<SubmissionPPIValue__c>>();
        }

        // Fetch the contacts data
        Map<Id, Contact> contactsById = SurveyResultsLogic.getContacts(submissions);

        // Start or continue from the first non processed record
        Integer i = this.processedCount;
        this.processedRows += (this.pager.getPageNumber() != 1 && this.processedCount == 0)
            ? SUBMISSIONS_PER_PAGE
            : this.processedCount;
        this.processedCount = 0;

        // Generate the rows for the fetched submissions
        for (; i < submissions.size(); i ++) {
            // Check the limits before processing the submission
            if (!tooCloseToTheLimits()) {
                String submissionRow = '';

                // Check if Ppi Survey is new or old, then accordingly use data model
                if (SurveyDO.isNewPpiSurvey(survey)) {
                    submissionRow = SurveyResultsLogic.createSubmissionRow(
                         this.survey,
                         this.questionsData,
                         submissions.get(i),
                         this.maxInstanceByQuestionId,
                         ppiAssociationsBySubmission.get(submissions.get(i).Id),
                         contactsById,
                         this.currentUser.TimeZoneSidKey,
                         true
                     );
                } else {
                    submissionRow = SurveyResultsLogic.createSubmissionRow(
                        this.survey,
                        this.questionsData,
                        submissions.get(i),
                        this.maxInstanceByQuestionId,
                        ppiValuesBySubmission.get(submissions.get(i).Id),
                        contactsById,
                        this.currentUser.TimeZoneSidKey,
                        true
                    );
                }
                this.submissionRows.add(
                     new SubmissionRow(
                         submissions.get(i).Id,
                         submissions.get(i).StartDate__c,
                         submissions.get(i).Gps_x__c,
                         submissions.get(i).Gps_y__c,
                         submissionRow
                     )
                 );
            } else {
                // If some limit is about to get hit, save the count of procesed
                // records and abort
                this.processedCount = i;
                break;
            }
        }


        if(this.processedCount > 0) {
            this.moreRows = true;
        }
        else if(this.pager.getHasNext()) {
            this.pager.next();
            this.moreRows = true;
        }
        else {
            this.moreRows = false;
        }
    }

    //------------------------------------------------
    // Private methods
    //------------------------------------------------

    /**
     * Initialize the submission records pager
     */
    private void initSubmissionsPager() {
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
            Submission__c.Surveyor__c
        });

        GenericObjectCreator submissionScoreCreator =
            new GenericObjectCreator(SubmissionScore__c.SObjectType);
        submissionScoreCreator.checkObjectAccessible();
        submissionScoreCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            SubmissionScore__c.TotalScore__c,
            SubmissionScore__c.ScoringGroup__c
        });

        // Get the list of records
        List<Submission__c> submissions = [SELECT Id,
                                                  Survey__c,
                                                  StartDate__c,
                                                  EndDate__c,
                                                  Date__c,
                                                  Device__c,
                                                  Gps_x__c,
                                                  Gps_y__c,
                                                  PPIScore__c,
                                                  Surveyor__c,
                                                  (SELECT Id, TotalScore__c, ScoringGroup__c
                                                   FROM   SubmissionScore__r
                                                   ORDER BY ScoringGroup__c)
                                           FROM Submission__c
                                           WHERE Survey__c = :this.survey.Id
                                                 AND (Status__c = :C.SUBMISSION_STATUS_UPLOADED
                                                      OR Status__c = :C.SUBMISSION_STATUS_UPLOADED_AUTO)
                                           ORDER BY StartDate__c, Id];

        // Initialize the pager
        this.pager = new ApexPages.StandardSetController(submissions);
        this.pager.setPageSize(SUBMISSIONS_PER_PAGE);
        this.pager.first();

        // Check the amount of records loaded to the pager
        // It has a limit of 10,000 records
        if(submissions.size() > this.pager.getResultSize()) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.INFO,
                    String.format(
                        System.Label.SURVEY_RESULT_MOREROWSTOVIEW,
                        new String[] {
                            String.valueOf(this.pager.getResultSize()),
                            System.Label.SURVEY_RESULT_EXPORT_ALL_CSV
                        }
                    )
                )
            );
        }
    }

    /**
     * Gets the header row parsed into a headers list
     *
     * @param  survey                  the current survey record
     * @param  questionsData           a map with the data of all the questions in the survey
     * @param  maxInstanceByQuestionId a map with the max instance answer for
     *                                 the repeated questions
     * @return                         a list of strings with the headers
     */
    private List<String> getHeaders(
        Survey__c survey,
        Map<Id, Question__c> questionsData,
        Map<Id, Integer> maxInstanceByQuestionId
    ) {
        String headerRow = SurveyResultsLogic.createHeaderRow(
            survey,
            questionsData,
            maxInstanceByQuestionId,
            true
        );
        // Remove leading and trailing quotation marks, and split it
        return SurveyUtils.parseCsvLine(headerRow);
    }

    /**
     * Checks the Salesforce limits
     * Limits: Script statements, Heap size and Queries
     *
     * @return true if the limits are too close
     */
    private Boolean tooCloseToTheLimits() {
        return Limits.getLimitCpuTime() != -1
            && Limits.getLimitCpuTime() - Limits.getCpuTime() < LIMIT_CPU_TIME
            || Limits.getLimitHeapSize() - Limits.getHeapSize() < LIMIT_HEAP
            || Limits.getLimitQueries() - Limits.getQueries() < LIMIT_QUERIES
            || Limits.getLimitQueryRows() - Limits.getQueryRows() < LIMIT_QUERY_ROWS;
    }

    /**
     * Creates the SelectOption of the list of surveys with answers.
     *
     * @return a list of options to use in the page
     */
    private List<SelectOption> getSurveyOptions() {
        List<SelectOption> options = new List<SelectOption>();
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Survey__c.Name
        });

        for (Survey__c s : [SELECT Id, Name
                            FROM Survey__c
                            WHERE ResponseCount__c > 0
                            ORDER BY Name ]
        ) {
            options.add(new SelectOption(s.Id, s.Name));
        }

        return options;
    }


    //------------------------------------------------
    // Inner classes
    //------------------------------------------------

    /**
     * Wrapper class to use nested apex:repeat in visualforce.
     * This class represents each row inside the table.
     */
    public class SubmissionRow {
        public Id submissionId { get; set; }
        public DateTime submissionDate { get; set; }
        public Decimal latitude { get; set; }
        public Decimal longitude { get; set; }
        public List<String> cells { get; set; }
        public Boolean hasLocation {
            get {
                return latitude != null && longitude != null;
            }
            set;
        }

        public SubmissionRow(Id submission, DateTime sDate, Decimal gps_x, Decimal gps_y, String row) {
            this.submissionId = submission;
            this.submissionDate = sDate;
            this.latitude = gps_y;
            this.longitude = gps_x;

            // Remove leading and trailing quotation marks, and split it
            cells = SurveyUtils.parseCsvLine(row);
        }
    }
}