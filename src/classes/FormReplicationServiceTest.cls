/**
 * Test class for FormReplicationService
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class FormReplicationServiceTest {

    /**
     * Test cloning a basic survey locally
     */
    static testMethod void testCloningBasicSurvey() {
        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, true);
        Test.startTest();
        FormReplicationService.ReplicateBasicSurvey replicationService =
            FormReplicationService.cloneSurvey(
                testSurvey.testSurvey.Id
            );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        validateStandardSurvey(newSurveyId, testSurvey.testSurvey.Id);
    }

    /**
     * Test cloning a basic survey locally when the new survey is already created
     */
    static testMethod void testCloningBasicSurveyWithNewSurvey() {

        // Create the test survey and a clone to copy it into
        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, true);
        SurveyDO surveyDomain = new SurveyDO(new List<Survey__c>{testSurvey.testSurvey});
        SurveySelector selector = new SurveySelector();

        // Have to refetch the initial survey as the SurveyDO.cloneSurveys will remove the .Id field
        Survey__c surveyToClone = (Survey__c) selector.getRecordsByOnlyIdWithAllFields(
                    new Set<Id>{testSurvey.testSurvey.Id}
                )[0];
        testSurvey.testSurvey = surveyToClone;

        Survey__c newSurvey = surveyDomain.cloneSurveys()[0];
        insert newSurvey;
        Survey__c newSurvey2 = (Survey__c) selector.getRecordsByOnlyIdWithAllFields(
                    new Set<Id>{newSurvey.Id}
                )[0];
        Test.startTest();
        FormReplicationService.ReplicateBasicSurvey replicationService =
            FormReplicationService.cloneSurvey(
                testSurvey.testSurvey,
                newSurvey2,
                null
            );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        ValidateReplicatedSurvey validateReplicatedSurvey =
            new ValidateReplicatedSurvey(replicationService);
        validateReplicatedSurvey.validateAllComponents();
        validateStandardSurvey(newSurveyId, testSurvey.testSurvey.Id);
    }

    /**
     * Test cloning a basic survey locally when the new survey is already created and with
     * the UnitOfWork already created
     */
    static testMethod void testCloningBasicSurveyWithNewSurveyAndUow() {

        // Create the test survey and a clone to copy it into
        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, true);
        SurveyDO surveyDomain = new SurveyDO(new List<Survey__c>{testSurvey.testSurvey});
        SurveySelector selector = new SurveySelector();

        // Have to refetch the initial survey as the SurveyDO.cloneSurveys will remove the .Id field
        Survey__c surveyToClone = (Survey__c) selector.getRecordsByOnlyIdWithAllFields(
                    new Set<Id>{testSurvey.testSurvey.Id}
                )[0];
        testSurvey.testSurvey = surveyToClone;

        Survey__c newSurvey = surveyDomain.cloneSurveys()[0];
        insert newSurvey;
        Survey__c newSurvey2 = (Survey__c) selector.getRecordsByOnlyIdWithAllFields(
                    new Set<Id>{newSurvey.Id}
                )[0];
        UnitOfWork unitOfWork = new UnitOfWork();
        Test.startTest();
        FormReplicationService.ReplicateBasicSurvey replicationService =
            FormReplicationService.cloneLocalForm(
                testSurvey.testSurvey,
                newSurvey2,
                false,
                unitOfWork,
                true
            );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        ValidateReplicatedSurvey validateReplicatedSurvey =
            new ValidateReplicatedSurvey(replicationService);
        validateReplicatedSurvey.validateAllComponents();
        validateStandardSurvey(newSurveyId, testSurvey.testSurvey.Id);
    }

    /**
     * Test cloning a basic survey locally that contains scoring groups
     */
    static testMethod void testCloningBasicWithScoringGroup() {
        TestSurveyData testSurvey =
            TestSurveyData.addScoringGroupToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true), false
            );
        Test.startTest();
        FormReplicationService.ReplicateBasicSurvey replicationService =
            FormReplicationService.cloneSurvey(
                testSurvey.testSurvey.Id
            );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        validateStandardScoring(newSurveyId);
    }

    /**
     * Test cloning a basic survey locally that contains skip conditions
     */
    static testMethod void testCloningBasicWithSkipConditions() {
        TestSurveyData testSurvey =
            TestSurveyData.addSkipConditionsToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true)
        );
        Test.startTest();
        FormReplicationService.ReplicateBasicSurvey replicationService =
            FormReplicationService.cloneSurvey(
                testSurvey.testSurvey.Id
            );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        validateStandardSkipConditions(newSurveyId);
    }

    /**
     * Test cloning a basic survey locally that contains object mappings
     */
    static testMethod void testCloningBasicWithObjectMapping() {
        TestSurveyData testSurvey =
            TestSurveyData.addObjectMappingToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true)
        );
        Test.startTest();
        FormReplicationService.ReplicateBasicSurvey replicationService =
            FormReplicationService.cloneSurvey(
                testSurvey.testSurvey.Id
            );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        validateStandardSurvey(testSurvey.testSurvey.Id, newSurveyId);
        validateStandardFieldMappings(newSurveyId);
        ValidateReplicatedSurvey validateReplicatedSurvey =
            new ValidateReplicatedSurvey(replicationService);
        validateReplicatedSurvey.validateAllComponents();
    }

    /**
     * Test that a survey that has a bad field mapping is replicated but the original survey
     * is set to be closed
     */
    static testMethod void testClosingSurveyWithBadFieldMapping() {

        TestSurveyData testSurvey =
            TestSurveyData.addObjectMappingToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true)
        );

        // Create a bad field mapping
        UnitOfWork unitOfWork = new UnitOfWork();
        QuestionMapping__c badQuestionMapping = QuestionMappingDomainTest.createQuestionMapping(
            new Map<Schema.SObjectField, Object>{
                QuestionMapping__c.FieldApiName__c => 'fiedApiName'
            }
        );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            badQuestionMapping,
            testSurvey.surveyMappings[1],
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[1],
            unitOfWork
        );
        QuestionMappingTH.skipValidation = true;
        unitOfWork.commitWork();
        QuestionMappingTH.skipValidation = false;

        Test.startTest();
        FormReplicationService.ReplicateBasicSurvey replicationService =
            FormReplicationService.cloneSurvey(
                testSurvey.testSurvey.Id
            );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        Set<Id> surveysToClose = replicationService.getSurveysToClose();
        System.assertEquals(1, surveysToClose.size());
        System.assert(surveysToClose.contains(replicationService.surveyToCloneId));
    }

    /**
     * Test that a survey that has a bad object mapping is replicated but the original survey
     * is set to be closed
     */
    static testMethod void testClosingSurveyWithBadObjectMapping() {

        TestSurveyData testSurvey =
            TestSurveyData.addObjectMappingToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true)
        );

        // Create a bad object mapping
        UnitOfWork unitOfWork = new UnitOfWork();
        SurveyMapping__c badSurveyMapping = SurveyMappingDomainTest.createSurveyMapping(
            '',
            'BAD_NAME'
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            badSurveyMapping,
            testSurvey.testSurvey,
            null,
            unitOfWork
        );
        unitOfWork.commitWork();
        Test.startTest();
        FormReplicationService.ReplicateBasicSurvey replicationService =
            FormReplicationService.cloneSurvey(
                testSurvey.testSurvey.Id
            );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        Set<Id> surveysToClose = replicationService.getSurveysToClose();
        System.assertEquals(1, surveysToClose.size());
        System.assert(surveysToClose.contains(replicationService.surveyToCloneId));
    }

    /**
     * Test downloading a basic survey
     */
    static testMethod void testDownloadingBasicSurvey() {
        TestSurveyData testSurvey =
            TestSurveyData.addScoringGroupToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(null, true), false
            );
        SurveyLibrary__c lib = SurveyLibraryDomainTest.addLibraryToDatabase();
        SurveyData surveyData = new SurveyData(testSurvey.testSurvey.Id);
        Test.startTest();
        FormReplicationService.setRemoteLibrary(lib);
        FormReplicationService.ReplicateBasicSurvey replicationService =
            (FormReplicationService.ReplicateBasicSurvey) FormReplicationService.cloneSurveyData(
                surveyData
            );
        Test.stopTest();
        ValidateDownloadedSurvey validateReplicatedSurvey =
            new ValidateDownloadedSurvey(replicationService);
        validateReplicatedSurvey.validateAllComponents();
    }

    /**
     * Test cloning a template locally
     */
    static testMethod void testCloningLocalTemplate() {
        TestSurveyData testSurvey =
            TestSurveyData.addScoringGroupToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedTemplate(),
                    true,
                    true
                ),
                false
            );
        SurveyDO surveyDomain = new SurveyDO(new List<Survey__c>{testSurvey.testSurvey});
        SurveySelector selector = new SurveySelector();

        // Have to refetch the initial survey as the SurveyDO.cloneSurveys will remove the .Id field
        Survey__c surveyToClone = (Survey__c) selector.getRecordsByOnlyIdWithAllFields(
                    new Set<Id>{testSurvey.testSurvey.Id}
                )[0];
        testSurvey.testSurvey = surveyToClone;
        Survey__c newSurvey = surveyDomain.cloneSurveys()[0];
        insert newSurvey;
        Survey__c newSurvey2 = (Survey__c) selector.getRecordsByOnlyIdWithAllFields(
                    new Set<Id>{newSurvey.Id}
                )[0];
        Test.startTest();
        FormReplicationService.setIsTemplate(true);
        FormReplicationService.ReplicateLocalTemplate replicationService =
            (FormReplicationService.ReplicateLocalTemplate) FormReplicationService.cloneLocalForm(
                testSurvey.testSurvey,
                newSurvey2,
                true,
                true
            );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        ValidateReplicatedTemplate validateReplicatedTemplate =
            new ValidateReplicatedTemplate(replicationService);
        validateReplicatedTemplate.validateAllComponents();
    }

    /**
     * Test using a template locally
     */
    static testMethod void testUsingLocalTemplate() {
        TestSurveyData testSurvey =
            TestSurveyData.addScoringGroupToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedTemplate(),
                    true,
                    true
                ),
                false
            );
        SurveyDO surveyDomain = new SurveyDO(new List<Survey__c>{testSurvey.testSurvey});
        SurveySelector selector = new SurveySelector();

        // Have to refetch the initial survey as the SurveyDO.cloneSurveys will remove the .Id field
        Survey__c surveyToClone = (Survey__c) selector.getRecordsByOnlyIdWithAllFields(
                    new Set<Id>{testSurvey.testSurvey.Id}
                )[0];
        testSurvey.testSurvey = surveyToClone;
        Survey__c newSurvey = surveyDomain.cloneSurveys()[0];
        insert newSurvey;
        Survey__c newSurvey2 = (Survey__c) selector.getRecordsByOnlyIdWithAllFields(
                    new Set<Id>{newSurvey.Id}
                )[0];
        Test.startTest();
        FormReplicationService.ReplicateLocalTemplate replicationService =
            (FormReplicationService.ReplicateLocalTemplate) FormReplicationService.cloneLocalForm(
                testSurvey.testSurvey,
                newSurvey2,
                false,
                false
            );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        ValidateReplicatedTemplate validateReplicatedTemplate =
            new ValidateReplicatedTemplate(replicationService);
        validateReplicatedTemplate.validateAllComponents();
    }


    /**
     * Test cloning a PPI template locally
     */
    static testMethod void testCloningPpiTemplate() {
        ppiTest(true);
    }

    /**
     * Test using a PPI template locally
     */
    static testMethod void testUsingPpiTemplate() {
        ppiTest(false);
    }

    /**
     * Helper method to run the tests for replicating a PPI template locally
     */
    private static void ppiTest(Boolean isTemplateValue) {
        TestSurveyData testSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.createStandardTestSurvey(
                    SurveyDOTest.createInsertedPpiTemplate(), true, true
                )
            );
        SurveyDO surveyDomain = new SurveyDO(new List<Survey__c>{testSurvey.testSurvey});
        SurveySelector selector = new SurveySelector();

        // Have to refetch the initial survey as the SurveyDO.cloneSurveys will remove the .Id field
        Survey__c surveyToClone = (Survey__c) selector.getRecordsByOnlyIdWithAllFields(
                    new Set<Id>{testSurvey.testSurvey.Id}
                )[0];
        testSurvey.testSurvey = surveyToClone;
        Survey__c newSurvey = surveyDomain.cloneSurveys()[0];
        insert newSurvey;
        Survey__c newSurvey2 = (Survey__c) selector.getRecordsByOnlyIdWithAllFields(
                    new Set<Id>{newSurvey.Id}
                )[0];
        Test.startTest();
        FormReplicationService.setIsTemplate(isTemplateValue);
        FormReplicationService.ReplicateLocalPpiTemplate replicationService =
            (FormReplicationService.ReplicateLocalPpiTemplate)
                FormReplicationService.clonePpiTemplate(
                    testSurvey.testSurvey,
                    newSurvey2,
                    null
                );
        Id newSurveyId = replicationService.getNewSurvey().Id;
        Test.stopTest();
        ValidateReplicatedPpiTemplate validateReplicatedPpiTemplate =
            new ValidateReplicatedPpiTemplate(replicationService);
        validateReplicatedPpiTemplate.validateAllComponents();
    }

    /**
     * Test downloading a PPI Template when all the PPI tables do not exist on the local org yet
     */
    static testMethod void testDownloadingPpiNewTables() {
        TestSurveyData testSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.addScoringGroupToStandardSurvey(
                    TestSurveyData.createStandardTestSurvey(
                        SurveyDOTest.createInsertedPpiTemplate(), true
                    ), true
                )
            );
        SurveyLibrary__c lib = SurveyLibraryDomainTest.addLibraryToDatabase();
        SurveyData surveyData = new SurveyData(testSurvey.testSurvey.Id);

        // Delete all the PPI Tables from the System
        delete [SELECT Id FROM PPITable__c];
        delete [SELECT Id FROM PPITableLine__c];
        delete [SELECT Id FROM PPITableDataSet__c];

        Test.startTest();
        FormReplicationService.setRemoteLibrary(lib);
        FormReplicationService.setIsTemplate(true);
        FormReplicationService.ReplicateRemotePpiTemplate replicationService =
            (FormReplicationService.ReplicateRemotePpiTemplate)
                FormReplicationService.clonePpiSurveyData(surveyData);
        Test.stopTest();
        ValidateDownloadedPpiTemplate validateDownloadedPpiTemplate =
            new ValidateDownloadedPpiTemplate(replicationService);
        validateDownloadedPpiTemplate.validateAllComponents();
    }

    /**
     * Test downloading a PPI template when the PPI tables are already on the org
     */
    static testMethod void testDownloadingPpiExistingTables() {
        TestSurveyData testSurvey =
            TestSurveyData.addPpiTablesToStandardSurvey(
                TestSurveyData.addScoringGroupToStandardSurvey(
                    TestSurveyData.createStandardTestSurvey(
                        SurveyDOTest.createInsertedPpiTemplate(), true
                    ), true
                )
            );
        SurveyLibrary__c lib = SurveyLibraryDomainTest.addLibraryToDatabase();
        SurveyData surveyData = new SurveyData(testSurvey.testSurvey.Id);

        Test.startTest();
        FormReplicationService.setRemoteLibrary(lib);
        FormReplicationService.setIsTemplate(true);
        FormReplicationService.ReplicateRemotePpiTemplate replicationService =
            (FormReplicationService.ReplicateRemotePpiTemplate)
                FormReplicationService.clonePpiSurveyData(surveyData);
        Test.stopTest();
        ValidateDownloadedPpiTemplate validateDownloadedPpiTemplate =
            new ValidateDownloadedPpiTemplate(replicationService);
        validateDownloadedPpiTemplate.validateAllComponents();
    }

    /**
     * Validate a standard survey has downloaded correctly.
     */
    private static void validateStandardSurvey(Id newSurveyId, Id clonedSurveyId) {
        System.assert(newSurveyId != clonedSurveyId);
        QuestionSelector questionSelector = new QuestionSelector();
        QuestionDO questionDomain = new QuestionDO(
            (List<Question__c>) questionSelector.getAllForSurveyIds(
                new Set<String>{newSurveyId}
            )
        );
        System.assertEquals(13, questionDomain.records.size());
        OptionSelector optionSelector = new OptionSelector();
        OptionDomain optionDomain =
            new OptionDomain(optionSelector.getAllForSurvey(newSurveyId));
        System.assertEquals(5, optionDomain.records.size());
    }

    private static void validateStandardScoring(Id newSurveyId) {
        ScoringGroupSelector scoringGroupSelector = new ScoringGroupSelector();
        System.assertEquals(
            1,
            scoringGroupSelector.getAllForSurvey(newSurveyId).size()
        );
        ScoreValueSelector scoreValueSelector = new ScoreValueSelector();
        System.assertEquals(
            5,
            scoreValueSelector.getAllForSurvey(newSurveyId).size()
        );
    }

    private static void validateStandardSkipConditions(Id newSurveyId) {
        SkipConditionSelector skipConditionSelector = new SkipConditionSelector();
        System.assertEquals(
            1,
            skipConditionSelector.getAllForSurvey(newSurveyId).size()
        );
    }

    private static void validateStandardFieldMappings(Id newSurveyId) {

        SurveyMappingSelector surveyMappingSelector = new SurveyMappingSelector();
        System.assertEquals(
            2,
            surveyMappingSelector.getAllForSurveyIds(
                new Set<String>{newSurveyId}
            ).size()
        );

        QuestionMappingSelector questionMappingSelector = new QuestionMappingSelector();
        System.assertEquals(
            2,
            questionMappingSelector.getAllForSurvey(newSurveyId).size()
        );

        ObjectRelationshipMappingSelector objectRelationshipMappingSelector =
            new ObjectRelationshipMappingSelector();
        System.assertEquals(
            1,
            objectRelationshipMappingSelector.getAllForSurvey(newSurveyId).size()
        );
    }

    /**
     * Class to deal with validating that a replicated survey has been copied correctly
     */
    public virtual class ValidateReplicatedSurvey {

        private FormReplicationService.ReplicateBasicSurvey replicatedSurvey;

        public ValidateReplicatedSurvey(){}

        public ValidateReplicatedSurvey(
                FormReplicationService.ReplicateBasicSurvey replicatedSurvey
        ) {
            this.replicatedSurvey = replicatedSurvey;
        }

        public void validateAllComponents() {

            validateSurvey(
                replicatedSurvey.surveyToClone,
                replicatedSurvey.newSurvey
            );
            for (Id key : replicatedSurvey.getAllOldIds()) {
                SObject oldObject = replicatedSurvey.getOldRecord(key);
                Schema.SObjectType oldObjectType = oldObject.getSObjectType();
                SObject newObject = replicatedSurvey.getNewRecord(key);
                Schema.SObjectType newObjectType = newObject.getSObjectType();
                System.assertEquals(oldObjectType, newObjectType);

                if (oldObjectType == Question__c.getSObjectType()) {
                    validateQuestion(
                        (Question__c) oldObject,
                        (Question__c) newObject,
                        key);
                } else if (oldObjectType == Option__c.getSObjectType()) {
                    validateOption((Option__c) oldObject, (Option__c) newObject, key);
                } else if (oldObjectType == ScoringGroup__c.getSObjectType()) {
                    validateScoringGroup(
                        (ScoringGroup__c) oldObject,
                        (ScoringGroup__c) newObject,
                        key
                    );
                } else if (oldObjectType == ScoreValue__c.getSObjectType()) {
                    validateScoreValue(
                        (ScoreValue__c) oldObject,
                        (ScoreValue__c) newObject,
                        key
                    );
                } else if (oldObjectType == SkipCondition__c.getSObjectType()) {
                    validateSkipCondition(
                        (SkipCondition__c) oldObject,
                        (SkipCondition__c) newObject,
                        key
                    );
                } else if (oldObjectType == SurveyMapping__c.getSObjectType()) {
                    validateSurveyMapping(
                        (SurveyMapping__c) oldObject,
                        (SurveyMapping__c) newObject
                    );
                } else if (oldObjectType == QuestionMapping__c.getSObjectType()) {
                    validateQuestionMapping(
                        (QuestionMapping__c) oldObject,
                        (QuestionMapping__c) newObject
                    );
                } else if (oldObjectType == ObjectRelationshipMapping__c.getSObjectType()) {
                    validateObjectRelationshipMapping(
                        (ObjectRelationshipMapping__c) oldObject,
                        (ObjectRelationshipMapping__c) newObject
                    );
                } else if (oldObjectType == PPITable__c.getSObjectType()) {
                    validatePpiTable(
                        (PPITable__c) oldObject,
                        (PPITable__c) newObject
                    );
                } else if (oldObjectType == PPITableLine__c.getSObjectType()) {
                    validatePpiTableLine(
                        (PPITableLine__c) oldObject,
                        (PPITableLine__c) newObject
                    );
                }
            }
            validatePpiData();
        }

        private void validateSurvey(Survey__c oldSurvey, Survey__c newSurvey) {
            System.assertEquals(oldSurvey.Close_Message__c, newSurvey.Close_Message__c);
            System.assertEquals(oldSurvey.CountryCode__c, newSurvey.CountryCode__c);
            System.assertEquals(oldSurvey.Description__c, newSurvey.Description__c);
            System.assertEquals(oldSurvey.Deployment__c, newSurvey.Deployment__c);
            System.assertEquals(oldSurvey.IsPPI__c, newSurvey.IsPPI__c);
            System.assertEquals(replicatedSurvey.newSurveyIsTemplate, newSurvey.IsTemplate__c);
            System.assertEquals(oldSurvey.PPIDataYear__c, newSurvey.PPIDataYear__c);
            System.assertEquals(oldSurvey.LanguageCode__c, newSurvey.LanguageCode__c);
            System.assertEquals(oldSurvey.Version__c, newSurvey.Version__c);
        }

        private virtual void validateExtraSurveyFields(
                Survey__c oldSurvey,
                Survey__c newSurvey
        ) {
            System.assertEquals(oldSurvey.Alias__c, newSurvey.Alias__c);
        }

        private void validateQuestion(
                Question__c oldQuestion,
                Question__c newQuestion,
                Id oldQuestionId
        ) {

            System.assertEquals(replicatedSurvey.getNewSurvey().Id, newQuestion.Survey__c);
            System.assertEquals(oldQuestion.Name, newQuestion.Name);
            System.assertEquals(oldQuestion.Caption__c, newQuestion.Caption__c);
            System.assertEquals(oldQuestion.CurrentTime__c, newQuestion.CurrentTime__c);
            System.assertEquals(oldQuestion.DoAfter__c, newQuestion.DoAfter__c);
            System.assertEquals(oldQuestion.DoBefore__c, newQuestion.DoBefore__c);
            System.assertEquals(oldQuestion.FromVersion__c, newQuestion.FromVersion__c);
            System.assertEquals(oldQuestion.Hint__c, newQuestion.Hint__c);
            System.assertEquals(oldQuestion.IsDraft__c, newQuestion.IsDraft__c);
            System.assertEquals(oldQuestion.IsRemoteEditable__c, newQuestion.IsRemoteEditable__c);
            System.assertEquals(oldQuestion.Maximum__c, newQuestion.Maximum__c);
            System.assertEquals(oldQuestion.Minimum__c, newQuestion.Minimum__c);
            System.assertEquals(oldQuestion.Position__c, newQuestion.Position__c);
            System.assertEquals(oldQuestion.Required__c, newQuestion.Required__c);
            System.assertEquals(oldQuestion.SamePage__c, newQuestion.SamePage__c);
            System.assertEquals(oldQuestion.ToVersion__c, newQuestion.ToVersion__c);
            System.assertEquals(oldQuestion.Type__c, newQuestion.Type__c);
            System.assert(
                oldQuestion.Id != newQuestion.Id,
                'Old and new Questions should not have the same id'
            );

            System.assertEquals(0, newQuestion.MaxInstance__c);
            validateExtraQuestionFields(oldQuestion, newQuestion, oldQuestionId);
            validateSpecificQuestionTypes(oldQuestion, newQuestion);
        }

        private virtual void validateExtraQuestionFields(
                Question__c oldQuestion,
                Question__c newQuestion,
                Id oldQuestionId
        ) {}

        private void validateSpecificQuestionTypes(
                Question__c oldQuestion,
                Question__c newQuestion
        ) {
            if (oldQuestion.Type__c.equals(QuestionDO.TYPE_REPEAT)) {
                validateRepeatedQuestion(oldQuestion, newQuestion);
            } else if (oldQuestion.Type__c.equals(QuestionDO.TYPE_CASCADING_SELECT)) {
                validateCascadingSelect(oldQuestion, newQuestion);
            } else if (oldQuestion.Type__c.equals(QuestionDO.TYPE_CASCADING_LEVEL)) {
                validateCascadingLevel(oldQuestion, newQuestion);
            }
        }

        private void validateRepeatedQuestion(Question__c oldQuestion, Question__c newQuestion) {
            if (oldQuestion.RepeatSourceValue__c == null) {
                System.assert(
                    newQuestion.RepeatSourceValue__c == null,
                    'RepeatSourceValue__c should be null on new and old question'
                );
            } else {
                Question__c newSourceValue =
                    (Question__c) replicatedSurvey.getNewRecord(
                        oldQuestion.RepeatSourceValue__c
                    );
                System.assertEquals(newSourceValue.Id, newQuestion.RepeatSourceValue__c);
            }
        }

        private void validateCascadingSelect(Question__c oldQuestion, Question__c newQuestion) {
            System.assertEquals(
                oldQuestion.CascadingSelect__c,
                newQuestion.CascadingSelect__c
            );
        }

        private void validateCascadingLevel(Question__c oldQuestion, Question__c newQuestion) {
            System.assertEquals(
                oldQuestion.CascadingLevel__c,
                newQuestion.CascadingLevel__c
            );
            if (oldQuestion.CascadingLevel__c == null) {
                    System.assert(newQuestion.CascadingLevel__c == null);
            } else {
                Question__c oldControllingQuestion =
                    (Question__c) replicatedSurvey.getOldRecord(oldQuestion.ControllingQuestion__c);
                Question__c newControllingQuestion =
                    (Question__c) replicatedSurvey.getOldRecord(newQuestion.ControllingQuestion__c);
                System.assertEquals(
                    oldControllingQuestion.CascadingLevel__c,
                    newControllingQuestion.CascadingLevel__c
                );
            }
        }

        private void validateOption(
                Option__c oldOption,
                Option__c newOption,
                Id oldOptionId
        ) {
            System.assertEquals(oldOption.Position__c, newOption.Position__c);
            System.assertEquals(oldOption.Caption__c, newOption.Caption__c);
            Question__c newControllingQuestion =
                    (Question__c) replicatedSurvey.getNewRecord(oldOption.Question__c);
            System.assertEquals(newControllingQuestion.Id, newOption.Question__c);
            validateExtraOptionFields(oldOption, newOption, oldOptionId);
            System.assert(
                oldOption.Id != newOption.Id,
                'Old and new Options should not have the same id'
            );
        }

        private virtual void validateExtraOptionFields(
                Option__c oldOption,
                Option__c newOption,
                Id oldOptionId
        ) {}

        private void validateScoringGroup(
                ScoringGroup__c oldScoringGroup,
                ScoringGroup__c newScoringGroup,
                Id oldScoringGroupId
        ) {
            System.assertEquals(oldScoringGroup.Caption__c, newScoringGroup.Caption__c);
            System.assertEquals(replicatedSurvey.getNewSurvey().Id, newScoringGroup.Survey__c);
            validateExtraScoringGroupFields(oldScoringGroup, newScoringGroup, oldScoringGroupId);
            System.assert(
                oldScoringGroup.Id != newScoringGroup.Id,
                'Old and new Score Groups should not have the same id'
            );
        }

        private virtual void validateExtraScoringGroupFields(
                ScoringGroup__c oldScoringGroup,
                ScoringGroup__c newScoringGroup,
                Id oldScoringGroupId
        ) {}

        private void validateScoreValue(
                ScoreValue__c oldScoreValue,
                ScoreValue__c newScoreValue,
                Id oldScoreValueId
        ) {
            System.assertEquals(oldScoreValue.Value__c, newScoreValue.Value__c);
            ScoringGroup__c newScoringGroup =
                (ScoringGroup__c) replicatedSurvey.getNewRecord(oldScoreValue.ScoringGroup__c);
            System.assertEquals(newScoringGroup.Id, newScoreValue.ScoringGroup__c);
            Option__c newOption =
                (Option__c) replicatedSurvey.getNewRecord(oldScoreValue.Option__c);
            System.assertEquals(newOption.Id, newScoreValue.Option__c);


            System.assert(
                oldScoreValue.Id != newScoreValue.Id,
                'Old and new Score Values should not have the same id'
            );
            validateExtraScoreValueFields(oldScoreValue, newScoreValue, oldScoreValueId);
        }

        private virtual void validateExtraScoreValueFields(
                ScoreValue__c oldScoreValue,
                ScoreValue__c newScoreValue,
                Id oldScoreValueId
        ) {}

        private void validateSkipCondition(
                SkipCondition__c oldSkipCondition,
                SkipCondition__c newSkipCondition,
                Id oldSkipConditionId
        ) {

            Question__c sourceQuestion =
                (Question__c) replicatedSurvey.getNewRecord(oldSkipCondition.SourceQuestion__c);
            System.assertEquals(sourceQuestion.Id, newSkipCondition.SourceQuestion__c);
            String sourceQuestionType = sourceQuestion.Type__c;
            if (
                    (
                        sourceQuestionType.equals(QuestionDO.TYPE_RADIO) ||
                        sourceQuestionType.equals(QuestionDO.TYPE_CHECKBOX)
                    ) &&
                    !String.isEmpty(newSkipCondition.Value__c)
            ) {
                System.assertEquals(
                    ((Question__c) replicatedSurvey.getNewRecord(
                        oldSkipCondition.SourceQuestion__c
                    )).Id,
                    newSkipCondition.Value__c
                );
            } else {
                System.assertEquals(oldSkipCondition.Value__c, newSkipCondition.Value__c);
            }

            Question__c parent =
                (Question__c) replicatedSurvey.getNewRecord(oldSkipCondition.Parent__c);
            System.assertEquals(parent.Id, newSkipCondition.Parent__c);

            System.assert(
                oldSkipCondition.Id != newSkipCondition.Id,
                'Old and new Skip Conditions should not have the same id'
            );
            validateExtraSkipConditionFields(oldSkipCondition, newSkipCondition, oldSkipConditionId);
        }

        private virtual void validateExtraSkipConditionFields(
                SkipCondition__c oldSkipCondition,
                SkipCondition__c newSkipCondition,
                Id oldSkipConditionId
        ) {}

        private void validateSurveyMapping(
                SurveyMapping__c oldSurveyMapping,
                SurveyMapping__c newSurveyMapping
        ) {

            Question__c repeatQuestion =
                (Question__c) replicatedSurvey.getNewRecord(oldSurveyMapping.Repeat__c);
            if (repeatQuestion != null) {
                System.assertEquals(repeatQuestion.Id, newSurveyMapping.Repeat__c);
            }
            System.assertEquals(
                oldSurveyMapping.IsReference__c,
                newSurveyMapping.IsReference__c
            );
            System.assertEquals(
                oldSurveyMapping.MatchingField__c,
                newSurveyMapping.MatchingField__c
            );
            System.assertEquals(
                oldSurveyMapping.ObjectApiName__c,
                newSurveyMapping.ObjectApiName__c
            );
            System.assertEquals(
                oldSurveyMapping.PPIScoreApiField__c,
                newSurveyMapping.PPIScoreApiField__c
            );
            System.assertEquals(
                oldSurveyMapping.SubmissionApiField__c,
                newSurveyMapping.SubmissionApiField__c
            );
            System.assertEquals(
                oldSurveyMapping.SurveyorApiField__c,
                newSurveyMapping.SurveyorApiField__c
            );
            System.assertEquals(
                oldSurveyMapping.SurveyApiField__c,
                newSurveyMapping.SurveyApiField__c
            );
            System.assertEquals(
                oldSurveyMapping.SurveyVersionApiField__c,
                newSurveyMapping.SurveyVersionApiField__c
            );
            System.assert(
                oldSurveyMapping.Id != newSurveyMapping.Id,
                'Old and new Survey Mapping should not have the same id'
            );
            validateExtraSurveyMappingFields(oldSurveyMapping, newSurveyMapping);
        }

        private virtual void validateExtraSurveyMappingFields(
                SurveyMapping__c oldSurveyMapping,
                SurveyMapping__c newSurveyMapping
        ) {}

        private void validateQuestionMapping(
                QuestionMapping__c oldQuestionMapping,
                QuestionMapping__c newQuestionMapping
        ) {
            System.assertEquals(
                oldQuestionMapping.FieldApiName__c,
                newQuestionMapping.FieldApiName__c
            );
            SurveyMapping__c newSurveyMapping =
                (SurveyMapping__c) replicatedSurvey.getNewRecord(
                    oldQuestionMapping.SurveyMapping__c
                );
            System.assertEquals(newSurveyMapping.Id, newQuestionMapping.SurveyMapping__c);
            Question__c newQuestion =
                (Question__c) replicatedSurvey.getNewRecord(
                    oldQuestionMapping.Question__c
                );
            System.assertEquals(newQuestion.Id, newQuestionMapping.Question__c);

            System.assert(
                oldQuestionMapping.Id != newQuestionMapping.Id,
                'Old and new Question Mapping should not have the same id'
            );
            validateExtraQuestionMappingFields(oldQuestionMapping, newQuestionMapping);
        }

        private virtual void validateExtraQuestionMappingFields(
                QuestionMapping__c oldQuestionMapping,
                QuestionMapping__c newQuestionMapping
        ) {}

        private void validateObjectRelationshipMapping(
                ObjectRelationshipMapping__c oldObjectRelationshipMapping,
                ObjectRelationshipMapping__c newObjectRelationshipMapping
        ) {
            System.assertEquals(
                oldObjectRelationshipMapping.FieldApiName__c,
                newObjectRelationshipMapping.FieldApiName__c
            );
            SurveyMapping__c parentMapping =
                (SurveyMapping__c) replicatedSurvey.getNewRecord(
                    oldObjectRelationshipMapping.ParentSurveyMapping__c
                );
            System.assertEquals(
                parentMapping.Id,
                newObjectRelationshipMapping.ParentSurveyMapping__c
            );
            SurveyMapping__c childMapping =
                (SurveyMapping__c) replicatedSurvey.getNewRecord(
                    oldObjectRelationshipMapping.ChildSurveyMapping__c
                );
            System.assertEquals(
                childMapping.Id,
                newObjectRelationshipMapping.ChildSurveyMapping__c
            );

            System.assert(
                oldObjectRelationshipMapping.Id != newObjectRelationshipMapping.Id,
                'Old and new Object Relationship Mapping should not have the same id'
            );
            validateExtraObjectRelationshipMappingFields(
                oldObjectRelationshipMapping,
                newObjectRelationshipMapping
            );
        }

        private virtual void validateExtraObjectRelationshipMappingFields(
                ObjectRelationshipMapping__c oldObjectRelationshipMapping,
                ObjectRelationshipMapping__c newObjectRelationshipMapping
        ) {}

        private virtual void validatePpiTable(
                PPITable__c oldPpiTable,
                PPITable__c newPpiTable
        ) {}

        private virtual void validatePpiTableLine(
                PPITableLine__c oldPpiTableLine,
                PPITableLine__c newPpiTableLine
        ) {}

        private virtual void validatePpiData() {}
    }

    /**
     * Class for validating that a template has been correctly cloned
     */
    private class ValidateReplicatedTemplate extends ValidateReplicatedSurvey {

        public ValidateReplicatedTemplate(
                FormReplicationService.ReplicateBasicSurvey replicatedSurvey
        ) {
            super(replicatedSurvey);
        }

        private FormReplicationService.ReplicateLocalTemplate castReplicatedSurvey() {
            return (FormReplicationService.ReplicateLocalTemplate) this.replicatedSurvey;
        }

        private override void validateExtraSurveyFields(
                Survey__c oldSurvey,
                Survey__c newSurvey
        ) {
            System.assertEquals(
                this.replicatedSurvey.newSurveyIsTemplate,
                newSurvey.IsTemplate__c
            );
            System.assertEquals(oldSurvey.RemoteId__c, newSurvey.RemoteId__c);
            System.assertEquals(oldSurvey.SurveyLibrary__c, newSurvey.SurveyLibrary__c);
            System.assertEquals(oldSurvey.Id, newSurvey.ParentTemplate__c);
        }

        private override void validateExtraQuestionFields (
                Question__c oldQuestion,
                Question__c newQuestion,
                Id oldQuestionId
        ) {
            System.assertEquals(oldQuestion.RemoteServerId__c, newQuestion.RemoteServerId__c);
            System.assertEquals(oldQuestion.RemoteId__c, newQuestion.RemoteId__c);
            System.assertEquals(oldQuestion.SurveyLibrary__c, newQuestion.SurveyLibrary__c);
        }

        private override void validateExtraOptionFields(
                Option__c oldOption,
                Option__c newOption,
                Id oldOptionId
        ) {
            System.assertEquals(oldOption.RemoteId__c, newOption.RemoteId__c);
        }

        private override void validateExtraScoringGroupFields(
                ScoringGroup__c oldScoringGroup,
                ScoringGroup__c newScoringGroup,
                Id oldScoringGroupId
        ) {
            System.assertEquals(oldScoringGroup.RemoteId__c, newScoringGroup.RemoteId__c);
            System.assertEquals(
                oldScoringGroup.SurveyLibrary__c,
                newScoringGroup.SurveyLibrary__c
            );
        }

        private override void validateExtraScoreValueFields(
                ScoreValue__c oldScoreValue,
                ScoreValue__c newScoreValue,
                Id oldScoreValueId
        ) {
            System.assertEquals(oldScoreValue.RemoteId__c, newScoreValue.RemoteId__c);
            System.assertEquals(oldScoreValue.SurveyLibrary__c, newScoreValue.SurveyLibrary__c);
        }

        private override void validateExtraSkipConditionFields(
                SkipCondition__c oldSkipCondition,
                SkipCondition__c newSkipCondition,
                Id oldSkipConditionId
        ) {
            System.assertEquals(oldSkipCondition.RemoteId__c, newSkipCondition.RemoteId__c);
            System.assertEquals(
                oldSkipCondition.SurveyLibrary__c,
                newSkipCondition.SurveyLibrary__c
            );
        }
    }

    /**
     * Class for validating that a PPI template has been correctly cloned
     */
    private class ValidateReplicatedPpiTemplate extends ValidateReplicatedSurvey {

        public ValidateReplicatedPpiTemplate(
                FormReplicationService.ReplicateBasicSurvey replicatedSurvey
        ) {
            super(replicatedSurvey);
        }

        private FormReplicationService.ReplicateLocalPpiTemplate castReplicatedSurvey() {
            return (FormReplicationService.ReplicateLocalPpiTemplate) this.replicatedSurvey;
        }

        private override void validateExtraSurveyFields(
                Survey__c oldSurvey,
                Survey__c newSurvey
        ) {
            System.assertEquals(
                this.replicatedSurvey.newSurveyIsTemplate,
                newSurvey.IsTemplate__c
            );
            System.assertEquals(oldSurvey.RemoteId__c, newSurvey.RemoteId__c);
            System.assertEquals(oldSurvey.SurveyLibrary__c, newSurvey.SurveyLibrary__c);
            System.assertEquals(oldSurvey.Id, newSurvey.ParentTemplate__c);
            System.assertEquals(true, newSurvey.IsPPI__c);
        }

        private override void validatePpiData() {
            validatePpiDataExtra();
        }

        private virtual void validatePpiDataExtra() {
            PpiTableSelector ppiTableSelector = new PpiTableSelector();

            // Get all the PPI Tables for the old survey
            List<PPITable__c> oldTables = ppiTableSelector.getPpiTablesForSurveys(
                new List<Id>{replicatedSurvey.surveyToCloneId}
            );
            Map<Id, String> tableMap = new Map<Id, String>();
            for (PPITable__c oldTable : oldTables) {
                tableMap.put(oldTable.Id, oldTable.Name);
            }
            ppiTableSelector.resetQueryClauses();

            // Get all the PPI Tables for the new Survey
            List<PPITable__c> newTables = ppiTableSelector.getPpiTablesForSurveys(
                new List<Id>{replicatedSurvey.newSurvey.Id}
            );

            // Compare
            System.assertEquals(oldTables.size(), newTables.size());
            for (PPITable__c newTable : newTables) {
                System.assertEquals(tableMap.get(newTable.Id), newTable.Name);
            }

            List<PPITableDataSet__c> foundTableDataSets = 
                new PpiTableDataSetSelector().getForSurveyVersion(
                    new Set<Id>{replicatedSurvey.surveyVersion.Id}
                );
            System.assertEquals(newTables.size(), foundTableDataSets.size());
        }
    }

    /**
     * Class for validating a Survey has been correctly downloaded and copied
     */
    private virtual class ValidateDownloadedSurvey extends ValidateReplicatedSurvey {

        public ValidateDownloadedSurvey(
                FormReplicationService.ReplicateBasicSurvey replicatedSurvey
        ) {
            super(replicatedSurvey);
        }

        private FormReplicationService.ReplicateRemoteSurvey castReplicatedSurvey() {
            return (FormReplicationService.ReplicateRemoteSurvey) this.replicatedSurvey;
        }

        private override void validateExtraSurveyFields(
                Survey__c oldSurvey,
                Survey__c newSurvey
        ) {
            System.assertEquals(
                this.castReplicatedSurvey().remoteSurveyLibrary.Id,
                newSurvey.SurveyLibrary__c
            );
            System.assertEquals(oldSurvey.Id, newSurvey.RemoteId__c);
            SurveyDO surveyDomain = new SurveyDO();
            String aliasToCheck = surveyDomain.createCloneString(1, oldSurvey.Alias__c);
            System.assertEquals(aliasToCheck, newSurvey.Alias__c);
        }

        private override void validateExtraQuestionFields (
                Question__c oldQuestion,
                Question__c newQuestion,
                Id oldQuestionId
        ) {
            System.assertEquals(oldQuestionId, newQuestion.RemoteServerId__c);
            System.assertEquals(oldQuestionId, newQuestion.RemoteId__c);
            System.assertEquals(
                this.castReplicatedSurvey().remoteSurveyLibrary.Id,
                newQuestion.SurveyLibrary__c
            );
        }

        private override void validateExtraOptionFields(
                Option__c oldOption,
                Option__c newOption,
                Id oldOptionId
        ) {
            System.assertEquals(oldOptionId, newOption.RemoteId__c);
        }

        private override void validateExtraScoringGroupFields(
                ScoringGroup__c oldScoringGroup,
                ScoringGroup__c newScoringGroup,
                Id oldScoringGroupId
        ) {
            System.assertEquals(oldScoringGroupId, newScoringGroup.RemoteId__c);
            System.assertEquals(
                this.castReplicatedSurvey().remoteSurveyLibrary.Id,
                newScoringGroup.SurveyLibrary__c
            );
        }

        private override void validateExtraScoreValueFields(
                ScoreValue__c oldScoreValue,
                ScoreValue__c newScoreValue,
                Id oldScoreValueId
        ) {
            System.assertEquals(oldScoreValueId, newScoreValue.RemoteId__c);
            System.assertEquals(
                this.castReplicatedSurvey().remoteSurveyLibrary.Id,
                newScoreValue.SurveyLibrary__c
            );
        }

        private override void validateExtraSkipConditionFields(
                SkipCondition__c oldSkipCondition,
                SkipCondition__c newSkipCondition,
                Id oldSkipConditionId
        ) {
            System.assertEquals(oldSkipConditionId, newSkipCondition.RemoteId__c);
            System.assertEquals(
                this.castReplicatedSurvey().remoteSurveyLibrary.Id,
                newSkipCondition.SurveyLibrary__c
            );
        }

        private override void validatePpiData() {
            validateExtraPpiData();
        }

        private virtual void validateExtraPpiData() {}
    }

    /**
     * Class for validating a PpiTemplate has been correctly downloaded and copied
     */
    private class ValidateDownloadedPpiTemplate extends ValidateDownloadedSurvey {

        private Set<String> expectedTableNames;
        private Integer numberOfTablesExpected;
        private Integer numberOfTableLinesExpected;

        public ValidateDownloadedPpiTemplate(
                FormReplicationService.ReplicateBasicSurvey replicatedSurvey
        ) {
            super(replicatedSurvey);
            this.expectedTableNames = new Set<String>();
            this.expectedTableNames.addAll(
                this.castReplicatedPpiSurvey().ppiTableDomain.getValues(PPITable__c.Name)
            );
            this.numberOfTablesExpected =
                this.castReplicatedPpiSurvey().ppiTableDomain.records.size();
            this.numberOfTableLinesExpected =
                this.castReplicatedPpiSurvey().ppiTableLineDomain.records.size();
        }

        private FormReplicationService.ReplicateRemotePpiTemplate castReplicatedPpiSurvey() {
            return (FormReplicationService.ReplicateRemotePpiTemplate) this.replicatedSurvey;
        }

        private override void validateExtraPpiData() {
            validateRemotePpiTables();
            validateRemotePpiTableLines();
        }

        private void validateRemotePpiTables() {
            List<PPITable__c> foundTables = [SELECT Name FROM PPITable__c];
            System.assertEquals(numberOfTablesExpected, foundTables.size());
            for (PPITable__c foundTable : foundTables) {
                System.assert(this.expectedTableNames.contains(foundTable.Name));
            }
        }

        private void validateRemotePpiTableLines() {
            List<PPITableLine__c> foundTableLines = [SELECT Id FROM PPITableLine__c];
            System.assertEquals(numberOfTablesExpected, foundTableLines.size());
        }

        private void validateRemotePpiTableDataSet() {
            List<PPITableDataSet__c> foundTableDataSets = 
                new PpiTableDataSetSelector().getForSurveyVersion(
                    new Set<Id>{replicatedSurvey.surveyVersion.Id}
                );
            System.assertEquals(numberOfTableLinesExpected, foundTableDataSets.size());
        }
    }
}