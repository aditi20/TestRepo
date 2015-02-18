/**
 * Clean Orphan PpiTable records after deleting PpiTableDataSets
 * 
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
trigger CleanTableLines on PPITableDataSet__c (after delete) {
    TriggerHandler.triggerHandler(PpiTableDataSetDomain.class);
}