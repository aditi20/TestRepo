/**
 * Trigger for the QuestionMapping__c object. Keeps the old naming style as it was created
 * before we added the SoC architecture
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies - odavies@grameenfoundation.org
 */
trigger QuestionMappingCheckValidFieldType on QuestionMapping__c (before insert, before update) {
    TriggerHandler.triggerHandler(QuestionMappingDomain.class);
}