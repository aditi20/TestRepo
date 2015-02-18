/**
 * Test class for the LanguageWrapper
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class LanguageWrapperTest {

    public static Language__c createRecord(String name, String shortName) {
        Language__c country =
            new Language__c(Name = name, ShortLanguageName__c = shortName);
        return country;
    }

    public static Language__c insertRecord(String name, String shortName) {
        Language__c language = createRecord(name, shortName);
        insert language;
        return language;
    }

    /**
     * Test method to verify fetching of Language record with specified Name
     */
    static testmethod void testFetchInstanceWithName() {
        Language__c language1 = createRecord('AA', 'Afar');
        Language__c language2 = createRecord('LA', 'LATIN');
        insert new List<Language__c> {language1, language2};

        Test.startTest();
        Language__c language = LanguageWrapper.getInstanceWithName('LA');

        System.assert(language != null, 'Language not fetched properly');
        System.assertEquals('LATIN', language.ShortLanguageName__c);
        Test.stopTest();
    }
}