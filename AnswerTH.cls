/**
 * Logic for trigger handling for the Answer__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 */
public with sharing class AnswerTH {

    /**
     * Main trigger handling logic to be called from Answers trigger
     */
    public static void triggerHandler (
            Boolean isBefore,
            Boolean isAfter,
            Boolean isInsert,
            Boolean isUpdate,
            Boolean isDelete,
            List<Answer__c> newRecords,
            Map<Id, Answer__c> oldRecordsMap
    ) {
        if (isAfter) {
            afterHandler(isInsert, isUpdate, newRecords, oldRecordsMap);
        }
    }

    /**
     * After trigger handler to redirect properly based on insert or update
     */
    private static void afterHandler (
            Boolean isInsert,
            Boolean isUpdate,
            List<Answer__c> newRecords,
            Map<Id, Answer__c> oldRecordsMap
    ) {
        if (isInsert) {
            afterInsert(newRecords);
        }
    }

    /**
     * After insert logic
     */
    private static void afterInsert (List<Answer__c> newRecords) {
        setMaxInstanceQuestion(newRecords);
    }

    /**
     * Logic to get all answers records and populate parent Question record with maximum of 
     * Instance__c value of child Answer records
     */
    private static void setMaxInstanceQuestion (List<Answer__c> newAnswerRecords) {
        Set<Id> questionsId = new Set<Id>();
        for (Answer__c ansTempInstance : newAnswerRecords) {
            questionsId.add(ansTempInstance.Question__c);
        }

        Map<Id, Question__c> parentQuestionsMap =
            new Map<Id, Question__c>([
                SELECT
                    Id,
                    MaxInstance__c
                FROM
                    Question__c
                WHERE
                    Id IN : questionsId
            ]);

        Map<Id, Question__c> questionMapToUpdate = new Map<Id, Question__c>();
        // Logic to allocate maximum instance value to parent Question records
        // It will be based on maximum of Instance value from child answers
        for (Answer__c answerInstance : newAnswerRecords) {
            if (!questionMapToUpdate.containsKey(answerInstance.Question__c)) {
                if (
                        (
                            parentQuestionsMap.containsKey(answerInstance.Question__c) &&
                            parentQuestionsMap.get(answerInstance.Question__c).MaxInstance__c == null &&
                            answerInstance.Instance__c != null
                        ) ||
                        (
                            answerInstance.Instance__c >
                            parentQuestionsMap.get(answerInstance.Question__c).MaxInstance__c
                        )
                ) {
                    Question__c questionTemporary = new Question__c();
                    questionTemporary = parentQuestionsMap.get(answerInstance.Question__c);
                    questionTemporary.MaxInstance__c = answerInstance.Instance__c;
                    questionMapToUpdate.put(answerInstance.Question__c, questionTemporary);
                }
            } else {
                if (
                        questionMapToUpdate.get(answerInstance.Question__c).MaxInstance__c <
                        answerInstance.Instance__c
                ) {
                    questionMapToUpdate.get(answerInstance.Question__c).MaxInstance__c =
                    answerInstance.Instance__c;
                }
            }
        }
        if (questionMapToUpdate != null && !questionMapToUpdate.values().isEmpty()) {
            Database.update(questionMapToUpdate.values());
        }
    }
}