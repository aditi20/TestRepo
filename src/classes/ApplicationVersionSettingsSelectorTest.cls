/**
 * This class contains unit tests for validating the behavior of
 * ApplicationVersionSettingsSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public class ApplicationVersionSettingsSelectorTest {

    private static ApplicationVersionSettings__c applicationVersionSetting;

    /**
     * Test method to verify fetching of all ApplicationVersionSetting records
     */
    static testMethod void validateFetchRecords() {
        applicationVersionSetting = insertTestData();

        Test.startTest();
        List<ApplicationVersionSettings__c> applicationVersionSettingsList = 
            ApplicationVersionSettingsSelector.getRecords();
        Test.stopTest();

        System.assertEquals(
            1,
            applicationVersionSettingsList.size()
        );
    }

    /** 
     * Test method to verify fetching of records with is active checkbox as true/false
     */
    static testMethod void validateIsActiveRecords() {
        applicationVersionSetting = insertTestData();

        Test.startTest();
        List<ApplicationVersionSettings__c> applicationVersionSettingsList = 
            ApplicationVersionSettingsSelector.getActiveRecords();
        Test.stopTest();

        System.assertEquals(
            1,
            applicationVersionSettingsList.size()
        );

        System.assert(
            applicationVersionSettingsList[0].IsActive__c,
            'Record with isActive = true not present'
        );
    }

    /** 
     * Test method to verify fetching of records with Name as specified Version
     */
    static testMethod void validateRecordsWithVersion() {
        applicationVersionSetting = insertTestData();

        Test.startTest();
        ApplicationVersionSettings__c applicationVersionSettingsInstance = 
            ApplicationVersionSettingsSelector.getInstanceWithVersionNumber('123');
        Test.stopTest();

        System.assert(
            applicationVersionSettingsInstance != null,
            'Application Settings record should be created'
        );
    }

    /** 
     * Test method to verify fetching of records in sorted order
     */ 
    static testMethod void validateFetchingSortedRecords() {
       ApplicationVersionSettings__c version1 =
            createRecord(
                DateTime.now(),
                '123',
                'tesUrl',
                false,
                '1.8'
            );
        ApplicationVersionSettings__c version2 =
            createRecord(
                DateTime.now(),
                '124',
                'tesUrl1',
                true,
                '1.9'
            );
        insert new List<ApplicationVersionSettings__c> {version1, version2};

        Test.startTest();
        List<ApplicationVersionSettings__c> applicationVersionSettingsList = 
            ApplicationVersionSettingsSelector.getAllSortedRecords(
                ApplicationVersionSettings__c.MobileAPKVersion__c.getDescribe().getName(),
                'DESC'
            );
        Test.stopTest();

        // Records are sorted in descending order
        System.assertEquals(
            '1.9',
            applicationVersionSettingsList[0].MobileAPKVersion__c
        );
    }

    /**
     * Test method to verify creation of application version settings
     * record is done properly
     */
    static testMethod void validateCreateRecord() {
        Test.startTest();
        ApplicationVersionSettings__c applicationVersionSettings =
            new ApplicationVersionSettingsSelector().createRecord(
                '123', 
                '1.0',
                '1.0',
                'aUrl',
                '1.8',
                true
            );
        Test.stopTest();

        System.assert(
            applicationVersionSettings != null,
            'Application Version settings record not created properly'
        );
    }

        /**
     * Test method to verify set up data of  application version settings
     */
    static testMethod void testSetUpTestData() {
        Test.startTest();
        TestData testData = setUpTestData();
        Test.stopTest();

        verifyTestData(testData);
    }

    /**
     * Method to verify data is properly set up
     */
    public static void verifyTestData(TestData testData) {
        System.assert(
            testData != null,
            'Application Version settings record not created properly'
        );
        System.assertEquals(
            'downloadUrl',
            testData.downloadUrl
        );
        System.assertEquals(
            '1000',
            testData.versionNumber
        );
    }

    /**
     * Create new application version custom settings record
     */
    public static ApplicationVersionSettings__c createRecord(
            DateTime releaseDate,
            String versionNumber,
            String downloadUrl,
            Boolean isActive,
            String mobileAPKVersion
    ) {
        ApplicationVersionSettings__c version =
            new ApplicationVersionSettings__c(
                Name = versionNumber,
                ReleaseDate__c = releaseDate,
                DownloadUrl__c = downloadUrl,
                IsActive__c = isActive,
                CompatibleVersion__c = '1.0',
                OldestConfirmedVersion__c = '1.0',
                MobileAPKVersion__c = mobileAPKVersion
            );
        return version;
    }

    /** 
     * Method to create test data
     */
    public static ApplicationVersionSettings__c insertTestData() {
        applicationVersionSetting =
            ApplicationVersionSettingsSelectorTest.createRecord(
                DateTime.now().addDays(-1),
                '123', 
                'aUrl',
                true,
                '1.8'
            );

        insert applicationVersionSetting;
        return applicationVersionSetting;
    }

    /**
     * Create a default applicationVersionSettingsTestData to be used with tests
     */
    public static TestData setUpTestData() {
        return new TestData(
            '1000',
            '1.0',
            '1.0',
            'downloadUrl',
            '1.1.0'
        );
    }

    /**
     * Helper class to hold the data required to test application version creation
     */
    public class TestData {

        public String versionNumber;
        public String compatibleVersion;
        public String oldestVersion;
        public String downloadUrl;
        public String mobileApkVersion;

        public TestData(
                String versionNumber,
                String compatibleVersion,
                String oldestVersion,
                String downloadUrl,
                String mobileApkVersion
        ) {
            this.versionNumber = versionNumber;
            this.compatibleVersion = compatibleVersion;
            this.oldestVersion = oldestVersion;
            this.downloadUrl = downloadUrl;
            this.mobileApkVersion = mobileApkVersion;
        }
    }
}