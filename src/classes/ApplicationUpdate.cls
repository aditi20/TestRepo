/**
 * Rest Endpoint that allows the device to check to see if it has the latest
 * version of the application installed on it.
 * Logic for this endpoint is in ApplicationUpdateLogic.cls as it is not
 * possible to patch classes that are declared as RestResource in a managed
 * package
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 *
 * @author - Owen Davies (odavies@grameenfoundation.org)
 */
@RestResource(urlMapping='/applicationUpdate/*')
global class ApplicationUpdate {

    /**
     * Method for a POST request. Will check to see if the application that
     * made the request is the latest version
     */
    @HttpPost
    global static void doPost() {
        ApplicationUpdateLogic.checkForUpdate();
    }
}
