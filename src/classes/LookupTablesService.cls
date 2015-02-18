/**
 * Service class for all the logic to parse and upload lookup tables
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class LookupTablesService {
    // Constants
    private static final String FIELD_PRATE = 'PovertyRate__c';
    private static final String FIELD_ID = 'Identifier__c';
    private static final String POVERTY = 'poverty';
    private static final String IDENTIFIER = 'identifier';
    private static final List<String> TABLE_FIELDS = new List<String> {
        FIELD_PRATE,
        FIELD_ID
    };

    public static List<String> fileLines;
    public static List<String> headers;
    public static String fileContent;
    public static SavePoint savePointInstance;
    public static List<TableWrapper> ppiTablesWrapper;

    /**
     * Parse and read the csv file and add an error to the page if any exception is thrown
     */
    public static List<TableWrapper> parseAndReadCsv(Blob fileBinary, Survey__c survey) {
        // Pre parsing validation
        verifyFileContent(fileBinary);

        Set<String> povertyLineNames = parserHeaderForCsv();
        if (povertyLineNames != null) {
            readCsvFile(povertyLineNames, survey);
        }
        return refreshPpiTableList(survey);
    }

    /**
     * Validations needed before the parsing of the file
     * Add an error to the page if there is something wrong
     */
    public static void verifyFileContent(Blob fileBinary) {
        // Avoid process if there isn't any selected file, or if file exceeds size
        if (fileBinary == null) {
            throw new LookupTablesServiceException(
                System.Label.LOOKUP_ERR_SELECTFILE
            );
        } else if (fileBinary.size() > C.LOOKUP_MAX_FILE_SIZE) {
            throw new LookupTablesServiceException(System.Label.LOOKUP_ERR_FILE_SIZE);
        }

        // Convert the binary content to string
        try {
            fileContent = fileBinary.toString();
        } catch (StringException e) {
            throw new LookupTablesServiceException(System.Label.LOOKUP_ERR_NONUTF8FILE);
        }
    }

    /**
     * Parse the csv file headers
     * @return Set of parsed table names to create Ppi Tables
     */
    public static Set<String> parserHeaderForCsv() {
        headers = new List<String>();
        if (fileContent != null) {
            fileLines = fileContent.split('\n');
        }

        if (fileLines != null) {
            for (String header : fileLines[0].split(',')) {
                headers.add(header.trim());
            }
        }

        parseHeaders(headers);

        // Set of table names to create ppi tables
        Set<String> tableNames = new Set<String>(headers);

        // Remove the headers(From/To) which are not required
        tableNames.remove(headers.get(0));
        tableNames.remove(headers.get(1));
        return tableNames;
    }

    /**
     * Parse file headers and add an error to the page if there is some error
     */
    private static void parseHeaders(List<String> headerRecords) {
        // Validate column count
        // There must be at least three headers: From, To, TableNames,...
        if (headerRecords.size() < 3) {
            throw new LookupTablesServiceException(
                String.format(
                    System.Label.LOOKUP_ERR_WRONGCOLUMNCOUNTAT,
                    new String[] {'1'}
                )
            );
        }

        // Validate duplicated column names
        // Putting the headers in a set removes the duplicates
        Set<String> headersSet = new Set<String> (headerRecords);
        if (headersSet.size() != headerRecords.size()) {
            throw new LookupTablesServiceException(
                System.Label.LOOKUP_ERR_REPEATEDTABLENAME
            );
        }

        // Validate tables name length
        Integer tableNameLength = Schema.SObjectType.PPITable__c.fields.Name.getLength();
        Integer columnCount = 1;
        for (String name : headerRecords) {
            if (String.isEmpty(name)) {
                if (columnCount > 2) {
                    throw new LookupTablesServiceException(
                        String.format(
                            System.Label.LOOKUP_ERR_BLANKTABLENAME,
                            new String[] {
                                '1',
                                String.valueOf(columnCount)
                            }
                        )
                    );
                }
            }
            if (name.length() > tableNameLength) {
                throw new LookupTablesServiceException(
                    String.format(
                        System.Label.LOOKUP_ERR_NAMETOOLONG,
                        new String[] {
                            name,
                            String.valueOf(tableNameLength)
                        }
                    )
                );
            }
            columnCount++;
        }
    }

    /**
     * Parse file headers and add an error to the page if there is some error
     */
    public static void readCsvFile(Set<String> povertyLineNames, Survey__c survey) {
        // This map points the table name to the corresponding PpiTable
        Map<String, PPITable__c> dataTableMap =
            PpiTableDomain.getPovertyLineNameToPpiTableMap(povertyLineNames, survey);

        // Remove first line that was already processed
        fileLines.remove(0);

        // Parse the lines of Poverty Rate and Identifier
        Integer lineIndex = parsePpiTableRecords(fileLines, dataTableMap);

        // Parse the rest of the lines of Probabilities
        parseLines(fileLines, lineIndex, headers, dataTableMap);

        insertDataSetRecords(dataTableMap, survey);
    }

    /**
     * Insert data in data set table for new PpiTable / existing PpiTable
     * with specific Survey
     */
    private static void insertDataSetRecords(
            Map<String, PPITable__c> dataTableMap,
            Survey__c survey
    ) {
        List<PPITableDataSet__c> dataSetList = new List<PPITableDataSet__c>();
        PpiTableDataSetDomain dataSetDomain = new PpiTableDataSetDomain();
        Map<Id, PPITableDataSet__c> mapPpiTableWithDataSets =
            PpiTableDataSetDomain.getPpiTablePovertyLineToDataSetMap(
                dataTableMap.keySet(),
                survey
            );

        for (PPITable__c ppiTable : dataTableMap.values()) {
            if (!mapPpiTableWithDataSets.containsKey(ppiTable.Id)) {
                PPITableDataSet__c newDataSet =
                    dataSetDomain.createRecord(ppiTable.Id, survey);
                dataSetList.add(newDataSet);
            }
        }
        dataSetDomain.addRecords(dataSetList);
        dataSetDomain.insertRecords();
    }

    /**
     * Parse PpiTable records
     * @return lineIndex for parsing next lines in csv
     */
    private static Integer parsePpiTableRecords(
            List<String> fileLineRecords,
            Map<String, PPITable__c> dataTableMap
    ) {
        // Start in two because the first line (header) was removed after
        // completion of parsing
        Integer lineIndex = 2;
        while (!fileLineRecords.isEmpty()) {
            String[] inputValues = fileLineRecords[0].split(',', -1);
            // If the second value is not '' then is not a field line
            // So, stop the field parsing
            if (inputValues[1].trim() != '') {
                break;
            } else {
                parseFieldLine(inputValues, lineIndex, headers, dataTableMap);

                // Remove the parsed line
                fileLineRecords.remove(0);
                lineIndex++;
            }
        }

        PpiTableDomain ppiTableDomain =
            new PpiTableDomain.Constructor().constructWithRecords(dataTableMap.values());
        ppiTableDomain.upsertRecords();
        return lineIndex;
    }

    /**
     * Parse csv with Poverty Rates and Identifier for PpiTable records
     */
    private static void parseFieldLine(
            String[] inputValues,
            Integer lineIndex,
            List<String> headerRecords,
            Map<String, PPITable__c> ppiTableMap
    ) {
        Integer columnCount = headerRecords.size();

        // Validate column count
        if (inputValues.size() != columnCount) {
            clearVariables();
            throw new LookupTablesServiceException(
                String.format(
                    System.Label.LOOKUP_ERR_WRONGCOLUMNCOUNTAT,
                    new String[] {String.valueOf(lineIndex)}
                )
            );
        }

        // Get the field to parse
        String fieldName = getFieldToParse(inputValues[0]);
        if (fieldName == null) {
            clearVariables();
            throw new LookupTablesServiceException(
                String.format(
                    System.Label.LOOKUP_ERR_WRONGFIELD,
                    new String[] {String.valueOf(lineIndex)}
                )
            );
        }

        // Remove the first two columns of csv that are not needed
        inputValues.remove(0);
        inputValues.remove(0);

        // Keep track of the column to inform the user in case of an error
        Integer column = 3;
        for (String strValue : inputValues) {
            try {
                // Set the value in the corresonding field
                ppiTableMap.get(headerRecords[column-1]).put(
                    fieldName,
                    parseValue(
                        fieldName,
                        strValue.trim()
                    )
                );
            } catch (Exception e) {
                clearVariables();
                throw new LookupTablesServiceException(
                    String.format(
                        System.Label.LOOKUP_ERR_ERRORATCOLLINE,
                        new String[] {
                            String.valueOf(column),
                            String.valueOf(lineIndex),
                            e.getMessage()
                        }
                    )
                );
            }
            column++;
        }
    }

    /**
     * Parse the table lines
     * Add an error to the page if there is something wrong
     */
    private static void parseLines(
            List<String> fileLineRecords,
            Integer lineIndex,
            List<String> headerRecords,
            Map<String,PPITable__c> ppiDataTableMap
    ) {
        Integer columnCount = headerRecords.size();
        List<PPITableLine__c> parsedLines = new List<PPITableLine__c>();
        PpiTableLineDomain tableLineDomain = new PpiTableLineDomain();
        Set<Id> ppiTableIds = new Set<Id>();
        for (PPITable__c ppiTables : ppiDataTableMap.values()) {
            ppiTableIds.add(ppiTables.Id);
        }

        // A set that indicates the range covered by the parsed lines
        Set<Decimal> coveredRange = new Set<Decimal>();
        for (String line : fileLineRecords) {
            String[] inputValues = line.split(',');
            // Validate column count
            if (inputValues.size() != columnCount) {
                clearVariables();
                throw new LookupTablesServiceException(
                    String.format(
                        System.Label.LOOKUP_ERR_WRONGCOLUMNCOUNTAT,
                        new String[] {String.valueOf(lineIndex)}
                    )
                );
            }

            // Convert the numbers and add them to a list
            List<Decimal> numValues = new List<Decimal>();

            // Keep track of the column to inform the user in case of an error
            Integer column = 1;
            for (String strValue : inputValues) {
                try {
                    numValues.add(Decimal.valueOf(strValue.trim()));
                } catch (Exception e) {
                    clearVariables();
                    throw new LookupTablesServiceException(
                        String.format(
                            System.Label.LOOKUP_ERR_VALUECANTBECONVERTED,
                            new String[] {
                                String.valueOf(column),
                                String.valueOf(lineIndex)
                            }
                        )
                    );
                }
                column++;
            }

            // Check that the range is valid
            addScoreRange(numValues[0], numValues[1], coveredRange, lineIndex);

            // Create the lines for each table
            for (Integer j = 2; j < columnCount; j++) {
                parsedLines.add(
                    tableLineDomain.createRecord(
                        ppiDataTableMap.get(headerRecords[j]).Id,
                        numValues[0],
                        numValues[1],
                        numValues[j]
                    )
                );
            }
            lineIndex++;
        }

        // Clean old table lines
        tableLineDomain =
            new PpiTableLineDomain.Constructor().constructWithRecords(
                new PpiTableLineSelector().getForPpiTableIds(ppiTableIds)
            );
        tableLineDomain.deleteRecords();

        // Insert new table lines
        tableLineDomain =
            new PpiTableLineDomain.Constructor().constructWithRecords(parsedLines);
        tableLineDomain.insertRecords();
    }

    /**
     * Add the specified score range to the given set and throw error for invalid values
     */
    private static void addScoreRange(
            Decimal rangeFrom,
            Decimal rangeTo,
            Set<Decimal> coveredRange,
            Integer lineIndex
    ) {
        // If the range definition is wrong return null
        if (rangeFrom > rangeTo) {
            throw new LookupTablesServiceException(
               String.format(
                    System.Label.LOOKUP_ERR_ERRORATCOLLINE,
                    new String[] {
                        '1',
                        String.valueOf(lineIndex+1),
                        String.format(
                            System.Label.LOOKUP_ERR_WRONGRANGE,
                            new String[] {
                                String.valueOf(rangeFrom),
                                String.valueOf(rangeTo)
                            }
                        )
                    }
                )
            );
        }

        // Create a set for the new range
        Set<Decimal> newRange = new Set<Decimal>();
        for (Decimal i = rangeFrom; i <= rangeTo; i++) {
            newRange.add(i);
        }

        // If there are any intersection between the sets throw an error
        if (coveredRange.removeAll(newRange)) {
            throw new LookupTablesServiceException(
               String.format(
                    System.Label.LOOKUP_ERR_ERRORATCOLLINE,
                    new String[] {
                        '1',
                        String.valueOf(lineIndex+1),
                        String.format(
                            System.Label.LOOKUP_ERR_RANGEINTERSECTED,
                            new List<String> {
                                String.valueOf(rangeFrom),
                                String.valueOf(rangeTo)
                            }
                        )
                    }
                )
            );
        } else {
            // Add the new range and return the complete covered range
            coveredRange.addAll(newRange);
        }
    }

    /**
     * Get the field name by a string of the csv
     * This method uses keywords to find which field name to return
     * @return a string with the field name or null if no keywords matched
     */
    private static String getFieldToParse(String csvWords) {
        // Convert the text from csv to lowercase
        csvWords = csvWords.toLowerCase();
        if (csvWords.contains(POVERTY)) {
            return FIELD_PRATE;
        } else if (csvWords.contains(IDENTIFIER)) {
            return FIELD_ID;
        }
        return null;
    }

    /**
     * Parse a String value and convert it to the corresponding type
     * @return the parsed object
     */
    private static Object parseValue(String field, String value) {
        // If the value is empty throw error
        if (String.isEmpty(value)) {
            throw new LookupTablesServiceException(
                String.format(
                    System.Label.LOOKUP_ERR_INVALIDFIELDVALUE,
                    new String[] {
                        field
                    }
                )
            );
        } else {
            Integer fieldLength;
            // Parse the number fields
            if (field.equals(FIELD_PRATE)) {
                // Get the actual length of decimal places
                Integer fieldDecimalPlacesLength =
                    Schema.SObjectType.PPITable__c.fields.PovertyRate__c.getScale();

                // Get the actual length of decimal field
                fieldLength =
                    Schema.SObjectType.PPITable__c.fields.PovertyRate__c.getPrecision() -
                        fieldDecimalPlacesLength;

                Decimal fieldValue = Decimal.valueOf(value);

                // Verify that the actual length of parsed value is valid
                if (fieldValue.precision() - fieldValue.scale() > fieldLength) {
                    throw new LookupTablesServiceException(
                        String.format(
                            System.Label.LOOKUP_ERR_VALUETOOLONG,
                            new String[] {
                                value,
                                String.valueOf(fieldValue.precision() - fieldValue.scale())
                                    + ',' + String.ValueOf(fieldValue.scale()),
                                FIELD_PRATE,
                                String.valueOf(fieldLength)
                                    + ',' + String.ValueOf(fieldDecimalPlacesLength)
                            }
                        )
                    );
                }
                return fieldValue;
            }

            // Parse the string fields
            else if (field.equals(FIELD_ID)) {
                fieldLength = Schema.SObjectType.PPITable__c.fields.Identifier__c.getLength();

                if (value.length() > fieldLength) {
                    throw new LookupTablesServiceException(
                        String.format(
                            System.Label.LOOKUP_ERR_VALUETOOLONG,
                            new String[] {
                                value,
                                String.valueOf(value.length()),
                                FIELD_ID,
                                String.valueOf(fieldLength)
                            }
                        )
                    );
                }
                return value;
            }
        }
        return null;
    }

    /**
     * Refresh the table list to show in the page of selected survey
     */
    public static List<TableWrapper> refreshPpiTableList(Survey__c survey) {
        ppiTablesWrapper = new List<TableWrapper>();
        Map<Id, PPITableDataSet__c> dataSetMap =
            new Map<Id, PPITableDataSet__c>();
        PpiTableDataSetSelector dataSetSelector = new PpiTableDataSetSelector();
        PpiTableSelector ppiTableSelector = new PpiTableSelector();

        for (PPITableDataSet__c dataSet :
            dataSetSelector.getAllForSurveyVersion(survey.SurveyVersions__r[0].Id)
        ) {
            dataSetMap.put(dataSet.PPITable__c, dataSet);
        }

        // Get the Ppi table with its lines for specified data sets related to each survey
        List<PPITable__c> ppiTableList =
            ppiTableSelector.getWithPpiTableLines(dataSetMap.keySet());

        // Create a wrapper with each data set
        for (PPITable__c ppiTable : ppiTableList) {
            ppiTablesWrapper.add(new TableWrapper(ppiTable, ppiTable.PPI_Table__r));
        }
        return ppiTablesWrapper;
    }

    /**
     * Reset the upload variables
     */
    private static void clearVariables() {
        fileContent = null;
    }

    /**
     * Delete PpiTable DataSets for selected PpiTable of current Survey Version
     */
    public static void performDeleteForSelectedPpi(
            PPITable__c selectedPpiTable,
            Survey__c survey
    ) {
        List<PPITableDataSet__c> dataSets =
            new PpiTableDataSetSelector().getForSurveyVersionAndPovertyLineNames(
                survey.surveyVersions__r[0].Id,
                new Set<String> {selectedPpiTable.PovertyLine__c}
            );

        if (!dataSets.isEmpty()) {
            PpiTableDataSetDomain dataSetDomain =
                new PpiTableDataSetDomain.Constructor().constructWithRecords(dataSets);
            dataSetDomain.deleteRecords();
        }
    }

    /**
     * Wrapper class for the table and lines
     */
    public with sharing class TableWrapper {
        public PPITable__c ppiTable {get; set;}
        public List<PPITableLine__c> lines {get; set;}

        public TableWrapper(PPITable__c ppiTable, List<PPITableLine__c> lineList) {
            this.ppiTable = ppiTable;
            this.lines = lineList;
        }
    }

    public class LookupTablesServiceException extends BaseException {
        public LookupTablesServiceException(String message, String[] args) {
            super(message, args);
        }
    }

}