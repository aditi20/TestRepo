/**
 * Logic for trigger handling for the Scoring Group object.
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
public with sharing class ScoringGroupTH extends TriggerHandler {

    private ScoringGroupDomain getTriggerDomain() {
        return (ScoringGroupDomain) this.domain;
    }


    public override void validateBefore() {
        validateNonEditableSurvey();
    }

    /**
     * Validate that Scoring Group can be edited only for Draft Surveys
     */
    private void validateNonEditableSurvey() {
        // Get all draft surveys
        Map<Id, Survey__c> draftSurveys = new Map<Id, Survey__c>(new SurveySelector().getDraftSurveys());

        // Add an error to the scoring groups of draft surveys
        for(ScoringGroup__c scoringGroup : (List<ScoringGroup__c>)getTriggerDomain().records){
            if(!draftSurveys.containsKey(scoringGroup.Survey__c))
                scoringGroup.addError(ScoringGroupDomain.ERR_NO_EDITABLE_SURVEY);
        }
    }
}