/**
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class SurveySettingsController {


    public Boolean hasError {
        get{
            return (
                this.hasError ||
                (ApexPages.hasMessages(ApexPages.Severity.ERROR) ||
                ApexPages.hasMessages(ApexPages.Severity.FATAL))
            );
        }
        set;
    }
    public Boolean isPublished { get; set; }
    private Boolean isAlreadyCloned;
    public Boolean isSettingSaved { get; set; }
    public Survey__c survey { get; set; }
    public List<SelectOption> countriesToSelect { get; set; }
    public List<SelectOption> languagesToSelect { get; set; }
    public List<SelectOption> pPIExistingSurveys { get; set; }
    public Survey__c surveyToClone { get; set; }
    private List<Id> idsToClone;
    public String prevRadioButtonSelected { get; set; }
    public Boolean concurrentSave { get; set; }
    public Boolean cloneGroupsCheckbox { get; set; }
    public Boolean isNew { get; set; }
    public Boolean canChangePPIFields { get; set; }
    private DateTime lastModified;

    // Provide readonly access to PPI attributes for child orgs
    public String getCountryName() {
        return ISO_Country__c.getInstance(survey.CountryCode__c).ShortName__c;
    }
    public String getYear() {
        return '' + survey.PPIDataYear__c.intValue();
    }
    public String getLanguageName() {
        return Language__c.getInstance(survey.LanguageCode__c).ShortLanguageName__c;
    }
    public String getUserLanguage() {
      return C.getUserLanguage();
    }

    // The name of the library that is being requested to load
    private String libraryName;

    private static final Set<String> CONTACT_FIELDS_TO_MAP =
        new Set<string>{'Name','Email','LastName'};
    public List<SelectOption> contactFields;

    public Boolean isCloning { get; set; }

    //TODO - Can we get this from somewhere else
    public Boolean isPPI {
        get {
            if (this.survey.Id != null) {
                SurveySelector surveySelector =
                    new SurveySelector();
                surveySelector.getMainQueryBuilder().setSelectClause(
                    new List<Schema.SObjectField>{
                        Survey__c.IsPPI__c
                    }
                );
                Survey__c checkPpiSurvey =
                    (Survey__c) SurveySelector.getRecordById(survey.Id);
                return checkPpiSurvey.IsPPI__c;
            } else {
                return prevRadioButtonSelected == C.PPI_SURVEY || this.survey.IsPPI__c;
            }
        }
        set;
    }
    public Boolean isTemplate;
    public Boolean getIsTemplate() {

        if (this.survey.IsTemplate__c != null) {
            return this.survey.IsTemplate__c;
        }
        return false;
    }
    public void setIsTemplate(Boolean value) {
        this.IsTemplate = value;
    }

    /**
     * Add an error message to the page
     */
    private void addPageErrorMsg(ApexPages.Severity level, String msg) {
        ApexPages.addMessage(
            new ApexPages.Message(
                level,
                msg
            )
        );
    }

    /**
     * Constructor for the controller
     * Creates the Survey__c record that will be the basis for the entire survey
     */
    public SurveySettingsController(ApexPages.StandardController stdController) {

        try {
            this.prevRadioButtonSelected =
                System.currentPageReference().getParameters().get(C.START_FORM);
            if (
                    this.prevRadioButtonSelected == null ||
                    !this.prevRadioButtonSelected.equals(C.REMOTE_LIBRARY)
            ) {
                initController(stdController);
                setUpSurvey();

                // Check that we are creating/editing a PPI. If so get details needed
                if (this.survey.IsPPI__c) {
                    loadPpiDetails();
                }

                // If the survey is published add an error
                // setting concurrent save to false
                this.concurrentSave = false;
                if (survey.Status__c == SurveyDO.STATUS_PUBLISHED) {
                    addPageErrorMsg(
                        ApexPages.Severity.ERROR,
                        System.Label.BUILDER_ERR_SURVEYALREADYPUBLISHED
                    );
                    this.isPublished = true;
                }
            }
            else {
                this.libraryName =
                    System.currentPageReference().getParameters().get(C.REMOTE_LIBRARY_SELECT);
            }
            this.isAlreadyCloned = false;
        } catch (Exception e) {
            addPageErrorMsg(ApexPages.Severity.ERROR, e.getMessage());
        }
    }

    /**
     * Initiate the controller
     */
    private String initController(ApexPages.StandardController stdController) {
        this.isNew = true;
        this.hasError = false;
        this.cloneGroupsCheckbox = false;
        String surveyId = System.currentPageReference().getParameters().get('id');
        if (String.isEmpty(surveyId)) {
            this.survey = (Survey__c) stdController.getRecord();
        } else {
            this.survey =
                (Survey__c) new SurveySelector().getRecordByIdWithAllFields(surveyId);
            this.isNew = false;
            this.lastModified = this.survey.LastModifiedDate;
        }
        countriesToSelect = new List<SelectOption>();//Countries
        languagesToSelect = new List<SelectOption>();//Languages
        return surveyId;
    }

    /**
     * Set up the Survey
     */
    private void setUpSurvey() {
        GenericObjectCreator surveyCreator = GenericObjectCreator.fetchObjectsCreator(
            Survey__c.getSObjectType()
        );
        if (
                this.prevRadioButtonSelected == C.CLONE_SURVEY
        ) {
            initCloningSurvey();
        } else if (this.prevRadioButtonSelected == C.CREATE_FROM_TEMPLATE) {
            initTemplateCopy();
        } else if (this.prevRadioButtonSelected == C.CREATE_NEW_TEMPLATE) {
            surveyCreator.populateField(
                this.survey,
                Survey__c.IsTemplate__c,
                true
            );
        } else if (
                this.prevRadioButtonSelected == C.CREATE_NEW_PPI_TEMPLATE
        ) {
            surveyCreator.populateFields(
                this.survey,
                new Map<Schema.SObjectField, Object>{
                    Survey__c.IsPPI__c => true,
                    Survey__c.IsTemplate__c => true
                }
            );
        } else if (this.prevRadioButtonSelected == C.CLONE_PPI_TEMPLATE) {
            initPpiTemplateCopy();
            surveyCreator.populateFields(
                this.survey,
                new Map<Schema.SObjectField, Object>{
                    Survey__c.IsPPI__c => true,
                    Survey__c.IsTemplate__c => true
                }
            );
        }
    }

    /**
     * Initate the cloning of a survey. This will just clone the Survey__c object. The rest of
     * the cloning process is kicked of when the user saves the survey. Nothing commited to the
     * DB at this point
     */
    private void initCloningSurvey() {
        this.isCloning = true;
        this.surveyToClone =
            (Survey__c) new SurveySelector().getRecordByIdWithAllFields(
                System.currentPageReference().getParameters().get(C.BASE_SURVEY)
            );
        if (this.surveyToClone.IsPPI__c) {
            populatePpiDetails(this.surveyToClone, false);
        }
    }

    /**
     * Init the cloning of a ppi template
     */
    private void initPpiTemplateCopy() {
        initCloningSurvey();
        this.idsToClone = new List<Id>{this.surveyToClone.Id};
    }

    /**
     * Creating a survey from templates. Allows for many templates to make up a survey
     */
    private void initTemplateCopy() {

        this.idsToClone = getIdsToClone();
        Boolean ppiAlreadyFound = false;
        Survey__c mainSurvey;

        for (
            Survey__c template :
                (List<Survey__c>)
                    new SurveySelector().getRecordsByIdWithAllFields(
                        new Set<Id>(C.convertListToId(idsToClone))
                    )
        ) {

            // TODO - This is so the description, etc can be copied across.
            // Need to decide what to do when cloning multiple templates
            mainSurvey = template;
            if (template.IsPPI__c) {
                populatePpiDetails(template, ppiAlreadyFound);
                ppiAlreadyFound = true;
            }
        }
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.getSObjectType());
        surveyCreator.populateFields(
            this.survey,
            new Map<Schema.SObjectField, Object>{
                Survey__c.IsPPI__c => ppiAlreadyFound,
                Survey__c.Name => '',
                Survey__c.Description__c => mainSurvey.Description__c,
                Survey__c.Alias__c => '',
                Survey__c.Deployment__c => mainSurvey.Deployment__c,
                Survey__c.Close_Message__c => mainSurvey.Close_Message__c
            }
        );
        this.surveyToClone = mainSurvey;
    }

    private List<String> getIdsToClone() {
        String idsToCloneString =
            ApexPages.currentPage().getParameters().get(C.BASE_TEMPLATES);
        this.idsToClone = new List<String>();
        if (idsToCloneString == null) {
            idsToCloneString = ApexPages.currentPage().getParameters().get(C.BASE_PPI);
        }
        return idsToCloneString.split(',');
    }

    private void populatePpiDetails(Survey__c ppiTemplate, Boolean ppiAlreadyFound) {
        if (ppiAlreadyFound) {

            // Fail as trying to add more than one PPI
            // TODO - At the moment we do not allow for this to happen in the UI so this is a place holder.
            // This will need to re-direct to the calling page if this error is ever hit.
            addPageErrorMsg(
                ApexPages.Severity.ERROR,
                System.label.CREATE_SURVEY_TOO_MANY_PPI
            );
        }
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.getSObjectType());
        surveyCreator.populateFields(
            this.survey,
            new Map<Schema.SObjectField, Object>{
                Survey__c.CountryCode__c => ppiTemplate.CountryCode__c,
                Survey__c.LanguageCode__c => ppiTemplate.LanguageCode__c,
                Survey__c.PPIDataYear__c => ppiTemplate.PPIDataYear__c,
                Survey__c.PpiIdentifier__c => ppiTemplate.PpiIdentifier__c
            }
        );
    }

    /**
     * Load PPI Details
     */
    private void loadPpiDetails() {

        for (ISO_Country__c co : [SELECT Name, ShortName__c FROM ISO_Country__c ORDER BY ShortName__c LIMIT :C.RECORD_LIMIT]) {
            countriesToSelect.add(new SelectOption( co.Name, co.ShortName__c ));
        }
        for (Language__c la : [SELECT Name, ShortLanguageName__c FROM Language__c ORDER BY ShortLanguageName__c LIMIT :C.RECORD_LIMIT]) {
            languagesToSelect.add(new SelectOption( la.Name, la.ShortLanguageName__c ));
        }

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();

        // PPI Attributes can only be changed if the org has license and the survey was never published
        this.canChangePPIFields = C.getLicense().PPI_Editable__c;
        if (canChangePPIFields) {
            canChangePPIFields = [
                SELECT
                    Id
                FROM
                    SurveyVersion__c
                WHERE
                    Survey__c = :survey.Id
                    AND (
                        Status__c != :SurveyDO.STATUS_DRAFT
                        OR Distributed__c = true
                    )
            ].isEmpty();
        }
    }

    /*
     * Check if the title of the survey does not exists
     */
    public void validateTitleNotRepeated() {
        List<Survey__c> surveys =
            (List<Survey__c>) new SurveySelector().getNameNotForId(survey.Name, survey.Id);

        this.hasError = !surveys.isEmpty();
        if (hasError) {
            survey.Name.addError(System.label.SURVEY_ERR_UNIQUETITLE);
        }
    }

    private void preSaveChecks() {
        Survey__c surveyInUse =
            (Survey__c) new SurveySelector().getRecordByIdWithAllFields(this.survey.Id);
        checkConcurrentSave(surveyInUse);
        checkNotPublished(surveyInUse);
        this.validateTitleNotRepeated();
    }

    /**
     * Check that the survey is not being saved at the same time by another user
     */
    private void checkConcurrentSave(Survey__c surveyInUse) {
        if (surveyInUse.LastModifiedDate != lastModified) {
            concurrentSave = true;
            this.hasError = true;
            throw new C.SurveyBuilderException(
                System.Label.BUILDER_ERR_CONCURRENTSAVE
            );
        }
    }

    /**
     * Check that the survey is in draft status
     */
    private void checkNotPublished(Survey__c surveyInUse) {
        if (surveyInUse.Status__c != SurveyDO.STATUS_DRAFT) {
            isPublished = true;
            throw new C.SurveyBuilderException(System.Label.BUILDER_ERR_SURVEYALREADYPUBLISHED);
        }
    }

    /**
     * Refresh Survey DATA
     */
    public void refreshSurvey() {
        this.survey =
            (Survey__c) new SurveySelector().getRecordByIdWithAllFields(survey.Id);
    }

    /**
     * Save survey
     */
    public void save() {
        this.hasError = false;

        if (this.survey.Id != null) {
            try {
                preSaveChecks();
            } catch (Exception e) {
                addPageErrorMsg(ApexPages.Severity.ERROR, e.getMessage());
                return;
            }
        }
        if (!this.hasError) {
            try {
                upsertSurvey();
                refreshLastModifiedSurvey();
            } catch (DmlException e) {
                addPageErrorMsg(ApexPages.Severity.ERROR, e.getMessage());
                this.hasError = true;
            }
            if (survey.Id != null) {
                refreshSurvey();
            }
        }
    }

    private void upsertSurvey() {

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.getSObjectType());
        surveyCreator.populateField(
            this.survey,
            Survey__c.Deployment__c,
            SurveyDO.DEPLOYMENT_VALUE
        );
        surveyCreator.checkObjectCreateable();
        surveyCreator.checkObjectUpdateable();
        upsert this.survey;
    }

    private void refreshLastModifiedSurvey() {
        Survey__c currentSurvey =
            (Survey__c) new SurveySelector().getRecordById(this.survey.Id);
        this.lastModified = currentSurvey.LastModifiedDate;
    }

    /**
     * Check to see if this page should be redirected to the remote survey library page
     * Also does the License check
     */
    public PageReference checkRedirect() {

        PageReference newPage;
        if (this.prevRadioButtonSelected != null && this.prevRadioButtonSelected.equals(C.REMOTE_LIBRARY)) {
            newPage = Page.RemoteSurveyList;
            newPage.setRedirect(true);
            newPage.getParameters().put(C.LIBRARY_NAME, this.libraryName);
            newPage.getParameters().put(C.FORM_TYPE, C.FORM_TYPE_SUR);
        }
        return newPage;
    }

    /**
     * Quick save survey
     */
    public PageReference quicksave() {

        saveSettingContinue();
        PageReference settingPage = null;

        if (!this.hasError && isAlreadyCloned) {
            settingPage = Page.SurveySetting;
            settingPage.getParameters().put('id', this.survey.Id);
            settingPage.setRedirect(true);
        }
        return settingPage;
    }

    /**
     * Save setting survey on setting survey page, and redirect to question survey page
     */
    public PageReference saveSettingContinue() {

        UnitOfWork unitOfWork = new UnitOfWork(true);
        unitOfWork.setMasterSavePoint(Database.setSavepoint());
        this.save();
        if (!this.hasError) {
            PageReference nextPage;
            String surveyType = '';
            try {
                if (!this.isAlreadyCloned) {
                    if (this.prevRadioButtonSelected == C.CLONE_SURVEY) {
                        surveyType = 'Survey';
                        nextPage = cloneSurvey(unitOfWork);
                    } else if (
                            this.prevRadioButtonSelected == C.CREATE_FROM_TEMPLATE ||
                            this.prevRadioButtonSelected == C.CLONE_PPI_TEMPLATE
                    ) {
                        surveyType =
                            this.surveyToClone.IsPPI__c ?
                                System.Label.GENERAL_PPI_TEMPLATE :
                                System.Label.GENERAL_TEMPLATE;
                        nextPage = cloneTemplates(unitOfWork);
                    }
                }
            } catch (Exception e) {
                this.hasError = true;
                addPageErrorMsg(
                    ApexPages.Severity.ERROR,
                    String.format(
                        System.Label.SURVEY_MANAGER_FAILED_CLONE,
                        new List<String>{surveyType}
                    )
                );
                addPageErrorMsg(ApexPages.Severity.ERROR, e.getMessage());
                return null;
            }
            if (nextPage == null) {
                 nextPage = Page.SurveyQuestion;
            }
            nextPage.getParameters().put('id', this.survey.Id);
            return nextPage.setRedirect(true);
        } else {
           return null;
        }
    }

    /**
     * Perform the clone of the survey
     */
    private PageReference cloneSurvey(UnitOfWork unitOfWork) {
        if (this.surveyToClone != null) {
            FormReplicationService.ReplicateBasicSurvey replicatedSurvey;
            try {
                replicatedSurvey =
                    FormReplicationService.cloneLocalForm(
                        this.surveyToClone,
                        this.survey,
                        false,
                        unitOfWork,
                        this.isCloning == null ? false : this.isCloning
                    );
                if (replicatedSurvey.closeBrokenForms()) {
                    ErrorHandlingRest.addApexPageErrorsToPage();
                    return Page.SurveyFieldMapping;
                }
                this.isAlreadyCloned = true;
            } catch (Exception e) {
                replicatedSurvey.rollback();
                throw e;
            }
        } else {
            throw new C.SurveyBuilderException(
                System.Label.SURVEY_ERR_NOSURVEYSELECTED
            );
        }
        return null;
    }

    /**
     * Perform the clone of the templates
     */
    private PageReference cloneTemplates(UnitOfWork unitOfWork) {
        if (this.idsToClone != null) {
            Boolean staysTemplate =
             this.prevRadioButtonSelected.equalsIgnoreCase(C.CLONE_PPI_TEMPLATE);
            FormReplicationService.ReplicateBasicSurvey replicatedSurvey;
            try {
                replicatedSurvey =
                    FormReplicationService.cloneLocalForm(
                        this.surveyToClone,
                        this.survey,
                        staysTemplate,
                        unitOfWork,
                        this.isCloning == null ? false : this.isCloning
                    );
                if (replicatedSurvey.closeBrokenForms()) {
                    ErrorHandlingRest.addApexPageErrorsToPage();
                    return Page.SurveyFieldMapping;
                }
                this.isAlreadyCloned = true;
            } catch (Exception e) {
                replicatedSurvey.rollback();
                throw e;
            }
        } else {
            throw new C.SurveyBuilderException(System.Label.SURVEY_ERR_NOSURVEYSELECTED);
        }
        return null;
    }

    /**
     * Add all errors found when cloning a survey
     */
    private void addCloningErrorsToPage(
            FormReplicationService.ReplicateBasicSurvey replicatedSurvey
    ) {
        for (String errMsg : replicatedSurvey.getErrors()) {
            addPageErrorMsg(ApexPages.Severity.ERROR, errMsg);
        }
    }
}