/*
 * Class that get the login request and process it
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *

 * @author dcaballero// Test parent new changes
 * @author Alejandro De Gregorio Tort // Test parent new changes
 * @author dcaballero // Test child changes
 * @author Alejandro De Gregorio Tort // Test child changes
 * @author dcaballero
 * @author Alejandro De Gregorio Tort - Test child changes
 */

@RestResource(urlMapping='/login')
global class MobileUserLogin {
// Test Parent commit 2
    /**
     * Method in charge of processing a request
     * It requires mobileSurvey_Username, mobileSurvey_Password, deviceId
     * Test1234
     * If username and password are correct and device id exists -> returns a 200 and a session token and save a Session object
     * If username and password are correct and deviceId does not exists -> creates a device, returns a 200 and a  session token and save a session object
     * If username or password are wrong or device is deactivated -> returns a 401 (unauthorized)
     * If required parameters are missing -> returns a 400 (bad request). // test 123
     */
    @HttpGet
    global static void doGet(){
        MobileUserLoginLogic.processGetRequest();
    }
}
