/**
 * Test class for the Trigger handler
 */
@isTest
public with sharing class TriggerHandlerTest {

    /**
     * Test the trigger handling code for before insert. This should carry out the applyDefaults
     * code that is in the test class 
     */
    static testMethod void testBeforeInsert() {

        List<Contact> contactList = new List<Contact>{
            new Contact(), new Contact()
        };
        TriggerHandler.tests.mockDatabase.onInsert(contactList);
        TriggerHandler.tests.mockDatabase.setIsBefore(true);
        TriggerHandler.triggerHandler(SObjectDomainContactTest.class);
        System.assertEquals(
            SObjectDomainContactTest.LAST_NAME,
            TriggerHandler.tests.mockDatabase.newRecords[0].get(
                Contact.LastName.getDescribe().getName()
            )
        );
        System.assertEquals(
            SObjectDomainContactTest.LAST_NAME,
            TriggerHandler.tests.mockDatabase.newRecords[1].get(
                Contact.LastName.getDescribe().getName()
            )
        );
    }

    /**
     * Test afterInsert
     */
    static testMethod void testAfterInsert() {
        setUpAfterInsert();
        TriggerHandler.triggerHandler(SObjectDomainContactTest.class);
        System.assert(TriggerHandler.tests.errorFactory.hasErrors(), 'No errors recorded');
        System.assertEquals(1, TriggerHandler.tests.errorFactory.errors.size());
        System.assertEquals(
            SObjectDomainContactTest.VALIDATE_FIELD_ERROR,
            TriggerHandler.tests.errorFactory.errors[0].errorMessage
        );
    }

    /**
     * Test afterInsert with no access to object
     */
    static testMethod void testAfterInsertNoPermissions() {

        UserTH.setSkipValidation(true);
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        setUpAfterInsert();
        System.runAs(chatterExternalUser) {
            Test.startTest();
            conductPermissionTest(
                String.format(
                    System.Label.INSERT_DENIED,
                    new List<String>{Contact.SObjectType.getDescribe().getName()}
                )
            );
            Test.stopTest();
        }
    }

    private static void setUpAfterInsert() {
        List<Contact> contactList = new List<Contact>{
            new Contact(
                LastName = SObjectDomainContactTest.BAD_LAST_NAME
            ),
            new Contact(LastName = 'A good name')
        };
        TriggerHandler.tests.mockDatabase.onInsert(contactList);
        TriggerHandler.tests.mockDatabase.setIsBefore(false);
    }

    /**
     * Test afterUpdate
     */
    static testMethod void testAfterUpdate() {
        setUpAfterUpdate();
        TriggerHandler.triggerHandler(SObjectDomainContactTest.class);
        System.assert(TriggerHandler.tests.errorFactory.hasErrors(), 'No errors recorded');
        System.assertEquals(1, TriggerHandler.tests.errorFactory.errors.size());
        System.assertEquals(
            SObjectDomainContactTest.VALIDATE_MAP_FIELD_ERROR,
            TriggerHandler.tests.errorFactory.errors[0].errorMessage
        );
    }

    /**
     * Test afterUpdate with no access to object
     */
    static testMethod void testAfterUpdateNoPermissions() {

        UserTH.setSkipValidation(true);
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        setUpAfterUpdate();
        System.runAs(chatterExternalUser) {
            Test.startTest();
            conductPermissionTest(
                String.format(
                    System.Label.UPDATE_DENIED,
                    new List<String>{Contact.SObjectType.getDescribe().getName()}
                )
            );
            Test.stopTest();
        }
    }

    private static void setUpAfterUpdate() {
        List<Contact> contactList = new List<Contact>{
            new Contact(LastName = 'A good name'), new Contact(LastName = 'Also good name')
        };
        insert contactList;
        Map<Id, Contact> oldMap = new Map<Id, Contact>(
            [SELECT Id, LastName FROM Contact]
        );
        oldMap.values()[0].LastName = 'A changed name';
        TriggerHandler.tests.mockDatabase.onUpdate(contactList, oldMap);
        TriggerHandler.tests.mockDatabase.setIsBefore(false);
    }

    /**
     * Test afterDelete with no access to object
     */
    static testMethod void testAfterDeleteNoPermissions() {

        UserTH.setSkipValidation(true);
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        setUpAfterDelete();
        System.runAs(chatterExternalUser) {
            Test.startTest();
            conductPermissionTest(
                String.format(
                    System.Label.DELETE_DENIED,
                    new List<String>{Contact.SObjectType.getDescribe().getName()}
                )
            );
            Test.stopTest();
        }
    }

    private static void setUpAfterDelete() {
        List<Contact> contactList = new List<Contact>{
            new Contact(LastName = 'A good name'), new Contact(LastName = 'Also good name')
        };
        insert contactList;
        Map<Id, Contact> oldMap = new Map<Id, Contact>(
            [SELECT Id, LastName FROM Contact]
        );
        oldMap.values()[0].LastName = 'A changed name';
        TriggerHandler.tests.mockDatabase.onDelete(oldMap);
        TriggerHandler.tests.mockDatabase.setIsBefore(false);
    }

    /**
     * Carry out the test to check the permissions during a DML action
     */
    private static void conductPermissionTest(String expectedMessage) {
        try {
            TriggerHandler.triggerHandler(SObjectDomainContactTest.class);
            System.assert(false, 'Should not make it here user has no permissions to modify records');
        } catch (SObjectDomain.DomainException de) {
            System.assertEquals(
                expectedMessage,
                de.getMessage()
            );
        }
    }

    /**
     * Test getting the trigger class name
     */
    static testMethod void testGettingTriggerClassName() {
        String testName = 'testGettingTriggerClassName';
        String triggerClassName = TriggerHandler.getTriggerClassName(
            testName + 'DO'
        );
        System.assertEquals(testName, triggerClassName);
    }

    /**
     * Test catching bad Domain.Constructor class name
     */
    static testMethod void testCatchBadDomainConstructorName() {
        String className = 'BADNAME';
        String expectedMessage = String.format(
            System.Label.DOMAIN_CLASS_ERR_MSG,
            new List<String>{className}
        );
        try {
            TriggerHandler.getConstructor(className, '');
            System.assert(false, 'Exception should have been thrown as class doesn\'t exist');
        } catch (TriggerHandler.TriggerHandlerException the) {
            System.assertEquals(expectedMessage, the.getMessage());
        }
    }

    /**
     * Test catching bad TriggerHandler class name
     */
    static testMethod void testCatchBadTriggerHandlerName() {
        String className = 'BADNAME';
        String expectedMessage = String.format(
            System.Label.TRIGGER_CLASS_ERR_MSG,
            new List<String>{className}
        );
        try {
            TriggerHandler.getTriggerHandler(className, '');
            System.assert(false, 'Exception should have been thrown as class doesn\'t exist');
        } catch (TriggerHandler.TriggerHandlerException the) {
            System.assertEquals(expectedMessage, the.getMessage());
        }
    }
}