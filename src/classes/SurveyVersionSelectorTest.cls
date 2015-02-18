/**
 * Test class for the SurveyVersionSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 * @author - Aditi Satpute
 */
@isTest
public with sharing class SurveyVersionSelectorTest {

    /**
     * Test method to verify fetching of SurveyVersion object with survey details
     */
    static testmethod void testFetchAllWithSurveyDetails() {
        Survey__c survey1 = SurveyDOTest.createTestSurveyRecord('Test Survey 1');
        survey1.PpiIdentifier__c = 'TEST_1';
        Survey__c survey2 = SurveyDOTest.createTestSurveyRecord('Test Survey 2');
        survey2.PpiIdentifier__c = 'TEST_2';
        SurveyDO surveyDOInstance =
            new SurveyDO.Constructor().constructWithRecords(
                new List<Survey__c> {survey1, survey2}
            );
        surveyDOInstance.insertRecords();

        List<Survey__c> surveys = new SurveySelector().getWithSurveyVersion(
            new Set<String> {survey1.Id, survey2.Id}
        );
        System.assertEquals(2, surveys.size());
        System.assertEquals(1, surveys[0].SurveyVersions__r.size());

        Test.startTest();
        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyDetails(
                new Set<Id> {
                    surveys[0].SurveyVersions__r[0].Id,
                    surveys[1].SurveyVersions__r[0].Id
                }
            );
        Test.stopTest();

        // SurveyVersion records are fetched properly
        System.assertEquals(
            2,
            surveyVersions.size()
        );

        // Survey details fetched properly
        System.assertEquals(
            'TEST_1',
            surveyVersions[0].Survey__r.PpiIdentifier__c
        );
    }

    /**
     * Test method to verify fetching of SurveyVersion object with specified survey Ids
     */
    static testmethod void testFetchAllWithSurveyIds() {
        Survey__c survey1 = SurveyDOTest.createInsertedSurvey('Test Survey 1');
        Survey__c survey2 = SurveyDOTest.createInsertedSurvey('Test Survey 2');

        Test.startTest();
        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(
                new Set<String> {
                    survey1.Id,
                    survey2.Id
                }
            );
        Test.stopTest();

        // SurveyVersion records are fetched properly
        System.assertEquals(
            2,
            surveyVersions.size()
        );
    }

    /**
     * Test method to verify fetching of SurveyVersion record 
     * with specified Ppi, Template and SurveyLibrary with Name not as 'Default' and 'myLib'
     */
    static testMethod void testFetchAllWithSurveyLibrary() {

        SurveyLibrary__c surveyLibrary = SurveyLibraryDomainTest.addLibraryToDatabase();
        System.assert(surveyLibrary != null, 'SurveyLibrary record could not be created.');

        // Create survey with Survey Library 
        Survey__c surveywithLibrary = SurveyDOTest.createInsertedPpiTemplate();
        System.assert(surveywithLibrary != null, 'Survey record could not be created.');

        surveywithLibrary.SurveyLibrary__c = surveyLibrary.Id;
        SurveyDO surveyDomain = new SurveyDO();
        surveyDomain.addRecord(surveywithLibrary);
        surveyDomain.updateRecords();

        List<Survey__c> surveyRecord =
            (List<Survey__c>) new SurveySelector().getRecordsById(
                new Set<Id> {surveywithLibrary.Id}
            );
        System.assert(surveyRecord.size() == 1, 'Survey record could not be fetched properly.');
        System.assertEquals(SurveyDO.STATUS_DRAFT, surveyRecord[0].Status__c);

        // Create survey without any assigned survey library 
        Survey__c surveyWithoutLibrary = SurveyDOTest.createInsertedPpiTemplate();
        System.assert(surveyWithoutLibrary != null, 'Survey record could not be created.');

        Test.startTest();
        List<SurveyVersion__c> surveyVersionList =
            new SurveyVersionSelector().getAllTemplatesForLicense(
                surveyLibrary.Name,
                true,
                false,
                ''
            );
        Test.stopTest();

        System.assert(
            surveyVersionList.size() == 1,
            'Survey Version records could not be fetched.'
        );
        System.assert(surveyVersionList[0].Survey__r.SurveyLibrary__c != null);
    }

    /**
     * Test method to verify fetching of SurveyVersion record 
     * with specified Ppi, Template and SurveyLibrary Name as 'myLib'
     */
    static testMethod void testFetchAllSurveyVersionRecords() {

        LicenseSettings__c license = C.getLicense();
        license.UseTemplates__c = true;
        update license;

        SurveyLibrary__c surveyLibrary = SurveyLibraryDomainTest.createSurveyLibrary('myLib');
        System.assert(surveyLibrary != null, 'SurveyLibrary record could not be created.');

        SurveyLibraryDomain surveyLibraryDomain = new SurveyLibraryDomain();
        surveyLibraryDomain.addRecord(surveyLibrary);
        surveyLibraryDomain.insertRecords();
        System.assert(surveyLibraryDomain.records.size() > 0);
        System.assert(surveyLibraryDomain.records[0].Id != null);

        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        System.assert(survey != null, 'Survey record could not be created properly.');

        Test.startTest();
        List<SurveyVersion__c> surveyVersionList =
            new SurveyVersionSelector().getAllTemplatesForLicense(
                surveyLibrary.Name,
                true,
                true,
                ''
            );
        Test.stopTest();

        System.assert(
            surveyVersionList.size() == 1,
            'Survey Version records could not be fetched.'
        );
    }

    /**
     * Test method to verify fetching of SurveyVersion record 
     * with specified Ppi, Template, SurveyLibrary Name as 'Default' and Order by Created date
     */
    static testMethod void testFetchAllSurveyVersionRecordsForDefaultLibrary() {

        LicenseSettings__c license = C.getLicense();
        license.UseTemplates__c = true;
        update license;

        SurveyLibrary__c surveyLibrary = SurveyLibraryDomainTest.createSurveyLibrary('default');
        System.assert(surveyLibrary != null, 'SurveyLibrary record could not be created.');

        SurveyLibraryDomain surveyLibraryDomain = new SurveyLibraryDomain();
        surveyLibraryDomain.addRecord(surveyLibrary);
        surveyLibraryDomain.insertRecords();
        System.assert(surveyLibraryDomain.records.size() == 1);
        System.assert(surveyLibraryDomain.records[0].Id != null);

        Survey__c firstSurvey = SurveyDOTest.createInsertedPpiTemplate();
        System.assert(firstSurvey != null, 'Survey record not created properly.');

        C.wait(5);
        Survey__c secondSurvey = SurveyDOTest.createInsertedPpiTemplate();
        System.assert(secondSurvey != null, 'Survey record not created properly.');

        C.wait(5);
        Survey__c thirdSurvey = SurveyDOTest.createInsertedPpiTemplate();
        System.assert(thirdSurvey != null, 'Survey record not created properly.');

        thirdSurvey.SurveyLibrary__c = surveyLibrary.Id;
        SurveyDO surveyDomain = new SurveyDO();
        surveyDomain.addRecord(thirdSurvey);
        surveyDomain.updateRecords();

        List<Survey__c> surveyRecord =
            (List<Survey__c>) new SurveySelector().getRecordsById(new Set<Id> {thirdSurvey.Id});
        System.assert(surveyRecord.size() == 1, 'Survey record could not be fetched properly.');
        System.assertEquals(SurveyDO.STATUS_DRAFT, surveyRecord[0].Status__c);

        Test.startTest();
        List<SurveyVersion__c> surveyVersionList =
            new SurveyVersionSelector().getAllTemplatesForLicense(
                surveyLibrary.Name,
                true,
                true,
                'CreatedDate'
            );
        Test.stopTest();

        System.assert(
            surveyVersionList.size() == 3,
            'Survey Version records could not be fetched.'
        );
        System.assert(surveyVersionList[0].Survey__r != null, 'Survey data could be fetched.');
        System.assertEquals(firstSurvey.Name, surveyVersionList[0].Survey__r.Name);

        System.assert(surveyVersionList[1].Survey__r != null, 'Survey data could be fetched.');
        System.assertEquals(surveyVersionList[1].Survey__r.Name, secondSurvey.Name);

        System.assert(surveyVersionList[2].Survey__r != null, 'Survey data could be fetched.');
        System.assertEquals(surveyVersionList[2].Survey__r.Name, thirdSurvey.Name);
    }
}