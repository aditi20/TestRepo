/**
 * Data Object class for PerformanceTarget__c
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 * @author - Santiago Blankleider
 */
public with sharing class PerformanceTargetDO extends SObjectDomain {

    // Status
    public static final String STATUS_ACTIVE   = 'Active';
    public static final String STATUS_CLOSED   = 'Closed';
    public static final String STATUS_INACTIVE = 'Inactive';

    // Timeframes
    public static final String TIMEFRAME_WEEKLY  = 'Weekly';
    public static final String TIMEFRAME_MONTHLY = 'Monthly';

    // Types
    public static final String TYPE_JOB_TARGET  = 'Job_Target';
    public static final String TYPE_INDICATOR   = 'Performance_Indicator';

    // Close Reasons
    public static final String CLOSE_AUTOMATICALLY   = 'Automatically Closed';
    public static final String CLOSE_MANUALLY        = 'Manually Closed';

    // Aggregation Operataions
    public static final String AGGREGATION_OPERATION_AVG        = 'AVG';
    public static final String AGGREGATION_OPERATION_COUNT      = 'COUNT';
    public static final String AGGREGATION_OPERATION_CUSTOM     = 'CUSTOM';
    public static final String AGGREGATION_OPERATION_PERCENTAGE = 'PERCENTAGE';
    public static final String AGGREGATION_OPERATION_SUM        = 'SUM';

    public PerformanceTargetDO() {
        super(PerformanceTarget__c.SObjectType);
    }

    public PerformanceTargetDO(List<PerformanceTarget__c> sObjects) {
        super(sObjects);
    }

    /**
     * Get the PerformanceTargets for a given list of JobTemplates
     *
     * @param jobTemplates   - A list of JobTemplate__c.Id
     * @param requiredStatus - A list of PermanceTarget__c.Status__c
     *
     * @return - A map of the available PerformanceTarget__c
     */
    public static Map<Id, PerformanceTarget__c> getPerformanceTargetsForJobTemplates(
            Set<Id> jobTemplates,
            List<String> requiredStatus
    ) {
        return new Map<Id, PerformanceTarget__c>(
            new PerformanceTargetselector().getAllForJobTemplates(
                jobTemplates,
                requiredStatus
            )
        );
    }

    /**
     * Set the end and start dates based on the end date of the given target.
     *
     * @param target the performance target to set the dates
     */
    public static void setPeriodDates(PerformanceTarget__c target) {
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.getSObjectType());
        performanceTargetCreator.checkObjectUpdateable();
        // The date update has to be done in two parts as the end date is calculated from the new
        // start date
        performanceTargetCreator.populateFields(
            target,
            new Map<Schema.SObjectField, Object>{
                PerformanceTarget__c.StartDate__c =>
                    (target.Timeframe__c == TIMEFRAME_WEEKLY)
                    ? getPreviousMonday(target.EndDate__c)
                    : target.EndDate__c.toStartOfMonth()
            }
        );
        performanceTargetCreator.populateFields(
            target,
            new Map<Schema.SObjectField, Object>{
                PerformanceTarget__c.EndDate__c =>
                    (target.Timeframe__c == TIMEFRAME_WEEKLY)
                    ? target.StartDate__c.addDays(6)
                    : getLastDayOfMonth(target.EndDate__c)
            }
        );
    }

    // A map with the amount of days from monday for each day
    private static Map<String, Integer> DAYS_FROM_MONDAY =
        new Map<String, Integer> {
            'Monday'    => 0,
            'Tuesday'   => 1,
            'Wednesday' => 2,
            'Thursday'  => 3,
            'Friday'    => 4,
            'Saturday'  => 5,
            'Sunday'    => 6
        };

    /**
     * Find out if the day of the week is a Monday
     *
     * @param testDate - Date being checked
     *
     * @return - True if it is Monday, false otherwise
     */
    public static Boolean isMonday(Date testDate) {
        return DAYS_FROM_MONDAY.get(
            DateTime.newInstance(
                testDate.year(),
                testDate.month(),
                testDate.day()
            ).format('EEEE')
        ) == 0;
    }

    /**
     * Get the date of the previous monday.
     * If the date is already a monday, it returns it as is
     *
     * @param   aDate   some date
     * @return          the date of the previous monday of the given date
     */
    public static Date getPreviousMonday(Date aDate) {
        DateTime auxDate = DateTime.newInstance(
            aDate.year(),
            aDate.month(),
            aDate.day()
        );
        return aDate.addDays(-1 * DAYS_FROM_MONDAY.get(auxDate.format('EEEE')));
    }

    /**
     * Get the date of the last day of the month.
     *
     * @param   aDate   some date
     * @returm          tha date of the last day of the month
     */
    public static Date getLastDayOfMonth(Date aDate) {
        // Get the first day of the next month
        Date newDate = aDate.addMonths(1).toStartOfMonth();
        // Substract one day to get the last day of the previous month
        return newDate.addDays(-1);
    }

    /**
    * Change the status of a PerformanceTarget object and save it
    * @param performanceTarget The object to updated
    * @param status The data to put in the status field
    */
    public static void changeStatus(PerformanceTarget__c performanceTarget, String status) {
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.getSObjectType());
        performanceTargetCreator.populateFields(
            performanceTarget,
            new Map<Schema.SObjectField, Object>{
                PerformanceTarget__c.Status__c => status
            }
        );
        if (status.equals(PerformanceTargetDO.STATUS_CLOSED)) {
            performanceTargetCreator.populateFields(
                performanceTarget,
                new Map<Schema.SObjectField, Object>{
                    PerformanceTarget__c.CloseReason__c => PerformanceTargetDO.CLOSE_MANUALLY
                }
            );
        }
        performanceTargetCreator.checkObjectUpdateable();
        update performanceTarget;
    }

    /**
     * Get the start of the previous time period.
     *
     * @param dateToChange - The date that we want to check
     * @param timeframe    - The time frame for the target
     *
     * @return - The start time of the previous time period
     */
    public static Date getStartOfPreviousTimePeriod(Date dateToChange, String timeframe) {

        dateToChange = getStartOfCurrentTimePeriod(dateToChange, timeframe).addDays(-1);
        return getStartOfCurrentTimePeriod(dateToChange, timeframe);
    }

    /**
     * Get the start of the current time period.
     *
     * @param dateToChange - The date that we want to check
     * @param timeframe    - The time frame for the target
     *
     * @return - The start time of the current time period
     */
    public static Date getStartOfCurrentTimePeriod(Date dateToChange, String timeframe) {

        dateToChange = timeframe.equals(TIMEFRAME_WEEKLY) ? getPreviousMonday(dateToChange)
            : dateToChange.toStartOfMonth();
        return dateToChange;
    }

    /**
     * Get the end of the current time period
     *
     * @param dateToChange - The date that we want to check
     * @param timeframe    - The time frame for the target
     *
     * @return - The end date of the time period
     */
    public static Date getEndOfCurrentTimePeriod(Date dateToChange, String timeframe) {

        // Get the start date of the current time period
        dateToChange = getStartOfCurrentTimePeriod(dateToChange, timeframe);
        dateToChange = timeframe == TIMEFRAME_WEEKLY
            ? dateToChange.addDays(6)
            : dateToChange.addMonths(1).addDays(-1);
        return dateToChange;
    }

    /**
     * Get the list of object API names used by performance targets
     */
    public static List<String> getValidObjectApiNames() {
        String trackedObjectFieldName =
                Schema.sObjectType.PerformanceTarget__c.Fields.TrackedSObjectApiName__c.getName();
        List<String> validNames = new List<String>();
        List<String> invalidNames = new List<String>();
        for (AggregateResult result :
                new PerformanceTargetSelector().getAllTrackedObjectApiNames(
                    TYPE_INDICATOR,
                    STATUS_ACTIVE
                )
        ) {
            String apiName = (String)result.get(trackedObjectFieldName);
            if (DescribeHandler.objectExists(apiName)) {
                validNames.add(apiName);
            } else {
                invalidNames.add(apiName);
            }
        }
        closeInvalidTargets(invalidNames);
        return validNames;
    }

    /**
     * Close all the records that are related to an ObjectAPIName that doesn't exist
     * TODO - Make a batch if customers hit an issue. Don't really expect customers to have
     *         50,000 Performance Indicators
     */
    private static void closeInvalidTargets(List<String> objectApiNamesToClose) {
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.SObjectType);

        List<PerformanceTarget__c> targetsToClose =
            new PerformanceTargetSelector().getAllForObjectApiNames(
                objectApiNamesToClose,
                TYPE_INDICATOR,
                STATUS_ACTIVE
            );
        setTargetsToAutomaticallyClosed(targetsToClose);
        performanceTargetCreator.checkObjectUpdateable();
        update targetsToClose;
    }

    /**
     * Set a list of performance targets to be automatically closed
     */
    public static List<PerformanceTarget__c> setTargetsToAutomaticallyClosed(
            List<PerformanceTarget__c> targetsToClose
    ) {
        GenericObjectCreator performanceTargetCreator =
            new GenericObjectCreator(PerformanceTarget__c.getSObjectType());
        performanceTargetCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            PerformanceTarget__c.CloseReason__c,
            PerformanceTarget__c.Status__c
        });
        for (PerformanceTarget__c performanceTarget : targetsToClose) {
            performanceTargetCreator.populateFields(
                performanceTarget,
                new Map<Schema.SObjectField, Object>{
                    PerformanceTarget__c.CloseReason__c =>
                        PerformanceTargetDO.CLOSE_AUTOMATICALLY,
                    PerformanceTarget__c.Status__c =>
                        PerformanceTargetDO.STATUS_CLOSED
                }
            );
        }
        return targetsToClose;
    }

    /**
     * Check if the operation of the target require a tracked field
     *
     * @param performaceTarget - The target to check
     *
     * @return - True if the operation require a tracked field
     */
    public static Boolean operationRequireTrackedField(PerformanceTarget__c performanceTarget) {
        return performanceTarget.AggregationOperation__c != AGGREGATION_OPERATION_COUNT
            && performanceTarget.AggregationOperation__c != AGGREGATION_OPERATION_CUSTOM;
    }

    /**
     * Get all the actives performance in a map by name
     */
    public static Map<String, PerformanceTarget__c>  getActivePerformanceTargetsByName() {
        List<PerformanceTarget__c> targets =
            new PerformanceTargetSelector().getAllForStatus(STATUS_ACTIVE);

        Map<String, PerformanceTarget__c> performanceByName =
            new Map<String, PerformanceTarget__c>();
        for (PerformanceTarget__c performance : targets) {
            performanceByName.put(performance.Name, performance);
        }
        return performanceByName;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public PerformanceTargetDO constructWithRecords(List<SObject> sObjectList) {
            return new PerformanceTargetDO(sObjectList);
        }
        public PerformanceTargetDO constructEmpty() {
            return new PerformanceTargetDO();
        }
    }
}