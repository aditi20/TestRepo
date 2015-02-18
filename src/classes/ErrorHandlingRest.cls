/**
 * Class that deals with error handling for the REST API
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 *
 * @author - Owen Davies odavies@grameenfoundation.org
 */
public with sharing class ErrorHandlingRest {

    // Error code static values see https://applab.atlassian.net/wiki/pages/viewpage.action?pageId=19169358
    // These are shown to the MobileUser so they can report with the error to ease support
    // General Error codes. They are in the range 00000 - 09999
    public static final String ERR_CODE_GEN_NO_SPACE = '00002';
    public static final String ERR_CODE_CRUD_FLS = '00005';

    // Authentication Error Codes. They are in the range 10000 - 19999
    public static final String ERR_CODE_AUTH_INVALID_DEVICE        = '10000';
    public static final String ERR_CODE_AUTH_EMPTY_DEVICEID_HEADER = '10001';
    public static final String ERR_CODE_AUTH_INACTIVE_DEVICE       = '10002';
    public static final String ERR_CODE_AUTH_INVALID_CREDENTIALS   = '10003';
    public static final String ERR_CODE_AUTH_INACTIVE_MOBILEUSER   = '10004';
    public static final String ERR_CODE_AUTH_MISSING_USERNAME      = '10005';
    public static final String ERR_CODE_AUTH_MISSING_PASSWORD      = '10006';
    public static final String ERR_CODE_AUTH_MISSING_SESSIONID     = '10007';
    public static final String ERR_CODE_AUTH_INVALID_SESSIONID     = '10008';
    public static final String ERR_CODE_AUTH_SES_DEV_MISMATCH      = '10009';
    public static final String ERR_CODE_AUTH_ALREADY_LOGGED_IN     = '10010';
    public static final String ERR_CODE_DEVICE_NOT_FOUND           = '10011';
    public static final String ERR_CODE_DEVICE_ID_MISMATCH         = '10012';
    public static final String ERR_CODE_DEVICE_CREATION_FAILED     = '10013';
    public static final String ERR_CODE_IMEI_IN_USE                = '10014';
    public static final String ERR_CODE_AUTH_IMEI_MISMATCH         = '10015';
    public static final String ERR_CODE_AUTH_MOBILE_USER_BLOCKED   = '10017';

    // Survey Error Codes. They are in the range 20000 - 29999
    public static final String ERR_CODE_SURVEY_ID_NOT_EXIST          = '20000';
    public static final String ERR_CODE_SURVEY_MISSING_XFORM         = '20001';
    public static final String ERR_CODE_SURVEY_BLANK_XFORM           = '20002';
    public static final String ERR_CODE_SUB_ID_MISSING               = '20003';
    public static final String ERR_CODE_SUB_SURVEY_CLOSED            = '20004';
    public static final String ERR_CODE_SUB_SURVEY_UNAVAILABLE       = '20005';
    public static final String ERR_CODE_SUB_MISSING_XML              = '20006';
    public static final String ERR_CODE_SUB_DUPLICATE                = '20007';
    public static final String ERR_CODE_SUB_ID_MISSING_MEDIA         = '20008';
    public static final String ERR_CODE_SUB_CORRUPT_FIELD_MAP        = '20009';
    public static final String ERR_CODE_SUB_BAD_FIELD_MAP            = '20010';
    public static final String ERR_CODE_SUB_INVALID_SUBMISSION_ID    = '20011';
    public static final String ERR_CODE_SUB_INVALID_CASCADING        = '20012';
    public static final String ERR_CODE_SUB_MISSING_REF_OBJECT       = '20014';
    public static final String ERR_CODE_SUB_INVALID_GPS              = '20017';
    public static final String ERR_CODE_SURVEY_ID_MISSING            = '20018';

    // Sync Error Codes. They are in the range 30000 - 39999
    public static final String ERR_CODE_SYNC_SCHEMA_CORRUPT              = '30000';
    public static final String ERR_CODE_SYNC_GPS_FAIL                    = '30001';
    public static final String ERR_CODE_MISSING_RESOURCEID               = '30002';
    public static final String ERR_CODE_RESOURCE_ID_NOT_EXIST            = '30003';
    public static final String ERR_CODE_RESOURCE_TYPE_NOT_SUPPORTED      = '30004';
    public static final String ERR_CODE_SYNC_TASK_TEMP_BAD_TYPE          = '30005';
    public static final String ERR_CODE_SYNC_TASK_RESOURCE_NOT_SPECIFIED = '30006';
    public static final String ERR_CODE_JOB_TEMPLATE_REMOVED             = '30007';
    public static final String ERR_CODE_TASK_TEMPLATE_REMOVED            = '30008';

    // Parent child org communication Error codes
    public static final String DML_EXCEPTION = 'DML_EXCEPTION';
    public static final String GENERAL_EXCEPTION = 'GENERAL_EXCEPTION';
    public static final String INVALID_DATA = 'INVALID_DATA';
    public static final String DUPLICATE_VALUE = 'DUPLICATE_VALUE';

    // Error translation message codes. These are the codes that are sent to the
    // device so the device can locate the correct xlation for the error message
    // that is shown to the MobileUser

    // General xlation codes
    public static final String GEN_NO_SPACE = 'GEN_NO_SPACE';
    public static final String GENERAL_ERROR = 'GENERAL_ERROR';
    public static final String CRUD_FLS = 'CRUD_FLS';

    // Authentication xlation codes
    public static final String AUTH_INVALID_DEVICE          = 'AUTH_INVALID_DEVICE';
    public static final String AUTH_MISSING_DEVICEID        = 'AUTH_MISSING_DEVICEID';
    public static final String AUTH_INACTIVE_DEVICE         = 'AUTH_INACTIVE_DEVICE';
    public static final String AUTH_INVALID_CREDENTIALS     = 'AUTH_INVALID_CREDENTIALS';
    public static final String AUTH_INACTIVE_MOBILEUSER     = 'AUTH_INACTIVE_MOBILEUSER';
    public static final String AUTH_MISSING_USERNAME        = 'AUTH_MISSING_USERNAME';
    public static final String AUTH_MISSING_PASSWORD        = 'AUTH_MISSING_PASSWORD';
    public static final String AUTH_MISSING_SESSIONID       = 'AUTH_MISSING_SESSIONID';
    public static final String AUTH_INVALID_SESSION         = 'AUTH_INVALID_SESSION';
    public static final String AUTH_SESSION_DEVICE_MISMATCH = 'AUTH_SESSION_DEVICE_MISMATCH';
    public static final String AUTH_ALREADY_LOGGED_IN       = 'AUTH_ALREADY_LOGGED_IN';
    public static final String AUTH_DEVICE_NOT_FOUND        = 'AUTH_DEVICE_NOT_FOUND';
    public static final String AUTH_DEVICE_ID_MISMATCH      = 'AUTH_DEVICE_ID_MISMATCH';
    public static final String AUTH_FAILED_TO_CREATE_DEVICE = 'AUTH_FAILED_TO_CREATE_DEVICE';
    public static final String AUTH_DEVICE_ID_RESET         = 'AUTH_DEVICE_ID_RESET';
    public static final String AUTH_IMEI_MISMATCH           = 'AUTH_IMEI_MISMATCH';
    public static final String AUTH_MOBILE_USER_BLOCKED     = 'AUTH_MOBILE_USER_BLOCKED';

    // Survey xlation codes
    public static final String SURVEY_FORMLIST_ID_INVALID       = 'SURVEY_FORMLIST_ID_INVALID';
    public static final String SURVEY_FORMLIST_NO_XFORM         = 'SURVEY_FORMLIST_NO_XFORM';
    public static final String SURVEY_FORMLIST_XFORM_EMPTY      = 'SURVEY_FORMLIST_XFORM_EMPTY';
    public static final String SURVEY_SUB_MISSING_SURVEY_ID     = 'SURVEY_SUB_MISSING_SURVEY_ID';
    public static final String SURVEY_SUB_SURVEY_CLOSED         = 'SURVEY_SUB_SURVEY_CLOSED';
    public static final String SURVEY_SUB_SURVEY_UNAVAILABLE    = 'SURVEY_SUB_SURVEY_UNAVAILABLE';
    public static final String SURVEY_SUB_MISSING_XML           = 'SURVEY_SUB_MISSING_XML';
    public static final String SURVEY_SUB_DUPLICATE_SUBMISSION  = 'SURVEY_SUB_DUPLICATE_SUBMISSION';
    public static final String SURVEY_SUB_MISSING_SUB_ID        = 'SURVEY_SUB_MISSING_SUB_ID';
    public static final String SURVEY_SUB_BROKEN_FIELD_MAPPING  = 'SURVEY_SUB_BROKEN_FIELD_MAPPING';
    public static final String SURVEY_SUB_FIELD_MAPPING_ERROR   = 'SURVEY_SUB_FIELD_MAPPING_ERROR';
    public static final String SURVEY_SUB_INVALID_SUBMISSION_ID = 'SURVEY_SUB_INVALID_SUBMISSION_ID';
    public static final String SURVEY_SUB_INVALID_CASCADING     = 'SURVEY_SUB_INVALID_CASCADING';
    public static final String SURVEY_SUB_MISSING_REF_OBJECT    = 'SURVEY_SUB_MISSING_REF_OBJECT';
    public static final String SURVEY_SUB_INVALID_GPS           = 'SURVEY_SUB_INVALID_GPS';
    public static final String SURVEY_FORMLIST_ID_MISSING       = 'SURVEY_FORMLIST_ID_MISSING';

    // Sync xlation codes
    public static final String SYNC_JOB_DEF_CORRUPT             = 'SYNC_JOB_DEF_CORRUPT';
    public static final String SYNC_JOB_GPS_FAIL                = 'SYNC_JOB_GPS_FAIL';
    public static final String SYNC_MISSING_RESOURCEID          = 'SYNC_MISSING_RESOURCEID';
    public static final String SYNC_RESOURCE_ID_INVALID         = 'SYNC_RESOURCE_ID_INVALID';
    public static final String SYNC_RESOURCE_TYPE_NOT_SUPPORTED = 'SYNC_RESOURCE_TYPE_NOT_SUPPORTED';
    public static final String SYNC_BAD_TASK_TYPE               = 'SYNC_BAD_TASK_TYPE';
    public static final String SYNC_JOB_TEMPLATE_DELETED        = 'SYNC_JOB_TEMPLATE_DELETED';
    public static final String SYNC_TASK_TEMPLATE_DELETED       = 'SYNC_TASK_TEMPLATE_DELETED';
    public static final String SYNC_TASK_WITHOUT_RESOURCE       = 'SYNC_TASK_WITHOUT_RESOURCE';

    // The content type for the response on error
    public static final String ERROR_CONTENT_TYPE = C.CONTENT_TYPE_JSON_UTF;

    // Object that contains a list that contains all the error messages that have
    // been generated during a single invocation of Apex. This will be the list
    // that is serialized and returned to the device via the Response.Body
    private static ErrorMessages errors;
    private static Boolean hasError = true;
    private static Integer statusCode;

    // List of the error messages generated in this context that should be displayed on an ApexPage
    private static List<ApexPageErrorMessage> pageErrors = new List<ApexPageErrorMessage>();

    public List<ApexPageErrorMessage> getApexPageErrors() {
        return pageErrors;
    }

    public static void addApexPageError(String errorMessage, ApexPages.Severity severity) {
        pageErrors.add(new ApexPageErrorMessage(errorMessage, severity));
    }

    public static void clearApexPageErrors() {
        pageErrors.clear();
    }

    public static Boolean hasPageErrors() {
        return pageErrors.size() != 0;
    }

    public static void addApexPageErrorsToPage() {
        for (ApexPageErrorMessage pageError : pageErrors) {
            ApexPages.addMessage(new ApexPages.Message(
                pageError.severity,
                pageError.defaultErrorMsg
            ));
        }
    }

    /**
     * Add an error message to the error message object
     *
     * @param errorCode            - The error code
     * @param errorTranslationCode - The error translation code
     * @param defaultErrorMsg      - The default error message that is sent to the device. This is always in English
     */
    public static void addErrorMsg(String errorCode, String errorTranslationCode, String defaultErrorMsg) {
        if (errors == null) {
            errors = new ErrorMessages();
        }
        errors.addNewErrorMsg(errorCode, errorTranslationCode, defaultErrorMsg);
    }

    /**
     * Empty the error messages list
     */
    public static void clearAllErrorMsgs() {
        if (errors != null) {
            errors.clearErrors();
        }
    }

    /**
     * Return all the errors added to the errorMessages list
     */
    public static List<ErrorMessage> getAllErrors() {
        if (errors != null) {
            return errors.getErrors();
        }
        return null;
    }

    /**
     * Get the JSON String representing all the errors
     */
    public static String getErrorJson() {

        if (errors == null) {
            return '';
        }
        return JSON.serialize(errors);
    }

    /**
     * Check that errors exists
     */
    public static Boolean checkForErrors() {
        if (errors == null) {
            return false;
        }
        return errors.hasErrors();
    }

    /**
     * Set the status code for the current invocation
     *
     * @ param code
     */
    public static void setStatusCode(Integer code) {
        if (statusCode == null) {
            statusCode = code;
        }
    }

    /**
     * Get the status code for the current apex invocation
     * Will return 200 if not set and will always return the code that
     * was first encountered
     *
     * @return - The status code
     */
    public static Integer getStatusCode() {
        return statusCode == null ? C.HTTP_OK : statusCode;
    }

    /**
     * Parse a DML exception and see if it is an error we should catch and convert
     * to our own error message type
     *
     * @param e - The exception
     *
     * @return - Boolean indicating if the exception should be thrown
     */
    public static Boolean parseDmlException(System.DmlException e) {

        Boolean throwError = true;
        for (Integer i = 0; i < e.getNumDml(); i++) {
            if (e.getDmlType(i) == System.StatusCode.STORAGE_LIMIT_EXCEEDED) {
                throwError = false;
                ErrorHandlingRest.addErrorMsg(
                    ErrorHandlingRest.ERR_CODE_GEN_NO_SPACE,
                    ErrorHandlingRest.GEN_NO_SPACE,
                    'The Salesforce org has run out of space'
                );
                ErrorHandlingRest.setStatusCode(C.HTTP_SERVICE_UNAVAILABLE);
            }
        }
        return throwError;
    }


    /**
     * Class the represents the ErrorMessages. Allows for
     * easy JSON serialization
     */
    public class ErrorMessages {

        private List<ErrorMessage> error;

        public ErrorMessages() {
            this.error = new List<ErrorMessage>();
        }

        /**
         * Add an error message to the errorMessages list
         *
         * @param errorCode            - The error code
         * @param errorTranslationCode - The error translation code
         * @param defaultErrorMsg      - The default error message that is sent to the device. This is always in English
         */
        public void addNewErrorMsg(String errorCode, String errorTranslationCode, String defaultErrorMsg) {
            error.add(
                new ErrorMessage(
                    errorCode,
                    errorTranslationCode,
                    defaultErrorMsg
                )
            );
        }

        /**
         * Clear error messages
         */
        public void clearErrors() {
            this.error.clear();
            hasError = false;
        }

        /**
         * Get all the errors
         *
         * @return - A list of the errors
         */
        public List<ErrorMessage> getErrors() {
            return this.error;
        }

        /**
         * Indicate if there are errors
         *
         * @return - Boolean indicating if there are errors
         */
        public Boolean hasErrors() {
            return this.error.size() > 0;
        }
    }

    /**
     * Base class for the Error Message
     */
    public virtual class ErrorMessage {
        private String defaultErrorMsg;
        private String errorCode;
        private String errorTranslationCode;

        public ErrorMessage(String defaultErrorMsg) {
            this.defaultErrorMsg = defaultErrorMsg;
        }

        public ErrorMessage(String errorCode, String errorTranslationCode, String defaultErrorMsg) {
            this(defaultErrorMsg);
            this.errorCode = errorCode;
            this.errorTranslationCode = errorTranslationCode;
        }

        /**
         * Getter for the errorCode
         *
         *@return - The errorCode string
         */
        public String getErrorCode() {
            return this.errorCode;
        }

        /**
         * Getter for the errorTranslationCode
         *
         * @return - The errorTranslationCode string
         */
        public String getErrorTranslationCode() {
            return this.errorTranslationCode;
        }

        /**
         * Getter for the defaultErrorMsg
         *
         * @return - The defaultErrorMsg string
         */
        public String getDefaultErrorMsg() {
            return this.defaultErrorMsg;
        }
    }

    /**
     * Error message for an error generated that needs to be feed back to the user via ApexPages
     */
    public class ApexPageErrorMessage extends ErrorMessage {

        private ApexPages.Severity severity;

        public ApexPageErrorMessage(String defaultErrorMsg, ApexPages.Severity severity) {
            super(defaultErrorMsg);
            this.severity = severity;
        }
    }
}
