/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
 @isTest
private class XFormCreatorTest {
    /*Constants*/
    //class to keep the most used nodes in the xml
    public class XFormNodes{
        public dom.document document;
        public dom.xmlnode xmlRoot;
        public dom.xmlnode xmlBody;
        public dom.xmlnode xmlModel;
        public dom.xmlnode xmlData;
    }

    public static XFormNodes createCleanXForm(String SurveyId){
        //dom Xml generation
        XFormNodes XFormResult= new XFormNodes();

        dom.Document doc = new dom.Document();
        XFormResult.document = doc;
        dom.Xmlnode xmlRoot = doc.createRootElement('h:html',null,null);
        XFormResult.xmlRoot = xmlRoot;
        xmlRoot.setNamespace('jr','http://openrosa.org/javarosa');
        xmlRoot.setNamespace('h','http://www.w3.org/1999/xhtml');
        dom.Xmlnode xmlHead = xmlRoot.addChildElement('h:head',null,null);
        xmlHead.addChildElement('h:title',null,null).addTextNode('name');
        dom.Xmlnode xmlModel = xmlHead.addChildElement('model',null,null);
        XFormResult.xmlModel = xmlModel;
        dom.Xmlnode xmlInstance = xmlModel.addChildElement('instance',null,null);
        dom.Xmlnode xmlData = xmlInstance.addChildElement('data',null,null);
        XFormResult.xmlData = xmlData;
        //here goes the model questions
        xmlData.setAttribute('id',SurveyId);
        XFormCreator.setHeaderModel(xmlData);
        XFormCreator.setHeaderBindings(xmlModel);
        //here go the bindings questions
        dom.Xmlnode xmlBody = xmlRoot.addChildElement('h:body',null,null);
        XFormResult.xmlBody = xmlBody;
        //here goes the question body
        dom.Xmlnode xmlStandardQuestions = XmlBody.addChildElement('group',null,null);
        xmlStandardQuestions.setAttribute('appearance','field-list');
        dom.Xmlnode xmlLocationInput = xmlStandardQuestions.addChildElement('input',null,null);
        xmlLocationInput.setAttribute('ref','/data/location');
        xmlLocationInput.setAttribute('appearance','maps');
        xmlLocationInput.addChildElement('label',null,null).addTextNode('GPS Location');
        xmlLocationInput.addChildElement('hint',null,null).addTextNode('This will capture your current location');
        return XFormResult;
    }

    //Static question generated for every survey
    public static void addSimpleInputQuestionBody(dom.xmlnode xmlBody,String path,String label,String questionHint){
        dom.Xmlnode xmlQuestion = xmlBody.addChildElement('input',null,null);
        xmlQuestion.setAttribute('ref',path);
        xmlQuestion.addChildElement('label',null,null).addTextNode(label);
        xmlQuestion.addChildElement('hint',null,null).addTextNode(questionHint);
    }
    public static void addSelectItem(dom.xmlnode xmlBody,String label,String value){
        dom.Xmlnode xmlQuestion = xmlBody.addChildElement('item',null,null);
        xmlQuestion.addChildElement('label',null,null).addTextNode(label);
        xmlQuestion.addChildElement('value',null,null).addTextNode(value);
    }
    public static void addBindingNode(dom.xmlnode xmlModel,String questionPath,String questionType,boolean required,String questionConstraints,String questionconstraintMsg,String relevants){
        dom.xmlNode xmlBindQuestion = xmlModel.addChildElement('bind',null,null);
        xmlBindQuestion.setAttribute('nodeset',questionPath);
        xmlBindQuestion.setAttribute('type',questionType);
        if (required){
            xmlBindQuestion.setAttribute('required','true()');
        }
        if(questionConstraints!=''){
            xmlBindQuestion.setAttribute('jr:constraint',questionConstraints);
            if (questionConstraintMsg!=''){
                   xmlBindQuestion.setAttribute('jr:constraintMsg',questionConstraintMsg);
            }
        }
        if (relevants!=''){
            xmlBindQuestion.setAttribute('relevant',relevants);
        }
    }

    private static Question__c standardQuestion(String name,Id survey,Id parent){
        Question__c question = new Question__c(
            Caption__c ='How old are you?',
            Hint__c = 'Tell me Your age',
            Survey__c = survey,
            Type__c = QuestionDO.TYPE_TEXT_SHORT,
            Parent__c = parent
        );
        return question;
    }

    // Helper method to create skip conditions cases
    // Will be used by testSkipConditionFormation
    private static void newConditionCase(Question__c section, String questionName, Integer questionPosition,
            Question__c sourceQuestion, String condition, String value, Boolean negate,List<Question__c> questions,List<SkipCondition__c> conditions, String questionType){
            Question__c targetQuestion = new Question__c(
            Survey__c = section.Survey__c,
            Parent__c = section.Id,
            Name = questionName,
            Caption__c = questionName,
            Position__c = questionPosition,
            Type__c = questionType);
        questions.add(targetQuestion);

        SkipCondition__c skipCondition = new SkipCondition__c(
            Parent__c = targetQuestion.Id,
            SourceQuestion__c = sourceQuestion.Id,
            Condition__c = condition,
            SkipValue__c = value,
            Negate__c = negate);
        conditions.add(skipCondition);
    }

    /**
     * Auxiliary method to test skip conditions on sections (simple section, repeated, etc)
     * @param typeSection type of the section to create
     */
    static void testSkipConditionAux(String typeSection){
           // Set up the test survey
        //-----------------------
        Survey__c survey = new Survey__c(Name='name'); insert survey;

        SurveyVersion__c ver =[SELECT Id,Status__c,Survey__c,Survey__r.Name,Survey__r.Alias__c, Survey__r.Id,Survey__r.Close_Message__c,Survey__r.CreatedDate,Survey__r.Gps_Location_Enabled__c,Survey__r.Gps_ShowMap__c FROM SurveyVersion__c WHERE Survey__c= :survey.Id];

        Question__c section = new Question__c(Survey__c=survey.Id,Name='s',Caption__c='s',Type__c=QuestionDO.TYPE_SECTION,Position__c=1);
        insert section;

        Integer pos = 1;
        // Question used as base for conditions
        Question__c sq = new Question__c(Survey__c=survey.Id,Name='sq',Caption__c='sq',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++);

        // No conditions
        Question__c q01 = new Question__c(Survey__c=survey.Id,Name='q01',Caption__c='q01',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Show',SkipLogicOperator__c='All');
        Question__c q02 = new Question__c(Survey__c=survey.Id,Name='q02',Caption__c='q02',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Show',SkipLogicOperator__c='Any');
        Question__c q03 = new Question__c(Survey__c=survey.Id,Name='q03',Caption__c='q03',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Hide',SkipLogicOperator__c='All');
        Question__c q04 = new Question__c(Survey__c=survey.Id,Name='q04',Caption__c='q04',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Hide',SkipLogicOperator__c='Any');

        // One condition
        Question__c q11 = new Question__c(Survey__c=survey.Id,Name='q11',Caption__c='q11',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Show',SkipLogicOperator__c='All');
        Question__c q12 = new Question__c(Survey__c=survey.Id,Name='q12',Caption__c='q12',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Show',SkipLogicOperator__c='Any');
        Question__c q13 = new Question__c(Survey__c=survey.Id,Name='q13',Caption__c='q13',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Hide',SkipLogicOperator__c='All');
        Question__c q14 = new Question__c(Survey__c=survey.Id,Name='q14',Caption__c='q14',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Hide',SkipLogicOperator__c='Any');

        // Two conditions
        Question__c q21 = new Question__c(Survey__c=survey.Id,Name='q21',Caption__c='q21',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Show',SkipLogicOperator__c='All');
        Question__c q22= new Question__c(Survey__c=survey.Id,Name='q22',Caption__c='q22',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Show',SkipLogicOperator__c='Any');
        Question__c q23= new Question__c(Survey__c=survey.Id,Name='q23',Caption__c='q23',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Hide',SkipLogicOperator__c='All');
        Question__c q24= new Question__c(Survey__c=survey.Id,Name='q24',Caption__c='q24',Type__c=QuestionDO.TYPE_TEXT_LONG,Parent__c=section.Id,Position__c=pos++,SkipLogicBehavior__c='Hide',SkipLogicOperator__c='Any');

        insert new Question__c[]{sq,q01,q02,q03,q04,q11,q12,q13,q14,q21,q22,q23,q24};

        addConditions(q11,sq,1);
        addConditions(q12,sq,1);
        addConditions(q13,sq,1);
        addConditions(q14,sq,1);
        addConditions(q21,sq,2);
        addConditions(q22,sq,2);
        addConditions(q23,sq,2);
        addConditions(q24,sq,2);

        // Assert conditions are correctly generated
        //------------------------------------------
        final String COND = '/data/s/sq!=\'\''; // all individual conditions will be the same: sq is answered
        Map<String,String> expectedRelevants = new Map<String,String>{
            'q01' => null,
            'q02' => null,
            'q03' => null,
            'q04' => null,
            'q11' => '(' + COND + ')',
            'q12' => '(' + COND + ')',
            'q13' => 'not(' + COND + ')',
            'q14' => 'not(' + COND + ')',
            'q21' => '(' + COND + ' and ' + COND + ')',
            'q22' => '(' + COND + ' or ' + COND + ')',
            'q23' => 'not(' + COND + ' and ' + COND + ')',
            'q24' => 'not(' + COND + ' or ' + COND + ')'
        };

        XFormCreator creator = new XFormCreator();
        dom.Document xform = creator.getXFormFromSurvey(ver,survey.name);

        dom.XmlNode root = xform.getRootElement();
        dom.XmlNode head = root.getChildElement('h:head',null);
        dom.XmlNode model = head.getChildElement('model',null);
        dom.XmlNode[] bindings = model.getChildren();
        for (dom.XmlNode child : bindings){
            if ('bind' != child.getName()) continue;

            String nodeset = child.getAttribute('nodeset',null);
            if (!nodeset.startsWith('/data/s/')) continue;

            String relevant = child.getAttribute('relevant',null);
            String key = nodeset.replace('/data/s/','');
            system.assertEquals(expectedRelevants.get(key), relevant, 'Nodeset: ' + nodeset);
        }

    }

    /**
     * Test different combinations of Show/Hide, All/Any, and zero, one or two conditions, on a repeated section
     */
    static testMethod void testSkipConditionOnRepeatedSection(){
        Test.startTest();
            testSkipConditionAux(QuestionDO.TYPE_REPEAT);
        Test.stopTest();
    }

    /**
     * Test different combinations of Show/Hide, All/Any, and zero, one or two conditions
     */
    static testMethod void testSkipConditionCombination(){
        Test.startTest();
            testSkipConditionAux(QuestionDO.TYPE_SECTION);
        Test.stopTest();
    }

    /**
     * Helper method for testSkipConditionCombination
     */
    private static void addConditions(
            Question__c target,
            Question__c source,
            Integer nrOfConditions
    ) {
        while (0 < nrOfConditions) {
            insert new SkipCondition__c(
                Parent__c = target.Id,
                SourceQuestion__c = source.Id,
                Condition__c = SkipConditionDO.CONDITION_ISANSWERED,
                SkipValue__c = null,
                Negate__c = false
            );
            nrOfConditions--;
        }
    }

   /**
    * Init a simple survey with a repeated section and a numer input previously in order to be referenced
    * @param showAllInOnePage whether to show or not all questions in one page for the repeated section
    * @return the new created survey
    **/
    private static Survey__c initRepeatPreviousValue(Boolean showAllInOnePage,Boolean withSKipLogic) {
        // Create base survey and first section
        Survey__c survey = new Survey__c(Name='nameSurvey',Gps_Location_Enabled__c=false);
        insert survey;


        Question__c sectionSimple = new Question__c(Name='sectionWInput',Caption__c ='sectionWInputCaption',
                Hint__c = 'sectionWithInput',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_SECTION,
                SamePage__c = false, Position__c=1);

        Question__c sectionRepeat = new Question__c(Name='sectionRepeat',Caption__c ='sectionRepeatCaption',
                Hint__c = 'sectionRepeatHint',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_REPEAT,
                SamePage__c = showAllInOnePage, Position__c=2);

        insert new Question__c[]{sectionSimple,sectionRepeat};

        //Create a repeat input in the first section
        Question__c qnumb = new Question__c(Survey__c=survey.Id,Name='numberOfRepeats',Caption__c='numberOfRepeatsCaption',
            Hint__c = 'numberOfRepeatsHint',
            Type__c=QuestionDO.TYPE_NUMBER_INTEGER ,
            Parent__c=sectionSimple.Id,Position__c=2);


        Question__c qtext1 = new Question__c(Survey__c=survey.Id,Name='someTextInput',Caption__c='someTextInput',
            Hint__c  = 'someTextInput',
            Type__c  = QuestionDO.TYPE_TEXT_SHORT ,
            Parent__c= sectionSimple.Id,Position__c=1);

        // Create some different type questions
        Question__c qsing = new Question__c(Survey__c=survey.Id,Name='radioName' ,Caption__c='radioCaption' , Hint__c = 'radioHint',
            Type__c=QuestionDO.TYPE_RADIO ,Parent__c=sectionRepeat.Id,Position__c=1);

        Question__c qtext = new Question__c(Survey__c=survey.Id,Name='textName'  ,Caption__c='textCaption' , Hint__c = 'textHint',
            Type__c=QuestionDO.TYPE_TEXT_SHORT,Parent__c=sectionRepeat.Id,Position__c=2);


        insert new Question__c[]{qtext1, qsing, qnumb, qtext};

        if (withSKipLogic) {
            addConditions(sectionRepeat,qtext1,1);
        }



        Option__c option = new Option__c(Name='a',Caption__c='a',Question__c=qsing.Id,Position__c=1);
        insert option;


        // Set the numeric question as a source for the repeated section.
        sectionRepeat.RepeatSourceValue__c =  qnumb.Id;
        update sectionRepeat;

        return survey;
    }

   /**
    * Init a simple survey with a repeated section and some questions
    * @param showAllInOnePage whether to show or not all questions in one page for the repeated section
    * @return the new created survey
    **/
    private static Survey__c initSimpleRepeated(Boolean showAllInOnePage) {

        // Create base survey and first section
        Survey__c survey = new Survey__c(Name='nameSurvey',Gps_Location_Enabled__c=false);
        insert survey;

        Question__c section = new Question__c(Name='sectionName',Caption__c ='sectionCaption',
                Hint__c = 'sectionHint',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_REPEAT,
                SamePage__c = showAllInOnePage);

        insert section;
        system.assertEquals(QuestionDO.TYPE_REPEAT,section.Type__c);
        // Create some different type questions to use as source for different conditions
        Question__c qsing = new Question__c(Survey__c=survey.Id,Name='radioName' ,Caption__c='radioCaption' , Hint__c = 'radioHint',
            Type__c=QuestionDO.TYPE_RADIO,Parent__c=section.Id,Position__c=1);

        Question__c qnumb = new Question__c(Survey__c=survey.Id,Name='numberName',Caption__c='numberCaption', Hint__c = 'numberHint',
            Type__c=QuestionDO.TYPE_NUMBER,Parent__c=section.Id,Position__c=2);

        Question__c qtext = new Question__c(Survey__c=survey.Id,Name='textName'  ,Caption__c='textCaption' , Hint__c = 'textHint',
            Type__c=QuestionDO.TYPE_TEXT_SHORT,Parent__c=section.Id,Position__c=3);
        insert new Question__c[]{qsing, qnumb, qtext};

        Option__c option = new Option__c(Name='a',Caption__c='a',Question__c=qsing.Id,Position__c=1);
        insert option;

        return survey;
    }

   /**
    * Test the xform generation with a simple survey with a repeated section and some questions
    **/
    static testMethod void testRepeatedSectionsXForm(){
        //INITIALIZE TEST
        Survey__c survey = initSimpleRepeated(false);
        SurveyVersion__c ver = [SELECT Id,Status__c,Survey__c,Survey__r.Name,Survey__r.Alias__c, Survey__r.Id,Survey__r.Close_Message__c,Survey__r.CreatedDate,Survey__r.Gps_Location_Enabled__c,Survey__r.Gps_ShowMap__c FROM SurveyVersion__c WHERE Survey__c= :survey.Id];

        //START TEST
        Test.startTest();
            XFormCreator creator = new XFormCreator();
            dom.Document xform = creator.getXFormFromSurvey(ver,survey.name);

            system.assert(xform.toXmlString().length() > 0);

            dom.XmlNode root = xform.getRootElement();
            dom.XmlNode body = root.getChildElement('h:body',null);

            dom.XmlNode[] groups = body.getChildren();
        Test.stopTest();
        system.assert(groups.size()>0,'There must be a group tag in the body section');

        for (dom.XmlNode g : groups){

            if (g.getName() != 'group') continue;

            dom.XmlNode repeat = g.getChildElement('repeat',null);

            system.assert(repeat!=null,'There must be one repeat section within the group');

            String labelGroup = g.getChildElement('label',null).getText();
            system.assertEquals('sectionCaption',labelGroup);

            String nodeset =repeat.getAttribute('nodeset',null);

            if(nodeset != null && nodeset.startsWith('/data/sectionName')) { /// check the repeated section is in the correct group
              dom.XmlNode[] repeatedQuestions = repeat.getChildElements();
              system.assert(repeatedQuestions.size() >0,'');

                //verify questions are correctly formed

                dom.Xmlnode node1 = repeatedQuestions[0];
                dom.Xmlnode node2 = repeatedQuestions[1];
                dom.Xmlnode node3 = repeatedQuestions[2];

                system.assertEquals('select1',node1.getName());
                system.assertEquals('input',node2.getName());
                system.assertEquals('input',node3.getName());

                system.assertEquals('/data/sectionName/radioName',node1.getAttribute('ref',null));
                system.assertEquals('radioCaption',node1.getChildElement('label',null).getText());
                system.assertEquals('radioHint',node1.getChildElement('hint',null).getText());

                system.assertEquals('/data/sectionName/numberName',node2.getAttribute('ref',null));
                system.assertEquals('numberCaption',node2.getChildElement('label',null).getText());
                system.assertEquals('numberHint',node2.getChildElement('hint',null).getText());

                system.assertEquals('/data/sectionName/textName',node3.getAttribute('ref',null));
                system.assertEquals('textCaption',node3.getChildElement('label',null).getText());
                system.assertEquals('textHint',node3.getChildElement('hint',null).getText());

            }
            else system.assert(false,'The attribute nodeset of repeat section is incorrect');
        }

    }


   /**
    * Auxiliary method to test repeated section based on the value of a previous question
    * @param showAllInOnePage whether to show or not all questions in one page for the repeated section
    **/
    static void testRepeatedBasedOnPrevValAux(Boolean showAllInOnePage,Boolean withSKipLogic){
        //INITIALIZE TEST
        Survey__c survey = initRepeatPreviousValue(showAllInOnePage,withSKipLogic);
        SurveyVersion__c ver = [SELECT Id,Status__c,Survey__c,Survey__r.Name,Survey__r.Alias__c, Survey__r.Id,
                                       Survey__r.Close_Message__c,Survey__r.CreatedDate,
                                       Survey__r.Gps_Location_Enabled__c,Survey__r.Gps_ShowMap__c
                                FROM SurveyVersion__c
                                WHERE Survey__c= :survey.Id];

        //START TEST
        XFormCreator creator = new XFormCreator();
        dom.Document xform = creator.getXFormFromSurvey(ver,survey.name);

        dom.XmlNode root = xform.getRootElement();
        dom.XmlNode body = root.getChildElement('h:body',null);

        dom.XmlNode[] nodes = body.getChildren();

        for (dom.XmlNode n : nodes) {
            //if the node is not a group then we must keep searching
            if (n.getName() != 'group') continue;

            dom.XmlNode repeat = n.getChildElement('repeat',null);
            //check if we are in the repeat section
            if (repeat != null) {
                String labelGroup = n.getChildElement('label',null).getText();
                String nodeset =repeat.getAttribute('nodeset',null);

                if(nodeset != null && nodeset.startsWith('/data/sectionRepeat')) {
                   String jrNoAddRemove =repeat.getAttribute('jr:noAddRemove',null);
                   String jrCount =repeat.getAttribute('jr:count',null);

                   // this must be true() for the count value to work correctly
                   system.assertEquals(jrNoAddRemove,'true()');
                   // check the count value is referencing correctly the path to the number input
                   system.assertEquals(jrCount,'/data/sectionWInput/numberOfRepeats');

                }
            }
        }

        //verify the restriction of showing the repeated section only if related input has positive values
        dom.XmlNode head  = root.getChildElement('h:head',null);
        dom.XmlNode model = head.getChildElement('model',null);

        dom.XmlNode[] bindings = model.getChildren();

        for (dom.XmlNode child : bindings){
            if (child.getName() != 'bind') continue;
            String nodeset =child.getAttribute('nodeset',null);
            if( nodeset != null && nodeset == '/data/sectionRepeat' ){
                String relevant = child.getAttribute('relevant',null);

                if (withSKipLogic) {
                    system.assertEquals(
                        '(/data/sectionWInput/someTextInput!=\'\') and /data/sectionWInput/numberOfRepeats > 0'
                        ,relevant);
                }
                else
                 system.assertEquals('/data/sectionWInput/numberOfRepeats > 0',relevant);
            }
        }



    }



   /**
    * Test the xform generation for repeated section based on the value of a previous question of numeric type
    * with skip logic associated
    **/
    static testMethod void testRepeatedBasedOnPreviousValueSkipLogic(){
        Test.startTest();
            testRepeatedBasedOnPrevValAux(false,true);
        Test.stopTest();
    }
   /**
    * Test the xform generation for repeated section based on the value of a previous question of numeric type
    **/
    static testMethod void testRepeatedBasedOnPreviousValue(){
        Test.startTest();
            testRepeatedBasedOnPrevValAux(false,false);
        Test.stopTest();
    }


   /**
    * Test the xform generation for repeated section based on the value of a previous question of numeric type
    * Showing all repeated questions in one page
    **/
    static testMethod void testRepBasedOnPrevValShowAllInOnePage(){
        Test.startTest();
            testRepeatedBasedOnPrevValAux(true,false);
        Test.stopTest();
    }

   /**
    * Test the xform generation with a simple survey with a repeated section and some questions showing all in one page
    **/
    static testMethod void testRepeatedSectionsXFormShowAllinOnePage(){
        //INITIALIZE TEST
        Survey__c survey = initSimpleRepeated(true);
        SurveyVersion__c ver = [SELECT Id,Status__c,Survey__c,Survey__r.Name,Survey__r.Alias__c, Survey__r.Id,Survey__r.Close_Message__c,Survey__r.CreatedDate,Survey__r.Gps_Location_Enabled__c,Survey__r.Gps_ShowMap__c FROM SurveyVersion__c WHERE Survey__c= :survey.Id];

        //START TEST
        Test.startTest();
            XFormCreator creator = new XFormCreator();
            dom.Document xform = creator.getXFormFromSurvey(ver,survey.name);

            system.assert(xform.toXmlString().length() > 0);

            dom.XmlNode root = xform.getRootElement();
            dom.XmlNode body = root.getChildElement('h:body',null);

            dom.XmlNode[] groups = body.getChildren();
        Test.stopTest();

        system.assert(groups.size()>0,'There must be a group tag in the body section');

        for (dom.XmlNode g : groups){

            if (g.getName() != 'group') continue;

            dom.XmlNode repeat = g.getChildElement('repeat',null);

            system.assert(repeat!=null,'There must be one repeat section within the group');

            String labelGroup = g.getChildElement('label',null).getText();
            system.assertEquals('sectionCaption',labelGroup);

            String nodeset =repeat.getAttribute('nodeset',null);

            if(nodeset != null && nodeset.startsWith('/data/sectionName')) { /// check the repeated section is in the correct group

              dom.XmlNode repeatInnerGroup = repeat.getChildElement('group',null);
              system.assert(repeatInnerGroup!=null,
                'There must be an inner group in the repeat tag since we are showing all questions in one page');

              dom.XmlNode[] repeatedQuestions = repeatInnerGroup.getChildElements();
              system.assert(repeatedQuestions.size() >0,'');

                //verify questions are correctly formed
                dom.Xmlnode node1 = repeatedQuestions[0];
                dom.Xmlnode node2 = repeatedQuestions[1];
                dom.Xmlnode node3 = repeatedQuestions[2];

                system.assertEquals('select1',node1.getName());
                system.assertEquals('input',node2.getName());
                system.assertEquals('input',node3.getName());

                system.assertEquals('/data/sectionName/radioName',node1.getAttribute('ref',null));
                system.assertEquals('radioCaption',node1.getChildElement('label',null).getText());
                system.assertEquals('radioHint',node1.getChildElement('hint',null).getText());

                system.assertEquals('/data/sectionName/numberName',node2.getAttribute('ref',null));
                system.assertEquals('numberCaption',node2.getChildElement('label',null).getText());
                system.assertEquals('numberHint',node2.getChildElement('hint',null).getText());

                system.assertEquals('/data/sectionName/textName',node3.getAttribute('ref',null));
                system.assertEquals('textCaption',node3.getChildElement('label',null).getText());
                system.assertEquals('textHint',node3.getChildElement('hint',null).getText());

            }
            else system.assert(false,'The attribute nodeset of repeat section is incorrect');
        }

    }

    // Test that skip conditions are correctly formated for each type of target question
    static testMethod void testSkipConditionFormation_Text  (){ testSkipConditionFormation(QuestionDO.TYPE_TEXT_SHORT); }
    static testMethod void testSkipConditionFormation_Number(){ testSkipConditionFormation(QuestionDO.TYPE_NUMBER_INTEGER); }
    static testMethod void testSkipConditionFormation_Date  (){ testSkipConditionFormation(QuestionDO.TYPE_DATE); }
    static testMethod void testSkipConditionFormation_Single(){ testSkipConditionFormation(QuestionDO.TYPE_RADIO); }
    static testMethod void testSkipConditionFormation_Multi (){ testSkipConditionFormation(QuestionDO.TYPE_CHECKBOX); }
    static testMethod void testSkipConditionFormation_Static(){ testSkipConditionFormation(QuestionDO.TYPE_STATIC); }

    static void testSkipConditionFormation(String targetQuestionType){

        // Create base survey and first section
        Survey__c survey = new Survey__c(Name='name',Gps_Location_Enabled__c=true);
        insert survey;
        SurveyVersion__c ver =[SELECT Id,Status__c,Survey__c,Survey__r.Name,Survey__r.Alias__c, Survey__r.Id,Survey__r.Close_Message__c,Survey__r.CreatedDate,Survey__r.Gps_Location_Enabled__c,Survey__r.Gps_ShowMap__c FROM SurveyVersion__c WHERE Survey__c= :survey.Id];
        Question__c section = new Question__c(Name='s',Caption__c ='s',
                Hint__c = 's',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_SECTION);

        insert section;

        // Create some different type questions to use as source for different conditions
        Question__c qsing = new Question__c(Survey__c=survey.Id,Name='radio' ,Caption__c='radio' ,Type__c=QuestionDO.TYPE_RADIO     ,Parent__c=section.Id,Position__c=1);
        Question__c qnumb = new Question__c(Survey__c=survey.Id,Name='number',Caption__c='number',Type__c=QuestionDO.TYPE_NUMBER    ,Parent__c=section.Id,Position__c=2);
        Question__c qtext = new Question__c(Survey__c=survey.Id,Name='text'  ,Caption__c='text'  ,Type__c=QuestionDO.TYPE_TEXT_SHORT,Parent__c=section.Id,Position__c=3);
        insert new Question__c[]{qsing, qnumb, qtext};

        Option__c option = new Option__c(Name='a',Caption__c='a',Question__c=qsing.Id,Position__c=1);
        insert option;

        // Create a section that will hold all test questions
        Question__c ts = new Question__c(Survey__c=survey.Id,Name='t',Caption__c='t',Position__c=2,Type__c=QuestionDO.TYPE_SECTION);
        insert ts;

        Integer pos = 1; // positions to assign to test questions

        //List of the objects to insert
        List<Question__c> questions = new List<Question__c>();
        List<SkipCondition__c> conditions = new List<SkipCondition__c>();
        // From radio questions
        newConditionCase(ts,'radio1',pos++,qsing,SkipConditionDO.CONDITION_EQUAL, String.valueOf(option.Id), false,questions,conditions, targetQuestionType);
        newConditionCase(ts,'radio2',pos++,qsing,SkipConditionDO.CONDITION_EQUAL, String.valueOf(option.Id), true,questions,conditions, targetQuestionType);
        newConditionCase(ts,'radio3',pos++,qsing,SkipConditionDO.CONDITION_ISANSWERED, '', false,questions,conditions, targetQuestionType);
        newConditionCase(ts,'radio4',pos++,qsing,SkipConditionDO.CONDITION_ISANSWERED, '', true,questions,conditions, targetQuestionType);

        // From number questions;
        newConditionCase(ts,'number1',pos++,qnumb,SkipConditionDO.CONDITION_EQUAL, '9', false,questions,conditions, targetQuestionType);
        newConditionCase(ts,'number2',pos++,qnumb,SkipConditionDO.CONDITION_EQUAL, '9', true,questions,conditions, targetQuestionType);
        newConditionCase(ts,'number3',pos++,qnumb,SkipConditionDO.CONDITION_GREATER, '9', false,questions,conditions, targetQuestionType);
        newConditionCase(ts,'number4',pos++,qnumb,SkipConditionDO.CONDITION_GREATER, '9', true,questions,conditions, targetQuestionType);
        newConditionCase(ts,'number5',pos++,qnumb,SkipConditionDO.CONDITION_LESSER, '9', false,questions,conditions, targetQuestionType);
        newConditionCase(ts,'number6',pos++,qnumb,SkipConditionDO.CONDITION_LESSER, '9', true,questions,conditions, targetQuestionType);
        newConditionCase(ts,'number7',pos++,qnumb,SkipConditionDO.CONDITION_ISANSWERED, '', false,questions,conditions, targetQuestionType);
        newConditionCase(ts,'number8',pos++,qnumb,SkipConditionDO.CONDITION_ISANSWERED, '', true,questions,conditions, targetQuestionType);

        // From text questions;
        newConditionCase(ts,'text1',pos++,qtext,SkipConditionDO.CONDITION_EQUAL, 'test', false,questions,conditions, targetQuestionType);
        newConditionCase(ts,'text2',pos++,qtext,SkipConditionDO.CONDITION_EQUAL, 'test', true,questions,conditions, targetQuestionType);
        newConditionCase(ts,'text3',pos++,qtext,SkipConditionDO.CONDITION_ISANSWERED, '', false,questions,conditions, targetQuestionType);
        newConditionCase(ts,'text4',pos++,qtext,SkipConditionDO.CONDITION_ISANSWERED, '', true,questions,conditions, targetQuestionType);
        insert questions;
        Integer i=0;
        for (SkipCondition__c sk:conditions){
            sk.Parent__c=questions[i].Id;
            i++;
        }
        insert conditions;
        Map<String,String> expectedRelevants = new Map<String,String>{
            '/data/t/radio1' => '(selected(/data/s/radio,\'' + option.Id + '\'))',
            '/data/t/radio2' => '(not(selected(/data/s/radio,\'' + option.Id + '\')))',
            '/data/t/radio3' => '(/data/s/radio!=\'\')',
            '/data/t/radio4' => '(/data/s/radio=\'\')',

            '/data/t/number1' => '(/data/s/number=9)',
            '/data/t/number2' => '(/data/s/number!=9)',
            '/data/t/number3' => '(/data/s/number>9)',
            '/data/t/number4' => '(/data/s/number<=9)',
            '/data/t/number5' => '(/data/s/number<9)',
            '/data/t/number6' => '(/data/s/number>=9)',
            '/data/t/number7' => '(/data/s/number!=\'\')',
            '/data/t/number8' => '(/data/s/number=\'\')',

            '/data/t/text1' => '(/data/s/text=\'test\')',
            '/data/t/text2' => '(/data/s/text!=\'test\')',
            '/data/t/text3' => '(/data/s/text!=\'\')',
            '/data/t/text4' => '(/data/s/text=\'\')'
        };

        XFormCreator creator = new XFormCreator();
        dom.Document xform = creator.getXFormFromSurvey(ver,survey.name);

        dom.XmlNode root = xform.getRootElement();
        dom.XmlNode head = root.getChildElement('h:head',null);
        dom.XmlNode model = head.getChildElement('model',null);
        dom.XmlNode[] bindings = model.getChildren();

        // Check that the relevants for static questions are the expected ones
        dom.XmlNode bindstat = null;
        for (dom.XmlNode child : bindings){
            if (child.getName() != 'bind') continue;
            String nodeset =child.getAttribute('nodeset',null);
            if( nodeset != null && nodeset.startsWith('/data/t/') ){
                String relevant = child.getAttribute('relevant',null);
                system.assertEquals( expectedRelevants.get(nodeset), relevant );
            }
        }
    }

    // Helper class to ensure that correct attributes have been set for each binding element.
    class Binding{
        String type;
        String jrPreload;
        String jrPreloadParams;
        String required;
        String readOnly;
        String jrConstraint;
        String jrConstraintMsg;
        public Binding(String type,String jrPreload,String jrPreloadParams,String required,String readOnly,String jrConstraint,String jrConstraintMsg){
            this.type = type;
            this.jrPreload = jrPreload;
            this.jrPreloadParams = jrPreloadParams;
            this.required = required;
            this.readOnly = readOnly;
            this.jrConstraint = jrConstraint;
            this.jrConstraintMsg = jrConstraintMsg;
        }
    }

    /**
    * Validate the range for question number
    * <p>
    * Thousandths of a number should not be separated
    * Create a survey with a number question and assign a valid range.
    */
    static testMethod void testMinMaxRangeInNumberQuestion(){

        //create a suervey
        Survey__c survey = new Survey__c(Name='name',Gps_Location_Enabled__c=true, Close_Message__c = null);
        insert survey;

        SurveyVersion__c ver = [SELECT Id, Status__c, Survey__c, Survey__r.Name,
                                    Survey__r.Alias__c, Survey__r.Id,
                                    Survey__r.Close_Message__c, Survey__r.CreatedDate,
                                    Survey__r.Gps_Location_Enabled__c, Survey__r.Gps_ShowMap__c
                                FROM SurveyVersion__c
                                WHERE Survey__c= :survey.Id];

        // Create a section
        Question__c sectionQuestion = new Question__c(Caption__c ='Section 1',
                Hint__c = 'sectionTest',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_SECTION,Name='SectionOne');

        insert sectionQuestion;

        sectionQuestion = [SELECT Name,Hint__c,Caption__c FROM Question__c WHERE Id=:sectionQuestion.Id];

        //create a question to insert number (integer or decimal)
        Question__c questionSource = standardQuestion('question', survey.Id,sectionQuestion.Id);
        questionSource.Required__c = true;
        questionSource.Name= 'questionSource';
        questionSource.Position__c=1;

        Question__c questionNumberSource = new Question__c(Caption__c ='Number With Max and Min',
                    Hint__c = 'between 0 and 100000.5',Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,Minimum__c=0,Maximum__c=100000.5,
                    Type__c = QuestionDO.TYPE_NUMBER,Required__c=true,
                    Name='numberQuestion',Position__c=2);

        List<Question__c> questions = new List<Question__c>{questionSource,questionNumberSource};

        insert questions;

        Test.startTest();
            //generate XForm for ODK
            XFormCreator x = new XFormCreator();
            dom.document xform = x.getXFormFromSurvey(ver,survey.name);

            DOM.XMLNode root=xform.getRootElement();

            DOM.XMLNode model=root.getChildElement('h:head', null).getChildElement('model', null);
        Test.stopTest();

        //verify the range is valid
        for (DOM.XMLNode node: model.getChildElements()){

            if (node.getName()=='bind' &&
                node.getAttribute('nodeset', null)=='/data/SectionOne/numberQuestion'){

                String contraint=node.getAttribute('jr:constraint', null);
                String constraintMsg=node.getAttribute('jr:constraintMsg', null);

                System.assertEquals('(.>=0 and .<=100000.5)', contraint, 'The contraint must be (.<=0 and .>=100000.5)');
                System.assertEquals('Must be between 0 and 100000.5.', constraintMsg, 'Must be between 0 and 100000.5.');
            }
        }
    }

    static  testMethod void testSkipConditionGeneration() {
        final String CLOSE_MESSAGE = 'close</closemessage> &a'; // try to break the xml

        //PREPARING THE TEST
        Survey__c survey = new Survey__c(Name='name',Gps_Location_Enabled__c=true, Close_Message__c = CLOSE_MESSAGE);
        insert survey;
        SurveyVersion__c ver =[SELECT Id,Status__c,Survey__c,Survey__r.Name,Survey__r.Alias__c, Survey__r.Id,Survey__r.Close_Message__c,Survey__r.CreatedDate,Survey__r.Gps_Location_Enabled__c,Survey__r.Gps_ShowMap__c FROM SurveyVersion__c WHERE Survey__c= :survey.Id];
        Question__c sectionQuestion = new Question__c(Caption__c ='Section 1',
                Hint__c = 'sectionTest',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_SECTION,Name='SectionOne');

        insert sectionQuestion;

        sectionQuestion = [select Name,Hint__c,Caption__c from Question__c where Id=:sectionQuestion.Id];
        Question__c questionSource = standardQuestion('question', survey.Id,sectionQuestion.Id);
        questionSource.Required__c = true;
        questionSource.Name= 'questionSource';
        questionSource.Position__c=1;
        Question__c dateQuestion = new Question__c(Caption__c ='date',
                    Hint__c = 'a datetime',Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,
                    Type__c = QuestionDO.TYPE_DATE,Position__c=2,Name='dateQuestion');
        Question__c questionNumberSource = new Question__c(Caption__c ='Number With Max and Min',
                    Hint__c = 'between 0 and 10',Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,Minimum__c=0,Maximum__c=10,
                    Type__c = QuestionDO.TYPE_NUMBER,Required__c=true,
                    Name='numberQuestion',Position__c=3);
        Question__c checkboxQuestion = new Question__c(Caption__c ='select options',
                    Hint__c = 'select an option',Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,
                    Type__c = QuestionDO.TYPE_CHECKBOX,Required__c=false,
                    Name='checkboxQuestion',Position__c=4);
        Question__c radioQuestion = new Question__c(Caption__c ='select one option',
                    Hint__c = 'select an option',Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,Required__c=true,
                    Type__c = QuestionDO.TYPE_RADIO,
                    SkipLogicOperator__c='Any',
                    SkipLogicBehavior__c='Hide',
                    Name='radioQuestion',Position__c=5);
        Question__c questionParent = standardQuestion('question', survey.Id,sectionQuestion.Id);
        questionParent.Required__c = true;
        questionParent.Name= 'questionParent';
        questionParent.Position__c=6;
        Question__c longQuestion = new Question__c(Caption__c ='MultiText',
                    Hint__c = 'a hint',Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,
                    Type__c = QuestionDO.TYPE_TEXT_LONG,Position__c=8,Name='longQuestion');
        Question__c dateTimeQuestion = new Question__c(Caption__c ='dateTime',
                    Hint__c = 'a datetime',Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,
                    Type__c = QuestionDO.TYPE_DATETIME,Position__c=9,Name='dateTimeQuestion');
        Question__c maxNumberQuestion = new Question__c(Caption__c ='Number With Max and no Min',
                    Hint__c = 'less than 5',Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,Maximum__c=5,
                    Type__c = QuestionDO.TYPE_NUMBER,Required__c=false,
                    Name='maxQuestion',Position__c=10);
        Question__c minNumberQuestion = new Question__c(Caption__c ='Number With Min and no Max',
                    Hint__c = 'more than 5',Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,Minimum__c=5,
                    Type__c = QuestionDO.TYPE_NUMBER,Required__c=false,
                    Name='minQuestion',Position__c=11);
        Question__c staticQuestion = new Question__c(Caption__c ='Static question',
                    Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,
                    Type__c = QuestionDO.TYPE_STATIC,
                    Name='static',Position__c=12);
        Question__c barcodeQuestion = new Question__c(Caption__c ='BarCode',
                    Hint__c = 'a hint',Parent__c = sectionQuestion.Id,
                    Survey__c = survey.Id,
                    Type__c = QuestionDO.TYPE_BARCODE,Position__c=13,Name='barcodeQuestion');
        List<Question__c> questions = new List<Question__c>{questionSource,dateQuestion,questionNumberSource,checkboxQuestion,radioQuestion,questionParent,longQuestion,dateTimeQuestion,maxNumberQuestion,minNumberQuestion,staticQuestion,barcodeQuestion};
        insert questions;
        Option__c opACheckBox= new Option__c(Name='option1',Caption__c='option1',Question__c=checkboxQuestion.Id,Position__c=1);
        Option__c opBCheckBox= new Option__c(Name='option2',Caption__c='option2',Question__c=checkboxQuestion.Id,Position__c=2);
        Option__c opCCheckBox= new Option__c(Name='option3',Caption__c='option3',Question__c=checkboxQuestion.Id,Position__c=3);
        Option__c opARadio= new Option__c(Name='option1',Caption__c='option1',Question__c =radioQuestion.Id,Position__c=1);
        Option__c opBRadio= new Option__c(Name='option2',Caption__c='option2',Question__c=radioQuestion.Id,Position__c=2);
        Option__c opCRadio= new Option__c(Name='option3',Caption__c='option3',Question__c=radioQuestion.Id,Position__c=3);

        List<Option__c> options = new List<Option__c>{opACheckBox,opBCheckBox,opCCheckBox,opARadio,opBRadio,opCRadio};
        insert options;

        Test.startTest();
            //PERFORMING THE TEST
            XFormCreator x = new XFormCreator();
            dom.document xform = x.getXFormFromSurvey(ver,survey.name);

            dom.XmlNode root = xform.getRootElement();
            dom.XmlNode head = root.getChildElement('h:head',null);

            // Assert title is there and is right
            dom.XmlNode title = head.getChildElement('h:title',null);
            system.assertEquals('name',title.getText());

            dom.XmlNode model = head.getChildElement('model',null);
            dom.XmlNode instance = model.getChildElement('instance',null);
            dom.XmlNode data = instance.getChildElement('data',null);
        Test.stopTest();

        // Assert model is there, and data node contains all first level children
        String[] expectedDataChildren = new String[]{
            'start','end','today','deviceid','simid',
            'phonenumber','SectionOne','closemessage'};
        dom.XmlNode[] dataChildren = data.getChildElements();
        Integer i=0;
        for(dom.XmlNode child : dataChildren)
            system.assertEquals(expectedDataChildren[i++], child.getName());

        // Assert section one contains all questions it's supposed to contain
        String[] expectedSectionOneChildren = new String[]{
            'questionSource','dateQuestion','numberQuestion','checkboxQuestion',
            'radioQuestion','questionParent','longQuestion','dateTimeQuestion',
            'maxQuestion','minQuestion','static','barcodeQuestion'};
        dom.XmlNode sectionOne = data.getChildElement('SectionOne',null);
        dom.XmlNode[] sectionOneChildren = sectionOne.getChildElements();
        i=0;
        for(dom.XmlNode child : sectionOneChildren)
            system.assertEquals(expectedSectionOneChildren[i++], child.getName());

        // Assert bindings are there
        Map<String,Binding> expectedBindings = new Map<String,Binding>{
            // 'nodeset' => new Binding(type, jrPreload, jrPreloadParams, required, readonly, jrConstraint, jrConstraintMsg),
            '/data/start' => new Binding('dateTime', 'timestamp', 'start', null, null, null, null),
            '/data/end' => new Binding('dateTime', 'timestamp', 'end', null, null, null, null),
            '/data/today' => new Binding('date', 'date', 'today', null, null, null, null),
            '/data/deviceid' => new Binding('string', 'property', 'devicesid', null, null, null, null),
            '/data/simid' => new Binding('string', 'property', 'simserial', null, null, null, null),
            '/data/phonenumber' => new Binding('string', 'property', 'phonenumber', null, null, null, null),
            '/data/SectionOne' => new Binding(null, null, null, null, null, null,null),
            '/data/SectionOne/questionSource' => new Binding('string', null, null, 'true()', null, 'regex(.,\'^[\\w\\W]{0,50}$\')', 'Invalid response: the response exceeds 50 characters.'),
            '/data/SectionOne/dateQuestion' => new Binding('date', null, null, null, null, null, null),
            '/data/SectionOne/numberQuestion' => new Binding('int', null, null, 'true()', null, '(.>=0 and .<=10)', 'Must be between 0 and 10.'),
            '/data/SectionOne/checkboxQuestion' => new Binding('select', null, null, null, null, null, null),
            '/data/SectionOne/radioQuestion' => new Binding('select1', null, null, 'true()', null, null, null),
            '/data/SectionOne/questionParent' => new Binding('string', null, null, 'true()', null, 'regex(.,\'^[\\w\\W]{0,50}$\')', 'Invalid response: the response exceeds 50 characters.'),
            '/data/SectionOne/longQuestion' => new Binding('string', null, null, null, null, null, null),
            '/data/SectionOne/dateTimeQuestion' => new Binding('dateTime', null, null, null, null, null, null),
            '/data/SectionOne/maxQuestion' => new Binding('int', null, null, null, null, '.<=5', 'Must not be greater than 5.'),
            '/data/SectionOne/minQuestion' => new Binding('int', null, null, null, null, '.>=5', 'Must not be lower than 5.'),
            '/data/SectionOne/static' => new Binding('string', null, null, null, 'true()', null, null),
            '/data/SectionOne/barcodeQuestion' => new Binding('barcode', null, null, null, null, null, null),
            '/data/closemessage' => new Binding('string', null, null, null, 'true()', null, null)
        };
        Integer nrOfBindsFound = 0;
        for(dom.XmlNode node : model.getChildElements()){
            if(node.getName() != 'bind') continue;
            nrOfBindsFound++;
            String nodeset = node.getAttribute('nodeset',null);
            Binding expected = expectedBindings.get(nodeset);
            System.assertEquals(expected.type, node.getAttribute('type',null), 'nodeset: ' + nodeset);
            System.assertEquals(expected.jrPreload, node.getAttribute('jr:preload',null), 'nodeset: ' + nodeset);
            System.assertEquals(expected.jrPreloadParams, node.getAttribute('jr:preloadParams',null), 'nodeset: ' + nodeset);
            System.assertEquals(expected.required, node.getAttribute('required',null), 'nodeset: ' + nodeset);
            System.assertEquals(expected.readonly, node.getAttribute('readonly',null), 'nodeset: ' + nodeset);
            System.assertEquals(expected.jrConstraint, node.getAttribute('jr:constraint',null), 'nodeset: ' + nodeset);
            System.assertEquals(expected.jrConstraintMsg, node.getAttribute('jr:constraintMsg',null), 'nodeset: ' + nodeset);
        }
        System.assertEquals(expectedBindings.keyset().size(), nrOfBindsFound);

        // Assert body exists and questions are on the right order and have the right text
        dom.XmlNode body = root.getChildElement('h:body',null);
        dom.XmlNode[] bodyChildren = body.getChildElements();
        System.assertEquals(2, bodyChildren.size()); // SectionOne, and close message.

        // Assert the close message is correctly generated
        System.assertEquals(CLOSE_MESSAGE, bodyChildren[1].getChildElement('hint',null).getText());
        System.assertEquals(null, bodyChildren[1].getChildElement('label',null));
    }

    static testMethod void testQuestionOrdering(){
        Survey__c survey = new Survey__c(Name='name', Close_Message__c=null); insert survey;

        // Insert questions and sections in a randomized order, but with a correct position set
        Question__c section1 = new Question__c(Survey__c=survey.Id,Name='s1',Caption__c='s1',Type__c=QuestionDO.TYPE_SECTION,Position__c=1);
        Question__c section2 = new Question__c(Survey__c=survey.Id,Name='s2',Caption__c='s2',Type__c=QuestionDO.TYPE_SECTION,Position__c=2);
        Question__c section3 = new Question__c(Survey__c=survey.Id,Name='s3',Caption__c='s3',Type__c=QuestionDO.TYPE_SECTION,Position__c=3);
        insert new Question__c[]{section1, section3, section2};

        Question__c q1 = new Question__c(Survey__c=survey.Id,Name='q1',Caption__c='q1',Type__c=QuestionDO.TYPE_TEXT_LONG,Position__c=1,Parent__c=section1.Id);
        Question__c q2 = new Question__c(Survey__c=survey.Id,Name='q2',Caption__c='q2',Type__c=QuestionDO.TYPE_TEXT_LONG,Position__c=2,Parent__c=section1.Id);
        Question__c q3 = new Question__c(Survey__c=survey.Id,Name='q3',Caption__c='q3',Type__c=QuestionDO.TYPE_TEXT_LONG,Position__c=3,Parent__c=section1.Id);
        Question__c q4 = new Question__c(Survey__c=survey.Id,Name='q4',Caption__c='q4',Type__c=QuestionDO.TYPE_TEXT_LONG,Position__c=4,Parent__c=section2.Id);
        Question__c q5 = new Question__c(Survey__c=survey.Id,Name='q5',Caption__c='q5',Type__c=QuestionDO.TYPE_TEXT_LONG,Position__c=5,Parent__c=section2.Id);
        Question__c q6 = new Question__c(Survey__c=survey.Id,Name='q6',Caption__c='q6',Type__c=QuestionDO.TYPE_TEXT_LONG,Position__c=6,Parent__c=section2.Id);
        Question__c q7 = new Question__c(Survey__c=survey.Id,Name='q7',Caption__c='q7',Type__c=QuestionDO.TYPE_TEXT_LONG,Position__c=7,Parent__c=section3.Id);
        Question__c q8 = new Question__c(Survey__c=survey.Id,Name='q8',Caption__c='q8',Type__c=QuestionDO.TYPE_TEXT_LONG,Position__c=8,Parent__c=section3.Id);
        Question__c q9 = new Question__c(Survey__c=survey.Id,Name='q9',Caption__c='q9',Type__c=QuestionDO.TYPE_TEXT_LONG,Position__c=9,Parent__c=section3.Id);
        insert new Question__c[]{q5,q2,q7,q1,q3,q8,q6,q9,q4};
        SurveyVersion__c ver =[SELECT Id,Status__c,Survey__c,Survey__r.Name,Survey__r.Alias__c, Survey__r.Id,Survey__r.Close_Message__c,Survey__r.CreatedDate,Survey__r.Gps_Location_Enabled__c,Survey__r.Gps_ShowMap__c FROM SurveyVersion__c WHERE Survey__c= :survey.Id];

        Test.startTest();
            XFormCreator creator = new XFormCreator();
            dom.Document xform = creator.getXFormFromSurvey(ver,survey.name);

            dom.XmlNode root = xform.getRootElement();
            dom.XmlNode body = root.getChildElement('h:body',null);
            dom.XmlNode[] sectionNodes = body.getChildElements();
        Test.stopTest();
        // Sections are elements 1 through 3
        System.assertEquals(3, sectionNodes.size());
        System.assertEquals('s1', sectionNodes[0].getChildElement('label',null).getText());
        System.assertEquals('s2', sectionNodes[1].getChildElement('label',null).getText());
        System.assertEquals('s3', sectionNodes[2].getChildElement('label',null).getText());

        // Assert questions are correctly ordered
        // Element 0 of each section is it's label
        System.assertEquals('q1', sectionNodes[0].getChildElements()[1].getChildElement('label',null).getText());
        System.assertEquals('q2', sectionNodes[0].getChildElements()[2].getChildElement('label',null).getText());
        System.assertEquals('q3', sectionNodes[0].getChildElements()[3].getChildElement('label',null).getText());
        System.assertEquals('q4', sectionNodes[1].getChildElements()[1].getChildElement('label',null).getText());
        System.assertEquals('q5', sectionNodes[1].getChildElements()[2].getChildElement('label',null).getText());
        System.assertEquals('q6', sectionNodes[1].getChildElements()[3].getChildElement('label',null).getText());
        System.assertEquals('q7', sectionNodes[2].getChildElements()[1].getChildElement('label',null).getText());
        System.assertEquals('q8', sectionNodes[2].getChildElements()[2].getChildElement('label',null).getText());
        System.assertEquals('q9', sectionNodes[2].getChildElements()[3].getChildElement('label',null).getText());
    }

    static testMethod void testListAllSurveys(){
    //PREPARING THE TEST
        Survey__c survey = new Survey__c(Name='__test__survey', Status__c = SurveyDO.STATUS_PUBLISHED);
        Survey__c survey2 = new Survey__c(Name = '__test__survey2', Status__c = SurveyDO.STATUS_PUBLISHED);
        insert new Survey__c[]{survey, survey2};
        survey  = [Select Name, Id From Survey__c WHERE Id = :survey.Id];
        survey2 = [Select Name, Id From Survey__c WHERE Id = :survey2.Id];
        SurveyVersion__c version = [SELECT Version__c,Id,Status__c,Survey__c,Survey__r.Name,Survey__r.Alias__c, Survey__r.Id,Survey__r.Close_Message__c,Survey__r.CreatedDate,Survey__r.Gps_Location_Enabled__c,Survey__r.Gps_ShowMap__c
                                    FROM SurveyVersion__c
                                    WHERE Survey__c = :survey.Id ORDER BY Version__c DESC LIMIT 1];
        version.Status__c = SurveyDO.STATUS_PUBLISHED;
        update version;
        final String ORIGIN_URL = 'http://www.demopage.com/';
        //Contact and Contact Group Data(to filter the surveys)
        Contact con = new Contact(LastName = 'Robert');
        insert con;
        ContactGroup__c conGroup = new ContactGroup__c(Name = '__test__Group1', Status__c = 'Active');
        insert conGroup;
        ContactGroupMember__c member = new ContactGroupMember__c(Contact__c = con.Id, ContactGroup__c = conGroup.Id);
        insert member;
        ContactGroupSurveyAssignment__c surveyAssignment = new ContactGroupSurveyAssignment__c(ContactGroup__c = conGroup.Id, Survey__c = survey.Id);
        insert surveyAssignment;

        Test.startTest();
            //PERFORMING THE TEST
            XFormCreator creator = new XFormCreator();
            dom.Document doc = creator.getXmlAllSurveys(ORIGIN_URL, con.Id);
            dom.XmlNode root = doc.getRootElement();
            dom.XmlNode xformNode = root.getChildElement('xform', null);
            dom.XmlNode formIdNode = xformNode.getChildElement('formID', null);
            dom.XmlNode nameNode = xformNode.getChildElement('name', null);
            dom.XmlNode versionNode = xformNode.getChildElement('version', null);
            dom.XmlNode downloadUrlNode = xformNode.getChildElement('downloadUrl', null);
        Test.stopTest();
        //ASSERTIONS
        System.assertEquals(version.id, formIdNode.getText());
        System.assertEquals(survey.Name, nameNode.getText());
        System.assertEquals(version.Version__c, Integer.valueOf(versionNode.getText()));
        System.assertEquals(Page.formList.getUrl() + '?id=' + version.Id, downloadUrlNode.getText());
    }

    /**
     * Test Listall surveys assign to a private contact.
     */
    static testMethod void testListAllSurveysPrivateContact(){
        //PREPARING THE TEST
        Survey__c survey = new Survey__c(Name='__test__survey', Status__c = SurveyDO.STATUS_PUBLISHED);
        Survey__c survey2 = new Survey__c(Name = '__test__survey2', Status__c = SurveyDO.STATUS_PUBLISHED);
        insert new Survey__c[]{survey, survey2};
        survey  = [Select Name, Id From Survey__c WHERE Id = :survey.Id];
        survey2 = [Select Name, Id From Survey__c WHERE Id = :survey2.Id];
        SurveyVersion__c version = [SELECT Id,Status__c, Version__c
                                    FROM SurveyVersion__c
                                    WHERE Survey__c = :survey.Id ORDER BY Version__c DESC LIMIT 1];
        version.Status__c = SurveyDO.STATUS_PUBLISHED;
        update version;
        final String ORIGIN_URL = 'http://www.demopage.com/';
        //Contact and Contact Group Data(to filter the surveys)
        Contact con = new Contact(LastName = 'Robert');
        insert con;
        ContactGroup__c conGroup = new ContactGroup__c(Name = '__test__Group1', Status__c = 'Active');
        insert conGroup;
        ContactGroupMember__c member = new ContactGroupMember__c(Contact__c = con.Id, ContactGroup__c = conGroup.Id);
        insert member;
        ContactGroupSurveyAssignment__c surveyAssignment = new ContactGroupSurveyAssignment__c(ContactGroup__c = conGroup.Id, Survey__c = survey.Id);
        insert surveyAssignment;

        //PERFORMING THE TEST
        //Event that i run all the test with a user which isnt able to see the private contact, Everything should work allright.
        system.runAs(TestUtils.generateTaroworksUser()){
            Test.startTest();
                XFormCreator creator = new XFormCreator();
                dom.Document doc = creator.getXmlAllSurveys(ORIGIN_URL, con.Id);
                dom.XmlNode root = doc.getRootElement();
                dom.XmlNode xformNode = root.getChildElement('xform', null);
                dom.XmlNode formIdNode = xformNode.getChildElement('formID', null);
                dom.XmlNode nameNode = xformNode.getChildElement('name', null);
                dom.XmlNode versionNode = xformNode.getChildElement('version', null);
                dom.XmlNode downloadUrlNode = xformNode.getChildElement('downloadUrl', null);
            Test.stopTest();
            //ASSERTIONS
            System.assertEquals(version.id, formIdNode.getText());
            System.assertEquals(survey.Name, nameNode.getText());
            System.assertEquals(version.Version__c, Integer.valueOf(versionNode.getText()));
            System.assertEquals(Page.formList.getUrl() + '?id=' + version.Id, downloadUrlNode.getText());
        }
    }


    // Test different combinations of the first page:with/without GPS
    static testMethod void testInitialSection() {
        Survey__c survey_00 = new Survey__c(
            Name = 's01',
            Status__c = SurveyDO.STATUS_DRAFT,
            Gps_Location_Enabled__c = false
        );

        List<Survey__c> surveys = new List<Survey__c>{ survey_00};
        insert surveys;
        List<SurveyVersion__c> versions = [
            SELECT
                Id,
                Status__c,
                Survey__c,
                Survey__r.Name,
                Survey__r.Alias__c,
                Survey__r.Id,
                Survey__r.Close_Message__c,
                Survey__r.CreatedDate,
                Survey__r.Gps_Location_Enabled__c,
                Survey__r.Gps_ShowMap__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c IN :surveys
            ORDER BY
                Survey__r.Name
        ];

        Test.startTest();
        XFormCreator x = new XFormCreator();
        dom.Document xform = null;
        dom.XmlNode body = null;
        dom.XmlNode groupNode = null;

        // No GPS: don't give me the group (it would be empty)
        xform = x.getXFormFromSurvey(versions[0],'s00');
        body = xform.getRootElement().getChildElement('h:body',null);
        System.assertEquals(0, body.getChildElements().size());
        Test.stopTest();
    }

    // Test field length is correctly generated for mapped short-text questions.
    static testMethod void testMappedFieldLength(){

        //create a simple survey with a question
        Survey__c survey = new Survey__c(Name='name', Gps_Location_Enabled__c=false, Close_Message__c=null);
        insert survey;

        Question__c section1 = new Question__c(Survey__c=survey.Id,Name='s1',Caption__c='s1',Type__c=QuestionDO.TYPE_SECTION,Position__c=1);
        insert section1;

        Question__c q1 = new Question__c(Survey__c=survey.Id,Name='q1',Caption__c='q1',Type__c=QuestionDO.TYPE_TEXT_SHORT,Position__c=1,Parent__c=section1.Id);
        Question__c q2 = new Question__c(Survey__c=survey.Id,Name='q2',Caption__c='q2',Type__c=QuestionDO.TYPE_TEXT_SHORT,Position__c=2,Parent__c=section1.Id);
        insert new List<Question__c>{q1,q2};

        SurveyMapping__c sm = new SurveyMapping__c(ObjectApiName__c = 'Account',Survey__c = survey.Id);
        SurveyMapping__c sm2 = new SurveyMapping__c(ObjectApiName__c = 'Account',Survey__c = survey.Id);
        insert new List<SurveyMapping__c>{sm,sm2};

        insert new List<QuestionMapping__c>{
            new QuestionMapping__c(FieldApiName__c='Name'         ,Question__c=q2.Id,SurveyMapping__c=sm.Id),
            new QuestionMapping__c(FieldApiName__c='Site'         ,Question__c=q1.Id,SurveyMapping__c=sm2.Id),
            new QuestionMapping__c(FieldApiName__c='AccountNumber',Question__c=q1.Id,SurveyMapping__c=sm.Id)
        };

        SurveyVersion__c ver =[SELECT Id,Status__c,Survey__c,Survey__r.Name,Survey__r.Alias__c, Survey__r.Id,Survey__r.Close_Message__c,Survey__r.CreatedDate,Survey__r.Gps_Location_Enabled__c,Survey__r.Gps_ShowMap__c FROM SurveyVersion__c WHERE Survey__c= :survey.Id];

        Test.startTest();
            //create xform of survey
            XFormCreator creator = new XFormCreator();
            dom.Document xform = creator.getXFormFromSurvey(ver,survey.name);

            dom.XmlNode root = xform.getRootElement();
            dom.XmlNode head = root.getChildElement('h:head',null);
            dom.XmlNode model = head.getChildElement('model',null);
            dom.XmlNode[] bindings = model.getChildren();
        Test.stopTest();
        //check bind of the interviewee question,must not be required
        integer nodeIndex = 0;
        boolean foundQuestion = false;
        while (!foundQuestion && nodeIndex<=bindings.size()){
            dom.XmlNode node = bindings[nodeIndex];
            if (node.getAttribute('nodeset',null)=='/data/s1/q1'){
                // the length is the minimum mapped field of the question in this case is the length of the account number = 40
                system.assertEquals('Invalid response: the response exceeds 40 characters.', node.getAttribute('jr:constraintMsg',null));
                system.assertEquals('regex(.,\'^[\\w\\W]{0,40}$\')', node.getAttribute('jr:constraint', null));
                foundQuestion= true;
            }
            nodeIndex++;
        }
        system.assert(foundQuestion = true);
    }

    /* Test to assert the correct  generation of the relevants,
     * in an xform with some finalize questions
     */
    static testMethod void testFinalizeQuestion(){

        // Create base survey with three sections and two finalize questions
        Survey__c survey = new Survey__c(Name='name',Gps_Location_Enabled__c=true);
        insert survey;
        SurveyVersion__c ver =[SELECT Id,
                                         Status__c,
                                         Survey__c,
                                         Survey__r.Name,
                                         Survey__r.Alias__c,
                                         Survey__r.Close_Message__c,
                                         Survey__r.CreatedDate,
                                         Survey__r.Gps_Location_Enabled__c
                                         ,Survey__r.Gps_ShowMap__c
                                         FROM SurveyVersion__c
                                         WHERE Survey__c= :survey.Id];
        Question__c section1 = new Question__c(Name='s1',Caption__c ='s1',
                Hint__c = 's1',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_SECTION,
                Position__c=1);
        Question__c section2 = new Question__c(Name='s2',Caption__c ='s2',
                Hint__c = 's2',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_SECTION,
                Position__c=2);
        Question__c section3 = new Question__c(Name='s3',Caption__c ='s3',
                Hint__c = 's3',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_SECTION,
                Position__c=3);

        insert new Question__c[]{section1,section2,section3};

        // Create some questions
        Question__c q1 = new Question__c(Survey__c=survey.Id,    Name='q1'    ,    Caption__c='text' ,    Type__c=QuestionDO.TYPE_TEXT_SHORT,    Parent__c=section1.Id,    Position__c=1);
        Question__c q2 = new Question__c(Survey__c=survey.Id,    Name='q2'    ,    Caption__c='radio',    Type__c=QuestionDO.TYPE_RADIO     ,    Parent__c=section1.Id,    Position__c=2);
        Question__c f1 = new Question__c(Survey__c=survey.Id,    Name='final1',    Caption__c='final',    Type__c=QuestionDO.TYPE_FINAL     ,    Parent__c=section1.Id,    Position__c=3);
        Question__c q3 = new Question__c(Survey__c=survey.Id,    Name='q3'    ,    Caption__c='text' ,    Type__c=QuestionDO.TYPE_TEXT_SHORT,    Parent__c=section2.Id,    Position__c=1);
        Question__c f2 = new Question__c(Survey__c=survey.Id,    Name='final2',    Caption__c='final',    Type__c=QuestionDO.TYPE_FINAL     ,    Parent__c=section2.Id,    Position__c=2);
        Question__c q4 = new Question__c(Survey__c=survey.Id,    Name='q4'    ,    Caption__c='radio',    Type__c=QuestionDO.TYPE_RADIO     ,    Parent__c=section2.Id,    Position__c=3);
        Question__c q5 = new Question__c(Survey__c=survey.Id,    Name='q5'    ,    Caption__c='text' ,    Type__c=QuestionDO.TYPE_TEXT_SHORT,    Parent__c=section3.Id,    Position__c=1);
        insert new Question__c[]{q1, q2,f1, q3,f2,q4,q5};

        Option__c option1 = new Option__c(Name='a',Caption__c='a',Question__c=q1.Id,Position__c=1);
        Option__c option2 = new Option__c(Name='a',Caption__c='a',Question__c=q4.Id,Position__c=1);
        insert new Option__c[]{option1,option2};
        Map<String,String> expectedRelevants = new Map<String,String>{
            '/data/s1/q1' => null,
            '/data/s1/q2' => null,
            '/data/s1/final1' => '(/data/s1/q1=\'b\')',
            '/data/s2/q3' => 'not(((/data/s1/q1=\'b\'))) and (/data/s1/q1!=\'a\')',
            '/data/s2/final2' => 'not(((/data/s1/q1=\'b\'))) and (/data/s2/q3=\'b\')',
            '/data/s2/q4' => 'not(((/data/s1/q1=\'b\')) or ((/data/s2/q3=\'b\')))',
            '/data/s3/q5' => 'not(((/data/s1/q1=\'b\')) or ((/data/s2/q3=\'b\'))) and (/data/s2/q3!=\'c\')',
            '/data/closemessage'  => '(not((/data/s1/q1=\'b\') or (/data/s2/q3=\'b\'))'


        };
        //create some conditions
        SkipCondition__c skipCondition1 = createCondition(q3,q1,'a',true);
        SkipCondition__c skipCondition2 = createCondition(q5,q3,'c',true);

        //assign the finzalize conditions for both finzalize questions
        SkipCondition__c skipConditionFinalize1 = createCondition(f1,q1,'b',false);
        SkipCondition__c skipConditionFinalize2 = createCondition(f2,q3,'b',false);
        insert new SkipCondition__c[]{skipCondition1,skipCondition2,skipConditionFinalize1,skipConditionFinalize2};

        Test.startTest();
            XFormCreator creator = new XFormCreator();
            dom.Document xform = creator.getXFormFromSurvey(ver,survey.name);

            dom.XmlNode root = xform.getRootElement();
            dom.XmlNode head = root.getChildElement('h:head',null);
            dom.XmlNode model = head.getChildElement('model',null);
            dom.XmlNode[] bindings = model.getChildren();
        Test.stopTest();
        //check bindings
        for (dom.XmlNode child : bindings){
            if ('bind' != child.getName()) continue;

            String nodeset = child.getAttribute('nodeset',null);
            String relevant = child.getAttribute('relevant',null);
            String key = nodeset;
            system.assertEquals(expectedRelevants.get(key), relevant, 'Nodeset: ' + nodeset);
        }

    }

     /**
     * Test to assert the correct  generation of the relevants,
     * in an xform with skip logics in sections questions
     **/
    static testMethod void testSectionConditions() {

        // Create base survey with three sections and logic for these sections
        Survey__c survey = new Survey__c(
            Name = 'name',
            Gps_Location_Enabled__c = true
        );
        insert survey;
        SurveyVersion__c ver =[
            SELECT
                Id,
                Status__c,
                Survey__c,
                Survey__r.Name,
                Survey__r.Alias__c,
                Survey__r.Close_Message__c,
                Survey__r.CreatedDate,
                Survey__r.Gps_Location_Enabled__c,
                Survey__r.Gps_ShowMap__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c = :survey.Id
        ];
        Question__c section1 = new Question__c(Name='s1',Caption__c ='s1',
                Hint__c = 's1',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_SECTION,
                Position__c=1);
        Question__c section2 = new Question__c(Name='s2',Caption__c ='s2',
                Hint__c = 's2',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_SECTION,
                Position__c=2);
        Question__c section3 = new Question__c(Name='s3',Caption__c ='s3',
                Hint__c = 's3',
                Survey__c = survey.Id,
                Type__c = QuestionDO.TYPE_SECTION,
                Position__c=3);

        insert new Question__c[]{section1,section2,section3};

        // Create some questions
        Question__c q1 = new Question__c(Survey__c=survey.Id,
                                         Name='q1',
                                         Caption__c='text',
                                         Type__c=QuestionDO.TYPE_TEXT_SHORT,
                                         Parent__c=section1.Id,
                                         Position__c=1);
        Question__c q2 = new Question__c(Survey__c=survey.Id,
                                         Name='q2',
                                         Caption__c='radio',
                                         Type__c=QuestionDO.TYPE_RADIO,
                                          Parent__c=section1.Id,
                                          Position__c=2);
        Question__c q3 = new Question__c(Survey__c=survey.Id,
                                         Name='q3',
                                         Caption__c='text',
                                         Type__c=QuestionDO.TYPE_TEXT_SHORT,
                                         Parent__c=section2.Id,
                                         Position__c=1);

        Question__c q4 = new Question__c(Survey__c=survey.Id,
                                         Name='q4',
                                         Caption__c='radio',
                                         Type__c=QuestionDO.TYPE_RADIO,
                                         Parent__c=section2.Id,
                                         Position__c=2);
        Question__c qf = new Question__c(Survey__c=survey.Id,
                                         Name='qf',
                                         Caption__c='final',
                                         Type__c=QuestionDO.TYPE_FINAL,
                                         Parent__c=section2.Id,
                                         Position__c=3);

        Question__c q5 = new Question__c(Survey__c=survey.Id,
                                         Name='q5',
                                         Caption__c='text',
                                         Type__c=QuestionDO.TYPE_TEXT_SHORT,
                                         Parent__c=section3.Id,
                                         Position__c=1);
        insert new Question__c[]{q1, q2, q3, q4, qf, q5};

        Option__c option1 = new Option__c(Name='a',Caption__c='a',Question__c=q1.Id,Position__c=1);
        Option__c option2 = new Option__c(Name='a',Caption__c='a',Question__c=q4.Id,Position__c=1);
        insert new Option__c[]{option1,option2};
        Map<String,String> expectedRelevants = new Map<String,String>{
            '/data/s1' => null,
            '/data/s2' => '(/data/s1/q1!=\'a\')',
            '/data/s2/qf' => '(selected(/data/s1/q2,\'c\')) and (/data/s1/q1!=\'a\')',
            '/data/s3' => '(/data/s2/q3=\'b\')',
            '/data/s3/q5' => 'not(((selected(/data/s1/q2,\'c\')) and (/data/s1/q1!=\'a\')))'
        };

        // Create some conditions
        SkipCondition__c skipCondition1 = createCondition(section2,q1,'a',true);
        SkipCondition__c skipCondition2 = createCondition(section3,q3,'b',false);

        // Condition for the finalize question
        SkipCondition__c finalCondition1 = createCondition(qf,q2,'c',false);
        insert new SkipCondition__c[]{skipCondition1,skipCondition2,finalCondition1};

        Test.startTest();
        XFormCreator creator = new XFormCreator();
        dom.Document xform = creator.getXFormFromSurvey(ver,survey.name);

        dom.XmlNode root = xform.getRootElement();
        dom.XmlNode head = root.getChildElement('h:head',null);
        dom.XmlNode model = head.getChildElement('model',null);
        dom.XmlNode[] bindings = model.getChildren();
        Test.stopTest();

        // Check bindings
        for (dom.XmlNode child : bindings) {
            if ('bind' != child.getName()) {
                continue;
            }
            String nodeset = child.getAttribute('nodeset',null);
            String relevant = child.getAttribute('relevant',null);
            system.assertEquals(expectedRelevants.get(nodeset), relevant, 'Nodeset: ' + nodeset);
        }
    }

    //helper method to create a skip condition
    private static SkipCondition__c createCondition(Question__c target, Question__c source, String equalsTo, Boolean negate){
         return new SkipCondition__c(
            Parent__c = target.Id,
            SourceQuestion__c = source.Id,
            Condition__c = SkipConditionDO.CONDITION_EQUAL,
            SkipValue__c = equalsTo,
            Negate__c = negate);

    }
    /**
     * TestCase that test a survey with an image question.
     */
    public static testMethod void testImageQuestion() {
        //create a suervey
        Survey__c survey = new Survey__c(
            Name = 'Name',
            Gps_Location_Enabled__c = true,
            Close_Message__c = null
        );
        insert survey;

        SurveyVersion__c ver = [
            SELECT
                Id,
                Survey__c,
                Survey__r.Gps_Location_Enabled__c,
                Survey__r.Gps_ShowMap__c,
                Survey__r.Close_Message__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c= :survey.Id
        ];

        //create a section
        Question__c sectionQuestion = new Question__c(Caption__c ='Section 1',
                                                      Hint__c = 'sectionTest',
                                                      Survey__c = survey.Id,
                                                      Type__c = QuestionDO.TYPE_SECTION,
                                                      Name ='SectionOne');

        insert sectionQuestion;

        sectionQuestion = [SELECT Name,Hint__c,Caption__c FROM Question__c WHERE Id=:sectionQuestion.Id];

        Question__c imageQuestion = new Question__c(Caption__c ='Image',
                                                    Hint__c = 'This is an image question',
                                                    Parent__c = sectionQuestion.Id,
                                                    Survey__c = survey.Id,
                                                    Type__c = QuestionDO.TYPE_MEDIA_IMAGE,
                                                    Required__c = true,
                                                    Name = 'imageQuestion',
                                                    Position__c = 1);

        List<Question__c> questions = new List<Question__c>{imageQuestion};

        insert questions;

        Test.startTest();
            // Generate XForm for ODK
            XFormCreator x = new XFormCreator();
            dom.document xform = x.getXFormFromSurvey(ver,survey.name);

            DOM.XMLNode root = xform.getRootElement();

            DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
            DOM.XMLNode body = root.getChildElement('h:body',null);
        Test.stopTest();
        //verify the range is valid
        for (DOM.XMLNode node: model.getChildElements()){

            if (node.getName() == 'bind' &&
                node.getAttribute('nodeset', null) == '/data/SectionOne/imageQuestion'){

                System.assertEquals('binary',node.getAttribute('type',null));
            }
        }

        //looking for UPLOAD node
        boolean found = false;
        for (DOM.XMLNode nodes : body.getChildElements()){
            for( DOM.XMLNode node : nodes.getChildElements()){
                //I found the node, so checking if data is ok!
                if (node.getName() == 'upload'){
                    found = true;
                    System.AssertEquals('image/*', node.getAttribute('mediatype',null));
                    System.AssertEquals('/data/SectionOne/imageQuestion', node.getAttribute('ref',null));
                }
            }
        }
        System.assert(found, 'this should not fail since the image was uploaded');
    }

    /**
     *Test Signature question
     *
     */
    public static testMethod void testSignatureQuestion(){
        //create a suervey
        Survey__c survey = new Survey__c(Name = 'name', Gps_Location_Enabled__c=true, Close_Message__c = null);
        insert survey;

        SurveyVersion__c ver = [SELECT Id, Survey__c,
                                    Survey__r.Gps_Location_Enabled__c,
                                    Survey__r.Gps_ShowMap__c,
                                    Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        //create a section
        Question__c sectionQuestion = new Question__c(Caption__c ='Section 1',
                                                      Hint__c = 'sectionTest',
                                                      Survey__c = survey.Id,
                                                      Type__c = QuestionDO.TYPE_SECTION,
                                                      Name ='SectionOne');

        insert sectionQuestion;

        Question__c signatureQuestion = new Question__c(Caption__c ='Signature',
                                                        Hint__c = 'This is a signature question',
                                                        Parent__c = sectionQuestion.Id,
                                                        Survey__c = survey.Id,
                                                        Type__c = QuestionDO.TYPE_SIGNATURE,
                                                        Required__c = true,
                                                        Name = 'signatureQuestion',
                                                        Position__c = 1);

        List<Question__c> questions = new List<Question__c>{signatureQuestion};

        insert questions;

        Test.startTest();
            // Generate XForm for ODK
            XFormCreator x = new XFormCreator();
            dom.document xform = x.getXFormFromSurvey(ver,survey.name);

            DOM.XMLNode root = xform.getRootElement();

            DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
            DOM.XMLNode body = root.getChildElement('h:body',null);
        Test.stopTest();
        //verify the range is valid
        for (DOM.XMLNode node: model.getChildElements()){

            if (node.getName() == 'bind' &&
                node.getAttribute('nodeset', null) == '/data/SectionOne/signatureQuestion'){

                System.assertEquals('binary',node.getAttribute('type',null));
            }
        }
        //looking for UPLOAD node
        boolean found = false;
        for (DOM.XMLNode nodes : body.getChildElements()){
            for( DOM.XMLNode node : nodes.getChildElements()){
                //I found the node, so checking if data is ok!
                if (node.getName() == 'upload'){
                    found = true;
                    System.AssertEquals('image/*', node.getAttribute('mediatype',null));
                    System.AssertEquals('signature', node.getAttribute('appearance',null));
                    System.AssertEquals('/data/SectionOne/signatureQuestion', node.getAttribute('ref',null));
                }
            }
        }
        System.assert(found, 'this should not fail since the image was uploaded');
    }

    /**
     *TestCase that test GPS Location question
     *
     */
    public static testMethod void testGPSLocationQuestion() {
        // Create a survey record
        Survey__c survey = TestUtils.createSurvey('survey');
        SurveyVersion__c ver = [SELECT Id, Survey__c,
                                    Survey__r.Gps_Location_Enabled__c,
                                    Survey__r.Gps_ShowMap__c,
                                    Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];
        // Create a new section
        Question__c sectionQuestion = TestUtils.addQuestion(survey , 1, 'GPS_Section' , QuestionDO.TYPE_SECTION);
        // Verify section question is inserted properly
        System.assertEquals(true, sectionQuestion != null);

        // Create a GPS question
        Question__c gpsQuestion = TestUtils.addQuestion(sectionQuestion, 1, 'GPS_Location_Question', QuestionDO.TYPE_GPS);
        // Verify gps question is inserted properly
        System.assertEquals(true, gpsQuestion != null);

        Test.startTest();
        // Generate XForm for ODK
        XFormCreator x = new XFormCreator();
        dom.document xform = x.getXFormFromSurvey(ver,survey.name);
        DOM.XMLNode root = xform.getRootElement();
        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body = root.getChildElement('h:body',null);
        Test.stopTest();

        // Check for bind node
        for (DOM.XMLNode node: model.getChildElements()) {
            if (node.getName() == 'bind' &&
                node.getAttribute('nodeset', null) == '/data/GPS_Section/GPS_Location_Question') {
                System.assertEquals('geopoint',node.getAttribute('type',null));
            }
        }

        for (DOM.XMLNode nodes : body.getChildElements()) {
            for (DOM.XMLNode node : nodes.getChildElements()) {
                // Check for section
                if (node.getName() == 'group' && 
                    node.getAttribute('nodeset', null)=='/data/GPS_Section') {
                    // check for INPUT node having GPS question
                    if (node.getName() == 'input') {
                        System.AssertEquals('/data/GPS_Section/GPS_Location_Question', node.getAttribute('ref',null));
                    }
                }
            }
        }
    }

    /**
     * TestCase that test a survey with an image question with logic.
     */
    public static testMethod void testImageQuestionRelevant(){
        //create a suervey
        Survey__c survey = new Survey__c(Name='name',Gps_Location_Enabled__c=true, Close_Message__c = null);
        insert survey;

        SurveyVersion__c ver = [SELECT Id, Status__c, Survey__c, Survey__r.Name,
                                    Survey__r.Alias__c, Survey__r.Id,
                                    Survey__r.Close_Message__c, Survey__r.CreatedDate,
                                    Survey__r.Gps_Location_Enabled__c, Survey__r.Gps_ShowMap__c
                                FROM SurveyVersion__c
                                WHERE Survey__c= :survey.Id];

        //create a section
        Question__c sectionQuestion = new Question__c(Caption__c ='Section 1',
                                                      Hint__c = 'sectionTest',
                                                      Survey__c = survey.Id,
                                                      Type__c = QuestionDO.TYPE_SECTION,
                                                      Name='SectionOne');

        insert sectionQuestion;

        sectionQuestion = [SELECT Name,Hint__c,Caption__c FROM Question__c WHERE Id=:sectionQuestion.Id];

        Question__c sourceQuestion = new Question__c(Caption__c = 'sourceQuestion',
                                                     Hint__c = 'this is a short question 1',Parent__c = sectionQuestion.Id,
                                                     Survey__c = survey.Id,
                                                     Type__c = QuestionDO.TYPE_TEXT_SHORT, Required__c = true,
                                                     Name = 'sourceQuestion', Position__c = 1);

        Question__c imageQuestion = new Question__c(Caption__c ='Image',
                                                    Hint__c = 'This is an image question',Parent__c = sectionQuestion.Id,
                                                    Survey__c = survey.Id,
                                                    Type__c = QuestionDO.TYPE_MEDIA_IMAGE, Required__c = true,
                                                    Name ='imageQuestion', Position__c=2);

        Question__c targetQuestion = new Question__c(Caption__c ='sourceQuestion',
                                                     Hint__c = 'this is a short question 2',Parent__c = sectionQuestion.Id,
                                                     Survey__c = survey.Id,
                                                     Type__c = QuestionDO.TYPE_TEXT_SHORT,Required__c = true,
                                                     Name ='targetQuestion',Position__c=3);

        List<Question__c> questions = new List<Question__c>{imageQuestion,sourceQuestion,targetQuestion};

        insert questions;

        //add skiplogic to the question as source
        SkipCondition__c skip1 = createCondition(imageQuestion, sourceQuestion, 'a', false);

        //add skiplogic to the questiion as target
        SkipCondition__c skip2 = new SkipCondition__c(
            Parent__c = targetQuestion.Id,
            SourceQuestion__c = imageQuestion.Id,
            Condition__c = SkipConditionDO.CONDITION_ISANSWERED,
            SkipValue__c = '',
            Negate__c = false
        );
        insert new List<SkipCondition__c>{skip1, skip2};

        Test.startTest();
            // Generate XForm for ODK
            XFormCreator x = new XFormCreator();
            dom.document xform = x.getXFormFromSurvey(ver,survey.name);

            DOM.XMLNode root = xform.getRootElement();

            DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
            DOM.XMLNode body = root.getChildElement('h:body',null);
        Test.stopTest();
        //verify the range is valid
        boolean imageQuestionOk = false;
        boolean targetQuestionOk = false;
        for (DOM.XMLNode node: model.getChildElements()){

            if (node.getName()=='bind'){
                if(node.getAttribute('nodeset', null)=='/data/SectionOne/imageQuestion'){
                    System.assertEquals('(/data/SectionOne/sourceQuestion=\'a\')',node.getAttribute('relevant',null));
                    imageQuestionOk = true;
                }else if(node.getAttribute('nodeset', null)=='/data/SectionOne/targetQuestion'){
                    System.assertEquals('(/data/SectionOne/imageQuestion!=\'\')',node.getAttribute('relevant',null));
                    targetQuestionOk = true;

                }
            }


        }
        //check that both questions relevants were evaluated
        system.assert(targetQuestionOk && imageQuestionOk);
    }

    static testmethod void testRepeatAfterFinalize(){
           // Set up the test survey
        //-----------------------
        Survey__c survey = TestUtils.createSurvey('name');

        SurveyVersion__c ver =[SELECT Id,
                                      Status__c,
                                      Survey__c,
                                      Survey__r.Name,
                                      Survey__r.Alias__c,
                                      Survey__r.Id,
                                      Survey__r.Close_Message__c,
                                      Survey__r.CreatedDate,
                                      Survey__r.Gps_Location_Enabled__c,
                                      Survey__r.Gps_ShowMap__c
                               FROM SurveyVersion__c
                               WHERE Survey__c= :survey.Id][0];
        //Adding a section with a final question
        Question__c section = TestUtils.addQuestion(survey, 1, 's', QuestionDO.TYPE_SECTION);
        Integer pos = 1;

        Question__c sq = TestUtils.addQuestion(section, pos++, 'sq', QuestionDO.TYPE_FINAL);

        // Creating a repeat section with a question
        Question__c repeat = TestUtils.addQuestion(survey, pos++, 'repeat', QuestionDO.TYPE_REPEAT);

        Question__c question = TestUtils.addQuestion(repeat, pos++, 'question', QuestionDO.TYPE_TEXT_SHORT);

        Test.startTest();
            // Generation a XForm
            XFormCreator creator = new XFormCreator();
            dom.Document xform = creator.getXFormFromSurvey(ver,survey.name);

            dom.XmlNode root = xform.getRootElement();
            dom.XmlNode head = root.getChildElement('h:head',null);
            dom.XmlNode model = head.getChildElement('model',null);
            dom.XmlNode[] bindings = model.getChildren();
        Test.stopTest();
        for (dom.XmlNode child : bindings){
            if ('bind' != child.getName()) continue;

            String nodeset = child.getAttribute('nodeset',null);
            if (!nodeset.startsWith('/data/repeat')) continue;

            String relevant = child.getAttribute('relevant',null);
            String key = nodeset.replace('/data/repeat','');
            System.assertEquals('not((true()))', relevant, 'nodeset=' + nodeset);
        }

    }

    //---------------------------- CASCADING SELECT ----------------------------

    /**
     * Verify a correct xml is created with a basic cascading select question.
     */
    public static testMethod void testBasicCascadingSelect() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'Survey Name');
        insert survey;

        SurveyVersion__c ver = [SELECT Id,
                                       Survey__c,
                                       Survey__r.Gps_Location_Enabled__c,
                                       Survey__r.Gps_ShowMap__c,
                                       Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model'},
            new List<String> {'Audi', 'A3'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels =
            TestUtils.createCascadingSelect('Cascading Select', levelsData);

        //create a section
        Question__c sectionQuestion = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name ='section'
        );
        insert sectionQuestion;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Test.startTest();
        // Generate XForm for ODK
        XFormCreator x = new XFormCreator();
        dom.document xform = x.getXFormFromSurvey(ver, survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body = root.getChildElement('h:body', null);

        // There must be an instance for the model and one more for each cascading (1)
        List<DOM.XMLNode> instances = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'instance') {
                instances.add(node);
            }
        }
        System.assertEquals(2, instances.size());

        String expectedXml =
            '<rootNode>' +
                // The model of the xform
                '<data>' +
                    '<section>' +
                        '<cascading_select>' +
                            '<cascading_select_static />' +
                            '<make />' +
                            '<model />' +
                        '</cascading_select>' +
                    '</section>' +
                '</data>' +

                // The data for the cascading
                '<instance id="cascading_select_choices">' +
                    '<level1_list>' +
                        '<level1>' +
                            '<value>Audi</value>' +
                            '<level2_list>' +
                                '<level2>' +
                                    '<value>A3</value>' +
                                '</level2>' +
                            '</level2_list>' +
                        '</level1>' +
                    '</level1_list>' +
                '</instance>' +
            '</rootNode>';

        Dom.Document doc = new Dom.Document();
        doc.load(expectedXml);

        // Check the structure of the model
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('data', null).getChildElement('section', null)),
            String.valueOf(instances[0].getChildElement('data', null).getChildElement('section', null))
        );

        List<DOM.XMLNode> cascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('section', null)
            .getChildElement('cascading_select', null)
            .getChildElements();
        // There must be a question for each level (2) and one more for the static content
        System.assertEquals(3, cascadingNodes.size());
        System.assertEquals('cascading_select_static', cascadingNodes[0].getName());
        System.assertEquals('make', cascadingNodes[1].getName());
        System.assertEquals('model', cascadingNodes[2].getName());

        // Check the structure of the cascading data
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('instance', null).getChildElements()[0]),
            String.valueOf(instances[1].getChildElements()[0])
        );
        System.assertEquals('cascading_select_choices', instances[1].getAttribute('id', null));
        List<DOM.XMLNode> cascadingData = instances[1].getChildElements();
        System.assertEquals(1, cascadingData.size());
        checkCascadingData(levels, levels[0].Cascading_Select_Values__r, cascadingData[0], 1);
    }

    /**
     * Verify a correct xml is created with a basic cascading select question in a repeated section
     *
    public static testMethod void testBasicCascadingSelectInRepeated() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'Survey Name');
        insert survey;

        SurveyVersion__c ver = [SELECT Id,
                                       Survey__c,
                                       Survey__r.Gps_Location_Enabled__c,
                                       Survey__r.Gps_ShowMap__c,
                                       Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model'},
            new List<String> {'Audi', 'A3'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels =
            TestUtils.createCascadingSelect('Cascading Select', levelsData);

        //create a section
        Question__c sectionQuestion = new Question__c(
            Caption__c = 'repeated section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_REPEAT,
            Name = 'repeated_section'
        );
        insert sectionQuestion;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Test.startTest();
        // Generate XForm for ODK
        XFormCreator x = new XFormCreator();
        dom.document xform = x.getXFormFromSurvey(ver, survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body = root.getChildElement('h:body', null);

        // There must be an instance for the model and one more for each cascading (1)
        List<DOM.XMLNode> instances = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'instance') {
                instances.add(node);
            }
        }
        System.assertEquals(2, instances.size());

        String expectedXml =
            '<rootNode>' +
                // The model of the xform
                '<data>' +
                    '<repeated_section>' +
                        '<cascading_select>' +
                            '<cascading_select_static />' +
                            '<make />' +
                            '<model />' +
                        '</cascading_select>' +
                    '</repeated_section>' +
                '</data>' +

                // The data for the cascading
                '<instance id="cascading_select_choices">' +
                    '<make_list>' +
                        '<make>' +
                            '<value>Audi</value>' +
                            '<model_list>' +
                                '<model>' +
                                    '<value>A3</value>' +
                                '</model>' +
                            '</model_list>' +
                        '</make>' +
                    '</make_list>' +
                '</instance>' +
            '</rootNode>';

        Dom.Document doc = new Dom.Document();
        doc.load(expectedXml);

        // Check the structure of the model
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('data', null).getChildElement('repeated_section', null)),
            String.valueOf(instances[0].getChildElement('data', null).getChildElement('repeated_section', null))
        );

        List<DOM.XMLNode> cascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('repeated_section', null)
            .getChildElement('cascading_select', null)
            .getChildElements();
        // There must be a question for each level (2) and one more for the static content
        System.assertEquals(3, cascadingNodes.size());
        System.assertEquals('cascading_select_static', cascadingNodes[0].getName());
        System.assertEquals('make', cascadingNodes[1].getName());
        System.assertEquals('model', cascadingNodes[2].getName());

        // Check the structure of the cascading data
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('instance', null).getChildElements()[0]),
            String.valueOf(instances[1].getChildElements()[0])
        );
        System.assertEquals('cascading_select_choices', instances[1].getAttribute('id', null));
        List<DOM.XMLNode> cascadingData = instances[1].getChildElements();
        System.assertEquals(1, cascadingData.size());
        checkCascadingData(levels, levels[0].Cascading_Select_Values__r, cascadingData[0]);
    }

    /**
     * Verify a correct xml is created with a cascading select question with multiple items
     */
    public static testMethod void testBasicCascadingSelectMultipleItems() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'Survey Name');
        insert survey;

        SurveyVersion__c ver = [SELECT Id,
                                       Survey__c,
                                       Survey__r.Gps_Location_Enabled__c,
                                       Survey__r.Gps_ShowMap__c,
                                       Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2000'},
            new List<String> {'Audi', 'A3', '2001'},
            new List<String> {'Audi', 'A4', '1998'},
            new List<String> {'Audi', 'A4', '1999'},
            new List<String> {'Audi', 'A4', '2001'},
            new List<String> {'Audi', 'A5', '2002'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels =
            TestUtils.createCascadingSelect('Cascading Select', levelsData);

        //create a section
        Question__c sectionQuestion = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert sectionQuestion;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        Test.startTest();
        // Generate XForm for ODK
        XFormCreator x = new XFormCreator();
        dom.document xform = x.getXFormFromSurvey(ver, survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body = root.getChildElement('h:body', null);

        // There must be an instance for the model and one more for each cascading (1)
        List<DOM.XMLNode> instances = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'instance') {
                instances.add(node);
            }
        }
        System.assertEquals(2, instances.size());

        String expectedXml =
            '<rootNode>' +
                // The model of the xform
                '<data>' +
                    '<section>' +
                        '<cascading_select>' +
                            '<cascading_select_static />' +
                            '<make />' +
                            '<model />' +
                            '<year />' +
                        '</cascading_select>' +
                    '</section>' +
                '</data>' +

                // The data for the cascading
                '<instance id="cascading_select_choices">' +
                    '<level1_list>' +
                        '<level1>' +
                            '<value>Audi</value>' +
                            '<level2_list>' +
                                '<level2>' +
                                    '<value>A3</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>2000</value>' +
                                        '</level3>' +
                                        '<level3>' +
                                            '<value>2001</value>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                                '<level2>' +
                                    '<value>A4</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>1998</value>' +
                                        '</level3>' +
                                        '<level3>' +
                                            '<value>1999</value>' +
                                        '</level3>' +
                                        '<level3>' +
                                            '<value>2001</value>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                                '<level2>' +
                                    '<value>A5</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>2002</value>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                            '</level2_list>' +
                        '</level1>' +
                    '</level1_list>' +
                '</instance>' +
            '</rootNode>';

        Dom.Document doc = new Dom.Document();
        doc.load(expectedXml);

        // Check the structure of the model
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('data', null).getChildElement('section', null)),
            String.valueOf(instances[0].getChildElement('data', null).getChildElement('section', null))
        );
        List<DOM.XMLNode> cascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('section', null)
            .getChildElement('cascading_select', null)
            .getChildElements();
        // There must be a question for each level (3) and one more for the static content
        System.assertEquals(4, cascadingNodes.size());
        System.assertEquals('cascading_select_static', cascadingNodes[0].getName());
        System.assertEquals('make', cascadingNodes[1].getName());
        System.assertEquals('model', cascadingNodes[2].getName());
        System.assertEquals('year', cascadingNodes[3].getName());

        // Check the structure of the cascading data
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('instance', null).getChildElements()[0]),
            String.valueOf(instances[1].getChildElements()[0])
        );
        System.assertEquals('cascading_select_choices', instances[1].getAttribute('id', null));
        List<DOM.XMLNode> cascadingData = instances[1].getChildElements();
        System.assertEquals(1, cascadingData.size());
        checkCascadingData(levels, levels[0].Cascading_Select_Values__r, cascadingData[0], 1);
    }

    /**
     * Verify a correct xml is created with more than one cascading select question on different sections
     */
    public static testMethod void testMultipleCascadingDifferentSections() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'Survey Name');
        insert survey;

        SurveyVersion__c ver = [SELECT Id,
                                       Survey__c,
                                       Survey__r.Gps_Location_Enabled__c,
                                       Survey__r.Gps_ShowMap__c,
                                       Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> carsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2000'},
            new List<String> {'Audi', 'A3', '2001'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> carsLevels =
            TestUtils.createCascadingSelect('Cars select', carsData);

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> locationData = new List<List<String>> {
            new List<String> {'Country', 'Department', 'City', 'Neighborhood'},
            new List<String> {'Uruguay', 'Durazno', 'Durazno', 'Terminal'},
            new List<String> {'Uruguay', 'Montevideo', 'Montevideo', 'Parque Batlle'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> locationLevels =
            TestUtils.createCascadingSelect('Location select', locationData);

        //create a section
        Question__c sectionQuestion = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section',
            Position__c = 1
        );
        insert sectionQuestion;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = carsLevels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = carsLevels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = carsLevels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = carsLevels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = carsLevels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = carsLevels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = carsLevels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        //create a section
        Question__c sectionQuestion2 = new Question__c(
            Caption__c = 'section 2',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section_2',
            Position__c = 2
        );
        insert sectionQuestion2;

        Question__c cascadingParentQuestion2 = new Question__c(
            Caption__c = 'cascading select 2',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion2.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select_2',
            Position__c = 1,
            CascadingSelect__c = locationLevels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion2;

        Question__c countryQuestion = new Question__c(
            Caption__c = locationLevels[0].Name__c,
            Parent__c = cascadingParentQuestion2.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'country',
            Position__c = 1,
            CascadingLevel__c = locationLevels[0].Id
        );
        insert countryQuestion;

        Question__c departmentQuestion = new Question__c(
            Caption__c = locationLevels[1].Name__c,
            Parent__c = cascadingParentQuestion2.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'department',
            Position__c = 2,
            CascadingLevel__c = locationLevels[1].Id,
            ControllingQuestion__c = countryQuestion.Id
        );
        insert departmentQuestion;

        Question__c cityQuestion = new Question__c(
            Caption__c = locationLevels[2].Name__c,
            Parent__c = cascadingParentQuestion2.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'city',
            Position__c = 3,
            CascadingLevel__c = locationLevels[2].Id,
            ControllingQuestion__c = departmentQuestion.Id
        );
        insert cityQuestion;

        Question__c neighborhoodQuestion = new Question__c(
            Caption__c = locationLevels[3].Name__c,
            Parent__c = cascadingParentQuestion2.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'neighborhood',
            Position__c = 4,
            CascadingLevel__c = locationLevels[3].Id,
            ControllingQuestion__c = cityQuestion.Id
        );
        insert neighborhoodQuestion;

        Test.startTest();
        // Generate XForm for ODK
        XFormCreator x = new XFormCreator();
        dom.document xform = x.getXFormFromSurvey(ver, survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body = root.getChildElement('h:body', null);

        // There must be an instance for the model and one more for each cascading (2)
        List<DOM.XMLNode> instances = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'instance') {
                instances.add(node);
            }
        }
        System.assertEquals(3, instances.size());

        String expectedXml =
            '<rootNode>' +
                // The model of the xform
                '<data>' +
                    '<section>' +
                        '<cascading_select>' +
                            '<cascading_select_static />' +
                            '<make />' +
                            '<model />' +
                            '<year />' +
                        '</cascading_select>' +
                    '</section>' +
                    '<section_2>' +
                        '<cascading_select_2>' +
                            '<cascading_select_2_static />' +
                            '<country />' +
                            '<department />' +
                            '<city />' +
                            '<neighborhood />' +
                        '</cascading_select_2>' +
                    '</section_2>' +
                '</data>' +

                // The data for the cars cascading
                '<instance id="cascading_select_choices">' +
                    '<level1_list>' +
                        '<level1>' +
                            '<value>Audi</value>' +
                            '<level2_list>' +
                                '<level2>' +
                                    '<value>A3</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>2000</value>' +
                                        '</level3>' +
                                        '<level3>' +
                                            '<value>2001</value>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                            '</level2_list>' +
                        '</level1>' +
                    '</level1_list>' +
                '</instance>' +

                // The data for the cars cascading
                '<instance id="cascading_select_2_choices">' +
                    '<level1_list>' +
                        '<level1>' +
                            '<value>Uruguay</value>' +
                            '<level2_list>' +
                                '<level2>' +
                                '<value>Durazno</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>Durazno</value>' +
                                            '<level4_list>' +
                                                '<level4>' +
                                                    '<value>Terminal</value>' +
                                                '</level4>' +
                                            '</level4_list>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                                '<level2>' +
                                    '<value>Montevideo</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>Montevideo</value>' +
                                            '<level4_list>' +
                                                '<level4>' +
                                                    '<value>Parque Batlle</value>' +
                                                '</level4>' +
                                            '</level4_list>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                            '</level2_list>' +
                        '</level1>' +
                    '</level1_list>' +
                '</instance>' +
            '</rootNode>';

        Dom.Document doc = new Dom.Document();
        doc.load(expectedXml);

        // Check the structure of the model for cars
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('data', null).getChildElement('section', null)),
            String.valueOf(instances[0].getChildElement('data', null).getChildElement('section', null))
        );
        List<DOM.XMLNode> carsCascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('section', null)
            .getChildElement('cascading_select', null)
            .getChildElements();
        // There must be a question for each level (3) and one more for the static content
        System.assertEquals(4, carsCascadingNodes.size());
        System.assertEquals('cascading_select_static', carsCascadingNodes[0].getName());
        System.assertEquals('make', carsCascadingNodes[1].getName());
        System.assertEquals('model', carsCascadingNodes[2].getName());
        System.assertEquals('year', carsCascadingNodes[3].getName());

        // Check the structure of the cascading data
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElements()[1].getChildElements()[0]),
            String.valueOf(instances[1].getChildElements()[0])
        );
        System.assertEquals('cascading_select_choices', instances[1].getAttribute('id', null));
        List<DOM.XMLNode> carsCascadingData = instances[1].getChildElements();
        System.assertEquals(1, carsCascadingData.size());
        checkCascadingData(carsLevels, carsLevels[0].Cascading_Select_Values__r, carsCascadingData[0], 1);

        // Check the structure of the model for location
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('data', null).getChildElement('section_2', null)),
            String.valueOf(instances[0].getChildElement('data', null).getChildElement('section_2', null))
        );
        List<DOM.XMLNode> locationCascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('section_2', null)
            .getChildElement('cascading_select_2', null)
            .getChildElements();
        // There must be a question for each level (4) and one more for the static content
        System.assertEquals(5, locationCascadingNodes.size());
        System.assertEquals('cascading_select_2_static', locationCascadingNodes[0].getName());
        System.assertEquals('country', locationCascadingNodes[1].getName());
        System.assertEquals('department', locationCascadingNodes[2].getName());
        System.assertEquals('city', locationCascadingNodes[3].getName());
        System.assertEquals('neighborhood', locationCascadingNodes[4].getName());

        // Check the structure of the cascading data
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElements()[2].getChildElements()[0]),
            String.valueOf(instances[2].getChildElements()[0])
        );
        System.assertEquals('cascading_select_2_choices', instances[2].getAttribute('id', null));
        List<DOM.XMLNode> cascadingData = instances[2].getChildElements();
        System.assertEquals(1, cascadingData.size());
        checkCascadingData(locationLevels, locationLevels[0].Cascading_Select_Values__r, cascadingData[0], 1);
    }

    /**
     * Verify a correct xml is created with more than one cascading select question on the same section
     */
    public static testMethod void testMultipleCascadingSameSection() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'Survey Name');
        insert survey;

        SurveyVersion__c ver = [SELECT Id,
                                       Survey__c,
                                       Survey__r.Gps_Location_Enabled__c,
                                       Survey__r.Gps_ShowMap__c,
                                       Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> carsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A3', '2000'},
            new List<String> {'Audi', 'A3', '2001'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> carsLevels =
            TestUtils.createCascadingSelect('Cars select', carsData);

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> locationData = new List<List<String>> {
            new List<String> {'Country', 'Department', 'City', 'Neighborhood'},
            new List<String> {'Uruguay', 'Durazno', 'Durazno', 'Terminal'},
            new List<String> {'Uruguay', 'Montevideo', 'Montevideo', 'Parque Batlle'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> locationLevels =
            TestUtils.createCascadingSelect('Location select', locationData);

        //create a section
        Question__c sectionQuestion = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section',
            Position__c = 1
        );
        insert sectionQuestion;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = carsLevels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = carsLevels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = carsLevels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = carsLevels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = carsLevels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = carsLevels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = carsLevels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        Question__c cascadingParentQuestion2 = new Question__c(
            Caption__c = 'cascading select 2',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select_2',
            Position__c = 2,
            CascadingSelect__c = locationLevels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion2;

        Question__c countryQuestion = new Question__c(
            Caption__c = locationLevels[0].Name__c,
            Parent__c = cascadingParentQuestion2.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'country',
            Position__c = 1,
            CascadingLevel__c = locationLevels[0].Id
        );
        insert countryQuestion;

        Question__c departmentQuestion = new Question__c(
            Caption__c = locationLevels[1].Name__c,
            Parent__c = cascadingParentQuestion2.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'department',
            Position__c = 2,
            CascadingLevel__c = locationLevels[1].Id,
            ControllingQuestion__c = countryQuestion.Id
        );
        insert departmentQuestion;

        Question__c cityQuestion = new Question__c(
            Caption__c = locationLevels[2].Name__c,
            Parent__c = cascadingParentQuestion2.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'city',
            Position__c = 3,
            CascadingLevel__c = locationLevels[2].Id,
            ControllingQuestion__c = departmentQuestion.Id
        );
        insert cityQuestion;

        Question__c neighborhoodQuestion = new Question__c(
            Caption__c = locationLevels[3].Name__c,
            Parent__c = cascadingParentQuestion2.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'neighborhood',
            Position__c = 4,
            CascadingLevel__c = locationLevels[3].Id,
            ControllingQuestion__c = cityQuestion.Id
        );
        insert neighborhoodQuestion;

        Test.startTest();
        // Generate XForm for ODK
        XFormCreator x = new XFormCreator();
        dom.document xform = x.getXFormFromSurvey(ver, survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body = root.getChildElement('h:body', null);

        // There must be an instance for the model and one more for each cascading (2)
        List<DOM.XMLNode> instances = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'instance') {
                instances.add(node);
            }
        }
        System.assertEquals(3, instances.size());

        String expectedXml =
            '<rootNode>' +
                // The model of the xform
                '<data>' +
                    '<section>' +
                        '<cascading_select>' +
                            '<cascading_select_static />' +
                            '<make />' +
                            '<model />' +
                            '<year />' +
                        '</cascading_select>' +
                        '<cascading_select_2>' +
                            '<cascading_select_2_static />' +
                            '<country />' +
                            '<department />' +
                            '<city />' +
                            '<neighborhood />' +
                        '</cascading_select_2>' +
                    '</section>' +
                '</data>' +

                // The data for the cars cascading
                '<instance id="cascading_select_choices">' +
                    '<level1_list>' +
                        '<level1>' +
                            '<value>Audi</value>' +
                            '<level2_list>' +
                                '<level2>' +
                                    '<value>A3</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>2000</value>' +
                                        '</level3>' +
                                        '<level3>' +
                                            '<value>2001</value>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                            '</level2_list>' +
                        '</level1>' +
                    '</level1_list>' +
                '</instance>' +

                // The data for the cars cascading
                '<instance id="cascading_select_2_choices">' +
                    '<level1_list>' +
                        '<level1>' +
                            '<value>Uruguay</value>' +
                            '<level2_list>' +
                                '<level2>' +
                                '<value>Durazno</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>Durazno</value>' +
                                            '<level4_list>' +
                                                '<level4>' +
                                                    '<value>Terminal</value>' +
                                                '</level4>' +
                                            '</level4_list>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                                '<level2>' +
                                    '<value>Montevideo</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>Montevideo</value>' +
                                            '<level4_list>' +
                                                '<level4>' +
                                                    '<value>Parque Batlle</value>' +
                                                '</level4>' +
                                            '</level4_list>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                            '</level2_list>' +
                        '</level1>' +
                    '</level1_list>' +
                '</instance>' +
            '</rootNode>';

        Dom.Document doc = new Dom.Document();
        doc.load(expectedXml);

        // Check the structure of the whole model
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('data', null).getChildElement('section', null)),
            String.valueOf(instances[0].getChildElement('data', null).getChildElement('section', null))
        );

        // Check the structure of the model for cars
        List<DOM.XMLNode> carsCascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('section', null)
            .getChildElement('cascading_select', null)
            .getChildElements();
        // There must be a question for each level (3) and one more for the static content
        System.assertEquals(4, carsCascadingNodes.size());
        System.assertEquals('cascading_select_static', carsCascadingNodes[0].getName());
        System.assertEquals('make', carsCascadingNodes[1].getName());
        System.assertEquals('model', carsCascadingNodes[2].getName());
        System.assertEquals('year', carsCascadingNodes[3].getName());

        // Check the structure of the cascading data
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElements()[1].getChildElements()[0]),
            String.valueOf(instances[1].getChildElements()[0])
        );
        System.assertEquals('cascading_select_choices', instances[1].getAttribute('id', null));
        List<DOM.XMLNode> carsCascadingData = instances[1].getChildElements();
        System.assertEquals(1, carsCascadingData.size());
        checkCascadingData(carsLevels, carsLevels[0].Cascading_Select_Values__r, carsCascadingData[0], 1);

        // Check the structure of the model for location
        List<DOM.XMLNode> locationCascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('section', null)
            .getChildElement('cascading_select_2', null)
            .getChildElements();
        // There must be a question for each level (4) and one more for the static content
        System.assertEquals(5, locationCascadingNodes.size());
        System.assertEquals('cascading_select_2_static', locationCascadingNodes[0].getName());
        System.assertEquals('country', locationCascadingNodes[1].getName());
        System.assertEquals('department', locationCascadingNodes[2].getName());
        System.assertEquals('city', locationCascadingNodes[3].getName());
        System.assertEquals('neighborhood', locationCascadingNodes[4].getName());

        // Check the structure of the cascading data
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElements()[2].getChildElements()[0]),
            String.valueOf(instances[2].getChildElements()[0])
        );
        System.assertEquals('cascading_select_2_choices', instances[2].getAttribute('id', null));
        List<DOM.XMLNode> cascadingData = instances[2].getChildElements();
        System.assertEquals(1, cascadingData.size());
        checkCascadingData(locationLevels, locationLevels[0].Cascading_Select_Values__r, cascadingData[0], 1);
    }

    /**
     * Verify the order of the options in the xml
     */
    public static testMethod void testCascadingSelectChangedOrder() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'Survey Name');
        insert survey;

        SurveyVersion__c ver = [SELECT Id,
                                       Survey__c,
                                       Survey__r.Gps_Location_Enabled__c,
                                       Survey__r.Gps_ShowMap__c,
                                       Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A5', '2003'},
            new List<String> {'Audi', 'A3', '2000'},
            new List<String> {'Audi', 'S5', '2000'},
            new List<String> {'Audi', 'S4', '2002'},
            new List<String> {'Audi', 'A3', '2001'},
            new List<String> {'Audi', 'S5', '2001'},
            new List<String> {'Audi', 'S4', '2003'},
            new List<String> {'Audi', 'A5', '2002'},
            new List<String> {'Audi', 'A5', '2004'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels =
            TestUtils.createCascadingSelect('Cascading Select', levelsData);

        //create a section
        Question__c sectionQuestion = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert sectionQuestion;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        Test.startTest();
        // Generate XForm for ODK
        XFormCreator x = new XFormCreator();
        dom.document xform = x.getXFormFromSurvey(ver, survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body = root.getChildElement('h:body', null);

        // There must be an instance for the model and one more for each cascading (1)
        List<DOM.XMLNode> instances = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'instance') {
                instances.add(node);
            }
        }
        System.assertEquals(2, instances.size());

        String expectedXml =
            '<rootNode>' +
                // The model of the xform
                '<data>' +
                    '<section>' +
                        '<cascading_select>' +
                            '<cascading_select_static />' +
                            '<make />' +
                            '<model />' +
                            '<year />' +
                        '</cascading_select>' +
                    '</section>' +
                '</data>' +

                // The data for the cascading
                '<instance id="cascading_select_choices">' +
                    '<level1_list>' +
                        '<level1>' +
                            '<value>Audi</value>' +
                            '<level2_list>' +
                                '<level2>' +
                                    '<value>A5</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>2003</value>' +
                                        '</level3>' +
                                        '<level3>' +
                                            '<value>2002</value>' +
                                        '</level3>' +
                                        '<level3>' +
                                            '<value>2004</value>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                                '<level2>' +
                                    '<value>A3</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>2000</value>' +
                                        '</level3>' +
                                        '<level3>' +
                                            '<value>2001</value>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                                '<level2>' +
                                    '<value>S5</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>2000</value>' +
                                        '</level3>' +
                                        '<level3>' +
                                            '<value>2001</value>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                                '<level2>' +
                                    '<value>S4</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                            '<value>2002</value>' +
                                        '</level3>' +
                                        '<level3>' +
                                            '<value>2003</value>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                            '</level2_list>' +
                        '</level1>' +
                    '</level1_list>' +
                '</instance>' +
            '</rootNode>';

        Dom.Document doc = new Dom.Document();
        doc.load(expectedXml);

        // Check the structure of the model
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('data', null).getChildElement('section', null)),
            String.valueOf(instances[0].getChildElement('data', null).getChildElement('section', null))
        );

        List<DOM.XMLNode> cascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('section', null)
            .getChildElement('cascading_select', null)
            .getChildElements();
        // There must be a question for each level (3) and one more for the static content
        System.assertEquals(4, cascadingNodes.size());
        System.assertEquals('cascading_select_static', cascadingNodes[0].getName());
        System.assertEquals('make', cascadingNodes[1].getName());
        System.assertEquals('model', cascadingNodes[2].getName());
        System.assertEquals('year', cascadingNodes[3].getName());

        // Check the structure of the cascading data
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElements()[1].getChildElements()[0]),
            String.valueOf(instances[1].getChildElements()[0])
        );
        System.assertEquals('cascading_select_choices', instances[1].getAttribute('id', null));
        List<DOM.XMLNode> cascadingData = instances[1].getChildElements();
        System.assertEquals(1, cascadingData.size());
        checkCascadingData(levels, levels[0].Cascading_Select_Values__r, cascadingData[0], 1);
    }

    /**
     * Verify that five levels are supported
     */
    public static testMethod void testCascadingSelectFiveLevels() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'Survey Name');
        insert survey;

        SurveyVersion__c ver = [SELECT Id,
                                       Survey__c,
                                       Survey__r.Gps_Location_Enabled__c,
                                       Survey__r.Gps_ShowMap__c,
                                       Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Origin', 'Type of vehicle', 'Make', 'Model', 'Year'},
            new List<String> {'Germany', 'Car', 'Audi', 'A3', '2001'},
            new List<String> {'USA', 'Truck', 'Chevrolet', 'CYZ', '2010'},
            new List<String> {'Japan', 'Van', 'Toyota', 'Tundra', '2013'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels =
            TestUtils.createCascadingSelect('Cascading Select', levelsData);

        //create a section
        Question__c sectionQuestion = new Question__c(
            Caption__c = 'section',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name = 'section'
        );
        insert sectionQuestion;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'cascading select',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascading_select',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c originQuestion = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'origin',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert originQuestion;

        Question__c typeQuestion = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'type_of_vehicle',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = originQuestion.Id
        );
        insert typeQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'make',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = typeQuestion.Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c = levels[3].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'model',
            Position__c = 4,
            CascadingLevel__c = levels[3].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c = levels[4].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'year',
            Position__c = 5,
            CascadingLevel__c = levels[4].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;

        Test.startTest();
        // Generate XForm for ODK
        XFormCreator x = new XFormCreator();
        dom.document xform = x.getXFormFromSurvey(ver, survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body = root.getChildElement('h:body', null);

        // There must be an instance for the model and one more for each cascading (1)
        List<DOM.XMLNode> instances = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'instance') {
                instances.add(node);
            }
        }
        System.assertEquals(2, instances.size());

        String expectedXml =
            '<rootNode>' +
                // The model of the xform
                '<data>' +
                    '<section>' +
                        '<cascading_select>' +
                            '<cascading_select_static />' +
                            '<origin />' +
                            '<type_of_vehicle />' +
                            '<make />' +
                            '<model />' +
                            '<year />' +
                        '</cascading_select>' +
                    '</section>' +
                '</data>' +

                // The data for the cascading
                '<instance id="cascading_select_choices">' +
                    '<level1_list>' +
                        '<level1>' +
                            '<value>Germany</value>' +
                            '<level2_list>' +
                                '<level2>' +
                                '<value>Car</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                        '<value>Audi</value>' +
                                            '<level4_list>' +
                                                '<level4>' +
                                                '<value>A3</value>' +
                                                    '<level5_list>' +
                                                        '<level5>' +
                                                            '<value>2001</value>' +
                                                        '</level5>' +
                                                    '</level5_list>' +
                                                '</level4>' +
                                            '</level4_list>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                            '</level2_list>' +
                        '</level1>' +
                        '<level1>' +
                            '<value>USA</value>' +
                            '<level2_list>' +
                                '<level2>' +
                                '<value>Truck</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                        '<value>Chevrolet</value>' +
                                            '<level4_list>' +
                                                '<level4>' +
                                                '<value>CYZ</value>' +
                                                    '<level5_list>' +
                                                        '<level5>' +
                                                            '<value>2010</value>' +
                                                        '</level5>' +
                                                    '</level5_list>' +
                                                '</level4>' +
                                            '</level4_list>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                            '</level2_list>' +
                        '</level1>' +
                        '<level1>' +
                            '<value>Japan</value>' +
                            '<level2_list>' +
                                '<level2>' +
                                '<value>Van</value>' +
                                    '<level3_list>' +
                                        '<level3>' +
                                        '<value>Toyota</value>' +
                                            '<level4_list>' +
                                                '<level4>' +
                                                '<value>Tundra</value>' +
                                                    '<level5_list>' +
                                                        '<level5>' +
                                                            '<value>2013</value>' +
                                                        '</level5>' +
                                                    '</level5_list>' +
                                                '</level4>' +
                                            '</level4_list>' +
                                        '</level3>' +
                                    '</level3_list>' +
                                '</level2>' +
                            '</level2_list>' +
                        '</level1>' +
                    '</level1_list>' +
                '</instance>' +
            '</rootNode>';

        Dom.Document doc = new Dom.Document();
        doc.load(expectedXml);

        // Check the structure of the model
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElement('data', null).getChildElement('section', null)),
            String.valueOf(instances[0].getChildElement('data', null).getChildElement('section', null))
        );

        // Check the structure of the model
        List<DOM.XMLNode> cascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('section', null)
            .getChildElement('cascading_select', null)
            .getChildElements();
        // There must be a question for each level (5) and one more for the static content
        System.assertEquals(6, cascadingNodes.size());
        System.assertEquals('cascading_select_static', cascadingNodes[0].getName());
        System.assertEquals('origin', cascadingNodes[1].getName());
        System.assertEquals('type_of_vehicle', cascadingNodes[2].getName());
        System.assertEquals('make', cascadingNodes[3].getName());
        System.assertEquals('model', cascadingNodes[4].getName());
        System.assertEquals('year', cascadingNodes[5].getName());

        // Check the structure of the cascading data
        System.assertEquals(
            String.valueOf(doc.getRootElement().getChildElements()[1].getChildElements()[0]),
            String.valueOf(instances[1].getChildElements()[0])
        );
        System.assertEquals('cascading_select_choices', instances[1].getAttribute('id', null));
        List<DOM.XMLNode> cascadingData = instances[1].getChildElements();
        System.assertEquals(1, cascadingData.size());
        checkCascadingData(levels, levels[0].Cascading_Select_Values__r, cascadingData[0], 1);
    }

    /**
     * Test Cascading select question
     */
    public static testMethod void testCascadingQuestion() {
        //create a suervey
        Survey__c survey = new Survey__c(
            Name = 'name',
            Gps_Location_Enabled__c = true,
            Close_Message__c = null
        );
        insert survey;

        SurveyVersion__c ver = [SELECT Id,
                                       Survey__c,
                                       Survey__r.Gps_Location_Enabled__c,
                                       Survey__r.Gps_ShowMap__c,
                                       Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        List<CascadingLevel__c> levels =
            TestUtils.createCompleteCascadingSelect('Cascading Select', 3, 2);

        //create a section
        Question__c sectionQuestion = new Question__c(
            Caption__c = 'Section 1',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name ='SectionOne'
        );
        insert sectionQuestion;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'Cascading',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascadingQuestion',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c questionLevel1 = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'cascadingLevel1',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert questionLevel1;

        Question__c questionLevel2 = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'cascadingLevel2',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = questionLevel1.Id
        );
        insert questionLevel2;

        Question__c questionLevel3 = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'cascadingLevel3',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = questionLevel2.Id
        );
        insert questionLevel3;

        Test.startTest();
        // Generate XForm for ODK
        XFormCreator x = new XFormCreator();
        dom.document xform = x.getXFormFromSurvey(ver,survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body = root.getChildElement('h:body', null);

        // There must be an instance for the model and one more for each cascading (1)
        List<DOM.XMLNode> instances = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'instance') {
                instances.add(node);
            }
        }
        System.assertEquals(2, instances.size());

        // Check the structure of the model
        List<DOM.XMLNode> cascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('SectionOne', null)
            .getChildElement('cascadingQuestion', null)
            .getChildElements();
        // There must be a question for each level (3) and one more for the static content
        System.assertEquals(4, cascadingNodes.size());
        System.assertEquals('cascadingQuestion_static', cascadingNodes[0].getName());
        System.assertEquals('cascadingLevel1', cascadingNodes[1].getName());
        System.assertEquals('cascadingLevel2', cascadingNodes[2].getName());
        System.assertEquals('cascadingLevel3', cascadingNodes[3].getName());

        // Check the structure of the cascading data
        System.assertEquals('cascadingQuestion_choices', instances[1].getAttribute('id', null));
        List<DOM.XMLNode> cascadingData = instances[1].getChildElements();
        System.assertEquals(1, cascadingData.size());
        checkCascadingData(levels, levels[0].Cascading_Select_Values__r, cascadingData[0], 1);
    }

    /**
     * Test Cascading select question with specific order
     */
    public static testMethod void testCascadingQuestionOrder() {
        //create a suervey
        Survey__c survey = new Survey__c(
            Name = 'name',
            Gps_Location_Enabled__c = true,
            Close_Message__c = null
        );
        insert survey;

        SurveyVersion__c ver = [SELECT Id,
                                       Survey__c,
                                       Survey__r.Gps_Location_Enabled__c,
                                       Survey__r.Gps_ShowMap__c,
                                       Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        List<CascadingLevel__c> levels =
            TestUtils.createCompleteCascadingSelect('Cascading Select', 3, 2);

        // Change the order of some values
        List<CascadingSelectValue__c> valuesToReorder = [SELECT Id, Position__c
                                                         FROM CascadingSelectValue__c
                                                         WHERE CascadingLevel__c = :levels[2].Id
                                                         ORDER BY Position__c];
        for(Integer i = 0; i < valuesToReorder.size() - 1; i++) {
            valuesToReorder[i].Position__c = valuesToReorder[i].Position__c + 1;
        }
        valuesToReorder[valuesToReorder.size() - 1].Position__c = 1;
        update valuesToReorder;

        levels = [SELECT Id,
                         Name__c,
                         Position__c,
                         ControllingLevel__c,
                         CascadingSelect__c,
                         CascadingSelect__r.Id,
                         CascadingSelect__r.Name,
                         (SELECT Id,
                                 Position__c,
                                 Value__c,
                                 ControllingSelectValue__c
                          FROM Cascading_Select_Values__r
                          ORDER BY Position__c)
                  FROM CascadingLevel__c
                  WHERE CascadingSelect__c = :levels[0].CascadingSelect__r.Id
                  ORDER BY Position__c];

        //create a section
        Question__c sectionQuestion = new Question__c(
            Caption__c = 'Section 1',
            Hint__c = 'sectionTest',
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_SECTION,
            Name ='SectionOne'
        );
        insert sectionQuestion;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c = 'Cascading',
            Hint__c = 'This is a cascading question',
            Parent__c = sectionQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_SELECT,
            Name = 'cascadingQuestion',
            Position__c = 1,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c questionLevel1 = new Question__c(
            Caption__c = levels[0].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'cascadingLevel1',
            Position__c = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert questionLevel1;

        Question__c questionLevel2 = new Question__c(
            Caption__c = levels[1].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'cascadingLevel2',
            Position__c = 2,
            CascadingLevel__c = levels[1].Id,
            ControllingQuestion__c = questionLevel1.Id
        );
        insert questionLevel2;

        Question__c questionLevel3 = new Question__c(
            Caption__c = levels[2].Name__c,
            Parent__c = cascadingParentQuestion.Id,
            Survey__c = survey.Id,
            Type__c = QuestionDO.TYPE_CASCADING_LEVEL,
            Name = 'cascadingLevel3',
            Position__c = 3,
            CascadingLevel__c = levels[2].Id,
            ControllingQuestion__c = questionLevel2.Id
        );
        insert questionLevel3;

        Test.startTest();
        // Generate XForm for ODK
        XFormCreator x = new XFormCreator();
        dom.document xform = x.getXFormFromSurvey(ver,survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body = root.getChildElement('h:body', null);

        // There must be an instance for the model and one more for each cascading (1)
        List<DOM.XMLNode> instances = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'instance') {
                instances.add(node);
            }
        }
        System.assertEquals(2, instances.size());

        // Check the structure of the model
        List<DOM.XMLNode> cascadingNodes = instances[0].getChildElement('data', null)
            .getChildElement('SectionOne', null)
            .getChildElement('cascadingQuestion', null)
            .getChildElements();
        // There must be a question for each level (3) and one more for the static content
        // Also consider the order
        System.assertEquals(4, cascadingNodes.size());
        System.assertEquals('cascadingQuestion_static', cascadingNodes[0].getName());
        System.assertEquals('cascadingLevel1', cascadingNodes[1].getName());
        System.assertEquals('cascadingLevel2', cascadingNodes[2].getName());
        System.assertEquals('cascadingLevel3', cascadingNodes[3].getName());

        // Check the structure of the cascading data
        System.assertEquals('cascadingQuestion_choices', instances[1].getAttribute('id', null));
        List<DOM.XMLNode> cascadingData = instances[1].getChildElements();
        // It should only have the first level list node
        System.assertEquals(1, cascadingData.size());
        checkCascadingData(levels, levels[0].Cascading_Select_Values__r, cascadingData[0], 1);
    }

    // Check that if cascading questions and levels are required, then xform node is required too.
    public static testMethod void testCascadingRequiredXform() {
        Survey__c survey = new Survey__c(
            Name = 'name',
            Close_Message__c = null
        );
        insert survey;

        // Create cascading select with 3 levels and 2 values per level
        List<CascadingLevel__c> levels =
            TestUtils.createCompleteCascadingSelect('Cascading Select', 3, 2);

        SurveyVersion__c ver = [SELECT 
                                    Id, 
                                    Status__c,
                                    Survey__c,
                                    Survey__r.Name,
                                    Survey__r.Alias__c,
                                    Survey__r.Close_Message__c,
                                    Survey__r.CreatedDate,
                                    Survey__r.Gps_Location_Enabled__c,
                                    Survey__r.Gps_ShowMap__c 
                                FROM 
                                    SurveyVersion__c 
                                WHERE 
                                    Survey__c = :survey.Id];

        Question__c section1    = new Question__c(  Survey__c   = survey.Id, 
                                                    Name        = 's1',
                                                    Caption__c  = 's1', 
                                                    Type__c     = QuestionDO.TYPE_SECTION, 
                                                    Position__c = 1);
        insert section1;

        Question__c qCascading1 = new Question__c(  Survey__c          = survey.Id,
                                                    Name               = 'cascading_question_test',
                                                    Caption__c         = 'Cascading Question',
                                                    Type__c            = QuestionDO.TYPE_CASCADING_SELECT,
                                                    Position__c        = 1,
                                                    Parent__c          = section1.Id,
                                                    Required__c        = true,
                                                    CascadingSelect__c = levels[0].CascadingSelect__r.Id);
        insert qCascading1;

        Question__c level1      = new Question__c(  Caption__c        = levels[0].Name__c,
                                                    Parent__c         = qCascading1.Id,
                                                    Survey__c         = survey.Id,
                                                    Type__c           = QuestionDO.TYPE_CASCADING_LEVEL,
                                                    Name              = 'cascadingLevel1',
                                                    Position__c       = 1,
                                                    Required__c       = true,
                                                    CascadingLevel__c = levels[0].Id);
        insert level1;

        Question__c level2      = new Question__c(  Caption__c             = levels[1].Name__c,
                                                    Parent__c              = qCascading1.Id,
                                                    Survey__c              = survey.Id,
                                                    Type__c                = QuestionDO.TYPE_CASCADING_LEVEL,
                                                    Name                   = 'cascadingLevel2',
                                                    Position__c            = 2,
                                                    Required__c            = true,
                                                    CascadingLevel__c      = levels[1].Id,
                                                    ControllingQuestion__c = level1.Id);
        insert level2;

        Question__c level3      = new Question__c(  Caption__c             = levels[2].Name__c,
                                                    Parent__c              = qCascading1.Id,
                                                    Survey__c              = survey.Id,
                                                    Type__c                = QuestionDO.TYPE_CASCADING_LEVEL,
                                                    Name                   = 'cascadingLevel3',
                                                    Position__c            = 3,
                                                    Required__c            = true,
                                                    CascadingLevel__c      = levels[2].Id,
                                                    ControllingQuestion__c = level2.Id);
        insert level3;

        Test.startTest();
            // Generate XForm for ODK
            XFormCreator x     = new XFormCreator();
            dom.document xform = x.getXFormFromSurvey(ver, survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body  = root.getChildElement('h:body', null);

        List<DOM.XMLNode> cascadingNodes = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'bind' && node.getAttribute('nodeset', null).contains('/data/s1/cascading_question_test')) {
                cascadingNodes.add(node);
            }
        }
        
        // 1 cascading question, 3 levels and 1 static default question for odk
        System.assertEquals(5, cascadingNodes.size());
        
        // All cascading nodes must have required true as attribute
        System.assertEquals('true()', cascadingNodes[0].getAttribute('required', null));
        System.assertEquals('true()', cascadingNodes[2].getAttribute('required', null));
        System.assertEquals('true()', cascadingNodes[3].getAttribute('required', null));
        System.assertEquals('true()', cascadingNodes[4].getAttribute('required', null));
    }

    /**
     * Verify skip condition on cascading selects
     */
    public static testMethod void testCascadingSelectWithLogic() {
        // Create a survey
        Survey__c survey = new Survey__c(Name = 'Survey Name');
        insert survey;

        SurveyVersion__c ver = [SELECT Id,
                                       Survey__c,
                                       Survey__r.Gps_Location_Enabled__c,
                                       Survey__r.Gps_ShowMap__c,
                                       Survey__r.Close_Message__c
                                FROM SurveyVersion__c
                                WHERE Survey__c = :survey.Id];

        // Build a matrix with the data for the levels
        // Similar to the CSV
        List<List<String>> levelsData = new List<List<String>> {
            new List<String> {'Make', 'Model', 'Year'},
            new List<String> {'Audi', 'A5', '2003'},
            new List<String> {'Audi', 'A3', '2000'},
            new List<String> {'Audi', 'S5', '2000'},
            new List<String> {'Audi', 'S4', '2002'},
            new List<String> {'Audi', 'A3', '2001'},
            new List<String> {'Audi', 'S5', '2001'},
            new List<String> {'Audi', 'S4', '2003'},
            new List<String> {'Audi', 'A5', '2002'},
            new List<String> {'Audi', 'A5', '2004'}
        };

        // Create the cascading select with all the levels and values
        List<CascadingLevel__c> levels =
            TestUtils.createCascadingSelect('Cascading Select', levelsData);

        // Create a section
        Question__c sectionQuestion = new Question__c(
            Caption__c = 'section',
            Hint__c    = 'sectionTest',
            Survey__c  = survey.Id,
            Type__c    = QuestionDO.TYPE_SECTION,
            Name       = 'section'
        );
        insert sectionQuestion;

        Question__c cascadingParentQuestion = new Question__c(
            Caption__c         = 'cascading select',
            Hint__c            = 'This is a cascading question',
            Parent__c          = sectionQuestion.Id,
            Survey__c          = survey.Id,
            Type__c            = QuestionDO.TYPE_CASCADING_SELECT,
            Name               = 'cascading_select',
            Position__c        = 2,
            CascadingSelect__c = levels[0].CascadingSelect__r.Id
        );
        insert cascadingParentQuestion;

        Question__c makeQuestion = new Question__c(
            Caption__c        = levels[0].Name__c,
            Parent__c         = cascadingParentQuestion.Id,
            Survey__c         = survey.Id,
            Type__c           = QuestionDO.TYPE_CASCADING_LEVEL,
            Name              = 'make',
            Position__c       = 1,
            CascadingLevel__c = levels[0].Id
        );
        insert makeQuestion;

        Question__c modelQuestion = new Question__c(
            Caption__c             = levels[1].Name__c,
            Parent__c              = cascadingParentQuestion.Id,
            Survey__c              = survey.Id,
            Type__c                = QuestionDO.TYPE_CASCADING_LEVEL,
            Name                   = 'model',
            Position__c            = 2,
            CascadingLevel__c      = levels[1].Id,
            ControllingQuestion__c = makeQuestion.Id
        );
        insert modelQuestion;

        Question__c yearQuestion = new Question__c(
            Caption__c             = levels[2].Name__c,
            Parent__c              = cascadingParentQuestion.Id,
            Survey__c              = survey.Id,
            Type__c                = QuestionDO.TYPE_CASCADING_LEVEL,
            Name                   = 'year',
            Position__c            = 3,
            CascadingLevel__c      = levels[2].Id,
            ControllingQuestion__c = modelQuestion.Id
        );
        insert yearQuestion;
        
        Question__c freeText = new Question__c(
            Caption__c  = 'Free1',
            Parent__c   = sectionQuestion.Id,
            Survey__c   = survey.Id,
            Type__c     = QuestionDO.TYPE_TEXT_SHORT,
            Name        = 'free1',
            Position__c = 1
        );
        insert freeText;

        SkipCondition__c skipCondition = new SkipCondition__c(
            Parent__c = cascadingParentQuestion.Id,
            SourceQuestion__c = freeText.Id,
            Condition__c = SkipConditionDO.CONDITION_ISANSWERED,
            SkipValue__c = '',
            Negate__c = false
        );
        insert skipCondition;

        Test.startTest();
            // Generate XForm for ODK
            XFormCreator x = new XFormCreator();
            dom.document xform = x.getXFormFromSurvey(ver, survey.name);
        Test.stopTest();

        DOM.XMLNode root = xform.getRootElement();

        DOM.XMLNode model = root.getChildElement('h:head', null).getChildElement('model', null);
        DOM.XMLNode body  = root.getChildElement('h:body', null);

        List<DOM.XMLNode> cascadingNodes = new List<Dom.XmlNode>();
        for(Dom.XmlNode node : model.getChildElements()) {
            if(node.getName() == 'bind' && node.getAttribute('nodeset', null).contains('/data/section/cascading_select')) {
                cascadingNodes.add(node);
            }
        }
        
        // 1 cascading question, 3 levels and 1 static default question for odk
        System.assertEquals(5, cascadingNodes.size());
        
        // First cascading node must have relevant for logic
        System.assertEquals('(/data/section/free1!=\'\')', cascadingNodes[0].getAttribute('relevant', null));
    }

    /**
     * Helper method to check the structure of the cascading data
     *
     * @param  levels            the levels of the cascading
     * @param  valuesToCheck     the values that should be checked
     * @param  cascadingDataNode the root node of the cascading data
     * @param  index             number of the level
     */
    private static void checkCascadingData(
        List<CascadingLevel__c> levels,
        List<CascadingSelectValue__c> valuesToCheck,
        DOM.XMLNode currentLevelListNode,
        Integer index
    ) {
        // Remove the current level from the list to use it and to let the list
        // prepared to process the next level
        CascadingLevel__c currentLevel = levels.remove(0);
        // Check that the name of the node correspond to the current level
        System.assertEquals('level' + index + '_list', currentLevelListNode.getName());

        // Get the values for the current node
        List<DOM.XMLNode> levelValueNodes = currentLevelListNode.getChildElements();
        // There should be the same amount of nodes than values
        System.assertEquals(valuesToCheck.size(), levelValueNodes.size());

        // Iterate over the values to check if the node is the correct one
        for(Integer i = 0; i < valuesToCheck.size(); i++) {
            // Check the value
            System.assertEquals(
                valuesToCheck[i].Value__c,
                levelValueNodes[i].getChildElement('value', null).getText()
            );

            // If there are more levels, process them
            if(levels.size() > 0) {
                // Build the list of values to check in the next level
                List<CascadingSelectValue__c> nextValues = new List<CascadingSelectValue__c>();
                for(CascadingSelectValue__c value : levels[0].Cascading_Select_Values__r) {
                    if(value.ControllingSelectValue__c == valuesToCheck[i].Id) {
                        nextValues.add(value);
                    }
                }

                // Check the values of the next level
                checkCascadingData(levels, nextValues, levelValueNodes[i].getChildElements()[1], index + 1);
            }
        }
    }
    //---------------------------- END CASCADING SELECT ----------------------------
}
