/*
 * So not to proliferate the number of components I have re-purposed this to deal with the
 * testing for the QuestionMappingTH class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
@isTest
private class QuestionMappingCheckValidFieldTypeTest {

    /**
     * Test that a valid field mapping can be created
     */
    static testMethod void testValidFieldMapping() {
        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, false);
        UnitOfWork unitOfWork = new UnitOfWork();
        SurveyMapping__c surveyMapping = SurveyMappingDomainTest.createSurveyMapping(
            '',
            Contact.getSObjectType().getDescribe().getName()
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping,
            testSurvey.testSurvey,
            null,
            unitOfWork
        );
        QuestionMapping__c questionMapping =
            QuestionMappingDomainTest.createQuestionMapping(
                Contact.LastName.getDescribe().getName()
            );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            questionMapping,
            surveyMapping,
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[0],
            unitOfWork
        );
        Test.startTest();
        try {
            unitOfWork.commitWork();
            List<QuestionMapping__c> expectedQuestionMappings =
                new QuestionMappingSelector().getAllForSurvey(testSurvey.testSurvey.Id);
            System.assertEquals(1, expectedQuestionMappings.size());
        } catch (Exception ex) {
            System.assert(false, 'An exception should not have been thrown');
        }
        Test.stopTest();
    }
    /**
     * Test catching a duplicate field mapping when they are both inserted at once
     */
    static testMethod void testDuplicateFieldMapping() {
        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, false);
        UnitOfWork unitOfWork = new UnitOfWork();
        SurveyMapping__c surveyMapping = SurveyMappingDomainTest.createSurveyMapping(
            '',
            Contact.getSObjectType().getDescribe().getName()
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping,
            testSurvey.testSurvey,
            null,
            unitOfWork
        );
        QuestionMapping__c questionMapping =
            QuestionMappingDomainTest.createQuestionMapping(
                Contact.LastName.getDescribe().getName()
            );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            questionMapping,
            surveyMapping,
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[1],
            unitOfWork
        );
        QuestionMapping__c questionMappingDuplicate =
            QuestionMappingDomainTest.createQuestionMapping(
                Contact.LastName.getDescribe().getName()
            );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            questionMappingDuplicate,
            surveyMapping,
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[1],
            unitOfWork
        );
        Test.startTest();
        try {
            unitOfWork.commitWork();
            System.assert(false, 'An exception should have been thrown');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(
                QuestionMappingTH.ERR_FIELD_ALREADY_MAPPED
            ));
        }
        Test.stopTest();
    }

    /**
     * Test catching a duplicate field mapping when one mapping is already in the DB
     */
    static testMethod void testDuplicateAlreadyInDB() {

        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, false);
        UnitOfWork unitOfWork = new UnitOfWork();
        SurveyMapping__c surveyMapping = SurveyMappingDomainTest.createSurveyMapping(
            '',
            Contact.getSObjectType().getDescribe().getName()
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping,
            testSurvey.testSurvey,
            null,
            unitOfWork
        );

        QuestionMapping__c questionMapping =
            QuestionMappingDomainTest.createQuestionMapping(
                Contact.LastName.getDescribe().getName()
            );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            questionMapping,
            surveyMapping,
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[1],
            unitOfWork
        );
        unitOfWork.commitWork();
        unitOfWork.reset();
        List<QuestionMapping__c> questionMappingRecords =
            new QuestionMappingSelector().getAllForSurvey(testSurvey.testSurvey.Id);
        System.assertEquals(1, questionMappingRecords.size());
        QuestionMapping__c questionMappingDuplicate =
            QuestionMappingDomainTest.createQuestionMapping(
                Contact.LastName.getDescribe().getName()
            );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            questionMappingDuplicate,
            surveyMapping,
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[1],
            unitOfWork
        );
        try {
            unitOfWork.commitWork();
            System.assert(false, 'An exception should have been thrown');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(
                QuestionMappingTH.ERR_FIELD_ALREADY_MAPPED
            ));
        }
    }

    /**
     * Test catching the correct error when trying to add mis-matched types
     */
    static testMethod void testMismatchDataTypes() {
        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, false);
        UnitOfWork unitOfWork = new UnitOfWork();
        SurveyMapping__c surveyMapping = SurveyMappingDomainTest.createSurveyMapping(
            '',
            Contact.getSObjectType().getDescribe().getName()
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping,
            testSurvey.testSurvey,
            null,
            unitOfWork
        );

        QuestionMapping__c questionMapping =
            QuestionMappingDomainTest.createQuestionMapping(
                Contact.LastName.getDescribe().getName()
            );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            questionMapping,
            surveyMapping,
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[1],
            unitOfWork
        );
        unitOfWork.commitWork();
        unitOfWork.reset();
        List<QuestionMapping__c> questionMappingRecords =
            new QuestionMappingSelector().getAllForSurvey(testSurvey.testSurvey.Id);
        System.assertEquals(1, questionMappingRecords.size());
        QuestionMapping__c questionMappingDuplicate =
            QuestionMappingDomainTest.createQuestionMapping(
                Contact.DoNotCall.getDescribe().getName()
            );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            questionMappingDuplicate,
            surveyMapping,
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[1],
            unitOfWork
        );
        Test.startTest();
        try {

            // Have to override the roll back as it was made outside of this test segment
            unitOfWork.setOverrideRollbackToMaster(true);
            unitOfWork.commitWork();
            System.assert(false, 'An exception should have been thrown');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(
                QuestionMappingTH.ERR_FIELD_NO_MATCH_QUESTION
            ));
        }
    }

    /**
     * Test catching the correct error when a field doesn't exist
     */
    static testMethod void testFieldNotExisting() {
        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(null, false);
        UnitOfWork unitOfWork = new UnitOfWork();
        SurveyMapping__c surveyMapping = SurveyMappingDomainTest.createSurveyMapping(
            '',
            Contact.getSObjectType().getDescribe().getName()
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping,
            testSurvey.testSurvey,
            null,
            unitOfWork
        );

        QuestionMapping__c questionMapping =
            QuestionMappingDomainTest.createQuestionMapping(
                'BAD NAME'
            );
        unitOfWork = QuestionMappingDomainTest.addQuestionMappingToUnitOfWork(
            questionMapping,
            surveyMapping,
            testSurvey.questionMap.get(testSurvey.topLevelSections[0].Id)[1],
            unitOfWork
        );
        Test.startTest();
        try {
            unitOfWork.commitWork();
            System.assert(false, 'An exception should have been thrown');
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains(
                    String.format(
                        DescribeHandler.FIELD_NOT_EXIST,
                        new List<String>{
                            questionMapping.FieldApiName__c,
                            surveyMapping.ObjectApiName__c
                        }
                    )
                )
            );
        }
        Test.stopTest();
    }
}