/**
 * Test class for the PPITable__c object domain class
 * Deals with:
 *     - Creation of a PPI Table
 *     - Adding PPI Table to a UnitOfWork
 *
 * Contains a wrapper for a PPI Table to contain all test data for it
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class PpiTableDomainTest {

    public static final String TEST_TABLE_NAME = 'Test Table Name';
    public static final String TEST_IDENTIFIER = 'TEST_IDENTIFIER';
    public static final Decimal TEST_POVERTY_RATE = 0.5;

    public static PPITable__c createPpiTable() {
        return createPpiTable('');
    }

    public static PPITable__c createPpiTable(String suffix) {
        return createPpiTable(
            TEST_TABLE_NAME + suffix,
            TEST_TABLE_NAME + suffix,
            TEST_IDENTIFIER + suffix,
            '',
            TEST_POVERTY_RATE
        );
    }

    public static PPITable__c createPpiTable(String suffix, Survey__c survey) {
        return createPpiTable(
            PpiTableDomain.generateUniqueIdForPpiTableName(TEST_TABLE_NAME + suffix, survey),
            TEST_TABLE_NAME + suffix,
            TEST_IDENTIFIER + suffix,
            '',
            TEST_POVERTY_RATE
        );
    }

    public static PPITable__c createPpiTable(
            String tableName,
            String povertyLine,
            String identifier,
            String remoteId,
            Decimal povertyRate
    ) {
        return createPpiTable(new Map<Schema.SObjectField, Object>{
            PPITable__c.Name => tableName,
            PPITable__c.Identifier__c => identifier,
            PPITable__c.PovertyLine__c => povertyLine,
            PPITable__c.PovertyRate__c => povertyRate,
            PPITable__c.RemoteId__c => remoteId
        });
    }

    public static PPITable__c createPpiTable(
            Map<Schema.SObjectField, Object> fieldMap
    ) {

        GenericObjectCreator creator =
            new GenericObjectCreator(PPITable__c.getSObjectType());
        PPITable__c ppiTable =
            (PPITable__c) creator.createNewRecord();
        creator.populateFields(
            ppiTable,
            fieldMap
        );
        return ppiTable;
    }

    public static List<PPITable__c> createMultiplePpiTables(Integer amount) {
        return createMultiplePpiTables(amount, '');
    }

    public static List<PPITable__c> createMultiplePpiTables(Integer amount, String suffix) {
        List<PPITable__c> tableList = new List<PPITable__c>{};
        for (Integer i = 0; i < amount; i++) {
            tableList.add(
                createPpiTable(
                    TEST_TABLE_NAME + suffix + ' ' + i,
                    TEST_TABLE_NAME + suffix + ' ' + i,
                    TEST_IDENTIFIER + suffix + '_' + i,
                    '',
                    TEST_POVERTY_RATE
                )
            );
        }
        return tableList;
    }

    public static List<PPITable__c> insertMultiplePpiTables(Integer amount) {
        return insertMultiplePpiTables(amount, '');
    }

    public static List<PPITable__c> insertMultiplePpiTables(Integer amount, String suffix) {
        List<PPITable__c> tableList = createMultiplePpiTables(amount, suffix);
        insert tableList;
        return tableList;

    }

    public static UnitOfWork addPpiTableToUnitOfWork(
        PPITable__c ppiTable,
        SurveyLibrary__c surveyLibrary,
        UnitOfWork unitOfWork
    ) {
        unitOfWork.addToInsertionOrder(PPITable__c.getSObjectType(), 1);
        unitOfWork.addToInsertList(
            ppiTable,
            PPITable__c.SurveyLibrary__c,
            surveyLibrary,
            1
        );
        return unitOfWork;
    }

    
    /**
     * Test method to verify fetching orphan PpiTables
     */
    static testMethod void testGetOrphanPpiTables() {
        List<PPITableDataSet__c> expectedPpiDataSets = new List<PPITableDataSet__c>();
        Set<Id> ppiTableIds = new Set<Id>();

        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        List<Survey__c> surveyList =
            new SurveySelector().getWithSurveyVersion(new Set<String> {survey.Id});

        System.assertEquals(1, surveyList.size());
        survey = surveyList[0];

        // Verify survey has fetched Survey Vesion record properly
        System.assert(
            survey.SurveyVersions__r.size() > 0,
            'Survey Version records not fetched properly'
        );
        SurveyVersion__c surveyVersion = survey.SurveyVersions__r[0];

        // Create data for Ppi related Tables
        List<PPITable__c> ppiTables = PpiTableDomainTest.insertMultiplePpiTables(3);
        System.assertEquals(3, ppiTables.size());

        UnitOfWork unitOfWork = new UnitOfWork();

        // Insert individual data set and PpiTable line records for each ppiTable records
        for (Integer i = 0; i < ppiTables.size(); i++) {
            PPITableLine__c ppiTableLine = PpiTableLineDomainTest.createPpiTableLine();
            unitOfWork = PpiTableLineDomainTest.addPpiTableLineToUnitOfWork(
                ppiTableLine,
                ppiTables[i],
                unitOfWork
            );

            // Insert dataset only for last ppiTable record
            if (i == ppiTables.size() - 1) {
                PPITableDataSet__c dataSet = PpiTableDataSetDomainTest.createPpiTableDataSet();

                unitOfWork = PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
                    dataSet,
                    ppiTables[i],
                    survey,
                    surveyVersion,
                    unitOfWork
                );
                expectedPpiDataSets.add(dataSet);
            }
            ppiTableIds.add(ppiTables[i].Id);
        }
        unitOfWork.commitWork();

        // DataSet present only for one Ppitable record
        System.assertEquals(1, expectedPpiDataSets.size());

        // Verify that single PpiTableLine record is present for each PpiTable record
        System.assertEquals(
            3,
            new PpiTableLineSelector().getForPpiTableIds(ppiTableIds).size()
        );

        Test.startTest();
        List<PPITable__c> orphanPpiTables = new PpiTableDomain().getOrphanPpiTables(ppiTableIds);
        Test.stopTest();

        // Verify that orphan PpiTable records are fetched properly
        System.assertEquals(
            2,
            orphanPpiTables.size()
        );

        System.assertEquals(
            ppiTables[0].Id,
            orphanPpiTables[0].Id
        );
        System.assertEquals(
            ppiTables[1].Id,
            orphanPpiTables[1].Id
        );
    }

    /**
     * Test method to verify fetching Map of PovertyLine to PpiTable instance
     */
    static testMethod void testFetchPpiTableMap() {

        TestSurveyData testSurvey = TestSurveyData.addPpiTablesToStandardSurvey(
            TestSurveyData.createStandardTestSurvey(
                SurveyDOTest.createInsertedPpiTemplate(),
                false,
                false
            )
        );
        String ppiTableName = PpiTableDomainTest.TEST_TABLE_NAME + testSurvey.testSurvey.Name;

        // PpiTable records present in database
        System.assert(
            ((List<PPITable__c>) (
                new PpiTableSelector().getRecordsById(new Set<Id> {testSurvey.ppiTables[0].Id})
            )).size() == 1,
            'Ppi tables not inserted into database properly'
        );

        Test.startTest();
        Map<String, PPITable__c> uniquePpiTableNameMap =
            PpiTableDomain.getPovertyLineNameToPpiTableMap(
                new Set<String> {ppiTableName, ppiTableName, 'PPITable2'},
                testSurvey.testSurvey
            );
        Test.stopTest();

        // PpiTable records present in map
        System.assertEquals(
            2,
            uniquePpiTableNameMap.size()
        );
    }

    /**
     * Test method to verify fetching Map of PovertyLine to PpiTable instance for case-insensitive
     * table names and poverty lines
     */
    static testmethod void testFetchPpiTableMapForCaseInsensitive() {
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();

        // Create data for Ppi related Tables
        PPITable__c ppiTable1 =
            createPpiTable('PPITable1', 'PPITable1', 'PPITable1', 'TestRemoteId', 52.3);
        insert ppiTable1;

        // PpiTable records present in database
        System.assert(
            ((List<PPITable__c>) (
                new PpiTableSelector().getRecordsById(new Set<Id> {ppiTable1.Id})
            )).size() == 1,
            'Ppi tables not inserted into database properly'
        );

        Test.startTest();
        Map<String, PPITable__c> uniquePpiTableNameMap =
            PpiTableDomain.getPovertyLineNameToPpiTableMap(
                new Set<String> {'PpiTable1', 'PPITable2'},
                survey
            );
        Test.stopTest();

        // PpiTable records present in map
        System.assertEquals(
            2,
            uniquePpiTableNameMap.size()
        );

        // Verify the case insensitive Name has been properly updated in map properly
        System.assert(
            uniquePpiTableNameMap.get('PpiTable1') != null
        );

        // Verify that no record is present with old name i.e : PPITable1 in map
        System.assert(
            uniquePpiTableNameMap.get('PPITable1') == null
        );
    }

    /**
     * Test method to verify fetching of Unique PpiTable Names
     */
    static testMethod void testFetchUniquePpiTableNames() {

        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        Test.startTest();
        Set<String> uniquePpiTableNameSet =
            PpiTableDomain.getUniquePpiTableNames(
                new Set<String> {'PPITable1', 'PPITable1', 'PPITable2'},
                survey
            );
        Test.stopTest();

        System.assertEquals(2, uniquePpiTableNameSet.size());
    }

    /**
     * Test method to verify generation of Unique Id for PpiTable Name
     */
    static testMethod void testGenerateUniqueIdForPpiTableName() {

        TestSurveyData testSurvey = TestSurveyData.addPpiTablesToStandardSurvey(
            TestSurveyData.createStandardTestSurvey(
                SurveyDOTest.createInsertedPpiTemplate(),
                false,
                false
            )
        );

        // PpiTable records present in database
        System.assert(
            (PPITable__c) (
                new PpiTableSelector().getRecordById(
                    testSurvey.ppiTables[0].Id
                )
            ) != null,
            'Ppi tables not inserted into database properly'
        );

        Test.startTest();
        String actualUniquePpiTableName = PpiTableDomain.generateUniqueIdForPpiTableName(
            testSurvey.ppiTables[0].Name, testSurvey.testSurvey
        );
        Test.stopTest();

        String expectedUniqueTableName = testSurvey.ppiTables[0].Name + PpiTableDomain.SPLITTER +
            ISOCountryWrapper.getInstanceWithName(testSurvey.testSurvey.CountryCode__c).ShortName__c +
            PpiTableDomain.SPLITTER + testSurvey.testSurvey.PPIDataYear__c;

        System.assertEquals(expectedUniqueTableName , actualUniquePpiTableName);
    }

    /**
     * Test method to verify proper error is thrown for long(more than 80 chars) PpiTable Name
     */
    static testmethod void testGenerateUniqueIdForPpiTableLongName() {
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        String longPpiTableName =
            'This is to test Service Lookup Exception for 80 characters name for Ppi Table Name';

        String expectedUniquePpiTableName = longPpiTableName + PpiTableDomain.SPLITTER +
            ISOCountryWrapper.getInstanceWithName(survey.CountryCode__c).ShortName__c +
            PpiTableDomain.SPLITTER + survey.PPIDataYear__c;

        try {
            Test.startTest();
            String actualUniquePpiTableName = PpiTableDomain.generateUniqueIdForPpiTableName(
                longPpiTableName,
                survey
            );
            Test.stopTest();
        } catch (LookupTablesService.LookupTablesServiceException e) {
            Integer tableNameLength = Schema.SObjectType.PPITable__c.fields.Name.getLength();
            System.assertEquals(
                String.format(
                    System.Label.LOOKUP_ERR_NAMETOOLONG,
                    new String[] {
                        expectedUniquePpiTableName,
                        String.valueOf(tableNameLength)
                    }
                ),
                e.getMessage()
            );
        }
    }

    /**
     * Test method for deleting PpiTableLines on delete of specified PpiTables.
     */
    static testMethod void testDeletion() {

        TestSurveyData testSurvey = TestSurveyData.addPpiTablesToStandardSurvey(
            TestSurveyData.createStandardTestSurvey(
                SurveyDOTest.createInsertedPpiTemplate(),
                false,
                false
            )
        );

        // PpiTable records present in database
        System.assert(
            (PPITable__c) (
                new PpiTableSelector().getRecordById(
                    testSurvey.ppiTables[0].Id
                )
            ) != null,
            'Ppi tables not inserted into database properly'
        );

        // PpiTableLine records present in database
        System.assertEquals(
            1,
            new PpiTableLineSelector().getForPpiTableIds(
                new Set<Id> {testSurvey.ppiTables[0].Id}
            ).size()
        );

        Test.startTest();
        PpiTableDomain ppiTableDomainInstance =
            new PpiTableDomain.Constructor().constructWithRecords(
                new List<PPITable__c> {testSurvey.ppiTables[0]}
            );
        ppiTableDomainInstance.deleteWithTableLines();
        Test.stopTest();

        // PpiTableLine records are deleted
        System.assertEquals(
            0,
            new PpiTableLineSelector().getForPpiTableIds(
                new Set<Id> {testSurvey.ppiTables[0].Id}
            ).size()
        );
    }

    static testMethod void testGetMapWithNameAsKey() {
        PpiTableDomain domain = new PpiTableDomain(insertMultiplePpiTables(3));
        Map<String, PPITable__c> tables = domain.getMapWithNameAsKey();
        for (Integer i = 0; i < 3; i++) {
            System.assert(tables.get(TEST_TABLE_NAME + ' ' + i) != null);
        }
    }

    /**
     * Wrapper object to contain a complete PPI table definition
     */
    public class PpiTableWrapper {

        public PPITable__c table;
        public List<PPITableLine__c> tableLines;

        private SurveyLibrary__c surveyLibrary;
        private UnitOfWork unitOfWork;

        public PpiTableWrapper() {
            this.tableLines = new List<PPITableLine__c>();
            this.unitOfWork = new UnitOfWork();
            this.surveyLibrary = null;
        }

        public void createDefaultTable() {
            createDefaultTable('');
        }

        public void commitWork() {
            this.unitOfWork.commitWork();
        }

        public void addTable(String suffix) {
            this.table = PpiTableDomainTest.createPpiTable(suffix);
            this.unitOfWork = PpiTableDomainTest.addPpiTableToUnitOfWork(
                this.table,
                this.surveyLibrary,
                this.unitOfWork
            );
        }

        public void createDefaultTable(String suffix) {
            this.table = PpiTableDomainTest.createPpiTable(suffix);
            this.unitOfWork = PpiTableDomainTest.addPpiTableToUnitOfWork(
                this.table,
                this.surveyLibrary,
                this.unitOfWork
            );
            addLines(2);
            this.unitOfWork.commitWork();
        }

        public void addToSurvey(
                Boolean resetUnitOfWork,
                Survey__c parentSurvey,
                SurveyVersion__c parentSurveyVersion
        ) {
            if (resetUnitOfWork) {
                this.unitOfWork.reset();
            }
            PPITableDataSet__c dataSet =
                PpiTableDataSetDomainTest.createPpiTableDataSet();
            this.unitOfWork =
                PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
                    dataSet,
                    this.table,
                    parentSurvey,
                    parentSurveyVersion,
                    this.unitOfWork
                );
        }

        public PPITable__c refetchTable() {
            return (PPITable__c) new PpiTableSelector().getRecordById(table.Id);
        }

        public void addLines(Integer numberOfLinesRequired) {
            Decimal fromValue = PpiTableLineDomainTest.TEST_FROM_VALUE;
            Decimal probability = PpiTableLineDomainTest.TEST_PROBABILITY;
            Decimal toValue = PpiTableLineDomainTest.TEST_TO_VALUE;
            for (Integer i = 0; i < numberOfLinesRequired; i++) {
                PPITableLine__c newTableLine = PpiTableLineDomainTest.createPpiTableLine(
                    fromValue, probability, '', toValue
                );
                this.unitOfWork = PpiTableLineDomainTest.addPpiTableLineToUnitOfWork(
                    newTableLine,
                    this.table,
                    this.unitOfWork
                );
                this.tableLines.add(newTableLine);
                fromValue += 5;
                probability += 0.05;
                toValue += 5;
            }
        }
    }
}
