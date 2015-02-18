/**
* Grameen: Salesforce - Ppi Upload
* This is the test class for the LookupTablesController class
*
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
* @author - Alejandro De Gregorio
* @author - Aditi Satpute
*/
@isTest
private class LookupTablesControllerTest {

    // Constants
    static final String OLD_TABLE_NAME = '__Test__ Old Table';
    static final String VALID_TABLE_NAME = '__Test__ Valid Table';
    static final String INVALID_TABLE_NAME = '__Test__ Invalid Table';
    static final String MULTIPLE_TABLE_NAME = '__Test__ Multiple Table';
    static final String NON_UTF8_TABLE_NAME = '__Test__ Non UTF-8 File';
    static final String MULTIPLE_TABLE_DATA =
        '0,14,10,30,15\n' +
        '15,30,25,46,20\n' +
        '34,38,32,49,30\n' +
        '39,48,48,87,57';
    static final String PPI_TABLE_DATA =
        'Identifier,,International R59 MRP,National R59 MRP,International R59 MRP\n' +
        'Poverty Rate,,51.2,26.1,73.9\n';
    static final String FILE_CONTENT_VALID =
        'FROM,TO,' + VALID_TABLE_NAME + '\n' +
        'Poverty Rate,51.2,51.2\n'+
        'Identifier,International R59 MRP,International R59 MRP\n' +
        '0,5,10\n' +
        '6,10,20\n' +
        '11,20,38';
    static final String FILE_CONTENT_VALID2 =
        'FROM,TO,' + PpiTableDomainTest.TEST_TABLE_NAME + OLD_TABLE_NAME + '\n' +
        '0,5,24\n' +
        '6,10,36\n' +
        '11,20,49';
    static final String FILE_CONTENT_INVALID_RANGE =
        'FROM,TO,' + INVALID_TABLE_NAME + '\n' +
        '3,1,10\n' +
        '6,10,20\n' +
        '11,20,38';
    static final String FILE_CONTENT_OVERLAPPED_RANGE =
        'FROM,TO,' + INVALID_TABLE_NAME + '\n' +
        PPI_TABLE_DATA +
        '0,5,10\n' +
        '6,10,20\n' +
        '8,20,38\n' +
        '21,30,38';
    static final String FILE_CONTENT_WRONG_COLUMN_COUNT =
        'FROM,TO,' + INVALID_TABLE_NAME + '\n' +
        '0,5,10,24\n' +
        '6,10,20\n' +
        '11,20,38';
    static final String FILE_CONTENT_WRONG_COLUMN_COUNT2 =
        'FROM,TO\n' +
        '0,5,10,24\n' +
        '6,10,20\n' +
        '11,20,38';
    static final String FILE_CONTENT_NON_INTEGER =
        'FROM,TO,' + INVALID_TABLE_NAME + '\n' +
        '0,5,10\n' +
        '6,test0,20\n' +
        '11,20,38';
    static final String FILE_CONTENT_DUPLICATED_TABLES =
        'FROM,TO, ' + MULTIPLE_TABLE_NAME + ', ' + MULTIPLE_TABLE_NAME + ' 1, ' + 
        MULTIPLE_TABLE_NAME + '\n' + MULTIPLE_TABLE_DATA;
    static final String FILE_CONTENT_LONG_NAME =
        'FROM,TO,' + MULTIPLE_TABLE_NAME + ' 1, ' + MULTIPLE_TABLE_NAME + ' 2, ' +
        getLongString(81) + '\n' + MULTIPLE_TABLE_DATA;
    static final String FILE_CONTENT_MULTIPLE_TABLES =
        'FROM,TO,' + MULTIPLE_TABLE_NAME + ' 1, ' + MULTIPLE_TABLE_NAME + ' 2, ' +
        MULTIPLE_TABLE_NAME + ' 3\n' + PPI_TABLE_DATA + MULTIPLE_TABLE_DATA;
    static final String FILE_CONTENT_NON_UTF8 = 'test non UTF-8';

    /**
     * Helper method to prepare objects for the tests
     * @return a new PPI survey
     */
    private static TestSurveyData prepareObjects() {
        return prepareObjects(true);
    }

    /**
     * Helper method to prepare objects for the tests
     * @param createSamplePpiTable whether a sample Ppi table should be created
     * @return a new Ppi survey
     */
    private static TestSurveyData prepareObjects(Boolean createSamplePpiTable) {

        TestSurveyData testSurvey = TestSurveyData.createStandardTestSurvey(
            SurveyDOTest.createInsertedPpiTemplate(),
            false
        );

        if (createSamplePpiTable) {
            TestSurveyData.addPpiTablesToStandardSurvey(testSurvey);

            // A table not related to the new survey
            PPITable__c oldTable =
                PpiTableDomainTest.createPpiTable(OLD_TABLE_NAME, testSurvey.testSurvey);
            insert oldTable;
        }
        return testSurvey;
    }

    /**
     * Helper method to generate a csv content for multiple tables
     * @return a string with the csv content
     */
    private static String getSampleCSV(String identifier, String povertyRate) {
        return 
            'FROM,TO,'+MULTIPLE_TABLE_NAME+'1,' + MULTIPLE_TABLE_NAME+'2,' +
            MULTIPLE_TABLE_NAME+'3\n' +
            'Identifier,,'+identifier+',National R59 MRP,International R59 MRP\n' +
            'Poverty Rate,,'+povertyRate+',26.1,73.9\n' +
            '0,4,100,87.6,87.6\n' +
            '5,9,100,95.6,87.6';
    }

    /**
     * Helper method to generate a long string
     * @return a string with more than the specified length
     */
    private static String getLongString(Integer length) {
        String longStr = '1234567890';
        while (longStr.length() < length) {
            longStr += longStr;
        }
        return longStr;
    }

    private static LookupTablesController prepareTest() {
        TestSurveyData testSurvey = prepareObjects();
        ApexPages.currentPage().getParameters().put('id', testSurvey.testSurvey.Id);
        return new LookupTablesController();
    }

    /**
     * Test method for the readFileContent method without a file
     */
    static testMethod void testReadFileContentWithoutFile() {
        TestSurveyData testSurvey = prepareObjects();

        ApexPages.currentPage().getParameters().put('id', testSurvey.testSurvey.Id);
        LookupTablesController controller = new LookupTablesController();

        Test.startTest();
        // If there isn't a file loaded, it should show an error
        controller.fileBinary = null;
        controller.readFile();
        Test.stopTest();

        // The page should have an error message
        System.assertEquals(1, ApexPages.getMessages().size());
    }

    /**
     * Test method for the readFileContent method with non utf-8 file
     */
    static testMethod void testReadFileContent() {
        TestSurveyData testSurvey = prepareObjects(false);

        ApexPages.currentPage().getParameters().put('id', testSurvey.testSurvey.Id);
        LookupTablesController controller = new LookupTablesController();

        Test.startTest();
        // Uploading a non UTF-8 file should show an error
        controller.fileBinary = Blob.toPDF(FILE_CONTENT_NON_UTF8);
        System.assert(controller.fileBinary != null, 'Data should be present');
        controller.readFile();
        Test.stopTest();

        // The page should have an error message
        System.assertEquals(1, ApexPages.getMessages().size());

        // The table shouldn't be saved
        System.assertEquals(
            0,
            fetchPpiTableRecordsByName(NON_UTF8_TABLE_NAME, controller.survey).size()
        );
        System.assertEquals(
            0,
            fetchPpiTableDataSetRecords(testSurvey.testSurveyVersion.Id).size()
        );
        System.assertEquals(null, controller.fileBinary);
    }

    /**
     * Test method for the parseHeaders method with wrong column count
     */
    static testMethod void testParseHeadersWrongColumn() {
        TestSurveyData testSurvey = prepareObjects(false);
        ApexPages.currentPage().getParameters().put('id', testSurvey.testSurvey.Id);
        LookupTablesController controller = new LookupTablesController();

        Test.startTest();
        // Wrong column count at the header should show an error
        controller.fileBinary = Blob.valueOf(FILE_CONTENT_WRONG_COLUMN_COUNT2);
        System.assert(controller.fileBinary != null, 'Data should be present');
        controller.readFile();
        Test.stopTest();

        // The page should have an error messages
        System.assertEquals(1, ApexPages.getMessages().size());

        // The table shouldn't be saved
        System.assertEquals(
            0,
            fetchPpiTableDataSetRecords(testSurvey.testSurveyVersion.Id).size()
        );
        System.assertEquals(null, controller.fileBinary);
    }

    /**
     * Test method for the parseHeaders method with duplicated table names
     */
    static testMethod void testParseHeadersDuplicatedNames() {
        TestSurveyData testSurvey = prepareObjects(false);
        ApexPages.currentPage().getParameters().put('id', testSurvey.testSurvey.Id);
        LookupTablesController controller = new LookupTablesController();

        Test.startTest();
        // Duplicated table names in the header should show an error
        controller.fileBinary = Blob.valueOf(FILE_CONTENT_DUPLICATED_TABLES);
        System.assert(controller.fileBinary != null, 'Data should be present');
        controller.readFile();
        Test.stopTest();

        // The page should have an error messages
        System.assertEquals(1, ApexPages.getMessages().size());

        // The table shouldn't be saved
        System.assertEquals(
            0,
            fetchPpiTableWithSpecifiedName(MULTIPLE_TABLE_NAME).size()
        );
        System.assertEquals(
            0,
            fetchPpiTableDataSetRecords(testSurvey.testSurveyVersion.Id).size()
        );
        System.assertEquals(null, controller.fileBinary);
    }

    /**
     * Test method for the parseHeaders method
     */
    static testMethod void testParseHeaders() {
        TestSurveyData testSurvey = prepareObjects(false);
        ApexPages.currentPage().getParameters().put('id', testSurvey.testSurvey.Id);
        LookupTablesController controller = new LookupTablesController();

        Test.startTest();
        // Table name too long should show an error
        controller.fileBinary = Blob.valueOf(FILE_CONTENT_LONG_NAME );
        System.assert(controller.fileBinary != null, 'Data should be present');
        controller.readFile();
        Test.stopTest();

        // The page should have an error message
        System.assertEquals(1, ApexPages.getMessages().size());

        // The table shouldn't be saved
        System.assertEquals(
            0,
            fetchPpiTableWithSpecifiedName(MULTIPLE_TABLE_NAME).size()
        );
        System.assertEquals(
            0,
            fetchPpiTableDataSetRecords(testSurvey.testSurveyVersion.Id).size()
        );
        System.assertEquals(null, controller.fileBinary);
    }

    /**
     * Test method for the parseFields method with wrong values
     */
    private static void testParseFieldsError(String fileContent) {
        TestSurveyData testSurvey = prepareObjects(false);
        ApexPages.currentPage().getParameters().put('id', testSurvey.testSurvey.Id);
        LookupTablesController controller = new LookupTablesController();

        Test.startTest();
        // Run the test
        controller.fileBinary = Blob.valueOf(fileContent);
        System.assert(controller.fileBinary != null, 'Data should be present');
        controller.readFile();
        Test.stopTest();

        // The page should have an error message
        System.assert(ApexPages.getMessages().size() > 0, 'The page should have error messages');

        // Variables are cleared properly after exception is thrown
        System.assert(controller.fileBinary == null, 'Data should not be present');

        System.assertEquals(
            0,
            fetchPpiTableWithSpecifiedName(MULTIPLE_TABLE_NAME).size()
        );
        System.assertEquals(
            0,
            fetchPpiTableDataSetRecords(testSurvey.testSurveyVersion.Id).size()
        );
    }

    /**
     * Test method for the parseFields with wrong poverty rate
     */
    static testMethod void testParseFieldsWrongPRate() {
        testParseFieldsError(getSampleCSV('International R59 MRP', 'wrong'));
    }

    /**
     * Test method for the parseFields with wrong identification
     */
    static testMethod void testParseFieldsWrongIdentification() {
        testParseFieldsError(getSampleCSV(getLongString(256), '51.8'));
    }

    /**
     * Test method for the parseFields with wrong field name
     */
    static testMethod void testParseFieldsWrongFieldName() {
        testParseFieldsError(
            getSampleCSV(
                'International R59 MRP',
                '51.8'
            ).replace('Poverty Rate', 'Fake Field')
        );
    }

    /**
     * Test method for the parseFields with wrong column count at some field row
     */
    static testMethod void testParseFieldsWrongColumn() {
        testParseFieldsError(
            getSampleCSV(
                'International R59 MRP',
                '51.8'
            ).replace('Identifier','Identifier,,,')
        );
    }

    /**
     * Method to check the fields values
     */
    static void checkFieldsValues(String identifier, String povertRate) {
        PPITableDataSet__c[] dataSets =
            new PpiTableDataSetSelector().getLikePpiTableNames(
                MULTIPLE_TABLE_NAME + '%'
            );

        // Check the Poverty Rate of each table
        System.assertEquals(51.8, dataSets[0].PPITable__r.PovertyRate__c);
        System.assertEquals(
            povertRate == '' ? null : Decimal.valueOf(povertRate != null ? povertRate : '26.1'),
            dataSets[1].PPITable__r.PovertyRate__c
        );
        System.assertEquals(73.9, dataSets[2].PPITable__r.PovertyRate__c);

        // Check the Identifier of each table
        System.assertEquals('International R59 MRP', dataSets[0].PPITable__r.Identifier__c);
        System.assertEquals(
            identifier == '' ? null : (identifier != null ? identifier : 'National R59 MRP'),
            dataSets[1].PPITable__r.Identifier__c
        );
        System.assertEquals('International R59 MRP', dataSets[2].PPITable__r.Identifier__c);
    }

    /**
     * Test method for the parseFields method with empty fields
     */
    static testMethod void testParseEmptyFields() {
        LookupTablesController controller = prepareTest();
        Test.startTest();
        // Empty value for Poverty field is not accepted
        controller.fileBinary = Blob.valueOf(getSampleCSV('',''));
        controller.readFile();
        Test.stopTest();

        // The page should throw error as Poverty Rate is required.
        System.assertEquals(1, ApexPages.getMessages().size());

        // The tables should not be saved
        System.assertEquals(
            0,
            fetchPpiTableWithSpecifiedName(MULTIPLE_TABLE_NAME + '%').size()
        );
    }

    /**
     * Test method for the parseFields method with missing row
     */
    static testMethod void testParseFieldsMissingRow() {
        LookupTablesController controller = prepareTest();

        // Delete the Identifier rows
        String fileContent = getSampleCSV('International R59 MRP', '51.8');
        String[] rows = fileContent.split('\n');
        rows.remove(1); // Identifier row
        fileContent = '';
        for (String row : rows) {
            fileContent += row + '\n';
        }

        Test.startTest();
        controller.fileBinary = Blob.valueOf(fileContent);
        controller.readFile();
        Test.stopTest();

        // The page should have error messages as Identifier field is required
        System.assert(ApexPages.getMessages().size() > 0, 'The page should have error messages');

        // The tables should not be saved
        System.assertEquals(
            0,
            fetchPpiTableWithSpecifiedName(MULTIPLE_TABLE_NAME + '%').size()
        );
    }

    /**
     * Test method for the parseFields method with different order
     */
    static testMethod void testParseFieldsDiffOrder() {
        LookupTablesController controller = prepareTest();

        // Swap Identifier and PovertyRates rows
        String fileContent = getSampleCSV('International R59 MRP', '51.8');
        String[] rows = fileContent.split('\n');
        String pppRow = rows[1];

        rows.set(1, rows[2]);
        rows.set(2, pppRow);
        fileContent = '';
        for (String row : rows) {
            fileContent += row + '\n';
        }

        Test.startTest();
        controller.fileBinary = Blob.valueOf(fileContent);
        controller.readFile();
        Test.stopTest();

        // The page shouldn't have error messages
        System.assertEquals(0, ApexPages.getMessages().size());

        // The tables should be saved
        System.assertEquals(
            3,
            fetchPpiTableWithSpecifiedName(MULTIPLE_TABLE_NAME + '%').size()
        );
        System.assertEquals(
            4,
            fetchPpiTableDataSetRecords(
                controller.survey.SurveyVersions__r[0].Id
            ).size()
        );

        // Check the value of all fields
        checkFieldsValues('National R59 MRP', '26.1');
    }

    /**
     * Test method for the parseFields method with leading and trailing spaces
     */
    static testMethod void testParseFieldsSpaces() {
        LookupTablesController controller = prepareTest();
        Test.startTest();
        // Valid value for all the fields are saved
        controller.fileBinary = Blob.valueOf(getSampleCSV('  International R59 MRP  ', '  51.8  '));
        controller.readFile();
        Test.stopTest();

        System.assertEquals(0, ApexPages.getMessages().size());
        // The tables should be saved
        System.assertEquals(
            3,
            fetchPpiTableWithSpecifiedName(MULTIPLE_TABLE_NAME + '%').size()
        );
        System.assertEquals(
            4,
            fetchPpiTableDataSetRecords(
                controller.survey.SurveyVersions__r[0].Id
            ).size()
        );
        System.assertEquals(
            6,
            new PpiTableLineSelector().getLikePpiTableNames(
                MULTIPLE_TABLE_NAME + '%'
            ).size()
        );
        // Check the value of all fields
        checkFieldsValues('National R59 MRP', '26.1');
    }

    /**
     * Test method for the parseFields method with valid values
     */
    static testMethod void testParseFieldsValid() {
        LookupTablesController controller = prepareTest();

        Test.startTest();
        // Valid value for all the fields are saved
        controller.fileBinary = Blob.valueOf(getSampleCSV('International R59 MRP', '51.8'));
        controller.readFile();
        Test.stopTest();

        // The page shouldn't have error messages
        System.assertEquals(0, ApexPages.getMessages().size());
 
        // The tables should be saved
        System.assertEquals(
            3,
           fetchPpiTableWithSpecifiedName(MULTIPLE_TABLE_NAME + '%').size()
        );

        // Check the value of all fields
        checkFieldsValues('National R59 MRP', '26.1');
    }

    /**
     * Test method for the parsing invalid column count
     */
    static testMethod void testParseWithInvalidColumnCount() {
        LookupTablesController controller = prepareTest();
        Test.startTest();

        // Wrong column count in a line should show an error
        controller.fileBinary = Blob.valueOf(FILE_CONTENT_WRONG_COLUMN_COUNT);
        controller.readFile();

        // The page should have an error messages
         System.assert(ApexPages.getMessages().size() > 0, 'The page should have error messages');

        // Load a valid file after an error has occurred
        controller.fileBinary = Blob.valueOf(FILE_CONTENT_VALID);
        System.assert(controller.fileBinary != null, 'Data should be present');

        controller.readFile();
        Test.stopTest();

        // The tables and data sets from the failed upload shouldn't be created
        System.assertEquals(
            0,
            fetchPpiTableRecordsByName(INVALID_TABLE_NAME, controller.survey).size()
        );
        System.assertEquals(
            0,
           fetchPpiTableRecordsByName(INVALID_TABLE_NAME, controller.survey).size()
        );

         // Variables are cleared properly after exception is thrown
        System.assertEquals(null, controller.fileName);
        System.assertEquals(null, controller.fileBinary);
    }

    /**
     * Test method for the parsing invalid csv content
     */
    static testMethod void testParseWithInvalidContent() {
        LookupTablesController controller = prepareTest();
        Test.startTest();

        // Non integer value should show an error
        controller.fileBinary = Blob.valueOf(FILE_CONTENT_NON_INTEGER);
        controller.readFile();

        // The page should have an error messages
        System.assert(ApexPages.getMessages().size() > 0, 'The page should have error messages');

        // Load a valid file after an error has occurred
        controller.fileBinary = Blob.valueOf(FILE_CONTENT_VALID);
        controller.readFile();

        // The tables from the failed upload shouldn't be created
        System.assertEquals(
            0,
            fetchPpiTableRecordsByName(INVALID_TABLE_NAME, controller.survey).size()
        );
        Test.stopTest();
    }

    /**
     * Test different errors with score range
     */
    static void testScoreRangeError(String csvContent) {
        LookupTablesController controller = prepareTest();

        Test.startTest();
        // Invalid ranges should show an error
        controller.fileBinary = Blob.valueOf(csvContent);
        controller.readFile();
        Test.stopTest();

        // The page should have an error messages
        System.assert(ApexPages.getMessages().size() > 0, 'The page should have error messages');

        // The tables and data sets from the failed upload shouldn't be created
        System.assertEquals(
            0,
            fetchPpiTableRecordsByName(INVALID_TABLE_NAME, controller.survey).size()
        );
        System.assertEquals(
            0,
            fetchPpiTableRecordsByName(INVALID_TABLE_NAME, controller.survey).size()
        );
    }

    /**
     * Test method for the validateScoreRange method with wrong ranges
     */
    static testMethod void testScoreRangeWrong() {
        testScoreRangeError(FILE_CONTENT_INVALID_RANGE);
    }

    /**
     * Test method for the validateScoreRange method with overlapped ranges
     */
    static testMethod void testScoreRangeOverlapped() {
        testScoreRangeError(FILE_CONTENT_OVERLAPPED_RANGE);
    }

    /**
     * Test method for a valid case with multiple tables
     */
    static testMethod void testValidCaseMultiple() {
        LookupTablesController controller = prepareTest();

        // Test that ppiTables was loaded
        System.assertEquals(1, controller.lookUpTables.size());

        Test.startTest();
        // Multiple tables should be saved
        controller.fileBinary = Blob.valueOf(FILE_CONTENT_MULTIPLE_TABLES);
        controller.readFile();
        Test.stopTest();
        System.assertEquals(
            3,
            fetchPpiTableWithSpecifiedName(MULTIPLE_TABLE_NAME + '%').size()
        );
    }

    /**
     * Test method for a valid case updating an old data set
     */
    static testMethod void testValidCaseUpdating() {
        LookupTablesController controller = prepareTest();

        // Upload a table that already exists should replace the old lines
        Set<PPITableLine__c> oldLines = new Set<PPITableLine__c>();
        System.assertEquals(
            1,
            fetchPpiTableRecordsByName(
                PpiTableDomainTest.TEST_TABLE_NAME + controller.survey.Name,
                controller.survey
            ).size()
        );

        Test.startTest();
        controller.fileBinary =
            Blob.valueOf(FILE_CONTENT_VALID.replace(
                VALID_TABLE_NAME, PpiTableDomainTest.TEST_TABLE_NAME + controller.survey.Name
            ));
        controller.readFile();
        Test.stopTest();

        System.assertEquals(
            1,
            fetchPpiTableRecordsByName(
                PpiTableDomainTest.TEST_TABLE_NAME + controller.survey.Name,
                controller.survey
            ).size()
        );
    }

    /**
     * Test method for a valid case upload data for an old table
     */
    static testMethod void testValidCaseUploadOldTable() {
        LookupTablesController controller = prepareTest();

        PPITable__c oldTable = fetchPpiTableRecordsByName(
            PpiTableDomainTest.TEST_TABLE_NAME + OLD_TABLE_NAME,
            controller.survey
        )[0];

        // Data set for old Table Name not present.
        System.assertEquals(
            0,
            new PpiTableDataSetSelector().getForSurveyVersionAndPovertyLineNames(
                controller.survey.SurveyVersions__r[0].Id,
                new Set<String> {oldTable.PovertyLine__c}
            ).size()
        );

        Test.startTest();
        controller.fileBinary = Blob.valueOf(FILE_CONTENT_VALID2);
        controller.readFile();
        Test.stopTest();

        // Upload data for an existent table should add a new data set
        System.assertEquals(
            1,
            new PpiTableDataSetSelector().getForSurveyVersionAndPovertyLineNames(
                controller.survey.SurveyVersions__r[0].Id,
                new Set<String> {oldTable.PovertyLine__c}
            ).size()
        );
    }

    /**
     * Test method for the deleteTable method
     */
    static testMethod void testDeleteTable() {
        LookupTablesController controller = prepareTest();

        // The table data set should be deleted
        PPITable__c firstTable = fetchPpiTableRecordsByName(
            PpiTableDomainTest.TEST_TABLE_NAME + controller.survey.Name,
            controller.survey
        )[0];

        Test.startTest();
        controller.selectedTableId = firstTable.Id;
        controller.deleteDataSet();
        Test.stopTest();

        System.assertEquals(
            0,
            new PpiTableDataSetSelector().getForSurveyVersionAndPovertyLineNames(
                controller.survey.SurveyVersions__r[0].Id,
                new Set<String> {firstTable.PovertyLine__c}
            ).size()
        );
    }

    /**
     * Test mehod for the size of the file.
     */
    static testMethod void checkFileSize() {
        TestSurveyData testSurvey = prepareObjects(false);

        // Initialize controller
        ApexPages.currentPage().getParameters().put('id', testSurvey.testSurvey.Id);
        LookupTablesController controller = new LookupTablesController();

        Test.startTest();
        controller.fileBinary = blob.valueof(getLongString(c.LOOKUP_MAX_FILE_SIZE));
        controller.readFile();
        Test.stopTest();

        // The page should have an error messages
        System.assertEquals(1, ApexPages.getMessages().size());

        System.assertEquals(
            System.label.LOOKUP_ERR_FILE_SIZE,
            ApexPages.getMessages().get(0).getDetail()
        );

        // The table shouldn't be saved
        System.assertEquals(
            0,
            fetchPpiTableDataSetRecords(testSurvey.testSurveyVersion.Id).size()
        );
    }

    /**
     * Method for the fetching PpiTable Data Set records.
     */
    static List<PPITableDataSet__c> fetchPpiTableDataSetRecords(Id surveyVersionId) {
        PpiTableDataSetSelector ppiTableDataSetSelectorInstance =
            new PpiTableDataSetSelector();
        List<PPITableDataSet__c> dataSets =
            ppiTableDataSetSelectorInstance.getAllForSurveyVersion(surveyVersionId);
        return dataSets;
    }

    /**
     * Method for the fetching PpiTable records.
     */
    static List<PPITable__c> fetchPpiTableRecordsByName(String name, Survey__c survey) {
        return
            new PpiTableSelector().getForPpiTableNames(
                new Set<String> {PpiTableDomain.generateUniqueIdForPpiTableName(name, survey)}
            );
    }

    /**
     * Method for the fetching PpiTable records with specified string.
     */
    static List<PPITable__c> fetchPpiTableWithSpecifiedName(String tableName) {
        return
            new PpiTableSelector().getLikePpiTableNames(tableName);
    }
}