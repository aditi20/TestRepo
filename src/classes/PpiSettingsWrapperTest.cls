/**
 * Test class for validating the PpiSettingsWrapper class
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 * 
 * @author - Aditi Satpute
 */
@isTest
public class PpiSettingsWrapperTest {

    public static final String ACCOUNT_API_NAME =
        Account.sObjectType.getDescribe().getName();
    public static final String LEAD_API_NAME =
        Lead.sObjectType.getDescribe().getName();

    /**
     * Test method to verify creation of PpiSettings record is done properly
     */
    static testMethod void testCreateRecord() {
        Test.startTest();
        PpiSettings__c ppiSettings = PpiSettingsWrapper.createRecord(
            ACCOUNT_API_NAME,
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Site.getName(),
            '',
            '',
            ''
        );
        Test.stopTest();

        System.assert(
            ppiSettings != null,
            'Ppi settings record not created properly'
        );
    }

    static testMethod void testCreateDemographicDataQuery() {
        PpiSettings__c ppiSettings = PpiSettingsWrapper.insertRecord(
            ACCOUNT_API_NAME,
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Name.getName(),
            '',
            '',
            ''
        );

        PpiSettings__c ppiSettingsRecord = PpiSettingsWrapper.getRecordForName(ACCOUNT_API_NAME);
        System.assert(
            ppiSettingsRecord != null,
            'PpiSettings record not found for : ' + ACCOUNT_API_NAME
        );

        Survey__c surveyInstance = SurveyDOTest.createInsertedSurvey();
        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(
                new Set<String> {
                    surveyInstance.Id
                }
            );
        System.assert(surveyVersions.size() > 0);
        PpiResultDomain.PpiResultWrapper ppiResultWrapper =
            new PpiResultDomain.PpiResultWrapper(surveyVersions[0].Id);
        ppiResultWrapper.clientId = 'Test Name';
        Test.startTest();
        String demographicQuery =
            PpiSettingsWrapper.createDemographicDataQuery(ppiSettings, ppiResultWrapper);
        Test.stopTest();

        // Create Test Account data that can be verified with demographic data
        Account accountRecord = AccountDomainTest.createRecord('Test Name', 10, '', '');
        AccountDomain accountDomain = new AccountDomain();
        accountDomain.addRecord(accountRecord);
        accountDomain.insertRecords();
        System.assert(accountDomain.records.size() > 0);
        System.assert(accountDomain.records[0].Id != null);

        List<Sobject> demographicMappingData = DBFullAccess.querySObject(demographicQuery);
        System.assert(demographicMappingData != null);
        System.assert(demographicMappingData.size() == 1);
        System.assertEquals(
            'Test Name',
            demographicMappingData[0].get(Schema.sObjectType.Account.fields.Name.getName())
        );
        System.assertEquals(
            10,
            demographicMappingData[0].get(
                Schema.sObjectType.Account.fields.NumberOfEmployees.getName()
            )
        );
    }

    /**
     * Test method to verify fetching Ppisettings record for specified Name
     */
    static testMethod void testGetRecordForCustomSettingName() {
        PpiSettings__c ppiSettings = PpiSettingsWrapper.insertRecord(
            ACCOUNT_API_NAME,
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Site.getName(),
            '',
            '',
            ''
        );

        Test.startTest();
        PpiSettings__c ppiSettingsRecord =
            PpiSettingsWrapper.getRecordForName(ACCOUNT_API_NAME);
        Test.stopTest();

        System.assert(
            ppiSettingsRecord != null,
            'Could not find the PpiSettings record for the specified name :' + ACCOUNT_API_NAME
        );
    }

    /**
     * Test method to verify fetching Ppisettings all records 
     */
    static testMethod void testGetAllRecords() {
        List<PpiSettings__c> ppiSettingsList = new List<PpiSettings__c>();
        ppiSettingsList.add(PpiSettingsWrapper.insertRecord(
            ACCOUNT_API_NAME,
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Site.getName(),
            '',
            '',
            ''
        ));
        ppiSettingsList.add(PpiSettingsWrapper.insertRecord(
            LEAD_API_NAME,
            Schema.sObjectType.Lead.fields.Title.getName(),
            Schema.sObjectType.Lead.fields.Industry.getName(),
            '',
            '',
            ''
        ));

        Test.startTest();
        List<PpiSettings__c> ppiSettingsRecordList = PpiSettingsWrapper.getAllRecords();
        Test.stopTest();

        System.assertEquals(2, ppiSettingsRecordList.size());
    }

    /**
     * Test method to verify creation of Map for all existing Ppisettings records
     */
    static testMethod void testGetAllRecordsMap() {
        List<PpiSettings__c> ppiSettingsList = new List<PpiSettings__c>();
        ppiSettingsList.add(PpiSettingsWrapper.insertRecord(
            ACCOUNT_API_NAME,
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Site.getName(),
            '',
            '',
            ''
        ));
        ppiSettingsList.add(PpiSettingsWrapper.insertRecord(
            LEAD_API_NAME,
            Schema.sObjectType.Lead.fields.Title.getName(),
            Schema.sObjectType.Lead.fields.Industry.getName(),
            '',
            '',
            ''
        ));

        Test.startTest();
        Map<String, PpiSettings__c> ppiSettingsRecordMap = PpiSettingsWrapper.getAllRecordsMap();
        Test.stopTest();

        System.assertEquals(2, ppiSettingsRecordMap.size());
    }

    /**
     * Test method to verify fetching of field value for specified PpiSetting and field
     */
    static testMethod void testGetFieldValue() {
        PpiSettings__c ppiSettings = PpiSettingsWrapper.insertRecord(
            ACCOUNT_API_NAME,
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Site.getName(),
            '',
            '',
            ''
        );
        PpiSettings__c ppiSettingsRecord = PpiSettingsWrapper.getRecordForName(ACCOUNT_API_NAME);
        System.assert(
            ppiSettingsRecord != null,
            'PpiSettings record not found for : ' + ACCOUNT_API_NAME
        );

        Test.startTest();
        String fieldvalue =
            PpiSettingsWrapper.getFieldValue(
                ACCOUNT_API_NAME,
                PpiSettings__c.ObjectIdApiName__c.getDescribe().getName()
            );
        Test.stopTest();
        System.assertEquals(Schema.sObjectType.Account.fields.Site.getName(), fieldvalue);
    }
}