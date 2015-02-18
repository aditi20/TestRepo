/**
 * This class contains unit tests for validating the behavior of ApplicationVersionSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public class ApplicationVersionSelectorTest {

    /**
     * Test method to verify fetching of Application Version records
     */
    static testMethod void validateFetchRecords() {
        ApplicationVersion__c applicationVersion =
            ApplicationVersionDomainTest.createRecord(
                DateTime.now().addDays(-1),
                '1.2.3', 
                'aUrl',
                true 
            );

        ApplicationVersionDomain domainInstance = new ApplicationVersionDomain();
        domainInstance.addRecord(applicationVersion);
        domainInstance.insertRecords();

        Test.startTest();
        List<ApplicationVersion__c> applicationVersionList = 
            new ApplicationVersionSelector().getRecords();
        Test.stopTest();

        System.assertEquals(1, applicationVersionList.size());
    }
}