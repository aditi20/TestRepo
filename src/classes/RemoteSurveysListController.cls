/**
 * Controller for the page that shows the list of surveys available from a remote server
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 */
public with sharing class RemoteSurveysListController {

    private Map<String, SurveyVersion__c> versionMap;

    public SurveyLibrary__c library { get; set; }
    public List<SurveyVersion__c> parsedSurveys {
        get{
            this.parsedSurveys = versionMap.values();
            this.parsedSurveys.sort();
            return this.parsedSurveys;
        }
        set;
    }
    public String success { get; set; }
    public String newSurveyId { get; set; }
    public String originPreview { get; set; }
    public String successMessage { get; set; }

    private String formType;

    public RemoteSurveysListController() {

        this.success = '';
        this.newSurveyId = '';
        this.successMessage = '';
        String libraryName = System.currentPageReference().getParameters().get(C.LIBRARY_NAME);
        this.formType = System.currentPageReference().getParameters().get(C.FORM_TYPE);
        this.parsedSurveys = new List<SurveyVersion__c>();
        this.versionMap = new Map<String, SurveyVersion__c>();

        if (libraryName == null || !loadLibrary(libraryName)) {

            // The library no longer exists. Display error message
            if (libraryName != null && libraryName.equalsIgnoreCase(C.GRAMEEN_LIBRARY)) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'You do not have access to Grameen\'s survey library. Please contact support'));
            }
            else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, System.Label.SURVEY_LIBRARY_ERR_NOEXIST));
            }
        }
        else {

            try{
                // Library has successfully loaded so make the callout to get the list of available surveys
                getSurveyList();
            }
            catch (Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }
    }

    /**
     * Get the list of surveys from a remote server
     */
    private void getSurveyList() {

        HttpResponse res = getSurveyListResponse();
        checkResponse(res);
        if (res.getStatusCode() == C.HTTP_OK) {
            parseJsonListResponse(res.getBody());
        }
    }

    /**
     * Load the library
     *
     * @param libraryName - The SurveyLibrary__c.Name of the library being requested
     *
     * @return - Boolean to indicate the library has loaded and is valid
     */
    public Boolean loadLibrary(String libraryName) {
        GenericObjectCreator surveyLibraryCreator =
            new GenericObjectCreator(SurveyLibrary__c.SObjectType);
        surveyLibraryCreator.checkObjectAccessible();
        surveyLibraryCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyLibrary__c.Name,
                SurveyLibrary__c.URL__c,
                SurveyLibrary__c.RemoteLibraryPath__c,
                SurveyLibrary__c.SurveyPreviewPath__c,
                SurveyLibrary__c.Description__c
            }
        );
        SurveyLibrary__c[] remoteLibrary = [
            SELECT
                Id,
                Name,
                URL__c,
                RemoteLibraryPath__c,
                SurveyPreviewPath__c,
                Description__c
            FROM
                SurveyLibrary__c
            WHERE
                Name = :libraryName
            LIMIT 1
        ];
        if (remoteLibrary.isEmpty()) {
            return false;
        }
        this.library = remoteLibrary[0];
        if (
                this.library == null ||
                this.library.URL__c == null ||
                this.library.RemoteLibraryPath__c == null ||
                this.library.SurveyPreviewPath__c == null
        ) {
            return false;
        }
        return true;
    }

    /**
     * Get the http response with a list of surveys from a remote server
     */
    private HttpResponse getSurveyListResponse() {
        Http http = new Http();
        return http.send(buildRequest(null));
    }

    /**
     * Check the response code sent back and output a suitable message
     *
     * @param - The HttpResponse
     */
    private void checkResponse(HttpResponse res) {

        Integer code = res.getStatusCode();
        if (code == C.HTTP_NOT_FOUND) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, System.Label.SURVEY_LIBRARY_ERR_NOTFOUND));
        }
        else if (code == C.HTTP_NO_CONTENT) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, System.Label.SURVEY_LIBRARY_ERR_NOCONTENT));
        }
        else if (code != C.HTTP_OK) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, System.Label.SURVEY_LIBRARY_ERR_DOWNLOAD));
        }
    }

    /**
     * Parse the JSON response from the remote server for a survey list request
     *
     * @param jsonString - The JSON String that was returned by the remote server
     */
    public void parseJsonListResponse(String jsonString) {

        JSONParser parser = JSON.createParser(jsonString);
        while (parser.nextToken() != null) {

            // Check that the token is a field name
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME
                    && parser.getText().equals('results')
            ) {

                // Step past the name and the start of the array
                parser.nextToken();
                parser.nextToken();
                while (parser.getCurrentToken() != JSONToken.END_ARRAY) {
                    SurveyVersion__c ver = (SurveyVersion__c)parser.readValueAs(SurveyVersion__c.class);
                    versionMap.put(ver.Survey__r.Name, ver);
                    parser.nextToken();
                }
            }
        }

        if (formType.equals(C.FORM_TYPE_PPI) || formType.equals(C.FORM_TYPE_TEMP)) {

            // Remove any templates that have already been downloaded
            Map<String, SurveyVersion__c> existingTemps = new Map<String, SurveyVersion__c>();
            for (SurveyVersion__c s : loadTemplates()) {
                existingTemps.put(s.Survey__r.Name, s);
            }
            for (String key : versionMap.keySet()) {
                if (existingTemps.containsKey(key)) {
                    versionMap.remove(key);
                }
            }
        }
    }

    /**
     * Load all the templates that exist on the org for a given library
     */
    @TestVisible
    private List<SurveyVersion__c> loadTemplates() {

        Boolean showPpi = false;
        if (formType.equals(C.FORM_TYPE_PPI)) {
            showPpi = true;
        }
        String libraryToView = library.Name;
        SurveyUtils utils = new SurveyUtils();
        return new SurveyVersionSelector().getAllTemplatesForLicense(library.Name, showPpi, true, '');
    }

    /**
     * Build the request
     *
     * @param surveyId - The id of the survey being fetched. Null if looking for whole list
     *
     * @return - The request
     */
    public HttpRequest buildRequest(Id surveyId) {

        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        String params = '';
        if (surveyId != null) {
            params += 'id=' + surveyId;
        }
        if (this.formType != null) {
            if (!params.equals('')) {
                params += '&';
            }
            params += C.FORM_TYPE + '=' + this.formType;
        }
        if (!params.equals('')) {
            params = '?' + params;
        }
        req.setEndpoint(this.library.URL__c + this.library.RemoteLibraryPath__c + params);
        return req;
    }

    /**
     * Downloads a survey form a remote location and saves it to the DB
     *
     * @return - Page that the user should be redirected to next
     */
    public PageReference downloadSurvey() {

        try {
            processSurveyDownload(getRemoteSurvey(Apexpages.currentPage().getParameters().get('remoteSurveyId')));

        }
        catch (Exception e) {
            System.debug(LoggingLevel.Error, 'Failed to download remote survey. ' + e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.SURVEY_LIBRARY_ERR_DOWNLOAD));
        }
        return null;
    }

    /**
     * Proces the http response recieved when downloading a survey
     *
     * @param res - The response to be processed
     */
    public void processSurveyDownload(HttpResponse res) {
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Survey__c.Name,
                Survey__c.Version__c
            }
        );
        checkResponse(res);
        this.success = '';
        if (res.getStatusCode() == C.HTTP_OK) {
            String surveyId = parseJsonSurveyResponse(res.getBody());
            if (surveyId != null) {
                processSuccess(surveyId);
            }
        }
    }

    /**
     * Process a successsful download
     */
    private void processSuccess(String surveyId) {
        this.newSurveyId = surveyId;

        // Get the survey name for the success message
        Survey__c survey = [SELECT Name, Version__c FROM Survey__c WHERE Id = :newSurveyId];
        if (formType.equals(C.FORM_TYPE_SUR)) {
            this.success = 'surveyDownloadComplete';
            this.successMessage =
                String.format(
                    System.Label.SURVEY_LIBRARY_MSG_SUCCESS, new List<String>{survey.Name}
                );
        }
        else {
            this.success = 'templateDownloadComplete';
            this.successMessage =
                String.format(
                    System.Label.SURVEY_LIBRARY_MSG_SUCCESS_TEMPLATE, new List<String>{survey.Name}
                );
        }
        if (this.versionMap != null) {
            this.versionMap.remove(survey.Name);
        }
    }

    /**
     * Get a survey from a remote server
     *
     * @param remoteSurveyId - The survey id as it is on the remote server.
     */
    private HttpResponse getRemoteSurvey(String remoteSurveyId) {
        Http http = new Http();
        return http.send(buildRequest(remoteSurveyId));
    }

    /**
     * Parse a returned survey and create the survey. TODO - refactor into the same method as the parser above
     *
     * @param jsonString - The json string produced by the remote server
     *
     * @return - The survey id of the newly built survey. null if the survey failed to build
     */
    @TestVisible
    private String parseJsonSurveyResponse(String jsonString) {

        SurveyData data;
        JSONParser parser = JSON.createParser(jsonString);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME
                    && parser.getText().equals('results')
            ) {
                parser.nextToken();
                parser.nextToken();
                data = (SurveyData)parser.readValueAs(SurveyData.class);
            }
        }
        if (data == null) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.SURVEY_LIBRARY_ERR_FAILEDREBUILD));
        }
        FormReplicationService.setRemoteLibrary(this.library);
        FormReplicationService.ReplicateBasicSurvey replicatedSurvey =
            FormReplicationService.cloneSurveyData(data);
        String surveyId = replicatedSurvey.getNewId();
        if (surveyId == null) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.SURVEY_LIBRARY_ERR_FAILEDREBUILD));
        }
        return surveyId;
    }

    /**
     * Preview a remote survey. The remote survey is loaded from a parent org onto an iFrame
     */
    public PageReference previewSurvey() {
        String surveyId = Apexpages.currentPage().getParameters().get('originSurveyId');
        SFDCEncoder encoder = new SFDCEncoder();
        String previewURL = this.library.URL__c + this.library.SurveyPreviewPath__c + '?id=' +
            encoder.SFDC_URLENCODE(surveyId) + '&b=0';
        this.originPreview = previewURL;
        return null;
    }

    /**
     * Load the survey builder with a survey that is cloned from the template selected
     */
    public PageReference useIt() {

        PageReference newPage;
        newPage = Page.SurveySetting;
        newPage.getParameters().put(C.START_FORM, C.CREATE_FROM_TEMPLATE);
        newPage.getParameters().put(C.BASE_TEMPLATES, this.newSurveyId);
        newPage.setRedirect(true);
        return newPage;
    }
}