/**
 * Test class for the ObjectRelationshipMapping__c object domain class
 * Deals with:
 *     - Creation of a Object Relationship Mapping
 *     - Adding Object Relationship Mapping to a UnitOfWork
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class ObjectRelationshipMappingDomainTest {

    public static ObjectRelationshipMapping__c createObjectRelationMapping(
            String fiedApiName
    ) {
        return createObjectRelationMapping(new Map<Schema.SObjectField, Object>{
            ObjectRelationshipMapping__c.FieldApiName__c => fiedApiName
        });
    }

    public static ObjectRelationshipMapping__c createObjectRelationMapping(
            Map<Schema.SObjectField, Object> fieldMap
    ) {

        GenericObjectCreator creator =
            new GenericObjectCreator(ObjectRelationshipMapping__c.getSObjectType());
        ObjectRelationshipMapping__c objectRelationMapping =
            (ObjectRelationshipMapping__c) creator.createNewRecord();
        creator.populateFields(
            objectRelationMapping,
            fieldMap
        );
        return objectRelationMapping;
    }

    public static UnitOfWork addObjectRelationshipToUnitOfWork(
        ObjectRelationshipMapping__c objectRelationMapping,
        SurveyMapping__c childMapping,
        SurveyMapping__c parentMapping,
        UnitOfWork unitOfWork
    ) {

        unitOfWork.addToInsertionOrder(ObjectRelationshipMapping__c.getSObjectType(), 1);
        unitOfWork.addToInsertList(
            objectRelationMapping,
            ObjectRelationshipMapping__c.ChildSurveyMapping__c,
            childMapping,
            1
        );
        unitOfWork.createRelationship(
            objectRelationMapping,
            ObjectRelationshipMapping__c.ParentSurveyMapping__c,
            parentMapping,
            1
        );
        return unitOfWork;
    }
}