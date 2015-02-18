/**
 * Class contains all the logic that is carried out by the SkipConditionTrigger.trigger on the SkipCondition__c object.
 * Any new logic that needs to be added to the SkipCondition__c trigger goes in here.
 *
 * @author Santiago Blankleider
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
global with sharing class SkipConditionTriggerLogic {

    // Actions carried out before a DML action
    /**
     * Before Insert, Before Update
     *
     * Check to be carried out:-
     *     - Check that source question is valid
     *
     * Actions carried out:-
     *     - Cancel insert/update of skip condition and show error message
     *
     * @param triggerNewList - The list of skipLogics being inserted by the trigger
     */
    public static void beforeInsert(List<SkipCondition__c> triggerNewList) {
        canBeSource(triggerNewList);
    }

    public static void beforeUpdate(List<SkipCondition__c> triggerNewList){
        canBeSource(triggerNewList);
    }

    // Check if question can be source question
    private static void canBeSource(List<SkipCondition__c> triggerNewList){
        Map<String, SkipCondition__c> conditionBySource = new Map<String, SkipCondition__c>();
        Set<Id> sourceIds = new Set<Id>();
        String message    = '';
        String toAddError = '';

        for(SkipCondition__c condition : triggerNewList){
            sourceIds.add(condition.SourceQuestion__c);
            conditionBySource.put(condition.SourceQuestion__c, condition);
        }
        // if question is: final, static, cascading level or cascading select cannot be source question in skipcondition
        // then create error message
        for(Question__c sourceQuestion : [SELECT Type__c, Name FROM Question__c WHERE Id IN :sourceIds]){
            if( QuestionDO.isSection(sourceQuestion.Type__c)
                || (sourceQuestion.Type__c == QuestionDO.TYPE_STATIC)
                || (sourceQuestion.Type__c == QuestionDO.TYPE_FINAL)
                || (sourceQuestion.Type__c == QuestionDO.TYPE_CASCADING_SELECT)
                || (sourceQuestion.Type__c == QuestionDO.TYPE_CASCADING_LEVEL) ){

                message += String.format(System.Label.SKIP_CONDITION_INVALID_SOURCEQUESTION, new String[]{sourceQuestion.Name, ' '});
                toAddError = sourceQuestion.Id;
            }
        }

        if(message != ''){
            message += System.Label.SKIP_CONDITION_INVALID_SOURCEQUESTIONFINALMESSAGE;
        }
        if(toAddError != ''){
            conditionBySource.get(toAddError).addError(message);
        }
    }
}