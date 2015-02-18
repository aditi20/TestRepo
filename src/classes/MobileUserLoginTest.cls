/**
 * Class that test the MobileUserLogin class. This will test all the authentication
 * errors that can be generated whilst logging in or validating a mobile user using
 * a session token
 *
 * @author Owen Davies - odavies@grameenfiundation.org
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved.
 */
@isTest
global class MobileUserLoginTest {

    private static final String USERNAME = 'username';
    private static final String PASSWORD = 'password';

    /**
     * Set up the login request
     *
     * @param overrideUsername - Username to use instead of created one. Null to use created one
     * @param overridePassword - Password to use instead of created one. Null to use created one
     * @param mobileUserStatus - The status for the created mobile user
     * @param logUserIn        - FLag to indicate if the user should be logged in
     *
     * @return - The surveyor
     */
    static TestUtils.Surveyor setUpRequestFullLogin(
            String overrideUsername,
            String overridePassword,
            String mobileUserStatus,
            Boolean logUserIn
    ) {

        // Create the surveyor
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor(
            'lNameMULT',
            USERNAME,
            PASSWORD,
            mobileUserStatus,
            logUserIn
        );

        Map<String, String> headersMap = new Map<String, String>{
            C.USERNAME_HEADER => overrideUsername == null ? surveyor.user.Username__c : overrideUsername,
            C.PASSWORD_HEADER => overridePassword == null ? surveyor.user.Password__c : overridePassword
        };
        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('login'),
            null,
            headersMap
        );
        return surveyor;
    }

    /**
     * Set up a request that validates through the sessionToken.
     * MobileUser is logged in as part of this setup
     *
     * @param mobileUserStatus - The status for the created mobile user
     * @param login            - Flag to indicate that the mobile user should be logged in
     *
     * @return - The surveyor
     */
    static TestUtils.Surveyor setUpSessionUser(
            String mobileUserStatus,
            Boolean login
    ) {

        // Create the surveyor
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor(
            'lNameMULT',
            USERNAME,
            PASSWORD,
            mobileUserStatus,
            login
        );
        return surveyor;
    }

    // TESTS FOR LOGGING IN WITH USERNAME AND PASSWORD
    /**
     * This method is testing a successful login.
     */
    static testMethod void testSuccessLogin() {

        TestUtils.Surveyor surveyor =
            setUpRequestFullLogin(null, null, MobileUserDO.STATUS_ACTIVE, false);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        // Log the MobileUser in
        MobileUserLogin.doGet();

        // Checking if the response is ok
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);

        // Checking if the Session record is created:
        List<Mobile_User__c> sessions = [
            SELECT
                Id,
                Last_Login__c,
                Last_Activity__c
            FROM
                Mobile_User__c
            WHERE
                Contact__c = :surveyor.theContact.Id
        ];
        System.assert(!sessions.isEmpty(), 'There is no session object created');

        // Checking if session token is created
        String sessionToken = RestContext.response.responseBody.toString();
        System.assert(!String.isEmpty(sessionToken),'There is no Session Token');

        // Checking if last_login and Last_Activity are the same:
        System.assertEquals(sessions[0].Last_Login__c, sessions[0].Last_Activity__c);
    }

    /**
     * Test for logging in with a username and password mismatch
     */
    static testMethod void testUsernamePaswordMismatch() {

        setUpRequestFullLogin('wrongPassword', null, MobileUserDO.STATUS_ACTIVE, false);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        MobileUserLogin.doGet();
        System.assertEquals(C.HTTP_UNAUTHORIZED, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_INVALID_CREDENTIALS, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.AUTH_INVALID_CREDENTIALS, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Login with an inactive user
     */
    static testMethod void testInactiveUser() {

        setUpRequestFullLogin(null, null, MobileUserDO.STATUS_INACTIVE, false);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        MobileUserLogin.doGet();
        System.assertEquals(C.HTTP_UNAUTHORIZED, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_INACTIVE_MOBILEUSER, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.AUTH_INACTIVE_MOBILEUSER, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test for logging in with a missing username header
     */
    static testMethod void testLoginEmptyUsernameHeader() {

        setUpRequestFullLogin('', null, MobileUserDO.STATUS_ACTIVE, false);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        MobileUserLogin.doGet();
        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_MISSING_USERNAME, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.AUTH_MISSING_USERNAME, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test for logging in with a missing password header
     */
    static testMethod void testLoginEmptyPasswordHeader() {

        setUpRequestFullLogin(null, '', MobileUserDO.STATUS_ACTIVE, false);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        MobileUserLogin.doGet();
        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_MISSING_PASSWORD, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.AUTH_MISSING_PASSWORD, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test for logging in when the MobileUser is already logged in
     */
    static testMethod void testLoginWhenAlreadyLoggedIn() {

        setUpRequestFullLogin(null, null, MobileUserDO.STATUS_ACTIVE, true);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        MobileUserLogin.doGet();
        System.assertEquals(C.HTTP_UNAUTHORIZED, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_ALREADY_LOGGED_IN, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.AUTH_ALREADY_LOGGED_IN, errorMessages[0].getErrorTranslationCode());
    }

    // TESTS FOR AUTHENTICATION USING SESSION TOKEN
    /**
     * Test authenticating with a sessionToken
     */
    static testMethod void testAuthSuccess() {

        // Set up session
        TestUtils.Surveyor surveyor =
            setUpSessionUser(MobileUserDO.STATUS_ACTIVE, true);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        // Authenticate the user
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            surveyor.LoginResult.getSessionToken(),
            true
        );
        System.assertEquals(C.HTTP_OK, loginResult.statusCode);

       // Check that the session token return matches the token created on initial login
        System.assertEquals(
            surveyor.loginResult.getSessionToken(),
            loginResult.getSessionToken()
        );
    }

    /**
     * Test authentication with an empty session token
     */
    static testMethod void testAuthMissingSessionToken() {

        // Set up session
        TestUtils.Surveyor surveyor =
            setUpSessionUser(MobileUserDO.STATUS_ACTIVE, true);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

         // Authenticate the user
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            '',
            true
        );
        System.assertEquals(C.HTTP_BAD_REQUEST, loginResult.statusCode);

        // Check the error message is the correct one
        List<ErrorHandlingRest.ErrorMessage> errorMessages = ErrorHandlingRest.getAllErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_MISSING_SESSIONID, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.AUTH_MISSING_SESSIONID, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test with an invalid session token
     */
    static testMethod void testAuthInvaliSessionToken() {

        // Set up session
        TestUtils.Surveyor surveyor =
            setUpSessionUser(MobileUserDO.STATUS_ACTIVE, true);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        // Authenticate the user
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            'invalidSessionToken',
            true
        );
        System.assertEquals(C.HTTP_UNAUTHORIZED, loginResult.statusCode);

        // Check the error message is the correct one
        List<ErrorHandlingRest.ErrorMessage> errorMessages = ErrorHandlingRest.getAllErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_INVALID_SESSIONID, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.AUTH_INVALID_SESSION, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test authentication when the mobile user has been deactivated
     */
    static testMethod void testAuthInactiveUser() {

        // Set up session
        TestUtils.Surveyor surveyor =
            setUpSessionUser(MobileUserDO.STATUS_ACTIVE, true);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        // Deactivate the Mobile User
        surveyor.user.Status__c = MobileUserDO.STATUS_INACTIVE;
        update(surveyor.user);

        // Authenticate the user
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            surveyor.LoginResult.getSessionToken(),
            true
        );
        System.assertEquals(C.HTTP_UNAUTHORIZED, loginResult.statusCode);

        // Check the error message is the correct one
        List<ErrorHandlingRest.ErrorMessage> errorMessages = ErrorHandlingRest.getAllErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_INACTIVE_MOBILEUSER, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.AUTH_INACTIVE_MOBILEUSER, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test blocking a mobile user
     */
    static testMethod void testBlockingMobileUser() {

        // Set up session
        TestUtils.Surveyor surveyor =
            setUpSessionUser(MobileUserDO.STATUS_ACTIVE, true);

        // Authenticate the user
        MobileUserLoginLogic.setBlockMobileUserLogin(true);
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            surveyor.LoginResult.getSessionToken(),
            true
        );
        System.assertEquals(C.HTTP_UNAUTHORIZED, loginResult.statusCode);

        // Check the error message is the correct one
        List<ErrorHandlingRest.ErrorMessage> errorMessages = ErrorHandlingRest.getAllErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_MOBILE_USER_BLOCKED, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.AUTH_MOBILE_USER_BLOCKED, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test the authentication with a Partner User
     */
    static testMethod void testOAuthAuthentication() {

        // Given a Partner User
        Account a = new Account(Name = 'Test Account');
        insert a;

        Contact partnerContact = new Contact(LastName = 'Partner User', AccountId = a.Id);
        insert partnerContact;

        User partnerUser = TestUtils.getPartnerUser();
        partnerUser.ContactId = partnerContact.Id;
        partnerUser.CommunityNickname = 'someNickName';
        insert partnerUser;

        // When the authentication takes place
        MobileUserLoginLogic.LoginResult result;
        Id resultUserId;
        Contact resultContact;
        System.runAs(partnerUser) {
            result = MobileUserLoginLogic.authenticateMobileUser(null, null, null, null);
            resultUserId = result.getUserId();
            resultContact = result.getContact();
        }

        // The LoginResult is loaded with the user's data
        System.assertEquals(partnerContact.Id, resultContact.Id);
        System.assertEquals(partnerUser.Id, resultUserId);
    }

    /**
     * Test method to check CRUD-FLS permission check while processing Login request
     */
    static testMethod void testDoGetPermissionDenied() {

        setUpRequestFullLogin(null, null, MobileUserDO.STATUS_ACTIVE, true);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        System.RunAs(TestUtils.createChatterExternalUser()) {
            DescribeHandler.resetDescribeHandler();
            Test.startTest();
            MobileUserLogin.doGet();
            Test.stopTest();
        }

        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        System.assertEquals(1, errors.getErrors().size());
        System.assertEquals(C.HTTP_INTERNAL_SERVER_ERROR, RestContext.response.statusCode);
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assert(
            RestContext.response.responseBody.toString().contains(System.Label.ERR_PERMISSIONS)
        );
        System.assertEquals(
            ErrorHandlingRest.ERR_CODE_CRUD_FLS, errorMessages[0].getErrorCode()
        );
        System.assertEquals(
            ErrorHandlingRest.CRUD_FLS, errorMessages[0].getErrorTranslationCode()
        );
    }
}