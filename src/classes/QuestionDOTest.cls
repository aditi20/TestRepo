/*
 * Test class for the Question__c domain class
 * Deals with the creation of test Question__c objcts. Has methods for creating various types of
 * questions. Does not deal with inserting to the DB but does in some cases deal with adding
 * records to a UnitOfWork
 * Also has general tests for QuestionDO.cls
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author - Aditi Satpute
 */
@isTest
public class QuestionDOTest {

    public static Question__c createSection() {
        return createSection(1);
    }

    public static Question__c createSection(Integer position) {
        return createQuestion(
            QuestionDO.TYPE_SECTION,
            'Regular_Section_' + position,
            'Regular_Section_' + position,
            position
        );
    }

    public static Question__c createSection(Integer position, String questionName) {
        return createQuestion(
            QuestionDO.TYPE_SECTION,
            questionName,
            questionName + ' caption',
            position
        );
    }

    public static Question__c createRepeatSection() {
        return createRepeatSection(1);
    }

    public static Question__c createRepeatSection(Integer position) {
        return createQuestion(
            QuestionDO.TYPE_REPEAT,
            'Repeated_Section_' + position,
            'Repeated_Section_' + position,
            position
        );
    }

    public static Question__c createRepeatSection(Integer position, Integer repeatTimes) {
        return createQuestion(
            new Map<Schema.SObjectField, Object> {
                Question__c.Type__c => QuestionDO.TYPE_REPEAT,
                Question__c.Name => 'Repeated_Section_' + position,
                Question__c.Caption__c => 'Repeated_Section_' + position,
                Question__c.Position__c => position,
                Question__c.RepeatTimes__c => repeatTimes
            }
        );
    }

    public static Question__c createQuestion(
            String type,
            String name,
            String caption,
            Integer position
    ) {
        return createQuestion(
            new Map<Schema.SObjectField, Object> {
                Question__c.Type__c => type,
                Question__c.Name => name,
                Question__c.Caption__c => caption,
                Question__c.Position__c => position
            }
        );
    }

    public static Question__c createQuestion(Map<Schema.SObjectField, Object> fieldMap) {
        GenericObjectCreator creator = new GenericObjectCreator(Question__c.getSObjectType());
        Question__c question = (Question__c) creator.createNewRecord();
        creator.populateFields(
            question,
            fieldMap
        );
        return question;
    }

    public static Question__c createCascadingSelectQuestion(Integer position) {
        return createQuestion(
            QuestionDO.TYPE_CASCADING_SELECT,
            'Cascading_Select_' + position,
            'Cascading_Select_' + position,
            position
        );
    }

    public static UnitOfWork addCascadingSelectToUnitOfWork(
            CascadingSelect__c cascadingSelect,
            Question__c cascadingSelectQuestion,
            Question__c section,
            Survey__c survey,
            UnitOfWork unitOfWork
    ) {
        Integer level = unitOfWork.addToInsertionOrder(Question__c.getSObjectType());
        unitOfWork.addToInsertList(
            cascadingSelectQuestion, Question__c.Survey__c, survey, level
        );
        unitOfWork.createRelationship(
            cascadingSelectQuestion, Question__c.Parent__c, section, level
        );
        unitOfWork.createRelationship(
            cascadingSelectQuestion, Question__c.CascadingSelect__c, cascadingSelect, level
        );
        return unitOfWork;
    }

    public static List<Question__c> createCascadingLevelQuestions(
            List<CascadingLevel__c> cascadingLevels
    ) {
        List<Question__c> questions = new List<Question__c>();
        for (CascadingLevel__c cascadingLevel : cascadingLevels) {
            questions.add(
                createCascadingLevelQuestion((Integer) cascadingLevel.Position__c));
        }
        return questions;
    }

    public static Question__c createCascadingLevelQuestion(Integer position) {
        return createQuestion(
            QuestionDO.TYPE_CASCADING_LEVEL,
            'Cascading_Level_' + position,
            'Cascading_Level_' + position,
            position
        );
    }

    public static UnitOfWork addCascadingLevelToUnitOfWork(
            List<Question__c> cascadingLevelQuestions,
            Question__c cascadingSelectQuestion,
            Survey__c survey,
            UnitOfWork unitOfWork
    ) {

        Question__c controllingQuestion = null;
        Integer level = unitOfWork.addToInsertionOrder(Question__c.getSObjectType());
        for (Question__c cascadingLevelQuestion : cascadingLevelQuestions) {
            unitOfWork.addToInsertList(
                cascadingLevelQuestion,
                Question__c.ControllingQuestion__c,
                controllingQuestion,
                level
            );
            unitOfWork.createRelationship(
                cascadingLevelQuestion,
                Question__c.Survey__c,
                survey,
                level
            );
            unitOfWork.createRelationship(
                cascadingLevelQuestion,
                Question__c.Parent__c,
                cascadingSelectQuestion,
                level
            );
            controllingQuestion = cascadingLevelQuestion;
            level = unitOfWork.addToInsertionOrder(Question__c.getSObjectType());
        }
        return unitOfWork;
    }

    /**
     * Add a list of questions to the UnitOfWork. Assumes that they all have the same parent
     */
    public static UnitOfWork addQuestionsToUnitOfWork(
            List<Question__c> questionsToAdd,
            Question__c parent,
            Survey__c survey,
            UnitOfWork unitOfWork,
            Integer level
    ) {
        level = unitOfWork.addToInsertionOrder(Question__c.getSObjectType(), level);
        for (Question__c questionToAdd : questionsToAdd) {
            unitOfWork.addToInsertList(
                questionToAdd, Question__c.Survey__c, survey, level
            );
            unitOfWork.createRelationship(
                questionToAdd, Question__c.Parent__c, parent, level
            );
        }
        return unitOfWork;
    }

    public static UnitOfWork addQuestionToUnitOfWork(
            Question__c question,
            Question__c parent,
            Survey__c survey,
            UnitOfWork unitOfWork,
            Integer level
    ) {
        unitOfWork.addToInsertionOrder(Question__c.getSObjectType(), level);
        unitOfWork.addToInsertList(
            question, Question__c.Survey__c, survey, level
        );
        unitOfWork.createRelationship(
            question, Question__c.Parent__c, parent, level
        );
        return unitOfWork;
    }

    public static Question__c quickInsertedNonSectionQuestion(String questionType) {
        UnitOfWork unitOfWork = new UnitOfWork(
            new List<Schema.SObjectType> {
                Survey__c.getSObjectType(),
                Question__c.getSObjectType(),
                Question__c.getSObjectType()
            }
        );
        Survey__c surveyTest = SurveyDOTest.createTestSurveyRecord();
        unitOfWork.addToInsertList(surveyTest);
        Question__c regularSection = createSection();
        unitOfWork.addToInsertList(regularSection, Question__c.Survey__c, surveyTest);
        Question__c question =
            createQuestion(questionType, 'Question', 'Question', 1);
        unitOfWork.addToInsertList(question, Question__c.Survey__c, surveyTest, 2);
        unitOfWork.createRelationship(question, Question__c.Parent__c, regularSection, 2);
        unitOfWork.commitWork();
        return question;
    }

    /**
     * Check if the type of the question is section to validate the repeated sections
     */
    static testMethod void checkIsSection() {

        UnitOfWork unitOfWork = new UnitOfWork(
            new List<Schema.SObjectType> {
                Survey__c.getSObjectType(),
                Question__c.getSObjectType(),
                Question__c.getSObjectType()
            }
        );
        Survey__c surveyTest = SurveyDOTest.createTestSurveyRecord();
        unitOfWork.addToInsertList(surveyTest);
        Question__c regularSection = createSection();
        unitOfWork.addToInsertList(regularSection, Question__c.Survey__c, surveyTest);
        Question__c repeatedSection =
            createQuestion(QuestionDO.TYPE_REPEAT,'Repeated_Section', 'Repeated_Section', 2);
        unitOfWork.addToInsertList(repeatedSection, Question__c.Survey__c, surveyTest);
        Question__c question =
            createQuestion(QuestionDO.TYPE_TEXT_SHORT,'Question', 'Question', 1);
        unitOfWork.addToInsertList(question, Question__c.Survey__c, surveyTest, 2);
        unitOfWork.createRelationship(question, Question__c.Parent__c, regularSection, 2);
        unitOfWork.commitWork();

        Test.startTest();

        System.assert(
            QuestionDO.isSection(regularSection.Type__c),
            'Should not fail since is a section'
        );
        System.assert(
            QuestionDO.isSection(repeatedSection.Type__c),
            'Should not fail since is a section'
        );
        System.assert(
            !QuestionDO.isSection(question.Type__c),
            'Should not fail since is not a section'
        );
        Test.stopTest();
    }

    /**
     * Test class for populateTemplateQuestions method.
     */
    static testMethod void verifyPopulateTemplateQuestions() {
        Survey__c survey = SurveyDOTest.createPpiTemplate();
        survey.Version__c = 2;
        survey.RemoteId__c = null;
        insert survey;
        TestSurveyData testSurvey = TestSurveyData.createSamplePPITemplateQuestions(survey);
        QuestionDO questionDomain = new QuestionDO();

        Test.startTest();
        questionDomain.populateTemplateQuestions(testSurvey.testSurvey.Id);
        Test.stopTest();
        TemplateManagerTest.assertQuestionPPIResults(testSurvey.testSurvey, questionDomain);
    }

    public class SelectQuestion {
        public String questionType;
        public Question__c question;
        public Question__c parentQuestion;
        public Survey__c survey;
        public List<Option__c> options;

        public SelectQuestion(String questionType, Question__c parentQuestion, Survey__c survey) {
            this.questionType = questionType;
            this.parentQuestion = parentQuestion;
            this.survey = survey;
            this.options = new List<Option__c>();
        }

        public Question__c generateQuestion(Integer position) {
            return generateQuestion(position, '');
        }

        public Question__c generateQuestion(Integer position, String suffix) {
            this.question = QuestionDOTest.createQuestion(
                this.questionType,
                this.questionType + '_' + position + '_' + suffix,
                this.questionType + '_' + position + '_' + suffix + 'caption',
                position
            );
            return this.question;
        }

        public List<Option__c> createOptions(Integer numberOfOptions) {
            this.options = OptionDomainTest.createOptions(numberOfOptions);
            return this.options;
        }

        public List<Option__c> createOptions(List<String> values) {
            this.options = OptionDomainTest.createOptions(values);
            return this.options;
        }

        public UnitOfWork addQuestionToUnitOfWork(UnitOfWork unitOfWork, Integer questionLevel) {
            unitOfWork.addToInsertionOrder(Question__c.getSObjectType(), questionLevel);
            unitOfWork.addToInsertList(
                this.question,
                Question__c.Survey__c,
                this.survey,
                questionLevel
            );
            unitOfWork.createRelationship(
                this.question,
                Question__c.Parent__c,
                this.parentQuestion,
                questionLevel
            );
            return unitOfWork;
        }

        public UnitOfWork addOptionsToUnitOfWork(UnitOfWork unitOfWork, Integer optionLevel) {

            unitOfWork.addToInsertionOrder(Option__c.getSObjectType(), optionLevel);
            for (Option__c option : this.options) {
                unitOfWork.addToInsertList(
                    option,
                    Option__c.Question__c,
                    this.question,
                    optionLevel
                );
            }
            return unitOfWork;
        }
    }
}