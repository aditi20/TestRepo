/**
 * Batchable class to generate a cascading select list from a previously uploaded CSV file
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Ernesto Quesada
 * @author - Owen Davies
 */
global class CascadingUploadBatch implements Database.batchable<String>, Database.Stateful {

    // Map to keep the CascadingLevel__c for each level
    global Map<Integer, CascadingLevel__c> cascadingLevelPerLevel;

    // Map to keep track of all the select cascadingSelectValues per level
    global Map<Integer, List<SelectValueWrapper>> cascadingSelectValuesPerLevel;

    // Map String of the root elements of the select
    global Map<String, SelectValueWrapper> rootSelectValues;

    // The global counter for the position of the selectValues
    global Integer positionCounter;

    // The Current Cascading select
    global CascadingSelect__c cascadingSelect;

    // The Csv Content
    global String csvContent;

    // Boolean indicating that the batch has succeeded or not
    global Boolean stillValid;

    // A map of hash values that represent each created row. This is used to catch duplicates
    global Map<String, Integer> duplicateHash;

    // The length of the headers. This is checked against for every row to make sure that a cell is not completely missing
    global Integer rowLength;

    // The error message produced by the batch process
    global String errorMsg;
    
    // Global row counter
    global Integer totalRows;

    // Variables needed for test methods to ensure that the correct errors were sent
    @TestVisible static Integer emailInvocations;
    @TestVisible static String errorMessage;

    /**
     * Constructor of the class
     */
    global CascadingUploadBatch(CascadingSelect__c cascadingSelect) {

        // Initialize the variables
        this.positionCounter = 0;
        this.cascadingSelect = cascadingSelect;
        this.cascadingLevelPerLevel = new Map<Integer, CascadingLevel__c>();
        this.cascadingSelectValuesPerLevel = new Map<Integer, List<selectValueWrapper>> ();
        this.rootSelectValues = new Map<String, selectValueWrapper>();
        this.stillValid = true;
        this.duplicateHash = new Map<String, Integer>();
    }

    /**
     * Generate a list of Strings. One for each row in the CSV file
     * Carries out the validation checks on the CSV
     */
    global List<String> start(Database.batchableContext batchableContext) {
        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Attachment.Name,
            Attachment.Body,
            Attachment.ParentId
        });
        // Init the global counter of the rows in 1 (the header row)
        totalRows = 1;
        
        // Check that the csv file can be parsed from the blob
        String csv;
        try {
            csv = [
                SELECT
                    Body
                FROM
                    Attachment WHERE ParentId = :cascadingSelect.Id
                    AND Name = :C.CASCADING_CSV_ATT
            ].Body.toString();
        } catch(StringException e) {
            this.stillValid = false;
            setErrorMessage(System.label.CASCADING_BATCH_NONUTF8FILE);
            return new List<String>();
        }

        // Check that the csv is not empty
        if (String.isEmpty(csv)) {
            this.stillValid = false;
            setErrorMessage(System.label.CASCADING_BATCH_EMPTY_CSV);
            return new List<String>();
        }

        String[] fileLines = csv.split('\n');
        csv = null;
        List<String> headers = SurveyUtils.parseCsvLine(fileLines.remove(0));

        // Check that the csv is more than just headers
        if (fileLines.size() == 0) {
            this.stillValid = false;
            setErrorMessage(System.label.CASCADING_BATCH_CSV_ONLY_HEADERS);
            return new List<String>();
        }

        // Parse the headers
        if (!parseHeaders(headers)) {
            this.stillValid = false;
            return new List<String>();
        }

        return fileLines;
    }

    /**
     * Main execute method. Loops through the CSV lines parse the rows
     */
    global void execute(Database.BatchableContext BC, List<String> batch) {

        // Parse each row
        Integer i = 0;
        while (this.stillValid && i < batch.size()) {
            totalRows++;
            this.stillValid = parseRow(SurveyUtils.parseCsvLine(batch[i]), totalRows);
            i++;
        }
    }

    /**
     * Finish method. Sets the status of the cascading select and saves the values
     */
    global void finish(Database.BatchableContext BC) {
        GenericObjectCreator cascadingSelectCreator =
            new GenericObjectCreator(CascadingSelect__c.SObjectType);
        cascadingSelectCreator.checkObjectAccessible();
        cascadingSelectCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            CascadingSelect__c.Status__c
        });
        cascadingSelectCreator.checkObjectUpdateable();

        // Check that the amount of created CascadingSelectLevel__cs are less than the available rows to insert
        // Init the total needed at the highest possible amount of DML left plus the amount used already
        if (this.stillValid) {
            Integer totalDmlNeeded = Limits.getDMLRows() + this.rowLength + 1;
            for (List<SelectValueWrapper> levels : this.cascadingSelectValuesPerLevel.values()) {
                totalDmlNeeded += levels.size();
            }
            if (totalDmlNeeded >= Limits.getLimitDMLRows()) {
                this.stillValid = false;
                setErrorMessage(
                    String.format(
                        System.label.CASCADING_TOO_MANY_VALUES,
                        new List<String>{String.valueOf(totalDmlNeeded), String.valueOf(Limits.getLimitDMLRows())}
                    )
                );
            }
        }

        if (this.stillValid) {
            insertSelectValueItems();
            cascadingSelectCreator.populateField(
                cascadingSelect,
                CascadingSelect__c.Status__c,
                C.CASCADING_STATUS_UPLOADED
            );
        } else {
            GenericObjectCreator cascadingLevelCreator =
                new GenericObjectCreator(CascadingLevel__c.SObjectType);
            cascadingLevelCreator.checkObjectAccessible();
            cascadingLevelCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                CascadingLevel__c.CascadingSelect__c
            });
            cascadingLevelCreator.checkObjectDeletable();
            // Remove any levels that may have been created. This is most likely just the headers
            delete [
                SELECT
                    Id
                FROM
                    CascadingLevel__c
                WHERE
                    CascadingSelect__c = :cascadingSelect.Id
            ];
            cascadingSelectCreator.populateField(
                cascadingSelect,
                CascadingSelect__c.Status__c,
                C.CASCADING_STATUS_INVALID
            );

            // Send out the error message email
            try {
                sendErrorEmail();
            } catch (System.EmailException ex) {}
        }
        update cascadingSelect;

        // Set the email limit for testing purposes
        CascadingUploadBatch.emailInvocations = Limits.getEmailInvocations();
    }

    /**
     * Create and Insert the levels of the Cascading
     *
     * @param headerRow - First line of the csv
     *
     * @return - If the parsing fails return false. True if successful
     */
    private Boolean parseHeaders(List<String> headerRow) {

        // Check that there are not too many levels
        if (headerRow.size() > 6) {
            setErrorMessage(
                String.format(System.label.CASCADING_BATCH_TOO_MANY_HEADERS, new String[]{
                    String.valueOf(headerRow.size())
                })
            );
            return false;
        }
        List<CascadingLevel__c> createdLevels = new List<CascadingLevel__c>();
        Integer i = 1;
        for (String header : headerRow) {

            // If the header is empty or too long
            if (String.isBlank(header) || header.length() > 255) {
                if (String.isBlank(header)) {
                    setErrorMessage(
                        String.format(System.label.CASCADING_BATCH_BLANK_HEADER, new String[]{
                            String.valueOf(i)
                        })
                    );
                } else {
                    setErrorMessage(
                        String.format(System.label.CASCADING_BATCH_HEADER_CELL_TOO_LONG , new String[]{
                            String.valueOf(i)
                        })
                    );
                }
                return false;
            }
            GenericObjectCreator cascadingLevelCreator =
                new GenericObjectCreator(CascadingLevel__c.SObjectType);
            cascadingLevelCreator.checkObjectAccessible();
            cascadingLevelCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                CascadingLevel__c.Name__c,
                CascadingLevel__c.Position__c,
                CascadingLevel__c.CascadingSelect__c
            });
            CascadingLevel__c createdLevel =
                (CascadingLevel__c) cascadingLevelCreator.createNewRecord();
            cascadingLevelCreator.populateFields(
                createdLevel,
                new Map<Schema.SObjectField, Object> {
                    CascadingLevel__c.Name__c => header,
                    CascadingLevel__c.Position__c => i,
                    CascadingLevel__c.CascadingSelect__c => cascadingSelect.Id
                }
            );
            createdLevels.add(createdLevel);
            cascadingLevelPerLevel.put(i, createdLevel);
            i++;
        }
        this.rowLength = createdLevels.size();
        insert createdLevels;
        assignControllingLevel(createdLevels);
        return true;
    }

    /**
     * Assign the controlling level of each level, all the cascading levels must be inserted previously
     *
     * @param cascadingLevels - The list of the CascadingLevel__c to assign it's parent
     */
    private void assignControllingLevel(List<CascadingLevel__c> cascadingLevels) {
        GenericObjectCreator cascadingLevelCreator =
            new GenericObjectCreator(CascadingLevel__c.SObjectType);
        cascadingLevelCreator.checkObjectUpdateable();
        for (CascadingLevel__c level : cascadingLevels) {

            // Get the previous controlling level(the -2 is because the array index starts
            // at 0 and the position at 1)
            cascadingLevelCreator.populateField(
                level,
                CascadingLevel__c.ControllingLevel__c,
                (level.Position__c > 1) ?
                    cascadingLevels.get((Integer)level.Position__c - 2).Id : null
            );
        }
        update cascadingLevels;
    }

    /**
     * Parse a Row of the CSV and add the generated selectValueWrappers to the map per level
     *
     * @param row - The row values in a List
     * @param rowNumber - The number that this row is in the CSV
     *
     * @return - A boolean indicating if the row parsed successfully
     */
    private Boolean parseRow(List<String> row, Integer rowNumber) {

        // Check the row is not a duplicate of a previous row and that it is the correct length
        String rowHash = EncodingUtil.base64Encode(Crypto.generateDigest('MD5', blob.valueof(String.join(row, '_#@#JOINER#@#_'))));
        Integer duplicateRowNumber = this.duplicateHash.get(rowHash);
        if (duplicateRowNumber != null || this.rowLength != row.size()) {
            if (this.rowLength != row.size()) {
                setErrorMessage(
                    String.format(System.label.CASCADING_BATCH_ROW_DIFFERENT_LENGTH, new String[]{
                        String.valueOf(rowNumber),
                        String.valueOf(row.size()),
                        String.valueOf(this.rowLength)
                    })
                );
            } else {
                setErrorMessage(
                    String.format(System.label.CASCADING_BATCH_DUPLICATE_ROW, new String[]{
                        String.valueOf(rowNumber),
                        String.valueOf(duplicateRowNumber)
                    })
                );
            }
            return false;
        }
        this.duplicateHash.put(rowHash, rowNumber);

        List<selectValueWrapper> rowSelectValues = new List<selectValueWrapper>();
        selectValueWrapper parent = null;
        Integer level = 1;
        for (String cell : row) {

            // If the cell is empty or too long
            if (String.isBlank(cell) || cell.length() > 255) {
                if (String.isBlank(cell)) {
                    setErrorMessage(
                        String.format(System.label.CASCADING_BATCH_BLANK_CELL, new String[]{
                            String.valueOf(level),
                            String.valueOf(rowNumber)
                        })
                    );
                } else {
                    setErrorMessage(
                        String.format(System.label.CASCADING_BATCH_CELL_TOO_LONG, new String[]{
                            String.valueOf(level),
                            String.valueOf(rowNumber)
                        })
                    );
                }
                return false;
            }

            // First item case
            if (parent == null) {

                // If the item exists assign it as parent else create it
                if (rootSelectValues.get(cell) != null) {
                    parent = rootSelectValues.get(cell);
                } else {
                    parent = createSelectValueAndAssignToLevel(cell, positionCounter, level, null);
                    rootSelectValues.put(cell, parent);
                }

            // If the item has a parent, check if this parent has a child with this value
            } else if (parent.childSelectValues.get(cell) != null) {
                parent = parent.childSelectValues.get(cell);
            } else {
                selectValueWrapper newSelectValue =
                    createSelectValueAndAssignToLevel(cell, positionCounter, level, parent);
                parent.childSelectValues.put(cell, newSelectValue);
                parent = newSelectValue;
            }

            // Increment level
            level++;
        }
        return true;
    }

    /**
     * Create a selectValueWrapper and assign it to the level map
     *
     * @param value    - Value of the select value object
     * @param position - Position of the select value object
     * @param level    - The Cascading Level position
     * @param parent   - The controlling Select Value
     */
    private selectValueWrapper createSelectValueAndAssignToLevel(
            String value,
            Integer position,
            Integer level,
            SelectValueWrapper parent
    ) {

        // Create a new Wrapper SelectValue item and add it to
        // Its corresponding level position (if the list for the level was not yet created, create it)
        SelectValueWrapper currentSelectValue = new SelectValueWrapper(value, position, level, parent, cascadingLevelPerLevel.get(level).Id);
        if (cascadingSelectValuesPerLevel.get(level) != null){
            cascadingSelectValuesPerLevel.get(level).add(currentSelectValue);
        } else {
            cascadingSelectValuesPerLevel.put(level, new List<selectValueWrapper>{currentSelectValue});
        }

        // Increment the global counter
        positionCounter++;
        return currentSelectValue;
    }

    /**
     * Insert the created objects per level and assign the previous Controlling
     */
    private void insertSelectValueItems() {
        GenericObjectCreator cascadingSelectValueCreator =
            new GenericObjectCreator(CascadingSelectValue__c.SObjectType);
        cascadingSelectValueCreator.checkObjectAccessible();
        cascadingSelectValueCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                CascadingSelectValue__c.Value__c,
                CascadingSelectValue__c.Position__c,
                CascadingSelectValue__c.CascadingLevel__c,
                CascadingSelectValue__c.ControllingSelectValue__c
            }
        );
        // Insert per level, if a level list is null the process end
        Integer level = 1;
        while (cascadingSelectValuesPerLevel.get(level) != null) {
            List<CascadingSelectValue__c> levelValues = new List<CascadingSelectValue__c>();
            for (SelectValueWrapper selectValue : cascadingSelectValuesPerLevel.get(level)) {
                levelValues.add(selectValue.toActualObject());
            }
            insert levelValues;
            level++;
        }
    }

    /**
     * Set both error message variables
     *
     * @param msg - The error message
     */
    private void setErrorMessage(String msg) {
        this.errorMsg = msg;
        CascadingUploadBatch.errorMessage = msg;
    }

    /**
     * Send out the error email.
     */
    private void sendErrorEmail() {

        Messaging.SingleEmailMessage mail = EmailUtils.createSingleEmailForCurrentUser();

        mail.setSenderDisplayName(System.label.CASCADING_BATCH_SENDER_NAME);
        mail.setSubject(
            String.format(
                System.label.CASCADING_BATCH_SUBJECT_LINE,
                new List<String>{this.cascadingSelect.Name}
            )
        );
        mail.setPlainTextBody(
            String.format(
                System.label.CASCADING_BATCH_EMAIL_BODY,
                new List<String>{this.cascadingSelect.Name, this.errorMsg}
            )
        );
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }

    /**
     * Class to construct the selectValue tree before inserting, and keep a
     * reference to the parent without an insertion. Composite pattern applied.
     */
    private Class SelectValueWrapper {

        public Id cascadingLevel;
        public Integer depth;
        public Integer position;
        public String value;
        public SelectValueWrapper controllingSelectValueWrapper;
        public CascadingSelectValue__c actualObject;
        public Map <String, SelectValueWrapper> childSelectValues;

        /**
         * Constructor of the wrapper
         */
        public SelectValueWrapper(
                String val,
                Integer pos,
                Integer level,
                SelectValueWrapper contSelect,
                Id selectLevelId
        ) {

            this.cascadingLevel = selectLevelId;
            this.depth = level;
            this.position = pos;
            this.value = val;
            this.controllingSelectValueWrapper = contSelect;
            this.actualObject = null;
            this.childSelectValues = new Map<String, SelectValueWrapper>();
        }

        /**
         * Parse the wrapper to the salesforce actual object
         * and assign it to this wrapper as well, the controllingSelectValueWrapper
         * must be inserted before calling this method
         *
         * @return - The generated object
         */
        public CascadingSelectValue__c toActualObject() {

            GenericObjectCreator cascadingSelectValueCreator =
                new GenericObjectCreator(CascadingSelectValue__c.SObjectType);
            this.actualObject =
                (CascadingSelectValue__c) cascadingSelectValueCreator.createNewRecord();
            cascadingSelectValueCreator.populateFields(
                this.actualObject,
                new Map<Schema.SObjectField, Object>{
                    CascadingSelectValue__c.Value__c => this.value,
                    CascadingSelectValue__c.Position__c => this.position,
                    CascadingSelectValue__c.CascadingLevel__c => this.cascadingLevel,
                    CascadingSelectValue__c.ControllingSelectValue__c =>
                        (controllingSelectValueWrapper != null) ?
                            controllingSelectValueWrapper.actualObject.Id : null
                }
            );
           return this.actualObject;
        }
    }
}
