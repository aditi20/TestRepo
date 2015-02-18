/**
 * Test class for the SObjectDomain class
 */
@isTest
public with sharing class SObjectDomainTest {

    /**
     * Test creation of a domain class
     */
    static testMethod void testCreationWithSObjectType() {
        SObjectDomain domain = new SObjectDomainContactTest();
        validateDomainConstructor(domain, 0);
    }

    static testMethod void testConstructorWithRecords() {
        Integer amountCreated = 3;
        SObjectDomain domain = new SObjectDomainContactTest(
            TestUtils.createContactsNotInserted(amountCreated)
        );
        validateDomainConstructor(domain, amountCreated);
    }

    static testMethod void testGetGenericFields() {
        SObjectDomain domain = new SObjectDomainContactTest(
            TestUtils.createContactsNotInserted(3)
        );
        List<String> foundNames = domain.getValues(Contact.LastName);
        for (Integer i = 0; i < 3; i++) {
            System.assertEquals(TestUtils.TEST_CONTACT_LAST_NAME + i, foundNames[i]);
        }
    }

    private static void validateDomainConstructor(SObjectDomain domain, Integer expectedSize) {
        System.assertEquals(expectedSize, domain.records.size());
        System.assertEquals(Contact.SObjectType, domain.objectType);
        System.assertEquals(Contact.SObjectType.getDescribe().getName(), domain.sObjectName);
    }
}