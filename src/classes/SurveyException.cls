/*
 * Exception class to handle any known exceptions that are generated during the
 * submission of a survey
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public class SurveyException extends BaseException{

    public SurveyException(
            String twErrorCode,
            String twXlationCode,
            Integer statusCode,
            String defaultMessage,
            Boolean fatalError
    ) {
        super(twErrorCode, twXlationCode, statusCode, defaultMessage, fatalError);
    }

    // Legacy raise methods for creating a standard Exception with no extra data
    public static void raise(String msg) {
        throw new SurveyException(msg);
    }

    public static void raise(String msg, String arg) {
        throw new SurveyException(String.format(msg, new String[]{arg}));
    }

    public static void raise(String msg, String[] args) {
        throw new SurveyException(String.format(msg, args));
    }
}