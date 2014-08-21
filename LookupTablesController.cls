/**
*   Grameen: Salesforce - PPI Upload
*   Controller for the LookupTables page
*   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*   @author Alejandro De Gregorio
*/
public with sharing class LookupTablesController {
    //---------------------------------------
    // Constants
    //---------------------------------------
    private static final String FIELD_ALPHA = 'Alpha__c';
    private static final String FIELD_PRATE = 'PovertyRate__c';
    private static final String FIELD_PPP = 'PPP__c';
    private static final String FIELD_EXPDEF = 'ExpenditureDefinition__c';
    private static final String FIELD_LDEF = 'LineDefinition__c';
    private static final String FIELD_ID = 'Identifier__c';

    //---------------------------------------
    // Page properties
    //---------------------------------------
    private Id surveyId;                                // The id of the survey
    public Survey__c survey { get; set; }               // The actual survey
    public List<TableWrapper> ppiTables { get; set; }   // A list with all tables for the survey
    public PPITable__c selectedTable { get; set; }      // The selected table
    public boolean readOnly{get;set;}                   // Indicates if the survey must be shown in read only mode
    public boolean wasDownloaded{get;set;}              // Indicates if the survey was downloaded from another org
    public boolean sameOrg{get;set;}                    // To render the close button just when is in the same org
    public String selectedTableId { get;                // The id of the selected table
        set {
            if(String.isBlank(value)){
                selectedTable = null;
            }
            else {
                selectedTable = [SELECT Id, Name
                                 FROM PPITable__c
                                 WHERE Id = :value];
                selectedTableId = value;
            }
        }
        //Test parent - test
    }


    //---------------------------------------
    // File upload properties
    //---------------------------------------
    public string fileName{get;set;}                    // The name of the selected file
    public string fileContent{get;set;}                 // The string content of the file
    public Blob fileBinary{get;set;}                    // The binary content of the file


    //---------------------------------------
    // Class constructor
    //---------------------------------------
    public LookupTablesController(){
        this.surveyId = ApexPages.currentPage().getParameters().get('id');

        // Catching when the url id is null
        if(surveyId != null){
            this.survey   = [SELECT Id, Name, Alias__c, IsPPI__c, Status__c, (SELECT RemoteServerId__c
                                                                              FROM Questions__r
                                                                              WHERE RemoteServerId__c != null
                                                                                  AND RemoteServerId__c != '')
                             FROM Survey__c
                             WHERE Id =: this.surveyId];
        }else
            throw new C.InvalidUrlException(system.Label.BUILDER_ERR_INVALIDURL);

        // If at least one question has remote server Id, the survey was downloaded
        wasDownloaded = !this.survey.Questions__r.isEmpty();

        // Set to true when is the same org to show the preview.
        sameOrg = Site.getName() == null;

        this.selectedTableId = '';
        refreshTableList();
        String commingFromBuilder = Apexpages.currentPage().getParameters().get('b');
        readOnly = !((commingFromBuilder == null || commingFromBuilder == '1')
                     && this.survey.Status__c == SurveyDO.STATUS_DRAFT
                     && Survey__c.sObjectType.getDescribe().isUpdateable());
    }

    // Refresh the table list to show in the page
    private void refreshTableList(){
        this.ppiTables = new List<TableWrapper>();

        // Get the data sets with its lines for this survey
        List<PPITableDataSet__c> tableDataSets = [SELECT Id,
                                                         Alpha__c,
                                                         PovertyRate__c,
                                                         PPP__c,
                                                         ExpenditureDefinition__c,
                                                         LineDefinition__c,
                                                         Identifier__c,
                                                         PPITable__r.Name,
                                                         PPITable__r.Id,
                                                         (SELECT Id,
                                                                 From__c,
                                                                 To__c,
                                                                 Probability__c
                                                          FROM PPI_Table_Lines__r
                                                          ORDER BY From__c)
                                                  FROM PPITableDataSet__c
                                                  WHERE Survey__c = :this.surveyId
                                                  ORDER BY Id ASC];
        // Create a wrapper with each data set
        for(PPITableDataSet__c dataSet : tableDataSets){
            this.ppiTables.add(new TableWrapper(dataSet, dataSet.PPI_Table_Lines__r));
        }
    }

    // Get a map with a data set for each table
    private Map<String, PPITableDataSet__c> getDataSetMap(Set<String> tableNames){
        Map<String, PPITableDataSet__c> dataSetMap = new Map<String, PPITableDataSet__c>();
        List<PPITableDataSet__c> newDataSets = new List<PPITableDataSet__c>();
        List<PPITable__c> newTables = new List<PPITable__c>();

        // Get the old data sets that match with the table names
        for(PPITableDataSet__c dataSet : [SELECT Id,
                                                 PPITable__r.Id,
                                                 PPITable__r.Name
                                          FROM PPITableDataSet__c
                                          WHERE Survey__r.Id = :this.surveyId
                                                AND PPITable__r.Name IN :tableNames]){
                dataSetMap.put(dataSet.PPITable__r.Name, dataSet);
                tableNames.remove(dataSet.PPITable__r.Name);
        }

        // Create a new data set for each table that already exists in the database
        for(PPITable__c table : [SELECT Id, Name FROM PPITable__c WHERE Name in :tableNames]){
            PPITableDataSet__c newDataSet = new PPITableDataSet__c(PPITable__c = table.Id, Survey__c = this.surveyId);
            dataSetMap.put(table.Name, newDataSet);
            tableNames.remove(table.Name);
        }

        // Create new tables that don't exists in the database
        for(String name : tableNames){
            PPITable__c newTable = new PPITable__c(Name = name);
            newTables.add(newTable);
        }

        if (Schema.sObjectType.PPITable__c.isCreateable()) {
            insert newTables;
        }

        // Create data sets for the new tables
        for(PPITable__c table : newTables){
            PPITableDataSet__c newDataSet = new PPITableDataSet__c(PPITable__c = table.Id, Survey__c = this.surveyId);
            dataSetMap.put(table.Name, newDataSet);
        }

        if (Schema.sObjectType.PPITableDataSet__c.isCreateable() || Schema.sObjectType.PPITableDataSet__c.isUpdateable()) {
            upsert dataSetMap.values();
        }

        return dataSetMap;
    }

    // Reset the upload variables
    private void clearVariables(){
        this.fileName = null;
        this.fileContent = null;
        this.fileBinary = null;
    }

    // Add the specified score range to the given set
    // If there is an error returns the error message, otherwise returns null
    private String addScoreRange(Decimal rangeFrom, Decimal rangeTo, Set<Decimal> coveredRange){
        // If the range definition ir wrong return null
        if(rangeFrom > rangeTo){
            return String.format(System.label.LOOKUP_ERR_WRONGRANGE,
                                 new String[]{String.valueOf(rangeFrom), String.valueOf(rangeTo)});
        }

        // Create a set for the new range
        Set<Decimal> newRange = new Set<Decimal>();
        for(Decimal i = rangeFrom; i <= rangeTo; i++){
            newRange.add(i);
        }

        // If there are any intersection between the sets return null
        if(coveredRange.removeAll(newRange)){
            return String.format(System.label.LOOKUP_ERR_RANGEINTERSECTED,
                                 new String[]{String.valueOf(rangeFrom), String.valueOf(rangeTo)});
        }
        else {
            // Add the new range and return the complete covered range
            coveredRange.addAll(newRange);
            return null;
        }
    }

    /**
     *    Validations needed before the parsing of the file
     *    Add an error to the page if there is something wrong
     *    @return false if an error occurred
     */
    private boolean readFileContent(){
        // Avoid process if there isn't a selected file, or if file exceeds size
        if(this.fileBinary == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                       System.label.LOOKUP_ERR_SELECTFILE));
            clearVariables();
            // Finish the process if error
            return false;
        }else if(this.fileBinary.size()>c.LOOKUP_MAX_FILE_SIZE){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                       System.label.LOOKUP_ERR_FILE_SIZE));
            clearVariables();
            // Finish the process if error
            return false;
        }

        // Convert the binary content to string
        try{
            fileContent = fileBinary.toString();
        } catch(StringException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                       System.label.LOOKUP_ERR_NONUTF8FILE));
            clearVariables();
            // Finish the process if error
            return false;
        }

        return true;
    }

    /**
     *    Parse file headers and load the data sets map
     *    Add an error to the page if there is something wrong
     *    @return false if an error occurred
     */
    private boolean parseHeaders(List<String> headers){
        // Validate column count
        // There must be at least three headers: From, To, TableName1, ...
        if(headers.size() < 3){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                       String.format(System.label.LOOKUP_ERR_WRONGCOLUMNCOUNTAT,
                                                                     new String[]{'1'})));
            clearVariables();
            // Finish the process if error
            return false;
        }

        // Validate duplicated column names
        // Putting the headers in a set removes the duplicates
        Set<String> headersSet = new Set<String>(headers);
        if(headersSet.size() != headers.size()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                       System.label.LOOKUP_ERR_REPEATEDTABLENAME));
            clearVariables();
            // Finish the process if error
            return false;
        }

        // Validate tables name length
        Integer tableNameLength = Schema.SObjectType.PPITable__c.fields.Name.getLength();
        for(String name : headers){
            if(name.length() > tableNameLength){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                           String.format(System.label.LOOKUP_ERR_NAMETOOLONG,
                                                                         new String[]{name, String.valueOf(tableNameLength)})));
                clearVariables();
                // Finish the process if error
                return false;
            }
        }

        return true;
    }

    /**
     *    Parse a String value and convert it to the corresponding type
     *    @return the parsed object
     */
    private Object parseValue(String field, String value){
        // If the value is empty return null
        if(value == null || String.isBlank(value)){
            return null;
        }

        // Parse the number fields
        if(field == FIELD_ALPHA || field == FIELD_PRATE || field == FIELD_PPP){
            return Decimal.valueOf(value);
        }
        // Parse the string fields
        else if(field == FIELD_EXPDEF || field == FIELD_LDEF || field == FIELD_ID){
            return value;
        }

        return null;
    }

    /**
     *    Get the field name by a string of the csv
     *    This method uses keywords to find wich field name to return
     *    @return a string with the field name or null if no keywords matched
     */
    private String getFieldToParse(String csvWords){
        // convert the text to lowercase
        csvWords = csvWords.toLowerCase();
        if(csvWords.contains('alpha')){
            return FIELD_ALPHA;
        }
        else if(csvWords.contains('poverty')){
            return FIELD_PRATE;
        }
        else if(csvWords.contains('ppp')){
            return FIELD_PPP;
        }
        else if(csvWords.contains('expenditure')){
            return FIELD_EXPDEF;
        }
        else if(csvWords.contains('line')){
            return FIELD_LDEF;
        }
        else if(csvWords.contains('identifier')){
            return FIELD_ID;
        }

        return null;
    }


    /**
     *    Parse the line for some field
     *    Add an error to the page if there is something wrong
     *    @return false if an error occurred
     */
    private boolean parseFieldLine(String[] inputValues, Integer lineIndex, List<String> headers, Map<String, PPITableDataSet__c> stringToDataSets){
        Integer columnCount = headers.size();
        // Validate column count
        if(inputValues.size() != columnCount){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                        String.format(System.label.LOOKUP_ERR_WRONGCOLUMNCOUNTAT,
                            new String[]{String.valueOf(lineIndex)})));

            clearVariables();
            // Finish the process if error
            return false;
        }

        // Get the field to parse
        String fieldName = getFieldToParse(inputValues[0]);
        if(fieldName==null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                            String.format(System.label.LOOKUP_ERR_WRONGFIELD,
                                new String[]{String.valueOf(lineIndex)})));

            clearVariables();
            // Finish the process if error
            return false;
        }

        // Remove the first two columns that are unneeded
        inputValues.remove(0);
        inputValues.remove(0);
        // Keep track of the column to inform the user in case of an error
        Integer column = 3;
        for(String strValue : inputValues){
            try{
                // Set the value in the corresonding field
                stringToDataSets.get(headers[column-1]).put(fieldName, parseValue(fieldName, strValue.trim()));
            }
            catch (Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                            String.format(System.label.LOOKUP_ERR_ERRORATCOLLINE,
                                new String[]{String.valueOf(column),
                                String.valueOf(lineIndex),
                                e.getMessage()})));

                clearVariables();
                // Finish the process if error
                return false;
            }
            column++;
        }

        try{
            if (Schema.sObjectType.PPITableDataSet__c.isUpdateable()) {
                update stringToDataSets.values();
            }
        }
        catch (Exception e){
            // The exception add a message to the page
            clearVariables();
            // Finish the process if error
            return false;
        }

        return true;
    }

    /**
     *    Parse the table lines
     *    Add an error to the page if there is something wrong
     *    @return false if an error occurred
     */
    private boolean parseLines(List<String> fileLines, Integer lineIndex, List<String> headers, Map<String, PPITableDataSet__c> stringToDataSets){
        Integer columnCount = headers.size();
        // List of the already parsed lines
        List<PPITableLine__c> parsedLines = new List<PPITableLine__c>();
        // A set that indicates the range covered by the prsed lines
        Set<Decimal> coveredRange = new Set<Decimal>();
        for (String line : fileLines){
            String[] inputValues = line.split(',');

            // Validate column count
            if(inputValues.size() != columnCount){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                           String.format(System.label.LOOKUP_ERR_WRONGCOLUMNCOUNTAT,
                                                                         new String[]{String.valueOf(lineIndex)})));

                clearVariables();
                // Finish the process if error
                return false;
            }

            // Convert the numbers and add them to a list
            List<Decimal> numValues = new List<Decimal>();
            // Keep track of the column to inform the user in case of an error
            Integer column = 1;
            for(String strValue : inputValues){
                try{
                    numValues.add(Decimal.valueOf(strValue.trim()));
                }
                catch (Exception e){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                               String.format(System.label.LOOKUP_ERR_VALUECANTBECONVERTED,
                                                                             new String[]{String.valueOf(column),
                                                                                          String.valueOf(lineIndex)})));

                    clearVariables();
                    // Finish the process if error
                    return false;
                }
                column++;
            }

            // Check that the range is valid
            String error = addScoreRange(numValues[0], numValues[1], coveredRange);
            if(error != null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                           String.format(System.label.LOOKUP_ERR_ERRORATCOLLINE,
                                                                         new String[]{'1', String.valueOf(lineIndex+1),
                                                                                      error})));

                clearVariables();
                // Finish the process if error
                return false;
            }

            // Create the lines for each table
            for(Integer j = 2; j < columnCount; j++){
                parsedLines.add(new PPITableLine__c(PPITableDataSet__c = stringToDataSets.get(headers[j]).Id,
                                                           From__c = numValues[0], To__c = numValues[1],
                                                           Probability__c = numValues[j]));
            }
            lineIndex++;
        }

        if (Schema.sObjectType.PPITableLine__c.isDeletable()) {
            // Clean old lines in existent data sets
            delete [SELECT Id FROM PPITableLine__c WHERE PPITableDataSet__c IN :stringToDataSets.values()];
        }

        // Save the new lines in the database
        if (Schema.sObjectType.PPITableLine__c.isCreateable()) {
            insert parsedLines;
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                           system.label.LOOKUP_ERR_PERMISSIONS_CREATE));
         }

        return true;
    }

    //---------------------------------------
    // Actions
    //---------------------------------------

    // Read and parse the uploaded file
    public Pagereference readFile()
    {
        // Save point in case of an error
        Savepoint sp = Database.setSavepoint();

        // Pre parsing validation
        // ----------------------------------
        if(!readFileContent()){
            Database.rollback(sp);
            return null;
        }


        // Parse the headers
        // ----------------------------------
        String[] fileLines = fileContent.split('\n');
        List<String> headers = new List<String>();
        for(String header : fileLines[0].split(',')){
            headers.add(header.trim());
        }
        if(!parseHeaders(headers)){
            Database.rollback(sp);
            return null;
        }

        // Set of table names to create the data sets
        Set<String> tableNames = new Set<String>(headers);
        // Remove the range headers
        tableNames.remove(headers.get(0));
        tableNames.remove(headers.get(1));

        // This map points the table name to the corresponding data set
        Map<String, PPITableDataSet__c> stringToDataSets = getDataSetMap(tableNames);

        // Remove first line that was already processed
        fileLines.remove(0);


        // Parse the fields
        // ----------------------------------
        // Keep track of the line being parsed to inform the user in case of an error
        // Start in two becouse the first line (header) was removed
        Integer lineIndex = 2;
        while(!fileLines.isEmpty()){
            String[] inputValues = fileLines[0].split(',', -1);
            // If the second value is not '' then is not a field line
            // So, finish the field parsing
            if (inputValues[1].trim() != ''){
                break;
            }
            else {
                // Process this line. Don't assume positions: they might have any order.
                if(!parseFieldLine(inputValues, lineIndex, headers, stringToDataSets)){
                    Database.rollback(sp);
                    return null;
                }
                // Remove the parsed line
                fileLines.remove(0);
                lineIndex++;
            }
        }


        // Parse the rest of the lines
        // ----------------------------------
        if(!parseLines(fileLines, lineIndex, headers, stringToDataSets)){
            Database.rollback(sp);
            return null;
        }

        // Refresh and finish
        refreshTableList();
        clearVariables();
        return null;
    }

    // Delete the data set for the specified table
    public Pagereference deleteDataSet(){
        if (Schema.sObjectType.PPITableDataSet__c.isDeletable()) {
            delete [SELECT Id FROM PPITableDataSet__c WHERE PPITable__c = :selectedTable.Id AND Survey__c = :this.surveyId];
            refreshTableList();
         }
         else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,
                                                           system.label.LOOKUP_ERR_PERMISSIONS_DELETE));
         }

         return null;
    }


    //---------------------------------------
    // Inner class definition
    //---------------------------------------

    // Wrapper class for the table and lines
    public with sharing class TableWrapper {
        public PPITableDataSet__c dataSet { get; set; }
        public List<PPITableLine__c> lines { get; set; }

        public TableWrapper(PPITableDataSet__c aDataSet, List<PPITableLine__c> lineList){
            this.dataSet = aDataSet;
            this.lines = lineList;
        }
    }
}
