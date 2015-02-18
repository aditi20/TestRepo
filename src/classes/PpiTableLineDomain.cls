/**
 * Domain class for the PPITableLine__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class PpiTableLineDomain extends SObjectDomain {

    public PpiTableLineDomain() {
        super(PPITableLine__c.SObjectType);
    }

    public PpiTableLineDomain(List<PPITableLine__c> sObjects) {
        super(sObjects);
    }

    /**
     * Create new Ppi Table Line record
     */
    public PPITableLine__c createRecord(
            Id ppiTableInstanceId,
            Decimal fromValue,
            Decimal toValue,
            Decimal probability
    ) {
        GenericObjectCreator ppiTableLineCreator =
            new GenericObjectCreator(PPITableLine__c.SObjectType);
        PPITableLine__c ppiTableLine =
                (PPITableLine__c) ppiTableLineCreator.createNewRecord();
        ppiTableLineCreator.populateFields(
            ppiTableLine,
            new Map<Schema.SObjectField, Object> {
                PPITableLine__c.PPITable__c => ppiTableInstanceId,
                PPITableLine__c.From__c => fromValue,
                PPITableLine__c.To__c => toValue,
                PPITableLine__c.Probability__c => probability
            }
        );
        return ppiTableLine;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public PpiTableLineDomain constructWithRecords(List<SObject> sObjectList) {
            return new PpiTableLineDomain(sObjectList);
        }
        public PpiTableLineDomain constructEmpty() {
            return new PpiTableLineDomain();
        }
    }
}
