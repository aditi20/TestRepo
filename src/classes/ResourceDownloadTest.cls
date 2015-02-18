/**
 * Test class for the resource download feature
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
@isTest
public with sharing class ResourceDownloadTest {

    /**
     * Inner class for the test data
     */
    private class TestData {
        public TestUtils.Surveyor surveyor;
        public Blob contentData;
        public Id contentDocumentId;

        public TestData() {}

        public TestData(String contentType) {
            this.addSurveyor();
            this.addContent(contentType);
        }

        public void addSurveyor() {
            UserTH.setSkipValidation(true);
            this.surveyor = TestUtils.createPartnerSurveyor(
                'LastNameRDT',
                true
            );
            this.surveyor = TestUtils.partnerLoginDetails(this.surveyor);
        }

        public void addContent(String contentType) {
            this.contentData = Blob.valueOf('Some content data');

            // Create the ContentVersion object for the file
            ContentVersion doc = new ContentVersion(
                title = 'SomeContent',
                versionData = this.contentData,
                pathOnClient = 'some/path.' + contentType
            );
            insert doc;
            this.contentDocumentId = [
                SELECT
                    contentDocumentId
                FROM
                    ContentVersion
                WHERE
                    Id = :doc.Id
            ].contentDocumentId;

            // Add to the TaroWorks content library. Library must be set up on org already
            // and Partner Users must be given membership via a public group.
            List<ContentWorkspace> cws = [
                SELECT
                    Name,
                    Id
                FROM
                    ContentWorkspace
                WHERE
                    Name = :C.WORKSPACE_LIBRARY_NAME
                ];
            System.assertEquals(
                1,
                cws.size(),
                'YOU MUST SET UP THE SALESFORCE LIBRARY TO CONTINUE TESTING'
            );
            ContentWorkspaceDoc cwsDoc = new ContentWorkspaceDoc(
                ContentDocumentId = this.contentDocumentId,
                ContentWorkspaceId = cws[0].Id
            );
            insert cwsDoc;
        }
    }

    /**
     * Test for the correct download of a resource
     */
    static testMethod void testDownloadResource() {

        TestData data = new TestData('3gp');

        // Prepare the request data
        String serviceUrl = TestUtils.getServiceUrl('resources');
        Map<String, String> headersMap = new Map<String, String> {
            C.SESSION_TOKEN_HEADER => data.surveyor.loginResult.getSessionToken(),
            C.RESOURCE_ID_HEADER   => data.contentDocumentId
        };
        TestUtils.prepareRestContext(serviceUrl, null, headersMap);

        // Run the test
        Test.startTest();
        System.runAs(data.surveyor.partnerUser) {
            ResourceDownload.processDownload();
        }
        Test.stopTest();

        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
        System.assertEquals('video/3gpp', RestContext.response.headers.get(C.CONTENT_TYPE_HEADER));
        System.assertEquals(data.contentData.toString(), RestContext.response.responseBody.toString());
    }

    /**
     * Test what happens when the document id headeris missing
     */
    static testMethod void testMissingHeader() {
        // Prepare the data for the test
        TestData data = new TestData('mp4');

        // Prepare the request data
        String serviceUrl = TestUtils.getServiceUrl('resources');
        Map<String, String> headersMap = new Map<String, String> {
            C.SESSION_TOKEN_HEADER => data.surveyor.loginResult.getSessionToken()
        };
        TestUtils.prepareRestContext(serviceUrl, null, headersMap);

        // Run the test
        Test.startTest();
        System.runAs(data.surveyor.partnerUser) {
            ResourceDownload.processDownload();
        }

        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);
        System.assertEquals(1, ErrorHandlingRest.getAllErrors().size());
        ErrorHandlingRest.ErrorMessage errorMessage = ErrorHandlingRest.getAllErrors().get(0);
        System.assertEquals(ErrorHandlingRest.ERR_CODE_MISSING_RESOURCEID, errorMessage.getErrorCode());
        System.assertEquals(ErrorHandlingRest.SYNC_MISSING_RESOURCEID, errorMessage.getErrorTranslationCode());
        System.assertEquals(System.Label.RESOURCE_ERROR_MISSING_ID, errorMessage.getDefaultErrorMsg());

        ErrorHandlingRest.clearAllErrorMsgs();

        // Test with a empty string in the header
        headersMap.put(C.RESOURCE_ID_HEADER, '');
        TestUtils.prepareRestContext(serviceUrl, null, headersMap);

        System.runAs(data.surveyor.partnerUser) {
            ResourceDownload.processDownload();
        }

        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);
        System.assertEquals(1, ErrorHandlingRest.getAllErrors().size());
        errorMessage = ErrorHandlingRest.getAllErrors().get(0);
        System.assertEquals(ErrorHandlingRest.ERR_CODE_MISSING_RESOURCEID, errorMessage.getErrorCode());
        System.assertEquals(ErrorHandlingRest.SYNC_MISSING_RESOURCEID, errorMessage.getErrorTranslationCode());
        System.assertEquals(System.Label.RESOURCE_ERROR_MISSING_ID, errorMessage.getDefaultErrorMsg());

        Test.stopTest();
    }

    /**
     * Test for a wrong resource id
     */
    static testMethod void testWrongResourceId() {
        // Prepare the data for the test
        TestData data = new TestData('mp4');

        // Prepare the request data
        String serviceUrl = TestUtils.getServiceUrl('resources');
        Map<String, String> headersMap = new Map<String, String> {
            C.SESSION_TOKEN_HEADER => data.surveyor.loginResult.getSessionToken(),
            C.RESOURCE_ID_HEADER   => 'wrongId'
        };
        TestUtils.prepareRestContext(serviceUrl, null, headersMap);

        // Run the test
        Test.startTest();

        // Test with a wrong id
        System.runAs(data.surveyor.partnerUser) {
            ResourceDownload.processDownload();
        }

        System.assertEquals(C.HTTP_NOT_FOUND, RestContext.response.statusCode);
        System.assertEquals(1, ErrorHandlingRest.getAllErrors().size());
        ErrorHandlingRest.ErrorMessage errorMessage = ErrorHandlingRest.getAllErrors().get(0);
        System.assertEquals(ErrorHandlingRest.ERR_CODE_RESOURCE_ID_NOT_EXIST, errorMessage.getErrorCode());
        System.assertEquals(ErrorHandlingRest.SYNC_RESOURCE_ID_INVALID, errorMessage.getErrorTranslationCode());
        System.assertEquals(
            String.format(
                System.Label.RESOURCE_ERROR_INVALID_ID,
                new String[] {'wrongId'}
            ),
            errorMessage.getDefaultErrorMsg()
        );

        ErrorHandlingRest.clearAllErrorMsgs();

        // Test with the id of a deleted resource
        headersMap.put(C.RESOURCE_ID_HEADER, data.contentDocumentId);
        TestUtils.prepareRestContext(serviceUrl, null, headersMap);
        delete [SELECT Id FROM ContentDocument WHERE Id = :data.contentDocumentId];

        System.runAs(data.surveyor.partnerUser) {
            ResourceDownload.processDownload();
        }
        System.assertEquals(C.HTTP_NOT_FOUND, RestContext.response.statusCode);
        System.assertEquals(1, ErrorHandlingRest.getAllErrors().size());
        errorMessage = ErrorHandlingRest.getAllErrors().get(0);
        System.assertEquals(ErrorHandlingRest.ERR_CODE_RESOURCE_ID_NOT_EXIST, errorMessage.getErrorCode());
        System.assertEquals(ErrorHandlingRest.SYNC_RESOURCE_ID_INVALID, errorMessage.getErrorTranslationCode());
        System.assertEquals(
            String.format(
                System.Label.RESOURCE_ERROR_INVALID_ID,
                new String[] {data.contentDocumentId}
            ),
            errorMessage.getDefaultErrorMsg()
        );

        Test.stopTest();
    }

    /**
     * Test for an unsupported type
     */
    static testMethod void testUnsupportedType() {
        // Prepare the data for the test
        TestData data = new TestData('mp3');

        // Prepare the request data
        String serviceUrl = TestUtils.getServiceUrl('resources');
        Map<String, String> headersMap = new Map<String, String> {
            C.SESSION_TOKEN_HEADER => data.surveyor.loginResult.getSessionToken(),
            C.RESOURCE_ID_HEADER   => data.contentDocumentId
        };
        TestUtils.prepareRestContext(serviceUrl, null, headersMap);

        // Run the test
        Test.startTest();

        // Test with a wrong id
        System.runAs(data.surveyor.partnerUser) {
            ResourceDownload.processDownload();
        }

        System.assertEquals(C.HTTP_BAD_REQUEST, RestContext.response.statusCode);
        System.assertEquals(1, ErrorHandlingRest.getAllErrors().size());
        ErrorHandlingRest.ErrorMessage errorMessage = ErrorHandlingRest.getAllErrors().get(0);
        System.assertEquals(ErrorHandlingRest.ERR_CODE_RESOURCE_TYPE_NOT_SUPPORTED, errorMessage.getErrorCode());
        System.assertEquals(ErrorHandlingRest.SYNC_RESOURCE_TYPE_NOT_SUPPORTED, errorMessage.getErrorTranslationCode());
        System.assertEquals(System.Label.RESOURCE_TYPE_NOT_SUPPORTED, errorMessage.getDefaultErrorMsg());

        Test.stopTest();
    }

    /**
     * Test method to check CRUD-FLS permission check while processing resources request 
     */
    static testMethod void testProcessDownload() {

        TestData data = new TestData('3gp');
        String serviceUrl = TestUtils.getServiceUrl('resources');

        Map<String, String> headersMap = new Map<String, String> {
            C.SESSION_TOKEN_HEADER => data.surveyor.loginResult.getSessionToken(),
            C.RESOURCE_ID_HEADER   => data.contentDocumentId
        };
        TestUtils.prepareRestContext(serviceUrl, null, headersMap);
        MobileUserLoginLogic.setBlockMobileUserLogin(false);

        System.RunAs(TestUtils.createChatterExternalUser()) {
            DescribeHandler.resetDescribeHandler();
            Test.startTest();
            ResourceDownload.processDownload();
            Test.stopTest();
        }

        ErrorHandlingRest.ErrorMessages errors = (ErrorHandlingRest.ErrorMessages)
            JSON.deserialize(
                RestContext.response.responseBody.toString(),
                ErrorHandlingRest.ErrorMessages.class
            );
        System.assertEquals(1, errors.getErrors().size());
        System.assertEquals(C.HTTP_INTERNAL_SERVER_ERROR, RestContext.response.statusCode);
        List<ErrorHandlingRest.ErrorMessage> errorMessages = errors.getErrors();
        System.assert(
            RestContext.response.responseBody.toString().contains(System.Label.ERR_PERMISSIONS)
        );
        System.assertEquals(
            ErrorHandlingRest.ERR_CODE_CRUD_FLS, errorMessages[0].getErrorCode()
        );
        System.assertEquals(
            ErrorHandlingRest.CRUD_FLS, errorMessages[0].getErrorTranslationCode()
        );
    }
}