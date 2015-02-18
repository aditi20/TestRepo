/**
 * Rest Endpoint that allows the device to fetch all the information it needs
 * to see the performance of the MobileUser logged in
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved.
 *
 * @author - Owen Davies (odavies@grameenfoundation.org)
 */
@RestResource(urlMapping='/performance/*')
global class PerformanceManagementEndpoint {

    /**
     * Method to deal with the GET request to this endpoint
     */
    @HttpGet
    global static void doGet() {
        PerformanceManagementLogic.processGetRequest();
    }
}