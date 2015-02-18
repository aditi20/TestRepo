/**
 * Util Class with auxiliary functions for test methods
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Sebastian Piazza
 * @author Alejandro De Gregorio Tort
 */
@isTest
public with sharing class TestUtils {

    public static String TEST_CONTACT_LAST_NAME = 'TestLastName_';
    public static String TEST_SURVEY_NAME = 'SurveyName_';

    private static Profile taroWorksPartnerProfile;
    private static Profile chatterExternalProfile;
    private static Profile standardUserProfile;
    private static Profile systemAdminProfile;
    private static Profile taroWorksUserProfile;


    /**
     * Method that returns the URL of the service
     * @param service String identifying the service
     * @return The url of the service
     */
    public static String getServiceURL(String service){
        return URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/' + service;
    }

    /**
     * Create a given number of accounts
     */
    public static List<Account> createAccounts(Integer amountNeeded) {

        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < amountNeeded; i++) {
            accounts.add(new Account(Name = 'TestAccount_' + i));
        }
        insert accounts;
        return accounts;
    }

    /**
     * Creates a case for each account passed in
     */
     public static List<Case> createCasesForAccounts(List<Account> caseOwners) {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < caseOwners.size(); i++) {
            cases.add(new Case(Subject = 'TestCase_' + i, AccountId = caseOwners[i].Id));
        }
        insert cases;
        return cases;
    }

    /**
     * Creates a case for each contact passed in
     */
     public static List<Case> createCasesForContacts(List<Contact> caseOwners) {

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < caseOwners.size(); i++) {
            cases.add(new Case(Subject = 'TestCaseContact_' + i, ContactId = caseOwners[i].Id));
        }
        insert cases;
        return cases;
    }

    /**
     * Create a bunch of contact for testing
     */
    public static List<Contact> createContactsNotInserted(Integer amountNeeded) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < amountNeeded; i++) {
            contacts.add(new Contact(LastName = TEST_CONTACT_LAST_NAME + i));
        }
        return contacts;
    }

    public static List<Contact> createContacts(Integer amountNeeded) {
        List<Contact> contacts = createContactsNotInserted(amountNeeded);
        insert contacts;
        return contacts;
    }

    /**
     * Method to create a contact
     * @param aName - a string with the last name for the contact
     * @return the created contact object
     */
    public static Contact createContact(String aName) {
        Contact con = new Contact(LastName = aName);
        insert con;
        return [SELECT Id, Name, LastName FROM Contact WHERE Id = :con.Id];
    }

    /**
     * Create contacts for a list of accounts
     */
    public static List<Contact> createContactsForAccounts(
            List<Account> accounts,
            Integer numberOfContacts
    ) {
        List <Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            List<Contact> accountContacts = createContactsNotInserted(numberOfContacts);
            for (Contact c : accountContacts) {
                c.AccountId = acc.Id;
            }
            contacts.addAll(accountContacts);
        }
        insert contacts;
        return contacts;
    }

    /**
     * Method to create a contact
     * @return the created contact object
     */
    public static Contact createContact() {
        return createContact('Contact_' + String.valueOf(Crypto.getRandomInteger()));
    }

    /**
     * Method to create a publish job template with a data collection task
     *
     * @param jobName - Name of job to create
     * @param surveyName - Name of survey to publish the job
     *
     * @return jobTemplate - Published job template
     */
    public static JobTemplate__c createPublishedDataCollectionJobTemplate(String jobName, String surveyName){
        // Add a Job wth a collect data task
        Survey__c survey = new Survey__c(Name = surveyName);
        insert survey;

        SurveyVersion__c surveyVersion = SurveyDO.publishSurvey(survey);

        JobTemplate__c jobTemplate = JobTemplateDO.createJobTemplate(
            jobName,
            JobTemplateDO.STATUS_DRAFT,
            null,
            ''
        );
        insert jobTemplate;

        TaskTemplate__c task = TaskTemplateDO.createDataCollectionTaskTemplate(
            'taskName',
            1,
            jobTemplate.Id,
            '',
            null,
            surveyVersion.Id,
            null
        );
        insert task;

        // Publish job
        jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        update jobTemplate;

        return jobTemplate;
    }

    /**
     * Method to create published job templates with a data collection task
     *
     * @param jobName - Name of job to create
     * @param surveyName - Name of survey to publish the job
     * @param numberOfJobs - Quantity of jobs to create
     *
     * @return jobTemplate - Published job templates
     */
    public static List<JobTemplate__c> createPublishedDataCollectionJobTemplates(String jobName, String surveyName, Integer numberOfJobs){
        // Add a Job wth a collect data task
        Survey__c survey = new Survey__c(Name = surveyName);
        insert survey;
        SurveyVersion__c surveyVersion = SurveyDO.publishSurvey(survey);
        List<TaskTemplate__c> newTasks = new List<TaskTemplate__c>();
        List<JobTemplate__c> newJobs = new List<JobTemplate__c>();
        for (Integer i = 0; i < numberOfJobs; i++) {
            newJobs.add(new JobTemplate__c(Name = jobName + i, Status__c = JobTemplateDO.STATUS_DRAFT));
        }
        insert newJobs;

        for (JobTemplate__c jobTemplate:newJobs) {
            newTasks.add(new TaskTemplate__c(Name = 'taskName',
                                             JobTemplate__c = jobTemplate.Id,
                                             Form__c = surveyVersion.Id,
                                             Position__c = 1,
                                             Type__c = TaskTemplateDO.TYPE_FORM));
        }
        insert newTasks;

        // Publish jobs
        for (JobTemplate__c jobTemplate:newJobs){
            jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        }
        update newJobs;

        return newJobs;
    }

    /**
     *  Method to create a Job__c.
     *
     * @param jobName       - Job name
     * @param jobTemplateId - Related JobTemplate Id.
     * @param contactId     - Related Contact Id.
     * @param assignedId    - Related assigned Id.
     * @param startDate     - Start date.
     * @param endDate       - End date.
     *
     * @return Created Job Activity.
     */
    public static Job__c createJobActivity(
            String jobName,
            Id jobTemplateId,
            Id contactId,
            Id assignedId,
            Datetime startDate,
            Datetime endDate
    ) {
        Job__c newJobActivity  = new Job__c(
            Name = jobName,
            JobTemplate__c = jobTemplateId,
            Contact__c = contactId,
            Assigned__c = assignedId,
            StartDate__c = startDate,
            EndDate__c = endDate
        );
        insert newJobActivity;
        return newJobActivity;
    }

    /**
     *  Method to create a Task__c.
     *
     * @param jobActivityId  - Related Job.
     * @param startDate      - Start date.
     * @param endDate        - End date.
     * @param taskTemplateId - Related Task template.
     *
     * @return Created Task Activity.
     */
    public static Task__c createTaskActivity(
            Id jobActivityId,
            Datetime startDate,
            Datetime endDate,
            Id taskTemplateId
    ) {
        Task__c newTaskActivity  = new Task__c(
            Job__c          = jobActivityId,
            StartDate__c    = startDate,
            EndDate__c      = endDate,
            TaskTemplate__c = taskTemplateId
        );
        insert newTaskActivity;
        return newTaskActivity;
    }

    /**
     * Method that creates an object of mobile Survey and return it.
     */
    public static Mobile_User__c createMobileUser(Contact con, String mobileUsername, String mobilePassword, String status) {
        Mobile_User__c user = new Mobile_User__c(
            Username__c = mobileUsername,
            Password__c = mobilePassword,
            Contact__c  = con.Id,
            Status__c   = status
        );
        insert user;
        return MobileUserDO.getMobileUser(user.Id);
    }

    /**
     * Create a user with a Chatter External profile. They cannot access objects
     */
    public static User createChatterExternalUser() {
        try {
            return createUser(getChatterExternalUser().Id);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Get the Chatter External profile
     */
    public static Profile getChatterExternalUser() {
        if (chatterExternalProfile == null) {
            chatterExternalProfile = getProfile('Chatter External User');
        }
        return chatterExternalProfile;
     }

    /**
     * Retrieve a Profile for a TaroWorks Partner User
     *
     * @return - TaroWorks Partner User profile
     */
    public static Profile getPartnerUserProfile() {
        if (taroWorksPartnerProfile == null) {
            taroWorksPartnerProfile = getProfile('TaroWorks Partner User');
        }
        return taroWorksPartnerProfile;
    }

   /**
    * This functions retrieves a salesforce standard profile from the database
    *
    * @return salesforce standard profile for standard user
    */
    public static Profile getStandardProfile() {
        if (standardUserProfile == null) {
            standardUserProfile = getProfile('Standard User');
        }
        return standardUserProfile;
    }

    /**
     * Retrieve a Profile for a System Administrator
     *
     * @return - System administrator profile
     */
    public static Profile getSysAdminProfile() {
        if (systemAdminProfile == null) {
            systemAdminProfile = getProfile('System Administrator');
        }
        return systemAdminProfile;
    }

    /**
     * This functions retrieves a salesforce taroworks profile from the database
     *
     * @return salesforce Taroworks profile for Taroworks user
     */
     public static Profile getTaroworksProfile() {
        if (taroWorksUserProfile == null) {
            taroWorksUserProfile = getProfile('TaroWorks User');
        }
        return taroWorksUserProfile;
    }

    /**
     * Retrieve a Profile for the given Name
     *
     * @param   profileName the name of the profile to retrieve
     * @return              a profile
     */
    public static Profile getProfile(String profileName) {
        return [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
    }

    /**
     * Create a User
     *
     * @param profileId - Id for the profile that the User will belong to
     *
     * @return - The user
     */
    public static User createUser(Id profileId) {
        insert new Settings__c(
            Name = 'Test',
            FilterJobsBySalesforceUser__c = ApplicationSettingsUtils.JOBS_FILTER_ALL,
            ReCalculateJobTargets__c = false
        );
        User newUser = getUser(profileId, '');
        insert newUser;
        return newUser;
    }

    /**
     * Given a standard profile, and a suffix, it creates a valid test user
     * @return standard user with credentials and standard profile assigned
     */
    public static User getStandardUser() {
        Profile stdProfile = getStandardProfile();
        return getUser(stdProfile.Id, '' + Crypto.getRandomInteger());
    }

    /**
     * Creates a valid TaroWorks Partner User
     *
     * @return A TaroWorks Partner User
     */
    public static User getPartnerUser() {
        Profile stdProfile = getPartnerUserProfile();
        return getUser(stdProfile.Id, '' + Crypto.getRandomInteger());
    }

    /**
     * Given a profile, and a suffix, it creates a valid test user
     *
     * @param profileId - Valid salesforce standard profile id
     * @param suffix    - Suffix to be used when generating username firstname alias, etc
     *
     * @return User with credentials and the given profile
     */
    public static User getUser(Id profileId, String suffix) {
        if (String.isBlank(suffix)){
            suffix = '' + Crypto.getRandomInteger();
        }

        return new User(
            UserName = 'usr-' + suffix + '@gfsurveys.com',
            FirstName = 'First-Name-' + suffix,
            LastName = 'Last-Name' + suffix,
            Alias = (suffix.length() > 8 ? suffix.substring(0,8) : suffix),
            Email = 'usr-' + suffix + '@gfsurveys.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocalesIdKey = 'en_US',
            TimezonesIdKey = 'America/Los_Angeles',
            ProfileId = profileId
        );
    }

    /**
     * Create a Taroworks User
     * @return User with Taroworks User profile.
     */
    public static User createTaroworksUser() {

        Profile taroworksProfile = getTaroworksProfile();
        User taroworksUser = new User(
            UserName = 'taroworks_' + Crypto.getRandomInteger() + '@user.com',
            FirstName = 'Taroworks',
            LastName = 'User',
            Alias = 'taro',
            Email = 'taroworks@user.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocalesIdKey = 'en_US',
            TimezonesIdKey = 'America/Los_Angeles',
            ProfileId = taroworksProfile.Id
        );

        return taroworksUser;
    }

    /**
     * Generate a Taroworks User
     * @return User with Taroworks User profile.
     */
    public static User generateTaroworksUser() {
        User taroworksUser = createTaroworksUser();
        insert taroworksUser;
        return taroworksUser;
    }

    /**
     * Given a valid contact with credentials, this prepares the credentials on the rest context
     *
     * @param uri a string with the uri for the request
     * @param body a string to add in the body of the request
     * @param header a map of headers (header => value)
     */
    public static void prepareRestContext(String uri, Blob body, Map<String, String> headersMap){

        // Prepare the new request
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = uri;

        // Set the body
        if(body != null) {
            RestContext.request.requestBody = body;
        }

        // Set headers
        for(String header : headersMap.keySet()){
            if(header != null){
                RestContext.request.addHeader(header, headersMap.get(header));
            }
        }

        // Set a new response
        RestContext.response = new RestResponse();
    }

    /**
     * Given a valid contact with credentials, this prepares the credentials on the current apexpage
     *
     * @param user contact user name
     * @param pass contact pass
     * @param imei mobile imei
     * @param surveyAnswer survey answer in xml format
     * @param last if the Last parameter is true, the submission is marked as uploaded
     */
    public static void preparePageHeaders(String user, String pass, String imei, String surveyAnswer, boolean last){
        if(user != null) {
            ApexPages.currentPage().getHeaders().put(C.USERNAME_HEADER, user);
        }
        if(pass != null) {
            ApexPages.currentPage().getHeaders().put(C.PASSWORD_HEADER, pass);
        }
        if(imei != null) {
            ApexPages.currentPage().getHeaders().put(C.IMEI_HEADER, imei);
        }
        if(surveyAnswer != null) {
            ApexPages.currentPage().getHeaders().put(C.SURVEY_ANSWER_HEADER, surveyAnswer);
        }
        ApexPages.currentPage().getParameters().put(C.LAST_HEADER, String.valueOf(last));
    }

    /**
     * Given a valid contact with credentials, this prepares the credentials on the current apexpage
     *
     * @param user contact user name
     * @param pass contact pass
     * @param imei mobile imei
     * @param surveyAnswer survey answer in xml format
     * @param last if the Last parameter is true, the submission is marked as uploaded
     */
    public static void prepareCredentials(String user, String pass, String imei, String surveyAnswer, String last){
        ApexPages.currentPage().getHeaders().put(C.USERNAME_HEADER, user);
        ApexPages.currentPage().getHeaders().put(C.PASSWORD_HEADER, pass);

        if (imei != '') {
            ApexPages.currentPage().getHeaders().put(C.IMEI_HEADER,imei);
        }

        if (surveyAnswer != '') {
            ApexPages.currentPage().getHeaders().put(C.SURVEY_ANSWER_HEADER, surveyAnswer);
        }

        if (last != '') {
            ApexPages.currentPage().getParameters().put(C.LAST_HEADER, 'true');
        }
    }

    /**
     * Given an existing survey with a section and some questions
     * and some answers to those questions it generates the given submission xml
     *
     * @param surveyId id of the survey
     * @param qAnswers array of string values representing answers to the corresponding questions in order
     * @return xml submission as string
     */
    public static String getTestSubmissionXML(String surveyId, String[] qAnswers) {

        Question__c[] sections = [SELECT Id,Name,Survey__r.Name
                                  FROM Question__c WHERE Survey__c = :surveyId and Type__c = :QuestionDO.TYPE_SECTION];

        if (sections.size() > 0) {
            Question__c[] questions = [SELECT Name,Type__c,Parent__c
                                FROM Question__c
                                WHERE Survey__c = :surveyId and Type__c !=:QuestionDO.TYPE_SECTION order by Parent__c,Position__c];

            String xmlBuild='';
            Integer answerIterator = 0;

            String surveyName = sections[0].Survey__r.Name;

            for (Question__c sec: sections){
                String secName = sec.Name;
                xmlBuild += '<' + secName + '>';
                for (Question__c q : questions) {
                    if (q.Parent__c == sec.Id) {
                        xmlBuild += '<'+ q.Name +'>' + qAnswers[answerIterator] + '</'+ q.Name +'>';
                        answerIterator++;
                    }
                }
                xmlBuild += '</' + secName + '>';
            }

            return
            '<?xml version=\'1.0\' ?><' + surveyName + ' id="' + surveyId + '">'+
                '<start>2012-02-14T19:23:53.463</start>'+
                '<end>2012-02-14T19:24:40.816</end>'+
                '<today>2012-02-14</today>'+
                '<deviceid>356402040028589</deviceid>'+
                '<simid />'+
                '<phonenumber />'+
                    xmlBuild+
            '</'+ surveyName + '>';
        }
        else{
            return '';
        }
    }

    // ---------------------------------
    // UTILITY METHODS TO CREATE SURVEYS
    // ---------------------------------

    /**
     * Create a Partner User for the given account
     */
    public static MobileUserDO.UserWrapper createPartnerUser(Boolean isActive) {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return createPartnerUser(acc, isActive);
    }
    public static MobileUserDO.UserWrapper createPartnerUser(Account anAccount, Boolean isActive) {
        Contact partnerContact = new Contact(LastName = 'Partner User', AccountId = anAccount.Id);
        insert partnerContact;

        User partnerUser = getUser(
            getProfile('TaroWorks Partner User').Id,
            '' + Crypto.getRandomInteger()
        );
        partnerUser.IsActive = isActive;
        partnerUser.ContactId = partnerContact.Id;
        partnerUser.CommunityNickname = 'nickName' + + Crypto.getRandomInteger();
        insert partnerUser;

        return MobileUserDO.getUserWrapper(partnerUser.Id);
    }

    /**
     * Create a Partner User for the specified contact Name and account
     */
    public static User createPartnerUser(Account anAccount, String contactName, Boolean isActive) {
        Contact partnerContact = new Contact(LastName = contactName, AccountId = anAccount.Id);
        insert partnerContact;

        User partnerUser = getUser(
            getProfile('TaroWorks Partner User').Id,
            '' + Crypto.getRandomInteger()
        );
        partnerUser.IsActive = isActive;
        partnerUser.ContactId = partnerContact.Id;
        partnerUser.CommunityNickname = 'nickName' + + Crypto.getRandomInteger();
        partnerUser.UserPermissionsSFContentUser = true;
        insert partnerUser;

        return MobileUserDO.getPartnerUser(partnerUser.Id);
    }

    public static User createPartnerUser() {
        User partnerUser = createPartnerUserNotInserted();
        insert partnerUser;
        return partnerUser;
    }
    public static User createPartnerUserNotInserted() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contact partnerContact = new Contact(LastName = 'Partner User', AccountId = acc.Id);
        insert partnerContact;
        User partnerUser = getPartnerUser();
        partnerUser.IsActive = true;
        partnerUser.ContactId = partnerContact.Id;
        partnerUser.CommunityNickname = 'nickName' + + Crypto.getRandomInteger();
        return partnerUser;
    }

    public static Contact createSurveyor() {
        Contact surveyor = new Contact(
            FirstName                 = 'John',
            LastName                  = 'Surveyor',
            mobilesurveys_username__c = 'johnsur',
            mobilesurveys_password__c = 'johnsur',
            mobilesurveys_status__c   = C.SURVEYOR_STATUS_ACTIVE);
        insert surveyor;
        return surveyor;
    }

    /**
     * Create the contact and mobile user
     *
     * @param username - a string with the username for the login
     * @param password - a string with the password for the login
     * @param status - a string with the status for the mobile user object
     * @return an instance of Surveyor wich includes a contact and the corresponding mobile user
     */
    public static Surveyor createSurveyor(
            String lastName,
            String username,
            String password,
            String status
    ) {
        Contact c = TestUtils.createContact(lastName);
        Mobile_User__c mUser = TestUtils.createMobileUser(c, username, password, status);
        return new Surveyor(c, mUser);
    }

    /**
     * Create the contact and partner user
     *
     * @param lastname  - a string with lastname specified for contact
     * @param status    - a string with the status for the partner user object
     * @return an instance of Surveyor which includes a contact and the corresponding partner user
     */
    public static Surveyor createPartnerSurveyor(
        String lastName,
        Boolean status
    ) {
        // Create Partner Account
        List<Account> partnerAccount = TestUtils.createAccounts(1);
        User partnerUser = TestUtils.createPartnerUser(partnerAccount[0], lastName, status);
        Contact[] contacts = [SELECT LastName, Name, Id FROM Contact WHERE Id = :partnerUser.ContactId];
        return new Surveyor(contacts[0], partnerUser);
    }

    /**
     * Retrieve partner user login details for surveyor 
     *
     * @param surveyor  - surveyor instance for Partner User
     * 
     * @return an instance of Surveyor along with login detials
     */
    public static Surveyor partnerLoginDetails(Surveyor surveyor) {
        surveyor.addLoginResult(MobileUserLoginLogic.loadPartnerUserData(surveyor.partnerUser.Id));
        return surveyor;
    }

    /**
     * Insert a user in the given status
     *
     * @param userStatus - The status of the user being inserted
     * @return - The user created
     */
    public static Surveyor createSurveyorWithStatus(String userStatus) {
        return createSurveyor(
            'lastName' + Crypto.getRandomInteger(),
            'username' + Crypto.getRandomInteger(),
            'password',
            userStatus
        );
    }

    /**
     * Create a list of surveyors
     *
     * @param amount - The amount of surveyors to create
     *
     * @return - A list of surveyors
     */
    public static List<TestUtils.Surveyor> createSurveyors(Integer amount) {
        List<TestUtils.Surveyor> surveyors = new List<TestUtils.Surveyor>();
        for (Integer i = 0; i < amount; i++) {
            surveyors.add(TestUtils.createSurveyorWithStatus(MobileUserDO.STATUS_ACTIVE));
        }
        return surveyors;
    }

    /**
     * Change the status of the given surveyor
     *
     * @param surveyorToChange - The surveyor to change
     * @param newStatus        - The new status for the surveyor
     *
     * @return - The updated surveyor
     */
    public static Surveyor changeSurveyorStatus(
            Surveyor surveyorToChange,
            String newStatus
    ) {
        surveyorToChange.user.Status__c = newStatus;
        update surveyorToChange.user;
        return surveyorToChange;
    }

    /**
     * Create the Contact and a Mobile User. Also optionally logs the Mobile User in
     *
     * @param lastName     - The last name of the surveyor
     * @param username     - The username for the login
     * @param password     - The password for the login
     * @param status       - The status for the mobile user object
     * @param login        - Boolean indicating if the MobileUser should be logged in as well
     *
     * @return - an instance of Surveyor wich includes a contact and the corresponding mobile user
     */
    public static Surveyor createSurveyor(
            String lastName,
            String username,
            String password,
            String status,
            Boolean login
    ) {

        Surveyor surveyor = createSurveyor(lastName, username, password, status);
        if (login) {
            MobileUserLoginLogic.setBlockMobileUserLogin(false);
            surveyor.addLoginResult(MobileUserLoginLogic.authenticateMobileUser(
                username,
                password,
                '',
                false
            ));
            MobileUserLoginLogic.setBlockMobileUserLogin(true);
        }
        return surveyor;
    }
    /**
     * Wrapper class for the contact and mobile user objects
     */
    public class Surveyor {
        public Contact theContact { get; set; }
        public Mobile_User__c user { get; set; }
        public User partnerUser { get; set; }
        public MobileUserLoginLogic.LoginResult loginResult;

        /**
         * The constructor of the class
         */
        public Surveyor(Contact aContact, Mobile_User__c mUser){
            theContact = aContact;
            user = mUser;
        }

        /**
         * The constructor of the class for partner User
         */
        public Surveyor(Contact aContact, User partnerUser) {
            this.theContact = aContact;
            this.partnerUser = partnerUser;
        }

        /**
         * Add a LoginResult to the surveyor
         */
        public void addLoginResult(MobileUserLoginLogic.LoginResult loginResult) {
            this.loginResult = loginResult;
        }
    }

    public static List<Survey__c> createSurveysNotInserted(Integer amountNeeded) {
        List<Survey__c> newSurveys = new List<Survey__c>();
        for (Integer i = 0; i < amountNeeded; i++) {
            newSurveys.add(
                new Survey__c(
                    Name = TEST_SURVEY_NAME + i,
                    Status__c = SurveyDO.STATUS_DRAFT,
                    Version__c = 1
                )
            );
        }
        return newSurveys;
    }

    /**
     * Create a PPI Survey
     */
    public static Survey__c createPPISurvey() {
        updatePPILicenseSettings();
        Language__c language = insertPpiLanguage();
        ISO_Country__c country = insertCountry('IN', 'IN');

        // Create the survey
        Survey__c survey = new Survey__c(
            Name = 'TestPPIDisp',
            Description__c = 'A Description',
            PPIDataYear__c = 2012,
            CountryCode__c = country.Name,
            LanguageCode__c = language.Name,
            IsPPI__c = true,
            IsTemplate__c = true
        );
        return survey;
    }

    /**
     * Insert a language to use to test PPI
     */
    public static Language__c insertPpiLanguage() {
        return insertLanguage('IN', 'IN');
    }

    /**
     * Insert a country to use to test PPI
     */
    public static ISO_Country__c insertPpiCountry() {
        return insertCountry('IN', 'IN');
    }

    /**
     * Update LicenseSettings
     */
    public static void updatePPILicenseSettings() {
        allowUseOfPpiSurvey();
    }

    /**
     * Allow use of PPI surveys
     */
    public static void allowUseOfPpiSurvey() {
        LicenseSettings__c license = C.getLicense();
        license.UsePPI__c = true;
        update license;
    }

    public static Language__c insertLanguage(String name, String shortLanguageName) {
        Language__c language =
            new Language__c(Name = name, ShortLanguageName__c = shortLanguageName);
        insert language;
        return language;
    }

    public static Language__c addLanguage(String name, String shortLanguageName){
        return new Language__c(Name = name, ShortLanguageName__c = shortLanguageName);
    }

    public static ISO_Country__c insertCountry(String name, String shortName) {
        ISO_Country__c country =
            new ISO_Country__c(Name = name, ShortName__c = shortName);
        insert country;
        return country;
    }

    public static ISO_Country__c addCountry(String name, String shortName){
        return new ISO_Country__c(Name = name, ShortName__c = shortName);
    }

    public static Survey__c createSurvey(String surveyName) {
        Survey__c survey = new Survey__c(
            Name = surveyName,
            Status__c = SurveyDO.STATUS_DRAFT,
            Version__c = 1
        );
        insert survey;
        return survey;
    }

    public static Question__c addSection(Survey__c survey, Integer position, String name){
        return addQuestion(survey.Id, null, position, name, QuestionDO.TYPE_SECTION);
    }

    public static Question__c addQuestion(Survey__c survey, Integer position, String name, String type){
        return addQuestion(survey.Id, null, position, name, type);
    }

    public static Question__c addQuestion(Question__c section, Integer position, String name, String type){
        return addQuestion(section.Survey__c, section.Id, position, name, type);
    }

    private static Question__c addQuestion(
            Id surveyId,
            Id sectionId,
            Integer position,
            String name,
            String type
    ) {
        Question__c question = new Question__c(
            Survey__c   = surveyId,
            Parent__c   = sectionId,
            Name        = name,
            Caption__c  = name,
            Position__c = position,
            Type__c     = type);
        insert question;
        return question;
    }

    /**
     * This method will be used to create an instance of Question and not insert it in Database
     */
    public static Question__c createQuestion(
            Id surveyId,
            Id sectionId,
            Integer position,
            String name,
            String type
    ) {
        Question__c questionInstance =
            new Question__c(
                Survey__c   = surveyId,
                Parent__c   = sectionId,
                Name        = name,
                Caption__c  = name,
                Position__c = position,
                Type__c     = type
            );
        return questionInstance;
    }

    public static List<Option__c> addOptions(
            Question__c question,
            List<String> options
    ) {
        return addOptions(question, options, new List<Integer>());
    }

    public static Option__c[] addOptions(
            Question__c question,
            List<String> options,
            List<Integer> ppiScores
    ) {
        List<Option__c> optionList = new List<Option__c>{};
        for (Integer i = 0; i < options.size(); i++) {
            optionList.add(new Option__c(
                Question__c = question.Id,
                Caption__c  = options[i],
                PPIScore__c =
                    ppiScores.size() >= i + 1
                        ? ppiScores[i]
                        : null,
                Position__c = i + 1
            ));
        }
        insert optionList;
        return optionList;
    }

    /**
     * Create Skip Condition records along with related Survey details
     */
    public static List<SkipCondition__c> createSkipConditions() {
        // Create a Survey
        Survey__c survey = createSurvey('Skip Survey');

        // Create a new section
        Question__c sectionQuestion = addQuestion(
            survey,
            1,
            'section',
            QuestionDO.TYPE_SECTION
        );

        // Create types of questions
        List<String> types = new List<String> {
            QuestionDO.TYPE_RADIO,
            QuestionDO.TYPE_TEXT_SHORT,
            QuestionDO.TYPE_TEXT_LONG,
            QuestionDO.TYPE_NUMBER_INTEGER,
            QuestionDO.TYPE_NUMBER_DECIMAL,
            QuestionDO.TYPE_DATE,
            QuestionDO.TYPE_DATETIME,
            QuestionDO.TYPE_BARCODE,
            QuestionDO.TYPE_GPS
        };

        // Create the questions
        Map<String, Question__c> questions = new Map<String, Question__c>();
        for(Integer i = 0; i < types.size(); i++) {
            questions.put(
                types.get(i),
                addQuestion(
                    sectionQuestion,
                    i,
                    'qName' + types.get(i),
                    types.get(i)
                )
            );
        }

        // Add the options to the radio question
        List<String> optionNameList = new List<String> {
            'Option1',
            'Option2',
            'Option3'
        };
        List<Option__c> options = addOptions(
            questions.get(QuestionDO.TYPE_RADIO),
            optionNameList
        );

        // Add the skip condition logic to all questions
        List<SkipCondition__c> listConditions = new List<SkipCondition__c>();
        for (Integer i = 0; i < questions.size(); i++){
            if (i != 0) {
                listConditions.add(new SkipCondition__c (
                    Parent__c = questions.get(types[i]).Id,
                    SourceQuestion__c = questions.get(types[0]).Id,
                    Condition__c = 'Is',
                    Negate__c = false,
                    Value__c = options[1].id
                ));
            }
        }
        return listConditions;
    }

    /**
     * Inserts specified Skip Condition records in database
     *
     * @param listConditions - the list of skip condition records for insert
     */
    public static void insertSkipConditionRecords(List<SkipCondition__c> listConditions) {
        insert listConditions;
    }

    /**
     * Create the questions for a cascading select.
     * It creates the question and inserts it to the database.
     *
     * @param  name             the name of the question
     * @param  caption          the caption for the question
     * @param  hint             a hint for the question
     * @param  survey           the survey that the question will belong to
     * @param  section          the section where the question will be included
     * @param  cascadingLevels  a list with the cascading levels to create the question
     * @return                  the questions created
     */
    public static List<Question__c> addCascadingSelectQuestion(
        String name,
        String caption,
        String qHint,
        Survey__c survey,
        Question__c section,
        Integer position,
        List<CascadingLevel__c> cascadingLevels
    ) {
        List<Question__c> result = new List<Question__c>();

        Question__c cascadingParentQuestion = new Question__c(
            Name = name,
            Caption__c = caption,
            Hint__c = qHint,
            Parent__c = section.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Position__c = position,
            CascadingSelect__c = cascadingLevels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        result.add(cascadingParentQuestion);


        result.addAll(createQuestionsforCascading(survey.Id, cascadingParentQuestion, cascadingLevels));
        return result;
    }

    /**
     * Create a SurveyMapping that is a reference
     *
     * @param survey        - The survey that the mapping is for
     * @param objectName    - The object API Name that is being mapped to
     * @param isReference   - Is this a reference mapping
     * @param matchingField - The API Name for the field that identifies a record
     *
     * @return - The SurveyMapping object
     */
    public static SurveyMapping__c mapObject(
            Survey__c survey,
            String objectName,
            Boolean isReference,
            String matchingField
    ) {
        SurveyMapping__c surveymapping = new SurveyMapping__c(
            Survey__c        = survey.Id,
            ObjectApiName__c = objectName,
            IsReference__c   = isReference,
            MatchingField__c = matchingField
        );
        insert surveymapping;
        return surveymapping;
    }

    public static SurveyMapping__c mapObject(Survey__c survey, String objectName){
        SurveyMapping__c surveymapping = new SurveyMapping__c(
            Survey__c        = survey.Id,
            ObjectApiName__c = objectName);
        insert surveymapping;
        return surveymapping;
    }

    /**
     * Create a QuestionMapping
     *
     * @param surveyMapping - The survey mapping that the question mapping is for
     * @param fieldName     - The field API Name
     * @param question      - Question that is being mapped to
     *
     * @return - The QuestionMapping object
     */
    public static QuestionMapping__c mapQuestion(SurveyMapping__c surveyMapping, Question__c question, String fieldName){
        QuestionMapping__c questionmapping = new QuestionMapping__c(
            SurveyMapping__c = surveyMapping.Id,
            Question__c      = question.Id,
            FieldApiName__c  = fieldName);
        insert questionmapping;
        return questionmapping;
    }

    public static QuestionMapping__c mapQuestion(SurveyMapping__c surveyMapping, Question__c question, String fieldName, Boolean isBroken){
        QuestionMapping__c questionmapping = new QuestionMapping__c(
            SurveyMapping__c = surveyMapping.Id,
            Question__c      = question.Id,
            IsBroken__c      = isBroken,
            FieldApiName__c  = fieldName);
        insert questionmapping;
        return questionmapping;
    }

    /**
     *  Method in charge to create and return a ObjectRelationshipMapping__c object.
     *  @param childObject Object that will be the child in the relation.
     *  @param parentObject Object that will be the parent in the relation.
     *  @param fieldName Field of the relation.
     *  @return ObjectRelationshipMapping__c object.
     */
    public static ObjectRelationshipMapping__c relateObjects(
            SurveyMapping__c childObject,
            SurveyMapping__c parentObject,
            String fieldName
    ) {
        ObjectRelationshipMapping__c relationObject = new ObjectRelationshipMapping__c();
        relationObject.ChildSurveyMapping__c        = childObject.Id;
        relationObject.ParentSurveyMapping__c       = parentObject.Id;
        relationObject.FieldApiName__c              = fieldName;

        insert relationObject;
        return relationObject;
    }

    /**
     * Create a submission. Up to calling method to insert
     */
    public static Submission__c createSubmission(Id surveyId, Id versionId, Id surveyorId) {
        return new Submission__c(
            Survey__c = surveyId,
            SurveyVersion__c = versionId,
            Surveyor__c = surveyorId
        );
    }

    /**
     * Create a submission ppi value. Up to calling method to insert
     */
    public static SubmissionPPIValue__c createSubmissionPPI(Id tableLine, Id submission) {
        return new SubmissionPPIValue__c(PPITableLine__c = tableLine, Submission__c = submission);
    }

    public static DOM.Document createSubmissionDataNode(Survey__c survey){
        // Get the survey's latest version. If it's in draft, publish it.
        SurveyVersion__c version = null;
        if (survey.Status__c == SurveyDO.STATUS_DRAFT){
            version = SurveyDO.publishSurvey(survey);
            survey.Status__c = version.Status__c;
        } else {
            version = [SELECT Id FROM SurveyVersion__c WHERE Survey__c = :survey.Id AND Version__c = :survey.Version__c];
        }

        // Get the full generated XForm and extract the data model.
        Attachment att = [SELECT Id, Body FROM Attachment WHERE Name = :XformCreator.XFORM_ATTACHMENT AND ParentId = :version.Id];
        DOM.Document fullXForm = new Dom.Document();
        fullXForm.load( att.Body.toString() );
        DOM.XMLNode root     = fullXForm.getRootElement();
        DOM.XMLNode head     = root.getChildElement('head', C.NS_XHTML);
        DOM.XMLNode model    = head.getChildElement('model',null);
        DOM.XMLNode instance = model.getChildElement('instance',null);
        DOM.XMLNode datanode = instance.getChildElements()[0];

        DOM.Document dataDoc = new DOM.Document();
        DOM.XMLNode dataRoot = dataDoc.createRootElement(datanode.getName(), datanode.getNamespace(), null);
        dataRoot.setNamespace('jr', C.NS_JAVAROSA);
        dataRoot.setNamespace('h' , C.NS_XHTML);
        dataRoot.setAttribute('id', datanode.getAttributeValue('id',null));
        for(DOM.XMLNode child : datanode.getChildElements()){
            deepCloneXMLNode(dataRoot, child);
        }

        // Set up some basic data
        dataRoot.getChildElement('start'   ,null).addTextNode('2013-01-20T21:11:48.809-02');
        dataRoot.getChildElement('end'     ,null).addTextNode('2013-01-20T21:14:48.809-02');
        dataRoot.getChildElement('today'   ,null).addTextNode('2013-01-20');
        dataRoot.getChildElement('deviceid',null).addTextNode('12345');
        dataRoot.getChildElement('simid'   ,null).addTextNode('67890');
        return dataDoc;
    }

    private static DOM.XMLNode deepCloneXMLNode(DOM.XMLNode newParent, DOM.XMLNode sourceNode){
        DOM.XMLNode newNode = newParent.addChildElement( sourceNode.getName(), sourceNode.getNamespace(), null );
        // Copy all attributes
        Integer attributeCount = sourceNode.getAttributeCount();
        for(Integer i = 0; i < attributeCount; i++ ){
            String key = sourceNode.getAttributeKeyAt(i);
            newNode.setAttribute(key, sourceNode.getAttributeValue(key,null));
        }
        // Copy all child elements
        for (DOM.XMLNode child : sourceNode.getChildren()){
            if (child.getNodeType() == DOM.XMLNodeType.TEXT) {
                newNode.addTextNode(child.getText());
            } else if (child.getNodeType() == DOM.XMLNodeType.COMMENT) {
                newNode.addCommentNode(child.getText());
            } else {
                deepCloneXMLNode(newNode, child);
            }
        }
        return newNode;
    }

    /**
     * Create and validate a new submission
     *
     * @param xml         - The submission XML
     * @param loginResult - LoginResult for the surveyor
     *
     * @return - The submission object that contains the submission
     */
    public static Submission submitNewSubmission(String xml, MobileUserLoginLogic.LoginResult loginResult) {

        Submission sub = new Submission(xml, loginResult.mobileUser.Contact__c);
        sub.validateNewSubmission();
        ServicesController sc = new ServicesController();
        return sc.submit(loginResult, sub);
    }

    /**
     * Helper to create a Survey Library
     * Create a survey library as utility
     * (Related: IDALMA-3213)
     *
     * @return lib SurveyLibrary__c  Created Survey Library
     */
    public static SurveyLibrary__c createLib() {

        SurveyLibrary__c lib = new SurveyLibrary__c( Name = 'TEST LIB', URL__c = 'www.testurl.org', RemoteLibraryPath__c = 'path', SurveyPreviewPath__c = 'Path' );
        Database.insert(lib);
        return lib;
    }

    /**
     *  Method in charge of creating a list of ContentVersion.
     *
     *  @return List of conten version.
     */
    public static List<ContentVersion> createListContentVersion(){
        // Insert some files to generate a version
        String fileNameStandard      = 'someFile.mp4';
        String fileNameSeveralPoints = 'some.Fi.Le.3gp';
        String fileNameEndPoint      = 'someFile.';

        ContentVersion doc1 = new ContentVersion(
            title = 'title1',
            VersionData = Blob.valueof('aaa324'),
            pathOnClient = fileNameStandard); // I'm using the fileName as the pathOnClient value, but it could be different
        ContentVersion doc2 = new ContentVersion(
            title = 'title1',
            VersionData = Blob.valueof('aaa324'),
            pathOnClient = fileNameSeveralPoints);
        ContentVersion doc3 = new ContentVersion(
            title = 'title1',
            VersionData = Blob.valueof('aaa324'),
            pathOnClient = fileNameEndPoint);

        List<ContentVersion> contentVersions = new List<ContentVersion> {doc1, doc2, doc3};
        insert contentVersions;

        return contentVersions;
    }

    /**
     * Create complete cascading select
     */
    public static List<CascadingLevel__c> createCompleteCascadingSelect(
        String aName,
        Integer numberOfLevels,
        Integer amountPerLevel
    ) {

        CascadingSelect__c cascadingSelect = TestUtils.createCascadingSelect(aName);
        List<CascadingLevel__c> cascadingLevels =
            TestUtils.createCascadingLevels(cascadingSelect, numberOfLevels);
        TestUtils.createCascadingValues(cascadingLevels, amountPerLevel);
        return getCascadingLevels(cascadingSelect.Id);
    }

    /**
     * Create a cascading select with the given data
     *
     * @param  aName         a name for the cascading select
     * @param  cascadingData a matrix with the data for the cascading
     * @return               a list with the cascading levels containing the
     *                       data of the cascading select and its values
     */
    public static List<CascadingLevel__c> createCascadingSelect(String aName, List<List<String>> cascadingData) {
        // Create the cascading object
        CascadingSelect__c cascadingObject = new CascadingSelect__c(Name = aName, Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cascadingObject;

        // Create the levels
        List<CascadingLevel__c> levels = new List<CascadingLevel__c>();
        Id controllingLevel = null;
        for(Integer i = 0; i < cascadingData[0].size(); i ++) {
            // Create the level
            CascadingLevel__c level = new CascadingLevel__c(
                Name__c = cascadingData[0][i].toLowerCase(),
                Position__c = i + 1,
                CascadingSelect__c = cascadingObject.Id,
                ControllingLevel__c = controllingLevel
            );
            insert level;

            levels.add(level);

            // Set the controlling for the next level
            controllingLevel = level.Id;
        }

        // Create the values
        Map<Id, Set<String>> createdValues = new Map<Id, Set<String>> ();
        Map<Id, Map<String, Id>> valuesByControllingValue = new Map<Id, Map<String, Id>>();
        // Loop over the rows, skipping the first one that was already used
        for(Integer i = 1; i < cascadingData.size(); i ++) {
            Id controllingValue = null;
            // Loop over the values
            for(Integer j = 0; j < cascadingData[0].size(); j ++) {

                // Check if the value already exists
                if(j == 0 && createdValues.get(null) != null && createdValues.get(null).contains(cascadingData[i][j])) {
                    controllingValue = valuesByControllingValue.get(null).get(cascadingData[i][j]);
                    continue;
                }
                else if(createdValues.get(controllingValue) != null && createdValues.get(controllingValue).contains(cascadingData[i][j])) {
                    controllingValue = valuesByControllingValue.get(controllingValue).get(cascadingData[i][j]);
                    continue;
                }

                CascadingSelectValue__c value = new CascadingSelectValue__c(
                    CascadingLevel__c = levels[j].Id,
                    ControllingSelectValue__c = controllingValue,
                    Position__c = i,
                    Value__c = cascadingData[i][j]
                );
                insert value;

                if(createdValues.get(controllingValue) == null) {
                    createdValues.put(controllingValue, new Set<String> {value.Value__c});
                }
                else {
                    createdValues.get(controllingValue).add(value.Value__c);
                }

                if(valuesByControllingValue.get(controllingValue) == null) {
                    valuesByControllingValue.put(controllingValue, new Map<String, Id> {value.Value__c => value.Id});
                }
                else {
                    valuesByControllingValue.get(controllingValue).put(value.Value__c, value.Id);
                }

                controllingValue = value.Id;
            }
        }

        // Return the cascading select with all its children
        return getCascadingLevels(cascadingObject.Id);
    }

    /**
     * Create a Cascading Select object
     */
    public static CascadingSelect__c createCascadingSelect(String name) {

        CascadingSelect__c cascadingSelect =
            new CascadingSelect__c(
                Name = name,
                Status__c = C.CASCADING_STATUS_UPLOADED
            );
        insert cascadingSelect;
        return cascadingSelect;
    }

    /**
     * Create the cascading level objects
     */
    public static List<CascadingLevel__c> createCascadingLevels(
            CascadingSelect__c controllingCascadingSelect,
            Integer numberOflevels
    ) {

        List<CascadingLevel__c> cascadingLevels = new List<CascadingLevel__c>();
        for (Integer i = 1; i <= numberOflevels; i++) {
            CascadingLevel__c level = new CascadingLevel__c(
                Name__c = 'Level' + i,
                Position__c = i,
                CascadingSelect__c = controllingCascadingSelect.Id
            );
            cascadingLevels.add(level);
        }
        insert cascadingLevels;
        for (Integer i = cascadingLevels.size() - 1; i > 0; i--) {
            cascadingLevels[i].ControllingLevel__c = cascadingLevels[i - 1].Id;
        }
        update cascadingLevels;
        return cascadingLevels;
    }

    /**
     * Create and insert the cascadingValues for a list of CascadingLevels.
     * Assumes that the levels are in the correct order in the list
     */
    public static void createCascadingValues(
            List<CascadingLevel__c> cascadingLevels,
            Integer amountPerLevel
    ) {
        Map<Integer, List<CascadingSelectValue__c>> valuesByLevel =
            new Map<Integer, List<CascadingSelectValue__c>>();
        valuesByLevel.put(
            0,
            createCascadingValuesForLevel(cascadingLevels[0], null, amountPerLevel)
        );
        insert valuesByLevel.get(0);

        for (Integer i = 1; i < cascadingLevels.size(); i ++) {
            valuesByLevel.put(i, new List<CascadingSelectValue__c>());
            for(CascadingSelectValue__c controllingValue : valuesByLevel.get(i - 1)) {
                valuesByLevel.get(i).addAll(
                    createCascadingValuesForLevel(
                        cascadingLevels[i], controllingValue, amountPerLevel
                    )
                );
            }
            insert valuesByLevel.get(i);
        }
    }

    /**
     * Create cascading values.
     * The values will not be inserted.
     *
     * @param  level            the level where the value will be included
     * @param  controllingValue the parent value
     * @param  aomunt           the amount of values to create
     * @return                  a list with the created values
     */
    private static List<CascadingSelectValue__c> createCascadingValuesForLevel(
       CascadingLevel__c level,
       CascadingSelectValue__c controllingValue,
       Integer amount
    ) {
        List<CascadingSelectValue__c> values = new List<CascadingSelectValue__c>();

        for(Integer i = 1; i < amount + 1; i++) {
            values.add(
                new CascadingSelectValue__c(
                    CascadingLevel__c = level.Id,
                    ControllingSelectValue__c =
                        (controllingValue != null)
                            ? controllingValue.Id
                            : null,
                    Position__c = i,
                    Value__c =
                        (controllingValue != null ? controllingValue.Value__c : '') + 'value' + i
                )
            );
        }
        return values;
    }

    /**
     *  Return the cascading select with all its children
     */
    public static List<CascadingLevel__c> getCascadingLevels(Id cascadingSelectId) {
        return [
            SELECT
                Id,
                Name__c,
                Position__c,
                ControllingLevel__c,
                CascadingSelect__c,
                CascadingSelect__r.Id,
                CascadingSelect__r.Name,
                (
                    SELECT
                        Id,
                        Value__c,
                        Position__c,
                        ControllingSelectValue__c
                    FROM
                        Cascading_Select_Values__r
                    ORDER BY
                        Position__c
                )
            FROM
                CascadingLevel__c
            WHERE
                CascadingSelect__c = :cascadingSelectId
            ORDER BY
                Position__c
        ];
    }

    /**
    * Create Questions of a cascading select
    * @surveyId         Survey Id
    * @cascadingParent  The Cascading Select Question parent
    * @cascadingLevels  The list of the cascading levels to convert to its correct question model
    * @return           The list of questions for the given levels, already inserted in the db
    **/
    public static List<Question__c> createQuestionsforCascading(
            Id surveyId,
            Question__c CascadingParent,
            List<CascadingLevel__c> cascadingLevels
    ) {
        List<Question__c> levelQuestions = new List<Question__c>();

        Id controllingQuestion = null;
        for (CascadingLevel__c level : cascadingLevels) {
            Question__c newQuestion       = new Question__c();
            newQuestion.ControllingQuestion__c  = controllingQuestion;
            newQuestion.Survey__c               = surveyId;
            newQuestion.Parent__c               = CascadingParent.Id;
            newQuestion.Caption__c              = level.Name__c;
            newQuestion.CascadingLevel__c       = level.Id;
            newQuestion.Type__c                 = QuestionDO.TYPE_CASCADING_LEVEL;
            newQuestion.Position__c             = level.Position__c;

            insert newQuestion;
            controllingQuestion = newQuestion.Id;
            levelQuestions.add(newQuestion);
        }
        return levelQuestions;
    }

    /**
     * Get a valid CSV of cars for the cascading select list tests
     */
    public static String getValidCascadingSelectCsv() {

        return
            'Select Make,Select Model,Select Year\n' +
            'Audi,A3,1999\n' +
            'Audi,A3,2000\n' +
            'Audi,A3,2001\n' +
            'Audi,A4,1998\n' +
            'Audi,A4,1999\n' +
            'Audi,A4,2001\n' +
            'Audi,A5,2002\n' +
            'Audi,A5,2003\n' +
            'Audi,A5,2004\n' +
            'Audi,A5,2005\n' +
            'Audi,S4,2001\n' +
            'Audi,S4,2002\n' +
            'Audi,S4,2003\n' +
            'Audi,S5,2000\n' +
            'Audi,S5,2001\n' +
            'Audi,S5,2002\n' +
            'BMW,3 Series,1995\n' +
            'BMW,3 Series,1998\n' +
            'BMW,3 Series,1997\n' +
            'BMW,5 Series,1998\n' +
            'BMW,5 Series,1999\n' +
            'BMW,6 Series,2000\n' +
            'BMW,6 Series,2001\n' +
            'BMW,7 Series,2000\n' +
            'BMW,M3,1997\n' +
            'BMW,M3,1998\n' +
            'BMW,M3,1999\n' +
            'BMW,X3,2000\n' +
            'BMW,X5,2001\n' +
            'BMW,X5,2003\n' +
            'Honda,Accord,1993\n' +
            'Honda,Accord,1994\n' +
            'Honda,Accord,1996\n';
    }
}
