/**
 * This test class is used to test cases related to RemoteActionUtils class
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 */
@isTest
public class RemoteActionUtilsTest {

    /**
     *  Test method for getClients method.
     */
    static testmethod void getClientsTest() {

        // Create contacts
        Contact newContact = TestUtils.createContact('Last Name');
        Contact otherContact = TestUtils.createContact('Other Last Name');

        List<RemoteActionUtils.ContactWrapper> listWrappedContacts = RemoteActionUtils.getClients();
        List<Contact> listOrgContacts = [select Id, Name from Contact];

        // First assert that were created two contact wrappers.
        System.assertEquals( 2, listWrappedContacts.size() );

        Integer assertionsMade = 0;
        for (RemoteActionUtils.ContactWrapper contactWrapper : listWrappedContacts) {
            for (Contact contact : listOrgContacts) {
                if (contact.Id == contactWrapper.id) {
                    assertionsMade++;

                    // Ensures that each contact wrapper is correctly created.
                    System.assertEquals( contact.Name, contactWrapper.label );
                }
            }
        }
        // Also asserts that there was two assertion (one for each contact).
        System.assertEquals( 2, assertionsMade );
    }

    /**
     * Test method for getStaffs method.
     */
    static testmethod void getStaffsTest() {
        // Create Mobile user
        TestUtils.Surveyor surveyorInstance =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);

        // Create Partner user
        List<Account> partnerAccount = TestUtils.createAccounts(1);
        System.assert(partnerAccount.size() == 1, 'One Account should get created');
        MobileUserDo.UserWrapper partnerUser = TestUtils.createPartnerUser(partnerAccount[0], true);
        System.assert(partnerUser != null, 'Partner User should not be null');

        Test.startTest();
        List<RemoteActionUtils.ContactWrapper> listWrappedStaffs = RemoteActionUtils.getStaffs();
        Test.stopTest();

        // We need to get all Partner user count as
        // User object does not take into consideration test environment
        Integer partnerUsersCount = [
            SELECT
                Id
            FROM
                User
            WHERE
                UserType = 'PowerPartner'
        ].size();

        // Result should return total Partner users plus one Mobile user added in test class
        System.assertEquals(
            partnerUsersCount + 1,
            listWrappedStaffs.size(),
            'Total two staffs should be present'
        );
    }
}