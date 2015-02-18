/**
 * Test class for the Survey__c domain class
 * Deals with the creation of test Survey__c objcts and full Surveys
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 * @author - Aditi Satpute
 * @author - Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public with sharing class SurveyDOTest {

    public static final String TEST_SURVEY_NAME = 'A test name';
    public static final String TEST_SURVEY_ALIAS = 'A test alias';
    public static final String PPI_IDENTIFIER = 'Test_1';

    public static Survey__c createInsertedSurvey() {
        Survey__c survey = createTestSurveyRecord();
        insert survey;
        return survey;
    }

    public static Survey__c createInsertedSurvey(String surveyName) {
        Survey__c survey = createTestSurveyRecord(surveyName);
        insert survey;
        return survey;
    }

    public static Survey__c createInsertedSurvey(Map<Schema.SObjectField, Object> fieldMap) {
        Survey__c survey =  createTestSurveyRecord(fieldMap);
        insert survey;
        return survey;
    }

    public static Survey__c createTestSurveyRecord() {
        return createTestSurveyRecord(TEST_SURVEY_NAME);
    }

    public static Survey__c createTestSurveyRecord(String surveyName) {
        return createTestSurveyRecord(
            new Map<Schema.SObjectField, Object>{
                Survey__c.Name => surveyName
            }
        );
    }

    public static Survey__c createInsertedTemplate() {
        Survey__c template = createTemplate();
        insert template;
        return template;
    }

    public static Survey__c createTemplate() {
        return createTestSurveyRecord(new Map<Schema.SObjectField, Object>{
            Survey__c.Name => SurveyDOTest.TEST_SURVEY_NAME + '_TEMPLATE',
            Survey__c.Alias__c => SurveyDOTest.TEST_SURVEY_ALIAS + '_TEMPLATE',
            Survey__c.IsTemplate__c => true
        });
    }

    public static Survey__c createInsertedPpiTemplate() {
        Survey__c ppiTemplate = createPpiTemplate();
        insert ppiTemplate;
        return ppiTemplate;
    }

    public static Survey__c createInsertedPpiTemplate(
            Language__c language,
            ISO_Country__c country,
            Integer year
    ) {
        Survey__c ppiTemplate = createPpiTemplate(
            language,
            country,
            year
        );
        insert ppiTemplate;
        return ppiTemplate;
    }

    public static Survey__c createPpiTemplate() {
        return createPpiTemplate(
            LanguageWrapperTest.insertRecord('AA', 'Afar'),
            ISOCountryWrapperTest.insertRecord('KE', 'KENYA'),
            2012
        );
    }
    public static Survey__c createPpiTemplate(
            Language__c language,
            ISO_Country__c country,
            Integer year
    ) {
        TestUtils.allowUseOfPpiSurvey();
        String randomString = String.valueOf(Crypto.getRandomInteger());
        return createTestSurveyRecord(new Map<Schema.SObjectField, Object>{
            Survey__c.Name => SurveyDOTest.TEST_SURVEY_NAME + '_PPI_' + randomString,
            Survey__c.Alias__c => SurveyDOTest.TEST_SURVEY_ALIAS + '_PPI_' + randomString,
            Survey__c.PPIDataYear__c => year,
            Survey__c.CountryCode__c => country.Name,
            Survey__c.LanguageCode__c => language.Name,
            Survey__c.IsPPI__c => true,
            Survey__c.IsTemplate__c => true
        });
    }

    public static Survey__c createTestSurveyRecordWithAlias(String suffix) {
        return createTestSurveyRecord(new Map<Schema.SObjectField, Object>{
            Survey__c.Name => SurveyDOTest.TEST_SURVEY_NAME + suffix,
            Survey__c.Alias__c => SurveyDOTest.TEST_SURVEY_ALIAS + suffix
        });
    }

    public static Survey__c createTestSurveyRecord(Map<Schema.SObjectField, Object> fieldMap) {
        GenericObjectCreator creator = new GenericObjectCreator(Survey__c.getSObjectType());
        Survey__c testSurvey = (Survey__c) creator.createNewRecord();
        creator.populateFields(
            testSurvey,
            fieldMap
        );
        return testSurvey;
    }

    /**
     * Test class for setting Ppi Identifier comparing with old value
     */
    static testmethod void testSetPpiIdentifierAfterComparison() {

        Survey__c survey1 = createPpiTemplate();
        Survey__c survey2 = createPpiTemplate(
            LanguageWrapperTest.insertRecord('LA', 'LATIN'),
            ISOCountryWrapperTest.insertRecord('IT', 'ITALY'),
            2013
        );

        Map<Id, Survey__c> oldMap = new Map<Id, Survey__c>();
        oldMap.put(survey1.Id, survey1);

        Test.startTest();
        SurveyDO domainInstance = new SurveyDO();
        domainInstance.addRecord(survey2);
        domainInstance.setPpiIdentifier(oldMap, domainInstance.records);
        Test.stopTest();

        Survey__c surveyWithIdentifier = (Survey__c) domainInstance.records[0];
        System.assertEquals('ITALY_2013', surveyWithIdentifier.PpiIdentifier__c);
    }

    /**
     * Test class for setting Ppi Identifier
     */
    static testMethod void testSetPpiIdentifier() {

        Survey__c survey = createPpiTemplate();

        Test.startTest();
        SurveyDO domainInstance = new SurveyDO();
        domainInstance.addRecord(survey);
        domainInstance.setPpiIdentifier(domainInstance.records);
        Test.stopTest();

        Survey__c surveyWithIdentifier = (Survey__c) domainInstance.records[0];
        System.assertEquals('KENYA_2012', surveyWithIdentifier.PpiIdentifier__c);
    }

    /**
     * Test that the name and alias change correctly when cloning twice
     */
    static testMethod void testCloneSurveyAliasAndNameChange() {

        Survey__c initialSurvey = createTestSurveyRecordWithAlias('');
        insert initialSurvey;
        Survey__c firstClone = createTestSurveyRecordWithAlias('');
        SurveyDO domain = new SurveyDO();
        firstClone = domain.cloneSurveyCheckingNameAndAlias(firstClone);
        insert firstClone;
        Survey__c secondClone = createTestSurveyRecordWithAlias('');
        secondClone = domain.cloneSurveyCheckingNameAndAlias(secondClone);

        System.assertEquals(
            System.label.CLONE_SURVEY_NAME + ' ' + 1 + ' ' + initialSurvey.Name,
            firstClone.Name
        );
        System.assertEquals(
            System.label.CLONE_SURVEY_NAME + ' ' + 1 + ' ' + initialSurvey.Alias__c,
            firstClone.Alias__c
        );
        System.assertEquals(
            System.label.CLONE_SURVEY_NAME + ' ' + 2 + ' ' + initialSurvey.Name,
            secondClone.Name
        );
        System.assertEquals(
            System.label.CLONE_SURVEY_NAME + ' ' + 2 + ' ' + initialSurvey.Alias__c,
            secondClone.Alias__c
        );
    }

    /**
     * Test method to verify created survey is based on new Ppi data model returns true
     */
    static testMethod void testIsNewPpiSurvey() {

        TestSurveyData testSurvey = TestSurveyData.createFullPpiTemplate();
        System.assertEquals(true, SurveyDO.isNewPpiSurvey(testSurvey.testSurvey));
    }

    /**
     * Test method to verify created survey is not based on new Ppi data model retruns false
     */
    static testMethod void testIsNotNewPpiSurvey() {

        Survey__c testSurvey = createInsertedPpiTemplate();
        System.assertEquals(false, SurveyDO.isNewPpiSurvey(testSurvey));
    }
}