/*
 * Test class for the controller of the Object Assinment page
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Ernesto Quesada - equesada@altimetrik.com
 * @author Alejandro De Gregorio - adegregorio@altimetrik.com
 */
@isTest
public class ObjectAssignmentControllerTest {

    /**
     * Test the validation of the contact id when the page is loaded
     */
    static testMethod void testContactValidationOnLoad() {

        // Given a wrong contact id
        ApexPages.currentPage().getParameters().put(
            ObjectAssignmentController.PARAM_CONTACT_ID,
            'someWrongId'
        );

        Test.startTest();

        try {

            // When the page is loaded
            ObjectAssignmentController controller = new ObjectAssignmentController();
            System.assert(false, 'An exception should be thrown because of the wrong id');
        } catch(Exception e) {

            // Then an exception is thrown
            System.assert(
                e.getMessage().contains('Invalid id'),
                'The exception error should say Invalid id'
            );
        }
        Test.stopTest();
    }

    /**
     * Test the load of the object filtering the already assigned objects
     */
    static testMethod void testFilterObjectsList() {

        // Given some assigned objects
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(5);
        preconditions.assignRecords(
            Account.sObjectType.getDescribe().getName(),
            new List<Id>{preconditions.accounts[0].Id, preconditions.accounts[1].Id}
        );
        preconditions.createContacts(5);
        preconditions.assignRecords(
            Contact.sObjectType.getDescribe().getName(),
            C.extractIds(preconditions.contacts)
        );

        // When the page loads the objects for the select list
        Test.startTest();
        ObjectAssignmentController controller = preconditions.initControllerForCreate();
        Test.stopTest();

        // Then the already assigned objects should not be in the list
        Set<String> objectsToSelect = getValuesSet(controller.orgObjects);
        System.assert(
            !objectsToSelect.contains(Account.sObjectType.getDescribe().getName()),
            'The Account object is shown in the list but should be filtered'
        );
        System.assert(
            !objectsToSelect.contains(Contact.sObjectType.getDescribe().getName()),
            'The Contact object is shown in the list but should be filtered'
        );
    }

    /**
     * Test successful save an object assignment
     */
    static testMethod void saveObjectAssignment() {

        // Given some accounts selected and a contact
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(2);
        ObjectAssignmentController controller = preconditions.initControllerForCreate();
        controller.associatedIds = preconditions.accounts[0].Id + ',' + preconditions.accounts[1].Id;
        controller.selectedObject = Account.sObjectType.getDescribe().getName();

        Test.startTest();

        // When the changes are saved
        controller.save();
        Test.stopTest();

        // Then the associations are created
        SObjectContactAssociation__c assignedObject = [
            SELECT
                Name,
                AssociatedIds__c,
                SObjectApiName__c,
                Contact__c
            FROM SObjectContactAssociation__c
            LIMIT 1
        ];
        System.assertEquals(
            String.join(
                new List<Id>{preconditions.accounts[0].Id, preconditions.accounts[1].Id},
                ','
            ),
            assignedObject.AssociatedIds__c
        );
        System.assertEquals(
            Account.sObjectType.getDescribe().getName(),
            assignedObject.SObjectApiName__c
        );
        System.assertEquals(
            preconditions.userWrapper.contactId,
            assignedObject.Contact__c
        );
    }

    /**
     * Test the validation of the selected object when saving
     */
    static testMethod void testSelectedObjectValidationOnSave() {

        // Given a contact, an empty object name and some ids
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(2);
        ObjectAssignmentController controller = preconditions.initControllerForCreate();
        controller.associatedIds = preconditions.accounts[0].Id + ',' + preconditions.accounts[1].Id;
        controller.selectedObject = '';

        Test.startTest();
        controller.save();
        Test.stopTest();

        // Then an error is added to the page
        System.assert(ApexPages.hasMessages(), 'The page should have messages');
        System.assertEquals(
            ApexPages.getMessages()[0].getSummary(),
            System.Label.RECORDS_ASSIGNMENT_SELECT_OBJECT_ERROR
        );
    }

    /**
     * Test the validation of the assigned ids when saving
     */
    static testMethod void testAssignedIdsValidationOnSave() {

        // Given a contact, a selected object and missing ids
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(2);
        ObjectAssignmentController controller = preconditions.initControllerForCreate();
        controller.selectedObject = Account.sObjectType.getDescribe().getName();
        controller.associatedIds = '';

        Test.startTest();

        // When the save action is ran
        controller.save();
        Test.stopTest();

        // Then an error is added to the page
        System.assert(ApexPages.hasMessages(), 'The page should have messages');
        System.assertEquals(
            ApexPages.getMessages()[0].getSummary(),
            System.Label.RECORDS_ASSIGNMENT_NO_RECORDS_SELECTED_ERROR
        );
    }

    /**
     * Test fetch the records of an object
     */
    static testMethod void getRecordsTest() {

        // Given some accounts and a contact
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(2);
        ObjectAssignmentController controller = preconditions.initControllerForCreate();

        Test.startTest();

        // When the records are fetched
        List<Sobject> records = (List<Sobject>) JSON.deserialize(
            ObjectAssignmentController.getNonAssignedRecords(
                Account.sObjectType.getDescribe().getName(),
                '',
                '[{"operator": "Equals", "field" : "", "value": ""}]'
            ),
            List<Sobject>.class
        );
        Test.stopTest();

        // Then all the records are returned
        List<Account> accountsInDB = [SELECT Name FROM Account ORDER BY Name];
        System.AssertEquals(accountsInDB.size(), records.size());
        System.AssertEquals(accountsInDB[0].Id, records[0].Id);
        System.AssertEquals(accountsInDB[1].Id, records[1].Id);
        System.AssertEquals(accountsInDB[0].Name, records[0].get('Name'));
        System.AssertEquals(accountsInDB[1].Name, records[1].get('Name'));
    }

    /**
     * Test filter the records of an object
     */
    static testMethod void getRecordsWithFilterTest() {

        // Given some accounts and a contact
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(3);
        ObjectAssignmentController controller = preconditions.initControllerForCreate();

        List<Account> accountsInDB = [SELECT Name FROM Account ORDER BY Name];

        Test.startTest();

        // When the records are fetched
        List<Sobject> records = (List<Sobject>) JSON.deserialize(
            ObjectAssignmentController.getNonAssignedRecords(
                Account.sObjectType.getDescribe().getName(),
                '',
                '[{"operator" : "Equals", "field" : "Name", "value" : "' + accountsInDB[0].Name +'"}]'
            ),
            List<Sobject>.class
        );
        Test.stopTest();

        // The filtered record is returned

        System.AssertEquals(1, records.size());
        System.AssertEquals(accountsInDB[0].Id, records[0].Id);
    }

    /**
     * Test multiple filters to get the records of an object
     */
    static testMethod void getRecordsWithMultipleFilterTest() {

        // Given some accounts and a contact
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(10);
        ObjectAssignmentController controller = preconditions.initControllerForCreate();

        List<Account> accountsInDB = [SELECT Name,Sic FROM Account ORDER BY Name];
        accountsInDB[0].Sic = 'ThisIsASic';
        update accountsInDB;


        Test.startTest();

        // When the records are fetched
        List<Sobject> records = (List<Sobject>) JSON.deserialize(
            ObjectAssignmentController.getNonAssignedRecords(
                Account.sObjectType.getDescribe().getName(),
                '',
                '[{"operator" : "Equals", "field" : "Name", "value" : "' + accountsInDB[0].Name +'"}, '+
                '{"operator" : "Equals", "field" : "Sic", "value" : "' + accountsInDB[0].Sic +'"}]'
            ),
            List<Sobject>.class
        );
        Test.stopTest();

        // The filtered record is returned
        System.AssertEquals(1, records.size());
        System.AssertEquals(accountsInDB[0].Id, records[0].Id);
    }

    /**
     * Test that if there are more than 250 records to show it's limited
     */
    static testMethod void testRecordsAmountLimit() {

        // Given 300 records
        List<Account> accounts = TestUtils.createAccounts(300);
        accounts = [
            SELECT
                Id,
                Name
            FROM
                Account
            WHERE
                Id IN :accounts
            ORDER BY
                Name
        ];
        TestUtils.Surveyor surveyor = TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);
        ApexPages.currentPage().getParameters().put('contactId', surveyor.theContact.Id);
        ObjectAssignmentController controller = new ObjectAssignmentController();

        Test.startTest();
        // When the records are fetched
        List<Account> records = (List<Account>)JSON.deserialize(
            ObjectAssignmentController.getNonAssignedRecords(
                Account.sObjectType.getDescribe().getName(),
                '',
                '[{"operator": "Equals", "field" : "", "value": ""}]'
            ),
            List<Account>.class
        );
        Test.stopTest();

        // Then only the top 250 recors are fetched
        System.assertEquals(250, records.size());
        for (Integer i = 0; i < 250; i ++) {
            System.assertEquals(accounts[i].Id, records[i].Id);
        }
    }

    /**
     * Test fetch only the non assigned records
     */
    static testMethod void testGetNonAssignedRecords() {

        // Given some accounts and two of them assigned to a contact
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(8);
        preconditions.assignRecords(
            Account.sObjectType.getDescribe().getName(),
            new List<Id>{preconditions.accounts[0].Id, preconditions.accounts[1].Id}
        );
        preconditions.initControllerForEdit();

        Test.startTest();

        // When it asks for the records to assign
        List<Account> records = (List<Account>) JSON.deserialize(
            ObjectAssignmentController.getNonAssignedRecords(
                Account.sObjectType.getDescribe().getName(),
                preconditions.accounts[0].Id + ',' + preconditions.accounts[1].Id,
                '[{"operator": "Equals", "field" : "", "value": ""}]'
            ),
            List<Account>.class
        );
        Test.stopTest();

        // Then the records list is filtered
        List<Account> allAccounts = [SELECT Id FROM Account];
        System.assertEquals(allAccounts.size() - 2, records.size());
        for (Account nonAssignedAccount : records) {
            System.assert(nonAssignedAccount.Id != preconditions.accounts[0].Id);
            System.assert(nonAssignedAccount.Id != preconditions.accounts[1].Id);
        }
    }

    /**
     * Test fetch only the assigned records
     */
    static testMethod void testGetAssignedRecords() {

        // Given some accounts and two of them assigned to a contact
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(8);
        preconditions.assignRecords(
            Account.sObjectType.getDescribe().getName(),
            new List<Id>{preconditions.accounts[0].Id, preconditions.accounts[1].Id}
        );

        // When the object assignment page is loaded for edition
        Test.startTest();
        ObjectAssignmentController controller = preconditions.initControllerForEdit();
        Test.stopTest();

        // Then the assigned records list is set
        System.assertEquals(
            preconditions.accounts[0].Id + ',' + preconditions.accounts[1].Id + ',',
            controller.associatedIds
        );
    }

    /**
     * Test when some records, not all, are unassigned
     */
    static testMethod void testUnassignSomeRecords() {

        // Given some records assigned and the controller loaded for edition
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(8);
        preconditions.assignRecords(
            Account.sObjectType.getDescribe().getName(),
            C.extractIds(preconditions.accounts)
        );
        ObjectAssignmentController controller = preconditions.initControllerForEdit();

        Test.startTest();

        // When some of them are removed from the assignedIds list and saved
        controller.associatedIds = preconditions.accounts[0].Id + ',' +
            preconditions.accounts[1].Id + ',' +
            preconditions.accounts[2].Id + ',' +
            preconditions.accounts[3].Id;
        controller.save();
        Test.stopTest();

        // Then only the remaining records still assigned
        SObjectContactAssociation__c assignedObject = [
            SELECT
                Name,
                AssociatedIds__c,
                SObjectApiName__c,
                Contact__c
            FROM SObjectContactAssociation__c
            LIMIT 1
        ];
        System.assertEquals(
            String.join(
                new List<Id>{
                    preconditions.accounts[0].Id,
                    preconditions.accounts[1].Id,
                    preconditions.accounts[2].Id,
                    preconditions.accounts[3].Id
                },
                ','
            ),
            assignedObject.AssociatedIds__c
        );
        System.assertEquals(
            Account.sObjectType.getDescribe().getName(),
            assignedObject.SObjectApiName__c
        );
        System.assertEquals(
            preconditions.userWrapper.contactId,
            assignedObject.Contact__c
        );
    }

    /**
     * Test unassign some records when there are more than one instance
     */
    static testMethod void testUnassignMultipleInstances() {

        // Given some records assigned and the controller loaded for edition
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(1705);
        preconditions.assignRecords(
            Account.sObjectType.getDescribe().getName(),
            C.extractIds(preconditions.accounts)
        );
        ObjectAssignmentController controller = preconditions.initControllerForEdit();
        List<Id> associatedIds = C.extractIds(
            C.getListSubset(15, preconditions.accounts.size(), preconditions.accounts)
        );

        Test.startTest();

        // When some of the assigned ids are removed
        controller.associatedIds = String.join(associatedIds, ',');
        controller.save();
        Test.stopTest();

        // Then only one assignation record remains with ids that still assigned
        List<SObjectContactAssociation__c> assignedObjects = [
            SELECT
                Name,
                AssociatedIds__c,
                SObjectApiName__c,
                Contact__c
            FROM SObjectContactAssociation__c
        ];
        System.assertEquals(1, assignedObjects.size());
        System.assertEquals(String.join(associatedIds, ','), assignedObjects[0].AssociatedIds__c);
        System.assertEquals(
            Account.sObjectType.getDescribe().getName(),
            assignedObjects[0].SObjectApiName__c
        );
        System.assertEquals(
            preconditions.userWrapper.contactId,
            assignedObjects[0].Contact__c
        );
    }

    /**
     * Test that if all the records are unassigned, then the asignment is removed
     */
    static testMethod void testUnassignAllRecords() {

        // Given some records assigned and the controller loaded for edition
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(8);
        preconditions.assignRecords(
            Account.sObjectType.getDescribe().getName(),
            C.extractIds(preconditions.accounts)
        );
        ObjectAssignmentController controller = preconditions.initControllerForEdit();

        Test.startTest();

        // When all the assigned ids are removed
        controller.associatedIds = '';
        controller.save();
        Test.stopTest();

        // Then the assignation record is removed
        System.assertEquals(0, [SELECT Id FROM SObjectContactAssociation__c].size());
    }

    /**
     * Test that an object fails the canBeSelected test due to being a feed item
     */
    static testMethod void testFeedFail() {
        GenericObjectCreator creator =
            new GenericObjectCreator(AccountFeed.getSObjectType().getDescribe().getName());
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(2);
        ObjectAssignmentController controller = preconditions.initControllerForCreate();
        System.assert(!controller.canBeSelected(
            creator.objectType,
            creator.sObjectDescribe
        ));
    }

    /**
     * Test that an object fails the canBeSelected test due to being a history object
     * THIS NEEDS TO BE COMMENTED OUT AS IT CAUSES THE TARGET ORGS TO REQUIRE TO TURN ON HISTORY TRACKING
     * FOR THE ACCOUNT OBJECT
    static testMethod void testHistoryFail() {
        GenericObjectCreator creator =
            new GenericObjectCreator(AccountHistory.getSObjectType().getDescribe().getName());
        AssignRecordsPreconditions preconditions = new AssignRecordsPreconditions();
        preconditions.createUserWrapper();
        preconditions.createAccounts(2);
        ObjectAssignmentController controller = preconditions.initControllerForCreate();
        System.assert(!controller.canBeSelected(
            creator.objectType,
            creator.sObjectDescribe
        ));
    }

    /**
     * Build a set with the values of a the given options
     */
    private static Set<String> getValuesSet(List<SelectOption> options) {
        Set<String> values = new Set<String>();
        for (SelectOption option : options) {
            values.add(option.getValue());
        }
        return values;
    }

    /*
     * Wrapper class to manage the preconditions
     */
    private class AssignRecordsPreconditions {
        public MobileUserDO.UserWrapper userWrapper {get; set;}
        public List<Account> accounts {get; set;}
        public List<Contact> contacts {get; set;}

        /**
         * Constructor of the class
         */
        public AssignRecordsPreconditions() {
            this.accounts = new List<Account>();
            this.contacts = new List<Contact>();
        }

        /**
         * Create a contact
         */
        public void createUserWrapper() {
            this.userWrapper =
                TestUtils.createPartnerUser(true);
        }

        /**
         * Create the given amount of accounts
         *
         * @param amountOfRecords - The amount of accounts to create
         */
        public void createAccounts(Integer amountOfRecords) {
            this.accounts = TestUtils.createAccounts(amountOfRecords);
        }

        /**
         * Create the given amount of contacts
         *
         * @param amountOfRecords - The amount of contacts to create
         */
        public void createContacts(Integer amountOfRecords) {
            this.contacts = TestUtils.createContacts(amountOfRecords);
        }

        /**
         * Assign some records to the current contact
         *
         * @param objectName  - The API name of the object to assign
         * @param idsToAssign - A list with the ids of the recors to assign
         *
         * @return - The list of associations
         */
        public List<SObjectContactAssociation__c> assignRecords(String objectName, List<Id> idsToAssign) {
            List<SObjectContactAssociation__c> associations =
                SObjectContactAssociationDO.createNewRecords(
                    this.userWrapper.contactId,
                    objectName,
                    idsToAssign
                );
            insert associations;

            return associations;
        }

        /**
         * Initialize the controller for the creation
         *
         * @return - The controller
         */
        public ObjectAssignmentController initControllerForCreate() {
            ApexPages.currentPage().getParameters().put(
                ObjectAssignmentController.PARAM_CONTACT_ID,
                this.userWrapper.contactId
            );
            ApexPages.currentPage().getParameters().put(
                ObjectAssignmentController.PARAM_USER_ID,
                this.userWrapper.Id
            );
            return new ObjectAssignmentController();
        }

        /**
         * Initialize the controller for the edition
         *
         * @return - The controller
         */
        public ObjectAssignmentController initControllerForEdit() {
            ApexPages.currentPage().getParameters().put(
                ObjectAssignmentController.PARAM_CONTACT_ID,
                this.userWrapper.contactId
            );
            ApexPages.currentPage().getParameters().put(
                ObjectAssignmentController.PARAM_OBJECT_NAME,
                Account.sObjectType.getDescribe().getName()
            );
            return new ObjectAssignmentController();
        }
    }
}
