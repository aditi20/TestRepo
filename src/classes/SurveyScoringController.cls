/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
 public with sharing class SurveyScoringController {

    public Survey__c survey{get; set;}                                    // Actual survey.
    public BuilderQuestion[] questions = new BuilderQuestion[]{};
    public List<ScoringGroupDomain.ScoringGroup> listGroups =
        new List<ScoringGroupDomain.ScoringGroup>{};
    public List<ScoreValueDomain.ScoringValue> listScoreValues =
        new List<ScoreValueDomain.ScoringValue>{};
    public String scoringGroupStr {get; set;}                             // JSON string passed from the page with the group data.
    public String scoringValuesJson {get; set;}                           // JSON string passed from the page with the Score values data.
    public String continueAfterwards {get;set;}                           // String that decides if should stay in the page (quick save) or continue
    public boolean hasPPILicense {get;set;}
    public boolean wasDownloaded {get;set;}                               // True if it is distributed
    public Boolean concurrentSave{ get; set; }

    public String getQuestions()      { return JSON.serialize(questions); }
    public String getListGroups()     { return JSON.serialize(listGroups); }
    public String getListScoreValues(){ return JSON.serialize(listScoreValues); }

    public static final string PPI_ID = 'PPI';
    public static final string PPI_LABEL = 'Progress out of poverty index';
    public boolean hasApexMessage{
                                get{
                                    return (ApexPages.hasMessages(ApexPages.Severity.ERROR) || ApexPages.hasMessages(ApexPages.Severity.FATAL));
                                }set;}
    public Boolean isPublished {
                                get{
                                    return (survey.Status__c == SurveyDO.STATUS_PUBLISHED);
                                }set;}

    private Integer offset;            // offset to retrieve next batch of questions
    private Boolean hasMoreQuestions;  // set if all questions have already been retrieved
    private BuilderQuestion[] lastBatchOfQuestions;

    public Integer getOffset(){ return offset; }
    public Boolean getHasMoreQuestions(){ return hasMoreQuestions; }
    public String getLastBatchOfquestions(){ return JSON.serialize(lastBatchOfQuestions); }

    /*
    *    Class constructor
    */
    public SurveyScoringController (ApexPages.StandardController stdController) {

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Survey__c.Name,
            Survey__c.Alias__c,
            Survey__c.Version__c,
            Survey__c.IsPPI__c,
            Survey__c.IsTemplate__c,
            Survey__c.Status__c
        });

        this.survey = (Survey__c)stdController.getRecord();

        // Check if has ppi license
        LicenseSettings__c license = C.getLicense();
        hasPPILicense = license.PPI_Editable__c;

        // Catching when the url id is null
        if (this.survey.Id != null) {
            this.survey = new SurveySelector().getSpecificWithSurveyVersion(survey.id);
        } else {
            throw new C.InvalidUrlException(System.Label.BUILDER_ERR_INVALIDURL);
        }

        // setting concurrent save to false
        concurrentSave = false;

        offset = 0;
        lastBatchOfQuestions = new BuilderQuestion[]{};

        SurveyScoringService.loadScoringGroups(this.survey, listGroups);
        loadMoreQuestions();

        //if the survey is published add an error
        if (survey.Status__c == SurveyDO.STATUS_PUBLISHED) {
            ApexPages.message myMsg =
                new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    system.Label.BUILDER_ERR_SURVEYALREADYPUBLISHED
                );
            ApexPages.addMessage(myMsg);
        }
    }

    /**
     * Load More Operations of Questions
     */
    public void loadMoreQuestions() {

        hasMoreQuestions = false;
        lastBatchOfQuestions.clear();

        // Obtain all questions and their options, for this survey.
        List<Question__c> questionList =
            new QuestionSelector().getWithOptions(this.survey.Id, offset);
        Set<Id> processedQuestions = new Set<Id>();

        // Load questions until I'm close to script statement limit
        Integer cpuTimeLimit = Limits.getLimitCpuTime() - 1000; // save some CPU time for score values
        for(Question__c q : questionList){

            BuilderQuestion bq = new BuilderQuestion(q);
            questions.add(bq);
            lastBatchOfQuestions.add(bq);

            // If at least one question has origin id is a distributed survey
            if(q.RemoteServerId__c != null && q.RemoteServerId__c != ''){
                wasDownloaded = true;
            }

            for(Option__c o : q.Options__r){
                bq.options.add(new BuilderQuestion.Option(o));

                // Add an additional score value for the PPI scoring group
                if (this.survey.isPPI__c) {
                    listScoreValues.add(
                        new ScoreValueDomain.ScoringValue(
                            String.valueof(o.PPIScore__c),
                            String.valueof(o.Id),
                            PPI_ID
                        )
                    );
                }
            }

            offset++;
            processedQuestions.add(q.Id);

            if (cpuTimeLimit > 0 && cpuTimeLimit < Limits.getCpuTime()) {
                hasMoreQuestions = true;
                return;
            }
        }

        // Load score values for processed batch of questions
        ScoreValueSelector scoreValueSelector = new ScoreValueSelector();
        for (ScoreValue__c scoreValue :
                new ScoreValueSelector().getForQuestionIds(processedQuestions)
        ) {
            listScoreValues.add(
                new ScoreValueDomain.ScoringValue(
                    scoreValue,
                    scoreValue.ScoringGroup__r.Caption__c
                )
            );
        }
    }

    // Find a question on the list by it's id
    private BuilderQuestion findQuestion(String id) {
        BuilderQuestion questionReturn = null;
        for (BuilderQuestion q : questions){
            if (q.id == id){
                questionReturn = q;
            }
        }
        return questionReturn;
    }

    // Called from the page when clicking "Save and continue".
    public PageReference saveScoring() {

        PageReference returnPage = null;

        try {

            Survey__c dummySurvey = (Survey__c) new SurveySelector().getRecordById(this.survey.id);

            // Save point in case of an error
            Savepoint sp = Database.setSavepoint();

            if (dummySurvey.Status__c != SurveyDO.STATUS_DRAFT) {
                throw new SurveyScoringService.SurveyScoringServiceException(
                    System.Label.BUILDER_ERR_SURVEYALREADYPUBLISHED
                );
            } else if (dummySurvey.LastModifiedDate != this.survey.LastModifiedDate) {
                // Set boolean to true to display popup to refresh the page
                concurrentSave = true;
                return null;
            } else {
                ScoringGroupDomain scoringGroupDomain =
                    new ScoringGroupDomain.Constructor().constructWithRecords(
                        new ScoringGroupSelector().getAllForSurvey(survey.Id)
                    );
                scoringGroupDomain.deleteRecords();

                // Creates groups.
                if (this.scoringGroupStr != '') {
                    try {
                        SurveyScoringService.databaseSavepoint = sp;
                        this.survey =
                            SurveyScoringService.parseSurveyScoring(
                                this.survey,
                                scoringGroupStr,
                                scoringValuesJson
                            );
                        if (this.continueAfterwards == 'true') {
                            returnPage = survey.IsPPI__c ? Page.LookupTables : Page.SurveyQuestionLogic;
                            returnPage.getParameters().put('id', survey.Id);
                        }
                    } catch (Exception e) {
                        Database.rollback(sp);
                        throw e;
                    }
                }
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            returnPage = null;
        }
        return returnPage;
    }

}
