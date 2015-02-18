/**
 * Schedulable class to schedule the PerformanceIndicatorsCalculatorBatch_V2
 * It will set to run every day at 1 AM
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
global class PerformanceIndicatorsCalculatorSchedule implements Schedulable {

    // Constant to define when the batch will run
    public static String CRON_EXP = '0 0 1 * * ?';

    global void execute(SchedulableContext sc) {
        List<String> objectApiNames = PerformanceTargetDO.getValidObjectApiNames();
        if (objectApiNames.size() > 0) {
            PerformanceIndicatorsCalculatorBatch_V2 batch =
                new PerformanceIndicatorsCalculatorBatch_V2(
                    objectApiNames,
                    0,
                    -1
                );
            database.executebatch(batch);
        }
    }

}
