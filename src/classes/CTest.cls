/**
*   Grameen: Salesforce - SF Field Force, SF - Jobs
*   Test for the CTest
*   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*   @author Dennys López Dinza - dlopez@altimetrik.com
*/
@isTest
public class CTest{

    /**
    * Load the User Language
    */
    static testMethod void testGetUserLanguage(){

        //create a user with language setting
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User adminUser = new User(
            UserName = 'admin12@test.com',
            FirstName = 'Admin User 12',
            LastName = 'Admin12',
            Alias = 'admin12',
            Email = 'admin12@testing.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocalesIdKey = 'en_US',
            TimezonesIdKey = 'America/Los_Angeles',
            ProfileId = adminProfile.Id
        );

        insert adminUser;

        String userLanguage = '';
        Test.startTest();
            //loading language
            System.RunAs(adminUser){
                userLanguage = C.getUserLanguage();
            }
        Test.stopTest();

        System.assertEquals('en', userLanguage, 'The user language should be "en"');
    }

    /**
    * Get an existing license.
    */
    static testMethod void testGetLicense(){

        //create license
        LicenseSettings__c li = new LicenseSettings__c(Name = 'Test 1');
        insert li;
        
        Test.startTest();
            //getting the license
            LicenseSettings__c new_li = C.getLicense();

            //verify the right loading of license
            LicenseSettings__c li_loaded = [SELECT Name FROM LicenseSettings__c LIMIT 1];
        Test.stopTest();    
        System.assertEquals('Test 1', li_loaded.Name, 'This is a loaded license, the name of license should be "Test".');
    }

    /**
    * Generate a new License
    */
    static testMethod void testGenerateLicense(){
        
        Test.startTest();
            //auto generate a new license
            LicenseSettings__c new_li = C.getLicense();

            //verify the right loading of license
            LicenseSettings__c li_loaded = [SELECT Name FROM LicenseSettings__c LIMIT 1];
        Test.stopTest();
        System.assertEquals('Test', li_loaded.Name, 'This is a test running method, the name of license should be "Test".');
    }

     /**
     * Test obtainFileExtensionFromVersion method.
     */
    static testMethod void testGetExtension() {
        
        // Obtain the list of ContentVersion.
        List<ContentVersion> contentVersions = TestUtils.createListContentVersion();

        // check that the method obtains the correct Extension

        // standard case
        system.assertEquals('mp4', C.obtainFileExtensionFromVersion(contentVersions.get(0)));
        // several periods character.
        system.assertEquals('3gp', C.obtainFileExtensionFromVersion(contentVersions.get(1)));
        // Period is the last character.
        system.assertEquals('', C.obtainFileExtensionFromVersion(contentVersions.get(2)));
        
    }

    /**
     * Test isAutonumberNotIdField method.
     */
    static testMethod void testIsAutonumberNotIdField() {

        // Create object, and the id field of an object that will fail.
        String objectNameFail = 'Case';
        String idFieldFail = 'Type';

        // Create the list of fields that would be mapped (note that CaseNumber is autonumber and is not id field).
        List<String> mappedFieldListFail = new List<String>{'CaseNumber', 'Owner'};

        // Create object, and the id field of an object that won't fail because autonumber field is id field.
        String objectNameOk = 'Case';
        String idFieldOk = 'CaseNumber';

        // Create the list of fields that would be mapped (note that CaseNumber is autonumber and is id field).
        List<String> mappedFieldListOk = new List<String>{'CaseNumber', 'Owner'};

        // Create object, and the id field of an object that won't fail because has not autonumber fields.
        String objectNameNoAutoNumber = 'Case';
        String idFieldNoAutoNumber = 'Owner';

        // Create the list of fields that would be mapped (note that there is no autonumber field mapped).
        List<String> mappedFieldListNoAutoNumber = new List<String>{'ContactFax', 'Owner'};

        Map<String, Schema.SObjectField> objectFields = DescribeHandler.getFieldMap('Case');

        Test.startTest();
        Boolean isAnyAutonumberNotIdFieldFail =
            C.isAutonumberNotIdField(objectNameFail, idFieldFail, mappedFieldListFail, objectFields);
        Boolean isAnyAutonumberNotIdFieldOk =
            C.isAutonumberNotIdField(objectNameOk, idFieldOk, mappedFieldListOk, objectFields);
        Boolean isAnyAutonumberNotIdFieldNoAutoNumber =
            C.isAutonumberNotIdField(
                objectNameNoAutoNumber,
                idFieldNoAutoNumber,
                mappedFieldListNoAutoNumber,
                objectFields
            );
        Test.stopTest();

        System.assert(isAnyAutonumberNotIdFieldFail, 'Autonumber field mapped is not longer autonumber');
        System.assert(!isAnyAutonumberNotIdFieldOk, 'Another field besides CaseNumber is autonumber');
        System.assert(!isAnyAutonumberNotIdFieldNoAutoNumber, 'One of the mapped fields is autonumber and not id field');
    }

    /**
     * Test getting subset of a list
     */
    static testMethod void testListSubset() {

        List<Object> completeList = new List<Integer>{
            1, 2, 3, 4, 5, 6
        };
        List<Object> subsetToCompare = new List<Integer>{
            2, 3, 4
        };

        List<Object> testList = C.getListSubset(
            1, 4, completeList
        );
        System.assertEquals(subsetToCompare, testList);
    }
}