/**
 * Test class for the ISOCountryWrapper
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class ISOCountryWrapperTest {

    public static ISO_Country__c createRecord(String name, String shortName) {
        ISO_Country__c country =
            new ISO_Country__c(Name = name, ShortName__c = shortName);
        return country;
    }

    public static ISO_Country__c insertRecord(String name, String shortName) {
        ISO_Country__c country = createRecord(name, shortName);
        insert country;
        return country;
    }

    /**
     * Test method to verify fetching of ISO_Country record with specified Name
     */
    static testmethod void testFetchInstanceWithName() {
        ISO_Country__c country1 = createRecord('KE', 'KENYA');
        ISO_Country__c country2 = createRecord('IT', 'ITALY');
        insert new List<ISO_Country__c> {country1, country2};

        Test.startTest();
        ISO_Country__c country = ISOCountryWrapper.getInstanceWithName('IT');

        System.assert(country != null, 'ISO Country not fetched properly');
        System.assertEquals('ITALY', country.ShortName__c);
        Test.stopTest();
    }
}