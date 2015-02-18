/**
 * Grameen: Salesforce - Cascading Select Upload Batch Test
 * Test for the CascadingUploadBatch
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Ernesto Quesada
 * @author - Owen Davies
 */
@isTest
public with sharing class CascadingUploadBatchTest {

    /**
     * Create a test Cascading Select List
     *
     * @param name        - A name for the cascading select. Leave empty for the default
     * @param description - A description for the cascading select. Leave empty for the default
     *
     * @return - The new cascading select list with processing status
     */
    private static CascadingSelect__c createTestCascadingSelect(String name, String description) {

        CascadingSelect__c cascadingSelect = new CascadingSelect__c(
            Name = String.isEmpty(name) ? 'TestName' : name,
            Description__c = String.isEmpty(description) ? 'A Description' : description,
            Status__c = C.CASCADING_STATUS_PROCESSING
        );
        insert cascadingSelect;
        return cascadingSelect;
    }

    /**
     * Add a CSV as an attachment to the CascadingSelect
     *
     * @param csv             - The csv String to be added
     * @param cascadingSelect - The cascading select that the CSV is being added to
     */
    private static void addCsvToCascadingSelect(String csv, CascadingSelect__c cascadingSelect) {
        insert new Attachment(
            Name = C.CASCADING_CSV_ATT,
            ParentId = cascadingSelect.Id,
            Body = Blob.valueOf(csv)
        );
    }

    /**
     * Test Batch with one call
     */
    static testMethod void uploadOneBatch() {

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('Some Name', 'Some Description');

        // Add the attachment
        addCsvToCascadingSelect(TestUtils.getValidCascadingSelectCsv(), cascadingSelect);

        // Process Batch in one call
        Test.startTest();
        Id batchInstanceId = Database.executeBatch(new CascadingUploadBatch(cascadingSelect), 50);
        Test.stopTest();

        // Assertions
        assertCorrectCarCsvUpload();
    }

    /**
     * Assertion of the correct upload of the car csv
     */
    private static void assertCorrectCarCsvUpload() {

        // Assert correct insertion of the CascadingSelect__c
        List<CascadingSelect__c> selectCascading = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Name = 'Some Name'
        ];
        System.assertEquals(1, selectCascading.size(), 'one CascadingSelect__c object only must exist with this name');
        System.assertEquals(
            'Some Description', selectCascading[0].Description__c, 'the Description__c was not correctly saved'
        );
        System.assertEquals(C.CASCADING_STATUS_UPLOADED, selectCascading[0].Status__c, 'The status must be ready' );

        // Assert correct insertion of the CascadingLevels__c and association with the CascadingSelect__c
        List<CascadingLevel__c> levelLinkedList = [
            SELECT
                Id,
                Name__c,
                ControllingLevel__c,
                Position__c,
                (
                    SELECT
                        Id,
                        Position__c,
                        Value__c,
                        ControllingSelectValue__c
                    FROM
                        Cascading_Select_Values__r
                    ORDER BY
                        Position__c
                )
                FROM
                    CascadingLevel__c
                WHERE
                    CascadingSelect__c = :selectCascading[0].Id
                ORDER BY
                    Position__c
        ];
        System.assertEquals(3, levelLinkedList.size(), 'There should be three levels for the CascadingSelect__c');

        // Assert correct name__c assignment
        System.assertEquals('Select Make', levelLinkedList[0].Name__c, 'The Name__c of the Level in incorrect');
        System.assertEquals('Select Model', levelLinkedList[1].Name__c, 'The Name__c of the Level in incorrect');
        System.assertEquals('Select Year', levelLinkedList[2].Name__c, 'The Name__c of the Level in incorrect');

        // Assert correct assignment of controlling level and position
        Integer i = 1;
        for (CascadingLevel__c level : levelLinkedList) {
            System.assertEquals(i, level.Position__c, 'the position is incorrect');
            System.assertEquals(
                (i != 1) ? levelLinkedList[i-2].Id : null,
                level.ControllingLevel__c,
                'The controlling level is incorrect'
            );
            i++;
        }

        // Assert correct insertion of the CascadingSelectValue__c and correct association to their parent CascadingLevel__c
        System.assertEquals(
            3, levelLinkedList[0].Cascading_Select_Values__r.size(), 'There should be 3 values for the first level'
        );
        System.assertEquals(
            13, levelLinkedList[1].Cascading_Select_Values__r.size(), 'There should be 13 values for the second level'
        );
        System.assertEquals(
            33, levelLinkedList[2].Cascading_Select_Values__r.size(), 'There should be 33 values for the third level'
        );

        // Get the second level to evaluate correct generation of the tree
        List<CascadingSelectValue__c> valueSecondLevel = [
            SELECT
                ControllingSelectValue__r.Value__c,
                Value__c,
                (
                    SELECT
                        Id,
                        Position__c,
                        Value__c,
                        ControllingSelectValue__c
                    FROM
                        Cascading_Select_Values__r
                    ORDER BY
                        Position__c
                )
            FROM
                CascadingSelectValue__c
            WHERE
                CascadingLevel__r.Position__c = 2
            ORDER BY
                Position__c
         ];

       // There should be 13 values for the second level values
       System.assertEquals(13, valueSecondLevel.size(), 'There should be 13 values for the second level');

       i = 1;
       for (CascadingSelectValue__c selectValue : valueSecondLevel) {

            // Check the parents are correct
            if (i <= 5) {
                System.AssertEquals('Audi', selectValue.ControllingSelectValue__r.Value__c);
            } else if (i <= 12) {
                System.AssertEquals('BMW', selectValue.ControllingSelectValue__r.Value__c);
            } else if (i <= 13) {
                System.AssertEquals('Honda', selectValue.ControllingSelectValue__r.Value__c);
            }

            // Check the child size is correct for each element of the list
            if (i == 1 || i == 2 || i == 4 || i == 5 || i == 6 || i == 10 || i == 13) {
                System.AssertEquals(
                    3, selectValue.Cascading_Select_Values__r.size(), 'the child list size is incorrect'
                );
            } else if (i == 3) {
                System.AssertEquals(
                    4, selectValue.Cascading_Select_Values__r.size(), 'the child list size is incorrect'
                );
            } else if (i == 7 || i == 8 || i == 12) {
                System.AssertEquals(
                    2, selectValue.Cascading_Select_Values__r.size(), 'the child list size is incorrect'
                );
            } else if (i == 9 || i == 11) {
                System.AssertEquals(
                    1, selectValue.Cascading_Select_Values__r.size(), 'the child list size is incorrect'
                );
            }
            i++;
       }
    }

    /**
     * Test upload fails when a duplicate row exists in the CSV
     */
    static testMethod void testFailureWithDuplicateRow() {

        String csv = 'Level1,Level2,Level3,Level4,Level5,Level6\n' +
            '1,2,3,4,5,7\n' +
            '1,2,3,4,5,8\n' +
            '1,2,3,4,5,6\n' +
            '1,2,3,4,5,6\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_DUPLICATE_ROW, new String[]{'5', '4'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test failure when CSV is empty
     */
    static testMethod void testFailureWhenCsvIsEmpty() {

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect('', cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(System.label.CASCADING_BATCH_EMPTY_CSV, CascadingUploadBatch.errorMessage);
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test failure when a cell in level 1 is missing
     */
    static testMethod void testFailureWhenCellInLevel1Empty() {

        String csv = 'Level1,Level2,Level3,Level4,Level5,Level6\n' +
            '1,2,3,4,5,6\n' +
            '   ,2,3,4,5,7\n' +
            '1,2,3,4,5,8\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_BLANK_CELL, new String[]{'1', '3'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test failure when a cell in level 2 is missing
     */
    static testMethod void testFailureWhenCellInLevel2Empty() {

        String csv = 'Level1,Level2,Level3,Level4,Level5,Level6\n' +
            '1,2,3,4,5,6\n' +
            '1,,3,4,5,7\n' +
            '1,2,3,4,5,8\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_BLANK_CELL, new String[]{'2', '3'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test failure when a cell in level 3 is missing
     */
    static testMethod void testFailureWhenCellInLevel3Empty() {

        String csv = 'Level1,Level2,Level3,Level4,Level5,Level6\n' +
            '1,2,3,4,5,6\n' +
            '1,2,,4,5,7\n' +
            '1,2,3,4,5,8\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_BLANK_CELL, new String[]{'3', '3'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test failure when a cell in level 4 is missing
     */
    static testMethod void testFailureWhenCellInLevel4Empty() {

        String csv = 'Level1,Level2,Level3,Level4,Level5,Level6\n' +
            '1,2,3,4,5,6\n' +
            '1,2,3,,5,7\n' +
            '1,2,3,4,5,8\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_BLANK_CELL, new String[]{'4', '3'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test failure when a cell in level 5 is missing
     */
    static testMethod void testFailureWhenCellInLevel5Empty() {

        String csv = 'Level1,Level2,Level3,Level4,Level5,Level6\n' +
            '1,2,3,4,,6\n' +
            '1,2,3,4,5,7\n' +
            '1,2,3,4,5,8\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_BLANK_CELL, new String[]{'5', '2'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test failure when a cell in level 6 is missing
     */
    static testMethod void testFailureWhenCellInLevel6Empty() {

        String csv = 'Level1,Level2,Level3,Level4,Level5,Level6\n' +
            '1,2,3,4,5,6\n' +
            '1,2,3,4,5,7\n' +
            '1,2,3,4,5,\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_BLANK_CELL, new String[]{'6', '4'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test failure when CSV only has headers
     */
    static testMethod void testFailureWhenCsvHasOnlyHeaders() {

        String csv = 'Level1,Level2,Level3,Level4,Level5,Level6\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(System.label.CASCADING_BATCH_CSV_ONLY_HEADERS, CascadingUploadBatch.errorMessage);
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test failure when a cell has text longer than is allowed
     */
    static testMethod void testFailureWhenTextTooLongInCell() {

        String csv = 'Level1,Level2,Level3,Level4,Level5,Level6\n' +
            '1,2,3,4,5,123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123' +
                '456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012' +
                '345678901234567890123456789012345678901234567890123456789012345678901234567890\n' +
            '1,2,3,4,5,7\n' +
            '1,2,3,4,5,8\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_CELL_TOO_LONG, new String[]{'6', '2'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test missing level in header
     */
    static testMethod void emptyHeaderValue() {

        String csv = 'Level1,Level2,Level3,Level4,Level5,\n' +
            '1,2,3,4,5,1\n' +
            '1,2,3,4,5,7\n' +
            '1,2,3,4,5,8\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_BLANK_HEADER, new String[]{'6'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test header value too long
     */
    static testMethod void testHeaderTooLong() {

            String csv = 'Level1,Level2,Level3,Level4,Level5,123456789012345678901234567890123456789012345678901234567890' +
            '123456789012345678901234567890123' +
            '456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012' +
            '345678901234567890123456789012345678901234567890123456789012345678901234567890\n' +
            '1,2,3,4,5,1\n' +
            '1,2,3,4,5,7\n' +
            '1,2,3,4,5,8\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_HEADER_CELL_TOO_LONG, new String[]{'6'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test for completely missing cell
     */
    static testMethod void testCellMissing() {

            String csv = 'Level1,Level2,Level3,Level4,Level5,Level6\n' +
            '1,2,3,4,5\n' +
            '1,2,3,4,5,7\n' +
            '1,2,3,4,5,8\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_ROW_DIFFERENT_LENGTH, new String[]{'2', '5', '6'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }

    /**
     * Test for headers greater than 6
     */
    static testMethod void testTooManyLevels() {

            String csv = 'Level1,Level2,Level3,Level4,Level5,Level6,Level7\n' +
            '1,2,3,4,5,6,7\n' +
            '1,2,3,4,5,7,7\n' +
            '1,2,3,4,5,8,7\n';

        CascadingSelect__c cascadingSelect = createTestCascadingSelect('', '');
        addCsvToCascadingSelect(csv, cascadingSelect);

        // Process Batch in one call
        Integer emailbefore = Limits.getEmailInvocations();
        Test.startTest();
        CascadingUploadBatch uploadBatch = new CascadingUploadBatch(cascadingSelect);
        Id batchInstanceId = Database.executeBatch(uploadBatch, 50);
        Test.stopTest();

        System.assertEquals(
            String.format(System.label.CASCADING_BATCH_TOO_MANY_HEADERS, new String[]{'7'}),
            CascadingUploadBatch.errorMessage
        );
        System.assertNotEquals(1, emailbefore - CascadingUploadBatch.emailInvocations);

        // Check that the CascadingSelect is in status invalid
        CascadingSelect__c[] updatedCascadingSelect = [
            SELECT
                Name,
                Description__c,
                Status__c
            FROM
                CascadingSelect__c
            WHERE
                Id = :cascadingSelect.Id
        ];

        System.assertEquals(1, updatedCascadingSelect.size());
        System.assertEquals(C.CASCADING_STATUS_INVALID, updatedCascadingSelect[0].Status__c);
        System.assertEquals(
            0, [SELECT Id FROM CascadingLevel__c WHERE CascadingSelect__c = :cascadingSelect.Id].size()
        );
    }
}
