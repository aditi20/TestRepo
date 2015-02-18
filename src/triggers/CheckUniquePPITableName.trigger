/**
 * - This trigger check that the name of the table is unique for the survey
 * - Delete PPITableLines on delete of PPITables
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */

trigger CheckUniquePPITableName on PPITable__c (
        before insert,
        before update,
        before delete
) {
    TriggerHandler.triggerHandler(PpiTableDomain.class);
}