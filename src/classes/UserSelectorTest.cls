/**
 * This class contains test methods for validating the behavior of UserSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 */
@isTest
public with sharing class UserSelectorTest {

    /**
     * Testdata for User object
     */
    static User createTestData() {
        Profile profile = TestUtils.getTaroworksProfile();
        User user = UserDomainTest.createRecord(
            profile,
            'User',
            'taroworks@user.com'
        );
        return user;
    }

    /**
     * Test method to verify fetching of User records
     */
    static testMethod void testGetWithProfile() {
        List<User> existingUserList = new UserSelector().getForProfile('TaroWorks User');

        User user = createTestData();
        UserDomain domainInstance = new UserDomain();
        domainInstance.addRecord(user);
        domainInstance.insertRecords();

        Test.startTest();
        List<User> userList = new UserSelector().getForProfile('TaroWorks User');
        Test.stopTest();

        System.assertEquals(1, userList.size() - existingUserList.size());
    }
}