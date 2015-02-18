/**
 * Contains the logic for the SurveyFormList REST Resource.
 * This is moved into its own class as it is not possible to patch classes
 * in a managed package that is marked as @RestResource
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public with sharing class SurveyFormListLogic {

    public static void processGetRequest() {

        // Autheticate the MobileUser
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            RestContext.request.headers.get(C.SESSION_TOKEN_HEADER),
            true
        );

        // Check user was authenticated properly
        Restcontext.response.statusCode = loginResult.statusCode;
        if (loginResult.hasError) {
            // Add the headers
            for(String header : loginResult.headers.keySet()) {
                RestContext.response.addHeader(header, loginResult.headers.get(header));
            }
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
        }
        else {

            // Create Savepoint to be able to rollback all the DB changes if needed
            Savepoint sp = Database.setSavepoint();
            String result;

            try {
                ServicesController sc = new ServicesController();

                String surveyVersionId = RestContext.request.headers.get(C.SURVEY_ID_HEADER) == null ?
                    RestContext.request.params.get('id')
                    : RestContext.request.headers.get(C.SURVEY_ID_HEADER);

                result = sc.processDataAux(
                    surveyVersionId,
                    loginResult.MobileUser.Contact__c
                );
            } catch (GenericObjectCreator.GenericObjectCreatorException genericObjectCreatorException) {
                Database.rollback(sp);
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
                RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, C.CONTENT_TYPE_JSON_UTF);
                RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
            } else {
                RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, 'text/xml;charset=UTF-8');
                RestContext.response.addHeader('X-OpenRosa-Version', '1.0');
                RestContext.response.responseBody = Blob.valueOf(result);
            }
        }
    }
}
