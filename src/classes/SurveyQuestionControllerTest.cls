/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
public class SurveyQuestionControllerTest{
    // Helper method to test empty strings
    private static Boolean empty(String s){
        return s == null || s.length() == 0;
    }

    //------------
    // Stub class for easy accessing controller methods
    //------------
    private class ControllerStub {
        public SurveyQuestionController controller;
        public String firstSection;
        public ControllerStub(boolean withTestData){
            Survey__c newSurvey = new Survey__c(Name = 'survey', Status__c = SurveyDO.STATUS_DRAFT); insert newSurvey;

            LicenseSettings__c license = C.getLicense();
            license.PPI_Editable__c = false;
            update license;

            if (withTestData) {
                Question__c auxSection = new Question__c (
                    Caption__c = 'TestSec',
                    Name = 'TestSec',
                    Type__c = QuestionDO.TYPE_SECTION,
                    Survey__c = newSurvey.Id,
                    Position__c = 1
                );
                insert auxSection;

                Question__c auxQuestion = new Question__c (
                    Caption__c = 'Test1',
                    Name = 'Test1',
                    Type__c = QuestionDO.TYPE_TEXT_SHORT,
                    Survey__c = newSurvey.Id,
                    Parent__c = auxSection.Id,
                    Position__c = 1
                );
                insert auxQuestion;

                SkipCondition__c auxCondition = new SkipCondition__c (
                    Parent__c = auxQuestion.Id,
                    SourceQuestion__c = auxQuestion.Id,
                    Condition__c = 'Is',
                    SkipValue__c = 'Test'
                );
                insert auxCondition;

                Option__c auxOption = new Option__c (
                    Question__c = auxQuestion.Id,
                    Name = 'TestOption',
                    Position__c = 1
                );
                insert auxOption;

                ScoringGroup__c auxScoringGroup = new ScoringGroup__c (
                    Survey__c = newSurvey.Id,
                    Caption__c = 'TestGroup'
                );
                insert auxScoringGroup;

                ScoreValue__c auxScoreValue = new ScoreValue__c (
                    ScoringGroup__c = auxScoringGroup.Id,
                    Option__c = auxOption.Id,
                    Value__c = 10
                );
                insert auxScoreValue;
            }
            ApexPages.StandardController stdController = new ApexPages.StandardController(newSurvey);
            this.controller = new SurveyQuestionController(stdController);
        }

        public ControllerStub(Survey__c survey){
            LicenseSettings__c license = C.getLicense();
            license.PPI_Editable__c = false;
            update license;

            ApexPages.StandardController stdController = new ApexPages.StandardController(survey);
            this.controller = new SurveyQuestionController(stdController);
        }

        public void addQuestion(BuilderQuestion question) {
            addQ(JSON.serialize(question));
        }
        public void addQ(String question){
            ApexPages.currentPage().getParameters().put('question', question);
            controller.addQuestionController();
        }

        public void editQuestion(BuilderQuestion question) {
            editQ(JSON.serialize(question));
        }
        public void editQ(String question){
            ApexPages.currentPage().getParameters().put('question', question);
            controller.editQuestionController();
        }

        public void removeQ(String name){
            ApexPages.currentPage().getParameters().put('qId', name);
            controller.removeQuestionController();
        }
        public void moveQ(String originId, String destinationId){
            ApexPages.currentPage().getParameters().put('originId',originId);
            ApexPages.currentPage().getParameters().put('destinationId',destinationId);
            controller.moveQuestionController();
            this.firstSection = SurveyQuestionController.FIRST_SECTION ;

        }

        public void publish(){
            SurveyDO.updateSurveysStatus(new List <Survey__c> {controller.survey}, SurveyDO.STATUS_PUBLISHED);
        }

        public BuilderQuestion getQ(String id) {
            return controller.findQuestion(id);
        }

        public void clear(){
            delete controller.survey;
        }
    }

    /**
    * Add and Save automatically a new Question to a Survey
    * When a survey add a new question to a list.
    * This saves it inmediatly.
    */
    static testMethod void testAutoSaveAddQuestion(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);
            // add a section
            stub.addQ('{"id":"s1", "caption":"s1", "name":"s1", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"1"}');

            // add a single question
            stub.addQ('{"id":"a1","caption":"a1","name":"a1","qhint":"a1","type":"text","parent":"s1"}');
        Test.stopTest();

        Question__c q = retrieveQuestion('a1');

        System.assertNotEquals(q, null, 'The Question must be saved when it\'s added.');
    }

    /**
     * Save automatically an edited a Survey
     *
     * Afterward a question is added to a Survey if
     * one is modified the changes are immediately saved.
     */
    static testMethod void testAutoSaveEditQuestion () {

        Test.startTest();
        ControllerStub stub = new ControllerStub(false);
        stub.addQ(
            '{"id":"s1", "caption":"s1", "name":"s1", "type":"'+
                QuestionDO.TYPE_SECTION +'", "position":"1","required":false}'
        );
        stub.addQ(
            '{"id":"a1","caption":"a1","name":"a1","qhint":"a1","type":' +
                '"text","parent":"s1","required":false}'
        );
        Question__c q = retrieveQuestion('a1');
        System.assertNotEquals(
            null,
            q,
            'The question "a1" must be stored because it was added to the Survey.'
        );
        stub.editQ(
            '{"id":"a1","caption":"aNewCaption","name":"a1","qhint":"a-edited",' +
                '"type":"text","required":false}'
        );
        Test.stopTest();

        q = retrieveQuestion('a1');
        System.assertEquals(
            'aNewCaption',
            q.Caption__c,
            'The Caption must be the same because the edition' +
                ' of question must be saved inmediatly.'
        );
    }

    /**
     * Testing it's not Autosaving when delete or move questions
     *
     * Create questions, remove one of them, move others, check there are still 3 stored questions,
     * edit one resting question and verify the postion and edition operation were saved automatically
     * when the edition successed.
     */
    static testMethod void testAutoSaveDeletingMoving(){

        Test.startTest();
            ControllerStub stub = new ControllerStub(false);

            //add Section and Question to the Survey (Precondition: have a survey with three questions, A B and C)
            stub.addQ('{"id":"sec1", "caption":"Section 1", "name":"Section_1", "type":"section", "position":"1","required":false}');
            stub.addQ('{"id":"a1","caption":"a1","name":"a1","qhint":"a1","type":"text", "parent":"sec1", "position":"1", "required":false}');
            stub.addQ('{"id":"b1","caption":"b1","name":"b1","qhint":"b1","type":"text", "parent":"sec1", "position":"2", "required":false}');
            stub.addQ('{"id":"c1","caption":"c1","name":"c1","qhint":"c1","type":"text", "parent":"sec1", "position":"3", "required":false}');

            //remove first question. (Delete A). The movement affects in cascade the position of below questions.
            stub.removeQ('a1');

            //Move questions (Move B to be the last)
            stub.moveQ('b1','c1');

            //Verify there is still three stored questions
            Question__c [] qs1=[
                            SELECT q.Id, q.Name, q.Caption__c, q.Type__c
                            FROM Question__c q
                            WHERE Type__c!='section'];

            System.assertEquals(3, qs1.size(), 'There should be 3 stored questions.');

            //One question is modified. (Edit C -modify it's caption-)
            BuilderQuestion q3_moved = stub.getQ('c1');
            stub.editQ('{"id":"c1","caption":"c1-New Caption","name":"c1","qhint":"c1 - New Hint","type":"text", "parent":"sec1","position":"'+q3_moved.position+'","required":false}');
        Test.stopTest();

        System.assertEquals(null, retrieveQuestion('a1'), 'The Question "a1" had to be deleted.');

        //Verify there are two stored questions (Assert the database now contains two questions)
        Question__c [] qs2=[
                        SELECT Id, Name, Caption__c, Position__c
                        FROM Question__c
                        WHERE Type__c!='section'
                        ORDER BY Position__c];
        System.assertEquals(2, qs2.size(), 'There should be 2 stored questions because one of three questions was deleted.');

        //(Assert positions for B and C are correct)
        System.assertEquals('c1', qs2[0].Name, 'First question is not c1');
        System.assertEquals('b1', qs2[1].Name, 'Seccond question is not b1');
        System.assertEquals(1, qs2[0].Position__c, 'Position of c1 is not 1');
        System.assertEquals(2, qs2[1].Position__c, 'Position of b1 is not 2');

        //C's caption was changed.
        System.assertEquals('c1-New Caption', qs2[0].Caption__c, 'Caption for c1 was not changed');
    }

    /**
    * Retrieve an stored question
    * <p>
    * Create a query to the database to retrieve a question
    * identified by the Name.
    */
    private static Question__c retrieveQuestion(String name){

        Question__c [] qs = [SELECT q.Id, q.Name, q.Caption__c FROM Question__c q WHERE q.Name = :name];

        return (qs.isEmpty()) ? null : qs[0];
    }

    /**
     * Test adding a question
     */
    static testMethod void addQuestion(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);

            // add a typeless question (should fail)
            stub.addQ('{"id":"Question1","caption":"This is question one."}');

            system.assert(!Apexpages.getMessages().isEmpty(), 'Should have complained that type is missing.');

            // add a single question
            stub.addQ('{'
                +'"id":"a",'
                +'"caption":"This is question one.",'
                +'"type":"'+ QuestionDO.TYPE_SECTION+'",'
                +'"options":[{"name":"a","position":"1"},{"name":"b","position":"2"}]'
                +'}');
        Test.stopTest();

        system.assertEquals('This is question one.',stub.controller.questions[0].caption);
        system.assertEquals(2, stub.controller.questions[0].options.size());
        system.assertEquals('a', stub.controller.questions[0].options[0].name);
    }

    /**
     * Test the editing of a question
     */
    static testMethod void editQuestionSuccess() {

        String questionId = 'a';
        String editedHint = 'a-edited';
        String editedType = QuestionDO.TYPE_TEXT_SHORT;

        Test.startTest();
        ControllerStub stub = new ControllerStub(false);

        BuilderQuestion section = createQuestion('s1', null, QuestionDO.TYPE_SECTION);
        section.position = 1;
        stub.addQuestion(section);

        // Create and then edit existing question: change description, keep caption
        BuilderQuestion questionToEdit = createQuestion(questionId, section, editedType);
        stub.addQuestion(questionToEdit);
        questionToEdit.qhint = editedHint;
        stub.editQuestion(questionToEdit);
        BuilderQuestion q = stub.getQ(questionId);
        System.assert(Apexpages.getMessages().isEmpty(), 'Found errors, but none were expected.');
        System.assertEquals(editedHint, q.qhint);
        System.assertEquals(editedType, q.type);
    }

    /**
     * Test that editing a question to have the same name as another fails
     */
    static testMethod void editQuestionFailureNameClash() {

        String clashName = 'a';

        Test.startTest();
        ControllerStub stub = new ControllerStub(false);

        BuilderQuestion section = createQuestion('s1', null, QuestionDO.TYPE_SECTION);
        section.position = 1;
        stub.addQuestion(section);

        BuilderQuestion initialQuestion = createQuestion(clashName, section, QuestionDO.TYPE_TEXT_SHORT);
        stub.addQuestion(initialQuestion);
        BuilderQuestion questionToClash = createQuestion('b', section, QuestionDO.TYPE_TEXT_SHORT);
        stub.addQuestion(questionToClash);
        questionToClash.name = clashName;
        stub.editQuestion(questionToClash);
        Test.stopTest();
        System.assert(
            !Apexpages.getMessages().isEmpty(),
            'Should have complained that caption is repeated'
        );
    }

    /**
     * Helper method to create a builder question
     */
    private static BuilderQuestion createQuestion(String prefix, BuilderQuestion parent, String type) {
        BuilderQuestion question = new BuilderQuestion();
        question.id = prefix;
        question.caption = prefix;
        question.name = prefix;
        question.qhint = prefix;
        question.type = type;
        question.parent = (parent != null) ? parent.name : '';
        question.required = false;
        return question;
    }

    /**
     * Test removing a question
     */
    static testMethod void removeQuestion(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);

            // add a section
            stub.addQ('{"id":"s1", "caption":"s1", "name":"s1", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"1"}');

            // remove an existing question (other questions should be shifted)
            stub.addQ('{"id":"a","caption":"a","name":"a","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","position":"1","parent":"s1"}');
            stub.addQ('{"id":"b","caption":"b","name":"b","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","position":"2","parent":"s1"}');

            system.assertEquals(3, stub.controller.questions.size());
            stub.removeQ('a');
            system.assert(Apexpages.getMessages().isEmpty(), 'Found errors, but none were expected.');
            system.assertEquals(3, stub.controller.questions.size());
            stub.controller.save();
        Test.stopTest();
        system.assertEquals(2, stub.controller.questions.size());
    }

    static testMethod void removeAddAndSaveQuestion() {
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);
            stub.addQ('{"id":"s","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1"}');
            stub.addQ('{"id":"a","caption":"a","name":"a","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"s"}');
            stub.controller.save();

            stub.removeQ('a');
            stub.addQ('{"id":"b","caption":"b","name":"b","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"s"}');
            boolean removeAndAddfail = false;
            try {
                stub.controller.save();
            } catch (Dmlexception dmlException) {
                removeAndAddfail = true;
            }
        Test.stopTest();
        system.assertEquals(false, removeAndAddfail, 'Removing and adding question in same save operation should be successful.');
    }

    static testMethod void questionOptions(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);
            stub.addQ('{'
                +'"id":"q",'
                +'"caption":"questionOptions()",'
                +'"type":"'+ QuestionDO.TYPE_SECTION +'","required":false,'
                +'"options":[{"id":"a","name":"a-orig","position":1},{"id":"b","name":"b","position":2}]'
                +'}');
            stub.editQ('{'
                +'"id":"q",'
                +'"caption":"questionOptions()",'
                +'"type":"'+ QuestionDO.TYPE_SECTION +'","required":false,'
                +'"options":[{"id":"a","name":"a","position":1},{"id":"c","name":"c","position":2}]'
                +'}');

            BuilderQuestion q = stub.getQ('q');
            system.assertEquals(2, q.options.size());
            system.assertEquals('a', q.getOption('a').name);

            stub.controller.quickSave();
            Id qid = [Select Id from Question__c where Caption__c = 'questionOptions()'][0].Id;
            Option__c[] ops = [select Id, Name from Option__c where Question__c = :qid order by Position__c];
            system.assertEquals(2, ops.size());
            system.assertEquals('a', ops[0].Name);
            system.assertEquals('c', ops[1].Name);

            // Let's try deleting c and adding d
            stub.editQ('{'
                +'"id":"q",'
                +'"caption":"This is still question one.",'
                +'"type":"'+ QuestionDO.TYPE_SECTION +'","required":false,'
                +'"options":[{"id":"a","name":"a","position":1},{"id":"d","name":"d","position":2}]'
                +'}');
        Test.stopTest();
        system.assertEquals(2, q.options.size());

        ops = [select Id, Name from Option__c where Question__c = :qid order by Position__c];
        system.assertEquals(2, ops.size());
        system.assertEquals('a', ops[0].Name);
        system.assertEquals('d', ops[1].Name);
    }

    /**
    * This method is to validate edition of a question not editable
    */
    static testMethod void editNotEditableQuestion(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(true);

            Question__c auxQuestion = [SELECT Id FROM Question__c WHERE Name = 'TestSec'];

            // Add question
            stub.addQ('{'
                +'"id":"q",'
                +'"caption":"TestQuest",'
                +'"type":"'+ QuestionDO.TYPE_TEXT_SHORT +'",'
                +'"options":[{"id":"a","name":"a-orig","position":1},{"id":"b","name":"b","position":2}],'
                +'"originId":"1234",'
                +'"remoteEditable":false,'
                +'"parent" : "' + auxQuestion.Id + '",'
                +'"position" : 1'
                +'}');
            // Save Question
            stub.controller.save();

            // Edit non editable question
            try{
                stub.controller.editQuestion('{'
                    +'"id":"q",'
                    +'"caption":"TestQuestEdition",'
                    +'"type":"'+ QuestionDO.TYPE_TEXT_SHORT +'",'
                    +'"options":[{"id":"a","name":"a-orig","position":1},{"id":"b","name":"b","position":2}],'
                    +'"originId":"1234",'
                    +'"remoteEditable":false,'
                    +'"parent" : "' + auxQuestion.Id + '",'
                    +'"position" : 1'
                    +'}');
                system.assert(false, 'Should have failed since origin Id is not null and is not an editable question.');
            }catch(Exception e){
                system.assert(e.getMessage().contains(system.label.QUESTION_ERR_CANTEDIT), e.getMessage());
            }
            // Checking that changes wasn't made
            BuilderQuestion q = stub.getQ('q');
        Test.stopTest();
        system.assertEquals('TestQuest',q.caption);

    }
        /**
     * This method validate:
     * 1- edition of section with non-editable question and with an editable question inside.
     * 2- deletion of section with editable questions inside.
     */
    static testMethod void editAndRemoveSectionWithEditableQuestion(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);

            stub.addQ('{"id":"secId","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true}');
            stub.addQ('{"id":"qId","caption":"a","name":"a","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"secId","position":"1","remoteEditable":true}');

            // Testing editable section with editable question inside
            stub.controller.editQuestion('{"id":"secId","caption":"NewSection","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true}');
            // Checking that change was made
            BuilderQuestion sec = stub.getQ('secId');
            system.assertEquals('NewSection',sec.caption);

            // Testing removable section with editable question inside
            // Remove Section
            stub.controller.removeQuestion('secId');
            // Checking that question was removed
            stub.controller.save();
            sec = stub.getQ('secId');
        Test.stopTest();
        system.assertEquals(null, sec);
    }

    /**
     * This method validate:
     * edition and deletion of editable questions.
     */
    static testMethod void editAndDeleteEditableQuestion(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);
            // Adding non-editable question and editable question and section
            stub.addQ('{"id":"secId","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true}');
            stub.addQ('{"id":"qId","caption":"a","name":"a","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"secId","position":"1","remoteEditable":true}');
            stub.addQ('{"id":"q2Id","caption":"b","name":"b","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"secId","position":"2","remoteEditable":false}');

            // Testing editable section with non-editable question inside
            stub.controller.editQuestion('{"id":"secId","caption":"NewSection","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true}');
            // Checking that change was made
            BuilderQuestion sec = stub.getQ('secId');
            sec = stub.getQ('secId');
            system.assertEquals('NewSection', sec.caption);

            //-----------------------------------

            // Testing editable question
            // Edit Question
            stub.controller.editQuestion('{"id":"qId","caption":"NewQuestion","name":"newQuestion","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"secId","position":"1","remoteEditable":true}');
            // Checking that change was made
            BuilderQuestion q = stub.getQ('qId');
            system.assertEquals('NewQuestion',q.caption);

            // Remove Question
            stub.removeQ('qId');
            // Checking that question was removed
            stub.controller.save();
            q = stub.getQ('qId');
        Test.stopTest();
        system.assertEquals(null, q);
    }

    /**
     * This method is to validate the remove action of a question not editable and a section with at least one question not editable
     */
    static testMethod void removeNotEdtiableQuestionAndSection(){
        Test.startTest();
        ControllerStub stub = new ControllerStub(false);
            stub.addQ('{"id":"s","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","originId":"12345","remoteEditable":true}');
            stub.addQ('{"id":"s2","caption":"Section 2","name":"Section_2","type":"'+ QuestionDO.TYPE_SECTION +'","position":"2","originId":"12334","remoteEditable":true}');
            stub.addQ('{'
                +'"id":"testRemove",'
                +'"caption":"questionOptions()",'
                +'"type":"'+ QuestionDO.TYPE_TEXT_SHORT +'",'
                +'"parent":"s",'
                +'"options":[{"id":"a","name":"a-orig","position":1},{"id":"b","name":"b","position":2}],'
                +'"originId":"1234",'
                +'"remoteEditable":false'
                +'}');

            // Save Question
            stub.controller.save();

            try{
                stub.controller.removeQuestion('testRemove');
                system.assert(false, 'Should have failed since origin Id is not null and is not a removable question.');
            }catch(Exception e){
                system.assert(e.getMessage().contains(system.label.QUESTION_ERR_CANTEDIT));
            }
            try{
                stub.controller.removeQuestion('s');
                system.assert(false, 'Should have failed since origin Id is not null and this section has a question that is not editable.');
            }
            catch(Exception e){
                system.assert(e.getMessage().contains(system.label.QUESTION_ERR_SECTIONCANTEDIT));
            }
        Test.stopTest();
    }

    static testMethod void sections(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);

            SurveyTriggerLogic.setOverrideChecksWhenSavingQuestion(true);

            stub.addQ('{"id":"s","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true}');
            stub.addQ('{"id":"a","caption":"a","name":"a","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"s","position":"1","remoteEditable":true}');
            stub.addQ('{"id":"b","caption":"b","name":"b","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"s","position":"2","remoteEditable":true}');

            Question__c[] savedQuestions = [SELECT Id, Name, Parent__c FROM Question__c WHERE Survey__c = :stub.controller.survey.Id ORDER BY Caption__c];
            system.assertEquals(3, savedQuestions.size());

            Question__c qa = savedQuestions[0];
            Question__c qb = savedQuestions[1];
            Question__c qs = savedQuestions[2];
            system.assertEquals(qa.Parent__c, qs.Id);
            system.assertEquals(qb.Parent__c, qs.Id);

            stub.addQ('{"id":"t","caption":"Section 2","name":"Section_2","type":"'+ QuestionDO.TYPE_SECTION +'"}');
            stub.addQ('{"id":"c","caption":"c","name":"c","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"t","position":"1"}');
            stub.addQ('{"id":"d","caption":"d","name":"d","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"t","position":"2"}');

            stub.removeQ('s');

            stub.controller.save();
        Test.stopTest();

        // Assert all questions are in the database, since t, c and d do autosave, but removing 's' doesn't
        savedQuestions = [select Id, Name, Parent__c from Question__c where Survey__c = :stub.controller.survey.Id order by Caption__c];
        system.assertEquals(3, savedQuestions.size());
        Question__c qc = savedQuestions[0];
        Question__c qd = savedQuestions[1];
        Question__c qt = savedQuestions[2];
        system.assertEquals(qc.Parent__c, qt.Id);
        system.assertEquals(qd.Parent__c, qt.Id);
    }

    static testMethod void editSurvey(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);
            stub.addQ('{'
                +'"id":"q",'
                +'"caption":"questionOptions()",'
                +'"type":"'+ QuestionDO.TYPE_SECTION +'",'
                +'"options":[{"id":"a","name":"a-orig","position":"1"},{"id":"b","name":"b","position":"2"}]'
                +'}');
            stub.controller.quickSave();
            ApexPages.StandardController stdController = new ApexPages.StandardController(stub.controller.survey);
            SurveyQuestionController controller = new SurveyQuestionController(stdController);
            system.assertEquals(1, controller.questions.size());
            BuilderQuestion bq = controller.questions[0];
            system.assertEquals(2, bq.options.size());
        Test.stopTest();
    }

    // Tests for moving questions
    static testMethod void move(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);

            SurveyTriggerLogic.setOverrideChecksWhenSavingQuestion(true);

            //prepare some questions to move
            //Sections
            stub.addQ('{"id":"sec1","caption":"first","name":"first_section","type":"'+ QuestionDO.TYPE_SECTION +'","position":1}');
            stub.addQ('{"id":"sec2","caption":"second","name":"second_section","type":"'+ QuestionDO.TYPE_SECTION +'","position":2}');
            //Questions
            stub.addQ('{"id":"a","caption":"first","name":"first","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","position":1,"parent":"sec1"}');
            stub.addQ('{"id":"b","caption":"second","name":"second","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","position":2,"parent":"sec1"}');
            stub.addQ('{"id":"c","caption":"third","name":"third","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","position":3,"parent":"sec1"}');

            BuilderQuestion q1 = stub.getQ('a');
            BuilderQuestion q2 = stub.getQ('b');
            BuilderQuestion q3 = stub.getQ('c');

            //----SAME SECTION------
            //Move down
            stub.moveQ('a','b');
            system.assertEquals(2,q1.position);
            system.assertEquals(1,q2.position);
            //Move up
            stub.moveQ('c','b');
            system.assertEquals(1,q2.position);
            system.assertEquals(2,q3.position);
            system.assertEquals(3,q1.position);

            //----DIFFERENT SECTIONS-----
            stub.removeQ('b');
            stub.controller.save();
            system.assertEquals(1,q3.position);
            system.assertEquals(2,q1.position);
            stub.addQ('{"id":"b","caption":"second","name":"second","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","position":1,"parent":"sec2"}');

            q2 = stub.getQ('b');
            BuilderQuestion sec1 = stub.getQ('sec1');
            BuilderQuestion sec2 = stub.getQ('sec2');
            //Move down
            stub.moveQ('a','b');
            system.assertEquals(2,q1.position);
            system.assertEquals('sec2',q1.parent);
            system.assertEquals(1,q2.position);
            system.assertEquals('sec2',q2.parent);
            system.assertEquals(1,q3.position);
            system.assertEquals('sec1',q3.parent);
            //Move up
            stub.moveQ('b','c');
            system.assertEquals(1,q1.position);
            system.assertEquals('sec2',q1.parent);
            system.assertEquals(2,q2.position);
            system.assertEquals('sec1',q2.parent);
            system.assertEquals(1,q3.position);
            system.assertEquals('sec1',q3.parent);

            //-------INSERT FIRST--------
            //-------SAME SECTION--------
            stub.moveQ('b','sec1');
            system.assertEquals(1,q2.position);
            system.assertEquals('sec1',q2.parent);
            system.assertEquals(1,q1.position);
            system.assertEquals('sec2',q1.parent);
            system.assertEquals(2,q3.position);
            system.assertEquals('sec1',q3.parent);

            //----DIFFERENT SECTIONS-------
            stub.moveQ('b','sec2');
            system.assertEquals(1,q2.position);
            system.assertEquals('sec2',q2.parent);
            system.assertEquals(2,q1.position);
            system.assertEquals('sec2',q1.parent);
            system.assertEquals(1,q3.position);
            system.assertEquals('sec1',q3.parent);
            //---------------------------------

            //-------MOVE SECTIONS---------
            stub.moveQ('sec1','sec2');
            system.assertEquals(2,sec1.position);
            system.assertEquals(1,sec2.position);
            system.assertEquals('sec1',q3.parent);
            system.assertEquals('sec2',q2.parent);
            system.assertEquals('sec2',q1.parent);
            //-----MOVE SECTION FIRST PLACE-----
            stub.moveQ('sec1', SurveyQuestionController.FIRST_SECTION);
            system.assertEquals(1,sec1.position);
            system.assertEquals(2,sec2.position);
        Test.stopTest();

    }

    static testmethod void checkNotPublishAlreadyPublished(){
        Test.startTest();
            //PREPARING THE TEST
            ControllerStub stub = new ControllerStub(false);
            //PERFORMING THE TEST
            stub.controller.save();
            PageReference pageReference = stub.controller.saveContinue();

            //CHECKING IF COULD SAVE IT
            System.assert(Apexpages.getMessages().isEmpty(), 'Found errors, but none were expected.');

            //CHECKING THE SAVE AND CONTINUE SUCCESS
            //I HAVE TO GO TO THE NEXT PAGE, THE RETURN CAN'T BE NULL
            System.assertNotEquals(null,pageReference);

            //PREPARING THE TEST
            stub.clear();
            stub = new ControllerStub(false);
            stub.publish();
            //PERFORMING THE TEST
            stub.controller.save();
            pageReference = stub.controller.saveContinue();
        Test.stopTest();
        //CHECKING IF A COULD SAVE IT
        System.assertEquals(SurveyQuestionController.ERR_SURVEY_ALREADY_PUBLISHED, ApexPages.getMessages().get(0).getDetail());

        //CHECKING THE SAVE AND CONTINUE FAIL
        //I HAVE TO STAY IN THIS PAGE, THE RETURN MUST BE NULL
        System.assertEquals(null,pageReference);
    }

    /**
     * This test the proper throw an error when i try to make changes in the Field mapping for this survey mean while the survey is been update.
     * This should not let me save the changes since the survey was modified.
     */
    static testmethod void testOutofSyncUpdateError(){

        Survey__c newSurvey = new Survey__c(Name='SurveyTest');
        insert newSurvey;
        Question__c section = new Question__c (Caption__c = 'sec1', Name = 'sec1', Type__c = QuestionDO.TYPE_SECTION, Survey__c = newSurvey.Id,Position__c = 1);
        insert section;
        Question__c auxQuestion = new Question__c (Caption__c = 'Test1', Name = 'Test1', Type__c = QuestionDO.TYPE_TEXT_SHORT, Survey__c = newSurvey.Id,Position__c =1,Parent__c = section.Id);
        insert auxQuestion;
        ApexPages.StandardController stdController = new ApexPages.StandardController(newSurvey);
        SurveyQuestionController controller = new SurveyQuestionController(stdController);
        //Update the survey directly(this is not using the controller.)
        newSurvey.Alias__c = 'as';

        C.wait(1);
        update newSurvey;
        newSurvey = [Select LastModifiedDate FROM Survey__c WHERE Id=:newsurvey.Id limit 1];
        DateTime currentLastModifiedDate = newSurvey.LastModifiedDate;
        Test.startTest();
            //If i try to save the survey from the controller it shouldnt be posible.
            controller.save();
            //It should trow the concurrent save popup
            System.assert(controller.concurrentSave, 'popup expected, but it was not shown.');
            //And it shouldn't update the survey.
            newSurvey = [Select LastModifiedDate FROM Survey__c WHERE Id = :newsurvey.Id limit 1];
            System.assertEquals(currentLastModifiedDate, newSurvey.LastModifiedDate);

            //Reload the controller now the last modified date will be updated.
            controller = new SurveyQuestionController(stdController);
            C.wait(1);
            controller.save();
        Test.stopTest();
        //It should trow no error, and it should update the survey
        System.assert(ApexPages.getMessages().isEmpty(), 'Found errors, but none were expected.');
        newSurvey = [Select LastModifiedDate FROM Survey__c WHERE Id = :newsurvey.Id limit 1];
        System.assertNotEquals(currentLastModifiedDate, newSurvey.LastModifiedDate);
    }

    static testMethod void testDeleteMappedQuestion_Required(){
        Survey__c survey = newSurvey('survey');
        Question__c section = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 's', 's', 1); insert section;
        Question__c question = newQuestion(survey,section,QuestionDO.TYPE_TEXT_SHORT,'q','q',1); insert question;


        SurveyMapping__c smapping = new SurveyMapping__c(Survey__c = survey.Id,ObjectApiName__c='Contact');
        insert smapping;
        QuestionMapping__c qmapping = new QuestionMapping__c(SurveyMapping__c = smapping.Id,Question__c=question.Id,FieldApiName__c='LastName');
        insert qmapping;


        //try to delete required question, it shouldn't be possible.
        Test.startTest();
            SurveyQuestionController controller = new SurveyQuestionController(new ApexPages.StandardController(survey));
            ApexPages.currentPage().getParameters().put('qId',question.Id);
            controller.removeQuestionController();
        Test.stopTest();
        //It should throw an error message.
        system.assertEquals(1, [SELECT Id FROM Question__c WHERE Id = :question.Id].size());
        system.assert(!Apexpages.getMessages().isEmpty(), 'Expected error on page, but none found');
    }

    static testMethod void testDeleteMappedQuestion_NotRequired(){
        Survey__c survey = newSurvey('survey');
        Question__c section = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 's', 's', 1); insert section;
        Question__c question = newQuestion(survey,section,QuestionDO.TYPE_TEXT_SHORT,'q','q',1); insert question;

        // Map the question to a required field
        SurveyMapping__c smapping = new SurveyMapping__c(Survey__c = survey.Id,ObjectApiName__c = 'Contact');
        insert smapping;
        QuestionMapping__c qmapping = new QuestionMapping__c(SurveyMapping__c = smapping.Id,Question__c = question.Id,FieldApiName__c = 'Description');
        insert qmapping;

        //I should not remove the question at save.
        Test.startTest();
            SurveyQuestionController controller = new SurveyQuestionController(new ApexPages.StandardController(survey));
            ApexPages.currentPage().getParameters().put('qId',question.Id);
            controller.removeQuestionController();
            system.assert(Apexpages.getMessages().isEmpty(), 'Found error, but none was expected');
        controller.save();
        Test.stopTest();

        //If I delete the mapping first, I should be able to delete the question.
        system.assert([SELECT Id FROM Question__c WHERE Id = :question.Id].isEmpty());
        system.assert([SELECT Id FROM QuestionMapping__c WHERE Id = :qmapping.Id].isEmpty());
    }
        //Delete a question without mapping
    static testMethod void testDeleteMappedQuestion_NotMapped(){
        Survey__c survey = newSurvey('survey');
        Question__c section = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 's', 's', 1); insert section;
        Question__c question = newQuestion(survey,section,QuestionDO.TYPE_TEXT_SHORT,'q','q',1); insert question;
        //Delete a question with not required mapping
        Test.startTest();
            SurveyQuestionController controller = new SurveyQuestionController(new ApexPages.StandardController(survey));
            ApexPages.currentPage().getParameters().put('qId',question.Id);
            controller.removeQuestionController();
            system.assert(Apexpages.getMessages().isEmpty(), 'Found error, but none was expected');
            controller.save();
        Test.stopTest();
        //Delete a question with required default mapping
        system.assert([SELECT Id FROM Question__c WHERE Id = :question.Id].isEmpty());
    }
    static testMethod void testDeleteMappedQuestion_MappedWithDefaultValue(){
        // TO BE DONE: There are no standard fields that are required and have default value at the same time.
        system.assert(true);
    }

    //Question Order Test
    static testMethod void initQuestionOrder(){
        Survey__c sur = newSurvey('surveyTest');
        Question__c sec1 = newQuestion(sur, null, QuestionDO.TYPE_SECTION, 'sectionTest', 'sectionTest',1);
        insert sec1;
        Question__c quest1 = newQuestion(sur, sec1, QuestionDO.TYPE_TEXT_SHORT, 'question1', 'question1',1);
        Question__c quest2 = newQuestion(sur, sec1, QuestionDO.TYPE_TEXT_SHORT, 'question2', 'question2',2);
        Question__c quest3 = newQuestion(sur, sec1, QuestionDO.TYPE_TEXT_SHORT, 'question3', 'question3',3);
        insert new Question__c[]{quest1, quest2, quest3};

        //Question Order-----
        quest3.Position__c = 2;
        update quest3;

        ApexPages.StandardController stdController = new ApexPages.StandardController(sur);
        SurveyQuestionController controller = new SurveyQuestionController(stdController);

        Test.startTest();
            controller.init();
            controller.updatePositions();
        Test.stopTest();

        quest3 =[select Id, Position__c from Question__c where Id = :quest3.Id];
        //Position fixed
        system.assertNotEquals( quest3.Position__c, quest2.Position__c );
        system.assertEquals(3,quest3.Position__c);
        system.assertEquals(2,quest2.Position__c);
        system.assertEquals(1,quest1.Position__c);
        //-------------------
    }
    static testMethod void initSectionOrder(){
        Survey__c sur = newSurvey('surveyTest');
        Question__c sec1 = newQuestion(sur, null, QuestionDO.TYPE_SECTION, 'sectionTest', 'sectionTest',1);
        insert sec1;

        //Section order------
        Question__c sec2 = newQuestion(sur, null, QuestionDO.TYPE_SECTION, 'sectionTest2', 'sectionTest2',2);
        insert sec2;

        sec2.Position__c=1;
        update sec2;

        Test.startTest();
            ApexPages.StandardController stdController2 = new ApexPages.StandardController(sur);
            SurveyQuestionController controller2 = new SurveyQuestionController(stdController2);
            controller2.init();
            controller2.updatePositions();
        Test.stopTest();

        sec2=[select Id, Position__c from Question__c where Id = :sec2.Id];
        //Position fixed
        system.assertNotEquals( sec2.Position__c, sec1.Position__c );
        system.assertEquals(1,sec1.Position__c);
        system.assertEquals(2,sec2.Position__c);
        //--------------------
    }
    static testMethod void initSectionWrongOrder(){
        Survey__c sur = newSurvey('surveyTest');
        Question__c sec1 = newQuestion(sur, null, QuestionDO.TYPE_SECTION, 'sectionTest', 'sectionTest',1);
        insert sec1;
        Question__c sec2 = newQuestion(sur, null, QuestionDO.TYPE_SECTION, 'sectionTest2', 'sectionTest2',2);
        insert sec2;

        sec1.Position__c = 210;
        update sec1;
        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(sur);
            SurveyQuestionController controller = new SurveyQuestionController(stdController);
            controller.init();
            controller.updatePositions();
        Test.stopTest();
        sec1 = [select Id, Position__c from Question__c where Id = :sec1.Id];
        sec2 = [select Id, Position__c from Question__c where Id = :sec2.Id];

        //Position fixed
        system.assertEquals(sec1.Position__c, sec2.Position__c+1);
        system.assertEquals(2,sec1.Position__c);
        system.assertEquals(1,sec2.Position__c);
        //---------------------------

    }
    static testMethod void initQuestWrongOrder(){
        Survey__c sur = newSurvey('surveyTest');
        Question__c sec1 = newQuestion(sur, null, QuestionDO.TYPE_SECTION, 'sectionTest', 'sectionTest',1);
        insert sec1;
        Question__c quest3 = newQuestion(sur, sec1, QuestionDO.TYPE_TEXT_SHORT, 'question3', 'question3',1);
        insert quest3;

        //Wrong position--------------
        Question__c quest4 = newQuestion(sur, sec1, QuestionDO.TYPE_TEXT_SHORT, 'question1', 'question1',2);
        insert quest4;

        quest4.Position__c = 210;
        update quest4;

        Test.startTest();
            ApexPages.StandardController stdController3 = new ApexPages.StandardController(sur);
            SurveyQuestionController controller3 = new SurveyQuestionController(stdController3);
            controller3.init();
            controller3.updatePositions();
        Test.stopTest();
        quest4 = [select Id, Position__c from Question__c where Id = :quest4.Id];

        //Position fixed
        system.assertEquals(quest4.Position__c, quest3.Position__c+1);
        system.assertEquals(2,quest4.Position__c);
        //---------------------------

    }

    // Test that skipped positions get fixed
    static testMethod void testInitFirstQuestionIsNotPositionOne(){
        Survey__c sur = newSurvey('surveyTest');
        Question__c sec1 = newQuestion(sur, null, QuestionDO.TYPE_SECTION, 'sectionTest', 'sectionTest',1);
        insert sec1;
        Question__c quest1 = newQuestion(sur, sec1, QuestionDO.TYPE_TEXT_SHORT, 'question1', 'question1',4);
        Question__c quest2 = newQuestion(sur, sec1, QuestionDO.TYPE_TEXT_SHORT, 'question2', 'question2',8);
        insert new Question__c[]{quest1, quest2};

        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(sur);
            SurveyQuestionController controller = new SurveyQuestionController(stdController);
            controller.init();
            controller.updatePositions();
        Test.stopTest();

        // Check positions were fixed
        quest1 = [select Id, Position__c from Question__c where Id = :quest1.Id];
        quest2 = [select Id, Position__c from Question__c where Id = :quest2.Id];
        system.assertEquals(1, quest1.Position__c);
        system.assertEquals(2, quest2.Position__c);
    }

    /**
        This method validate:
        1- Move the last question of a section to another section
        2- Delete the section without questions
        3- Show that the changes were made without problems
    */
    static testMethod void moveQuestionAndDeleteEmptySection(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);

            stub.addQ('{"id":"sec1", "caption":"Section 1", "name":"Section_1", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"1"}');
            stub.addQ('{"id":"sec2", "caption":"Section 2", "name":"Section_2", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"2"}');
            stub.addQ('{"id":"qId1", "caption":"a", "name":"a", "type":"'+ QuestionDO.TYPE_TEXT_SHORT +'", "parent":"sec1", "position":"1"}');
            stub.addQ('{"id":"qId2", "caption":"b", "name":"b", "type":"'+ QuestionDO.TYPE_TEXT_SHORT +'", "parent":"sec2", "position":"1"}');

            // Save the changes
            stub.controller.save();

            // Testing move the question to another section
            stub.moveQ('qId2', 'qId1');
            // Checking that move was made
            BuilderQuestion q2 = stub.getQ('qId2');
            system.assertEquals(2, q2.position);

            // Testing remove empty section
            // Remove Section
            stub.removeQ('sec2');
            stub.controller.save();
        Test.stopTest();

        // Check that the section was removed and the moved question was updated
        Question__c[] savedQuestions = [select Id, Caption__c, Parent__c, Position__c from Question__c where Survey__c = :stub.controller.survey.Id order by Caption__c];
        system.assertEquals(3, savedQuestions.size());
        Question__c a = savedQuestions[0];
        Question__c b = savedQuestions[1];
        Question__c s1 = savedQuestions[2];
        // Captions
        system.assertEquals('a', a.Caption__c);
        system.assertEquals('b', b.Caption__c);
        system.assertEquals('Section 1', s1.Caption__c);
        // Same section
        system.assertEquals(a.Parent__c, s1.Id);
        system.assertEquals(b.Parent__c, s1.Id);
        // Positions
        system.assertEquals(1, a.Position__c);
        system.assertEquals(2, b.Position__c);
    }

    /**
     * This method validate:
     * 1- Add a new section
     * 2- Move an existing question to the new section and save
     * 3- Show that the changes were made without problems
     */
    static testMethod void moveQuestionToNewSection(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);

            stub.addQ('{"id":"sec1", "caption":"Section 1", "name":"Section_1", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"1"}');
            stub.addQ('{"id":"qId1", "caption":"a", "name":"a", "type":"'+ QuestionDO.TYPE_TEXT_SHORT +'", "parent":"sec1", "position":"1"}');
            stub.addQ('{"id":"qId2", "caption":"b", "name":"b", "type":"'+ QuestionDO.TYPE_TEXT_SHORT +'", "parent":"sec1", "position":"2"}');

            // Save the changes
            stub.controller.save();

            // Add the new section
            stub.addQ('{"id":"sec2", "caption":"Section 2", "name":"Section_2", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"2"}');

            // Testing move the question to the new section
            stub.moveQ('qId2', 'sec2');
            // Checking that move was made
            BuilderQuestion q2 = stub.getQ('qId2');
            system.assertEquals(1, q2.position);
            system.assertEquals('sec2', q2.parent);

            // Save the changes
            stub.controller.save();
        Test.stopTest();

        // Check that all changes were made without problems
        Question__c[] savedQuestions = [select Id, Caption__c, Parent__c, Position__c from Question__c where Survey__c = :stub.controller.survey.Id order by Caption__c];
        system.assertEquals(4, savedQuestions.size());
        Question__c a = savedQuestions[0];
        Question__c b = savedQuestions[1];
        Question__c s1 = savedQuestions[2];
        Question__c s2 = savedQuestions[3];

        // Captions
        system.assertEquals('a', a.Caption__c);
        system.assertEquals('b', b.Caption__c);
        system.assertEquals('Section 1', s1.Caption__c);
        system.assertEquals('Section 2', s2.Caption__c);
        // Parents
        system.assertEquals(a.Parent__c, s1.Id);
        system.assertEquals(b.Parent__c, s2.Id);
        // Positions
        system.assertEquals(1, a.Position__c);
        system.assertEquals(1, b.Position__c);
        system.assertEquals(1, s1.Position__c);
        system.assertEquals(2, s2.Position__c);
    }

    /**
     * Move a question to another section with other questions, and delete the orgin section
     * Precondition: have S1(Q1,Q2),S2(Q3),S3(Q4)
     * Steps:
     *  # Move Q3 to be after Q1
     *  # Delete S2
     *  # Save
     */
    static testMethod void moveQuestionAndDeleteOriginSection(){
        // Precondition
        Survey__c surv = newSurvey('survey');
        Question__c s1 = newQuestion(surv, null, QuestionDO.TYPE_SECTION, 's1', 's1', 1);
        Question__c s2 = newQuestion(surv, null, QuestionDO.TYPE_SECTION, 's2', 's2', 2);
        Question__c s3 = newQuestion(surv, null, QuestionDO.TYPE_SECTION, 's3', 's3', 3);
        insert new Question__c[]{s1,s2,s3};
        Question__c q1 = newQuestion(surv, s1, QuestionDO.TYPE_TEXT_SHORT, 'q1', 'q1', 1);
        Question__c q2 = newQuestion(surv, s1, QuestionDO.TYPE_TEXT_SHORT, 'q2', 'q2', 2);
        Question__c q3 = newQuestion(surv, s2, QuestionDO.TYPE_TEXT_SHORT, 'q3', 'q3', 1);
        Question__c q4 = newQuestion(surv, s3, QuestionDO.TYPE_TEXT_SHORT, 'q4', 'q4', 1);
        insert new Question__c[]{q1,q2,q3,q4};

        // Test case
        Test.startTest();
            ControllerStub stub = new ControllerStub(surv);
            stub.moveQ(q3.Id,q1.Id);
            stub.removeQ(s2.Id);
            stub.controller.save();
        Test.stopTest();

        system.assert(Apexpages.getMessages().isEmpty(), Apexpages.getMessages());

        // Assert changes were made (questions should be [q1,q2,q3,q4,s1,s3])
        Question__c[] qs = [SELECT Id, Name, Position__c, Parent__c
                            FROM Question__c
                            WHERE Survey__c = :stub.controller.survey.Id
                            ORDER BY Name];

        system.assertEquals(6, qs.size(), 'Questions in database do not match expected number.');
        // Positions
        system.assertEquals(1, qs[0].Position__c, qs[0].Name + ' is missplaced');
        system.assertEquals(2, qs[2].Position__c, qs[2].Name + ' is missplaced');
        system.assertEquals(3, qs[1].Position__c, qs[1].Name + ' is missplaced');
        system.assertEquals(1, qs[3].Position__c, qs[3].Name + ' is missplaced');
        system.assertEquals(1, qs[4].Position__c, qs[4].Name + ' is missplaced');
        system.assertEquals(2, qs[5].Position__c, qs[5].Name + ' is missplaced');
        // Parents
        system.assertEquals(qs[4].Id, qs[0].Parent__c, qs[0].Name + ' has wrong parent');
        system.assertEquals(qs[4].Id, qs[1].Parent__c, qs[1].Name + ' has wrong parent');
        system.assertEquals(qs[4].Id, qs[2].Parent__c, qs[2].Name + ' has wrong parent');
        system.assertEquals(qs[5].Id, qs[3].Parent__c, qs[3].Name + ' has wrong parent');
    }

    /**
     * Move a question to the first place of next section and delete the origin section
     * Precondition: have S1(Q1,Q2),S2(Q3),S3(Q4)
     * Steps:
     *  # Move Q3 to be first question of S3
     *  # Delete S2
     *  # Save
     */
    static testMethod void moveQuestionFirstAndDeleteSection(){
        // Precondition
        Survey__c surv = newSurvey('survey');
        Question__c s1 = newQuestion(surv, null, QuestionDO.TYPE_SECTION, 's1', 's1', 1);
        Question__c s2 = newQuestion(surv, null, QuestionDO.TYPE_SECTION, 's2', 's2', 2);
        Question__c s3 = newQuestion(surv, null, QuestionDO.TYPE_SECTION, 's3', 's3', 3);
        insert new Question__c[]{s1,s2,s3};
        Question__c q1 = newQuestion(surv, s1, QuestionDO.TYPE_TEXT_SHORT, 'q1', 'q1', 1);
        Question__c q2 = newQuestion(surv, s1, QuestionDO.TYPE_TEXT_SHORT, 'q2', 'q2', 2);
        Question__c q3 = newQuestion(surv, s2, QuestionDO.TYPE_TEXT_SHORT, 'q3', 'q3', 1);
        Question__c q4 = newQuestion(surv, s3, QuestionDO.TYPE_TEXT_SHORT, 'q4', 'q4', 1);
        insert new Question__c[]{q1,q2,q3,q4};

        // Test case
        Test.startTest();
            ControllerStub stub = new ControllerStub(surv);
            stub.moveQ(q3.Id,s3.Id);
            stub.removeQ(s2.Id);
            stub.controller.save();
        Test.stopTest();

        system.assert(Apexpages.getMessages().isEmpty(), Apexpages.getMessages());

        // Assert changes were made (questions should be [q1,q2,q3,q4,s1,s3])
        Question__c[] qs = [SELECT Id, Name, Position__c, Parent__c
                            FROM Question__c
                            WHERE Survey__c = :stub.controller.survey.Id
                            ORDER BY Name];

        system.assertEquals(6, qs.size(), 'Questions in database do not match expected number.');
        // Positions
        system.assertEquals(1, qs[0].Position__c, qs[0].Name + ' is missplaced');
        system.assertEquals(2, qs[1].Position__c, qs[1].Name + ' is missplaced');
        system.assertEquals(1, qs[2].Position__c, qs[2].Name + ' is missplaced');
        system.assertEquals(2, qs[3].Position__c, qs[3].Name + ' is missplaced');
        system.assertEquals(1, qs[4].Position__c, qs[4].Name + ' is missplaced');
        system.assertEquals(2, qs[5].Position__c, qs[5].Name + ' is missplaced');
        // Parents
        system.assertEquals(qs[4].Id, qs[0].Parent__c, qs[0].Name + ' has wrong parent');
        system.assertEquals(qs[4].Id, qs[1].Parent__c, qs[1].Name + ' has wrong parent');
        system.assertEquals(qs[5].Id, qs[2].Parent__c, qs[2].Name + ' has wrong parent');
        system.assertEquals(qs[5].Id, qs[3].Parent__c, qs[3].Name + ' has wrong parent');
    }

    /**
     * Add new section, move an existing question to this section and remove the origin section
     * Precondition: have S1(Q1)
     * Steps:
     *  # Add S2
     *  # Add Q2 in S2
     *  # Remove S1
     *  # Save
     */
    static testMethod void moveQuestionToNewSectionAndDelete(){
        Test.startTest();
            // Precondition
            ControllerStub stub = new ControllerStub(false);
            stub.addQ('{"id":"s1", "caption":"s1", "name":"s1", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"1"}');
            stub.addQ('{"id":"q1", "caption":"q1", "name":"q1", "type":"'+ QuestionDO.TYPE_TEXT_SHORT +'", "parent":"s1", "position":"1"}');
            stub.controller.save();

            // Test case
            stub.addQ('{"id":"s2", "caption":"s2", "name":"s2", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"2"}');
            stub.addQ('{"id":"q2", "caption":"q2", "name":"q2", "type":"'+ QuestionDO.TYPE_TEXT_SHORT +'", "parent":"s2", "position":"1"}');
            stub.removeQ('s1');
            stub.controller.save();
        Test.stopTest();

        // Assert changes were made (questions should be [q2,s2])
        Question__c[] qs = [SELECT Id, Name, Position__c, Parent__c
                            FROM Question__c
                            WHERE Survey__c = :stub.controller.survey.Id
                            ORDER BY Name];

        system.assertEquals(4, qs.size(), 'Questions in database do not match expected number.');
        // Positions
        system.assertEquals(1, qs[0].Position__c, qs[0].Name + ' is missplaced');
        system.assertEquals(1, qs[1].Position__c, qs[1].Name + ' is missplaced');
        // Parents
        system.assertEquals(qs[2].Id, qs[0].Parent__c, qs[0].Name + ' has wrong parent');
    }

    /**
     * Test the validation rule Question CheckRepeatedSourceFields for questions repeated
     */
    static testMethod void validationCheckRepeatedSourceFieldsTest(){
        //set up the data
        Survey__c survey = newSurvey('someSurvey');

        Question__c section = new Question__c (Survey__c = survey.Id,
                                               Type__c   = QuestionDo.TYPE_SECTION,
                                               Name      = 'Section'
                                               );

        insert section;
        Question__c questionNumber = new Question__c (Survey__c = survey.id,
                                                      Type__c = QuestionDo.TYPE_NUMBER_INTEGER,
                                                      Name = 'QuestionNumber',
                                                      Parent__c = section.Id,
                                                      Position__c = 1
                                                    );

        Question__c questionText = new Question__c (Survey__c = survey.id,
                                                      Type__c = QuestionDo.TYPE_TEXT_SHORT,
                                                      Name = 'QuestionText',
                                                      Parent__c = section.Id,
                                                      Position__c = 2
                                                    );
        insert new Question__c[]{questionNumber, questionText};

        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_TEXT_SHORT,
                                    Parent__c = section.Id,
                                    Name = 'normalQuestion',
                                    RepeatTimes__c = 3 ,
                                    Position__c = 3
                                    );
            system.assert(false,'The insertion should fail here because text questions can not have RepeatTimes__c set');

        }catch(Exception e){
            system.assert(true);
        }

        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_TEXT_SHORT,
                                    Parent__c = section.Id,
                                    Name = 'normalQuestion',
                                    RepeatSourceValue__c =  questionNumber.Id,
                                    RepeatTimes__c = 3 ,
                                    Position__c = 3
                                    );
            system.assert(false,'The insertion should fail here because text questions can not have RepeatSourceValue__c and RepeatTimes__c set');

        }catch(Exception e){
            system.assert(true);
        }

        //insert a normal question with repeatsourcevalue set
        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_TEXT_SHORT,
                                    Parent__c = section.Id,
                                    Name = 'normalQuestion',
                                    RepeatSourceValue__c =  questionNumber.Id,
                                    Position__c = 3
                                    );
            system.assert(false,'The insertion should fail here because text questions can not have RepeatSourceValue__c set');

        }catch(Exception e){
            system.assert(true);
        }

         //insert a repeated the two custom fields set

        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_SECTION,
                                    Name = 'normalQuestion',
                                    RepeatSourceValue__c =  questionNumber.Id,
                                    Position__c = 3
                                    );
            system.assert(false,'The insertion should fail here because RepeatSourceValue__c  cannot be set in a section');

        }catch(Exception e){
            system.assert(true);
        }

         //insert a  section with set values

        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_SECTION,
                                    Name = 'normalQuestion',
                                    RepeatTimes__c = 3,
                                    Position__c = 3
                                    );
            system.assert(false,'The insertion should fail here because section cant have RepeatTimes__c');

        }catch(Exception e){
            system.assert(true);
        }

        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_SECTION,
                                    Name = 'normalQuestion',
                                    RepeatSourceValue__c =  questionNumber.Id,
                                    Position__c = 3
                                    );
            system.assert(false,'The insertion should fail here because section cant have RepeatSourceValue__c');

        }catch(Exception e){
            system.assert(true);
        }

        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_SECTION,
                                    Name = 'normalQuestion',
                                    RepeatSourceValue__c =  questionNumber.Id,
                                    RepeatTimes__c = 3,
                                    Position__c = 3
                                    );
            system.assert(false,'The insertion should fail here because section cant have RepeatSourceValue__c and RepeatTimes__c');

        }catch(Exception e){
            system.assert(true);
        }
         //insert a repeated the two custom fields set

        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_REPEAT,
                                    Name = 'normalQuestion',
                                    RepeatTimes__c = 3,
                                    RepeatSourceValue__c =  questionNumber.Id,
                                    Position__c = 3
                                    );
            system.assert(false,'The insertion should fail here because RepeatTimes__c and RepeatSourceValue__c  cannot be set simultaniusly');

        }catch(Exception e){
            system.assert(true);
        }

        //insert a repeated with a non-numerical value

        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_REPEAT,
                                    Name = 'normalQuestion',
                                    RepeatSourceValue__c =  questionText.Id,
                                    Position__c = 3
                                    );
            system.assert(false,'The insertion should fail here because  RepeatSourceValue__c  cannot be text');

        }catch(Exception e){
            system.assert(true);
        }

        //insert a repeated question with a set custom field
        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_REPEAT,
                                    Name = 'normalQuestion',
                                    RepeatTimes__c = 3,
                                    Position__c = 3
                                    );
            system.assert(true);

        }catch(Exception e){
            //'The Question should be inserted since its correct'
            system.assert(false, e.getMessage());
        }



        //insert a repeated question with null fields
        try{
            insert new Question__c( Survey__c = survey.Id,
                                    Type__c = QuestionDo.TYPE_REPEAT,
                                    Name='normalQuestion2',
                                    Position__c = 4
                                    );
            system.assert(true);

        }catch(Exception e){
            //'The Question should be inserted since its correct'
            system.assert(false, e.getMessage());
        }
    }

   /**
     * Validate that a final question cannot be added into a repeated section
     *
     * IDALMSA-2293
     */
    static testMethod void testAddFinalQuestionInRepeatedFail(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);
            // add a repeated section
            stub.addQ('{"id":"s1", "caption":"s1", "name":"s1", "type":"'+ QuestionDO.TYPE_REPEAT +'", "position":"1"}');
            // add a final question
            stub.addQ('{"id":"a1","caption":"a1","name":"a1","qhint":"a1","type":"'+ QuestionDO.TYPE_FINAL +'","parent":"s1"}');
        Test.stopTest();
        System.assert(ApexPages.getMessages().get(0).getDetail().contains('Cannot add or move an end of survey question into a repeated section'),
                      'this should not fail since is forbidden add a final question into a repeated section');
    }

    /**
     * Validate that a final question cannot be moved into a repeated section
     *
     * IDALMSA-2293
     */
    static testMethod void testMoveFinalQuestionInRepeatedFail(){
        Test.startTest();
            ControllerStub stub = new ControllerStub(false);
            // add a repeated section
            stub.addQ('{"id":"s1", "caption":"s1", "name":"s1", "type":"'+ QuestionDO.TYPE_REPEAT +'", "position":"1"}');
            // add a regular section
            stub.addQ('{"id":"s2", "caption":"s2", "name":"s2", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"2"}');
            // add a final question
            stub.addQ('{"id":"a1","caption":"a1","name":"a1","qhint":"a1","type":"'+ QuestionDO.TYPE_FINAL +'","parent":"s1"}');

            stub.moveQ('a1','s2');
        Test.stopTest();
        System.assert(ApexPages.getMessages().get(0).getDetail().contains('Cannot add or move an end of survey question into a repeated section'),
                      'this should not fail since is forbidden to move a final question into a repeated section');
    }

    /**
     * Validate that cascading questions can be added as a new type
     *
     * IDALMSA-4011
     */
    static testMethod void addNewCascadingQuestion(){
        CascadingSelect__c cS = new CascadingSelect__c(Name = 'testSlect1', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;

        createCascadingSelectLevels(cS.Id, 3);

        Test.startTest();
            ControllerStub stub = new ControllerStub(false);
            // Add a regular section
            stub.addQ('{"id":"s1", "caption":"s1", "name":"s1", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"1"}');
            // Add a cascading question
            stub.addQ('{"id":"a1","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s1","required":false}');
            // Save
            stub.controller.save();
        Test.stopTest();

        Question__c cascadingSelect = [SELECT Id, Name FROM Question__c WHERE Type__c = :QuestionDO.TYPE_CASCADING_SELECT AND Parent__r.Position__c = 1 LIMIT 1];

        // Check if Cascading select questions is inserted
        system.assertEquals(cascadingSelect.Name, 'cascading_parent');

        // Check children too
        List<Question__c> questionLevels = [SELECT Id, Name, Position__c FROM Question__c WHERE Parent__c = :cascadingSelect.Id];
        system.assert(!questionLevels.isEmpty(), 'List of levels cannot be empty');
        system.assertEquals(questionLevels.size(), 3);

        for(Integer i = 0; i < questionLevels.size(); i++){
            system.assertEquals(questionLevels[i].Name, questionLevels[i].Id);
        }
    }

    /**
     * Validate edition of caption and name cascading question
     *
     * IDALMSA-4321
     */
    static testMethod void editCaptionNameCascadingQuestion(){
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testSlect1', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;

        createCascadingSelectLevels(cS.Id, 3);

        // Add cascading question
        ControllerStub stub = new ControllerStub(false);
        // Add a regular section
        stub.addQ('{"id":"s1", "caption":"s1", "name":"s1", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"1"}');
        // Add a cascading question
        stub.addQ('{"id":"a1","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s1","required":false}');
        // Save
        stub.controller.save();

        Question__c cascadingSelect = [SELECT
                                            Id,
                                            Name,
                                            Caption__c
                                        FROM
                                            Question__c
                                        WHERE
                                            Type__c = :QuestionDO.TYPE_CASCADING_SELECT LIMIT 1];

        // Check name and caption before edition
        system.assertEquals(cascadingSelect.Name, 'cascading_parent');
        system.assertEquals(cascadingSelect.Caption__c, 'cascading parent');

        test.startTest();
            // Edit caption and name
            stub.editQ('{"id":"a1","caption":"cascading edited parent","cascadingId":"'+ cS.Id +'" ,"name":"cascading_edited_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s1","required":false}');
            // Save
            stub.controller.save();
        test.stopTest();

        cascadingSelect = [SELECT
                                Id,
                                Name,
                                Caption__c
                            FROM
                                Question__c
                            WHERE
                                Type__c = :QuestionDO.TYPE_CASCADING_SELECT LIMIT 1];

        // Check name and caption after edition
        system.assertEquals(cascadingSelect.Name, 'cascading_edited_parent');
        system.assertEquals(cascadingSelect.Caption__c, 'cascading edited parent');
    }

    /**
     * Validate edition of cascading selects selected from library in cascading questions
     *
     * IDALMSA-4321
     */
    static testMethod void editCascadingSelectsFromLibraryQuestion(){
        // Create 2 cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testSlect1', Status__c = C.CASCADING_STATUS_UPLOADED);
        CascadingSelect__c cS2 = new CascadingSelect__c(Name = 'testSlect2', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert new List<CascadingSelect__c>{cS, cS2};

        // Create levels
        createCascadingSelectLevels(cS.Id, 3);
        createCascadingSelectLevels(cS2.Id, 3);

        // Add cascading question
        ControllerStub stub = new ControllerStub(false);
        // Add a regular section
        stub.addQ('{"id":"s1", "caption":"s1", "name":"s1", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"1"}');
        // Add a cascading question
        stub.addQ('{"id":"a1","caption":"cascading parent","cascadingId":"'+ cS.Id +'","name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s1","required":false}');

        Question__c cascadingSelect = [SELECT
                                            Id,
                                            CascadingSelect__c
                                        FROM
                                            Question__c
                                        WHERE
                                            Type__c = :QuestionDO.TYPE_CASCADING_SELECT
                                            AND
                                                Name = 'test_cascading_parent' LIMIT 1];

        // Check cascading select before edition
        system.assertEquals(cascadingSelect.CascadingSelect__c, cS.Id);

        test.startTest();
            // Edit caption and name
            stub.editQ('{"id":"a1","caption":"cascading parent","cascadingId":"'+ cS2.Id +'" ,"name":"test_cascading_parent_edited","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s1","required":false}');
        test.stopTest();

        cascadingSelect = [SELECT
                                Id,
                                CascadingSelect__c
                            FROM
                                Question__c
                            WHERE
                                Type__c = :QuestionDO.TYPE_CASCADING_SELECT
                                AND
                                    Id = :cascadingSelect.Id
                            ORDER BY LastModifiedDate DESC
                            LIMIT 1];

        // Check cascading select after edition
        system.assertEquals(cascadingSelect.CascadingSelect__c, cS2.Id);
    }

    /**
     * Validate deletion of cascading selects and child questions
     *
     * IDALMSA-4322
     */
    static testMethod void deleteCascadingSelectsFromLibraryQuestion(){
        // Create cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testSlect1', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;

        // Create levels
        createCascadingSelectLevels(cS.Id, 3);

        // Add cascading question
        ControllerStub stub = new ControllerStub(false);
        // Add a regular section
        stub.addQ('{"id":"s1", "caption":"s1", "name":"s1", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"1"}');
        // Add a cascading question
        stub.addQ('{"id":"a1","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s1","required":false}');
        // Save
        stub.controller.save();

        Question__c cascadingSelect = [SELECT
                                            Id
                                        FROM
                                            Question__c
                                        WHERE
                                            Type__c = :QuestionDO.TYPE_CASCADING_SELECT
                                            AND
                                                Name = 'test_cascading_parent' LIMIT 1];

        test.startTest();
            // Remove cascading select question
            stub.removeQ('a1');
            // Save
            stub.controller.save();
        test.stopTest();

        // Check if children were correctly deleted
        List<Question__c> questionLevels = [SELECT
                                                Id
                                            FROM
                                                Question__c
                                            WHERE
                                                Parent__c = :cascadingSelect.Id];

        system.assert(questionLevels.isEmpty(), 'List of levels must be empty');
    }


    /**
      * Validate deletion of cascading selects and child questions when deleting a section
      *
      * IDALMSA-4418
      */
    static testMethod void deleteSectionThatContainsCascadingQuestion(){
        // Create cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testSlect2', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;

        // Create levels
        createCascadingSelectLevels(cS.Id, 3);

        Test.startTest();
            ControllerStub stub = new ControllerStub(false);

            SurveyTriggerLogic.setOverrideChecksWhenSavingQuestion(true);

            stub.addQ('{"id":"s","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true}');
            stub.addQ('{"id":"a","caption":"a","name":"a","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"s","position":"1","remoteEditable":true,"required":false}');
            // Add a cascading question
            stub.addQ('{"id":"b","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s", "position":"2", "remoteEditable":true,"required":false}');

            // Check questions are saved in database
            List<Question__c> savedQuestions = [SELECT
                                                    Id
                                                FROM
                                                    Question__c
                                                WHERE
                                                    Survey__c = :stub.controller.survey.Id];

            // 3 added questions manually and 3 levels questions added automatically
            system.assertEquals(6, savedQuestions.size());

            // Remove section that contains cascading question
            stub.removeQ('s');
            stub.controller.save();
        Test.stopTest();

        savedQuestions = [SELECT
                                Id
                            FROM
                                Question__c
                            WHERE
                                Survey__c = :stub.controller.survey.Id
                                AND
                                    Name = 'test_cascading_parent'];

        // All level question must be removed with cascading question parent
        system.assert(savedQuestions.isEmpty(), 'Questions and question Levels must be removed');
    }

    /**
      * Validate insertion of required cascading selects must set all children as required too
      *
      * IDALMSA-4012
      */
    static testMethod void insertingCascadingAsRequired(){
        // Create cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testRequiredSelect', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;

        // Create levels
        createCascadingSelectLevels(cS.Id, 3);

        Test.startTest();
            ControllerStub stub = new ControllerStub(false);

            SurveyTriggerLogic.setOverrideChecksWhenSavingQuestion(true);

            stub.addQ('{"id":"s","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true}');
            stub.addQ('{"id":"a","caption":"a","name":"a","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"s","position":"1","remoteEditable":true}');
            // Add a cascading question
            stub.addQ('{"id":"b","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s", "position":"2", "required":true, "remoteEditable":true}');
        Test.stopTest();

        List<Question__c> levels = [SELECT
                                        Id,
                                        Name,
                                        Required__c
                                    FROM
                                        Question__c
                                    WHERE
                                        Parent__r.Name = :'test_cascading_parent'
                                    ORDER BY
                                        Position__c];

        // Checking that every child is required too
        for(Question__c level : levels){
            system.assert(level.Required__c, 'Question: ' + level.Name + ' must be required as his parent');
        }
    }

    /**
      * Validate edition of required cascading selects must set all children as required too
      *
      * IDALMSA-4012
      */
    static testMethod void editCascadingAsRequired(){
        // Create cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testRequiredSelect', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;

        // Create levels
        createCascadingSelectLevels(cS.Id, 3);

        ControllerStub stub = new ControllerStub(false);

        SurveyTriggerLogic.setOverrideChecksWhenSavingQuestion(true);

        stub.addQ('{"id":"s","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true}');
        stub.addQ('{"id":"a","caption":"a","name":"a","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"s","position":"1","remoteEditable":true}');
        // Add a cascading question
        stub.addQ('{"id":"b","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s", "position":"2", "required":false, "remoteEditable":true}');

        Test.startTest();
            // Make parent required
            stub.editQ('{"id":"b","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s", "position":"2", "required":true, "remoteEditable":true}');
        Test.stopTest();

        List<Question__c> levels = [SELECT
                                        Id,
                                        Name,
                                        Required__c
                                    FROM
                                        Question__c
                                    WHERE
                                        Parent__r.Name = :'test_cascading_parent'
                                    ORDER BY
                                        Position__c];

        // Checking that every child is required too
        for(Question__c level : levels){
            system.assert(level.Required__c, 'Question: ' + level.Name + ' must be required as his parent');
        }
    }

    /**
      * Validate edition of not required cascading selects must set all children as not required too
      *
      * IDALMSA-4012
      */
    static testMethod void editCascadingAsNotRequired(){
        // Create cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testRequiredSelect', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;

        // Create levels
        createCascadingSelectLevels(cS.Id, 3);

        ControllerStub stub = new ControllerStub(false);

        SurveyTriggerLogic.setOverrideChecksWhenSavingQuestion(true);

        stub.addQ('{"id":"s","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true}');
        stub.addQ('{"id":"a","caption":"a","name":"a","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","parent":"s","position":"1","remoteEditable":true}');
        // Add a cascading question
        stub.addQ('{"id":"b","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s", "position":"2", "required":true, "remoteEditable":true}');

        Test.startTest();
            // Make parent not required
            stub.editQ('{"id":"b","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s", "position":"2", "required":false, "remoteEditable":true}');
        Test.stopTest();

        List<Question__c> levels = [SELECT
                                        Id,
                                        Name,
                                        Required__c
                                    FROM
                                        Question__c
                                    WHERE
                                        Parent__r.Name = :'test_cascading_parent'
                                    ORDER BY
                                        Position__c];

        // Checking that every child is required too
        for(Question__c level : levels){
            system.assert(!level.Required__c, 'Question: ' + level.Name + ' must be not required as his parent');
        }
    }

    /**
      * Validate uniqueness of names in question levels
      *
      * IDALMSA-4478
      */
    static testMethod void checkUniqueNameOfQuestionLevels(){
        // Create cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testRequiredSelect', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;

        // Create levels
        createCascadingSelectLevels(cS.Id, 3);

        ControllerStub stub = new ControllerStub(false);

        SurveyTriggerLogic.setOverrideChecksWhenSavingQuestion(true);

        stub.addQ('{"id":"s","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true}');
        // Add a cascading question
        stub.addQ('{"id":"b","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s", "position":"2", "required":true, "remoteEditable":true}');

        List<Question__c> levels = [SELECT
                                        Id,
                                        Name,
                                        Required__c
                                    FROM
                                        Question__c
                                    WHERE
                                        Parent__r.Name = :'test_cascading_parent'
                                    ORDER BY
                                        Position__c];

        // Checking that every child name is the record id
        for(Question__c level : levels){
            system.assertEquals(level.Name, level.Id);
        }
    }

    // Check validation rule when question is not related to a cascading library
    static testMethod void checkValidationOfCascadingSelectInCascadingQuestion(){
        // Create Survey
        Survey__c survey = newSurvey('TestCascadingQuestionWithoutCascadingLibray');
        // Create Section
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section_name', 'section_caption', 1);
        insert sec;
        // Create Cascading without cascading library
        Question__c qCas = new Question__c(
            Survey__c   = survey.Id,
            Parent__c   = sec.Id,
            Type__c     = QuestionDO.TYPE_CASCADING_SELECT,
            Name        = 'cascading_name',
            Caption__c  = 'CascadingCaption',
            Position__c = 2);

        try{
            insert qCas;
            system.assert(false, 'this should fail since cascading question is not related to any cascading library');
        }
        catch(Exception e){
            system.assert(e.getMessage().contains(System.Label.QUESTION_TYPE_CASCADING_SELECT_NULL_LIBRARY), e.getMessage());
        }
    }

    /**
     * IDALMSA-4251
     * Check adding a cascading question sets section same page field in false
     */
    static testMethod void addCascadingSameOnOnePageFalse(){
        // Create cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testRequiredSelect', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;

        // Create levels
        createCascadingSelectLevels(cS.Id, 3);

        ControllerStub stub = new ControllerStub(false);

        SurveyTriggerLogic.setOverrideChecksWhenSavingQuestion(true);
        // Add section with sampe page set in true
        stub.addQ('{"id":"s","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true, "samePage":true}');

        Test.startTest();
            // Add a cascading question
            stub.addQ('{"id":"b","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s", "position":"2", "required":true, "remoteEditable":true}');
        Test.stopTest();

        // Check same page is false in destination section
        system.assert(![SELECT SamePage__c FROM Question__c WHERE Name = 'Section_1' LIMIT 1].SamePage__c, 'Cannot fail since section contains a cascading select');
    }

    /**
     * IDALMSA-4251
     * Check moving a cascading question sets section same page field in false
     */
    static testMethod void moveCascadingSameOnOnePageFalse(){
        // Create cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testRequiredSelect', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;

        // Create levels
        createCascadingSelectLevels(cS.Id, 3);

        ControllerStub stub = new ControllerStub(false);

        SurveyTriggerLogic.setOverrideChecksWhenSavingQuestion(true);
        // Add section with sampe page set in true
        stub.addQ('{"id":"s","caption":"Section 1","name":"Section_1","type":"'+ QuestionDO.TYPE_SECTION +'","position":"1","remoteEditable":true, "samePage":true}');
        // Add text question
        stub.addQ('{"id":"q1","caption":"Text 1","name":"Text_1","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","position":"1","parent":"s","remoteEditable":true}');
        // Add second section same page false
        stub.addQ('{"id":"s2","caption":"Section 2","name":"Section_2","type":"'+ QuestionDO.TYPE_SECTION +'","position":"2","remoteEditable":true}');
        // Add text question
        stub.addQ('{"id":"q2","caption":"Text 2","name":"Text_2","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","position":"1","parent":"s2","remoteEditable":true}');
        // Add a cascading question
        stub.addQ('{"id":"b","caption":"cascading parent","cascadingId":"'+ cS.Id +'" ,"name":"test_cascading_parent","qhint":"a1","type":"'+ QuestionDO.TYPE_CASCADING_SELECT +'","parent":"s2", "position":"2", "required":true, "remoteEditable":true}');

        Test.startTest();
            // Move a cascading question to the first section
            stub.moveQ('b','q1');
            // Save the changes
            stub.controller.save();
        Test.stopTest();

        // Check same page is false in destination section
        system.assert(![SELECT SamePage__c FROM Question__c WHERE Name = 'Section_1' LIMIT 1].SamePage__c, 'Cannot fail since section contains a cascading select');
    }

    // Validate insert of cascading select question on repeated sections
    static testMethod void insertCascadingOnRepeatedSection(){
        // Create Survey
        Survey__c survey = newSurvey('TestcascadingOnRepeatedSection');
        // Create cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testRequiredSelect', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;
        // Create levels
        createCascadingSelectLevels(cS.Id, 3);
        // Create Section
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'section_name', 'section_caption', 1);
        insert sec;
        // Create Cascading without cascading library
        Question__c qCas = new Question__c(
            Survey__c          = survey.Id,
            Parent__c          = sec.Id,
            Type__c            = QuestionDO.TYPE_CASCADING_SELECT,
            Name               = 'cascading_name',
            Caption__c         = 'CascadingCaption',
            CascadingSelect__c = cS.Id,
            Position__c        = 1);

        Test.startTest();
            try{
                insert qCas;
                system.assert(false, 'this should fail since cascading question cannot be inserted into a repeated section');
            }
            catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.QUESTION_TYPE_CASCADING_SELECT_INTO_REPEAT), e.getMessage());
            }
        Test.stopTest();
    }

    // Validate update cascading select question on repeated sections
    static testMethod void updateCascadingOnRepeatedSection(){
        // Create Survey
        Survey__c survey = newSurvey('TestcascadingOnRepeatedSection');
        // Create cascading selects in library
        CascadingSelect__c cS  = new CascadingSelect__c(Name = 'testRequiredSelect', Status__c = C.CASCADING_STATUS_UPLOADED);
        insert cS;
        // Create levels
        createCascadingSelectLevels(cS.Id, 3);
        // Create Sections
        Question__c rep  = newQuestion(survey, null, QuestionDO.TYPE_REPEAT, 'rep_name', 'rep_caption', 1);
        insert rep;
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section_name', 'section_caption', 2);
        insert sec;
        // Create text question
        Question__c txt  = newQuestion(survey, rep, QuestionDO.TYPE_TEXT_SHORT, 'question_name', 'question_caption', 1);
        insert txt;
        // Create Cascading without cascading library
        Question__c qCas = new Question__c(
            Survey__c          = survey.Id,
            Parent__c          = sec.Id,
            Type__c            = QuestionDO.TYPE_CASCADING_SELECT,
            Name               = 'cascading_name',
            Caption__c         = 'CascadingCaption',
            CascadingSelect__c = cS.Id,
            Position__c        = 1);
        insert qCas;

        // Change question parent
        qCas.Parent__c = rep.Id;

        Test.startTest();
            try{
                update qCas;
                system.assert(false, 'this should fail since cascading question cannot be inserted into a repeated section');
            }
            catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.QUESTION_TYPE_CASCADING_SELECT_INTO_REPEAT), e.getMessage());
            }
        Test.stopTest();
    }

    // Validate updating question to be not required with id field mapping
    static testMethod void setQuestionMappedToAnIdFieldAsNotRequired(){
        // Create Survey
        Survey__c survey = newSurvey('TestMappingIdField');
        // Create Section
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section_name', 'section_caption', 1);
        insert sec;
        // Create required text question
        Question__c txt  = new Question__c (
            Survey__c   = survey.Id,
            Parent__c   = sec.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT,
            Name        = 'question_name',
            Caption__c  = 'question_caption',
            Position__c = 1,
            Required__c = true
        );
        insert txt;
        // Create survey mapping
        SurveyMapping__c sm   = new SurveyMapping__c(Survey__c = survey.Id, ObjectApiName__c = 'Contact', MatchingField__c = 'mobilesurveys_Id__c');
        insert sm;
        QuestionMapping__c qm = new QuestionMapping__c(SurveyMapping__c = sm.Id, Question__c = txt.Id, FieldApiName__c = 'mobilesurveys_Id__c');
        insert qm;

        // Change required to false
        txt.Required__c = false;

        Test.startTest();
            try{
                update txt;
                system.assert(false, 'Should fail here since question cannot be not required cause is mapped to an id field');
            }catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.SURVEY_QUESTION_ERR_MAPPED_QUESTION_IDFIELD_REQUIRED), e.getMessage());
            }
        Test.stopTest();
    }

    // Validate deletion of questions mapped to an id field (Trigger)
    static testMethod void removeQuestionMappedToAnIdFieldTrigger(){
        // Create Survey
        Survey__c survey = newSurvey('TestMappingIdField');
        // Create Section
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section_name', 'section_caption', 1);
        insert sec;
        // Create required text question
        Question__c txt  = new Question__c (
            Survey__c   = survey.Id,
            Parent__c   = sec.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT,
            Name        = 'question_name',
            Caption__c  = 'question_caption',
            Position__c = 1,
            Required__c = true
        );
        insert txt;
        // Create survey mapping
        SurveyMapping__c sm   = new SurveyMapping__c(Survey__c = survey.Id, ObjectApiName__c = 'Contact', MatchingField__c = 'mobilesurveys_Id__c');
        insert sm;
        QuestionMapping__c qm = new QuestionMapping__c(SurveyMapping__c = sm.Id, Question__c = txt.Id, FieldApiName__c = 'mobilesurveys_Id__c');
        insert qm;

        Test.startTest();
            try{
                delete txt;
                system.assert(false, 'Should fail here since question required by id field mapping cannot be removed');
            }catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.SURVEY_QUESTION_ERR_MAPPED_QUESTION_IDFIELD), e.getMessage());
            }
        Test.stopTest();
    }

    // Validate deletion of section with question mapped to an id field
    static testMethod void removeSectionWithQuestionMappedToAnIdField(){
        // Create Survey
        Survey__c survey = newSurvey('TestMappingIdField');
        // Create Section
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section_name', 'section_caption', 1);
        insert sec;
        // Create required text question
        Question__c txt  = new Question__c (
            Survey__c   = survey.Id,
            Parent__c   = sec.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT,
            Name        = 'question_name',
            Caption__c  = 'question_caption',
            Position__c = 1,
            Required__c = true
        );
        insert txt;
        // Create survey mapping
        SurveyMapping__c sm   = new SurveyMapping__c(Survey__c = survey.Id, ObjectApiName__c = 'Contact', MatchingField__c = 'mobilesurveys_Id__c');
        insert sm;
        QuestionMapping__c qm = new QuestionMapping__c(SurveyMapping__c = sm.Id, Question__c = txt.Id, FieldApiName__c = 'mobilesurveys_Id__c');
        insert qm;

        Test.startTest();
            SurveyQuestionController controller = new SurveyQuestionController(new ApexPages.StandardController(survey));
            ApexPages.currentPage().getParameters().put('qId', txt.Id);
            controller.removeQuestionController();
        Test.stopTest();

        system.assert(!Apexpages.getMessages().isEmpty(), 'Must had an error message since question mapped to an id field is required');
        system.assert(Apexpages.getMessages().get(0).getDetail().contains(System.Label.SURVEY_QUESTION_ERR_MAPPED_QUESTION_IDFIELD), Apexpages.getMessages().get(0).getDetail());

    }

    // Validate deletion of questions mapped to an id field
    static testMethod void removeQuestionMappedToAnIdField(){
        // Create Survey
        Survey__c survey = newSurvey('TestMappingIdField');
        // Create Section
        Question__c sec  = newQuestion(survey, null, QuestionDO.TYPE_SECTION, 'section_name', 'section_caption', 1);
        insert sec;
        // Create required text question
        Question__c txt  = new Question__c (
            Survey__c   = survey.Id,
            Parent__c   = sec.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT,
            Name        = 'question_name',
            Caption__c  = 'question_caption',
            Position__c = 1,
            Required__c = true
        );
        insert txt;
        // Create survey mapping
        SurveyMapping__c sm   = new SurveyMapping__c(Survey__c = survey.Id, ObjectApiName__c = 'Contact', MatchingField__c = 'mobilesurveys_Id__c');
        insert sm;
        QuestionMapping__c qm = new QuestionMapping__c(SurveyMapping__c = sm.Id, Question__c = txt.Id, FieldApiName__c = 'mobilesurveys_Id__c');
        insert qm;

        Test.startTest();
            SurveyQuestionController controller = new SurveyQuestionController(new ApexPages.StandardController(survey));
            ApexPages.currentPage().getParameters().put('qId', txt.Id);
            controller.removeQuestionController();
        Test.stopTest();

        system.assert(!Apexpages.getMessages().isEmpty(), 'Must had an error message since question mapped to an id field is required');
        system.assert(Apexpages.getMessages().get(0).getDetail().contains(System.Label.SURVEY_QUESTION_ERR_MAPPED_QUESTION_IDFIELD), Apexpages.getMessages().get(0).getDetail());
    }

    // Validate deletion of number questions related to a repeated section
    static testMethod void removeNumberQuestionRelatedToRepeated(){
        ControllerStub stub = new ControllerStub(false);

        // Create Section and Repeated
        stub.addQ('{"id":"s1", "caption":"s1", "name":"s1", "type":"'+ QuestionDO.TYPE_SECTION +'", "position":"1"}');
        // Add 2 questions to first section
        stub.addQ('{"id":"a","caption":"a","name":"a","type":"'+ QuestionDO.TYPE_NUMBER_INTEGER +'","position":"1","parent":"s1"}');
        stub.addQ('{"id":"b","caption":"b","name":"b","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","position":"2","parent":"s1"}');
        // Add repeated section related to number
        stub.addQ('{"id":"r1", "caption":"r1", "name":"r1", "type":"'+ QuestionDO.TYPE_REPEAT +'", "prevSourceQuestion":"a", "position":"1"}');
        // Add a question to the repeated
        stub.addQ('{"id":"c","caption":"c","name":"c","type":"'+ QuestionDO.TYPE_TEXT_SHORT +'","position":"1","parent":"r1"}');
        // Save
        stub.controller.save();
        // Remove number related
        stub.removeQ('a');

        Test.startTest();
        // Save
        stub.controller.save();
        Test.stopTest();

        // Check that section related to the removed number question was correctly updated
        system.assert(![SELECT RepeatSourceValue__c FROM Question__c WHERE Name = 'r1'].isEmpty(), 'Should find at least the created repeated section');
        system.assertEquals(null, [SELECT RepeatSourceValue__c FROM Question__c WHERE Name = 'r1'].RepeatSourceValue__c);
    }


    //----------Utility methods------------
    static Survey__c newSurvey(String surveyName){
        Survey__c s = new Survey__c(Name = surveyName, Status__c = SurveyDO.STATUS_DRAFT);
        insert s;
        return s;
    }

    static Question__c newQuestion(Survey__c survey, Question__c parent, String type, String name, String caption, Integer position){
        return new Question__c(Survey__c = survey.Id, Parent__c = (parent != null ? parent.Id : null), Type__c = type, Name = name, Caption__c = caption, Position__c = position);
    }
    static void createCascadingSelectLevels(String cSId, Integer levels){
        String controlling;
        for(Integer i = 1 ; i <= levels ; i++){
            CascadingLevel__c cL = new CascadingLevel__c(Position__c = i, CascadingSelect__c = cSId);
            insert cL;
            if(i != 1){
                cL.ControllingLevel__c = controlling;
                update cL;
            }
            controlling = cL.Id;
        }
    }
}