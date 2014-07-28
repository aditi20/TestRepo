/*
 * DO class for the Mobile_User__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved.
 *
 * @author - Owen Davies (odavies@grameenfoundation.org)
 */
public with sharing class MobileUserDO {

    public static final String STATUS_ACTIVE   = 'Active';
    public static final String STATUS_INACTIVE = 'Inactive';

    /**
     * Get a list of the contact.Id for MobileUsers with that have a certain status
     *
     * @param status - A list of the statuses that are required
     *
     * @return - A list of the ids found
     */
    public static List<Id> getMobileUserContactIds(List<String> status) {

        List<Id> mobileUserContactIds = new List<Id>();
        String queryString =
            'SELECT ' +
                'Id, ' +
                'Contact__c ' +
            'FROM ' +
                'Mobile_User__c ' +
            'WHERE ' +
                'Status__c IN (\'' + String.join(status, '\',\'') + '\')';
        List<Mobile_User__c> mobileUsers = DBFullAccess.querySObject(queryString);
        for (Mobile_User__c mobileUser : mobileUsers) {
            mobileUserContactIds.add(mobileUser.Contact__c);
        }
        return mobileUserContactIds;
    }

    /**
     * Get a list of mobile users with the given status.
     * The result is filtered if job filter is on
     *
     * @param status - A list of the statuses that are required
     *
     * @return - A list of mobile users
     */
    public static List<Mobile_User__c> getMobileUsers(List<String> status) {

        String mobileUsersQuery =
            'SELECT ' +
                'Id, ' +
                'Contact__c, ' +
                'Contact__r.Name, ' +
                'Contact__r.OwnerId ' +
            'FROM ' +
                'Mobile_User__c ' +
            'WHERE ' +
                'Status__c IN (\'' + String.join(status, '\',\'') + '\')';

        if (ApplicationSettingsUtils.isJobFilterEnable()) {
            mobileUsersQuery += ' AND Contact__r.OwnerId = \'' + UserInfo.getUserId() + '\'';
        }

        mobileUsersQuery += ' ORDER BY Contact__r.Name';

        return DBFullAccess.querySObject(mobileUsersQuery);
    }

    /**
     * Get a Mobile User from it's Id
     */
    public static Mobile_User__c getMobileUser(Id mobileUserId) {
        return [
            SELECT
                Name,
                Contact__c
            FROM
                Mobile_User__c
            WHERE Id = :mobileUserId LIMIT 1
        ];
    }

    /**
     * Get the mobile user record for the given contact id
     */
    public static Mobile_User__c getMobileUserForContact(Id contactId) {
        return [
            SELECT
                Id,
                Name
            FROM
                Mobile_User__c
            WHERE Contact__c = :contactId
            LIMIT 1
        ];

    }

}