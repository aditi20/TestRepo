/**
 * Test class for the PpiDataSubmission
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
@isTest
public with sharing class PpiDataSubmissionTest {

    /**
     * Test method for processing Ppi Result Data 
     */
    static testmethod void testProcessPostRequest() {
        PpiDataSubmissionServiceTest.setUpTestData();

        Test.startTest();
        PpiDataSubmission.processPostRequest();
        Test.stopTest();

        // Assert success
        System.assertEquals(C.HTTP_OK, RestContext.response.statusCode);
    }
}