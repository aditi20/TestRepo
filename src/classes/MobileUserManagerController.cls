/**
 * Controller class for the Mobile User Manager page
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
public with sharing class MobileUserManagerController {

    public List<MobileUserDO.UserWrapper> users {get; set;}
    public Id userId {get; set;}
    public String userFilter {get; set;}

    public List<SelectOption> userList {
        get {
            userList = new List<SelectOption>();
            userList.add(new SelectOption(System.Label.ALL_USERS, System.Label.ALL_USERS));
            userList.add(new SelectOption(
                System.Label.OLD_MOBILE_USERS,
                System.Label.OLD_MOBILE_USERS
            ));
            userList.add(new SelectOption(
                System.Label.TAROWORKS_PARTNER_USERS,
                System.Label.TAROWORKS_PARTNER_USERS
            ));
            return userList;
        }
        set;
    }

    /**
     * Constructor of the class
     */
    public MobileUserManagerController() {
        this.userFilter = System.Label.ALL_USERS;
        // Get both mobile and partner user values
        this.users = MobileUserDO.getUsersWrappers(this.userFilter);
    }

    /**
     * Returns result for selected user filter
     */
    public PageReference performUserFilter() {
        this.users = MobileUserDO.getUsersWrappers(this.userFilter);
        return null;
    }
}