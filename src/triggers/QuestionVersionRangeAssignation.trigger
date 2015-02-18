/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
trigger QuestionVersionRangeAssignation on Question__c (before insert,before update) {


    /*Before insert/update a ScoringGroup, check if the survey is in Draft
    abort the operation and show an error*/

    // Get Ids of affected surveys
    Set<Id> surveyIds = new Set<Id>();
    for(Question__c q : trigger.new)
        surveyIds.add(q.Survey__c);

    GenericObjectCreator surveyCreator =
        new GenericObjectCreator(Survey__c.SObjectType);
    surveyCreator.checkObjectAccessible();
    surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
        Survey__c.Status__c,
        Survey__c.Version__c
    });

    // Get all SurveyDO.STATUS_DRAFT surveys
    Map<Id, Survey__c> surveys = new Map<Id, Survey__c>([SELECT Id, Status__c, Version__c FROM Survey__c WHERE Id IN :surveyIds]);

    // Add an error to the scoring groups of SurveyDO.STATUS_DRAFT surveys. 
    // Also make sure if MaxInstance__c field is getting updated then allow updation
    for(Question__c question:trigger.new) {
        if(surveys.get(question.Survey__c).Status__c != SurveyDO.STATUS_DRAFT &&
            (
                Trigger.isUpdate &&
                question.MaxInstance__c == Trigger.oldMap.get(question.Id).MaxInstance__c
            )
        ) {
            question.addError(system.label.BUILDER_ERR_QUESTION_NOTDRAFTSURVEY);
        }
    }

    if(trigger.isInsert){

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.FromVersion__c,
                Question__c.ToVersion__c,
                Question__c.PreviousVersionQuestion__c
            }
        );

        // Get questions that were updated
        Set<Id> updatedQuestionsIds = new Set<Id>();
        for(Question__c q : trigger.new) updatedQuestionsIds.add(q.PreviousVersionQuestion__c);
        Map<Id,Question__c> updatedQuestions = new Map<Id,Question__c>([
            SELECT Id,FromVersion__c,ToVersion__c, PreviousVersionQuestion__c
            FROM Question__c
            WHERE Id IN :updatedQuestionsIds]);

        /*Assign the correct version for a question and limit the previous one*/
        //&& updatedQuestions.get(question.PreviousVersionQuestion__c)!= null
        for (Question__c question:trigger.new){
            question.FromVersion__c = surveys.get(question.Survey__c).Version__c;
            Question__c previousQuestion = updatedQuestions.get(question.PreviousVersionQuestion__c);
            if(previousQuestion != null)
                previousQuestion.ToVersion__c = question.FromVersion__c - 1;
        }
        update updatedQuestions.values();
    }
}