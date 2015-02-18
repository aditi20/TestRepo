/**
 * This class contains test methods for validating the behavior of SubmissionPpiAssociationSelector
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
@isTest
public with sharing class SubmissionPpiAssociationSelectorTest {

    /**
     * Test to verify fetching of SubmissionPpiAssociation records for specified PpiResult Ids
     */
    static testMethod void testGetForPpiResult() {

        List<PpiResult__c> ppiResultList =
            PpiResultDomainTest.createSamplePpiResultData(3, false);

        PPITable__c ppiTable = PpiTableDomainTest.createPpiTable();
        PpiTableDomain ppiTableDoamin = new PpiTableDomain();
        ppiTableDoamin.addRecord(ppiTable);
        ppiTableDoamin.insertRecords();

        PPITableLine__c ppiTableLine = PpiTableLineDomainTest.createPpiTableLine();
        ppiTableLine.PPITable__c = ppiTable.Id;
        PpiTableLineDomain domainInstance = new PpiTableLineDomain();
        domainInstance.addRecord(ppiTableLine);
        domainInstance.insertRecords();

        SubmissionPpiAssociation__c submissionPpiAssociation =
            SubmissionPpiAssociationDomain.createRecord(ppiResultList[0], ppiTableLine);
        SubmissionPpiAssociationDomain instance = new SubmissionPpiAssociationDomain();
        instance.addRecord(submissionPpiAssociation);
        instance.insertRecords();

        Set<String> ppiResultIds = new Set<String>();
        for (PpiResult__c ppiResult : ppiResultList) {
            ppiResultIds.add(ppiResult.Id);
        }

        Test.startTest();
        List<SubmissionPpiAssociation__c> submissionPpiAssociationList =
            new SubmissionPpiAssociationSelector().getForPpiResult(ppiResultIds);
        Test.stopTest();

        System.assert(submissionPpiAssociationList.size() != 0, 'Could not fetch records.');
    }

    /**
     * Test to verify fetching of SubmissionPpiAssociation records for specified submission Ids
     */
    static testMethod void testGetForSubmissionIds() {

        TestUtils.Surveyor surveyor = TestUtils.createPartnerSurveyor('Test surveyor', true);
        surveyor = TestUtils.partnerLoginDetails(surveyor);

        TestSurveyData testSurvey = TestSurveyData.createFullPpiTemplate();
        System.assert(testSurvey != null, 'Survey data not created properly');

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
        System.assert(submissionInstance != null, 'Submission record not found.');

        Test.startTest();
        List<SubmissionPpiAssociation__c> submissionPpiAssociations =
            new SubmissionPpiAssociationSelector().getForSubmissionIds(
                new Set<Id> {submissionInstance.getExistingSubmissionId()}
            );
        Test.stopTest();
        System.assert(
            submissionPpiAssociations != null,
            'SubmissionPpiAssociation records not found.'
        );
        System.assertEquals(1, submissionPpiAssociations.size());
    }
}