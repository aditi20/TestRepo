/**
 * Test class for the ContactSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
@isTest
public with sharing class ContactSelectorTest {

    /**
     * Test method to verify fetching of Contact records
     */
    static testmethod void testFetchAllWithNameNotNull() {

        List<Contact> contactList = TestUtils.createContacts(5);

        Test.startTest();
        List<Contact> contactRetrieved = new ContactSelector().getAllWithNameNotNull();
        Test.stopTest();

        // SurveyVersion records are fetched properly
        System.assertEquals(
            5,
            contactRetrieved.size()
        );
    }
}