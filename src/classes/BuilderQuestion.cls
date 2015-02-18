/*
 *(c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class BuilderQuestion {

    //----------
    // CONSTANTS
    //----------

    public static final String ERR_MISSING_REQ_FIELD = system.label.QUESTION_BUILDER_ERR_MISSING_REQ_FIELD;
    public static final String ERR_INVALID_OPERATION = system.label.QUESTION_BUILDER_ERR_INVALID_OPERATION;
    public static final String ERR_NO_SURVEY_SPECIFIED = system.label.QUESTION_BUILDER_ERR_SURVEY_NOT_SPECIFIED;
    public static final String OP_CHANGE_QUESTION_TYPE = system.label.QUESTION_BUILDER_CHANGE_QUESTION_TYPE;

    //-------
    // FIELDS
    //-------

    public String id;     // id to identify this question during construction
    public String parent; // id of the parent question, if any
    public String originId; // Origin question id
    public String prevSourceQuestion; // Id of prev question to set the repeated times of the section
    public String prevSourceQuestionName; //name of the  source number question

    public String caption;
    public String name;
    public String qhint;
    public Integer position;
    public Boolean required;
    public Boolean remoteEditable;
    public Boolean samePage;
    public String skipLogicBehavior;
    public String skipLogicOperator;
    public Decimal minimum;
    public Decimal maximum;
    public String doAfter;
    public String doBefore;
    public String type;
    public Option[] options = new Option[]{};
    public Set<String> deletedOptions = new Set<String>();
    public SkipCondition[] skipconditions = new SkipCondition[]{};
    public String cascadingId;
    public String cascadingName;
    public List<ScoreValue> scoreValues;

    //-------------
    // CONSTRUCTORS
    //-------------

    /**
     * No param constructor
     */
    public BuilderQuestion() {}

    // Creates a new BuilderQuestion object from a json input
    public static BuilderQuestion fromJson(String jsonQuestion, Boolean checkRequiredFields) {
        JSONParser parser = JSON.createParser(jsonQuestion);
        Type builderQuestionType = Type.forName('BuilderQuestion');
        BuilderQuestion q = (BuilderQuestion)parser.readValueAs(builderQuestionType);

        if (checkRequiredFields){
            if (q.type == null) SurveyException.raise(ERR_MISSING_REQ_FIELD, 'type');
        }

        // If id was not specified on the json string, generate a new id for this question
        if (q.id == null) q.id = Datetime.now().getTime().format();
        return q;
    }

    // Creates a new BuilderQuestion object from a Question__c input
    public BuilderQuestion(Question__c question) {

        SFDCEncoder encode = new SFDCEncoder();
        id                     = question.Id;
        parent                 = question.Parent__c;
        type                   = question.Type__c;
        required               = question.Required__c != null && question.Required__c;
        samePage               = question.SamePage__c;
        skipLogicBehavior      = question.SkipLogicBehavior__c;
        skipLogicOperator      = question.SkipLogicOperator__c;
        caption                = question.Caption__c;
        name                   = question.Name;
        qhint                  = question.Hint__c;
        position               = Integer.valueOf(question.Position__c);
        remoteEditable         = question.IsRemoteEditable__c;
        originId               = question.RemoteServerId__c;
        prevSourceQuestion     = question.RepeatSourceValue__c;
        prevSourceQuestionName = question.RepeatSourceValue__r.Name;
        // Number questions
        minimum                = question.Minimum__c;
        maximum                = question.Maximum__c;
        doBefore               = question.DoBefore__c;
        doAfter                = question.DoAfter__c;

        // Cascading questions
        cascadingId            = question.CascadingSelect__c;
        cascadingName          = encode.SFDC_HTMLENCODE(question.CascadingSelect__r.Name);
    }

    //Generate id
    private String newId(){
        return Datetime.now().getTime().format();
    }

    //--------
    // METHODS
    //--------

    public Option getOption(String id){
        if (this.options != null)
            for(Option o: this.options)
                if (o.id == id)
                    return o;
        return null;
    }

    public void copyTo(BuilderQuestion target) {
        // Copy the list of options

        // 0. Use temporary lists, in case there is an error and a rollback is needed
        Option[] ops = new Option[]{};
        Set<String> del = new Set<String>();
        if (target.deletedOptions != null) del.addAll(target.deletedOptions);

        // 1. Update existing options
        // 2. Remove options that no longer exist
        // -- Variables: t(arget), s(ource), n(ew)
        if (target.options != null) {
            for(Option t : target.options) {
                Option s = this.getOption(t.id);
                if (s != null) {
                    Option n = new Option();
                    t.copyTo(n);
                    s.copyTo(n);
                    ops.add(n);
                } else {
                    del.add(t.id);
                }
            }
        }

        // 3. Add newly created options
        if (this.options != null) {
            for(Option s : this.options) {
                Option t = target.getOption(s.id);
                if (t == null) {
                    ops.add(s);
                }
            }
        }

        // 4. Sort options (insert-sort by position)
        for(Integer start = 0; start < ops.size(); start++){
            Integer minval = 9999, minpos = 9999;
            for(Integer pos = start; pos < ops.size(); pos++){
                Option o = ops[pos];
                if (o.position < minval) { minval = o.position; minpos = pos; }
            }
            Option picked = ops[minpos];
            ops[minpos] = ops[start];
            ops[start] = picked;
        }

        // 5. Check that option positions are valid (secuential, unique, complete)
        final String REPEATED_POS = 'Two or more options share the same position for question {0}.';
        final string MISSING_POS = 'There are missing positions on the option list for question {0}. There are {1} options, but none has position {2}.';
        Integer lastpos = 9999;
        for (Integer pos = 0; pos < ops.size(); pos++) {
            Option o = ops[pos];
            if (o.position == lastpos) SurveyException.raise(REPEATED_POS, this.id);
            if (o.position > pos+1) SurveyException.raise(MISSING_POS, new String[]{this.id, String.valueOf(ops.size()), String.valueOf(pos+1)});
            lastpos = o.position;
        }

        // Now that everything's ok, replace the values on target for real
        target.id                   = id;
        target.parent               = parent;
        target.caption              = caption;
        target.name                 = name;
        target.qhint                = qhint;
        target.required             = required != null && required;
        target.samePage             = samePage;
        target.skipLogicBehavior    = skipLogicBehavior;
        target.skipLogicOperator    = skipLogicOperator;
        target.position             = position;
        target.type                 = type;
        target.remoteEditable       = remoteEditable;
        target.originId             = originId;
        target.prevSourceQuestion   = prevSourceQuestion;

        // Number type questions
        target.minimum              = minimum;
        target.maximum              = maximum;
        target.doBefore             = doBefore;
        target.doAfter              = doAfter;

        target.options              = ops;
        target.deletedOptions       = del;

        // Cascading type questions
        target.cascadingId          = cascadingId;
        target.cascadingName        = cascadingName;
    }

    public Question__c createQuestion(Survey__c survey) {
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        Question__c question = (Question__c) questionCreator.createNewRecord();
        questionCreator.populateField(
            question,
            Question__c.Survey__c,
            survey.id
        );
        updateQuestion(question);
        return question;
    }

    public void updateQuestion(Question__c question) {
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.populateFields(
            question,
            new Map<Schema.SObjectField, Object>{
                Question__c.Caption__c => caption,
                Question__c.Name => name,
                Question__c.Hint__c => qhint,
                Question__c.Required__c => required != null && required,
                Question__c.IsRemoteEditable__c =>
                    remoteEditable != null && remoteEditable,
                Question__c.SamePage__c => samePage != null && samePage,
                Question__c.SkipLogicBehavior__c => skipLogicBehavior,
                Question__c.SkipLogicOperator__c => skipLogicOperator,
                Question__c.Minimum__c => minimum,
                Question__c.Maximum__c => maximum,
                Question__c.DoBefore__c => doBefore,
                Question__c.DoAfter__c => doAfter,
                Question__c.Type__c => type,
                Question__c.Position__c => position,
                Question__c.RemoteServerId__c => originId,
                Question__c.RepeatSourceValue__c => prevSourceQuestion,
                Question__c.CascadingSelect__c => cascadingId
            }
        );
    }

    public with sharing class Option {
        public String id;
        public String name;
        public String caption;
        public Integer position;
        public Decimal ppiScore;
        public List<ScoreValue> scoreValues;

        // Shortcut for SurveyQuestion.page: we don't need to know
        // the actual values, we only need to know if it has any.
        public Boolean hasScoreValues = false;
        // Only need to know if it has any ppi score value.
        public Boolean hasPPIScoreValues = false;

        public Option(){}
        public Option(Option__c option){
            this.id       = option.Id;
            this.name     = option.name;
            this.caption  = option.Caption__c;
            this.position = Integer.valueOf(option.Position__c);
            this.ppiScore = option.PPIScore__c ;
            this.scoreValues = new List<ScoreValue>();
        }

        public void copyTo(Option target){
            target.id       = id;
            target.name     = name;
            target.caption  = caption;
            target.position = position;
            target.ppiScore = ppiScore;
        }

        public Option__c createOption(Question__c question) {
            GenericObjectCreator optionCreator =
                new GenericObjectCreator(Option__c.SObjectType);
            Option__c option = (Option__c) optionCreator.createNewRecord();
            optionCreator.populateField(
                option,
                Option__c.Question__c,
                question.id
            );
            updateOption(option);
            return option;
        }

        public void updateOption(Option__c option) {
            GenericObjectCreator optionCreator =
                new GenericObjectCreator(Option__c.SObjectType);
            optionCreator.populateFields(
                option,
                new Map<Schema.SObjectField, Object>{
                    Option__c.Caption__c => caption,
                    Option__c.name => name,
                    Option__c.Position__c => position,
                    Option__c.PPIScore__c => ppiScore
                }
            );
        }
    }  

    public with sharing class SkipCondition {
        public String id;
        public String sourceQuestionId;
        public String condition;
        public String value;
        public Boolean negate;
        public String parent;

        public SkipCondition(){}
        public SkipCondition(SkipCondition__c source){
            this.id               = source.Id;
            this.sourceQuestionId = source.SourceQuestion__c;
            this.condition        = source.Condition__c;
            this.value            = source.SkipValue__c;
            this.negate           = source.Negate__c;
            this.parent           = source.Parent__c;
        }

        public void copyTo(SkipCondition target){
            target.id               = id;
            target.sourceQuestionId = sourceQuestionId;
            target.condition        = condition;
            target.value            = value;
            target.negate           = negate;
            target.parent           = parent;
        }

        public SkipCondition__c createSkipCondition(Question__c question) {
            GenericObjectCreator skipConditionCreator =
                new GenericObjectCreator(SkipCondition__c.SObjectType);
            SkipCondition__c skipcond =
                (SkipCondition__c) skipConditionCreator.createNewRecord();
            skipConditionCreator.populateField(
                skipcond,
                SkipCondition__c.Parent__c,
                question.id
            );
            updateSkipCondition(skipcond);
            return skipcond;
        }

        public void updateSkipCondition(SkipCondition__c target) {
            GenericObjectCreator skipConditionCreator =
                new GenericObjectCreator(SkipCondition__c.SObjectType);
            skipConditionCreator.populateFields(
                target,
                new Map<Schema.SObjectField, Object> {
                    SkipCondition__c.SourceQuestion__c => this.sourceQuestionId,
                    SkipCondition__c.Condition__c => this.condition,
                    SkipCondition__c.SkipValue__c => this.value,
                    SkipCondition__c.Negate__c => this.negate
                }
            );
        }
    }

    public with sharing class ScoreValue{

        public String id;
        public String optionId;
        public String ScoringGroupId;
        public Decimal value;

        public ScoreValue(ScoreValue__c source){
            this.id             = source.Id;
            this.optionId       = source.Option__c;
            this.ScoringGroupId = source.ScoringGroup__c;
            this.value          = source.Value__c;
        }

    }
}
