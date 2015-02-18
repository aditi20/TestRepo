/**
 * This class contains logic for CheckUniquePPITableName Trigger on PpiTable.
 * Delete PpiTable lines on delete of PPITables
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class PpiTableTH extends TriggerHandler {

    private PpiTableDomain getTriggerDomain() {
        return (PpiTableDomain) this.domain;
    }

    /**
     * Validate unique PpiTable names
     */
    public override void validateBefore() {
        // Verify that PpiTable names are unique
        validateUniquePpiTableName();
    }

    /**
     * Actions carried out:-
     *     - Throw an error if PpiTable name is not unique
     */
    public void validateUniquePpiTableName() {
        // Add the new tables to a map with the name as the key
        Map<String, PPITable__c> namesToTables = new Map<String, PPITable__c>();

        for (PPITable__c table : (List<PPITable__c>) getTriggerDomain().records) {
            // Add tables to the map
            namesToTables.put(table.Name.toLowerCase(), table);
        }

        // Get the tables that match the same name from the database
        List<PPITable__c> savedPpiTables =
            new PpiTableSelector().getForPpiTableNames(namesToTables.keySet());

        if (!savedPpiTables.isEmpty()) {
            // If the tables that match have different Ids add an error
            for (PPITable__c savedTable : savedPpiTables) {
                PPITable__c newTable = namesToTables.get(savedTable.Name.toLowerCase());

                if (newTable != null && savedTable.Id != newTable.Id) {
                    newTable.Name.AddError('The table name must be unique for the survey.');
                }
            }
        }
    }

    /**
     * Before Delete
     *
     * Actions carried out:-
     *     - Delete all PpiTableLines if PpiTable is deleted
     */
    public override void onBeforeDelete() {
        getTriggerDomain().deleteWithTableLines();
    }
}