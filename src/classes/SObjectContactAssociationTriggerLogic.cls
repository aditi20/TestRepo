/**
 * Logic for trigger handling for the SObjectContactAssociation__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class SObjectContactAssociationTriggerLogic extends TriggerHandler {

    private SObjectContactAssociationDO getTriggerDomain() {
        return (SObjectContactAssociationDO) this.domain;
    }

    /**
     * Defaults to apply before insert
     */
    public override void applyDefaults() {
        getTriggerDomain().setUniqueKeys((List<SObjectContactAssociation__c>) getRecords());
    }

    public override void onBeforeUpdate(Map<Id, sObject> oldMap) {
        getTriggerDomain().setUniqueKeys((List<SObjectContactAssociation__c>) getRecords());
    }
}