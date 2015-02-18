/**
 * Domain class for the PPITable__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class PpiTableDomain extends SObjectDomain {

    public static final String SPLITTER = '_';

    public PpiTableDomain() {
        super(PPITable__c.SObjectType);
    }

    public PpiTableDomain(List<PPITable__c> sObjects) {
        super(sObjects);
    }

    /**
     * Method to return all orphan PpiTable records that are not linked to any dataSets
     */
    public List<PPITable__c> getOrphanPpiTables(Set<Id> ppiTableIds) {
        List<PPITable__c> orphanPpiTables = new List<PPITable__c>();

        for (PPITable__c ppiTable :
                new PpiTableSelector().getForIdsWithPpiTableDataSets(ppiTableIds)
        ) {
            if (ppiTable.PPI_Table_Data_Sets__r.isEmpty()) {
                orphanPpiTables.add(ppiTable);
            }
        }
        return orphanPpiTables;
    }

    /**
     * Create a map of each ppi table PovertyLineName and its instance for specific survey version
     * @return a map with each ppi table
     */
    public static Map<String, PPITable__c> getPovertyLineNameToPpiTableMap(
            Set<String> povertyLineNames,
            Survey__c survey
    ) {
        Map<String, PPITable__c> povertyLineNameToPpiTableMap = new Map<String, PPITable__c>();
        Set<String> uniqueTableNames = getUniquePpiTableNames(povertyLineNames, survey);
        Map<String, String> mapLowerCaseToActualLineNames = new Map<String, String>();
        GenericObjectCreator ppiTableCreator =
            new GenericObjectCreator(PPITable__c.SObjectType);

        for (String povertyLineName : povertyLineNames) {
            mapLowerCaseToActualLineNames.put(povertyLineName.toLowerCase(), povertyLineName);
        }

        // Fill map with records from database to update Name and Poverty Line
        // if table names already exists
        for (PPITable__c ppiTableInstance :
                new PpiTableSelector().getForPpiTableNames(uniqueTableNames)
        ) {
            String povertyLineLowerCase = ppiTableInstance.PovertyLine__c.toLowerCase();
            ppiTableCreator.populateFields(
                ppiTableInstance,
                new Map<Schema.SObjectField, Object> {
                    PPITable__c.Name =>
                        PpiTableDomain.generateUniqueIdForPpiTableName(
                            mapLowerCaseToActualLineNames.get(povertyLineLowerCase),
                            survey
                        ),
                    PPITable__c.PovertyLine__c =>
                        mapLowerCaseToActualLineNames.get(povertyLineLowerCase)
                }
            );
            povertyLineNameToPpiTableMap.put(
                mapLowerCaseToActualLineNames.get(povertyLineLowerCase),
                ppiTableInstance
            );
            mapLowerCaseToActualLineNames.remove(povertyLineLowerCase);
        }

        // Fill map with records to insert new PpiTable records along with Name as uniqueId
        // if tableName is not present in database
        for (String povertyLineName : mapLowerCaseToActualLineNames.values()) {
            PPITable__c newPpiTable = (PPITable__c) ppiTableCreator.createNewRecord();
            ppiTableCreator.populateFields(
                newPpiTable,
                new Map<Schema.SObjectField, Object> {
                    PPITable__c.Name =>
                        PpiTableDomain.generateUniqueIdForPpiTableName(povertyLineName, survey),
                    PPITable__c.PovertyLine__c => povertyLineName
                }
            );

            povertyLineNameToPpiTableMap.put(
                povertyLineName,
                newPpiTable
            );
        }

        return povertyLineNameToPpiTableMap;
    }

    /**
     * Method to generate Set of Unique PpiTable Names
     */
    @TestVisible
    private static Set<String> getUniquePpiTableNames(
            Set<String> povertyLineNames,
            Survey__c survey
    ) {
        Set<String> uniqueTableNames = new Set<String>();
        for (String name : povertyLineNames) {
            uniqueTableNames.add(generateUniqueIdForPpiTableName(name, survey));
        }
        return uniqueTableNames;
    }

    /**
     * Method to generate Unique Id for PpiTable Name
     */
    @TestVisible
    private static String generateUniqueIdForPpiTableName(String ppiTableName, Survey__c survey) {
        String uniquePpiTableName = ppiTableName + SPLITTER +
            ISOCountryWrapper.getInstanceWithName(survey.CountryCode__c).ShortName__c + SPLITTER +
            survey.PPIDataYear__c;
        Integer tableNameLength = Schema.SObjectType.PPITable__c.fields.Name.getLength();
        if (uniquePpiTableName.length() > tableNameLength) {
            throw new LookupTablesService.LookupTablesServiceException(
                String.format(
                    System.Label.LOOKUP_ERR_NAMETOOLONG,
                    new String[] {
                        uniquePpiTableName,
                        String.valueOf(tableNameLength)
                    }
                )
            );
        }
        return uniquePpiTableName;
    }

    /**
     * Delete all Ppi Table records along with table lines
     */
    public void deleteWithTableLines() {
        Set<Id> ppiTableIds = new Set<Id>();
        for (PPITable__c ppiTable : (List<PPITable__c>) records) {
            ppiTableIds.add(ppiTable.Id);
        }

        // Delete Ppi table lines before deleting Ppi Tables
        PpiTableLineDomain tableLineDomainInstance =
            new PpiTableLineDomain.Constructor().constructWithRecords(
                new PpiTableLineSelector().getForPpiTableIds(ppiTableIds)
            );
        tableLineDomainInstance.deleteRecords();
    }

    /**
     * Create a map with a given field as a key
     */
    public Map<String, PPITable__c> getMapWithNameAsKey() {
        Map<String, PPITable__c> foundTables = new Map<String, PPITable__c>();
        for (PPITable__c  table : (List<PPITable__c>) this.records) {
            foundTables.put(table.Name, table);
        }
        return foundTables;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public PpiTableDomain constructWithRecords(List<SObject> sObjectList) {
            return new PpiTableDomain(sObjectList);
        }
        public PpiTableDomain constructEmpty() {
            return new PpiTableDomain();
        }
    }
}
