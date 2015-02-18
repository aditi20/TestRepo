/**
 * Selector class for the SObjectContactAssociation object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class SObjectContactAssociationSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return SObjectContactAssociation__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            SObjectContactAssociation__c.Id,
            SObjectContactAssociation__c.Name,
            SObjectContactAssociation__c.AssociatedIds__c,
            SObjectContactAssociation__c.Contact__c,
            SObjectContactAssociation__c.Instance__c,
            SObjectContactAssociation__c.NumberOfRecords__c,
            SObjectContactAssociation__c.SObjectApiName__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Return the default order by clause
     */
    public override String getDefaultOrderByClause() {
        return SObjectContactAssociation__c.SObjectApiName__c.getDescribe().getName();
    }

    /**
     * Get all the SObjectContactAssociations for a given contact
     */
    public List<SObjectContactAssociation__c> getAllForContact(Id contactId) {
        createContactWhereClause(contactId);
        return
            (List<SObjectContactAssociation__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Get all the SObjectContactAssociations for a given contact and sObject
     */
    public List<SObjectContactAssociation__c> getAllForContactAndObject(
            Id contactId,
            List<String> sObjectApiNames
    ) {
        this.createContactWhereClause(contactId);
        this.createSobjectApiNameWhereClause(sObjectApiNames);
        return
            (List<SObjectContactAssociation__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    private void createContactWhereClause(Id contactId) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                SObjectContactAssociation__c.Contact__c.getDescribe().getName(),
                SObjectSelector.EQUALS_OPERATOR,
                contactId
            )
        );
    }

    private void createSobjectApiNameWhereClause(List<String> sObjectApiNames) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                SObjectContactAssociation__c.SObjectApiName__c,
                SObjectSelector.IN_OPERATOR,
                sObjectApiNames
            )
        );
    }
}