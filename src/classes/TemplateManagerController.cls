/**
 * Controller for the template manager page
 * Allows user to create/edit/download/use/delete/distribute
 * templates based on the license that the user has
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public with sharing class TemplateManagerController {


    // Pagination variables
    public ApexPages.StandardSetController paginator { get; set; }

    @TestVisible
    private void setUpPagination(Boolean reload) {

        if (this.paginator == null || reload) {
            SurveyUtils utils = new SurveyUtils();
            this.paginator = new ApexPages.StandardSetController(
                new SurveyVersionSelector().getAllTemplatesForLicense(
                    libraryToView,
                    showPpi,
                    showAll,
                    getOrderByClause()
                )
            );
            this.paginator.setPageNumber(1);
            this.paginator.setPageSize(20);
        }
    }

    // The SObjectDomain that can be typecasted dynamically to be used based on implementation
    public transient SObjectDomain domain;

    // Survey id when clicking delete link
    public String surveyIdToDelete {get;set;}

    // Ordering varaibles
    private String oldOrderByColumn;
    public String orderByColumn;
    public String getOrderByColumn() {
        return this.orderByColumn;
    }
    public void setOrderByColumn(String value) {

        if (value == null || value.trim().equals('')) {
            this.orderByColumn = 'Survey__r.Name';
        }
        else {
            this.orderByColumn = value.trim();
        }
        this.oldOrderByColumn = this.orderByColumn;
    }
    private String sortOrder;

    public PageReference doSort() {
        this.sortOrder =
            (
                this.oldOrderByColumn == this.orderByColumn &&
                this.sortOrder == SObjectSelector.DESCENDING_OPERATOR
            ) ?
            SObjectSelector.ASCENDING_OPERATOR :
            SObjectSelector.DESCENDING_OPERATOR;
        setUpPagination(true);
        return null;
    }

    Transient List<SurveyVersion__c> templates;
    public List<SurveyVersion__c> getTemplates() {
        if (paginator == null) {
            setUpPagination(false);
        }
        return (List<SurveyVersion__c>)paginator.getRecords();
    }
    public void setTemplates(List<SurveyVersion__c> values) {
        this.templates = values;
    }

    // License settings
    private LicenseSettings__c license;
    public Boolean canEditPPI { get; set; }
    public Boolean canDownloadPpi { get; set; }
    public Boolean canCreatePpi { get; set; }
    public Boolean canDeletePpi { get; set; }
    public Boolean canUsePPI { get; set; }
    public Boolean canEditTemplates { get; set; }
    public Boolean canDownloadTemplates { get; set; }
    public Boolean canCreateTemplates { get; set; }
    public Boolean canDeleteTemplates { get; set; }
    public Boolean canUseTemplates { get; set; }
    public Boolean canDistribute { get; set; }
    public Boolean canClonePpi { get; set; }

    private Boolean showPpi;
    private Boolean showAll;
    private String libraryToView;

    /**
     * Get the order by clause
     */
    private String getOrderByClause() {
        return String.escapeSingleQuotes(this.orderByColumn) + ' ' + this.sortOrder;
    }

    public TemplateManagerController(ApexPages.standardController controller) {

        this.showPpi = true;
        this.showAll = true;
        this.libraryToView = 'default';
        this.sortOrder = SObjectSelector.ASCENDING_OPERATOR;
        init();
        setOrderByColumn('Name');
        setUpPagination(false);
    }

    /**
     * Init the controller. Adds the license settings
     */
    public void init() {

        // Load license settings
        this.license = C.getLicense();

        this.canDistribute = this.license.Can_Distribute__c;

        // PPI license settings
        this.canCreatePpi = license.PPI_Editable__c;
        this.canDeletePpi = license.PPI_Editable__c;
        this.canDownloadPpi = license.DownloadPPI__c;
        this.canEditPPI = license.PPI_Editable__c;
        this.canUsePPI = license.UsePPI__c;

        this.canCreateTemplates = license.CreateTemplates__c;
        this.canDeleteTemplates = license.DeleteTemplates__c;
        this.canDownloadTemplates = license.DownloadTemplates__c;
        this.canEditTemplates = license.EditTemplates__c;
        this.canUseTemplates = license.UseTemplates__c;
        this.canClonePpi = license.CanClonePpi__c;
    }

    /**
     * Create a new template
     * Includes:
     *     - new blank template/ppi
     *     - Download from a remote library of choice
     *         -Requires target SurveyLibrary__c to be set up
     *     - Download a PPI from Grameen - Requires grameen's SurveyLibrary__c to be set up
     */
    public PageReference newTemplate() {

        String action = ApexPages.currentPage().getParameters().get(C.TEMPLATE_ACTION);
        PageReference newPage;

        // Get a PPI from Grameen
        if (action.equalsIgnoreCase(C.GET_PPI_ACTION)) {
            newPage = Page.RemoteSurveyList;

            // Add Grameen's remote library name
            newPage.getParameters().put(C.LIBRARY_NAME, C.GRAMEEN_LIBRARY);
            newPage.getParameters().put(C.FORM_TYPE, C.FORM_TYPE_PPI);
        } else if (action.equalsIgnoreCase(C.DOWNLOAD_ACTION)) {

            // Download a new template
            newPage = Page.RemoteSurveyList;

            // Add the name of the library that the new template will come from
            newPage.getParameters().put(
                C.LIBRARY_NAME,
                ApexPages.currentPage().getParameters().get(C.LIBRARY_NAME)
            );
            newPage.getParameters().put(C.FORM_TYPE, C.FORM_TYPE_TEMP);
        } else if (action.equalsIgnoreCase(C.CLONE_PPI_TEMPLATE)) {
            newPage = Page.SurveySetting;
            newPage.getParameters().put(C.START_FORM, action);
            newPage.getParameters().put(
                C.BASE_SURVEY,
                ApexPages.currentPage().getParameters().get(C.PPI_TO_CLONE)
            );
        } else if (
                action.equalsIgnoreCase(C.CREATE_NEW_TEMPLATE) ||
                action.equalsIgnoreCase(C.CREATE_NEW_PPI_TEMPLATE)
        ) {
            newPage = Page.SurveySetting;
            newPage.getParameters().put(C.START_FORM, action);
        } else {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    System.Label.TEMP_MAN_INVALID_ACTION
                )
            );
            return null;
        }
        newPage.setRedirect(true);
        return newPage;
    }

    /**
     * Load the survey builder with a survey that is cloned from the template selected
     */
    public PageReference useIt() {

        PageReference newPage;
        newPage = Page.SurveySetting;
        String surveyId = ApexPages.currentPage().getParameters().get(C.BASE_TEMPLATES);
        QuestionDo questionDomain = new QuestionDo();
        questionDomain.populateTemplateQuestions(surveyId);
        newPage.getParameters().put(C.START_FORM, C.CREATE_FROM_TEMPLATE);
        newPage.getParameters().put(C.BASE_TEMPLATES, surveyId);
        newPage.setRedirect(true);
        return newPage;
    }

    /**
     * Edit a template. This opens the survey builder to allow the template to be edited
     */
    public PageReference editIt() {
        PageReference newPage;
        newPage = Page.SurveySetting;
        String surveyId = ApexPages.currentPage().getParameters().get(C.BASE_TEMPLATES);
        newPage.getParameters().put(C.START_FORM, C.EDIT_TEMPLATE);
        newPage.getParameters().put('id', surveyId);
        newPage.setRedirect(true);
        return newPage;
    }

    /**
     * Delete a template. Oncomplete the page will rerender the list of templates
     */
    public PageReference deleteIt() {
        String surveyId = surveyIdToDelete;
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.Name
        });

        Survey__c surveyToDelete = [SELECT Id, Name FROM Survey__c WHERE Id = :surveyId];
        String surveyName = surveyToDelete.Name;
        surveyCreator.checkObjectDeletable();
        delete surveyToDelete;

        ApexPages.addMessage(
            new ApexPages.Message(
                ApexPages.severity.INFO,
                String.format(System.Label.TEMPLATE_MAN_DELETE, new List<String>{ surveyName })
            )
        );
        setUpPagination(true);
        return null;
    }

    /**
     * Distribute a template. This makes it available to any remote library that is connected to this
     * org
     */
    public PageReference distributeIt() {

        String surveyId = ApexPages.currentPage().getParameters().get(C.BASE_TEMPLATES);
        QuestionDo questionDomain = new QuestionDo();
        questionDomain.populateTemplateQuestions(surveyId);
        SurveyUtils utils = new SurveyUtils();

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.Name,
            Survey__c.IsPPI__c
        });

        Survey__c s = [SELECT Name, IsPPI__c FROM Survey__c WHERE Id = :surveyId];
        String templateType =
            s.IsPPI__c ?
            System.Label.GENERAL_PPI_TEMPLATE : 
            System.Label.GENERAL_TEMPLATE;
        try {
            utils.distributeSurvey(surveyId);

            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.INFO,
                    String.format(
                        System.Label.SURVEY_MANAGER_SUCCESSFUL_DISTRIBUTION,
                        new List<String>{ templateType, s.Name }
                    )
                )
            );
        } catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.ERROR,
                    String.format(
                        System.Label.SURVEY_MANAGER_FAILED_DISTRIBUTION,
                        new List<String>{ templateType, s.Name }
                    )
                )
            );
        }
        setUpPagination(true);
        return null;
    }

    /**
     * This is a sub method that currently does nothing.
     * It will need to be implemented when we add the ability to update templates.
     * This will be done after we implement proper versioning
     */
    public PageReference checkForUpdates() {

        String surveyId = ApexPages.currentPage().getParameters().get('surveyId');
        Boolean getAll = surveyId == null ? true : false;
        return null;
    }

    /**
     * Filter the templates that are shown in the list.
     * Supported filters are:
     *    - Type of template PPI|Template|All
     *    - Library the template is from
     */
    public PageReference filterDisplay() {
        this.libraryToView = ApexPages.currentPage().getParameters().get(C.LIBRARY_NAME);
        this.showPpi = Boolean.valueOf(ApexPages.currentPage().getParameters().get('showPpi'));
        this.showAll = Boolean.valueOf(ApexPages.currentPage().getParameters().get('showAll'));
        try {
            setUpPagination(true);
        } catch (Exception e) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.ERROR,
                    System.Label.TEMP_MAN_FAILED_REFRESH
                )
            );
        }
        return null;
    }
}