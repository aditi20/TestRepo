/**
 * Selector class for the CronTrigger object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
public with sharing class CronTriggerSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return CronTrigger.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            CronTrigger.Id,
            CronTrigger.CronExpression,
            CronTrigger.TimesTriggered,
            CronTrigger.NextFireTime
        };
    }

    public String pathToJobFiltering() {
        return null;
    }
}