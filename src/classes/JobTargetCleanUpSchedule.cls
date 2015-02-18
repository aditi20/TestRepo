/**
 * Schedulable class to schedule the JobTargetCleanUpBatch
 * It will set to run every day at 1 AM
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Alejandro De Gregorio Tort - adegregorio@altimetrik.com
 */
global class JobTargetCleanUpSchedule implements Schedulable {

    // Constant to define when the batch will run
    public static String CRON_EXP = '0 0 1 * * ?';

    global void execute(SchedulableContext sc) {
        JobTargetCleanUpBatch batch = new JobTargetCleanUpBatch();
        database.executebatch(batch, JobTargetCleanUpBatch.MAX_BATCH_SIZE);
    }

}
