/**
 * Class to handle the logic for Performance management
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved.
 *
 * @author - Owen Davies (odavies@grameenfoundation.org)
 */
public with sharing class PerformanceManagementLogic {

    /**
     * Generate the response that gets the current time periods Performance Targets for a given Mobile User
     */
    public static void processGetRequest() {

        String sessionId = RestContext.request.headers.get(C.SESSION_TOKEN_HEADER);

        MobileUserLoginLogic.LoginResult loginResult = MobileUserLoginLogic.authenticateMobileUser(
            '',
            '',
            sessionId,
            true
        );
        if (loginResult.hasError) {
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
            Restcontext.response.statusCode = loginResult.statusCode;
            return;
        }

        PerformanceManagementResponse performanceManagementResponse;
        try {
            performanceManagementResponse =
                getCurrentPerformanceTargetsResponse(loginResult);
        } catch (GenericObjectCreator.GenericObjectCreatorException genericObjectCreatorException) {
            ErrorHandlingRest.addErrorMsg(
                ErrorHandlingRest.ERR_CODE_CRUD_FLS,
                ErrorHandlingRest.CRUD_FLS,
                System.Label.ERR_PERMISSIONS + '\n\n' + genericObjectCreatorException.getMessage()
            );
            ErrorHandlingRest.setStatusCode(C.HTTP_INTERNAL_SERVER_ERROR);
        }

        RestContext.response.statusCode = ErrorHandlingRest.getStatusCode();
        if (ErrorHandlingRest.checkForErrors()) {
            RestContext.response.addHeader(C.CONTENT_TYPE_HEADER, C.CONTENT_TYPE_JSON_UTF);
            RestContext.response.responseBody = Blob.valueOf(ErrorHandlingRest.getErrorJson());
        } else {
            Restcontext.response.statusCode = C.HTTP_OK;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(performanceManagementResponse));
        }
    }

    /**
     * Get the response for the current performance targets
     *
     * @param loginResult - The MobileUsers login result
     *
     * @return - A PerformanceManagementResponse object representing the found performance targets
     */
    private static PerformanceManagementResponse getCurrentPerformanceTargetsResponse(
            MobileUserLoginLogic.LoginResult loginResult
    ) {

        PerformanceManagementResponse performanceManagementResponse = new PerformanceManagementResponse();

        // Split the AssignedTargets into their types
        for (
                AssignedTarget__c currentAssignedTarget : AssignedTargetDO.getCurrentActiveAssignedTargets(
                    loginResult.getContact().Id,
                    loginResult.getContact().OwnerId
                )
        ) {
            performanceManagementResponse.generatePerformanceTarget(currentAssignedTarget);
        }
        return performanceManagementResponse;
    }

    /**
     * Wrapper class to allow for easy serialization of the response to the endpoint
     */
    @TestVisible
    private class PerformanceManagementResponse {

        private String indicatorsUpdateTime;
        private List<PerformanceTarget> targets;
        private List<PerformanceTarget> indicators;

        /**
         * Constructor
         */
        public PerformanceManagementResponse() {
            this.indicatorsUpdateTime = getIndicatorUpdateNextFireTime();
            this.targets = new List<PerformanceTarget>();
            this.indicators = new List<PerformanceTarget>();
        }

        /**
         * Get the next fire time of the indicators update batch job
         *
         * @return - A string with the time in GMT
         */
        private String getIndicatorUpdateNextFireTime() {
            List<CronTrigger> cronTriggers = [
                SELECT
                    NextFireTime
                FROM
                    CronTrigger
                WHERE
                    CronJobDetail.Name = :System.Label.INDICATOR_TARGET_UPDATE_BATCH
                LIMIT 1
            ];
            return (
                cronTriggers.size() == 1
                    ? cronTriggers[0].NextFireTime.formatGmt('hh:mmz')
                    : null
            );
        }

        /**
         * Generate a PerformanceTarget object from an AssignedTarget
         *
         * @param assignedTarget - The AssignedTarget record to be processed
         */
        public void generatePerformanceTarget(AssignedTarget__c assignedTarget) {

            PerformanceTarget performanceTarget = new PerformanceTarget(
                assignedTarget.PerformanceTarget__r.Name,
                assignedTarget.EndDate__c,
                assignedTarget.PerformanceTarget__r.Timeframe__c,
                0,
                new List<PerformanceRank>{new PerformanceRank(
                    assignedTarget.Contact__r.Name,
                    assignedTarget.TargetValue__c,
                    assignedTarget.ActualValue__c
                )}
            );
            if (
                    assignedTarget.PerformanceTarget__r.Type__c == null ||
                    assignedTarget.PerformanceTarget__r.Type__c.equals(PerformanceTargetDO.TYPE_JOB_TARGET)
            ) {
                this.targets.add(performanceTarget);
            } else if (assignedTarget.PerformanceTarget__r.Type__c.equals(PerformanceTargetDO.TYPE_INDICATOR)) {
                this.indicators.add(performanceTarget);
            }
        }

        /**
         * Add a target to the list of found targets
         *
         * @param newTarget - The PerformanceTarget to add to the list
         */
        public void addTarget(PerformanceTarget newTarget) {
            this.targets.add(newTarget);
        }

        /**
         * Getter for the indicator JobTargets
         *
         * @return - The list of JobTargets for the performance targets found
         */
        public List<PerformanceTarget> getTargets() {
            return this.targets;
        }

        /**
         * Getter for the indicator PerformanceIndicators
         *
         * @return - The list of PerformanceIndicators for the performance targets found
         */
        public List<PerformanceTarget> getIndicators() {
            return this.indicators;
        }

        /**
         * Add a target to the list of found performance indicators
         *
         * @param newTarget - The PerformanceTarget to add to the list
         */
        public void addPerformanceIndicator(PerformanceTarget newTarget) {
            this.indicators.add(newTarget);
        }
    }

    /**
     * Wrapper class for an individual performance target
     */
    @TestVisible
    private class PerformanceTarget {

        String targetName;
        String timePeriodEndDate;
        String timeframe;
        Integer rankPosition;
        List<PerformanceRank> rank;

        /**
         * Constructor for PerformanceTarget
         *
         * @param targetName        - Name of the target
         * @param timePeriodEndDate - The date that the time period ends
         * @param timeframe         - The timeframe of the target Monthly|Weekly
         */
        public PerformanceTarget(String targetName, Date timePeriodEndDate, String timeframe) {
            this.targetName = targetName;
            this.timePeriodEndDate = PerformanceManagementUtils.convertDateToTimePeriod(timePeriodEndDate);
            this.timeframe = timeframe;
            this.rank = new List<PerformanceRank>();
        }

        /**
         * Constructor when all the details of the PerformanceTarget are known at the start
         *
         * @param targetName        - Name of the target
         * @param timePeriodEndDate - The date that the time period ends
         * @param timeframe         - The timeframe of the target Monthly|Weekly
         * @param rankPosition      - The position of the calling mobile user in the rank array
         * @param rank              - The list of ranks for the target in descending order of progress
         */
        public PerformanceTarget(
                String targetName,
                Date timePeriodEndDate,
                String timeframe,
                Integer rankPosition,
                List<PerformanceRank> rank
        ) {
            this.targetName = targetName;
            this.timePeriodEndDate = PerformanceManagementUtils.convertDateToTimePeriod(timePeriodEndDate);
            this.timeframe = timeframe;
            this.rankPosition = rankPosition;
            this.rank = rank;
        }

        /**
         * Get the name of the target
         *
         * @return - Name of the target
         */
        public String getTargetName() {
            return this.targetName;
        }

        /**
         * Getter for the timePeriodEndDate
         *
         * @return - The timePeriodEndDate String
         */
        public String getTimePeriodEndDate() {
            return this.timePeriodEndDate;
        }

        /**
         * Getter for the timeframe
         *
         * @return - The time frame
         */
        public String getTimeFrame() {
            return this.timeframe;
        }

        /**
         * Get the rank position for the target
         *
         * @return - The rank position
         */
        public Integer getRankPosition() {
            return this.rankPosition;
        }

        /**
         * Get the rank list for the performance target
         *
         * @return - The ranking list
         */
        public List<PerformanceRank> getPerformanceRank() {
            return this.rank;
        }
    }

    /**
     * Wrapper class for a rank entry in a PerformanceTarget
     */
    @TestVisible
    private class PerformanceRank {

        String contactName;
        Decimal targetValue;
        Decimal actualValue;

        /**
         * Constructor for a PerformanceRank
         */
        public PerformanceRank(String contactName, Decimal targetValue, Decimal actualValue) {
            this.contactName = contactName;
            this.targetValue = targetValue;
            this.actualValue = actualValue;
        }

        /**
         * Getter for the contact name
         */
        public String getContactName() {
            return this.contactName;
        }

        /**
         * Getter for the target value
         */
        public Decimal getTargetValue() {
            return this.targetValue;
        }

        /**
         * Getter for the actual value
         */
        public Decimal getActualValue() {
            return this.actualValue;
        }
    }
}