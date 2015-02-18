/**
 * Selector class for the ApplicationVersion object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class ApplicationVersionSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return ApplicationVersion__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField> {
            ApplicationVersion__c.Id,
            ApplicationVersion__c.Name,
            ApplicationVersion__c.CompatibleVersion__c,
            ApplicationVersion__c.OldestConfirmedVersion__c,
            ApplicationVersion__c.ReleaseDate__c,
            ApplicationVersion__c.DownloadURL__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Fetch all records for Application Version
     */
    public List<ApplicationVersion__c> getRecords() {
        return
            (List<ApplicationVersion__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }


}