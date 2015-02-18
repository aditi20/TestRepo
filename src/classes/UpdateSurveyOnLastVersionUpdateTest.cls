/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
private class UpdateSurveyOnLastVersionUpdateTest {

    static testMethod void testSurveyUpdateOnLastVersionUpdate() {

        // Create a new Survey
        Survey__c survey = new Survey__c(Name='survey');
        insert survey;
        //refresh survey
        survey = [SELECT Name,Status__c,Version__c FROM Survey__c WHERE Id = :survey.Id];
        SurveyVersion__c version = [SELECT Version__c,Status__c,Name FROM SurveyVersion__c WHERE Survey__r.Id = :survey.Id];
        
        Test.startTest();
            version.Status__c = SurveyDO.STATUS_PUBLISHED;
            update version;

            //the survey would have to be updated
            //refresh survey
            survey = [SELECT Name,Status__c,Version__c FROM Survey__c WHERE Id = :survey.Id];
            system.assertEquals(SurveyDO.STATUS_PUBLISHED, survey.Status__c);
            //get the last version and try to update it FROM any status to draft,it should fail
            version = [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c= :survey.Id order by Version__c desc];
            try{
                version.Status__c = SurveyDO.STATUS_DRAFT;
                update version;
                system.assert(false);
            }
            catch (Exception e){
                system.assert(true);
            }
        Test.stopTest();
    }

    static testMethod void testSurveyStatusUpdates() {
        Survey__c survey = new Survey__c(Name='survey'); insert survey;

        // Test change status FROM Draft to Published
        SurveyVersion__c version = [SELECT Version__c,Status__c,Name FROM SurveyVersion__c WHERE Survey__r.Id = :survey.Id];
        Test.startTest();
            version.Status__c = SurveyDO.STATUS_PUBLISHED; update version;
            system.assertEquals(SurveyDO.STATUS_PUBLISHED, [SELECT Status__c FROM Survey__c WHERE Id = :survey.Id].Status__c);

            // Test change status FROM Published to Closed
            version = [SELECT Version__c,Status__c,Name FROM SurveyVersion__c WHERE Survey__r.Id = :survey.Id];
            version.Status__c = SurveyDO.STATUS_CLOSED; update version;
            system.assertEquals(SurveyDO.STATUS_CLOSED, [SELECT Status__c FROM Survey__c WHERE Id = :survey.Id].Status__c);

            // Test change status FROM Draft to Closed
            Survey__c closeableSurvey = new Survey__c(Name='closeable survey'); insert closeableSurvey;

            version = [SELECT Version__c,Status__c,Name FROM SurveyVersion__c WHERE Survey__r.Id = :closeableSurvey.Id];
            version.Status__c = SurveyDO.STATUS_CLOSED; update version;
            system.assertEquals(SurveyDO.STATUS_CLOSED, [SELECT Status__c FROM Survey__c WHERE Id = :closeableSurvey.Id].Status__c);

            // Test change status FROM Draft to Closed with open job
            Survey__c nonCloseableSurvey = new Survey__c (Name = 'non-closeable survey'); insert nonCloseableSurvey;
            SurveyVersion__C versionNonCloseable = [SELECT Version__c,Status__c,Name FROM SurveyVersion__c WHERE Survey__r.Id = :nonCloseableSurvey.Id];
            JobTemplate__c job           = new JobTemplate__c (Name = 'open job',
                                                               Status__c = JobTemplateDO.STATUS_DRAFT); insert job;
            TaskTemplate__c firstTask    = new TaskTemplate__c (Form__c = versionNonCloseable.Id,
                                                                JobTemplate__c = job.Id,
                                                                Position__c = 1,
                                                                Type__c = 'form');insert firstTask;
            version = [SELECT Version__c, Status__c, Name FROM SurveyVersion__c WHERE Survey__r.Id = :nonCloseableSurvey.Id];
            version.Status__c = SurveyDO.STATUS_CLOSED;
            try{
                update version;
                system.assert(false, 'This should fail since is not possible to change the status ' +
                                     'of a survey to closed with a non closed job related');
            }catch(DMLException e){
                system.assert(e.getMessage().contains(system.Label.SURVEYVERSION_ERR_CLOSEWITHOPENJOBS));
            }

            System.assertEquals(SurveyDO.STATUS_DRAFT, [SELECT Status__c FROM SurveyVersion__c WHERE Survey__r.Id = :nonCloseableSurvey.Id].Status__c);

            // Test change status FROM Draft to Closed with closed job
            Survey__c withClosedJobSurvey = new Survey__c (Name = 'With Closed Job Survey'); insert withClosedJobSurvey;
            SurveyVersion__c versionWithClosedJobSurvey= [SELECT id FROM SurveyVersion__c Where Survey__c = :withClosedJobSurvey.Id][0];
            JobTemplate__c closedJob      = new JobTemplate__c (Name = 'closed job',
                                                                Status__c = JobTemplateDO.STATUS_DRAFT); insert closedJob;
            TaskTemplate__c secondTask    = new TaskTemplate__c (Form__c = versionWithClosedJobSurvey.Id,
                                                                 JobTemplate__c = closedJob.Id,
                                                                 Position__c = 1,
                                                                 Type__c = 'form');insert secondTask;
            closedJob.Status__c = JobTemplateDO.STATUS_CLOSED;
            update closedJob;
            version = [SELECT Version__c, Status__c, Name FROM SurveyVersion__c WHERE Survey__r.Id = :withClosedJobSurvey.Id];
            version.Status__c = SurveyDO.STATUS_CLOSED;
            update version;
        Test.stopTest();
        system.assertEquals(SurveyDO.STATUS_CLOSED, [SELECT Status__c FROM Survey__c WHERE Id = :withClosedJobSurvey.Id].Status__c);

    }
}
