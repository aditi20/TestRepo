/**
 * Test class for the AttachmentSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class AttachmentSelectorTest {

    /**
     * Test method to verify fetching of Attachment records for specified
     * parent Ids and Name
     */
    static testmethod void testFetchAllForParentIds() {
        List<Attachment> attachments = new List<Attachment>();
        Survey__c survey1 = SurveyDOTest.createInsertedSurvey('Test Survey 1');
        Survey__c survey2 = SurveyDOTest.createInsertedSurvey('Test Survey 2');

        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(
                new Set<String> {
                    survey1.Id,
                    survey2.Id
                }
            );

        Attachment attachment1 =
            AttachmentDomainTest.createRecord('Attachment1', surveyVersions[0]);
        Attachment attachment2 =
            AttachmentDomainTest.createRecord('Attachment1', surveyVersions[1]);
        Attachment attachment3 =
            AttachmentDomainTest.createRecord('Attachment2', surveyVersions[1]);

        AttachmentDomain attachmentDomainInstance =
            new AttachmentDomain.Constructor().constructWithRecords(
                new List<Attachment> {attachment1, attachment2, attachment3}
            );
        attachmentDomainInstance.insertRecords();

        Test.startTest();
        System.assertEquals(2, surveyVersions.size());

        attachments =
            new AttachmentSelector().getAllWithParentId(
                new Set<Id> {surveyVersions[0].Id, surveyVersions[1].Id},
                'Attachment1'
            );
        Test.stopTest();

        // Attachment records are fetched properly
        System.assertEquals(2, attachments.size());
    }

    /**
     * Test method to verify fetching of Attachment records for specified
     * parent Ids and Name, order by Last Modified date
     */ 
    static testMethod void testGetAllWithParentIdOrdered () {
        List<Attachment> attachments = new List<Attachment>();
        Survey__c survey1 = SurveyDOTest.createInsertedSurvey('Test Survey 1');
        Survey__c survey2 = SurveyDOTest.createInsertedSurvey('Test Survey 2');

        List<SurveyVersion__c> surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(
                new Set<String> {
                    survey1.Id,
                    survey2.Id
                }
            );
        System.assertEquals(2, surveyVersions.size());

        Attachment attachment1 =
            AttachmentDomainTest.createRecord('Attachment1', surveyVersions[0]);
        Attachment attachment2 =
            AttachmentDomainTest.createRecord('Attachment1', surveyVersions[1]);

        AttachmentDomain attachmentDomainInstance =
            new AttachmentDomain.Constructor().constructWithRecords(
                new List<Attachment> {attachment1, attachment2}
            );
        attachmentDomainInstance.insertRecords();

        List<Attachment> expectedAttachments = new List<Attachment>();
        expectedAttachments = 
            new AttachmentSelector().getAllWithParentId(
                new Set<Id> {surveyVersions[0].Id, surveyVersions[1].Id},
                'Attachment1'
            );
        System.assertEquals(2, expectedAttachments.size());

        C.wait(2);
        expectedAttachments[0].Body = Blob.valueOf('Updated Test');
        AttachmentDomain attachemntDomain = new AttachmentDomain();
        attachemntDomain.addRecord(expectedAttachments[0]);
        attachemntDomain.updateRecords();

        Test.startTest();
        attachments =
            new AttachmentSelector().getAllWithParentIdOrdered(
                new Set<Id> {surveyVersions[0].Id, surveyVersions[1].Id},
                'Attachment1'
            );
        Test.stopTest();

        System.assertEquals(2, attachments.size());
        System.assertEquals(expectedAttachments[0].ParentId, attachments[1].ParentId);
    }
}