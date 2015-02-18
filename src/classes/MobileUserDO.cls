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
    public static final String PARTNER_USER_TYPE = 'PowerPartner';

    /**
     * Get a list of the contact.Id for MobileUsers with that have a certain status
     *
     * @param status - A list of the statuses that are required
     *
     * @return - A list of the ids found
     */
    public static List<Id> getMobileUserContactIds(List<String> status) {
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();
        mobileUserCreator.checkFieldsAccessible(new List<String>{
            'Username__c',
            'Status__c',
            'Contact__c'
        });
        StringBuilder.CommaSeparatedBuilder commaSeparatedBuilder =
            new StringBuilder.CommaSeparatedBuilder(status);
        commaSeparatedBuilder.setShouldEscapeSingleQuotes(true);

        List<Id> mobileUserContactIds = new List<Id>();
        String queryString =
            'SELECT ' +
                'Id, ' +
                'Contact__c ' +
            'FROM ' +
                'Mobile_User__c ' +
            'WHERE ' +
                'Status__c IN (\'' + commaSeparatedBuilder.generateString() + '\')';
        List<Mobile_User__c> mobileUsers = DBFullAccess.querySObject(queryString);
        for (Mobile_User__c mobileUser : mobileUsers) {
            mobileUserContactIds.add(mobileUser.Contact__c);
        }
        return mobileUserContactIds;
    }

    /**
     * Get a list of the contact.Id for Partner Users with that have a certain status
     *
     * @param status - A list of the statuses (Active/ Inactive) that are required
     *
     * @return - A list of Contact ids found
     */
    public static List<Id> getPartnerUserContactIds(List<Boolean> status) {
        GenericObjectCreator userCreator =
                new GenericObjectCreator(User.SObjectType);
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(new List<String>{
            'isActive',
            'UserType',
            'ContactId'
        });
        List<Id> partnerUserContactIds = new List<Id>();
        String queryString =
            'SELECT ' +
                'Id, ' +
                'ContactId ' +
            'FROM ' +
                'User ' +
            'WHERE ' +
                'UserType = \''+ PARTNER_USER_TYPE + '\' ' +
            'AND ' +
                'isActive IN ' + status;
        List<User> partnerUsers = DBFullAccess.querySObject(queryString);
        for (User partnerUser : partnerUsers) {
            partnerUserContactIds.add(partnerUser.ContactId);
        }
        return partnerUserContactIds;
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
        StringBuilder.CommaSeparatedBuilder commaSeparatedBuilder =
            new StringBuilder.CommaSeparatedBuilder(status);
        commaSeparatedBuilder.setShouldEscapeSingleQuotes(true);
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(new List<String>{
            'Name',
            'OwnerId'
        });
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();
        mobileUserCreator.checkFieldsAccessible(new List<String>{
            'Username__c',
            'Status__c',
            'Last_Login__c',
            'Contact__c'
        });
        String mobileUsersQuery =
            'SELECT ' +
                'Id, ' +
                'Contact__c, ' +
                'Contact__r.Name, ' +
                'Contact__r.OwnerId, ' +
                'Username__c, ' +
                'Status__c, ' +
                'Last_Login__c ' +
            'FROM ' +
                'Mobile_User__c ' +
            'WHERE ' +
                'Status__c IN (\'' + commaSeparatedBuilder.generateString() + '\')';

        if (ApplicationSettingsUtils.isJobFilterEnable()) {
            mobileUsersQuery += ' AND Contact__r.OwnerId = \'' + UserInfo.getUserId() + '\'';
        }

        mobileUsersQuery += ' ORDER BY Contact__r.Name';

        return DBFullAccess.querySObject(mobileUsersQuery);
    }

    /**
     * Get a list of mobile users with any status.
     */
    public static List<Mobile_User__c> getAllMobileUsers() {
        GenericObjectCreator accountCreator =
            new GenericObjectCreator(Account.SObjectType);
        accountCreator.checkObjectAccessible();
        accountCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Account.Name,
                Account.isPartner
            }
        );
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name,
                Contact.Email,
                Contact.OwnerId,
                Contact.AccountId,
                Contact.FirstName,
                Contact.LastName
            }
        );
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();
        mobileUserCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Mobile_User__c.Contact__c,
                Mobile_User__c.Status__c,
                Mobile_User__c.Username__c,
                Mobile_User__c.Last_Login__c
            }
        );
        return [
            SELECT
                Id,
                Contact__c,
                Contact__r.Name,
                Contact__r.Email,
                Contact__r.OwnerId,
                Contact__r.AccountId,
                Contact__r.Account.Name,
                Contact__r.Account.isPartner,
                Contact__r.FirstName,
                Contact__r.LastName,
                Username__c,
                Status__c,
                Last_Login__c,
                CreatedById,
                CreatedBy.Name,
                CreatedDate,
                LastModifiedById,
                LastModifiedBy.Name,
                LastModifiedDate
            FROM
                Mobile_User__c
            WHERE
                Status__c IN :new List<String>{STATUS_ACTIVE, STATUS_INACTIVE}
            ORDER BY Contact__r.Name
        ];
    }

    /**
     * Get a list of Partner users
     */
    public static List<User> getPartnerUsers() {
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name
            }
        );
        GenericObjectCreator userCreator =
            new GenericObjectCreator(User.SObjectType);
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                User.Username,
                User.Name,
                User.ContactId,
                User.LastLoginDate,
                User.Email,
                User.isActive
            }
        );
        return [
            SELECT
                Id,
                Username,
                Email,
                ContactId,
                Contact.Name,
                LastLoginDate,
                IsActive,
                CreatedById,
                CreatedBy.Name,
                CreatedDate,
                LastModifiedById,
                LastModifiedBy.Name,
                LastModifiedDate
            FROM
                User
            WHERE
                UserType =: PARTNER_USER_TYPE
        ];
    }

    /**
     * Get a list of Partner users of provided contact Id's
     */
    public static List<User> getPartnerUsers(Set<Id> contactIds) {
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name
            }
        );
        GenericObjectCreator userCreator =
            new GenericObjectCreator(User.SObjectType);
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                User.Username,
                User.Name,
                User.ContactId,
                User.LastLoginDate,
                User.Email,
                User.isActive
            }
        );
        return [
            SELECT
                Id,
                Username,
                Email,
                ContactId,
                Contact.Name,
                LastLoginDate,
                IsActive,
                CreatedById,
                CreatedBy.Name,
                CreatedDate,
                LastModifiedById,
                LastModifiedBy.Name,
                LastModifiedDate
            FROM
                User
            WHERE
                UserType =: PARTNER_USER_TYPE
            AND
                ContactId IN :contactIds
        ];
    }

    /**
     * Get a list of Active/Inactive Partner users
     */
    public static List<User> getPartnerUsersStatusWise(Boolean status) {
        GenericObjectCreator contactCreator =
                new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(new List<String>{
            'Name',
            'OwnerId'
        });
        GenericObjectCreator userCreator =
                new GenericObjectCreator(User.SObjectType);
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(new List<String>{
            'isActive',
            'UserType',
            'ContactId',
            'UserName',
            'LastLoginDate',
            'Email',
            'Name'
        });
        String partnerUsersQuery =
            'SELECT ' +
                'Id, ' +
                'Username, ' +
                'Email, ' +
                'ContactId, ' +
                'Contact.Name, ' +
                'LastLoginDate, ' +
                'IsActive, ' +
                'CreatedById, ' +
                'CreatedBy.Name, ' +
                'CreatedDate, ' +
                'LastModifiedById, ' +
                'LastModifiedBy.Name, ' +
                'LastModifiedDate ' +
            'FROM ' +
                'User ' +
            'WHERE ' +
                'UserType = \'' + PARTNER_USER_TYPE + '\' ' +
            'AND ' +
                'isActive = ' + status;

        if (ApplicationSettingsUtils.isJobFilterEnable()) {
            partnerUsersQuery += ' AND Contact.OwnerId = \'' + UserInfo.getUserId() + '\'';
        }
        partnerUsersQuery += ' ORDER BY Contact.Name';
        return DBFullAccess.querySObject(partnerUsersQuery);
    }

    /**
     * Get a User from it's Id
     */
    public static User getPartnerUser(Id userId) {
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name
            }
        );
        GenericObjectCreator userCreator =
            new GenericObjectCreator(User.SObjectType);
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                User.Username,
                User.Name,
                User.ContactId,
                User.LastLoginDate,
                User.Email,
                User.isActive,
                User.UserType
            }
        );
        return [
            SELECT
                Id,
                Username,
                Email,
                ContactId,
                Contact.Name,
                LastLoginDate,
                IsActive,
                UserType,
                UserPermissionsSFContentUser,
                CreatedById,
                CreatedBy.Name,
                CreatedDate,
                LastModifiedById,
                LastModifiedBy.Name,
                LastModifiedDate
            FROM
                User
            WHERE
                Id = :userId
        ];
    }

    /**
     * Get a Mobile User from it's Id
     */
    public static Mobile_User__c getMobileUser(Id mobileUserId) {
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name,
                Contact.Email,
                Contact.OwnerId
            }
        );
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();
        mobileUserCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Mobile_User__c.Contact__c,
                Mobile_User__c.Status__c,
                Mobile_User__c.Username__c,
                Mobile_User__c.Password__c,
                Mobile_User__c.Last_Login__c
            }
        );
        return [
            SELECT
                Name,
                Contact__c,
                Contact__r.Name,
                Contact__r.OwnerId,
                Contact__r.Email,
                Username__c,
                Password__c,
                Status__c,
                Last_Login__c,
                CreatedById,
                CreatedBy.Name,
                CreatedDate,
                LastModifiedById,
                LastModifiedBy.Name,
                LastModifiedDate
            FROM
                Mobile_User__c
            WHERE Id = :mobileUserId LIMIT 1
        ];
    }

    /**
     * Get list of Mobile Users from specified Contact Ids
     */
    public static List<Mobile_User__c> getMobileUsers(Set<Id> contactIds) {
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name,
                Contact.Email,
                Contact.OwnerId
            }
        );
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();
        mobileUserCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Mobile_User__c.Contact__c,
                Mobile_User__c.Status__c,
                Mobile_User__c.Username__c,
                Mobile_User__c.Password__c,
                Mobile_User__c.Last_Login__c
            }
        );
        return [
            SELECT
                Name,
                Contact__c,
                Contact__r.Name,
                Contact__r.OwnerId,
                Contact__r.Email,
                Username__c,
                Password__c,
                Status__c,
                Last_Login__c,
                CreatedById,
                CreatedBy.Name,
                CreatedDate,
                LastModifiedById,
                LastModifiedBy.Name,
                LastModifiedDate
            FROM
                Mobile_User__c
            WHERE
                Contact__c = :contactIds
        ];
    }

    /**
     * Get the mobile user record for the given contact id
     */
    public static Mobile_User__c getMobileUserForContact(Id contactId) {
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name
            }
        );
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();
        mobileUserCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Mobile_User__c.Contact__c,
                Mobile_User__c.Status__c,
                Mobile_User__c.Username__c,
                Mobile_User__c.Last_Login__c
            }
        );
        return [
            SELECT
                Id,
                Name,
                Username__c,
                Contact__c,
                Contact__r.Name,
                Last_Login__c,
                Status__c
            FROM
                Mobile_User__c
            WHERE Contact__c = :contactId
            LIMIT 1
        ];

    }

    /**
     * Fetch the users from the database and create the wrappers for them
     */
    public static List<UserWrapper> getUsersWrappers(String usersFilter) {
        List<UserWrapper> users = new List<UserWrapper>();
        if (
            usersFilter == System.Label.OLD_MOBILE_USERS ||
            usersFilter == System.Label.ALL_USERS
        ) {
             for (Mobile_User__c theUser : getAllMobileUsers()) {
                 users.add(new UserWrapper(theUser));
             }
        }
        if (
            usersFilter == System.Label.TAROWORKS_PARTNER_USERS ||
            usersFilter == System.Label.ALL_USERS
        ) {
            for (User theUser : getPartnerUsers()) {
                users.add(new UserWrapper(theUser));
            }
        }
        return users;
    }

    /**
     * Get the UserWrapper for the given id
     */
    public static UserWrapper getUserWrapper(Id userId) {
        UserWrapper wrappedUser;
        GenericObjectCreator contactCreator =
                new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name,
                Contact.Email
            }
        );
        if (userId.getSObjectType() == Mobile_User__c.getSObjectType()) {
            GenericObjectCreator mobileUserCreator =
                new GenericObjectCreator(Mobile_User__c.SObjectType);
            mobileUserCreator.checkObjectAccessible();
            mobileUserCreator.checkFieldsAccessible(
                new List<Schema.SObjectField> {
                    Mobile_User__c.Username__c,
                    Mobile_User__c.Contact__c,
                    Mobile_User__c.Last_Login__c,
                    Mobile_User__c.Status__c
                }
            );
            wrappedUser = new MobileUserDO.UserWrapper(getMobileUser(userId));
        }
        else if (userId.getSObjectType() == User.getSObjectType()) {
            GenericObjectCreator userCreator =
                new GenericObjectCreator(User.SObjectType);
            userCreator.checkObjectAccessible();
            userCreator.checkFieldsAccessible(
                new List<Schema.SObjectField> {
                    User.Username,
                    User.Name,
                    User.ContactId,
                    User.LastLoginDate,
                    User.Email,
                    User.isActive
                }
            );
            wrappedUser = new MobileUserDO.UserWrapper(getPartnerUser(userId));
        }
        return wrappedUser;
    }

    /**
     * Returns username to be used for Partner user.
     */
    public static String createUserName(
            Mobile_User__c mobileUserInstance,
            String domainForPartnerUsers
    ) {
        GenericObjectCreator mobileUserCreator =
            new GenericObjectCreator(Mobile_User__c.SObjectType);
        mobileUserCreator.checkObjectAccessible();
        mobileUserCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Mobile_User__c.Username__c
            }
        );
        String finalUserName = '';
        finalUserName =
            mobileUserInstance.Username__c.replace('@', '').replace('.','').replace(' ', '');
        return finalUserName + '@' + domainForPartnerUsers;
    }

    /**
     * Get profile id based on name passed
     */
    public static Profile getProfileId(String profileName) {
        GenericObjectCreator profileCreator =
                new GenericObjectCreator(Profile.SObjectType);
        profileCreator.checkObjectAccessible();
        return [
            SELECT
                Id
            FROM
                Profile
            WHERE
                Name = :profileName LIMIT 1
        ];
    }

    /*
     * Wrapper class to show both types of user in the page
     */
    public class UserWrapper {
        public Id id {get; set;}
        public String username {get; set;}
        public Id contactId {get; set;}
        public String contactName {get; set;}
        public String email {get; set;}
        public DateTime lastLogin {get; set;}
        public Boolean isActive {get; set;}
        public Boolean isPartner {get; set;}
        public Id createdById {get; set;}
        public String createdBy {get; set;}
        public DateTime createdDate {get; set;}
        public Id lastModifiedById {get; set;}
        public String lastModifiedBy {get; set;}
        public DateTime lastModifiedDate {get; set;}

        /**
         * Constructor for a Mobile_User__c
         */
        public UserWrapper(Mobile_User__c theUser) {
            this.username = theUser.Username__c;
            this.contactId = theUser.Contact__c;
            this.contactName = theUser.Contact__r.Name;
            this.email = theUser.Contact__r.Email;
            this.lastLogin = theUser.Last_Login__c;
            this.isActive = theUser.Status__c == MobileUserDO.STATUS_ACTIVE;
            this.isPartner = false;
            this.id = theUser.Id;
            this.createdById = theUser.CreatedById;
            this.createdBy = theUser.CreatedBy.Name;
            this.createdDate = theUser.CreatedDate;
            this.lastModifiedById = theUser.LastModifiedById;
            this.lastModifiedBy = theUser.LastModifiedBy.Name;
            this.lastModifiedDate = theUser.LastModifiedDate;
        }

        /**
         * Constructor for a Partner user
         */
        public UserWrapper(User theUser) {
            this.username = theUser.Username;
            this.contactId = theUser.ContactId;
            this.contactName = theUser.Contact.Name;
            this.email = theUser.Email;
            this.lastLogin = theUser.LastLoginDate;
            this.isActive = theUser.IsActive;
            this.isPartner = true;
            this.id = theUser.Id;
            this.createdById = theUser.CreatedById;
            this.createdBy = theUser.CreatedBy.Name;
            this.createdDate = theUser.CreatedDate;
            this.lastModifiedById = theUser.LastModifiedById;
            this.lastModifiedBy = theUser.LastModifiedBy.Name;
            this.lastModifiedDate = theUser.LastModifiedDate;
        }
    }
}