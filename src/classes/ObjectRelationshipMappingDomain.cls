/**
 * Domain class for the ObjectRelationshipMapping__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class ObjectRelationshipMappingDomain extends SObjectDomain {

    public ObjectRelationshipMappingDomain() {
        super(ObjectRelationshipMapping__c.SObjectType);
    }
    public ObjectRelationshipMappingDomain(List<ObjectRelationshipMapping__c> sObjects) {
        super(sObjects);
    }
}