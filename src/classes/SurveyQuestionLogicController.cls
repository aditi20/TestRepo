/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved*
 */
public with sharing class SurveyQuestionLogicController {

    public Survey__c survey{get; set;}
    // ERROR MESSAGES
    public static final String ERR_UNKNOWN_QUESTION = system.label.QUESTION_BUILDER_ERR_UNKNOWN_QUESTION;
    public static final String ERR_SURVEY_ALREADY_PUBLISHED= system.label.QUESTION_BUILDER_ERR_SURVEY_ALREADY_PUBLISHED;
    public String SurveyAlreadyPublished{get{return ERR_SURVEY_ALREADY_PUBLISHED;}}
    private DateTime lastModified;
    public Boolean concurrentSave{ get; set; }
    public static final String FIRST_SECTION='1'; //Constant to handle the First Section of the page

    // Labels for conditions, behaviors and operators
    public String getConditions(){
        return JSON.serialize(SkipConditionDO.getConditionTranslations());
    }
    public String getBehaviors(){
        return JSON.serialize(QuestionDO.getSkipConditionBehaviorTranslations());
    }
    public String getOperators(){
        return JSON.serialize(QuestionDO.getSkipConditionOperatorsTranslations());
    }

    // Maps to keep correspondence between builder objects and actual Salesforce objects.
    private Map<String,Question__c> sfquestions = new Map<String,Question__c>();
    private Map<String,Option__c> sfoptions = new Map<String,Option__c>();
    private Map<String,SkipCondition__c> sfskipconditions = new Map<String, SkipCondition__c>();
    public boolean hasApexMessage{get{
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

    //CONSTRUCTOR
    public SurveyQuestionLogicController(ApexPages.StandardController stdController) {
        this.survey = (Survey__c)stdController.getRecord();


        // Catching when the url id is null
        if(this.survey.Id != null) {
            GenericObjectCreator surveyCreator =
                new GenericObjectCreator(Survey__c.SObjectType);
            surveyCreator.checkObjectAccessible();
            surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Survey__c.Name,
                Survey__c.Status__c,
                Survey__c.Alias__c,
                Survey__c.Version__c,
                Survey__c.IsPPI__c,
                Survey__c.IsTemplate__c
            });
            this.survey = [SELECT Id, Name, Alias__c, Version__c, LastModifiedDate, IsPPI__c, IsTemplate__c, Status__c FROM Survey__c WHERE Id=:this.survey.id limit 1];
        } else {
            throw new C.InvalidUrlException(system.Label.BUILDER_ERR_INVALIDURL);
        }

        // setting concurrent save to false
        concurrentSave = false;

        offset = 0;
        lastBatchOfQuestions = new BuilderQuestion[]{};

        lastModified = this.survey.LastModifiedDate;

        loadMoreQuestions();

        //if the survey is published add an error
        if (survey.Status__c == SurveyDO.STATUS_PUBLISHED){
            ApexPages.message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, system.Label.BUILDER_ERR_SURVEYALREADYPUBLISHED);
            ApexPages.addMessage(myMsg);
        }
    }

    public void loadMoreQuestions(){
        hasMoreQuestions = false;
        lastBatchOfQuestions.clear();

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Name,
                Question__c.Type__c,
                Question__c.Caption__c,
                Question__c.Survey__c,
                Question__c.Parent__c,
                Question__c.Hint__c,
                Question__c.Position__c,
                Question__c.Minimum__c,
                Question__c.Maximum__c,
                Question__c.DoBefore__c,
                Question__c.DoAfter__c,
                Question__c.Required__c,
                Question__c.SamePage__c,
                Question__c.CurrentTime__c,
                Question__c.SkipLogicBehavior__c,
                Question__c.SkipLogicOperator__c,
                Question__c.CascadingSelect__c
            }
        );

        GenericObjectCreator optionCreator =
            new GenericObjectCreator(Option__c.SObjectType);
        optionCreator.checkObjectAccessible();
        optionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Option__c.Name,
            Option__c.Caption__c,
            Option__c.Position__c,
            Option__c.Question__c,
            Option__c.PPIScore__c
        });

        GenericObjectCreator skipConditionCreator =
            new GenericObjectCreator(SkipCondition__c.SObjectType);
        skipConditionCreator.checkObjectAccessible();
        skipConditionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SkipCondition__c.Parent__c,
                SkipCondition__c.SkipValue__c,
                SkipCondition__c.SourceQuestion__c,
                SkipCondition__c.Condition__c,
                SkipCondition__c.Negate__c
            }
        );

        // Obtain all questions, with their options and skip conditions
        Question__c[] questionList = [
                SELECT Id, Name, Survey__c, Type__c, Parent__c, Caption__c, Hint__c, Position__c,
                       Minimum__c, Maximum__c, DoBefore__c, DoAfter__c, Required__c, SamePage__c,
                       CurrentTime__c, SkipLogicBehavior__c, SkipLogicOperator__c, CascadingSelect__c, CascadingSelect__r.Name,
                       IsRemoteEditable__c, RemoteServerId__c, RepeatSourceValue__c, RepeatSourceValue__r.Name,
                       (SELECT Id, Name, Caption__c, Position__c, Question__c, PPIScore__c
                        FROM   Options__r
                        ORDER BY Position__c),
                       (
                           SELECT
                               Id,
                               Parent__c,
                               SourceQuestion__c,
                               Condition__c,
                               Negate__c,
                               SkipValue__c
                           FROM
                               SkipConditions__r
                           ORDER BY Id
                       )
                FROM   Question__c
                WHERE  Survey__c = :this.survey.Id AND IsDraft__c = 1
                ORDER BY Survey__r.Id, Parent__r.Position__c, Position__c
                OFFSET :offset];

        Set<Id> processedQuestions = new Set<Id>();

        Integer cpuTimeLimit = Limits.getLimitCpuTime() - 1000; // save some CPU time for score values
        for(Question__c q : questionList){

            sfquestions.put(q.Id, q);
            BuilderQuestion bq = new BuilderQuestion(q);
            lastBatchOfQuestions.add(bq);

            for(Option__c o : q.Options__r){
                sfoptions.put(o.Id, o);
                bq.options.add(new BuilderQuestion.Option(o));
            }

            for(SkipCondition__c c : q.SkipConditions__r){
                sfskipconditions.put(c.Id, c);
                bq.skipconditions.add(new BuilderQuestion.SkipCondition(c));
            }

            offset++;
            processedQuestions.add(q.Id);

            if (cpuTimeLimit > 0 && cpuTimeLimit < Limits.getCpuTime()) {
                hasMoreQuestions = true;
                return;
            }
        }
    }

    // Shorthand method
    private String getParam(String key){ return ApexPages.CurrentPage().getParameters().get(key); }

    // Saves the list of questions to the database
    public PageReference save(){

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkObjectUpdateable();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Survey__c.Status__c,
            Survey__c.IsPPI__c
        });

        GenericObjectCreator skipConditionCreator =
            new GenericObjectCreator(SkipCondition__c.SObjectType);
        skipConditionCreator.checkObjectAccessible();
        skipConditionCreator.checkObjectDeletable();
        skipConditionCreator.checkObjectCreateable();

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkObjectUpdateable();

        Boolean hasError = false;
        this.survey = [SELECT Status__c,LastModifiedDate FROM Survey__c WHERE Id = :this.survey.Id];
        if (this.survey.Status__c != SurveyDO.STATUS_DRAFT) {
            ApexPages.message myMsg = new ApexPages.Message(
                ApexPages.Severity.ERROR,
                System.label.BUILDER_ERR_SURVEYALREADYPUBLISHED
            );
            ApexPages.addMessage(myMsg);
            return null;
        } else if (this.survey.LastModifiedDate != lastModified){
            // Set boolean to true to display popup to refresh the page
            concurrentSave = true;
            return null;
        }

        try {
            surveyCreator.checkObjectUpdateable();
            update survey;
        }
            // Do not add an apex error message because the trigger does
        catch (DmlException e) {
            system.debug(e);
            hasError = true;
        }
        String pquestions = getParam('questions');
        String pquicksave = getParam('quicksave');

        if (!hasError) {
            this.survey = [SELECT LastModifiedDate, IsPPI__c, Status__c  FROM Survey__c WHERE Id=:this.survey.id limit 1];
            lastModified = survey.LastModifiedDate;

            JSONParser parser = JSON.createParser(pquestions);
            BuilderQuestion[] newQuestions = (BuilderQuestion[])parser.readValueAs(BuilderQuestion[].class);

                
            // Delete all existing conditions from local or editbable questions.
            delete [
                SELECT
                    Id
                FROM
                    SkipCondition__c
                WHERE
                    Parent__r.Survey__c = :this.survey.Id
                    AND (Parent__r.RemoteServerId__c = null
                    OR Parent__r.IsRemoteEditable__c = true)
            ];

            // Create all conditions again
            SkipCondition__c[] conditions = new SkipCondition__c[]{};
            Question__c[] questions = new Question__c[]{};
            for(BuilderQuestion bq : newQuestions) {
                Question__c question = sfquestions.get(bq.id);

                // Prevent edition of readonly qustions (protect from html-js hacker users -- it's ok if page crashes on their face)
                if (question.RemoteServerId__c != null && question.RemoteServerId__c != '' && !question.IsRemoteEditable__c)
                    SurveyException.raise(System.Label.BUILDER_ERR_NONEDITABLEQUESTION + ' ' + question.Id);

                bq.updateQuestion(question);
                questions.add(question);
                for(BuilderQuestion.SkipCondition cond : bq.skipconditions)
                    conditions.add( cond.createSkipCondition(question) );
            }

            try {
                insert conditions;
            } catch(Exception e) {
                system.debug(e);
            }

            try {
                update questions;
            } catch (Exception e) {
                system.debug(e);
            }

            PageReference goPreview = Page.SurveyFieldMapping;
            goPreview.setRedirect(true);
            goPreview.getParameters().put('id', this.survey.Id);

            return pquicksave == 'true' ? null : goPreview;

        } else {
            return null;
        }
    }
}