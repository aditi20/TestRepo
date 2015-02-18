/**
 * This class contains logic for CleanTableLines Trigger on PpiTableDataSet.
 * Delete orphan PpiTable records if its related PpiTableDataSets are deleted
 *
 * (c) Copyright 2015 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class PpiTableDataSetTH extends TriggerHandler {

    /**
     * After Delete
     *
     * Actions carried out:-
     *     - Delete all orphan PpiTable record if its related PpiTableDataSet is deleted
     */
    public override void onAfterDelete() {
        deleteOrphanPpiTables((List<PPITableDataSet__c>) getRecords());
    }

    /**
     * Method to delete PpiTable records only if the last linked dataSet record is also deleted
     */
    private void deleteOrphanPpiTables(List<PPITableDataSet__c> dataSets) {
        List<PPITable__c> orphanPpiTableDeleteList = new List<PPITable__c>();
        Set<Id> ppiTableIds = new Set<Id>();

        for (PPITableDataSet__c dataSet : dataSets) {
            ppiTableIds.add(dataSet.PPITable__c);
        }

        // Fetch all ppiTable records that are no more linked to any DataSet records
        orphanPpiTableDeleteList = new PpiTableDomain().getOrphanPpiTables(ppiTableIds);

        if (!orphanPpiTableDeleteList.isEmpty()) {
            PpiTableDomain ppiTableDomain =
                new PpiTableDomain.Constructor().constructWithRecords(orphanPpiTableDeleteList);
            ppiTableDomain.deleteRecords();
        }
    }
}