/**
 * Domain class for the QuestionMapping__c object
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class QuestionMappingDomain extends SObjectDomain {

    public QuestionMappingDomain() {
        super(QuestionMapping__c.SObjectType);
    }
    public QuestionMappingDomain(List<QuestionMapping__c> sObjects) {
        super(sObjects);
    }

    /**
     * Check that any of mappings are to an auto number field and are not the ID field of the
     * survey mapping
     */
    public void checkFieldIsAutoNumberAndNotId(Map<Id, SurveyMapping__c> surveyMappings) {
        for (
                QuestionMapping__c mapping :
                (List<QuestionMapping__c>) this.records
        ) {
            String fieldName = mapping.FieldApiName__c;
            String objectName = surveyMappings.get(mapping.SurveyMapping__c).ObjectApiName__c;
            String idFieldName = surveyMappings.get(mapping.SurveyMapping__c).MatchingField__c;
            if (
                    DescribeHandler.getFieldDescribe(objectName, fieldName).isAutoNumber() &&
                    (String.isBlank(idFieldName) || !fieldName.equalsIgnoreCase(idFieldName))
            ) {
                throw new C.AutonumberNotIdFieldException(
                    System.label.SURVEY_MAPPING_CANT_USE_AN_IF_NOT_IDFIELD_EXCEPTION
                );
            }
        }
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public QuestionMappingDomain constructWithRecords(List<SObject> sObjectList) {
            return new QuestionMappingDomain(sObjectList);
        }
        public QuestionMappingDomain constructEmpty() {
            return new QuestionMappingDomain();
        }
    }
}