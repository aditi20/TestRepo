/**
 * Class to test MobileUserDetailController
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Ernesto Quesada - equesada@altimetrik.com
 */
 @isTest
public with sharing class MobileUserDetailControllerTest {

    /**
     * Check that controller loads correctly when all objects are valid
     */
    static testMethod void testLoadWrapper() {

        // Preconditions
        MobileUserPagePreconditions preconditions = new MobileUserPagePreconditions();

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', preconditions.mobileUser.Id);
        MobileUserDetailController controller = new MobileUserDetailController();
        controller.getSObjectAssignmentWrappers();
        Test.stopTest();

        System.assertEquals(
            1,
            controller.assignedRecordsWrapper.size(),
            'There should be only 1 wrapper'
        );
        System.assertEquals(
            preconditions.accountLabel,
            controller.assignedRecordsWrapper[0].sobjectNameLabel,
            'This should be an account assignment'
        );
        System.assertEquals(
            2000,
            controller.assignedRecordsWrapper[0].numberOfAssociations,
            'There should be 2000 records'
        );
    }

    /**
     * Test loading the page with no wrappers
     */
    static testMethod void testLoadWithNoAssignedRecords() {

        TestUtils.Surveyor surveyor = TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', surveyor.user.Id);
        MobileUserDetailController controller = new MobileUserDetailController();
        controller.getSObjectAssignmentWrappers();
        Test.stopTest();

        System.assertEquals(
            0,
            controller.assignedRecordsWrapper.size(),
            'There should no wrapper'
        );
    }

    /**
     * Test load wrappers with a deleted object as one of the wrappers
     */
    static testMethod void testLoadWithDeletedObjectName() {

        TestUtils.Surveyor surveyor = TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);
        Integer numberOfRecords = 3;
        List<Id> accountIds = C.extractIds(TestUtils.createAccounts(numberOfRecords));
        String accountName = Account.SObjectType.getDescribe().getName();
        String accountLabel = Account.SObjectType.getDescribe().getLabel();
        String deletedObjectName = 'BADNAME';
        insert new List<SObjectContactAssociation__c>{
            SObjectContactAssociationDO.createNew(
                surveyor.theContact.Id,
                accountName,
                accountIds
            ),
            SObjectContactAssociationDO.createNew(
                surveyor.theContact.Id,
                deletedObjectName,
                accountIds
            )
        };

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', surveyor.user.Id);
        MobileUserDetailController controller = new MobileUserDetailController();
        controller.getSObjectAssignmentWrappers();
        Test.stopTest();

        System.assertEquals(
            1,
            controller.assignedRecordsWrapper.size(),
            'There should be only 1 wrapper'
        );
        System.assertEquals(
            accountLabel,
            controller.assignedRecordsWrapper[0].sobjectNameLabel,
            'This should be an account assignment'
        );
        System.assertEquals(
            numberOfRecords,
            controller.assignedRecordsWrapper[0].numberOfAssociations,
            'There should be 3 records'
        );
    }

    /**
     * Test to delete an assignment
     */
    static testMethod void testDeleteAssignment() {

        // Preconditions
        MobileUserPagePreconditions preconditions = new MobileUserPagePreconditions();


        ApexPages.currentPage().getParameters().put('id', preconditions.mobileUser.Id);
        MobileUserDetailController controller = new MobileUserDetailController();

        // Run test
        controller.assignedObjectSelected = preconditions.accountName;
        controller.deleteAssignment();

        // Assertions
        System.assertEquals(
            0,
            controller.assignedRecordsWrapper.size(),
            'There should not be any wrapper'
        );

    }

    /**
     * Class to keep the preconditions data for the controller test cases
     */
    private Class MobileUserPagePreconditions {
        Contact contactToAssign;
        List<Id> accountIds;
        String accountName = Account.SObjectType.getDescribe().getName();
        String accountLabel = Account.SObjectType.getDescribe().getLabel();
        List<SObjectContactAssociation__c> associations;
        Mobile_User__c mobileUser;

        public MobileUserPagePreconditions() {
            TestUtils.Surveyor surveyor = TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);
            this.mobileUser = surveyor.user;
            this.contactToAssign = surveyor.theContact;
            Integer numberOfAccounts = 2000;
            this.accountIds = C.extractIds(TestUtils.createAccounts(numberOfAccounts));
            this.associations = SObjectContactAssociationDO.createNewRecords(
                contactToAssign.Id,
                accountName,
                accountIds
            );
            insert associations;
        }
    }
}
