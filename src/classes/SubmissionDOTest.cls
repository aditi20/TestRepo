/**
 * Test class for SubmissionDO
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public with sharing class SubmissionDOTest {

        static testMethod void testUpdateSubmissions() {

        // Create some surveys
        Survey__c s1 = new Survey__c( Name = 'Testing Survey 1', Description__c = 'A Description' );
        Survey__c s2 = new Survey__c( Name = 'Testing Survey 2', Description__c = 'A Description' );
        Database.insert(new Survey__c[]{s1,s2});

        // Create a three Groups
        ContactGroup__c g1 = new ContactGroup__c( Name = 'Group1aaaaaa' );
        ContactGroup__c g2 = new ContactGroup__c( Name = 'Group2bbbbbb' );
        Database.insert(new ContactGroup__c[]{g1,g2});

        // Create a couple of surveyors
        Contact c1 = new Contact( LastName = 'c1' );
        Contact c2 = new Contact( LastName = 'c2' );
        Database.insert(new Contact[]{c1,c2});

        // Assign surveys to the groups
        ContactGroupSurveyAssignment__c cgsa1 = new ContactGroupSurveyAssignment__c( Survey__c = s1.Id, ContactGroup__c = g1.Id );
        ContactGroupSurveyAssignment__c cgsa2 = new ContactGroupSurveyAssignment__c( Survey__c = s1.Id, ContactGroup__c = g2.Id );
        ContactGroupSurveyAssignment__c cgsa3 = new ContactGroupSurveyAssignment__c( Survey__c = s2.Id, ContactGroup__c = g1.Id );
        ContactGroupSurveyAssignment__c cgsa4 = new ContactGroupSurveyAssignment__c( Survey__c = s2.Id, ContactGroup__c = g2.Id );
        Database.insert( new ContactGroupSurveyAssignment__c[]{cgsa1, cgsa2, cgsa3, cgsa4} );

        // Assign members to the groups
        Database.insert(new List<ContactGroupMember__c>{
            new ContactGroupMember__c( Contact__c = c1.Id , ContactGroup__c = g1.Id ),
            new ContactGroupMember__c( Contact__c = c2.Id , ContactGroup__c = g1.Id ),
            new ContactGroupMember__c( Contact__c = c1.Id , ContactGroup__c = g2.Id )
        });

        // Create some submissions
        Submission__c[] submissions = new Submission__c[]{
            new Submission__c ( Survey__c = s1.Id, Surveyor__c = c1.Id ),
            new Submission__c ( Survey__c = s1.Id, Surveyor__c = c1.Id ),
            new Submission__c ( Survey__c = s2.Id, Surveyor__c = c1.Id ),
            new Submission__c ( Survey__c = s1.Id, Surveyor__c = c2.Id ),
            new Submission__c ( Survey__c = s2.Id, Surveyor__c = c2.Id )
        };

        // Add the assignment group to the submission
        Test.startTest();
        List<Submission__c> resultSubmissions = SubmissionDO.linkSubmissionsAssignmentGroups(submissions);
        Test.stopTest();
        System.assertEquals(resultSubmissions.size(), 5);

        System.assertEquals(cgsa2.Id, resultSubmissions[0].Assignment__c, resultSubmissions[0]);
        System.assertEquals(cgsa2.Id, resultSubmissions[1].Assignment__c, resultSubmissions[1]);
        System.assertEquals(cgsa4.Id, resultSubmissions[2].Assignment__c, resultSubmissions[2]);
        System.assertEquals(cgsa1.Id, resultSubmissions[3].Assignment__c, resultSubmissions[3]);
        System.assertEquals(cgsa3.Id, resultSubmissions[4].Assignment__c, resultSubmissions[4]);
    }
}