/**
 * This Batch class is called after we upgrade package.
 * 
 * This batch will process all Answer records and it's corresponding Question object MaxInstance__c value.
 *
 * Populate max value of Answer__c Instance__c value to parent Question MaxInstance__c field
 */
global with sharing class ProcessAnswerRecordsBatch implements Database.Batchable<sObject> {

    global final String query;

    global ProcessAnswerRecordsBatch(String queryToExecute) {
        // Batch Constructor
        this.query = queryToExecute;
    }

    /**
     * Start method of batch to return all Answer records which will be processed.
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }

    /**
     * Execute method of batch process. This will process all answer records provided in scope.
     * Also populate global map questionsToUpdateMapLocal, which will be updated finally in finish method
     */
    global void execute(Database.BatchableContext BC, List<sObject> answersToProcess) {
        // This map will contain all Question records to update in each batch
        Map<String, Question__c> questionsToUpdateMapLocal = new Map<String, Question__c>();
        // This map will contain updated database Question records
        Map<String, Question__c> questionsToUpdateMapDatabase = new Map<String, Question__c>();

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Question__c.MaxInstance__c
        });

        List<Id> questionsToProcessIds = new List<Id>();
        for (Answer__c parentQuestionId : (List<Answer__c>)answersToProcess) {
            questionsToProcessIds.add(parentQuestionId.Question__c);
        }

        // Get updated Database question values
        // In previous batch this same question might have been updated already
        questionsToUpdateMapDatabase =
            new Map<String, Question__c>([
                SELECT 
                    Id,
                    MaxInstance__c
                FROM
                    Question__c
                WHERE
                    Id IN :questionsToProcessIds
            ]);
        for (Answer__c answerTemporaryInstance : (List<Answer__c>)answersToProcess) {
            // Check if questionsToUpdateMapLocal contains key for the Question map that needs to be updated.
            if (!questionsToUpdateMapLocal.containsKey(answerTemporaryInstance.Question__c)) {
                // Check MaxInstance__c of parent Question is already null OR
                // MaxInstance__c is having lesser value than child Answer instance.
                if (
                        (
                            questionsToUpdateMapDatabase.get(answerTemporaryInstance.Question__c).MaxInstance__c == null &&
                            answerTemporaryInstance.Instance__c != null
                        ) || 
                        (
                            questionsToUpdateMapDatabase.get(answerTemporaryInstance.Question__c).MaxInstance__c <
                            answerTemporaryInstance.Instance__c
                        )
                ) {
                    Question__c newQuestion =
                        (Question__c) questionCreator.createNewRecord();
                    questionCreator.populateFields(
                        newQuestion,
                        new Map<Schema.SObjectField, Object> {
                            Question__c.MaxInstance__c => answerTemporaryInstance.Instance__c
                        }
                    );
                    newQuestion.Id = answerTemporaryInstance.Question__c;
                    questionsToUpdateMapLocal.put(
                        answerTemporaryInstance.Question__c,
                        newQuestion
                    );
                }
            } else {
                // If Question key already present, then check if it's MaxInstance__c
                // Value is less than child answer Instance__c value
                if (
                        questionsToUpdateMapDatabase.get(answerTemporaryInstance.Question__c).MaxInstance__c < 
                        answerTemporaryInstance.Instance__c
                ) {
                    questionCreator.populateFields(
                        questionsToUpdateMapLocal.get(answerTemporaryInstance.Question__c),
                        new Map<Schema.SObjectField, Object> {
                            Question__c.MaxInstance__c => answerTemporaryInstance.Instance__c
                        }
                    );
                }
            }
        }
        if (questionsToUpdateMapLocal != null && !questionsToUpdateMapLocal.values().isEmpty()) {
            questionCreator.checkObjectUpdateable();
            update questionsToUpdateMapLocal.values();
        }
    }

    /**
     * Finish method of batch process.
     */
    global void finish(Database.BatchableContext BC) {
    }
}