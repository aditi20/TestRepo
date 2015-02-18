/**
 * After version 1.10.0, the value for the answers of the text questions is stored in
 * the new field TextAreaValue__c of Answer__c and the old field is deprecated.
 * This batch moves these values to the new fields for the old answers.
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio
 */
global class PostInstallScript_011000MoveAnswerText implements Database.Batchable<Answer__c> {

    global PostInstallScript_011000MoveAnswerText(){}

    global List<Answer__c> start(Database.BatchableContext BC) {
        return [SELECT Id,
                       TextValue__c,
                       Value__c,
                       Question__r.Type__c
                FROM Answer__c
                WHERE TextValue__c != null
                      OR Question__r.Type__c = :QuestionDO.TYPE_TEXT_LONG];
    }

    global void execute(Database.BatchableContext BC, List<Answer__c> batch) {
        for(Answer__c answer : batch){
            if(answer.Question__r.Type__c == QuestionDO.TYPE_TEXT_LONG){
                answer.TextAreaValue__c = answer.Value__c;
            }
            else {
                answer.TextAreaValue__c = answer.TextValue__c;
            }
        }
        update batch;
    }

    global void finish(Database.BatchableContext BC) {}

    
}
