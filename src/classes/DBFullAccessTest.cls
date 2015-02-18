/**
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public with sharing class DBFullAccessTest {

    static testMethod void TestDMLOperations() {

        User standardUser =  TestUtils.getStandardUser();

        // Contact without account shall be private by default.
        Contact privateContact = new Contact(Lastname ='Doe');
        insert privateContact;

        System.runAs(standardUser) {
            Test.startTest();
            //Test Query
            List<Contact> contacts = (List<Contact>)DBFullAccess.QuerySObject('SELECT Id FROM Contact WHERE Id=\''+ privateContact.Id+'\' limit 1');
            //I should be able to query the contact even though the contact is private.
            System.assertEquals(1,contacts.size());

            //Test UPDATE
            privateContact.LastName = 'Doe2';
            DBFullAccess.UpdateSObject(privateContact);
            contacts = (List<Contact>)DBFullAccess.QuerySObject('SELECT Id,LastName FROM Contact WHERE Id=\''+ privateContact.Id+'\' limit 1');
            //The contact should be updated.
            System.assertEquals('Doe2',contacts[0].LastName);

            //Test INSERT
            Contact testContact = new Contact(Lastname ='smith');
            DBFullAccess.InsertSObject(testContact);
            //The contact should be inserted.
            System.assertNotEquals(null,testContact.id);

            //Test DELETE
            DBFullAccess.DeleteSObject(testContact);
            contacts = (List<Contact>)DBFullAccess.QuerySObject('SELECT Id,LastName FROM Contact WHERE Id=\''+ testContact.Id+'\' limit 1');
            //The contact should be deleted.
            System.assertEquals(0,contacts.size());

            //Test UPSERT
            testContact = new Contact(Lastname ='smitha');
            DBFullAccess.UpsertSObject(testContact);
            contacts = (List<Contact>)DBFullAccess.QuerySObject('SELECT Id,LastName FROM Contact WHERE Id=\''+ testContact.Id+'\' limit 1');
            //The contact should be inserted again.
            System.assertEquals(1,contacts.size());
            testContact.Birthdate = Date.today();
            DBFullAccess.UpsertSObject(testContact);
            contacts = (List<Contact>)DBFullAccess.QuerySObject('SELECT Id,LastName,BirthDate FROM Contact WHERE Id=\''+ testContact.Id+'\' limit 1');
            System.assertEquals(testContact.Birthdate,contacts[0].Birthdate);

            //With <LIST> AS PARAMETER.

            //Test UPDATE
            privateContact.LastName = 'Doe3';
            testContact.LastName = 'Smith123';
            DBFullAccess.UpdateSObject(new List<Contact>{privateContact,testContact});
            contacts = (List<Contact>)DBFullAccess.QuerySObject('SELECT Id,LastName FROM Contact WHERE Id=\''+ privateContact.Id+'\' or Id=\''+ testContact.id +'\' limit 2');
            //The contact should be updated.
            System.assertEquals('Doe3',contacts[0].LastName);
            System.assertEquals('Smith123',contacts[1].LastName);

            //Test INSERT
            Contact testContact2 = new Contact(Lastname ='smith3');
            Contact testContact3 = new Contact(Lastname ='smith4');
            DBFullAccess.InsertSObject(new List<Contact>{testContact2,testContact3});
            //The contact should be inserted.
            System.assertNotEquals(null,testContact2.id);
            System.assertNotEquals(null,testContact3.id);

            //Test DELETE
            DBFullAccess.DeleteSObject(new List<Contact>{testContact2,testContact3});
            contacts = (List<Contact>)DBFullAccess.QuerySObject('SELECT Id,LastName FROM Contact WHERE Id=\''+ testContact2.Id+'\' or Id=\''+ testContact3.id +'\'');
            //The contact should be deleted.
            System.assertEquals(0,contacts.size());

            //Test UPSERT
            Contact testContact4 = new Contact(Lastname ='smith4');
            Contact testContact5 = new Contact(Lastname ='smith5');
            DBFullAccess.UpsertSObject(new List<Contact>{testContact4,testContact5});
            contacts = (List<Contact>)DBFullAccess.QuerySObject('SELECT Id,LastName FROM Contact WHERE Id=\''+ testContact4.Id+'\' or Id=\''+ testContact5.id +'\'');
            //The contact should be inserted again.
            System.assertEquals(2,contacts.size());
            testContact4.Birthdate = Date.today();
            testContact5.Birthdate = Date.today();
            DBFullAccess.UpsertSObject(new List<Contact>{testContact4,testContact5});
            contacts = (List<Contact>)DBFullAccess.QuerySObject('SELECT Id,LastName,BirthDate FROM Contact WHERE Id=\''+ testContact4.Id+'\' or Id=\''+ testContact5.id +'\'');
            System.assertEquals(testContact4.Birthdate,contacts[0].Birthdate);
            System.assertEquals(testContact5.Birthdate,contacts[1].Birthdate);
            Test.stopTest();
        }
    }
}