/*
 * Class to test the Generatation of instance data
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class GenerateInstanceDataTest {

    private class TestGetInstanceData {

        Map<String, SObjectContactAssociation__c> sObjectContactAssociations;

        Mobile_User__c mobileUser;
        List<GenerateInstanceData.ObjectInstanceDataDefinition> testInstances;

        // Records for the first JobHierarchy
        List<Contact> contacts;
        List<Submission__c> submissions;
        List<SubmissionPPIValue__c> submissionPpis;

        // Records for the 2nd JobHierarchy
        List<Account> accounts;
        List<Case> cases;

        public TestGetInstanceData() {

            Contact mobileUserContact = TestUtils.createSurveyor();
            this.mobileUser =
                TestUtils.createMobileUser(
                    mobileUserContact, 'GIDT1', 'GIDT1', C.SURVEYOR_STATUS_ACTIVE
                );
            this.testInstances = new List<GenerateInstanceData.ObjectInstanceDataDefinition>();
            this.cases = new List<Case>();
        }

        public List<Account> getAccounts() {
            return this.accounts;
        }

        public Mobile_User__c getMobileUser() {
            return this.mobileUser;
        }

        public List<GenerateInstanceData.ObjectInstanceDataDefinition> getTestInstances() {
            return this.testInstances;
        }

        public void clearTestInstances() {
            this.testInstances.clear();
        }

        public void addAllInstances() {
            addSubmissionObjectInstance();
            addAccountCaseTemplateObjectInstance();
        }

        /**
         * Set up a full test suite
         */
        public void fullInit() {
            createTestJobTemplates();
            setUpSubmissionData();
            addContactCaseData();
            setAccountCaseData();
            addAccountCaseTemplateObjectInstance();
        }

        public List<JobTemplate__c> createTestJobTemplates() {
            List<JobTemplate__c> jobTemplates = new List<JobTemplate__c>();
            JobTemplate__c jobTemplate1 =
                GenerateMetaDataTest.createJobTemplate1();
            JobTemplate__c jobTemplate2 =
                GenerateMetaDataTest.createAccountCaseJobTemplate();
            JobTemplate__c jobTemplate3 =
                GenerateMetaDataTest.createContactCaseJobTemplate();
            List<JobTemplate__c> newJobTemplates = new List<JobTemplate__c>{
                jobTemplate1,
                jobTemplate2,
                jobTemplate3
            };
            insert newJobTemplates;

            insert(new List<TaskTemplate__c>{
                TaskTemplateDO.createDataViewTaskTemplate(
                    'Task1',
                    1,
                    jobTemplate1.Id,
                    'SomeInstructions',
                    '1'
                ),
                TaskTemplateDO.createDataViewTaskTemplate(
                    'Task2',
                    1,
                    jobTemplate2.Id,
                    'SomeInstructions',
                    '2'
                ),
                TaskTemplateDO.createDataViewTaskTemplate(
                    'Task3',
                    1,
                    jobTemplate3.Id,
                    'SomeInstructions',
                    '1'
                )
            });
            JobTemplateDO.setJobTemplatesToPublished(newJobTemplates);
            update(newJobTemplates);
            return newJobTemplates;
        }

        /**
         * Set up the test data for the Contact -> Submission -> SubmissionPPI
         * template
         */
        public void setUpSubmissionData() {
            addDataForSubmissionTemplate();
            assignContactsToContact();
            addSubmissionObjectInstance();
        }

        /**
         * Add records for the Submission template
         */
        private void addDataForSubmissionTemplate() {
            this.contacts = TestUtils.createContacts(3);

            // Create some submissions
            Survey__c survey = TestUtils.createSurvey('TestSurvey');
            SurveyVersion__c version = [
                SELECT
                    Id
                FROM
                    SurveyVersion__c
                WHERE
                    Survey__c = :survey.Id
            ][0];
            Submission__c sub1 = TestUtils.createSubmission(survey.Id, version.Id, this.contacts[0].Id);
            Submission__c sub2 = TestUtils.createSubmission(survey.Id, version.Id, this.contacts[0].Id);
            Submission__c sub3 = TestUtils.createSubmission(survey.Id, version.Id, this.contacts[1].Id);
            Submission__c sub4 = TestUtils.createSubmission(survey.Id, version.Id, this.contacts[1].Id);
            Submission__c sub5 = TestUtils.createSubmission(survey.Id, version.Id, this.contacts[2].Id);
            Submission__c sub6 = TestUtils.createSubmission(survey.Id, version.Id, this.contacts[2].Id);
            this.submissions = new List<Submission__c>{ sub1, sub2, sub3, sub4, sub5, sub6 };
            insert(this.submissions);

            // Create some Submission Ppi Values
            UnitOfWork unitOfWork = new UnitOfWork();
            PPITable__c ppiTable = PpiTableDomainTest.createPpiTable('PPITable');
            unitOfWork = PpiTableDomainTest.addPpiTableToUnitOfWork(ppiTable, null, unitOfWork);
            PPITableDataSet__c dataSet =
                PpiTableDataSetDomainTest.createPpiTableDataSet();
            unitOfWork = PpiTableDataSetDomainTest.addPpiTableDataSetToUnitOfWork(
                dataSet,
                ppiTable,
                survey,
                version,
                unitOfWork
            );
            PPITableLine__c tableLine =
                PpiTableLineDomainTest.createPpiTableLine();
            unitOfWork = PpiTableLineDomainTest.addPpiTableLineToUnitOfWork(
                tableLine,
                ppiTable,
                unitOfWork
            );
            unitOfWork.commitWork();
            SubmissionPPIValue__c spv1 = TestUtils.createSubmissionPpi(tableLine.Id, sub1.Id);
            SubmissionPPIValue__c spv2 = TestUtils.createSubmissionPpi(tableLine.Id, sub2.Id);
            SubmissionPPIValue__c spv3 = TestUtils.createSubmissionPpi(tableLine.Id, sub3.Id);
            SubmissionPPIValue__c spv4 = TestUtils.createSubmissionPpi(tableLine.Id, sub4.Id);
            SubmissionPPIValue__c spv5 = TestUtils.createSubmissionPpi(tableLine.Id, sub5.Id);
            SubmissionPPIValue__c spv6 = TestUtils.createSubmissionPpi(tableLine.Id, sub6.Id);
            this.submissionPpis = new List<SubmissionPPIValue__c>{ spv1, spv2, spv3, spv4, spv5, spv6 };
            insert(this.submissionPpis);
        }

        /**
         * Set up the data for the Contact Case template
         */
        public void addContactCaseData() {
            this.cases.addAll(TestUtils.createCasesForContacts(this.contacts));
        }

        /**
         * Set up the full test data for the account template
         */
        public void setAccountCaseData() {
            addDataForAccountCaseTemplate();
            assignAccountsToContact();
        }

        /**
         * Set up the data needed for the AccountCase template
         */
        private void addDataForAccountCaseTemplate() {
            this.accounts = TestUtils.createAccounts(3);
            this.cases.addAll(TestUtils.createCasesForAccounts(this.accounts));
        }

        /**
         * Update account at the position in the accounts list specified
         */
        public void updateAccount(Integer positionInList) {

            this.accounts[positionInList].Description = 'A New Description';
            update this.accounts[positionInList];
        }

        /**
         * Assign the contacts to the contact so they are linked as top level
         */
        private SObjectContactAssociation__c assignContactsToContact() {
            SObjectContactAssociation__c contactLink =
                SObjectContactAssociationDO.createNewRecords(
                    this.mobileUser.Contact__c,
                    Contact.SObjectType.getDescribe().getName(),
                    C.extractIds(this.contacts)
                )[0];
            insert contactLink;
            return contactLink;
        }

        /**
         * Assign the accounts to the contact so they are linked as top level
         */
        private SObjectContactAssociation__c assignAccountsToContact() {
            SObjectContactAssociation__c accountLink =
                SObjectContactAssociationDO.createNewRecords(
                    this.mobileUser.Contact__c,
                    Account.SObjectType.getDescribe().getName(),
                    C.extractIds(this.accounts)
                )[0];
            insert accountLink;
            return accountLink;
        }

        /**
         * Generate the ObjectInstances for the Contact->Submisson->SubmissionPPI template
         * This will be the ObjectInstances to test against
         */
        private void addSubmissionObjectInstance() {
            createObjectInstances(
                this.contacts,
                Contact.getSObjectType().getDescribe().getName(),
                new List<String>{
                    'Name',
                    'Id'
                },
                new Set<Id>()
            );
            createObjectInstances(
                this.submissions,
                Submission__c.getSObjectType().getDescribe().getName(),
                new List<String>{
                    Schema.SObjectType.Submission__c.Fields.Surveyor__c.getName(),
                    'Name',
                    'Id',
                    'CreatedDate'
                },
                new Set<Id>()
            );
            createObjectInstances(
                this.submissionPpis,
                SubmissionPPIValue__c.getSObjectType().getDescribe().getName(),
                new List<String>{
                    Schema.SObjectType.SubmissionPPIValue__c.Fields.Submission__c.getName()
                },
                new Set<Id>()
            );
        }

        /**
         * Generate the ObjectInstances for the Account Case template
         * This will be the ObjectInstances to test against
         */
        public void addAccountCaseTemplateObjectInstance() {
            createObjectInstances(
                this.accounts,
                Account.getSObjectType().getDescribe().getName(),
                new List<String>{
                    'Name',
                    'Fax'
                },
                new Set<Id>()
            );
            createObjectInstances(
                this.cases,
                Case.getSObjectType().getDescribe().getName(),
                new List<String>{
                    'CaseNumber',
                    'Subject'
                },
                new Set<Id>()
            );
        }

        /**
         * Add deleted data to instances
         */
        public void addDeletedInstances() {
            createObjectInstances(
                new List<SObject>(),
                Account.getSObjectType().getDescribe().getName(),
                new List<String>{
                    'Name',
                    'Fax'
                },
                new Set<Id>{this.accounts[0].Id}
            );
            createObjectInstances(
                new List<SObject>(),
                Case.getSObjectType().getDescribe().getName(),
                new List<String>{
                    'CaseNumber',
                    'Subject'
                },
                new Set<Id>{this.cases[0].Id}
            );
            createObjectInstances(
                new List<SObject>(),
                Contact.getSObjectType().getDescribe().getName(),
                new List<String>{
                    'Name',
                    'Id'
                },
                new Set<Id>()
            );
            createObjectInstances(
                new List<SObject>(),
                Submission__c.getSObjectType().getDescribe().getName(),
                new List<String>{
                    Schema.SObjectType.Submission__c.Fields.Surveyor__c.getName(),
                    'Name',
                    'Id',
                    'CreatedDate'
                },
                new Set<Id>()
            );
            createObjectInstances(
                new List<SObject>(),
                SubmissionPPIValue__c.getSObjectType().getDescribe().getName(),
                new List<String>{
                    Schema.SObjectType.SubmissionPPIValue__c.Fields.Submission__c.getName()
                },
                new Set<Id>()
            );
        }

        /**
         * Create the object instances for the update test
         */
        public void generateUpdateInstances() {

            createObjectInstances(
                new List<SObject>{this.accounts[0]},
                Account.getSObjectType().getDescribe().getName(),
                new List<String>{
                    'Name',
                    'Fax'
                },
                new Set<Id>()
            );
            createObjectInstances(
                new List<SObject>(),
                Case.getSObjectType().getDescribe().getName(),
                new List<String>{
                    'CaseNumber',
                    'Subject'
                },
                new Set<Id>()
            );
            createObjectInstances(
                new List<SObject>(),
                Contact.getSObjectType().getDescribe().getName(),
                new List<String>{
                    'Name',
                    'Id'
                },
                new Set<Id>()
            );
            createObjectInstances(
                new List<SObject>(),
                Submission__c.getSObjectType().getDescribe().getName(),
                new List<String>{
                    Schema.SObjectType.Submission__c.Fields.Surveyor__c.getName(),
                    'Name',
                    'Id',
                    'CreatedDate'
                },
                new Set<Id>()
            );
            createObjectInstances(
                new List<SObject>(),
                SubmissionPPIValue__c.getSObjectType().getDescribe().getName(),
                new List<String>{
                    Schema.SObjectType.SubmissionPPIValue__c.Fields.Submission__c.getName()
                },
                new Set<Id>()
            );
        }

        /**
         * Create and ObjectInstanceDataDefinition
         */
        private void createObjectInstances(
                List<SObject> records,
                String objectName,
                List<String> fields,
                Set<Id> deletedIds
        ) {
            GenerateInstanceData.ObjectInstanceDataDefinition ObjectInstanceDataDefinition =
                new GenerateInstanceData.ObjectInstanceDataDefinition(
                    objectName
                );
            for (SObject record : records) {
                ObjectInstanceDataDefinition.addRecord(
                    new GenerateInstanceData.InstanceDefinition(record, fields)
                );
            }
            ObjectInstanceDataDefinition.setDeletedInstances(deletedIds);
            this.testInstances.add(ObjectInstanceDataDefinition);
        }
    }

    /**
     * Test get initial data
     */
    static testMethod void testGetInstanceData() {

        TestGetInstanceData testData = new TestGetInstanceData();
        testData.fullInit();

        Test.startTest();
        List<GenerateInstanceData.ObjectInstanceDataDefinition> instances =
            GenerateInstanceData.generateInstanceData(
                GenerateMetaData.getHierarchyMetadata(
                    JobTemplateDO.getMobileUserJobTemplates(
                        testData.getMobileUser().Contact__r,
                        JobTemplateDO.STATUS_PUBLISHED
                    )
                ),
                testData.getMobileUser().Contact__c,
                new Map<String, GenerateInstanceData.KnownInstance>(),
                DateTime.now().addDays(-1)
            );
        Test.stopTest();
        System.assertEquals(testData.getTestInstances().size(), instances.size());

        // Put the test instances into a map in order to easily compare to
        // the fetched instances
        Map<String, GenerateInstanceData.ObjectInstanceDataDefinition> testInstanceMap =
            createInstanceMap(testData.getTestInstances());

        // Loop through the discovered instances and check that they match the test instances
        for (GenerateInstanceData.ObjectInstanceDataDefinition instance : instances) {
            GenerateInstanceData.ObjectInstanceDataDefinition testInstance =
                testInstanceMap.get(instance.getObjectName());
            System.assert(testInstance != null);
            System.assertEquals(
                testInstance.getRecords().size(), instance.getRecords().size()
            );
        }
    }

    /**
     * Test removing a top level assignment
     */
    static testMethod void deleteTopLevelAssignment() {

        TestGetInstanceData testData = new TestGetInstanceData();
        testData.fullInit();

        Map<String, GenerateInstanceData.KnownInstance> prevIdMap =
            getKnownInstances(testData.getTestInstances());

        C.wait(1);

        // Take a time stamp for the last sync
        DateTime syncTime = DateTime.now();
        C.wait(1);
        SObjectContactAssociationDO.removeIds(
            testData.getMobileUser().Contact__c,
            'Account',
            new List<String>{String.valueOf(testData.getAccounts()[0].Id)}
        );
        testData.clearTestInstances();
        testData.addDeletedInstances();
        List<GenerateInstanceData.ObjectInstanceDataDefinition> testInstances =
            testData.getTestInstances();

        Test.startTest();
        List<GenerateInstanceData.ObjectInstanceDataDefinition> instances =
            GenerateInstanceData.generateInstanceData(
                GenerateMetaData.getHierarchyMetadata(
                    JobTemplateDO.getMobileUserJobTemplates(
                        testData.getMobileUser().Contact__r,
                        JobTemplateDO.STATUS_PUBLISHED
                    )
                ),
                testData.getMobileUser().Contact__c,
                prevIdMap,
                syncTime
            );
        Test.stopTest();

        // Put the test instances into a map in order to easily compare to the fetched instances
        Map<String, GenerateInstanceData.ObjectInstanceDataDefinition> testInstanceMap =
            createInstanceMap(testInstances);

        // Loop through the discovered instances and check that they match the test instances
        for (GenerateInstanceData.ObjectInstanceDataDefinition instance : instances) {
            GenerateInstanceData.ObjectInstanceDataDefinition testInstance =
                testInstanceMap.get(instance.getObjectName());
            System.assert(testInstance != null);
            System.assertEquals(
                testInstance.getRecords().size(),
                instance.getRecords().size()
            );
            System.assertEquals(
                testInstance.getDeletedInstances().size(),
                instance.getDeletedInstances().size()
            );
        }
    }

    /**
     * Test updating a record
     */
    static testMethod void testGetInstanceDataUpdate() {

        TestGetInstanceData testData = new TestGetInstanceData();
        testData.fullInit();

        Map<String, GenerateInstanceData.KnownInstance> prevIdMap =
            getKnownInstances(testData.getTestInstances());

        C.wait(1);

        // Take a time stamp for the last sync
        DateTime syncTime = DateTime.now();
        C.wait(1);
        testData.clearTestInstances();
        testData.updateAccount(0);
        testData.generateUpdateInstances();
        List<GenerateInstanceData.ObjectInstanceDataDefinition> testInstances =
            testData.getTestInstances();

        Test.startTest();
        List<GenerateInstanceData.ObjectInstanceDataDefinition> instances =
            GenerateInstanceData.generateInstanceData(
                GenerateMetaData.getHierarchyMetadata(
                    JobTemplateDO.getMobileUserJobTemplates(
                        testData.getMobileUser().Contact__r,
                        JobTemplateDO.STATUS_PUBLISHED
                    )
                ),
                testData.getMobileUser().Contact__c,
                prevIdMap,
                syncTime
            );
        Test.stopTest();

        // Put the test instances into a map in order to easily compare to the fetched instances
        Map<String, GenerateInstanceData.ObjectInstanceDataDefinition> testInstanceMap =
            createInstanceMap(testInstances);

        // Loop through the discovered instances and check that they match the test instances
        for (GenerateInstanceData.ObjectInstanceDataDefinition instance : instances) {
            GenerateInstanceData.ObjectInstanceDataDefinition testInstance =
                testInstanceMap.get(instance.getObjectName());
            System.assert(testInstance != null);
            System.assertEquals(
                testInstance.getRecords().size(),
                instance.getRecords().size(),
                'OBJECT NAME: ' + instance.getObjectName()
            );
        }
    }

    /**
     * Convert a list of GenerateInstanceData.ObjectInstanceDataDefinition into a Map with the object API name as the key
     *
     * @param instances - A list of the GenerateInstanceData.ObjectInstanceDataDefinition that are being converted to a map
     *
     * @return - The new Map
     */
     static Map<String, GenerateInstanceData.ObjectInstanceDataDefinition> createInstanceMap(
            List<GenerateInstanceData.ObjectInstanceDataDefinition> instances
    ) {

        Map<String, GenerateInstanceData.ObjectInstanceDataDefinition> returnValues =
            new Map<String, GenerateInstanceData.ObjectInstanceDataDefinition>();
        for (GenerateInstanceData.ObjectInstanceDataDefinition instance : instances) {
            returnValues.put(instance.getObjectName(), instance);
        }
        return returnValues;
     }

    /**
     * Create a Map for the instance ids in
     *
     * @param objects - The list of object instance
     */
    static Map<String, GenerateInstanceData.KnownInstance> getKnownInstances(
            List<GenerateInstanceData.ObjectInstanceDataDefinition> objects
    ) {

        Map<String, GenerateInstanceData.KnownInstance> returnMap = new Map<String, GenerateInstanceData.KnownInstance>();
        for (GenerateInstanceData.ObjectInstanceDataDefinition obj : objects) {
            Set<Id> existingIds = new Set<Id>();
            for (GenerateInstanceData.InstanceDefinition instance : obj.getRecords()) {
                existingIds.add(instance.getInstanceId());
            }
            GenerateInstanceData.KnownInstance exObj = new GenerateInstanceData.KnownInstance(obj.getObjectname());
            exObj.addRecords(existingIds);
            returnMap.put(obj.getObjectname(), exObj);
        }
        return returnMap;
    }
}