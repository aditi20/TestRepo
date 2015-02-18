/**
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved.
 *
 */
@isTest
private class MobileUserLogoutTest {

    private static final String USERNAME = 'username';
    private static final String PASSWORD = 'password';

    /**
     * Method that prepares the RestContext to send a logout request
     *
     * @param overrideSessionToken - SessionToken to use instead of created one. Null to use created one
     *
     * @return - The logged in surveyor
     */
    static TestUtils.Surveyor setUpLogoutRequest(String overrideSessionToken) {

        // Create the surveyor and log the mobile user in
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor(
            'lNameMULOT',
            USERNAME,
            PASSWORD,
            MobileUserDO.STATUS_ACTIVE,
            true
        );

        // Setup the request
        Map<String, String> headersMap = new Map<String, String>{
            C.SESSION_TOKEN_HEADER => overrideSessionToken == null ? surveyor.loginResult.getSessionToken() : overrideSessionToken
        };
        TestUtils.prepareRestContext(
            TestUtils.getServiceURL('logout'),
            null,
            headersMap
        );
        return surveyor;
    }

    /**
     * Test successful logout
     */
    static testMethod void testLogoutSuccess() {

        setUpLogoutRequest(null);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);
        MobileUserLogout.doGet();
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
    }

    /**
     * Test for failure due to invalide session token
     */
    static testMethod void testLogoutInvalidSessionToken() {

        setUpLogoutRequest('invalidToken');
        MobileUserLoginLogic.setBlockMobileUserLogin(false);
        MobileUserLogout.doGet();
        System.assertEquals(C.HTTP_UNAUTHORIZED, RestContext.response.statusCode);

        // Check the error message is the correct one
        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assertEquals(1, errorMessages.size());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_INVALID_SESSIONID, errorMessages[0].getErrorCode());
        System.assertEquals(ErrorHandlingRest.AUTH_INVALID_SESSION, errorMessages[0].getErrorTranslationCode());
    }

    /**
     * Test method to check CRUD-FLS permission check while processing Logout request 
     */
    static testMethod void testDoGetPermissionDenied() {

        setUpLogoutRequest(null);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        System.RunAs(TestUtils.createChatterExternalUser()) {
            DescribeHandler.resetDescribeHandler();
            Test.startTest();
            MobileUserLogout.doGet();
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