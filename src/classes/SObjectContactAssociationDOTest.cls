/**
 * Test class for the SObject Contact Association Data Model class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 * @author Aditi Satpute
 */
@isTest
public with sharing class SObjectContactAssociationDOTest {

    /**
     * Test creation of a new SObjectContactAssociation__c
     */
    static testMethod void testSObjectContactAssociationCreation() {

        Contact associate = TestUtils.createContact('TestLastName');
        Integer numberOfAccounts = 3;
        List<Id> accountIds = C.extractIds(TestUtils.createAccounts(numberOfAccounts));
        String accountApiName = Account.SObjectType.getDescribe().getName();
        SObjectContactAssociation__c association =
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                accountApiName,
                accountIds
            )[0];

        Test.startTest();
        insert association;
        Test.stopTest();

        // Get the SObjectContactAssociation__c to ensure the defaults have been set
        SObjectContactAssociation__c insertedAssociation =
            (SObjectContactAssociation__c)
                new SObjectContactAssociationSelector().getRecordById(association.Id);

        validateSObjectContactAssociation(
            insertedAssociation,
            accountApiName,
            numberOfAccounts,
            1,
            accountIds,
            associate.Id
        );
    }

    /**
     * Test creation of a new SObjectContactAssociation__c with more ids than can fit in one record
     */
    static testMethod void testSObjectContactAssociationCreationOverMultipleRecords() {

        Contact associate = TestUtils.createContact('TestLastName');
        Integer numberOfAccounts = 1701;
        List<Id> accountIds = C.extractIds(TestUtils.createAccounts(numberOfAccounts));
        List<Id> accountIdsForFirstRecord = C.convertListToId(
            C.getListSubset(0, SObjectContactAssociationDO.MAX_LENGTH_OF_ASSOCIATE_IDS, accountIds)
        );
        List<Id> accountIdsForSecondRecord = new List<Id>{accountIds.get(
            SObjectContactAssociationDO.MAX_LENGTH_OF_ASSOCIATE_IDS
        )};
        String accountApiName = Account.SObjectType.getDescribe().getName();
        List<SObjectContactAssociation__c> associations =
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                accountApiName,
                accountIds
            );

        Test.startTest();
        insert associations;
        Test.stopTest();

        SObjectContactAssociationSelector selector =
            new SObjectContactAssociationSelector();

        List<SObjectContactAssociation__c> insertedAssociations =
            selector.getAllForContact(associate.Id);
        validateSObjectContactAssociation(
            insertedAssociations[0],
            accountApiName,
            SObjectContactAssociationDO.MAX_LENGTH_OF_ASSOCIATE_IDS,
            1,
            accountIdsForFirstRecord,
            associate.Id
        );
        validateSObjectContactAssociation(
            insertedAssociations[1],
            accountApiName,
            1,
            2,
            accountIdsForSecondRecord,
            associate.Id
        );
    }

    /**
     * Test getting all SObjectContactAssociation__c for a given contact
     */
    static testMethod void testGettingSObjectContactAssociationForContact() {

        Contact associate = TestUtils.createContact('TestLastName');
        Integer numberOfRecords = 3;
        List<Account> accounts = TestUtils.createAccounts(numberOfRecords);
        List<Id> accountIds = C.extractIds(accounts);
        String accountApiName = Account.SObjectType.getDescribe().getName();
        List<Case> cases = TestUtils.createCasesForAccounts(accounts);
        List<Id> caseIds = C.extractIds(cases);
        String caseApiName = Case.SObjectType.getDescribe().getName();

        insert new List<SObjectContactAssociation__c>{
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                accountApiName,
                accountIds
            )[0],
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                caseApiName,
                caseIds
            )[0]
        };

        SObjectContactAssociationSelector selector =
            new SObjectContactAssociationSelector();

        Test.startTest();
        List<SObjectContactAssociation__c> insertedAssociations =
            selector.getAllForContact(associate.Id);
        Test.stopTest();

        validateSObjectContactAssociation(
            insertedAssociations[0],
            accountApiName,
            numberOfRecords,
            1,
            accountIds,
            associate.Id
        );
        validateSObjectContactAssociation(
            insertedAssociations[1],
            caseApiName,
            numberOfRecords,
            1,
            caseIds,
            associate.Id
        );
    }

    /**
     * Test getting SObjectApiName to Id Map
     */
    static testMethod void testGettingSObjectApiNameToIdMap() {

        Contact associate = TestUtils.createContact('TestLastName');
        Integer numberOfRecords = 3;
        List<Account> accounts = TestUtils.createAccounts(numberOfRecords);
        List<Id> accountIds = C.extractIds(accounts);
        String accountApiName = Account.SObjectType.getDescribe().getName();
        List<Case> cases = TestUtils.createCasesForAccounts(accounts);
        List<Id> caseIds = C.extractIds(cases);
        String caseApiName = Case.SObjectType.getDescribe().getName();

        insert new List<SObjectContactAssociation__c>{
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                accountApiName,
                accountIds
            )[0],
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                caseApiName,
                caseIds
            )[0]
        };

        Test.startTest();
        Map<String, Set<String>> objectToIdMap =
            SObjectContactAssociationDO.getMapOfIdsForContact(associate.Id);
        System.assertEquals(3, objectToIdMap.get(accountApiName).size());
        System.assertEquals(3, objectToIdMap.get(caseApiName).size());
    }

    /**
     * Test removing ids from an object
     */
    static testMethod void testRemoveIds() {

        Contact associate = TestUtils.createContact('TestLastName');
        Integer numberOfAccounts = 1701;
        List<Id> accountIds = C.extractIds(TestUtils.createAccounts(numberOfAccounts));
        List<Id> idsToRemove = new List<Id>{
            accountIds[0],
            accountIds[1],
            accountIds[2]
        };
        String accountApiName = Account.SObjectType.getDescribe().getName();
        List<SObjectContactAssociation__c> associations =
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                accountApiName,
                accountIds
            );
        System.assertEquals(2, associations.size());

        insert associations;

        SObjectContactAssociationSelector selector =
            new SObjectContactAssociationSelector();

        Test.startTest();
        SObjectContactAssociationDO.removeIds(associate.Id, accountApiName, idsToRemove);
        Test.stopTest();

        List<SObjectContactAssociation__c> insertedAssociations =
            selector.getAllForContact(associate.Id);
        System.assertEquals(1, insertedAssociations.size());
        List<Id> foundIdsList = C.convertListToId(insertedAssociations[0].AssociatedIds__c.split(','));
        Set<Id> foundIdsSet = new Set<Id>();
        foundIdsSet.addAll(foundIdsList);
        System.assert(foundIdsSet.add(idsToRemove[0]));
        System.assert(foundIdsSet.add(idsToRemove[1]));
        System.assert(foundIdsSet.add(idsToRemove[2]));
    }

    /**
     * Test deleting assignments for a given object
     */
    static void testDeletingObjectAssignations() {

        Contact associate = TestUtils.createContact('TestLastName');
        Integer numberOfRecords = 3;
        List<Account> accounts = TestUtils.createAccounts(numberOfRecords);
        List<Id> accountIds = C.extractIds(accounts);
        String accountApiName = Account.SObjectType.getDescribe().getName();
        List<Case> cases = TestUtils.createCasesForAccounts(accounts);
        List<Id> caseIds = C.extractIds(cases);
        String caseApiName = Case.SObjectType.getDescribe().getName();

        insert new List<SObjectContactAssociation__c>{
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                accountApiName,
                accountIds
            )[0],
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                caseApiName,
                caseIds
            )[0]
        };

        SObjectContactAssociationSelector selector =
            new SObjectContactAssociationSelector();

        Test.startTest();
        SObjectContactAssociationDO.removeAllObjects(
            associate.Id,
            new List<String>{accountApiName}
        );
        Test.stopTest();

        System.assertEquals(
            0,
            selector.getAllForContactAndObject(
                associate.Id,
                new List<String>{accountApiName}
            ).size()
        );

        selector.resetQueryClauses();
        System.assertEquals(
            1,
            selector.getAllForContactAndObject(
                associate.Id,
                new List<String>{caseApiName}
            ).size()
        );
    }

    /**
     * Test validating and removing bad associations due to deleted object
     */
    static testMethod void testDeletingInvalidAssociationsDueToDeletedObject() {

        Contact associate = TestUtils.createContact('TestLastName');
        Integer numberOfRecords = 3;
        List<Account> accounts = TestUtils.createAccounts(numberOfRecords);
        List<Id> accountIds = C.extractIds(accounts);
        String accountApiName = Account.SObjectType.getDescribe().getName();
        String badApiName = 'BADNAME';

        List<SObjectContactAssociation__c> associations = new List<SObjectContactAssociation__c>{
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                accountApiName,
                accountIds
            )[0],
            SObjectContactAssociationDO.createNewRecords(
                associate.Id,
                badApiName,
                accountIds
            )[0]
        };

        insert associations;

        SObjectContactAssociationSelector selector =
            new SObjectContactAssociationSelector();

        Test.startTest();
        SObjectContactAssociationDO.deleteInvalidAssociations(associations);
        Test.stopTest();

        System.assertEquals(
            1,
            selector.getAllForContactAndObject(
                associate.Id,
                new List<String>{accountApiName}
            ).size()
        );

        selector.resetQueryClauses();
        System.assertEquals(
            0,
            selector.getAllForContactAndObject(
                associate.Id,
                new List<String>{badApiName}
            ).size()
        );
    }

    /**
     * Test fetching associated records with Objects having escaped name
     */
    static testMethod void testFetchObjectsWithEscapedName() {

        Contact associate = TestUtils.createContact('TestLastName');
        List<Account> accounts = TestUtils.createAccounts(3);
        List<Id> accountIds = C.extractIds(accounts);
        List<Contact> contacts = TestUtils.createContacts(2);
        List<Id> contactIds = C.extractIds(contacts);

        String accountApiName = Account.SObjectType.getDescribe().getName();
        String contactApiName = Contact.SObjectType.getDescribe().getName();
        String badApiName = 'Account\',\'Contact';

        List<SObjectContactAssociation__c> associations =
            new List<SObjectContactAssociation__c> {
                SObjectContactAssociationDO.createNewRecords(
                    associate.Id,
                    accountApiName,
                    accountIds
                )[0],
                SObjectContactAssociationDO.createNewRecords(
                    associate.Id,
                    contactApiName,
                    accountIds
                )[0]
            };
        insert associations;

        SObjectContactAssociationSelector selector =
            new SObjectContactAssociationSelector();

        Test.startTest();

        // Verify that one record is fetched from database for Account api name
        System.assertEquals(
            1,
            selector.getAllForContactAndObject(
                associate.Id,
                new List<String> {accountApiName}
            ).size()
        );
        selector.resetQueryClauses();

        // Verify that one record is fetched from database for Contact api name
        System.assertEquals(
            1,
            selector.getAllForContactAndObject(
                associate.Id,
                new List<String>{contactApiName}
            ).size()
        );
        selector.resetQueryClauses();

        // Verify that no records are fetched from database for Bad api name
        System.assertEquals(
            0,
            selector.getAllForContactAndObject(
                associate.Id,
                new List<String>{badApiName}
            ).size()
        );
        selector.resetQueryClauses();

        // Verify that all records are fetched from database for specified api list
        System.assertEquals(
            2,
            selector.getAllForContactAndObject(
                associate.Id,
                new List<String>{
                    accountApiName,
                    contactApiName,
                    badApiName
                }
            ).size()
        );
        Test.stopTest();
     }

    /**
     * Validate a SObjectContactAssociation__c
     */
    private static void validateSObjectContactAssociation(
        SObjectContactAssociation__c association,
        String objectName,
        Integer numberOfRecords,
        Integer instanceNumber,
        List<Id> recordIds,
        Id associateId
    ) {

        System.assertEquals(
            instanceNumber,
            Integer.valueOf(association.Instance__c)
        );
        System.assertEquals(
            numberOfRecords,
            Integer.valueOf(association.NumberOfRecords__c)
        );
        System.assertEquals(
            recordIds,
            association.AssociatedIds__c.split(',', 0)
        );
        System.assertEquals(
            objectName,
            association.SObjectApiName__c
        );
        System.assertEquals(
            associateId,
            association.Contact__c
        );
    }

    /**
     * Test creating unique key string
     */
    static testMethod void testUniqueKeyString() {

        Contact associate = TestUtils.createContact('TestLastName');
        List<Id> accountIds = C.extractIds(TestUtils.createAccounts(3));
        String accountApiName = Account.SObjectType.getDescribe().getName();
        SObjectContactAssociation__c association =
            SObjectContactAssociationDO.createNew(
                associate.Id,
                accountApiName,
                accountIds,
                1
            );

        String testKey = associate.Id + '_' + 1 + '_' + accountApiName;
        SObjectContactAssociationDO domain = new SObjectContactAssociationDO();
        String uniqueKey = domain.createUniqueKey(association);
        System.assertEquals(testKey, uniqueKey);
    }
}