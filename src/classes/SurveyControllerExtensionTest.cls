/*
 * Test class for the SurveyControllerExtension class
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
private class SurveyControllerExtensionTest {

    static testMethod void checkSaveContinue() {
        SurveyControllerExtension extension = new SurveyControllerExtension();
        Test.startTest();
        extension.init();
        Test.stopTest();
        System.assertEquals(C.getLicense().PPI_Editable__c, extension.isPPIEnabled);
    }

    /**
     * Test to generate a Survey Lib
     * Verify the Survey Library is loaded successfully when invoke remoting method.
     * (Related: IDALMSA-3213)
     */
    static testMethod void testRemoteMethodGenerateSurveyLibraryList() {
        // Save a survey library and activate it as Survey
        SurveyLibrary__c surveyLib =
            SurveyLibraryDomainTest.addLibraryToDatabase(C.GRAMEEN_LIBRARY);
        System.assert(surveyLib.Id != null, 'Survey Library should not be created in database properly');

        surveyLib.IsSurvey__c = true;
        SurveyLibraryDomain surveyLibraryDomain = new SurveyLibraryDomain();
        surveyLibraryDomain.addRecord(surveyLib);
        surveyLibraryDomain.updateRecords();

        Test.startTest();
        List <SurveyControllerExtension.SurveyLibraryItem> surveyLibaries =
            SurveyControllerExtension.generateSurveyLibraryList();
        Test.stopTest();

        System.assert(!surveyLibaries.isEmpty(), 'There should be a stored survey library.');
    }

    static testMethod void testGetSurveyList() {
        Set<Id> oldPpiTemplate = new Set<Id>();
        Set<Id> newPpiTemplate = new Set<Id>();
        Set<Id> oldPpiUseItSurvey = new Set<Id>();
        Set<Id> newPpiUseItSurvey = new Set<Id>();
        Set<Id> normalSurvey = new Set<Id>();

        // Normal Surveys without Ppi
        Survey__c surveyPublishedInstance = SurveyDOTest.createInsertedSurvey('TestPublishedSurvey');
        Survey__c surveyDraftInstance = SurveyDOTest.createInsertedSurvey('TestDraftSurvey');

        // Old PpiTemplate and its use It Survey
        Survey__c oldPpiTemplateInstance = SurveyDOTest.createInsertedPpiTemplate();
        Survey__c useItOldPpiTemplateInstance = SurveyDOTest.createInsertedPpiTemplate();
        useItOldPpiTemplateInstance.isTemplate__c = false;

        // New PpiTemplate and its use It Survey
        TestSurveyData newPpiTemplateInstance = TestSurveyData.createFullPpiTemplate();
        System.assertEquals(1, newPpiTemplateInstance.ppiTables.size(), 'There should be 1 PPI Table');
        newPpiTemplateInstance.ppiTables[0].Name = 'Parent PpiTable';
        PpiTableDomain ppiTableDomainInstance =
            new PpiTableDomain.Constructor().constructWithRecords(newPpiTemplateInstance.ppiTables);
        ppiTableDomainInstance.updateRecords();

        TestSurveyData useItNewPpiTemplateInstance =
            TestSurveyData.createFullPpiTemplate();
        useItNewPpiTemplateInstance.testSurvey.RemoteId__c = 'Test';
        useItNewPpiTemplateInstance.testSurvey.isTemplate__c = false;

        // Verify that all surveys are inserted into database properly
        List<Survey__c> surveyList = new SurveySelector().getAllSurveys();
        System.assertEquals(6, surveyList.size());
        Map<Id, Survey__c> mapExpectedSurveyIdToInstance = new Map<Id, Survey__c>(surveyList);

        SurveyDO surveyDomainInstance =
            new SurveyDO.Constructor().constructWithRecords(
                new List<Survey__c> {
                    useItOldPpiTemplateInstance,
                    useItNewPpiTemplateInstance.testSurvey
                }
            );
        surveyDomainInstance.updateRecords();

        SurveyManagerController surveyManager =
            new SurveyManagerController(new ApexPages.StandardController(new Survey__c()));
        surveyManager.surveyToPublish = surveyPublishedInstance.Id;
        surveyManager.doPublish();

        Test.startTest();
        String getSurveyJsonString = new SurveyControllerExtension().getSurveyList();
        Test.stopTest();

        System.assert(getSurveyJsonString != null, 'Json String should be generated properly');
        List<SurveyControllerExtension.SurveyWrapper> surveyWrapperList =
            (List<SurveyControllerExtension.SurveyWrapper>) JSON.deserialize(
                getSurveyJsonString,
                List<SurveyControllerExtension.SurveyWrapper>.class
            );
        System.assertEquals(6, surveyWrapperList.size());

        for (SurveyControllerExtension.SurveyWrapper surveyWrapperInstance : surveyWrapperList) {
            if (surveyWrapperInstance.isPpi && surveyWrapperInstance.isTemplate) {
                if (
                    !SurveyDO.isNewPpiSurvey(
                        mapExpectedSurveyIdToInstance.get(surveyWrapperInstance.Id)
                    )
                ) {
                    System.assert(!surveyWrapperInstance.isDemographicPpiSurvey);
                    oldPpiTemplate.add(surveyWrapperInstance.Id);
                } else {
                    System.assert(surveyWrapperInstance.isDemographicPpiSurvey);
                    newPpiTemplate.add(surveyWrapperInstance.Id);
                }
            } else if (surveyWrapperInstance.isPpi) {
                if (
                    !SurveyDO.isNewPpiSurvey(
                        mapExpectedSurveyIdToInstance.get(surveyWrapperInstance.Id)
                    )
                ) {
                    System.assert(!surveyWrapperInstance.isDemographicPpiSurvey);
                    oldPpiUseItSurvey.add(surveyWrapperInstance.Id);
                } else {
                    System.assert(surveyWrapperInstance.isDemographicPpiSurvey);
                    newPpiUseItSurvey.add(surveyWrapperInstance.Id);
                }
            } else {
                System.assert(!surveyWrapperInstance.isDemographicPpiSurvey);
                normalSurvey.add(surveyWrapperInstance.Id);
            }
        }
        System.assertEquals(1, oldPpiTemplate.size());
        System.assertEquals(1, newPpiTemplate.size());
        System.assertEquals(1, oldPpiUseItSurvey.size());
        System.assertEquals(1, newPpiUseItSurvey.size());
        System.assertEquals(2, normalSurvey.size());
    }
}