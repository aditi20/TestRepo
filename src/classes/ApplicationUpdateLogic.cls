/**
 * Checks to see if the application version that the mobile user has on their device is the most up to date
 * version. Allows device to know where to download updates from.
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 *
 * @author - Owen Davies (odavies@grameenfoundation.org)
 */
public with sharing class ApplicationUpdateLogic {

    /**
     * Check that the Mobile User has the latest version of the application.
     * This requires the Mobile User to have already logged in and be in possession
     * of a valid session token
     */
    public static void checkForUpdate() {

        // Validate the user
        MobileUserLoginLogic.setBlockMobileUserLogin(false);
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            RestContext.request.headers.get(C.SESSION_TOKEN_HEADER),
            true
        );
        RestContext.response.statusCode = loginResult.statusCode;
        if (loginResult.hasError) {
            // Add the headers
            for(String header : loginResult.headers.keySet()) {
                RestContext.response.addHeader(header, loginResult.headers.get(header));
            }
            // Return failure message if the user has failed authentication
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
        }
        else {

            // Check that this is the most current version of the mobile application available
            RestContext.response.responseBody = Blob.valueOf(Json.serialize(
                checkApplicationVersion(RestContext.request.headers.get(C.APPLICATION_VERSION_NUMBER_HEADER))
            ));
        }
    }

    /**
     * Compare the version number that the mobile user has with the most recently released application version
     * to see if the mobile user needs to update the application
     *
     * @param versionNumber - The version number for the application that the mobile user has on their device
     *
     * @return - ApplicationVersionResult object that indicates if the mobile user needs a new app and where to get it from
     */
    private static ApplicationVersionResult checkApplicationVersion(String versionNumber) {

        // Get the most recent application
        ApplicationVersionSettings__c mostRecent = getMostRecentApplicationVersionSetting();

        if (mostRecent == null) {
            return new ApplicationVersionResult('', false);
        }

        // Compare the version numbers to
        Integer versionComparison = compareApplicationVersionNumbers(versionNumber, mostRecent.Name);

        // Decide if the mobile user needs to update their application version
        ApplicationVersionResult result;
        if (versionComparison == 0) {
            result = new ApplicationVersionResult('', false);
        }
        else {
            result = new ApplicationVersionResult(mostRecent.DownloadUrl__c, true);
        }
        return result;
    }

    /**
     * Find the most recent application version available and check that the mobile user has it.
     * At the moment there is not concept of allowing the application to be made avaiable
     * to a subset of Mobile Users. So the query here looks at all ApplicationVersions
     *
     * @return - The ApplicationVerionSettings__c record for the most recently 
     * available application version
     */
    private static ApplicationVersionSettings__c getMostRecentApplicationVersionSetting() {
        ApplicationVersionSettings__c mostRecentVersion;
        // Loop through the available application versions and get the most recent
        // one based on the Release Date
        for (
                ApplicationVersionSettings__c version :
                ApplicationVersionSettingsSelector.getActiveRecords(
                    ApplicationVersionSettingsSelector.getAllSortedRecords(
                        ApplicationVersionSettings__c.Name.getDescribe().getName(),
                        SObjectSelector.DESCENDING_OPERATOR
                    )
                )
        ) {
            // Check that the release date is not in the future
            if (version.ReleaseDate__c.getTime() > DateTime.now().getTime()) {
                continue;
            }
            // Get the most recent version that has been released
            mostRecentVersion = version;
            break;
        }
        return mostRecentVersion;
    }

    /**
     * Compare two application version numbers
     * Version numbers are of the format x.y.z
     *
     * @param existingVersionNumber - The version number for the application version that the mobile user has on their device
     * @param compareVersionNumber  - The version number for the application version that is being compared
     *
     * @return - Integer indicating if the version the mobile user has is the same, newer or older
     *             - -1 indicates that the existingVersion is older
     *             -  0 indicates that the version numbers match
     *             -  1 indicates that the existingVersion is newer
     */
    private static Integer compareApplicationVersionNumbers(String existingVersionNumber, String compareVersionNumber) {

        // Convert both version number strings to integers
        Integer existingVersion = Integer.valueOf(String.join(existingVersionNumber.split('\\.'), ''));
        Integer compareVersion = Integer.valueOf(String.join(compareVersionNumber.split('\\.'), ''));
        if (existingVersion == compareVersion) {
            return 0;
        }
        else if (existingVersion < compareVersion) {
            return -1;
        }
        return 1;
    }

    /**
     * Private class the represents the result from comparing application versions.
     * applicationAvailable will equal true if the Mobile User needs to update their applcation
     * downloadUrl will be an empty string if no update is required
     */
    public class ApplicationVersionResult {

        // The url that the application version can be found
        String downloadUrl;

        // Indicates if an update needs to be downloaded
        Boolean applicationAvailable;

        /**
         * Constructor for the class
         */
        public ApplicationVersionResult(String downloadUrl, Boolean applicationAvailable) {
            this.downloadUrl = downloadUrl;
            this.applicationAvailable = applicationAvailable;
        }

        /**
         * Getter for the downloadUrl
         *
         * @return - The download url
         */
        public String getDownloadUrl() {
            return this.downloadUrl;
        }

        /**
        * Getter for applicationAvailable
        *
        * @return - Boolean to indicate if an application is available
        */
        public Boolean getApplicationAvailable() {
            return this.applicationAvailable;
        }
    }
}
