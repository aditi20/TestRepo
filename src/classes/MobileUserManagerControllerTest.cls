/**
 * Test class for the Mobile User Manager controller
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
@isTest
public class MobileUserManagerControllerTest {
    static MobileUserDo.UserWrapper partnerUser1;
    static MobileUserDo.UserWrapper partnerUser2;
    static Map<Id, Mobile_User__c> mobileUsers;
    static Map<Id, MobileUserDO.UserWrapper> partnerUsers;

    /**
     * Create test data for Mobile / Partner Users
     */
    private static void usersTestData() {
        // Given some active and inactive mobile users and some partner users
        TestUtils.Surveyor surveyorInstance1 =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE);
        TestUtils.Surveyor surveyorInstance2 =
            TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_INACTIVE);

        // Create Partner Account
        List<Account> partnerAccount = TestUtils.createAccounts(1);
        System.assert(partnerAccount.size() == 1, 'Account not created properly');

        // Create Partner Users
        partnerUser1 = TestUtils.createPartnerUser(partnerAccount[0], true);
        System.assert(partnerUser1 != null, 'Partner User not created properly');
        partnerUser2 = TestUtils.createPartnerUser(partnerAccount[0], false);
        System.assert(partnerUser2 != null, 'Partner User not created properly');

        mobileUsers = new Map<Id, Mobile_User__c>();
        mobileUsers.put(surveyorInstance1.user.Id, surveyorInstance1.user);
        mobileUsers.put(surveyorInstance2.user.Id, surveyorInstance2.user);
        partnerUsers = new Map<Id, MobileUserDO.UserWrapper>();
        partnerUsers.put(partnerUser1.Id, partnerUser1);
        partnerUsers.put(partnerUser2.Id, partnerUser2);
    }

    /**
     * Test the initialization of the controller load all the wrappers
     */
    static testMethod void testGetUsersWrappers() {
        // Create test data for Mobile / Partner Users
        usersTestData();

        Map<Id, User> oldUsers = new Map<Id, User>([
            SELECT
                Id
            FROM
                User
            WHERE
                UserType = 'PowerPartner'
            AND Id NOT IN (:partnerUser1.Id, :partnerUser2.Id)
        ]);

        Test.startTest();
        // When the controller is initialized
        MobileUserManagerController controller = new MobileUserManagerController();
        Test.stopTest();

        // Then the list of wrappers must be loaded
        for (MobileUserDO.UserWrapper wrappedUser : controller.users) {
            // Avoid processing the users of the org and only consider the ones created within the test
            // See http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_testing_data_access.htm
            if (oldUsers.containsKey(wrappedUser.Id)) {
                continue;
            }

            if (wrappedUser.IsPartner) {
                checkPartnerFields(partnerUsers.get(wrappedUser.Id), wrappedUser);
            } else {
                checkMobileUserFields(mobileUsers.get(wrappedUser.Id), wrappedUser);
            }
        }
    }

    /**
     * If filter selected is Mobile User, then displays only Mobile user related data
     */
    static testMethod void testGetMobileUsersWrappers() {
        // Create test data for Mobile / Partner Users
        usersTestData();

        Test.startTest();
        MobileUserManagerController controller = new MobileUserManagerController();
        List<SelectOption> userList = controller.userList;
        controller.userFilter = System.Label.OLD_MOBILE_USERS;

        // Retrieves data for all Mobile Users
        controller.performUserFilter();
        System.assertEquals(2, controller.users.size());
        Test.stopTest();

        // The list of wrappers for Mobile Users must be loaded
        for (MobileUserDO.UserWrapper wrappedUser : controller.users) {
            checkMobileUserFields(mobileUsers.get(wrappedUser.Id), wrappedUser);
        }
    }

    /**
     * If filter seclected is Partner User, then displays only Partner user related data
     */
    static testMethod void testGetPartnerUsersWrappers() {
        // Create test data for Mobile / Partner Users
        usersTestData();

        Map<Id, User> oldUsers = new Map<Id, User>([
            SELECT
                Id
            FROM
                User
            WHERE
                UserType = 'PowerPartner'
            AND Id NOT IN (:partnerUser1.Id, :partnerUser2.Id)
        ]);

        Test.startTest();
        MobileUserManagerController controller = new MobileUserManagerController();
        List<SelectOption> userList = controller.userList;
        controller.userFilter = System.Label.TAROWORKS_PARTNER_USERS;

        // Retrieves data for all Partner Users
        controller.performUserFilter();
        System.assertEquals(2, controller.users.size() - oldUsers.size());
        Test.stopTest();

        // The list of wrappers for Partner Users must be loaded
        for (MobileUserDO.UserWrapper wrappedUser : controller.users) {
            // Avoid processing the users of the org and only consider the ones created within the test
            if (oldUsers.containsKey(wrappedUser.Id)) {
                continue;
            }
            checkPartnerFields(partnerUsers.get(wrappedUser.Id), wrappedUser);
        }
    }

    /**
     * Check if the fields of a partner user are correct
     */
    private static void checkPartnerFields(
            MobileUserDO.UserWrapper partner,
            MobileUserDO.UserWrapper wrappedUser
    ) {

        System.assertEquals(partner.Id, wrappedUser.Id);
        System.assertEquals(partner.Username, wrappedUser.Username);
        System.assertEquals(partner.ContactId, wrappedUser.ContactId);
        System.assertEquals(partner.ContactName, wrappedUser.ContactName);
        System.assertEquals(partner.LastLogin, wrappedUser.LastLogin);
        System.assertEquals(partner.IsActive, wrappedUser.IsActive);
    }

    /**
     * Check if the fields of a mobile user are correct
     */
    private static void checkMobileUserFields(
            Mobile_User__c mUser,
            MobileUserDO.UserWrapper wrappedUser
    ) {
        System.assertEquals(mUser.Id, wrappedUser.Id);
        System.assertEquals(mUser.Username__c, wrappedUser.Username);
        System.assertEquals(mUser.Contact__c, wrappedUser.ContactId);
        System.assertEquals(mUser.Contact__r.Name, wrappedUser.ContactName);
        System.assertEquals(mUser.Last_Login__c, wrappedUser.LastLogin);
        System.assertEquals(mUser.Status__c == MobileUserDO.STATUS_ACTIVE, wrappedUser.IsActive);
    }
}
