/**
 * Class to process some fo the services exposed to the mobile application
 * TODO - Update class based on SOC and UoW
 * 
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class ServicesController {

    /***************************************************************************
     * Code for the FormList processes. I hope to remove this if we stop supporting
     * Vanilla ODK
     **************************************************************************/

    public String form {get; set;}
    public String msg {get; set;}

    /**
     * Process a request to the formList page.
     * This method should not be used by our application and is kept for
     * backwards compatibility.
     */
    public PageReference process() {

        //-------------------------------------------------------------------------------
        // This code is for the automated tests only and should be removed.
        //
        // Check if its a Flag creation operation,
        // if it is not, continue the normal flow
        if (ApexPages.currentPage().getParameters().containsKey('flag')) {
            processFlag();
            return null;
        }
        //-------------------------------------------------------------------------------

        Id surveyVersionId = ApexPages.currentPage().getParameters().get('id');

        // Authenticate the MobileUser
        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            ApexPages.currentPage().getHeaders().get(C.USERNAME_HEADER),
            ApexPages.currentPage().getHeaders().get(C.PASSWORD_HEADER),
            '',
            false
        );

        if (loginResult.hasError) {
            this.form = '<error>' + ErrorHandlingRest.getErrorJson() + '</error>';
        }
        else {
            this.form = processDataAux(surveyVersionId, loginResult.getContact().Id);
        }
        Apexpages.currentPage().getHeaders().put('X-OpenRosa-Version', '1.0');
        return ApexPages.currentPage();
    }

    /**
     * Auxiliary method to do the processing and retrieval of forms
     *
     * @param   surveyVersionId The Id of the survey to download. If null,
     *                          returns the list of surveys the user can download.
     * @param   contactId       The contact id of the mobile user
     * @return                  Xml with the forms
     */
    public String processDataAux(Id surveyVersionId, Id contactId) {

        XFormCreator x = new XFormCreator();
        String result = '';
        if (surveyVersionId == null) {
            
            // No surveyVersionId passed so get list of all forms available
            // This method can be removed in 3.0 as it is redundant but we are too close
            // to release to risk removing it now.
            result = x.getXmlAllSurveys('', contactId).toXmlString();

            /**
             * Code below needs to be added back in for 3.0
             *  too close to release to refactor this code now
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_SURVEY_ID_MISSING,
                ErrorHandlingRest.SURVEY_FORMLIST_ID_MISSING,
                'Survey Id has not been supplied'
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_BAD_REQUEST);
            */
        } else {

            // Get the specific survey xForm that matches the surveyVersionId
            result = this.getSurvey(surveyVersionId);
        }
        return result;
    }
    /**********************************************************************************************
     * Remove to this point
     *********************************************************************************************/

    // Map of question names to the questions themselves
    private Map<Id, Question__c> allQuestionsById;

    // Map of question names to the questions themselves
    private Map<String, Question__c> allQuestionsByName;

    // Map of questions that have the PpiResultsField__c added. Key is the PpiResultsField__c
    private Map<String, Question__c> ppiQuestions;

    // Map of all the options in the survey
    private Map<Id, Option__c> optionsMap;

    // Map of the PPI ScorceValues to their options
    private Map<Id, Decimal> ppiScoreValues;

    // Map of the answers to the questions.
    // Key is Question__c.Name + SPLITTER + Answer__c.Instance__c
    private Map<String, Answer__c> allAnswersMap;

    // Set of the ids for cascading select questions
    private Set<Id> cascadingSelects;

    // A map with all the values for each cascading level
    private Map<Id, Set<String>> cascadingValuesByLevel;

    // A map with the possible values for a parent value
    private Map<String, Set<String>> cascadingValuesByParent;

    // A map with the answers of the cascading level questions
    private Map<Id, String> cascadingAnswersByQuestion;

    private UnitOfWork unitOfWork;
    private static final String SPLITTER = '_#@#_';

    /**
     * Get the xform for a surveyVersion
     *
     * @param surveyVersionId - The SurveyVersion__c.Id that is being fetched
     */
    public String getSurvey(Id surveyVersionId) {

        XFormCreator x = new XFormCreator();
        SurveyVersion__c version =
            (SurveyVersion__c) new SurveyVersionSelector().getRecordById(surveyVersionId);

        String result = '';
        if (version != null) {
            List<Attachment> attachments =
                new AttachmentSelector().getAllWithParentIdOrdered(
                    new Set<Id> {surveyVersionId},
                    XFormCreator.XFORM_ATTACHMENT
                );
            if (attachments.size() != 1) {
                ErrorHandlingRest.addErrorMsg(
                    ErrorHandlingRest.ERR_CODE_SURVEY_MISSING_XFORM,
                    ErrorHandlingRest.SURVEY_FORMLIST_NO_XFORM,
                    'Survey with Id: ' + surveyVersionId + ' does not have an xForm attached'
                );
                ErrorHandlingRest.setStatusCode(C.HTTP_NOT_FOUND);
            } else {
                result = attachments[0].body.toString();
                if (String.isEmpty(result)) {
                    ErrorHandlingRest.addErrorMsg(
                        ErrorHandlingRest.ERR_CODE_SURVEY_BLANK_XFORM,
                        ErrorHandlingRest.SURVEY_FORMLIST_XFORM_EMPTY,
                        'Survey with Id: ' + surveyVersionId + ' xform is empty'
                    );
                ErrorHandlingRest.setStatusCode(C.HTTP_NOT_FOUND);
                }
            }
        } else {
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_SURVEY_ID_NOT_EXIST,
                ErrorHandlingRest.SURVEY_FORMLIST_ID_INVALID,
                'Survey Id ' + surveyVersionId + ' is not available'
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_NOT_FOUND);
        }
        return result;
    }

    /**
     * Parse the XML of a submission.
     * Fills in the Submission__c record, creates the Answer objects
     * and carried out the field mapping
     *
     * @param surveyorId - The Contact.Id of the surveyort
     * @param submission - The submission validation object that holds the data
     *                       about the submission
     *
     * @return - The submission object that has been updated
     */
    public Submission parseSubmission(
            String surveyorId,
            Submission submission
    ) {

        // Initialize the xml reader
        Xmlstreamreader xmlReader = new Xmlstreamreader(submission.getSubmissionXml());

        String submissionId = submission.getExistingSubmissionId();

        // Find the Survey name and id
        String surveyName = findSurveyName(xmlReader);

        GenericObjectCreator answerCreator =
            new GenericObjectCreator(Answer__c.SObjectType);
        answerCreator.checkObjectAccessible();
        answerCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Answer__c.Submission__c,
                Answer__c.Question__c,
                Answer__c.Option__c,
                Answer__c.Instance__c,
                Answer__c.TextAreaValue__c,
                Answer__c.Value__c,
                Answer__c.NumericValue__c,
                Answer__c.DateValue__c,
                Answer__c.DateTimeValue__c,
                Answer__c.TextAreaValue__c
            }
        );
        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        submissionCreator.checkObjectAccessible();
        submissionCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Submission__c.Status__c,
            Submission__c.Survey__c,
            Submission__c.SurveyVersion__c,
            Submission__c.Surveyor__c,
            Submission__c.PPIScore__c
        });

        this.loadAllQuestions(submission.getVersion().Survey__c);

        // Load the data needed to validate answers for cascading select questions
        this.loadCascadingData(cascadingSelects);

        this.optionsMap = new Map<Id, Option__c>(
            new OptionSelector().getAllForSurveyOrdered(submission.getVersion().Survey__c)
        );

        // Build a map of the attachments for the media files of the submission
        Map<String, String> mediaFileIdByFileName = this.loadMediaFiles(submissionId);

        Submission__c su = submission.getExistingSubmission();

        // Get the submission data from the xml. Moves the cursor on the XmlReader to the start
        // of the survey proper (past the header)
        this.parseSubmissionData(xmlReader, submission);

        // Set other submission data
        submissionCreator.populateFields(
            su,
            new Map<Schema.SObjectField, Object> {
                Submission__c.SurveyVersion__c => submission.getVersion().Id,
                Submission__c.Surveyor__c => surveyorId
            }
        );
        if (!submission.getFailedFieldMapping()) {
            submissionCreator.populateFields(
                su,
                new Map<Schema.SObjectField, Object> {
                    Submission__c.Status__c => C.SUBMISSION_STATUS_UPLOADED
                }
            );
        }

        submissionCreator.checkObjectCreateable();
        submissionCreator.checkObjectUpdateable();
        DBFullAccess.upsertSObject(su);

        // The current stack of the repeated sections
        List<Answer> currentRepeatStack = new List<Answer>();

        // The root Answers for the Repeated Questions
        List<Answer> rootAnswers = new List<Answer>();

        // Map to keep track of the Last instance number for each repeat question answer
        Map<String, Integer> questionToInstanceNumber = new Map<String, Integer>();

        // Read through the Question + Answer
        Boolean endOfXml = false;
        while (xmlReader.hasNext() && !endOfXml) {

            if (xmlReader.getEventType() == XmlTag.END_ELEMENT) {
                Question__c question = allQuestionsByName.get(xmlReader.getLocalName());
                if (xmlReader.getLocalName() == surveyName) {
                    endOfXml = true;
                } else if (question != null && question.Type__c == QuestionDO.TYPE_REPEAT) {
                    currentRepeatStack.remove(currentRepeatStack.size() - 1);
                }
                xmlReader.next();
                continue;
            } else if (xmlReader.getEventType() == XmlTag.START_ELEMENT) {

                // Save the Questions Answer of the Survey Answer in the header
                Question__c question = allQuestionsByName.get(xmlReader.getLocalName());
                if (
                        question != null &&
                        question.Type__c != QuestionDO.TYPE_SECTION &&
                        question.Type__c != QuestionDO.TYPE_REPEAT &&
                        question.Type__c != QuestionDO.TYPE_CASCADING_SELECT
                ) {

                    // If the answer is not a child of a repeat-section process as always
                    if (currentRepeatStack.isEmpty()) {
                        if (
                                question.Type__c == QuestionDO.TYPE_CHECKBOX ||
                                question.Type__c == QuestionDO.TYPE_RADIO
                        ) {
                            this.parseCheckboxQuestion(
                                xmlReader,
                                question,
                                su,
                                optionsMap,
                                rootAnswers,
                                null
                            );
                        } else {
                            this.parseSimpleQuestion(
                                xmlReader,
                                question,
                                su,
                                rootAnswers,
                                mediaFileIdByFileName,
                                null
                            );
                        }
                    } else {
                        // If the answer is a child of a repeated-section, add the answers in the map
                        // of their respective parent
                        // Get the parent repeat-section of the question
                        Answer parentSectionAnswer = currentRepeatStack[currentRepeatStack.size() - 1];
                        List<Answer> childAnswerList = parentSectionAnswer.childAnswers;
                        if (
                                question.Type__c == QuestionDO.TYPE_CHECKBOX ||
                                question.Type__c == QuestionDO.TYPE_RADIO
                        ) {
                            this.parseCheckboxQuestion(
                                xmlReader,
                                question,
                                su,
                                optionsMap,
                                childAnswerList,
                                Integer.ValueOf(parentSectionAnswer.AnswerObj.Instance__c)
                            );
                        } else {
                            this.parseSimpleQuestion(
                                xmlReader,
                                question,
                                su,
                                childAnswerList,
                                mediaFileIdByFileName,
                                Integer.ValueOf(parentSectionAnswer.AnswerObj.Instance__c)
                            );
                        }
                    }
                } else if (question != null && question.Type__c == QuestionDO.TYPE_REPEAT) {

                    // If the tag is a repeat section type, add it to the map (in the case is not already added)
                    // and create the Answer, continue with the parsing.
                    // If there is no repeat in the stack, it means the repeated section has no parents(its a root)
                    if (currentRepeatStack.isEmpty()) {

                        // If it's a root question assign it's instance
                        if (!questionToInstanceNumber.containsKey(question.Name)) {
                            questionToInstanceNumber.put(question.Name, 1);
                        } else {
                            questionToInstanceNumber.put(
                                question.Name,
                                questionToInstanceNumber.get(question.Name) + 1
                            );
                        }
                        Answer__c answerInstance = (Answer__c) answerCreator.createNewRecord();
                        answerCreator.populateFields(
                            answerInstance,
                            new Map<Schema.SObjectField, Object> {
                                Answer__c.Submission__c => su.Id,
                                Answer__c.Instance__c => questionToInstanceNumber.get(question.Name),
                                Answer__c.Question__c => question.Id
                            }
                        );
                        Answer repeatedSectionAnswer = new Answer(answerInstance);
                        rootAnswers.add(repeatedSectionAnswer);
                        currentRepeatStack.add(repeatedSectionAnswer);
                    } else {

                        // Create a new repeated section
                        // Get the last element in the stack
                        Answer parentSection = currentRepeatStack[currentRepeatStack.size() - 1];

                        // Keep the instance of the repeat section
                        // Add the new answer to the parent tree node
                        Answer__c answerInstance = (Answer__c) answerCreator.createNewRecord();
                        answerCreator.populateFields(
                            answerInstance,
                            new Map<Schema.SObjectField, Object> {
                                Answer__c.Submission__c => su.Id,
                                Answer__c.Question__c => question.Id
                            }
                        );
                        Answer repeatChildAnswer = new Answer(answerInstance);
                        parentSection.childAnswers.add(repeatChildAnswer);

                        // Add the answer to the stack
                        currentRepeatStack.add(repeatChildAnswer);
                    }
                }
            }
            xmlReader.next();
        }

        // Insert all the parent questions
        // Insert answers;
        // Insert all the answer per levels.
        List<Answer> tempList = rootAnswers;
        List<Answer__c> answersToInsert = new List<Answer__c>();
        List<Answer__c> allAnswers = new List<Answer__c>();

        for (Answer ans : tempList) {
            answersToInsert.add(ans.AnswerObj);
        }

        answerCreator.checkObjectCreateable();
        answerCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Answer__c.Submission__c,
                Answer__c.Question__c,
                Answer__c.Option__c,
                Answer__c.Instance__c,
                Answer__c.TextAreaValue__c,
                Answer__c.Value__c,
                Answer__c.NumericValue__c,
                Answer__c.DateValue__c,
                Answer__c.DateTimeValue__c,
                Answer__c.TextAreaValue__c
            }
        );
        insert AnswersToInsert;

        allAnswers.addAll(answersToInsert);

        while (!templist.isEmpty()) {
            // Algorithm to insert list
            answersToInsert = new List<Answer__c>();

            // A list of all the child answers of the inserted
            List<Answer> childAnswers = new List<Answer>();
            for (Answer ans : tempList) {
                if (allQuestionsById.get(ans.AnswerObj.Question__c).Type__c ==  QuestionDO.TYPE_REPEAT) {

                    // Map to keep track of the Last instance number for each repeat question answer
                    Map<String, Integer> questionInstance = new Map<String, Integer>();
                    for (Answer child : ans.childAnswers) {

                        // Assign the correct instance
                        if (child.AnswerObj.Instance__c == null) {
                            String QuestionName = allQuestionsById.get(child.AnswerObj.Question__c).Name;
                            if (!questionInstance.containsKey(QuestionName)) {
                                questionInstance.put(QuestionName, 1);
                            } else {
                                questionInstance.put(QuestionName, questionInstance.get(QuestionName) + 1);
                            }
                            child.AnswerObj.Instance__c = questionInstance.get(QuestionName);
                        }
                        child.AnswerObj.Parent__c = ans.AnswerObj.Id;
                        answersToInsert.add(child.AnswerObj);
                    }
                    childAnswers.addAll(ans.childAnswers);
                }
            }
            templist = childAnswers;
            insert answersToInsert;
            allAnswers.addAll(answersToInsert);
        }

        // Calculate the scores
        calculateScores(allAnswers, submission.getVersion().Survey__c, submissionId);

        // If it's a PPI survey calculates the PPI scores too
        if (submission.getVersion().Survey__r.IsPPI__c) {

            // Allows for the old method to still parse
            Decimal newPpiScore;

            if (ppiQuestions.size() == 0) {
                calculatePPIScores(
                    allAnswers,
                    submission.getVersion(),
                    submission.getExistingSubmission()
                );
                
                Submission__c submissionRecord = (Submission__c)
                    new SubmissionSelector().getRecordById(submission.getExistingSubmissionId());
                newPpiScore = submissionRecord.PPIScore__c;

            } else {
                newPpiScore = generatePpiScore(submission);
            }
            submissionCreator.populateFields(
                su,
                new Map<Schema.SObjectField, Object> {
                    Submission__c.PPIScore__c => newPpiScore
                }
            );
        }
        // If it is broken do not create the mapped objects
        if (!submission.getFailedFieldMapping()) {

            // Create the mapped objects
            new MappedObjectsCreator().generateObjects(
                su,
                submission.getSubmissionXml(),
                mediaFileIdByFileName
            );
        }
        update su;
        return submission;
    }

    /**
     * Find the name of the survey from the submission XML
     */
    private String findSurveyName(Xmlstreamreader xmlReader) {
        String surveyName = '';
        Boolean surveyFound = false;
        while (xmlReader.hasNext() && !surveyFound) {
            if (xmlReader.getEventType() == XmlTag.START_ELEMENT) {
                surveyName = xmlReader.getLocalName();
                surveyFound = true;
            }
            xmlReader.next();
        }
        return surveyName;
    }

    /**
     * Load all the questions for the Survey
     */
    private void loadAllQuestions(Id surveyId) {

        this.allQuestionsById = new Map<Id, Question__c>(
            new QuestionSelector().getAllForSurveyIds(new Set<String> {surveyId})
        );
        this.ppiQuestions = new Map<String, Question__c>();

        this.cascadingSelects = new Set<Id>();
        this.allQuestionsByName = new Map<String, Question__c>();
        for (Question__c question : allQuestionsById.values()) {

            this.allQuestionsByName.put(question.Name, question);
            if (question.Type__c == QuestionDO.TYPE_CASCADING_SELECT) {
                cascadingSelects.add(question.CascadingSelect__c);
            }
            if (String.isNotBlank(question.PpiResultsField__c)) {
                this.ppiQuestions.put(question.PpiResultsField__c, question);
            }
        }
    }

    /**
     * Load the PPI Scoring Group
     */
    private void loadPpiScoringGroup(Id surveyId) {
        List<ScoreValue__c> scoreValues =
            new ScoreValueSelector().getAllForSurveyPpi(surveyId, false);
        this.ppiScoreValues = new Map<Id, Decimal>();
        for (ScoreValue__c scoreValue : scoreValues) {
            this.ppiScoreValues.put(scoreValue.Option__c, scoreValue.Value__c);
        }
    }

    /**
     * Load any attachments already submitted
     */
    private Map<String, String> loadMediaFiles(Id submissionId) {
        Map<String, String> mediaFileIdByFileName = new Map<String, String>();
        AttachmentSelector attachmentSelector = new AttachmentSelector();
        attachmentSelector.createParentIdWhereClause(new Set<Id> {submissionId});
        attachmentSelector.createNameWhereClause(
            C.SURVEY_ANSWER_ATTACHMENT_NAME,
            SObjectSelector.NOT_EQUALS_OPERATOR
        );
        for (
                Attachment att :
                    (List<Attachment>)
                        attachmentSelector.runSoqlQuery(SObjectSelector.AND_OPERATOR, null)
        ) {
            mediaFileIdByFileName.put(att.Name, att.Id);
        }
        return mediaFileIdByFileName;
    }

    /**
     * Loads the cascading data needed for the validations
     *
     * @param   cascadingSelects    a set with the ids of the cascading selects
     *                              used in the survey
     */
    private void loadCascadingData(Set<Id> cascadingSelects) {

        // Load the values for each cascading level
        this.cascadingValuesByLevel = new Map<Id, Set<String>>();
        // Load the possible values for each parent value
        this.cascadingValuesByParent = new Map<String, Set<String>>();
        for (
                CascadingSelectValue__c value :
                    new CascadingSelectValueSelector().getAllForCascadingSelect(cascadingSelects)
        ) {
            Set<String> valuesForLevel = this.cascadingValuesByLevel.get(
                value.CascadingLevel__c
            );
            Set<String> valuesForParent = this.cascadingValuesByParent.get(
                value.ControllingSelectValue__r.Value__c
            );

            if (valuesForLevel == null) {
                valuesForLevel = new Set<String>();
                this.cascadingValuesByLevel.put(
                    value.CascadingLevel__c,
                    valuesForLevel
                );
            }

            if (valuesForParent == null) {
                valuesForParent = new Set<String>();
                this.cascadingValuesByParent.put(
                    value.ControllingSelectValue__r.Value__c,
                    valuesForParent
                );
            }

            valuesForLevel.add(value.Value__c);
            valuesForParent.add(value.Value__c);
        }

        // Initialize the map for the answers of the cascading level questions
        this.cascadingAnswersByQuestion = new Map<Id, String>();
    }

    /**
     * Calculates the total survey's score and Creates the SubmissionScore record.
     *
     * @param   answers         the answers to calculate the scores
     * @param   surveyId        the id of the survey
     * @param   submissionId    the id of the submission
     */
    private void calculateScores(List<Answer__c> answers, string surveyId, string submissionId) {

        GenericObjectCreator submissionScoreCreator =
            new GenericObjectCreator(SubmissionScore__c.SObjectType);
        submissionScoreCreator.checkObjectAccessible();
        submissionScoreCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            SubmissionScore__c.ScoringGroup__c,
            SubmissionScore__c.TotalScore__c,
            SubmissionScore__c.Submission__c
        });

        // 1. Retrieve scoring groups for survey
        List<ScoringGroup__c> scoringGroups =
            new ScoringGroupSelector().getAllForSurveyPpi(surveyId, false);
        List<ScoreValue__c> scoreValues =
            new ScoreValueSelector().getAllForSurveyPpi(surveyId, false);

        // 2. Retrieve option's values for survey
        Map <Id, Map<Id, Decimal>> optionIdToScores = new Map<Id, Map<Id, Decimal>>();
        if (scoringGroups.size() != 0 && scoreValues.size() != 0) {
            // Stores each possible score value for one option in each ScoringGroup.
            // Final structure is OptionId -> ( ScoringGroupId -> Value )
            for ( ScoreValue__c score : scoreValues) {
                Map<Id, Decimal> Values = optionIdToScores.get(score.Option__c);
                if (Values == null) {
                    optionIdToScores.put(
                        score.Option__c,
                        new Map<Id, Decimal> {score.ScoringGroup__c => score.Value__c}
                    );
                }
                else {
                    Values.put(score.ScoringGroup__c, score.Value__c);
                }
            }
        }

          // 3. For each option, get it's value for each question group and add it to that group's total
        Map<Id, SubmissionScore__c> totalScorePerScoringGroup = new Map<Id, SubmissionScore__c>();
        for (Answer__c qAns : answers) {
            Map<Id, Decimal> optionScoreValues = optionIdToScores.get(qAns.Option__c);
            if (optionScoreValues != null) {
                for (Id sGroup : optionScoreValues.keySet()) {
                    SubmissionScore__c sAS = totalScorePerScoringGroup.get(sGroup);
                    if (sAS == null) {
                        Decimal totalScore = optionScoreValues.get(sGroup) == null
                                             ? 0
                                             : optionScoreValues.get(sGroup);

                        SubmissionScore__c submissionScoreInstance =
                            (SubmissionScore__c) submissionScoreCreator.createNewRecord();
                        submissionScoreCreator.populateFields(
                            submissionScoreInstance,
                            new Map<Schema.SObjectField, Object> {
                                SubmissionScore__c.ScoringGroup__c => sGroup,
                                SubmissionScore__c.TotalScore__c => totalScore,
                                SubmissionScore__c.Submission__c => submissionId
                            }
                        );
                        totalScorePerScoringGroup.put(
                            sGroup,
                            submissionScoreInstance
                        );
                    }
                    else {
                        sAS.TotalScore__c += 
                            optionScoreValues.get(sGroup) == null
                            ? 0 : optionScoreValues.get(sGroup);
                    }
                }
            }
        }

        // 4. Insert each SubmissionScore object
        if (totalScorePerScoringGroup.values().size() != 0) {
            insert (totalScorePerScoringGroup.values());
        }
    }

    /**
     * Create and insert the PpiResult__c object for the submission
     */
    private Decimal generatePpiScore(Submission submission) {
        Id ppiTemplateId = submission.getVersion().Id;
        PpiResultDomain.PpiResultWrapper ppiResultWrapper = createPpiResult(ppiTemplateId);
        ppiResultWrapper.populateGeneralFields(submission.getExistingSubmission());
        PpiResult__c ppiResult = PpiResultDomain.createRecord(ppiResultWrapper);
        insert ppiResult;
        PpiResult__c createdPpiResult =
            (PpiResult__c) new PpiResultSelector().getRecordById(ppiResult.Id);
        new SubmissionPpiAssociationDomain().setSubmissionIdForPpiAssociations(
            createdPpiResult,
            submission.getExistingSubmissionId()
        );
        return createdPpiResult.PpiScore__c;
    }

    /**
     * Create the PpiResult__c object for the submission
     */
    private PpiResultDomain.PpiResultWrapper createPpiResult(Id ppiTemplateId) {
        PpiResultDomain.PpiResultWrapper ppiResultWrapper =
            new PpiResultDomain.PpiResultWrapper(ppiTemplateId);
        populateSubmissionAnswersToPpiResult(ppiResultWrapper);
        if (
                PpiSettingsWrapper.getAllRecords() != null &&
                PpiSettingsWrapper.getAllRecords().size() > 0 &&
                ppiResultWrapper.clientId != null
        ) {
            populateExistingDemographicData(ppiResultWrapper);
        }
        return ppiResultWrapper;
    }

    /**
     * Code to populate submission answer to Ppi result wrapper record
     */
    private void populateSubmissionAnswersToPpiResult(
            PpiResultDomain.PpiResultWrapper ppiResultWrapper
    ) {
        List<Schema.PicklistEntry> picklistEntries = DescribeHandler.getFieldPicklist(
                Question__c.getSObjectType().getDescribe().getName(),
                Question__c.PpiResultsField__c.getDescribe().getName()
        );
        Integer sequenceCount = 1;
        for (Schema.PicklistEntry picklistEntry : picklistEntries) {
            Question__c ppiQuestion = ppiQuestions.get(picklistEntry.getValue());

            // Will always be instance null as PPI Questions cannot be in a repeat for the moment
            Answer__c ppiAnswer = allAnswersMap.get(ppiQuestion.Name + SPLITTER + 'null');

            if (ppiQuestion.PpiResultsField__c.contains('Answer')) {
                if (ppiAnswer != null) {
                    ppiResultWrapper.setPpiResultSequenceOption(
                        sequenceCount, ppiAnswer.Option__c
                    );
                }
                sequenceCount++;
            } else {

                // We allow partial submissions for Ppi, if no answer for a question continue.
                if (ppiAnswer == null) {
                    continue;
                }

                Option__c ppiOption;
                if (
                        ppiQuestion.Type__c == QuestionDO.TYPE_CHECKBOX ||
                        ppiQuestion.Type__c == QuestionDO.TYPE_RADIO
                ) {
                    ppiOption = this.optionsMap.get(ppiAnswer.Option__c);
                }

                ppiResultWrapper.processAnswer(ppiQuestion, ppiAnswer, ppiOption);
            }
        }
    }

    /**
     * Populate data if demographic configuration have been set
     */
    private void populateExistingDemographicData(
        PpiResultDomain.PpiResultWrapper ppiResultWrapper
    ) {
        List<PpiSettings__c> demographicMappings = PpiSettingsWrapper.getAllRecords();
        if (
            demographicMappings != null &&
            demographicMappings.size() > 0 &&
            DescribeHandler.objectExists(demographicMappings[0].Name)
        ) {
            String demographicDataQuery =
                PpiSettingsWrapper.createDemographicDataQuery(
                    demographicMappings[0], ppiResultWrapper
                );

            Sobject demographicInstance;
            // We will need to execute the query from Services class as we don't know exact object
            List<Sobject> demographicMappingData = DBFullAccess.querySObject(demographicDataQuery);

             if (demographicMappingData != null && demographicMappingData.size() > 0) {
                Schema.SObjectType targetType =
                    Schema.getGlobalDescribe().get(
                        demographicMappingData[0].getSObjectType().getDescribe().getName()
                    );
                demographicInstance = targetType.newSObject();
                demographicInstance = demographicMappingData[0];
                ppiResultWrapper.updateDemographicFieldsWithExistingData(
                    demographicMappings[0],
                    demographicInstance
                );
            }
        }
    }

    /**
     * Calculates the total survey's PPI score
     * Creates the SubmissionScore record for Old Ppi templates
     */
    private void calculatePPIScores(
            List<Answer__c> answers,
            SurveyVersion__c surveyVersion,
            Submission__c submission
    ) {
        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        GenericObjectCreator optionCreator =
            new GenericObjectCreator(Option__c.SObjectType);
        optionCreator.checkObjectAccessible();
        optionCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Option__c.PPIScore__c
        });
        GenericObjectCreator answerCreator =
            new GenericObjectCreator(Answer__c.SObjectType);
        answerCreator.checkObjectAccessible();
        answerCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Answer__c.Option__c
        });
        GenericObjectCreator ppiTableLineCreator =
            new GenericObjectCreator(PPITableLine__c.SObjectType);
        ppiTableLineCreator.checkObjectAccessible();
        ppiTableLineCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            PPITableLine__c.From__c,
            PPITableLine__c.To__c,
            PPITableLine__c.Probability__c,
            PPITableLine__c.PPITableDataSet__c
        });
        GenericObjectCreator submissionPpiValueCreator =
            new GenericObjectCreator(SubmissionPPIValue__c.SObjectType);
        submissionPpiValueCreator.checkObjectAccessible();
        submissionPpiValueCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            SubmissionPPIValue__c.PPITableLine__c,
            SubmissionPPIValue__c.Submission__c
        });
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Question__c.Name,
            Question__c.Position__c
        });

        // Fetch all answer records based on its question position order with respect
        // to individual Section's position order
        answers = [
            SELECT
                Id,
                Option__r.PPIScore__c,
                Question__r.Name,
                Question__r.Position__c,
                Question__r.RemoteServerId__c,
                Option__c
            FROM
                Answer__c
            WHERE
                Id IN :answers
            ORDER BY
                Question__r.Parent__r.Position__c, Question__r.Position__c
        ];

        PpiResultDomain.PpiResultWrapper ppiResultWrapper =
            new PpiResultDomain.PpiResultWrapper(surveyVersion.Id);
        ppiResultWrapper.populateGeneralFields(submission);

        // Sum all the PPI Scoring of each answer.
        Decimal ppiScoringSUM = 0;
        Integer sequenceCount = 1;

        for (Answer__c answer : answers) {

            // Added RemoteServerId check so that only downloaded ppiQuestions
            // will be considered for PpiScore calculation
            if (answer.Question__r.RemoteServerId__c != null && answer.Option__c != null
                    && answer.Option__r.PPIScore__c != null
            ) {
                ppiScoringSUM += answer.Option__r.PPIScore__c;

                // SequenceCount is used to maintain a proper sequence so that all Ppi
                // Question that may be present in any section will be used in PpiResult creation
                ppiResultWrapper.setPpiResultSequenceOption(
                    sequenceCount++, answer.Option__c
                );
            }
        }

        /**
         * This code will be required if we decide to support Ppi result creation for old Ppi surveys
         * Uncomment the code at that time
         * PpiResult__c ppiResult =  PpiResultDomain.createRecord(ppiResultWrapper);
         * insert ppiResult;
         */

        submissionCreator.checkObjectUpdateable();
        submissionCreator.populateFields(
            submission,
            new Map<Schema.SObjectField, Object> {
                Submission__c.PPIScore__c => ppiScoringSUM
            }
        );
        update submission;

        /**
         * This code supports older way to create Submission Ppi value record
         * Uncomment this code when we decide to support Ppi result creation for old Ppi surveys
         */
        PPITableLine__c[] PPITableLines = [
            SELECT
                Id,
                From__c,
                Probability__c,
                To__c,
                PPITableDataSet__c
            FROM
                PPITableLine__c
            WHERE
                PPITableDataSet__r.Survey__c = :surveyVersion.Survey__c
        ];

        Map<String, List<PPITableLine__c>> ppiTableLinesByDataSet =
            new Map<String, List<PPITableLine__c>>();
        for (PPITableLine__c ppiTL : PPITableLines) {
            List<PPITableLine__c> tableLines = ppiTableLinesByDataSet.get(ppiTL.PPITableDataSet__c);
            if (tableLines == null) {
                tableLines = new List<PPITableLine__c> {ppiTL};
                ppiTableLinesByDataSet.put(ppiTL.PPITableDataSet__c, tableLines);
            } else {
                tableLines.add(ppiTL);
            }
        }

        SubmissionPPIValue__c[] subVals = new SubmissionPPIValue__c[] {};

        for (String ppiDataSetId : ppiTableLinesByDataSet.keySet()) {
            List<PPITableLine__c> ppiLines = ppiTableLinesByDataSet.get(ppiDataSetId);
            for (PPITableLine__c pLine : ppiLines) {
                if (pLine.From__c <= ppiScoringSUM && pLine.To__c >= ppiScoringSUM) {
                    SubmissionPPIValue__c submissionPpiValueInstance =
                            (SubmissionPPIValue__c) submissionPpiValueCreator.createNewRecord();
                    submissionPpiValueCreator.populateFields(
                        submissionPpiValueInstance,
                        new Map<Schema.SObjectField, Object> {
                            SubmissionPPIValue__c.PPITableLine__c => pLine.Id,
                            SubmissionPPIValue__c.Submission__c => submission.Id
                        }
                    );
                    subVals.add(submissionPpiValueInstance);
                    break;
                }
            }
        }
        insert subVals;
    }

    /**
     * Method to parse the submission data
     *
     * @param   xmlReader   xml reader with the xml to parse
     * @param   submission  the submission wrapper
     * @return              the submission object with the fields set
     */
    private Submission__c parseSubmissionData(
            Xmlstreamreader xmlReader,
            Submission submission
    ) {
        Submission__c su = submission.getExistingSubmission();
        Boolean endOfHeader = false;
        while(xmlReader.hasNext() && !endOfHeader) {

            if (xmlReader.getEventType() == XmlTag.END_ELEMENT) {
                xmlReader.next();
                continue;
            } else if (xmlReader.getEventType() == XmlTag.START_ELEMENT) {
                if (xmlReader.getLocalName() == 'today') {
                    xmlReader.next();
                    if (xmlReader.getEventType() == XmlTag.CHARACTERS) {
                        su.Date__c = Date.valueOf(xmlReader.getText());
                    }
                } else if (xmlReader.getLocalName() == 'start') {
                    xmlReader.next();
                    if (xmlReader.getEventType() == XmlTag.CHARACTERS) {
                        String startDateTime = xmlReader.getText();
                        su.startDate__c = SurveyUtils.valueInGmt(startDateTime);
                    }
                } else if (xmlReader.getLocalName() == 'end') {
                    xmlReader.next();
                    if (xmlReader.getEventType() == XmlTag.CHARACTERS) {
                        String endDateTime = xmlReader.getText();
                        su.endDate__c = SurveyUtils.valueInGmt(endDateTime);
                    }
                } else if (xmlReader.getLocalName() == 'deviceid') {
                    // WE ARE NOT CURRENTLY SAVING THE deviceid
                } else if (xmlReader.getLocalName() == 'simid') {
                    // WE ARE NOT CURRENTLY SAVING THE simid
                } else if (xmlReader.getLocalName() == 'location') {
                     // Parse the location in the survey Answer
                     xmlReader.next();
                     if (xmlReader.getEventType() == XmlTag.CHARACTERS) {
                         parseLocation(xmlReader.getText(), su);
                     }
                } else if (xmlReader.getLocalName() == 'phonenumber') {
                    endOfHeader = true;
                }
            }
            xmlReader.next();
        }
        return su;
    }

    /**
     * Method to Parse the checkbox Question type of the Survey Answer
     *
     * @param   xmlReader   the xml reader with the xml to parse
     * @param   question    the question
     * @param   su          the submission object
     * @param   optionsMap  a map with the options of the question
     * @param   answers     the answers
     * @param   instance    the instance of the repeat
     */
    private void parseCheckboxQuestion(
        Xmlstreamreader xmlReader,
        Question__c question,
        Submission__c su,
        Map<Id, Option__c> optionsMap,
        List<Answer> answers,
        Integer instance
    ) {
        GenericObjectCreator answerCreator =
            new GenericObjectCreator(Answer__c.getSObjectType());

        xmlReader.next();
        if (xmlReader.getEventType() == XmlTag.CHARACTERS) {
            List<String> checkedAnswers = xmlReader.getText().split(' ', 0);
            for (String s : checkedAnswers) {
                Answer__c answerInstance = (Answer__c) answerCreator.createNewRecord();
                answerCreator.populateFields(
                    answerInstance,
                    new Map<Schema.SObjectField, Object> {
                        Answer__c.Submission__c => su.Id,
                        Answer__c.Question__c => question.Id,
                        Answer__c.Option__c => s,
                        Answer__c.Instance__c => instance,
                        Answer__c.TextAreaValue__c => optionsMap.get(s).Caption__c,
                        Answer__c.Value__c => optionsMap.get(s).Caption__c
                    }
                );
                this.allAnswersMap.put(question.Name + SPLITTER + instance, answerInstance);
                answers.add(new Answer(answerInstance));
            }
        }
    }

    /**
     * Method to parse the text, number, date and radio question types
     *
     * @param   xmlReader       the xml reader with the xml to parse
     * @param   question        the question
     * @param   su              the submission object
     * @param   answers         the answers
     * @param   mediaFileMap    a map with the files
     * @param   instance        the instance of the repeat
     */
    private void parseSimpleQuestion(
        Xmlstreamreader xmlReader,
        Question__c question,
        Submission__c su,
        List<Answer> answers,
        Map<String, String> mediaFileMap,
        Integer instance
    ) {

        GenericObjectCreator answerCreator =
            new GenericObjectCreator(Answer__c.getSObjectType());

        // Get the answer for this question.
        xmlReader.next();
        String questionValue = '';
        while (xmlReader.getEventType() == XmlTag.CHARACTERS) {
            questionValue = questionValue + xmlReader.getText();
            xmlReader.next();
        }
        questionValue = questionValue.trim();

        // If there's no answer, don't save an Answer__c object.
        if (questionValue == '') {
            return;
        }

        // Create the Answer__c object that will be inserted, and load appropriate field.
        Answer__c answerInstance = (Answer__c) answerCreator.createNewRecord();
        answerCreator.populateFields(
            answerInstance,
            new Map<Schema.SObjectField, Object> {
                Answer__c.Submission__c => su.Id,
                Answer__c.Question__c => question.Id,
                Answer__c.Instance__c => instance,
                Answer__c.Value__c =>
                    (
                        question.Type__c == QuestionDO.TYPE_TEXT_LONG &&
                        questionValue.length() > 255
                    ) ? questionValue.substring(0, 254) : questionValue
            }
        );

        if (question.Type__c == QuestionDO.TYPE_NUMBER) {
            answerInstance.NumericValue__c = decimal.valueOf(questionValue);
        } else if (question.Type__c == QuestionDO.TYPE_NUMBER_INTEGER) {
            answerInstance.NumericValue__c = Integer.valueOf(questionValue);
        } else if (question.Type__c == QuestionDO.TYPE_NUMBER_DECIMAL) {
            answerInstance.NumericValue__c = decimal.valueOf(questionValue);
        } else if (question.Type__c == QuestionDO.TYPE_DATETIME || question.Type__c == QuestionDO.TYPE_DATE) {
            answerInstance.Value__c = questionValue.replace('T', ' ');
            answerInstance.DateValue__c = date.valueOf(answerInstance.Value__c);

            if (question.Type__c == QuestionDO.TYPE_DATETIME) {
                answerInstance.DateTimeValue__c = SurveyUtils.valueInGmt(answerInstance.Value__c);
            }
        } else if (
                question.Type__c == QuestionDO.TYPE_RADIO
                || question.Type__c == QuestionDO.TYPE_TEXT_SHORT
                || question.Type__c == QuestionDO.TYPE_TEXT_LONG
        ) {
            answerInstance.TextAreaValue__c = questionValue;
        } else if (QuestionDO.isMedia(question.Type__c)) {
            // If the question is an image question, save the answer as a string
            // save the question filename (the image should be an attachement of the submission with this name)
            answerInstance.TextAreaValue__c = mediaFileMap.get(questionValue);
            answerInstance.Value__c = mediaFileMap.get(questionValue);
        } else if (question.Type__c == QuestionDO.TYPE_CASCADING_LEVEL) {
            // Validate the answers for a cascading select question
            if (validateCascadingAnswer(question, questionValue)) {
                answerInstance.TextAreaValue__c = questionValue;
                this.cascadingAnswersByQuestion.put(question.Id, questionValue);
            } else {
                throw new SubmissionDO.SubmissionException();
            }
        }
        this.allAnswersMap.put(question.Name + SPLITTER + instance, answerInstance);
        answers.add(new Answer(answerInstance));
    }

    /**
     * Validate the answers for a cascading select question.
     * Checks that:
     *    - The answer is valid for the level
     *    - The controlling question exists
     *    - The previous level was answered
     *    - The answer corresponds with a child value of the previous level answer
     */
    private Boolean validateCascadingAnswer(Question__c question, String answer) {
        Boolean result =
            (
                cascadingValuesByLevel.get(question.CascadingLevel__c).contains(answer)
                && (
                    question.ControllingQuestion__c == null
                    || cascadingAnswersByQuestion.get(question.ControllingQuestion__c) != null
                )

                && cascadingValuesByParent.get(
                    cascadingAnswersByQuestion.get(question.ControllingQuestion__c)
                ).contains(answer)
            );

        if (!result) {
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_SUB_INVALID_CASCADING,
                ErrorHandlingRest.SURVEY_SUB_INVALID_CASCADING,
                'One or more answers for a cascading select question is invalid.'
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_BAD_REQUEST);
        }
        return result;
    }

    /**
     * This method will process submitted survey data
     *
     * @param xml                - Survey Answer as xml String
     * @param loginResult        - MobileUserLoginLogic.LoginResult from the MobileUser authenication
     * @param submission - The submission validation object that holds the data
     *                                about the submission
     *
     * @return - The submission object that has been updated
     */
    public Submission submit(
            MobileUserLoginLogic.LoginResult loginResult,
            Submission submission
    ) {

        this.allAnswersMap = new Map<String, Answer__c>();
        return parseSubmission(
            loginResult.getContact().Id,
            submission
        );
    }

    /**
     * Parse the string data from submission xml and set it to the submission
     * The String list is divided like follows:
     *     [0] = y position
     *     [1] = x position
     *     [2] = alttitude position
     *     [3] = Approximation
     *
     * @param   gpsData a string with the GPS values
     * @param   submissionInstance   the submissin to set the data
     */
    public void parseLocation(String gpsData, Submission__c submissionInstance) {
        GenericObjectCreator submissionCreator =
            new GenericObjectCreator(Submission__c.SObjectType);
        String[] gpsDataList = gpsData.split(' ', 0);
        if (gpsDataList.size() > 1) {
            submissionCreator.populateFields(
                submissionInstance,
                new Map<Schema.SObjectField, Object> {
                    Submission__c.gps_y__c => double.valueOf(gpsDataList[0]),
                    Submission__c.gps_x__c => double.valueOf(gpsDataList[1]),
                    Submission__c.gps_approximation__c => double.valueOf(gpsDataList[03])
                }
            );
        }
    }

    /**
     * Answer Wrapper class
     */
    public class Answer {
        public List<Answer> childAnswers {get; set;}
        public Answer__c answerObj {get; set;}

        public Answer(Answer__c ans) {
            answerObj = ans;
            childAnswers = new List<Answer>();
        }
    }

    /**
     *  Code to set flags for automation
     *
     * This code is for testing the managed packages. Remove if LMA allows us to test
     * properly without it. It should never be made available to customers.
     * Enable some licenses or settings.
     */
    public final static String VALID_KEY = 'db83e76c-a1d1-422a-a560-0a37c6718d7f';
    public final static String PPI_EDITABLE_FLAG = 'PPI_CREATION';
    public final static String CAN_DISTRIBUTE_FLAG = 'CAN_DISTRIBUTE_FLAG';
    public final static String GRAMEEN_LICENSE = 'GRAMEEN_LICENSE';
    public final static String  TOGGLE_JOB_FILTERING = 'TOGGLE_JOB_FILTERING';

    /**
     * Process a flag creation or deletion request
     */
    private static void processFlag() {

        // Get the parameters
        String flagName = ApexPages.currentPage().getParameters().get('flag');
        String activateParam = ApexPages.currentPage().getParameters().get('activateFlag');
        String token = ApexPages.currentPage().getParameters().get('token');
        Boolean activateFlag = activateParam == '1';

        if (String.isNotBlank(flagName) && token == VALID_KEY) {
            if (flagName == GRAMEEN_LICENSE) {
                LicenseSettings__c license = c.getLicense();
                license.Can_Distribute__c = activateFlag;
                license.CanClonePpi__c = activateFlag;
                license.CreateTemplates__c = activateFlag;
                license.DeleteTemplates__c = activateFlag;
                license.DownloadPPI__c = activateFlag;
                license.DownloadTemplates__c = activateFlag;
                license.EditTemplates__c = activateFlag;
                license.PPI_Editable__c = activateFlag;
                license.UsePPI__c = activateFlag;
                license.UseTemplates__c = activateFlag;
                update license;
            } else if (flagName == PPI_EDITABLE_FLAG) {
                LicenseSettings__c license = c.getLicense();
                license.UsePPI__c = activateFlag;
                update license;
            } else if (flagName == CAN_DISTRIBUTE_FLAG) {
                LicenseSettings__c license = c.getLicense();
                license.Can_Distribute__c = activateFlag;
                update license;
            } else if (flagName == TOGGLE_JOB_FILTERING) {
                String jobFilteringValue = (activateFlag) ?
                    ApplicationSettingsUtils.JOBS_FILTER_SF_USER :
                    ApplicationSettingsUtils.JOBS_FILTER_ALL;
                ApplicationSettingsUtils.setJobFilterSetting(jobFilteringValue);
            } else {
                Settings__c flagSetting = Settings__c.getInstance(flagName);
                if (flagSetting == null && activateFlag) {
                    insert new Settings__c(Name = flagName);
                } else if (flagSetting != null && !activateFlag) {
                    delete flagSetting;
                }
            }
        }
    }
}