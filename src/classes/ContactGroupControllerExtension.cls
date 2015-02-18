/*
 *(c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class ContactGroupControllerExtension {

    // Current contact group
    public ContactGroup__c contactGroup {get; set;}

    // Lists for selected elements
    public List<Id> selectedMemberList {get; set;}
    public List<Id> selectedNonMemberList {get; set;}
    public List<Id> selectedUnassignedSurveyList {get; set;}
    public List<Id> selectedAssignedSurveyList {get; set;}

    // Cache of objects to add or remove when saving the group
    private Set<Contact> memberToAdd;
    private Set<Contact> memberToRemove;
    private Set<Survey__c> surveyToAdd;
    private Set<Survey__c> surveyToRemove;
    private ApexPages.StandardController stdController;

    // Constructor
    public ContactGroupControllerExtension(ApexPages.StandardController controller) {
        this.stdController = controller;
        this.contactGroup = (ContactGroup__c)controller.getRecord();
        this.memberToAdd = new Set<Contact>();
        this.memberToRemove = new Set<Contact>();
        this.surveyToAdd = new Set<Survey__c>();
        this.surveyToRemove = new Set<Survey__c>();
    }

    // Return the options for the non member list with contacts that aren't members
    public List<SelectOption> getNonMemberList() {
        try {
            GenericObjectCreator contactGroupMemberCreator =
                new GenericObjectCreator(ContactGroupMember__c.SObjectType);
            contactGroupMemberCreator.checkObjectAccessible();
            contactGroupMemberCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                ContactGroupMember__c.Contact__c
            });

            // Get the actual member list for the group
            Set<Id> memberIds = new Set<id>();
            for (ContactGroupMember__c contactGroupMemberInstance : [
                    SELECT
                        Contact__c
                    FROM
                        ContactGroupMember__c
                    WHERE
                        ContactGroup__r.Id = :this.contactGroup.Id
                ]
            ) {
                memberIds.add(contactGroupMemberInstance.Contact__c);
            }

            // Add the new member to the filter to avoid showing them in the non member list
            for (Contact contactToAdd : this.memberToAdd) {
                memberIds.add(contactToAdd.Id);
            }

            GenericObjectCreator contactCreator =
                new GenericObjectCreator(Contact.SObjectType);
            contactCreator.checkObjectAccessible();
            contactCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Contact.Name
            });

            // Get the non member contacts and create the options for the non member select
            List<SelectOption> nonMemberOptions = new List<SelectOption>();
            for (Contact contact : [
                    SELECT
                        Id,
                        Name
                    FROM
                        Contact
                    WHERE
                        Id NOT IN :memberIds
                        ORDER BY Name
                ]
            ) {
                nonMemberOptions.add(new SelectOption(contact.Id, contact.Name));
            }

            // Add options for the removed members for visual consistence
            for (Contact contactToRemove : memberToRemove) {
                nonMemberOptions.add(new SelectOption(contactToRemove.Id, contactToRemove.Name));
            }
            return nonMemberOptions;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    // Return the options of the members fo the group
    public List<SelectOption> getMemberList() {
        try{
            GenericObjectCreator contactGroupMemberCreator =
                new GenericObjectCreator(ContactGroupMember__c.SObjectType);
            contactGroupMemberCreator.checkObjectAccessible();
            contactGroupMemberCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                ContactGroupMember__c.Contact__c
            });
            GenericObjectCreator contactCreator =
                new GenericObjectCreator(Contact.SObjectType);
            contactCreator.checkObjectAccessible();
            contactCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Contact.Name
            });

            // Create a set with the id of the contacts to delete to filter the member list
            Set<Id> contactsToRemove = new Set<Id>();
            for (Contact contactToRemove : this.memberToRemove) {
                contactsToRemove.add(contactToRemove.Id);
            }

            // Create the options for the member select
            List<SelectOption> memberOptions = new List<SelectOption>();
            for (ContactGroupMember__c contactGroupMemberInstance : [
                    SELECT
                        Id,
                        Contact__r.Id,
                        Contact__r.Name
                    FROM
                        ContactGroupMember__c
                    WHERE
                        ContactGroup__r.Id = :contactGroup.Id
                        AND Contact__c NOT IN :contactsToRemove
                        ORDER BY Contact__r.Name
                ]
            ) {
                memberOptions.add(new SelectOption(
                    contactGroupMemberInstance.Contact__r.Id,
                    contactGroupMemberInstance.Contact__r.Name)
                );
            }

            // Add the new members to the select for visual consistence
            for (Contact contactToAdd : memberToAdd) {
                memberOptions.add(new SelectOption(contactToAdd.Id, contactToAdd.Name));
            }
            return memberOptions;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    // Return the options for the unassigned survey list
    public List<SelectOption> getUnassignedSurveyList() {
        try {
            GenericObjectCreator contactGroupSurveyAssignmentCreator =
                new GenericObjectCreator(ContactGroupSurveyAssignment__c.SObjectType);
            contactGroupSurveyAssignmentCreator.checkObjectAccessible();
            contactGroupSurveyAssignmentCreator.checkFieldsAccessible(
                new List<Schema.SObjectField> {
                    ContactGroupSurveyAssignment__c.ContactGroup__c,
                    ContactGroupSurveyAssignment__c.Survey__c
                }
            );
            GenericObjectCreator surveyCreator =
                new GenericObjectCreator(Survey__c.SObjectType);
            surveyCreator.checkObjectAccessible();
            surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Survey__c.Name
            });

            List<ContactGroupSurveyAssignment__c> surveyAssignments = [
                SELECT
                    Survey__r.Id
                FROM
                    ContactGroupSurveyAssignment__c
                WHERE
                    ContactGroup__r.Id = :contactGroup.Id
            ];

            // Convert the list to a set of ids to use as a filter in the query
            Set<Id> assignmentsIds = new Set<Id>();
            for (ContactGroupSurveyAssignment__c assignmentInstance : surveyAssignments) {
                assignmentsIds.add(assignmentInstance.Survey__r.Id);
            }

            // Add the new survey to the filter to avoid showing them in the unassigned survey list
            for (Survey__c survey : surveyToAdd) {
                assignmentsIds.add(survey.Id);
            }

            // Get the unassigned surveys and create the options for the unassigned survey select
            List<SelectOption> unassignedSurveyOptions = new List<SelectOption>();
            for (Survey__c survey : [
                    SELECT
                        Id,
                        Name
                    FROM
                        Survey__c
                    WHERE
                        Status__c IN (:SurveyDO.STATUS_PUBLISHED, :SurveyDO.STATUS_DRAFT)
                        AND Id NOT IN :assignmentsIds
                        AND IsTemplate__c = false
                ]
            ) {
                unassignedSurveyOptions.add(new SelectOption(survey.Id, survey.Name));
            }

            // Add the deleted survey to the list for visual consistence
            for (Survey__c survey : this.surveyToRemove) {
                unassignedSurveyOptions.add(new SelectOption(survey.Id, survey.Name));
            }

            return unassignedSurveyOptions;
        } catch (Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    /**
     * Return the options for the assigned survey list
     */
    public List<SelectOption> getAssignedSurveyList() {

        try {
            GenericObjectCreator contactGroupSurveyAssignmentCreator =
                new GenericObjectCreator(ContactGroupSurveyAssignment__c.SObjectType);
            contactGroupSurveyAssignmentCreator.checkObjectAccessible();
            contactGroupSurveyAssignmentCreator.checkFieldsAccessible(
                new List<Schema.SObjectField> {
                    ContactGroupSurveyAssignment__c.ContactGroup__c,
                    ContactGroupSurveyAssignment__c.Survey__c
                }
            );
            GenericObjectCreator surveyCreator =
                new GenericObjectCreator(Survey__c.SObjectType);
            surveyCreator.checkObjectAccessible();
            surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Survey__c.Name
            });

            // Create a set with the id of the surveys to delete to filter the list
            Set<Id> surveyToRemoveIds = new Set<Id>();
            for (Survey__c survey : this.surveyToRemove) {
                surveyToRemoveIds.add(survey.Id);
            }

            // Get the actual survey list for the group
            List<ContactGroupSurveyAssignment__c> assignmentsList = [
                SELECT
                    Survey__r.Id,
                    Survey__r.Name
                FROM
                    ContactGroupSurveyAssignment__c
                WHERE
                    ContactGroup__r.Id = :contactGroup.Id 
                    AND Survey__r.Id NOT IN :surveyToRemoveIds
            ];

            // Create the options for the assigned survey select
            List<SelectOption> assignedOptions = new List<SelectOption>();
            for (ContactGroupSurveyAssignment__c assignment : assignmentsList) {
                assignedOptions.add(new SelectOption(
                    assignment.Survey__r.Id,
                    assignment.Survey__r.Name
                ));
            }

            // Add the new assigned surveys to the select for visual consistence
            for (Survey__c survey : surveyToAdd) {
                assignedOptions.add(new SelectOption(survey.Id, survey.Name));
            }

            return assignedOptions;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    // Return the survey assignments for the group. Used only when group is inactive.
    public List<ContactGroupSurveyAssignment__c> getSurveyAssignments() {
        try {
            GenericObjectCreator contactGroupSurveyAssignmentCreator =
                new GenericObjectCreator(ContactGroupSurveyAssignment__c.SObjectType);
            contactGroupSurveyAssignmentCreator.checkObjectAccessible();
            contactGroupSurveyAssignmentCreator.checkFieldsAccessible(
                new List<Schema.SObjectField> {
                    ContactGroupSurveyAssignment__c.ContactGroup__c,
                    ContactGroupSurveyAssignment__c.Survey__c,
                    ContactGroupSurveyAssignment__c.DatePublishedToThisGroup__c
                }
            );
            GenericObjectCreator surveyCreator =
                new GenericObjectCreator(Survey__c.SObjectType);
            surveyCreator.checkObjectAccessible();
            surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Survey__c.Name,
                Survey__c.Alias__c
            });

            return [
                SELECT
                    Id,
                    Survey__r.Name,
                    Survey__r.Alias__c,
                    DatePublishedToThisGroup__c
                FROM
                    ContactGroupSurveyAssignment__c
                WHERE
                    ContactGroup__r.Id = :contactGroup.Id
            ];
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    // Add the selected contacts to the cache of members to add when saving the group
    public void addMember() {
        try {
            GenericObjectCreator contactCreator =
                new GenericObjectCreator(Contact.SObjectType);
            contactCreator.checkObjectAccessible();
            contactCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Contact.Name
            });

            memberToAdd.addAll([
                SELECT
                    Id,
                    Name
                FROM
                    Contact
                WHERE
                    Id IN :this.selectedNonMemberList
            ]);
            cleanMemberSets();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    // Add the selected contacts to the cache of members to remove when saving the group
    public void removeMember() {
        try {
            GenericObjectCreator contactCreator =
                new GenericObjectCreator(Contact.SObjectType);
            contactCreator.checkObjectAccessible();
            contactCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Contact.Name
            });

            memberToRemove.addAll([
                SELECT
                    Id,
                    Name
                FROM
                    Contact
                WHERE
                    Id IN :this.selectedMemberList
            ]);
            cleanMemberSets();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    // Add the selected survey to the cache of surveys to add when saving the group
    public void addSurvey() {
        try {
            GenericObjectCreator surveyCreator =
                new GenericObjectCreator(Survey__c.SObjectType);
            surveyCreator.checkObjectAccessible();
            surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Survey__c.Name
            });

            surveyToAdd.addAll([
                SELECT
                    Id,
                    Name
                FROM
                    Survey__c
                WHERE
                    Id IN :this.selectedUnassignedSurveyList
            ]);
            cleanSurveySets();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    // Add the selected surveys to the cache of surveys to remove when saving the group
    public void removeSurvey() {
        try {
            GenericObjectCreator surveyCreator =
                new GenericObjectCreator(Survey__c.SObjectType);
            surveyCreator.checkObjectAccessible();
            surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Survey__c.Name
            });

            surveyToRemove.addAll([
                SELECT
                    Id,
                    Name
                FROM
                    Survey__c
                WHERE
                    Id IN :this.selectedAssignedSurveyList
            ]);
            cleanSurveySets();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    /**
     * Save Group
     *
     * @return redirector PageReference      Redirect to Contact Group Page
     */
    public PageReference saveGroup() {
        // Manage validation
        try {
            // Verify object permission for Contact Group
            GenericObjectCreator contactGroupCreator =
                new GenericObjectCreator(ContactGroup__c.SObjectType);
            contactGroupCreator.checkObjectCreateable();
            contactGroupCreator.checkObjectUpdateable();

            // Save changes in the contact group information
            upsert contactGroup;

            // Verify object permission for Contact Group Member
            GenericObjectCreator contactGroupMemberCreator =
                new GenericObjectCreator(ContactGroupMember__c.SObjectType);

            List<ContactGroupMember__c> newCGMembers = new List <ContactGroupMember__c>();
            for (Contact contact : this.memberToAdd) {
                ContactGroupMember__c contactGroupMemberInstance =
                    (ContactGroupMember__c) contactGroupMemberCreator.createNewRecord();
                contactGroupMemberCreator.populateFields(
                    contactGroupMemberInstance,
                    new Map<Schema.SObjectField, Object>{
                        ContactGroupMember__c.Contact__c => contact.Id,
                        ContactGroupMember__c.ContactGroup__c => this.contactGroup.Id
                    }
                );
                newCGMembers.add(contactGroupMemberInstance);
            }
            contactGroupMemberCreator.checkObjectCreateable();
            contactGroupMemberCreator.checkObjectDeletable();
            upsert newCGMembers;

            // Delete the association objects of the removed member
            contactGroupMemberCreator.checkObjectDeletable();
            delete [
                SELECT
                    Id
                FROM
                    ContactGroupMember__c
                WHERE
                    Contact__c in :memberToRemove
            ];

            // Survey assignment can be changed only in active groups
            if (contactGroup.Status__c != C.SURVEYOR_STATUS_INACTIVE) {
                GenericObjectCreator contactGroupSurveyAssignmentCreator =
                    new GenericObjectCreator(ContactGroupSurveyAssignment__c.SObjectType);

                // Create the association object for the assigned surveys and save them
                List<ContactGroupSurveyAssignment__c> newCGSurveyAssignments =
                    new List<ContactGroupSurveyAssignment__c>();
                for (Survey__c survey : this.surveyToAdd) {
                    ContactGroupSurveyAssignment__c contactGroupSurveyAssignmentInstance =
                        (ContactGroupSurveyAssignment__c)
                            contactGroupSurveyAssignmentCreator.createNewRecord();
                    contactGroupSurveyAssignmentCreator.populateFields(
                        contactGroupSurveyAssignmentInstance,
                        new Map<Schema.SObjectField, Object>{
                            ContactGroupSurveyAssignment__c.Survey__c => survey.Id,
                            ContactGroupSurveyAssignment__c.ContactGroup__c => this.contactGroup.Id
                        }
                    );
                    newCGSurveyAssignments.add(contactGroupSurveyAssignmentInstance);
                }
                contactGroupSurveyAssignmentCreator.checkObjectCreateable();
                contactGroupSurveyAssignmentCreator.checkObjectDeletable();
                upsert newCGSurveyAssignments;

                // Delete the association object for the unassigned surveys
                contactGroupSurveyAssignmentCreator.checkObjectDeletable();
                delete [
                    SELECT
                        Id
                    FROM
                        ContactGroupSurveyAssignment__c
                    WHERE
                        Survey__c IN: surveyToRemove
                ];
            }
        } catch(Exception e) {
            ApexPages.Message auxMessage =
                new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(auxMessage);
            return null;
        }

        // Redirect to the group detail view
        String contactGroupSurveyAssignmentApiName =
            ContactGroupSurveyAssignment__c.SObjectType.getDescribe().getName();
        return new PageReference(
            '/' + contactGroup.Id + '?pkgprefix=' +
            DescribeHandler.getObjectDescribeResult(
                contactGroupSurveyAssignmentApiName, false
            ).getName()
        );
    }

    /**
     * Save Group and create new one.
     *
     * @return redirector PageReference      Redirect to Contact Group Page
     */
    public PageReference saveAndNew() {
        // Save as usual and redirect to blank edit
        PageReference resultPage = saveGroup();
        if (resultPage == null) {
            return resultPage;
        } else {
            // The URL for the new record page is the {org URL}/{3 letter object prefix}/e?"
            string reference = '/' + ('' + contactGroup.get('Id')).subString(0, 3) + '/e?';
            return new PageReference(reference);
        }
    }

    // Return the page reference to redirect on cancel
    public PageReference cancel() {
        return this.contactGroup.Id != null
            ? stdController.cancel()
            : Page.ContactGroupList;
    }

    // Remove the member added and removed
    private void cleanMemberSets() {
        for (Contact contact : this.memberToRemove) {
            if (this.memberToAdd.remove(contact)) {
                this.memberToRemove.remove(contact);
            }
        }
    }

    // Remove the survey added and removed
    private void cleanSurveySets() {
        for (Survey__c survey : this.surveyToRemove) {
            if (this.surveyToAdd.remove(survey)) {
                this.surveyToRemove.remove(survey);
            }
        }
    }
}