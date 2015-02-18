/**
 * Before insert/update a ScoringGroup check if the survey is in Draft, *
 * in that case abort the operation and show an error.
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Ernesto Quesada
 * @author Kaushik Ray
 */
trigger AvoidUpdateNonDraftSurvey on ScoringGroup__c(
        before insert,
        before update,
        after update,
        after insert
) {
    TriggerHandler.triggerHandler(ScoringGroupDomain.class);
}

