/**
 * Controller for the Mobile User Detail custom page
 * The page will show the standard detail and a list of the assigned records
 * of the mobile user
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Ernesto Quesada - equesada@altimetrik.com
 */
public with sharing class MobileUserDetailController {

    public MobileUserDO.UserWrapper currentUser {get;set;}
    public List<SObjectAssignmentWrapper> assignedRecordsWrapper {get;set;}
    public String assignedObjectSelected {get;set;}

    /**
     * Constructor of the class
     */
    public MobileUserDetailController() {
        String idParam = ApexPages.CurrentPage().getParameters().get('id');

        if (String.isNotBlank(idParam)) {
            this.currentUser = MobileUserDO.getUserWrapper(idParam);
        }

        this.assignedRecordsWrapper = new List<SObjectAssignmentWrapper>();
    }

    /**
     * Get the SObjectAssignmentWrappers
     */
    public void getSObjectAssignmentWrappers() {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        Map<String, Decimal> recordsPerObject =
            SObjectContactAssociationDO.getNumberOfRecordsPerValidObject(currentUser.ContactId);
        List<String> orderedObjectNames = getOrderedAssignements(recordsPerObject.keySet());
        this.assignedRecordsWrapper =
            createAssignmentWrappers(recordsPerObject, orderedObjectNames);
    }

    /**
     * Create the assignment wrappers whilst ensuring that the objects still exist
     */
    private List<SObjectAssignmentWrapper> createAssignmentWrappers(
            Map<String, Decimal> recordsPerObject,
            List<String> orderedObjectNames
    ) {

        List<SObjectAssignmentWrapper> wrappers = new List<SObjectAssignmentWrapper>();
        for (String sobjectName : orderedObjectNames) {
            wrappers.add(new SObjectAssignmentWrapper(
                sobjectName,
                recordsPerObject.get(sobjectName)
            ));
        }
        return wrappers;
    }

    /**
     * Order a set into alphabetically ordered list
     * TODO - Add this to a list utilities class
     */
    private List<String> getOrderedAssignements(Set<String> setToOrder) {
        List<String> orderedObjectNames = new List<String>();
        orderedObjectNames.addAll(setToOrder);
        orderedObjectNames.sort();
        return orderedObjectNames;
    }

    /**
     * Delete an assignment
     */
    public void deleteAssignment() {
        GenericObjectCreator sObjectContactAssociationCreator =
            new GenericObjectCreator(SObjectContactAssociation__c.SObjectType);
        sObjectContactAssociationCreator.checkObjectAccessible();
        sObjectContactAssociationCreator.checkObjectDeletable();
        SObjectContactAssociationSelector selector = new SObjectContactAssociationSelector();
        SObjectContactAssociationDO.deleteAssignments(
            selector.getAllForContactAndObject(
                currentUser.ContactId,
                new List<String>{assignedObjectSelected}
            )
        );
    }
    /**
     * Class for that wraps all the instances of the SObjectContactAssociation__c
     */
    public class SObjectAssignmentWrapper{
        public String sobjectNameLabel {get;set;}
        public String sobjectNameApi {get;set;}
        public Integer numberOfAssociations {get;set;}

        /**
         * Constructor of the class
         * @param object Name of the object
         * @param records Sum up of the number of records of all Instances
         */
        public SObjectAssignmentWrapper(String sobjectName, Decimal numberOfAssociations) {
            this.sobjectNameLabel = DescribeHandler.getObjectLabel(sobjectName);
            this.sobjectNameApi = sobjectName;
            this.numberOfAssociations = Integer.valueOf(numberOfAssociations);
        }
    }
}
