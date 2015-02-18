/**
 * Schedulable class to serialize Ppi results and send to parent org
 * It will set to run every Saturday at 1 AM
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
global class SerializePpiResultsSchedule implements Schedulable {

    // Constant to define when the batch will run
    public static String CRON_EXP = '0 0 1 ? * 7 *';

    global void execute(SchedulableContext sc) {
        Id batchInstanceId =
            Database.executeBatch(
                new SendPpiDataBatch(
                    new PpiResultSelector().generateSyncQuery(false)
                )
            );
    }
}