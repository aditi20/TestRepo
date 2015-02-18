/**
 * Test class for the generic object creator
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class GenericObjectCreatorTest {

    /**
     * Test creation of an object using the map of values with Schema.SObjectField
     */
    static testMethod void testPopulateWithSObjectField() {
        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Contact newContact = (Contact) creator.createNewRecord();

        Test.startTest();
        creator.populateFields(newContact, new Map<Schema.SObjectField, Object>{
            Contact.LastName => SObjectDomainContactTest.LAST_NAME,
            Contact.FirstName => SObjectDomainContactTest.FIRST_NAME
        });
        Test.stopTest();
        assertPopulationOfCorrectFields(newContact);
    }


    /**
     * Test creation of an object using the map of values with Strings
     */
    static testMethod void testPopulateWithString() {
        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Contact newContact = (Contact) creator.createNewRecord();

        Test.startTest();
        creator.populateFields(newContact, new Map<String, Object>{
            Contact.LastName.getDescribe().getName() => SObjectDomainContactTest.LAST_NAME,
            Contact.FirstName.getDescribe().getName() => SObjectDomainContactTest.FIRST_NAME
        });
        Test.stopTest();
        assertPopulationOfCorrectFields(newContact);
    }

    /**
     * Test creation of Geolocation field with permission check
     */
    static testMethod void testPopulateGeoLocationFieldCreateWithoutPermission() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        GenericObjectCreator creator = new GenericObjectCreator(Job__c.getSObjectType());
        Job__c newJobActivity = (Job__c) creator.createNewRecord();

        System.runAs(chatterExternalUser) {
            Test.startTest();
            try {
                creator.populateFields(newJobActivity, new Map<String, Object> {
                    Job__c.StartLocation__c.getDescribe().getName() =>
                        '18.5472615 73.8180623 0.0 25.0'
                });
            } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
                System.assertEquals(
                    String.format(
                        System.Label.FIELD_CAN_NOT_BE_CREATED,
                        new List<String>{
                            Job__c.StartLocation__c.getDescribe().getName(),
                            Job__c.SObjectType.getDescribe().getName()
                        }
                    ),
                    goce.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * Test updation of Geolocation field with permission check
     */
    static testMethod void testPopulateGeoLocationFieldUpdateWithPermission() {

        GenericObjectCreator creator = new GenericObjectCreator(Job__c.getSObjectType());
        Contact newContact = TestUtils.createContact('Last Name');
        JobTemplate__c newJobTemplate =
            JobTemplateDO.createJobTemplate('NameJobTemplate', JobTemplateDO.STATUS_DRAFT, '[]');
        insert newJobTemplate;

        // Create job activities.
        Job__c jobActivity =
            TestUtils.createJobActivity(
                'Job activity 1',
                newJobTemplate.Id,
                newContact.Id,
                newContact.Id,
                Datetime.now(),
                Datetime.now()
            );

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }

        System.runAs(chatterExternalUser) {
            Test.startTest();
            try {
                creator.populateFields(jobActivity, new Map<String, Object> {
                    Job__c.StartLocation__c.getDescribe().getName() =>
                        '18.5472615 73.8180623 0.0 25.0'
                });
            } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
                System.assertEquals(
                    String.format(
                        System.Label.FIELD_CAN_NOT_BE_UPDATED,
                        new List<String>{
                            Job__c.StartLocation__c.getDescribe().getName(),
                            Job__c.SObjectType.getDescribe().getName()
                        }
                    ),
                    goce.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    static testMethod void testPopulateWithStringNullValueSuccess() {
        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Contact newContact = (Contact) creator.createNewRecord();

        Test.startTest();
        creator.populateFields(newContact, new Map<String, Object>{
            Contact.LastName.getDescribe().getName() => SObjectDomainContactTest.LAST_NAME,
            Contact.FirstName.getDescribe().getName() => '  '
        });
        Test.stopTest();
        System.assertEquals(SObjectDomainContactTest.LAST_NAME, newContact.LastName);
    }

    static testMethod void testPopulateWithStringNullValueFail() {
        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Contact newContact = (Contact) creator.createNewRecord();

        Test.startTest();
        try {
            creator.populateFields(newContact, new Map<String, Object>{
                Contact.LastName.getDescribe().getName() => '  ',
                Contact.FirstName.getDescribe().getName() => SObjectDomainContactTest.FIRST_NAME
            });
            System.assert(false, 'Cannot set Contact.LastName to empty');
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.FIELD_CANNOT_BE_NULLED,
                    new List<String>{
                        Contact.LastName.getDescribe().getName()
                    }
                ),
                goce.getMessage()
            );
        }
        Test.stopTest();
    }

    /**
     * Pretty hard to find a suitable object with all the needed types hence the multiple records
     */
    static testMethod void testPopulateWithStringAllTypeSuccess() {
        GenericObjectCreator contactCreator = new GenericObjectCreator(Contact.getSObjectType());
        Contact newContact = (Contact) contactCreator.createNewRecord();
        GenericObjectCreator caseCreator = new GenericObjectCreator(Case.getSObjectType());
        Case newCase = (Case) caseCreator.createNewRecord();
        GenericObjectCreator solutionCreator = new GenericObjectCreator(Solution.getSObjectType());
        Solution newSolution = (Solution) solutionCreator.createNewRecord();

        Test.startTest();
        contactCreator.populateFields(newContact, new Map<String, Object>{
            Contact.LastName.getDescribe().getName() => SObjectDomainContactTest.LAST_NAME,
            Contact.Birthdate.getDescribe().getName() => '2014-06-24'
        });
        caseCreator.populateFields(newCase, new Map<String, Object>{
            Case.IsEscalated.getDescribe().getName() => '1'
        });
        solutionCreator.populateFields(newSolution, new Map<String, Object>{
            Solution.IsPublishedInPublicKb.getDescribe().getName() =>
                'true',
            Solution.IsPublished.getDescribe().getName() => 'false',
            Solution.Status.getDescribe().getName() => 'Draft'
        });
        Test.stopTest();
    }

    /**
     * Test populating all the records in the domain with the same values
     */
    static testMethod void testPopulateAllRecords() {
        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Contact newContact = (Contact) creator.createNewRecord();
        Contact newContact1 = (Contact) creator.createNewRecord();
        List<Contact> contactsToUpdate = new List<Contact>{newContact, newContact1};
        creator.populateFieldForAllRecords(
            contactsToUpdate,
            Contact.LastName,
            SObjectDomainContactTest.LAST_NAME
        );
        creator.populateFieldForAllRecords(
            contactsToUpdate,
            Contact.FirstName,
            SObjectDomainContactTest.FIRST_NAME
        );
        assertPopulationOfCorrectFields(newContact);
        assertPopulationOfCorrectFields(newContact1);
    }

    /**
     * Test field doesn't exist exception
     */
    static testMethod void testFieldNotExistException() {

        String badFieldName = 'BADFIELD';
        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Contact newContact = (Contact) creator.createNewRecord();
        Test.startTest();
        try {
            creator.populateFields(
                newContact,
                new Map<String, Object>{
                    badFieldName => 1
                }
            );
            System.assert(false, 'Should not make it here as field doesn\'t exist');
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.FIELD_DOES_NOT_EXIST,
                    new List<String>{
                        badFieldName,
                        Contact.SObjectType.getDescribe().getName()
                    }
                ),
                goce.getMessage()
            );
        }
        Test.stopTest();
    }

    static testMethod void testCheckObjectAccessibleSuccess() {

        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Test.startTest();
        try {
            creator.checkObjectAccessible();
            System.assert(true);
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.OBJECT_CAN_NOT_BE_ACCESSED,
                    new List<String>{Contact.SObjectType.getDescribe().getName()}
                ),
                goce.getMessage()
            );
            System.assert(false, 'Should not be here as user has access to Contact');
        }
        Test.stopTest();
    }

    static testMethod void testCheckObjectAccessibleFail() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
            Test.startTest();
            try {
                creator.checkObjectAccessible();
                System.assert(false, 'User should not have access to Contact object');
            } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
                System.assertEquals(
                    String.format(
                        System.Label.OBJECT_CAN_NOT_BE_ACCESSED,
                        new List<String>{Contact.SObjectType.getDescribe().getName()}
                    ),
                    goce.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    static testMethod void testIsObjectAccessibleSuccess() {

        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Test.startTest();
        System.assertEquals(
            true,
            creator.isObjectAccessible(false),
            'Should have access to Contact object'
        );
        Test.stopTest();
    }

    static testMethod void testIsObjectAccessibleFail() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
            Test.startTest();
            System.assertEquals(
                false,
                creator.isObjectAccessible(false),
                'Should not have access to Contact object'
            );
            Test.stopTest();
        }
    }

    static testMethod void testCheckObjectCreateableSuccess() {

        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Test.startTest();
        try {
            creator.checkObjectCreateable();
            System.assert(true);
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.OBJECT_CAN_NOT_BE_CREATED,
                    new List<String>{Contact.SObjectType.getDescribe().getName()}
                ),
                goce.getMessage()
            );
            System.assert(false, 'Should not be here as user has creatable rights to Contact');
        }
        Test.stopTest();
    }

    static testMethod void testCheckObjectCreateableFail() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
            Test.startTest();
            try {
                creator.checkObjectCreateable();
                System.assert(false, 'User should not have create access to Contact object');
            } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
                System.assertEquals(
                    String.format(
                        System.Label.OBJECT_CAN_NOT_BE_CREATED,
                        new List<String>{Contact.SObjectType.getDescribe().getName()}
                    ),
                    goce.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    static testMethod void testCheckObjectUpdateableSuccess() {

        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Test.startTest();
        try {
            creator.checkObjectUpdateable();
            System.assert(true);
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.OBJECT_CAN_NOT_BE_UPDATE,
                    new List<String>{Contact.SObjectType.getDescribe().getName()}
                ),
                goce.getMessage()
            );
            System.assert(false, 'Should not be here as user has creatable rights to Contact');
        }
        Test.stopTest();
    }

    static testMethod void testCheckObjectUpdateableFail() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
            Test.startTest();
            try {
                creator.checkObjectUpdateable();
                System.assert(false, 'User should not have update access to Contact object');
            } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
                System.assertEquals(
                    String.format(
                        System.Label.OBJECT_CAN_NOT_BE_UPDATE,
                        new List<String>{Contact.SObjectType.getDescribe().getName()}
                    ),
                    goce.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    static testMethod void testCheckObjectDeletableSuccess() {

        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Test.startTest();
        try {
            creator.checkObjectDeletable();
            System.assert(true);
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.OBJECT_CAN_NOT_BE_DELETED,
                    new List<String>{Contact.SObjectType.getDescribe().getName()}
                ),
                goce.getMessage()
            );
            System.assert(false, 'Should not be here as user has updateable rights to Contact');
        }
        Test.stopTest();
    }

    static testMethod void testCheckObjectDeletableFail() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
            Test.startTest();
            try {
                creator.checkObjectDeletable();
                System.assert(false, 'User should not have delete access to Contact object');
            } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
                System.assertEquals(
                    String.format(
                        System.Label.OBJECT_CAN_NOT_BE_DELETED,
                        new List<String>{Contact.SObjectType.getDescribe().getName()}
                    ),
                    goce.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * Test that a field is accessible to a user
     */
    static testMethod void testFieldAccessibleFieldList() {
        runFieldAccessibleFieldListTest(true, true, false);
    }

    /**
     * Test that a field is accessible to a user
     */
    static testMethod void testFieldAccessibleStringList() {
        runFieldAccessibleFieldListTest(false, true, false);
    }


    /**
     * Test that the correct error is thrown if a field is not accessible to a user
     */
    static testMethod void testFieldInaccessibleExceptionFieldList() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            runFieldAccessibleFieldListTest(true, false, true);
        }
    }

    /**
     * Test that the correct error is thrown if a field is not accessible to a user
     */
    static testMethod void testFieldInaccessibleExceptionStringList() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            runFieldAccessibleFieldListTest(false, false, true);
        }
    }

    /**
     * Test that a reference field is correctly accessible to a user
     */
    static testMethod void testReferenceFieldsAccessible() {
        try {
            Test.startTest();
            GenericObjectCreator creator =
                new GenericObjectCreator(Contact.getSObjectType());
            creator.checkFieldsAccessible(
                new List<String>{
                    'Account.Name'
                }
            );
            Test.stopTest();
            System.assert(true);
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assert(false, 'Should not get here as field is Accessible');
        }
    }

    /**
     * Test that the correct error is thrown if a reference field is not accessible to a user
     */
    static testMethod void testReferenceFieldsInAccessible() {
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        GenericObjectCreator creator =
            new GenericObjectCreator(Contact.getSObjectType());
        try {
            Test.startTest();
            System.runAs(chatterExternalUser) {
                creator.checkFieldsAccessible(
                    new List<String>{
                      'Account.Name'
                    }
                );
            }
            Test.stopTest();
            System.assert(false, 'Should not get here as field is not Accessible');
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.FIELD_CAN_NOT_BE_ACCESSED,
                    new List<String>{
                        Contact.AccountId.getDescribe().getName(),
                        Contact.SObjectType.getDescribe().getName()
                    }
                ),
                goce.getMessage()
            );
        }
    }

    /**
     * Test that a reference field is correctly createable by a user
     */
    static testMethod void testReferenceFieldsCreateable() {
        try {
            Test.startTest();
            GenericObjectCreator creator =
                new GenericObjectCreator(Contact.getSObjectType());
            creator.checkFieldsCreateable(
                new List<String>{
                    'Account.Name'
                }
            );
            Test.stopTest();

            System.assert(true);
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assert(false, 'Should not get here as field is Createable');
        }
    }

    /**
     * Test that the correct error is thrown if a reference field is not createable by a user
     */
    static testMethod void testReferenceFieldsNotCreateable() {
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        GenericObjectCreator creator =
            new GenericObjectCreator(Contact.getSObjectType());
        try {
            Test.startTest();
            System.runAs(chatterExternalUser) {
                creator.checkFieldsCreateable(
                    new List<String>{
                      'Account.Name'
                    }
                );
            }
            Test.stopTest();
            System.assert(false, 'Should not get here as field is not Createable');
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.FIELD_CAN_NOT_BE_CREATED,
                    new List<String>{
                        Contact.AccountId.getDescribe().getName(),
                        Contact.SObjectType.getDescribe().getName()
                    }
                ),
                goce.getMessage()
            );
        }
    }

    /**
     * Test that a reference field is correctly updateable by a user
     */
    static testMethod void testReferenceFieldsUpdateable() {
        try {
            Test.startTest();
            GenericObjectCreator creator =
                new GenericObjectCreator(Contact.getSObjectType());
            creator.checkFieldsUpdateable(
                new List<String>{
                    'Account.Name'
                }
            );
            Test.stopTest();

            System.assert(true);
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assert(false, 'Should not get here as field is Updateable');
        }
    }

    /**
     * Test that the correct error is thrown if a reference field is not updateable by a user
     */
    static testMethod void testReferenceFieldsNotUpdateable() {
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        GenericObjectCreator creator =
            new GenericObjectCreator(Contact.getSObjectType());
        try {
            Test.startTest();
            System.runAs(chatterExternalUser) {
                creator.checkFieldsUpdateable(
                    new List<String>{
                      'Account.Name'
                    }
                );
            }
            Test.stopTest();
            System.assert(false, 'Should not get here as field is not Updateable');
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.FIELD_CAN_NOT_BE_UPDATED,
                    new List<String>{
                        Contact.AccountId.getDescribe().getName(),
                        Contact.SObjectType.getDescribe().getName()
                    }
                ),
                goce.getMessage()
            );
        }
    }

    private static void runFieldAccessibleFieldListTest(
            Boolean useFieldList,
            Boolean firstAssert,
            Boolean secondAssert
    ) {
        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        try {
            if (useFieldList) {
                creator.checkFieldsAccessible(
                    new List<Schema.SObjectField>{
                        Contact.LastName
                    }
                );
            } else {
                creator.checkFieldsAccessible(
                    new List<String>{
                        Contact.LastName.getDescribe().getName()
                    }
                );
            }
            System.assert(firstAssert);
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.FIELD_CAN_NOT_BE_ACCESSED,
                    new List<String>{
                        Contact.LastName.getDescribe().getName(),
                        Contact.SObjectType.getDescribe().getName()
                    }
                ),
                goce.getMessage()
            );
            System.assert(secondAssert);
        }
    }

    /**
     * Test that a field is Createable for a user
     */
    static testMethod void testFieldCreateableFieldList() {
        runFieldCreateableFieldListTest(true, true, false);
    }

    /**
     * Test that a field is Createable for a user
     */
    static testMethod void testFieldCreateableStringList() {
        runFieldCreateableFieldListTest(false, true, false);
    }


    /**
     * Test that the correct error is thrown if a field is not Createable for a user
     */
    static testMethod void testFieldCreateableExceptionFieldList() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            runFieldCreateableFieldListTest(true, false, true);
        }
    }

    /**
     * Test that the correct error is thrown if a field is not Createable for a user
     */
    static testMethod void testFieldCreateableExceptionStringList() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            runFieldCreateableFieldListTest(false, false, true);
        }
    }

    private static void runFieldCreateableFieldListTest(
            Boolean useFieldList,
            Boolean firstAssert,
            Boolean secondAssert
    ) {
        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        try {
            if (useFieldList) {
                creator.checkFieldsCreateable(
                    new List<Schema.SObjectField>{
                        Contact.LastName
                    }
                );
            } else {
                creator.checkFieldsCreateable(
                    new List<String>{
                        Contact.LastName.getDescribe().getName()
                    }
                );
            }
            System.assert(firstAssert);
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.FIELD_CAN_NOT_BE_CREATED,
                    new List<String>{
                        Contact.LastName.getDescribe().getName(),
                        Contact.SObjectType.getDescribe().getName()
                    }
                ),
                goce.getMessage()
            );
            System.assert(secondAssert);
        }
    }

    /**
     * Test that a field is Updateable for a user
     */
    static testMethod void testFieldUpdateableFieldList() {
        runFieldUpdateableFieldListTest(true, true, false);
    }

    /**
     * Test that a field is Updateable for a user
     */
    static testMethod void testFieldUpdateableStringList() {
        runFieldUpdateableFieldListTest(false, true, false);
    }


    /**
     * Test that the correct error is thrown if a field is not Updateable for a user
     */
    static testMethod void testFieldUpdateableExceptionFieldList() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            runFieldUpdateableFieldListTest(true, false, true);
        }
    }

    /**
     * Test that the correct error is thrown if a field is not Updateable for a user
     */
    static testMethod void testFieldUpdateableExceptionStringList() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            runFieldUpdateableFieldListTest(false, false, true);
        }
    }

    private static void runFieldUpdateableFieldListTest(
            Boolean useFieldList,
            Boolean firstAssert,
            Boolean secondAssert
    ) {
        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        try {
            if (useFieldList) {
                creator.checkFieldsUpdateable(
                    new List<Schema.SObjectField>{
                        Contact.LastName
                    }
                );
            } else {
                creator.checkFieldsUpdateable(
                    new List<String>{
                        Contact.LastName.getDescribe().getName()
                    }
                );
            }
            System.assert(firstAssert);
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.FIELD_CAN_NOT_BE_UPDATED,
                    new List<String>{
                        Contact.LastName.getDescribe().getName(),
                        Contact.SObjectType.getDescribe().getName()
                    }
                ),
                goce.getMessage()
            );
            System.assert(secondAssert);
        }
    }



    /**
     * Test populating a field with a creator of one type and an object of another
     */
    static testMethod void testCreatorTypeMisMatch() {

        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.getSObjectType());
        GenericObjectCreator accountCreator = new GenericObjectCreator(Account.getSObjectType());
        Account acc = (Account) accountCreator.createNewRecord();
        try {
            contactCreator.populateField(
                acc,
                Contact.LastName,
                'New Name'
            );
            System.assert(false, 'Should not get here as creator type mismatch should be thrown');
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                        System.Label.TYPE_MISMATCH,
                        new List<String>{
                            Account.SObjectType.getDescribe().getName(),
                            Contact.SObjectType.getDescribe().getName()
                        }
                ),
                goce.getMessage()
            );
        }
    }

    /**
     * Test that field cannot be created exception thrown
     */
    static testMethod void testFieldCreationDenied() {

        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Contact newContact = (Contact) creator.createNewRecord();
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            Test.startTest();
            carryOutPermissionTest(
                creator,
                newContact,
                String.format(
                    System.Label.FIELD_CAN_NOT_BE_CREATED,
                    new List<String>{
                        Contact.LastName.getDescribe().getName(),
                        Contact.SObjectType.getDescribe().getName()
                    }
                ),
                Contact.LastName
            );
            Test.stopTest();
        }
    }

    /**
     * Test that field cannot be updated exception thrown
     */
    static testMethod void testFieldUpdatedDenied() {

        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Contact newContact = (Contact) creator.createNewRecord();
        carryOutFieldUpdate(creator, newContact, Contact.LastName);
        insert newContact;
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        System.runAs(chatterExternalUser) {
            Test.startTest();
            carryOutPermissionTest(
                creator,
                newContact,
                String.format(
                    System.Label.FIELD_CAN_NOT_BE_UPDATED,
                    new List<String>{
                        Contact.CreatedDate.getDescribe().getName(),
                        Contact.SObjectType.getDescribe().getName()
                    }
                ),
                Contact.CreatedDate
            );
            Test.stopTest();
        }
    }

    private static void carryOutPermissionTest(
            GenericObjectCreator creator,
            Contact newContact,
            String expectedMessage,
            Schema.SObjectField field
    ) {
        try {
            carryOutFieldUpdate(creator, newContact, field);
            System.assert(false, 'Should not make it here user has no permissions to modify fields');
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                expectedMessage,
                goce.getMessage()
            );
        }
    }

    private static void carryOutFieldUpdate(
            GenericObjectCreator creator,
            Contact newContact,
            Schema.SObjectField field
    ) {
        creator.populateFields(newContact, new Map<Schema.SObjectField, Object>{
            field => SObjectDomainContactTest.LAST_NAME
        });
    }

    /**
     * Assert that the fields were correctly initiated
     */
    private static void assertPopulationOfCorrectFields(Contact newContact) {
        System.assertEquals(
            SObjectDomainContactTest.LAST_NAME,
            newContact.get(Contact.LastName.getDescribe().getName())
        );
        System.assertEquals(
            SObjectDomainContactTest.FIRST_NAME,
            newContact.get(Contact.FirstName.getDescribe().getName())
        );
    }

    /**
     * Test whether Geolocation fields are split
     */
     static testMethod void testSplitingOfGpsFields() {
        String geoLocationField = 'geoLocationField__c';
        GenericObjectCreator creator = new GenericObjectCreator(Contact.getSObjectType());
        Test.startTest();
        List<String> distributedGpsFields =
            creator.distributeLocationField(geoLocationField);
        Test.stopTest();
        System.assertEquals(
            2,
            distributedGpsFields.size(),
            'Geo location field not distributed properly'
        );
        System.assertEquals(
            'geoLocationField__Latitude__s',
            distributedGpsFields[0]
        );
        System.assertEquals(
            'geoLocationField__Longitude__s',
            distributedGpsFields[1]
        );
    }
}