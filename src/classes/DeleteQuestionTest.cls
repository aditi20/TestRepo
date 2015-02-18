/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public class DeleteQuestionTest {
    static testMethod void testDeleteQuestionsWithMapping() {
        Survey__c survey1 = newSurvey('FirstSurvey');
        Question__c sec1 = newQuestion(survey1, null,QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
        Question__c questionWithRequiredMapping = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'questionWithRequiredMapping','Last name',1);
        Question__c questionWithoutMapping = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'questionWithoutMapping','questionWithoutMapping',2);
        Question__c questionWithNotRequiredMapping = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'questionWithNotRequiredMapping','Description',3);
        Question__c questionWithDefaultValueMapping = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'questionWithDefaultValueMapping','Id',4);
        SurveyMapping__c sM = new SurveyMapping__c(ObjectApiName__c = 'Contact',Survey__c = survey1.Id);
        insert sM;
        QuestionMapping__c qM = new QuestionMapping__c(Question__c = questionWithRequiredMapping.Id,SurveyMapping__c = sM.Id,FieldApiName__c = 'LastName');
        insert qM;
        QuestionMapping__c qM2 = new QuestionMapping__c(Question__c = questionWithNotRequiredMapping.Id,SurveyMapping__c = sM.Id,FieldApiName__c = 'Description');
        insert qM2;
        //try to delete the question, it shouldn't be possible.
        try{
            delete questionWithRequiredMapping;
            System.Assert(false,'The question mapped to a required field has been deleted.');
        }catch(Exception ex){
            System.Assert(true);
        }
        //If I delete the mapping first, I should be able to delete the question.
        delete sM;
        System.Assert(Database.delete(questionWithRequiredMapping).isSuccess());
        //Delete a question without mapping
        System.Assert(Database.delete(questionWithoutMapping).isSuccess());
        //Delete a question with not required mapping
        System.Assert(Database.delete(questionWithNotRequiredMapping).isSuccess());
        //Delete a question with required default mapping
        System.Assert(Database.delete(questionWithDefaultValueMapping).isSuccess());
    }

    //Test if all the others records related to the deleted question are also deleted.
    static testMethod void relatedRecordsTest() {
        Survey__c survey1 = newSurvey('FirstSurvey');
        Question__c sec1 = newQuestion(survey1, null,QuestionDO.TYPE_SECTION, 'section1', 'section1', 1);
        Question__c question1           = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'question1','question1',1);
        Question__c questionToBeRelated = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'lname'    ,'Last name',2);
        Question__c question3           = newQuestion(survey1,sec1,QuestionDO.TYPE_TEXT_SHORT,'question3','question3',3);

        SkipCondition__c cond1 = new SkipCondition__c(
            Condition__c = SkipConditionDO.CONDITION_EQUAL,
            Parent__c = questionToBeRelated.Id,
            SourceQuestion__c = question3.Id,
            SkipValue__c = 'Value'
        );
        insert cond1;
        SkipCondition__c cond2 = new SkipCondition__c(
            Condition__c = SkipConditionDO.CONDITION_EQUAL,
            Parent__c = question1.id,
            SourceQuestion__c = questionToBeRelated.id,
            SkipValue__c = 'Value'
        );
        insert cond2;
        ScoringGroup__c sg = new ScoringGroup__c (Caption__c = 'caption', Survey__c = survey1.id);
        insert sg;
        Option__c option1 = new Option__c(Name = 'NameOption', Position__c = 1, Question__c = questionToBeRelated.Id);
        insert option1;
        ScoreValue__c sv = new ScoreValue__c(Value__c = 40, ScoringGroup__c = sg.id, Option__c = option1.id);
        insert sv;
        delete questionToBeRelated;
        //All records related to the question should have been eliminated.
        System.AssertEquals(0,[SELECT Id FROM Option__c WHERE Question__c=: questionToBeRelated.Id].size());
        System.AssertEquals(0,[SELECT Id FROM ScoreValue__c WHERE Option__c=: option1.Id].size());
        System.AssertEquals(0,[SELECT Id FROM SkipCondition__c WHERE Parent__c=: questionToBeRelated.Id or SourceQuestion__c=: questionToBeRelated.Id].size());
        System.AssertEquals(0,[SELECT Id FROM SkipCondition__c WHERE Id=:cond1.Id].size());
        System.AssertEquals(0,[SELECT Id FROM SkipCondition__c WHERE Id=:cond2.Id].size());
    }

    /**
     *  Tests that if a question is mapped to a required field, then the question cannot be set as not required.
     */
    static testMethod void avoidUpdateRequiredQuestion() {

        Survey__c survey1 = TestUtils.createSurvey('FirstSurvey');

        Question__c sec1  = TestUtils.addQuestion(survey1, 1, 'section1', QuestionDO.TYPE_SECTION);
        
        // In this question set required as true
        Question__c question1 =  new Question__c(
                Survey__c   = survey1.Id,
                Parent__c   = sec1.Id,
                Name        = 'question1',
                Caption__c  = 'question1',
                Required__c = true,
                Position__c = 1,
                Type__c     = QuestionDO.TYPE_TEXT_SHORT);
        insert question1;
        
        Question__c question2 = TestUtils.addQuestion(sec1, 2, 'question2', QuestionDO.TYPE_TEXT_SHORT);
        
        // Generate a survey mapping with a required field
        SurveyMapping__c sm   = TestUtils.mapObject(survey1, 'Contact');
        QuestionMapping__c qm = TestUtils.mapQuestion(sm, question1, 'LastName');

        question1.Required__c = false;
        
        // When trying to update the answer, the trigger should avoid deleting it, because it is mapped to a required field
        Test.startTest();
            try{
                update question1;
                system.assert(false);
            }
            catch(Exception e){
                system.assertEquals(1, ApexPages.getMessages().size());
            }
        Test.stopTest();
        
        system.assert(ApexPages.getMessages().get(0).getDetail().contains(System.Label.SURVEY_QUESTION_ERR_MAPPED_REQUIREDCANNOTBEFALSE));
    }

    /**
     *  Tests that if a question is in a reference object, and the reference object is parent in a Master-Detail or required lookup
     *  relation, then the question cannot be set as not required.
     * TODO - This is commented out as you cannot map to gfsurveys namespaced objects and there
     *         are no m-d relationships on standard objects. This makes the test impossible to
     *         write at the moment. Need to look at a way to break down the test to get code
     *         coverage. IDALMSA-5677
     *
    static testMethod void UpdateQuestionInReference() {

        Survey__c survey1     = TestUtils.createSurvey('FirstSurvey');

        Question__c sec1      = TestUtils.addQuestion(survey1, 1, 'section1', QuestionDO.TYPE_SECTION);
        Question__c question1 = TestUtils.addQuestion(sec1, 1, 'question1', QuestionDO.TYPE_TEXT_SHORT);
        Question__c question2 = new Question__c(
                Survey__c   = survey1.Id,
                Parent__c   = sec1.Id,
                Name        = 'question2',
                Caption__c  = 'question2',
                Required__c = true,
                Position__c = 2,
                Type__c     = QuestionDO.TYPE_TEXT_SHORT);
        insert question2;
        // Now will try to update to not required a question that is mapped in a reference object and has a relation to a Master-Detail (Question__c on Option__c).

        String questionApiName = Question__c.sObjectType.getDescribe().getName();
        String optionApiName = Option__c.sObjectType.getDescribe().getName();
        String questionFieldApiName =
            Option__c.Question__c.getDescribe().getName();

        // First we create both survey mappings.
        SurveyMapping__c sm1 = TestUtils.mapObject(survey1, questionApiName);
        SurveyMapping__c sm2 = TestUtils.mapObject(survey1, optionApiName);
        // Relate each other...
        ObjectRelationshipMapping__c relation = TestUtils.relateObjects(sm2, sm1, questionFieldApiName);
        // ...map the question...
        QuestionMapping__c qm2 = TestUtils.mapQuestion(sm1, question2, 'Name');
        // ...and convert sm1 to reference object.
        sm1.IsReference__c   = true;
        sm1.MatchingField__c = 'LastName';
        update sm1;
        
        // Now try to make question2 not required
        question2.Required__c = false;
        
        Test.startTest();
            try{
                update question2;
                system.assert(false);
            }
            catch(Exception e){
                system.assert(true);
            }
        Test.stopTest();
        // Will fail because question is mapped in a reference object and the object has a relation to a Master-Detail.
        system.assert(ApexPages.getMessages().get(0).getDetail().contains(System.Label.SURVEY_QUESTION_ERR_RELATION_REQUIRED_CANNOT_BE_FALSE));
    }

    /**
     * Try to insert a cascading question with an invalid cascading select library
     */
    static testMethod void cannotInsertQuestionWithInvalidCascadingSelect(){
        List<CascadingLevel__c> levels =
            TestUtils.createCompleteCascadingSelect('TestInvalidCascading', 3, 2);
        Survey__c survey = newSurvey('InvalidCascadingInsert');
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1); 
        
        // Change status to processing
        CascadingSelect__c cascading = [SELECT Id, Status__c FROM CascadingSelect__c WHERE Id = :levels[0].CascadingSelect__c];
        cascading.Status__c = C.CASCADING_STATUS_PROCESSING;
        update cascading;

        Question__c qC1  = new Question__c( 
                Survey__c          = survey.Id, 
                Parent__c          = sec.Id, 
                Type__c            = QuestionDO.TYPE_CASCADING_SELECT, 
                Name               = 'cascading1', 
                Caption__c         = 'cascading1', 
                Position__c        = 1,
                CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        
        Test.startTest();
            try{
                insert qC1;
                system.assert(false, 'This should fail since cascading select is not in ready status');
            }catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.SURVEY_QUESTION_ERR_INVALID_CASCADINGSELECT), e.getMessage());
            }
        Test.stopTest();
    }

    // Try to update a cascading question with an invalid cascading select library
    static testMethod void cannotUpdateQuestionWithInvalidCascadingSelect(){
        List<CascadingLevel__c> levels  =
            TestUtils.createCompleteCascadingSelect('TestInvalidCascading', 3, 2);
        List<CascadingLevel__c> levels2 =
            TestUtils.createCompleteCascadingSelect('TestInvalidCascading2', 3, 2);
        
        Survey__c survey = newSurvey('InvalidCascadingInsert');
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1); 
        
        Question__c qC1  = new Question__c( 
                Survey__c          = survey.Id, 
                Parent__c          = sec.Id, 
                Type__c            = QuestionDO.TYPE_CASCADING_SELECT, 
                Name               = 'cascading1', 
                Caption__c         = 'cascading1', 
                Position__c        = 1,
                CascadingSelect__c = levels[0].CascadingSelect__c
        );
        
        insert qC1;

        // Change status to processing
        CascadingSelect__c cascading = [SELECT Id, Status__c FROM CascadingSelect__c WHERE Id = :levels2[0].CascadingSelect__c];
        cascading.Status__c = C.CASCADING_STATUS_PROCESSING;
        update cascading;
        // Change cascading select
        qC1.CascadingSelect__c = levels2[0].CascadingSelect__c;

        Test.startTest();
            try{
                update qC1;
                system.assert(false, 'This should fail since cascading select is not in ready status');
            }catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.SURVEY_QUESTION_ERR_INVALID_CASCADINGSELECT), e.getMessage());
            }
        Test.stopTest();
    }

    /**
      * Validate insertion of repeated question names
      *
      * IDALMSA-4478
      */
    static testMethod void validateInsertRepeatedTriggerNames(){
        Survey__c survey = newSurvey('TestInsertRepeatedNames');
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1); 
        Question__c q1   = newQuestion(survey, sec, QuestionDO.TYPE_TEXT_SHORT, 'q1', 'q1', 1); 

        Question__c q    = new Question__c( 
                Survey__c          = survey.Id, 
                Parent__c          = sec.Id, 
                Type__c            = QuestionDO.TYPE_TEXT_SHORT, 
                Name               = 'q1', 
                Caption__c         = 'q1', 
                Position__c        = 2
        );
        
        Test.startTest();
            try{
                insert q;
                system.assert(false, 'this should fail since question name is repeated');
            }catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.SURVEY_QUESTION_ERR_REP_QUESTION_NAME), e.getMessage());
            }
        Test.stopTest();
    }

    /**
      * Validate update of repeated question names
      *
      * IDALMSA-4478
      */
    static testMethod void validateUpdateRepeatedTriggerNames(){
        Survey__c survey = newSurvey('TestUpdateRepeatedNames');
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section1', 'section1', 1); 
        Question__c q1   = newQuestion(survey, sec, QuestionDO.TYPE_TEXT_SHORT, 'q1', 'q1', 1); 
        Question__c q2   = newQuestion(survey, sec, QuestionDO.TYPE_TEXT_SHORT, 'q2', 'q2', 2); 

        // Change name and try to update question
        q2.Name = 'q1';

        Test.startTest();
            try{
                update q2;
                system.assert(false, 'this should fail since question name is repeated');
            }catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.SURVEY_QUESTION_ERR_REP_QUESTION_NAME), e.getMessage());
            }
        Test.stopTest();
    }

    /**
     * IDALMSA-4251
     * Validate insert cascading question to a section with Same page set as true 
     */
    static testMethod void validateInsertCascadingSectionTrueShowAllSamePage(){
        // Create survey
        Survey__c survey = newSurvey('TestInsertCascadingInSectionShowAllToTrue');
        // Create levels
        List<CascadingLevel__c> levels =
            TestUtils.createCompleteCascadingSelect('Test', 3, 2);
        // Create section
        Question__c sec  = new Question__c(
                Survey__c   = survey.Id, 
                Parent__c   = null, 
                Type__c     = QuestionDO.TYPE_SECTION, 
                Name        = 'section1', 
                Caption__c  = 'section1', 
                Position__c = 1,
                SamePage__c = true);
        insert sec;
                 
        // Create cascading question
        Question__c qC1  = new Question__c( 
                Survey__c          = survey.Id, 
                Parent__c          = sec.Id, 
                Type__c            = QuestionDO.TYPE_CASCADING_SELECT, 
                Name               = 'cascading1', 
                Caption__c         = 'cascading1', 
                Position__c        = 1,
                CascadingSelect__c = levels[0].CascadingSelect__c
        );
        
        Test.startTest();
            try{
                insert qC1;
                system.assert(false, 'this should fail since add cascading question to a section with same page set as true');
            }catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.SURVEY_QUESTION_ERR_CANNOT_CASCADING_SHOWSAMEPAGE), e.getMessage());
            }
        Test.stopTest();
    }

    /**
     * IDALMSA-4251
     * Validate update cascading question to a section with Same page set as true 
     */
    static testMethod void validateUpdateCascadingInSectionTrueShowAllSamePage(){
        // Create survey
        Survey__c survey = newSurvey('TestUpdateCascadingInSectionShowAllToTrue');
        // Create levels
        List<CascadingLevel__c> levels =
            TestUtils.createCompleteCascadingSelect('Test', 3, 2);
        // Create section
        Question__c sec  = new Question__c(
                Survey__c   = survey.Id, 
                Parent__c   = null, 
                Type__c     = QuestionDO.TYPE_SECTION, 
                Name        = 'section1', 
                Caption__c  = 'section1', 
                Position__c = 1,
                SamePage__c = true);
        insert sec;
        // Create another section
        Question__c sec2  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section2', 'section2', 2); 
        
        // Create cascading question into the second section
        Question__c qC1  = new Question__c( 
                Survey__c          = survey.Id, 
                Parent__c          = sec2.Id, 
                Type__c            = QuestionDO.TYPE_CASCADING_SELECT, 
                Name               = 'cascading1', 
                Caption__c         = 'cascading1', 
                Position__c        = 1,
                CascadingSelect__c = levels[0].CascadingSelect__c
        );
        insert qC1;
        
        // Set section 1 as new parent
        qC1.Parent__c = sec.Id;

        Test.startTest();
            try{
                update qC1;
                system.assert(false, 'this should fail since update parent cascading question to a section with same page set as true');
            }catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.SURVEY_QUESTION_ERR_CANNOT_CASCADING_SHOWSAMEPAGE), e.getMessage());
            }
        Test.stopTest();
    }

    //----------Utility methods------------
    static Survey__c newSurvey(String surveyName){
        Survey__c s = new Survey__c(Name = surveyName);
        insert s;
        return s;
    }
    static Question__c newQuestion(Survey__c survey, Question__c parent, String type, String name, String caption, Integer position){
        Question__c q = new Question__c(Survey__c = survey.Id, Parent__c = (parent != null ? parent.Id : null), Type__c = type, Name = name, Caption__c = caption, Position__c = position);
        insert q;
        return q;
    }
}
