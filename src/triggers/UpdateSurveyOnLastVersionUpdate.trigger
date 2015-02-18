/**
 * Trigers the actions before update or delete the SurveyVersion__c object
 * Actions:
 *     - Set the Distribution Date if the flag is set to true.
 *     - Update the Survey__c Status when the last version is updated and
 *           prevent the updating of a published survey to Draft.
 *     - Prevent the update of a version when the survey is related to a non closed job
 *     - Prevent the deletion of non Draft surveys
 * @author Ernesto Quesada
 * @author Alejandro De Gregorio
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
trigger UpdateSurveyOnLastVersionUpdate on SurveyVersion__c (before update, after update, before delete) {

    // Prevent the deletion of non Draft surveys versions
    if (trigger.isDelete) {
        for (SurveyVersion__c version : trigger.old) {
            if (version.Status__c != SurveyDO.STATUS_DRAFT && Settings__c.getInstance(C.FLAG_SKIP_SURVEY_STATUS_VALIDATION) == null){
                version.addError(system.label.SURVEY_ERR_CANNOTDELETEPUBLISHED);
            }
        }
    }
    else {

        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkObjectAccessible();
        taskTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                TaskTemplate__c.Form__c
            }
        );

        Set<Id> surveysWithNonClosedTasks = new Set<Id>();
        for(TaskTemplate__c task : [
                SELECT Form__c
                FROM TaskTemplate__c
                WHERE Form__c IN :trigger.new
                AND JobTemplate__r.Status__c != :JobTemplateDO.STATUS_CLOSED
        ]) {
            surveysWithNonClosedTasks.add(task.Form__c);
        }

        // Get the surveys that are having a version updated
        Set<Id> surveysId = new Set<Id>();
        for (SurveyVersion__c version : trigger.new){

            // Set the distribution date
            if (
                    version.Distributed__c &&
                    !trigger.oldMap.get(version.Id).Distributed__c
                    && trigger.isBefore
            ) {
                version.DistributionDate__c = Datetime.now();
            }

            // Add the survey to the set
            surveysId.add(version.Survey__c);
        }

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkObjectUpdateable();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Survey__c.Version__c,
            Survey__c.Status__c
        });

        Map<Id,Survey__c> idToSurvey = new Map<Id, Survey__c>([
            SELECT Id, Version__c, Status__c
            FROM Survey__c
            WHERE Id IN :surveysId
        ]);

        for (SurveyVersion__c newVersion : trigger.new) {

            // Update the survey status with the version status, but only if it's the latest version of the survey.
            // However, a survey cannot go back to Draft from any other status. Raise an error in this situation.
            SurveyVersion__c oldVersion = trigger.oldMap.get(newVersion.Id);
            if (
                    (oldVersion.Status__c != SurveyDO.STATUS_DRAFT
                    && newVersion.Status__c == SurveyDO.STATUS_DRAFT)
                    && Settings__c.getInstance(C.FLAG_SKIP_SURVEY_STATUS_VALIDATION) == null
            ) {

                // Add an error and remove the survey from the surveys to be updated
                idToSurvey.remove(newVersion.Survey__c);
                newVersion.Status__c.AddError(system.label.SURVEYVERSION_ERR_CANNOTGOBACKTODRAFT);
            }
            else if (newVersion.Status__c == SurveyDO.STATUS_CLOSED) {

                // If change status of version to closed, validate if there is at least one job for this survey that is not closed.
                if (surveysWithNonClosedTasks.contains(newVersion.Id)) {

                    // Add an error and remove the survey from the surveys to be updated
                    idToSurvey.remove(newVersion.Survey__c);
                    newVersion.AddError(system.Label.SURVEYVERSION_ERR_CLOSEWITHOPENJOBS);
                }
                else if (idToSurvey.get(newVersion.Survey__c).Version__c == newVersion.Version__c) {

                    // If there is no task and job for the survey, do not validate.
                    idToSurvey.get(newVersion.Survey__c).Status__c = newVersion.Status__c;
                }
            }
            else if (idToSurvey.get(newVersion.Survey__c).Version__c == newVersion.Version__c) {
                idToSurvey.get(newVersion.Survey__c).Status__c = newVersion.Status__c;
                if (newVersion.Status__c == SurveyDO.STATUS_PUBLISHED && idToSurvey.get(newVersion.Survey__c).PublishedDate__c == null) {

                    // Save the publish date for the first version published
                    idToSurvey.get(newVersion.Survey__c).PublishedDate__c = Date.today();
                }
            }
        }

        // If there are any valid versions being updated then update the relative surveys
        if (!idToSurvey.isEmpty() && trigger.isAfter) {
            update idToSurvey.values();
        }
    }
}