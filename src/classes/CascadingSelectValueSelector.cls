/**
 * Selector class for CascadingSelectValue__c
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class CascadingSelectValueSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return CascadingSelectValue__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField> {
            CascadingSelectValue__c.Id,
            CascadingSelectValue__c.Name,
            CascadingSelectValue__c.CascadingLevel__c,
            CascadingSelectValue__c.ControllingSelectValue__c,
            CascadingSelectValue__c.Value__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get all the values for given CascadingSelects
     */
    public List<CascadingSelectValue__c> getAllForCascadingSelect(Set<Id> cascadingSelectIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                new List<Schema.SObjectField> {
                    CascadingSelectValue__c.CascadingLevel__c,
                    CascadingLevel__c.CascadingSelect__c
                },
                SObjectSelector.IN_OPERATOR,
                cascadingSelectIds
            )
        );
        this.mainQueryBuilder.addRelationshipToSelect(
            new List<Schema.SObjectField> {
                CascadingSelectValue__c.ControllingSelectValue__c,
                CascadingSelectValue__c.Value__c
            }
        );
        return (List<CascadingSelectValue__c>)
            runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }
}