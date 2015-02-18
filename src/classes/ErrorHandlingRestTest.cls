/**
 * Test class for the error handling for the REST API
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 *
 * @author - Owen Davies odavies@grameenfoundation.org
 */
 @isTest
public with sharing class ErrorHandlingRestTest {

    /**
     * Test apex page errors
     */
    static testMethod void testAddingErrorsToPage() {
        ErrorHandlingRest.addApexPageError('message', ApexPages.Severity.Error);
        System.assertEquals(0, ApexPages.getMessages().size());
        ErrorHandlingRest.addApexPageErrorsToPage();
        System.assertEquals(1, ApexPages.getMessages().size());
    }

    /**
     * Test clearing errors
     */
    static testMethod void testClearingPageErrors() {
        ErrorHandlingRest.addApexPageError('message', ApexPages.Severity.Error);
        System.assert(ErrorHandlingRest.hasPageErrors());
        ErrorHandlingRest.clearApexPageErrors();
        System.assert(!ErrorHandlingRest.hasPageErrors());
    }

    /**
     * Test adding an error message to the error message list
     */
    static testMethod void testAddingError() {

        String errorMsgString = 'Mobile User is already logged in on another device';

        ErrorHandlingRest.addErrorMsg(
            ErrorHandlingRest.AUTH_ALREADY_LOGGED_IN,
            ErrorHandlingRest.ERR_CODE_AUTH_ALREADY_LOGGED_IN,
            errorMsgString
        );
        System.assertEquals(1, ErrorHandlingRest.getAllErrors().size());
        ErrorHandlingRest.ErrorMessage errorMessage = ErrorHandlingRest.getAllErrors().get(0);
        System.assertEquals(ErrorHandlingRest.AUTH_ALREADY_LOGGED_IN, errorMessage.getErrorCode());
        System.assertEquals(ErrorHandlingRest.ERR_CODE_AUTH_ALREADY_LOGGED_IN, errorMessage.getErrorTranslationCode());
        System.assertEquals(errorMsgString, errorMessage.getDefaultErrorMsg());
    }

    /**
     * Test clearing the errorMessages list
     */
    static testMethod void testClearingErrors() {

        String errorMsgString = 'Mobile User is already logged in on another device';

        ErrorHandlingRest.addErrorMsg(
            ErrorHandlingRest.AUTH_ALREADY_LOGGED_IN,
            ErrorHandlingRest.ERR_CODE_AUTH_ALREADY_LOGGED_IN,
            errorMsgString
        );
        System.assertEquals(1, ErrorHandlingRest.getAllErrors().size());
        ErrorHandlingRest.clearAllErrorMsgs();
        System.assertEquals(0, ErrorHandlingRest.getAllErrors().size());
    }
}
