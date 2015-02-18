/**
 * Grameen: Salesforce - PPI Upload
 * Controller for the LookupTables page
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class LookupTablesController {
    private Id surveyId;
    public List<LookupTablesService.TableWrapper> lookUpTables {get; set;}
    public Survey__c survey {get; set;}
    public PPITable__c selectedTable {get; set;}
    public String selectedTableId {
        get;
        set {
            if (String.isBlank(value)) {
                selectedTable = null;
            } else {
                selectedTable =
                    new PpiTableSelector().getWithPpiTableDataSets(value);
                selectedTableId = value;
            }
        }
    }

    // Indicates if the survey must be shown in read only mode
    public Boolean readOnly {get; set;}

    // Indicates if the survey was downloaded from another org
    public Boolean wasDownloaded {get; set;}

    // To render the close button just when is in the same org
    public Boolean sameOrg {get; set;}

    // File upload properties
    public String fileName {get; set;}
    public Blob fileBinary {get; set;}

    public LookupTablesController() {
        this.selectedTableId = '';
        this.surveyId =
            ApexPages.currentPage().getParameters().get('id');

        this.lookUpTables= new List<LookupTablesService.TableWrapper>();
        try {
            if (surveyId != null) {
                this.survey =
                    new SurveySelector().getWithSurveyVersionAndQuestions(this.surveyId);
            } else {
                throw new C.InvalidUrlException(System.Label.BUILDER_ERR_INVALIDURL);
            }

            // If at least one question has remote server Id, the survey was downloaded
            wasDownloaded = !this.survey.Questions__r.isEmpty();

            // Set to true when is the same org to show the preview.
            sameOrg = Site.getName() == null;

            String commingFromBuilder = Apexpages.currentPage().getParameters().get('b');
            readOnly = !(
                (
                    commingFromBuilder == null || commingFromBuilder == '1'
                ) &&
                this.survey.Status__c == SurveyDO.STATUS_DRAFT
            );
            this.lookUpTables= LookupTablesService.refreshPpiTableList(this.survey);
        } catch (Exception generalException) {
            // If error is thrown, make page read only so that no file san be uploaded
            readOnly = true;

            // The exception adds a message to the page
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.ERROR,
                    generalException.getMessage()
                )
            );
        }
    }

    /**
     * Read and parse the uploaded file
     */
    public Pagereference readFile() {
        // Save point in case of an error
        Savepoint sp = Database.setSavepoint();
        try {
            this.lookUpTables = LookupTablesService.parseAndReadCsv(fileBinary, this.survey);
            clearVariables();
        } catch (Exception generalException) {
            clearVariables();
            Database.rollback(sp);

            // The exception adds a message to the page
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.ERROR,
                    generalException.getMessage()
                )
            );
        }
        return null;
    }

    /**
     * Reset the upload variables
     */
    private void clearVariables() {
        this.fileName = null;
        this.fileBinary = null;
    }

    /**
     * Delete the data set for the selected ppi table
     */
    public Pagereference deleteDataSet() {
        LookupTablesService.performDeleteForSelectedPpi(selectedTable, this.survey);
        this.lookUpTables = LookupTablesService.refreshPpiTableList(this.survey);
        return null;
    }
}
