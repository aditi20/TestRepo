/**
* Test for the Cascading Select Trigger
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
* @author  Ernesto Quesada
*/
@isTest
private class CascadingSelectTriggerTest{

    /*
    * Delete unused cascading selects that are in ready status
    */
    static testMethod void testCorrectDeleteCascading(){
    
        // Create and insert an uploaded cascading (no need to create levels or values)
        CascadingSelect__c cascadingSelect = new CascadingSelect__c(Name = 'cascadingS1', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cascadingSelect;
        try {
            delete cascadingSelect;
            system.assert(true);
        } catch (Exception e){
            system.assert(false);
        }
    
    }


    /*
    * Avoid to delete a processing cascading test
    */
    static testMethod void testAvoidDeleteProcessingCascading(){
    
        // Create and insert a uploaded cascading (no need to create levels or values)
        CascadingSelect__c cascadingSelect = new CascadingSelect__c(Name = 'cascadingS1', Status__c = C.CASCADING_STATUS_PROCESSING);
        insert cascadingSelect;
        try {
            delete cascadingSelect;
            system.assert(false);
        } catch (Exception e) {
            system.assert(true);
        }
    }
    
    
    /*
    * Avoid to publish a Job with associated Form Status Draft
    */
    static testMethod void testAvoidDeleteUsedCascading(){
        
        // Create and insert a uploaded cascading (no need to create levels or values)
        CascadingSelect__c cascadingSelect = new CascadingSelect__c(Name = 'cascadingS1', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cascadingSelect;
        
        // Create a survey 
        Survey__c survey = new Survey__c(Name = 'surveyCascading',
                                                            Status__c  = SurveyDO.STATUS_DRAFT,
                                                            Version__c = 1);
        insert survey;
        Question__c section1 = new Question__c(Name = 'section1',
                                         Caption__c = 'section1',
                                         Survey__c = survey.Id,
                                         Type__c = QuestionDO.TYPE_SECTION,
                                         Position__c = 1);
        insert section1;
                                         
        Question__c q1 = new Question__c(Name = 'cascadingQuestion',
                                         Caption__c = 'cascadingQuestion',
                                         Parent__c = section1.Id,
                                         Survey__c = survey.Id,
                                         Type__c = QuestionDO.TYPE_CASCADING_SELECT,
                                         Position__c = 1,
                                         CascadingSelect__c = cascadingSelect.Id);
        insert q1;
        try {
            delete cascadingSelect;
            system.assert(false);
        } catch (Exception e){
            system.assert(true);
        }
    }
}
