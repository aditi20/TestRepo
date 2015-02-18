/**
 * Trigger Handling class for the QuestionMapping__c object
 * Deals with
 *    - Ensuring that the field is not mapped to another question
 *    - Ensuring that the field still exists
 *    - Ensuring that the type of question matches the type of field mapped to
 *    - Ensuring that a field is not mapped to an AutoNumber unless it is the ID field for the record
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public with sharing class QuestionMappingTH extends TriggerHandler {

    public static Boolean skipValidation = false;

    public static void setSkipValidation(Boolean value) {
        skipValidation = value;
    }

    public static final String ERR_FIELD_ALREADY_MAPPED =
        'A field is being referenced more than once for this surveyMapping';
    public static final String ERR_FIELD_NO_MATCH_QUESTION =
        'A field type doesn\'t match with the question type of the field';

    private Map<Id, Question__c> questionMap;
    private Set<Id> questionIds;
    private Map<Id, SurveyMapping__c> surveyMappingMap;
    private Set<Id> surveyMappingIds;

    private List<QuestionMapping__c> existingMappings;
    private Map<String, Set<Id>> fieldMappings;

    private QuestionMappingDomain getTriggerDomain() {
        return (QuestionMappingDomain) this.domain;
    }

    public override void onBeforeInsert() {
        if (skipValidation) {
            return;
        }
        setUpData((List<QuestionMapping__c>) getRecords());
        validateMappings();
        checkAutoNumberMappings();
    }

    public override void onBeforeUpdate(Map<Id, sObject> oldMap) {
        if (skipValidation) {
            return;
        }
        setUpData((List<QuestionMapping__c>) getRecords());
        validateMappings();
        checkAutoNumberMappings();
    }

    private void setUpData(List<QuestionMapping__c> questionMappings) {
        this.extractIds((List<QuestionMapping__c>) this.domain.records);
        this.questionMap = loadQuestionMap();
        this.surveyMappingMap = loadSurveyMappings();
        this.existingMappings =
            new QuestionMappingSelector().getAllForSurveyMappings(this.surveyMappingMap.keySet());
        this.fieldMappings = createExistingFieldMap();
    }

    private void checkAutoNumberMappings() {

        // Add the existing mappings from the DB for all of the related survey mappings
        this.domain.addRecords(this.existingMappings);
        this.getTriggerDomain().checkFieldIsAutoNumberAndNotId(this.surveyMappingMap);
    }

    private void extractIds(List<QuestionMapping__c> questionMappings) {
        this.questionIds = new Set<Id>();
        this.surveyMappingIds = new Set<Id>();
        for (QuestionMapping__c questionMapping : questionMappings) {
            this.questionIds.add(questionMapping.Question__c);
            this.surveyMappingIds.add(questionMapping.SurveyMapping__c);
        }
    }

    private Map<Id, Question__c> loadQuestionMap() {
        QuestionSelector questionSelector = new QuestionSelector();
        questionSelector.getMainQueryBuilder().setSelectClause(
            new List<Schema.SObjectField>{
                Question__c.Name,
                Question__c.Type__c
            }
        );
        Map<Id, Question__c> idToQuestion = new Map<Id, Question__c>(
            (List<Question__c>) questionSelector.getRecordsById(this.questionIds)
        );
        return idToQuestion;
    }

    private Map<Id, SurveyMapping__c> loadSurveyMappings() {
        SurveyMappingSelector surveyMappingSelector = new SurveyMappingSelector();
        Map<Id, SurveyMapping__c> idToSurveyMapping =
            new Map<Id, SurveyMapping__c>(
                (List<SurveyMapping__c>) surveyMappingSelector.getRecordsById(this.surveyMappingIds)
            );
            return idToSurveyMapping;
    }

    private Map<String, Set<Id>> createExistingFieldMap() {
        // Get the name space prefix
        String namespacePrefix =
            QuestionMapping__c.getSObjectType().getDescribe().getName().split('_')[0];
        Map<String, Set<Id>> duplicateMap = new Map<String, Set<Id>>();
        for (QuestionMapping__c questionMapping : this.existingMappings) {

            // Get the field api name without the prefix
            String fieldApiName = questionMapping.FieldApiName__c.replaceAll(namespacePrefix + '__','');
            if (duplicateMap.get(fieldApiName) == null) {
                duplicateMap.put(fieldApiName, new Set<Id>{questionMapping.SurveyMapping__c});
            } else {
                duplicateMap.get(fieldApiName).add(questionMapping.SurveyMapping__c);
            }
        }
        return duplicateMap;
    }   

    private void validateMappings() {

        // Get the name space prefix
        String namespacePrefix =
            QuestionMapping__c.getSObjectType().getDescribe().getName().split('_')[0];
        for (QuestionMapping__c mapping : (List<QuestionMapping__c>) this.domain.records) {

            // Get the field api name without the prefix
            String fieldApiName = mapping.FieldApiName__c.replaceAll(namespacePrefix + '__','');
            checkFieldMappingNotDuplicated(mapping, fieldApiName);
            String objectName = surveyMappingMap.get(mapping.SurveyMapping__c).ObjectApiName__c;
            checkFieldExists(mapping, objectName);
            checkTypeMatch(mapping, objectName);
        }
    }

    private void checkFieldMappingNotDuplicated(QuestionMapping__c mapping, String fieldApiName) {
        if (this.fieldMappings.get(fieldApiName) == null) {
            this.fieldMappings.put(fieldApiName, new Set<Id>{mapping.SurveyMapping__c});
        } else if (!this.fieldMappings.get(fieldApiName).add(mapping.SurveyMapping__c)) {
            mapping.FieldApiName__c.AddError(ERR_FIELD_ALREADY_MAPPED);
        }
    }

    private void checkFieldExists(QuestionMapping__c mapping, String objectName) {
        if (!DescribeHandler.fieldExists(objectName, mapping.FieldApiName__c)) {
            throw new QuestionMappingTHException(
                DescribeHandler.FIELD_NOT_EXIST,
                new List<String>{mapping.FieldApiName__c, objectName}
            );
        }
    }

    private void checkTypeMatch(QuestionMapping__c mapping, String objectName) {
        String fieldDisplayType =
            DescribeHandler.getFieldDescribe(
                objectName,
                mapping.FieldApiName__c
            ).getType().name();

        Set<String> typeValidMappings =
            QuestionType.QuestionTypeToSchemaType.get(
                questionMap.get(mapping.Question__c).Type__c
            );
        if (typeValidMappings == null || !typeValidMappings.contains(fieldDisplayType)) {
            mapping.FieldApiName__c.AddError(ERR_FIELD_NO_MATCH_QUESTION);
        }
    }

    public class QuestionMappingTHException extends BaseException {
        public QuestionMappingTHException(String message, List<String> args) {
            super(message, args);
        }
    }
}