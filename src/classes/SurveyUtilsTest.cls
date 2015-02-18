/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 * 
 * @author - Aditi Satpute
 */
@isTest
public class SurveyUtilsTest {
    static SurveyUtils.GeoLocation parsedGPSData;

    /**
     * Test Datetime manipulation
     */
    static testMethod void splitDatetimeAndTimeZoneOffsetTest() {
        Test.startTest();
            String[] parts = SurveyUtils.splitDatetimeAndTimeZoneOffset('2012-08-16 02:41:40');
            System.assertEquals(3, parts.size());
            System.assertEquals('2012-08-16 02:41:40', parts[0]);
            System.assertEquals('0', parts[1]);
            System.assertEquals('0', parts[2]);

            parts = SurveyUtils.splitDatetimeAndTimeZoneOffset('2012-08-16 02:41:40+05:30');
            System.assertEquals(3, parts.size());
            System.assertEquals('2012-08-16 02:41:40', parts[0]);
            System.assertEquals('-05', parts[1]);
            System.assertEquals('-30', parts[2]);

            parts = SurveyUtils.splitDatetimeAndTimeZoneOffset('2012-08-16T02:41:40+05:30');
            System.assertEquals(3, parts.size());
            System.assertEquals('2012-08-16 02:41:40', parts[0]);
            System.assertEquals('-05', parts[1]);
            System.assertEquals('-30', parts[2]);

            parts = SurveyUtils.splitDatetimeAndTimeZoneOffset('2012-08-16 02:41:40+0530');
            System.assertEquals(3, parts.size());
            System.assertEquals('2012-08-16 02:41:40', parts[0]);
            System.assertEquals('-05', parts[1]);
            System.assertEquals('-30', parts[2]);

            parts = SurveyUtils.splitDatetimeAndTimeZoneOffset('2012-08-16 02:41:40-05:30');
            System.assertEquals(3, parts.size());
            System.assertEquals('2012-08-16 02:41:40', parts[0]);
            System.assertEquals('05', parts[1]);
            System.assertEquals('30', parts[2]);

            parts = SurveyUtils.splitDatetimeAndTimeZoneOffset('2012-08-16 02:41:40-0530');
            System.assertEquals(3, parts.size());
            System.assertEquals('2012-08-16 02:41:40', parts[0]);
            System.assertEquals('05', parts[1]);
            System.assertEquals('30', parts[2]);

            parts = SurveyUtils.splitDatetimeAndTimeZoneOffset('2012-08-16 02:41:40-05');
            System.assertEquals(3, parts.size());
            System.assertEquals('2012-08-16 02:41:40', parts[0]);
            System.assertEquals('05', parts[1]);
            System.assertEquals('0', parts[2]);
        Test.stopTest();
    }

    static testMethod void valueInGmtTest() {
        Test.startTest();
            String actualDateTime = '' + SurveyUtils.valueInGmt('2012-08-16 02:41:40-05:30');
            String expectDatetime = '2012-08-16 08:11:40';
            System.assertEquals(expectDatetime, actualDateTime);

            actualDateTime = '' + SurveyUtils.valueInGmt('2012-08-16 02:41:40+05:30');
            expectDatetime = '2012-08-15 21:11:40';
            System.assertEquals(expectDatetime, actualDateTime);

            actualDateTime = '' + SurveyUtils.valueInGmt('2012-08-16 02:41:40+0530');
            expectDatetime = '2012-08-15 21:11:40';
            System.assertEquals(expectDatetime, actualDateTime);

            actualDateTime = '' + SurveyUtils.valueInGmt('2012-08-16 02:41:40');
            expectDatetime = '2012-08-16 02:41:40';
            System.assertEquals(expectDatetime, actualDateTime);
        Test.stopTest();
    }

    static testMethod void convertDateTimeToStringTest() {
        Test.startTest();
        DateTime dateTimeInstance = DateTime.valueOf('2014-04-21 14:34:19');
        String actualDateTime = SurveyUtils.convertDateTimeToString(dateTimeInstance);

        // This test can run in any time zone, so making use of Salesforce TimeZone class
        TimeZone currentUserTimeZone = UserInfo.getTimeZone();
        Integer timeOffset = currentUserTimeZone.getOffSet(dateTimeInstance);
        String expectDatetime =
            dateTimeInstance.addSeconds(
                (-1)*(timeOffset/1000)
            ).format('yyyy-MM-dd H:mm:s.SS').replaceFirst(' ', 'T');
        System.assertEquals(expectDatetime, actualDateTime);
        Test.stopTest();
    }

    static testMethod void removeAllWithDistinctRemovelIndexesTest() {
        Object[]  objects           = createSomeObjectsForRemoveAllTest();
        Object[]  expectedObjects   = createExpectedObjects();
        Test.startTest();
            SurveyUtils.removeAll(objects, new Integer[]{1,3});
        Test.stopTest();
        system.assertEquals(expectedObjects, objects);
    }

    static testMethod void removeAllWithDuplicateRemoveIndexesTest() {
        Object[]  objects           = createSomeObjectsForRemoveAllTest();
        Object[]  expectedObjects   = createExpectedObjects();
        Test.startTest();
            SurveyUtils.removeAll(objects, new Integer[]{1,1,1,1,1,1,1,1,3});
        Test.stopTest();
        system.assertEquals(expectedObjects, objects);
    }

    static testMethod void removeAllWithInvalidRemoveIndexesTest() {
        Object[]            objects = createSomeObjectsForRemoveAllTest();
        Object[]    expectedObjects = createExpectedObjects();
        Test.startTest();
            SurveyUtils.removeAll(objects,  new Integer[]{1,3,10,11});
        Test.stopTest();
        system.assertEquals(expectedObjects, objects);
    }

    static testMethod void removeAllWithEmptyRemoveIndexesTest() {
        Object[]           objects = createSomeObjectsForRemoveAllTest();
        Object[]   expectedObjects = createSomeObjectsForRemoveAllTest();
        Test.startTest();
            SurveyUtils.removeAll(objects, new Integer[]{});
        Test.stopTest();
        system.assertEquals(expectedObjects, objects);
    }

    static testMethod void removeAllWithUnsortedRemoveIndexesTest() {
        Object[]            objects = createSomeObjectsForRemoveAllTest();
        Object[]    expectedObjects = createExpectedObjects();
        Test.startTest();
            SurveyUtils.removeAll(objects,  new Integer[]{3,1});
        Test.stopTest();
        system.assertEquals(expectedObjects, objects);
    }

    private static Object[] createSomeObjectsForRemoveAllTest() {
        return new Object[] {
            new Account(name = 'a'),
            new Account(name = 'b'),
            new Account(name = 'c'),
            new Account(name = 'd'),
            new Account(name = 'e')
        };
    }

    private static Object[] createExpectedObjects() {
        return new Object[] {
            new Account(name = 'a'),
            new Account(name = 'c'),
            new Account(name = 'e')
        };
    }

    static testMethod void testIsGeoLocationComponentField() {
        Test.startTest();
        System.assert(
            SurveyUtils.isGeoLocationComponentField(
                'StartLocation__Latitude__s'
            ),
            'Latitude fields are part of geolocation component fields'
        );
        System.assert(
            SurveyUtils.isGeoLocationComponentField(
                'BillingLongitude'
            ),
            'Longitude fields are part of geolocation component fields'
        );
        System.assert(
            !SurveyUtils.isGeoLocationComponentField(
                'StartLocation__c'
            ),
            'Normal Geolocation fields does not contain geolocation component fields'
        );
        Test.stopTest();
    }

    static testMethod void testFormatGeolocationFields() {
        Test.startTest();
        System.assertEquals(
            SurveyUtils.formatGeolocationFields(
                'api location: [19.87 78.58]'
            ),
            '19.87 78.58 0 0',
            'Formatting to be sent to mobile should be correct'
        );
        Test.stopTest();
    }

    /**
     * Test the parsing of a valid geolocation
     */
    static testMethod void testValidGeoLocationParse() {
        // Test with four values
        String location = '-122.366667 -56.516667 0.001 5.002';
        SurveyUtils.GeoLocation parsedLocation =
            SurveyUtils.parseGeoLocation(
                location,
                false
            );

        System.assertEquals(Double.valueOf('-122.366667'), parsedLocation.longitude);
        System.assertEquals(Double.valueOf('-56.516667'), parsedLocation.latitude);
        System.assertEquals(Double.valueOf('0.001'), parsedLocation.altitude);
        System.assertEquals(Double.valueOf('5.002'), parsedLocation.aproximation);

        // Test with five values
        location = '-122.366667 -56.516667 0.001 5.002 1234';
        parsedLocation = SurveyUtils.parseGeoLocation(location, false);

        System.assertEquals(Double.valueOf('-122.366667'), parsedLocation.longitude);
        System.assertEquals(Double.valueOf('-56.516667'), parsedLocation.latitude);
        System.assertEquals(Double.valueOf('0.001'), parsedLocation.altitude);
        System.assertEquals(Double.valueOf('5.002'), parsedLocation.aproximation);
    }

    /**
     * Parsed test data for valid GPS submissions
     */
    static void validGPSSubmissionData() {
        String location = '17.366667 56.516667 0.0 25.0';
        parsedGPSData = SurveyUtils.parseGeoLocation(location, true);
    }

    /**
     * Test the GPS latitude data is in valid range
     */
    static testMethod void testValidGPSLatitudeData() {
        // Create test data for valid GPS submission
        validGPSSubmissionData();

        Decimal validLatitude = parsedGPSData.validGeoLocationValue(
            'Start_Location__Latitude__s',
            parsedGPSData
        );
        // Verify that parsed latitude value is valid
        System.assertEquals(17.366667, validLatitude);
    }

    /**
     * Test the GPS longitude data is in valid range
     */
    static testMethod void testValidGPSLongitudeData() {
        // Create test data for valid GPS submission
        validGPSSubmissionData();

        Decimal validLongitude = parsedGPSData.validGeoLocationValue(
             'Start_Location__Longitude__s',
             parsedGPSData
         );
        // Verify that parsed longitude value is valid
        System.assertEquals(56.516667, validLongitude);
    }

    /**
     * Test the GPS latitude data is not in valid range
     */
    static testMethod void testInvalidGPSLatitudeData() {
        try {
            String location = '96.516667 17.366667 0.0 25.0';
            SurveyUtils.GeoLocation parsedLocation =
                SurveyUtils.parseGeoLocation(
                    location,
                    true
                );
            Decimal invalidLatitude =
                parsedLocation.validLatitudeValue(parsedLocation.latitude);
            System.assert(false, 'This System assert should never get called.');
        } catch (SurveyException surveyException) {
            // Verify that proper error code is generated for invalid GPS latitude data
            System.assertEquals(
                ErrorHandlingRest.ERR_CODE_SUB_INVALID_GPS,
                surveyException.getTwErrorCode()
            );
            // Verify that proper error message is generated for invalid GPS latitude data
            System.assertEquals(
                System.Label.LOCATION_ERR_INVALIDGPS,
                surveyException.getDefaultMessage()
            );
        }
    }

    /**
     * Test the GPS longitude data is not in valid range
     */
    static testMethod void testInvalidGPSLongitudeData() {
        try {
            String location = '56.516667 187.366667 0.0 25.0';
            SurveyUtils.GeoLocation parsedLocation =
                SurveyUtils.parseGeoLocation(
                    location,
                    true
                );
            Decimal invalidLongitude =
                parsedLocation.validLongitudeValue(parsedLocation.longitude);
            System.assert(false, 'This System assert should never get called.');
        } catch (SurveyException surveyException) {
           // Verify that proper error code is generated for invalid GPS longitude data
            System.assertEquals(
                ErrorHandlingRest.ERR_CODE_SUB_INVALID_GPS,
                surveyException.getTwErrorCode()
            );
            // Verify that proper error message is generated for invalid GPS longitude data
            System.assertEquals(
                System.Label.LOCATION_ERR_INVALIDGPS,
                surveyException.getDefaultMessage()
            );
        }
    }

    /**
     * Test the parsing of a null location
     */
    static testMethod void testNullGeoLocationParse() {
        SurveyUtils.GeoLocation parsedLocation =
            SurveyUtils.parseGeoLocation(
                null,
                false
            );
        System.assertEquals(null, parsedLocation);
    }

    /**
     * Test the parsing of a geolocation with wrong number of values
     */
    static testMethod void testWrongGeoLocationParse() {
        String location = '-33.366667 -56.516667 0.001 5.002 45.03 1234';
        try {
            SurveyUtils.GeoLocation parsedLocation =
                SurveyUtils.parseGeoLocation(
                    location,
                    false
                );
            System.assert(
                true,
                'It should throw an exception when the number of values is wrong'
            );
        } catch(SurveyException e) {
            System.assertEquals(e.getTwErrorCode(), ErrorHandlingRest.ERR_CODE_SYNC_GPS_FAIL);
        }

        location = '-56.516667 0.001 5.002';
        try {
            SurveyUtils.GeoLocation parsedLocation =
                SurveyUtils.parseGeoLocation(
                    location,
                    false
                );
            System.assert(
                true,
                'It should throw an exception when the number of values is wrong'
            );
        } catch(SurveyException e) {
            System.assertEquals(e.getTwErrorCode(), ErrorHandlingRest.ERR_CODE_SYNC_GPS_FAIL);
        }
    }

    /**
     * Test the parsing of a geolocation with wrong values
     */
    static testMethod void testWrongDataGeoLocationParse() {
        String location = '-33.366667 -56.sdsd516667 0.001 5.002 1234';
        try {
            SurveyUtils.GeoLocation parsedLocation =
                SurveyUtils.parseGeoLocation(
                    location,
                    false
                );
            System.assert(
                true,
                'It should throw an exception when the values can\'t be parsed'
            );
        } catch(SurveyException e) {
            System.assertEquals(e.getTwErrorCode(), ErrorHandlingRest.ERR_CODE_SYNC_GPS_FAIL);
        }
    }

    // Test preview a survey that has some missing mapped object
    static testMethod void previewSurveyWithMissingMappedObject(){
        // Create survey
        Survey__c survey = new Survey__c(Name = 'SubmissionTestMissingObject', Status__c = SurveyDO.STATUS_DRAFT);
        insert survey;

        // Create questions
        List<Question__c> questions = createQuestions(survey);

        SurveyVersion__c[] versions = [SELECT
                                            Status__c
                                        FROM
                                            SurveyVersion__c
                                        WHERE
                                            Survey__c = :survey.Id
                                        ORDER BY
                                            Version__c DESC];
        // Publish survey
        versions[0].Status__c = SurveyDO.STATUS_PUBLISHED;
        update versions;

        // Create survey mapping with a fake object name that behave as a deleted object.
        SurveyMapping__c sm = TestUtils.mapObject(survey, 'deletedObject');

        Test.startTest();
            SurveyUtils.closeFailedSurveysAndUserInfo(survey.Id, true);
        Test.stopTest();

        System.assertEquals(surveyDO.STATUS_CLOSED, [SELECT Status__c FROM SurveyVersion__c WHERE Survey__c = :survey.Id ORDER BY Version__c DESC LIMIT 1].Status__c);

    }

    // Create questions to use in to the test cases
    static List<Question__c> createQuestions(Survey__c survey){
        Question__c qSection = new Question__c( Survey__c   = survey.Id,
                                                Name = 'section',
                                                Caption__c  = 'section',
                                                Type__c     = QuestionDO.TYPE_SECTION,
                                                Position__c = 1 );
        insert qSection;

        Question__c q1 = new Question__c( Survey__c   = survey.Id,
                                          Name        = 'q1',
                                          Caption__c  = 'q1',
                                          Type__c     = QuestionDO.TYPE_TEXT_SHORT,
                                          Position__c = 1,
                                          Parent__c   = qSection.Id );
        insert q1;

        return new List<Question__c>{qSection, q1};

    }
}