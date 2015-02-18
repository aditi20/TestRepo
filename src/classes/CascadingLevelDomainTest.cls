/**
 * Test class for the CascadingLevel__c object domain class
 * Deals with:
 *     - Creation of cascading levels
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class CascadingLevelDomainTest {

    public static List<CascadingLevel__c> createCascadingLevels(Integer numberOflevels) {
        List<CascadingLevel__c> cascadingLevels = new List<CascadingLevel__c>();
        for (Integer i = 1; i <= numberOflevels; i++) {
            cascadingLevels.add(createCascadingLevel(new Map<Schema.SObjectField, Object>{
                CascadingLevel__c.Name__c => 'Level_' + i,
                CascadingLevel__c.Position__c => i
            }));
        }
        return cascadingLevels;
    }

    public static CascadingLevel__c createCascadingLevel(Map<Schema.SObjectField, Object> fieldMap) {

        GenericObjectCreator creator = new GenericObjectCreator(CascadingLevel__c.getSObjectType());
        CascadingLevel__c cascadingLevel = (CascadingLevel__c) creator.createNewRecord();
        creator.populateFields(
            cascadingLevel,
            fieldMap
        );
        return cascadingLevel;
    }

    /**
     * Adds the passed in CascadingLevel__c to a unit of work.
     * Assumes that the controllingCascadingSelect has already been added
     */
    public static UnitOfWork addLevelsToUnitOfWork(
            List<CascadingLevel__c> cascadingLevels,
            CascadingSelect__c controllingCascadingSelect,
            UnitOfWork unitOfWork
    ) {
        Schema.SObjectType cascadingLevelObjectType = CascadingLevel__c.getSObjectType();
        Integer level = unitOfWork.addToInsertionOrder(cascadingLevelObjectType);
        unitOfWork.addToInsertList(
            cascadingLevels[0],
            CascadingLevel__c.CascadingSelect__c,
            controllingCascadingSelect,
            level
        );
        for (Integer i = 1; i < cascadingLevels.size(); i++) {
            level = unitOfWork.addToInsertionOrder(cascadingLevelObjectType);
            unitOfWork.addToInsertList(
                cascadingLevels[i],
                CascadingLevel__c.CascadingSelect__c,
                controllingCascadingSelect,
                level
            );
            unitOfWork.createRelationship(
                cascadingLevels[i],
                CascadingLevel__c.ControllingLevel__c,
                cascadingLevels[i - 1],
                level
            );
        }
        return unitOfWork;
    }
}