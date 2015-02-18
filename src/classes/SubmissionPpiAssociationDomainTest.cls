/**
 * This class contains test methods for validating the behavior of SubmissionPpiAssociationDomain
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
@isTest
public with sharing class SubmissionPpiAssociationDomainTest {

    public static SubmissionPpiAssociation__c createRecord(
            PpiResult__c ppiResult,
            PPITableLine__c tableLine,
            Submission__c submission
    ) {
        SubmissionPpiAssociation__c submissionPpiAssociation = createRecord(ppiResult, tableLine);
        submissionPpiAssociation.Submission__c = submission.Id;
        return submissionPpiAssociation;
    }

    /**
     * Method to create Submission Record
     */
    static SubmissionPpiAssociation__c createRecord(
            PpiResult__c ppiResult,
            PPITableLine__c tableLine
    ) {
        SubmissionPpiAssociation__c submissionPpiAssociation = new SubmissionPpiAssociation__c(
            PpiResult__c = ppiResult.Id,
            PpiTableLine__c = tableLine.Id
        );
        return submissionPpiAssociation;
    }

    /**
     * Test to verify create Record
     */
    static testMethod void testCreateRecord() {

        List<PpiResult__c> ppiResultList =
            PpiResultDomainTest.createSamplePpiResultData(2, false);
        System.assertEquals(2, ppiResultList.size());

        PPITable__c ppiTable = PpiTableDomainTest.createPpiTable();
        PpiTableDomain ppiTableDoamin = new PpiTableDomain();
        ppiTableDoamin.addRecord(ppiTable);
        ppiTableDoamin.insertRecords();

        PPITableLine__c ppiTableLine = PpiTableLineDomainTest.createPpiTableLine();
        ppiTableLine.PPITable__c = ppiTable.Id;
        PpiTableLineDomain domainInstance = new PpiTableLineDomain();
        domainInstance.addRecord(ppiTableLine);
        domainInstance.insertRecords();

        Test.startTest();
        SubmissionPpiAssociation__c submissionPpiAssociation =
            SubmissionPpiAssociationDomain.createRecord(ppiResultList[0], ppiTableLine);
        Test.stopTest();

        System.assert(
            submissionPpiAssociation != null,
            'SubmissionPpiAssociation record not created properly'
        );
    }

    /**
     * Test to verify Submission Ppi Association records are linked to submission record
     */
    static testMethod void testSetSubmissionIdForPpiAssociations() {

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('lastNameSCT', true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);

        TestSurveyData testSurvey =
            TestSurveyData.createFullPpiTemplate();
        String xml =
        '<?xml version=\'1.0\' ?><data id="' + testSurvey.testSurveyVersion.Id + '">'+
            '<start>2012-02-14T19:23:53.463</start>'+
            '<end>2012-02-14T19:24:40.816</end>'+
            '<today>2012-02-14</today>'+
            '<deviceid>356402040028589</deviceid>'+
            '<simid />'+
            '<location>70.0 80.0 0.0 1400.0</location>'+
            '<phonenumber />'+
            '<new_section><name>' + 
            testSurvey.getSection(1).Name + '</name>' +
                '<'+ testSurvey.getQuestion(1, 0).Name +'>' + testSurvey.getOption(1, 0, 0).Id +
                '</'+ testSurvey.getQuestion(1, 0).Name +'>'+
                '<'+ testSurvey.getQuestion(1, 2).Name +'>' + '4' +
                '</'+ testSurvey.getQuestion(1, 2).Name +'>' +
                '<'+ testSurvey.getQuestion(1, 3).Name +'>' +
                Datetime.newInstanceGMT(2000, 01, 02, 00, 00, 00) +
                '</'+ testSurvey.getQuestion(1, 3).Name +'>' +
            '</new_section>' +
            '<new_section><name>' +
            testSurvey.getSection(2).Name + '</name>' +
                '<'+ testSurvey.getQuestion(2, 1).Name +'>' + testSurvey.getOption(2, 1, 0).Id +
                '</'+ testSurvey.getQuestion(2, 1).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 2).Name +'>' + testSurvey.getOption(2, 2, 0).Id +
                '</'+ testSurvey.getQuestion(2, 2).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 5).Name +'>' + testSurvey.getOption(2, 5, 0).Id +
                '</'+ testSurvey.getQuestion(2, 5).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 6).Name +'>' + testSurvey.getOption(2, 6, 0).Id +
                '</'+ testSurvey.getQuestion(2, 6).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 8).Name +'>' + testSurvey.getOption(2, 8, 0).Id +
                '</'+ testSurvey.getQuestion(2, 8).Name +'>'+
                '<'+ testSurvey.getQuestion(2, 9).Name +'>' + testSurvey.getOption(2, 9, 0).Id +
                '</'+ testSurvey.getQuestion(2, 9).Name +'>'+
            '</new_section>' +
        '</data>';

        Submission submissionInstance =
            TestUtils.submitNewSubmission(xml, surveyor.loginResult);

        List<PpiResult__c> ppiResults =
            new PpiResultSelector().getAllForSurveyVersionIds(
                new Set<Id> {testSurvey.testSurveyVersion.Id}
            );

        System.assertEquals(1, ppiResults.size());

        Test.startTest();
        new SubmissionPpiAssociationDomain().setSubmissionIdForPpiAssociations(
            ppiResults[0],
            submissionInstance.getExistingSubmissionId()
        );
        Test.stopTest();

        List<SubmissionPpiAssociation__c> ppiAssociations =
            new SubmissionPpiAssociationSelector().getForPpiResult(
                new Set<String> {ppiResults[0].Id}
            );

        System.assertEquals(1, ppiAssociations.size());

        // Verify Submission record is linked properly to Submission Ppi Association records
        System.assertEquals(
            submissionInstance.getExistingSubmissionId(),
            ppiAssociations[0].Submission__c
        );
    }
}