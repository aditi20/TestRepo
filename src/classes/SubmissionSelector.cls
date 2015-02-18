/**
 * Selector class for the Submission object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
public with sharing class SubmissionSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return Submission__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField> {
            Submission__c.Id,
            Submission__c.Name,
            Submission__c.PPIScore__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

}