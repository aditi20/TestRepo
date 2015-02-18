/**
 * Controller class for dealing with functionality around all questions on Question builder page
 *
 * TODO:
 *    - Refactor code based on SOC architechture
 *    - Use appropriate selector and domain layers and update all queries and DML operations
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
 public with sharing class SurveyQuestionController {

    public Survey__c survey{get; set;}
    public List<Question__c> questionList = new List<Question__c>();
    public Boolean positionsWereFixed {get;set;}
    public Boolean canDistribute {get;set;}
    public String cascadingSelectedName {get;set;}
    private Map<String, List<QuestionMapping__c>> mappingsPerQuestion;

    public String getCascadingSelects(){
        return JSON.serialize(encodeCascadingsData());
    }

    public String getQuestionTypesLabels(){
        return JSON.serialize(QuestionDO.getTypesTranslations());
    }
    public Boolean isPublished {
        get {
            return (survey.Status__c == SurveyDO.STATUS_PUBLISHED);
        }
        set;
    }
    private DateTime lastModified;

    public boolean hasApexMessage {
        get {
            return (ApexPages.hasMessages(ApexPages.Severity.ERROR) || ApexPages.hasMessages(ApexPages.Severity.FATAL));
        }
        set;
    }

    private Integer offset;            // offset to retrieve next batch of questions
    private Boolean hasMoreQuestions;  // set if all questions have already been retrieved
    public Boolean concurrentSave{ get; set; }
    private BuilderQuestion[] lastBatchOfQuestions;

    public Integer getOffset(){ return offset; }
    public Boolean getHasMoreQuestions(){ return hasMoreQuestions; }
    public String getLastBatchOfquestions(){ return JSON.serialize(lastBatchOfQuestions); }
    public String getQuestionMappingsRelated(){ return JSON.serialize(mappingsPerQuestion); }
    public String getConditions(){
        return JSON.serialize(SkipConditionDO.getConditionTranslations());
    }

    public String getUserLanguage(){
      return C.getUserLanguage();
    }

    /**
    * Update the survey with data from the database.
    */
    private void refetchSurvey(){
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

        this.survey = [
            SELECT
                Id,
                Name,
                Alias__c,
                Version__c,
                LastModifiedDate,
                IsPPI__c,
                IsTemplate__c,
                Status__c
            FROM
                Survey__c
            WHERE
                Id = :survey.Id
        ];
    }

    public SurveyQuestionController(ApexPages.StandardController stdController) {

        this.survey = (Survey__c)stdController.getRecord();

        // Catching when the url id is null
        if(this.survey.Id != null)
            refetchSurvey();
        else
             throw new C.InvalidUrlException(system.Label.BUILDER_ERR_INVALIDURL);
        lastModified = this.survey.LastModifiedDate;
        // setting concurrent save to false
        concurrentSave = false;
        offset = 0;
        lastBatchOfQuestions = new BuilderQuestion[]{};

        loadMoreQuestions();

        //if the survey is published add an error
        if (survey.Status__c == SurveyDO.STATUS_PUBLISHED){
            ApexPages.message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, system.Label.BUILDER_ERR_SURVEYALREADYPUBLISHED);
            ApexPages.addMessage(myMsg);
        }

        //load a map of questionMappings per question
        loadQuestionMappings();
        init();
    }

    /**
     *  Method in charge to encode each field that could be entered by the user.
     *  @param question Question__c to be encoded.
     *  @param encode SFDCEncoder to be used.
     */
    public void encodeQuestionData(Question__c question, SFDCEncoder encode) {
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Caption__c,
                Question__c.Hint__c,
                Question__c.DoBefore__c,
                Question__c.DoAfter__c
            }
        );
        questionCreator.populateFields(
            question,
            new Map<Schema.SObjectField, Object>{
                Question__c.Caption__c => encode.SFDC_JSENCODE(question.Caption__c),
                Question__c.Hint__c => encode.SFDC_JSENCODE(question.Hint__c),
                Question__c.DoBefore__c => encode.SFDC_JSENCODE(question.DoBefore__c),
                Question__c.DoAfter__c => encode.SFDC_JSENCODE(question.DoAfter__c)
            }
        );
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
        questionList = [SELECT Id, Name, Survey__c, Type__c, Parent__c, Caption__c, Hint__c, Position__c,
                               Minimum__c, Maximum__c, DoBefore__c, DoAfter__c, Required__c, SamePage__c,
                               CurrentTime__c, SkipLogicBehavior__c, SkipLogicOperator__c,
                               IsRemoteEditable__c, RemoteServerId__c, RepeatSourceValue__c, RepeatSourceValue__r.Name,
                               CascadingSelect__c, CascadingSelect__r.Name, CascadingSelect__r.Status__c,
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
                        FROM Question__c
                        WHERE  Survey__c = :this.survey.Id AND IsDraft__c = 1 AND Type__c != :QuestionDO.TYPE_CASCADING_LEVEL
                        ORDER BY Survey__r.Id, Parent__c, Parent__r.Position__c, Position__c
                        OFFSET :offset];

        Set<Id> processedQuestions = new Set<Id>();

        Integer cpuTimeLimit = Limits.getLimitCpuTime() - 1000; // save some CPU time for score values

        for(Question__c q : questionList){
            sfquestions.put(q.Id, q);
            BuilderQuestion bq = new BuilderQuestion(q);
            questions.add(bq);
            lastBatchOfQuestions.add(bq);
            cascadingSelectedName = q.CascadingSelect__r.Name;

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

        GenericObjectCreator scoreValueCreator =
            new GenericObjectCreator(ScoreValue__c.SObjectType);
        scoreValueCreator.checkObjectAccessible();
        scoreValueCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            ScoreValue__c.Option__c
        });

        // Mark the options that have score value, so we can asks the user for confirmation when deleting.
        for(Option__c o : [SELECT Id, Question__c
                           FROM Option__c
                           WHERE Id IN (SELECT Option__c
                                        FROM ScoreValue__c
                                        WHERE Option__r.Question__c IN :questionList
                                        AND Value__c != 0)
                           ]){
            findQuestion(o.Question__c).getOption(o.Id).hasScoreValues = true;
        }

        if(survey.IsPPI__c){
            // Mark the options that have ppi score value, so we can asks the user for confirmation when deleting.
            for(Option__c o : [SELECT Id, PPIScore__c, Question__c
                               FROM Option__c
                               WHERE Question__c IN :questionList
                               AND PPIScore__c != 0]){

                findQuestion(o.Question__c).getOption(o.Id).hasPPIScoreValues = true;
            }
        }

    }
    /**
    * update the list of questions, used if the init() function
    * made some modifications over the list, and the user confirm
    * these changes
    **/
    public PageReference updatePositions(){
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkObjectUpdateable();

        update questionList;
        positionsWereFixed = false;

        return null;
    }

    public PageReference init() {

        LicenseSettings__c license = C.getLicense();
        // Distributable License
        canDistribute = license.Can_Distribute__c;

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();

        Question__c prevQuestion;
        positionsWereFixed = false;
        boolean questionChanged = false;

        for(Question__c q : questionList){
            // Must have at least two questions
            if(prevQuestion != null ){
                if(q.Survey__c == prevQuestion.Survey__c && q.Parent__c == prevQuestion.Parent__c ){
                    //Fixing when positions are repeated
                    if(q.Position__c == prevQuestion.Position__c || q.Position__c != prevQuestion.Position__c +1){
                        //fixing question position
                        questionCreator.populateField(
                            q,
                            Question__c.Position__c,
                            prevQuestion.Position__c + 1
                        );
                        //fixing builder question position
                        findQuestion(q.Id).position = Integer.valueOf(q.Position__c);
                        positionsWereFixed = true;
                        //information message
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, system.label.QUESTION_ERR_WRONGORDER));
                    }
                }else{
                    questionCreator.populateField(
                        q,
                        Question__c.Position__c,
                        1
                    );
                }

            //If it is the first question of the list
            }else{
                questionCreator.populateField(
                    q,
                    Question__c.Position__c,
                    1
                );
            }
            prevQuestion = q;
        }
        return null;
    }
    //--------------------------------------------------------
    // ERROR MESSAGES
    public static final String ERR_DUPLICATE_ID             = system.label.QUESTION_BUILDER_ERR_DUPLICATE_ID;
    public static final String ERR_DUPLICATE_NAME           = system.label.QUESTION_BUILDER_ERR_DUPLICATE_NAME;
    public static final String ERR_UNKNOWN_QUESTION         = system.label.QUESTION_BUILDER_ERR_UNKNOWN_QUESTION;
    public static final String ERR_SURVEY_ALREADY_PUBLISHED = system.label.QUESTION_BUILDER_ERR_SURVEY_ALREADY_PUBLISHED;
    public BuilderQuestion[] questions                      = new BuilderQuestion[]{}; // Contains questions to be upserted on the next "save" call.
    public BuilderQuestion[] deletedQuestions               = new BuilderQuestion[]{}; // Contains questions to be delete on the next "save" call.
    public String error{ get; set; }
    public String requiredError;
    public String getQuestions(){ return JSON.serialize(questions); }
    public String SurveyAlreadyPublished{get{return ERR_SURVEY_ALREADY_PUBLISHED;}}

    public static final String FIRST_SECTION = '1'; //Constant to handle the First Section of the page

        // Maps to keep correspondence between builder objects and actual Salesforce objects.
    private Map<String,Question__c> sfquestions                  = new Map<String,Question__c>();
    private Map<String,Option__c> sfoptions                      = new Map<String,Option__c>();
    private Map<String,SkipCondition__c> sfskipconditions        = new Map<String, SkipCondition__c>();
    // Contains Id's of all deleted questions
    private Set<String> setDeletedIds                            = new Set<String>();
    // HELPER METHODS : GENERAL
    // # Delete questions that were removed

    /**
     * Create a list of questions without the questions to be removed
     *
     * @return questions list
     */
    public BuilderQuestion[] nonDeletedQuestions(){
        Set<BuilderQuestion> nonDeletedQuestionsSet = new Set<BuilderQuestion>(questions);

        if(nonDeletedQuestionsSet.containsAll(deletedQuestions)){
            nonDeletedQuestionsSet.removeAll(deletedQuestions);
        }

        //return nonDeletedQuestionsList;
        return new List<BuilderQuestion>(nonDeletedQuestionsSet);
    }

    /**
     * Create a set of questions without the questions to be removed
     *
     * @return questions set
     */
    public Set<BuilderQuestion> nonDeletedQuestionsSet(){
        Set<BuilderQuestion> nonDeletedQuestionsSet = new set<BuilderQuestion>(questions);

        if(nonDeletedQuestionsSet.containsAll(deletedQuestions))
            nonDeletedQuestionsSet.removeAll(deletedQuestions);

        return nonDeletedQuestionsSet;
    }

    // Find a question on the list by it's id
    public BuilderQuestion findQuestion(String id) {
        for (BuilderQuestion q : questions)
            if (q.id == id){
                return q;
            }
        return null;
    }

    /**
     * Find a question by it's name on the list without the removed questions
     *
     * @return question if it's found
     */
    public BuilderQuestion findQuestionByName(String name) {

        for (BuilderQuestion q : nonDeletedQuestions()){
            if (q.name == name)
                return q;
        }
        return null;
    }

    // PUBLIC METHODS TO HANDLE SURVEY QUESTIONS

    // Adds a new question to the list of questions
    // Returns the Id for the created question, for future reference
    public String addQuestion(String json){
        BuilderQuestion newQuestion = BuilderQuestion.fromJson(json, true);

        // Check for a duplicate name or id
        BuilderQuestion existingQuestion = null;
        existingQuestion = findQuestion(newQuestion.id);
        if (existingQuestion != null) SurveyException.raise(ERR_DUPLICATE_ID, newQuestion.id);
        existingQuestion = findQuestionByName(newQuestion.name);
        if (existingQuestion != null) SurveyException.raise(ERR_DUPLICATE_NAME, newQuestion.name);

        questions.add(newQuestion);

        // Update position after add the new question
        for(BuilderQuestion q : questions){
            if(!QuestionDO.isSection(newQuestion.type)){
                if(!QuestionDO.isSection(q.type) && q.position >= newQuestion.position && q.id != newQuestion.id && q.parent == newQuestion.parent)
                    q.position++;
            }
            else{
                if(QuestionDO.isSection(q.type) && q.position >= newQuestion.position && q.id != newQuestion.id)
                    q.position++;
            }
        }

        // If im adding a repeat section, set the previous source question id as a valid salesforce id
        if(newQuestion.type == QuestionDO.TYPE_REPEAT && newQuestion.prevSourceQuestion != null){
            newQuestion.prevSourceQuestion = sfquestions.get(newQuestion.prevSourceQuestion).Id;
        }

        // Set show all on one page as false when adding a cascading question
        if(newQuestion.type == QuestionDO.TYPE_CASCADING_SELECT){
            findQuestion(newQuestion.parent).samePage = false;
        }

        return newQuestion.id;
    }

    // Edit's an existing question
    public String editQuestion(String json){
        BuilderQuestion question = BuilderQuestion.fromJson(json, false);
        BuilderQuestion existingQuestion = findQuestion(question.id);

        if (existingQuestion == null){
            // You cannot edit a question that does not exist
            SurveyException.raise(ERR_UNKNOWN_QUESTION, question.id);
        }else if (existingQuestion.name != question.name){
            // If the name of the question changed, check for colisions
            for(BuilderQuestion q : questions){
                if(q.name == question.name)
                    SurveyException.raise(ERR_DUPLICATE_NAME, question.name);
            }
        }
        // Restrict the edition of questions in distributed surveys
        else if(existingQuestion.originId != null && !existingQuestion.remoteEditable){
            SurveyException.raise(system.label.QUESTION_ERR_CANTEDIT, existingQuestion.caption);
        }

        // Set true the edition of sections in distributed surveys
        if(QuestionDO.isSection(existingQuestion.type)){
            existingQuestion.remoteEditable = true;
            // If the section to edit is type repeat, set the new id as a valid salesforce id
            if(existingQuestion.type == QuestionDO.TYPE_REPEAT && existingQuestion.prevSourceQuestion != question.prevSourceQuestion && question.prevSourceQuestion != null){
                question.prevSourceQuestion  = sfquestions.get(question.prevSourceQuestion).Id;
            }
        }

        // Edition of cascading selects questions
        if(question.type == QuestionDO.TYPE_CASCADING_SELECT){
            if(existingQuestion.cascadingId != question.cascadingId){
                // Delete old children when edit question and change the cascading selects library
                deleteOldChildren(new List<Question__c>{sfquestions.get(question.id)});
                // Question to update must have the new cascading as CascadingSelect__c
                sfquestions.get(question.id).CascadingSelect__c = question.cascadingId;
                // Add children to cascading question when updating
                addChildCascading(new List<BuilderQuestion>{question});
                // Set new cascading select id
                existingQuestion.cascadingId = question.cascadingId;
            }else if(question.required != existingQuestion.required){
                setChildrenAsRequired(question);
            }
        }

        // Copy the new values into the existing question
        question.copyTo(existingQuestion);
        return question.Id;
    }

    // Removes a question from the survey (moves it to the "deleted questions" array.
    public void removeQuestion(String id){
        BuilderQuestion[] listOfQuestions = new BuilderQuestion[]{};
        BuilderQuestion[] listOfSections  = new BuilderQuestion[]{};
        // Find the question that I want to remove
        Integer pos = 0;
        BuilderQuestion question = null;
        for(pos = 0; question == null && pos < questions.size(); pos++){
                question = questions[pos];
                if (question.id != id) question = null;
        }

        if (question == null)
                SurveyException.raise(ERR_UNKNOWN_QUESTION, id);

        // Restrict the deletion of sections with non editable questions inside
        else if(QuestionDO.isSection(question.type)){
            for(BuilderQuestion q : questions){
                if (q.parent == question.id && !q.remoteEditable && q.originId != null){
                    SurveyException.raise(system.label.QUESTION_ERR_SECTIONCANTEDIT, question.name);
                }
            }
        }
        // Restrict the deletion of questions in distributed surveys
        else if(question.originId != null && !question.remoteEditable){
            SurveyException.raise(system.label.QUESTION_ERR_CANTEDIT, question.name);
        }

        // Remove this question from question list
        pos--;
        // Deleting questions that never been saved in data base
        if(getQuestion(question,false) == null) questions.remove(pos);

        // Update position for all posterior sibling questions
        for(BuilderQuestion q : questions){
            if (q.parent == question.parent && q.position > question.position){
                        q.position -= 1;
        }
            // Adding all questions with same parent to the list
            if(QuestionDO.isSection(q.type)){
                listOfSections.add(q);
            }else if(q.parent == question.parent){
                listOfQuestions.add(q);
            }
        }

        // Move the removed question to the last place
        question.position = (QuestionDO.isSection(question.type) ? listOfSections.size() : listOfQuestions.size());

        // Add this question to deleted questions list
        deletedQuestions.add(question);

        // Remove all questions for that parent, recursively
        Set<BuilderQuestion> nonDeletedQuestion = nonDeletedQuestionsSet();
        String[] childrenIds = new String[]{};
        for(BuilderQuestion q : questions) if (q.parent == id && nonDeletedQuestion.contains(q)) childrenIds.add(q.id);
        for(String childId : childrenIds) removeQuestion(childId);
    }

    list<BuilderQuestion>lSections = new list<BuilderQuestion>();
    list<BuilderQuestion>childQuest = new list<BuilderQuestion>();

    // Looks for the corresponding Question__c object.
    private Question__c getQuestion(BuilderQuestion bq, Boolean doCreateOrUpdate) {
                Question__c q = sfquestions.get(bq.id);
                if (doCreateOrUpdate) {
                        if (q != null) { bq.updateQuestion(q); }
                        else { q = bq.createQuestion(survey); sfquestions.put(bq.id, q); }
                }
                return q;
    }

    // Looks for the corresponding Option__c object.
    // If it doesn't exist, and a Question__c was provided, creates it.
    private Option__c getOption(BuilderQuestion.Option bo, Question__c question) {
                Option__c o = sfoptions.get(bo.id);
                if (question != null) {
                        if (o != null) { bo.updateOption(o); }
                        else { o = bo.createOption(question); sfoptions.put(bo.id, o); }
                }
                return o;
    }

    // Saves the list of questions to the database
    public void save(){
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkObjectUpdateable();
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkObjectCreateable();
        questionCreator.checkObjectUpdateable();
        questionCreator.checkObjectDeletable();

        Savepoint sp = Database.setSavepoint();
        // Validating that survey is not already published
        refetchSurvey();
        if (this.survey.Status__c != SurveyDO.STATUS_DRAFT) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,ERR_SURVEY_ALREADY_PUBLISHED));
            return;
        } else if (this.survey.LastModifiedDate != lastModified) {
            // Set boolean to true to display popup to refresh the page
            concurrentSave = true;
            return;
        }

        String pquestions = getParam('questions');

        update this.survey;

        if (pquestions != null) {
            JSONParser parser = JSON.createParser(pquestions);
            BuilderQuestion[] newQuestions = (BuilderQuestion[])parser.readValueAs(BuilderQuestion[].class);

            GenericObjectCreator skipConditionCreator =
                new GenericObjectCreator(SkipCondition__c.SObjectType);
            skipConditionCreator.checkObjectAccessible();
            skipConditionCreator.checkObjectDeletable();
            skipConditionCreator.checkObjectCreateable();

            // Delete all existing conditions
            delete [select Id from SkipCondition__c where Parent__r.Survey__c = :this.survey.Id];

            // Create all conditions again
            SkipCondition__c[] conditions = new SkipCondition__c[]{};
            for (BuilderQuestion bq : newQuestions) {
                Question__c question = getQuestion(bq, false);
                if (question != null && bq.skipconditions != null) {
                    for (BuilderQuestion.SkipCondition cond : bq.skipconditions) {
                        conditions.add( cond.createSkipCondition(question) );
                    }
                }
            }

            insert conditions;
        }

        Question__c[] toUpdate                  = new Question__c[]{};
        Question__c[] toInsert                  = new Question__c[]{};
        Question__c[] toDelete                  = new Question__c[]{};
        Question__c[] cascadingToDeleteChildren = new Question__c[]{};
        BuilderQuestion[] builderToInsert       = new BuilderQuestion[]{};

        // 1. delete

        // # Delete questions that were removed from the list
        questions = nonDeletedQuestions();

        for (BuilderQuestion bq : deletedQuestions) {
            Question__c q = getQuestion(bq, false);
            if (q != null) {
                setDeletedIds.add(q.Id);
                toDelete.add(q);
                if (q.Type__c == QuestionDO.TYPE_CASCADING_SELECT) {
                    cascadingToDeleteChildren.add(q);
                }
            }
        }

        // Related option objects will be cascade-delete by master-detail relationship
        try {
            // 1.1 delete cascading children questions
            if (!cascadingToDeleteChildren.isEmpty()) {
                deleteOldChildren(cascadingToDeleteChildren);
            }
        } catch(Exception ex) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            Database.rollback(sp);
            return;
        }

        // 2. Upsert sections
        for (BuilderQuestion bq : questions) {
            if (QuestionDO.isSection(bq.type)) {
                Question__c q = getQuestion(bq, true);
                // Check if section to update was related to a deleted question
                isNumberAndIsRelated(q);
                if (q.Id != null) {
                    toUpdate.add(q);
                } else {
                    toInsert.add(q);
                }
            }
        }

        try {
            update toUpdate;
            delete toDelete;
            insert toInsert;
        } catch(Exception ex) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            Database.rollback(sp);
            return;
        }

        // Cleaning arrays
        toInsert.clear();
        toUpdate.clear();
        toDelete.clear();

        // 3. Upsert questions
        for (BuilderQuestion bq : questions) {
            if (!QuestionDO.isSection(bq.type)) {
                Question__c q = getQuestion(bq, true);
                if (bq.parent != null && bq.parent != '') {
                    BuilderQuestion bqparent = findQuestion(bq.parent);
                        Question__c parent = getQuestion(bqparent, false);
                        q.Parent__c = parent.Id;
                } if (q.Id != null) {
                    toUpdate.add(q);
                } else {
                    toInsert.add(q);
                    builderToInsert.add(bq);
                }
            }
        }

        try {
            update toUpdate;
            insert toInsert;
        } catch(Exception ex) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            Database.rollback(sp);
            return;
        }

        // Add children to cascading question when inserting
        addChildCascading(builderToInsert);

        GenericObjectCreator optionCreator =
            new GenericObjectCreator(Option__c.SObjectType);
        optionCreator.checkObjectAccessible();
        optionCreator.checkObjectCreateable();
        optionCreator.checkObjectUpdateable();
        optionCreator.checkObjectDeletable();

        // 4. Convert BuilderQuestion.Option objects into actual Option__c objects
        Option__c[] opUpsert = new Option__c[]{};
        Option__c[] opDelete = new Option__c[]{};

        for (BuilderQuestion bq : questions) {
                Question__c q = getQuestion(bq, false);
            if (bq.options != null) {
                for (BuilderQuestion.Option bo : bq.options) {
                        opUpsert.add( getOption(bo, q) );
                }
            }

            if (bq.deletedOptions != null) {
                for (String optionId : bq.deletedOptions) {
                    Option__c o = sfoptions.get(optionId);
                    if (o != null) opDelete.add(o);
                }
            }
        }

        upsert opUpsert;
        delete opDelete;

        // Clear the deletedQuestion list (these have been deleted already)
        for (BuilderQuestion q: deletedQuestions) {
            sfquestions.remove(q.id);
        }

        for (BuilderQuestion q: questions) {
            if(q.deletedOptions != null) {
                for (String optionId : q.deletedOptions) {
                    sfoptions.remove(optionId);
                }
                q.deletedOptions.clear();
            }
        }

        // Clean the list of deleted questions
        deletedQuestions.clear();

        // Refresh Last modified DATE.
        Survey__c currentSurvey =
            [SELECT LastModifiedDate FROM Survey__c WHERE Id = :this.survey.Id limit 1];
        lastModified = currentSurvey.LastModifiedDate;
    }

    /**
     * IDALMSA-4011 / IDALMSA-4012
     * Insert child questions of cascading parent
     * Set as required if parent is required too
     *
     * @param List of questions parent of cascading levels
     */
    public void addChildCascading(List<BuilderQuestion> parentQuestions){
        Set<String> parentsSelects                 = new Set<String>();
        Set<String> parentsIds                     = new Set<String>();
        List<Question__c> newQuestionLevels        = new List<Question__c>();
        List<Question__c> levelsToUpdate           = new List<Question__c>();
        Map<String, Question__c> parentByCascading = new Map<String, Question__c>();
        Map<String, Boolean> requiredByQuestionId  = new Map<String, Boolean>();
        String controlling;

        for(BuilderQuestion bq : parentQuestions){
            if(bq.type == QuestionDO.TYPE_CASCADING_SELECT){
                Question__c pQuestion = sfquestions.get(bq.id);
                parentsSelects.add(pQuestion.CascadingSelect__c);
                parentsIds.add(pQuestion.Id);
                parentByCascading.put(pQuestion.CascadingSelect__c, pQuestion);
                requiredByQuestionId.put(pQuestion.Id, bq.required);
                cascadingSelectedName = pQuestion.CascadingSelect__r.Name;
            }
        }

        GenericObjectCreator cascadingSelectCreator =
            new GenericObjectCreator(CascadingSelect__c.SObjectType);
        cascadingSelectCreator.checkObjectAccessible();
        GenericObjectCreator cascadingLevelCreator =
            new GenericObjectCreator(CascadingLevel__c.SObjectType);
        cascadingLevelCreator.checkObjectAccessible();
        cascadingLevelCreator.checkFieldsCreateable(
            new List<Schema.SObjectField> {
                CascadingLevel__c.Name__c,
                CascadingLevel__c.Position__c
            }
        );
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkObjectCreateable();
        questionCreator.checkObjectUpdateable();
        questionCreator.checkFieldsUpdateable(
            new List<Schema.SObjectField> {
                Question__c.ControllingQuestion__c,
                Question__c.Required__c
            }
        );
        questionCreator.checkFieldsCreateable(
            new List<Schema.SObjectField> {
                Question__c.Survey__c,
                Question__c.Parent__c,
                Question__c.Caption__c,
                Question__c.CascadingLevel__c,
                Question__c.Type__c,
                Question__c.Position__c
            }
        );

        if(!parentsSelects.isEmpty()){
            List<CascadingSelect__c> selects = [SELECT
                                                    Id,
                                                    (SELECT
                                                            Name__c,
                                                            Position__c
                                                        FROM
                                                            Cascading_Levels__r
                                                        ORDER BY
                                                            Position__c ASC)
                                                FROM
                                                    CascadingSelect__c
                                                WHERE
                                                    Id IN :parentsSelects];

            for(CascadingSelect__c s : selects){
                if(!s.Cascading_Levels__r.isEmpty()){
                    // Create child questions to insert
                    for(CascadingLevel__c level : s.Cascading_Levels__r){
                        Question__c newChild =
                            new Question__c();

                        newChild.Survey__c         = parentByCascading.get(s.Id).Survey__c;
                        newChild.Parent__c         = parentByCascading.get(s.Id).Id;
                        newChild.Caption__c        = level.Name__c;
                        newChild.CascadingLevel__c = level.Id;
                        newChild.Type__c           = QuestionDO.TYPE_CASCADING_LEVEL;
                        newChild.Position__c       = level.Position__c;
                        newQuestionLevels.add(newChild);
                    }
                }
            }
        }

        if(!newQuestionLevels.isEmpty()){
            // Insert new questions
            insert newQuestionLevels;

            // Select all questions to update, depending on the parent
            newQuestionLevels = [SELECT
                                        Id,
                                        (SELECT
                                                Id,
                                                Position__c,
                                                ControllingQuestion__c
                                            FROM
                                                Questions__r
                                            ORDER BY
                                                Position__c ASC)
                                    FROM
                                        Question__c
                                    WHERE
                                        Id IN :parentsIds
                                    ORDER BY
                                        Position__c ASC];

            // Update new questions
            for(Question__c parentQ : newQuestionLevels){
                controlling = '';
                for(Question__c newLevel : parentQ.Questions__r){
                    // Set required field of level depending on parent
                    newLevel.Required__c = requiredByQuestionId.get(parentQ.Id);
                    // If it is not first level, set controlling question
                    if(newLevel.Position__c > 1){
                        newLevel.ControllingQuestion__c = controlling;
                    }
                    // Add questions levels to update
                    levelsToUpdate.add(newLevel);
                    controlling = newLevel.Id;
                }
            }
            update levelsToUpdate;
        }

        if (!parentsSelects.isEmpty()) {

            // Update last modified date after de deletion of the question levels
            lastModified =
                [
                    SELECT
                        LastModifiedDate
                    FROM
                        Survey__c
                    WHERE
                        Id = :this.survey.Id LIMIT 1
                ].LastModifiedDate;
        }
    }

    /**
     * IDALMSA-4012
     * Only execute when is updating cascading parent question
     * Set children of cascading questions required or not depending on parent
     *
     * @param Id of cascading question
     */
    public void setChildrenAsRequired(BuilderQuestion cascadingParent){
        Set<String> parentsIds = new Set<String>();
        String parentId = sfquestions.get(cascadingParent.id).Id;

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkObjectUpdateable();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Required__c
            }
        );
 
        List<Question__c> children = [SELECT
                                            Id,
                                            Required__c
                                        FROM
                                            Question__c
                                        WHERE
                                            Parent__c = :parentId
                                        ORDER BY
                                            Position__c];

        // Set required or not depending on parent
        for (Question__c child : children) {
            questionCreator.populateField(
                child,
                Question__c.Required__c,
                cascadingParent.required
            );
        }
        update children;
    }

    /**
     * IDALMSA-4321
     * Delete question levels when edit and change cascading select library
     *
     * @param Id of cascading question
     */
    public void deleteOldChildren(List<Question__c> cascadingParents){
        Set<String> parentsIds = new Set<String>();

        for(Question__c cP : cascadingParents){
            parentsIds.add(cP.Id);
        }

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkObjectDeletable();

        if(!parentsIds.isEmpty()){
            List<Question__c> childrenToDelete = [SELECT
                                                        Id
                                                    FROM
                                                        Question__c
                                                    WHERE
                                                        Parent__c IN :parentsIds];

            delete childrenToDelete;

            // Update last modified date after de deletion of the question levels
            lastModified = [SELECT LastModifiedDate FROM Survey__c WHERE Id = :this.survey.Id LIMIT 1].LastModifiedDate;
        }
    }

    //Move the selected question after to the destination selected question
    public void move(String originId, String destinationId){
        if(originId == destinationId && destinationId != null) return;
        BuilderQuestion movedQ       = findQuestion(originId);
        BuilderQuestion destinationQ = findQuestion(destinationId);

        //Updating sections position
        if(QuestionDO.isSection(movedQ.type)){
            //Update position for Section moved to first place
            if(destinationId == FIRST_SECTION){
                for(BuilderQuestion q: questions){
                    if(q.position < movedQ.position && QuestionDO.isSection(q.type))
                        q.position++;
                }
                movedQ.position = 1;
            }
            else{
                for(BuilderQuestion q: questions){
                    if(q.position > movedQ.position && QuestionDO.isSection(q.type))
                        q.position--;
                }
                //Update moved section position
                movedQ.position = destinationQ.position +1;

                //Update position of sections following
                for(BuilderQuestion q: questions){
                    if(q.position >= movedQ.position && q.id != movedQ.id && QuestionDO.isSection(q.type))
                        q.position++;
                }
            }
        }
        else{
            // Update questions position
            for (BuilderQuestion q : questions){
                if (q.parent == movedQ.parent && q.position > movedQ.position){
                    q.position--;
                }
            }
            // Update moved question position
            // (Consider if destination is section or question)
            if (QuestionDO.isSection(destinationQ.type)){
                // Set show all on one page as false when section contains a cascading question
                if (movedQ.type == QuestionDO.TYPE_CASCADING_SELECT && movedQ.parent != destinationQ.id){
                    findQuestion(destinationQ.id).samePage = false;
                }
                movedQ.parent   = destinationQ.Id;
                movedQ.position = 1;
            } else {
                // Set show all on one page as false when section contains a cascading question
                if (movedQ.type == QuestionDO.TYPE_CASCADING_SELECT && movedQ.parent != destinationQ.parent){
                    findQuestion(destinationQ.parent).samePage = false;
                }
                movedQ.parent   = destinationQ.parent;
                movedQ.position = destinationQ.position + 1;
            }

            // Update position of questions following
            for (BuilderQuestion q : questions){
              if (q.parent == movedQ.parent && q.position >= movedQ.position && q.id != movedQ.id)
                q.position++;
            }
        }
    }

    /**
     * Encode Cascading selects fields to handle scripts and html text.
     * @return List of cascading selects
     */
    public List<CascadingSelect__c> encodeCascadingsData(){
        SFDCEncoder encode = new SFDCEncoder();
        GenericObjectCreator cascadingSelectCreator =
            new GenericObjectCreator(CascadingSelect__c.SObjectType);
        cascadingSelectCreator.checkObjectAccessible();
        cascadingSelectCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            CascadingSelect__c.Name,
            CascadingSelect__c.Description__c
        });
        List<CascadingSelect__c> cascadings = [SELECT
                                                    Id,
                                                    Name,
                                                    Description__c
                                                FROM
                                                    CascadingSelect__c
                                                WHERE
                                                    Status__c = :C.CASCADING_STATUS_UPLOADED
                                                ORDER BY
                                                    Name ASC];

        for (CascadingSelect__c cascading : cascadings) {
            cascadingSelectCreator.populateFields(
                cascading,
                new Map<Schema.SObjectField, Object> {
                    CascadingSelect__c.Name =>
                        encode.SFDC_HTMLENCODE(cascading.Name),
                    CascadingSelect__c.Description__c =>
                        encode.SFDC_HTMLENCODE(cascading.Description__c)
                }
            );
        }
        return cascadings;
    }

    // Shorthand method
    private String getParam(String key){ return ApexPages.CurrentPage().getParameters().get(key); }

    public PageReference addQuestionController(){
        try{
            String strQuestion = getParam('question');
            this.addQuestion(strQuestion);
            this.save();
        }catch(Exception ex){
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
        }
        return null;
    }

    public PageReference editQuestionController(){
        try{
            String strQuestion = getParam('question');
            String qId = this.editQuestion(strQuestion);

            if(!findQuestion(qId).required && !QuestionDO.isSection(findQuestion(qId).type) && hasRequiredMapped(qId, false)){
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, requiredError));
            }else{
                this.save();
            }
        }catch(Exception ex){
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
        }
        return null;
    }

    public PageReference moveQuestionController(){
        String originId      = getParam('originId');
        String destinationId = getParam('destinationId');
        try {
            this.move(originId, destinationId);
        } catch(Exception ex) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
        }
        return null;
    }

    public PageReference removeQuestionController(){
        String id = getParam('qId');
        if(!hasRequiredMapped(id, true)){
            try{
                this.removeQuestion(id);
            }catch(Exception ex){
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            }
        }else{
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, requiredError));
        }
        return null;
    }

    public PageReference quickSave(){
        save();
        return null;
    }

    public PageReference saveContinue(){
        save();
        if(!hasApexMessage && !concurrentSave){
            PageReference auxRef = Page.SurveyScoring;
            string surveyId = ApexPages.currentPage().getParameters().get('id');
            auxRef.getParameters().put('id', surveyId);
            return auxRef;
        }else{
            return null;
        }
    }

    private Boolean hasRequiredMapped(String qId, Boolean isDeleting) {
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Question__c.Type__c,
            Question__c.Survey__c,
            Question__c.Required__c
        });

        List<Question__c> question = [SELECT Type__c, Survey__c, Required__c FROM Question__c WHERE Id = :qId limit 1];
        if (!question.isEmpty()) {
            return hasRequiredMapped(question[0], isDeleting);
        } else {
            for (Integer i = 0; i < questions.size(); i++) {
                if (questions[i].parent == qid) {
                    if (hasRequiredMapped(getQuestion(questions[i], true), isDeleting)) {
                        return true;
                    }
                }
            }
            return false;
        }
    }

    /**
     * IDALMSA-4430
     * 1- Validate if question is required by mapping to a required field, then show errors depending on action
     * 2- Validate if question is required by mapping to an id field, then show errors depending on action
     * 3- Validate if question is required by mapping to required relations, then show errors depending on action
     *
     * @param question   - To validate
     * @param isDeleting - True if question is being deleted
     *
     * @return - Boolean true if there is an error to show
     */
    private Boolean hasRequiredMapped(Question__c question, Boolean isDeleting) {

        if (sfquestions.get(question.Id) != null) {

            // Save point
            Savepoint sp = Database.setSavepoint();
            String qId = sfquestions.get(question.Id).Id;
            Question__c questToDelete = question;
            List<QuestionMapping__c> mapping = new List<QuestionMapping__c>{};
            List<String> childrenIds = new List<String>{};

            // If question to delete is a section, check if it contains at least a question mapped to a required field inside
            if (questToDelete != null) {
                if (QuestionDo.isSection(questToDelete.Type__c)) {
                    for (BuilderQuestion bq : questions) {
                        if (bq.parent == qId) {
                            if(this.mappingsPerQuestion.containsKey(bq.id)) {
                                if (this.mappingsPerQuestion.get(bq.id) != null) {
                                    mapping.addAll(this.mappingsPerQuestion.get(bq.id));
                                }
                            }
                        }
                    }
                } else {

                    // If it is a question just check if it is mapped to a required field
                    if (this.mappingsPerQuestion.get(qId) != null) {
                        mapping.addAll(this.mappingsPerQuestion.get(qId));
                    }
                }
            }

            Set<Id> surveyIds = new Set<Id>();
            surveyIds.add(question.Survey__c);

            // Obtain the Set of the survey mappings Id's with required relations.
            Set<String> listReferenceRequiredSM =
                SurveyFieldMappingController.obtainListOfSurveyMappingsWithRequiredRelations(surveyIds);

            if (!mapping.isEmpty()) {
                for (QuestionMapping__c qM : mapping) {
                    if(DescribeHandler.fieldExists(qM.SurveyMapping__r.ObjectApiName__c, qM.FieldApiName__c)) {

                        Schema.DescribeFieldResult fieldDescribe =
                            DescribeHandler.getFieldDescribe(qM.SurveyMapping__r.ObjectApiName__c, qM.FieldApiName__c);

                        // If the Field is required and is not set by itself
                        if(
                                !qM.SurveyMapping__r.IsReference__c &&
                                !fieldDescribe.isNillable() &&
                                !fieldDescribe.isDefaultedOnCreate() &&
                                (!findQuestion(qId).required || isDeleting)
                        ) {
                            requiredError = isDeleting ?
                                System.label.SURVEY_QUESTION_ERR_MAPPED_QUESTION :
                                System.label.SURVEY_QUESTION_ERR_MAPPED_REQUIREDCANNOTBEFALSE;

                            // Set builder question to required
                            findQuestion(qId).required = true;
                            return true;
                        } else if(
                                !qM.SurveyMapping__r.IsReference__c &&
                                qM.FieldApiName__c.equals(qM.SurveyMapping__r.MatchingField__c) &&
                                qM.SurveyMapping__r.MatchingField__c != null &&
                                (!findQuestion(qId).required || isDeleting)
                        ) {

                            // If it is required by mapping with an id field
                            requiredError = (isDeleting ? System.label.SURVEY_QUESTION_ERR_MAPPED_QUESTION_IDFIELD
                                            : System.label.SURVEY_QUESTION_ERR_MAPPED_QUESTION_IDFIELD_REQUIRED);

                            // Set builder question to required
                            findQuestion(qId).required = true;
                            return true;
                        } else if(
                                qM.SurveyMapping__r.IsReference__c &&
                                listReferenceRequiredSM.contains(qM.SurveyMapping__c)
                                && (!findQuestion(qId).required || isDeleting)
                        ) {
                            requiredError = isDeleting ?
                                System.label.SURVEY_QUESTION_ERR_MAPPED_QUESTION_REFERENCE_OBJECT :
                                System.label.SURVEY_QUESTION_ERR_RELATION_REQUIRED_CANNOT_BE_FALSE;

                            // Set builder question to required
                            findQuestion(qId).required = true;
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    private void loadQuestionMappings() {
        this.mappingsPerQuestion = new Map<String, List<QuestionMapping__c>> ();

        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            SurveyMapping__c.ObjectApiName__c,
            SurveyMapping__c.MatchingField__c,
            SurveyMapping__c.IsReference__c
        });
        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(QuestionMapping__c.SObjectType);
        questionMappingCreator.checkObjectAccessible();
        questionMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            QuestionMapping__c.FieldApiName__c,
            QuestionMapping__c.SurveyMapping__c,
            QuestionMapping__c.Question__c
        });

        for (QuestionMapping__c qm : [SELECT
                                            Id,
                                            FieldApiName__c,
                                            Question__c,
                                            SurveyMapping__r.ObjectApiName__c,
                                            SurveyMapping__r.MatchingField__c,
                                            SurveyMapping__r.IsReference__c
                                        FROM
                                            QuestionMapping__c
                                        WHERE
                                            SurveyMapping__r.Survey__c = :survey.Id]){
            encodeQuestionMappingRecords(qm);
            if (mappingsPerQuestion.get(qm.Question__c) == null) {
                mappingsPerQuestion.put(qm.Question__c, new List<QuestionMapping__c>{qm});
            } else {
                mappingsPerQuestion.get(qm.Question__c).add(qm);
            }
        }
    }

    /** 
     * Method to encode Question Mapping values
     */
    private void encodeQuestionMappingRecords(QuestionMapping__c questionMapping) {
        SFDCEncoder encoder = new SFDCEncoder();
        questionMapping.FieldApiName__c = encoder.SFDC_JSENCODE(questionMapping.FieldApiName__c);
        questionMapping.SurveyMapping__r.ObjectApiName__c =
            encoder.SFDC_JSENCODE(questionMapping.SurveyMapping__r.ObjectApiName__c);
        questionMapping.SurveyMapping__r.MatchingField__c =
            encoder.SFDC_JSENCODE(questionMapping.SurveyMapping__r.MatchingField__c);
    }

    /**
     * Check if the number question to delete is related to a repeated section
     *
     * IDALMSA-4842
     * @param id of section to update
     */
    private void isNumberAndIsRelated(Question__c section) {
        // The section to update is repeated then check if there is some question to delete related to this
        if(section.Type__c == QuestionDO.TYPE_REPEAT && section.RepeatSourceValue__c != null) {
            if(setDeletedIds.contains(section.RepeatSourceValue__c)) {
                    section.RepeatSourceValue__c = null;
            }
        }
    }
}
