/**
 * Domain class for the PPITableDataSet__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class PpiTableDataSetDomain extends SObjectDomain {

    public PpiTableDataSetDomain() {
        super(PPITableDataSet__c.SObjectType);
    }

    public PpiTableDataSetDomain(List<PPITableDataSet__c> sObjects) {
        super(sObjects);
    }

    /**
     * Create new PpiTableDataSet record related to each ppiTable id and Survey
     * TODO - Remove this and use addRecordsForPpiTables() below
     */
    public PPITableDataSet__c createRecord(
            Id ppiTableInstanceId,
            Survey__c survey
    ) {
        GenericObjectCreator ppiTableDataSetCreator =
            new GenericObjectCreator(PPITableDataSet__c.SObjectType);
        PPITableDataSet__c newDataSet =
                (PPITableDataSet__c) ppiTableDataSetCreator.createNewRecord();
        ppiTableDataSetCreator.populateFields(
            newDataSet,
            new Map<Schema.SObjectField, Object> {
                PPITableDataSet__c.PPITable__c => ppiTableInstanceId,
                PPITableDataSet__c.Survey__c => survey.Id,
                PPITableDataSet__c.SurveyVersion__c => survey.SurveyVersions__r[0].Id
            }
        );
        return newDataSet;
    }

    /**
     * Create a record
     */
    public PPITableDataSet__c createRecord() {
        return (PPITableDataSet__c) this.genericObjectCreator.createNewRecord();
    }

    public UnitOfWork addRecordsForPpiTables(
            List<PPITable__c> localTables,
            UnitOfWork unitOfWork,
            Survey__c survey,
            SurveyVersion__c version
    ) {
        unitOfWork.addToInsertionOrder(PPITableDataSet__c.getSObjectType(), 1);
        for (PPITable__c localTable : localTables) {
            PPITableDataSet__c dataSet = this.createRecord();
            unitOfWork.addToInsertList(
                dataSet,
                PPITableDataSet__c.SurveyVersion__c,
                version,
                1
            );
            unitOfWork.createRelationship(
                dataSet,
                PPITableDataSet__c.Survey__c,
                survey,
                1
            );
            unitOfWork.createRelationship(
                dataSet,
                PPITableDataSet__c.PPITable__c,
                localTable,
                1
            );
            this.addRecord(dataSet);
        }
        return unitOfWork;
    }

    /**
     * Create a map of each ppi table data Sets with PpiTable PovertyLine Name as its Key
     */
    public static Map<Id, PPITableDataSet__c> getPpiTablePovertyLineToDataSetMap(
            Set<String> ppiPovertyLineNames,
            Survey__c survey
    ) {
        Map<Id, PPITableDataSet__c> mapPpiTableWithDataSets =
            new Map<Id, PPITableDataSet__c>();
        for (PPITableDataSet__c dataSet :
            new PpiTableDataSetSelector().getForSurveyVersionAndPovertyLineNames(
                survey.SurveyVersions__r[0].Id,
                ppiPovertyLineNames
            )
        ) {
            mapPpiTableWithDataSets.put(dataSet.PPITable__c, dataSet);
        }
        return mapPpiTableWithDataSets;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public PpiTableDataSetDomain constructWithRecords(List<SObject> sObjectList) {
            return new PpiTableDataSetDomain(sObjectList);
        }
        public PpiTableDataSetDomain constructEmpty() {
            return new PpiTableDataSetDomain();
        }
    }
}
