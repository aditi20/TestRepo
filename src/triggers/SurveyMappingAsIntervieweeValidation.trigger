/**
 * Trigger used to validate that the object is not mapped to a mobile-survey object
 * This class is poorly named. It doesn't do validation on the Interviewee mapping
 * as we cannot map an interviewee anymore
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Ernesto Quesada
 * @author Aditi Satpute
 */
trigger SurveyMappingAsIntervieweeValidation on SurveyMapping__c (after insert, after update) {
    TriggerHandler.triggerHandler(SurveyMappingDomain.class);
}