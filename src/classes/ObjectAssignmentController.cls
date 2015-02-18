/*
 * Controller class for the Object Assignment page.
 * It enables the user to select records of an object and assign them to a
 * contact.
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Ernesto Quesada - equesada@altimetrik.com
 * @author Alejandro De Gregorio - adegregorio@altimetrik.com
 * @author Aditi Satpute
 */
public with sharing class ObjectAssignmentController {

    public static final String PARAM_CONTACT_ID = 'contactId';
    public static final String PARAM_OBJECT_NAME = 'objectName';
    public static final String PARAM_USER_ID = 'userId';


    public List<SelectOption> orgObjects {get; set;}
    public Contact contactToAssign {get; set;}
    public Id userId {get; set;}
    public String selectedObject {get; set;}
    public String associatedIds {get; set;}
    public Boolean isEdition {get; set;}

    private Set<String> alreadyAssignedObjects;

    /**
     * Class constructor
     */
    public ObjectAssignmentController() {
        processContactParameter();
        processObjectParameter();
        processUserIdParameter();
        this.alreadyAssignedObjects =
            SObjectContactAssociationDO.getAssignedObjectsForContact(this.contactToAssign.Id);
        loadOrgObjects();
    }

    /**
     * Process the parameter with the contact id
     */
    private void processContactParameter() {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        sObjectContactAssociationCreator.checkFieldsAccessible(
            new List<String> {
                'Name'
            }
        );
        Id contactId = ApexPages.CurrentPage().getParameters().get(PARAM_CONTACT_ID);
        String query =
            'SELECT ' +
                'Id, ' +
                'Name ' +
            'FROM ' +
                'Contact ' +
            'WHERE ' +
                'Id = \'' + String.escapeSingleQuotes(contactId) + '\'';

        List<Contact> foundContacts = (List<Contact>) Database.query(query);
        if (foundContacts.size() == 0) {
            throw new RecordAccessException(
                String.format(
                    System.Label.INSUFFICIENT_PRIVILEGES_ON_RECORD,
                    new List<String>{contactId}
                )
            );
        } else {
            this.contactToAssign = foundContacts[0];
        }
    }

    /**
     * Process the parameter with the object name to load the associated ids
     */
    private void processObjectParameter() {
        this.selectedObject = ApexPages.CurrentPage().getParameters().get(PARAM_OBJECT_NAME);

        if (this.selectedObject == null) {
            this.isEdition = false;
        } else {
            this.associatedIds = SObjectContactAssociationDO.getAllAssignedIdsForContactAndObject(
                this.contactToAssign.Id,
                this.selectedObject
            );
            this.isEdition = this.associatedIds.length() != 0;
        }
    }

    /**
     * Process the parameter with the user id
     */
    private void processUserIdParameter() {
        this.userId = ApexPages.CurrentPage().getParameters().get(PARAM_USER_ID);
        if (this.userId == null) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.ERROR,
                    System.Label.RECORDS_ASSIGNMENT_MISSING_USER_ID
                )
            );
        }
    }

    /**
     * Save the current Assignment Object
     */
    public PageReference save() {
        PageReference nextPage = null;

        if (propertiesAreValid()) {
            if (this.isEdition) {
                if (String.isNotBlank(this.associatedIds)) {
                    SObjectContactAssociationDO.updateAssignations(
                        this.contactToAssign.Id,
                        this.selectedObject,
                        associatedIds.split(',', 0)
                    );
                } else {
                    SObjectContactAssociationDO.unassignAllForContactAndObject(
                        this.contactToAssign.Id,
                        this.selectedObject
                    );
                }
            } else {
                insert SObjectContactAssociationDO.createNewRecords(
                    this.contactToAssign.Id,
                    selectedObject,
                    associatedIds.split(',', 0)
                );
            }

            nextPage = Page.MobileUserDetail;
            nextPage.getParameters().put('id', this.UserId);
            nextPage.setRedirect(true);
        }

        return nextPage;
    }

    /**
     * Check the values of the properties
     */
    private Boolean propertiesAreValid() {
        Boolean result = true;
        if (String.isBlank(this.selectedObject)) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.ERROR,
                    System.Label.RECORDS_ASSIGNMENT_SELECT_OBJECT_ERROR
                )
            );
            result = false;
        }

        if (!this.isEdition && String.isBlank(this.associatedIds)) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.severity.ERROR,
                    System.Label.RECORDS_ASSIGNMENT_NO_RECORDS_SELECTED_ERROR
                )
            );
            result = false;
        }

        return result;
    }

    /**
     * Get the records from a certain object that are not assigned
     *
     * @param objctName   - Sobject name to get all the records
     * @param assignedIds - A comma separated list of ids
     * @param filterData  - data to filter the query
     *
     * @return - A JSON with the non assigned records
     */
    @RemoteAction
    public static String getNonAssignedRecords(
            String objectName,
            String assignedIds,
            String filterData
    ) {
        List<FilterCondition> filters =
            (List<FilterCondition>) Json.deserialize(filterData, List<FilterCondition>.class);
        GenericObjectCreator creator =
            new GenericObjectCreator(DescribeHandler.getGlobalDescribe().get(objectName));
        creator.checkObjectAccessible();
        creator.checkFieldsAccessible(
            new List<String> {
                'Name'
            }
        );

        String query =
            'SELECT '+
                'Id, ' +
                'Name ' +
            'FROM ' +
                String.escapeSingleQuotes(objectName);

        query += buildWhereClause(assignedIds, filters);
        query += ' ' +
            'ORDER BY ' +
                'Name ' +
            'LIMIT 250';
        return JSON.serialize(Database.query(query));
    }

    /**
     * Build the where clause for the query
     */
    private static String buildWhereClause(String assignedIds, List<FilterCondition> filters) {
        String whereClause = '';
        List<String> clauses = new List<String>();

        // TODO: this should be generated for a list when adding multiple filters in another method
        if (!filters.isEmpty()) {
            clauses.addAll(getFilterClauses(filters));
        }
        if (String.isNotBlank(assignedIds)) {
            List<String> ids = assignedIds.split(',', 0);
            StringBuilder.InClauseBuilder inClauseBuilder =
                new StringBuilder.InClauseBuilder(ids);
            inClauseBuilder.setShouldEscapeSingleQuotes(true);
            clauses.add('Id NOT IN (' + inClauseBuilder.generateString() + ')');
        }

        if (clauses.size() != 0) {
            whereClause = ' WHERE ' + String.join(clauses, ' AND ');
        }
        return whereClause;
    }

    /**
     * Get the assigned records
     *
     * @param objctName   - Sobject name to get all the records
     * @param assignedIds - A comma separated list of ids
     *
     * @return - A JSON with the assigned records
     */
    @RemoteAction
    public static String getAssignedRecords(String objectName, String assignedIds) {
        GenericObjectCreator creator =
            new GenericObjectCreator(DescribeHandler.getGlobalDescribe().get(objectName));
        creator.checkObjectAccessible();
        creator.checkFieldsAccessible(
            new List<String> {
                'Name'
            }
        );
        StringBuilder.InClauseBuilder inClauseBuilder =
            new StringBuilder.InClauseBuilder(assignedIds.split(',', 0));
        inClauseBuilder.setShouldEscapeSingleQuotes(true);
        String query =
            'SELECT ' +
                'Id, ' +
                'Name ' +
            'FROM ' +
                String.escapeSingleQuotes(objectName) + ' ' +
            'WHERE ' +
                'Id IN (' + inClauseBuilder.generateString() + ') ' +
            'ORDER BY ' +
                'Name ';
        return JSON.serialize(DBFullAccess.querySObject(query));
    }

    /**
     * Return a list of clauses formed with a list of filterConditions
     * @param filters - the list of FilterConditions
     * @return - list of formed clauses
     */
    private static List<String> getFilterClauses(List<FilterCondition> filters) {
        List<String> clauses = new List<String>();
        for (FilterCondition filter : filters) {
            if (String.isNotBlank(filter.value) &&
                String.isNotBlank(filter.field)
            ) {
                clauses.add(
                    String.escapeSingleQuotes(filter.field) +
                    SObjectFilterConditionDO.operatorTranslations.get(filter.operator) +
                    ' \'' + String.escapeSingleQuotes(filter.value) +'\' '
                );
            }
        }
        return clauses;
    }

    /**
     * Get the available objects to assign this contact to
     */
    private void loadOrgObjects() {
        this.orgObjects = new List<SelectOption>();

        // Add dummy option
        this.orgObjects.add(new SelectOption('', '-'));

        // TODO: same method as surveyField mapping, centralize it some way
        for (String objectName : DescribeHandler.getGlobalDescribe().keySet()) {

            GenericObjectCreator creator = new GenericObjectCreator(objectName);
            if (creator.isObjectAccessible(false)) {
                if(canBeSelected(creator.objectType, creator.sObjectDescribe)) {
                    this.orgObjects.add(
                        new SelectOption(
                            creator.sObjectDescribe.getName(),
                            creator.sObjectDescribe.getLabel()
                        )
                    );
                }
            }
        }
    }

    /**
     * Check if the given object can be selected
     */
    @TestVisible
    private Boolean canBeSelected(
            Schema.SObjectType objectType,
            Schema.DescribeSObjectResult sObjectDescribe
    ) {
        return
            !C.hasNameSpacePrefix(objectType) &&
            (
                !this.alreadyAssignedObjects.contains(sObjectDescribe.getName()) ||
                this.isEdition && this.selectedObject == sObjectDescribe.getName()
            ) &&
            !sObjectDescribe.isCustomSetting() &&
            !isFeed(sObjectDescribe) &&
            !isHistory(sObjectDescribe);
    }

    private Boolean isFeed(Schema.DescribeSObjectResult sObjectDescribe) {
        return (
                sObjectDescribe.isCustom() &&
                sObjectDescribe.getName().toLowerCase().contains('__feed')
            ) ||
            (
                !sObjectDescribe.isCustom() &&
                sObjectDescribe.getName().toLowerCase().contains('feed')
            );
    }

    private Boolean isHistory(Schema.DescribeSObjectResult sObjectDescribe) {
        return (
                sObjectDescribe.isCustom() &&
                sObjectDescribe.getName().toLowerCase().contains('__history')
            ) ||
            (
            !sObjectDescribe.isCustom() &&
            sObjectDescribe.getName().toLowerCase().contains('history')
            );
    }

    /**
     * Class to wrap a filter data
     */
    public class FilterCondition {
        public String operator {get; set;}
        public String field {get; set;}
        public String value {get; set;}
    }
}
