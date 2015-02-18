/**
 * Contains the logic for the MobileUserLogin REST Resource.
 * This is moved into its own class as it is not possible to patch classes
 * in a managed package that is marked as @RestResource
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - dcaballero
 * @author - Alejandro De Gregorio Tort
 * @author - Owen Davies
 */
public with sharing class MobileUserLoginLogic {

    // Allow old MobbileUsers to login. This is only for the ApplicationUpdate endpoint
    // so that existing Field staff can get the new apk. All other endpoints should leave
    // this variable as false. Once the switch over to partner community users has been completed
    // then all MobileUser login logic will be removed
    public static Boolean blockMobileUserLogin = true;
    public static void setBlockMobileUserLogin(Boolean value) {
        blockMobileUserLogin = value;
    }

    /**
     * Process the GET request.
     * This method allows all the logic to be moved out of the RestResource class
     */
    public static void processGetRequest() {

        String username = RestContext.request.headers.get(C.USERNAME_HEADER);
        String password = RestContext.request.headers.get(C.PASSWORD_HEADER);
        String imei     = RestContext.request.headers.get(C.IMEI_HEADER);

        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            username, password, '', false
        );

        RestContext.response.statusCode = loginResult.statusCode;
        if (loginResult.hasError) {

            // Add the headers
            for(String header : loginResult.headers.keySet()) {
                RestContext.response.addHeader(header, loginResult.headers.get(header));
            }
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());

        }
        else {
            RestContext.response.responseBody =
                Blob.valueOf(loginResult.mobileUser.Session_Token__c);
        }
    }

    /**
     * Check the authentication data to log the user in or valididate their session.
     * Requries: Username, Password, DeviceId and IMEI OR
     *             SessionToken and DeviceId
     *
     * If authenticating using username and password the Mobile User must not be already logged in
     *  The authentication will be carried out using the login method
     * If authenticating using sessionToken then the Mobile User must be already logged in
     *  The authentication is done using the validateSession method
     *
     * @param username          - A string with the username to login
     * @param password          - A string with the passwod to login
     * @param sessionToken      - A string with the session token to validate the session
     * @param usingSessionToken - A flag to indicate that the Mobile User is being
     *                              authenticated using a session token
     *
     * @retun - An instance of LoginResult with the status code and a message
     */
    public static LoginResult authenticateMobileUser(
            String username,
            String password,
            String sessionToken,
            Boolean usingSessionToken
    ) {

        // Set a savepoint to rollback to
        SavePoint sp = Database.setSavepoint();
        LoginResult loginResult;

        try {

            loginResult = new LoginResult();
            if (UserInfo.getUserType() == 'PowerPartner') {
                return loadPartnerUserData(UserInfo.getUserId());
            }

            if (blockMobileUserLogin) {
                loginResult.addError(
                    ErrorHandlingRest.ERR_CODE_AUTH_MOBILE_USER_BLOCKED,
                    ErrorHandlingRest.AUTH_MOBILE_USER_BLOCKED,
                    'You cannot log in with a mobile user: ' + username
                );
                loginResult.statusCode = C.HTTP_UNAUTHORIZED;
                return loginResult;
            }

            // Validate the data received
            loginResult = validateAuthenticationData(
                username,
                password,
                sessionToken,
                usingSessionToken
            );
            if (loginResult.hasError) {
                return loginResult;
            }

            if (usingSessionToken) {

                // Validate session
                return MobileUserLoginLogic.validateSession(sessionToken, loginResult);
            }
            else {

                // Login with user and password
                return MobileUserLoginLogic.login(username, password, loginResult);
            }
        } catch (GenericObjectCreator.GenericObjectCreatorException genericObjectCreatorException) {
            loginResult.addError(
                ErrorHandlingRest.ERR_CODE_CRUD_FLS,
                ErrorHandlingRest.CRUD_FLS,
                System.Label.ERR_PERMISSIONS + '\n\n' + genericObjectCreatorException.getMessage()
            );
            loginResult.statusCode = C.HTTP_INTERNAL_SERVER_ERROR;
        } catch (DmlException e) {
            Database.rollback(sp);
            Boolean throwError = true;
            for (Integer i = 0; i < e.getNumDml(); i++) {
                if (e.getDmlType(i) == StatusCode.STORAGE_LIMIT_EXCEEDED) {
                    throwError = false;
                    loginResult.addError(
                        ErrorHandlingRest.ERR_CODE_GEN_NO_SPACE,
                        ErrorHandlingRest.GEN_NO_SPACE,
                        'The Salesforce org has run out of space'
                    );
                    loginResult.statusCode = C.HTTP_SERVICE_UNAVAILABLE;
                }
            }
            if (throwError) {
                throw e;
            }
        }
        return loginResult;
    }

    /**
     * Load the info of the partner user into the login result
     */
    public static LoginResult loadPartnerUserData(Id userId) {
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name,
                Contact.LastName,
                Contact.OwnerId
            }
        );
        GenericObjectCreator userCreator =
            new GenericObjectCreator(User.SObjectType);
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                User.ContactId
            }
        );
        LoginResult result = new LoginResult();
        result.statusCode = C.HTTP_OK;
        result.isPartnerUser = true;
        result.userContact = [
            SELECT
                Id,
                Name,
                LastName,
                OwnerId
            FROM
                Contact
            WHERE
                Id IN (SELECT ContactId FROM User WHERE Id = :userId)
        ];

        return result;
    }

    /**
     * Validate the login data and create the session
     *
     * @param username - A string with the username to login
     * @param password - A string with the password to login
     * @param loginResult - The LoginResult for the MobileUser being authenticated
     *
     * @return - An instance of LoginResult with the status code and a message
     */
     public static LoginResult login(
            String username,
            String password,
            LoginResult loginResult
    ) {
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();
        // Authentication data provided is present and so validate the MobileUser
        loginResult =
            validateMobileUser(null, username, password, loginResult);
        if (loginResult.hasError) {
            return loginResult;
        }

        DateTime now = DateTime.now();

        // If the user is logged, we shouldn't change login time
        if (String.isEmpty(loginResult.mobileUser.Session_Token__c)) {
            // Update the mobile user object and generate the session token
            mobileUserCreator.populateFields(
                loginResult.mobileUser,
                new Map<Schema.SObjectField, Object> {
                    Mobile_User__c.Last_Login__c => DateTime.now(),
                    Mobile_User__c.Session_Token__c =>
                        EncodingUtil.base64Encode(Crypto.generateAesKey(192))
                }
            );
        }
        mobileUserCreator.populateFields(
            loginResult.mobileUser,
            new Map<Schema.SObjectField, Object> {
                Mobile_User__c.Last_Activity__c => DateTime.now()
            }
        );
        mobileUserCreator.checkObjectUpdateable();
        DBFullAccess.UpdateSObject(loginResult.mobileUser);

        loginResult.statusCode = C.HTTP_OK;
        return loginResult;
    }

    /**
     * Check if the session is valid
     * Also updates the Mobile_User
     *
     * @param sessionToken - A string with the session token to validate
     * @param loginResult - The LoginResult for the MobileUser being authenticated
     *
     * @return - An instance of LoginResult with the status code and a message
     */
    public static LoginResult validateSession(String sessionToken, LoginResult loginResult) {
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();

        // Authentication data provided is present so validate the MobileUser
        loginResult =
            validateMobileUser(sessionToken, null, null, loginResult);
        if (loginResult.hasError) {
            return loginResult;
        }

        // Update the mobile user object
        mobileUserCreator.populateFields(
            loginResult.mobileUser,
            new Map<Schema.SObjectField, Object> {
                Mobile_User__c.Last_Activity__c => DateTime.now()
            }
        );
        mobileUserCreator.checkObjectUpdateable();
        DBFullAccess.UpdateSObject(loginResult.mobileUser);

        loginResult.statusCode = C.HTTP_OK;
        return loginResult;
    }

    /**
     * Check that the data sent for the login is valid
     *
     * @param username          - A string with the username for the authentication
     * @param password          - A string with the password for the authentication
     * @param sessionToken      - A string with the session token for the authentication
     * @param usingSessionToken - A flag to indicate that authentication is being done
     *                             using a sessionToken
     *
     * @return - An instance of LoginResult with the status and a message
     */
     public static LoginResult validateAuthenticationData(
            String username,
            String password,
            String sessionToken,
            Boolean usingSessionToken
    ) {

        LoginResult loginResult = new LoginResult();

        // Checking that the request has all the needed parameters
        if (usingSessionToken) {

            // See what header was missing and add the appropriate error message
            if (String.isEmpty(sessionToken)) {
                loginResult.addError(
                    ErrorHandlingRest.ERR_CODE_AUTH_MISSING_SESSIONID,
                    ErrorHandlingRest.AUTH_MISSING_SESSIONID,
                    'The Session-Id header was missing or empty'
                );
                loginResult.statusCode = C.HTTP_BAD_REQUEST;
            }
        }
        else {
            if (String.isEmpty(username)) {
               loginResult.addError(
                    ErrorHandlingRest.ERR_CODE_AUTH_MISSING_USERNAME,
                    ErrorHandlingRest.AUTH_MISSING_USERNAME,
                    'Username was not provided in request'
                );
                loginResult.statusCode = C.HTTP_BAD_REQUEST;
            }
            else if (String.isEmpty(password)) {
               loginResult.addError(
                    ErrorHandlingRest.ERR_CODE_AUTH_MISSING_PASSWORD,
                    ErrorHandlingRest.AUTH_MISSING_PASSWORD,
                    'Password was not provided in request'
                );
                loginResult.statusCode = C.HTTP_BAD_REQUEST;
            }
        }
        return loginResult;
    }

    /**
     * Validate the MobileUser. This will either validate the MobileUser.Session_Token or
     * attempt to log the MobileUser in to the system.
     *
     * @param sessionToken - Session Token for the MobileUser.
     *                         Can be empty if username and password supplied instead
     * @param username     - Username for the MobileUser. Can be empty if a sessionToken passed
     * @param password     - Password for the MobileUser. Can be empty if a sessionToken passed
     * @param loginResult  - The loginResult for the MobileUser. Should have already have
     *                         had the device validated
     *
     * @return - The loginResult that contains the authentication information
     */
    private static LoginResult validateMobileUser(
            String sessionToken,
            String username,
            String password,
            LoginResult loginResult
    ) {
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name,
                Contact.LastName,
                Contact.OwnerId
            }
        );
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Mobile_User__c.Contact__c,
                Mobile_User__c.Status__c,
                Mobile_User__c.Username__c,
                Mobile_User__c.Password__c,
                Mobile_User__c.Session_Token__c,
                Mobile_User__c.Last_Activity__c
            }
        );
        // If no session token present assume that the MobileUser is logging in
        if (String.isEmpty(sessionToken)) {

            List<Mobile_User__c> mobileUsers = DBFullAccess.QuerySObject(
                'SELECT ' +
                    'Id, ' +
                    'Name, ' +
                    'Session_Token__c, ' +
                    'Status__c, ' +
                    'Contact__c, ' +
                    'Contact__r.Name, ' +
                    'Contact__r.LastName, ' +
                    'Contact__r.OwnerId ' +
                'FROM ' +
                    'Mobile_User__c ' +
                'WHERE ' +
                    'Username__c = \'' + String.escapeSingleQuotes(username) + '\'' +
                    'AND Password__C = \'' + String.escapeSingleQuotes(password) + '\''
            );
            if (mobileUsers.isEmpty()) {
                loginResult.addError(
                    ErrorHandlingRest.ERR_CODE_AUTH_INVALID_CREDENTIALS,
                    ErrorHandlingRest.AUTH_INVALID_CREDENTIALS,
                    'The login credentials for username:' + username +
                        ' are not recognised'
                );
                loginResult.statusCode = C.HTTP_UNAUTHORIZED;
                return loginResult;
            }

            // If a session token already exists for the user then they can be considered as
            // already logged in so fail the login
            if (!String.isEmpty(mobileUsers[0].Session_Token__c)) {
                loginResult.addError(
                    ErrorHandlingRest.ERR_CODE_AUTH_ALREADY_LOGGED_IN,
                    ErrorHandlingRest.AUTH_ALREADY_LOGGED_IN,
                    'The MobileUser with username: ' + username + ' is already logged in'
                );
                loginResult.statusCode = C.HTTP_UNAUTHORIZED;
                return loginResult;
            }
            loginResult.mobileUser = mobileUsers[0];
        }
        else {
            List<Mobile_User__c> mobileUsers = DBFullAccess.QuerySObject(
                'SELECT ' +
                    'Id, ' +
                    'Name, ' +
                    'Session_Token__c, ' +
                    'Status__c, ' +
                    'Contact__c, ' +
                    'Contact__r.Name, ' +
                    'Contact__r.LastName, ' +
                    'Contact__r.OwnerId ' +
                'FROM ' +
                    'Mobile_User__c ' +
                'WHERE ' +
                    'Session_Token__c = \'' + String.escapeSingleQuotes(sessionToken) + '\''
            );
            if (mobileUsers.isEmpty()) {
                loginResult.addError(
                    ErrorHandlingRest.ERR_CODE_AUTH_INVALID_SESSIONID,
                    ErrorHandlingRest.AUTH_INVALID_SESSION,
                    'The Session-Id ' + sessionToken + ' was not found on the system'
                );
                loginResult.statusCode = C.HTTP_UNAUTHORIZED;
                return loginResult;
            }
            loginResult.mobileUser = mobileUsers[0];
        }

        // Check that the MobileUser is Active
        if (loginResult.mobileUser.Status__c != MobileUserDO.STATUS_ACTIVE) {
            loginResult.addError(
                ErrorHandlingRest.ERR_CODE_AUTH_INACTIVE_MOBILEUSER,
                ErrorHandlingRest.AUTH_INACTIVE_MOBILEUSER,
                'The MobileUser ' + loginResult.mobileUser.Name + 'has been deactivated'
            );
            loginResult.statusCode = C.HTTP_UNAUTHORIZED;
            return loginResult;
        }
        return loginResult;
    }

    /**
     * Get the JSON response for successful login
     *
     * @param result - The login result
     *
     * @return - A JSON string with the session token
     */
    private static String getJsonResponse(LoginResult result) {
        return '{"token" : "' + result.mobileUser.Session_Token__c + '"}';
    }

    /**
     * Class used to set the result variables in a login attemp
     */
    public class LoginResult {

        public Integer statusCode {
            get;
            set {

                // Add the authenticate header for the 401 responses
                if(value == C.HTTP_UNAUTHORIZED) {
                    this.headers.put(C.AUTHENTICATE_HEADER, 'none');
                }
                statusCode = value;
            }
        }
        public Mobile_User__c mobileUser;
        public Boolean hasError;
        public Map<String, String> headers;
        public Contact userContact;

        public Boolean isPartnerUser;

        /**
         * Constructor
         */
        public LoginResult() {
            this.hasError = false;
            this.headers = new Map<String, String>();
            this.isPartnerUser = false;
        }

        /**
         * Add an error to the LoginResult. This will also add the Error to the ErrorHandlingRest.errorMessages list
         *
         * @param errorCode            - The error code
         * @param errorTranslationCode - The error translation code
         * @param defaultErrorMsg      - The default error message that is sent to the device. This is always in English
         */
        public void addError(String errorCode, String errorTranslationCode, String defaultErrorMsg) {
            this.hasError = true;
            ErrorHandlingRest.addErrorMsg(errorCode, errorTranslationCode, defaultErrorMsg);

            // Add a header for the content type
            headers.put(C.CONTENT_TYPE_HEADER, C.CONTENT_TYPE_JSON_UTF);
        }

        public Contact getContact() {
            return isPartnerUser ? this.userContact : this.mobileUser.Contact__r;
        }

        public String getSessionToken() {
            return isPartnerUser ? UserInfo.getSessionId() : this.mobileUser.Session_Token__c;
        }

        public Id getUserId() {
            return isPartnerUser ? UserInfo.getUserId() : this.mobileUser.Id;
        }

        public Id getAttachmentParentId() {
            return isPartnerUser ? this.userContact.Id : this.mobileUser.Id;
        }
    }
}