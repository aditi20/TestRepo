/**
 * This class contains test methods for validating the behavior of UserDomain
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 */
@isTest
public with sharing class UserDomainTest {

    /**
     * Create record for User object 
     */
    public static User createRecord(
            Profile profile,
            String LastName,
            String Email
    ) {
        User user = new User(
            LastName = LastName,
            Alias = 'alias' + String.valueOf(Crypto.getRandomInteger()).subString(0, 2),
            Email = Email,
            UserName = 'taroworks_' + Crypto.getRandomInteger() + '@user.com',
            ProfileId = profile.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocalesIdKey = 'en_US',
            TimezonesIdKey = 'America/Los_Angeles'
        );
        return user;
    }
}