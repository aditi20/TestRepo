/**
 * Test class for SObjectSelector
 */
@isTest
private with sharing class SObjectSelectorTest {

    private static List<Contact> testContacts;

    /**
     * Test getting records only by id
     */
    static testMethod void testGettingRecordsOnlyById() {

        TestSObjectSelectorContact selector = new TestSObjectSelectorContact();
        createTestContacts();
        Set<Id> idsToFind = new Set<Id>{
            testContacts[0].Id,
            testContacts[1].Id,
            testContacts[2].Id
        };
        List<Contact> foundContacts = (List<Contact>)selector.getRecordsByOnlyId(idsToFind);
        System.assertEquals(3, foundContacts.size());
        System.assert(
            idsToFind.contains(foundContacts[0].Id),
            'The following id should have been returned ' + foundContacts[0].Id
        );
        System.assert(
            idsToFind.contains(foundContacts[1].Id),
            'The following id should have been returned ' + foundContacts[1].Id
        );
        System.assert(
            idsToFind.contains(foundContacts[2].Id),
            'The following id should have been returned ' + foundContacts[2].Id
        );
    }

    /**
     * Test getting records only by id but limit to one record
     */
    static testMethod void testGettingRecordsOnlyByIdLimit1() {

        TestSObjectSelectorContact selector = new TestSObjectSelectorContact();
        createTestContacts();
        Set<Id> idsToFind = new Set<Id>{
            testContacts[0].Id,
            testContacts[1].Id,
            testContacts[2].Id
        };
        selector.mainQueryBuilder.setLimitAmount(1);
        List<Contact> foundContacts = (List<Contact>)selector.getRecordsByOnlyId(idsToFind);
        System.assertEquals(1, foundContacts.size());
    }

    /**
     * Test getting records only by id with all fields
     */
    static testMethod void testGettingRecordsOnlyByIdAllFields() {

        TestSObjectSelectorContact selector = new TestSObjectSelectorContact();
        createTestContacts();
        Set<Id> idsToFind = new Set<Id>{
            testContacts[0].Id,
            testContacts[1].Id,
            testContacts[2].Id
        };
        List<Contact> foundContacts =
            (List<Contact>)selector.getRecordsByOnlyIdWithAllFields(idsToFind);
        System.assertEquals(3, foundContacts.size());
        for (Contact con : foundContacts) {
            System.assert(con.CreatedDate != null, 'CreatedDate should have been found');
        }
    }

    /**
     * Test exception when accessing an inaccessible object
     */
    static testMethod void testInaccessibleObjectThrowsError() {
        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }
        TestSObjectSelectorContact selector;
        createTestContacts();
        System.runAs(chatterExternalUser) {
            try {
                Test.startTest();
                selector = new TestSObjectSelectorContact();
                Set<Id> idsToFind = new Set<Id>{
                    testContacts[0].Id,
                    testContacts[1].Id,
                    testContacts[2].Id
                };
                List<Contact> foundContacts =
                    (List<Contact>)selector.getRecordsByOnlyIdWithAllFields(idsToFind);
                System.assert(false, 'Should not get here as domain has no records');
            } catch (SObjectSelector.SelectorException se) {
                System.assertEquals(
                    String.format(
                        System.Label.ACCESS_DENIED,
                        new List<String>{selector.getObjectName()}
                    ),
                    se.getMessage()
                );
            }
        }
    }

    /**
     * Test getting an inaccessible field from an accessable object
     */
    static testMethod void testInaccessibleFieldThrowsError() {

        TestSObjectSelectorContact selector = new TestSObjectSelectorContact();
        createTestContacts();
        Set<Id> idsToFind = new Set<Id>{
            testContacts[0].Id,
            testContacts[1].Id,
            testContacts[2].Id
        };
        selector.mainQueryBuilder.setSelectClause(new List<Schema.SObjectField>{
            Contact.DoNotCall
        });
        Test.startTest();
        try {
            List<Contact> foundContacts =
                (List<Contact>) selector.getRecordsByOnlyId(idsToFind);
            System.assert(false, 'User doesn\'t have access to Contact.DoNotCall');
        } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
            System.assertEquals(
                String.format(
                    System.Label.FIELD_CAN_NOT_BE_ACCESSED,
                    new List<String>{
                        Contact.DoNotCall.getDescribe().getName(),
                        Contact.sObjectType.getDescribe().getName()
                    }
                ),
                goce.getMessage()
            );
        }
        Test.stopTest();
    }

    /**
     * Test using custom field list
     */
    static testMethod void testGettingRecordsByIdWithCustomFieldList() {

        TestSObjectSelectorContact selector = new TestSObjectSelectorContact();
        createTestContacts();
        Set<Id> idsToFind = new Set<Id>{
            testContacts[0].Id,
            testContacts[1].Id,
            testContacts[2].Id
        };
        selector.mainQueryBuilder.setSelectClause(new List<Schema.SObjectField>{
            Contact.LastModifiedDate
        });
        List<Contact> foundContacts =
            (List<Contact>)selector.getRecordsByOnlyId(idsToFind);
        System.assertEquals(3, foundContacts.size());
        for (Contact con : foundContacts) {
            System.assert(con.LastModifiedDate != null, 'LastModifiedDate should have been found');
            try {
                String name = con.Name;
                System.assert(false, ' Should not have fetched Name field');
            } catch (Exception e) {
                System.assert(true);
            }
        }
    }

    /**
     * Test getting by id with an extra where clause
     */
    static testMethod void testGettingRecordsByIdWithExtraWhereClause() {

        TestSObjectSelectorContact selector = new TestSObjectSelectorContact();
        createTestContacts();
        Set<Id> idsToFind = new Set<Id>{
            testContacts[0].Id,
            testContacts[1].Id,
            testContacts[2].Id
        };
        selector.mainQueryBuilder.addToWhereClause(
            'LastName = \'' + TestUtils.TEST_CONTACT_LAST_NAME + '0\''
        );
        List<Contact> foundContacts =
            (List<Contact>)selector.getRecordsById(idsToFind);
        System.assertEquals(1, foundContacts.size());
        System.assert(
            idsToFind.contains(foundContacts[0].Id),
            'The following id should have been returned ' + foundContacts[0].Id
        );
        System.assertEquals(TestUtils.TEST_CONTACT_LAST_NAME + '0', foundContacts[0].Name);
    }

    /**
     * Test using custom order by clause
     */
    static testMethod void testGettingRecordsOnlyByIdWithCustomOrderByClause() {

        TestSObjectSelectorContact selector = new TestSObjectSelectorContact();
        createTestContacts();
        Set<Id> idsToFind = new Set<Id>{
            testContacts[0].Id,
            testContacts[1].Id,
            testContacts[2].Id
        };
        selector.addToMainOrderByClause('LastName DESC');
        List<Contact> foundContacts = (List<Contact>) selector.getRecordsByOnlyId(idsToFind);
        System.assertEquals(3, foundContacts.size());
        System.assertEquals(TestUtils.TEST_CONTACT_LAST_NAME + '2', foundContacts[0].LastName);
        System.assertEquals(TestUtils.TEST_CONTACT_LAST_NAME + '1', foundContacts[1].LastName);
        System.assertEquals(TestUtils.TEST_CONTACT_LAST_NAME + '0', foundContacts[2].LastName);
    }

    /**
     * Test path conversion
     */
    static testMethod void testPathConversion() {
        String pathToMatch = 'ReportsTo.AccountId';
        TestSObjectSelectorContact selector = new TestSObjectSelectorContact();
        String convertedPath =
            selector.getMainQueryBuilder().generateLookUp(new List<Schema.SObjectField>{
                Contact.ReportsToId,
                Contact.AccountId
            });
        System.assertEquals(pathToMatch, convertedPath);
    }

    /**
     * Test use of inner select query
     */
    static testMethod void testInnerSelect() {

        TestSObjectSelectorAccount accountSelector = new TestSObjectSelectorAccount();
        List<Account> testAccounts = TestUtils.createAccounts(2);
        testContacts = TestUtils.createContactsForAccounts(testAccounts, 5);

        accountSelector.addInnerSelectQuery(buildInnerContactQuery());
        List<Account> foundAccounts = (List<Account>) accountSelector.getRecordsByOnlyId(
            new Set<Id>{testAccounts[0].Id}
        );
        System.assertEquals(1, foundAccounts.size());
        System.assertEquals(testAccounts[0].Id, foundAccounts[0].Id);
        System.assertEquals(5, foundAccounts[0].Contacts.size());
    }

    /**
     * Test escaping single quotes in standard where clause
     */
    static testMethod void testEscapeSingleQuotesStandardWhereClause() {
        String testString = Contact.AccountId.getDescribe().getName() + ' = \'Hell\\\'o\' ';
        TestSObjectSelectorContact selector = new TestSObjectSelectorContact();
        String escapedString =
            selector.getMainQueryBuilder().generateStandardWhereClause(
                Contact.AccountId,
                '=',
                'Hell\'o'
            );
        System.assertEquals(testString, escapedString);
    }

    /**
     * Test generating order by clause
     */
    static testMethod void testGenerateOrderByClause() {
        String testString = Account.Id.getDescribe().getName() + ' DESC,' +
            Account.Name.getDescribe().getName() + ' ASC';

        List<SObjectSelector.OrderByBuilder> orderByBuilderList =
            new List<SObjectSelector.OrderByBuilder> {
                new SObjectSelector.OrderByBuilder(Account.Id, 'DESC'),
                new SObjectSelector.OrderByBuilder(Account.Name, 'ASC')
            };

        String orderByClause =
            new TestSObjectSelectorAccount().getMainQueryBuilder().generateOrderByClause(
                orderByBuilderList
            );
        System.assertEquals(testString, orderByClause);
    }

    /**
     * Test method to verify concatenation of where clause with specified operator
     */
    static testMethod void testGenerateConcatenatedWhereClause() {

        String expectedString =
            Contact.LastName.getDescribe().getName() + ' = \'Test\' ' +
            ' AND ' +
            Contact.FirstName.getDescribe().getName() + ' = \'Contact\' ';

        TestSObjectSelectorContact contactSelector = new TestSObjectSelectorContact();
        contactSelector.addToMainWhereClause(
            contactSelector.getMainQueryBuilder().generateStandardWhereClause(
                Contact.LastName,
                '=',
                'Test'
            )
        );
        contactSelector.addToMainWhereClause(
            contactSelector.getMainQueryBuilder().generateStandardWhereClause(
                Contact.FirstName,
                '=',
                'Contact'
            )
        );
        String concatenatedWhereClause =
            contactSelector.getMainQueryBuilder().generateConcatenatedWhereClause(
                SObjectSelector.AND_OPERATOR
            );
        System.assertEquals(expectedString, concatenatedWhereClause);
    }

    /**
     * Build the inner query to get the contacts for the account
     */
    private static SObjectSelector.SoqlQueryBuilder buildInnerContactQuery() {

        TestSObjectSelectorContact contactSelector = new TestSObjectSelectorContact();
        return new SObjectSelector.SoqlQueryBuilder(
            'Contacts',
            contactSelector.getObjectName(),
            contactSelector.getDefaultSelectFields(),
            contactSelector.getDefaultOrderByClause()
        );
    }

    /**
     * Create test contacts
     */
    private static void createTestContacts() {
        testContacts = TestUtils.createContacts(5);
    }

    /**
     * Create a mock Contact sobject selector to run the tests with 
     */
    private class TestSObjectSelectorContact extends SObjectSelector {

        public Schema.SObjectType getSObjectType() {
            return Contact.sObjectType;
        }

        public List<Schema.SObjectField> getDefaultSelectFields() {
            return new List<Schema.SObjectField>{
                Contact.Name,
                Contact.Id,
                Contact.LastName,
                Contact.FirstName
            };
        }

        public String pathToJobFiltering() {
            return 'OwnerId';
        }
    }

    /**
     * Create a mock Account sobject selector to run the tests with 
     */
    private class TestSObjectSelectorAccount extends SObjectSelector {

        public Schema.SObjectType getSObjectType() {
            return Account.sObjectType;
        }

        public List<Schema.SObjectField> getDefaultSelectFields() {
            return new List<Schema.SObjectField>{
                Account.Name,
                Account.Id,
                Account.AccountNumber,
                Account.Type
            };
        }

        public String pathToJobFiltering() {
            return 'OwnerId';
        }
    }
}