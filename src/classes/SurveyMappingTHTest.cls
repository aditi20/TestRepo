/**
 * Test class for the SurveyMappingTH
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class SurveyMappingTHTest {
    static final string PACKAGED_OBJECT = Survey__c.sObjectType.getDescribe().getName();
    static final string OBJ_CONTACT = 'Contact';
    static final string OBJ_ACCOUNT = 'Account';
    static final string SURVEY_NAME = 'Test Survey';

    /**
     * Test method to verify if Survey mapping record gets saved properly if
     * selected object doesn't have any namespace
     */
    static testmethod void testValidateRecordsWithoutNamespace() {
        Survey__c survey = SurveyDOTest.createInsertedSurvey(SURVEY_NAME);

        SurveyMapping__c surveyMapping1 =
            SurveyMappingDomainTest.createSurveyMapping('', OBJ_CONTACT);
        SurveyMapping__c surveyMapping2 =
            SurveyMappingDomainTest.createSurveyMapping('', OBJ_ACCOUNT);
        UnitOfWork unitOfWork = new UnitOfWork();
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping1,
            survey,
            null,
            unitOfWork
        );
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping2,
            survey,
            null,
            unitOfWork
        );

        Test.startTest();
        unitOfWork.commitWork();
        Test.stopTest();

        List<SurveyMapping__c> surveyMappings =
            (List<SurveyMapping__c>) new SurveyMappingSelector().getRecordsById(
                new Set<Id> {surveyMapping1.Id, surveyMapping2.Id}
            );

        System.assertEquals(
            surveyMappings.size(), 2,
            'Survey Mapping records not inserted into database properly'
        );

        System.assertEquals(
            OBJ_CONTACT,
            surveyMappings[0].ObjectApiName__c
        );

        System.assertEquals(
            OBJ_ACCOUNT,
            surveyMappings[1].ObjectApiName__c
        );
    }

    /**
     * Test method for throwing error if Survey mapping field contains packaged objects
     */
    static testMethod void testValidateRecordsWithNamespace() {
        try {
            Survey__c survey = SurveyDOTest.createInsertedSurvey(SURVEY_NAME);

            SurveyMapping__c surveyMapping =
                SurveyMappingDomainTest.createSurveyMapping('', PACKAGED_OBJECT);
            UnitOfWork unitOfWork = new UnitOfWork();
            unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
                surveyMapping,
                survey,
                null,
                unitOfWork
            );

            Test.startTest();
            unitOfWork.commitWork();
            Test.stopTest();
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains(System.Label.BUILDER_ERR_MOBILESURVEY_MAPPING),
                'Survey Mapping field with object having namespace should throw proper error'
            );
        }
    }

    /**
     * Test method to verify error is not thrown even if Survey mapping field contains
     * PpiResult packaged object
     */
    static testmethod void testValidatePpiResultWithNamespaceAllowed() {

        String ppiResultPackagedObject =
            PpiResult__c.sObjectType.getDescribe().getName();

        Survey__c survey = SurveyDOTest.createInsertedSurvey(SURVEY_NAME);

        SurveyMapping__c surveyMapping =
            SurveyMappingDomainTest.createSurveyMapping('', ppiResultPackagedObject);
        UnitOfWork unitOfWork = new UnitOfWork();
        unitOfWork = SurveyMappingDomainTest.addSurveyMappingToUnitOfWork(
            surveyMapping,
            survey,
            null,
            unitOfWork
        );

        Test.startTest();
        unitOfWork.commitWork();
        Test.stopTest();

        SurveyMapping__c surveyMappingInstance =
            (SurveyMapping__c) new SurveyMappingSelector().getRecordById(
                surveyMapping.Id
            );

        System.assert(
            surveyMappingInstance != null,
            'Survey Mapping record not inserted into database properly'
        );

        System.assertEquals(
            ppiResultPackagedObject,
            surveyMappingInstance.ObjectApiName__c
        );
    }
}