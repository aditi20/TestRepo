/**
 * Test class for the UnitOfWork
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies (odavies@grameenfoundation.org)
 */
@isTest
public with sharing class UnitOfWorkTest {

    /**
     * Test constructing a unit of work with the SObjectType
     */
    static testMethod void testUnitOfWorkConstructionWithSObjectType() {
        UnitOfWork unitOfWork = setUpBasic();
        validateUnitOfWorkConstruction(unitOfWork);
    }

    /**
     * Test constructing a unit of work with a String
     */
    static testMethod void testUnitOfWorkConstructionWithString() {

        List<String> objectsToAdd = new List<String>{
            Contact.SObjectType.getDescribe().getName(),
            Account.SObjectType.getDescribe().getName(),
            Contact.SObjectType.getDescribe().getName()
        };
        UnitOfWork unitOfWork = new UnitOfWork(objectsToAdd);
        validateUnitOfWorkConstruction(unitOfWork);
    }

    /**
     * Test adding to the insert order
     */
    static testMethod void testAddingToInsertOrder() {
        UnitOfWork unitOfWork = setUpBasic();
        unitOfWork.addToInsertionOrder(Account.SObjectType);
        System.assertEquals(
            2,
            unitOfWork.numberOfLevelsInInsertionOrder.get(
                Account.SObjectType.getDescribe().getName()
            )
        );
        System.assertEquals(
            unitOfWork.generateKey(
                Account.SObjectType.getDescribe().getName(), 2
            ),
            unitOfWork.insertionOrder[3]
        );
    }

    /**
     * Test inserting records
     */
    static testMethod void testInsertionSuccess() {

        String accountName = 'accountName';
        String managerName = 'managerName';
        String middleManagerName = 'middleManagerName';
        String staffName = 'staffName';

        List<String> objectsToAdd = new List<String>{
            Account.SObjectType.getDescribe().getName(),
            Contact.SObjectType.getDescribe().getName(),
            Contact.SObjectType.getDescribe().getName(),
            Contact.SObjectType.getDescribe().getName()
        };
        UnitOfWork unitOfWork = new UnitOfWork(objectsToAdd);

        Account parentAcount = new Account(Name = accountName);
        Contact manager = new Contact(LastName = managerName);
        Contact middleManager = new Contact(LastName = middleManagerName);
        Contact staff = new Contact(LastName = staffName);

        Test.startTest();
        unitOfWork.addToInsertList(parentAcount);
        unitOfWork.addToInsertList(manager, Contact.AccountId, parentAcount);
        unitOfWork.addToInsertList(middleManager, Contact.ReportsToId, manager, 2);
        unitOfWork.addToInsertList(staff, Contact.ReportsToId, middleManager, 3);
        unitOfWork.commitWork();
        Test.stopTest();

        List<Account> savedAccount = [SELECT Id, Name FROM Account WHERE Name = :accountName];
        List<Contact> savedManager = getContact(managerName);
        List<Contact> savedMiddleManager = getContact(middleManagerName);
        List<Contact> savedStaff = getContact(staffName);

        System.assertEquals(1, savedAccount.size());
        System.assertEquals(1, savedManager.size());
        System.assertEquals(1, savedMiddleManager.size());
        System.assertEquals(1, savedStaff.size());

        System.assertEquals(
            savedAccount[0].Id,
            savedManager[0].AccountId
        );
        System.assertEquals(
            savedManager[0].Id,
            savedMiddleManager[0].ReportsToId
        );
        System.assertEquals(
            savedMiddleManager[0].Id,
            savedStaff[0].ReportsToId
        );
    }

    private static List<Contact> getContact(String lastName) {
        return [
            SELECT
                Id,
                Name,
                ReportsToId,
                AccountId
            FROM
                Contact
            WHERE
                LastName = :lastName
        ];
    }

    /**
     * Test error throwing when inserting records that already have an id
     */
    static testMethod void testInsertWithId() {
        Contact testContact = new Contact(LastName = 'LastName');
        insert testContact;

        UnitOfWork uow = new UnitOfWork(
            new List<String>{
                Contact.SObjectType.getDescribe().getName()
            }
        );
        try {
            uow.addToInsertList(testContact);
            System.assert(false);
        } catch (UnitOfWork.UnitOfWorkException uowe) {
            System.assertEquals(
                System.Label.ONLY_NEW_RECORDS_INSERTED,
                uowe.getMessage()
            );
        }
    }

    /**
     * Test error thrown when an invalid object is added to the insert list
     */
    static testMethod void testInsertWithInvalidObject() {
        Contact testContact = new Contact(LastName = 'LastName');

        UnitOfWork uow = new UnitOfWork(
            new List<String>{
                Account.SObjectType.getDescribe().getName()
            }
        );
        try {
            uow.addToInsertList(testContact);
            System.assert(false);
        } catch (UnitOfWork.UnitOfWorkException uowe) {
            System.assertEquals(
                String.format(
                    System.Label.OBJECT_NOT_SUPPORTED,
                    new List<String>{
                        Contact.SObjectType.getDescribe().getName(),
                        '1'
                    }
                ),
                uowe.getMessage()
            );
        }
    }

    /**
     * Test catching the parent record not having an ID
     */
    static testMethod void testCatchBadRelationshipResolutionNoId() {
        Account acc = new Account(Name = 'account name');
        Contact manager = new Contact(LastName = 'Manager');
        UnitOfWork.Relationship relationship = new UnitOfWork.Relationship(
            acc,
            Contact.AccountId,
            manager
        );
        try {
            relationship.resolveRelationship();
            System.assert(false);
        }  catch (UnitOfWork.UnitOfWorkException uowe) {
            System.assertEquals(
                String.format(
                    System.Label.PARENT_RECORD_REQUIRES_ID,
                    new List<String>{
                        Contact.AccountId.getDescribe().getName(),
                        Account.SObjectType.getDescribe().getName()
                    }
                ),
                uowe.getMessage()
            );
        }
    }

    /**
     * Test catching that the relationship field is not of type relationship
     */
    static testMethod void testCatchBadRelationshipResolutionInvalidField() {
        Account testAccount = new Account(Name = 'account name');
        Contact manager = new Contact(LastName = 'Manager');
        insert testAccount;
        UnitOfWork.Relationship relationship = new UnitOfWork.Relationship(
            manager,
            Account.Site,
            testAccount
        );
        try {
            relationship.resolveRelationship();
            System.assert(false);
        }  catch (UnitOfWork.UnitOfWorkException uowe) {
            System.assertEquals(
                String.format(
                    System.Label.RELATIONSHIP_FIELD_INVALID,
                    new List<String>{
                        Account.Site.getDescribe().getName(),
                        Contact.SObjectType.getDescribe().getName()
                    }
                ),
                uowe.getMessage()
            );
        }
    }

    /**
     * Test that an object cannot be inserted if the user doesn't have permission
     */
    static testMethod void testInsertDenied() {
        Contact manager = new Contact(LastName = 'Manager');
        UnitOfWork unitOfWork = new UnitOfWork(new List<Schema.SObjectType>{
            Contact.SObjectType
        });
        unitOfWork.addToInsertList(manager);
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            try {
                Test.startTest();
                unitOfWork.commitWork();
                System.assert(false, 'Should not get here as User doesn\'t have insert ability');
            }  catch (GenericObjectCreator.GenericObjectCreatorException uowe) {
                System.assertEquals(
                    String.format(
                        System.Label.OBJECT_CAN_NOT_BE_CREATED,
                        new List<String>{
                            Contact.SObjectType.getDescribe().getName()
                        }
                    ),
                    uowe.getMessage()
                );
            }
        }
    }

    /**
     * Test that an object cannot be inserted if the user doesn't have permission
     */
    static testMethod void testUpdateDenied() {
        Contact manager = new Contact(LastName = 'Manager');
        insert manager;
        UnitOfWork unitOfWork = new UnitOfWork();
        unitOfWork.addToUpdateOrder(new List<Schema.SObjectType>{
            Contact.SObjectType
        });
        manager.LastName = 'A New Last Name';
        unitOfWork.addToUpdateList(manager);
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            try {
                Test.startTest();
                unitOfWork.commitWork();
                System.assert(false, 'Should not get here as User doesn\'t have insert ability');
            }  catch (GenericObjectCreator.GenericObjectCreatorException uowe) {
                System.assertEquals(
                    String.format(
                        System.Label.OBJECT_CAN_NOT_BE_UPDATE,
                        new List<String>{
                            Contact.SObjectType.getDescribe().getName()
                        }
                    ),
                    uowe.getMessage()
                );
            }
        }
    }

    /**
     * Test that the master rollback removes all objects
     */
    static testMethod void setMasterRollback() {
        List<Schema.SObjectType> objectList =
            new List<Schema.SObjectType>{
                Contact.SObjectType
            };
        UnitOfWork uow = new UnitOfWork(objectList);
        uow.addToInsertList(new Contact(LastName='Contact1'));
        uow.commitWork();
        uow.reset();
        uow.addToInsertionOrder(objectList);
        uow.addToInsertList(new Contact(LastName='Contact2'));
        uow.commitWork();
        uow.reset();
        uow.addToInsertionOrder(objectList);
        uow.addToInsertList(new Contact(LastName='Contact3'));
        uow.commitWork();
        uow.reset();
        uow.addToInsertionOrder(objectList);
        uow.addToInsertList(new Contact(LastName='Contact4'));
        uow.commitWork();
        uow.reset();
        uow.rollbackToMaster();
        System.assertEquals(
            0,
            [SELECT Id FROM Contact].size()
        );
    }

    /**
     * Set up standard unit of work for tests
     */
    private static UnitOfWork setUpBasic() {
        List<Schema.SObjectType> objectsToAdd = new List<Schema.SObjectType>{
            Contact.SObjectType,
            Account.SObjectType,
            Contact.SObjectType
        };
        return new UnitOfWork(objectsToAdd);
    }

    private static void validateUnitOfWorkConstruction(UnitOfWork unitOfWork) {
        System.assertEquals(
            2,
            unitOfWork.numberOfLevelsInInsertionOrder.get(
                Contact.SObjectType.getDescribe().getName()
            )
        );
        System.assertEquals(
            1,
            unitOfWork.numberOfLevelsInInsertionOrder.get(
                Account.SObjectType.getDescribe().getName()
            )
        );
        System.assertEquals(
            unitOfWork.generateKey(
                Contact.SObjectType.getDescribe().getName(), 1
            ),
            unitOfWork.insertionOrder[0]
        );
        System.assertEquals(
            unitOfWork.generateKey(
                Account.SObjectType.getDescribe().getName(), 1
            ),
            unitOfWork.insertionOrder[1]
        );
        System.assertEquals(
            unitOfWork.generateKey(
                Contact.SObjectType.getDescribe().getName(), 2
            ),
            unitOfWork.insertionOrder[2]
        );
    }
}