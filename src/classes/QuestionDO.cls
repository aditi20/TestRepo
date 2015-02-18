/**
 * Domain class for the Question__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class QuestionDO extends SObjectDomain {
    //---------------
    // QUESTION TYPES
    //---------------
    // Non leaf questions
    public static final String TYPE_SECTION = 'section';
    public static final String TYPE_REPEAT = 'repeat';
    public static final String TYPE_CASCADING_SELECT = 'cascading-select';

    // Leaf questions
    public static final String TYPE_TEXT_SHORT = 'text-short';
    public static final String TYPE_TEXT_LONG = 'text-long';
    public static final String TYPE_NUMBER = 'number';
    public static final String TYPE_NUMBER_INTEGER = 'number-integer';
    public static final String TYPE_NUMBER_DECIMAL = 'number-decimal';
    public static final String TYPE_DATE = 'date-date';
    public static final String TYPE_DATETIME = 'date-datetime';
    public static final String TYPE_BARCODE = 'barcode';
    public static final String TYPE_RADIO = 'radio';
    public static final String TYPE_CHECKBOX = 'checkbox';
    public static final String TYPE_STATIC = 'static-content';
    public static final String TYPE_FINAL = 'end_of_survey';
    public static final String TYPE_MEDIA_IMAGE = 'picture';
    public static final String TYPE_MEDIA_AUDIO = 'capture-audio';
    public static final String TYPE_MEDIA_VIDEO = 'capture-video';
    public static final String TYPE_SIGNATURE = 'signature';
    public static final String TYPE_CASCADING_LEVEL = 'cascading-level';
    public static final String TYPE_GPS = 'gps-location';

    //-----------------------------
    // QUESTION SKIP LOGIC BEHAVIOR
    //-----------------------------
    public static final String SKIPLOGIC_BEHAVIOR_SHOW = 'Show';
    public static final String SKIPLOGIC_BEHAVIOR_HIDE = 'Hide';

    //-----------------------------
    // QUESTION SKIP LOGIC OPERATORS
    //-----------------------------
    public static final String SKIPLOGIC_OPERATOR_ALL = 'All';
    public static final String SKIPLOGIC_OPERATOR_ANY = 'Any';

    //---------------
    // Populates maps
    //---------------
    public static Map<String, String> getSkipConditionBehaviorTranslations() {
        return new Map<String, String>{
            SKIPLOGIC_BEHAVIOR_SHOW => Label.QUESTION_SKIPLOGIC_BEHAVIOR_SHOW,
            SKIPLOGIC_BEHAVIOR_HIDE => Label.QUESTION_SKIPLOGIC_BEHAVIOR_HIDE
        };
    }

    public static Map<String, String> getSkipConditionOperatorsTranslations() {
        return new Map<String, String>{
            SKIPLOGIC_OPERATOR_ALL => Label.ALL,
            SKIPLOGIC_OPERATOR_ANY => Label.ANY
        };
    }

    public static Map<String, String> getTypesTranslations() {
        return new Map<String, String>{
            TYPE_TEXT_SHORT => Label.QUESTION_TYPE_TEXT_SHORT,
            TYPE_TEXT_LONG => Label.QUESTION_TYPE_TEXT_LONG,
            TYPE_NUMBER => Label.QUESTION_TYPE_NUMBER,
            TYPE_NUMBER_INTEGER => Label.QUESTION_TYPE_NUMBER_INTEGER,
            TYPE_NUMBER_DECIMAL => Label.QUESTION_TYPE_NUMBER_DECIMAL,
            TYPE_DATE => Label.QUESTION_TYPE_DATE,
            TYPE_DATETIME => Label.QUESTION_TYPE_DATETIME,
            TYPE_BARCODE => Label.QUESTION_TYPE_BARCODE,
            TYPE_RADIO => Label.QUESTION_TYPE_RADIO,
            TYPE_CHECKBOX => Label.QUESTION_TYPE_CHECKBOX,
            TYPE_STATIC => Label.QUESTION_TYPE_STATIC,
            TYPE_REPEAT => Label.QUESTION_TYPE_REPEAT,
            TYPE_SECTION => Label.QUESTION_TYPE_SECTION,
            TYPE_MEDIA_IMAGE => Label.QUESTION_TYPE_MEDIA,
            TYPE_SIGNATURE => Label.QUESTION_TYPE_SIGNATURE,
            TYPE_CASCADING_SELECT => Label.QUESTION_TYPE_CASCADING_SELECT,
            TYPE_GPS => label.XFORM_ODK_GPSLOCATION
        };
    }

    public QuestionDO() {
        super(Question__c.SObjectType);
    }
    public QuestionDO(List<Question__c> sObjects) {
        super(sObjects);
    }

    /**
     * Method to populate PPI Questions with unique identifier
     */
    public void populateTemplateQuestions(Id surveyId) {
        QuestionSelector selector = new QuestionSelector();
        addRecords(selector.getAllForPpiSurveyId(surveyId));
        String namespace = C.getClassNameSpace(QuestionDO.class.getName());
        namespace = (namespace == null) ? '' : namespace + '__';
        if (records != null && !records.isEmpty()) {
            updateUniqueIdentifier(
                DescribeHandler.getFieldPicklist(sObjectName, namespace + 'PpiResultsField__c'),
                records,
                namespace
            );
        }
    }

    /**
     * Method to apply logic for unique identifier and update same.
     */
    private void updateUniqueIdentifier(
            List<Schema.PicklistEntry> picklistValuesPPIResults,
            List<SObject> records,
            String namespace
    ) {
        Integer recordCount = 0;
        for (SObject questionRecord : records) {
            if (questionRecord.get(namespace + 'Parent__c') != null) {
                Object valueToAdd =
                    (
                        picklistValuesPPIResults != null &&
                        picklistValuesPPIResults.size() > recordCount
                    ) ?
                    (Object) picklistValuesPPIResults[recordCount].getValue() :
                    null;
                genericObjectCreator.populateField(
                    questionRecord,
                    sObjectFieldMap.get(namespace + 'PpiResultsField__c'),
                    valueToAdd
                );
                recordCount++;
            }
        }
        update records;
    }

    /**
     * Check if the question type is section
     *
     * @param   type    the type of the question to check
     * @return          true if it is section or repeated
     */
    public static Boolean isSection(String type) {
        return type == QuestionDO.TYPE_SECTION || type == QuestionDO.TYPE_REPEAT;
    }

    /**
     * Check if the question type is media
     *
     * @param  type the type of the question to check
     * @return      true if it is a media question type
     */
    public static Boolean isMedia(String type) {
        return (
            type == QuestionDO.TYPE_MEDIA_IMAGE || type == QuestionDO.TYPE_MEDIA_AUDIO
            || type == QuestionDO.TYPE_SIGNATURE || type == QuestionDO.TYPE_MEDIA_VIDEO
        );
    }

    /**
     * Check if the question is a leaf
     *
     * @param  question the question to check
     * @return          true if the question is leaf
     */
    public static Boolean isLeaf(Question__c question) {
        return
            question.Type__c != QuestionDO.TYPE_SECTION &&
            question.Type__c != QuestionDO.TYPE_REPEAT &&
            question.Type__c != QuestionDO.TYPE_CASCADING_SELECT;
    }

    /**
     * Split Questions in to sections and questions. Order the questions by the surveyId that is
     * passed in. This will allow for sections to be correctly renumbered if multiple forms are
     * cloned into the same Survey
     */
    public QuestionCollection generateNewSurveyQuestionOrder(List<Id> surveyOrder) {

        QuestionCollection questionCollection = new QuestionCollection(surveyOrder);
        for (Question__c question : (List<Question__c>) this.records) {
            questionCollection.assignQuestionToList(question);
        }
        questionCollection.createOrderMap();
        return questionCollection;
    }

    /**
     * Class to store the order that questions should be added to a new survey in.
     * Keeps track of section order in the new survey
     */
    public class QuestionCollection {

        // The order that the cloned surveys are to be added to the new survey in
        public List<Id> surveyOrder;

        // List of the sections
        public List<CloneQuestionWrapper> sections;

        // List for the repeat sections. This needs to be done separatley as they can be nested
        public List<CloneQuestionWrapper> repeats;

        // List of the cascading select questions
        public List<CloneQuestionWrapper> cascadings;

        // List of the cascading select levels
        public List<CloneQuestionWrapper> cascadingLevels;

        // List of the questions
        public List<CloneQuestionWrapper> questions;
        // Map to store the order of sections found in a survey.
        public Map<Id, List<CloneQuestionWrapper>> sectionOrderMap;

        // The new order numbers for the sections for when the questions are cloned
        // into a new survey
        public Map<Id, Double> orderMap;


        public QuestionCollection(List<Id> surveyOrder) {
            this.surveyOrder = surveyOrder;
            this.sections = new List<CloneQuestionWrapper>();
            this.repeats = new List<CloneQuestionWrapper>();
            this.cascadings = new List<CloneQuestionWrapper>();
            this.questions = new List<CloneQuestionWrapper>();
            this.cascadingLevels = new List<CloneQuestionWrapper>();
            this.sectionOrderMap = new Map<Id, List<CloneQuestionWrapper>>();
            this.orderMap = new Map<Id, Double>();
        }

        public void assignQuestionToList(Question__c question) {

            // If this is a section or repeat question keep track of its order.
            // This will allow the sections to be re-ordered correctly when cloning many surveys into one
            if (isSection(question.Type__c)) {
                CloneQuestionWrapper sectionWrapper;
                if (question.Type__c.equalsIgnoreCase(TYPE_SECTION)) {
                    sectionWrapper = addSection(question);
                } else if (question.Type__c.equalsIgnoreCase(TYPE_REPEAT)) {
                    sectionWrapper = addRepeat(question);
                }
                if (question.Parent__c == null) {
                    addToSectionOrder(sectionWrapper, question.Survey__c);
                }
            } else if(question.Type__c.equalsIgnoreCase(TYPE_CASCADING_SELECT)) {
                addCascading(question);
            } else if (question.Type__c.equalsIgnoreCase(TYPE_CASCADING_LEVEL)) {
                addCascadingLevel(question);
            } else {
                addQuestion(question);
            }
        }

        /**
         * Creates the order for the sections as they will be in the new survey
         */
        public void createOrderMap() {

            if (!this.sections.isEmpty()) {
                Double sectionNumber = 1;
                for (String surveyId : this.surveyOrder) {
                    for (CloneQuestionWrapper section : this.sectionOrderMap.get(surveyId)) {
                        this.orderMap.put(section.originalQuestionId, sectionNumber);
                        sectionNumber++;
                    }
                }
            }
        }

        private CloneQuestionWrapper addSection(Question__c section) {
            CloneQuestionWrapper sectionWrapper = new CloneQuestionWrapper(section);
            this.sections.add(sectionWrapper);
            return sectionWrapper;
        }

        private CloneQuestionWrapper addRepeat(Question__c repeat) {
            CloneQuestionWrapper repeatWrapper = new CloneQuestionWrapper(repeat);
            this.repeats.add(repeatWrapper);
            return repeatWrapper;
        }

        private void addCascading(Question__c cascading) {
            this.cascadings.add(new CloneQuestionWrapper(cascading));
        }

        private void addCascadingLevel(Question__c cascadingLevel) {
            this.cascadingLevels.add(new CloneQuestionWrapper(cascadingLevel));
        }

        private void addQuestion(Question__c question) {
            this.questions.add(new CloneQuestionWrapper(question));
        }

        private void addToSectionOrder(CloneQuestionWrapper question, Id surveyId) {
            List<CloneQuestionWrapper> sectionOrder =
                this.sectionOrderMap.get(question.originalQuestion.Survey__c);
            if (sectionOrder == null) {
                sectionOrder = new List<CloneQuestionWrapper>();
            }
            sectionOrder.add(question);
            this.sectionOrderMap.put(surveyId, sectionOrder);
        }
    }

    /**
     * Wrapper class for cloning questions. This is required because there is a bug where by
     * it is not possible to clone a record that is from another org if the original record
     * has the .Id field set
     */
    public class CloneQuestionWrapper {

        public Question__c originalQuestion;
        public Id originalQuestionId;
        public Question__c copiedQuestion;

        public CloneQuestionWrapper(Question__c questionToClone) {
            this.originalQuestion = questionToClone;
            this.originalQuestionId = originalQuestion.Id;
        }

        public void cloneQuestion() {
            this.originalQuestion.Id = null;
            this.copiedQuestion = this.originalQuestion.clone(false, true, false, false);
        }
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public QuestionDo constructWithRecords(List<SObject> sObjectList) {
            return new QuestionDo(sObjectList);
        }
        public QuestionDo constructEmpty() {
            return new QuestionDo();
        }
    }
}