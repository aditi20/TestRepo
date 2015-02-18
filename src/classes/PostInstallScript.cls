/*
 * This class manage the migration of data when installing a new version of the package
 *(c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
global class PostInstallScript implements InstallHandler {

    // Actual version
    global static final Integer MAJOR_VERSION = 0;
    global static final Integer MINOR_VERSION = 0;
    global static final Integer PATCH_VERSION = 0;

    private String versionNumber;
    private String compatibleVersion;
    private String oldestVersion;
    private String downloadUrl;
    private String mobileApkVersion;
    private Boolean versionSetUp = false;
    private Boolean versionIsActive = true;

    private InstallContext icontext;

    global void onInstall(InstallContext context) {
        this.icontext = context;

        // Positions validation interferes with survey update scripts,
        // so we skip it for this method
        setFlag(C.FLAG_SKIP_QUESTION_POSITION_VALIDATION);

        loadISOCountries();

        // IDALMSA-3357: Add a record for the current ApplicationVersion
        // Allways add the last application version, the compatibles versions should be
        // updated with every release
        setUpApplicationVersion(
            '30000',
            '3.0',
            '3.0',
            'https://sites.google.com/a/grameenfoundation.org/ibt-customer-portal/' +
                'home/mobile-surveys-release-notes/mobile-app-downloads/' +
                'TaroWorks3.0.0.apk?attredirects=0&d=1',
            '3.0'
            );

        if (context.isUpgrade()) {
            performUpgrade();
        } else {
            performInstall();
        }

        addApplicationVersionSettings();
    }

    /**
     * Actions to be carried out when the application is upgraded
     */
    private void performUpgrade() {

        clearFlags();
        if (beforeVersion(2, 18, 0)) {
            addGroupToSubmission();
            moveAnswerTextValue();
        }
        if (beforeVersion(2, 22, 0)) {
            ApplicationSettingsUtils.getDefaultSetting(true);
        }
        if (beforeVersion(2, 25, 0)) {
            updateSurveysFor2_25();
            updateSurveyMappingssFor2_25();
        }
        if (beforeVersion(2, 26, 0)) {
            moveClientAssignation();
        }
        if (beforeVersion(2, 27, 0)) {
            updateCaptureGPS();
            populateMaxInstanceQuestion();
        }
        if (beforeVersion(2, 28, 0)) {
            populateSkipConditionRecords();
            migrateToApplicationVersionSettings();
        }
        if (beforeVersion(3, 1, 0)) {
            if (C.PARENT_ORG_ID != UserInfo.getOrganizationId()) {
                updateChildPpiTemplates();
            } else {
                updateExistingParentPpiTemplates();
            }
        }

        // Verify version details for the package getting installed
        verifyVersionDetails();

        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectDeletable();

        // Delete all orphan survey mappings
        delete [SELECT Id FROM SurveyMapping__c WHERE Survey__c = null];
    }

    /**
     * Verify whether package version is 3.0 and set isActive accordingly
     */
    private void verifyVersionDetails() {
        // Set isActive = false if package is upgraded to version 3.0
        if (this.versionNumber == '30000') {
            this.versionIsActive = false;
        }
    }

    /**
     * Update all Skip Condition records so that value__c will be populated to SkipValue__c
     */
    private void populateSkipConditionRecords() {
        GenericObjectCreator skipConditionCreator =
            new GenericObjectCreator(SkipCondition__c.SObjectType);
        skipConditionCreator.checkObjectAccessible();
        skipConditionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SkipCondition__c.Value__c,
                SkipCondition__c.SkipValue__c
            }
        );
        String skipConditionsQuery = 
            'SELECT ' +
                'Id, ' +
                'Value__c, ' +
                'SkipValue__c ' +
            'FROM ' +
                'SkipCondition__c';
        Id batchInstanceId = 
            Database.executeBatch(
                new ProcessExistingSkipConditionsBatch(skipConditionsQuery),
                200
            );
    }

    /**
     * For IDALMSA-3817
     * Update all Surveys when updating from a version before 2.27
     * Set Gps_Location_Enabled__c__c to false
     */
    private void updateCaptureGPS() {
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Survey__c.Gps_Location_Enabled__c
            }
        );
        List<Survey__c> surveysToUpdate = [
            SELECT
                Id,
                Gps_Location_Enabled__c
            FROM
                Survey__c
            WHERE
                Gps_Location_Enabled__c = true
        ];
        for (Survey__c survey : surveysToUpdate) {
            surveyCreator.populateFields(
                survey,
                new Map<Schema.SObjectField, Object> {
                    Survey__c.Gps_Location_Enabled__c => false
                }
            );
        }
        surveyCreator.checkObjectUpdateable();
        update surveysToUpdate;
    }

    /**
     * Actions to be carried out when the application is installed for the first time
     */
    private void performInstall() {

        // Languages must be loaded first before other survey fields are populated
        loadLanguages();
        setSurveyLanguage();
        clearFlags();
        ApplicationSettingsUtils.getDefaultSetting(true);
        addPPILicense();
        addGrameenSurveyLibrary();
    }

    String[] myflags = new String[]{};

    /**
     * Sets a flag for the post-install script.
     *
     * @param flag the name f the flag to be set.
     * @return true if the flag was set, false if the flag already exists.
     */
    private Boolean setFlag(String flag) {
        Settings__c settingsInstance = ApplicationSettingsUtils.getInstanceWithName(flag);
        if (settingsInstance == null) {
            myflags.add(flag);
            Settings__c settings = new Settings__c(Name = flag);
            insert settings;
        }
        return settingsInstance == null;
    }

    /**
     * Removes all flags created during the post-install script
     */
    private void clearFlags() {
        delete [SELECT Id FROM Settings__c WHERE Name IN :myflags];
        myflags.clear();
    }

    /**
     * Method add languages to the custom settings
     * @param languagesCodes List with languages codes that will be added
     * @param setDefault true if the surveys without language should be set to EN
     */
    private void loadLanguages(List<String> languagesCodes) {
        List<Language__c> listNewLanguages = new List<Language__c>();
        for (String key : languagesCodes) {
            if (Language__c.getInstance(key) == null) {
                Language__c languageNewInstance = new Language__c(
                    Name = key,
                    ShortLanguageName__c = PostInstallScript.allLanguages.get(key)
                );
                listNewLanguages.add(languageNewInstance);
            }
        }
        if (!listNewLanguages.isEmpty()) {
            insert listNewLanguages;
        }
    }

    /**
     * Add all languages for the Language__c custom setting.
     */
    private void loadLanguages() {
        List<String> aList = new List<String>();
        aList.addAll(PostInstallScript.allLanguages.keySet());
        this.loadLanguages(aList);
    }

    /**
     * Sets 'EN' as language to PPI surveys created before the LanguageCode__c field existed
     */
    private void setSurveyLanguage() {
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkObjectUpdateable();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.LanguageCode__c
        });
        Survey__c[] nonLaguagedSurveys = [
            SELECT
                Id
            FROM
                Survey__c
            WHERE
                LanguageCode__c = null
                OR LanguageCode__c = ''
        ];
        for (Survey__c survey : nonLaguagedSurveys) {
            surveyCreator.populateFields(
                survey,
                new Map<Schema.SObjectField, Object> {
                    Survey__c.LanguageCode__c => 'EN'
                }
            );
        }
        update nonLaguagedSurveys;
    }

    private void loadISOCountries() {
        Map<String, ISO_Country__c> currentCountries  = ISO_Country__c.getAll();
        ISO_Country__c[] countriesToInsert = new ISO_Country__c[]{};
        for (String countryCode : PostInstallScript.allCountryCodes.keySet()) {
            if (!currentCountries.containsKey(countryCode)) {
                ISO_Country__c isoCountryNewInstance = new ISO_Country__c(
                    Name = countrycode,
                    ShortName__c = PostInstallScript.allCountryCodes.get(countryCode)
                );
                countriesToInsert.add(isoCountryNewInstance);
            }
        }
        upsert countriesToInsert;
    }

    /**
     * Set the license up for a user to be able to download and use PPIs by default
     * For 1.11 and use with the template manager
     */
    private void addPPILicense() {

        // Look for the default license setting.
        LicenseSettings__c license = C.getLicense();
        license.UsePPI__c = true;
        license.DownloadPPI__c = true;
        Database.upsert(license);
    }

    /**
     * Add the library for Grameen
     */
    private void addGrameenSurveyLibrary() {

        GenericObjectCreator surveyLibraryCreator =
            new GenericObjectCreator(SurveyLibrary__c.SObjectType);
        surveyLibraryCreator.checkObjectAccessible();
        surveyLibraryCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyLibrary__c.Name,
                SurveyLibrary__c.IsPPI__c,
                SurveyLibrary__c.Active__c,
                SurveyLibrary__c.Description__c,
                SurveyLibrary__c.URL__c,
                SurveyLibrary__c.RemoteLibraryPath__c,
                SurveyLibrary__c.SurveyPreviewPath__c
            }
        );

        // Check that the user already has a library called Grameen
        SurveyLibrary__c[] libs = [
            SELECT
                Name,
                Id
            FROM
                SurveyLibrary__c
            WHERE
                Name = :C.GRAMEEN_LIBRARY
        ];
        SurveyLibrary__c lib;
        if (libs.isEmpty()) {
            lib = (SurveyLibrary__c) surveyLibraryCreator.createNewRecord();
            surveyLibraryCreator.populateFields(
                lib,
                new Map<Schema.SObjectField, Object> {
                    SurveyLibrary__c.Name => C.GRAMEEN_LIBRARY
                }
            );
        } else {
            surveyLibraryCreator.checkObjectUpdateable();
            lib = libs[0];
        }
        surveyLibraryCreator.populateFields(
            lib,
            new Map<Schema.SObjectField, Object> {
                SurveyLibrary__c.IsPPI__c => true,
                SurveyLibrary__c.Active__c => true,
                SurveyLibrary__c.Description__c  =>
                    System.Label.SURVEYLIBRARY_GRAMEEN_DESCRIPTION,
                SurveyLibrary__c.URL__c =>
                    'https://grameen-foundation.secure.force.com/surveys',
                SurveyLibrary__c.RemoteLibraryPath__c =>
                    '/services/apexrest/gfsurveys/getRemoteSurvey',
                SurveyLibrary__c.SurveyPreviewPath__c =>
                    '/gfsurveys__SurveyPreview',
                SurveyLibrary__c.PpiResultsEndpoint__c =>
                    'Testing Url. Need to change once decided'
            }
        );
        Database.upsert(lib);
    }

    /**
     * Add the group that the surveyor belongs to for all submissions to date
     */
    private void addGroupToSubmission() {

        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectAccessible();
        submissionCreator.checkObjectUpdateable();
        submissionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Submission__c.Survey__c,
                Submission__c.Surveyor__c
            }
        );

        List<Submission__c> submissions = [
            SELECT
                Id,
                Survey__c,
                Surveyor__c
            FROM
                Submission__c
            WHERE
                Assignment__c = null
        ];
        update SubmissionDO.linkSubmissionsAssignmentGroups(submissions);
    }

    /**
     * HELPER METHOD - check if the installed version is previous to this version
     */
    private Boolean beforeVersion(Integer major, Integer minor, Integer patch){
        return icontext.previousVersion().compareTo(new Version(major, minor, patch)) < 0;
    }

    /**
     * HELPER METHOD - set the version after post install
     */
    public void setVersion(Integer major, Integer minor, Integer patch) {
        Settings__c setting = ApplicationSettingsUtils.getInstanceWithName('1');
        if (setting == null) {
            Settings__c newSetting = new Settings__c(
                Name = '1',
                MajorVersion__c = 0,
                MinorVersion__c = 0,
                PatchVersion__c = 0
            );
            insert newSetting;
        } else {
            setting.MajorVersion__c = major;
            setting.MinorVersion__c = minor;
            setting.PatchVersion__c = patch;
            update setting;
        }
    }

    /**
     * Move the value of the TextValue__c field of Answer__c to TextAreaValue__c
     */
    private void moveAnswerTextValue(){
        // Only one batch can be called from test methods, so if I'm running a test method,
        // I only want to execute this piece if I'm actually testing it.
        if (Test.isRunningTest()
                && ApplicationSettingsUtils.getInstanceWithName(C.TEST_ANSWER_TEXT_VALUE) == null
        ) {
            return;
        }

        Database.executeBatch(new PostInstallScript_011000MoveAnswerText(), 1);
    }

    /**
     * Update all Surveys when updating from a version before 2.25
     * Set AllowAnonymousInterviewee__c to false
     * Set InterviewMapField__c == null
     */
    private void updateSurveysFor2_25() {

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkObjectUpdateable();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Survey__c.InterviewMapField__c,
            Survey__c.AllowAnonymousInterviewee__c
        });

        List<Survey__c> surveysToUpdate = [
            SELECT
                Id,
                InterviewMapField__c,
                AllowAnonymousInterviewee__c
            FROM
                Survey__c
            WHERE
                InterviewMapField__c != null
                OR AllowAnonymousInterviewee__c = true
        ];
        for (Survey__c survey : surveysToUpdate) {
            surveyCreator.populateFields(
                survey,
                new Map<Schema.SObjectField, Object> {
                    Survey__c.InterviewMapField__c => null,
                    Survey__c.AllowAnonymousInterviewee__c => false
                }
            );
        }
        update surveysToUpdate;
    }

    /**
     * Update all SurveyMappings when updating from a version before 2.25
     * Set UseAsInterviewee__c to false
     * Set IntervieweeApiField__c == null
     */
    private void updateSurveyMappingssFor2_25() {

        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkObjectUpdateable();
        surveyMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            SurveyMapping__c.IntervieweeApiField__c,
            SurveyMapping__c.UseAsInterviewee__c
        });

        List<SurveyMapping__c> surveyMappingsToUpdate = [
            SELECT
                Id,
                IntervieweeApiField__c,
                UseAsInterviewee__c
            FROM
                SurveyMapping__c
            WHERE
                UseAsInterviewee__c = true
                OR IntervieweeApiField__c != null
        ];
        for (SurveyMapping__c surveyMapping : surveyMappingsToUpdate) {
            surveyMappingCreator.populateFields(
                surveyMapping,
                new Map<Schema.SObjectField, Object> {
                    SurveyMapping__c.IntervieweeApiField__c => null,
                    SurveyMapping__c.UseAsInterviewee__c => false
                }
            );
        }
        update surveyMappingsToUpdate;
    }

    /**
     * Move the client assignation to the new object model
     */
    private void moveClientAssignation() {
        List<SObjectContactAssociation__c> newAssociations = new List<SObjectContactAssociation__c>();
        List<Client_Assignation__c> oldAssignations = new List<Client_Assignation__c>();
        GenericObjectCreator clientAssignationCreator =
            new GenericObjectCreator(Client_Assignation__c.SObjectType);
        clientAssignationCreator.checkObjectAccessible();
        clientAssignationCreator.checkObjectDeletable();
        clientAssignationCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Client_Assignation__c.Mobile_User__c,
            Client_Assignation__c.Client__c
        });
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();
        mobileUserCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                Mobile_User__c.Contact__c
            }
        );

        for (Mobile_User__c mobileUser : [
                SELECT
                    Id,
                    Contact__c,
                    (
                        SELECT
                            Id,
                            Client__c
                        FROM
                            Client_Assignations__r
                    )
                FROM
                    Mobile_User__c
            ]
        ) {
            List<Id> clientIds = new List<Id>();
            for (Client_Assignation__c assignation : mobileUser.Client_Assignations__r) {
                clientIds.add(assignation.Client__c);
            }

            if (clientIds.size() > 0) {
                newAssociations.addAll(
                    SObjectContactAssociationDO.createNewRecords(
                        mobileUser.Contact__c,
                        Schema.SObjectType.Contact.getName(),
                        clientIds
                    )
                );
                oldAssignations.addAll(mobileUser.Client_Assignations__r);
            }
        }
        insert newAssociations;
        delete oldAssignations;
    }

    /**
     * Populate all question records with max of Instance__c from its child answer records
     *
     * This method will in turn call ProcessAnswerRecordsBatch to process all answer records present in database
     */
    private void populateMaxInstanceQuestion() {

        GenericObjectCreator answerCreator =
            new GenericObjectCreator(Answer__c.SObjectType);
        answerCreator.checkObjectAccessible();
        answerCreator.checkFieldsAccessible(
            new List<String> {
                'Question__c',
                'Instance__c'
            }
        );
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<String> {'MaxInstance__c'}
        );

        String parentAnswersQuery = 
            'SELECT ' +
                'Instance__c, ' +
                'Question__r.Id, ' +
                'Question__r.MaxInstance__c ' +
            'FROM ' +
                'Answer__c ';
        Id batchInstanceId = 
            Database.executeBatch(
                new ProcessAnswerRecordsBatch(parentAnswersQuery),
                200
            );
    }

    /**
     * Set the parameters for the application version
     * TODO: Move this to ApplicationVersionDomain when SoC is finished
     *
     * @param newVersionNumber     - The version of the mobile application
     * @param newCompatibleVersion - The version of Salesforce that this application was released to
     *                                 work with
     * @param newOldestVersion     - Indicates the oldest version of Salesforce that the application
     *                                 was tested against
     * @param newDownloadUrl       - The URL where the application version can be downloaded from
     */
    @TestVisible
    private void setUpApplicationVersion(
            String newVersionNumber,
            String newCompatibleVersion,
            String newOldestVersion,
            String newDownloadUrl,
            String mobileApkVersion
    ) {
        if (!this.versionSetUp) {
            this.versionNumber = newVersionNumber;
            this.compatibleVersion = newCompatibleVersion;
            this.oldestVersion = newOldestVersion;
            this.downloadUrl = newDownloadUrl;
            this.versionSetUp = true;
            this.mobileApkVersion = mobileApkVersion;
        }
    }

    /**
     * Add a record for the version custom setting of the mobile application.
     * Checks that the version doesn't exist already.
     */
    private void addApplicationVersionSettings() {

        ApplicationVersionSettings__c applicationVersionSettings =
            ApplicationVersionSettingsSelector.getInstanceWithVersionNumber(this.versionNumber);
        if (applicationVersionSettings == null) {
            applicationVersionSettings =
                new ApplicationVersionSettingsSelector().createRecord(
                    this.versionNumber,
                    this.compatibleVersion,
                    this.oldestVersion,
                    this.downloadUrl,
                    this.mobileAPKVersion,
                    this.versionIsActive
                );

            insert applicationVersionSettings;
        }
    }

    /**
     * Migrating the existing records of Application version object to Apllication
     * version Custom Settings
     */
    @TestVisible
    private static void migrateToApplicationVersionSettings () {

        List<ApplicationVersionSettings__c> applicationVersionSettings = 
            new List<ApplicationVersionSettings__c>();

        GenericObjectCreator applicationVersionCreator =
            new GenericObjectCreator(ApplicationVersion__c.SObjectType);
        applicationVersionCreator.checkObjectAccessible();
        ApplicationVersionDomain applicationVersionDomain =
            new ApplicationVersionDomain(new ApplicationVersionSelector().getRecords());

        for (
                ApplicationVersion__c applicationVersion :
                    (List<ApplicationVersion__c>) applicationVersionDomain.records
        ) {
            if (ApplicationVersionSettings__c.getInstance(applicationVersion.Name) == null) {
                applicationVersionSettings.add(
                    new ApplicationVersionSettings__c(
                        Name = applicationVersion.Name,
                        CompatibleVersion__c = applicationVersion.CompatibleVersion__c,
                        OldestConfirmedVersion__c = applicationVersion.OldestConfirmedVersion__c,
                        DownloadUrl__c = applicationVersion.DownloadURL__c,
                        ReleaseDate__c = applicationVersion.ReleaseDate__c
                    )
                );
            }
        }
        insert applicationVersionSettings;
        applicationVersionDomain.deleteRecords();
    }

    /**
     * Update Status of PPI Template (Survey Verion) to 'Deprecated'
     * and append '_DEPRECATED' to Survey Name.
     */
    @TestVisible
    private void updateChildPpiTemplates() {
        SurveyDO surveyDomainInstance =
            new SurveyDO.Constructor().constructWithRecords(
                new SurveySelector().getPpiTemplatesWithSurveyVersion()
            );

        List<SurveyVersion__c> listSurveyVersion = new List<SurveyVersion__c>();

        for (Survey__c surveyInstance : (List<Survey__c>) surveyDomainInstance.records) {
            new GenericObjectCreator(Survey__c.SObjectType).populateField(
                surveyInstance,
                Survey__c.Name,
                surveyInstance.Name + '_DEPRECATED'
            );

            for (SurveyVersion__c surveyVersionInstance : surveyInstance.SurveyVersions__r) {
                new GenericObjectCreator(SurveyVersion__c.SObjectType).populateField(
                    surveyVersionInstance,
                    SurveyVersion__c.Status__c,
                    SurveyDO.STATUS_DEPRECATED
                );
                listSurveyVersion.add(surveyVersionInstance);
            }
        }

        if (surveyDomainInstance.records.size() > 0) {
            surveyDomainInstance.updateRecords();
        }
        if (listSurveyVersion.size() > 0) {
            SurveyVersionDomain surveyVersionDomainInstance =
                new SurveyVersionDomain.Constructor().constructWithRecords(listSurveyVersion);
            surveyVersionDomainInstance.updateRecords();
        }
    }

    /**
     * Populate PpiIdentifier__c field in ppi template survey.
     * Update Distributed__c field from SurveyVersion__c to allow to update ppi template
     * Delete old Ppi template's survey.json attachment records
     * Delete all lookup table records for old ppi templates.
     */
    @TestVisible
    private void updateExistingParentPpiTemplates() {

        Set<Id> setPpiTemplateIds = populatePpiIdentifierInPpiTemplate();
        if (setPpiTemplateIds != null && !setPpiTemplateIds.isEmpty()) {
            Set<Id> setSurveyVersionIds = updateDistributedInSurveyVersion(setPpiTemplateIds);
            if (setSurveyVersionIds != null && !setSurveyVersionIds.isEmpty()) {
                deleteOldTemplateJSONAttachment(setSurveyVersionIds);
            }
            deleteLookUpTableRecords(setPpiTemplateIds);
        }
    }

    /**
     * Populate PpiIdentifier__c in Ppi Template Survey
     */
    private Set<Id> populatePpiIdentifierInPpiTemplate() {
        // Get all Ppi Template records
        SurveyDO surveyDomainInstance =
            new SurveyDO.Constructor().constructWithRecords(
                new SurveySelector().getPpiTemplatesWithDbFullAccess()
            );

        Set<Id> setPpiTemplateIds = new Set<Id>();
        for (Survey__c surveyInstance : (List<Survey__c>) surveyDomainInstance.records) {
            setPpiTemplateIds.add(surveyInstance.Id);
        }

        // Populate PpiIdentifier__c field in Ppi Template 
        surveyDomainInstance.setPpiIdentifier((List<Survey__c>) surveyDomainInstance.records);
        surveyDomainInstance.upsertRecordsDbFullAccess();
        return setPpiTemplateIds;
    }

    /**
     * Update Distributed__c field from SurveyVersion__c to allow to update ppi template
     */
    private Set<Id> updateDistributedInSurveyVersion(Set<Id> setPpiTemplateIds) {
        Set<Id> updatedSurveyVersionIds = new Set<Id>();

        // Update Survey Version
        SurveyVersionDomain surveyVersionDomainInstance =
            new SurveyVersionDomain.Constructor().constructWithRecords(
                new SurveyVersionSelector().getAllForSurveyIds(setPpiTemplateIds)
            );

        for (
                SurveyVersion__c surveyVersionInstance :
                    (List<SurveyVersion__c>) surveyVersionDomainInstance.records
        ) {
            surveyVersionInstance.Distributed__c = false;
            surveyVersionInstance.DistributionDate__c = null;
            updatedSurveyVersionIds.add(surveyVersionInstance.Id);
        }
        surveyVersionDomainInstance.upsertRecordsDbFullAccess();

        return updatedSurveyVersionIds;
    }

    /**
     * Delete all survey.json attachment records related to old template's Suvey Version records 
     */
    @TestVisible
    private void deleteOldTemplateJSONAttachment(Set<Id> setSurveyVersionIds) {
        List<Attachment> attachmentList =
            new AttachmentSelector().getAllWithParentId(setSurveyVersionIds, C.SURVEY_FILE_JSON);

        if (!attachmentList.isEmpty()) {
            AttachmentDomain attachmentDomainInstance =
                new AttachmentDomain.Constructor().constructWithRecords(attachmentList);
            attachmentDomainInstance.deleteRecords();
        }
    }

    /**
     * Delete all lookup table records for specified old ppi templates.
     */
    private void deleteLookUpTableRecords(Set<Id> setPpiTemplateIds) {
        // Delete Ppi Table Line records
        PpiTableLineDomain ppiTableLineDomainInstance =
            new PpiTableLineDomain.Constructor().constructWithRecords(
               new PpiTableLineSelector().getAllForOldSurveyIds(setPpiTemplateIds)
            );

        Set<Id> setPpiTableIds = new Set<Id>();
        for (
                PPITableLine__c ppiTableLineInstance :
                    (List<PPITableLine__c>) ppiTableLineDomainInstance.records
        ) {
            setPpiTableIds.add(ppiTableLineInstance.PPITableDataSet__r.PPITable__c);
        }
        ppiTableLineDomainInstance.deleteRecordsDbFullAccess();

        // Delete Ppi Table records
        PpiTableDomain ppiTableDomainInstance =
            new PpiTableDomain.Constructor().constructWithRecords(
                new PpiTableSelector().getRecordsById(setPpiTableIds)
            );
        ppiTableDomainInstance.deleteRecordsDbFullAccess();
    }

    //--------------------
    // BIG LISTS OF VALUES
    //--------------------

    global static final Map<String, String> allLanguages = new Map<String, String>{
                                                        'AA' =>'Afar',
                                                        'AB' =>'Abkhazian',
                                                        'AF' =>'Afrikaans',
                                                        'AM' =>'Amharic',
                                                        'AR' =>'Arabic',
                                                        'AS' =>'Assamese',
                                                        'AY' =>'Aymara',
                                                        'AZ' =>'Azerbaijani',
                                                        'BA' =>'Bashkir',
                                                        'BE' =>'Byelorussian',
                                                        'BG' =>'Bulgarian',
                                                        'BH' =>'Bihari',
                                                        'BI' =>'Bislama',
                                                        'BN' =>'Bengali',
                                                        'BO' =>'Tibetan',
                                                        'BR' =>'Breton',
                                                        'CA' =>'Catalan',
                                                        'CEB' => 'Cebuano',
                                                        'CO' =>'Corsican',
                                                        'CS' =>'Czech',
                                                        'CY' =>'Welsh',
                                                        'DA' =>'Danish',
                                                        'DE' =>'German',
                                                        'DZ' =>'Bhutani',
                                                        'EL' =>'Greek',
                                                        'EN' =>'English',
                                                        'EO' =>'Esperanto',
                                                        'ES' =>'Spanish',
                                                        'ET' =>'Estonian',
                                                        'EU' =>'Basque',
                                                        'FA' =>'Persian',
                                                        'FI' =>'Finnish',
                                                        'FJ' =>'Fiji',
                                                        'FO' =>'Faeroese',
                                                        'FR' =>'French',
                                                        'FY' =>'Frisian',
                                                        'GA' =>'Irish',
                                                        'GD' =>'Gaelic',
                                                        'GL' =>'Galician',
                                                        'GN' =>'Guarani',
                                                        'GU' =>'Gujarati',
                                                        'HA' =>'Hausa',
                                                        'HI' =>'Hindi',
                                                        'HIL' => 'Hiligaynon',
                                                        'HR' =>'Croatian',
                                                        'HU' =>'Hungarian',
                                                        'HY' =>'Armenian',
                                                        'IA' =>'Interlingua',
                                                        'IE' =>'Interlingue',
                                                        'IK' =>'Inupiak',
                                                        'IN' =>'Indonesian',
                                                        'IS' =>'Icelandic',
                                                        'IT' =>'Italian',
                                                        'IW' =>'Hebrew',
                                                        'JA' =>'Japanese',
                                                        'JI' =>'Yiddish',
                                                        'JW' =>'Javanese',
                                                        'KA' =>'Georgian',
                                                        'KK' =>'Kazakh',
                                                        'KL' =>'Greenlandic',
                                                        'KM' =>'Cambodian',
                                                        'KN' =>'Kannada',
                                                        'KO' =>'Korean',
                                                        'KS' =>'Kashmiri',
                                                        'KU' =>'Kurdish',
                                                        'KY' =>'Kirghiz',
                                                        'LA' =>'Latin',
                                                        'LN' =>'Lingala',
                                                        'LO' =>'Laothian',
                                                        'LT' =>'Lithuanian',
                                                        'LV' =>'Latvian',
                                                        'MG' =>'Malagasy',
                                                        'MI' =>'Maori',
                                                        'MK' =>'Macedonian',
                                                        'ML' =>'Malayalam',
                                                        'MN' =>'Mongolian',
                                                        'MO' =>'Moldavian',
                                                        'MR' =>'Marathi',
                                                        'MS' =>'Malay',
                                                        'MT' =>'Maltese',
                                                        'MY' =>'Burmese',
                                                        'NA' =>'Nauru',
                                                        'NE' =>'Nepali',
                                                        'NL' =>'Dutch',
                                                        'NO' =>'Norwegian',
                                                        'OC' =>'Occitan',
                                                        'OM' =>'Oromo',
                                                        'OR' =>'Oriya',
                                                        'PA' =>'Punjabi',
                                                        'PL' =>'Polish',
                                                        'PS' =>'Pashto',
                                                        'PT' =>'Portuguese',
                                                        'QU' =>'Quechua',
                                                        'RM' =>'Rhaeto-Romance',
                                                        'RN' =>'Kirundi',
                                                        'RO' =>'Romanian',
                                                        'RU' =>'Russian',
                                                        'RW' =>'Kinyarwanda',
                                                        'SA' =>'Sanskrit',
                                                        'SD' =>'Sindhi',
                                                        'SG' =>'Sangro',
                                                        'SH' =>'Serbo-Croatian',
                                                        'SI' =>'Singhalese',
                                                        'SK' =>'Slovak',
                                                        'SL' =>'Slovenian',
                                                        'SM' =>'Samoan',
                                                        'SN' =>'Shona',
                                                        'SO' =>'Somali',
                                                        'SQ' =>'Albanian',
                                                        'SR' =>'Serbian',
                                                        'SS' =>'Siswati',
                                                        'ST' =>'Sesotho',
                                                        'SU' =>'Sudanese',
                                                        'SV' =>'Swedish',
                                                        'SW' =>'Swahili',
                                                        'TA' =>'Tamil',
                                                        'TE' =>'Tegulu',
                                                        'TG' =>'Tajik',
                                                        'TH' =>'Thai',
                                                        'TI' =>'Tigrinya',
                                                        'TK' =>'Turkmen',
                                                        'TL' =>'Tagalog',
                                                        'TN' =>'Setswana',
                                                        'TO' =>'Tonga',
                                                        'TR' =>'Turkish',
                                                        'TS' =>'Tsonga',
                                                        'TT' =>'Tatar',
                                                        'TW' =>'Twi',
                                                        'UK' =>'Ukrainian',
                                                        'UR' =>'Urdu',
                                                        'UZ' =>'Uzbek',
                                                        'VI' =>'Vietnamese',
                                                        'VO' =>'Volapuk',
                                                        'WO' =>'Wolof',
                                                        'XH' =>'Xhosa',
                                                        'YO' =>'Yoruba',
                                                        'ZH' =>'Chinese',
                                                        'ZU' =>'Zulu'};

    global static final Map<String, String> allCountryCodes = new Map<String, String>{'AF' => 'AFGHANISTAN',
                                                        'AX' => 'ÅLAND ISLANDS',
                                                        'AL' => 'ALBANIA',
                                                        'DZ' => 'ALGERIA',
                                                        'AS' => 'AMERICAN SAMOA',
                                                        'AD' => 'ANDORRA',
                                                        'AO' => 'ANGOLA',
                                                        'AI' => 'ANGUILLA',
                                                        'AQ' => 'ANTARCTICA',
                                                        'AG' => 'ANTIGUA AND BARBUDA',
                                                        'AR' => 'ARGENTINA',
                                                        'AM' => 'ARMENIA',
                                                        'AW' => 'ARUBA',
                                                        'AU' => 'AUSTRALIA',
                                                        'AT' => 'AUSTRIA',
                                                        'AZ' => 'AZERBAIJAN',
                                                        'BS' => 'BAHAMAS',
                                                        'BH' => 'BAHRAIN',
                                                        'BD' => 'BANGLADESH',
                                                        'BB' => 'BARBADOS',
                                                        'BY' => 'BELARUS',
                                                        'BE' => 'BELGIUM',
                                                        'BZ' => 'BELIZE',
                                                        'BJ' => 'BENIN',
                                                        'BM' => 'BERMUDA',
                                                        'BT' => 'BHUTAN',
                                                        'BO' => 'BOLIVIA, PLURINATIONAL STATE OF',
                                                        'BQ' => 'BONAIRE, SINT EUSTATIUS AND SABA',
                                                        'BA' => 'BOSNIA AND HERZEGOVINA',
                                                        'BW' => 'BOTSWANA',
                                                        'BV' => 'BOUVET ISLAND',
                                                        'BR' => 'BRAZIL',
                                                        'IO' => 'BRITISH INDIAN OCEAN TERRITORY',
                                                        'BN' => 'BRUNEI DARUSSALAM',
                                                        'BG' => 'BULGARIA',
                                                        'BF' => 'BURKINA FASO',
                                                        'BI' => 'BURUNDI',
                                                        'KH' => 'CAMBODIA',
                                                        'CM' => 'CAMEROON',
                                                        'CA' => 'CANADA',
                                                        'CV' => 'CAPE VERDE',
                                                        'KY' => 'CAYMAN ISLANDS',
                                                        'CF' => 'CENTRAL AFRICAN REPUBLIC',
                                                        'TD' => 'CHAD',
                                                        'CL' => 'CHILE',
                                                        'CN' => 'CHINA',
                                                        'CX' => 'CHRISTMAS ISLAND',
                                                        'CC' => 'COCOS (KEELING) ISLANDS',
                                                        'CO' => 'COLOMBIA',
                                                        'KM' => 'COMOROS',
                                                        'CG' => 'CONGO',
                                                        'CD' => 'CONGO, THE DEMOCRATIC REPUBLIC OF THE',
                                                        'CK' => 'COOK ISLANDS',
                                                        'CR' => 'COSTA RICA',
                                                        'CI' => 'CÔTE D\'IVOIRE',
                                                        'HR' => 'CROATIA',
                                                        'CU' => 'CUBA',
                                                        'CW' => 'CURAÇAO',
                                                        'CY' => 'CYPRUS',
                                                        'CZ' => 'CZECH REPUBLIC',
                                                        'DK' => 'DENMARK',
                                                        'DJ' => 'DJIBOUTI',
                                                        'DM' => 'DOMINICA',
                                                        'DO' => 'DOMINICAN REPUBLIC',
                                                        'EC' => 'ECUADOR',
                                                        'EG' => 'EGYPT',
                                                        'SV' => 'EL SALVADOR',
                                                        'GQ' => 'EQUATORIAL GUINEA',
                                                        'ER' => 'ERITREA',
                                                        'EE' => 'ESTONIA',
                                                        'ET' => 'ETHIOPIA',
                                                        'FK' => 'FALKLAND ISLANDS (MALVINAS)',
                                                        'FO' => 'FAROE ISLANDS',
                                                        'FJ' => 'FIJI',
                                                        'FI' => 'FINLAND',
                                                        'FR' => 'FRANCE',
                                                        'GF' => 'FRENCH GUIANA',
                                                        'PF' => 'FRENCH POLYNESIA',
                                                        'TF' => 'FRENCH SOUTHERN TERRITORIES',
                                                        'GA' => 'GABON',
                                                        'GM' => 'GAMBIA',
                                                        'GE' => 'GEORGIA',
                                                        'DE' => 'GERMANY',
                                                        'GH' => 'GHANA',
                                                        'GI' => 'GIBRALTAR',
                                                        'GR' => 'GREECE',
                                                        'GL' => 'GREENLAND',
                                                        'GD' => 'GRENADA',
                                                        'GP' => 'GUADELOUPE',
                                                        'GU' => 'GUAM',
                                                        'GT' => 'GUATEMALA',
                                                        'GG' => 'GUERNSEY',
                                                        'GN' => 'GUINEA',
                                                        'GW' => 'GUINEA-BISSAU',
                                                        'GY' => 'GUYANA',
                                                        'HT' => 'HAITI',
                                                        'HM' => 'HEARD ISLAND AND MCDONALD ISLANDS',
                                                        'VA' => 'HOLY SEE (VATICAN CITY STATE)',
                                                        'HN' => 'HONDURAS',
                                                        'HK' => 'HONG KONG',
                                                        'HU' => 'HUNGARY',
                                                        'IS' => 'ICELAND',
                                                        'IN' => 'INDIA',
                                                        'ID' => 'INDONESIA',
                                                        'IR' => 'IRAN, ISLAMIC REPUBLIC OF',
                                                        'IQ' => 'IRAQ',
                                                        'IE' => 'IRELAND',
                                                        'IM' => 'ISLE OF MAN',
                                                        'IL' => 'ISRAEL',
                                                        'IT' => 'ITALY',
                                                        'JM' => 'JAMAICA',
                                                        'JP' => 'JAPAN',
                                                        'JE' => 'JERSEY',
                                                        'JO' => 'JORDAN',
                                                        'KZ' => 'KAZAKHSTAN',
                                                        'KE' => 'KENYA',
                                                        'KI' => 'KIRIBATI',
                                                        'KP' => 'KOREA, DEMOCRATIC PEOPLE\'S REPUBLIC OF',
                                                        'KR' => 'KOREA, REPUBLIC OF',
                                                        'KW' => 'KUWAIT',
                                                        'KG' => 'KYRGYZSTAN',
                                                        'LA' => 'LAO PEOPLE\'S DEMOCRATIC REPUBLIC',
                                                        'LV' => 'LATVIA',
                                                        'LB' => 'LEBANON',
                                                        'LS' => 'LESOTHO',
                                                        'LR' => 'LIBERIA',
                                                        'LY' => 'LIBYA',
                                                        'LI' => 'LIECHTENSTEIN',
                                                        'LT' => 'LITHUANIA',
                                                        'LU' => 'LUXEMBOURG',
                                                        'MO' => 'MACAO',
                                                        'MK' => 'MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF',
                                                        'MG' => 'MADAGASCAR',
                                                        'MW' => 'MALAWI',
                                                        'MY' => 'MALAYSIA',
                                                        'MV' => 'MALDIVES',
                                                        'ML' => 'MALI',
                                                        'MT' => 'MALTA',
                                                        'MH' => 'MARSHALL ISLANDS',
                                                        'MQ' => 'MARTINIQUE',
                                                        'MR' => 'MAURITANIA',
                                                        'MU' => 'MAURITIUS',
                                                        'YT' => 'MAYOTTE',
                                                        'MX' => 'MEXICO',
                                                        'FM' => 'MICRONESIA, FEDERATED STATES OF',
                                                        'MD' => 'MOLDOVA, REPUBLIC OF',
                                                        'MC' => 'MONACO',
                                                        'MN' => 'MONGOLIA',
                                                        'ME' => 'MONTENEGRO',
                                                        'MS' => 'MONTSERRAT',
                                                        'MA' => 'MOROCCO',
                                                        'MZ' => 'MOZAMBIQUE',
                                                        'MM' => 'MYANMAR',
                                                        'NA' => 'NAMIBIA',
                                                        'NR' => 'NAURU',
                                                        'NP' => 'NEPAL',
                                                        'NL' => 'NETHERLANDS',
                                                        'NC' => 'NEW CALEDONIA',
                                                        'NZ' => 'NEW ZEALAND',
                                                        'NI' => 'NICARAGUA',
                                                        'NE' => 'NIGER',
                                                        'NG' => 'NIGERIA',
                                                        'NU' => 'NIUE',
                                                        'NF' => 'NORFOLK ISLAND',
                                                        'MP' => 'NORTHERN MARIANA ISLANDS',
                                                        'NO' => 'NORWAY',
                                                        'OM' => 'OMAN',
                                                        'PK' => 'PAKISTAN',
                                                        'PW' => 'PALAU',
                                                        'PS' => 'PALESTINIAN TERRITORY, OCCUPIED',
                                                        'PA' => 'PANAMA',
                                                        'PG' => 'PAPUA NEW GUINEA',
                                                        'PY' => 'PARAGUAY',
                                                        'PE' => 'PERU',
                                                        'PH' => 'PHILIPPINES',
                                                        'PN' => 'PITCAIRN',
                                                        'PL' => 'POLAND',
                                                        'PT' => 'PORTUGAL',
                                                        'PR' => 'PUERTO RICO',
                                                        'QA' => 'QATAR',
                                                        'RE' => 'RÉUNION',
                                                        'RO' => 'ROMANIA',
                                                        'RU' => 'RUSSIAN FEDERATION',
                                                        'RW' => 'RWANDA',
                                                        'BL' => 'SAINT BARTHÉLEMY',
                                                        'SH' => 'SAINT HELENA, ASCENSION AND TRISTAN DA CUNHA',
                                                        'KN' => 'SAINT KITTS AND NEVIS',
                                                        'LC' => 'SAINT LUCIA',
                                                        'MF' => 'SAINT MARTIN (FRENCH PART)',
                                                        'PM' => 'SAINT PIERRE AND MIQUELON',
                                                        'VC' => 'SAINT VINCENT AND THE GRENADINES',
                                                        'WS' => 'SAMOA',
                                                        'SM' => 'SAN MARINO',
                                                        'ST' => 'SAO TOME AND PRINCIPE',
                                                        'SA' => 'SAUDI ARABIA',
                                                        'SN' => 'SENEGAL',
                                                        'RS' => 'SERBIA',
                                                        'SC' => 'SEYCHELLES',
                                                        'SL' => 'SIERRA LEONE',
                                                        'SG' => 'SINGAPORE',
                                                        'SX' => 'SINT MAARTEN (DUTCH PART)',
                                                        'SK' => 'SLOVAKIA',
                                                        'SI' => 'SLOVENIA',
                                                        'SB' => 'SOLOMON ISLANDS',
                                                        'SO' => 'SOMALIA',
                                                        'ZA' => 'SOUTH AFRICA',
                                                        'GS' => 'SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS',
                                                        'SS' => 'SOUTH SUDAN',
                                                        'ES' => 'SPAIN',
                                                        'LK' => 'SRI LANKA',
                                                        'SD' => 'SUDAN',
                                                        'SR' => 'SURINAME',
                                                        'SJ' => 'SVALBARD AND JAN MAYEN',
                                                        'SZ' => 'SWAZILAND',
                                                        'SE' => 'SWEDEN',
                                                        'CH' => 'SWITZERLAND',
                                                        'SY' => 'SYRIAN ARAB REPUBLIC',
                                                        'TW' => 'TAIWAN, PROVINCE OF CHINA',
                                                        'TJ' => 'TAJIKISTAN',
                                                        'TZ' => 'TANZANIA, UNITED REPUBLIC OF',
                                                        'TH' => 'THAILAND',
                                                        'TL' => 'TIMOR-LESTE',
                                                        'TG' => 'TOGO',
                                                        'TK' => 'TOKELAU',
                                                        'TO' => 'TONGA',
                                                        'TT' => 'TRINIDAD AND TOBAGO',
                                                        'TN' => 'TUNISIA',
                                                        'TR' => 'TURKEY',
                                                        'TM' => 'TURKMENISTAN',
                                                        'TC' => 'TURKS AND CAICOS ISLANDS',
                                                        'TV' => 'TUVALU',
                                                        'UG' => 'UGANDA',
                                                        'UA' => 'UKRAINE',
                                                        'AE' => 'UNITED ARAB EMIRATES',
                                                        'GB' => 'UNITED KINGDOM',
                                                        'US' => 'UNITED STATES',
                                                        'UM' => 'UNITED STATES MINOR OUTLYING ISLANDS',
                                                        'UY' => 'URUGUAY',
                                                        'UZ' => 'UZBEKISTAN',
                                                        'VU' => 'VANUATU',
                                                        'VE' => 'VENEZUELA, BOLIVARIAN REPUBLIC OF',
                                                        'VN' => 'VIETNAM',
                                                        'VG' => 'VIRGIN ISLANDS, BRITISH',
                                                        'VI' => 'VIRGIN ISLANDS, U.S.',
                                                        'WF' => 'WALLIS AND FUTUNA',
                                                        'EH' => 'WESTERN SAHARA',
                                                        'YE' => 'YEMEN',
                                                        'ZM' => 'ZAMBIA',
                                                        'ZW' => 'ZIMBABWE'};
}
