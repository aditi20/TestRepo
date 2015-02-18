/**
 * Service class to allow for replication of a form
 * This can include cloning internally, the downloading of a form from
 * a remote server
 *
 * TODO:
 *    - Convert to use SurveyVersion__c when VERSIONING is implemented
 *    - Adding a (PPI) template into an existing survey
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class FormReplicationService {

    private static Boolean isPpi = false;
    private static Boolean isTemplate = false;
    private static Boolean isDownload = false;
    private static Boolean isCloned = false;
    private static SurveyVersion__c parentSurveyVersion;

    @TestVisible
    private static SurveyLibrary__c remoteLibrary;

    public static void setIsPpi(Boolean value) {
        isPpi = value;
    }

    public static Boolean getIsTemplate() {
        return isTemplate;
    }

    public static void setIsTemplate(Boolean value) {
        isTemplate = value;
    }

    public static Boolean getIsCloned() {
        return isCloned;
    }

    public static void setIsCloned(Boolean value) {
        isCloned = value;
    }

    public static Boolean getIsDownload() {
        return isDownload;
    }

    public static void setIsDownload(Boolean value) {
        isDownload = value;
    }

    public static void setRemoteLibrary(SurveyLibrary__c library) {
        remoteLibrary = library;
    }

    /**
     * Clone a survey that is not a template or PPITemplate
     */
    public static ReplicateBasicSurvey cloneSurvey(Id surveyId) {
        SurveySelector selector = new SurveySelector();
        ReplicateBasicSurvey replicator =
            new ReplicateBasicSurvey(
                (Survey__c) selector.getRecordById(surveyId)
            );
        replicator.copySurveyComponents();
        return replicator;
    }

    public static ReplicateBasicSurvey cloneSurvey(
            Survey__c surveyToClone,
            Survey__c newSurvey,
            UnitOfWork unitOfWork
    ) {
        SurveySelector selector = new SurveySelector();
        ReplicateBasicSurvey replicator =
            new ReplicateBasicSurvey(surveyToClone, newSurvey, unitOfWork);
        replicator.copySurveyComponents();
        return replicator;
    }

    public static ReplicateBasicSurvey cloneSurvey(
            Survey__c surveyToClone,
            Survey__c newSurvey
    ) {
        return cloneSurvey(surveyToClone, newSurvey, new UnitOfWork());
    }

    /**
     * Method passes isClonedForm as true when any normal survey or Ppi Survey
     * is cloned using "More Actions" on Survey Manager
     */
    public static ReplicateBasicSurvey cloneLocalForm(
            Survey__c surveyToClone,
            Survey__c newSurvey,
            Boolean usingTemplate,
            Boolean isClonedForm
    ) {
        return cloneLocalForm(surveyToClone, newSurvey, usingTemplate, null, isClonedForm);
    }

    /**
     * Method passes isClonedForm as true for following scenarios
     * 1. Normal survey or PpiSurvey is cloned using "Clone Existing Survey" button on Survey Settings
     * 2. Ppi template is cloned on Parent org
     */
    public static ReplicateBasicSurvey cloneLocalForm(
            Survey__c surveyToClone,
            Survey__c newSurvey,
            Boolean usingTemplate,
            UnitOfWork unitOfWork,
            Boolean isClonedForm
    ) {
        setIsTemplate(usingTemplate);
        setIsCloned(isClonedForm);

        if (surveyToClone.IsPPI__c) {
            return clonePpiTemplate(surveyToClone, newSurvey, unitOfWork);
        } else if (surveyToClone.IsTemplate__c) {
            return cloneTemplate(surveyToClone, newSurvey, unitOfWork);
        } else {
            return cloneSurvey(surveyToClone, newSurvey, unitOfWork);
        }
    }

    public static ReplicateLocalTemplate cloneTemplate(
            Survey__c surveyToClone,
            Survey__c newSurvey,
            UnitOfWork unitOfWork
    ) {
        SurveySelector selector = new SurveySelector();
        ReplicateLocalTemplate replicator =
            new ReplicateLocalTemplate(surveyToClone, newSurvey, unitOfWork);
        replicator.copySurveyComponents();
        return replicator;
    }

    public static ReplicateLocalPpiTemplate clonePpiTemplate(
            Survey__c surveyToClone,
            Survey__c newSurvey,
            UnitOfWork unitOfWork
    ) {
        SurveySelector selector = new SurveySelector();
        ReplicateLocalPpiTemplate replicator =
            new ReplicateLocalPpiTemplate(surveyToClone, newSurvey, unitOfWork);
        replicator.copySurveyComponents();
        return replicator;
    }

    /**
     * Replicate a form that is represented using the SurveyData class. This usually
     * means that it has been downloaded from another org
     */
    public static ReplicateBasicSurvey cloneSurveyData(SurveyData surveyDefinition) {
        setIsTemplate(surveyDefinition.survey.IsTemplate__c);
        if (surveyDefinition.survey.IsPPI__c) {
            return clonePpiSurveyData(surveyDefinition);
        } else {
            return cloneBasicSurveyData(surveyDefinition);
        }
    }

    /**
     * Replicate a basic survey that is represented using the SurveyData class. This usually
     * means that it has been downloaded from another org
     */
    public static ReplicateBasicSurvey cloneBasicSurveyData(SurveyData surveyDefinition) {
        ReplicateRemoteSurvey replicator =
            new ReplicateRemoteSurvey(
                surveyDefinition,
                remoteLibrary
            );
        replicator.copySurveyComponents();
        return replicator;
    }

    /**
     * Replicate a ppi survey that is represented using the SurveyData class. This usually
     * means that it has been downloaded from another org
     */
    public static ReplicateRemotePpiTemplate clonePpiSurveyData(SurveyData surveyDefinition) {
        ReplicateRemotePpiTemplate replicator =
            new ReplicateRemotePpiTemplate(
                surveyDefinition,
                remoteLibrary
            );
        replicator.copySurveyComponents();
        return replicator;
    }

    /**
     * Base class for replicating a survey. Contains all the replication that is common
     * amongst all types of form no matter the source
     */
    public virtual with sharing class ReplicateBasicSurvey {

        @TestVisible
        private Id surveyToCloneId;

        @TestVisible
        private Survey__c surveyToClone;

        @TestVisible
        private Survey__c newSurvey;

        @TestVisible
        private SurveyVersion__c surveyVersion;
        private QuestionDO.QuestionCollection questionCollection;
        private OptionDomain optionDomain;
        private ScoringGroupDomain scoringGroupDomain;
        private ScoreValueDomain scoreValueDomain;
        private SkipConditionDO skipConditionDomain;
        private FormReplicationService.ObjectMappingReplicator
            objectMappingReplicator;

        private UnitOfWork unitOfWork;

        private List<String> errors;

        // Map to track the ids from the original objects. Note that the key
        // in both of these maps is the oldId
        public Map<Id, sObject> oldIdMap;
        public Map<Id, sObject> newIdMap;

        @TestVisible
        private Boolean newSurveyIsTemplate;

        /**
         * 0 argument constructor for implicit construction. Not used throughout code.
         * Only for the compliler
         */
        public ReplicateBasicSurvey(){}
        public ReplicateBasicSurvey(Survey__c surveyToClone) {
            if (surveyToClone == null) {
                throw new FormReplicationService.FormReplicationServiceException(
                    System.label.SURVEY_ERR_NOSURVEYSELECTED
                );
            }
            this.surveyToClone = surveyToClone;
            this.surveyToCloneId = surveyToClone.Id;
            this.unitOfWork = new UnitOfWork();

            this.errors = new List<String>();

            this.oldIdMap = new Map<Id, SObject>();
            this.newIdMap = new Map<Id, SObject>();
            this.newSurveyIsTemplate = FormReplicationService.getIsTemplate();
            setUpDataToCopy();
        }
        public ReplicateBasicSurvey(Survey__c surveyToClone, Survey__c newSurvey) {
            this(surveyToClone);
            this.newSurvey = newSurvey;
        }
        public ReplicateBasicSurvey(
                Survey__c surveyToClone,
                Survey__c newSurvey,
                UnitOfWork newUnitOfWork
        ) {
            this(surveyToClone, newSurvey);
            if (newUnitOfWork != null) {
                this.unitOfWork = newUnitOfWork;
            }
        }

        public virtual void setUpDataToCopy() {
            QuestionDO questionDomain = new QuestionDO(
                (List<Question__c>) new QuestionSelector().getAllForSurveyIds(
                    new Set<String>{this.surveyToCloneId}
                )
            );
            this.questionCollection =
                questionDomain.generateNewSurveyQuestionOrder(
                    new List<Id>{this.surveyToCloneId}
                );
            this.optionDomain =
                new OptionDomain(new OptionSelector().getAllForSurvey(this.surveyToCloneId));
            this.scoringGroupDomain =
                new ScoringGroupDomain(
                    new ScoringGroupSelector().getAllForSurvey(this.surveyToCloneId)
                );
            this.scoreValueDomain =
                new ScoreValueDomain(
                    new ScoreValueSelector().getAllForSurvey(this.surveyToCloneId)
                );
            this.skipConditionDomain =
                new SkipConditionDO(
                    new SkipConditionSelector().getAllForSurvey(this.surveyToCloneId)
                );
            setUpExtraDataToCopy();
        }

        public virtual void setUpExtraDataToCopy() {}

        public void populateFromSurveyData(SurveyData surveyData) {
            this.questionCollection =
                new QuestionDO(surveyData.questions).generateNewSurveyQuestionOrder(
                    new List<Id>{this.surveyToCloneId}
                );
            this.optionDomain = new OptionDomain(surveyData.options);
            this.scoringGroupDomain = new ScoringGroupDomain(surveyData.scoreGroups);
            this.scoreValueDomain = new ScoreValueDomain(surveyData.scoreValues);
            this.skipConditionDomain = new SkipConditionDO(surveyData.skipConditions);
            populateFromSurveyDataExtra(surveyData);
        }

        public virtual void populateFromSurveyDataExtra(SurveyData surveyData) {}

        public Id getNewId() {
            return (this.hasErrors()) ? null : this.newSurvey.Id;
        }

        public Survey__c getNewSurvey() {
            return this.newSurvey;
        }

        private Boolean hasErrors() {
            return this.errors.size() > 0;
        }

        public List<String> getErrors() {
            return this.errors;
        }

        public Set<Id> getSurveysToClose() {
            if (this.objectMappingReplicator != null) {
                return this.objectMappingReplicator.getSurveysToClose();
            }
            return new Set<Id>();
        }

        /**
         * Close the surveys that were cloned that have broken field mappings
         */
        public Boolean closeBrokenForms() {
            if (!this.getSurveysToClose().isEmpty()) {
                SurveyUtils.closeFailedSurveysAndUserInfo(
                    this.getSurveysToClose(),
                    true
                );
                return true;
            }
            return false;
        }

        /**
         * Rollback the unit of work
         */
        public void rollback() {
            this.unitOfWork.setOverrideRollbackToMaster(false);
            this.unitOfWork.rollbackToMaster();
        }

        public virtual void copySurveyComponents() {
            this.copySurvey();
            this.copyAllQuestions();
            this.copyOptions();
            this.copyScoringGroups();
            this.copyScoreValues();
            this.copySkipConditions();
            this.copyObjectMapping();
            this.copyPpiTables();
            this.unitOfWork.commitWork();
        }

        public void copySurvey() {

            Boolean isNewSurvey = this.newSurvey == null;
            if (isNewSurvey) {
                SurveyDO surveyDomain = new SurveyDO(new List<Survey__c>{this.surveyToClone});
                this.newSurvey = surveyDomain.cloneSurveys()[0];
            }

            // Set isCloned Value for survey or template
            this.newSurvey.isCloned__c = getIsCloned();

            this.copySurveyOverride();
            if (isNewSurvey) {
                this.unitOfWork.addToInsertionOrder(Survey__c.SObjectType);
                this.unitOfWork.addToInsertList(this.newSurvey);
            } else {
                this.unitOfWork.addToUpdateOrder(Survey__c.SObjectType);
                this.unitOfWork.addToUpdateList(this.newSurvey);
            }
            this.unitOfWork.commitWork();
            this.unitOfWork.reset();
            loadSurveyVersion(this.newSurvey.Id);
        }
        public virtual void copySurveyOverride() {}

        private void loadSurveyVersion(Id newSurveyId) {
            this.surveyVersion = new SurveyVersionSelector().getLatestSurveyVersion(
                new List<Survey__c>{this.newSurvey}
            ).get(newSurveyId);
        }

        public void copyAllQuestions() {
            copyQuestions(this.questionCollection.sections);
            copyQuestions(this.questionCollection.repeats);
            copyQuestions(this.questionCollection.cascadings);
            copyQuestions(this.questionCollection.questions);
            copyQuestions(this.questionCollection.cascadingLevels);
            this.unitOfWork.commitWork();
            this.unitOfWork.reset();

            this.unitOfWork.addToUpdateOrder(Question__c.getSObjectType());
            addRepeatLinks();
            addCascadingLevelControls();
        }

        public void copyQuestions(List<QuestionDO.CloneQuestionWrapper> questionsToCopy) {

            for (QuestionDO.CloneQuestionWrapper questionWrapper : questionsToCopy) {
                Question__c parent = (questionWrapper.originalQuestion.Parent__c != null) ?
                    (Question__c) getOldRecord(questionWrapper.originalQuestion.Parent__c) :
                    null;
                Boolean hasParent = (parent != null);
                Integer level = (hasParent) ? 2 : 1;
                while (hasParent) {
                    if (getOldRecord(parent.Parent__c) != null) {
                        parent =
                            (Question__c)
                                getOldRecord(parent.Parent__c);
                        level++;
                    } else {
                        hasParent = false;
                    }
                }
                this.unitOfWork.addToInsertionOrder(Question__c.getSObjectType(), level);
                questionWrapper.cloneQuestion();
                GenericObjectCreator.fetchObjectsCreator(
                    Question__c.getSObjectType()
                ).populateFields(
                    questionWrapper.copiedQuestion,
                    new Map<Schema.SObjectField, Object>{
                        Question__c.MaxInstance__c => 0
                    }
                );
                copyQuestionOverride(questionWrapper, parent, level);
            }
        }

        private virtual void copyQuestionOverride(
                QuestionDO.CloneQuestionWrapper questionWrapper,
                Question__c parent,
                Integer level
        ) {
            copyQuestion(questionWrapper, parent, level);
        }

        private void copyQuestion(
                QuestionDO.CloneQuestionWrapper questionWrapper,
                Question__c parent,
                Integer level
        ) {
            this.unitOfWork.createRelationship(
                questionWrapper.copiedQuestion,
                Question__c.Survey__c,
                this.newSurvey,
                level
            );

            if (questionCollection.orderMap.get(questionWrapper.originalQuestionId) != null) {
                GenericObjectCreator.fetchObjectsCreator(
                    Question__c.getSObjectType()
                ).populateFields(
                    questionWrapper.copiedQuestion,
                    new Map<Schema.SObjectField, Object>{
                        Question__c.Position__c =>
                            questionCollection.orderMap.get(questionWrapper.originalQuestionId)
                    }
                );
            }

            // If the question is a repeat and there is a controlling question to it
            // Blank the new question as it will be filled in later when the questions are saved
            if (
                    questionWrapper.copiedQuestion.Type__c.equals(QuestionDO.TYPE_REPEAT) &&
                    questionWrapper.originalQuestion.RepeatSourceValue__c != null
            ) {
                GenericObjectCreator.fetchObjectsCreator(
                    Question__c.getSObjectType()
                ).populateFields(
                    questionWrapper.copiedQuestion,
                    new Map<Schema.SObjectField, Object>{
                        Question__c.RepeatSourceValue__c => null
                    }
                );
            }

            // Add the parent question
            if (parent == null) {
                this.unitOfWork.addToInsertList(questionWrapper.copiedQuestion, level);
            } else {
                this.unitOfWork.addToInsertList(
                    questionWrapper.copiedQuestion,
                    Question__c.Parent__c,
                    this.getNewRecord(questionWrapper.originalQuestion.Parent__c),
                    level
                );
            }
            this.addToIdMaps(questionWrapper);
        }

        private void addRepeatLinks() {
            for (
                    QuestionDO.CloneQuestionWrapper questionWrapper :
                        this.questionCollection.repeats
            ) {
                Question__c question = questionWrapper.originalQuestion;
                if (question.RepeatSourceValue__c != null) {
                    Question__c newQuestion =
                        (Question__c) this.getNewRecord(questionWrapper.originalQuestionId);
                    GenericObjectCreator.fetchObjectsCreator(
                        Question__c.getSObjectType()
                    ).populateFields(
                        questionWrapper.copiedQuestion,
                        new Map<Schema.SObjectField, Object>{
                            Question__c.RepeatSourceValue__c =>
                                this.getNewRecord(
                                    questionWrapper.originalQuestion.RepeatSourceValue__c
                                ).Id
                        }
                    );
                    this.unitOfWork.addToUpdateList(questionWrapper.copiedQuestion);
                }
            }
        }

        private void addCascadingLevelControls() {
            for (
                    QuestionDO.CloneQuestionWrapper questionWrapper :
                        this.questionCollection.cascadingLevels
            ) {
                Question__c question = questionWrapper.originalQuestion;
                if (question.ControllingQuestion__c != null) {
                    Question__c newQuestion =
                        (Question__c) this.getNewRecord(questionWrapper.originalQuestionId);
                    GenericObjectCreator.fetchObjectsCreator(
                        Question__c.getSObjectType()
                    ).populateFields(
                        questionWrapper.copiedQuestion,
                        new Map<Schema.SObjectField, Object>{
                            Question__c.ControllingQuestion__c =>
                                this.getNewRecord(
                                    questionWrapper.originalQuestion.ControllingQuestion__c
                                ).Id
                        }
                    );
                    this.unitOfWork.addToUpdateList(questionWrapper.copiedQuestion);
                }
            }
        }

        private void copyOptions() {
            this.unitOfWork.addToInsertionOrder(Option__c.getSObjectType(), 1);
            for (Option__c option : (List<Option__c>) this.optionDomain.records) {
                Id oldOptionId = option.Id;
                option.Id = null;
                Option__c newOption = option.clone(false, true, false, false);
                copyOptionOverride(newOption, option, oldOptionId);
                this.addToIdMaps(option, newOption, oldOptionId);
                this.unitOfWork.addToInsertList(
                    newOption,
                    Option__c.Question__c,
                    this.getNewRecord(option.Question__c),
                    1
                );
            }
        }

        private virtual void copyOptionOverride(
                Option__c newOption,
                Option__c optionToCopy,
                Id oldOptionId
        ) {}

        private virtual void copyScoringGroups() {
            this.unitOfWork.addToInsertionOrder(ScoringGroup__c.getSObjectType(), 1);
            for (
                    ScoringGroup__c scoreGroup :
                    (List<ScoringGroup__c>) this.scoringGroupDomain.records
            ) {
                Id scoreGroupToCopyId = scoreGroup.Id;
                scoreGroup.Id = null;
                ScoringGroup__c newGroup = scoreGroup.clone(false, true, false, false);
                copyScoringGroupOverride(newGroup, scoreGroup, scoreGroupToCopyId);
                this.addToIdMaps(scoreGroup, newGroup, scoreGroupToCopyId);
                this.unitOfWork.addToInsertList(
                    newGroup,
                    ScoringGroup__c.Survey__c,
                    this.newSurvey,
                    1
                );
            }
        }

        private virtual void copyScoringGroupOverride(
                ScoringGroup__c newScoringGroup,
                ScoringGroup__c scoringGroupToCopy,
                Id scoreGroupToCopyId
        ) {}

        private void copyScoreValues() {
            this.unitOfWork.addToInsertionOrder(ScoreValue__c.getSObjectType(), 1);

            for (ScoreValue__c scoreValue : (List<ScoreValue__c>) this.scoreValueDomain.records) {
                Id oldScoreValueId = scoreValue.Id;
                scoreValue.Id = null;
                ScoreValue__c newScoreValue = scoreValue.clone(false, true, false, false);
                copyScoreValueOverride(newScoreValue, scoreValue, oldScoreValueId);
                this.addToIdMaps(scoreValue, newScoreValue, oldScoreValueId);
                this.unitOfWork.addToInsertList(
                    newScoreValue,
                    ScoreValue__c.Option__c,
                    this.getNewRecord(scoreValue.Option__c),
                    1
                );
                this.unitOfWork.createRelationship(
                    newScoreValue,
                    ScoreValue__c.ScoringGroup__c,
                    this.getNewRecord(scoreValue.ScoringGroup__c),
                    1
                );
            }
        }

        private virtual void copyScoreValueOverride(
                ScoreValue__c newScoreValue,
                ScoreValue__c scoreValueToCopy,
                Id scoreValueToCopyId
        ) {}

        private void copySkipConditions() {
            this.unitOfWork.addToInsertionOrder(SkipCondition__c.getSObjectType(), 1);
            for (
                    SkipCondition__c skipCondition :
                        (List<SkipCondition__c>) this.skipConditionDomain.records
            ) {
                Id oldSkipConditionId = skipCondition.Id;
                skipCondition.Id = null;
                SkipCondition__c newSkipCondition =
                    skipCondition.clone(false, true, false, false);
                copySkipConditionOverride(newSkipCondition, skipCondition, oldSkipConditionId);
                this.addToIdMaps(skipCondition, newSkipCondition, oldSkipConditionId);

                // Get type of question to insert the right skip condition
                String type =
                    ((Question__c) getNewRecord(skipCondition.SourceQuestion__c)).Type__c;

                // Set the condition value to insert
                if (type == QuestionDO.TYPE_RADIO || type == QuestionDO.TYPE_CHECKBOX) {
                    if (!String.isEmpty(skipCondition.Value__c)) {
                        GenericObjectCreator.fetchObjectsCreator(
                            SkipCondition__c.getSObjectType()
                        ).populateFields(
                            newSkipCondition,
                            new Map<Schema.SObjectField, Object>{
                                SkipCondition__c.Value__c =>
                                    getNewRecord(skipCondition.Value__c).Id
                            }
                        );
                    }
                    if(!String.isEmpty(skipCondition.SkipValue__c)) {
                        GenericObjectCreator.fetchObjectsCreator(
                            SkipCondition__c.getSObjectType()
                        ).populateFields(
                            newSkipCondition,
                            new Map<Schema.SObjectField, Object>{
                                SkipCondition__c.SkipValue__c =>
                                    getNewRecord(skipCondition.SkipValue__c).Id
                            }
                        );
                    }
                }
                this.unitOfWork.addToInsertList(
                    newSkipCondition,
                    SkipCondition__c.Parent__c,
                    this.getNewRecord(skipCondition.Parent__c),
                    1
                );
                this.unitOfWork.createRelationship(
                    newSkipCondition,
                    SkipCondition__c.SourceQuestion__c,
                    this.getNewRecord(skipCondition.SourceQuestion__c),
                    1
                );
            }
        }

        private virtual void copySkipConditionOverride(
                SkipCondition__c newSkipCondition,
                SkipCondition__c skipConditionToCopy,
                Id oldSkipConditionId
        ) {}

        /**
         * Not every type of survey can replicate their field mappings
         * Extending classes that cannot replicate field mappings override this
         * method with an empty method
         */
        private virtual void copyObjectMapping() {
            this.objectMappingReplicator =
                new FormReplicationService.ObjectMappingReplicator(
                    this.surveyToCloneId,
                    this.surveyToClone,
                    this.newSurvey,
                    this.unitOfWork,
                    this.newIdMap,
                    this.oldIdMap
                );
            this.objectMappingReplicator.replicateMappings();
            this.errors.addAll(this.objectMappingReplicator.getErrors());
        }

        /**
         * Standard Survey doesn't have PPI tables in it so this method does nothing.
         * Is to be overriden by extending class that do need to copy PPI tables
         */
        private virtual void copyPpiTables() {}

        private void addToIdMaps(SObject oldObject, SObject newObject, Id oldObjectId) {
            this.oldIdMap.put(oldObjectId, oldObject);
            this.newIdMap.put(oldObjectId, newObject);
        }

        private void addToIdMaps(QuestionDO.CloneQuestionWrapper questionWrapper) {
            this.oldIdMap.put(
                questionWrapper.originalQuestionId,
                questionWrapper.originalQuestion
            );
            this.newIdMap.put(
                questionWrapper.originalQuestionId,
                questionWrapper.copiedQuestion
            );
        }

        @TestVisible
        private SObject getOldRecord(Id oldId) {
            return this.oldIdMap.get(oldId);
        }

        @TestVisible
        private SObject getNewRecord(Id oldId) {
            return this.newIdMap.get(oldId);
        }

        @TestVisible
        private Set<Id> getAllOldIds() {
            return this.oldIdMap.keySet();
        }
    }

    // Local Template Replication
    public with sharing class ReplicateLocalTemplate extends ReplicateBasicSurvey {

        public ReplicateLocalTemplate(Survey__c templateToClone, Survey__c newSurvey) {
            super(templateToClone, newSurvey);
        }

        public ReplicateLocalTemplate(
                Survey__c surveyToClone,
                Survey__c newSurvey,
                UnitOfWork unitOfWork
        ) {
            super(surveyToClone, newSurvey, unitOfWork);
        }

        public override void copySurveyOverride() {
            GenericObjectCreator.fetchObjectsCreator(
                Survey__c.getSObjectType()
            ).populateFields(
                this.newSurvey,
                new Map<Schema.SObjectField, Object>{
                    Survey__c.RemoteId__c => this.surveyToClone.RemoteId__c,
                    Survey__c.SurveyLibrary__c => this.surveyToClone.SurveyLibrary__c,
                    Survey__c.ParentTemplate__c => this.surveyToCloneId,
                    Survey__c.IsTemplate__c => this.newSurveyIsTemplate
                }
            );
        }

        public override void copyQuestionOverride(
                QuestionDO.CloneQuestionWrapper questionWrapper,
                Question__c parent,
                Integer level
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                Question__c.getSObjectType()
            ).populateFields(
                questionWrapper.copiedQuestion,
                new Map<Schema.SObjectField, Object>{
                    Question__c.RemoteId__c => questionWrapper.originalQuestion.RemoteId__c,
                    Question__c.RemoteServerId__c =>
                        questionWrapper.originalQuestion.RemoteServerId__c,
                    Question__c.SurveyLibrary__c =>
                        questionWrapper.originalQuestion.SurveyLibrary__c
                }
            );
            copyQuestion(questionWrapper, parent, level);
        }

        private override void copyOptionOverride(
                Option__c newOption,
                Option__c optionToCopy,
                Id oldOptionId
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                Option__c.getSObjectType()
            ).populateFields(
                newOption,
                new Map<Schema.SObjectField, Object>{
                    Option__c.RemoteId__c => optionToCopy.RemoteId__c
                }
            );
        }

        private override void copyScoreValueOverride(
                ScoreValue__c newScoreValue,
                ScoreValue__c scoreValueToCopy,
                Id scoreValueToCopyId
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                ScoreValue__c.getSObjectType()
            ).populateFields(
                newScoreValue,
                new Map<Schema.SObjectField, Object>{
                    ScoreValue__c.RemoteId__c => scoreValueToCopy.RemoteId__c,
                    ScoreValue__c.SurveyLibrary__c => scoreValueToCopy.SurveyLibrary__c
                }
            );
        }

        private override void copySkipConditionOverride(
                SkipCondition__c newSkipCondition,
                SkipCondition__c skipConditionToCopy,
                Id skipConditionToCopyId
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                SkipCondition__c.getSObjectType()
            ).populateFields(
                newSkipCondition,
                new Map<Schema.SObjectField, Object>{
                    SkipCondition__c.RemoteId__c => skipConditionToCopy.RemoteId__c,
                    SkipCondition__c.SurveyLibrary__c => skipConditionToCopy.SurveyLibrary__c
                }
            );
        }
    }

    // Local PPI Replication
    public with sharing class ReplicateLocalPpiTemplate extends ReplicateBasicSurvey {

        public List<PPITable__c> ppiTables;

        public ReplicateLocalPpiTemplate(Survey__c ppiTemplateToClone, Survey__c newSurvey) {
            super(ppiTemplateToClone, newSurvey);
        }

        public ReplicateLocalPpiTemplate(
                Survey__c surveyToClone,
                Survey__c newSurvey,
                UnitOfWork unitOfWork
        ) {
            super(surveyToClone, newSurvey, unitOfWork);
        }

        public override void copySurveyOverride() {
            GenericObjectCreator.fetchObjectsCreator(
                Survey__c.getSObjectType()
            ).populateFields(
                this.newSurvey,
                new Map<Schema.SObjectField, Object>{
                    Survey__c.RemoteId__c => this.surveyToClone.RemoteId__c,
                    Survey__c.SurveyLibrary__c => this.surveyToClone.SurveyLibrary__c,
                    Survey__c.ParentTemplate__c => this.surveyToCloneId,
                    Survey__c.IsTemplate__c => this.newSurveyIsTemplate,
                    Survey__c.IsPPI__c => true
                }
            );
        }

        public override void copyQuestionOverride(
                QuestionDO.CloneQuestionWrapper questionWrapper,
                Question__c parent,
                Integer level
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                Question__c.getSObjectType()
            ).populateFields(
                questionWrapper.copiedQuestion,
                new Map<Schema.SObjectField, Object>{
                    Question__c.RemoteId__c => questionWrapper.originalQuestion.RemoteId__c,
                    Question__c.RemoteServerId__c =>
                        questionWrapper.originalQuestion.RemoteServerId__c,
                    Question__c.SurveyLibrary__c =>
                        questionWrapper.originalQuestion.SurveyLibrary__c
                }
            );
            copyQuestion(questionWrapper, parent, level);
        }

        private override void copyOptionOverride(
                Option__c newOption,
                Option__c optionToCopy,
                Id oldOptionId
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                Option__c.getSObjectType()
            ).populateFields(
                newOption,
                new Map<Schema.SObjectField, Object>{
                    Option__c.RemoteId__c => optionToCopy.RemoteId__c
                }
            );
        }

        private override void copyScoreValueOverride(
                ScoreValue__c newScoreValue,
                ScoreValue__c scoreValueToCopy,
                Id scoreValueToCopyId
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                ScoreValue__c.getSObjectType()
            ).populateFields(
                newScoreValue,
                new Map<Schema.SObjectField, Object>{
                    ScoreValue__c.RemoteId__c => scoreValueToCopy.RemoteId__c,
                    ScoreValue__c.SurveyLibrary__c => scoreValueToCopy.SurveyLibrary__c
                }
            );
        }

        private override void copySkipConditionOverride(
                SkipCondition__c newSkipCondition,
                SkipCondition__c skipConditionToCopy,
                Id skipConditionToCopyId
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                SkipCondition__c.getSObjectType()
            ).populateFields(
                newSkipCondition,
                new Map<Schema.SObjectField, Object>{
                    SkipCondition__c.RemoteId__c => skipConditionToCopy.RemoteId__c,
                    SkipCondition__c.SurveyLibrary__c => skipConditionToCopy.SurveyLibrary__c
                }
            );
        }

        private override void copyPpiTables() {
            // As this is local the assumption is that all the tables exist
            this.ppiTables = new PpiTableSelector().getPpiTablesForSurveys(
                new List<Id>{surveyToCloneId}
            );
            if (!this.ppiTables.isEmpty()) {
                PpiTableDataSetDomain ppiTableDataSetDomain = new PpiTableDataSetDomain();
                this.unitOfWork = ppiTableDataSetDomain.addRecordsForPpiTables(
                    this.ppiTables,
                    this.unitOfWork,
                    this.newSurvey,
                    this.surveyVersion
                );
            }
        }
    }

    /**
     * Class to replicate a Downloaded Survey. Downloaded surveys
     */
    public virtual with sharing class ReplicateRemoteSurvey extends ReplicateBasicSurvey {
        private SurveyData surveyData;

        @TestVisible
        public SurveyLibrary__c remoteSurveyLibrary;

        /**
         * 0 argument constructor for implicit construction. Not used throughout code.
         * Only for the compliler
         */
        public ReplicateRemoteSurvey(){}
        public ReplicateRemoteSurvey(SurveyData surveyData, SurveyLibrary__c surveyLibrary) {
            super(surveyData.survey);
            this.surveyData = surveyData;
            this.remoteSurveyLibrary = surveyLibrary;
            populateFromSurveyData(this.surveyData);
        }

        /**
         * Left empty as the constructor deals with the set up of data on it's own
         */
        public override void setUpDataToCopy() {}

        public override void copySurveyOverride() {
            // TODO - This item is not currently used. We will need to use it
            // when we open up the copying of forms from other orgs than Grameen's
            //this.newSurvey.RemoteOrganisation__c =
            //this.newSurvey.RemoteCreatorName__c = this.surveyToClone.CreatedBy.Name;
            GenericObjectCreator.fetchObjectsCreator(
                Survey__c.getSObjectType()
            ).populateFields(
                this.newSurvey,
                new Map<Schema.SObjectField, Object>{
                    Survey__c.RemoteId__c => this.surveyToCloneId,
                    Survey__c.SurveyLibrary__c => this.remoteSurveyLibrary.Id
                }
            );
        }

        public override void copyQuestionOverride(
                QuestionDO.CloneQuestionWrapper questionWrapper,
                Question__c parent,
                Integer level
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                Question__c.getSObjectType()
            ).populateFields(
                questionWrapper.copiedQuestion,
                new Map<Schema.SObjectField, Object>{
                    Question__c.RemoteId__c => questionWrapper.originalQuestionId,
                    Question__c.RemoteServerId__c => questionWrapper.originalQuestionId,
                    Question__c.SurveyLibrary__c => this.remoteSurveyLibrary.Id
                }
            );
            copyQuestion(questionWrapper, parent, level);
        }

        private override void copyOptionOverride(
                Option__c newOption,
                Option__c optionToCopy,
                Id oldOptionId
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                Option__c.getSObjectType()
            ).populateFields(
                newOption,
                new Map<Schema.SObjectField, Object>{
                    Option__c.RemoteId__c => oldOptionId
                }
            );
        }

        private override void copyScoringGroupOverride(
                ScoringGroup__c newScoringGroup,
                ScoringGroup__c scoringGroupToCopy,
                Id scoringGroupToCopyId
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                ScoringGroup__c.getSObjectType()
            ).populateFields(
                newScoringGroup,
                new Map<Schema.SObjectField, Object>{
                    ScoringGroup__c.RemoteId__c => scoringGroupToCopyId,
                    ScoringGroup__c.SurveyLibrary__c => this.remoteSurveyLibrary.Id
                }
            );
        }

        private override void copyScoreValueOverride(
                ScoreValue__c newScoreValue,
                ScoreValue__c scoreValueToCopy,
                Id scoreValueToCopyId
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                ScoreValue__c.getSObjectType()
            ).populateFields(
                newScoreValue,
                new Map<Schema.SObjectField, Object>{
                    ScoreValue__c.RemoteId__c => scoreValueToCopyId,
                    ScoreValue__c.SurveyLibrary__c => this.remoteSurveyLibrary.Id
                }
            );
        }

        private override void copySkipConditionOverride(
                SkipCondition__c newSkipCondition,
                SkipCondition__c skipConditionToCopy,
                Id skipConditionToCopyId
        ) {
            GenericObjectCreator.fetchObjectsCreator(
                SkipCondition__c.getSObjectType()
            ).populateFields(
                newSkipCondition,
                new Map<Schema.SObjectField, Object>{
                    SkipCondition__c.RemoteId__c => skipConditionToCopyId,
                    SkipCondition__c.SurveyLibrary__c => this.remoteSurveyLibrary.Id
                }
            );
        }

        /**
         * Remote surveys cannot distribute object mapping so this is overriden to do nothing
         */
        private override void copyObjectMapping() {
            copyObjectMappingRemote();
        }
        private virtual void copyObjectMappingRemote() {}
    }

    // Downloaded Template Replication
    public with sharing class ReplicateRemoteTemplate extends ReplicateRemoteSurvey {

        /**
         * 0 argument constructor for implicit construction. Not used throughout code.
         * Only for the compliler
         */
        public ReplicateRemoteTemplate(){}

        /**
         * Remote surveys cannot distribute object mapping so this is overriden to do nothing
         */
        private override void copyObjectMappingRemote() {}
    }

    // Downloaded PPI Replication
    public with sharing class ReplicateRemotePpiTemplate extends ReplicateRemoteSurvey {

        @TestVisible
        private PpiTableDomain ppiTableDomain;

        @TestVisible
        private PpiTableLineDomain ppiTableLineDomain;
        private Map<String, PPITable__c> newRemoteTables;
        private Map<String, PPITable__c> existingTables;
        private Set<Id> remoteTableIdsToBeCloned;

        /**
         * 0 argument constructor for implicit construction. Not used throughout code.
         * Only for the compliler
         */
        public ReplicateRemotePpiTemplate(){}
        public ReplicateRemotePpiTemplate (
                SurveyData surveyData, 
                SurveyLibrary__c surveyLibrary
        ) {
            super(surveyData, surveyLibrary);
        }

        public override void populateFromSurveyDataExtra(SurveyData surveyData) {
            this.ppiTableDomain = new PpiTableDomain(surveyData.tables);
            this.ppiTableLineDomain = new PpiTableLineDomain(surveyData.allLines);
        }

        /**
         * Remote surveys cannot distribute object mapping so this is overriden to do nothing
         */
        private override void copyObjectMappingRemote() {}

        private override void copyPpiTables() {
            List<PPITable__c> localTables = addAllPpiTablesRequired();
            copyPpiTableLines();
            PpiTableDataSetDomain ppiTableDataSetDomain = new PpiTableDataSetDomain();
            this.unitOfWork = ppiTableDataSetDomain.addRecordsForPpiTables(
                localTables,
                this.unitOfWork,
                this.newSurvey,
                this.surveyVersion
            );
        }

        /**
         * Add all tables in the domain that do not alreay exist on this org. Will return the
         * list of all tables that are now on the org
         */
        private List<PPITable__c> addAllPpiTablesRequired() {

            this.newRemoteTables = this.ppiTableDomain.getMapWithNameAsKey();
            this.existingTables = new PpiTableSelector().getNameMapFromNames(
                this.newRemoteTables.keySet()
            );

            // Remove all found ones from the new ones map
            for (String tableName : this.existingTables.keySet()) {
                this.newRemoteTables.remove(tableName);
            }
            List<PPITable__c> tablesOnThisOrg = clonePpiTables(this.newRemoteTables.values());
            tablesOnThisOrg.addAll(this.existingTables.values());
            return tablesOnThisOrg;
        }

        /**
         * Clone the PPITable__c from the remote orgs
         */
        private List<PPITable__c> clonePpiTables(List<PPITable__c> tablesToClone) {
            this.remoteTableIdsToBeCloned = new Set<Id>();
            List<PPITable__c> newTables = new List<PPITable__c>();
            this.unitOfWork.addToInsertionOrder(PPITable__c.getSObjectType(), 1);

            for (PPITable__c tableToClone : tablesToClone) {
                this.remoteTableIdsToBeCloned.add(tableToClone.Id);
                Id oldTableId = tableToClone.Id;
                tableToClone.Id = null;
                PPITable__c newTable = tableToClone.clone(false, true, false, false);
                GenericObjectCreator.fetchObjectsCreator(
                    PPITable__c.getSObjectType()
                ).populateFields(
                    newTable,
                    new Map<Schema.SObjectField, Object>{
                        PPITable__c.RemoteId__c => oldTableId,
                        PPITable__c.SurveyLibrary__c => this.remoteSurveyLibrary.Id
                    }
                );
                this.unitOfWork.addToInsertList(newTable, 1);
                this.addToIdMaps(tableToClone, newTable, oldTableId);
                newTables.add(newTable);
            }
            return newTables;
        }

        private void copyPpiTableLines() {
            this.unitOfWork.addToInsertionOrder(PPITableLine__c.getSObjectType(), 1);

            for (
                    PPITableLine__c tableLine :
                        (List<PPITableLine__c>) this.ppiTableLineDomain.records
            ) {
                if (this.remoteTableIdsToBeCloned.contains(tableLine.PPITable__c)) {
                    clonePpiTableLine(tableLine);
                }
            }
        }

        private void clonePpiTableLine(PPITableLine__c tableLine) {
            Id oldPpiTableLineId = tableLine.Id;
            tableLine.Id = null;
            PPITableLine__c newTableLine = tableLine.clone(false, true, false, false);
            newTableLine.RemoteId__c = oldPpiTableLineId;
            newTableLine.SurveyLibrary__c = this.remoteSurveyLibrary.Id;
            this.unitOfWork.addToInsertList(
                newTableLine,
                PPITableLine__c.PPITable__c,
                this.getNewRecord(tableLine.PPITable__c),
                1
            );
        }
    }

    /**
     * Class that deals with replicating Object Mapping
     */
    public class ObjectMappingReplicator {

        private SurveyMappingDomain surveyMappingDomain;
        private QuestionMappingDomain questionMappingDomain;
        private ObjectRelationshipMappingDomain objectRelationshipMappingDomain;

        private Id surveyToCloneId;
        private Survey__c surveyToClone;
        private Survey__c newSurvey;
        private UnitOfWork unitOfWork;

        private Map<Id, sObject> oldIdMap;
        private Map<Id, sObject> newIdMap;

        private Set<String> badObjects;
        private Set<Id> surveysToClose;

        private List<String> errors;

        public ObjectMappingReplicator(
                Id surveyToCloneId,
                Survey__c surveyToClone,
                Survey__c newSurvey,
                UnitOfWork unitOfWork,
                Map<Id, sObject> newIdMap,
                Map<Id, sObject> oldIdMap
        ) {
            this.surveyToCloneId = surveyToCloneId;
            this.surveyToClone = surveyToClone;
            this.newSurvey = newSurvey;
            this.unitOfWork = unitOfWork;
            this.newIdMap = newIdMap;
            this.oldIdMap = oldIdMap;

            this.surveyMappingDomain = new SurveyMappingDomain(
                new SurveyMappingSelector().getAllForSurveyIds(
                    new Set<String>{this.surveyToCloneId}
                )
            );
            this.questionMappingDomain = new QuestionMappingDomain(
                new QuestionMappingSelector().getAllForSurvey(this.surveyToCloneId)
            );
            this.objectRelationshipMappingDomain = new ObjectRelationshipMappingDomain(
                new ObjectRelationshipMappingSelector().getAllForSurvey(this.surveyToCloneId)
            );

            this.badObjects = new Set<String>();
            this.surveysToClose = new Set<Id>();
            this.errors = new List<String>();
        }

        public UnitOfWork getUnitOfWork() {
            return this.unitOfWork;
        }

        public List<String> getErrors() {
            return this.errors;
        }

        public Set<Id> getSurveysToClose() {
            return this.surveysToClose;
        }

        public void replicateMappings() {
            this.copySurveyMappings();
            this.copyQuestionMappings();
            this.copyObjectRelationMappings();
        }

        private void addBadObjectMappingError(String objectName) {
            this.errors.add(String.format(
                System.label.FRS_BAD_OBJECT_ERROR,
                new List<String>{objectName}
            ));
        }

        private void addBadFieldMappingError(String objectName, String fieldName) {
            this.errors.add(String.format(
                System.label.FRS_BAD_FIELD_ERROR,
                new List<String>{fieldName, objectName}
            ));
        }

        private void copySurveyMappings() {
            this.unitOfWork.addToInsertionOrder(SurveyMapping__c.getSObjectType(), 1);
            for (
                    SurveyMapping__c surveyMapping :
                        (List<SurveyMapping__c>) this.surveyMappingDomain.records
            ) {
                if (validateSurveyMapping(surveyMapping)) {
                    Id oldSurveyMappingId = surveyMapping.Id;
                    surveyMapping.Id = null;
                    SurveyMapping__c newSurveyMapping =
                        surveyMapping.clone(false, true, false, false);
                    this.unitOfWork.addToInsertList(
                        newSurveyMapping,
                        SurveyMapping__c.Survey__c,
                        this.newSurvey,
                        1
                    );
                    this.unitOfWork.createRelationship(
                        newSurveyMapping,
                        SurveyMapping__c.Repeat__c,
                        this.getNewRecord(surveyMapping.Repeat__c),
                        1
                    );
                    this.addToIdMaps(surveyMapping, newSurveyMapping, oldSurveyMappingId);
                }
            }
        }

        private Boolean validateSurveyMapping(SurveyMapping__c surveyMapping) {
            Boolean isSuccessful = true;
            if (!DescribeHandler.objectExists(surveyMapping.ObjectApiName__c)) {
                addBadObject(surveyMapping.ObjectApiName__c);
                this.surveysToClose.add(surveyMapping.Survey__c);
                isSuccessful = false;
            }
            return isSuccessful;
        }

        private void addBadObject(String objectName) {
            if (this.badObjects.add(objectName)) {
                addBadObjectMappingError(objectName);
            }
        }

        private void copyQuestionMappings() {
            this.unitOfWork.addToInsertionOrder(QuestionMapping__c.getSObjectType(), 1);
            for (
                    QuestionMapping__c questionMapping :
                        (List<QuestionMapping__c>) this.questionMappingDomain.records
            ) {
                if (
                        validateQuestionMapping(
                            (SurveyMapping__c)
                                this.getNewRecord(questionMapping.SurveyMapping__c),
                            questionMapping.FieldApiName__c
                        )
                ) {
                    Id oldQuestionMappingId = questionMapping.Id;
                questionMapping.Id = null;
                    QuestionMapping__c newQuestionMapping =
                        questionMapping.clone(false, true, false, false);
                    this.unitOfWork.addToInsertList(
                        newQuestionMapping,
                        QuestionMapping__c.SurveyMapping__c,
                        this.getNewRecord(questionMapping.SurveyMapping__c),
                        1
                    );
                    this.unitOfWork.createRelationship(
                        newQuestionMapping,
                        QuestionMapping__c.Question__c,
                        this.getNewRecord(questionMapping.Question__c),
                        1
                    );
                    this.addToIdMaps(questionMapping, newQuestionMapping, oldQuestionMappingId);
                }
            }
        }

        private Boolean validateQuestionMapping(SurveyMapping__c surveyMapping, String fieldName) {
            Boolean isSuccessful = true;
            if (surveyMapping == null) {
                return false;
            }
            String objectName = surveyMapping.ObjectApiName__c;
            if (
                    this.badObjects.contains(objectName) ||
                    !DescribeHandler.fieldExists(objectName, fieldName)
            ) {
                this.addBadFieldMappingError(objectName, fieldName);
                this.surveysToClose.add(surveyMapping.Survey__c);
                isSuccessful = false;
            }
            return isSuccessful;
        }

        private void copyObjectRelationMappings() {
            this.unitOfWork.addToInsertionOrder(ObjectRelationshipMapping__c.getSObjectType(), 1);
            for (
                    ObjectRelationshipMapping__c objectRelationMapping :
                        (List<ObjectRelationshipMapping__c>)
                            this.objectRelationshipMappingDomain.records
            ) {
                SurveyMapping__c parent =
                    (SurveyMapping__c)
                        this.getNewRecord(objectRelationMapping.ParentSurveyMapping__c);
                SurveyMapping__c child =
                    (SurveyMapping__c)
                        this.getNewRecord(objectRelationMapping.ChildSurveyMapping__c);
                if (
                        parent != null && child != null &&
                        validateQuestionMapping(child, objectRelationMapping.FieldApiName__c)
                ) {
                    Id oldObjectRelationshipMappingId = objectRelationMapping.Id;
                    objectRelationMapping.Id = null;
                    ObjectRelationshipMapping__c newObjectRelationMapping =
                        objectRelationMapping.clone(false, true, false, false);
                    this.unitOfWork.addToInsertList(
                        newObjectRelationMapping,
                        ObjectRelationshipMapping__c.ParentSurveyMapping__c,
                        parent,
                        1
                    );
                    this.unitOfWork.createRelationship(
                        newObjectRelationMapping,
                        ObjectRelationshipMapping__c.ChildSurveyMapping__c,
                        child,
                        1
                    );
                    this.addToIdMaps(
                        objectRelationMapping,
                        newObjectRelationMapping,
                        oldObjectRelationshipMappingId
                    );
                }
            }
        }

        private SObject getNewRecord(Id oldId) {
            return this.newIdMap.get(oldId);
        }

        private void addToIdMaps(SObject oldObject, SObject newObject, Id oldObjectId) {
            this.oldIdMap.put(oldObjectId, oldObject);
            this.newIdMap.put(oldObjectId, newObject);
        }
    }

    /**
     * Exception class for this service
     */
    public class FormReplicationServiceException extends BaseException {
        public FormReplicationServiceException(String message, String[] args) {
            super(message, args);
        }
    }
}