/**
 * DEPRECATED CLASS (obsolete)
 *
 * After version 1.4.0, xform.xml attachments are stored in SurveyVersion__c instead of Survey__c.
 * It will also create missing XForms for published surveys that do not have a generated XForm yet.
 * This batch moves these attachments to the corresponding SurveyVersion__c.
 * It needs to be done one by one because attachments have to be moved.
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 */
global class PostInstallScript_010400MoveXFormsToVer implements Database.Batchable<Survey__c> {
    global PostInstallScript_010400MoveXFormsToVer(){}
    global List<Survey__c> start(Database.BatchableContext BC) {return null;}
    global void execute(Database.BatchableContext BC, List<Survey__c> batch) {}
    global void finish(Database.BatchableContext BC) {}
}