/**
 * This class contains unit tests for validating the behavior of AccountDomain
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
@isTest
public with sharing class AccountDomainTest {

    /**
     * Create Account record with all necessary data
     */
    public static Account createRecord(
            String name,
            Integer numberOfEmployees,
            String site,
            String accountNumber
    ) {
        Account account = new Account(
            Name = name,
            NumberOfEmployees = numberOfEmployees,
            Site = site,
            AccountNumber = accountNumber
        );
        return account;
    }
}