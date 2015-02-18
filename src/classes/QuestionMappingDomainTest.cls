/**
 * Test class for the QuestionMapping__c object domain class
 * Deals with:
 *     - Creation of a Question Mapping
 *     - Adding Question Mapping to a UnitOfWork
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class QuestionMappingDomainTest {

    public static QuestionMapping__c createQuestionMapping(String fiedApiName) {
        return createQuestionMapping(new Map<Schema.SObjectField, Object>{
            QuestionMapping__c.FieldApiName__c => fiedApiName
        });
    }

    public static QuestionMapping__c createQuestionMapping(
            Map<Schema.SObjectField, Object> fieldMap
    ) {

        GenericObjectCreator creator = new GenericObjectCreator(QuestionMapping__c.getSObjectType());
        QuestionMapping__c questionMapping = (QuestionMapping__c) creator.createNewRecord();
        creator.populateFields(
            questionMapping,
            fieldMap
        );
        return questionMapping;
    }

    public static UnitOfWork addQuestionMappingToUnitOfWork(
        QuestionMapping__c questionMapping,
        SurveyMapping__c surveyMapping,
        Question__c question,
        UnitOfWork unitOfWork
    ) {

        unitOfWork.addToInsertionOrder(QuestionMapping__c.getSObjectType(), 1);
        unitOfWork.addToInsertList(
            questionMapping,
            QuestionMapping__c.Question__c,
            question,
            1
        );
        unitOfWork.createRelationship(
            questionMapping,
            QuestionMapping__c.SurveyMapping__c,
            surveyMapping,
            1
        );
        return unitOfWork;
    }

    /**
     * Test that a question mapping that is mapped to an auto number that is not the survey
     * mapping ID field throws the correct error
     */
    static testMethod void testAutoNumberError() {

        UnitOfWork unitOfWork = new UnitOfWork();
        SurveyMapping__c surveyMapping = SurveyMappingDomainTest.createSurveyMapping(
            '',
            Case.getSObjectType().getDescribe().getName()
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping,
            null,
            null,
            unitOfWork
        );

        Question__c question = QuestionDOTest.quickInsertedNonSectionQuestion(
            QuestionDO.TYPE_TEXT_SHORT
        );

        QuestionMapping__c questionMapping =
            createQuestionMapping(Case.CaseNumber.getDescribe().getName());
        unitOfWork = addQuestionMappingToUnitOfWork(
            questionMapping,
            surveyMapping,
            question,
            unitOfWork
        );
        QuestionMappingTH.skipValidation = true;
        unitOfWork.commitWork();
        QuestionMappingTH.skipValidation = false;

        SurveyMappingSelector surveyMappingSelector = new SurveyMappingSelector();
        Map<Id, SurveyMapping__c> surveyMappings = new Map<Id, SurveyMapping__c>{
            surveyMapping.Id => surveyMapping
        };

        Test.startTest();
        try {
            QuestionMappingDomain domain = new QuestionMappingDomain(
                new List<QuestionMapping__c>{questionMapping}
            );
            domain.checkFieldIsAutoNumberAndNotId(surveyMappings);
            System.assert(false, 'Should not have got here as exception should have been thrown');
        } catch (C.AutonumberNotIdFieldException e) {
            System.assertEquals(
                System.label.SURVEY_MAPPING_CANT_USE_AN_IF_NOT_IDFIELD_EXCEPTION,
                e.getMessage()
            );
        }
    }
}