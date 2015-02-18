/*
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*/
public with sharing class SurveyControllerExtension {

    // License settings
    private LicenseSettings__c license;
    public Boolean isPPIEnabled { get; set; }
    public Boolean canDownloadPpi { get; set; }
    public Boolean canEditPPI { get; set; }
    public Boolean canDeletePpi { get; set; }
    public Boolean canUsePPI { get; set; }
    public Boolean canEditTemplates { get; set; }
    public Boolean canDownloadTemplates { get; set; }
    public Boolean canCreateTemplates { get; set; }
    public Boolean canDeleteTemplates { get; set; }
    public Boolean canUseTemplates { get; set; }
    public Boolean canDistribute { get; set; }

    public Survey__c[] surveysToClone {get; set;}
    public Survey__c survey {get; set;}

    /**
     * Class that represent a survey only with the data being retrieved.
     */
    public class SurveyWrapper {
        public String id {get; set;}
        public String name {get; set;}
        public Boolean isPPI {get; set;}
        public Boolean isTemplate {get; set;}
        public Boolean isDemographicPpiSurvey {get; set;}

        /**
         * Constructor from a Survey__c.
         */
        public SurveyWrapper(Survey__c survey) {
            this.id = survey.Id;
            this.name = survey.Name;
            this.isPPI = survey.IsPPI__c;
            this.isTemplate = survey.IsTemplate__c;

            if (SurveyDO.isNewPpiSurvey(survey) && survey.IsPPI__c ) {
                this.isDemographicPpiSurvey = true;
            } else {
                this.isDemographicPpiSurvey = false;
            }
        }
    }

    /**
     * Get all surveys list and create a json list from a SurveyWrapper list only with the retrieved data
     */
    public String getSurveyList() {
        List<SurveyWrapper> surveyWrapperList = new List<SurveyWrapper>();
        SurveySelector surveySelectorInstance = new SurveySelector();
        surveySelectorInstance.addToMainOrderByClause('');

        for (Survey__c surveyInstance : surveySelectorInstance.getAllSurveys()) {
            surveyWrapperList.add(new SurveyWrapper(surveyInstance));
        }
        return JSON.serialize(surveyWrapperList);
    }

    public void init() {
        LicenseSettings__c license = C.getLicense();

        // PPI license settings
        this.isPPIEnabled = license.PPI_Editable__c;
        this.canDeletePpi = license.PPI_Editable__c;
        this.canDownloadPpi = license.DownloadPPI__c;
        this.canEditPPI = license.PPI_Editable__c;
        this.canUsePPI = license.UsePPI__c;

        this.canCreateTemplates = license.CreateTemplates__c;
        this.canDeleteTemplates = license.DeleteTemplates__c;
        this.canDownloadTemplates = license.DownloadTemplates__c;
        this.canEditTemplates = license.EditTemplates__c;
        this.canUseTemplates = license.UseTemplates__c;
    }

    public SurveyControllerExtension() {
        surveysToClone = new SurveySelector().getAllSurveys();
    }

    /**
     * Generate the Survey Library List.
     * Load all existing Survey Libraries from the database and wrapper them into a dedicated class.
     * (Related: IDALMSA-3213)
     *
     * @return surveyLibraryItems List[] SurveyLibraryItem       List of Survey Library List
     */
    @RemoteAction
    public static List <SurveyLibraryItem> generateSurveyLibraryList() {

        List <SurveyLibrary__c> surveyLibraries =
            new SurveyLibrarySelector().getAllForIsSurveyWithActiveStatus(true);

        // Copy the custom object to a wrapper class to send it to UI.
        List <SurveyLibraryItem> surveyLibraryItems = new List <SurveyLibraryItem>();

        for (SurveyLibrary__c surveyLibrary: surveyLibraries) {
            surveyLibraryItems.add( new SurveyLibraryItem(surveyLibrary));
        }

        return surveyLibraryItems;
    }

    /**
     * Wrapper Class of Survey Library
     * Class to wrapper the query result of Survey Library to send it to UI.
     * (Related: IDALMSA-3213)
     */
    public class SurveyLibraryItem {
        public Id id {get; set;}
        public String Name {get; set;}
        public SurveyLibraryItem() {}

        public SurveyLibraryItem(SurveyLibrary__c surveyLibrary) {
            this.id = surveyLibrary.Id;
            this.Name = surveyLibrary.Name;
        }
    }
}