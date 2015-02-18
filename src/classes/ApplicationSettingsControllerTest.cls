/**
 * Test class for the application settings controller
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 */
@isTest
public class ApplicationSettingsControllerTest {


    /**
     * Test creating a default setting when no other setting exists
     */
    static testMethod void testCreatingDefaultSetting() {

        Settings__c setting = ApplicationSettingsUtils.getDefaultSetting(true);
        System.assertEquals(ApplicationSettingsUtils.JOBS_FILTER_ALL, setting.FilterJobsBySalesforceUser__c);
        System.assertEquals('Test', setting.Name);
    }

    /**
     * Test getting the default setting when it has already been created
     */
    static testMethod void testGettingDefaultSetting() {

        // Create the setting
        Settings__c setting = ApplicationSettingsUtils.getDefaultSetting(true);

        // Fetch it again
        setting = ApplicationSettingsUtils.getDefaultSetting(false);
        System.assertEquals(ApplicationSettingsUtils.JOBS_FILTER_ALL, setting.FilterJobsBySalesforceUser__c);
        System.assertEquals('Test', setting.Name);
    }

    /**
     * Test updating the Jobs Filter setting to filter by Salesforce User via the controller
     */
    static testMethod void testChangingJobFilterSetting() {

        // Create the initial filter
        ApplicationSettingsUtils.getDefaultSetting(true);

        // Create the controller
        ApplicationSettingsController controller = new ApplicationSettingsController();

        // Assert that the setting is in default
        Settings__c setting = ApplicationSettingsUtils.getDefaultSetting(false);
        System.assertEquals(ApplicationSettingsUtils.JOBS_FILTER_ALL, setting.FilterJobsBySalesforceUser__c);
        System.assertEquals('Test', setting.Name);

        // Add the parameters to the page to change the setting
        PageReference applicationSettingsPage = Page.ApplicationSettings;
        applicationSettingsPage.getParameters().put(
            ApplicationSettingsUtils.JOBS_FILTER_NAME,
            ApplicationSettingsUtils.JOBS_FILTER_SF_USER
        );
        Test.setCurrentPageReference(applicationSettingsPage);

        // Call method to update the setting
        controller.save();

        // Assert that the setting has been changed
        setting = ApplicationSettingsUtils.getDefaultSetting(false);
        System.assertEquals(ApplicationSettingsUtils.JOBS_FILTER_SF_USER, setting.FilterJobsBySalesforceUser__c);
        System.assertEquals('Test', setting.Name);
    }

    /**
     * Test FilterJobsBySalesforceUser__c setting works
     */
    static testMethod void testJobFilterSetting() {

        // Create a mobile user
        TestUtils.Surveyor mobileUser =
            TestUtils.createSurveyor('LastName', 'user', 'pass', MobileUserDO.STATUS_ACTIVE);

        Profile[] admins = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        // Create a User
        User user1 = TestUtils.getUser(admins[0].Id, '');

        // Create a 2nd User
        User user2 = TestUtils.getUser(admins[0].Id, '');
        insert new List<User>{ user1, user2 };

        // Create a job for the first User
        JobTemplate__c jobTemp1 =
            JobTemplateDO.createJobTemplate('temp1', JobTemplateDO.STATUS_DRAFT, '');

        // Create a job for the 2nd User
        JobTemplate__c jobTemp2 =
            JobTemplateDO.createJobTemplate('temp2', JobTemplateDO.STATUS_DRAFT, '');
        insert(new List<JobTemplate__c>{jobTemp1, jobTemp2});

        // Update the job templates
        jobTemp1.OwnerId = user1.Id;
        jobTemp2.OwnerId = user2.Id;
        update new List<JobTemplate__c>{ jobTemp1, jobTemp2 };

        // Update the Mobile User to be owned by User1
        mobileUser.theContact.OwnerId = user1.Id;
        update mobileUser.theContact;

        // Load the job templates for the mobile user
        List<JobTemplate__c> jobTemps =
            JobTemplateDO.getMobileUserJobTemplates(mobileUser.theContact, JobTemplateDO.STATUS_DRAFT);
        System.assertEquals(2, jobTemps.size());

        // Update the setting
        Settings__c setting = ApplicationSettingsUtils.getDefaultSetting(true);
        setting.FilterJobsBySalesforceUser__c = ApplicationSettingsUtils.JOBS_FILTER_SF_USER;
        update setting;

        // Get the mobile user to ensure we have the ownerId
        Mobile_User__c user = [
            SELECT
                Id,
                Contact__r.OwnerId
            FROM
                Mobile_User__c
            WHERE Id = :mobileUser.user.Id
        ];

        // Reload the jobs
        jobTemps.clear();
        jobTemps = JobTemplateDO.getMobileUserJobTemplates(user.Contact__r, JobTemplateDO.STATUS_DRAFT);
        System.assertEquals(1, jobTemps.size());
    }

    /**
     * Test method to verify ApplicationVersionSettings are displayed properly
     * with individual column sorting
     */
    static testMethod void testSortingWithFields() {
        ApplicationVersionSettings__c version1 =
            ApplicationVersionSettingsSelectorTest.createRecord(
                DateTime.now(),
                '1.2.3',
                'tesUrl',
                false,
                '1.8'
            );
        ApplicationVersionSettings__c version2 =
            ApplicationVersionSettingsSelectorTest.createRecord(
                DateTime.now(),
                '1.2.4',
                'tesUrl1',
                true,
                '1.9'
            );
        insert new List<ApplicationVersionSettings__c> {version1, version2};

        Test.startTest();
        ApplicationSettingsController conroller = new ApplicationSettingsController();
        // Before sorting, the first record will be with Mobile version 1.8
        System.assertEquals(
           '1.8',
            conroller.applicationVersionSettingsList[0].MobileAPKVersion__c
        );
        conroller.sortField = 'MobileAPKVersion__c';
        conroller.sortDirection = 'DESC';
        conroller.sortData();
        Test.StopTest();

        // After sorting, the first record will be with Mobile version 1.9
        System.assertEquals(
           '1.9',
            conroller.applicationVersionSettingsList[0].MobileAPKVersion__c
        );
    }

    /**
     * Test method to verify update for ApplicationVersionSettings works properly
     */
    static testMethod void testUpdateApplicationVersionSettings() {
        ApplicationVersionSettings__c version =
            ApplicationVersionSettingsSelectorTest.insertTestData();

        // Add the parameters to the page to change the setting
        PageReference applicationSettingsPage = Page.ApplicationSettings;
        applicationSettingsPage.getParameters().put(
            ApplicationSettingsUtils.JOBS_FILTER_NAME,
            ApplicationSettingsUtils.JOBS_FILTER_SF_USER
        );

        Test.setCurrentPageReference(applicationSettingsPage);

        Test.startTest();
        ApplicationSettingsController conroller = new ApplicationSettingsController();
        conroller.applicationVersionSettingsList[0].IsActive__c = true;
        conroller.save();
        Test.StopTest();

        System.assert(
            conroller.applicationVersionSettingsList[0].IsActive__c,
            'The Application Version Settings is not updated properly'
        );
    }

    /**
     * Test method to verify ApplicationVersionSettings are displayed properly
     */
    static testMethod void testDisplayApplicationVersionSettings() {
        ApplicationVersionSettings__c version =
            ApplicationVersionSettingsSelectorTest.insertTestData();

        Test.startTest();
        ApplicationSettingsController conroller = new ApplicationSettingsController();
        Test.StopTest();

        System.assertEquals(
            version.Name,
            conroller.applicationVersionSettingsList[0].Name
        );
    }

    /**
     * Test method to verify retrival of all objects from org
     */
    static testmethod void testLoadObjectSelectList() {
        ApplicationSettingsController controller =
            new ApplicationSettingsController();

        Test.startTest();
        List<SelectOption> objectList = controller.getObjectSelectList();
        Test.stopTest();

        Set<String> expectedObjects = new Set<String>();
        for (Schema.SObjectType sObjectType : Schema.getGlobalDescribe().Values()) {
            if (!C.hasNameSpacePrefix(sObjectType.getDescribe().getName()) ||
                    C.whiteListedObjects.contains(sObjectType.getDescribe().getName().toLowerCase())
            ) {
                GenericObjectCreator creator =
                    new GenericObjectCreator(sObjectType.getDescribe().getName());
                if (creator.isObjectAccessible(false)) {
                    expectedObjects.add(sObjectType.getDescribe().getName());
                }
            }
        }

        // Expected object list has + 1 added as the actual object list
        // also contains additional None option in the list
        System.assertEquals(expectedObjects.size() + 1, objectList.size());
    }

    /**
     * Test method to verify fields are fetched properly for selected object
     */
    static testmethod void testLoadFieldSelectList() {
        ApplicationSettingsController controller =
            new ApplicationSettingsController();

        List<SelectOption> clientIdFieldList;
        List<SelectOption> genderFieldList;
        List<SelectOption> ageFieldList;
        List<SelectOption> householdMemberFieldList;
        List<SelectOption> joinedDateFieldList;
        List<SelectOption> geoLocationFieldList;

        Test.startTest();
        controller.ppiSettingsInstance.Name = Account.sObjectType.getDescribe().getName();
        controller.loadFieldsbasedOnType();
        clientIdFieldList = controller.clientIdSelectOption;
        genderFieldList = controller.genderSelectOption;
        ageFieldList = controller.ageSelectOption;
        householdMemberFieldList = controller.householdMembersSelectOption;
        joinedDateFieldList = controller.dateOfJoiningSelectOption;
        Test.stopTest();

        Set<String> expectedClientIdList = new Set<String>();
        Set<String> expectedGenderList = new Set<String>();
        Set<String> expectedAgeList = new Set<String>();
        Set<String> expectedHouseholdMemberList = new Set<String>();
        Set<String> expectedJoinedDateList = new Set<String>();
        if (DescribeHandler.getFieldMap(controller.ppiSettingsInstance.Name) != null) {
            for (String fieldName :
                DescribeHandler.getFieldMap(controller.ppiSettingsInstance.Name).keySet()
            ) {
                Schema.DescribeFieldResult fieldResult = 
                    DescribeHandler.getFieldDescribe(controller.ppiSettingsInstance.Name, fieldName);
                if (fieldResult.getType() == Schema.Displaytype.Integer ||
                    fieldResult.getType() == Schema.Displaytype.Double
                ) {
                    if (!SurveyUtils.isGeoLocationComponentField(fieldName)) {
                        expectedClientIdList.add(fieldResult.getName());
                        expectedHouseholdMemberList.add(fieldResult.getName());
                        expectedAgeList.add(fieldResult.getName());
                    }
                } else if (fieldResult.getType() == Schema.Displaytype.String) {
                    expectedClientIdList.add(fieldResult.getName());
                    if (!fieldResult.isAutoNumber()) {
                        expectedGenderList.add(fieldResult.getName());
                    }
                } else if (fieldResult.getType() == Schema.Displaytype.Picklist) {
                    expectedGenderList.add(fieldResult.getName());
                } else if (fieldResult.getType() == Schema.Displaytype.ID) {
                    expectedClientIdList.add(fieldResult.getName());
                } else if (fieldResult.getType() == Schema.Displaytype.Date) {
                    expectedJoinedDateList.add(fieldResult.getName());
                }
            }
        }

        // Expected field list has + 1 added as the actual field list
        // also contains additional None option in the list
        System.assertEquals(
            expectedClientIdList.size() + 1,
            clientIdFieldList.size()
        );
        System.assertEquals(
            expectedGenderList.size() + 1,
            genderFieldList.size()
        );
        System.assertEquals(
            expectedAgeList.size() + 1,
            ageFieldList.size()
        );
        System.assertEquals(
            expectedHouseholdMemberList.size() + 1,
            householdMemberFieldList.size()
        );
        System.assertEquals(
            expectedJoinedDateList.size() + 1,
            joinedDateFieldList.size()
        );
    }

    /**
     * Test method to verify retrival of all Records of PpiSettings
     */
    static testMethod void testfetchPpiRecords() {
        PpiSettings__c ppiSettingsInstacne = PpiSettingsWrapper.insertRecord(
            Account.sObjectType.getDescribe().getName(),
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Site.getName(),
            '',
            '',
            ''
        );

        Test.startTest();
        ApplicationSettingsController controller = new ApplicationSettingsController();
        Test.stopTest();

        System.assert(
            controller.ppiSettingsInstance != null,
            'PpiSettings record not fetched properly'
        );
    }

    /**
     * Test method to verify inserting of PpiSettings
     */
    static testMethod void testSavePpiSettingsForInsert() {
        PpiSettings__c ppiSettingsInstacne = PpiSettingsWrapper.createRecord(
            Account.sObjectType.getDescribe().getName(),
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Site.getName(),
            '',
            '',
            ''
        );

        ApplicationSettingsController controller = new ApplicationSettingsController();
        controller.ppiSettingsInstance = ppiSettingsInstacne;
        Test.startTest();
        controller.savePpiSettings();
        Test.stopTest();

        List<PpiSettings__c> ppiSettingsList = PpiSettingsWrapper.getAllRecords();
        System.assertEquals(1, ppiSettingsList.size());
    }

    /**
     * Test method to verify update of ppiSettings 
     */
    static testMethod void testSavePpiSettingsForUpdate() {

        PpiSettings__c ppiSettingsInstacne = PpiSettingsWrapper.insertRecord(
            Account.sObjectType.getDescribe().getName(),
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Site.getName(),
            '',
            '',
            ''
        );

        List<PpiSettings__c> ppiSettingsList = PpiSettingsWrapper.getAllRecords();
        System.assertEquals(1, ppiSettingsList.size());
        System.assertEquals(
            Account.sObjectType.getDescribe().getName(),
            ppiSettingsList[0].Name
        );

        Test.startTest();
        // Update the selected object and its corresponding field in custom Setting
        ApplicationSettingsController controller = new ApplicationSettingsController();
        controller.ppiSettingsInstance.Name = Lead.sObjectType.getDescribe().getName();
        controller.ppiSettingsInstance.ObjectIdApiName__c =
            Schema.sObjectType.Lead.fields.Title.getName();

        controller.savePpiSettings();
        Test.stopTest();

        ppiSettingsList = PpiSettingsWrapper.getAllRecords();
        System.assertEquals(1, ppiSettingsList.size());
        System.assertEquals(
            Lead.sObjectType.getDescribe().getName(), 
            ppiSettingsList[0].Name
        );

        // Verify fields are updated
        System.assertEquals(
            Schema.sObjectType.Lead.fields.Title.getName(), 
            ppiSettingsList[0].ObjectIdApiName__c
        );

        // Verify fields are reset properly if not selected anything
        System.assertEquals(
            null, 
            ppiSettingsList[0].GenderApiName__c
        );
    }

    /**
     * Test method to verify delete of ppiSettings if none is selected for the object
     */
    static testMethod void testSavePpiSettingsForDelete() {

        PpiSettings__c ppiSettingsInstacne = PpiSettingsWrapper.insertRecord(
            Account.sObjectType.getDescribe().getName(),
            Schema.sObjectType.Account.fields.NumberOfEmployees.getName(),
            Schema.sObjectType.Account.fields.Site.getName(),
            '',
            '',
            ''
        );

        List<PpiSettings__c> ppiSettingsList = PpiSettingsWrapper.getAllRecords();
        System.assertEquals(1, ppiSettingsList.size());
        System.assertEquals(
            Account.sObjectType.getDescribe().getName(),
            ppiSettingsList[0].Name
        );

        Test.startTest();
        // Update the selected object to None value
        ApplicationSettingsController controller = new ApplicationSettingsController();
        controller.ppiSettingsInstance.Name = '';

        controller.savePpiSettings();
        Test.stopTest();

        ppiSettingsList = PpiSettingsWrapper.getAllRecords();
        System.assertEquals(0, ppiSettingsList.size(), 'Custom Setting not deleted properly');
    }
}