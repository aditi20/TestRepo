/**
 * Utility class for methods related to Survey processing
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 */
public with sharing class SurveyUtils {

    /**
     * Generate json file to distribute
     */
    public Attachment generateJsonFile(SurveyVersion__c version){

        SurveyData newSurveyData = new SurveyData(version.Survey__c);

        List<SurveyData> surveyData = new List<SurveyData>();
        surveyData.add(newSurveyData);

        //Serializing json
        String str = JSON.serialize(surveyData);

        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkObjectCreateable();
        attachmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Attachment.Name,
            Attachment.Body,
            Attachment.ParentId
        });

        //Insert attachment to actual survey version object
        Attachment att = (Attachment) attachmentCreator.createNewRecord();
        attachmentCreator.populateFields(
            att,
            new Map<Schema.SObjectField, Object>{
                Attachment.Name => C.SURVEY_FILE_JSON,
                Attachment.ParentId => version.Id,
                Attachment.Body => Blob.valueOf(str)
            }
        );
        insert att;
        return att;
    }

    /**
     * Save distributed survey
     */
    public SurveyData deserializeSurveyJson(Attachment att){
        List<SurveyData> surveyAllData = (List<SurveyData>)JSON.deserialize(att.Body.toString(), List<SurveyData>.class);
        return surveyAllData[0];
    }

    /**
     * Get the Json Attachment from a survey. There should only ever be one of these but in
     * case there is more return the most recent
     */
    public Attachment getJsonFile(String versionId) {
        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Attachment.Body
        });

        Attachment[] files = [
            SELECT
                Body
            FROM
                Attachment
            WHERE
                Name = :C.SURVEY_FILE_JSON
                AND ParentId = :versionId
            ORDER BY
                LastModifiedDate DESC
            ];
        if (files.isEmpty()) {
            return null;
        }
        return files[0];
    }

    public static Datetime valueInGmt(String dt) {
        String[] parts = splitDatetimeAndTimeZoneOffset(dt);
        String dateTimePart = parts[0];
        Integer hourOffset   = Integer.valueOf(parts[1]);
        Integer minOffset    = Integer.valueOf(parts[2]);

        Datetime gmtTime = Datetime.valueOfGmt(dateTimePart);

        return gmtTime.addHours(hourOffset).addMinutes(minOffset);
    }

    public static String[] splitDatetimeAndTimeZoneOffset(String dt) {
        dt = dt.replace('T', ' ');

        String dateTimePart;
        String offsetSign;
        String offset           = '0:0';
        String hourOffset       = '0';
        String minOffset        = '0';

        if(dt.contains('+')) {
            List<String> parts = dt.split('\\+');
            dateTimePart = parts[0];
            offset       = parts[1];
            offsetSign = '-';
        } else {
            Integer len = dt.length();
            Boolean offSetFound = false;
            Integer colonCount = 0;
            Integer i;
            for(i = len-1;i>=0;--i) {
                String c = dt.substring(i, i+1);
                if(c.equals(' ') || c.equals('.')) break;
                if(c.equals(':')) {
                    ++colonCount;
                    if(colonCount > 1) break; //There can have atmost one colon in timezone offset
                }
                if(c.equals('-')) {
                    offSetFound = true;
                    break;
                }
            }
            if(offsetFound) {
                dateTimePart    = dt.substring(0, i);
                offset          = dt.substring(i+1, len);
            } else {
                dateTimePart    = dt;
            }
            offsetSign = '';
        }

        if(offset.contains(':')) {
            List<String> parts = offset.split(':');
            hourOffset = parts[0];
            minOffset  = parts[1];
        } else {
            if(offset.length()<=2) {
                hourOffset = offset;
            } else {
                hourOffset = offset.substring(0,2);
                minOffset  = offset.substring(2,offset.length());
            }
        }
        hourOffset = offsetSign + hourOffset;
        minOffset  = offsetSign + minOffset;
        return new String[]{dateTimePart, hourOffset, minOffset};
    }

    /**
     * Convert a datetime to the format expected in the JSON string submitted to this REST service
     *
     * @param dateTime - The DateTime being converted
     *
     * @return - The formatted string
     */
    public static String convertDateTimeToString(DateTime dTime) {
        return dTime.formatGMT('yyyy-MM-dd H:mm:s.SS').replaceFirst(' ', 'T');
    }

    /*
     * Remove all objects(specified by given indexes) from the list of object
     */
    public static void removeAll(List<Object> objects, List<Integer> indexes) {
        if(indexes.isEmpty()) return;
        //Removing duplicate indexes and sorting
        indexes.sort();
        List<Integer> distinctIndexes = new List<Integer>();
        for(Integer i = 0; i < indexes.size(); ++i) {
            if(i > 0 && indexes[i] == indexes[i-1]) continue;
            distinctIndexes.add(indexes[i]);
        }
        //Now removing all elements specified by distinct indexes
        for(Integer i = distinctIndexes.size()-1; i >= 0; --i) {
            Integer index = distinctIndexes.get(i);
            if(index < objects.size()) {
                objects.remove (index);
            }
        }
    }

    /**
     * Distribute a survey
     *
     * @param surveyId - The id for the survey to be distibuted
     *
     * @return - Boolean indicating success
     */
    public Boolean distributeSurvey(String surveyId) {

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(
            new List<String> {
                'IsPPI__c'
            }
        );

        // License Control, can't execute without licence permission
        List<Survey__c> surveys = [
            SELECT
                Id,
                IsPPI__c
            FROM
                Survey__c
            WHERE
                Id = :surveyId
        ];
        if (surveys.size() > 0) {
            LicenseSettings__c license = C.getLicense();
            if (!license.Can_Distribute__c) {
                SurveyException.raise(System.label.SYSTEM_ERR_NOLICENSEPERMISSION);
            }
        }

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkObjectUpdateable();
        surveyVersionCreator.checkFieldsAccessible(
            new List<String> {
                'Survey__c'
            }
        );

        // -----------------------------------------------------------------------------
        // This query is temporal and assumes that there is only one version per survey
        // because the manager don't support version so far. When the manager supports
        // versions, this query will use the version id.
        List<SurveyVersion__c> versions = [
            SELECT
                Id,
                Survey__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c = :surveyId
            ORDER BY
                Version__c DESC LIMIT 1
        ];
        if (versions.isEmpty()) {
            SurveyException.raise(System.label.SURVEY_ERR_WRONGSURVEYID);
        }

        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkObjectCreateable();
        attachmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Attachment.Name,
            Attachment.Body,
            Attachment.ParentId
        });

        // Check if there is a json generated and created if there isn't
        List<Attachment> att = [
            SELECT
                Id,
                Name,
                ParentId,
                Body
            FROM
                Attachment
            WHERE
                ParentId = :versions[0].Id
                AND Name = :C.SURVEY_FILE_JSON
        ];
        if (att.isEmpty()) {

            // Generating Json file to distribute
            generateJsonFile(versions[0]);
        }

        surveyVersionCreator.populateField(
            versions[0],
            SurveyVersion__c.Distributed__c,
            true
        );
        update versions[0];
        return true;
    }

    /**
     * Parses a CSV line into a list of strings.
     * Code obtained from the developerforce wiki and changed to parse a single line
     * See the original code at:
     *     http://wiki.developerforce.com/page/Code_Samples#Parse_a_CSV_with_APEX
     *
     * @param  csvLine a string with the CSV line
     * @return         a list with the values in the CSV line
     */
    public static List<String> parseCsvLine(String csvLine) {
        List<String> allValues = new List<String>();

        // Replace instances where a double quote begins a value containing a comma
        // in this case you get a double quote followed by a doubled double quote
        // do this for beginning and end of a value
        csvLine = csvLine.replaceAll(',"""',',"DBLQT').replaceAll('""",','DBLQT",').replaceFirst('^"""', '"DBLQT').replaceFirst('"""$', 'DBLQT"');
        // Now replace all remaining double quotes - we do this so that we can reconstruct
        // values with commas inside assuming they begin and end with a double quote
        csvLine = csvLine.replaceAll('""','DBLQT');
        
        //Remove the CR char (to support windows end of line)
        csvLine = csvLine.replace('\r','');
        List<String> values = csvLine.split(',', -1);

        // Used to reconstruct values that were splited because they contained a comma
        String compositeValue;
        // Indicates if we are in the middle of a splited value
        Boolean makeCompositeValue = false;


        for(String value : values) {
            if (value.startsWith('"') && value.endsWith('"') && !makeCompositeValue) {
                // Add the non splited value
                allValues.add(value.replaceFirst('^"', '').replaceFirst('"$', '').replaceAll('DBLQT','"'));
            } else if (value.startsWith('"') && !makeCompositeValue) {
                // Start reconstructing a splited value
                makeCompositeValue = true;
                compositeValue = value;
            } else if (value.endsWith('"') && makeCompositeValue) {
                // Finish reconstructing a splited value and add it
                compositeValue += ',' + value;
                allValues.add(compositeValue.replaceFirst('^"', '').replaceFirst('"$', '').replaceAll('DBLQT','"'));
                makeCompositeValue = false;
            } else if (makeCompositeValue) {
                // Continue reconstructing a splited value
                compositeValue +=  ',' + value;
            } else {
                // Add the value non sorrounded with double quotes
                allValues.add(value.replaceAll('DBLQT','"'));
            }
        }

        return allValues;
    }

    /**
     * Method to verify if field is latitude or longitude for standard or custom objects
     */
    public static Boolean isGeoLocationComponentField(String fieldName) {
        if (fieldName.toLowerCase().contains('__')) {
            return isGeoLocationComponentCustomField(fieldName);
        } else {
            return isGeoLocationComponentStandardField(fieldName);
        }
    }

    /**
     * Method to verify if field is latitude or longitude standard field 
     */
    public static Boolean isGeoLocationComponentStandardField(String fieldName) {
        return
            fieldname.toLowerCase().contains('latitude') ||
            fieldname.toLowerCase().contains('longitude');
    }

    /**
     * Method to verify if field is latitude or longitude custom field 
     */
    public static Boolean isGeoLocationComponentCustomField(String fieldName) {
        return
            fieldname.toLowerCase().contains('latitude__s') ||
            fieldname.toLowerCase().contains('longitude__s');
    }

    /**
     * Method to get geolocation field format for composite field value to be passed to mobile
     */
    public static String formatGeolocationFields(String fieldValue) {
        if (
                !String.isBlank(fieldValue) &&
                fieldValue.toLowerCase().contains('api location: ')
        ) {
            fieldValue =
                fieldValue.toLowerCase().substring(
                    fieldValue.indexOf(
                        '[', fieldValue.indexOf('api location: ')
                    ) + 1,
                    fieldValue.indexOf(']')
                );
        }
        fieldValue += ' 0 0';
        return fieldValue;
    }

    /**
     * Parse a geolocation string
     *
     * @param geolocation - A string with a geolocation in the format "latitude longitude altitude aproximation"
     * @param isGpsData   - A boolean variable set as true if the geolocation data is of Answer
     *                      submitted from GPS question
     *
     * @return - The geolocation parsed into a GeoLocation class
     *
     * @throws - SurveyException
     */
    public static GeoLocation parseGeoLocation(String location, Boolean isGpsData) {

        GeoLocation result = null;

        // Validate the location is not blank or empty
        if (String.isNotBlank(location)) {
            List<String> startDividedLocation = location.split(' ', 0);

            // Validate the format (four double values)
            if (startDividedLocation.size() > 3 && startDividedLocation.size() < 6) {
                try {
                    result = new GeoLocation(
                        isGpsData
                            ? Decimal.ValueOf(startDividedLocation[1]).setScale(6)
                            : Decimal.ValueOf(startDividedLocation[0]).setScale(6),
                        isGpsData
                            ? Decimal.ValueOf(startDividedLocation[0]).setScale(6)
                            : Decimal.ValueOf(startDividedLocation[1]).setScale(6),
                        Decimal.ValueOf(startDividedLocation[2]).setScale(6),
                        Decimal.ValueOf(startDividedLocation[3]).setScale(6)
                    );
                }
                catch (TypeException e) {
                    throw new SurveyException(
                        ErrorHandlingRest.ERR_CODE_SYNC_GPS_FAIL,
                        ErrorHandlingRest.SYNC_JOB_GPS_FAIL,
                        C.HTTP_OK,
                        System.Label.LOCATION_ERR_CANTPARSEVALUES + ' ' + location,
                        false
                    );
                }
            }
            else {
                throw new SurveyException(
                    ErrorHandlingRest.ERR_CODE_SYNC_GPS_FAIL,
                    ErrorHandlingRest.SYNC_JOB_GPS_FAIL,
                    C.HTTP_OK,
                    System.Label.LOCATION_ERR_WRONGNUMBEROFVALUES + ' ' + location,
                    false
                );
            }
        }
        return result;
    }

    /**
     * Search and close published surveys/templates and his related jobs with missing mapped objects, fields or relations
     * @param Survey Id
     * @param Boolean true if can add messages, just in VF pages
     */

    public static void closeFailedSurveysAndUserInfo(Id surveyId, Boolean addMessages){
        Set<Id>surveysToClose = new Set<Id>();
        surveysToClose.add(surveyId);
        closeFailedSurveysAndUserInfo(surveysToClose, addMessages);
    }

    public static void closeFailedSurveysAndUserInfo(Set<Id> surveyIds, Boolean addMessages){
        //If there is some missing object, field or relation mapped close the survey and give information to the user
        Set<Id> jobsToClose = new Set<Id>();
        List<SurveyVersion__c> closedAndDraftSurveys = new List<SurveyVersion__c>();
        List<SurveyVersion__c> closedSurveysAuto     = new List<SurveyVersion__c>();

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkObjectUpdateable();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Survey__c,
                SurveyVersion__c.Status__c
            }
        );

        // Get surveys to close
        List<SurveyVersion__c> versions = [SELECT
                                                Status__c,
                                                Survey__c
                                            FROM
                                                SurveyVersion__c
                                            WHERE
                                                Survey__c IN :surveyIds
                                            ORDER BY
                                                Version__c DESC];

        GenericObjectCreator taskTemplateCreator =
            new GenericObjectCreator(TaskTemplate__c.SObjectType);
        taskTemplateCreator.checkObjectAccessible();
        taskTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                TaskTemplate__c.JobTemplate__c
            }
        );

        GenericObjectCreator jobTemplateCreator =
            new GenericObjectCreator(JobTemplate__c.SObjectType);
        jobTemplateCreator.checkObjectAccessible();
        jobTemplateCreator.checkObjectUpdateable();
        jobTemplateCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                JobTemplate__c.CloseReason__c,
                JobTemplate__c.Status__c
            }
        );

        // Get tasks related to these versions to close too
        List<TaskTemplate__c> tasks = [SELECT
                                            JobTemplate__c,
                                            JobTemplate__r.Status__c,
                                            JobTemplate__r.CloseReason__c
                                        FROM
                                            TaskTemplate__c
                                        WHERE
                                            Form__c IN :versions
                                        AND
                                            JobTemplate__r.Status__c = :JobTemplateDO.STATUS_PUBLISHED];

        // If jobs exist, lets update status before update the survey
        if(!tasks.isEmpty()){
            for(TaskTemplate__c task : tasks){
                jobsToClose.add(task.JobTemplate__c);
            }

            List<JobTemplate__c> jobs = [SELECT Id, Status__c, CloseReason__c FROM JobTemplate__c WHERE Id IN :jobsToClose];
            for(JobTemplate__c job : jobs){
                // Close jobs that are related to an invalid survey
                jobTemplateCreator.populateFields(
                    job,
                    new Map<Schema.SObjectField, Object> {
                        JobTemplate__c.Status__c =>  SurveyDO.STATUS_CLOSED,
                        JobTemplate__c.CloseReason__c => SurveyDO.STATUS_CLOSED_AUTO
                    }
                );
            }
            // Update jobs
            update jobs;
        }

        for(SurveyVersion__c version : versions){
            if(version.Status__c == SurveyDO.STATUS_DRAFT || version.Status__c == SurveyDO.STATUS_CLOSED){
                closedAndDraftSurveys.add(version);
            }else if(version.Status__c == SurveyDO.STATUS_PUBLISHED){
                // Close survey with missing mapped objects, fields or relations
                surveyVersionCreator.populateFields(
                    version,
                    new Map<Schema.SObjectField, Object> {
                        SurveyVersion__c.Status__c =>  SurveyDO.STATUS_CLOSED,
                        SurveyVersion__c.CloseReason__c => SurveyDO.STATUS_CLOSED_AUTO
                    }
                );
                closedSurveysAuto.add(version);
            }
        }

        if(!closedSurveysAuto.isEmpty()) {
            // Update survey
            update closedSurveysAuto;
            if (addMessages) {
                // Show information after close and clone survey
                ErrorHandlingRest.addApexPageError(
                    System.Label.ERR_SURVEY_PUBLISHED_CLONE_WRONGMAP,
                    ApexPages.severity.INFO
                );
            }
        } else if(!closedAndDraftSurveys.isEmpty()) {
            if (addMessages) {
                // Show information after clone survey
                ErrorHandlingRest.addApexPageError(
                    System.Label.ERR_SURVEY_NONPUBLISHED_CLONE_WRONGMAP,
                    ApexPages.severity.INFO
                );
            }
        }
    }

    /**
     * Wrapper class for the geolocation data
     */
    public class GeoLocation {
        // Properties
        public Decimal longitude {get; set;}
        public Decimal latitude {get; set;}
        public Decimal altitude {get; set;}
        public Decimal aproximation {get; set;}

        /**
         * Constructor for the class
         */
        public GeoLocation(Decimal theLongitude, Decimal theLatitude, Decimal theAltitude, Decimal theAproximation) {
            this.longitude    = theLongitude;
            this.latitude     = theLatitude;
            this.altitude     = theAltitude;
            this.aproximation = theAproximation;
        }

        /**
         * Check that submitted parsed GPS data is in valid range
         *
         * @param geoLocationField      Contains geo location field name (latitude/longitude)
         * @param parsedLocationField   Contains gps data for latitude/longitude after submission
         * @return                      Valid latitude/longitude data
         */
        public Decimal validGeoLocationValue(String geoLocationField, GeoLocation parsedLocationField) {
            if (geoLocationField.contains('Latitude__s')) {
                return validLatitudeValue(parsedLocationField.latitude);
            } else if (geoLocationField.contains('Longitude__s')) {
                return validLongitudeValue(parsedLocationField.longitude);
            }
            return null;
        }

        /**
         * Check that submitted parsed GPS Latitude data is in valid range
         *
         * @param parsedLatitudeValue   Contains gps data for latitude after submission
         * @return                      Valid latitude/longitude data
         */
        public Decimal validLatitudeValue(Decimal parsedLatitudeValue) {
            if (validateLatitude(parsedLatitudeValue)) {
                return parsedLatitudeValue;
            } else {
                throwExceptionForInvalidGPS();
            }
            return null;
        }

        /**
         * Validate parsed latitude value
        *
        * @param parsedLatitude - parsed latitude value
        * @return               - true value if parsed latitude is in valid range
        */
        public Boolean validateLatitude(Decimal parsedLatitude) {
            if (parsedLatitude < -90 || parsedLatitude > 90) {
                return false;
            } else {
                return true;
            }
        }

        /**
         * Check that submitted parsed GPS Longitude data is in valid range
         *
         * @param parsedLongitudeValue   Contains gps data for longitude after submission
         * @return                       Valid latitude/longitude data
         */
        public Decimal validLongitudeValue(Decimal parsedLongitudeValue) {
            if (validateLongitude(parsedLongitudeValue)) {
                return parsedLongitudeValue;
            } else {
                throwExceptionForInvalidGPS();
            }
            return null;
        }

        /**
        * Validate parsed longitude value
         *
         * @param parsedLongitude - parsed longitude value
         * @return                - true value if parsed longitude is in valid range
         */
        public Boolean validateLongitude(Decimal parsedLongitude) {
            if (parsedLongitude < -180 || parsedLongitude > 180) {
                return false;
            } else {
                return true;
            }
        }

       /**
        * Throw exception if Latitude/Longitude is not in valid range
        */
        public void throwExceptionForInvalidGPS() {
            throw new SurveyException(
                ErrorHandlingRest.ERR_CODE_SUB_INVALID_GPS,
                ErrorHandlingRest.SURVEY_SUB_INVALID_GPS,
                C.HTTP_INTERNAL_SERVER_ERROR,
                System.Label.LOCATION_ERR_INVALIDGPS,
                true
            );
        }
    }
}
