/**
 * Utils class for the application settings
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 */
public with sharing class ApplicationSettingsUtils {

    // Static variables
    // Possible values for the Jobs filter
    public static final String JOBS_FILTER_ALL = 'ALL';
    public static final String JOBS_FILTER_SF_USER = 'SFUSER';
    public static final String JOBS_FILTER_NAME = 'jobFilterValue';

    /**
     * Get the instance of Settings record for the specified Name
     */
    public static Settings__c getInstanceWithName(String name) {
        return Settings__c.getInstance(name);
    }

    /**
     * Get the default Settings.
     * Will create it if it doesn't exist already on the org
     *
     * @param allowAddition - Flag to indicate if the setting can be created
     *
     * @return - The setting
     */
    public static Settings__c getDefaultSetting(Boolean allowAddition) {

        String settingName = Test.isRunningTest() ? 'Test' : 'Default';
        Settings__c setting = getInstanceWithName(settingName);
        if (setting == null && allowAddition) {
            setting = insertRecord(settingName, JOBS_FILTER_ALL, false);
        }
        return setting;
    }

    /**
     * Create a new Settings custom Setting record
     */
    public static Settings__c createRecord(
            String name,
            String filterBySalesforceUser,
            Boolean reCalculateJobTargets
    ) {
        Settings__c settingsInstance =
            new Settings__c(
                Name = name,
                FilterJobsBySalesforceUser__c = filterBySalesforceUser,
                ReCalculateJobTargets__c = reCalculateJobTargets
            );
        return settingsInstance;
    }

    /**
     * Insert a new Settings custom Setting record with specified parameters
     */
    public static Settings__c insertRecord(
            String name,
            String filterBySalesforceUser,
            Boolean reCalculateJobTargets
    ) {
        Settings__c settingsInstance =
            createRecord(
                name,
                filterBySalesforceUser,
                reCalculateJobTargets
            );
        insert settingsInstance;
        return settingsInstance;
    }

    /**
     * Create a new Settings custom Setting record for specified name
     */
    public static Settings__c createRecord(String name) {
        return new Settings__c(Name = name);
    }

    /**
     * Insert a new Settings custom Setting record for specified name
     */
    public static Settings__c insertRecord(String name) {
        Settings__c settingsInstance = createRecord(name);
        insert settingsInstance;
        return settingsInstance;
    }

    /**
     * Set the JobFiltering setting
     *
     * @param value - The new value for the setting
     */
    public static void setJobFilterSetting(String value) {
        Settings__c setting = getDefaultSetting(true);
        setting.FilterJobsBySalesforceUser__c = value;
        update setting;
    }

    /**
     * Check if the setting for job filtering is enable
     *
     * @return - True if the job filtering is enable
     */
    public static Boolean isJobFilterEnable() {
        return getDefaultSetting(true).FilterJobsBySalesforceUser__c.equals(
            ApplicationSettingsUtils.JOBS_FILTER_SF_USER
        );
    }

    /**
     * Set ReCalculateJobTarget
     *
     * @param value         - New value for the setting
     * @param allowAddition - Flag to indicate if the setting can be created
     *
     * @return - The setting
     */
    public static Settings__c setReCalculateJobTarget(Boolean value, Boolean allowAddition) {

        Settings__c setting = getDefaultSetting(allowAddition);
        setting.ReCalculateJobTargets__c = value;
        update setting;
        return setting;
    }

    /**
     * Check a setting matches a given String value
     *
     * @param fieldName  - The name of the field to be tested
     * @param testString - The string to test
     */
    public static Boolean validateSettingValue(String fieldName, String testString) {

        Settings__c setting = getDefaultSetting(true);
        String settingValue = String.valueOf(setting.get(fieldName));
        return settingValue.equals(testString);
    }
}