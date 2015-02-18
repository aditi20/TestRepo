/**
 * Domain class for the SubmissionPpiAssociation object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class SubmissionPpiAssociationDomain extends SObjectDomain {

    public SubmissionPpiAssociationDomain() {
        super(SubmissionPpiAssociation__c.SObjectType);
    }

    public SubmissionPpiAssociationDomain(List<SubmissionPpiAssociation__c> sObjects) {
        super(sObjects);
    }

    /**
     * Method to create Submission Ppi Association Record
     */
    public static SubmissionPpiAssociation__c createRecord(
            PpiResult__c ppiResult,
            PPITableLine__c tableLine
    ) {
        GenericObjectCreator submissionPpiDataCreator =
            new GenericObjectCreator(SubmissionPpiAssociation__c.SObjectType);
        submissionPpiDataCreator.checkObjectAccessible();
        submissionPpiDataCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SubmissionPpiAssociation__c.PpiResult__c,
                SubmissionPpiAssociation__c.PpiTableLine__c
            }
        );

        SubmissionPpiAssociation__c newSubmissionPpiDataInstance =
            (SubmissionPpiAssociation__c) submissionPpiDataCreator.createNewRecord();
        submissionPpiDataCreator.populateFields(
            newSubmissionPpiDataInstance,
                new Map<Schema.SObjectField, Object>{
                    SubmissionPpiAssociation__c.PpiResult__c => ppiResult.Id,
                    SubmissionPpiAssociation__c.PpiTableLine__c => tableLine.Id
                }
            );
        return newSubmissionPpiDataInstance;
    }

    /**
     * Method to link Submission record to calculated SubmissionPpiAssociations for
     * newly created PpiResult records
     */
    public void setSubmissionIdForPpiAssociations(
            PpiResult__c ppiResultInstance,
            Id submissionId
    ) {
        GenericObjectCreator submissionPpiAssociationCreator =
                new GenericObjectCreator(SubmissionPpiAssociation__c.SObjectType);
        submissionPpiAssociationCreator.checkObjectAccessible();
        submissionPpiAssociationCreator.checkObjectUpdateable();
        submissionPpiAssociationCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            SubmissionPpiAssociation__c.Submission__c
        });
        List<SubmissionPpiAssociation__c> ppiAssociationsToUpdate =
            new List<SubmissionPpiAssociation__c>();

        for (SubmissionPpiAssociation__c ppiAssociationInstance :
                new SubmissionPpiAssociationSelector().getForPpiResult(
                    new Set<String> {ppiResultInstance.Id}
                )
        ) {
            submissionPpiAssociationCreator.populateField(
                ppiAssociationInstance,
                SubmissionPpiAssociation__c.Submission__c,
                submissionId
            );
            ppiAssociationsToUpdate.add(ppiAssociationInstance);
        }

        this.addRecords(ppiAssociationsToUpdate);
        this.updateRecords();
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public SubmissionPpiAssociationDomain constructWithRecords(List<SObject> sObjectList) {
            return new SubmissionPpiAssociationDomain(sObjectList);
        }
        public SubmissionPpiAssociationDomain constructEmpty() {
            return new SubmissionPpiAssociationDomain ();
        }
    }
}