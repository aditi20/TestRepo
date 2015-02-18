/*
 * Test for TrackedObjectController
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Ernesto Quesada
 */
@isTest
public class TrackedObjectControllerTest {

    /**
     * Get all the related objects of a certain objects
     */
    static testMethod void getRelatedObjectsWrapper() {

        String objectsJson = TrackedObjectController.loadSerializedChildObjects(
                Contact.sObjectType.getDescribe().getLocalName().toLowerCase());

        Test.startTest();
         Map <String, TrackedObjectController.objectData> objectWrappers=
                                        (Map <String, TrackedObjectController.objectData>)
                                                Json.deserialize(objectsJson, Map <String,
                                                        TrackedObjectController.objectData>.class);
        Test.stopTest();


        SFDCEncoder encoder = new SFDCEncoder();
        for (
                Schema.ChildRelationship child :
                DescribeHandler.getChildRelationships(Contact.sObjectType.getDescribe().getLocalName().toLowerCase())
        ) {
            DescribeSObjectResult objDesc = child.getChildSObject().getDescribe();
            DescribeFieldResult fieldDescribe = child.getField().getDescribe();
            TrackedObjectController.objectData currentWrapper = objectWrappers.get(objDesc.getName());
            System.assert(currentWrapper != null,'this object should exist');
            System.assertEquals(objDesc.getLabel(),currentWrapper.label,'The label is not correct');
            System.assert(currentWrapper.fields.get(fieldDescribe.getName()) != null,'The field should exist');
            System.assertEquals(
                encoder.SFDC_JSENCODE(fieldDescribe.getLabel()),
                currentWrapper.fields.get(fieldDescribe.getName()).label,
                'The field should exist'
            );
        }
    }

    /**
     * Get all the related objects of a certain objects with permissions check
     */
    static testMethod void getRelatedObjectsWrapperWithPermissionCheck() {

        User chatterExternalUser = TestUtils.createChatterExternalUser();
        if (chatterExternalUser == null) {
            return;
        }

        List<String> expectedObjects = new List<String>();
        Map <String, TrackedObjectController.objectData> objectWrappers;
        System.runAs(chatterExternalUser) {
            Test.startTest();
            String objectsJson = TrackedObjectController.loadSerializedChildObjects(
                Account.sObjectType.getDescribe().getLocalName().toLowerCase());
            objectWrappers =
                (Map <String, TrackedObjectController.objectData>)
                    Json.deserialize(objectsJson, Map <String,
                        TrackedObjectController.objectData>.class);
            Test.stopTest();

            for (
                Schema.ChildRelationship child :
                DescribeHandler.getChildRelationships(
                    Account.sObjectType.getDescribe().getLocalName().toLowerCase()
                )
            ) {
                DescribeSObjectResult objDesc = child.getChildSObject().getDescribe();
                GenericObjectCreator creator =
                    new GenericObjectCreator(objDesc.getName());

                if (creator.isObjectAccessible(false)) {
                    expectedObjects.add(objDesc.getName());
                }
            }
        }

        System.assertEquals(
            expectedObjects.size(),
            objectWrappers.size()
        );

    }

    /**
     * load the object data from a path
     */
    static testMethod void loadTrackedObjectData() {

        // Get the describes of the objects and fields
        Schema.DescribeSObjectResult submissionDescribe = Submission__c.sObjectType.getDescribe();
        Schema.DescribeSObjectResult answerDescribe     = Answer__c.sObjectType.getDescribe();

        Schema.DescribeFieldResult surveyorField   =
                //submissionDescribe.Fields.getMap().get('Surveyor__c').getDescribe();
                Submission__c.SObjectType.Fields.Surveyor__c.getDescribe();
        Schema.DescribeFieldResult submissionField =
                Answer__c.SObjectType.Fields.Submission__c.getDescribe();
        Schema.DescribeFieldResult parentField     =
                Answer__c.SObjectType.Fields.Parent__c.getDescribe();
        String path = parentField.getName() + '.' + submissionField.getName() +'.' + surveyorField.getName();

        TrackedObjectController.PathData pathObject = new TrackedObjectController.PathData(answerDescribe.getName(), path);

        // Run the test
        Test.startTest();
        List<TrackedObjectController.ObjectSelectData> objectsData =
            (List<TrackedObjectController.ObjectSelectData>)Json.deserialize(
                TrackedObjectController.getSerializedObjectsFromPath(Json.serialize(pathObject)),
                List<TrackedObjectController.ObjectSelectData>.class
            );
        Test.stopTest();

        // Assert the wrapper is correct
        System.assertEquals(answerDescribe.getLabel(), objectsData.get(0).objectLabel);
        System.assertEquals(parentField.getLabel(), objectsData.get(0).fieldLabel);

        System.assertEquals(answerDescribe.getLabel(), objectsData.get(1).objectLabel);
        System.assertEquals(submissionField.getLabel(), objectsData.get(1).fieldLabel);

        System.assertEquals(submissionDescribe.getLabel(), objectsData.get(2).objectLabel);
        System.assertEquals(surveyorField.getLabel(), objectsData.get(2).fieldLabel);
    }
}
