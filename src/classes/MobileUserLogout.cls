/*
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
* @author dcaballero
* Class that get the logout request and process it
*/

@RestResource(urlMapping='/logout')
global class MobileUserLogout {
    /**
     * Method that receives the session token in the http header and remove it
     *
     * @return - 204 if you successfully logout
     *         - 400 if session token not provided
     *         - 404 if user not found who owns the session token
     */
    @HttpGet
    global static void doGet() {
        MobileUserLogoutLogic.logout();
    }
}