/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved.
 *
 * Test class for DeleteResource.trigger.
 */
@isTest
private class DeleteResourceTest {

    /**
     *  Method in charge of test that user cannot deleted a resource used in a task.
     */
    static testMethod void deleteResourceTriggerTest() {

        // Create a job template
        JobTemplate__c jobTemplate = JobTemplateDO.createJobTemplate('JobName', 'Draft', '[]');
        insert jobTemplate;

        // Create a version, so the ContentDocument will be automatically created.
        ContentVersion version = new ContentVersion(
            Title = 'title1',
            VersionData = Blob.valueof('aaa324'),
            PathOnClient = 'fileName.mp4'
        );
        insert version;

        // Obtain the created ContentDocument.
        ContentDocument cd = [SELECT Id From ContentDocument][0];

        // Create the task, and link it to the created ContentDocument.
        TaskTemplate__c taskResource =
            TaskTemplateDO.createResourceTaskTemplate(
                'TaskName',
                1,
                jobTemplate.Id,
                'instructions',
                'j8ji',
                cd.Id
            );
        insert taskResource;

        try {
            delete cd;
            System.assert(false);
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains(System.Label.RESOURCE_CANT_BE_REMOVED_REFERENCED_BY_TASK),
                'Was triggered, but there was no error on the Document'
            );
        }
    }
}