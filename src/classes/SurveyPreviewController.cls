/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class SurveyPreviewController {

    public Survey__c survey{get; set;} // Survey to be shown.
    public List<ScoringGroup> scoringGroups {get;set;} //Scoring groups related to this survey.
    public Boolean builder{get;set;}
    public Boolean isPreview{get;set;}

    public Boolean hasPPILicense{get;set;}  // check if has ppi license
    public Boolean sameOrg{get;set;} // To render the close button just when is in the same org
    public String jsonScoringGroups {get;set;} //Json scoring groups related to this survey.

    private Integer offset;            // offset to retrieve next batch of questions
    private Boolean hasMoreQuestions;  // set if all questions have already been retrieved
    private BuilderQuestion[] lastBatchOfQuestions;

    public Integer getOffset(){ return offset; }
    public Boolean getHasMoreQuestions(){ return hasMoreQuestions; }
    public String getLastBatchOfquestions(){ return JSON.serialize(lastBatchOfQuestions); }

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

    public SurveyPreviewController(ApexPages.StandardController stdController) {
        builder = Apexpages.currentPage().getParameters().get('b') == '0';
        isPreview = true;
        this.survey = (Survey__c)stdController.getRecord();

        setDataForPreview();

        // Set to true when is the same org to show the preview.
        sameOrg = Site.getName() == null;

        // Check if has ppi license
        LicenseSettings__c license = C.getLicense();
        hasPPILicense = license.PPI_Editable__c;

        scoringGroups = new List<ScoringGroup>();

        GenericObjectCreator scoringGroupCreator =
            new GenericObjectCreator(ScoringGroup__c.SObjectType);
        scoringGroupCreator.checkObjectAccessible();
        scoringGroupCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            ScoringGroup__c.Name,
            ScoringGroup__c.Caption__c
        });

        for (
                ScoringGroup__c scoringGroup :
                    new ScoringGroupSelector().getAllForSurveyPpiOrderByCreatedDate(
                        this.survey.Id,
                        false
                    )
        ) {
            ScoringGroup newScoringGroup = new ScoringGroup(scoringGroup);
            scoringGroups.add( newScoringGroup );
        }
        jsonScoringGroups = JSON.serialize(scoringGroups);

        offset = 0;
        lastBatchOfQuestions = new BuilderQuestion[]{};

        loadMoreQuestions();

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();

        // Validate if the survey was automatically closed, by preview, and show message
        if (this.survey.Status__c == SurveyDO.STATUS_CLOSED) {
            List<SurveyVersion__c> versions = [
                SELECT
                    Id
                FROM
                    SurveyVersion__c
                WHERE
                    Survey__c = :this.survey.Id
                    AND CloseReason__c = :SurveyDO.STATUS_CLOSED_AUTO
                    ORDER BY Version__c DESC
            ];

            if (!versions.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.severity.INFO,
                    System.Label.ERR_SURVEY_PREVIEW_WRONGMAP
                ));
            }
        }
    }

    public void loadMoreQuestions() {
        hasMoreQuestions = false;
        lastBatchOfQuestions.clear();

        List<BuilderQuestion.ScoreValue> scoreTempList = new List<BuilderQuestion.ScoreValue>();

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Name,
                Question__c.Survey__c,
                Question__c.Type__c,
                Question__c.Parent__c,
                Question__c.Caption__c,
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
                Question__c.CascadingSelect__c,
                Question__c.IsRemoteEditable__c,
                Question__c.RemoteServerId__c,
                Question__c.RepeatSourceValue__c,
                Question__c.RepeatTimes__c
            }
        );
        GenericObjectCreator cascadingSelectCreator =
            new GenericObjectCreator(CascadingSelect__c.SObjectType);
        cascadingSelectCreator.checkObjectAccessible();
        cascadingSelectCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            CascadingSelect__c.Name
        });
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
                SkipCondition__c.SourceQuestion__c,
                SkipCondition__c.Condition__c,
                SkipCondition__c.Negate__c,
                SkipCondition__c.SkipValue__c
            }
        );

        // Obtain all questions, with their options and skip conditions
        Question__c[] questionList = [
            SELECT
                Id,
                Name,
                Survey__c,
                Type__c,
                Parent__c,
                Caption__c,
                Hint__c,
                Position__c,
                Minimum__c,
                Maximum__c,
                DoBefore__c,
                DoAfter__c,
                Required__c,
                SamePage__c,
                CurrentTime__c,
                SkipLogicBehavior__c,
                SkipLogicOperator__c,
                CascadingSelect__c,
                CascadingSelect__r.Name,
                IsRemoteEditable__c,
                RemoteServerId__c,
                RepeatSourceValue__c,
                RepeatSourceValue__r.Name,
                RepeatTimes__c,
                (
                    SELECT
                        Id,
                        Name,
                        Caption__c,
                        Position__c,
                        Question__c,
                        PPIScore__c
                    FROM
                        Options__r
                        ORDER BY Position__c
                ),
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
            FROM
                Question__c
            WHERE
                Survey__c = :this.survey.Id
                AND IsDraft__c = 1
                ORDER BY Survey__r.Id, Parent__r.Position__c, Position__c
                OFFSET :offset
        ];

        Set<Id> processedQuestions = new Set<Id>();
        Map<Id,BuilderQuestion.Option> builderOptions = new Map<Id,BuilderQuestion.Option>();

        Integer cpuTimeLimit = Limits.getLimitCpuTime() - 1000; // save some CPU time for score values
        for(Question__c q : questionList){

            // sfquestions.put(q.Id, q);
            BuilderQuestion bq = new BuilderQuestion(q);
            lastBatchOfQuestions.add(bq);

            for(Option__c o : q.Options__r){
                // sfoptions.put(o.Id, o);
                BuilderQuestion.Option bo = new BuilderQuestion.Option(o);
                bq.options.add(bo);
                builderOptions.put(o.Id, bo);
            }

            for(SkipCondition__c c : q.SkipConditions__r){
                bq.skipconditions.add(new BuilderQuestion.SkipCondition(c));
            }

            offset++;
            processedQuestions.add(q.Id);

            if (cpuTimeLimit > 0 && cpuTimeLimit < Limits.getCpuTime()) {
                hasMoreQuestions = true;
                return;
            }
        }

        GenericObjectCreator scoreValueCreator =
            new GenericObjectCreator(ScoreValue__c.SObjectType);
        scoreValueCreator.checkObjectAccessible();
        scoreValueCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            ScoreValue__c.Value__c,
            ScoreValue__c.Option__c,
            ScoreValue__c.ScoringGroup__c
        });

        // Obtain ScoreValues for questions selected.
        for (ScoreValue__c scoreValue : [
                SELECT
                    Id,
                    Option__c,
                    Value__c,
                    ScoringGroup__c
                FROM
                    ScoreValue__c
                WHERE
                    Option__r.Question__c IN :processedQuestions
                    ORDER BY ScoringGroup__r.CreatedDate
            ]
        ) {
            builderOptions.get(scoreValue.Option__c).scoreValues.add(
                new BuilderQuestion.ScoreValue(scoreValue)
            );
        }
    }

    // Sets the preview Survey__c object and data to be shown.
    public void setDataForPreview() {

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Survey__c.Name,
            Survey__c.IsPPI__c,
            Survey__c.Alias__c,
            Survey__c.Description__c,
            Survey__c.Deployment__c,
            Survey__c.IsTemplate__c,
            Survey__c.Close_Message__c,
            Survey__c.Status__c
        });

        if (this.survey.Id != null) {
            survey = [
                SELECT
                    Id,
                    Name,
                    IsPPI__c,
                    Alias__c,
                    Description__c,
                    Deployment__c,
                    IsTemplate__c,
                    Close_Message__c,
                    Status__c
                FROM
                    Survey__c
                WHERE
                    Id = :this.survey.Id
            ][0];
        } else {
            throw new C.InvalidUrlException(system.Label.BUILDER_ERR_INVALIDURL);
        }
        String referer = ApexPages.currentPage().getHeaders().get('Referer');
        if (referer != null) {
            String lowerCaseReferer = ApexPages.currentPage().getHeaders().get('Referer').toLowerCase();
            integer refererIndex = lowerCaseReferer.indexOf('surveymanager');
        }
    }

    /*
    *  Given a BuilderQuestion.Option, and a List of BuilderQuestion.ScoreValues, adds the related scoreValues
    *  to the given BuilderQuestion.Option.
    */
    private BuilderQuestion.Option addCorrectScoreValues(BuilderQuestion.Option opt, List<BuilderQuestion.ScoreValue> scoreList ){
        if(scoreList != null && scoreList.size() > 0){
            String idOpt = opt.Id;
            for( BuilderQuestion.ScoreValue sv : scoreList ){
                if(sv.optionId == idOpt){
                    opt.scoreValues.add(sv);
                }
            }
        }
        return opt;
    }

    public with sharing class ScoringGroup {
        public String scoringNumber {get;set;}
        public String caption {get;set;}
        public String id {get;set;}

        public ScoringGroup(ScoringGroup__c source){
            this.scoringNumber = source.Name;
            this.caption = source.Caption__c;
            this.id = source.Id;
        }

    }
}
