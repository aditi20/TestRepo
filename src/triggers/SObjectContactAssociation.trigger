/**
 * Trigger for the SObjectContactAssociation__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
trigger SObjectContactAssociation on SObjectContactAssociation__c (before insert, before update) {
    TriggerHandler.triggerHandler(SObjectContactAssociationDO.class);
}