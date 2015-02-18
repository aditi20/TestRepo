/**
 * Endpoint for the download of resources
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
@RestResource(urlMapping='/resources/*')
global with sharing class ResourceDownload {

    @HttpGet
    global static void processDownload() {
        ResourceDownloadLogic.processDownload();
    }
}
