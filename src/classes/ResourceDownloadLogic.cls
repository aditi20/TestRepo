/**
 * Logic class for the resource download service
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
public with sharing class ResourceDownloadLogic {

    /**
     * Process the request for the download of a resource
     */
    public static void processDownload() {
        // Get request data
        String sessionId  = RestContext.request.headers.get(C.SESSION_TOKEN_HEADER);
        String resourceId = RestContext.request.headers.get(C.RESOURCE_ID_HEADER);

        // Check the session and device
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            sessionId,
            true
        );

        if (loginResult.hasError) {
            // Add the headers
            for(String header : loginResult.headers.keySet()) {
                RestContext.response.addHeader(header, loginResult.headers.get(header));
            }
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
            Restcontext.response.statusCode = loginResult.statusCode;
            return;
        }

        // Check the resource header
        if(String.isBlank(resourceId)) {
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_MISSING_RESOURCEID,
                ErrorHandlingRest.SYNC_MISSING_RESOURCEID,
                System.Label.RESOURCE_ERROR_MISSING_ID
            );
            RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, C.CONTENT_TYPE_JSON_UTF);
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
            Restcontext.response.statusCode = C.HTTP_BAD_REQUEST;
            return;
        }

        // Fetch the requested resource
        List<ContentVersion> contentList = [
            SELECT
                VersionData,
                FileType,
                PathOnClient
            FROM
                ContentVersion
            WHERE
                ContentDocumentId = :resourceId
                AND isLatest = true
            LIMIT 1
        ];

        // Process the resource
        if (contentList.size() > 0) {
            // Get the MIME type
            // It will be null if not supported
            String contentType = C.getContentMimeType(contentList[0]);
            if (contentType != null) {
                RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, contentType);
                RestContext.response.responseBody = contentList[0].VersionData;
                Restcontext.response.statusCode = C.HTTP_OK;
            } else {
                ErrorHandlingRest.addErrorMsg(
                    ErrorHandlingRest.ERR_CODE_RESOURCE_TYPE_NOT_SUPPORTED,
                    ErrorHandlingRest.SYNC_RESOURCE_TYPE_NOT_SUPPORTED,
                    System.Label.RESOURCE_TYPE_NOT_SUPPORTED
                );
                RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, ErrorHandlingRest.ERROR_CONTENT_TYPE);
                RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
                Restcontext.response.statusCode = C.HTTP_BAD_REQUEST;
                return;
            }
        }
        else {
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_RESOURCE_ID_NOT_EXIST,
                ErrorHandlingRest.SYNC_RESOURCE_ID_INVALID,
                String.format(
                    System.Label.RESOURCE_ERROR_INVALID_ID,
                    new String[] {resourceId}
                )
            );
            RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, ErrorHandlingRest.ERROR_CONTENT_TYPE);
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
            Restcontext.response.statusCode = C.HTTP_NOT_FOUND;
            return;
        }
    }
}
