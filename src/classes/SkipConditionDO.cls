/**
 * Domain class for the SkipCondition__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class SkipConditionDO extends SObjectDomain {

    public static final String CONDITION_GREATER = 'GreaterThan';
    public static final String CONDITION_LESSER = 'LesserThan';
    public static final String CONDITION_EQUAL = 'Is';
    public static final String CONDITION_ISANSWERED = 'Answered';

    public static Map<String,String> getConditionTranslations() {
        return new Map<String,String>{
            CONDITION_GREATER => Label.SKIPLOGIC_CONDITION_GREATER,
            CONDITION_LESSER => Label.SKIPLOGIC_CONDITION_LESSER,
            CONDITION_EQUAL => Label.SKIPLOGIC_CONDITION_EQUAL,
            CONDITION_ISANSWERED => Label.SKIPLOGIC_CONDITION_ISANSWERED
        };
    }

    public SkipConditionDO() {
        super(SkipCondition__c.SObjectType);
    }
    public SkipConditionDO(List<SkipCondition__c> sObjects) {
        super(sObjects);
    }
}