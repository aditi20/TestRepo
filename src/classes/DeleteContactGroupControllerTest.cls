/**
*  Grameen: Salesforce - Contact Group
*  This is the test class for the DeleteContactGroupController class
*   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*  @author  Alejandro De Gregorio
*/
@isTest
private class DeleteContactGroupControllerTest {

    static testMethod void testContactGroup() {

        ContactGroup__c group1 = new ContactGroup__c(Name = 'Contact Group 1');
        insert group1;

        List<Contact> contacts = new List<Contact>();
        for(integer i=0; i<4; i++){
            contacts.add(new Contact(FirstName='Contact ' + i, LastName='a'));
        }
        insert contacts;

        List<Survey__c> surveys = new List<Survey__c>();
        for(integer i=0; i<4; i++){
            surveys.add(new Survey__c(Status__c = SurveyDO.STATUS_DRAFT, Name='Survey ' + i));
        }
        insert surveys;

        List<Survey__c> activeSurveys = new List<Survey__c>();
        activeSurveys.add(new Survey__c(Name='Active Survey 1'));
        activeSurveys.add(new Survey__c(Name='Active Survey 2'));
        insert activeSurveys;

        // Actually activate Surveys
        SurveyDO.updateSurveysStatus(activeSurveys, SurveyDO.STATUS_PUBLISHED);
        List<ContactGroupMember__c> members = new List<ContactGroupMember__c>();
        for(integer i=0; i<4; i++){
            members.add(new ContactGroupMember__c(ContactGroup__c = group1.Id, Contact__c = contacts[i].Id));
        }
        insert members;

        List<ContactGroupSurveyAssignment__c> surveyAssignment = new List<ContactGroupSurveyAssignment__c>();
        // Insert inactive surveys
        for(integer i=0; i<4; i++){
            surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = group1.Id, Survey__c = surveys[i].Id));
        }

        // Insert active surveys
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = group1.Id, Survey__c = activeSurveys[0].Id));
        surveyAssignment.add(new ContactGroupSurveyAssignment__c(ContactGroup__c = group1.Id, Survey__c = activeSurveys[1].Id));
        insert surveyAssignment;

        ApexPages.StandardController stdController = new ApexPages.Standardcontroller(group1);
        DeleteContactGroupController controller = new DeleteContactGroupController(stdController);

        // Test the properties
        System.assertEquals(2, controller.activeSurvey.size());
        System.assertEquals(4, controller.activeMemberCount);
        
        Test.startTest();
            // Test that deleted the group and junction objects
            controller.deleteContactGroup();
        Test.stopTest();
        
        System.assertEquals(0, [select Id from ContactGroup__c where Id = :group1.Id].size());
        System.assertEquals(0, [select Id from ContactGroupMember__c where ContactGroup__r.Id = :group1.Id].size());
        System.assertEquals(0, [select Id from ContactGroupSurveyAssignment__c where ContactGroup__r.Id = :group1.Id].size());
    }
}