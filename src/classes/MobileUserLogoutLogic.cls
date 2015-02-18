/**
 * Contains the logic for the MobileUserLogout REST Resource.
 * This is moved into its own class as it is not possible to patch classes
 * in a managed package that is marked as @RestResource
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public with sharing class MobileUserLogoutLogic {

    /**
     * Log a mobile user out of the application. This will clear their session token
     */
    public static void logout() {

        // Check the session and device
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            RestContext.request.headers.get(C.SESSION_TOKEN_HEADER),
            true
        );
        if (loginResult.hasError) {
            // Add the headers
            for(String header : loginResult.headers.keySet()) {
                RestContext.response.addHeader(header, loginResult.headers.get(header));
            }
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
            Restcontext.response.statusCode = loginResult.statusCode;
            return;
        }

        // Create Savepoint to be able to rollback all the DB changes if needed
        Savepoint sp = Database.setSavepoint();
        try {
            GenericObjectCreator mobileUserCreator =
                new GenericObjectCreator(Mobile_User__c.SObjectType);
            // Cleaning up current session token
            mobileUserCreator.populateFields(
                loginResult.mobileUser,
                new Map<Schema.SObjectField, Object> {
                    Mobile_User__c.Session_Token__c => ''
                }
            );
            DBFullAccess.updateSObject(loginResult.mobileUser);
        } catch (GenericObjectCreator.GenericObjectCreatorException genericObjectCreatorException) {
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_CRUD_FLS,
                ErrorHandlingRest.CRUD_FLS,
                System.Label.ERR_PERMISSIONS + '\n\n' + genericObjectCreatorException.getMessage()
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_INTERNAL_SERVER_ERROR);
        } catch (DmlException e) {
            Database.rollback(sp);
            if (ErrorHandlingRest.parseDmlException(e)) {
                throw e;
            }
        }
        RestContext.response.statusCode = ErrorHandlingRest.getStatusCode();
        if (ErrorHandlingRest.checkForErrors()) {
            RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, 'application/json;charset=UTF-8');
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
        }
    }
}