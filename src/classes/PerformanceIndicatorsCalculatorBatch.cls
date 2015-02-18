/**
 * DEPRECATED PLEASE USE PerformanceIndicatorsCalculatorBatch_V2
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
global class PerformanceIndicatorsCalculatorBatch implements Database.Batchable<SObject>, Database.Stateful {

    global PerformanceIndicatorCategory performanceIndicatorCategory;
    global List<String> objectApiNames;
    global Integer indexForApiNames;
    global Integer dateModifier;
    global Date monthlyStartDate;
    global Date weeklyStartDate;
    global Date startDate;
    global Date endDate;

    // Key to this map is formed by createAssignedTargetMapKey method
    global Map<String, AssignedTarget__c> assignedTargets;

    /**
     * Constructor
     */
    global PerformanceIndicatorsCalculatorBatch(
        List<String> objectApiNames,
        Integer indexForApiNames,
        Integer dateModifier
    ) {}

    /**
     * return empty list. Legacy as packaging doesn't allow removal of global methods
     */
    global List<SObject> start(Database.BatchableContext batchableContext) {
        return new List<SObject>{};
    }

    /**
     *  Execute method
     */
    global void execute(Database.BatchableContext batchableContext, List<SObject> batch) {}

    /**
     * Finish method for the batch. If there are more objects that have PerformanceIndicators
     * then run the batch again
     */
    global void finish(Database.BatchableContext batchableContext) {}

    private class PerformanceIndicatorCategory {}
}