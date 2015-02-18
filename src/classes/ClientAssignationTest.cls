/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public class ClientAssignationTest{

    // Client assignment must be unique.
    static testMethod void clientAssignationMustBeUnique() {
        Contact ctc = TestUtils.createContact();
        Mobile_User__c mu = TestUtils.createMobileUser(ctc, 'robert', '1234', MobileUserDO.STATUS_ACTIVE);

        insert new Client_Assignation__c(Client__c = ctc.Id, Mobile_User__c = mu.Id);
        
        Test.startTest();
            // Insert existing assignment
            try {
                insert new Client_Assignation__c(Client__c = ctc.Id, Mobile_User__c = mu.Id);
                system.assert(false, 'Should fail here since ther is a duplicate value');
            }
            catch(DMLException e) {
                system.assert(e.getMessage().contains('duplicate value found'));
            }
        
            // Insert both assignments at same time
            try {
                insert new Client_Assignation__c[]{
                                new Client_Assignation__c(Client__c = ctc.Id, Mobile_User__c = mu.Id),
                                new Client_Assignation__c(Client__c = ctc.Id, Mobile_User__c = mu.Id)};
                system.assert(false, 'Should fail here since are the same assignations to insert');
            }
            catch(DMLException e) {
                system.assert(e.getMessage().contains('duplicate value found'));
            }
        Test.stopTest();
    }
}