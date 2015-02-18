/**
 * Base Exception class. Class that provides the generic error handling.
 * The class acts as a container to propagate exception messages back to the mobile client
 */
public virtual with sharing class BaseException extends Exception {

    private String twErrorCode;
    private String twXlationCode;
    private Integer statusCode;
    private String defaultMessage;

    // Indicates if the error should cause a DB rollback. This is not always the case
    // as an error message may want to be returned to the client without the data being rolled back
    private Boolean fatalError;

    public BaseException(String message, String[] args) {
        this.setMessage(String.format(message, args));
    }

    public BaseException(
            String twErrorCode,
            String twXlationCode,
            Integer statusCode,
            String defaultMessage,
            Boolean fatalError
    ) {
        this.twErrorCode = twErrorCode;
        this.twXlationCode = twXlationCode;
        this.statusCode = statusCode;
        this.defaultMessage = defaultMessage;
        this.fatalError = fatalError;
    }

    /**
     * Get the twErrorCode
     *
     * @return - The twErrorCode
     */
    public String getTwErrorCode() {
        return this.twErrorCode;
    }

    /**
     * Set the twErrorCode
     *
     * @param errorCode - The twErrorCode. Defined in ErrorHandlingRest.cls
     */
    public void setTwErrorCode(String errorCode) {
        this.twErrorCode = errorCode;
    }

    /**
     * Get the twXlationCode
     *
     * @return - The twXlationCode
     */
    public String getTwXlationCode() {
        return this.twXlationCode;
    }

    /**
     * Set the twXlationCode
     *
     * @param xlationCode - The xlation code for the exception
     */
    public void setTwXlationCode(String xlationCode) {
        this.twXlationCode = xlationCode;
    }

    /**
     * Get the status code
     *
     * @return - The HTTP status code for the exception
     */
    public Integer getStatusCode() {
        return this.statusCode;
    }

    /**
     * Set the HTTP status code for the exception
     *
     * @param statusCode - The HTTP status code for the exception
     */
    public void setStatusCode(Integer statusCode) {
        this.statusCode = statusCode;
    }

    /**
     * Get the default message
     *
     * @return - The default error message for the exception
     */
    public String getDefaultMessage() {
        return this.defaultMessage;
    }

    /**
     * Set the default message
     *
     * @param defaultMessage - The new default message for the exception
     */
    public void setDefaultMessage(String defaultMessage) {
        this.defaultMessage = defaultMessage;
    }

    /**
     * Get the fatal error flag
     *
     * @return - Flag indicating if the error requires the 
     */
    public Boolean getFatalError() {
        return this.fatalError;
    }

    /**
     * Set the fatal error flag
     *
     * @param fatalError - Boolean to indicate if the exception requires a DB rollback
     */
    public void setFatalError(Boolean fatalError) {
        this.fatalError = fatalError;
    }


    /**
     * Convert the exception into a TaroWorks error message
     */
    public void convertToErrorMessage() {

        ErrorHandlingRest.addErrorMsg(
            this.twErrorCode,
            this.twXlationCode,
            this.defaultMessage
        );
        ErrorHandlingRest.setStatusCode(this.statusCode);
        System.debug(LoggingLevel.ERROR, this.defaultMessage);
    }
}