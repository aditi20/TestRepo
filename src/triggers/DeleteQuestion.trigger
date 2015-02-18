/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
trigger DeleteQuestion on Question__c (before delete, before update, before insert) {
    Map<string,QuestionMapping__c[]> mappingByQuestionId = new Map<string,QuestionMapping__c[]>();
    QuestionMapping__c[] mapping = new QuestionMapping__c[] {};
    Set<String> listReferenceRequiredSM = new Set<String>();

    if(!trigger.isInsert) {
        GenericObjectCreator questionMappingCreator =
            new GenericObjectCreator(QuestionMapping__c.SObjectType);
        questionMappingCreator.checkObjectAccessible();
        questionMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            QuestionMapping__c.FieldApiName__c,
            QuestionMapping__c.SurveyMapping__c,
            QuestionMapping__c.Question__c
        });

        GenericObjectCreator surveyMappingCreator =
            new GenericObjectCreator(SurveyMapping__c.SObjectType);
        surveyMappingCreator.checkObjectAccessible();
        surveyMappingCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            SurveyMapping__c.ObjectApiName__c,
            SurveyMapping__c.IsReference__c,
            SurveyMapping__c.MatchingField__c
        });

        // Get all the mappings related to the Deleted questions.
        mapping = [SELECT
                        Id,
                        FieldApiName__c,
                        SurveyMapping__r.ObjectApiName__c,
                        SurveyMapping__r.IsReference__c,
                        SurveyMapping__r.MatchingField__c,
                        Question__c
                    FROM
                        QuestionMapping__c
                    WHERE
                        Question__c IN :trigger.oldMap.keySet()];

        Set<Id> surveyIds = new Set<Id>();

        // Obtain Surveys in trigger.

        List<Question__c> questions = trigger.isDelete ? trigger.old : trigger.new;

        for(Question__c qu : questions) {
            surveyIds.add(qu.Survey__c);
        }

        // And obtain the Set of the survey mappings Id's with required relations.
        listReferenceRequiredSM =
        SurveyFieldMappingController.obtainListOfSurveyMappingsWithRequiredRelations(surveyIds);


        for(QuestionMapping__c qM: mapping) {
            QuestionMapping__c[] qMapList = mappingByQuestionId.get(qM.Question__c);
            if(qMapList == null) {
                mappingByQuestionId.put(qM.Question__c, new QuestionMapping__c[] {qM});
            }
            else {
                qMapList.add(qM);
            }
        }
    }

    if(trigger.isDelete) {

        GenericObjectCreator skipConditionCreator =
            new GenericObjectCreator(SkipCondition__c.SObjectType);
        skipConditionCreator.checkObjectAccessible();
        skipConditionCreator.checkObjectDeletable();

        // Deletes all the SkipConditions records related to the deleted questions.
        delete [SELECT Id FROM SkipCondition__c WHERE SourceQuestion__c in :trigger.oldMap.keySet()];

        for(Question__c q : trigger.old) {
            boolean error = false;
            QuestionMapping__c[] mappingList = mappingByQuestionId.get(q.Id);

            if(mappingList != null) {
                for(QuestionMapping__c qM : mappingList) {
                    Schema.DescribeFieldResult fieldDescribe =
                        DescribeHandler.getFieldDescribe(
                            qM.SurveyMapping__r.ObjectApiName__c,
                            qM.FieldApiName__c
                        );

                    //If the Field is required and is not set by it self then stop the delete of the question.
                    if(
                            !qM.SurveyMapping__r.IsReference__c
                            && fieldDescribe != null
                            && !fieldDescribe.isNillable()
                            && !fieldDescribe.isDefaultedOnCreate()
                    ) {

                        q.addError(System.label.SURVEY_QUESTION_ERR_MAPPED_QUESTION);
                        error = true;
                        break;
                    }
                    // If question is mapped to an id field then stop delete of question, and show error message
                    else if(
                        !qM.SurveyMapping__r.IsReference__c
                        && qM.FieldApiName__c.equals(qM.SurveyMapping__r.MatchingField__c)
                        && q.Required__c
                        && qM.SurveyMapping__r.MatchingField__c != null
                    ) {

                        q.addError(System.label.SURVEY_QUESTION_ERR_MAPPED_QUESTION_IDFIELD);
                        error = true;
                        break;
                    }
                }
            }
        }
        delete mapping;
    }
    else {

        Map<String, Question__c> questionByCascading = new Map<String, Question__c>();
        Map<String, Question__c> namesToQuestions    = new Map<String, Question__c>();
        Map<String, String>      namesToSurvey       = new Map<String, String>();
        Map<String, Question__c> parents             = new Map<String, Question__c>();
        Map<String, List<Question__c>> cascadingByParent    = new Map<String, List<Question__c>>();

        List<Question__c> newParents = new List<Question__c>();

        // If cascading question is related add to map to check status
        for(Question__c q : trigger.new) {
            namesToQuestions.put(q.Name, q);
            namesToSurvey.put(q.Name, q.Survey__c);

            if(q.Type__c == QuestionDO.TYPE_CASCADING_SELECT) {
                questionByCascading.put(q.CascadingSelect__c, q);

                // Fill map with new cascading questions
                if (cascadingByParent.get(q.Parent__c) == null) {
                    cascadingByParent.put(q.Parent__c, new List<Question__c> {q});
                }
                else {
                    cascadingByParent.get(q.Parent__c).add(q);
                }
            }

            // Add new parents to the list
            if(QuestionDO.isSection(q.Type__c)) {
                newParents.add(q);
            }
        }

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Name,
                Question__c.Type__c,
                Question__c.Parent__c,
                Question__c.Survey__c,
                Question__c.SamePage__c
            }
        );

        // Get saved questions
        List<Question__c> savedQuestions = [
            SELECT
                Name,
                Type__c,
                Parent__c,
                SamePage__c,
                Survey__c
            FROM
                Question__c
            WHERE
                Survey__c IN :namesToSurvey.values()
        ];

        if(!savedQuestions.isEmpty()) {
            for(Question__c sq : savedQuestions) {
                // Fill parents map
                if(QuestionDO.isSection(sq.Type__c)) {
                    parents.put(sq.Id, sq);

                    // Check before put saved questions into the map
                    if(
                        cascadingByParent.get(sq.Id) != null
                        && !cascadingByParent.get(sq.Id).isEmpty()
                        && sq.SamePage__c
                    ) {
                        for(Question__c cascadingChild : cascadingByParent.get(sq.Id)) {
                            // If inserting or updating and change parent then show error
                            if(
                                cascadingChild.Id == null
                                || cascadingChild.Parent__c
                                    != trigger.oldMap.get(cascadingChild.Id).Parent__c
                            ) {
                                cascadingChild.addError(
                                    System.Label.SURVEY_QUESTION_ERR_CANNOT_CASCADING_SHOWSAMEPAGE
                                );
                                break;
                            }
                        }
                    }
                }

                // Validate if there is at least one repeated name into the survey
                if(
                    namesToQuestions.get(sq.Name) != null
                    && sq.Id != namesToQuestions.get(sq.Name).Id
                    && sq.Survey__c == namesToSurvey.get(sq.Name)
                ) {
                    namesToQuestions.get(sq.Name).addError(
                        System.Label.SURVEY_QUESTION_ERR_REP_QUESTION_NAME
                    );
                    break;
                }
            }
        }

        if(!questionByCascading.values().isEmpty()) {
            GenericObjectCreator cascadingSelectCreator =
                new GenericObjectCreator(CascadingSelect__c.SObjectType);
            cascadingSelectCreator.checkObjectAccessible();
            cascadingSelectCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                CascadingSelect__c.Status__c
            });

            // Check status of library and show error
            for(
                CascadingSelect__c cascading : [
                    SELECT Id,
                           Status__c
                    FROM CascadingSelect__c
                    WHERE Id IN :questionByCascading.keySet()
                ]
            ) {
                if(cascading.Status__c != C.CASCADING_STATUS_UPLOADED) {
                    questionByCascading.get(cascading.Id).addError(
                        System.Label.SURVEY_QUESTION_ERR_INVALID_CASCADINGSELECT
                    );
                    break;
                }
            }
        }

        if(trigger.isUpdate) {
            for(Question__c q : trigger.new) {
                QuestionMapping__c[] mappingList = mappingByQuestionId.get(q.Id);

                if(mappingList != null) {
                    // If the question is mapped and is moved to a repeat section
                    // or is moved from a repeat section, this movement cannot be done.
                    if(
                        trigger.oldMap.get(q.Id).Parent__c != q.Parent__c
                        && (
                            parents.get(trigger.oldMap.get(q.Id).Parent__c).Type__c == QuestionDO.TYPE_REPEAT
                            || parents.get(q.Parent__c).Type__c == QuestionDO.TYPE_REPEAT
                        )
                    ) {

                        q.addError(System.label.CANNOT_MOVE_MAPPED_QUESTION);
                        break;
                    }

                    // When change the required field of a question to false
                    // and is mapped to a required field or object is reference
                    // and relation required, raise an error.
                    if (trigger.oldMap.get(q.Id).Required__c && !q.Required__c) {
                        for (QuestionMapping__c qM : mappingList) {
                            Schema.DescribeFieldResult fieldDescribe =
                                DescribeHandler.getFieldDescribe(
                                    qM.SurveyMapping__r.ObjectApiName__c, qM.FieldApiName__c
                                );

                            if (!qM.SurveyMapping__r.IsReference__c && !q.Required__c) {
                                if (!fieldDescribe.isNillable() && !fieldDescribe.isDefaultedOnCreate()) {

                                    // The field mapped in the question mapping is required so the
                                    // question cannot be not-required.
                                    q.addError(
                                        System.label.SURVEY_QUESTION_ERR_MAPPED_REQUIREDCANNOTBEFALSE
                                    );
                                    break;
                                } else if(
                                        qM.FieldApiName__c.equals(qM.SurveyMapping__r.MatchingField__c)
                                        && qM.SurveyMapping__r.MatchingField__c != null
                                ) {
                                    // The field mapped in the question mapping is required so the
                                    // question cannot be not-required.
                                    q.addError(
                                        System.label.SURVEY_QUESTION_ERR_MAPPED_QUESTION_IDFIELD_REQUIRED
                                    );
                                    break;
                                }
                            } else if(
                                    qM.SurveyMapping__r.IsReference__c
                                    && listReferenceRequiredSM.contains(qM.SurveyMapping__c)
                            ) {

                                // Is a question mapping in which the survey mapping is reference
                                // and the survey mapping is related (as parent) to a Master-Detail
                                // or required lookup relation.
                                q.addError(
                                    System.label.SURVEY_QUESTION_ERR_RELATION_REQUIRED_CANNOT_BE_FALSE
                                );
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
}