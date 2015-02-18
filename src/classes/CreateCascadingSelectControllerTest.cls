/**
 * Grameen: Salesforce - Cascading Select Upload Test
 * Test for the CreateCascadingSelect
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Ernesto Quesada
 * @author - Owen Davies
 * @author - Santiago Blankleider
 */
@isTest
public with sharing class CreateCascadingSelectControllerTest {

    /**
     * Test correct parsing of a csv without
     */
    static testMethod void csvSimpleParseTesting() {

        CreateCascadingSelectController controller = new CreateCascadingSelectController(new ApexPages.Standardcontroller(new CascadingSelect__c()));
        controller.fileName = 'uploadCsv.csv';
        controller.fileBinary = Blob.valueOf(TestUtils.getValidCascadingSelectCsv());
        controller.cascadingSelect.Name = 'Some Name';
        controller.cascadingSelect.Description__c = 'Some Description';

        // Process test
        Test.startTest();
        controller.readFile();
        Test.stopTest();

        // Assertions

        // assert correct insertion of the CascadingSelect__c
        List<CascadingSelect__c> selectCascading = [SELECT Name, Description__c, Status__c FROM CascadingSelect__c WHERE Name = 'Some Name'];
        System.assertEquals(1, selectCascading.size(), 'one CascadingSelect__c object only must exist with this name');
        System.assertEquals('Some Description', selectCascading[0].Description__c, 'the Description__c was not correctly saved');
        System.assertEquals(C.CASCADING_STATUS_UPLOADED, selectCascading[0].Status__c, 'The status must be ready' );

        // assert correct insertion of the CascadingLevels__c and association with the CascadingSelect__c
        List<CascadingLevel__c> levelLinkedList = [SELECT Id, Name__c,ControllingLevel__c,Position__c,
                                                            (SELECT Id,
                                                                    Position__c,
                                                                    Value__c,
                                                                    ControllingSelectValue__c
                                                             FROM Cascading_Select_Values__r
                                                             ORDER BY Position__c
                                                             )
                                                   FROM CascadingLevel__c
                                                   WHERE CascadingSelect__c = :selectCascading[0].Id
                                                   ORDER BY Position__c];
        System.assertEquals(3, levelLinkedList.size(), 'There should be three levels for the CascadingSelect__c');

        // assert correct name__c assignment
        System.assertEquals('Select Make', levelLinkedList[0].Name__c, 'The Name__c of the Level in incorrect');
        System.assertEquals('Select Model', levelLinkedList[1].Name__c, 'The Name__c of the Level in incorrect');
        System.assertEquals('Select Year', levelLinkedList[2].Name__c, 'The Name__c of the Level in incorrect');

        // assert correct assignment of controlling level and position
        Integer i = 1;
        for (CascadingLevel__c level : levelLinkedList){
            System.assertEquals(i, level.Position__c, 'the position is incorrect');
            System.assertEquals((i != 1) ? levelLinkedList[i-2].Id : null, level.ControllingLevel__c, 'The controlling level is incorrect');
            i++;
        }

        // assert correct insertion of the CascadingSelectValue__c and correct association to their parent CascadingLevel__c
        System.assertEquals(3, levelLinkedList[0].Cascading_Select_Values__r.size(), 'There should be 3 values for the first level');

        System.assertEquals(13, levelLinkedList[1].Cascading_Select_Values__r.size(), 'There should be 13 values for the second level');

        System.assertEquals(33, levelLinkedList[2].Cascading_Select_Values__r.size(), 'There should be 33 values for the third level');

        // get the second level to evaluate correct generation of the tree
        List<CascadingSelectValue__c> valueSecondLevel = [SELECT ControllingSelectValue__r.Value__c,
                                                                 Value__c,
                                                            (SELECT Id,
                                                                    Position__c,
                                                                    Value__c,
                                                                    ControllingSelectValue__c
                                                             FROM Cascading_Select_Values__r
                                                             ORDER BY Position__c
                                                             )
                                                             FROM CascadingSelectValue__c
                                                             WHERE CascadingLevel__r.Position__c = 2
                                                             ORDER BY Position__c
                                                         ];

       // There should be 13 values for the second level values
       System.assertEquals(13, valueSecondLevel.size(), 'There should be 13 values for the second level');

       i = 1;
       for (CascadingSelectValue__c selectValue : valueSecondLevel){

            // Check the parents are correct
            if(i <= 5) {
                System.AssertEquals('Audi', selectValue.ControllingSelectValue__r.Value__c);
            }else if (i <= 12) {
                System.AssertEquals('BMW', selectValue.ControllingSelectValue__r.Value__c);
            }else if (i <= 13) {
                System.AssertEquals('Honda', selectValue.ControllingSelectValue__r.Value__c);
            }

            // Check the child size is correct for each element of the list
            if (i == 1 || i == 2 || i == 4 || i == 5 || i == 6 || i == 10 || i == 13){
                System.AssertEquals(3, selectValue.Cascading_Select_Values__r.size(), 'the child list size is incorrect');
            }else if (i == 3){
                System.AssertEquals(4, selectValue.Cascading_Select_Values__r.size(), 'the child list size is incorrect');
            }else if (i == 7 || i == 8 || i == 12){
                System.AssertEquals(2, selectValue.Cascading_Select_Values__r.size(), 'the child list size is incorrect');
            }else if (i == 9 || i == 11){
                System.AssertEquals(1, selectValue.Cascading_Select_Values__r.size(), 'the child list size is incorrect');
            }
            i++;
       }
    }

    /**
     * Test that the uploaded file has the correct file extension
     */
    static testmethod void testCorrectFileExtension() {

        CreateCascadingSelectController controller = new CreateCascadingSelectController(new ApexPages.Standardcontroller(new CascadingSelect__c()));
        controller.fileName = 'uploadCsv.csv';
        controller.fileBinary = Blob.valueOf('csv');
        controller.cascadingSelect.Name = 'Some Name';
        controller.cascadingSelect.Description__c = 'Some Description';

        System.assert(controller.validateFile());
        System.assert(ApexPages.getMessages().size() == 0);
    }

    /**
     * Test that the correct error is generated if the file extension is incorrect
     */
    static testMethod void testIncorrectFileExtension() {

        CreateCascadingSelectController controller = new CreateCascadingSelectController(new ApexPages.Standardcontroller(new CascadingSelect__c()));
        controller.fileName = 'uploadCsv.theHorror';
        controller.fileBinary = Blob.valueOf('csv');
        controller.cascadingSelect.Name = 'Some Name';
        controller.cascadingSelect.Description__c = 'Some Description';

        System.assert(!controller.validateFile());
        System.assert(ApexPages.getMessages().size() > 0);
        System.assertEquals(
            ApexPages.getMessages()[0].getSummary(), System.label.LOOKUP_ERR_WRONG_FILE_EXTENSION
        );
        System.assertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.severity.ERROR);
    }

    /**
     * Test that the correct error is generated if the file extension is not present
     */
    static testMethod void testNoFileExtension() {

        CreateCascadingSelectController controller = new CreateCascadingSelectController(new ApexPages.Standardcontroller(new CascadingSelect__c()));
        controller.fileName = 'uploadCsv';
        controller.fileBinary = Blob.valueOf('csv');
        controller.cascadingSelect.Name = 'Some Name';
        controller.cascadingSelect.Description__c = 'Some Description';

        System.assert(!controller.validateFile());
        System.assert(ApexPages.getMessages().size() > 0);
        System.assertEquals(
            ApexPages.getMessages()[0].getSummary(), System.label.LOOKUP_ERR_WRONG_FILE_EXTENSION
        );
        System.assertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.severity.ERROR);
      }

    /**
     * Test having <filename>.csv.csv as the file name. Should be allowed
     */
    static testMethod void testCsvInMiddleValid() {

        CreateCascadingSelectController controller = new CreateCascadingSelectController(new ApexPages.Standardcontroller(new CascadingSelect__c()));
        controller.fileName = 'upload.Csv.CSV';
        controller.fileBinary = Blob.valueOf('csv');
        controller.cascadingSelect.Name = 'Some Name';
        controller.cascadingSelect.Description__c = 'Some Description';

        System.assert(controller.validateFile());
        System.assert(ApexPages.getMessages().size() == 0);
    }

    /**
     * Test having <filename>.csv.xls as the file name. Should be invalid
     */
    static testMethod void testCsvInMiddleInvalid() {

        CreateCascadingSelectController controller = new CreateCascadingSelectController(new ApexPages.Standardcontroller(new CascadingSelect__c()));
        controller.fileName = 'upload.Csv.xls';
        controller.fileBinary = Blob.valueOf('csv');
        controller.cascadingSelect.Name = 'Some Name';
        controller.cascadingSelect.Description__c = 'Some Description';

        System.assert(!controller.validateFile());
        System.assert(ApexPages.getMessages().size() > 0);
        System.assertEquals(
            ApexPages.getMessages()[0].getSummary(), System.label.LOOKUP_ERR_WRONG_FILE_EXTENSION
        );
        System.assertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.severity.ERROR);
    }

    /**
     * Test that the correct error is generated if the file is null and an attempt at validating a file is carried out
     */
    static testMethod void testNullFile() {

        CreateCascadingSelectController controller = new CreateCascadingSelectController(new ApexPages.Standardcontroller(new CascadingSelect__c()));
        controller.fileName = 'uploadCsv.csv';
        controller.fileBinary = null;
        controller.cascadingSelect.Name = 'Some Name';
        controller.cascadingSelect.Description__c = 'Some Description';

        System.assert(!controller.validateFile());
        System.assert(ApexPages.getMessages().size() > 0);
        System.assertEquals(
            ApexPages.getMessages()[0].getSummary(), System.label.LOOKUP_ERR_SELECTFILE
        );
        System.assertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.severity.ERROR);
    }

    /**
     * IDALMSA-4800
     *
     * Check validation rule on unique names inserting cascading selects
     */
    static testMethod void testUniqueNameCascadingSelectInsert(){
        // Create cascading select
        CascadingSelect__c cascading1 = new CascadingSelect__c(Name = 'testUniqueName', Description__c = '');
        insert cascading1;
        // Create another cascading with same name
        CascadingSelect__c cascading2 = new CascadingSelect__c(Name = 'testUniqueName', Description__c = 'Description');
        
        Test.startTest();
            try{
                insert cascading2;
                system.assert(false, 'should fail here since name of cascading selects must be unique');
            }catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.CASCADING_UNIQUE_NAME));
            }
        Test.stopTest();
    }

    /**
     * IDALMSA-4800
     *
     * Check validation rule on unique names updating cascading selects
     */
    static testMethod void testUniqueNameCascadingSelectUpdate(){
        // Create cascading select
        CascadingSelect__c cascading1 = new CascadingSelect__c(Name = 'testUniqueName', Description__c = '');
        // Create another cascading with same name
        CascadingSelect__c cascading2 = new CascadingSelect__c(Name = 'testUniqueName2', Description__c = 'Description');
        insert new List<CascadingSelect__c>{cascading1,cascading2};
        
        // Set name for second cascading same as first cascading
        cascading2.Name = 'testUniqueName';

        Test.startTest();
            try{
                update cascading2;
                system.assert(false, 'should fail here since name of cascading selects must be unique');
            }catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.CASCADING_UNIQUE_NAME));
            }
        Test.stopTest();
    }
}
