/**
 * Test class for the SObject Contact Association Trigger handler class
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public with sharing class SObjectContactAssociationTriggerTest {

    /**
     * Test trigger handling code for beforeInsert
     */
    static testMethod void testBeforeInsertTriggerHandler() {
        List<SObjectContactAssociation__c> associations =
            createBeforeTriggerPreconditions();
        TriggerHandler.tests.mockDatabase.onInsert(associations);
        TriggerHandler.tests.mockDatabase.setIsBefore(true);
        TriggerHandler.triggerHandler(SObjectContactAssociationDO.class);
        System.assertEquals(associations[0].UniqueKey__c, associations[1].UniqueKey__c);
    }

    /**
     * Test correct error gets thrown when two SObjectContactAssociation__c have the same unique key
     */
    static testMethod void testCatchUniqueKeyErrorOnInsert() {

        List<SObjectContactAssociation__c> associations =
            createBeforeTriggerPreconditions();
        try {
            insert associations;
            System.assert(false, 'Cannot save the records as it violates UniqueKey__c constraint');
        } catch (DmlException  e) {
            System.assertEquals(StatusCode.DUPLICATE_VALUE, e.getDmlType(0));
        }
    }

    /**
     * Test trigger handling code for beforeUpdate
     */
    static testMethod void testBeforeUpdateTriggerHandler() {
        List<SObjectContactAssociation__c> associations =
            createBeforeTriggerPreconditions();
        TriggerHandler.tests.mockDatabase.onUpdate(associations, new Map<Id, SObject>());
        TriggerHandler.tests.mockDatabase.setIsBefore(true);
        TriggerHandler.triggerHandler(SObjectContactAssociationDO.class);
        System.assertEquals(associations[0].UniqueKey__c, associations[1].UniqueKey__c);
    }

    /**
     * Create the preconditions to test the trigger handler for unique key addition
     */
    private static List<SObjectContactAssociation__c> createBeforeTriggerPreconditions() {

        Contact associate = TestUtils.createContact('TestLastName');
        List<Id> accountIdsGroup1 = C.extractIds(TestUtils.createAccounts(3));
        List<Id> accountIdsGroup2 = C.extractIds(TestUtils.createAccounts(3));
        String accountApiName = Account.SObjectType.getDescribe().getName();
        List<SObjectContactAssociation__c> associations = new List<SObjectContactAssociation__c>{
            SObjectContactAssociationDO.createNew(
                associate.Id,
                accountApiName,
                accountIdsGroup1,
                1
            ),
            SObjectContactAssociationDO.createNew(
                associate.Id,
                accountApiName,
                accountIdsGroup2,
                1
            )
        };
        return associations;
    }
}