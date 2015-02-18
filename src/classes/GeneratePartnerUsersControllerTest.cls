/**
 * Test class for the application settings controller
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 *
 * @author - Kaushik Ray
 */
@isTest
public class GeneratePartnerUsersControllerTest {
    static List<Account> listAccounts {get; set;}
    static TestUtils.Surveyor mobileUser;

    /**
     * Set Up active mobile user record
     */
    static void setupMobileUserData(String status) {
        Contact surveyor = TestUtils.createSurveyor();
        mobileUser = TestUtils.createSurveyor(
            surveyor.LastName,
            surveyor.LastName,
            'test123',
            status
        );
        listAccounts = TestUtils.createAccounts(1);
        System.assertEquals(
            1,
            [
                SELECT
                    Id
                FROM
                    Account
            ].size()
        );
    }

    /**
     * Migrate existing Active Mobile users to Active Partner Users
     */
    static testMethod void testMigrateUser() {
        setupMobileUserData(MobileUserDo.STATUS_ACTIVE);

        Test.startTest();
        // Update Account record to enable Partner
        listAccounts[0].isPartner = true;
        update listAccounts[0];

        GeneratePartnerUsersController generateUsersInstance =
            new GeneratePartnerUsersController();
        generateUsersInstance.domainForPartnerUsers = 'testdomain.com';
        generateUsersInstance.emailForPartnerUsers = 'test@test.com';
        generateUsersInstance.partnerAccountSelected = listAccounts[0].Id;
        generateUsersInstance.migrateMobileUsers();
        System.assertEquals(
            1,
            [
                SELECT
                    Id
                FROM
                    User
                WHERE
                    UserName = :mobileUser.user.Contact__r.Name + '@' +
                        generateUsersInstance.domainForPartnerUsers
                AND
                    isActive = true
            ].size()
        );
        Test.stopTest();
    }

    /**
     * Migrate existing Inactive Mobile users to Inactive Partner Users
     */
    static testMethod void testMigrateUserInactive() {
        setupMobileUserData(MobileUserDo.STATUS_INACTIVE);

        Test.startTest();
        listAccounts[0].isPartner = true;
        update listAccounts[0];
        GeneratePartnerUsersController generateUsersInstance =
            new GeneratePartnerUsersController();
        generateUsersInstance.domainForPartnerUsers = 'testdomain.com';
        generateUsersInstance.emailForPartnerUsers = 'test@test.com';
        generateUsersInstance.partnerAccountSelected = listAccounts[0].Id;
        generateUsersInstance.migrateMobileUsers();
        System.assertEquals(
            1,
            [
                SELECT
                    Id
                FROM
                    User
                WHERE
                    UserName = :mobileUser.user.Contact__r.Name + '@' +
                        generateUsersInstance.domainForPartnerUsers
                AND
                    isActive = false
            ].size()
        );
        Test.stopTest();
    }

    /**
     * Test migration if no Partner Account is created
     */
    static testMethod void testNoPartnerAccountExists() {
        setupMobileUserData(MobileUserDo.STATUS_ACTIVE);

        Test.startTest();
        GeneratePartnerUsersController generateUsersInstance =
            new GeneratePartnerUsersController();
        generateUsersInstance.domainForPartnerUsers = 'testdomain.com';
        generateUsersInstance.emailForPartnerUsers = 'test@test.com';
        try {
            generateUsersInstance.migrateMobileUsers();
        } catch (Exception genericException){
            // Exception occurs if Partner account not set while inserting Partner Users
            System.assertEquals(Label.NO_PARTNER_ACCOUNT_ERROR, genericException.getMessage());
        }
        Test.stopTest();
    }

    /**
     * Test migration if mandatory fields are not filled up
     */
    static testMethod void testMigrateUserMandatoryFields() {
        setupMobileUserData(MobileUserDo.STATUS_ACTIVE);

        Test.startTest();
        GeneratePartnerUsersController generateUsersInstance =
            new GeneratePartnerUsersController();
        generateUsersInstance.emailForPartnerUsers = 'test@test.com';
        try {
            generateUsersInstance.migrateMobileUsers();
        } catch (Exception genericException){
            // Exception occurs if domain/Email not set while inserting Partner Users
            System.assertEquals(Label.MANDATORY_FIELDS_ERROR, genericException.getMessage());
        }
        Test.stopTest();
    }

    /**
     * Test migration if domain specified is invalid
     */
    static testMethod void testMigrateUserInvalidDomain() {
        setupMobileUserData(MobileUserDo.STATUS_ACTIVE);
        Test.startTest();

        GeneratePartnerUsersController generateUsersInstance =
            new GeneratePartnerUsersController();
        generateUsersInstance.domainForPartnerUsers = 'testdomain';
        generateUsersInstance.emailForPartnerUsers = 'test@test.com';
        try {
            generateUsersInstance.migrateMobileUsers();
        } catch (Exception genericException){
            // Exception occurs if invalid domain is set while inserting Partner Users
            System.assertEquals(
                Label.INVALID_DOMAIN_ERROR_TEXT,
                genericException.getMessage()
            );
        }
        Test.stopTest();
    }

    /**
     * Test migration if email specified is invalid
     */
    static testMethod void testMigrateUserInvalidEmail() {
        setupMobileUserData(MobileUserDo.STATUS_ACTIVE);

        Test.startTest();
        GeneratePartnerUsersController generateUsersInstance =
            new GeneratePartnerUsersController();
        generateUsersInstance.domainForPartnerUsers = 'testdomain.com';
        generateUsersInstance.emailForPartnerUsers = 'testcom';
        try {
            generateUsersInstance.migrateMobileUsers();
        } catch (Exception genericException){
            // Exception occurs if invalid email is set while inserting Partner Users
            System.assertEquals(
                Label.INVALID_EMAIL_ERROR_TEXT,
                genericException.getMessage()
            );
        }
        Test.stopTest();
    }

    /**
     * Display results for inserted partner users 
     */
    static testMethod void testDisplayResults() {
        setupMobileUserData(MobileUserDo.STATUS_ACTIVE);

        Test.startTest();
        GeneratePartnerUsersController generateUsersInstance =
            new GeneratePartnerUsersController();
        generateUsersInstance.domainForPartnerUsers = 'testdomain.com';
        generateUsersInstance.emailForPartnerUsers = 'test@test.com';
        generateUsersInstance.partnerAccountSelected = listAccounts[0].Id;
        generateUsersInstance.migrateMobileUsers();
        List<MobileUserDo.UserWrapper> migratedUsersWrapper =
            generateUsersInstance.getDisplayResult();

        // Retieve map of inserted partner user
        Map<Id, User> mapInsertedUsersList = 
            new Map<Id, User> ([
                                    SELECT
                                        Id,
                                        ContactId,
                                        Contact.Name,
                                        UserName,
                                        IsActive
                                    FROM
                                        User
                                    WHERE
                                        UserName = :mobileUser.user.Contact__r.Name + '@' +
                                            generateUsersInstance.domainForPartnerUsers
                                    AND
                                        isActive = true
                            ]);
        System.assertEquals(
            1,
            mapInsertedUsersList.size()
        );
        for (MobileUserDO.UserWrapper wrappedUser : migratedUsersWrapper) {
            checkInsertedParnerUserFields(mapInsertedUsersList.get(wrappedUser.Id), wrappedUser);
        }

        // Try migrating again and no new Partner users should be created.
        generateUsersInstance = new GeneratePartnerUsersController();
        generateUsersInstance.migrateMobileUsers();
        migratedUsersWrapper = generateUsersInstance.getDisplayResult();
        System.assertEquals(0, migratedUsersWrapper.size());
        Test.stopTest();
    }

    /**
     * Display results for mobile users with invalid usernames
     */
    static testMethod void testInvalidUserNameResult() {
        setupMobileUserData(MobileUserDo.STATUS_ACTIVE);

        Test.startTest();
        GeneratePartnerUsersController generateUsersInstance =
            new GeneratePartnerUsersController();
        generateUsersInstance.domainForPartnerUsers = 'testdomain.com';
        generateUsersInstance.emailForPartnerUsers = 'test@test.com';
        generateUsersInstance.partnerAccountSelected = listAccounts[0].Id;
        generateUsersInstance.migrateMobileUsers();
        List<MobileUserDo.UserWrapper> invalidUserNameMobileUserWrapper =
            generateUsersInstance.getMobileUsersWithExistingUsernames();
        for (MobileUserDO.UserWrapper wrappedMobileUser : invalidUserNameMobileUserWrapper) {
            checkInvalidUserNameMobileUsersFields(wrappedMobileUser);
        }
        Test.stopTest();
    }

    /**
     * Verify wrapper fields displayed on page match with the inserted Partner Users
     */
    private static void checkInsertedParnerUserFields(
        User partnerUser,
        MobileUserDO.UserWrapper wrappedUser
    ) {
        System.assertEquals(partnerUser.Username, wrappedUser.Username);
        System.assertEquals(partnerUser.ContactId, wrappedUser.ContactId);
        System.assertEquals(partnerUser.Contact.Name, wrappedUser.ContactName);
        System.assertEquals(partnerUser.isActive, wrappedUser.IsActive);
    }

    /**
     * Verify wrapper fields displayed on page match with the Mobile Users with invalid UserName
     */
    private static void checkInvalidUserNameMobileUsersFields(
            MobileUserDO.UserWrapper wrappedMobileUser
    ) {
        System.assertEquals(mobileUser.user.UserName__c , wrappedMobileUser.Username);
        System.assertEquals(mobileUser.user.Contact__r.Name , wrappedMobileUser.ContactName);
    }
}