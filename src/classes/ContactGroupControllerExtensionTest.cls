/**
*  Grameen: Salesforce - Contact Group
*  This is the test class for the ContactGroupControllerExtension class
*  (Related: IDALMSA-1358)
*
*   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*  @author  Dennys López Dinza
*/
@isTest
private class ContactGroupControllerExtensionTest {

    /**
    * Test to verify the ContactGroup saves successfully for non restricted user.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroup__c                     "Groups"                (CRU-)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testSaveGroupSuccess() {

        //creatae the group
        ContactGroup__c group1 = new ContactGroup__c ( Name = 'Group 1' );
        insert group1;

        ApexPages.StandardController  stdController = new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller = new ContactGroupControllerExtension(stdController);

        //change the contact group record
        controller.contactGroup.Name = 'New Name';
        Test.startTest();
        controller.saveGroup();
        Test.stopTest();
        //verify the record was successfully updated
        ContactGroup__c contactGroup_loaded = [SELECT Id, Name FROM ContactGroup__c WHERE Id =: group1.Id];

        System.assertEquals('New Name', contactGroup_loaded.Name, 'The name of contact group must be "New Name"');
    }

    /**
     * Test to verify a restricted user cannot save ContactGroup.
     *
     * Permission Dependence to run. (Create Read Update Delete)
     * - ContactGroup__c                     "Groups"                (----)
     *
     * (Related: IDALMSA-1358)
     */
    static testMethod void testNoAccessContactsSaveGroup() {

        String testGroupName = 'Group 1';
        ContactGroup__c group1 = new ContactGroup__c (Name = testGroupName);
        insert group1;

        ApexPages.StandardController  stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        controller.contactGroup.Name = 'New Name';
        User stdUser = TestUtils.getStandardUser();

        Test.startTest();
        System.runAs (stdUser) {
            controller.saveGroup();
        }
        Test.stopTest();
        System.assert(ApexPages.getMessages().size() > 0 , 'A message had to be generated');
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'The level of error must be "' + ApexPages.Severity.ERROR + '"'
        );
        // Verify the record was not successfully updated
        ContactGroup__c contactGroupLoaded =
            [SELECT Id, Name FROM ContactGroup__c WHERE Id = :group1.Id];
        System.assertEquals(
            testGroupName,
            contactGroupLoaded.Name,
            'The name should stay as ' + testGroupName
        );
    }

    /**
     * Test to verify the ContactMemberGroup saves successfully for non restricted user.
     *
     * Permission Dependence to run. (Create Read Update Delete)
     * - ContactGroup__c                     "Groups"                (CRUD)
     * - ContactGroupMember__c               "Members"               (CRUD)
     *
     * (Related: IDALMSA-1358)
     */
    static testMethod void testSaveContactGroupMemberSuccess() {

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();

        for(integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(ContactGroup__c = group1.Id, Contact__c = contacts[i].Id)
            );
        }
        insert members;

        ApexPages.StandardController  stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        // Select last two members to add
        controller.selectedNonMemberList = new List <Id>();
        Set<String> contactNames = new Set<String>();
        for(integer i = 2; i < 5; i++){
            controller.selectedNonMemberList.add(contacts[i].Id);
            contactNames.add(contacts[i].FirstName);
        }
        Test.startTest();
        controller.addMember();
        controller.saveGroup();
        Test.stopTest();

        // Verify the record was successfully updated
        ContactGroupMember__c[] contactMembers =
            [SELECT Id, Contact__r.FirstName FROM ContactGroupMember__c];

        System.assertEquals(
            5,
            contactMembers.size(),
            'The number of existing members should be 5.'
        );

        for (ContactGroupMember__c contactMember : contactMembers) {
            System.assert(contactNames.contains(contactMember.Contact__r.FirstName));
        }
    }

    /**
    * Test to verify the ContactGroupSurveyAssigments saves successfully for non restricted user.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - Survey__c                           "Surveys"               (CRUD)
    * - ContactGroupSurveyAssignment__c     "Targets"               (CRUD)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testSaveContactGroupSurveyAssigments() {

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        //Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();

        for(integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(ContactGroup__c = group1.Id, Contact__c = contacts[i].Id)
            );
        }
        insert members;

        //Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        ApexPages.StandardController  stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        //select some surveys to create assignments
        controller.selectedUnassignedSurveyList = new List<Id>();
        Set<Id> surveysId = new Set<Id>();
        for (Survey__c survey: surveys){
            controller.selectedUnassignedSurveyList.add(survey.Id);
            surveysId.add(survey.Id);
        }

        Test.startTest();
        controller.addSurvey();
        controller.saveGroup();
        Test.stopTest();

        List <ContactGroupSurveyAssignment__c> contactGSAssignments =
            [SELECT Id, Survey__r.Id FROM ContactGroupSurveyAssignment__c];

        System.assertEquals(4, contactGSAssignments.size(), 'Four assignments had to be created.');

        for(ContactGroupSurveyAssignment__c contactGSAssigment : contactGSAssignments) {
            surveysId.contains(contactGSAssigment.Survey__r.Id);
        }
    }

    /**
    * Test to verify success to delete ContactGroupSurveyAssigments.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroup__c                     "Groups"                (CRUD)
    * - ContactGroupMember__c               "Members"               (CRUD)
    * - ContactGroupSurveyAssignment__c     "Targets"               (CRUD)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testDeleteContactGroupSurveyAssigments() {

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        //Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();

        for(integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(ContactGroup__c = group1.Id, Contact__c = contacts[i].Id)
            );
        }
        insert members;

        // Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        // Create some assignments
        List<ContactGroupSurveyAssignment__c> surveyAssignment = new List<ContactGroupSurveyAssignment__c>();
        for(Integer i = 0; i < 3; i++) {
            surveyAssignment.add(
                new ContactGroupSurveyAssignment__c(
                    ContactGroup__c = group1.Id,
                    Survey__c = surveys[i].Id
                )
            );
        }
        insert surveyAssignment;

        ApexPages.StandardController  stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        controller.selectedAssignedSurveyList = new List <Id>();
        for (Integer i = 0; i < 2; i++) {
           controller.selectedAssignedSurveyList.add(surveys[i].Id);
        }

        Test.startTest();
        controller.removeSurvey();
        controller.saveGroup();
        Test.stopTest();

        List<ContactGroupSurveyAssignment__c> contactGSAssignments =
            [SELECT Id, Survey__r.Id FROM ContactGroupSurveyAssignment__c];

        System.assertEquals(
            1,
            contactGSAssignments.size(),
            'The should be only one assignment, the rest was removed.'
        );
    }

    /**
    * Test to verify generating list of non member list.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - Contact                             "Contacts"              (-R--)
    * - ContactGroup__c                     "Groups"                (-R--)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testGetNonMemberList() {

        //create a ContactGroup
        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        //create some contacts
        List <Contact> contacts = new List <Contact>();
        List <String> nameNonMembers = new List <String>();
        for(integer i=0; i<5; i++){

            Contact contact = new Contact(FirstName='Contact ' + i, LastName='LastName');
            contacts.add(contact);

            //save the name of contacts that are not going to be Members
            if (i >= 2){
                nameNonMembers.add(contact.FirstName +' '+ contact.LastName);
            }
        }
        insert contacts;

        //Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();

        for(integer i=0; i<2; i++){
            members.add(new ContactGroupMember__c(ContactGroup__c = group1.Id, Contact__c = contacts[i].Id));
        }
        insert members;

        ApexPages.StandardController stdController = new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller = new ContactGroupControllerExtension(stdController);

        Test.startTest();
            //generate the list of contacts that are not assigned to any group member
            List <SelectOption> selectOptions = controller.getNonMemberList();
        Test.stopTest();

        //verify the number of available selections is the same of non grouped contacts
        System.assertEquals(contacts.size() - members.size(), selectOptions.size(), 'The sould be 3 options.');

        //verify the correponding labels
        for(Integer i=0; i < selectOptions.size(); i++){

            System.assertEquals(nameNonMembers[i],
                                selectOptions[i].getLabel(),
                                'The option at [' + String.valueOf(i) + '] postion value should be "' + nameNonMembers[i]  + '"');
        }
    }

    /**
    * Test to verify not selecting list of non member list Deny Access ContactGroupMember.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroup__c                     "Groups"                (----)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testNoGetNonMemberListDenyAccessContactGroupMember() {

        //create a ContactGroup
        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        for(integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(
                    ContactGroup__c = group1.Id,
                    Contact__c = contacts[i].Id
                )
            );
        }
        insert members;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        User stdUser = TestUtils.getStandardUser();
        Test.startTest();
        System.runAs (stdUser) {
            List <SelectOption> selectOptions = controller.getNonMemberList();
        }
        Test.stopTest();

        System.assert(ApexPages.getMessages().size() > 0, 'There should be pages error message.');
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'The level of error must be "' + ApexPages.Severity.ERROR + '"'
        );
    }

    /**
    * Test to verify not selecting list of non member list Deny Access Contact.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - Contact                             "Contacts"              (----)
    * - ContactGroup__c                     "Groups"                (-R--)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testNoGetNonMemberListDenyAccessContact() {

        //create a ContactGroup
        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        for(integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(
                    ContactGroup__c = group1.Id,
                    Contact__c = contacts[i].Id
                )
            );
        }
        insert members;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        User stdUser = TestUtils.getStandardUser();

        Test.startTest();
        System.runAs (stdUser) {
            List <SelectOption> selectOptions = controller.getNonMemberList();
        }
        Test.stopTest();

        System.assert(!ApexPages.getMessages().isEmpty(), 'There should be pages error message.');
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'The level of error must be "' + ApexPages.Severity.ERROR + '"'
        );
    }

    /**
    * Test to verify not selecting list of member list Deny Access ContactGroupMember.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroup__c                     "Groups"                (----)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testNoGetMemberListDenyAccessContactGroupMember() {

        //create a ContactGroup
        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        for (integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(
                    ContactGroup__c = group1.Id,
                    Contact__c = contacts[i].Id
                )
            );
        }
        insert members;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        User stdUser = TestUtils.getStandardUser();
        Test.startTest();
        System.runAs (stdUser) {
            List <SelectOption> selectOptions = controller.getMemberList();
        }
        Test.stopTest();

        System.assert(!ApexPages.getMessages().isEmpty(), 'There should be pages error message.');
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'The level of error must be "' + ApexPages.Severity.ERROR + '"'
        );
    }

    /**
    * Test to verify selecting list of unassigned surveys.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroupSurveyAssignment__c       "Targets"               (-R--)
    * - Survey__c                             "Surveys"               (-R--)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testGetUnassignedSurveyList() {

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        for (integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(
                    ContactGroup__c = group1.Id,
                    Contact__c = contacts[i].Id
                )
            );
        }
        insert members;

        // Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        // Create some assignments
        List<ContactGroupSurveyAssignment__c> surveyAssignment = new List<ContactGroupSurveyAssignment__c>();
        for (Integer i = 0; i < 3; i++) {
            surveyAssignment.add(
                new ContactGroupSurveyAssignment__c(
                    ContactGroup__c = group1.Id,
                    Survey__c = surveys[i].Id
                )
            );
        }
        insert surveyAssignment;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        Test.startTest();
        List <SelectOption> selectOptions = controller.getUnassignedSurveyList();
        Test.stopTest();

        // Check quantity and name are corresponding
        System.assertEquals(
            surveys.size() - surveyAssignment.size(),
            selectOptions.size(),
            'There should be only one unassigned survey.'
        );
        System.assertEquals(
            surveys[surveys.size() - 1].Name,
            selectOptions[0].getLabel(),
            'The label of selection must be "' + surveys[surveys.size() - 1].Name + '"'
        );
    }

    /**
    * Test to verify selecting list of unassigned surveys cannot be generated, no permission for Contact Survey Assignment.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroupSurveyAssignment__c       "Targets"               (----)
    * - Survey__c                             "Surveys"               (-R--)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testGetUnassignedSurveyListDenyAccessContactSurveyAssignment() {

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();

        for (Integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(ContactGroup__c = group1.Id, Contact__c = contacts[i].Id)
            );
        }
        insert members;

        // Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        // Create some assignments
        List<ContactGroupSurveyAssignment__c> surveyAssignment =
            new List<ContactGroupSurveyAssignment__c>();
        for(Integer i = 0; i < 3; i++) {
            surveyAssignment.add(
                new ContactGroupSurveyAssignment__c(
                    ContactGroup__c = group1.Id, Survey__c = surveys[i].Id
                )
            );
        }
        insert surveyAssignment;

        ApexPages.StandardController stdController = new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        User stdUser = TestUtils.getStandardUser();
        Test.startTest();
        System.runAs (stdUser) {
            // Generate unassigned list of surveys
            List <SelectOption> selectOptions = controller.getUnassignedSurveyList();
        }
        Test.stopTest();

        System.assert(
            !ApexPages.getMessages().isEmpty(),
            'There sould be at least an error message.'
        );
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'This must be an Error Message.'
        );
    }

    /**
    * Test to verify selecting list of unassigned surveys cannot be generated, no permission for Survey.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroupSurveyAssignment__c       "Targets"               (----)
    * - Survey__c                             "Surveys"               (----)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testGetUnassignedSurveyListDenyAccessSurvey() {

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        for (integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(
                    ContactGroup__c = group1.Id,
                    Contact__c = contacts[i].Id
                )
            );
        }
        insert members;

        // Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        // Create some assignments
        List<ContactGroupSurveyAssignment__c> surveyAssignment = new List<ContactGroupSurveyAssignment__c>();
        for (Integer i = 0; i < 3; i++) {
            surveyAssignment.add(
                new ContactGroupSurveyAssignment__c(
                    ContactGroup__c = group1.Id,
                    Survey__c = surveys[i].Id
                )
            );
        }
        insert surveyAssignment;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        User stdUser = TestUtils.getStandardUser();

        Test.startTest();
        System.runAs (stdUser) {
            List <SelectOption> selectOptions = controller.getUnassignedSurveyList();
        }
        Test.stopTest();

        System.assert(
            !ApexPages.getMessages().isEmpty(),
            'There sould be at least an error message.'
        );
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'This must be an Error Message.'
        );
    }

    /**
    * Test to verify selecting list of assigned surveys.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroupSurveyAssignment__c       "Targets"                (-R--)
    * - Survey__c                             "Surveys"                (-R--)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testGetAssignedSurveyList() {

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        for (integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(
                    ContactGroup__c = group1.Id,
                    Contact__c = contacts[i].Id
                )
            );
        }
        insert members;

        // Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        // Create some assignments
        Set<String> surveyNames = new Set<String>();
        List<ContactGroupSurveyAssignment__c> surveyAssignment = new List<ContactGroupSurveyAssignment__c>();
        for (Integer i = 0; i < 3; i++) {
            surveyAssignment.add(
                new ContactGroupSurveyAssignment__c(
                    ContactGroup__c = group1.Id,
                    Survey__c = surveys[i].Id
                )
            );
            surveyNames.add(surveys[i].Name);
        }
        insert surveyAssignment;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        Test.startTest();
        List <SelectOption> selectOptions = controller.getAssignedSurveyList();
        Test.stopTest();

        // Check quantity and name are corresponding
        System.assertEquals(
            surveyAssignment.size(),
            selectOptions.size(),
            'There should be 3 assigned survey.'
        );

        // Verify the survey names are in the list
        for (SelectOption selectOption : selectOptions) {
            System.assert(
                surveyNames.contains(selectOption.getLabel()),
                'The survey name should be in the list.'
            );
        }
    }

    /**
    * Test to verify selecting list of assigned surveys cannot be generated, no permission for Contact Survey Assignment.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroupSurveyAssignment__c       "Targets"               (----)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testGetAssignedSurveyListDenyAccessContactSurveyAssignment() {

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        for (integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(
                    ContactGroup__c = group1.Id,
                    Contact__c = contacts[i].Id
                )
            );
        }
        insert members;

        // Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        // Create some assignments
        List<ContactGroupSurveyAssignment__c> surveyAssignment = new List<ContactGroupSurveyAssignment__c>();
        for (Integer i = 0; i < 3; i++) {
            surveyAssignment.add(
                new ContactGroupSurveyAssignment__c(
                    ContactGroup__c = group1.Id,
                    Survey__c = surveys[i].Id
                )
            );
        }
        insert surveyAssignment;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        User stdUser = TestUtils.getStandardUser();
        Test.startTest();
        System.runAs (stdUser) {
            List <SelectOption> selectOptions = controller.getAssignedSurveyList();
        }
        Test.stopTest();

        System.assert(
            !ApexPages.getMessages().isEmpty(),
            'There sould be at least an error message.'
        );
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'This must be an Error Message.'
        );
    }

    /**
    * Test to verify getting Survey Assignments.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroupSurveyAssignment__c       "Targets"               (-R--)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testGetSurveyAssigments(){

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        for (integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(
                    ContactGroup__c = group1.Id,
                    Contact__c = contacts[i].Id
                )
            );
        }
        insert members;

        // Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        Set<String> surveyNames = new Set<String>();
        List<ContactGroupSurveyAssignment__c> surveyAssignment =
            new List<ContactGroupSurveyAssignment__c>();
        for (Integer i = 0; i < 3; i++) {
            surveyAssignment.add(
                new ContactGroupSurveyAssignment__c(
                    ContactGroup__c = group1.Id,
                    Survey__c = surveys[i].Id
                )
            );
            surveyNames.add(surveys[i].Name);
        }
        insert surveyAssignment;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        Test.startTest();
        List <ContactGroupSurveyAssignment__c> surveyAssignments =
            controller.getSurveyAssignments();
        Test.stopTest();

        System.assert(!surveyAssignments.isEmpty(), 'Assignments had to be loaded.');

        for (ContactGroupSurveyAssignment__c surveyAssign: surveyAssignments) {
            System.assert(
                surveyNames.contains(surveyAssign.Survey__r.Name),
                'This survey had to be assigned.'
            );
        }
    }

    /**
    * Test to verify getting Survey Assignments fails because deny access to ContactSurveyAssignment.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroupSurveyAssignment__c       "Targets"               (----)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testGetSurveyAssigmentsDenyAccessSurveyAssigments(){

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = TestUtils.createContacts(5);

        // Save only first two members
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        for (integer i = 0; i < 2; i++) {
            members.add(
                new ContactGroupMember__c(
                    ContactGroup__c = group1.Id,
                    Contact__c = contacts[i].Id
                )
            );
        }
        insert members;

        // Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        // Create some assignments
        List<ContactGroupSurveyAssignment__c> surveyAssignment = new List<ContactGroupSurveyAssignment__c>();
        for (Integer i = 0; i < 3; i++) {
            surveyAssignment.add(
                new ContactGroupSurveyAssignment__c(
                    ContactGroup__c = group1.Id,
                    Survey__c = surveys[i].Id
                )
            );
        }
        insert surveyAssignment;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension controller =
            new ContactGroupControllerExtension(stdController);

        User stdUser = TestUtils.getStandardUser();
        Test.startTest();
        System.runAs (stdUser) {
            List <ContactGroupSurveyAssignment__c> surveyAssignments = controller.getSurveyAssignments();
        }
        Test.stopTest();

        System.assert(
            !ApexPages.getMessages().isEmpty(),
            'There sould be at least an error message.'
        );
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'This must be an Error Message.'
        );
    }

    /**
    * Test to verify not adding surveys because missing access to Surveys.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - Survey__c                 "Survey"               (----)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testAddSurveyDenyAccessSurvey(){

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        //Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension ctrl =
            new ContactGroupControllerExtension(stdController);

        ctrl.selectedUnassignedSurveyList = new List <Id>();

        for (Survey__c survey: surveys){
            ctrl.selectedUnassignedSurveyList.add(survey.Id);
        }

        User stdUser = TestUtils.getStandardUser();
        Test.startTest();
        System.runAs (stdUser) {
            ctrl.addSurvey();
        }
        Test.stopTest();

        System.assert(
            !ApexPages.getMessages().isEmpty(),
            'There sould be at least an error message.'
        );
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'This must be an Error Message.'
        );
    }

    /**
    * Test to verify not remove surveys because missing access to Surveys.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - Survey__c                 "Survey"               (----)
    *
    * (Related: IDALMSA-1358)
    */
    static testMethod void testRemoveSurveyDenyAccessSurvey(){

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        //Create some surveys
        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(4);
        insert surveys;

        ApexPages.StandardController stdController =
            new ApexPages.StandardController(group1);
        ContactGroupControllerExtension ctrl =
            new ContactGroupControllerExtension(stdController);

        ctrl.selectedUnassignedSurveyList = new List <Id>();

        for (Survey__c survey: surveys){
            ctrl.selectedUnassignedSurveyList.add(survey.Id);
        }

        User stdUser = TestUtils.getStandardUser();
        System.runAs (stdUser) {
            ctrl.removeSurvey();
        }

        System.assert(
            !ApexPages.getMessages().isEmpty(),
            'There sould be at least an error message.'
        );
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'This must be an Error Message.'
        );
    }
}
