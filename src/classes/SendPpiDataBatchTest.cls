/**
 * This class contains test methods for validating the behavior of SendPpiDataBatch
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 */
@isTest
public class SendPpiDataBatchTest {

    /**
     * Test to verify that batch processes all data to be sent to parent Ppi org.
     */
    static testMethod void testSendPpiDataBatch() {

        SurveyLibraryDomainTest.addLibraryToDatabase(C.GRAMEEN_LIBRARY);

        List<PpiResult__c> ppiResultList =
            PpiResultDomainTest.createSamplePpiResultData(1, false);
        System.assertEquals(1, ppiResultList.size());

        Test.startTest();
        Database.executeBatch(
            new SendPpiDataBatch(
                new PpiResultSelector().generateSyncQuery(false)
            )
        );
        Test.stopTest();

        List<PpiResult__c> ppiResultFetchedList =
            new PpiResultSelector().getAllWithSyncTrue(new Set<Id> {ppiResultList[0].Id});
        System.assert(
            !ppiResultFetchedList.isEmpty(),
            'Ppi result should return record with updated value'
        );
        System.assertEquals(1, ppiResultFetchedList.size());
    }
}