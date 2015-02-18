/**
 * Domain test class for the SurveyLibrary__c object
 * Deals with:
 *    - Creating test instances of this object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 * @author Owen Davies
 */
@isTest
public class SurveyLibraryDomainTest {

    public static final String PPI_ENDPOINT = 'EndPoint';

    public static SurveyLibrary__c createSurveyLibrary() {
        return createSurveyLibrary('TEST LIB');
    }

    public static SurveyLibrary__c createSurveyLibrary(String libraryName) {
        return createSurveyLibrary(new Map<Schema.SObjectField, Object>{
            SurveyLibrary__c.Name => libraryName,
            SurveyLibrary__c.PpiResultsEndpoint__c => PPI_ENDPOINT,
            SurveyLibrary__c.RemoteLibraryPath__c => 'path',
            SurveyLibrary__c.SurveyPreviewPath__c => 'path',
            SurveyLibrary__c.URL__c => 'www.testurl.org'
        });
    }

    public static SurveyLibrary__c createSurveyLibrary(Map<Schema.SObjectField, Object> fieldMap) {

        GenericObjectCreator creator =
            new GenericObjectCreator(SurveyLibrary__c.getSObjectType());
        SurveyLibrary__c surveyLibrary =
            (SurveyLibrary__c) creator.createNewRecord();
        creator.populateFields(
            surveyLibrary,
            fieldMap
        );
        return surveyLibrary;
    }

    public static List<SurveyLibrary__c> addMultipleLibraryToDatabase(
            String libraryName,
            Integer numberOfRecords
    ) {
        List<SurveyLibrary__c> surveyLibraryList = new List<SurveyLibrary__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            surveyLibraryList.add(createSurveyLibrary(libraryName + i));
        }
        SurveyLibraryDomain surveyLibraryDomainInstance =
            new SurveyLibraryDomain.Constructor().constructWithRecords(surveyLibraryList);
        surveyLibraryDomainInstance.insertRecords();

        return surveyLibraryList;
    }

    public static SurveyLibrary__c addLibraryToDatabase() {
        SurveyLibrary__c surveyLibrary = createSurveyLibrary();
        insert surveyLibrary;
        return surveyLibrary;
    }

    public static SurveyLibrary__c addLibraryToDatabase(String libraryName) {
        SurveyLibrary__c surveyLibrary = createSurveyLibrary(libraryName);
        insert surveyLibrary;
        return surveyLibrary;
    }
}