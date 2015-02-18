/**
 * Grameen: Salesforce - Contact Group Manager
 * Controller for the ContactGroupList page
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio
 */
public with sharing class ContactGroupListController {

    // Constants
    public static final String FILTER_ALL = 'All';
    public static final String FILTER_ACTIVE = 'Active';
    public static final String FILTER_INACTIVE = 'Inactive';
    public static final Integer MAX_ROWS_PER_PAGE = 20;

    public Map<String,String> statusGroup {
        get {
            return
                C.getPickListMap(Schema.SObjectType.ContactGroup__c.fields.Status__c);
        }
        set;
    }

    // Public properties
    public ContactGroup__c contactGroup {get; set;}              // Current contact group
    public String currentGroupId {
        get;
        set {
            try {
                GenericObjectCreator contactGroupCreator =
                    new GenericObjectCreator(ContactGroup__c.SObjectType);
                contactGroupCreator.checkObjectAccessible();
                currentGroupId = value;

                this.contactGroup = [
                    SELECT
                        Id
                    FROM
                        ContactGroup__c
                    WHERE
                        Id = :currentGroupId
                ];
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }
    }
    // Groups to show in the table of the page
    public List<ContactGroup__c> groupList {
        get {
            return (List<ContactGroup__c>) paginator.getRecords();
        }
        set;
    }

    public String selectedGroupIds {get; set;}                   // String with the ids of the selected groups (comma separated)

    // Flags
    public boolean displayConfirmationPopUp {get; set;}          // Indicate whether the confirmation popup should be displayed or not
    public boolean targetIsSelection {get; set;}                 // Indicate whether the target of the action is a selection or not

    // Filter properties
    public List<SelectOption> filterList {get; set;}             // Options for the filter select list
    public String filter {get; set{                              // The actual filter value
        if (value == null || String.isBlank(value.trim())
                || String.escapeSingleQuotes(value).contains('\\')){
            filter = FILTER_ALL;
        } else {
            filter = value;
        }
    }}

    private String previousSortField;                             // Indicate the previous sort column
                                                                  // ^(used to check if have to change the order on the same column)
    public String tableOrderColumn {get; set{                     // Indicate the column to sort the records (should be a field name)
        if (value == null || String.isBlank(value.trim())
                || String.escapeSingleQuotes(value).contains('\\') ){
            tableOrderColumn = 'LastModifiedDate';
        } else {
            tableOrderColumn = value.trim() ;
        }
        // Set the previous field
        previousSortField = tableOrderColumn;
    }}

    private String sortOrder;                                      // Indicate the order for the rows

    // Pagination property
    public ApexPages.StandardSetController paginator{get;set;}


    //---------------------------------------
    // Class contructor
    //---------------------------------------
    public ContactGroupListController(ApexPages.StandardController controller) {
        this.targetIsSelection = false;
        this.displayConfirmationPopUp = false;
        this.tableOrderColumn = 'LastModifiedDate';
        this.sortOrder = 'desc';
        this.contactGroup = (ContactGroup__c)controller.getRecord();
        this.filter = FILTER_ALL;
        this.filterList = new List<SelectOption>{
            new SelectOption(FILTER_ALL, system.Label.ALL),
            new SelectOption(FILTER_ACTIVE, statusGroup.get(FILTER_ACTIVE)),
            new SelectOption(FILTER_INACTIVE, statusGroup.get(FILTER_INACTIVE))
        };
        this.groupList = new List<ContactGroup__c>();
        refreshGroupList();
    }

    // Return the active surveys for the current or selected active groups
    public List<ContactGroupSurveyAssignment__c> getActiveSurvey() {
        try {
            GenericObjectCreator surveyCreator =
                new GenericObjectCreator(Survey__c.SObjectType);
            surveyCreator.checkObjectAccessible();
            surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                Survey__c.Name,
                Survey__c.PublishedDate__c,
                Survey__c.ResponseCount__c
            });
            GenericObjectCreator contactGroupCreator =
                new GenericObjectCreator(ContactGroup__c.SObjectType);
            contactGroupCreator.checkObjectAccessible();
            contactGroupCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                ContactGroup__c.Status__c
            });
            GenericObjectCreator contactGroupSurveyAssignmentCreator =
                new GenericObjectCreator(ContactGroupSurveyAssignment__c.SObjectType);
            contactGroupSurveyAssignmentCreator.checkObjectAccessible();
            contactGroupSurveyAssignmentCreator.checkFieldsAccessible(
                new List<Schema.SObjectField> {
                    ContactGroupSurveyAssignment__c.Survey__c
                }
            );

            if (this.targetIsSelection) {
                String[] groupIds = this.selectedGroupIds.split(',');
                return [
                    SELECT
                        Id,
                        Survey__r.Id,
                        Survey__r.Name,
                        Survey__r.PublishedDate__c,
                        Survey__r.ResponseCount__c
                    FROM
                        ContactGroupSurveyAssignment__c
                    WHERE
                        ContactGroup__c IN :groupIds
                        AND Survey__r.Status__c = :SurveyDO.STATUS_PUBLISHED
                        AND ContactGroup__r.Status__c = 'Active'
                ];
            } else {
                return [
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
                        AND Survey__r.Status__c = :SurveyDO.STATUS_PUBLISHED
                        AND ContactGroup__r.Status__c = 'Active'
                ];
            }
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }


    //---------------------------------------
    // PopUp methods
    //---------------------------------------

    public void showPopUp(){
        displayConfirmationPopUp = true;
    }

    public void closeGroupPopup(){
        displayConfirmationPopUp = false;
    }

    // Activate the selected contact groups
    public void activateGroup() {
        try {
            GenericObjectCreator contactGroupCreator =
                new GenericObjectCreator(ContactGroup__c.SObjectType);
            contactGroupCreator.checkObjectAccessible();
            contactGroupCreator.checkObjectUpdateable();
            contactGroupCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                ContactGroup__c.Status__c
            });

            if (this.targetIsSelection) {
                String[] groupIds = this.selectedGroupIds.split(',');
                List<ContactGroup__c> groupList = [
                    SELECT
                        Id
                    FROM
                        ContactGroup__c
                    WHERE
                        Id IN :groupIds
                ];
                for (ContactGroup__c contactGroup : groupList) {
                    contactGroupCreator.populateFields(
                        contactGroup,
                        new Map<Schema.SObjectField, Object> {
                            ContactGroup__c.Status__c => FILTER_ACTIVE
                        }
                    );
                }
                update groupList;
            } else {
                contactGroupCreator.populateFields(
                    this.contactGroup,
                    new Map<Schema.SObjectField, Object> {
                        ContactGroup__c.Status__c => FILTER_ACTIVE
                    }
                );
                update contactGroup;
            }
            refreshGroupList();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    // Inactivate the selected contact groups
    public void inactivateGroup() {
        try {
            GenericObjectCreator contactGroupCreator =
                new GenericObjectCreator(ContactGroup__c.SObjectType);
            contactGroupCreator.checkObjectAccessible();
            contactGroupCreator.checkObjectUpdateable();
            contactGroupCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                ContactGroup__c.Status__c
            });

            // Inactivate selection
            if (this.targetIsSelection) {
                String[] groupIds = this.selectedGroupIds.split(',');
                List<ContactGroup__c> selectedGroupList = [
                    SELECT
                        Id
                    FROM
                        ContactGroup__c
                    WHERE
                        Id IN :groupIds
                ];
                for (ContactGroup__c contactGroup : selectedGroupList) {
                    contactGroupCreator.populateFields(
                        contactGroup,
                        new Map<Schema.SObjectField, Object> {
                            ContactGroup__c.Status__c => FILTER_INACTIVE
                        }
                    );
                }
                update selectedGroupList;
            } else {
                // Inactivate current contact group
                contactGroupCreator.populateFields(
                    this.contactGroup,
                    new Map<Schema.SObjectField, Object> {
                        ContactGroup__c.Status__c => FILTER_INACTIVE
                    }
                );
                update contactGroup;
            }

            this.displayConfirmationPopUp = false;
            refreshGroupList();
        }
        catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    // Set the order and refresh the list
    public void doSort() {
        this.sortOrder =
            (this.previousSortField == this.tableOrderColumn && this.sortOrder == 'desc')
                ? 'asc' : 'desc';
        refreshGroupList();
    }

    // Apply the filter to the list
    public void doFilter() {
        // Any time a filter is applyed must show the first page
        this.paginator.setPageNumber(1);
        refreshGroupList();
    }

    // Refresh the contact group list
    public void refreshGroupList() {

        try {
            GenericObjectCreator contactGroupCreator =
                new GenericObjectCreator(ContactGroup__c.SObjectType);
            contactGroupCreator.checkObjectAccessible();
            contactGroupCreator.checkObjectDeletable();
            contactGroupCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                ContactGroup__c.Name,
                ContactGroup__c.MemberCount__c,
                ContactGroup__c.SurveyCount__c,
                ContactGroup__c.Status__c
            });

            // Basic query
            String queryString =
                'SELECT Id, Status__c, Name, MemberCount__c, SurveyCount__c, ' +
                    'LastModifiedDate, CreatedDate, CreatedById FROM ContactGroup__c';

            // Add filter to the query
            if (this.filter != FILTER_ALL) {
                queryString = queryString + ' WHERE Status__c = \''
                    + String.escapeSingleQuotes(this.filter) + '\'';
            }

            // Set the order
            queryString =
                queryString + ' ORDER BY ' + this.tableOrderColumn + ' ' + this.sortOrder;

            // Setup the pagination controller
            Integer oldPageNumber = 1;
            if (this.paginator != null) oldPageNumber = this.paginator.getPageNumber();
            this.paginator = new ApexPages.StandardSetController(Database.query(queryString));
            this.paginator.setPageSize(MAX_ROWS_PER_PAGE);
            this.paginator.setPageNumber(oldPageNumber);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() ) );
        }
    }

    // Delete the contact group
    // if the contact group does not have any surveys assigned, then it's deleted directly
    // if the contact group has surveys assigned, then it's redirected to a confirmation page.
    public PageReference deleteGroupDirectly() {
        GenericObjectCreator contactGroupSurveyAssignmentCreator =
            new GenericObjectCreator(ContactGroupSurveyAssignment__c.SObjectType);
        contactGroupSurveyAssignmentCreator.checkObjectAccessible();

        List<ContactGroupSurveyAssignment__c> activeSurvey = [
            SELECT
                Id
            FROM
                ContactGroupSurveyAssignment__c
            WHERE
                ContactGroup__r.Id = :contactGroup.Id
                AND Survey__r.Status__c = :SurveyDO.STATUS_PUBLISHED
        ];

        if (activeSurvey.size() == 0) {
            // Delete the group because it does not have any surveys assigned
            contactGroupSurveyAssignmentCreator.checkObjectDeletable();
            delete contactGroup; 
            PageReference groupDelPage2 = Page.ContactGroupList;
            groupDelPage2.setRedirect(true);
            return groupDelPage2;
        }

        // There are surveys assigned, so first display the list of surveys assigned
        // to confirm what the user wants to do
        PageReference groupDelPage = Page.DeleteContactGroup;
        groupDelPage.getParameters().put('id', contactGroup.Id);
        groupDelPage.setRedirect(true);
        return groupDelPage;
    }
}
