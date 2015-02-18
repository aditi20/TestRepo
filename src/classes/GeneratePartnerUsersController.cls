/**
 * Controller logic to generate Partner users
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 */
public with sharing class GeneratePartnerUsersController{

    public Id partnerAccountSelected {get; set;}
    public String domainForPartnerUsers {get; set;}
    public String emailForPartnerUsers {get; set;}
    public List<SelectOption> partnerAccounts {get; set;}
    public Boolean isResultPage {get; set;}
    public Set<Id> finalListSuccessUsers {get; set;}

    Map<Id,Mobile_User__c> mapToMigrateMobileUsers {get; set;}
    Set<Id> setExisitngUserNamesMobileUserId {get; set;}
    Map<Id, Contact> mapContactToUpdate {get; set;}
    List<User> listPartnerUsersToInsert {get; set;}
    private GenericObjectCreator contactCreator {
        get{
            return new GenericObjectCreator(Contact.SObjectType);
        }
        set;
    }
    private GenericObjectCreator userCreator {
        get{
            return new GenericObjectCreator(User.SObjectType);
        }
        set;
    } 

    public GeneratePartnerUsersController() {
        isResultPage = false;
        mapToMigrateMobileUsers = new Map<Id,Mobile_User__c>();
        mapContactToUpdate = new Map<Id, Contact>();
        listPartnerUsersToInsert = new List<User>();
        finalListSuccessUsers = new Set<Id>();
        partnerAccounts = new List<SelectOption>();

        GenericObjectCreator accountCreator =
            new GenericObjectCreator(Account.SObjectType);
        accountCreator.checkObjectAccessible();
        accountCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Account.Name,
                Account.isPartner
            }
        );

        // Get all partner accounts
        for (Account accountInstance : [
            SELECT
                Id,
                Name
            FROM
                Account
            WHERE
                isPartner = true
            ORDER BY Name
        ]) {
            partnerAccounts.add(new SelectOption(accountInstance.id, accountInstance.Name));
        }

        // If no Partner accounts present display error message on page and disable Migrate button
        if (partnerAccounts == null || partnerAccounts.isEmpty()) {
            addError(Label.NO_PARTNER_ACCOUNT_ERROR);
        }
    }

    /**
     * This method will initiate creation of Partner users.
     */
    public void migrateMobileUsers() {
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.AccountId
            }
        );

        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                User.Username,
                User.FirstName,
                User.LastName,
                User.Alias,
                User.Email,
                User.EmailEncodingKey,
                User.LanguageLocaleKey,
                User.LocalesIdKey,
                User.TimezonesIdKey,
                User.IsActive,
                User.ProfileId,
                User.ContactId,
                User.CommunityNickname
            }
        );

        mapToMigrateMobileUsers = new Map<Id,Mobile_User__c>();
        Map<String,id> mapUserNameToContactId = new Map<String,Id>();

        // Get all relevant mobile users to be migrated.
        for (Mobile_User__c mobileUserInstance : MobileUserDo.getAllMobileUsers()) {
            mapToMigrateMobileUsers.put(mobileUserInstance.Contact__c, mobileUserInstance);
            mapUserNameToContactId.put(
                MobileUserDo.createUserName(
                    mobileUserInstance,
                    domainForPartnerUsers
                ),
                mobileUserInstance.Contact__c
            );
        }

        // Remove mobile users for which we already have a User created
        removeExistingUsers(mapUserNameToContactId);

        // Remove mobile users for which username have already been taken
        removeInvalidUserNamesMobileUsers(mapUserNameToContactId);

        // Populate remaining contacts for which we need to update Account Id
        populateExistingContactsToUpdate();

        // Update contact list with appropriate Account Id
        if (!updateContactsWithPartnerAccount()) {
            return;
        }

        // Create all users corresponding to success Contact updated
        if (mapContactToUpdate != null && !mapContactToUpdate.keySet().isEmpty()) {
            populatePartnerUsersDetails();
            if (!insertPartnerUsers()) {
                return;
            }
        }

        // All activities done - so we can display results
        isResultPage = true;
    }

    /**
     * This method will insert all Partner users finally created
     *
     * @return - true if Partners inserted successfully
     */
    private Boolean insertPartnerUsers() {
        userCreator.checkObjectCreateable();
        finalListSuccessUsers = new Set<Id>();
        try {
            // Adding dml options will allow to send auto emails to end users.
            isResultPage = true;
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.EmailHeader.triggerUserEmail = true;
            Database.SaveResult[] saveResultList = Database.insert(listPartnerUsersToInsert, dmlOptions);
            for (Database.SaveResult saveResultInstance : saveResultList) {
                if (saveResultInstance.isSuccess()) {
                    // Will be used to display final Partner user inserted in results page
                    finalListSuccessUsers.add(saveResultInstance.getId());
                } else {
                    for(Database.Error error : saveResultInstance.getErrors()) {
                        // When we have insufficient Licences available.
                        // Then none of the users gets inserted. Display message
                        if (String.valueOf(error.getStatusCode()) == 'LICENSE_LIMIT_EXCEEDED') {
                            addError(Label.LICENSE_LIMIT_EXCEEDED);
                            isResultPage = false;
                        }
                    }
                }
            }
        } catch (Exception genericException) {
            addError('Following error occured : ' + genericException.getMessage());
            isResultPage = false;
            return isResultPage;
        }
        return isResultPage;
    }

    /**
     * This method will be used to update all relevant Contact records with Partner Account.
     *
     * @return - true if Contacts updated succesfully with Partner Account
     */
    private Boolean updateContactsWithPartnerAccount() {
        contactCreator.checkObjectUpdateable();
        try {
            Database.SaveResult[] saveResultList = Database.update(mapContactToUpdate.values(), false);
            for (Database.SaveResult saveResultInstance : saveResultList) {
                if (!saveResultInstance.isSuccess()) {
                    mapContactToUpdate.remove(saveResultInstance.getId());
                }
            }
            isResultPage = true;
        } catch (Exception genericException) {
            addError('Following error occured : ' + genericException.getMessage());
            isResultPage = false;
        }
        return isResultPage;
    }

    /**
     * This method will be used to display results of inserted Partner users.
     */
    public List<MobileUserDo.UserWrapper> getDisplayResult() {
        userCreator.checkObjectAccessible();
        userCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                User.ContactId
            }
        );
        Set<Id> contactIdsInserted = new Set<Id>();
        for (User userInstance : [
            SELECT
                Id,
                ContactId
            FROM
                User
            WHERE
                Id IN : finalListSuccessUsers
        ]) {
            contactIdsInserted.add(userInstance.ContactId);
        }
        List<MobileUserDo.UserWrapper> users = new List<MobileUserDo.UserWrapper>();
        for (User partnerUser : MobileUserDo.getPartnerUsers(contactIdsInserted)) {
            users.add(new MobileUserDo.UserWrapper(partnerUser));
        }
        return users;
    }

    /**
     * This method will get all mobile users for which Usernames have already been taken
     */
    public List<MobileUserDo.UserWrapper> getMobileUsersWithExistingUsernames() {
        List<MobileUserDo.UserWrapper> users = new List<MobileUserDo.UserWrapper>();
        for (Mobile_User__c theUser :
                MobileUserDo.getMobileUsers(setExisitngUserNamesMobileUserId)
        ) {
            users.add(new MobileUserDo.UserWrapper(theUser));
        }
        return users;
    }

    /**
     * Create list of partner users to be inserted
     */
    private void populatePartnerUsersDetails() {
        listPartnerUsersToInsert = new List<User>();
        Id taroworksPartnerProfileId = MobileUserDo.getProfileId(Label.TAROWORKS_PARTNER_USER).Id;
        for (Contact contactInstance : mapContactToUpdate.values()) {
            // Active Partner users should be created for active mobile users
            if (mapToMigrateMobileUsers.get(contactInstance.Id).Status__c == MobileUserDO.STATUS_ACTIVE) {
                listPartnerUsersToInsert.add(
                    getUser(
                        contactInstance,
                        taroworksPartnerProfileId,
                        true,
                        emailForPartnerUsers
                    )
                );
            } else if (
                mapToMigrateMobileUsers.get(contactInstance.Id).Status__c ==
                    MobileUserDO.STATUS_INACTIVE
            ) {
                listPartnerUsersToInsert.add(
                    getUser(
                        contactInstance,
                        taroworksPartnerProfileId,
                        false,
                        emailForPartnerUsers
                    )
                );
            }
        }
    }

    /**
     * Return a new User instance that will be populated based on Contact details
     *
     * @param   - Contact instance to be linked to User
     * @param   - taroworksPartnerProfileId ~ will have details of profile to link to user
     * @param   - isActive ~ to tell status of user
     *
     * @return  - user instance holding all necessary details to be inserted
     */
    public User getUser(
        Contact contactInstance,
        Id taroworksPartnerProfileId,
        Boolean isActive,
        String emailForPartner
    ) {
        User userInstance =
            (User) userCreator.createNewRecord();
        userCreator.populateFields(
            userInstance,
            new Map<Schema.SObjectField, Object> {
                User.Username => MobileUserDo.createUserName(
                    mapToMigrateMobileUsers.get(contactInstance.Id),
                    domainForPartnerUsers
                ),
                User.FirstName => contactInstance.FirstName,
                User.LastName => contactInstance.LastName,
                User.Alias => String.valueOf(Crypto.getRandomInteger()).substring(0,8),
                User.Email => emailForPartner,
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                User.LocalesIdKey => 'en_US',
                User.TimezonesIdKey => 'America/Los_Angeles',
                User.IsActive => isActive,
                User.ProfileId => taroworksPartnerProfileId,
                User.ContactId => contactInstance.Id,
                User.CommunityNickname => contactInstance.LastName + Crypto.getRandomInteger()
            }
        );
        return userInstance;
    }

    /**
     * This method will populate all Contacts that needs to be updated with Partner account
     */
    private void populateExistingContactsToUpdate() {
        mapContactToUpdate = new map<Id, Contact>();
        for (Id contactId : mapToMigrateMobileUsers.keySet()) {
            // Only update Contact Account details if the account is not a Partner account
            if (mapToMigrateMobileUsers.get(contactId).Contact__r.Account.isPartner == false) {
                contactCreator.populateField(
                    mapToMigrateMobileUsers.get(contactId).Contact__r,
                    Contact.AccountId,
                    partnerAccountSelected
                );
            }
            mapContactToUpdate.put(contactId, mapToMigrateMobileUsers.get(contactId).Contact__r);
        }
    }

    /**
     * This method will remove all mobile users for which user name has already been taken
     */
    private void removeInvalidUserNamesMobileUsers (Map<String, Id> mapUserNameToContactId) {
        setExisitngUserNamesMobileUserId = new Set<Id>();
        for (User userInstance : [
            SELECT
                Id,
                ContactId,
                Username
            FROM
                User
            WHERE
                Username IN : mapUserNameToContactId.keySet()
        ]) {
            setExisitngUserNamesMobileUserId.add(
                mapUserNameToContactId.get(
                    userInstance.Username
                )
            );
            mapToMigrateMobileUsers.remove(mapUserNameToContactId.get(userInstance.Username));
        }
    }

    /**
     * Remove all users who are already present corresponding to the mobile user contact ids
     */
    private void removeExistingUsers(Map<String, Id> mapUserNameToContactId) {
        for (User userInstance : [
            SELECT
                Id,
                ContactId
            FROM
                User
            WHERE
                ContactId IN : mapToMigrateMobileUsers.keySet()
        ]) {
            mapUserNameToContactId.remove(
                MobileUserDo.createUserName(
                    mapToMigrateMobileUsers.get(userInstance.ContactId),
                    domainForPartnerUsers
                )
            );
            mapToMigrateMobileUsers.remove(userInstance.ContactId);
        }
    }

    /**
     * This method will be used to add error messages in page
     */
    private void addError(String errorMessage) {
        ApexPages.addMessage(
            new ApexPages.message(
                ApexPages.severity.ERROR,
                errorMessage
            )
        );
    }
}