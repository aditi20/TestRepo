/**
 * Test class for the SkipCondition__c object domain class
 * Deals with:
 *     - Creation of a Skip Conditions
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class SkipConditionDOTest {

    public static SkipCondition__c createSkipCondition() {
        return createSkipCondition(new Map<Schema.SObjectField, Object>{
            SkipCondition__c.Condition__c => 'Answered',
            SkipCondition__c.Negate__c => false,
            SkipCondition__c.Value__c => 'value'
        });
    }

    public static SkipCondition__c createSkipCondition(Map<Schema.SObjectField, Object> fieldMap) {

        GenericObjectCreator creator = new GenericObjectCreator(SkipCondition__c.getSObjectType());
        SkipCondition__c skipCondition = (SkipCondition__c) creator.createNewRecord();
        creator.populateFields(
            skipCondition,
            fieldMap
        );
        return skipCondition;
    }

    public static UnitOfWork addSkipConditionToUnitOfWork(
            SkipCondition__c skipCondition,
            Question__c parent,
            Question__c sourceQuestion,
            UnitOfWork unitOfWork,
            Integer level
    ) {

        unitOfWork.addToInsertionOrder(SkipCondition__c.getSObjectType(), level);
        unitOfWork.addToInsertList(
            skipCondition,
            SkipCondition__c.Parent__c,
            parent,
            level
        );
        unitOfWork.createRelationship(
            skipCondition,
            SkipCondition__c.SourceQuestion__c,
            sourceQuestion,
            level
        );
        return unitOfWork;
    }
}