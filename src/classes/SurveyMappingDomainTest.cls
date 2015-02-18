/**
 * Test class for the SurveyMapping__c object domain class
 * Deals with:
 *     - Creation of a Survey Mapping
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Aditi Satpute
 */
@isTest
public class SurveyMappingDomainTest {

    public static SurveyMapping__c createSurveyMapping(
            String matchingField,
            String objectApiName
    ) {
        return createSurveyMapping(matchingField, objectApiName, false);
    }

    public static SurveyMapping__c createSurveyMapping(
            String matchingField,
            String objectApiName,
            Boolean isReference
    ) {
        return createSurveyMapping(new Map<Schema.SObjectField, Object>{
            SurveyMapping__c.IsReference__c => isReference,
            SurveyMapping__c.MatchingField__c => matchingField,
            SurveyMapping__c.ObjectApiName__c => objectApiName
        });
    }

    public static SurveyMapping__c createSurveyMapping(Map<Schema.SObjectField, Object> fieldMap) {

        GenericObjectCreator creator = new GenericObjectCreator(SurveyMapping__c.getSObjectType());
        SurveyMapping__c surveyMapping = (SurveyMapping__c) creator.createNewRecord();
        creator.populateFields(
            surveyMapping,
            fieldMap
        );
        return surveyMapping;
    }

    public static UnitOfWork addSurveyMappingToUnitOfWork(
        SurveyMapping__c surveyMapping,
        Survey__c survey,
        Question__c repeat,
        UnitOfWork unitOfWork
    ) {

        unitOfWork.addToInsertionOrder(SurveyMapping__c.getSObjectType(), 1);
        unitOfWork.addToInsertList(
            surveyMapping,
            SurveyMapping__c.Survey__c,
            survey,
            1
        );
        unitOfWork.createRelationship(
            surveyMapping,
            SurveyMapping__c.Repeat__c,
            repeat,
            1
        );
        return unitOfWork;
    }
}