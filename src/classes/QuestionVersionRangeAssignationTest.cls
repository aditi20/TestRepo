/*
*   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*/
@isTest
private class QuestionVersionRangeAssignationTest {

    static testMethod void QuestionVersionAssignmentTest() {
        // Insert a survey with a version and check version assignment
        Survey__c survey = new Survey__c(Name = 'Test Question Version');
        insert survey;

        Question__c qSection = new Question__c(Survey__c=survey.Id,Caption__c= 'SECTION',Type__c = QuestionDO.TYPE_SECTION, Position__c = 1);
        insert qSection;

        Question__c q1 = new Question__c(Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Username',Type__c = QuestionDO.TYPE_TEXT_SHORT, Position__c = 1);
        insert q1;
        q1 = [select FromVersion__c,ToVersion__c from Question__c where Id = :q1.Id];

        // Insertion of a question for version1
        system.assertEquals(1, q1.FromVersion__c);
        system.assertEquals(null, q1.ToVersion__c);

        // Publish the version,and leave it in draft to create a new Version
        SurveyVersion__c version = [select Version__c,Status__c from SurveyVersion__c where Survey__c= :survey.Id];
        version.Status__c = SurveyDO.STATUS_PUBLISHED;
        
        Test.startTest();
            update version;

            SurveyTriggerLogic.setOverrideDeleteChecks(true);
            survey.Status__c = SurveyDO.STATUS_DRAFT;
            update survey;
            SurveyTriggerLogic.setOverrideDeleteChecks(false);

            // Insertion of a question for Version 2
            Question__c q2 = new Question__c(Parent__c= qSection.Id,survey__c=survey.Id, Caption__c= 'Username',Type__c = QuestionDO.TYPE_TEXT_SHORT, Position__c = 2);
            insert q2;

            // Assert if the From and To were correctly assigned
            q2 = [select ToVersion__c,FromVersion__c from Question__c where Id = :q2.Id];
            system.assertEquals(2, q2.FromVersion__c);
            system.assertEquals(null, q2.ToVersion__c);

            // Insertion of a modified question in a new Version 3
            // Create new Version
            version = [select Version__c,Status__c from SurveyVersion__c where Survey__c= :survey.Id order by Version__c desc][0];
            version.Status__c = SurveyDO.STATUS_PUBLISHED;
            update version;
            SurveyTriggerLogic.setOverrideDeleteChecks(true);
            survey.Status__c = SurveyDO.STATUS_DRAFT;
            update survey;
            SurveyTriggerLogic.setOverrideDeleteChecks(false);
            Question__c q1new = new Question__c(PreviousVersionQuestion__c=q1.Id,Parent__c= qSection.Id,survey__c=survey.Id,Caption__c= 'Username',Type__c = QuestionDO.TYPE_TEXT_SHORT, Position__c = 3);
            insert q1new;
        Test.stopTest();
        q1 = [select FromVersion__c,ToVersion__c from Question__c where Id = :q1.Id];
        q1new = [select FromVersion__c,ToVersion__c from Question__c where Id = :q1new.Id];

        // Assert if the From and To were correctly assigned
        system.assertEquals(3, q1new.FromVersion__c);
        system.assertEquals(null, q1new.ToVersion__c);
        system.assertEquals(1, q1.FromVersion__c);
        system.assertEquals(2, q1.ToVersion__c);
    }


    static testMethod void VerifySurveyStatusInsertQuestion() {
        // create a new ScoringGroup__c
        Survey__c survey = new Survey__c(Name='survey');
        insert survey;

        //insert a Question
        Question__c qSection = new Question__c(Survey__c=survey.Id,Caption__c= 'SECTION',Type__c = QuestionDO.TYPE_SECTION, Position__c = 1);
        insert qSection;
        Question__c question = new Question__c(Parent__c = qSection.Id, Caption__c ='TestQuestion',Survey__c=survey.Id, Position__c = 1);
        insert question;

        //ASSERTIONS
        List<SurveyVersion__c> versions = [select Version__c,Status__c,Name from SurveyVersion__c where Survey__r.Id = :survey.Id];
        survey = [select Status__c from Survey__c where Id=:survey.Id];
        system.assertEquals(1,versions.size());
        system.assertEquals(SurveyDO.STATUS_DRAFT,survey.Status__c);
        versions = [select Version__c,Status__c,Name from SurveyVersion__c where Survey__r.Id = :survey.Id];
        versions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        Test.startTest();
            update versions;

            // try to insert a new question,it should fail since Survey is Published
            try{
                insert new Question__c(Caption__c ='TestQuestion2',Survey__c=survey.Id, Position__c = 2);
                system.assert(false);
            }catch(Exception e){
                system.assert(true);
            }

            // try to update a new question,it should fail since Survey is Published
            try{
                update question;
                system.assert(false);
            }catch(Exception e){
                system.assert(true);
            }
        Test.stopTest();
    }

    static testMethod void testUpdateQuestionVersionChain(){
        Survey__c survey = new Survey__c(Name = 'survey', Status__c = SurveyDO.STATUS_DRAFT);
        insert survey;
        Question__c qSection = new Question__c(Survey__c = survey.Id, Caption__c = 'SECTION', Name = 'section', Type__c = QuestionDO.TYPE_SECTION, Position__c = 1);
        insert qSection;
        Question__c question = new Question__c(Survey__c = survey.Id, Parent__c = qSection.Id, Name='a', Caption__c='a', Position__c=1, Type__c = QuestionDO.TYPE_TEXT_SHORT);
        insert question;
        question = [SELECT Id, FromVersion__c, ToVersion__c FROM Question__c WHERE Id = :question.Id];
        system.assertEquals(1, question.FromVersion__c);
        system.assertEquals(null, question.ToVersion__c);

        // Publish the survey. Assert it's status is updated.
        SurveyVersion__c version = [SELECT Id, Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id];
        system.assertEquals(SurveyDO.STATUS_DRAFT, version.Status__c);
        version.Status__c = SurveyDO.STATUS_PUBLISHED;
        
        Test.startTest();
            update version;
            survey = [SELECT Id, Status__c, Version__c FROM Survey__c WHERE Id = :survey.Id];
            system.assertEquals(SurveyDO.STATUS_PUBLISHED, survey.Status__c);

            // Move the survey to Draft again. Assert a new version is created, and survey version is updated.
            SurveyTriggerLogic.setOverrideDeleteChecks(true);
            survey.Status__c = SurveyDO.STATUS_DRAFT;
            update survey;
            SurveyTriggerLogic.setOverrideDeleteChecks(false);

            survey = [SELECT Id, Status__c, Version__c FROM Survey__c WHERE Id = :survey.Id];
            system.assertEquals(2, survey.Version__c);
            system.assertEquals(2, [SELECT Id FROM SurveyVersion__c WHERE Survey__c = :survey.Id].size());

            // Insert a new version of the question, assert the version range is updated
            Question__c question2 = new Question__c(Survey__c = survey.Id, Parent__c = qSection.Id, Name='b', Caption__c='b', Position__c=1, Type__c=QuestionDO.TYPE_TEXT_SHORT, PreviousVersionQuestion__c = question.Id);
            insert question2;

            question = [SELECT Id, FromVersion__c, ToVersion__c FROM Question__c WHERE Id = :question.Id];
            system.assertEquals(1, question.FromVersion__c);
            system.assertEquals(1, question.ToVersion__c);

            question2 = [SELECT Id, FromVersion__c, ToVersion__c FROM Question__c WHERE Id = :question2.Id];
            system.assertEquals(2, question2.FromVersion__c);
            system.assertEquals(null, question2.ToVersion__c);
        Test.stopTest();
    }
}
