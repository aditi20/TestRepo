/**
 * Test class for Survey Library Selector
 *
 * @author - Kaushik Ray
 * @author - Aditi Satpute
 */
@isTest
private with sharing class SurveyLibrarySelectorTest {

    static testMethod void validateGetAllForIsSurveyWithActiveStatus() {
        List<SurveyLibrary__c> surveyLibraryList =
            SurveyLibraryDomainTest.addMultipleLibraryToDatabase(C.GRAMEEN_LIBRARY, 3);
        System.assertEquals(3, surveyLibraryList.size());

        surveyLibraryList[0].Active__c = true;
        surveyLibraryList[1].Active__c = true;
        surveyLibraryList[2].Active__c = false;

        surveyLibraryList[0].isSurvey__c = false;
        surveyLibraryList[1].isSurvey__c = true;
        surveyLibraryList[2].isSurvey__c = true;

        SurveyLibraryDomain surveyLibraryDomainInstance =
            new SurveyLibraryDomain.Constructor().constructWithRecords(surveyLibraryList);
        surveyLibraryDomainInstance.updateRecords();

        Test.startTest();
        List<SurveyLibrary__c> surveyLibraryRecords =
            new SurveyLibrarySelector().getAllForIsSurveyWithActiveStatus(true);
        Test.stopTest();

        // Verify that only one record is fetched which has Active__c = true and isSurvey__c = true
        System.assert(
            1 == surveyLibraryRecords.size(),
            'Survey Library record should get fetched properly'
        );
        System.assertEquals(surveyLibraryList[1].Id, surveyLibraryRecords[0].Id);
    }

    static testMethod void validateRecordsByName() {
        SurveyLibraryDomainTest.addLibraryToDatabase(C.GRAMEEN_LIBRARY);

        Test.startTest();
        List<SurveyLibrary__c> surveyLibraryRecords =
            new SurveyLibrarySelector().getRecordsByName(C.GRAMEEN_LIBRARY);
        Test.stopTest();

        System.assert(
            1 == surveyLibraryRecords.size(),
            'Survey Library record should get inserted'
        );
        System.assertEquals(surveyLibraryRecords[0].Name, C.GRAMEEN_LIBRARY);
    }
}