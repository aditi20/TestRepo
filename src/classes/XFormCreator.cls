/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class XFormCreator {

    public String url { get; set; }

    public String Message{get; set; }
    public static final String ERR_NO_PARAM = 'No Survey found';
    public static final String URL_XMLLISTSURVEYS = 'http://openrosa.org/xforms/xformsList';
    public static final String XFORM_ATTACHMENT = 'xform.xml';
    public static final String XFORM_INITIALPATH= '/data';
    public static final String STATUS_PUBLISHED = SurveyDO.STATUS_PUBLISHED;
    public static survey__c currentSurvey;


    //creates a binding node for any type of question
    public static void createBindingNode(dom.Xmlnode rootNode,String nodeset,String xmlType,String preload,String preloadParams){
          dom.Xmlnode bindNode = rootNode.addChildElement('bind', null, null);
          bindNode.setAttribute('nodeset',nodeset);
          bindNode.setAttribute('type',XmlType);
          bindNode.setAttribute('jr:preload',preload);
          bindNode.setAttribute('jr:preloadParams',preloadParams);
    }

    //sets the standard header binding nodes of the xform
    public static void setHeaderBindings(dom.Xmlnode rootNode) {

          createBindingNode(rootNode,'/data/start','dateTime','timestamp','start');
          createBindingNode(rootNode,'/data/end','dateTime','timestamp','end');
          createBindingNode(rootNode,'/data/today','date','date','today');
          createBindingNode(rootNode,'/data/deviceid','string','property','devicesid');
          createBindingNode(rootNode,'/data/simid','string','property','simserial');
          createBindingNode(rootNode,'/data/phonenumber','string','property','phonenumber');
    }

    //sets the standard header model nodes of the xform
    public static void setHeaderModel(dom.Xmlnode rootNode){
          rootNode.addChildElement('start', null, null);
          rootNode.addChildElement('end', null, null);
          rootNode.addChildElement('today', null, null);
          rootNode.addChildElement('deviceid', null, null);
          rootNode.addChildElement('simid', null, null);
          rootNode.addChildElement('phonenumber', null, null);
    }


    /**
      * Auxiliary function that creates the xform as an attachment but without inserting it.
      * @param ver survey version
      */
    public Attachment getAttachment(SurveyVersion__c ver){

        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Attachment.Name,
            Attachment.Body
        });

        // Remove any previously existing xforms
        Attachment[] atts = [Select Id from Attachment where ParentId = :ver.Id and Name = :XFORM_ATTACHMENT];

        attachmentCreator.checkObjectDeletable();
        if (atts.size() > 0) delete atts;

        String surveyNameToRender = (ver.Survey__r.Alias__c=='' ||ver.Survey__r.Alias__c==null)
                                        ? ver.Survey__r.Name
                                        : ver.Survey__r.Alias__c;
        String xform = this.getXFormFromSurvey(ver, surveyNameToRender).ToXmlString();

        Attachment att = (Attachment)attachmentCreator.createNewRecord();
        attachmentCreator.populateFields(
            att,
            new Map<Schema.SObjectField, Object>{
                Attachment.Name => XFORM_ATTACHMENT,
                Attachment.ParentId => ver.Id,
                Attachment.Body => Blob.valueOf(xform)
            }
        );

        return att;

    }
    public Attachment createDocument(SurveyVersion__c ver){
        Attachment att = null;

        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkObjectCreateable();

        att = getAttachment(ver);
        insert att;

        this.Message ='XForm generated correctly.';
        this.url='/servlet/servlet.FileDownload?file='+att.Id;
        return att;
    }

    public PageReference createDocument(){
        //Obtains the surveyId or the surveyId from the url and create the correct document.
        Id surveyId = Apexpages.currentPage().getParameters().get('SurveyId');

        //if the parameter SurveyId Exist create that document,else use the Surveyid param
        if (surveyId != null){
            ServicesController sc = new ServicesController();
            sc.getSurvey(surveyId);
        }else{
            //in case that surveyId is not found in the page
            this.Message= ERR_NO_PARAM;
        }
        return null;
    }

    /**
     * Create the xform xml for the given survey
     *
     * @param  ver the version to generate the xform
     * @param  surveyTitle the title of the survey
     * @return             an xml document with the xform
     */
    public Dom.Document getXFormFromSurvey(SurveyVersion__c ver, String surveyTitle) {

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Question__c.SkipLogicBehavior__c,
            Question__c.SkipLogicOperator__c,
            Question__c.Name,
            Question__c.Hint__c,
            Question__c.Caption__c,
            Question__c.Type__c,
            Question__c.Maximum__c,
            Question__c.Minimum__c,
            Question__c.Parent__c,
            Question__c.Required__c,
            Question__c.SamePage__c,
            Question__c.RepeatSourceValue__c,
            Question__c.CascadingLevel__c,
            Question__c.Minimum__c,
            Question__c.Minimum__c,
            Question__c.Parent__c
        });

        GenericObjectCreator optionCreator =
            new GenericObjectCreator(Option__c.SObjectType);
        optionCreator.checkObjectAccessible();
        optionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Option__c.Name,
            Option__c.Caption__c,
            Option__c.Position__c
        });

        // Get all the questions of the survey
        List<Question__c> questions = [SELECT Id,
                                              SkipLogicBehavior__c,
                                              SkipLogicOperator__c,
                                              Name,
                                              Hint__c,
                                              Caption__c,
                                              Type__c,
                                              Maximum__c,
                                              Minimum__c,
                                              Parent__r.Id,
                                              Parent__c,
                                              Required__c,
                                              SamePage__c,
                                              Question__c.CascadingLevel__r.Name__c,
                                              Question__c.CascadingLevel__c,
                                              RepeatSourceValue__c,
                                              CascadingSelect__r.Id,
                                              (SELECT Id,
                                                      Name,
                                                      Caption__c
                                               FROM Options__r
                                               ORDER BY Position__c),
                                              (SELECT Id,
                                                      SkipLogicBehavior__c,
                                                      SkipLogicOperator__c,
                                                      Name,
                                                      Hint__c,
                                                      Caption__c,
                                                      Type__c,
                                                      Maximum__c,
                                                      Minimum__c,
                                                      Parent__r.Id,
                                                      Parent__c,
                                                      Required__c,
                                                      SamePage__c,
                                                      RepeatSourceValue__c,
                                                      CascadingSelect__c,
                                                      Question__c.CascadingLevel__c,
                                                      CascadingLevel__r.Name__c
                                               FROM Questions__r
                                               WHERE Type__c = :QuestionDO.TYPE_CASCADING_LEVEL
                                               ORDER BY Position__c)
                                       FROM Question__c
                                       WHERE Survey__r.Id = :ver.Survey__c
                                             AND Type__c != :QuestionDO.TYPE_CASCADING_LEVEL
                                       ORDER BY Position__c];

        // Create the wrapper class
        Survey survey = new Survey();
        survey.Name = surveyTitle;
        survey.SurveyId = ver.Survey__c;
        survey.VersionId = ver.Id;

        // A set of the cascasding selects used by the survey
        Set<Id> cascadingSelects = new Set<Id>();

        Map<Id, QuestionType.Section> sections = new Map<Id, QuestionType.Section>();
        List<Option__c> options = [SELECT Name, Caption__c, Question__r.Name, Position__c
                                   FROM Option__c
                                   WHERE Question__r.Survey__c = :ver.Survey__c
                                   ORDER BY Position__c];

        //used to map (question Id, Path Id)
        Map<Id, String> questionPaths = new Map<Id, String>();

        // Iterate over the questions to create the section wrappers
        for(Question__c q : questions) {
            // If the question is of type Section, add it to the Section Map
            if ((q.Type__c == QuestionDO.TYPE_SECTION) || (q.Type__c == QuestionDO.TYPE_REPEAT)) {
                QuestionType.Section foundSection = new QuestionType.Section(q, questionPaths);
                survey.questions.add(foundSection);
                sections.put(q.Id, foundSection);

                //add the section path
                foundSection.Path = XFORM_INITIALPATH;
                questionPaths.put(q.Id, foundSection.Path + '/' + q.Name);
            }
            else if(q.Type__c == QuestionDO.TYPE_CASCADING_SELECT) {
                cascadingSelects.add(q.CascadingSelect__c);
            }
        }

        GenericObjectCreator cascadingLevelCreator =
            new GenericObjectCreator(CascadingLevel__c.SObjectType);
        cascadingLevelCreator.checkObjectAccessible();
        cascadingLevelCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            CascadingLevel__c.Name__c,
            CascadingLevel__c.Position__c,
            CascadingLevel__c.CascadingSelect__c
        });

        // Get all the cascading levels used by the survey
        List<CascadingLevel__c> allLevels = [SELECT Id,
                                                    Name__c,
                                                    Position__c,
                                                    CascadingSelect__r.Id,
                                                    (SELECT Id
                                                     FROM Cascading_Select_Values__r
                                                     ORDER BY Position__c)
                                             FROM CascadingLevel__c
                                             WHERE CascadingSelect__c IN :cascadingSelects
                                             ORDER BY Position__c];

        // Build a map with the levels for each cascading
        Map<Id, List<CascadingLevel__c>> levelsByCascadingId = new Map<Id, List<CascadingLevel__c>>();
        for(CascadingLevel__c level : allLevels) {
            if(levelsByCascadingId.get(level.CascadingSelect__c) == null) {
                levelsByCascadingId.put(level.CascadingSelect__c, new List<CascadingLevel__c> {level});
            }
            else {
                levelsByCascadingId.get(level.CascadingSelect__c).add(level);
            }
        }

        GenericObjectCreator cascadingSelectValueCreator =
            new GenericObjectCreator(CascadingSelectValue__c.SObjectType);
        cascadingSelectValueCreator.checkObjectAccessible();
        cascadingSelectValueCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            CascadingSelectValue__c.Value__c
        });
        // Build a map with the child values for each value
        Map<Id, CascadingSelectValue__c> childValuesByParentId = new Map<Id, CascadingSelectValue__c> (
            [SELECT Id,
                    Value__c,
                    (SELECT Id
                     FROM Cascading_Select_Values__r
                     ORDER BY Position__c)
             FROM CascadingSelectValue__c
             WHERE CascadingLevel__c IN :allLevels]
        );

        // Iterate over the questions to create the question wrappers and add them to the section wrappers
        for(Question__c q : questions) {
            if((q.Type__c != QuestionDO.TYPE_SECTION) && (q.Type__c != QuestionDO.TYPE_REPEAT)) {
                // Create the question wrapper depending on the type
                QuestionType.Question question;
                if( q.Type__c == QuestionDO.TYPE_RADIO || q.Type__c == QuestionDO.TYPE_CHECKBOX ) {
                    question = new QuestionType.SelectionQuestion(q);
                }
                else if(q.Type__c == QuestionDO.TYPE_FINAL) {
                    question = new QuestionType.FinalizeQuestion(q);
                }
                else if(q.Type__c == QuestionDO.TYPE_MEDIA_IMAGE) {
                    question = new QuestionType.MediaQuestion(q);
                }
                else if(q.Type__c == QuestionDO.TYPE_SIGNATURE) {
                    question = new QuestionType.SignatureQuestion(q);
                }
                else if(q.Type__c == QuestionDO.TYPE_CASCADING_SELECT) {
                    question = new QuestionType.CascadingSelectQuestion(
                        q,
                        levelsByCascadingId.get(q.CascadingSelect__r.Id),
                        childValuesByParentId
                    );
                }
                else {
                    question = new QuestionType.SimpleInput(q);
                }

                // Set the path of the question
                question.Path = XFORM_INITIALPATH + '/' + sections.get(q.Parent__r.Id).Name;
                questionPaths.put(q.Id, question.Path + '/' + q.Name);
                // Add the question wrapper to the corresponding section wrapper
                sections.get(q.Parent__r.Id).sectionQuestions.add(question);
            }
        }

        return survey.getXForms(questionPaths, ver);
    }

    /**
     * Get all the surveys available to a given user
     *
     * @param urlBobdy
     * @param contactId - Contact.Id for the user that has requested the surveys
     */
    public Dom.Document getXmlAllSurveys(String UrlBody,Id contactId) {
        GenericObjectCreator contactGroupSurveyAssignmentCreator =
            new GenericObjectCreator(ContactGroupSurveyAssignment__c.SObjectType);
        contactGroupSurveyAssignmentCreator.checkObjectAccessible();
        contactGroupSurveyAssignmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            ContactGroupSurveyAssignment__c.Survey__c
        });

        GenericObjectCreator contactGroupMembeCreator =
            new GenericObjectCreator(ContactGroupMember__c.SObjectType);
        contactGroupMembeCreator.checkObjectAccessible();
        contactGroupMembeCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            ContactGroupMember__c.ContactGroup__c
        });

        // Filter the downloadable surveys for the group this contact belongs to
        List<ContactGroupSurveyAssignment__c> assignmentsIds =
            (List<ContactGroupSurveyAssignment__c>)DBFullAccess.QuerySObject(
                'SELECT ' +
                    'Survey__c ' +
                'FROM ' +
                    'ContactGroupSurveyAssignment__c ' +
                 'WHERE ' +
                    'ContactGroup__c IN (' +
                        'SELECT ' +
                            'ContactGroup__c ' +
                        'FROM ' +
                            'ContactGroupMember__c ' +
                        'WHERE ' +
                            'Contact__c =\'' + String.escapeSingleQuotes(contactId) + '\')');
        Set<Id> surveyIds = new Set<Id>();
        for (ContactGroupSurveyAssignment__c cgsa : assignmentsIds) {
            surveyIds.add(cgsa.Survey__c);
        }

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.Name,
            Survey__c.Alias__c,
            Survey__c.Close_Message__c
        });

        // Get all published surveys
        List<Survey__c> allSurveyList;
        if (Test.isRunningTest()) {
            allSurveyList = [
                SELECT
                    Name,
                    Id,
                    Alias__c,
                    Close_Message__c
                FROM
                    Survey__c
                WHERE
                    Name LIKE '__test__%'
                    AND Status__c = :STATUS_PUBLISHED
                    AND Id in :surveyIds
                ORDER BY
                    CreatedDate DESC
            ];
        }
        else {
            allSurveyList = [
                SELECT
                    Name,
                    Id,
                    Alias__c,
                    Close_Message__c
                FROM
                    Survey__c
                WHERE
                    Status__c = :STATUS_PUBLISHED
                    AND Id in :surveyIds
                ORDER BY
                    CreatedDate DESC
            ];
        }

        // Map used to list only the last published version of a survey
        Map<Id,Survey__c> SurveysMap = new Map<Id,Survey__c>();
        dom.Document doc = new dom.Document();
        dom.Xmlnode xmlRoot = doc.createRootElement('xforms', URL_XMLLISTSURVEYS, '');
        String downloadUrl = (Site.getName() != null ? Site.getCurrentSiteUrl().replaceFirst('/$','') : '') + Page.formList.getUrl(); // base Url for downloading any survey

        // Get the latest version for each survey
        Map<Id,SurveyVersion__c> versions = new Map<Id,SurveyVersion__c>();

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            SurveyVersion__c.Version__c,
            SurveyVersion__c.Survey__c
        });
        for (SurveyVersion__c version : [SELECT Id, Version__c, Survey__c
                FROM SurveyVersion__c
                WHERE Status__c = :STATUS_PUBLISHED
                ORDER BY Survey__c ASC, Version__c ASC]
        ) {
            versions.put(version.Survey__c, version);
        }
        for (Survey__c sur: allSurveyList) {
            if (!(SurveysMap.containsKey(sur.Id))) {
                dom.Xmlnode xmlForm = xmlRoot.addChildElement('xform', null, null);
                SurveysMap.put(sur.Id, sur);
                String surveyLabel = ((sur.Alias__c=='') || (sur.Alias__c == null) ) ? sur.Name : sur.Alias__c;
                xmlForm.addChildElement('formID', null, null).addTextNode(versions.get(sur.Id).Id);
                xmlForm.addChildElement('name', null, null).addTextNode(surveyLabel);
                xmlForm.addChildElement('majorMinorVersion', null, null);
                xmlForm.addChildElement('version', null, null).addTextNode(String.valueOf(versions.get(sur.Id).Version__c));
                xmlForm.addChildElement('hash', null, null);
                xmlForm.addChildElement('downloadUrl', null, null).addTextNode(downloadUrl + '?id=' + versions.get(sur.Id).Id);
            }
        }
        return doc;
    }

    // used as a tag to mark a class as XFormsSerializable
    public interface  IXFormsSerializable{
        /*generate the data for the model node of the dom document*/

        void getXFormsModel(dom.Xmlnode node,Map<Id,String> questionPaths);

        /*generate the data for the body node of the dom document*/
        void getXFormBody(dom.Xmlnode node,SurveyVersion__c ver);
    }

    // Represents an survey with convient method to make the xForms convertion
    public with sharing class Survey implements IXFormsSerializable{

        public Id VersionId{ get; set; }
        public Id SurveyId{ get; set; }
        public String Name { get; set; }
        public List<QuestionType.IQuestion> questions = new List<QuestionType.IQuestion>();
        public String ValidName {get {return this.Name.replace(' ','_');}}

        /* This method returns the part of the model of the survey */
        public void getXFormsModel(dom.Xmlnode xmlRoot,Map<Id,String> questionPaths){

            dom.Xmlnode xmlHead = xmlRoot.addChildElement('h:head',null,null);
            xmlHead.addChildElement('h:title',null,null).addTextNode(Name);
            dom.Xmlnode xmlModel = xmlHead.addChildElement('model',null,null);
            dom.Xmlnode xmlInstance = xmlModel.addChildElement('instance',null,null);
            dom.Xmlnode xmlData = xmlInstance.addChildElement('data',null,null);
            xmlData.setAttribute('id',VersionId);
            setHeaderModel(xmlData);
            setHeaderBindings(xmlModel);

            GenericObjectCreator skipConditionCreator =
                new GenericObjectCreator(SkipCondition__c.SObjectType);
            skipConditionCreator.checkObjectAccessible();
            skipConditionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                SkipCondition__c.Name,
                SkipCondition__c.Parent__c,
                SkipCondition__c.SourceQuestion__c,
                SkipCondition__c.SkipValue__c,
                SkipCondition__c.Condition__c,
                SkipCondition__c.Negate__c,
                SkipCondition__c.SourceQuestion__c
            });

            GenericObjectCreator questionCreator =
                new GenericObjectCreator(Question__c.SObjectType);
            questionCreator.checkObjectAccessible();
            questionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                Question__c.Type__c
            });

            // List of conditions used to generate the Xform
            List<SkipCondition__c> skipConditions = [
                SELECT
                    Name,
                    Parent__c,
                    SourceQuestion__c,
                    SkipValue__c,
                    Condition__c,
                    Negate__c,
                    SourceQuestion__r.Type__c
                FROM
                    SkipCondition__c
                WHERE
                    SourceQuestion__r.Survey__c =:surveyId
                ORDER BY Id
            ];

            GenericObjectCreator questionMappingCreator =
                new GenericObjectCreator(QuestionMapping__c.SObjectType);
            questionMappingCreator.checkObjectAccessible();
            questionMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                QuestionMapping__c.FieldApiName__c,
                QuestionMapping__c.Question__c,
                QuestionMapping__c.SurveyMapping__c
            });

            GenericObjectCreator surveyMappingCreator =
                new GenericObjectCreator(SurveyMapping__c.SObjectType);
            surveyMappingCreator.checkObjectAccessible();
            surveyMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                SurveyMapping__c.ObjectApiName__c
            });

            List<QuestionMapping__c> questionMappings = [
                SELECT Id, FieldApiName__c, Question__c, SurveyMapping__c, SurveyMapping__r.ObjectApiName__c
                FROM QuestionMapping__c
                WHERE Question__r.Type__c = :QuestionDO.TYPE_TEXT_SHORT
                    AND SurveyMapping__c IN (SELECT Id
                                             FROM SurveyMapping__c
                                             WHERE Survey__c = :surveyId)];

            Map<String, Schema.SObjectType> globalDescribe;

            if(!questionMappings.isEmpty()){
                globalDescribe = DescribeHandler.getGlobalDescribe();
            }
            String finishConditions;
            for(QuestionType.IQuestion question : this.questions){
                question.getXFormsModel(xmlData);
                question.getBindings(xmlModel,skipConditions,questionMappings,questionPaths,globalDescribe,finishConditions);
                finishConditions = ((QuestionType.section)question).FinishConditions;
            }
            // Insert close message at the end of the survey, if present.
            if (currentSurvey.Close_Message__c != null && currentSurvey.Close_Message__c != ''){
                //Adds a Node for closemessage into the Model Node.
                xmlData.addChildElement('closemessage', null, null);
                //Adds a Node for closemessage into the Bind Node.
                dom.Xmlnode closemessageNode = xmlModel.addChildElement('bind', null, null);
                closemessageNode.setAttribute('nodeset','/data/closemessage');
                closemessageNode.setAttribute('type','string');
                closemessageNode.setAttribute('readonly','true()');

                //The message will show if the finalization conditions have not been met
                closemessageNode.setAttribute('relevant','not(' +finishConditions+')');
            }
        }

        public void getXFormBody(dom.Xmlnode xmlRoot,SurveyVersion__c version){
            dom.Xmlnode xmlBody = xmlRoot.addChildElement('h:body',null,null);

            for(QuestionType.IQuestion q :this.questions){
                q.getXformBody(xmlBody);
            }

            // Insert close message at the end of the survey, if present.
            if (version.Survey__r.Close_Message__c != null && version.Survey__r.Close_Message__c != ''){
                //Add the close message Node into the Data Node
                dom.Xmlnode xmlCloseMessage = XmlBody.addChildElement('input',null,null);

                //The close message will been showed as HINT text.
                xmlCloseMessage.addChildElement('hint',null,null).addTextNode(version.Survey__r.Close_Message__c);
                xmlCloseMessage.setAttribute('ref','/data/closemessage');
            }
        }

        /**
         * Method to build XML to list this survey
         *
         * @param  questionPaths a map with the paths for each question
         * @param  version       the version of the survey
         * @return               an xml document
         */
        public Dom.Document getXForms(Map<Id, String> questionPaths, SurveyVersion__c version) {
            GenericObjectCreator surveyCreator =
                new GenericObjectCreator(Survey__c.SObjectType);
            surveyCreator.checkObjectAccessible();
            surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                Survey__c.Name,
                Survey__c.Alias__c,
                Survey__c.Close_Message__c
            });

            currentSurvey = [SELECT Id,
                                    Alias__c,
                                    Name,
                                    Close_Message__c
                             FROM Survey__c
                             WHERE Id = :version.Survey__c];

            Dom.Document doc = new Dom.Document();
            Dom.Xmlnode xmlRoot = doc.createRootElement('h:html', null, null);
            xmlRoot.setNamespace('jr', 'http://openrosa.org/javarosa');
            xmlRoot.setNamespace('h', 'http://www.w3.org/1999/xhtml');

            this.getXFormsModel(xmlRoot, questionPaths);
            this.getXFormBody(xmlRoot, version);

            return doc;
        }

    }
}
