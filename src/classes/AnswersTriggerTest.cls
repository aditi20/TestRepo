/**
 * This test class is used to cover test cases for Answers trigger.
 * 
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 */
@isTest
public class AnswersTriggerTest {

    static Question__c questionRepeat = new Question__c();

    static testMethod void testAfterUpdateTriggerHandler() {
        
        Test.startTest();
        // Pass parameters for number of submissions and number of answers for a single submission to be created
        List<Answer__c> listAnswer = createAfterUpdatePreConditions(2, 3);
        insert listAnswer;
        Test.stopTest();
        System.assertEquals(
            3,
            [SELECT
                MaxInstance__c
            FROM
                Question__c
            WHERE
                Id = :questionRepeat.Id
            LIMIT 1
            ].MaxInstance__c
        );
    }

    /**
    * Create test data for child answers.
    * 
    * @param noOfSubmissions - Integer value to indicate number of Submissions to be created
    * @param noOfAnswers - Integer value to indicate number of answers to be created
    */
    public static List<Answer__c> createAfterUpdatePreConditions(Integer noOfSubmissions, Integer noOfAnswers) {
        Contact contactInst =  TestUtils.createContact();

        // Create Survey Data
        Survey__c survey = TestUtils.createSurvey('TestSurvey');
        System.assertEquals(
            true,
            survey.Id != null,
            'Test Case for Answers trigger - Survey not inserted properly. Please verify.'
        );

        SurveyVersion__c version =  [SELECT
                                            Id
                                        FROM
                                            SurveyVersion__c
                                        WHERE
                                            Survey__c = :survey.Id
                                        LIMIT 1
                                    ];

        // Create Submission Records
        List<Submission__c> listSubmissions = new List<Submission__c>();
        for (Integer i = 0; i < noOfSubmissions ; i++) {
            listSubmissions.add(TestUtils.createSubmission(survey.Id, version.Id, contactInst.Id));
        }
        insert listSubmissions;

        // Create Question related data
        Question__c sectionRepeat = TestUtils.addQuestion(survey, 1, 'section', QuestionDO.TYPE_REPEAT);
        questionRepeat = TestUtils.addQuestion(sectionRepeat, 1, 'numberQuestion', QuestionDO.TYPE_NUMBER_INTEGER);
        System.assertEquals(
            true,
            questionRepeat.Id != null,
            'Test Case for Answers trigger - Repeat Question not inserted properly.'
        );

        List<Answer__c> listAnswer = new List<Answer__c>();
        // Create Answers for this repeat Question
        for (Integer i = 0; i < noOfSubmissions; i++) {
            for (Integer j = 1; j <= noOfAnswers; j++) {
                listAnswer.add(new Answer__c (
                    Submission__c = listSubmissions[i].Id,
                    Instance__c = j,
                    Question__c = questionRepeat.Id
                ));
            }
        }
        System.assertEquals(
            noOfAnswers*noOfSubmissions,
            listAnswer.size(),
            'Test Case for Answers trigger - Answer list created should have same size as that requested.'
       );
       return listAnswer;
    }
}