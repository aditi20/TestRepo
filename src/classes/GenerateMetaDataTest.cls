/*
 * Class to test the Generatation of meta data
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies     - odavies@grameenfoundation.org
 * @author Ernesto Quesada - equesada@altimetrik.com
 */
@isTest
public class GenerateMetaDataTest {

    static String CONTACT_OBJECT = Contact.getSObjectType().getDescribe().getName();
    static String SUBMISSION_OBJECT = Submission__c.getSObjectType().getDescribe().getName();
    static String PPI_VALUE_OBJECT = SubmissionPPIValue__c.getSObjectType().getDescribe().getName();
    static String MEMBER_OBJECT = ContactGroupMember__c.getSObjectType().getDescribe().getName();
    static String DEVICE_OBJECT = Device__c.getSObjectType().getDescribe().getName();

    static String SUBMISSION_FIELD = Schema.SObjectType.SubmissionPPIValue__c.Fields.Submission__c.getName();
    static String SURVEYOR_FIELD = Schema.SObjectType.Submission__c.Fields.Surveyor__c.getName();
    static String CONTACT_FIELD = Schema.SObjectType.ContactGroupMember__c.Fields.Contact__c.getName();
    static String APP_VERSION_FIELD = Schema.SObjectType.Device__c.Fields.App_version__c.getName();
    static String DEVICE_ID_FIELD = Schema.SObjectType.Device__c.Fields.Device_Id__c.getName();
    static String LAST_CHECK_FIELD = Schema.SObjectType.Device__c.Fields.LastCheckInBy__c.getName();

    static String JOB_TEMPLATE_NAME_1 = 'JobTemp1';
    static String JOB_TEMPLATE_NAME_2 = 'JobTemp2';

    static Map<String, Integer> fieldNumberCount = new Map<String, Integer>{
        'Contact' => 5,
        SUBMISSION_OBJECT => 4,
        PPI_VALUE_OBJECT => 1,
        MEMBER_OBJECT => 2
    };

    /**
     * Set up a generic test hierarchy
     * Has three jobs that use four different objects
     * Contact has 5 fields
     * Submission__c has 4 fields
     * SubmissionPPIValue__c has 1 field
     * Member has 2 fields
     */
    public static void setUpTestHierarchy() {

        JobTemplate__c jobTemplate1 = createJobTemplate1();
        JobTemplate__c jobTemplate2 = createJobTemplate2();
        JobTemplate__c jobTemplate3 = createJobTemplate3();
        List<JobTemplate__c> newJobTemplates = new List<JobTemplate__c>{
            jobTemplate1,
            jobTemplate2,
            jobTemplate3
        };
        insert newJobTemplates;

        // Add a task to each job. Just one for now as the task templates do not affect the meta-data at the moment
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
        JobTemplateDo.setJobTemplatesToPublished(newJobTemplates);
        update(newJobTemplates);
    }

    /**
     * Create a JobTemplate that has 3 objects
     * Contact has 2 fields assigned to it
     * Submission has 5 fields assigned to it
     * Submission PPI Valus has 1 field assigned to it
     */
    public static JobTemplate__c createJobTemplate1() {

        // Create three jobs and add a hierarchy to them
        List<JobTemplateDo.ObjectHierarchy> jobTempHier1 = new List<JobTemplateDo.ObjectHierarchy>();
        JobTemplateDo.ObjectHierarchy oh1 =
            new JobTemplateDo.ObjectHierarchy('1', 'Field Officer', CONTACT_OBJECT);
        oh1.addListField('Name');
        oh1.addListField('Id');
        JobTemplateDo.ObjectHierarchy oh2 =
            new JobTemplateDo.ObjectHierarchy('2', 'Submission', SUBMISSION_OBJECT);
        oh2.addListField('Name');
        oh2.addDetailField('Name');
        oh2.addDetailField('Id');
        oh2.addDetailField('CreatedDate');
        oh2.addRelation('1', SURVEYOR_FIELD);
        JobTemplateDo.ObjectHierarchy oh3 =
            new JobTemplateDo.ObjectHierarchy('3', 'Submission PPI Value', PPI_VALUE_OBJECT);
        oh3.addListField(SUBMISSION_FIELD);
        oh3.addRelation('2', SUBMISSION_FIELD);
        jobTempHier1.add(oh1);
        jobTempHier1.add(oh2);
        jobTempHier1.add(oh3);
        return JobTemplateDO.createJobTemplate(
            JOB_TEMPLATE_NAME_1,
            JobTemplateDO.STATUS_DRAFT,
            JSON.serialize(jobTempHier1),
            'Desc1'
        );
    }


    /**
     * Job 2 has 2 objects
     * Contact has 3 fields assigned to it
     * Member has 2 fields assigned to it
     */
    private static JobTemplate__c createJobTemplate2() {

        List<JobTemplateDo.ObjectHierarchy> jobTempHier = new List<JobTemplateDo.ObjectHierarchy>();
        JobTemplateDo.ObjectHierarchy oh1 = new JobTemplateDo.ObjectHierarchy('1', 'Contact', CONTACT_OBJECT);
        oh1.addListField('Name');
        oh1.addDetailField('Id');
        oh1.addDetailField('CreatedDate');
        JobTemplateDo.ObjectHierarchy oh2 = new JobTemplateDo.ObjectHierarchy('2', 'Member', MEMBER_OBJECT);
        oh2.addListField('Name');
        oh2.addRelation('1', CONTACT_FIELD);
        jobTempHier.add(oh1);
        jobTempHier.add(oh2);
        return JobTemplateDO.createJobTemplate(
            JOB_TEMPLATE_NAME_2,
            JobTemplateDO.STATUS_DRAFT,
            JSON.serialize(jobTempHier),
            'Desc2'
        );
    }

    /**
     * Job 3 has 1 object
     * Contact has 2 fields assigned to it
     */
    private static JobTemplate__c createJobTemplate3() {

        List<JobTemplateDo.ObjectHierarchy> jobTempHier = new List<JobTemplateDo.ObjectHierarchy>();
        JobTemplateDo.ObjectHierarchy oh = new JobTemplateDo.ObjectHierarchy('1', 'Contact', CONTACT_OBJECT);
        oh.addListField('FirstName');
        oh.addDetailField('LastName');
        jobTempHier.add(oh);
        return JobTemplateDO.createJobTemplate(
            'JobTemp3',
            JobTemplateDO.STATUS_DRAFT,
            JSON.serialize(jobTempHier),
            'Desc3'
        );
    }

    /**
     * Create a fourth jobtemplate
     * Contact has 2 fields assigned to it
     * Device has 3 fields assigned to it
     */
    private static JobTemplate__c createJobTemplate4() {

        List<JobTemplateDo.ObjectHierarchy> jobTempHier = new List<JobTemplateDo.ObjectHierarchy>();
        JobTemplateDO.ObjectHierarchy oh1 =
            new JobTemplateDO.ObjectHierarchy('1', 'Contact', CONTACT_OBJECT);
        oh1.addListField('Email');
        oh1.addDetailField('LastName');
        jobTempHier.add(oh1);
        JobTemplateDO.ObjectHierarchy oh2 =
            new JobTemplateDO.ObjectHierarchy('2', 'Device', DEVICE_OBJECT);
        oh2.addListField(APP_VERSION_FIELD);
        oh2.addDetailField(DEVICE_ID_FIELD);
        oh2.addRelation('1', LAST_CHECK_FIELD);
        jobTempHier.add(oh2);
        return JobTemplateDO.createJobTemplate(
            'JobTemp4',
            JobTemplateDO.STATUS_DRAFT,
            JSON.serialize(jobTempHier),
            'Desc4'
        );
    }

    /**
     * Create a test jobTemplate that has a suitable hierarchy for Accounts -> Cases
     */
    public static JobTemplate__c createAccountCaseJobTemplate() {

        List<JobTemplateDo.ObjectHierarchy> jobTempHier = new List<JobTemplateDo.ObjectHierarchy>();
        JobTemplateDO.ObjectHierarchy oh1 =
            new JobTemplateDO.ObjectHierarchy('1', 'Account', 'Account');
        oh1.addListField('Name');
        oh1.addDetailField('Fax');
        jobTempHier.add(oh1);
        JobTemplateDO.ObjectHierarchy oh2 =
            new JobTemplateDO.ObjectHierarchy('2', 'Case', 'Case');
        oh2.addListField('CaseNumber');
        oh2.addDetailField('Subject');
        oh2.addRelation('1', 'AccountId');
        jobTempHier.add(oh2);
        return JobTemplateDO.createJobTemplate(
            'JobTemp5',
            JobTemplateDO.STATUS_DRAFT,
            JSON.serialize(jobTempHier),
            'Desc5'
        );
    }

    /**
     * Create a test jobTemplate that has a suitable hierarchy for Accounts -> Cases
     */
    public static JobTemplate__c createContactCaseJobTemplate() {

        List<JobTemplateDo.ObjectHierarchy> jobTempHier = new List<JobTemplateDo.ObjectHierarchy>();
        JobTemplateDO.ObjectHierarchy oh1 =
            new JobTemplateDO.ObjectHierarchy('1', 'Contact', 'Contact');
        oh1.addListField('Id');
        oh1.addDetailField('Fax');
        jobTempHier.add(oh1);
        JobTemplateDO.ObjectHierarchy oh2 =
            new JobTemplateDO.ObjectHierarchy('2', 'Case', 'Case');
        oh2.addListField('CaseNumber');
        oh2.addDetailField('Subject');
        oh2.addRelation('1', 'ContactId');
        jobTempHier.add(oh2);
        return JobTemplateDO.createJobTemplate(
            'JobTemp6',
            JobTemplateDO.STATUS_DRAFT,
            JSON.serialize(jobTempHier),
            'Desc5'
        );
    }

    /**
     * Change the JobTemplates so a different metadata needs to be generated
     * Needs to be called after setUpHierarchy()
     * Will close job 2 and create a forth job
     */
    static void changeHierarchy() {

        // Deactivate a jobs
        JobTemplate__c deactivateTemplate = [
            SELECT
                Id,
                Status__c
            FROM
                JobTemplate__c
            WHERE
                Name = :JOB_TEMPLATE_NAME_2
        ];
        deactivateTemplate.Status__c = JobTemplateDO.STATUS_CLOSED;
        update(deactivateTemplate);

        // Create a new jobs to add a new field on an existing object and add a new object
        JobTemplate__c jobTemplate = createJobTemplate4();

        insert(jobTemplate);
        insert(TaskTemplateDO.createDataViewTaskTemplate(
            'Task4',
            1,
            jobTemplate.Id,
            'SomeInstructions',
            '1'
        ));
        jobTemplate.Status__c = JobTemplateDO.STATUS_PUBLISHED;
        update(jobTemplate);
    }

    /**
     * Create a test metadata delta object to test the serialisation against
     */
    static GenerateMetaData.MetaDataDelta testMetaDataDeltaObject;
    static void setUpDeltaTestObject() {
        testMetaDataDeltaObject = new GenerateMetaData.MetaDataDelta();

        // Add the object that is expected to be removed
        testMetaDataDeltaObject.addRemovedObjects(ContactGroupMember__c.sObjectType.getDescribe().getName());

        // Add the Contact metadata delta
        GenerateMetaData.ObjectDefinitionDelta contactDelta = new GenerateMetaData.ObjectDefinitionDelta(Contact.sObjectType.getDescribe().getName());
        contactDelta.addFieldDef(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Contact.fields.Email));
        contactDelta.addFieldToRemove(Schema.sObjectType.Contact.fields.CreatedDate.getName());
        testMetaDataDeltaObject.addToMetaData(contactDelta);

        // Add the Device__c metadata delta
        GenerateMetaData.ObjectDefinitionDelta deviceDelta = new GenerateMetaData.ObjectDefinitionDelta(Device__c.sObjectType.getDescribe().getName());
        deviceDelta.addFieldDef(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Device__c.fields.Device_Id__c));
        deviceDelta.addFieldDef(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Device__c.fields.LastCheckInBy__c));
        deviceDelta.addFieldDef(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Device__c.fields.App_version__c));
        testMetaDataDeltaObject.addToMetaData(deviceDelta);
    }

    /**
     * Create the maps that are used to test the FullMetaData in order to take into account the namespace
     * This full metadata contains the same objects and fields as the one created from the hierarchy
     * set up in the create test hierarchy
     */
    static Map<String, GenerateMetaData.ObjectDefinition> fullMetaDataTestMap;
    static void setUpFullMetaDataTest() {

        // Create the map
        fullMetaDataTestMap = new Map<String, GenerateMetaData.ObjectDefinition>();

        // Create a map for SubmissionPPIValue__c object
        GenerateMetaData.ObjectDefinition ppiValue = new GenerateMetaData.ObjectDefinition(SubmissionPPIValue__c.sObjectType.getDescribe().getName());
        ppiValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.SubmissionPPIValue__c.fields.Submission__c));
        fullMetaDataTestMap.put(SubmissionPPIValue__c.sObjectType.getDescribe().getName(), ppiValue);

        // Set up map for the Contact object
        GenerateMetaData.ObjectDefinition contactValue = new GenerateMetaData.ObjectDefinition(Contact.sObjectType.getDescribe().getName());
        contactValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Contact.fields.LastName));
        contactValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Contact.fields.Id));
        contactValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Contact.fields.FirstName));
        contactValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Contact.fields.CreatedDate));
        contactValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Contact.fields.Name));
        fullMetaDataTestMap.put(Contact.sObjectType.getDescribe().getName(), contactValue);

        // Add the ContactGroupMember__c
        GenerateMetaData.ObjectDefinition memberValue = new GenerateMetaData.ObjectDefinition(ContactGroupMember__c.sObjectType.getDescribe().getName());
        memberValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.ContactGroupMember__c.fields.Contact__c));
        memberValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.ContactGroupMember__c.fields.Name));
        fullMetaDataTestMap.put(ContactGroupMember__c.sObjectType.getDescribe().getName(), memberValue);

        // Add the Submission__c
        GenerateMetaData.ObjectDefinition submissionValue = new GenerateMetaData.ObjectDefinition(Submission__c.sObjectType.getDescribe().getName());
        submissionValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Submission__c.fields.Surveyor__c));
        submissionValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Submission__c.fields.Id));
        submissionValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Submission__c.fields.CreatedDate));
        submissionValue.addFieldDefinition(new GenerateMetaData.FieldDefinition(Schema.sObjectType.Submission__c.fields.Name));
        fullMetaDataTestMap.put(Submission__c.sObjectType.getDescribe().getName(), submissionValue);
    }

    /**
     * Test the generation of full meta-data JSON String
     */
    static testMethod void testGetFullMetaData() {

        // Add a new mobile user
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor('LastName', 'user', 'pass', MobileUserDO.STATUS_ACTIVE);

        setUpTestHierarchy();
        setUpFullMetaDataTest();
        Test.startTest();

        // Get the hierarchy metadata for the Job Templates available to the mobile user
        Map<String, GenerateMetaData.HierarchyObjectDefinitions> objectMetaData =
           GenerateMetaData.getHierarchyMetadata(JobTemplateDO.getMobileUserJobTemplates(surveyor.theContact, JobTemplateDO.STATUS_PUBLISHED));
        GenerateMetaData.FullMetaData fullMetaData = GenerateMetaData.generateFullMetaData(objectMetaData);

        // Step through the genertated metadata and check that it has been created properly
        System.assert(fullMetaData.getMetaData().size() == 4);
        for (GenerateMetaData.ObjectDefinition objDef : fullMetaData.getMetaData().values()) {

            // Check that the name is valid
            System.assert(fullMetaDataTestMap.containsKey(objDef.getObjectName()));

            // Loop through the available fields and check that the right fields were found and the data in them in correct
            GenerateMetaData.ObjectDefinition testObjDef = fullMetaDataTestMap.get(objDef.getObjectName());
            for (GenerateMetaData.FieldDefinition fieldDef : objDef.getFieldDefs().values()) {

                System.assert(testObjDef.getFieldDefs().containsKey(fieldDef.getFieldName()));
                GenerateMetaData.FieldDefinition testFieldDef = testObjDef.getFieldDefs().get(fieldDef.getFieldName());

                // Test that the data in the two field defs is the same
                System.assertEquals(testFieldDef.getFieldName(), fieldDef.getFieldName());
                System.assertEquals(testFieldDef.getLabel(), fieldDef.getLabel());
                System.assertEquals(testFieldDef.getFieldType(), fieldDef.getFieldType());
                System.assertEquals(testFieldDef.getLength(), fieldDef.getLength());
            }
        }
        Test.stopTest();
    }

    /**
     * Test the generation of a metadata delta
     */
    static testMethod void testCreateDelta() {

        // Set up the initial jobs
        setUpTestHierarchy();

        // Add a new mobile user
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor('LastName', 'user', 'pass', MobileUserDO.STATUS_ACTIVE);

       // Get the hierarchy metadata for the Job Templates available to the mobile user
       Map<String, GenerateMetaData.HierarchyObjectDefinitions> objectMetaData =
           GenerateMetaData.getHierarchyMetadata(JobTemplateDO.getMobileUserJobTemplates(surveyor.theContact, JobTemplateDO.STATUS_PUBLISHED));

        // Generate the base delta
        String originalMetaDataJsonString = JSON.serialize(GenerateMetaData.generateFullMetaData(objectMetaData));

        // Change the hierarchy
        changeHierarchy();
        objectMetaData =
           GenerateMetaData.getHierarchyMetadata(JobTemplateDO.getMobileUserJobTemplates(surveyor.theContact, JobTemplateDO.STATUS_PUBLISHED));

        // Generate the new delta
        String newMetaDataJsonString = JSON.serialize(GenerateMetaData.generateFullMetaData(objectMetaData));

        Test.startTest();

        // Generate the delta
        GenerateMetaData.MetaDataDelta delta = GenerateMetaData.getMetaDataDifference(originalMetaDataJsonString, newMetaDataJsonString);

        Test.stopTest();
        setUpDeltaTestObject();
        compareMetaDataDelta(testMetaDataDeltaObject, delta);
    }

    /**
     * Test that two equal FullMetaDatas return a null when trying to get a delta
     */
    static testMethod void testEqualMetaDatas() {

        // Set up the initial jobs
        setUpTestHierarchy();

        // Add a new mobile user
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor('LastName', 'user', 'pass', MobileUserDO.STATUS_ACTIVE);

       // Get the hierarchy metadata for the Job Templates available to the mobile user
       Map<String, GenerateMetaData.HierarchyObjectDefinitions> objectMetaData =
           GenerateMetaData.getHierarchyMetadata(JobTemplateDO.getMobileUserJobTemplates(surveyor.theContact, JobTemplateDO.STATUS_PUBLISHED));

        // Generate the base delta
        String originalMetaDataJsonString = JSON.serialize(GenerateMetaData.generateFullMetaData(objectMetaData));
        String newMetaDataJsonString = JSON.serialize(GenerateMetaData.generateFullMetaData(objectMetaData));

        Test.startTest();
        GenerateMetaData.MetaDataDelta metaDataDelta = GenerateMetaData.getMetaDataDifference(originalMetaDataJsonString, newMetaDataJsonString);
        Test.stopTest();
        System.assert(MetaDataDelta == null);
    }

    /**
     * Compare meta data delta
     *
     * @param expectedMetaData - the expected metadata to compare with
     * @param actualMetaData   - the actual metadata
     */
    static void compareMetaDataDelta(GenerateMetaData.MetaDataDelta expectedMetaData, GenerateMetaData.MetaDataDelta actualMetaData){

        // Compare the lists of removed objects
        System.assert(compareStringLists(
            expectedMetaData.removedObjects, actualMetaData.removedObjects),
            'The removedObjects lists are different. Expected: ' + expectedMetaData.removedObjects +
                ' Actual: ' + actualMetaData.removedObjects
        );

        // Compare the metadata
        System.assertEquals(expectedMetaData.metaData.size(), actualMetaData.metaData.size());

        // Build a map to be able to access the object definition delta of the actual metadata
        Map<String, GenerateMetaData.ObjectDefinitionDelta> objDefByName = new Map<String, GenerateMetaData.ObjectDefinitionDelta>();
        for(GenerateMetaData.ObjectDefinitionDelta objDef : actualMetaData.metaData){
            objDefByName.put(objDef.objectName, objDef);
        }

        // Compare each object definition delta
        for(GenerateMetaData.ObjectDefinitionDelta expectedObjDef : expectedMetaData.metaData){
            GenerateMetaData.ObjectDefinitionDelta actualObjDef = objDefByName.get(expectedObjDef.objectName);
            System.assertNotEquals(null, actualObjDef);
            System.assertEquals(expectedObjDef.add.size(), actualObjDef.add.size());

            // Compare the list of removed fields
            System.assert(compareStringLists(
                expectedObjDef.remove, actualObjDef.remove),
                'The removed fields list are different. Expected: ' + expectedObjDef.remove +
                ' Actual: ' + actualObjDef.remove
            );

            // Build a map to be able to access the field definition on the actual object definition delta
            Map<String, GenerateMetaData.FieldDefinition> fieldDefByName = new Map<String, GenerateMetaData.FieldDefinition>();
            for(GenerateMetaData.FieldDefinition fieldDef : actualObjDef.add){
                fieldDefByName.put(fieldDef.fieldName, fieldDef);
            }

            // Compare each field definition
            for(GenerateMetaData.FieldDefinition expectedFieldDef : expectedObjDef.add){
                GenerateMetaData.FieldDefinition actualFieldDef = fieldDefByName.get(expectedFieldDef.fieldName);
                System.assertNotEquals(null, actualFieldDef);
                System.assertEquals(expectedFieldDef.label, actualFieldDef.label);
                System.assertEquals(expectedFieldDef.fieldType, actualFieldDef.fieldType);
                System.assertEquals(expectedFieldDef.length, actualFieldDef.length);
            }

        }
    }

    /**
     * Compare two list of strings
     *
     * @param expectedList - a list of String to compare with
     * @param actualList   - a list of String to compare
     * @return true if the elements of one list are contained in the other
     */
    static Boolean compareStringLists(List<String> expectedList, List<String> actualList){
        Set<String> expected = new Set<String>();
        expected.addAll(expectedList);
        return expected.size() == actualList.size() && expected.containsAll(actualList);
    }

    /**
     * Test generating metadata delta from an original attachment
     */
    static testMethod void testCreateDeltaFromAttachment() {

        // Set up the initial jobs
        setUpTestHierarchy();

        // Add a new mobile user
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor('LastName', 'user', 'pass', MobileUserDO.STATUS_ACTIVE);

        Test.startTest();

       // Get the hierarchy metadata for the Job Templates available to the mobile user
       Map<String, GenerateMetaData.HierarchyObjectDefinitions> objectMetaData =
           GenerateMetaData.getHierarchyMetadata(JobTemplateDO.getMobileUserJobTemplates(surveyor.theContact, JobTemplateDO.STATUS_PUBLISHED));

        // Get the current full metadata
        GenerateMetaData.FullMetaData originalMetaData = GenerateMetaData.generateFullMetaData(objectMetaData);

        // Save the last sync time stamp
        DateTime lastSync = DateTime.now();

        // Create the attachment
        GenerateMetaData.saveMetaData(surveyor.user.Id, 'deviceId', lastSync, originalMetaData);

        // Change the hierarchy
        changeHierarchy();
        objectMetaData =
           GenerateMetaData.getHierarchyMetadata(JobTemplateDO.getMobileUserJobTemplates(surveyor.theContact, JobTemplateDO.STATUS_PUBLISHED));

        // Save the new sync time stamp
        DateTime newSync = DateTime.now();

        // Update the metadata
        GenerateMetaData.MetaDataDelta metadata = GenerateMetaData.getMetaDataDelta(surveyor.user.Id, 'deviceId', lastSync, newSync, objectMetaData);

        // Get the current full metadata
        GenerateMetaData.FullMetaData newMetaData = GenerateMetaData.generateFullMetaData(objectMetaData);

        // The expected delta string
        setUpDeltaTestObject();

        // Carry out tests
        compareMetaDataDelta(testMetaDataDeltaObject, metadata);

        // Get the attachment back and check that the full metadata saved correctly
        Attachment updatedAttachment = GenerateMetaData.getPreviousMetaDataAttachment(surveyor.user.Id, 'deviceId', newSync);
        Test.stopTest();
        System.assertEquals(updatedAttachment.Body.toString(), JSON.serialize(newMetaData));
    }

    /**
     * Test creating an attachment for a new mobile user
     */
    static testMethod void testCreateMetaDataAttachment() {

        // Add a new mobile user
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor('LastName', 'user', 'pass', MobileUserDO.STATUS_ACTIVE);

        Test.startTest();
        Attachment attachment = GenerateMetaData.getPreviousMetaDataAttachment(surveyor.user.Id, 'deviceId', null);
        Test.stopTest();
        System.assert(attachment.Name.equals('deviceId' + GenerateMetaData.METADATA_ATTACHMENT_NAME));
        System.assert(attachment.Body == null);
    }

    /***
     * Test adding a string to an attachment
     */
    static testMethod void testUpdateAttachment() {
        // Set up the initial job templates
        setUpTestHierarchy();

        // Add a new mobile user
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor('LastName', 'user', 'pass', MobileUserDO.STATUS_ACTIVE);

        Test.startTest();
       // Get the hierarchy metadata for the Job Templates available to the mobile user
       Map<String, GenerateMetaData.HierarchyObjectDefinitions> objectMetaData =
           GenerateMetaData.getHierarchyMetadata(JobTemplateDO.getMobileUserJobTemplates(surveyor.theContact, JobTemplateDO.STATUS_PUBLISHED));

        GenerateMetaData.FullMetaData metaData = GenerateMetaData.generateFullMetaData(objectMetaData);
        DateTime newSync = DateTime.now();
        GenerateMetaData.saveMetaData(surveyor.user.Id, 'deviceId', newSync, metaData);
        Attachment attachment = GenerateMetaData.getPreviousMetaDataAttachment(surveyor.user.Id, 'deviceId', newSync);
        Test.stopTest();
        System.assertEquals(attachment.Body.toString(), JSON.serialize(metaData));
    }

    /**
     * Test clean unneeded attachments
     */
    static testMethod void testCleanAttachments(){
        // Add a new mobile user
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor('LastName', 'user', 'pass', MobileUserDO.STATUS_ACTIVE);

        // Create some time stamps for the attachments
        DateTime lastSync = DateTime.now();
        DateTime oldSync = lastSync.addDays(-1);
        DateTime failedSync = lastSync.addDays(1);

        Test.startTest();
        GenerateMetaData.FullMetaData fakeMetaData = new GenerateMetaData.FullMetaData();

        // Create some attachments
        GenerateMetaData.saveMetaData(surveyor.user.Id, 'deviceId', oldSync, fakeMetaData);
        GenerateMetaData.saveMetaData(surveyor.user.Id, 'deviceId', lastSync, fakeMetaData);
        GenerateMetaData.saveMetaData(surveyor.user.Id, 'deviceId', failedSync, fakeMetaData);

        // Check that the attachments were saved
        System.assertEquals(3, [SELECT Id FROM Attachment WHERE ParentId = :surveyor.user.Id].size());

        // Find the attachment of the last successful synchronization
        Attachment lastSyncAttachment = GenerateMetaData.getPreviousMetaDataAttachment(surveyor.user.Id, 'deviceId', lastSync);
        Test.stopTest();
        lastSyncAttachment = [SELECT Name FROM Attachment WHERE Id = :lastSyncAttachment.Id];

        // Check attachment name and that the other ones were deleted
        System.assertEquals('deviceId' + lastSync.getTime() + GenerateMetaData.METADATA_ATTACHMENT_NAME, lastSyncAttachment.Name);
        System.assertEquals(1, [SELECT Id FROM Attachment WHERE ParentId = :surveyor.user.Id].size());
    }

    /**
     * Test find an attachment with different time zone
     */
    static testMethod void testFindAttachmentTimeZone(){
        // Add a new mobile user
        TestUtils.Surveyor surveyor = TestUtils.createSurveyor('LastName', 'user', 'pass', MobileUserDO.STATUS_ACTIVE);

        // Create a timestamp
        DateTime timestamp = DateTime.now();

        Test.startTest();
        GenerateMetaData.FullMetaData fakeMetaData = new GenerateMetaData.FullMetaData();

        // Create an attachment
        GenerateMetaData.saveMetaData(surveyor.user.Id, 'deviceId', timestamp, fakeMetaData);

        // Add a user in another time zone
        User foreignUser = TestUtils.getStandardUser();
        foreignUser.TimezonesIdKey = 'Pacific/Niue';

        System.runAs(foreignUser) {
            Attachment foundAttachment = GenerateMetaData.getPreviousMetaDataAttachment(surveyor.user.Id, 'deviceId', timestamp);
            System.assertNotEquals(null, foundAttachment.Body);
        }
        Test.stopTest();
    }

    /**
     * Test that the generated job heirarchy field list is accurate. This tests that the JSON is serialized properly
     * and that a field is only counted once even if it appears in many jobs.
     */
    static testMethod void testGetHierarchyMetadata() {

        setUpTestHierarchy();

        Test.startTest();
        Map<String, GenerateMetaData.HierarchyObjectDefinitions> generatedData = GenerateMetaData.getHierarchyMetadata([SELECT Hierarchy__c FROM JobTemplate__c]);
        Test.stopTest();

        // Test that the generated data is correct
        // Four objects found
        System.assertEquals(4, generatedData.size());

        // Loop through the found objects and check the fields that were found
        for (String key : generatedData.keySet()) {
            System.assertEquals(fieldNumberCount.get(key), generatedData.get(key).getFieldNames().size());
        }
    }

    /**
     * Test to ensure that nothing is added to the map if no Jobs are provided
     */
    static testMethod void testNoJobTemplatesSupplied() {
        Test.startTest();
        Map<String, GenerateMetaData.HierarchyObjectDefinitions> generatedData = GenerateMetaData.getHierarchyMetadata(new List<JobTemplate__c>());
        Test.stopTest();
        System.assertEquals(0, generatedData.size());
    }

    /**
    * Test to check correct deserialization of the json with the inner classes
    */
    static testMethod void testDeserializationJson() {

        String metaJson = '[{' +
            '"objectId":"1", "label":"Farmer", "objectName":"Contact", "listFields":[' +
                '"Name"' +
             ']},' +
            '{' +
                '"objectName":"Farm__c", "label":"Farm", "relations":[{' +
                    '"parent":"1", "field":"Farmer__c"' +
                '}],' +
                '"listFields":[' +
                    '"Name"' +
                '],' +
                '"objectId":"2"' +
            '},' +
            '{' +
                '"relations":[{'+
                    '"parent":"2", "field":"Farm__c"'+
                '}],'+
                '"objectId":"3", "label":"Hive", "objectName":"Hive__c", "listFields":['+
                    '"LastInspectionDate__c"' +
                '],' +
                '"detailFields":[' +
                    '"LastInspectionDate__c",' +
                    '"LastInspectionNotes__c"' +
                ']' +
            '}' +
        ']';
        List<JobTemplateDo.ObjectHierarchy> jobHierarchy = (List<JobTemplateDo.ObjectHierarchy>)JSON.deserialize(metaJson, List<JobTemplateDo.ObjectHierarchy>.class);
        system.assertEquals(3 ,jobHierarchy.size());

        // Assert correct parsing from json to inner classes
        // First element of the json, with all the elements
        system.assertEquals('1', jobHierarchy[0].objectId);
        system.assertEquals('Farmer', jobHierarchy[0].label);
        system.assertEquals('Contact', jobHierarchy[0].objectName);
        system.assertEquals(null, jobHierarchy[0].relations);
        system.assertEquals(1, jobHierarchy[0].listFields.size());
        system.assertEquals(null, jobHierarchy[0].detailFields);
        system.assertEquals('Name', jobHierarchy[0].listFields[0]);

        // Second element of the json, with all the elements
        system.assertEquals('2', jobHierarchy[1].objectId);
        system.assertEquals('Farm', jobHierarchy[1].label);
        system.assertEquals('Farm__c', jobHierarchy[1].objectName);
        system.assertEquals(1, jobHierarchy[1].relations.size());
        system.assertEquals(1, jobHierarchy[1].listFields.size());
        system.assertEquals(null, jobHierarchy[1].detailFields);

        system.assertEquals('1', jobHierarchy[1].relations[0].parent);
        system.assertEquals('Farmer__c', jobHierarchy[1].relations[0].field);
        system.assertEquals('Name', jobHierarchy[1].listFields[0]);

        // Third element of the json, with all the elements
        system.assertEquals('3', jobHierarchy[2].objectId);
        system.assertEquals('Hive', jobHierarchy[2].label);
        system.assertEquals('Hive__c', jobHierarchy[2].objectName);
        system.assertEquals(1, jobHierarchy[2].relations.size());
        system.assertEquals(1, jobHierarchy[2].listFields.size());
        system.assertEquals(2, jobHierarchy[2].detailFields.size());

        system.assertEquals('2', jobHierarchy[2].relations[0].parent);
        system.assertEquals('Farm__c', jobHierarchy[2].relations[0].field);
        system.assertEquals('LastInspectionDate__c', jobHierarchy[2].detailFields[0]);
        system.assertEquals('LastInspectionNotes__c', jobHierarchy[2].detailFields[1]);
    }

    /**
     * Test creating a query string for a HierarchyObjectDefinitions
     */
    static testMethod void testCreatingHierarchyObjectDefinitionsQueryString() {

        String objectName = 'objectName';
        String fieldName1 = 'fieldName1';
        String fieldName2 = 'fieldName2';
        String fieldName3 = 'fieldName3';
        String fieldName4 = 'fieldName4';
        String topLevel1Path1 = 'topLevel1Path1';
        String topLevel1Path2 = 'topLevel1Path2';
        String topLevel2Path1 = 'topLevel2Path1';
        String topLevelObjectName1 = 'topLevelObjectName1';
        String topLevelObjectName2 = 'topLevelObjectName2';
        Set<String> topLevelIds1 = new Set<String>{ '1', '2', '3'};
        List<String> topLevelIds1List = new List<String>();
        topLevelIds1List.addAll(topLevelIds1);
        Set<String> topLevelIds2 = new Set<String>{ '4', '5', '6'};
        List<String> topLevelIds2List = new List<String>();
        topLevelIds2List.addAll(topLevelIds2);
        GenerateMetaData.HierarchyObjectDefinitions definition =
            new GenerateMetaData.HierarchyObjectDefinitions(objectName);
        definition.addFieldNames(new List<String>{
            fieldName1,
            fieldName2,
            fieldName3,
            fieldName4
        });
        definition.addPath(topLevelObjectName1, topLevel1Path1);
        definition.addPath(topLevelObjectName1, topLevel1Path2);
        definition.addPath(topLevelObjectName2, topLevel2Path1);
        Map<String, Set<String>> idMap = new Map<String, Set<String>>{
            topLevelObjectName1 => topLevelIds1,
            topLevelObjectName2 => topLevelIds2
        };
        String generatedQuery = definition.buildQuery(idMap);
        String testQuery =
            'SELECT ' +
                fieldName1 + ',' +
                fieldName2 + ',' +
                fieldName3 + ',' +
                fieldName4 + ',' +
                'LastModifiedDate ' +
            'FROM '+
                 objectName + ' ' +
            'WHERE ' +
                topLevel2Path1 + ' IN (\'' + String.join(topLevelIds2List, '\',\'') + '\') OR ' +
                topLevel1Path2 + ' IN (\'' + String.join(topLevelIds1List, '\',\'') + '\') OR ' +
                topLevel1Path1 + ' IN (\'' + String.join(topLevelIds1List, '\',\'') + '\')'
        ;
        System.assertEquals(testQuery, generatedQuery);
    }

    /**
     * Test that a query is not generated if the top level for a path doesn't have any
     * values assigned to the contact
     */
    static testMethod void testQueryEmptyIfNoTopLevelIds() {

        String objectName = 'objectName';
        String fieldName1 = 'fieldName1';
        String fieldName2 = 'fieldName2';
        String topLevelPath = 'topLevelPath';
        GenerateMetaData.HierarchyObjectDefinitions definition =
            new GenerateMetaData.HierarchyObjectDefinitions(objectName);
        definition.addFieldNames(new List<String>{
            fieldName1,
            fieldName2
        });
        String generatedQuery =
            definition.buildQuery(new Map<String, Set<String>>());
        System.assert(
            String.isEmpty(generatedQuery),
            'Query string should be empty as there are not top level ids to be in WHERE clause'
        );
    }

    /**
     * Test path conversion for String ending in Id
     */
    static testMethod void testFieldNameConversionStandardReference() {

        GenerateMetaData.PathToTopLevel path =
            new GenerateMetaData.PathToTopLevel('Path1');
        path.updatePath('ContactId');
        System.assertEquals('Contact.Path1', path.path);
    }

    /**
     * Test path conversion for String ending in __c
     */
    static testMethod void testFieldNameConversionCustomReference() {

        GenerateMetaData.PathToTopLevel path =
            new GenerateMetaData.PathToTopLevel('Path1');
        path.updatePath('Contact__c');
        System.assertEquals('Contact__r.Path1', path.path);
    }
}
