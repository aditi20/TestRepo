/**
 * Controller class used to handle multiple functionality related to any type of Surveys
 *  - Create new Survey
 *  - Multiple Actions around existing surveys
 *      - Clone a Survey
 *      - Delete a Survey
 *      - Preview a survey
 *  - Publish a Survey
 *  - Close a Survey
 *
 * TODO:
 *    - Refactor code based on SOC architechture
 *    - Use appropriate selector and domain layers and update all queries and DML operations
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class SurveyManagerController{

    public String getXFORM_STATUS_CUSTOM(){ return C.XFORM_STATUS_CUSTOM; }

    public final String OK = 'OK';
    public final Integer MAX_ROWS_PER_PAGE = 20; //Maybe, this number could be configured in a config or property file.
    public static final String CLONE_SURVEY_NAME = system.label.CLONE_SURVEY_NAME; // used to append to a survey name in case of a Duplicate survey generation
    public Id surveyToPublish {get;set;}
    public String SurveyToPublishName{get;set;}
    public List<ContactGroupSurveyAssignment__c> contactGroupsOfSurvey {get;set;}
    public Boolean isPPIEnabled {get;set;}
    public Boolean canDistribute {get;set;}
    public List<SurveyVersion__c> surveyList{
        get {
            return (List<SurveyVersion__c>) paginationController.getRecords();
        }
        set;
    }

    public String status_draft      { get { return SurveyDO.STATUS_DRAFT; } set; }
    public String status_published  { get {  return SurveyDO.STATUS_PUBLISHED;} set; }
    
    public Set<Id> idOfSurveyMappingsToRemove;
    public Set<Id> surveysToClose;
    public Set<Id> childrenToUpdateId;
    public List<ObjectRelationshipMapping__c> clonableRelations;
    public List<SurveyMapping__c> clonableMappings;
    public List<ObjectRelationshipMapping__c> relationsToRemove;

    public String doAction {get;set;}
    public String surveyIdAction {get;set;}
    public String surveyIdToEdit {get;set;}
    public String xformStatus {get;set;}
    public Boolean confirmAccepted {get;set;}
    public Boolean displayGroupPopup {get; set;}
    public Boolean cloneAllAssignments;

    // Labels for status values
    public String getStatusValues(){
        return JSON.serialize(SurveyDO.getStatusTranslations());
    }

    //The last order
    public String stringOrder{get;set;}

    public List<SelectOption> statusList{
        get{
            statusList = new List<SelectOption>();
            statusList.add(new SelectOption('publishedDraft',system.label.SURVEY_STATUS_DRAFT + ' + ' +  system.label.SURVEY_STATUS_PUBLISHED));
            statusList.add(new SelectOption('All',system.label.ALL));
            Schema.DescribeFieldResult fieldResult = Survey__c.Status__c.getDescribe();
            List<Schema.PicklistEntry> statusListOptions = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry f : statusListOptions){
                statusList.add(new SelectOption( f.getValue(),f.getLabel()));
            }
            return statusList;
        }
        set;
    }

    public String previousSortField{get;
        set{
            if (value == null || value.trim().equals('') || String.escapeSingleQuotes(value).contains('\\')){
                previousSortField = null;
            }
            else{
                previousSortField = value;
            }
        }
    }

    public String columnOrder {get;
        set {
            if (value == null || value.trim().equals('') || String.escapeSingleQuotes(value).contains('\\') ){
                columnOrder = 'Survey__r.CreatedDate';
            }
            else{
                 columnOrder = value.trim() ;
            }
        }
    }

    public String filter {get;
        set {
            if (value == null || value.trim().equals('') ||
                    String.escapeSingleQuotes(value).contains('\\') || value.trim().equals('publishedDraft')
            ){
                filter = 'publishedDraft';
            }else if (value == null || value.trim().equals('') ||
                    String.escapeSingleQuotes(value).contains('\\') || value.trim().equals('all')
            ){
                filter = 'all';
            }
            else{
                filter = value;
            }
        }
    }

    private static String SurveyVTName;
    private static String SurveyTName;
    private static String ContactGTName;
    private static String AtachmentTName;
    private static Map<String, DescribeSObjectResult> objectPermissions;

    static {
        SurveyVTName=Schema.sObjectType.SurveyVersion__c.getName();
        SurveyTName=Schema.sObjectType.Survey__c.getName();
        ContactGTName=Schema.sObjectType.ContactGroupSurveyAssignment__c.getName();
        AtachmentTName=Schema.sObjectType.Attachment.getName();
        objectPermissions=PrivilegesHelper.obtainObjectPermissions(
            new Set<String>{SurveyVTName,SurveyTName,ContactGTName,AtachmentTName});
    }
    
    public SurveyManagerController(){
    
    }
    public SurveyManagerController(ApexPages.StandardController controller){

        this.cloneAllAssignments = false;
        this.filter = 'publishedDraft';
        this.columnOrder = 'Survey__r.CreatedDate';
        stringOrder = 'desc';
        refreshPaginationController(columnOrder, stringOrder );
        this.surveyList = (List<SurveyVersion__c>) paginationController.getRecords();
        this.contactGroupsOfSurvey = new List<ContactGroupSurveyAssignment__c>();
    }

    //------------------------------------------------------------
    // Controller initialization script
    public void init() {

        // Load license settings
        LicenseSettings__c license = C.getLicense();
        isPPIEnabled = license.PPI_Editable__c;
        canDistribute = license.Can_Distribute__c;
    }

    public PageReference doFilterStatus(){
        refreshPaginationController(columnOrder, stringOrder);
        return null;
    }

    public PageReference doSort(){
        // If sorting by the same column, reverse the order. Else, sort ascending.
        if(previousSortField == columnOrder)
            stringOrder = ( stringOrder == 'asc' ) ? 'desc' : 'asc';
        else
            stringOrder = 'asc';

        previousSortField = columnOrder;
        integer Actualpagenumber = paginationController.getPageNumber();
        refreshPaginationController(columnOrder, stringOrder);
        paginationController.setPageNumber(Actualpagenumber);
        return null;
    }

    /**
    * Check if exist at leat a section without questions in a survey.
    * <p>
    * Get all section of survey and verify if there is not any question related to it.
    * (Related IDALMSA-2032)
    *
    * @param surveyId Id            Identifier of survey
    * @return assertion Boolean     Confirmation
    */
    private Boolean hasAnyEmptySection(Id surveyId) {

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Type__c,
                Question__c.Parent__c
            }
        );

        Question__c[] questions = [
            SELECT
                Id,
                Type__c,
                Parent__r.Id
            FROM
                Question__c
            WHERE
                Survey__c =: surveyId
        ];

        Set <Id> sectionIds = new Set <Id>();
        Set <Id> questionParentIds = new Set <Id>();

        for (Question__c q : questions){

            if (QuestionDO.isSection(q.Type__c)){
                sectionIds.add(q.Id);
            } else {
                questionParentIds.add(q.Parent__r.Id);
            }
        }

        for (Id sId: sectionIds) {
            if (!questionParentIds.contains(sId)){
                return true;
            }
        }

        return false;
    }

    public PageReference doPublish(){

        GenericObjectCreator contactGroupSurveyAssignmentCreator =
            new GenericObjectCreator(
                DescribeHandler.getGlobalDescribe().get(ContactGTName)
            );
        contactGroupSurveyAssignmentCreator.checkObjectCreateable();
        contactGroupSurveyAssignmentCreator.checkObjectDeletable();

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(
                DescribeHandler.getGlobalDescribe().get(SurveyVTName)
            );
        surveyVersionCreator.checkObjectUpdateable();

        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(
                DescribeHandler.getGlobalDescribe().get(AtachmentTName)
            );
        attachmentCreator.checkObjectCreateable();

        // Set a save point as publish must be called in a transaction
        Savepoint sp = Database.setSavepoint();
        try{
            if (this.surveyToPublish == null){
                SurveyException.raise(system.label.SURVEY_ERR_NULLREFERENCE);
            } else {
                //Check if the survey Id is valid(survey was not deleted)
                if (!surveyExists(surveyToPublish)){
                    closeGroupPopup();
                    return null;
                }
                GenericObjectCreator surveyCreator =
                    new GenericObjectCreator(Survey__c.SObjectType);
                surveyCreator.checkObjectAccessible();
                surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                    Survey__c.Status__c
                });
                Survey__c[] surveys = [
                    SELECT
                        Id,
                        Status__c
                    FROM
                        Survey__c
                    WHERE
                        Id = :this.surveyToPublish
                ];

                if(surveys[0].Status__c != SurveyDO.STATUS_DRAFT){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                String.format(system.label.SURVEY_ERR_CANTPUBLISHWITHSTATUS,new String []{surveys[0].Status__c})));
                    refreshPaginationController(columnOrder, stringOrder );
                } else if (hasAnyEmptySection(this.surveyToPublish)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ERR_SURVEY_PUBLISH_EMPTY_SECTION));
                } else {
                    List<String> idsToPublish = new List<String>();
                    GenericObjectCreator contactGroupCreator =
                        new GenericObjectCreator(ContactGroup__c.SObjectType);
                    contactGroupCreator.checkObjectAccessible();
                    contactGroupCreator.checkFieldsAccessible(
                        new List<Schema.SObjectField> {
                            ContactGroup__c.Name
                        }
                    );
                    if (!this.contactGroupsOfSurvey.isEmpty()) {
                        for (ContactGroupSurveyAssignment__c assignment: contactGroupsOfSurvey) {
                            idsToPublish.add(assignment.ContactGroup__c);
                        }
                        List<ContactGroup__c> inactiveGroups = [
                            SELECT
                                Name
                            FROM
                                ContactGroup__c
                            WHERE
                                Status__c = :C.GROUP_STATUS_INACTIVE
                                AND Id IN :idsToPublish
                        ];

                        if(!inactiveGroups.isEmpty()){
                            List<String> inactiveGroupsName = new List<String>();
                            for(ContactGroup__c cg : inactiveGroups){
                                inactiveGroupsName.add(cg.Name);
                            }
                            ApexPages.Message msg = new ApexPages.Message(ApexPages.severity.ERROR,system.label.BUILDER_ERR_INACTIVEGROUP + '  ' + inactiveGroupsName);
                            ApexPages.addMessage(msg);
                            closeGroupPopup();
                            refreshPaginationController(columnOrder, stringOrder );
                            return null;
                        }
                    }
                    if (!RemovedDataValidation.mappingsWithMissingObjectOrField(this.surveyToPublish).isEmpty()){
                        ApexPages.Message msg = new ApexPages.Message(ApexPages.severity.ERROR, system.Label.ERR_SURVEY_PUBLISH_WRONGMAP);
                        ApexPages.addMessage(msg);
                        closeGroupPopup();
                    } else {
                        // Actually publish the survey
                        SurveyDO.publishSurvey(surveys[0]);
                    }
                }
            }
            closeGroupPopup();
            refreshPaginationController(columnOrder, stringOrder );
        } catch (Exception ex) {
            closeGroupPopup();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            System.debug(LoggingLevel.INFO, ex.getMessage());
            Database.rollback(sp);
        }
        return null;
    }

    // ERROR MESSAGES
    public string error{get;set;}

    public PageReference doMoreAction() {
        PageReference returnExit = null;
        SFDCEncoder encoder = new SFDCEncoder();

        //Check if the survey Id is valid(survey was not deleted)
        if (this.surveyIdAction == null) {
            SurveyException.raise(System.label.SURVEY_ERR_NULLREFERENCE);
        } else if (!surveyExists(surveyIdAction)) {
            return null;
        }

        if (doAction == 'Close') {
            doCloseSurvey(surveyIdAction);
        } else if (doAction == 'Clone') {

            FormReplicationService.ReplicateBasicSurvey replicatedSurvey;
            try {
                Survey__c surveyToClone =
                    (Survey__c) new Surveyselector().getRecordByIdWithAllFields(
                        (Id) this.surveyIdAction
                    );

                // Throw an error if 3.0 or less version Ppi Use it surveys are cloned as all old 
                // Ppi Templates have been deprecated on child org
                if (!SurveyDO.isNewPpiSurvey(surveyToClone) && surveyToClone.isPpi__c
                        && !surveyToClone.isTemplate__c
                ) {
                    ApexPages.addMessage(
                        new ApexPages.Message(
                            ApexPages.Severity.ERROR,
                            System.Label.ERR_CANNOT_CLONE_SURVEY_WITH_DEPRECATED_PPI_TEMPLATE
                        )
                    );
                } else {
                    replicatedSurvey = FormReplicationService.cloneLocalForm(
                        surveyToClone,
                        null,
                        false,
                        true
                    );
                    if (replicatedSurvey.closeBrokenForms()) {
                        ErrorHandlingRest.addApexPageErrorsToPage();
                    }
                }
            } catch (Exception ex) {
                replicatedSurvey.rollback();
                error = ex.getMessage();
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        System.label.SURVEY_ERR_NOSURVEYSELECTED
                    )
                );
            }
        } else if (doAction == 'Delete') {
            doTrashSurvey(surveyIdAction);
        } else if (doAction == 'Distribute') {
            doDistribute(surveyIdAction);
        } else if (doAction == 'Preview') {
            return goToPreview(surveyIdAction);
        } else if (doAction == 'Export') {
            doExportCsv(surveyIdAction);
        }
        refreshPaginationController(columnOrder, stringOrder);
        return returnExit;
    }
   
    // When select to edit survey, if the survey has missing mappings then go to the survey field mapping page.
    public PageReference editSurvey(){
        PageReference pageToGo;
        // Check missing mappings and relations and close failed surveys.
        Set<Id>surveysToClose = RemovedDataValidation.mappingsWithMissingObjectOrField(surveyIdToEdit);
        if(xformStatus != C.XFORM_STATUS_CUSTOM){
            if(!surveysToClose.isEmpty()){
                pageToGo = Page.SurveyFieldMapping;
            }else{
                pageToGo = Page.SurveySetting;
            }
        }else if(confirmAccepted){
            if(!surveysToClose.isEmpty()){
                pageToGo = Page.SurveyFieldMapping;
            }else{
                pageToGo = Page.SurveySetting;
            }
        }else{
            return null;
        }

        pageToGo.getParameters().put('id', surveyIdToEdit);

        return pageToGo.setRedirect(true);
    }

    /**
     * When go to preview page, check if the survey has some missing mapped objects, fields or relations. 
     * In affirmative case, close survey and give information to user.
     *
     * @param Survey Id
     * @return Page regerence survey preview
     */
    public PageReference goToPreview(String surveyId){
        PageReference pageToGo = Page.SurveyPreview;
        
        // Redirect to survey preview
        pageToGo.getParameters().put('b', '0');
        pageToGo.getParameters().put('id', surveyId);

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                SurveyVersion__c.Status__c
            }
        );

        List<SurveyVersion__c> versions = [
            SELECT 
                Status__c 
            FROM 
                SurveyVersion__c 
            WHERE 
                Survey__c = :surveyId 
                ORDER BY Version__c DESC LIMIT 1
        ];

        // Check missing mappings and relations and close failed surveys.
        if(!versions.isEmpty()){ 
            if(versions[0].Status__c == SurveyDO.STATUS_PUBLISHED && 
                !RemovedDataValidation.mappingsWithMissingObjectOrField(surveyId).isEmpty()){
                SurveyUtils.closeFailedSurveysAndUserInfo(surveyId, true);
                ErrorHandlingRest.addApexPageErrorsToPage();
            }
        }
        
        return pageToGo.setRedirect(true);
    }
    
    /**
     * Distributes the survey
     *
     * @param  surveyId the id of the survey to distribute
     */
    private void doDistribute(String surveyId){
        SurveyUtils utils = new SurveyUtils();
        utils.distributeSurvey(surveyId);
    }

    /**
     * Closes the survey
     *
     * @param  surveyId the id of the survey to close
     */
    private void doCloseSurvey(String surveyId) {
        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkObjectUpdateable();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                SurveyVersion__c.Status__c
            }
        );

        SurveyVersion__c ver = [
            SELECT
                Status__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c=:surveyId
                ORDER BY Version__c DESC
                LIMIT 1
        ];

        surveyVersionCreator.populateField(
            ver,
            SurveyVersion__c.Status__c,
            SurveyDO.STATUS_CLOSED
        );

        try {
            update ver;
        }
        catch(DMLException e) {
            // Error message defined on UpdateSurveyOnLastVersion trigger
            system.debug(e);
        }
    }

    /**
     * Deletes the survey
     *
     * @param  surveyId the id of the survey to delete
     */
    private void doTrashSurvey(String surveyId) {
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkObjectDeletable();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.IsPPI__c
        });
        Survey__c surveyToDelete = [
            SELECT
                Id,
                IsPPI__c
            FROM
                Survey__c
            WHERE
                Id = :surveyId
        ];
        try {
            delete surveyToDelete;
        }
        catch(DMLException e) {
            // Error message defined on setPPISurveyName trigger
            system.debug(e);
        }
    }

    /**
     * Exports the results of the survey to CSV
     * It runs a batch process in background that send the CSV by email
     *
     * @param  surveyId the id of the survey to export the results
     */
    private void doExportCsv(String surveyId) {
        Integer batchSize = ExportCsvBatch.getCsvBatchSize(surveyIdAction);
        if(batchSize > 0) {
            Id batchInstanceId = Database.executeBatch(
                new ExportCsvBatch(
                    surveyId,
                    null,
                    UserInfo.getTimeZone().getId()
                ),
                batchSize
            );
        }
        else {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.ERROR,
                    System.Label.SURVEY_CSV_BATCHSIZEERROR
                )
            );
        }
    }

    /**
     * Refresh the paginator controller
     *
     * @param  colOrder the column to order the records
     * @param  order    indicates if the order is ascendent or descendent
     */
    private void refreshPaginationController(String colOrder, String order) {

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<String> {
                'DistributionDate__c',
                'Distributed__c',
                'Survey__c'
            }
        );
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<String> {
            'XForm_Status__c',
            'StatusImage__c',
            'Status__c',
            'isPPI__c',
            'PublishedDate__c',
            'Name',
            'Alias__c',
            'ResponseCount__c',
            'QuestionCount__c',
            'IsTemplate__c'
        });

        String queryString =
            'SELECT Id, Distributed__c, DistributionDate__c, Survey__r.XForm_Status__c, ' +
                   'Survey__r.StatusImage__c, Survey__r.Status__c, Survey__r.isPPI__c, ' +
                   'Survey__r.PublishedDate__c, Survey__r.id, Survey__r.Name, Survey__r.Alias__c, ' +
                   'Survey__r.CreatedDate, Survey__r.CreatedById, Survey__r.CreatedBy.Name, ' +
                   'Survey__r.OwnerId, Survey__r.Owner.Name, Survey__r.LastModifiedDate, ' +
                   'Survey__r.ResponseCount__c, Survey__r.QuestionCount__c ' +
            'FROM SurveyVersion__c ' +
            'WHERE ' +
                'Survey__r.IsTemplate__c = false ';
        if ((filter != null) && filter.equalsIgnoreCase('publishedDraft')) {
             queryString = queryString + ' AND    (Survey__r.Status__c = \'' + SurveyDO.STATUS_DRAFT +'\' OR Survey__r.Status__c = \'' + SurveyDO.STATUS_PUBLISHED +'\')';
        } else if ((filter != null) && !filter.equalsIgnoreCase('all')){
            queryString = queryString + ' AND    Survey__r.Status__c = \'' + String.escapeSingleQuotes(filter) +'\'';
        }

        queryString = queryString + ' ORDER BY ' + colOrder + ' ' + order;

        Integer oldPageNumber = 0;
        if (this.paginationController != null) oldPageNumber = this.paginationController.getPageNumber();
        this.paginationController = new ApexPages.StandardSetController(Database.query(queryString));
        this.paginationController.setPageSize(MAX_ROWS_PER_PAGE);
        this.paginationController.setPageNumber(oldPageNumber);
    }

    //Pagination Stuff
    public ApexPages.StandardSetController paginationController{get;set;}

    //Boolean to check if there are more records after the present displaying records
    public Boolean hasNext{
        get{ return paginationController.getHasNext();}
        set;
    }

    //Boolean to check if there are more records before the present displaying records
    public Boolean hasPrevious{
        get{ return paginationController.getHasPrevious();}
        set;
    }

    //Page number of the current displaying records
    public Integer pageNumber{
        get{ return paginationController.getPageNumber();}
        set;
    }

    //Page size of the current displaying records
    public Integer pageSize{
        get{ return paginationController.getPageSize();}
        set;
    }

    // Returns the number of records in the set.
    public Integer resultSize{
        get{ return paginationController.getResultSize();}
        set;
    }

    //Returns the previous page of records
    public void previous(){
        paginationController.previous();
    }

    //Returns the next page of records
    public void next(){
        paginationController.next();
    }

    public void closeGroupPopup() {
        displayGroupPopup = false;
    }

    public void showGroupPopup() {
        displayGroupPopup = true;
    }

    public PageReference newSurvey(){
        return Page.createSurvey;
    }

    /**
     * Returns true if a survey Id exists, false otherwise
     *
     * @param  surveyId
     * @return      a boolean indicating if the survey exists
     */
    public boolean surveyExists(Id surveyId) {
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();

        List<Survey__c> surveys=[
            SELECT
                Id
            FROM
                Survey__c
            WHERE
                Id = :surveyId
        ];

        if (surveys.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                            system.label.SURVEY_ERR_ID_NOT_FOUND));
                refreshPaginationController(columnOrder, stringOrder );
        }
        return (!surveys.isEmpty());
    }
}
