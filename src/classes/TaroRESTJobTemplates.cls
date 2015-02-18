/**
 * REST service for getting the Metadata, Instances and JobTemplates needed
 * in a particular mobile for a particular user of TaroWork app.
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved.
 *
 * @author - Owen Davies
 */
@RestResource(urlMapping='/jobtemplates')
global class TaroRESTJobTemplates {

    @HttpPost
    global static void generateDataAndMetaData() {
        TaroRESTJobTemplatesLogic.generateDataAndMetaData();
    }

    /**
     * Classes to parse the Request Body
     */
    global class TaroRequestBody {
    }

    global class KnownJobTemplate {
    }

    /**
     * Wrapper class for the response body
     */
    public class TaroResponseBody{
    }
}