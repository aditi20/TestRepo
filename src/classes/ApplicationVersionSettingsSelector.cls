/**
 * Selector class for the ApplicationVersion Custom Settings
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 * 
 * @author Aditi Satpute
 */
public with sharing class ApplicationVersionSettingsSelector {

    /**
     * Get all ApplicationVersionSetting records
     */
    public static List<ApplicationVersionSettings__c> getRecords() {
        return ApplicationVersionSettings__c.getAll().values();
    }

    /**
     * Get the list of active ApplicationVersionSettings__c
     */
    public static List<ApplicationVersionSettings__c> getActiveRecords() {
        return getActiveRecords(ApplicationVersionSettings__c.getAll().values());
    }

    public static List<ApplicationVersionSettings__c> getActiveRecords(
            List<ApplicationVersionSettings__c> versions
    ) {
        List<ApplicationVersionSettings__c> applicationVersionSettingsList =
            new List<ApplicationVersionSettings__c>();
        for (ApplicationVersionSettings__c applicationVersionSettings : versions) {
            if (applicationVersionSettings.IsActive__c) {
                applicationVersionSettingsList.add(applicationVersionSettings);
            }
        }
        return applicationVersionSettingsList;
    }

    /**
     * Get the instance of ApplicationVersionSettings record for the specified version number
     */
    public static ApplicationVersionSettings__c getInstanceWithVersionNumber(String versionNumber) {
        return ApplicationVersionSettings__c.getInstance(versionNumber);
    }

    /**
     * Get the list of ApplicationVersionSettings records sorted with specified 
     * field name and sort direction
     */
    public static List<ApplicationVersionSettings__c> getAllSortedRecords(
            String sortfieldName,
            String sortDirection
    ) {
        String queryString = getQueryString() + getOrderByString(sortfieldName, sortDirection);
        return DBFullAccess.querySObject(queryString);
    }

    /**
     * Get default base query string
     *
     * @return - Base query string
     */
    private static String getQueryString() {
        return
            'SELECT ' +
                getSelectClauseString() + ' ' +
            'FROM ' +
                'ApplicationVersionSettings__c ';
    }

    /**
     * Get the select clause as a joined string
     *
     * @return - A comma seperated string of all the fields needed in the select clause for
     *             the query to get the data for this object
     */
    public static String getSelectClauseString() {
        List<String> allFieldsList = new List<String>();
        allFieldsList.addAll(getSelectClauseFields());
        return String.join(allFieldsList, ',');
    }

    /**
     * Get default select clause fields
     *
     * @return - A set of string with all fields needed for select clause
     */
    private static Set<String> getSelectClauseFields() {
        Set<String> allFields = new Set<String>();
        allFields.addAll(
            new List<String>{
                'Id',
                'ReleaseDate__c',
                'CompatibleVersion__c',
                'OldestConfirmedVersion__c',
                'DownloadURL__c',
                'MobileAPKVersion__c',
                'IsActive__c',
                'Name'
            }
        );
        return allFields;
    }

    /**
     * Get order by clause
     *
     * @return - Order by string based on field name and sort direction
     */
    private static String getOrderByString(String sortfieldName, String sortDirection) {
        return 'ORDER BY ' + sortfieldName + ' ' + sortDirection;
    }

    /**
     * Create a new application version custom Setting record
     */
    public ApplicationVersionSettings__c createRecord(
            String versionNumber,
            String compatibleVersion,
            String oldestVersion,
            String downloadUrl,
            String mobileAPKVersion,
            Boolean isVersionActive
    ) {
        ApplicationVersionSettings__c version =
            new ApplicationVersionSettings__c(
                Name = versionNumber,
                CompatibleVersion__c = compatibleVersion,
                OldestConfirmedVersion__c = oldestVersion,
                DownloadUrl__c = downloadUrl,
                MobileAPKVersion__c = mobileAPKVersion,
                ReleaseDate__c = DateTime.now(),
                IsActive__c = isVersionActive
            );
        return version;
    }
}