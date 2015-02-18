/**
 * Grameen: Salesforce - Cascading Select Upload
 * Controller for the Cascading Select page
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Ernesto Quesada
 * @author - Owen Davies
 */
public with sharing class CreateCascadingSelectController {

    // The name of the selected file
    public string fileName{ get; set; }

    // The binary content of the file
    public Blob fileBinary{ get; set; }

    // The Current Cascading select (new or existing)
    public CascadingSelect__c cascadingSelect{ get; set; }

    /**
     * The constructor of the class
     *
     */
    public CreateCascadingSelectController(ApexPages.StandardController controller) {
        GenericObjectCreator cascadingSelectCreator =
            new GenericObjectCreator(CascadingSelect__c.SObjectType);
        cascadingSelectCreator.checkObjectAccessible();
        cascadingSelectCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            CascadingSelect__c.Name,
            CascadingSelect__c.Description__c
        });
        cascadingSelect =
            (CascadingSelect__c) cascadingSelectCreator.createNewRecord();
    }

    /**
     * Parse the file csv into the Cascading Select Structure
     *
     */
    public PageReference readFile() {

        // Save point in case of an error
        Savepoint sp = Database.setSavepoint();

        // Pre parsing validation
        if (!validateFile()) {
            Database.rollback(sp);
            return null;
        }

        // Save the Cascading select
        try {

            // Insert the cascading select. It will be marked as valid or invalid by the batch process that parses
            // the CSV file
            insert cascadingSelect;

            // Insert the csv as an attachment
            saveCsvFile();

            // Call the batch process
            Id batchInstanceId = Database.executeBatch(
                new CascadingUploadBatch(cascadingSelect),
                C.CASCADING_CSV_BATCH_SIZE
            );
            String ObjectPrefix = CascadingSelect__c.sObjectType.getDescribe().getKeyPrefix();
            PageReference cascadingManager = new PageReference('/' + ObjectPrefix);
            cascadingManager.setRedirect(true);
            return cascadingManager;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            Database.rollback(sp);
            return null;
        }
    }

    /**
     * Validations of the file
     */
    public boolean validateFile() {

        // Avoid process if there isn't a selected file, or if file exceeds size
        if (this.fileBinary == null) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.severity.ERROR, System.label.LOOKUP_ERR_SELECTFILE)
            );
            clearVariables();

            // Finish the process if error
            return false;
        } else if (this.fileBinary.size() > c.CSV_CASCADING_MAX_FILE_SIZE) {
            ApexPages.addMessage( new ApexPages.Message(ApexPages.severity.ERROR, System.label.LOOKUP_ERR_FILE_SIZE));
            clearVariables();

            // Finish the process if error
            return false;
        }

        // Check that the file has the correct file extension
        if (!checkFileExtension()) {

            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.severity.ERROR, System.label.LOOKUP_ERR_WRONG_FILE_EXTENSION)
            );
            clearVariables();

            // Finish the process if error
            return false;
        }
        return true;
    }

    /**
     * Checks that the file extension of the uploaded file is of the correct type .csv
     *
     * @return - True if the file extension is correct
     */
    private Boolean checkFileExtension() {

        List<String> fileNameSplit = this.fileName.split('\\.');
        String fileExtension = fileNameSplit[fileNameSplit.size() - 1];
        return (fileExtension != null && fileExtension.equalsIgnoreCase(C.CSV_FILE_EXTENSION));
    }

    /**
     * Clear all the file related variables
     */
    private void clearVariables() {
        this.fileName = null;
        this.fileBinary = null;
    }

    /**
     * Save the uploaded file as an attachment for processing
     */
    public void saveCsvFile() {
        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Attachment.Name,
                Attachment.ParentId,
                Attachment.Body
            }
        );
        Attachment attachmentInstance =
            (Attachment) attachmentCreator.createNewRecord();
        attachmentCreator.populateFields(
            attachmentInstance,
            new Map<Schema.SObjectField, Object> {
                Attachment.Name => C.CASCADING_CSV_ATT,
                Attachment.ParentId => cascadingSelect.Id,
                Attachment.Body => fileBinary
            }
        );
        insert attachmentInstance;
    }
}