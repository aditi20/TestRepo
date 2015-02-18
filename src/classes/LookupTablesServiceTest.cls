/**
 * Test class for LookupTablesService
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
@isTest
public with sharing class LookupTablesServiceTest {

    /**
     * Helper method to generate a valid csv content for multiple tables
     * @return a string with the valid csv content
     */
    private static String getSampleValidCSV(String identifier, String povertyRate) {
        return 
            'FROM,TO,TableName1,TableName2,TableName3\n' +
            'Identifier,,'+identifier+',National R59 MRP,International R59 MRP\n' +
            'Poverty Rate,,'+povertyRate+',26.1,73.9\n' +
            '0,4,100,87.6,87.6\n' +
            '5,9,100,95.6,87.6';
    }

    /**
     * Helper method to generate a invalid csv content for multiple tables
     * @return a string with the invalid csv content
     */
    private static String getSampleInValidCSV(
            String identifier,
            String povertyRate,
            String addTableNames
    ) {
        return 
            'FROM,TO'+addTableNames+'\n' +
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

    /**
     * Test method for verifying csv upload with null file content 
     */
    static testmethod void testVerifyNullFileContent() {
        try {
            Test.startTest();
            LookupTablesService.verifyFileContent(null);
            Test.stopTest();
        } catch (Exception e) {
            // The page should have an error message
            System.assertEquals(
                System.label.LOOKUP_ERR_SELECTFILE,
                e.getMessage()
            );
        }
    }

    /**
     * Test method for verfying csv upload with valid file content
     */
    static testmethod void testVerifyValidFileContent() {
        Test.startTest();
        LookupTablesService.verifyFileContent(
            Blob.valueOf(
                getSampleValidCSV(
                    'International R59 MRP',
                    '51.8'
                )
            )
        );
        Test.stopTest();
        // The page should has no error message
        System.assertEquals(0, ApexPages.getMessages().size());
    }

    /**
     * Test method for parsing valid csv header
     */
    static testmethod void testParseHeaderForValidCsv() {
        Test.startTest();
        LookupTablesService.fileContent =
            getSampleValidCSV('International R59 MRP', '51.8');
        Set<String> headers = LookupTablesService.parserHeaderForCsv();
        Test.stopTest();

        // The page should has no error message
        System.assertEquals(0, ApexPages.getMessages().size());

        // The header columns are parsed
        System.assert(
            headers.contains('TableName1'),
            'The headers are not parsed properly'
        );
    }

    /**
     * Test method for parsing invalid columns in csv header
     */
    static testmethod void testParseHeaderForInValidCsvColumn() {
        try {
            Test.startTest();
            LookupTablesService.fileContent =
                getSampleInValidCSV('International R59 MRP', '51.8', '');
            Set<String> headers = LookupTablesService.parserHeaderForCsv();
            Test.stopTest();
        } catch (Exception e) {
            // The page should has an error message
            System.assertEquals(
                String.format(
                    System.label.LOOKUP_ERR_WRONGCOLUMNCOUNTAT,
                    new String[] {'1'}
                ),
                e.getMessage()
            );
        }
    }

    /**
     * Test method for parsing duplicate columns in csv header
     */
    static testmethod void testParseHeaderForDuplicateCsvColumn() {
        try {
            Test.startTest();
            LookupTablesService.fileContent =
                getSampleInValidCSV(
                    'International R59 MRP',
                    '51.8',
                    ',TableName1,TableName1'
                );
            Set<String> headers = LookupTablesService.parserHeaderForCsv();
            Test.stopTest();
        } catch (Exception e) {
            // The page should has an error message
            System.assertEquals(
                System.label.LOOKUP_ERR_REPEATEDTABLENAME,
                e.getMessage()
            );
        }
    }

    /**
     * Test method for parsing blank table names in csv header
     */
    static testmethod void testParseHeaderForBlankTableNames() {
        try {
            Test.startTest();
            LookupTablesService.fileContent =
                getSampleInValidCSV(
                    'International R59 MRP',
                    '51.8',
                    ',,TableName1'
                );
            Set<String> headers = LookupTablesService.parserHeaderForCsv();
            Test.stopTest();
        } catch (Exception e) {
            // The page should has an error message
            System.assertEquals(
                String.format(
                    System.Label.LOOKUP_ERR_BLANKTABLENAME,
                    new String[] {
                        '1',
                        '3'
                    }
                ),
                e.getMessage()
            );
        }
    }

    /**
     * Test method for parsing long column names in csv header
     */
    static testmethod void testParseHeaderForLongCsvColumnNames() {
        try {
            Test.startTest();
            LookupTablesService.fileContent =
                getSampleInValidCSV('test', '22.5', getLongString(81));
            Set<String> headers = LookupTablesService.parserHeaderForCsv();
            Test.stopTest();
        } catch (Exception e) {
            // The page should has an error message
            System.assertEquals(
                String.format(
                    System.label.LOOKUP_ERR_WRONGCOLUMNCOUNTAT,
                    new String[] {'1'}
                ),
                e.getMessage()
            );
        }
    }

    /**
     * Test method for parsing valid data
     */
    static testmethod void testParseValidData() {
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        survey = new SurveySelector().getWithSurveyVersionAndQuestions(survey.Id);

        LookupTablesService.fileContent = getSampleValidCSV('International R59 MRP', '51.8');
        Set<String> headers = LookupTablesService.parserHeaderForCsv();

        Test.startTest();
        LookupTablesService.readCsvFile(headers, survey);
        LookupTablesService.refreshPpiTableList(survey);
        Test.stopTest();

        // The page should has no error message
        System.assertEquals(0, ApexPages.getMessages().size());

        // Test that ppiTables were parsed properly and created in database
        System.assertEquals(3, LookupTablesService.ppiTablesWrapper.size());
    }

    /**
     * Test class for parsing valid case insensitive table name data upload
     */
    static testmethod void testParseValidCaseInsensitiveTableNameData() {
        UnitOfWork unitOfWork = new UnitOfWork();
        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();

        SurveySelector surveySelectorInstance = new SurveySelector();
        survey = surveySelectorInstance.getWithSurveyVersionAndQuestions(survey.Id);

        System.assertEquals(
            1,
            survey.SurveyVersions__r.size()
        );

        // Create data for Ppi related Tables
        PPITable__c ppiTable =
            PpiTableDomainTest.createPpiTable(
                'TableName1_KENYA_2012',
                'TableName1',
                'TableName1',
                '',
                52.3
            );
        insert ppiTable;

        // PpiTable records present in database
        System.assert(
            ((List<PPITable__c>) (
                new PpiTableSelector().getRecordsById(new Set<Id> {ppiTable.Id})
            )).size() == 1,
            'Ppi tables not inserted into database properly'
        );

        PPITableLine__c ppiTableLine = PpiTableLineDomainTest.createPpiTableLine();
        PpiTableLineDomainTest.addPpiTableLineToUnitOfWork(
            ppiTableLine,
            ppiTable,
            unitOfWork
        );
        PPITableDataSet__c dataSet = PpiTableDataSetDomainTest.createPpiTableDataSet();
        PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
            dataSet,
            ppiTable,
            survey,
            survey.SurveyVersions__r[0],
            unitOfWork
        );
        unitOfWork.commitWork();

        Test.startTest();
        // Upload a csv again with updated old table name in case insensitive manner (i.e tablename1)
        // Also add two new tables (TableName2,TableName3) 
        Blob fileBinary = Blob.valueOf(
            getSampleInValidCSV(
                'International R59 MRP',
                '51.8',
                ',tablename1,TableName2,TableName3'
            )
        );
        LookupTablesService.parseAndReadCsv(fileBinary, survey);
        Test.stopTest();

        // The page should has no error message
        System.assertEquals(0, ApexPages.getMessages().size());

        // Test that ppiTables were parsed properly and updated/created in database
        System.assertEquals(3, LookupTablesService.ppiTablesWrapper.size());

        // Verify that existing table name is properly updated with uploaded case insensitive table name
        System.assertEquals(
            'tablename1',
            ((PPITable__c) new PpiTableSelector().getRecordById(ppiTable.Id)).PovertyLine__c
        );
    }

    /**
     * Test class for parsing and reading valid data
     */
    static testmethod void testParseAndReadValidData() {

        Survey__c survey = SurveyDOTest.createInsertedPpiTemplate();
        survey = new SurveySelector().getWithSurveyVersionAndQuestions(survey.Id);

        Blob fileBinary = Blob.valueOf(getSampleValidCSV('International R59 MRP', '51.8'));

        Test.startTest();
        LookupTablesService.parseAndReadCsv(fileBinary, survey);
        Test.stopTest();

        // The page should has no error message
        System.assertEquals(0, ApexPages.getMessages().size());

        // Test that ppiTables were parsed properly and created in database
        System.assertEquals(3, LookupTablesService.ppiTablesWrapper.size());
    }
}
