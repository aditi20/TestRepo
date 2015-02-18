/**
 * Class that represents a survey submission from a mobile user
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public with sharing class Submission {

    private String submissionXml;
    private Id surveyId;
    private SurveyVersion__c version;
    private Boolean success;
    private Id existingSubmissionId;
    private Submission__c existingSubmission;
    private String hash;
    private Boolean updateSubmission;
    private Boolean failedFieldMapping;
    private Boolean isDuplicate;
    private Id surveyorId;

    public Submission(String submissionXml, Id contactId) {
        this.submissionXml = submissionXml;
        this.updateSubmission = false;
        this.failedFieldMapping = false;
        this.isDuplicate = false;
        this.surveyorId = contactId;
    }
    public Submission(Id existingSubmissionId) {
        this.existingSubmissionId = existingSubmissionId;
        this.updateSubmission = false;
        this.failedFieldMapping = false;
        this.isDuplicate = false;
    }

    /**
     * Get the submissionXML
     */
    public String getSubmissionXml() {
        return this.submissionXml;
    }

    /**
     * Get success
     *
     * @return - The boolean indicating if validation has been successful
     */
    public Boolean getSuccess() {
        return this.success;
    }

    /**
     * Getter for updateSubmission
     */
    public Boolean getUpdateSubmission() {
        return this.updateSubmission;
    }

    /**
     * Get the existing submission Id
     *
     * @return - The existingSubmissionId
     */
    public Id getExistingSubmissionId() {
        return this.existingSubmissionId;
    }

    /**
     * Set the existingSubmissionId
     *
     * @param submissionId - The Id for the submission
     */
    public void setExistingSubmissionId(Id submissionId) {
        this.existingSubmissionId = submissionId;
    }

    /**
     * Get the existing submission
     *
     * @return - The existingSubmission
     */
    public Submission__c getExistingSubmission() {
        return this.existingSubmission;
    }

    /**
     * Get the existing submission status
     *
     * @return - The string for existingSubmission status
     */
    public String getExistingSubmissionStatus() {
        return this.existingSubmission.Status__c;
    }

    /**
     * Set the submission
     *
     * @param submission - The Submission__c record
     */
    public void setExistingSubmission(Submission__c submission) {
        this.existingSubmission = submission;
    }

    /**
     * Get the survey version
     */
    public SurveyVersion__c getVersion() {
        return this.version;
    }

    /**
     * Get the MD5 Hash of the submission
     */
    public String getHash() {
        return this.hash;
    }

    /**
     * Get failed field mapping boolean
     *
     * @return - Boolean indicating if the field mapping failed
     */
    public Boolean getFailedFieldMapping() {
        return this.failedFieldMapping;
    }

    /**
     * Get if the submission is a duplicate
     *
     * @return - Boolean indicating if the submission is a duplicate
     */
    public Boolean getIsDuplicate() {
        return this.isDuplicate;
    }

    /**
     * Validate an new submission. This is a submission that is in the init phase
     * This creates the stub Submission__c record
     */
    public void validateNewSubmission() {
        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectAccessible();
        submissionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Submission__c.Status__c,
            Submission__c.Survey__c,
            Submission__c.SurveyVersion__c,
            Submission__c.SubmissionXMLMD5__c,
            Submission__c.Surveyor__c
        });
        this.validate();
        if (this.getSuccess()) {
            Submission__c submissionInstance =
                (Submission__c) submissionCreator.createNewRecord();
            submissionCreator.populateFields(
                submissionInstance,
                new Map<Schema.SObjectField, Object> {
                    Submission__c.Status__c => C.SUBMISSION_STATUS_UPLOADING,
                    Submission__c.Survey__c => this.getVersion().Survey__c,
                    Submission__c.SurveyVersion__c => this.getVersion().Id,
                    Submission__c.SubmissionXMLMD5__c => this.hash,
                    Submission__c.Surveyor__c => this.surveyorId
                }
            );
            this.setExistingSubmission(
                submissionInstance
            );
            DBFullAccess.insertSObject(this.existingSubmission);
            this.existingSubmissionId = this.existingSubmission.Id;
            this.checkSurveyStatus();
            if (this.success) {
                this.checkFieldMappings();
            }
            this.saveSubmissionAsAttachment();
        }
    }

    /**
     * Validate the submission
     *
     * @throws SubmissionException
     */
    public void validate() {

        validateXml();
        this.success = checkForDuplicateSubmission();
    }

    /**
     * Check that the field mapping is still valid
     * If it is not then close the survey
     *
     * @return - Boolean indicating if validation has passed
     */
    public Boolean checkFieldMappings() {

        Set<Id> surveysToClose =
            RemovedDataValidation.mappingsWithMissingObjectOrField(
                this.version.Survey__c
            );
        if (!surveysToClose.isEmpty()) {
            this.existingSubmission.Status__c = C.SUBMISSION_STATUS_UPLOADED_AUTO;
            SurveyUtils.closeFailedSurveysAndUserInfo(
                this.version.Survey__c, false
            );
            this.updateSubmission = true;
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_SUB_CORRUPT_FIELD_MAP,
                ErrorHandlingRest.SURVEY_SUB_BROKEN_FIELD_MAPPING,
                'The survey ' + this.version.Survey__r.Name +
                    ' is no longer valid'
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_BAD_REQUEST);
            this.failedFieldMapping = true;
            return false;
        }
        return true;
    }

    /**
     * Load the existing submission
     */
    public void loadSubmission() {
        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectAccessible();
        submissionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Submission__c.Status__c,
            Submission__c.Survey__c,
            Submission__c.SurveyVersion__c,
            Submission__c.SubmissionXMLMD5__c,
            Submission__c.Surveyor__c,
            Submission__c.Device__c
        });

        if (String.isBlank(this.existingSubmissionId)) {
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_SUB_ID_MISSING,
                ErrorHandlingRest.SURVEY_SUB_MISSING_SURVEY_ID,
                'The submission id is missing'
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_BAD_REQUEST);
            this.success = false;
            return;
        }

        Submission__c[] submissions = [
            SELECT
                Id,
                SurveyVersion__c,
                Status__c,
                Surveyor__c,
                Device__c,
                Survey__c,
                SubmissionXMLMD5__c
            FROM
                Submission__c
            WHERE
                Id = :this.existingSubmissionId
        ];
        if (submissions.isEmpty()) {
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_SUB_INVALID_SUBMISSION_ID,
                ErrorHandlingRest.SURVEY_SUB_INVALID_SUBMISSION_ID,
                'The submission id ' + this.existingSubmissionId +
                    ' could not be found'
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_BAD_REQUEST);
            this.success = false;
            return;
        }
        this.success = true;
        this.existingSubmission = submissions[0];
        loadSubmissionXml();
    }

    /**
     * Load the submission xml from the attachment
     */
    public void loadSubmissionXml() {

        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Attachment.Body
        });
        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectAccessible();

        Attachment[] attachments = [
            SELECT
                Body
            FROM
                Attachment
            WHERE
                ParentId = :this.existingSubmissionId
                AND Name = :C.SURVEY_ANSWER_ATTACHMENT_NAME
            LIMIT
                1
        ];

        if (attachments.isEmpty()) {
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_SUB_MISSING_XML,
                ErrorHandlingRest.SURVEY_SUB_MISSING_XML,
                'The submission is missing required XML'
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_BAD_REQUEST);
            this.success = false;

            // Delete the existing submission so it can be resubmitted
            submissionCreator.checkObjectDeletable();
            delete this.existingSubmission;
            return;
        }
        this.submissionXml = attachments[0].Body.toString();
    }

    /**
     * Check the status of the Survey that the submission is for.
     * Update the existingSubmission if needed
     */
    public void checkSurveyStatus() {

        if (this.version == null) {
            this.loadSurveyVersion();
        }

        if (!this.version.Status__c.equals(SurveyDO.STATUS_PUBLISHED)) {

            if (
                    this.version.Status__c.equals(SurveyDO.STATUS_CLOSED)
                    && (
                        !this.existingSubmission.Status__c.equals(C.SUBMISSION_STATUS_UPLOADED_CLOSED)
                        && !this.existingSubmission.Status__c.equals(C.SUBMISSION_STATUS_UPLOADED_AUTO)
                    )
            ) {
                if (
                        this.version.CloseReason__c != null &&
                        this.version.CloseReason__c.equals(SurveyDO.STATUS_CLOSED_AUTO)
                ) {
                    this.existingSubmission.Status__c = C.SUBMISSION_STATUS_UPLOADED_AUTO;
                    this.updateSubmission = true;
                    this.success = false;
                    ErrorHandlingRest.addErrorMsg(
                        ErrorHandlingRest.ERR_CODE_SUB_SURVEY_CLOSED,
                        ErrorHandlingRest.SURVEY_SUB_SURVEY_CLOSED,
                        'The survey id ' + this.version.Survey__c + ' is closed'
                    );
                }
                else {
                    this.existingSubmission.Status__c = C.SUBMISSION_STATUS_UPLOADED_CLOSED;
                    this.updateSubmission = true;
                    ErrorHandlingRest.addErrorMsg(
                        ErrorHandlingRest.ERR_CODE_SUB_SURVEY_CLOSED,
                        ErrorHandlingRest.SURVEY_SUB_SURVEY_CLOSED,
                        'The survey id ' + this.version.Survey__c + ' is closed'
                    );
                }
            }
        }
    }

    /**
     * Save the submissionXML to the existingSubmission as an attachment
     */
    public void saveSubmissionAsAttachment() {
        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Attachment.Name,
            Attachment.ParentId,
            Attachment.Body
        });
        Attachment attachmentInstance = (Attachment) attachmentCreator.createNewRecord();
            attachmentCreator.populateFields(
                attachmentInstance,
                new Map<Schema.SObjectField, Object> {
                    Attachment.Name => c.SURVEY_ANSWER_ATTACHMENT_NAME,
                    Attachment.ParentId => this.existingSubmissionId,
                    Attachment.Body => Blob.valueOf(this.submissionXml)
                }
            );
        insert attachmentInstance;
    }

    /**
     * Save an image as an attachment of the submission
     *
     * @param media    - Blob of the file being saved
     * @param fileName - The filename of the attachment
     */
    public void saveImageAsAttachment(Blob media, String filename) {
        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Attachment.Name,
            Attachment.ParentId,
            Attachment.Body
        });
        Attachment attachmentInstance = (Attachment) attachmentCreator.createNewRecord();
            attachmentCreator.populateFields(
                attachmentInstance,
                new Map<Schema.SObjectField, Object> {
                    Attachment.Name => filename,
                    Attachment.ParentId => this.existingSubmissionId,
                    Attachment.Body => media
                }
            );
        insert attachmentInstance;
    }

    /**
     * Update the existing submission if needed
     */
    public void updateSubmission() {
         GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectUpdateable();
        if (this.updateSubmission && this.existingSubmission != null) {
            update this.existingSubmission;
        }
    }

    /**
     * Validate the submission XML
     *
     * @throws SubmissionException
     */
    private void validateXml() {

        // Check that the XML is not empty
        if (!String.isNotBlank(this.submissionXml)) {
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_SURVEY_BLANK_XFORM,
                ErrorHandlingRest.SURVEY_FORMLIST_XFORM_EMPTY,
                'The submission is missing required XML'
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_BAD_REQUEST);
            throw new SubmissionDO.SubmissionException();
        }
        else {

            // Get the survey version
            loadSurveyVersion();

            // Check that the survey exists
            if (this.version == null) {
                ErrorHandlingRest.addErrorMsg(
                    ErrorHandlingRest.ERR_CODE_SURVEY_ID_NOT_EXIST,
                    ErrorHandlingRest.SURVEY_FORMLIST_ID_INVALID,
                    'The survey id ' +
                         this.surveyId + ' no longer exists on the system'
                );
                ErrorHandlingRest.setStatusCode(C.HTTP_NOT_FOUND);
                throw new SubmissionDo.SubmissionException();
            }
        }
    }

    /**
     * Check that the submission has not already been made
     *
     * @return - Boolean indicating if validation has passed
     */
    private Boolean checkForDuplicateSubmission() {

        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectAccessible();

        this.hash = EncodingUtil.base64Encode(
            Crypto.generateDigest('MD5', blob.valueof(this.submissionXml))
        );
        Submission__c[] existingSubmissions = [
            SELECT
                Id
            FROM
                Submission__c
            WHERE
                Survey__c = :this.version.Survey__c
                AND SubmissionXMLMD5__c = :this.hash
        ];

        if (!existingSubmissions.isEmpty()) {
            this.existingSubmission = existingSubmissions[0];
            this.existingSubmissionId = existingSubmissions[0].Id;
            this.isDuplicate = true;
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_SUB_DUPLICATE,
                ErrorHandlingRest.SURVEY_SUB_DUPLICATE_SUBMISSION,
                'The submission is a duplicate'
            );
            return false;
        }
        return true;
    }

    /**
     * Load the most recent survey version from submission XML
     */
    private void loadSurveyVersion() {
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.Name,
            Survey__c.Status__c,
            Survey__c.Close_Message__c,
            Survey__c.IsPPI__c
        });
        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            SurveyVersion__c.Name,
            SurveyVersion__c.Status__c,
            SurveyVersion__c.CloseReason__c,
            SurveyVersion__c.Survey__c
        });
        Xmlstreamreader xmlReader = new Xmlstreamreader(this.submissionXml);

        // It is the second value in the xml so we skip the first
        xmlReader.next();

        // Find Survey id
        if (xmlReader.getEventType() == XmlTag.START_ELEMENT) {
            this.surveyId = xmlReader.getAttributeValue(null, 'id');
        }

        if (this.surveyId != null) {

            // Select survey id from survey version if it is necessary
            SurveyVersion__c[] versions = [
                SELECT
                    Id,
                    Name,
                    Status__c,
                    CloseReason__c,
                    Survey__c,
                    Survey__r.Status__c,
                    Survey__r.Name,
                    Survey__r.Id,
                    Survey__r.Close_Message__c,
                    Survey__r.IsPPI__c
                FROM
                    SurveyVersion__c
                WHERE
                    Id = :this.surveyId
                    OR Survey__c = :this.surveyId
                ORDER BY
                    Version__c DESC
                LIMIT 1
            ];
            if (!versions.isEmpty()) {
                this.version = versions[0];
            }
        }
    }
}
