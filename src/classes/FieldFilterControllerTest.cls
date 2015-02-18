/*
 * Test for TrackedObjectController
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Ernesto Quesada
 */
@isTest
public class FieldFilterControllerTest {

    /**
     * Check correct generation of the wrappers 
     */
    static testMethod void getRelatedObjectsWrapper() {
        
        String contactName = Contact.sObjectType.getDescribe().getLocalName().toLowerCase();
        String fieldJson = 
            FieldFilterController.getStringFieldsSerialized(contactName);
                
        Test.startTest();
         List <FieldFilterController.FieldData> objectWrappers = 
            (List<FieldFilterController.FieldData>) 
            Json.deserialize(fieldJson, List<FieldFilterController.FieldData>.class);
        Test.stopTest();
        
        for (FieldFilterController.FieldData fieldDataElement : objectWrappers) {
            System.assertNotEquals(
                null,
                DescribeHandler.getFieldDescribe(contactName, fieldDataElement.name),
                'The field does not exist'
            );
            System.assertEquals(
                fieldDataElement.label,
                DescribeHandler.getFieldDescribe(contactName, fieldDataElement.name).getLabel(),
                'The label is not correct'
            );
        }
    }
}
