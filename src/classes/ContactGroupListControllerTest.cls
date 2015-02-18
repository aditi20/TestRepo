/**
*  Grameen: Salesforce - Contact Group
*  This is the test class for the ContactGroupListController class
*  (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*  @author  Alejandro De Gregorio
*  @author  Dennys López Dinza
*/
@isTest
private class ContactGroupListControllerTest {

    static final String STATUS_ACTIVE = 'Active';
    static final String STATUS_INACTIVE = 'Inactive';

    static testMethod void testContactGroup() {

        List<ContactGroup__c> groups = new List<ContactGroup__c>();
        for(integer i = 0; i < 3; i++) {
            groups.add(new ContactGroup__c(Name = 'Contact Group ' + i));
        }
        insert groups;

        List<Contact> contacts = TestUtils.createContacts(9);

        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(8);
        insert surveys;

        List<Survey__c> activeSurveys = new List<Survey__c>();
        for(integer i=0; i<7; i++){
            activeSurveys.add(new Survey__c(Status__c = SurveyDO.STATUS_PUBLISHED, Name='Active Survey ' + i));
        }
        insert activeSurveys;
        //Publish all the versions of the Active Surveys
        List<SurveyVersion__c> activeSurveysVersions = [select Status__c from SurveyVersion__c where Survey__c in :activeSurveys];
        for (SurveyVersion__c version:activeSurveysVersions){
            version.Status__c = SurveyDO.STATUS_PUBLISHED;
        }
        update activeSurveysVersions;

        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[0].Id, Contact__c = contacts[0].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[0].Id, Contact__c = contacts[1].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[0].Id, Contact__c = contacts[2].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[0].Id, Contact__c = contacts[3].Id));

        members.add(new ContactGroupMember__c(ContactGroup__c = groups[1].Id, Contact__c = contacts[4].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[1].Id, Contact__c = contacts[5].Id));

        members.add(new ContactGroupMember__c(ContactGroup__c = groups[2].Id, Contact__c = contacts[6].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[2].Id, Contact__c = contacts[7].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[2].Id, Contact__c = contacts[8].Id));
        insert members;

        List<ContactGroupSurveyAssignment__c> surveyAssignment = new List<ContactGroupSurveyAssignment__c>();
        // Group with only inactive surveys
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[0].Id, Survey__c = surveys[0].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[0].Id, Survey__c = surveys[1].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[0].Id, Survey__c = surveys[2].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[0].Id, Survey__c = surveys[3].Id));


        // Group with 4 inactive surveys and 3 active surveys
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = surveys[4].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = surveys[5].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = surveys[6].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = surveys[7].Id));

        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = activeSurveys[0].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = activeSurveys[1].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = activeSurveys[2].Id));


        // Group with 4 active surveys
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[2].Id, Survey__c = activeSurveys[3].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[2].Id, Survey__c = activeSurveys[4].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[2].Id, Survey__c = activeSurveys[5].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[2].Id, Survey__c = activeSurveys[6].Id));
        insert surveyAssignment;


        ApexPages.StandardController stdController = new ApexPages.Standardcontroller(groups[0]);
        ContactGroupListController controller = new ContactGroupListController(stdController);


        //----------------------------------------------------------------
        // Test active survey count for current group and selection
        //----------------------------------------------------------------
        Test.startTest();
            // Set a current contact group without active surveys
            controller.contactGroup = groups[0];
            controller.targetIsSelection = false;
            // activeSurveysCount should be 0
            System.assertEquals(0, controller.getActiveSurvey().size());
        
            // Set a current contact group with 3 active surveys
            controller.contactGroup = groups[1];
            controller.targetIsSelection = false;
            // activeSurveysCount should be 3
            System.assertEquals(3, controller.getActiveSurvey().size());
        
            // Set a group without active surveys as selection
            controller.selectedGroupIds = groups[0].Id;
            controller.targetIsSelection = true;
            // activeSurveysCount should be 0
            System.assertEquals(0, controller.getActiveSurvey().size());
        
            // Set three groups selected. One without active surveys and two with 3 and 4 active surveys each
            controller.selectedGroupIds = groups[0].Id + ',' + groups[1].Id + ',' + groups[2].Id;
            controller.targetIsSelection = true;
            // activeSurveysCount should be 7
            System.assertEquals(7, controller.getActiveSurvey().size());


        //----------------------------------------------------------------
        // Test column sort
        //----------------------------------------------------------------
            // Sort by null should use default 'LastModifiedDate'
            controller.tableOrderColumn = null;
            System.assertEquals('LastModifiedDate', controller.tableOrderColumn);

            // Sort by 'SurveyCount__c' with default order desc, group[1] should be the last
            controller.tableOrderColumn = 'SurveyCount__c';
            controller.doSort();
            System.assertEquals(groups[1].Id, controller.groupList[2].Id);

            // Sort again with same column should change the order
            controller.tableOrderColumn = 'SurveyCount__c';
            controller.doSort();
            System.assertEquals(groups[1].Id, controller.groupList[0].Id);


        //----------------------------------------------------------------
        // Test activation and inactivation of contact groups
        //----------------------------------------------------------------
            controller.targetIsSelection = false;
            controller.currentGroupId = groups[1].Id;
            // Set currentGroupId should change the current contact group
            System.assertEquals(groups[1].Id, controller.contactGroup.Id);

            // Inactivate the current contact group should set Status__c to 'Inactive'
            controller.inactivateGroup();
            System.assertEquals(STATUS_INACTIVE, [select Id, Status__c from ContactGroup__c where Id = :groups[1].Id].Status__c);
        
            // Activate the current group should set the Status__c to 'Active'
            controller.activateGroup();
            System.assertEquals(STATUS_ACTIVE, [select Id, Status__c from ContactGroup__c where Id = :groups[1].Id].Status__c);

            // Inactivate the selected groups should change Status__c to 'Inactive' only in selected groups
            controller.selectedGroupIds = groups[0].Id + ',' + groups[2].Id;
            controller.targetIsSelection = true;
            controller.inactivateGroup();
            System.assertEquals(STATUS_INACTIVE, [select Id, Status__c from ContactGroup__c where Id = :groups[0].Id].Status__c);
            System.assertEquals(STATUS_ACTIVE, [select Id, Status__c from ContactGroup__c where Id = :groups[1].Id].Status__c);
            System.assertEquals(STATUS_INACTIVE, [select Id, Status__c from ContactGroup__c where Id = :groups[2].Id].Status__c);

            // Inactivate groups[1] to following test
            controller.targetIsSelection = false;
            controller.currentGroupId = groups[1].Id;
            controller.inactivateGroup();

            // Activate the selected groups should change Status__c to 'Inactive' only in selected groups
            controller.selectedGroupIds = groups[1].Id + ',' + groups[2].Id;
            controller.targetIsSelection = true;
            controller.activateGroup();
            System.assertEquals(STATUS_INACTIVE, [select Id, Status__c from ContactGroup__c where Id = :groups[0].Id].Status__c);
            System.assertEquals(STATUS_ACTIVE, [select Id, Status__c from ContactGroup__c where Id = :groups[1].Id].Status__c);
            System.assertEquals(STATUS_ACTIVE, [select Id, Status__c from ContactGroup__c where Id = :groups[2].Id].Status__c);


        //----------------------------------------------------------------
        // Test filters
        //----------------------------------------------------------------

            // Set null filter should change it with default value FILTER_ALL
            controller.filter = null;
            System.assertEquals(ContactGroupListController.FILTER_ALL, controller.filter);

            // Default filter is 'All'. So, should be 3 groups in the list
            System.assertEquals(3, controller.groupList.size());

            // With 'Active' filter should be 2 groups in the list
            controller.filter = ContactGroupListController.FILTER_ACTIVE;
            controller.refreshGroupList();
            System.assertEquals(2, controller.groupList.size());

            // With 'Inactive' filter should be 1 group in the list
            controller.filter = ContactGroupListController.FILTER_INACTIVE;
            controller.refreshGroupList();
            System.assertEquals(1, controller.groupList.size());


        //----------------------------------------------------------------
        // Test show and close popup
        //----------------------------------------------------------------
            controller.showPopUp();
            System.assertEquals(true, controller.displayConfirmationPopUp);
        
            controller.closeGroupPopup();
            System.assertEquals(false, controller.displayConfirmationPopUp);
        Test.stopTest();
    }

    /**
    * Test to get another contact group.
    * <p>
    * Change between records through Id and load corresponding object.
    *
    * (Related: IDALMSA-3198)
    */
    static testMethod void testSetContactGroup(){

        //create some contact groups
        List <ContactGroup__c> contactGroups = new List <ContactGroup__c>();
        for (Integer i = 0; i < 2; i++){
            contactGroups.add( new ContactGroup__c( Name = 'Contact Group Name ' + String.valueOf(i + 1) ) );
        }
        insert contactGroups;

        //load page controller
        ApexPages.Standardcontroller stdCtrl = new ApexPages.Standardcontroller(contactGroups[0]);
        ContactGroupListController ctrl = new ContactGroupListController(stdCtrl);
        Test.startTest();
            //change to other existing group
            ctrl.currentGroupId = contactGroups[1].Id;
        Test.stopTest();    
        //verify that othe group loads successfully.
        System.assertEquals(contactGroups[1].Id, ctrl.contactGroup.Id, 'The stored contact Id must be the same.');
    }


    /**
    * Test to fail getting active surveys by a restricted user.
    *
    * Permission Dependence to run. (Create Read Update Delete)
    * - ContactGroup__c                     "Groups"                (R---)
    * - ContactGroupSurveyAssignment__c     "Target"                (----)
    * - Survey__c                           "Surveys"               (R---)
    *
    * (Related: IDALMSA-3198)
    */
    static testMethod void testAvoidGetActiveSurvey() {

        List<ContactGroup__c> groups = new List<ContactGroup__c>();
        for (Integer i = 0; i < 3; i++) {
            groups.add(new ContactGroup__c(Name = 'Contact Group ' + i));
        }
        insert groups;

        List<Contact> contacts = TestUtils.createContacts(9);

        List<Survey__c> surveys = TestUtils.createSurveysNotInserted(8);
        insert surveys;

        List<Survey__c> activeSurveys = new List<Survey__c>();
        for(Integer i = 0; i < 7; i++){
            activeSurveys.add(
                new Survey__c(Status__c = SurveyDO.STATUS_PUBLISHED, Name='Active Survey ' + i)
            );
        }
        insert activeSurveys;

        // Publish all the versions of the Active Surveys
        List<SurveyVersion__c> activeSurveysVersions =
            [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c IN :activeSurveys];
        for (SurveyVersion__c version : activeSurveysVersions) {
            version.Status__c = SurveyDO.STATUS_PUBLISHED;
        }
        update activeSurveysVersions;

        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[0].Id, Contact__c = contacts[0].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[0].Id, Contact__c = contacts[1].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[0].Id, Contact__c = contacts[2].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[0].Id, Contact__c = contacts[3].Id));

        members.add(new ContactGroupMember__c(ContactGroup__c = groups[1].Id, Contact__c = contacts[4].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[1].Id, Contact__c = contacts[5].Id));

        members.add(new ContactGroupMember__c(ContactGroup__c = groups[2].Id, Contact__c = contacts[6].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[2].Id, Contact__c = contacts[7].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[2].Id, Contact__c = contacts[8].Id));
        insert members;

        List<ContactGroupSurveyAssignment__c> surveyAssignment = new List<ContactGroupSurveyAssignment__c>();
        // Group with only inactive surveys
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[0].Id, Survey__c = surveys[0].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[0].Id, Survey__c = surveys[1].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[0].Id, Survey__c = surveys[2].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[0].Id, Survey__c = surveys[3].Id));

        // Group with 4 inactive surveys and 3 active surveys
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = surveys[4].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = surveys[5].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = surveys[6].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = surveys[7].Id));

        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = activeSurveys[0].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = activeSurveys[1].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[1].Id, Survey__c = activeSurveys[2].Id));

        // Group with 4 active surveys
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[2].Id, Survey__c = activeSurveys[3].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[2].Id, Survey__c = activeSurveys[4].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[2].Id, Survey__c = activeSurveys[5].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[2].Id, Survey__c = activeSurveys[6].Id));
        insert surveyAssignment;

        ApexPages.StandardController stdController = new ApexPages.Standardcontroller(groups[0]);
        ContactGroupListController controller = new ContactGroupListController(stdController);

        //----------------------------------------------------------------
        // Test active survey count for current group and selection
        //----------------------------------------------------------------

        //create the restricted user
        Profile stdProf = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        User stdUser = TestUtils.getStandardUser();

        List <ContactGroupSurveyAssignment__c> assignments = new List <ContactGroupSurveyAssignment__c>();
        Test.startTest();
        System.RunAs(stdUser) {
        assignments = controller.getActiveSurvey();
        }
        Test.stopTest();

        System.assert(ApexPages.getMessages().size() > 0 , 'A message had to be generated');
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages().get(0).getSeverity(),
            'The level of error must be "' + ApexPages.Severity.ERROR + '"'
        );
        System.assertEquals(null, assignments, 'There shouldn\'t be any loaded assignment.');
    }

    static testMethod void testDeleteContactGroup() {

        //----------------------------------------------------------------
        // Initial data for testing
        //----------------------------------------------------------------

        List<ContactGroup__c> groups = new List<ContactGroup__c>();
        for(integer i=0; i<2; i++){
            groups.add(new ContactGroup__c(Name = 'Contact Group ' + i));
        }
        insert groups;

        List<Contact> contacts = new List<Contact>();
        for(integer i=0; i<2; i++){
            contacts.add(new Contact(FirstName='Contact ' + i, LastName='a'));
        }
        insert contacts;

        List<Survey__c> activeSurveys = new List<Survey__c>();
        for(integer i=0; i<2; i++){
            activeSurveys.add(new Survey__c(Status__c = SurveyDO.STATUS_PUBLISHED, Name='Active Survey ' + i));
        }
        insert activeSurveys;
        
        //Publish all the versions of the Active Surveys
        List<SurveyVersion__c> activeSurveysVersions = [select Status__c from SurveyVersion__c where Survey__c in :activeSurveys];
        for (SurveyVersion__c version:activeSurveysVersions){
            version.Status__c = SurveyDO.STATUS_PUBLISHED;
        }
        update activeSurveysVersions;

        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[0].Id, Contact__c = contacts[0].Id));
        members.add(new ContactGroupMember__c(ContactGroup__c = groups[0].Id, Contact__c = contacts[1].Id));
        insert members;

        List<ContactGroupSurveyAssignment__c> surveyAssignment = new List<ContactGroupSurveyAssignment__c>();
        // Group with only active surveys
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[0].Id, Survey__c = activeSurveys[0].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = groups[0].Id, Survey__c = activeSurveys[1].Id));
        insert surveyAssignment;


        ApexPages.StandardController stdController = new ApexPages.Standardcontroller(groups[0]);
        ContactGroupListController controller = new ContactGroupListController(stdController);


        //----------------------------------------------------------------
        // Test deletion of group with and without active surveys
        //----------------------------------------------------------------
        Test.startTest();
            // Delete the current contact group with active surveys (does not delete it, because it redirects to a confirmation page)
            controller.contactGroup = groups[0];
            ID idToDelete = groups[0].Id;
            controller.deleteGroupDirectly();
            System.assert([ SELECT c.Id FROM ContactGroup__c c WHERE c.Id =: idToDelete ].size() == 1, 'Error: the group should have not been deleted');

            // Delete the current contact group without active surveys
            controller.contactGroup = groups[1];
            idToDelete = groups[1].Id;
            controller.deleteGroupDirectly();
            System.assert([ SELECT c.Id FROM ContactGroup__c c WHERE c.Id =: idToDelete ].size() == 0, 'Error: the group should have been deleted');
                        
            // extra test to cover this function
            controller.dofilter();
            
        Test.stopTest();
        
    }
    
}
