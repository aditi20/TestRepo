/**
 * Test class for the AttachmentDomain
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class AttachmentDomainTest {

    private static Attachment attachment1;
    private static Attachment attachment2;
    private static List<SurveyVersion__c> surveyVersions;

    /**
     * Create Attachment record
     */
    public static Attachment createRecord(
            String attachmentName,
            SurveyVersion__c surveyVersion
    ) {
        return new Attachment(
            Name = attachmentName,
            ParentId = surveyVersion.Id,
            body = Blob.valueOf('test')
        );
     }

    /**
     * Test method to verify Attachment records are inserted properly
     */
    static testmethod void testInsertRecords() {
        setUpTestData();

        Test.startTest();
        AttachmentDomain attachmentDomainInstance =
            new AttachmentDomain.Constructor().constructWithRecords(
                new List<Attachment> {attachment1, attachment2}
            );
        attachmentDomainInstance.insertRecords();
        Test.stopTest();

        List<Attachment> attachments =
            new AttachmentSelector().getAllWithParentId(
                new Set<Id> {surveyVersions[0].Id, surveyVersions[1].Id},
                'Attachment1'
            );

        // Attachment records are inserted properly in database
        System.assertEquals(
            2,
            attachments.size()
        );
    }

    /**
     * Test method to verify Attachment records are deleted properly
     */
    static testmethod void testDeleteRecords() {
        setUpTestData();

        AttachmentDomain attachmentDomainInstance =
            new AttachmentDomain.Constructor().constructWithRecords(
                new List<Attachment> {attachment1, attachment2}
            );
        attachmentDomainInstance.insertRecords();

        List<Attachment> attachments =
            new AttachmentSelector().getAllWithParentId(
                new Set<Id> {surveyVersions[0].Id, surveyVersions[1].Id},
                'Attachment1'
            );

        // Attachment records are present in database
        System.assertEquals(
            2,
            attachments.size()
        );

        Test.startTest();
        attachmentDomainInstance =
            new AttachmentDomain.Constructor().constructWithRecords(
                attachments
            );
        attachmentDomainInstance.deleteRecords();
        Test.stopTest();

        attachments =
            new AttachmentSelector().getAllWithParentId(
                new Set<Id> {surveyVersions[0].Id, surveyVersions[1].Id},
                'Attachment1'
            );

        // Attachment records are deleted from database
        System.assertEquals(
            0,
            attachments.size()
        );
    }

    /**
     * Method to set up test data for attachment
     */
    private static void setUpTestData() {
        Survey__c survey1 = SurveyDOTest.createInsertedSurvey('Test Survey 1');
        Survey__c survey2 = SurveyDOTest.createInsertedSurvey('Test Survey 2');

        surveyVersions =
            new SurveyVersionSelector().getAllWithSurveyIds(
                new Set<String> {
                    survey1.Id,
                    survey2.Id
                }
            );

        attachment1 =
            AttachmentDomainTest.createRecord('Attachment1', surveyVersions[0]);
        attachment2 =
            AttachmentDomainTest.createRecord('Attachment1', surveyVersions[1]);
    }
}