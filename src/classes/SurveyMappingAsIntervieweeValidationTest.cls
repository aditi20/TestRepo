/**
 *    Test class for SurveyMappingAsIntervieweeValidation
 *    @author Ernesto Quesada
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 */
@isTest
private class SurveyMappingAsIntervieweeValidationTest {

    /*static testMethod void ValidateUseAsIntervieweeTest() {
        // insert a survey with a question
        Survey__c survey      = new Survey__c(Name = 'survey');
        insert survey;
        Question__c sec1      = new Question__c(Survey__c = survey.Id, Type__c = QuestionDO.TYPE_SECTION , Name = 'section', Caption__c = 'caption', Position__c = 1);
        insert sec1;
        Question__c q1        = new Question__c(Survey__c = survey.Id, Parent__c = sec1.Id, Type__c = QuestionDO.TYPE_TEXT_SHORT , Name = 'q1', Caption__c = 'caption', Position__c = 1);
        insert q1;
        SurveyMapping__c sM   = new SurveyMapping__c(ObjectApiName__c = 'Contact', Survey__c = survey.Id, UseAsInterviewee__c = true);
        insert sM;
        QuestionMapping__c qM = new QuestionMapping__c(Question__c = q1.Id, SurveyMapping__c = sM.Id, FieldApiName__c = 'LastName');
        insert qM;
        SurveyMapping__c sM2  = new SurveyMapping__c(ObjectApiName__c = 'Contact', Survey__c = survey.Id, UseAsInterviewee__c = true);

        //the insert should fail since there is already a UseAsInterviewee SurveyMapping for this survey
        Test.startTest();
            try{
                insert sM2;
                system.assert(false, 'The insert should fail since there is already a UseAsInterviewee SurveyMapping for this survey');
            }
            catch (Exception e) {
                system.assert(e.getMessage().contains(system.Label.BUILDER_ERR_INTERVIEWEE_MAPPING), e.getMessage());
            }

            sM2.UseAsInterviewee__c = false;
            insert sM2;

            sM2.UseAsInterviewee__c = true;
            //the update should fail because there is already a UseAsInterviewee SurveyMapping for this survey
            try{
                update sM2;
                system.assert(false, 'The update should fail since there is already a UseAsInterviewee SurveyMapping for this survey');
            }
            catch (Exception e) {
                system.assert(e.getMessage().contains(system.Label.BUILDER_ERR_INTERVIEWEE_MAPPING), e.getMessage());
            }

            sM2.UseAsInterviewee__c = true;
            sM.UseAsInterviewee__c = false;
            update new SurveyMapping__c[]{sM,sM2};
        Test.stopTest();

        system.assertEquals(false,sM.UseAsInterviewee__c);
        system.assertEquals(true,sM2.UseAsInterviewee__c);
    }*/
    /**
    * Test to validate the mapping of surveys to a mobile survey object
    *//*
    static testMethod void ValidateNotMappedToObjects(){
        Survey__c survey = new Survey__c(Name = 'survey');
        insert survey;
        Question__c sec1 = new Question__c(Survey__c = survey.Id, Type__c = QuestionDO.TYPE_SECTION , Name = 'section', Caption__c = 'caption', Position__c = 1);
        insert sec1;
        Question__c q1 =new Question__c(Survey__c = survey.Id, Parent__c=sec1.Id, Type__c = QuestionDO.TYPE_TEXT_SHORT, Name = 'q1', Caption__c = 'caption', Position__c = 1);
        insert q1;
        SurveyMapping__c sM = new SurveyMapping__c(ObjectApiName__c = Survey__c.getSObjectType().getDescribe().getName(), Survey__c = survey.Id);
        
        Test.startTest();
            // Insert invalid survey mapping
            try{
                insert sM;
                system.assert(false, 'The insert should fail since is trying to map a mobile-survey object');
            }catch (Exception e){
                system.assert(e.getMessage().contains(system.Label.BUILDER_ERR_MOBILESURVEY_MAPPING));
            }

            // Insert valid survey mapping
            sM.ObjectApiName__c='Contact';
            insert sM;
            // Set the invalid object api name
            sM.ObjectApiName__c = Survey__c.getSObjectType().getDescribe().getName();

            // Update invalid survey mapping
            try{
                update sM;
                system.assert(false, 'The update should fail since is trying to map a mobile-survey object');
            }catch (Exception e){
                system.assert(e.getMessage().contains(system.Label.BUILDER_ERR_MOBILESURVEY_MAPPING));
            }
        Test.stopTest();
    }
    */
}