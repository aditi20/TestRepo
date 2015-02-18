/**
 * This class contains unit tests for validating the behavior of ApplicationVersionDomain
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public class ApplicationVersionDomainTest {

    /**
     * Test method to verify creation of application version is done properly
     */
    static testMethod void validateCreateRecords() {
        ApplicationVersion__c applicationVersion = 
            createRecord(
                DateTime.now().addDays(-1),
                '1.2.3', 
                'aUrl',
                true
            );

        System.assert(
            applicationVersion != null,
            'Application Version record not created properly'
        );
    }

    /**
     * Test method to verify insertion of application version is done properly
     */
    static testMethod void validateInsertRecords() {
        ApplicationVersion__c applicationVersion = 
            createRecord(
                DateTime.now().addDays(-1),
                '1.2.3', 
                'aUrl',
                true
            );

        Test.startTest();
        ApplicationVersionDomain applicationVersionDomainInstance =
            new ApplicationVersionDomain(); 
        applicationVersionDomainInstance.addRecord(applicationVersion);
        applicationVersionDomainInstance.insertRecords();
        Test.stopTest();

        List<ApplicationVersion__c> applicationVertsion =
            new ApplicationVersionSelector().getRecords();

        System.assertEquals(
            1,
            applicationVertsion.size()
        );
        System.assertEquals(
            applicationVersion.DownloadURL__c,
            applicationVertsion[0].DownloadURL__c
        );
    }

    /**
     * Create record for Application version 
     */
    public static ApplicationVersion__c createRecord(
            DateTime releaseDate,
            String versionNumber,
            String downloadUrl,
            Boolean isActive
    ) {
        ApplicationVersion__c version = new ApplicationVersion__c(
            Name = versionNumber,
            ReleaseDate__c = releaseDate,
            DownloadUrl__c = downloadUrl,
            IsActive__c = isActive,
            CompatibleVersion__c = '1.0',
            OldestConfirmedVersion__c = '1.0'
        );
        return version;
    }
}