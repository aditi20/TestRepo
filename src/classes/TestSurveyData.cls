/**
 * Class that deals with the creation of a full survey for testing purposes
 * Can create many different types of survey with multiple component combinations
 * Will create a full ppi template
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */

@IsTest
public class TestSurveyData {

    public Survey__c testSurvey;
    public SurveyVersion__c testSurveyVersion;
    public List<Question__c> topLevelSections;

    public String suffix;

    // Map of questions to the Id for the section question they belong to
    public Map<Id, List<Question__c>> questionMap;

    // Map of options to the question Id that they belong to
    public Map<Id, List<Option__c>> optionMap;

    // Map of Score Groups to Score Values
    public Map<Id, List<ScoreValue__c>> scoreValueMap;
    public List<ScoringGroup__c> scoringGroupList;

    // Skip Conditions
    public Map<Id, List<SkipCondition__c>> skipConditionsMap;

    public List<SurveyMapping__c> surveyMappings;
    public List<QuestionMapping__c> questionMappings;
    public List<ObjectRelationshipMapping__c> objectRelationshipMappings;

    public List<PPITable__c> ppiTables;

    // Map of PPITableLine__c.Id This key to the map is PPITable__c.Id that they belong to
    public Map<Id, List<PPITableLine__c>> ppiTableLines;

    public TestSurveyData() {
        this.suffix = '';
        this.topLevelSections = new List<Question__c>();
        this.questionMap = new Map<Id, List<Question__c>>();
        this.optionMap = new Map<Id, List<Option__c>>();
        this.scoreValueMap = new Map<Id, List<ScoreValue__c>>();
        this.scoringGroupList = new List<ScoringGroup__c>();
        this.skipConditionsMap = new Map<Id, List<SkipCondition__c>>();
        this.surveyMappings = new List<SurveyMapping__c>();
        this.questionMappings = new List<QuestionMapping__c>();
        this.objectRelationshipMappings = new List<ObjectRelationshipMapping__c>();
        this.ppiTables = new List<PPITable__c>();
        this.ppiTableLines = new Map<Id, List<PPITableLine__c>>();
    }

    public String getSuffix() {
        return this.suffix;
    }

    public void setSuffix(String suffix) {
        this.suffix = suffix;
    }

    public void addSurvey(Survey__c survey) {
        this.testSurvey = survey;
    }

    public void addSurveyVersion(SurveyVersion__c surveyVersion) {
        this.testSurveyVersion = surveyVersion;
    }

    public void addAllQuestions(List<Question__c> questionsToAdd) {
        for (Question__c question : questionsToAdd) {
            this.addQuestion(question);
        }
    }

    public void addQuestion(Question__c question) {
        if (question.Parent__c == null) {
            this.topLevelSections.add(question);
        } else {
            addToQuestionMap(question);
        }
    }

    public void addToQuestionMap(Question__c question) {
        if (this.questionMap.get(question.Parent__c) == null) {
            this.questionMap.put(question.Parent__c, new List<Question__c>());
        }
        this.questionMap.get(question.Parent__c).add(question);
    }

    public void addAllSelectQuestions(List<QuestionDOTest.SelectQuestion> selectQuestions) {
        for (QuestionDOTest.SelectQuestion selectQuestion : selectQuestions) {
            addSelectQuestion(selectQuestion);
        }
    }

    public void addSelectQuestion(QuestionDOTest.SelectQuestion selectQuestion) {
        this.addQuestion(selectQuestion.question);
        this.optionMap.put(selectQuestion.question.Id, selectQuestion.options);
    }

    public void addScoringGroup(ScoringGroup__c scoringGroup) {
        this.scoringGroupList.add(scoringGroup);
    }

    public void addScoringGroup(ScoringGroup__c scoringGroup, List<ScoreValue__c> scoreValues) {
        this.scoreValueMap.put(scoringGroup.Id, scoreValues);
        this.addScoringGroup(scoringGroup);
    }

    public void addToSkipConditionMap(SkipCondition__c skipCondition) {
        if (this.skipConditionsMap.get(skipCondition.Parent__c) == null) {
            this.skipConditionsMap.put(skipCondition.Parent__c, new List<SkipCondition__c>());
        }
        this.skipConditionsMap.get(skipCondition.Parent__c).add(skipCondition);
    }

    public void addSurveyMapping(SurveyMapping__c surveyMapping) {
        this.surveyMappings.add(surveyMapping);
    }

    public void addQuestionMapping(QuestionMapping__c questionMapping) {
        this.questionMappings.add(questionMapping);
    }

    public void addObjectRelationshipMapping(
            ObjectRelationshipMapping__c objectRelationshipMapping
    ) {
        this.objectRelationshipMappings.add(objectRelationshipMapping);
    }

    public void addPpiTable(PPITable__c ppiTable) {
        this.ppiTables.add(ppiTable);
    }

    public void addPpiTableLines(List<PPITableLine__c> ppiTableLines) {
        for (PPITableLine__c ppiTableLine : ppiTableLines) {
            addPpiTableLine(ppiTableLine);
        }
    }

    public void addPpiTableLine(PPITableLine__c ppiTableLine) {
        if (this.ppiTableLines.get(ppiTableLine.PpiTable__c) == null) {
            this.ppiTableLines.put(ppiTableLine.PpiTable__c, new List<PPITableLine__c>());
        }
        this.ppiTableLines.get(ppiTableLine.PpiTable__c).add(ppiTableLine);
    }

    public Question__c getSection(Integer sectionIndexNumber) {
        return this.topLevelSections[sectionIndexNumber];
    }

    public List<Question__c> getQuestions(Integer sectionIndexNumber) {
        return this.questionMap.get(getSection(sectionIndexNumber).Id);
    }

    public Question__c getQuestion(Integer sectionIndexNumber, Integer questionIndexNumber) {
        return this.questionMap.get(getSection(sectionIndexNumber).Id)[questionIndexNumber];
    }

    public List<Option__c> getOptions(Integer sectionIndexNumber, Integer questionIndexNumber) {
        return this.optionMap.get(getQuestion(sectionIndexNumber, questionIndexNumber).Id);
    }

    public Option__c getOption(
            Integer sectionIndexNumber,
            Integer questionIndexNumber,
            Integer optionIndexNumber
    ) {
        return this.optionMap.get(
            getQuestion(sectionIndexNumber, questionIndexNumber).Id
        )[optionIndexNumber];
    }

    public List<ScoreValue__c> getScoreValues(Integer scoringGroupIndex) {
        return this.scoreValueMap.get(this.scoringGroupList[scoringGroupIndex].Id);
    }

    public ScoreValue__c getScoreValue(Integer scoringGroupIndex, Integer scoreValueIndex) {
        return this.scoreValueMap.get(
            this.scoringGroupList[scoringGroupIndex].Id
        )[scoreValueIndex];
    }

    /**
     * Creates a test survey
     */
    public static TestSurveyData createStandardTestSurvey(
            Survey__c surveySObject,
            Boolean includeCascading
    ) {
        return createStandardTestSurvey(surveySObject, includeCascading, false);
    }

    /**
     * Creates a test survey. Pass in a null Survey__c to have the method create that as well
     */
    public static TestSurveyData createStandardTestSurvey(
            Survey__c surveySObject,
            Boolean includeCascading,
            Boolean addRemoteIds
    ) {

        UnitOfWork unitOfWork = new UnitOfWork();
        String randomString = String.valueOf(Crypto.getRandomInteger());
        unitOfWork.addToInsertionOrder(Survey__c.getSObjectType());
        Schema.SObjectType questionType = Question__c.getSObjectType();
        if (surveySObject == null) {
            surveySObject = SurveyDOTest.createTestSurveyRecordWithAlias(randomString);
            if (addRemoteIds) {
                surveySObject.RemoteId__c = String.valueOf(Crypto.getRandomInteger());
            }
            insert surveySObject;
        }

        // Fetch the version for the survey
        Map<Id, SurveyVersion__c> lastVersionBySurveyId =
            new SurveyVersionSelector().getLatestSurveyVersion(
                new List<Survey__c> {surveySObject}
            );
        SurveyVersion__c version = lastVersionBySurveyId.get(surveySObject.Id);

        CascadingSelect__c cascadingSelect;
        List<CascadingLevel__c> cascadingLevels;
        if (includeCascading) {

            cascadingSelect =
                CascadingSelectDomainTest.createCascadingSelect(randomString);
            CascadingSelectDomainTest.addCascadingSelectToUnitOfWork(cascadingSelect, unitOfWork);
            cascadingLevels =
                CascadingLevelDomainTest.createCascadingLevels(5);
            CascadingLevelDomainTest.addLevelsToUnitOfWork(
                cascadingLevels,
                cascadingSelect,
                unitOfWork
            );
        }

        // Create a section
        unitOfWork.addToInsertionOrder(questionType, 1);
        Question__c regularSection = QuestionDOTest.createSection();
        if (addRemoteIds) {
            regularSection.RemoteId__c = String.valueOf(Crypto.getRandomInteger());
        }
        unitOfWork.addToInsertList(regularSection, Question__c.Survey__c, surveySObject);

        // Add some questions to the section
        Integer level = unitOfWork.addToInsertionOrder(questionType, 2);
        Question__c shortTextQuestion = QuestionDOTest.createQuestion(
            QuestionDO.TYPE_TEXT_SHORT,
            'Short 1',
            'Short 1',
            1
        );
        if (addRemoteIds) {
            shortTextQuestion.RemoteId__c = String.valueOf(Crypto.getRandomInteger());
        }
        unitOfWork.addToInsertList(shortTextQuestion, Question__c.Survey__c, surveySObject, level);
        unitOfWork.createRelationship(
            shortTextQuestion, Question__c.Parent__c, regularSection, level
        );
        Question__c numberQuestion = QuestionDOTest.createQuestion(
            QuestionDO.TYPE_NUMBER_INTEGER,
            'number 1',
            'number 1',
            2
        );
        if (addRemoteIds) {
            numberQuestion.RemoteId__c = String.valueOf(Crypto.getRandomInteger());
        }
        unitOfWork.addToInsertList(numberQuestion, Question__c.Survey__c, surveySObject, level);
        unitOfWork.createRelationship(
            numberQuestion, Question__c.Parent__c, regularSection, level
        );

        // Add a single select
        QuestionDOTest.SelectQuestion selectQuestion =
            new QuestionDOTest.SelectQuestion(
                QuestionDO.TYPE_CHECKBOX,
                regularSection,
                surveySObject
            );
        selectQuestion.generateQuestion(3);
        selectQuestion.createOptions(5);
        selectQuestion.addQuestionToUnitOfWork(unitOfWork, 2);
        selectQuestion.addOptionsToUnitOfWork(unitOfWork, 1);

        // Add a repeat section
        level = unitOfWork.addToInsertionOrder(questionType);
        Question__c repeatedSection = QuestionDOTest.createRepeatSection(2);
        if (addRemoteIds) {
            repeatedSection.RemoteId__c = String.valueOf(Crypto.getRandomInteger());
        }
        unitOfWork.addToInsertList(repeatedSection, Question__c.Survey__c, surveySObject, level);
        unitOfWork.createRelationship(
            repeatedSection, Question__c.RepeatSourceValue__c, numberQuestion, level
        );

        // Add some questions to it
        level = unitOfWork.addToInsertionOrder(questionType);
        Question__c repeatShortTextQuestion = QuestionDOTest.createQuestion(
            QuestionDO.TYPE_TEXT_SHORT,
            'Short repeat',
            'Short repeat',
            1
        );
        if (addRemoteIds) {
            repeatShortTextQuestion.RemoteId__c = String.valueOf(Crypto.getRandomInteger());
        }
        unitOfWork.addToInsertList(
            repeatShortTextQuestion, Question__c.Survey__c, surveySObject, level
        );
        unitOfWork.createRelationship(
            repeatShortTextQuestion, Question__c.Parent__c, repeatedSection, level
        );
        Question__c repeatNumberQuestion = QuestionDOTest.createQuestion(
            QuestionDO.TYPE_NUMBER_INTEGER,
            'number repeat',
            'number repeat',
            2
        );
        if (addRemoteIds) {
            repeatNumberQuestion.RemoteId__c = String.valueOf(Crypto.getRandomInteger());
        }
        unitOfWork.addToInsertList(repeatNumberQuestion, Question__c.Survey__c, surveySObject, level);
        unitOfWork.createRelationship(
            repeatNumberQuestion, Question__c.Parent__c, repeatedSection, level
        );

        Question__c cascadingSelectQuestion;
        List<Question__c> cascadingLevelQuestions;
        if (includeCascading) {
            cascadingSelectQuestion =
                QuestionDOTest.createCascadingSelectQuestion(4);
            unitOfWork = QuestionDOTest.addCascadingSelectToUnitOfWork(
                cascadingSelect,
                cascadingSelectQuestion,
                regularSection,
                surveySObject,
                unitOfWork
            );
            cascadingLevelQuestions =
                QuestionDOTest.createCascadingLevelQuestions(cascadingLevels);
            unitOfWork = QuestionDOTest.addCascadingLevelToUnitOfWork(
                cascadingLevelQuestions,
                cascadingSelectQuestion,
                surveySObject,
                unitOfWork
            );
        }
        unitOfWork.commitWork();

        // Populate the TestSurveyData object from the UnitOfWork
        TestSurveyData testSurvey = new TestSurveyData();
        testSurvey.addSurvey(
            (Survey__c) new SurveySelector().getRecordsByOnlyIdWithAllFields(
                new Set<Id> {surveySObject.Id}
            )[0]
        );
        testSurvey.addSurveyVersion(version);
        testSurvey.addQuestion(regularSection);
        testSurvey.addQuestion(shortTextQuestion);
        testSurvey.addQuestion(numberQuestion);
        testSurvey.addSelectQuestion(selectQuestion);
        testSurvey.addQuestion(repeatedSection);
        testSurvey.addQuestion(repeatShortTextQuestion);
        testSurvey.addQuestion(repeatNumberQuestion);
        if (includeCascading) {
            testSurvey.addQuestion(cascadingSelectQuestion);
            testSurvey.addAllQuestions(cascadingLevelQuestions);
        }
        testSurvey.setSuffix(randomString);
        return testSurvey;
    }

    /**
     * Assumption here is that the TestSurveyData passed in was created using
     * createStandardTestSurvey(null, true)
     */
    public static TestSurveyData addScoringGroupToStandardSurvey(
            TestSurveyData testSurvey,
            Boolean isPpi
    ) {
        return addScoringGroupToStandardSurvey(testSurvey, isPpi, true);
    }
    public static TestSurveyData addScoringGroupToStandardSurvey(
            TestSurveyData testSurvey,
            Boolean isPpi,
            Boolean addScoringValues
    ) {
        UnitOfWork unitOfWork = new UnitOfWork();
        Question__c selectQuestion =
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[2];
        List<Option__c> options = testSurvey.optionMap.get(selectQuestion.Id);
        ScoringGroup__c scoringGroup = ScoringGroupDomainTest.createScoringGroup(
            (Id) testSurvey.testSurvey.Id,
            isPpi
        );
        unitOfWork =
            ScoringGroupDomainTest.addScoringGroupToUnitOfWork(scoringGroup, unitOfWork);
        List<ScoreValue__c> scoreValues;
        if (addScoringValues) {
            scoreValues = ScoreValueDomainTest.createMultipleScoreValues(5);
            ScoreValueDomainTest.addScoreValuesToUnitOfWork(
                scoringGroup,
                scoreValues,
                options,
                unitOfWork,
                1
            );
        }
        unitOfWork.commitWork();
        if (addScoringValues) {
            testSurvey.addScoringGroup(scoringGroup, scoreValues);
        } else {
            testSurvey.addScoringGroup(scoringGroup);
        }
        return testSurvey;
    }

    /**
     * Assumption here is that the TestSurveyData passed in was created using
     * createStandardTestSurvey(null, true)
     */
    public static TestSurveyData addSkipConditionsToStandardSurvey(TestSurveyData testSurvey) {
        UnitOfWork unitOfWork = new UnitOfWork();
        SkipCondition__c firstSkipCondition = SkipConditionDOTest.createSkipCondition();
        SkipConditionDOTest.addSkipConditionToUnitOfWork(
            firstSkipCondition,
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[1],
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[0],
            unitOfWork,
            1
        );
        unitOfWork.commitWork();
        testSurvey.addToSkipConditionMap(firstSkipCondition);
        return testSurvey;
    }

    /**
     * Assumption here is that the TestSurveyData passed in was created using
     * createStandardTestSurvey(null, true)
     */
    public static TestSurveyData addObjectMappingToStandardSurvey(TestSurveyData testSurvey) {
        UnitOfWork unitOfWork = new UnitOfWork();
        SurveyMapping__c parentMapping = SurveyMappingDomainTest.createSurveyMapping(
            Contact.LastName.getDescribe().getName(),
            Contact.getSObjectType().getDescribe().getName(),
            true
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            parentMapping,
            testSurvey.testSurvey,
            null,
            unitOfWork
        );
        SurveyMapping__c childMapping = SurveyMappingDomainTest.createSurveyMapping(
            Contact.LastName.getDescribe().getName(),
            Contact.getSObjectType().getDescribe().getName(),
            false
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            childMapping,
            testSurvey.testSurvey,
            testSurvey.topLevelSections[1],
            unitOfWork
        );
        QuestionMapping__c parentQuestionMapping =
            QuestionMappingDomainTest.createQuestionMapping(
                Contact.LastName.getDescribe().getName()
            );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            parentQuestionMapping,
            parentMapping,
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[0],
            unitOfWork
        );
        QuestionMapping__c childQuestionMapping =
            QuestionMappingDomainTest.createQuestionMapping(
                Contact.LastName.getDescribe().getName()
            );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            childQuestionMapping,
            childMapping,
            testSurvey.questionMap.get(testSurvey.topLevelSections[1].Id)[0],
            unitOfWork
        );
        ObjectRelationshipMapping__c objectRelationshipMapping =
            ObjectRelationshipMappingDomainTest.createObjectRelationMapping(
                Contact.ReportsToId.getDescribe().getName()
            );
        unitOfWork = ObjectRelationshipMappingDomainTest.addObjectRelationshipToUnitOfWork(
            objectRelationshipMapping,
            childMapping,
            parentMapping,
            unitOfWork
        );
        unitOfWork.commitWork();
        testSurvey.addSurveyMapping(parentMapping);
        testSurvey.addSurveyMapping(childMapping);
        testSurvey.addQuestionMapping(parentQuestionMapping);
        testSurvey.addQuestionMapping(childQuestionMapping);
        testSurvey.addObjectRelationshipMapping(objectRelationshipMapping);
        return testSurvey;
    }

    /**
     * Assumption here is that the TestSurveyData passed in was created using
     * createStandardTestSurvey(null, true)
     */
    public static TestSurveyData addPpiTablesToStandardSurvey(TestSurveyData testSurvey) {

        UnitOfWork unitOfWork = new UnitOfWork();

        PPITable__c ppiTable = PpiTableDomainTest.createPpiTable(
            testSurvey.testSurvey.Name,
            testSurvey.testSurvey
        );
        insert ppiTable;
        PPITableLine__c ppiTableLine = PpiTableLineDomainTest.createPpiTableLine();
        PpiTableLineDomainTest.addPpiTableLineToUnitOfWork(
            ppiTableLine,
            ppiTable,
            unitOfWork
        );
        PPITableDataSet__c ppiTableDataSet = PpiTableDataSetDomainTest.createPpiTableDataSet();
        PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
            ppiTableDataSet,
            ppiTable,
            testSurvey.testSurvey,
            testSurvey.testSurveyVersion,
            unitOfWork
        );
        unitOfWork.commitWork();
        testSurvey.addPpiTable(ppiTable);
        testSurvey.addPpiTableLine(ppiTableLine);
        return testSurvey;
    }

    /**
     * Create a full PPI Template based on old data model
     */
    public static TestSurveyData createPpiTemplateWithoutDemographic() {
        Survey__c ppiSurvey = SurveyDOTest.createInsertedPpiTemplate();
        TestSurveyData testSurvey = createPpiQuestions(ppiSurvey);
        addSurveyDetails(testSurvey, ppiSurvey);
        testSurvey = addPpiTablesToPpiTemplate(testSurvey);
        testSurvey = addPpiScoreValues(testSurvey);
        return testSurvey;
    }

    /**
     * Add survey and survey version to TestSurveyData instance
     */
    private static TestSurveyData addSurveyDetails(TestSurveyData testSurvey, Survey__c ppiSurvey) {
        // Fetch the version for the survey
        Map<Id, SurveyVersion__c> lastVersionBySurveyId =
            new SurveyVersionSelector().getLatestSurveyVersion(
                new List<Survey__c> {ppiSurvey}
            );
        SurveyVersion__c version = lastVersionBySurveyId.get(ppiSurvey.Id);
        testSurvey.addSurvey(
            (Survey__c) new SurveySelector().getRecordsByOnlyIdWithAllFields(
                new Set<Id> {ppiSurvey.Id}
            )[0]
        );
        testSurvey.addSurveyVersion(version);
        return testSurvey;
    }

    /**
     * Create a full PPI Template
     */
    public static TestSurveyData createFullPpiTemplate() {
        Survey__c ppiSurvey = SurveyDOTest.createInsertedPpiTemplate();
        TestSurveyData testSurvey = createSamplePPITemplateQuestions(ppiSurvey);
        new QuestionDO().populateTemplateQuestions(ppiSurvey.Id);
        testSurvey = addPpiTablesToPpiTemplate(testSurvey);
        testSurvey = addPpiScoreValues(testSurvey, 2);
        return testSurvey;
    }

    /**
     * Create questions for a PPI template
     */
    public static TestSurveyData createSamplePPITemplateQuestions(Survey__c surveySObject) {

        // Fetch the version for the survey
        Map<Id, SurveyVersion__c> lastVersionBySurveyId =
            new SurveyVersionSelector().getLatestSurveyVersion(
                new List<Survey__c> {surveySObject}
            );
        SurveyVersion__c version = lastVersionBySurveyId.get(surveySObject.Id);
        TestSurveyData testSurvey = createDemographicQuestions(surveySObject);
        testSurvey = createPpiQuestions(testSurvey, surveySObject, 3);
        testSurvey.addSurveyVersion(version);
        return testSurvey;
    }

    private static TestSurveyData createPpiQuestions(Survey__c surveySObject) {
        return createPpiQuestions(new TestSurveyData(), surveySObject);
    }

    private static TestSurveyData createPpiQuestions(
            TestSurveyData testSurvey,
            Survey__c surveySObject
    ) {
        return createPpiQuestions(testSurvey, surveySObject, 1);
    }

    private static TestSurveyData createPpiQuestions(
            TestSurveyData testSurvey,
            Survey__c surveySObject,
            Integer ppiSectionLevel
    ) {
        UnitOfWork unitOfWork = new UnitOfWork();
        unitOfWork.addToInsertionOrder(Question__c.getSObjectType(), 1);
        Question__c ppiSection = QuestionDOTest.createSection(ppiSectionLevel, 'PPI Section');
        unitOfWork.addToInsertList(ppiSection, Question__c.Survey__c, surveySObject);
        Integer questionLevel = 2;

        // Create ppi questions
        List<QuestionDOTest.SelectQuestion> ppiQuestions =
            new List<QuestionDOTest.SelectQuestion>();
        for (Integer i = 1; i <= 10; i++) {
            QuestionDOTest.SelectQuestion ppiQuestion = new QuestionDOTest.SelectQuestion(
                QuestionDO.TYPE_RADIO,
                ppiSection,
                surveySObject
            );
            ppiQuestion.generateQuestion(i);
            ppiQuestion.createOptions(new List<String> {
                'Option ' + i + '.1',
                'Option ' + i + '.2',
                'Option ' + i + '.3',
                'Option ' + i + '.4'
            });
            unitOfWork = ppiQuestion.addQuestionToUnitOfWork(unitOfWork, questionLevel);
            unitOfWork = ppiQuestion.addOptionsToUnitOfWork(unitOfWork, 1);
            ppiQuestions.add(ppiQuestion);
        }
        unitOfWork.commitWork();

        // Add all survey objects to the test survey
        testSurvey.addSurvey(
            (Survey__c) new SurveySelector().getRecordsByOnlyIdWithAllFields(
                new Set<Id> {surveySObject.Id}
            )[0]
        );
        testSurvey.addAllQuestions(new List<Question__c> {ppiSection});
        testSurvey.addAllSelectQuestions(ppiQuestions);
        return testSurvey;
    }

    private static TestSurveyData createDemographicQuestions(Survey__c surveySObject) {
        TestSurveyData testSurvey = new TestSurveyData();
        UnitOfWork unitOfWork = new UnitOfWork();
        // Create the sections
        unitOfWork.addToInsertionOrder(Question__c.getSObjectType(), 1);
        Question__c clientIdSection = QuestionDOTest.createSection(1, 'Client Id Section');
        Question__c demographicSection =
            QuestionDOTest.createSection(2, 'Demographic Section');

        unitOfWork.addToInsertList(clientIdSection, Question__c.Survey__c, surveySObject);
        unitOfWork.addToInsertList(demographicSection, Question__c.Survey__c, surveySObject);

        // Create the client id questions
        Integer questionLevel = 2;
        Question__c clientIdQuestion = QuestionDOTest.createQuestion(
            QuestionDO.TYPE_TEXT_SHORT,
            'Client_Id',
            'Capture Client Id',
            1
        );
        unitOfWork = QuestionDOTest.addQuestionToUnitOfWork(
            clientIdQuestion,
            clientIdSection,
            surveySObject,
            unitOfWork,
            questionLevel
        );

        // Add the demographic questions
        QuestionDOTest.SelectQuestion genderQuestion = new QuestionDOTest.SelectQuestion(
            QuestionDO.TYPE_RADIO,
            demographicSection,
            surveySObject
        );
        genderQuestion.generateQuestion(1, 'Gender');
        genderQuestion.createOptions(new List<String> {'Male', 'Female'});
        unitOfWork = genderQuestion.addQuestionToUnitOfWork(unitOfWork, questionLevel);
        unitOfWork = genderQuestion.addOptionsToUnitOfWork(unitOfWork, 1);


        Question__c ageQuestion = QuestionDOTest.createQuestion(
            QuestionDO.TYPE_NUMBER,
            'Age',
            'Client\'s Age',
            2
        );
        Question__c householdQuestion = QuestionDOTest.createQuestion(
            QuestionDO.TYPE_NUMBER,
            'Household_Size',
            'How many people live in the house',
            3
        );
        Question__c joinedDateQuestion = QuestionDOTest.createQuestion(
            QuestionDO.TYPE_DATE,
            'Joined_Date',
            'When did the client join the company',
            4
        );
        Question__c geoLocationQuestion = QuestionDOTest.createQuestion(
            QuestionDO.TYPE_GPS,
            'Geolocation',
            'Take a GPS reading',
            5
        );
        unitOfWork = QuestionDOTest.addQuestionsToUnitOfWork(
            new List<Question__c> {
                ageQuestion,
                householdQuestion,
                joinedDateQuestion,
                geoLocationQuestion
            },
            demographicSection,
            surveySObject,
            unitOfWork,
            questionLevel
        );
        unitOfWork.commitWork();
        testSurvey.addAllQuestions(new List<Question__c> {
            clientIdSection,
            demographicSection,
            clientIdQuestion
        });
        testSurvey.addSelectQuestion(genderQuestion);
        testSurvey.addAllQuestions(new List<Question__c> {
            ageQuestion,
            householdQuestion,
            joinedDateQuestion,
            geoLocationQuestion
        });
        return testSurvey;
    }

    /**
     * Add ppi tables to the example ppi template
     */
    private static TestSurveyData addPpiTablesToPpiTemplate(TestSurveyData testSurvey) {
        PpiTableDomainTest.PpiTableWrapper tableWrapper =
            new PpiTableDomainTest.PpiTableWrapper();
        tableWrapper.addTable('');
        tableWrapper.addToSurvey(false, testSurvey.testSurvey, testSurvey.testSurveyVersion);
        tableWrapper.addLines(20);
        tableWrapper.commitWork();
        testSurvey.addPpiTable(tableWrapper.table);
        testSurvey.addPpiTableLines(tableWrapper.tableLines);
        return testSurvey;
    }

    private static TestSurveyData addPpiScoreValues(TestSurveyData testSurvey) {
        return addPpiScoreValues(testSurvey, 0);
    }

    /**
     * Add ppi scoring group test ppi template
     */
    private static TestSurveyData addPpiScoreValues(TestSurveyData testSurvey, Integer sectionCount) {
        UnitOfWork unitOfWork = new UnitOfWork();
        ScoringGroup__c scoringGroup =
            ScoringGroupDomainTest.createPpiScoringGroup(testSurvey.testSurvey.Id);
        unitOfWork = ScoringGroupDomainTest.addScoringGroupToUnitOfWork(scoringGroup, unitOfWork);
        unitOfWork.commitWork();
        unitOfWork.reset();

        testSurvey.addScoringGroup(
            scoringGroup,
            addScoringValuesForSection(sectionCount, testSurvey, unitOfWork, scoringGroup)
        );
        unitOfWork.commitWork();
        return testSurvey;
    }

    private static List<ScoreValue__c> addScoringValuesForSection(
            Integer sectionCount,
            TestSurveyData testSurvey,
            UnitOfWork unitOfWork,
            ScoringGroup__c scoringGroup
    ) {
        List<ScoreValue__c> allScoreValues = new List<ScoreValue__c>();
        for (
                Question__c question :
                testSurvey.getQuestions(sectionCount)
        ) {
            List<Option__c> options = testSurvey.optionMap.get(question.Id);
            List<ScoreValue__c> scoreValues =
                ScoreValueDomainTest.createMultipleScoreValues(options.size());
            unitOfWork = ScoreValueDomainTest.addScoreValuesToUnitOfWork(
                scoringGroup,
                scoreValues,
                options,
                unitOfWork,
                1
            );
            allScoreValues.addAll(scoreValues);
        }
        return allScoreValues;
    }

    /**
     * Ensure that the test survey is created correctly
     */
    static testMethod void testTestSurveyCreation() {
        TestSurveyData testSurvey = createStandardTestSurvey(null, true);
        System.assertEquals(2, testSurvey.topLevelSections.size());
        System.assertEquals(3, testSurvey.questionMap.size());
        System.assertEquals(
            4,
            testSurvey.questionMap.get(
                testSurvey.topLevelSections[0].Id
            ).size()
        );
        System.assertEquals(1, testSurvey.optionMap.size());
        System.assertEquals(
            5,
            testSurvey.optionMap.get(
                testSurvey.questionMap.get(
                    testSurvey.topLevelSections[0].Id
                )[2].Id
            ).size()
        );
    }

    /**
     * Test creating a test survey with scoring groups
     */
    static testMethod void testTestSurveyCreationWithScoringGroups() {
        TestSurveyData testSurvey = addScoringGroupToStandardSurvey(
            createStandardTestSurvey(null, true), false
        );
        System.assertEquals(1, testSurvey.scoreValueMap.size());
        System.assertEquals(5, testSurvey.scoreValueMap.get(
            testSurvey.scoringGroupList[0].Id
        ).size());
    }

    static testMethod void testTestSurveyCreationWithSkipConditions() {
        TestSurveyData testSurvey = addSkipConditionsToStandardSurvey(
            createStandardTestSurvey(null, true)
        );
        System.assertEquals(1, testSurvey.skipConditionsMap.size());
        System.assertEquals(1, testSurvey.skipConditionsMap.get(
            testSurvey.questionMap.get(
                testSurvey.topLevelSections[0].Id
            )[1].Id
        ).size());
    }

    static testMethod void testTestSurveyCreationWithObjectMappings() {
        TestSurveyData testSurvey = addObjectMappingToStandardSurvey(
            createStandardTestSurvey(null, true)
        );
        System.assertEquals(2, testSurvey.surveyMappings.size());
        System.assertEquals(2, testSurvey.questionMappings.size());
        System.assertEquals(1, testSurvey.objectRelationshipMappings.size());
    }

    /**
     * Test creation of a full PPI Template. Tests the methods in this class
     */
    static testMethod void testFullPpiTemplateCreation() {
        TestSurveyData testSurvey = createFullPpiTemplate();
        System.assertEquals(
            3,
            testSurvey.topLevelSections.size(),
            'There Should be three sections in the template'
        );
        System.assertEquals(
            1,
            testSurvey.getQuestions(0).size(),
            'There should be one question in the customer id section'
        );
        System.assertEquals(
            5,
            testSurvey.getQuestions(1).size(),
            'There should be 5 questions in the customer demographic section'
        );
        System.assertEquals(
            10,
            testSurvey.getQuestions(2).size(),
            'There should be 10 questions in the ppi questions section'
        );
        System.assertEquals(
            2,
            testSurvey.getOptions(1, 0).size(),
            'The Gender question should have two options'
        );
        for (Integer i = 0; i < 10; i++) {
            System.assertEquals(
                4,
                testSurvey.getOptions(2, i).size(),
                'Each PPI Question should have four options. Question ' + i + ' does not'
            );
        }

        System.assertEquals(
            1,
            testSurvey.scoringGroupList.size(),
            'The survey should have one scoring group'
        );

        System.assertEquals(
            40,
            testSurvey.getScoreValues(0).size(),
            'There should be 40 score values created'
        );
        System.assertEquals(1, testSurvey.ppiTables.size(), 'There should be 1 PPI Table');
        System.assertEquals(
            20,
            testSurvey.ppiTableLines.get(testSurvey.ppiTables[0].Id).size(),
            'There should be 20 PPI Table Lines'
        );
    }
}