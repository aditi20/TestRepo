/**
*   Grameen: Salesforce - Contact Group
*   Controller for the DeleteContactGroup page
*   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*   @author Alejandro De Gregorio
*/
public with sharing class DeleteContactGroupController {

    //---------------------------------------
    // Public properties
    //---------------------------------------
    public ContactGroup__c contactGroup {get; set;}                          // Current contact group
    public List<ContactGroupSurveyAssignment__c> activeSurvey {get; set;}    // List of active survey assignments
    public Integer activeMemberCount {get; set;}                             // Count of active member in the group
    public String errorMessage {get;set;}
    public Boolean isDeletable {get;set;}

    //---------------------------------------
    // Class contructor
    //---------------------------------------
    public DeleteContactGroupController(ApexPages.StandardController controller) {
        GenericObjectCreator contactGroupCreator =
            new GenericObjectCreator(ContactGroup__c.SObjectType);
        contactGroupCreator.checkObjectAccessible();
        contactGroupCreator.checkObjectDeletable();
        contactGroupCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            ContactGroup__c.Name
        });

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Survey__c.Name,
            Survey__c.PublishedDate__c,
            Survey__c.ResponseCount__c,
            Survey__c.Status__c
        });

        GenericObjectCreator contactGroupSurveyAssignmentCreator =
            new GenericObjectCreator(ContactGroupSurveyAssignment__c.SObjectType);
        contactGroupSurveyAssignmentCreator.checkObjectAccessible();
        contactGroupSurveyAssignmentCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                ContactGroupSurveyAssignment__c.ContactGroup__c,
                ContactGroupSurveyAssignment__c.Survey__c
            }
        );

        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Contact.mobilesurveys_Status__c
        });

        GenericObjectCreator contactGroupMemberCreator =
            new GenericObjectCreator(ContactGroupMember__c.SObjectType);
        contactGroupMemberCreator.checkObjectAccessible();
        contactGroupMemberCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            ContactGroupMember__c.Contact__c
        });

        this.contactGroup = (ContactGroup__c)controller.getRecord();
        isDeletable = Schema.sObjectType.ContactGroup__c.isDeletable();

        activeSurvey = [
            SELECT
                Id,
                Survey__r.Id,
                Survey__r.Name,
                Survey__r.PublishedDate__c,
                Survey__r.ResponseCount__c
            FROM
                ContactGroupSurveyAssignment__c
            WHERE
                ContactGroup__r.Id = :contactGroup.Id
                AND  Survey__r.Status__c = :SurveyDO.STATUS_PUBLISHED
        ];

        activeMemberCount = [
            SELECT
                Id
            FROM
                ContactGroupMember__c
            WHERE
                ContactGroup__r.Id = :contactGroup.Id
                AND  Contact__r.mobilesurveys_Status__c = 'Active'
        ].size();
    }

    // Delete the current contact group
    public PageReference deleteContactGroup() {
        if (isDeletable) {
            delete contactGroup;
        }
        return null;
    }
}