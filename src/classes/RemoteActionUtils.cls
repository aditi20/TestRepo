/**
 * Class created to store remote action calls.
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Claudio Soto csoto@altimetrik.com
 * @author Aditi Satpute
 */
global with sharing class RemoteActionUtils {

    public RemoteActionUtils(Object cont){

    }

    /**
     * Obtain list of contacts in the org.
     * @return List of ContactWrapper (wrapper of Contact) saved in the org.
     */
    @RemoteAction
    global static List<ContactWrapper> getClients(){
        List<ContactWrapper> contactList = new List<ContactWrapper>();
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Contact.Name
            }
        );
        List<Contact> contacts = [SELECT Id, Name FROM Contact ORDER BY Name];
        for (Contact contact : contacts){
            contactList.add(new ContactWrapper(contact));
        }
        return contactList;
    }

    /**
     * Obtain list of contacts in the org considered field staff.
     * @return List of ContactWrapper (wrapper of Contact) of field staff Contacts saved in the org.
     */
    @RemoteAction
    global static List<ContactWrapper> getStaffs() {
        Map<Id, ContactWrapper> contactWrapperMap = new Map<Id, ContactWrapper>();
        List<MobileUserDO.UserWrapper> userWrapperList =
            MobileUserDO.getUsersWrappers(System.Label.ALL_USERS);
        for (MobileUserDO.UserWrapper mobileUserInstance : userWrapperList) {
            if (!contactWrapperMap.containsKey(mobileUserInstance.contactId)) {
                contactWrapperMap.put(
                    mobileUserInstance.contactId,
                    new ContactWrapper(mobileUserInstance)
                );
            }
        }
        return contactWrapperMap.values();
    }

    /**
     * Wrapper class for Contact (only saves Name and Id).
     */
    global class ContactWrapper {
        public String label {get;set;}
        public Id id {get;set;}

        // This constructor will be used to populate Mobile users
        public ContactWrapper(Contact orgContact) {
            this.id    = orgContact.Id;
            this.label = orgContact.Name;
        }

        // This constructor will be used to populate Partner Users
        public ContactWrapper(MobileUserDO.UserWrapper mobileUserInstance) {
            this.id    = mobileUserInstance.id;
            this.label = mobileUserInstance.contactName;
        }
    }

}
