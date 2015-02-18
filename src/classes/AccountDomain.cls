/**
 * Domain class for Account object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
public with sharing class AccountDomain extends SObjectDomain {

    public AccountDomain() {
        super(Account.SObjectType);
    }

    public AccountDomain(List<Account> sObjects) {
        super(sObjects);
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public AccountDomain constructWithRecords(List<sObject> sObjectList) {
            return new AccountDomain(sObjectList);
        }

        public AccountDomain constructEmpty() {
            return new AccountDomain();
        }
    }
}