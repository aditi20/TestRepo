/**
 * Selector class for the Organization object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 * @author - Aditi Satpute
 */
public with sharing class OrganizationSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return Organization.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            Organization.Id,
            Organization.Name
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get Default Organization
     */
    public List<Organization> getDefault() {
        this.mainQueryBuilder.setLimitAmount(1);
        return
            (List<Organization>) runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }
}