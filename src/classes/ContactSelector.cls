/**
 * Selector class for the Contact object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
public with sharing class ContactSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return Contact.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            Contact.Id,
            Contact.mobilesurveys_Username__c,
            Contact.mobilesurveys_Password__c,
            Contact.mobilesurveys_Status__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Fetch all Contact records which have Name field as not null
     */
    public List<Contact> getAllWithNameNotNull() {
        this.createNameNotNullWhereClause();
        return (List<Contact>) runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Create where clause with survey Ids for main query of SurveyVersion object
     */
    private void createNameNotNullWhereClause() {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Contact.Name.getDescribe().getName(),
                SObjectSelector.NOT_EQUALS_OPERATOR,
                SObjectSelector.NULL_VALUE
            )
        );
    }
}