/**
 * Domain class for the User object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 */
public with sharing class UserDomain extends SObjectDomain {

    public UserDomain() {
        super(User.SObjectType);
    }

    public UserDomain(List<User> sObjects) {
        super(sObjects);
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public UserDomain constructWithRecords(List<SObject> sObjectList) {
            return new UserDomain(sObjectList);
        }
        public UserDomain constructEmpty() {
            return new UserDomain();
        }
    }
}