/*
 *(c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class C {

    // Set of object that are not able to be used.
    public static Set<String> forbiddenObjects = new Set<String>{
        Answer__c.sObjectType.getDescribe().getName().toLowerCase(),
        ContactGroup__c.sObjectType.getDescribe().getName().toLowerCase(),
        ContactGroupMember__c.sObjectType.getDescribe().getName().toLowerCase(),
        ContactGroupSurveyAssignment__c.sObjectType.getDescribe().getName().toLowerCase(),
        Device__c.sObjectType.getDescribe().getName().toLowerCase(),
        ISO_Country__c.sObjectType.getDescribe().getName().toLowerCase(),
        JobTemplate__c.sObjectType.getDescribe().getName().toLowerCase(),
        Language__c.sObjectType.getDescribe().getName().toLowerCase(),
        LicenseSettings__c.sObjectType.getDescribe().getName().toLowerCase(),
        ObjectRelationshipMapping__c.sObjectType.getDescribe().getName().toLowerCase(),
        Option__c.sObjectType.getDescribe().getName().toLowerCase(),
        PPITable__c.sObjectType.getDescribe().getName().toLowerCase(),
        PPITableDataSet__c.sObjectType.getDescribe().getName().toLowerCase(),
        PPITableLine__c.sObjectType.getDescribe().getName().toLowerCase(),
        Question__c.sObjectType.getDescribe().getName().toLowerCase(),
        QuestionMapping__c.sObjectType.getDescribe().getName().toLowerCase(),
        ScoreValue__c.sObjectType.getDescribe().getName().toLowerCase(),
        ScoringGroup__c.sObjectType.getDescribe().getName().toLowerCase(),
        Settings__c.sObjectType.getDescribe().getName().toLowerCase(),
        SkipCondition__c.sObjectType.getDescribe().getName().toLowerCase(),
        Submission__c.sObjectType.getDescribe().getName().toLowerCase(),
        SubmissionPPIValue__c.sObjectType.getDescribe().getName().toLowerCase(),
        SubmissionScore__c.sObjectType.getDescribe().getName().toLowerCase(),
        Survey__c.sObjectType.getDescribe().getName().toLowerCase(),
        SurveyLibrary__c.sObjectType.getDescribe().getName().toLowerCase(),
        SurveyMapping__c.sObjectType.getDescribe().getName().toLowerCase(),
        SurveyVersion__c.sObjectType.getDescribe().getName().toLowerCase(),
        TaskTemplate__c.sObjectType.getDescribe().getName().toLowerCase() };

    // Set of object that should be displayed inspite of having namespace
    public static Set<String> whiteListedObjects = new Set<String> {
        PpiResult__c.sObjectType.getDescribe().getName().toLowerCase()
    };

    public static Set<String> objectsWithoutLastModifiedDateField = new Set<String>{
        'accountfeed',
        'accounthistory',
        'assetfeed',
        'aggregateresult',
        'campaignfeed',
        'casefeed',
        'casehistory',
        'casesolution',
        'caseteamtemplaterecord',
        'collaborationgroupfeed',
        'contactfeed',
        'contacthistory',
        'contentdocumentfeed',
        'contentdocumenthistory',
        'contentversionhistory',
        'contractfeed',
        'contracthistory',
        'dashboardfeed',
        'documentattachmentmap',
        'entitysubscription',
        'eventfeed',
        'feedcomment',
        'feedtrackedchange',
        'fiscalyearsettings',
        'groupmember',
        'ideacomment',
        'leadfeed',
        'leadhistory',
        'name',
        'newsfeed',
        'opportunityfeed',
        'opportunityfieldhistory',
        'opportunityhistory',
        'period',
        'processinstancehistory',
        'processinstancestep',
        'processinstanceworkitem',
        'queuesobject',
        'reportfeed',
        'sitefeed',
        'sitehistory',
        'solutionfeed',
        'solutionhistory',
        'taskfeed',
        'userfeed',
        'userlicense',
        'userpreference',
        'userprofilefeed',
        'vote'


        /*
        *  These objects are org unaccesible, but may be used in the future
        *
        *ContactTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *ContentWorkspaceDoc.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *ContractLineItemHistory.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *CronTrigger.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *DashboardTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *DocumentTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *EntitlementFeed.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *EntitlementHistory.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *EventTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *FeedPost.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *LeadTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *CaseTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *KnowledgeArticleViewStat.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *KnowledgeArticleVoteStat.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *CampaignTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *CaseArticle.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *NoteTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *OpportunityTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *Product2Feed.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *ProductEntitlementTemplate.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *QuestionDataCategorySelection.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *ReportTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *ServiceContractHistory.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *SolutionTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *TagDefinition.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *AccountTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *AccountTerritoryAssignmentRule.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *AssetTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *AsyncApexJob.sObjectType.getDescribe().getLocalName().toLowerCase(),
        *TaskTag.sObjectType.getDescribe().getLocalName().toLowerCase(),
        */

    };

    // Map with the supported video MIME types by extension
    public static final Map<String, String> supportedVideoTypes = new Map<String, String> {
        '3gp'   => 'video/3gpp',
        'mp4'   => 'video/mp4'
    };

    public static final String FILE_TYPE_UNKNOWN = 'UNKNOWN';

    public static final Id PARENT_ORG_ID = '00DE0000000cJyP';

    /**
     * Get the MIME type of the content resource
     *
     * @param  content the content to download
     * @return         the content type
     */
    public static String getContentMimeType(ContentVersion content) {
        String type = '';
        if(content.FileType != null && content.FileType != C.FILE_TYPE_UNKNOWN) {
            type = content.FileType;
        }
        else {
            String filePath = content.PathOnClient;
            if(filePath.contains('.') && (filePath.length() > filePath.lastIndexOf('.') + 1) ) {
                type = filePath.substring(filePath.lastIndexOf('.') + 1, filePath.length());
            }
        }
        return C.supportedVideoTypes.get(type.toLowerCase());
    }

    /**
     * Check if the type is supported
     *
     * @param  content the content to download
     * @return         true if the type of the given resource is supported
     */
    public static Boolean isContentTypeSupported(ContentVersion content) {
        return getContentMimeType(content) != null;
    }

    // Exception for survey builder
    public class SurveyBuilderException extends Exception {}

    // Exception class for PPI license
    public class LicenseException extends Exception {}
    public class InvalidUrlException extends Exception {}

    // Exception to throw when an autonumber field is not an id field.
    public class AutonumberNotIdFieldException extends Exception {}

    // Create instance of license if it doesn't exist
    public static LicenseSettings__c getLicense() {
        String licenseName = Test.isRunningTest() ? 'Test' : 'Default';
        LicenseSettings__c license = LicenseSettings__c.getInstance(licenseName);
        if (license == null) {
            license = new LicenseSettings__c(Name = licenseName);
            insert license;
        }
        return license;
    }

    // Retrieve the current user language, giving the locale, ex: if it is "en_US" this methods returns "en"
    public static String getUserLanguage() {
        GenericObjectCreator userCreator =
            new GenericObjectCreator(User.SObjectType);
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            User.LanguageLocaleKey
        });

        User currentUser = [
            SELECT
                LanguageLocaleKey
            FROM
                User
            WHERE
                Id = :UserInfo.getUserId() LIMIT 1
        ];
        return currentUser.LanguageLocaleKey.split('_')[0];
    }

    //----------------
    // Device Status
    //----------------
    public static final String DEVICE_STATUS_ACTIVE   = 'Active';
    public static final String DEVICE_STATUS_INACTIVE = 'Inactive';

    //----------------
    // SURVEYOR STATUS
    //----------------
    public static final String SURVEYOR_STATUS_ACTIVE   = 'Active';
    public static final String SURVEYOR_STATUS_INACTIVE = 'Inactive';

    //----------------
    // GROUPS STATUS
    //----------------
    public static final String GROUP_STATUS_ACTIVE   = 'Active';
    public static final String GROUP_STATUS_INACTIVE = 'Inactive';

    //------------------
    // REQUEST HEADERS
    //------------------
    public static final String USERNAME_HEADER                   = 'user';
    public static final String PASSWORD_HEADER                   = 'pass';
    public static final String DEVICE_ID_HEADER                  = 'deviceId';
    public static final String IMEI_HEADER                       = 'imei';
    public static final String LAST_HEADER                       = 'last';
    public static final String SESSION_TOKEN_HEADER              = 'sessionId';
    public static final String APPLICATION_VERSION_NUMBER_HEADER = 'version';
    public static final String STAGE_HEADER                      = 'stage';
    public static final String FILENAME_HEADER                   = 'filename';
    public static final String SUBMISSION_ID_HEADER              = 'submissionId';
    public static final String SURVEY_ANSWER_HEADER              = 'surveyAnswer';
    public static final String CONTENT_TYPE_HEADER               = 'Content-type';
    public static final String SURVEY_ID_HEADER                  = 'surveyId';
    public static final String RESOURCE_ID_HEADER                = 'resourceId';
    public static final String AUTHENTICATE_HEADER               = 'WWW-Authenticate';
    public static final String POST_REQUEST_METHOD               = 'POST';

    // Constants for HTTP Status codes
    public static final Integer HTTP_OK                    = 200;
    public static final Integer HTTP_NO_CONTENT            = 204;
    public static final Integer HTTP_BAD_REQUEST           = 400;
    public static final Integer HTTP_UNAUTHORIZED          = 401;
    public static final Integer HTTP_NOT_FOUND             = 404;
    public static final Integer HTTP_INTERNAL_SERVER_ERROR = 500;
    public static final Integer HTTP_SERVICE_UNAVAILABLE   = 503;

    //-------------------
    // This variable will redirect to the correct salesforce instance (i.e. na9).
    public static final String SALESFORCE_INSTANCE  = 'https://na1.salesforce.com/';
    public static final String DOWNLOAD_ATT_URL  = 'servlet/servlet.FileDownload?file=';
    //-------------------

    public static String namespace;
    public static Boolean isNamespaceAssigned = false;

    /**
     * Method to get namespace for this class
     */
    public static String getNamespace() {
        if (!isNamespaceAssigned) {
            namespace = getClassNameSpace('C');
            isNamespaceAssigned = true;
        }
        return namespace;
    }

    // Wait the indicated number of questions.
    // WARNING: this performs busy waiting, which executes lots of statements per second. Beware governor limits.
    public static void wait(Integer seconds) {
        Long l = 0;
        DateTime finishTime = DateTime.now().addSeconds(seconds);
        while (finishTime > DateTime.now()) {
            l = (l - l) + Crypto.getRandomLong(); // weightly calculation. Takes time, but counts as one statement.
        }
    }

    /**
     * Create a mapping of picklist values variable from a Picklist Field of a certain object
     *
     * @param objectName Object Name
     * @param fieldName Picklist Field of the object
     * @return mapping of picklist values
     */
    public static Map<String,String> getPickListMap(Schema.DescribeFieldResult fieldDescribe) {
        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        Map<String,String> result = new Map<String,String>();
        for (Schema.PicklistEntry f : picklistValues) {
            result.put(f.getValue(), f.getLabel());
        }
        return result;
    }

    /**
     * Create a string with a js array variable from a Picklist Field of a certain object
     *
     * @param fieldDescribe - The fieldDescribe to extract objects from
     *
     * @return - js array variable
     */
    public static String getPickListValues(Schema.DescribeFieldResult fieldDescribe) {
        List<Schema.PicklistEntry> pickListValues = fieldDescribe.getPicklistValues();
        String returnString = '';
        for( Schema.PicklistEntry f : picklistValues){
            returnString += String.Format('"{0}":"{1}",', new String[]{ f.getValue(), f.getLabel() });
        }

        // Remove the last comma and return the string
        return returnString.substring(0, returnString.length() - 1);
    }

    /**
     * Create a string with a js array variable from a Picklist Field of a certain object
     *
     * @param objectName - Object Name
     * @param fieldName  - Picklist Field of the object
     *
     * @return - js array variable
     */
    public static String getPickListValues(String objectName,String fieldName) {

        List<Schema.PicklistEntry> pickListValues =
            DescribeHandler.getFieldDescribe(objectName, fieldName).getPicklistValues();
        String returnString = '';
        for (Schema.PicklistEntry f : picklistValues) {
            returnString += String.Format('"{0}":"{1}",', new String[]{ f.getValue(), f.getLabel() });
        }

        // Remove the last comma and return the string
        return returnString.substring(0, returnString.length() - 1);
    }

    /**
    * Check if the object has the prefix of the manage package
    *
    * @param Object that we want to know if has prefix
    * @return True if object has the prefix of the manage package
    */
    public static Boolean hasNameSpacePrefix(Schema.SObjectType obj){
        // Getting name space prefix from a custom object
        String namespacePrefix = Survey__c.getSObjectType().getDescribe().getName().split('_')[0];
        String[] objPrefixParts = obj.getDescribe().getName().split('_');

        // Check if are the same prefixes
        return (objPrefixParts.size() > 1 && objPrefixParts[0] == namespacePrefix);
    }

    /**
    * Check if the object has the prefix of the manage package
    *
    * @param Object that we want to know if has prefix
    * @return True if object has the prefix of the manage package
    */
    public static Boolean hasNameSpacePrefix(String sObjectName){
        // Getting name space prefix from a custom object
        String namespacePrefix = Survey__c.getSObjectType().getDescribe().getName().split('_')[0];
        String[] objPrefixParts = sObjectName.split('_');

        // Check if are the same prefixes
        return (objPrefixParts.size() > 1 && objPrefixParts[0] == namespacePrefix);
    }

    /**
     * Determine the namespace for a class
     */
    public static String getClassNameSpace(String className) {
        List<String> classNameParts = className.split('\\.');
        return [
            SELECT
                NameSpacePrefix
            FROM
                ApexClass
            WHERE
                Name = :classNameParts[classNameParts.size() - 1]
        ].NameSpacePrefix;
    }

    /**
     *  Check if the given object is in the list of forbidden objects
     *  @param Object that we want to know if its usable for mapping.
     *  @return True if the object is in the blacklist.
     */
    public static Boolean isInBlacklist(Schema.DescribeSObjectResult obj) {

        String objectName = obj.getName();
        return forbiddenObjects.contains(objectName.toLowerCase());
    }

    /**
     *  Check if the given object is in the list of objects without LastModifiedDate
     *  @param Object that we want to know if its usable for mapping.
     *  @return True if the object is in the ObjectsWithoutLastModifiedDateField list.
     */
    public static Boolean hasNotLastModifiedDate(Schema.DescribeSObjectResult obj){
        String objectName = obj.getLocalName();
        return ObjectsWithoutLastModifiedDateField.contains(objectName.toLowerCase());
    }
    // Constants for xform creator
    public static final String XFORM_INTERVIEWEE_LABEL          = System.Label.XFORM_ODK_INTERVIEWEELABEL;
    public static final String XFORM_INTERVIEWEE_HINT_ANONYMOUS = System.Label.XFORM_ODK_INTERVIEWEE_HINT_ANONYMOUS;
    public static final String XFORM_INTERVIEWEE_HINT_DEFAULT   = System.Label.XFORM_ODK_INTERVIEWEE_HINT_DEFAULT;

    // Possible Status for the Survey field XForm_Status__c
    public static final String XFORM_STATUS_CUSTOM  = 'CUSTOM';
    public static final String XFORM_STATUS_DEFAULT = 'DEFAULT';

    // Names of files and attachments used in the system
    public static final String SURVEY_FILE_JSON  = 'survey.json';

    // Flags to disable some code executions
    public static final String FLAG_SKIP_QUESTION_POSITION_VALIDATION = 'FLAG_SKIP_QUESTION_POSITION_VALIDATION';
    public static final String FLAG_SKIP_SURVEY_STATUS_VALIDATION     = 'FLAG_SKIP_SURVEY_STATUS_VALIDATION';

    // Flags for licenses
    // USE FOR AUTOMATION AND MANUAL TESTING ONLY, THIS CODE SHOULD BE REMOVED FOR RELEASES
    public final static String VALID_KEY = 'db83e76c-a1d1-422a-a560-0a37c6718d7f';
    public final static String PPI_EDITABLE_FLAG = 'PPI_CREATION';
    public final static String CAN_DISTRIBUTE_FLAG = 'CAN_DISTRIBUTE_FLAG';
    public final static String GRAMEEN_LICENSE = 'GRAMEEN_LICENSE';
    public final static String JOB_DELETE = 'JOB_DELETE_LICENSE';

    // Namespaces for XForms
    public static final String NS_JAVAROSA = 'http://openrosa.org/javarosa';
    public static final String NS_XHTML    = 'http://www.w3.org/1999/xhtml';

    // Constant to set the max size (in chars) of the ppi lookup table
    // The standard csv for lookup tables is 3k. So, we use 30k to be sure.
    public static final Integer LOOKUP_MAX_FILE_SIZE = 30000;

    // Survey Settings
    public static final String PPI_SURVEY              = 'ppiSurvey';           // PPI survey option
    public static final String CLONE_SURVEY            = 'existingSurvey';      // Clone Survey option
    public static final String BASE_SURVEY             = 'baseSurvey';          // Survey to clone
    public static final String START_FORM              = 'group1';              // Radio button selected
    public static final String CLONE_GROUPS            = 'cloneAssignments';    // Clone groups option
    public static final String REMOTE_LIBRARY          = 'templateSurvey';      // Open the remote survey page
    public static final String REMOTE_LIBRARY_SELECT   = 'libList';             // The id of the remote library selectList
    public static final String CLONE_TEMPLATE          = 'cloneTemplate';       // Clone a template
    public static final String TEMPLATE                = 'template';            // Create a new template
    public static final String BASE_TEMPLATES          = 'baseTemplates';       // The list of base templates
    public static final String CREATE_FROM_TEMPLATE    = 'createFromTemplate';  // Indicates to create a survey from a template(s)
    public static final String CREATE_NEW_TEMPLATE     = 'createTemp';          // Indicates that a new template it being created
    public static final String CREATE_NEW_PPI_TEMPLATE = 'createNewPPITemp';    // Indicates that a new PPI is being created
    public static final String CLONE_PPI_TEMPLATE      = 'clonePpiTemplate';    // Indicates that an existing PPI is being cloned
    public static final String BASE_PPI                = 'ppiList';             // PPI to turn into a survey

    // Template
    public static final String LIBRARY_NAME    = 'libraryName';
    public static final String PPI_TO_CLONE    = 'ppiToClone';
    public static final String TEMPLATE_ACTION = 'templateAction';      // The value that is passed via VF to decide the action to take
    public static final String GET_PPI_ACTION  = 'getPPI';              // Action name to get a PPI from Grameen
    public static final String DOWNLOAD_ACTION = 'download';            // Action to download a new template from a library
    public static final String GRAMEEN_LIBRARY = 'Grameen Foundation';  // The name of Grameen's library
    public static final String FORM_TYPE       = 'formType';            // Param to indicate the type of form
    public static final String FORM_TYPE_PPI   = 'ppi';                 // Indicates that the form is a ppi
    public static final String FORM_TYPE_TEMP  = 'temp';                // Indicates that the form is a template
    public static final String FORM_TYPE_SUR   = 'sur';                 // Indicates that the form is a survey
    public static final String EDIT_TEMPLATE   = 'editTemp';            // Indicates that a template is to be edited

    // Attachments names
    public static final String SURVEY_ANSWER_ATTACHMENT_NAME = 'submission.xml';

    // Field Force job submission request headers

    // Field force Job Source Creation picklist Values
    public static final String JOB_CREATION_SOURCE_ADHOC = 'Ad-hoc';

    // Field names
    public static final String FIELD_NAME_LASTMODIFIEDDATE = 'lastmodifieddate';

    // Stage types
    public static final String SUBMISSION_STAGE_INIT = 'init';
    public static final String SUBMISSION_STAGE_MEDIA = 'media';

    // Submission status
    public static final String SUBMISSION_STATUS_UPLOADING       = 'Uploading';
    public static final String SUBMISSION_STATUS_UPLOADED        = 'Uploaded';
    public static final String SUBMISSION_STATUS_UPLOADED_AUTO   = 'Uploaded - Processed after Survey Automatically Closed';
    public static final String SUBMISSION_STATUS_UPLOADED_CLOSED = 'Uploaded After Survey Closed';

    // X Frame constants
    public final static String XFRAME_OPTIONS_HEADER = 'X-Frame-Options';
    public final static String XFRAME_OPTIONS_DENY = 'DENY';

    // Borderline for unlimited records of queries
    public final static Integer RECORD_LIMIT = 5000;
    public final static Integer STANDARD_LIMIT = 2000;

    /**
     *  Method that given a ContentVersion, returns its file extension.
     *
     *  @param Content version to check.
     *  @return File extension.
     */
    public static String obtainFileExtensionFromVersion (ContentVersion cv) {
        String realType = '';
        if (cv.FileType != null && cv.FileType != 'UNKNOWN') {
            // The file type is known by Salesforce so we add it here.
            realType = cv.FileType;
        }
        else {
            String filePath = cv.PathOnClient;
            // The path is not known by salesforce so we deduce it from the attribute PathOnClient.
            if (filePath.contains('.') && (filePath.length() > filePath.lastIndexOf('.') + 1) ) {
                // The path has a file extension (has a ".") and "." is not the last character, so we can retrieve the extension.
                realType = filePath.substring(filePath.lastIndexOf('.') + 1, filePath.length());
            }
        }
        return realType;
    }

    /**
     * Method in charge of check if given an object name (survey mapping object),
     * and a list of fields (question mappings)
     * there is any autonumber field that is not set as Id field.
     *
     * @param objectName     - Object name related to the survey mapping (String).
     * @param idFieldApiName - Id field of the survey mapping (String).
     * @param fieldName      - Field name list (fields mapped) (List<String>).
     * @param fieldDescribes - Map of field describes (done in order to avoid
     *                           calling the same describe several times).
     *
     * @return True if there is some autonumber field that is not id field, false otherwise.
     */
    public static Boolean isAutonumberNotIdField(
            String objectName,
            String idFieldApiName,
            List<String> fieldNameList,
            Map<String, Schema.SObjectField> fieldDescribes
    ) {
        Boolean isAutonumberNotIdfield = false;

        for (String fieldName : fieldNameList) {
            Schema.SObjectField field = fieldDescribes.get(fieldName);
            if (field != null) {
                Schema.DescribeFieldResult dField = field.getDescribe();
                if (dField.isAutoNumber()) {
                    if (String.isBlank(idFieldApiName) || fieldName != idFieldApiName) {
                        // Fieldname is autonumber and is not the same as the id field.
                        isAutonumberNotIdfield = true;
                    }
                }
            }
        }

        return isAutonumberNotIdfield;
    }

    // Post Install Test Constants
    public static final String TEST_MOVE_XFORMS = '__test__testMoveXForms__0632cc8816e4';
    public static final String TEST_ANSWER_TEXT_VALUE = '__test__moveAnswerText__0632cc8816e4';

    // Name of the library for Tarowork users.
    public static final String WORKSPACE_LIBRARY_NAME = 'TaroWorks';

    // Contenty Types
    public static final String CONTENT_TYPE_JSON_UTF  = 'application/json;charset=UTF-8';

    // Max size for the Csv to allow to use it from attachment
    // set as 4.5 Mb in case the csv is attached to the Cascading Select
    public static final Integer CSV_CASCADING_MAX_FILE_SIZE = 4500000;

    // Cascading Select csv attachment nameField
    public static final String CASCADING_CSV_ATT = 'cascadingSelect.csv';

    // Cascading Select csv attachment nameField
    public static final Integer CASCADING_CSV_BATCH_SIZE = 1000;

    // Cascading Select Status values
    public static final String CASCADING_STATUS_PROCESSING = 'Processing';
    public static final String CASCADING_STATUS_UPLOADED = 'Ready';
    public static final String CASCADING_STATUS_INVALID = 'Invalid';

    // Expected file extension for the uploaded csv file for a cascading select
    public static final String CSV_FILE_EXTENSION = 'csv';

    /**
     * Get a subset of a list
     */
    public static List<Object> getListSubset(
            Integer start,
            Integer finish,
            List<Object> inputList
    ) {

        List<Object> returnList = new List<Object>();
        if (finish > inputList.size()) {
            finish = inputList.size();
        }
        for (Integer i = start; i < finish; i++) {
            returnList.add(inputList.get(i));
        }
        return returnList;
    }

    /**
     * Get a subset of a list
     */
    public static List<SObject> getListSubset(
            Integer start,
            Integer finish,
            List<SObject> inputList
    ) {

        List<SObject> returnList = new List<SObject>();
        if (finish > inputList.size()) {
            finish = inputList.size();
        }
        for (Integer i = start; i < finish; i++) {
            returnList.add(inputList.get(i));
        }
        return returnList;
    }

    /**
     * Convert a list of type Object to a List of type Id
     */
    public static List<Id> convertListToId(List<Object> listToConvert) {
        List<Id> returnList = new List<Id>();
        for (Object obj : listToConvert) {
            returnList.add(Id.valueOf(String.valueOf(obj)));
        }
        return returnList;
    }

    /**
     * Extract a list of the ids from a list of sObjects
     */
    public static List<Id> extractIds(List<SObject> objectsToExtractIdsFrom) {

        Map<Id, SObject> ids = new Map<Id, SObject>(objectsToExtractIdsFrom);
        List<Id> idsToReturn = new List<Id>();
        idsToReturn.addAll(ids.keySet());
        return idsToReturn;
    }
}
