/**
 * Contains the logic for the SurveySubmissionService REST Resource.
 * This is moved into its own class as it is not possible to patch classes
 * in a managed package that is marked as @RestResource
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public with sharing class SurveySubmissionServiceLogic {

    /**
     * Process a submission
     */
    public static void processSubmission() {

        Submission submission;
        SavePoint sp = Database.setSavePoint();

        // Authenticate the Mobile User
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            RestContext.request.headers.get(C.SESSION_TOKEN_HEADER),
            true
        );
        RestContext.response.statusCode = loginResult.statusCode;

        try {
            if (!loginResult.hasError) {
                ServicesController sc = new ServicesController();

                // Get the headers needed
                String stage = RestContext.request.headers.get(C.STAGE_HEADER);
                String last = RestContext.request.headers.get(C.LAST_HEADER);

                // Processing the first request of a submission with images or a submission
                // with no media
                if (
                        (String.isNotBlank(stage) && stage.equals(C.SUBMISSION_STAGE_INIT))
                        || String.isBlank(stage)
                ) {

                    // Create and validate the submissions
                    submission = new Submission(
                        RestContext.request.requestBody.toString(),
                        loginResult.getContact().Id
                    );
                    submission.validateNewSubmission();

                    // If there is no stage header and if all validation has passed process
                    // the survey
                    if (String.isBlank(stage) && submission.getSuccess()) {
                        submission = sc.submit(loginResult, submission);
                    }
                    if (submission.getSuccess() || submission.getIsDuplicate()) {
                        RestContext.response.headers.put(
                            C.SUBMISSION_ID_HEADER,
                            submission.getExistingSubmissionId()
                        );
                    }
                }
                else if (String.isNotBlank(stage) && stage.equals(C.SUBMISSION_STAGE_MEDIA)) {

                    // Load the submission
                    submission = new Submission(
                        (Id)RestContext.request.headers.get(C.SUBMISSION_ID_HEADER)
                    );
                    submission.loadSubmission();

                    if (submission.getSuccess()) {
                        if (submission.getExistingSubmissionStatus() != C.SUBMISSION_STATUS_UPLOADED) {

                            // Save the attachment to the submission
                            submission.saveImageAsAttachment(
                                RestContext.request.requestBody,
                                RestContext.request.headers.get(C.FILENAME_HEADER)
                            );

                            // If the last image has been sent, process the submission XML
                            if (last != null && last.equals('true')) {

                                if (
                                        submission.getSuccess() &&
                                        submission.checkFieldMappings()
                                ) {
                                    submission.checkSurveyStatus();

                                    // If all validation has passed process the survey
                                    if (submission.getSuccess()) {
                                        submission = sc.submit(loginResult, submission);
                                    }

                                    RestContext.response.headers.put(
                                        C.SUBMISSION_ID_HEADER,
                                        submission.getExistingSubmissionId()
                                    );
                                } else if (submission.getIsDuplicate()) {
                                    RestContext.response.headers.put(
                                        C.SUBMISSION_ID_HEADER,
                                        submission.getExistingSubmissionId()
                                    );
                                }
                            } else {
                                RestContext.response.headers.put(
                                    C.SUBMISSION_ID_HEADER,
                                    submission.getExistingSubmissionId()
                                );
                            }
                        } else {
                            RestContext.response.headers.put(
                                C.SUBMISSION_ID_HEADER,
                                submission.getExistingSubmissionId()
                            );
                        }
                    }
                }
                RestContext.response.statusCode = ErrorHandlingRest.getStatusCode();

                // Update the submission if needed
                submission.updateSubmission();
            }
        } catch(GenericObjectCreator.GenericObjectCreatorException genericObjectCreatorException) {
            Database.rollBack(sp);
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_CRUD_FLS,
                ErrorHandlingRest.CRUD_FLS,
                System.Label.ERR_PERMISSIONS + '\n\n' + genericObjectCreatorException.getMessage()
            );
            RestContext.response.statusCode = C.HTTP_INTERNAL_SERVER_ERROR;
        } catch(SubmissionDO.SubmissionException subE) {
            Database.rollBack(sp);
            RestContext.response.statusCode = ErrorHandlingRest.getStatusCode();
        } catch(SurveyException subE) {
            if (subE.getFatalError()) {
                Database.rollBack(sp);
            }
            subE.convertToErrorMessage();
            RestContext.response.statusCode = ErrorHandlingRest.getStatusCode();
        } catch(DMLException dmlE) {
            if (ErrorHandlingRest.parseDmlException(dmlE)) {
                throw dmlE;
            } else {
                Database.rollBack(sp);
                RestContext.response.statusCode = ErrorHandlingRest.getStatusCode();
            }
        }

        if (ErrorHandlingRest.checkForErrors()) {
            RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, 'application/json;charset=UTF-8');
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
        }
    }
}