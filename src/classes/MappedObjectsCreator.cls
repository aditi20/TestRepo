/**
* Create the mapped objects in a survey from a xml submission file.
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
* @author - Ernesto Quesada
* @author - Aditi Satpute
*/
public with sharing class MappedObjectsCreator {
    private Map<Id,Option__c> optionsMap;
    private Submission__c currentSubmission;
    private Map<Id,Question__c> questions;
    private Dom.Xmlnode root;

    // Keep track of created records to link them through relationships.
    // Map them to the SurveyMapping Id if they do not repeat.
    // Map them to the associated XMLNode (through attribute -> Id) if they repeat.
    private Map<String,SObject> createdRecords;

    //the interviewee and surveyor Map by contact Id
    private Map<Id,Contact> submissionContacts;

    //all the surveyMapping data by id
    private Map<Id, SurveyMapping__c> surveyMappingById;

    /**
    * For a given submission, generate its surveys defined mapped objects.
    * @param Submission
    */

    public void generateObjects(Submission__c submission) {

        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Attachment.Body
        });

        // Get the submission xml and generate the Dom
        Attachment submissionXML = [
            SELECT
                Id,
                Body
            FROM
                Attachment
            WHERE
                ParentId = :submission.Id
                AND Name = :c.SURVEY_ANSWER_ATTACHMENT_NAME
        ];
        generateObjects(submission, submissionXML.Body.toString(), new Map<String, String>());
    }
    /**
    * For a given submission, generate its surveys defined mapped objects.
    * @param Submission
    * @param xml Xml of the submission as String.
    * @param mediaFileIdByFileName map of the media files of this submission,
    *                              with filename as key and Attachement id as data.
    **/
    public void generateObjects(
            Submission__c submission,
            String xml,
            Map<String, String> mediaFileIdByFileName
    ) {
        currentSubmission = submission;

        Dom.Document doc = new Dom.Document();
        doc.load(xml);
        // Get the data node of the Dom
        root = doc.getRootElement();
        createdRecords = new Map<String,SObject>();

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Question__c.Parent__c,
            Question__c.Name,
            Question__c.Type__c
        });
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.OwnerId,
            Survey__c.Version__c
        });
        GenericObjectCreator optionCreator =
            new GenericObjectCreator(Option__c.SObjectType);
        optionCreator.checkObjectAccessible();
        optionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Option__c.Name,
            Option__c.Caption__c
        });
        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            SurveyMapping__c.Survey__c,
            SurveyMapping__c.ObjectApiName__c,
            SurveyMapping__c.MatchingField__c,
            SurveyMapping__c.SurveyApiField__c,
            SurveyMapping__c.SurveyVersionApiField__c,
            SurveyMapping__c.SubmissionApiField__c,
            SurveyMapping__c.SurveyorApiField__c,
            SurveyMapping__c.PPIScoreApiField__c,
            SurveyMapping__c.Repeat__c,
            SurveyMapping__c.IsReference__c
        });
        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(QuestionMapping__c.SObjectType);
        questionMappingCreator.checkObjectAccessible();
        questionMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            QuestionMapping__c.FieldApiName__c,
            QuestionMapping__c.SurveyMapping__c
        });
        GenericObjectCreator objectRelationshipMappingCreator =
            new GenericObjectCreator(ObjectRelationshipMapping__c.SObjectType);
        objectRelationshipMappingCreator.checkObjectAccessible();
        objectRelationshipMappingCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                ObjectRelationshipMapping__c.FieldApiName__c,
                ObjectRelationshipMapping__c.ParentSurveyMapping__c,
                ObjectRelationshipMapping__c.ChildSurveyMapping__c
            }
        );
        GenericObjectCreator contactCreator =
            new GenericObjectCreator(Contact.SObjectType);
        contactCreator.checkObjectAccessible();
        contactCreator.checkFieldsAccessible(
            new List<Schema.SObjectField>{
                Contact.Name
            }
        );

        // Get the survey questions
        questions = new Map<Id,Question__c>(
            [
                SELECT
                    Id,
                    Name,
                    Type__c,
                    Parent__c,
                    Parent__r.Name
                FROM
                    Question__c
                WHERE
                    Survey__c = :submission.Survey__c
            ]
        );

        // Get all options of the survey questions (used to translate ids to text)
        optionsMap = new Map<Id,Option__c>(
            [
                SELECT
                    Id,
                    Name,
                    Caption__c
                FROM
                    Option__c
                WHERE
                    Question__r.Survey__c = :submission.Survey__c
                    ORDER BY Question__r.Position__c, Position__c
            ]
        );

        // Get all the surveyMappings to process
        surveyMappingById = new Map<Id, SurveyMapping__c>(
            [
                SELECT
                    Id,
                    Survey__c,
                    Survey__r.OwnerId,
                    Survey__r.Version__c,
                    ObjectApiName__c,
                    MatchingField__c,
                    SurveyApiField__c,
                    SurveyVersionApiField__c,
                    SubmissionApiField__c,
                    SurveyorApiField__c,
                    PPIScoreApiField__c,
                    Repeat__c,
                    IsReference__c,
                    (
                        SELECT
                            Id,
                            FieldApiName__c,
                            Question__c,
                            SurveyMapping__c
                        FROM
                            QuestionMappings__r
                    ),
                    (
                        SELECT
                            Id,
                            FieldApiName__c,
                            ParentSurveyMapping__c,
                            ChildSurveyMapping__c
                        FROM
                            Object_Relationship_Mappings_Child__r
                    )
                FROM
                    SurveyMapping__c
                WHERE
                    Survey__c = :Submission.Survey__c
            ]
        );

        // Get the surveyor and interviewee Name to use in each SurveyMapping
        String conditions = (Submission.Interviewee__c != null
                            ? 'Id = \'' + Submission.Interviewee__c + '\' OR '
                            : '')
                            + 'Id = \'' + Submission.Surveyor__c + '\'';
        List<Contact> submissionContactsList = (List<Contact>) DBFullAccess.QuerySObject('SELECT Id, ' +
                                                                                         'Name ' +
                                                                                         'FROM Contact ' +
                                                                                         'WHERE ' + conditions);
        submissionContacts = new Map<Id,Contact>();
        for (Contact con : submissionContactsList) {
            submissionContacts.put(con.Id,con);
        }

        // Get the list of the surveyMappings in the correct order to create and relate them
        List<SurveyMapping__c> orderedSurveyMappings =
            this.orderSurveyMappings(surveyMappingById.values());

        // Map to keep track of all the Survey Mappings with their respective created/updated SObject
        Map<Id,SObject> surveyMappingIdToSObject = new Map<Id,SObject>();

        // Iterate over the SurveyMappings objects to create/update the respective objects
        for (SurveyMapping__c surveyMapping : orderedSurveyMappings) {

            // Process each survey mapping, this include the creation of the new object and the
            // insertion in the DB of the SObjects.
            processSurveyMapping(surveyMapping, mediaFileIdByFileName);
        }
    }

    /**
     * Create all records for the given survey mapping and
     * insert them into the database.
     *
     * @param surveyMapping - The survey mapping to create/update the records from
     * @param mediaFileIdByFileName map of the media files of this submission, with filename as key and Attachement id as data.
     *
     * @return - A list of the created/updated records
     */
    private List<SObject> processSurveyMapping(SurveyMapping__c surveyMapping, Map<String, String> mediaFileIdByFileName){

        // If mapped object is not found, we can't continue processing the submission.
        // Catches NullPointerException in case no object is found for the name specified in SurveyMapping__c.
        if (!DescribeHandler.objectExists(surveyMapping.ObjectApiName__c)) {
            throw new SurveyException(
                ErrorHandlingRest.ERR_CODE_SUB_CORRUPT_FIELD_MAP,
                ErrorHandlingRest.SURVEY_SUB_BROKEN_FIELD_MAPPING,
                C.HTTP_OK,
                String.format(
                    'Unable to find SObject for API name: {0}.',
                    new List<String>{surveyMapping.ObjectApiName__c}
                ),
                false
            );
        }

        // 1. Generate the path of the associated repeated section
        List<String>  path = generateObjectPath(questions.get(surveyMapping.Repeat__c));

        //2. get all the nodes with this path.
        List<SObject> createdObjects = new List<Sobject>();
        if (path!=null){
            List<Dom.XMLNode> nodeList = new List<Dom.XMLNode>();
            fillSectionNodes(nodeList,path,root,0);

            // 3. For each time the section is repeated(for each node), call createObject
            //    with that iterations node, and its parent nodes.
            //    Store the generated object in a list.
            for (Dom.XMLNode sectionNode:nodeList){

                // Create new object and add it to the createdObjects List
                SObject newObject = createObject(surveyMapping, sectionNode, mediaFileIdByFileName);

                // If it is not a reference survey mapping add the newObject to the created objects list
                if (!surveyMapping.IsReference__c) {
                    createdObjects.add(newObject);
                }

                // Create new unique id for this mapping and add it to the dom as an attribute
                String surveyMappingId = String.valueOf(createdRecords.size());
                sectionNode.setAttribute(surveyMapping.Id, surveyMappingId);

                // Add the new object to the createdRecords list with the new id as key
                createdRecords.put(surveyMappingId, newObject);

                // Assign the relation fields of the object
                assignRelationsToObject(surveyMapping, newObject, sectionNode);
            }
       }
       else {
            SObject mappedObject = createObject(surveyMapping,root, mediaFileIdByFileName);

            // If it is not a reference survey mapping add the newObject to the created objects list
            if (!surveyMapping.IsReference__c) {
                createdObjects.add(mappedObject);
            }
            createdRecords.put(surveyMapping.Id, mappedObject);
            assignRelationsToObject(surveyMapping, mappedObject, null);
        }

        // List of mappedObjects
        List<SObject> objectsToUpdate= new List<SObject>();
        List<SObject> objectsToInsert= new List<SObject>();

        // Separete insertions and updates and perform the operations
        // (Salesforce does not allow upserts on SObject lists)
        separateExistingObjects(createdObjects,objectsToInsert,objectsToUpdate);

        DBFullAccess.insertSobject(objectsToInsert);
        DBFullAccess.updateSobject(objectsToUpdate);
        return createdObjects;
    }

    /**
    * Assign the relationship fields set for a mapped object
    * @param createdObjects the list of all the objects
    * @param objectsToInsert empty list to fill up with the new objects
    * @param objectsToUpdate empty list to fill up with the existing objects
    **/
    private void assignRelationsToObject(SurveyMapping__c surveyMapping,SObject mappedObject,Dom.XMLNode node){

        // Iterate over the junction objects where surveyMapping is the child
        for (ObjectRelationshipMapping__c relationshipMapping  :surveyMapping.Object_Relationship_Mappings_Child__r){
            //if the parent is a repeat section,get the id
            //else use the surveyMapping id to get the data
            SurveyMapping__c parentMapping = surveyMappingById.get(relationshipMapping.ParentSurveyMapping__c);
            if (parentMapping.Repeat__c == null){
                //assign the relation
                mappedObject.put(relationshipMapping.FieldApiName__c, createdRecords.get(parentMapping.Id).Id);
            }else{

                String sectionName = questions.get(parentMapping.Repeat__c).Name;

                //get the id of the surveyMapping section
                String surveyMappingId = '';
                Dom.XMLNode CurrentNode = node;
                if (CurrentNode != null){
                    while (CurrentNode != null && String.isBlank(surveyMappingId)){
                        if (CurrentNode.getName() == sectionName){
                            surveyMappingId = CurrentNode.getAttribute(relationshipMapping.ParentSurveyMapping__c, null);
                        }
                        currentNode = currentNode.getParent();
                    }
                    //assign the relation
                mappedObject.put(relationshipMapping.FieldApiName__c, createdRecords.get(surveyMappingId).Id);
                }
            }

        }
    }

    /**
    * Helper method that separete the objects to update and the ones for insertion
    * (salesforce does not allow upsert on list of generic objects)
    * @param createdObjects the list of all the objects
    * @param objectsToInsert empty list to fill up with the new objects
    * @param objectsToUpdate empty list to fill up with the existing objects
    **/
    private void separateExistingObjects(
            List<SObject> createdObjects,
            List<SObject> objectsToInsert,
            List<SObject> objectsToUpdate
    ) {
        for (SObject obj : createdObjects) {
            GenericObjectCreator sObjectCreator =
                new GenericObjectCreator(obj.getSObjectType());
            sObjectCreator.checkObjectAccessible();
            if (obj.Id == null) {
                sObjectCreator.checkObjectCreateable();
                objectsToInsert.add(obj);
            } else {
                sObjectCreator.checkObjectUpdateable();
                objectsToUpdate.add(obj);
            }
        }
    }

    /**
    * Given a SurveyMapping__c, return the list of strings that conform its path.
    * @param surveyMapping the survey mapping to process
    * @return a list of strings that conform the path of the repeated section.
    */
    private List<String> generateObjectPath(Question__c question){
        List<String> path= null;
        //if the surveyMappings belongs to a repeat section get the complete path
        if (question != null){
            Question__c currentQuestion = question ;
            path = new List<String>();
            while (currentQuestion != null){
                path.add(currentQuestion.Name);
                CurrentQuestion= questions.get(CurrentQuestion.Parent__c);
            }
        }
        return path;
    }

    /**
    * Given a path (list of strings), fills the given list of XMLNodes with
    * all nodes in the submission.xml that match that path.
    * @param nodeList the list of nodes to fill.
    * @param path the list of strings that conform the path.
    * @currentNode the current XMLNode to process.
    * @param depth the depth level of the current iteration.
    */
    private void fillSectionNodes(
           Dom.XMLNode[] nodeList,
           String[] path,
           Dom.XMLNode currentNode,
           Integer depth){

        //get the children nodes
        String nextNodeName = path[(path.size() -1)-depth ];
        Dom.XMLNode[] children = currentNode.getChildElements();
        Boolean lastDepth = (depth == path.size() -1);
        for (Dom.XMLNode child:children){
            if (child.getName() == nextNodeName){
                //if the node its the repeated section add it to the list, otherwise
                //process the child node as well.
                if(lastDepth){
                    nodeList.add(child);
                }else {
                    fillSectionNodes(nodeList,path,child,depth + 1);
                }
            }
        }
    }


    /**
     * Creates a record of the mapped object for the current iteration
     * of its associated repeated section.
     * Does not insert the record in the databse.
     *
     * @param surveyMapping the survey mapping to generate the related object
     * @param node XMLNode for the sections current iteration.
     * @param mediaFileIdByFileName map of the media files of this submission, with filename as key and Attachement id as data.
     *
     * @return the generated record.
     */
    private SObject createObject(
            SurveyMapping__c surveyMapping,
            Dom.XMLNode node,
            Map<String, String> mediaFileIdByFileName
    ) {

        Map<String,String> fieldToAnswer = new Map<String,String>();

        // Boolean to track if a required field is null
        Boolean isRequiredAnswerNull = false;

        // The new object and describe of the object and fields
        SObject mappedObject;
        Map<String, Schema.SObjectField> fieldDescribeMap =
            DescribeHandler.getFieldMap(surveyMapping.ObjectApiName__c);

        // Boolean to set if the matching field was found
        String matchingAnswer =
            checkReferenceInSubmissionData(surveyMapping, currentSubmission, fieldDescribeMap);
        Boolean referenceFieldFound = (matchingAnswer != '');

        // Iterate over the list of Question Mappings
        for (QuestionMapping__c qm : surveyMapping.QuestionMappings__r) {

            // Get the mapped question
            Question__c mappedQuestion = questions.get(qm.Question__c);

            // Search the answer in the node
            Dom.XMLNode answer = node.getChildElement(mappedQuestion.Name, null);

            if (mappedQuestion.Parent__r.Name != node.getName()) {

                // If the parent is not the current node it could be in a lower node
                // This is for section or cascading select questions within a repeated section
                if (answer == null) {
                    answer = findLowerAnswerNode(mappedQuestion.Name, node);
                }

                // Or in an upper node
                if (answer == null) {
                    Dom.XMLNode CurrentNode = node.getParent();
                    if (CurrentNode != null) {
                        while (answer == null && CurrentNode != null) {
                            answer = CurrentNode.getChildElement(mappedQuestion.Name, null);
                            CurrentNode = CurrentNode.getParent();
                        }
                    }
                }

                // If the answer is not in an upper node search in the path
                if (answer == null) {
                    List<String> path = generateObjectPath(mappedQuestion);

                    // Search from the root all along his path
                    Dom.XMLNode currentNode = root;

                    // Navigate to the correct node
                    while (currentNode != null && path.size() != 0) {

                        // Get the first element of the path stack and remove it
                        currentNode = currentNode.getChildElement(path.remove(path.size()-1), null);
                    }

                    // If the last node was found, search the answer
                    if (currentNode != null) {
                        answer = currentNode;
                    }
                }
            }
            if (answer != null) {
                if (String.isBlank(answer.getText()) && !fieldDescribeMap.get(qm.FieldApiName__c).getDescribe().isNillable()) {
                    isRequiredAnswerNull = true;
                }

                // If the question is a radio or checkbox, use the caption of the option to the field
                String AnswerText = answer.getText();
                if (
                        questions.get(qm.Question__c).Type__c == QuestionDO.TYPE_CHECKBOX
                        || questions.get(qm.Question__c).Type__c == QuestionDO.TYPE_RADIO
                ) {
                    AnswerText = parseSelectionQuestion(AnswerText);
                } else if (QuestionDO.isMedia(questions.get(qm.Question__c).Type__c)) {
                    AnswerText = String.isBlank(mediaFileIdByFileName.get(AnswerText))
                        ? ''
                        : C.SALESFORCE_INSTANCE + C.DOWNLOAD_ATT_URL + mediaFileIdByFileName.get(AnswerText);
                }

                fieldToAnswer.put(qm.FieldApiName__c, AnswerText);

                if (qm.FieldApiName__c == surveyMapping.MatchingField__c) {
                    matchingAnswer = AnswerText;
                    referenceFieldFound = true;
                }

            } else if (!fieldDescribeMap.get(qm.FieldApiName__c).getDescribe().isNillable()) {
                isRequiredAnswerNull = true;
            }
        }

        // Get the object from the DB or create new one
        if (referenceFieldFound) {

            // Checking if numeric or string matching data,to generate the query correctly
            Schema.SOAPType fieldSoapType = fieldDescribeMap.get(surveyMapping.MatchingField__c).getDescribe().getSOAPType();

            if (fieldSoapType==Schema.SOAPType.Integer || fieldSoapType==Schema.SOAPType.Double){
                if (!isNumeric(matchingAnswer)) {
                    throw new SurveyException(
                        ErrorHandlingRest.ERR_CODE_SUB_BAD_FIELD_MAP,
                        ErrorHandlingRest.SURVEY_SUB_FIELD_MAPPING_ERROR,
                        C.HTTP_INTERNAL_SERVER_ERROR,
                        surveyMapping.MatchingField__c + ' matching field is numeric but has a non-numerical value',
                        true
                    );
                }
            }
            else {
                matchingAnswer =  '\'' + String.escapeSingleQuotes(matchingAnswer) + '\'';
            }
            GenericObjectCreator genericObjectCreator =
                new GenericObjectCreator(
                    DescribeHandler.getGlobalDescribe().get(surveyMapping.ObjectApiName__c)
                );
            genericObjectCreator.checkObjectAccessible();
            genericObjectCreator.checkFieldsAccessible(new List<String> {
                surveyMapping.MatchingField__c
            });

            SObject[] queryResult = DBFullAccess.QuerySObject(
                ' SELECT Id' +
                ' FROM ' + surveyMapping.ObjectApiName__c +
                ' WHERE ' + surveyMapping.MatchingField__c + '=' + matchingAnswer
            );
            if (queryResult.size() > 0) {
                mappedObject = queryResult[0];
            }
            else {
                if (isRequiredAnswerNull) {
                    throw new SurveyException(
                        ErrorHandlingRest.ERR_CODE_SUB_BAD_FIELD_MAP,
                        ErrorHandlingRest.SURVEY_SUB_FIELD_MAPPING_ERROR,
                        C.HTTP_INTERNAL_SERVER_ERROR,
                        'Cannot submit, the answer is empty and is mapped to a required field: '
                            + surveyMapping.MatchingField__c,
                        true
                    );
                }
            }
        }

        // If the mapping is for a reference object and the object has not been found then throw an error
        if (mappedObject == null && surveyMapping.IsReference__c) {
            throw new SurveyException(
                ErrorHandlingRest.ERR_CODE_SUB_MISSING_REF_OBJECT,
                ErrorHandlingRest.SURVEY_SUB_MISSING_REF_OBJECT,
                C.HTTP_INTERNAL_SERVER_ERROR,
                'Record of type: ' + surveyMapping.ObjectApiName__c + ' with identifier for field: ' +
                    surveyMapping.MatchingField__c + ' with idenifying value of: ' +
                    matchingAnswer + ' cannot be found on the org',
                true
            );
        }

        // If the object was not found and this is not a reference survey mapping, create the object
        if (mappedObject == null && !surveyMapping.IsReference__c) {
            Schema.SObjectType targetType =
                DescribeHandler.getGlobalDescribe().get(surveyMapping.ObjectApiName__c);
            GenericObjectCreator genericObjectCreator =
                new GenericObjectCreator(targetType);
            mappedObject = genericObjectCreator.createNewRecord();
        }

        // If the survey mapping is a reference the do not update any fields
        if (!surveyMapping.IsReference__c) {

            // Assign the submission data to the SObject field
            assignSubmissionData(mappedObject, surveyMapping, submissionContacts, fieldDescribeMap, currentSubmission);

            // Fill the values of the object
            setFieldValues(mappedObject, fieldToAnswer, fieldDescribeMap);
        }
        return mappedObject;
    }

    /**
     * Look for the answer node in the children of the node
     *
     * @param   questionName    the name of the question to find
     * @param   node            the node to look inside
     * @return                  the node corresponding to the answer of the
     *                          option or null if not found
     */
    private Dom.XmlNode findLowerAnswerNode(String questionName, Dom.XmlNode node) {
        // Look in the children
        Dom.XmlNode answer = node.getChildElement(questionName, null);

        if(answer == null) {
            // If not found dig in each child
            for(Dom.XmlNode child : node.getChildElements()) {
                answer = findLowerAnswerNode(questionName, child);

                // Stop when found
                if(answer != null) {
                    break;
                }
            }
        }

        return answer;
    }

     /**
     * Parse the options ids in a string to their correct caption in a semicolon separated list format
     *
     * @param mappedObject
     * @return a semicolon separated list of selected captions
     *
     */
   private String parseSelectionQuestion(String AnswerText){
		String answerWithCaption = '';
		if (AnswerText != ''){
			List<String> checkedAnswers = AnswerText.split(' ', 0);
			answerWithCaption = '';
			for (String s:checkedAnswers){
				answerWithCaption += (answerWithCaption == '' ? '' : ';') + optionsMap.get(s).Caption__c;
			}
		}
        return answerWithCaption;
    }

    /**
     * Set the values of the mappedObject with the field to answer data
     *
     * @param mappedObject
     * @param fieldToAnswer
     * @param fieldDescribeMap
     *
     */
    private void setFieldValues(
            SObject mappedObject,
            Map<String,String> fieldToAnswer,
            Map<String, Schema.SObjectField> fieldDescribeMap
    ) {

        Map<Schema.SObjectField, Object> newFields = new Map<Schema.SObjectField, Object>();
        for (String field : fieldToAnswer.keySet()) {
            newFields.put(fieldDescribeMap.get(field), fieldToAnswer.get(field));
        }
        GenericObjectCreator genericObjectCreator =
            new GenericObjectCreator(mappedObject.getSObjectType());
        genericObjectCreator.setSkipBlanks(true);
        genericObjectCreator.populateFields(mappedObject, newFields);
    }

     /**
     * Assing Submission data to mapped Sobject
     *
     * @param mappedObject
     * @param SurveyMapping
     * @param contacts contact map with Id as key
     * @param fieldDescribeMap map with the fields describes with field name(string) as key
     * @param submission submission generated in this submit
     *
     */

    private void assignSubmissionData(
            SObject mappedObject,
            SurveyMapping__c surveyMapping,
            Map<Id,Contact> contacts,
            Map<String, Schema.SObjectField> fieldDescribeMap,
            Submission__c submission
    ) {

        Contact surveyor = contacts.get(submission.Surveyor__c);
        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectAccessible();
        submissionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Submission__c.Surveyor__c,
                Submission__c.Survey__c,
                Submission__c.PPIScore__c,
                Submission__c.SurveyVersion__c
            }
        );
        //set the owner of the mapped sobject as the owner of the survey
        if( (mappedObject.get('Id') == null)
            && (fieldDescribeMap.get('OwnerId') !=null) ) {
            mappedObject.put('OwnerId',surveyMapping.Survey__r.OwnerId);
        }


        //fill the fields with submission data
        if(surveyMapping.SubmissionApiField__c!= null && surveyMapping.SubmissionApiField__c!='')
            mappedObject.put(surveyMapping.SubmissionApiField__c,Submission.Id);


        if(surveyMapping.SurveyApiField__c!= null && surveyMapping.SurveyApiField__c!='')
            mappedObject.put(surveyMapping.SurveyApiField__c,Submission.Survey__c);


        if(surveyMapping.PPIScoreApiField__c!= null && surveyMapping.PPIScoreApiField__c!='')
            mappedObject.put(surveyMapping.PPIScoreApiField__c,Submission.PPIScore__c);

        if(surveyMapping.SurveyVersionApiField__c!= null && surveyMapping.SurveyVersionApiField__c!=''){
        //if the survey Version field is numeric,fill it with version number,otherwise assign the survey version object
            if(fieldDescribeMap.get(surveyMapping.SurveyVersionApiField__c).getDescribe().getSOAPType()==Schema.SOAPType.Double){
                mappedObject.put(surveyMapping.SurveyVersionApiField__c,surveyMapping.Survey__r.Version__c);
            }else{
                mappedObject.put(surveyMapping.SurveyVersionApiField__c,Submission.SurveyVersion__c);
            }
        }

        if(surveyMapping.SurveyorApiField__c!= null && surveyMapping.SurveyorApiField__c!=''){
            if(fieldDescribeMap.get(surveyMapping.SurveyorApiField__c).getDescribe().getSOAPType()==Schema.SOAPType.String){
                mappedObject.put(surveyMapping.SurveyorApiField__c,surveyor.Name);
            }else{
                mappedObject.put(surveyMapping.SurveyorApiField__c,surveyor.Id);
            }
        }


    }
     /**
     * Order a SurveyMapping List according to their "parent level"
     * this is: the surveyMappings that are not parent goes first,
     * the ones that are parents of one second,and continue to the last
     * parent level
     *
     * @param surveyMappings
     * @return the ordered list of conditions
     *
    */
    private List<SurveyMapping__c> orderSurveyMappings(List<SurveyMapping__c> surveyMappings){

        //create new List to set the correct order of the list
        Set<Id> orderedMappings = new Set<Id>();

        //Used a list to return the ordered list, because the map.values does not conserve the order
        List<SurveyMapping__c> orderedMappingList = new List<SurveyMapping__c>();

        while(surveyMappings.size()!= orderedMappings.size()){
            //add the survey Mappings that has no parents, can be parents or not belong to any relation
            for (SurveyMapping__c sm:surveyMappings){
                if(!orderedMappings.contains(sm.Id)){
                    // Check that all the parent of the survey mapping were added before
                    // Use true by default in case the object doesn't have parents
                    Boolean parentsInList = true;
                    // Iterate over the junction objects where the survey mapping is the child to get the parents
                    for(ObjectRelationshipMapping__c relationshipMapping  :sm.Object_Relationship_Mappings_Child__r){
                        parentsInList = parentsInList &&
                                        orderedMappings.contains(relationshipMapping.ParentSurveyMapping__c);
                    }

                    if (parentsInList){
                        orderedMappings.add(sm.Id);
                        orderedMappingList.add(sm);
                    }
                }
            }
        }
        return orderedMappingList;
    }

    /**
    * Check if the Id field to reference the object is in a survey data
    * and saved the reference answer.
    *
    * @param surveyMapping     - The survey mapping.
    * @param currentSubmission - Submission object of the current submission.
    * @param fieldDescribeMap  - map with the field describes with field name(string) as key
    * @return - The matching answer.
    */
    private String checkReferenceInSubmissionData(
            SurveyMapping__c sm,
            Submission__c submission,
            Map<String, Schema.SObjectField> fieldDescribeMap
    ) {

        String matchingAnswer = '';
        Contact surveyor = submissionContacts.get(submission.Surveyor__c);
        Contact interviewee = submissionContacts.get(submission.Interviewee__c);

        if (String.isNotBlank(sm.MatchingField__c)) {
            if (
                    String.isNotBlank(sm.SurveyorApiField__c) && 
                    sm.SurveyorApiField__c == sm.MatchingField__c
                ) {
                if (
                        fieldDescribeMap.get(sm.SurveyorApiField__c).getDescribe().getSOAPType() ==
                        Schema.SOAPType.String
                ) {
                    matchingAnswer = surveyor.Name;
                } else {
                    matchingAnswer = surveyor.Id;
                }
            } else if (
                    String.isNotBlank(sm.SurveyApiField__c) 
                    && sm.SurveyApiField__c == sm.MatchingField__c
            ) {
                matchingAnswer = submission.Survey__c;
            } else if (
                    String.isNotBlank(sm.SurveyVersionApiField__c) &&
                    sm.SurveyVersionApiField__c == sm.MatchingField__c
            ) {

                // If the survey Version field is numeric,fill it with version number,
                // otherwise assign the survey version object
                if (
                        fieldDescribeMap.get(sm.SurveyVersionApiField__c).getDescribe().getSOAPType()
                        == Schema.SOAPType.Double
                ) {
                    matchingAnswer = String.ValueOf(sm.Survey__r.Version__c);
                } else {
                    matchingAnswer = submission.SurveyVersion__c;
                }
            } else if (
                    String.isNotBlank(sm.PPIScoreApiField__c) &&
                    sm.PPIScoreApiField__c == sm.MatchingField__c
            ) {
                matchingAnswer = String.ValueOf(submission.PPIScore__c);
            } else if (
                    String.isNotBlank(sm.SubmissionApiField__c)
                    && sm.SubmissionApiField__c == sm.MatchingField__c
            ) {
                matchingAnswer = submission.Id;
            }
        }
        return matchingAnswer;
    }

    /**
    * Check if a String is a numeric value
    *
    * @param String to check
    * @return true if the param is a valid numeric value,false otherwise
    *
    */
    private boolean isNumeric(String data){
        try {
            Double.valueOf(data);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}