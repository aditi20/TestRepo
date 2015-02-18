/**
 * Domain class for the ScoreValue__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class ScoreValueDomain extends SObjectDomain {

    public ScoreValueDomain() {
        super(ScoreValue__c.SObjectType);
    }

    public ScoreValueDomain(List<ScoreValue__c> sObjects) {
        super(sObjects);
    }

    /**
     * Given a list of ScoringValue object (inner Class),
     * and a map with the form <ScoringGroup__c.Caption, ScoringGroup__c.Id>,
     * insert each Scoring value, and relate it with the correct ScoringGroup.
     */
    public void saveScoringValues(
            List<ScoringValue> scoringValues,
            Map<String, Id> mapNameIdGroup
    ) {
        List<ScoreValue__c> scoreValueList = new List<ScoreValue__c>();
        if (scoringValues != null && scoringValues.size() > 0 ) {
            GenericObjectCreator scoreValueCreator =
                    new GenericObjectCreator(ScoreValue__c.sObjectType);
            for (ScoringValue sv : scoringValues) {
                ScoreValue__c scoreValueInstance =
                    (ScoreValue__c) scoreValueCreator.createNewRecord();
                scoreValueCreator.populateFields(
                    scoreValueInstance,
                    new Map<Schema.SObjectField, Object> {
                        ScoreValue__c.Option__c => sv.optionId,
                        ScoreValue__c.ScoringGroup__c => mapNameIdGroup.get(sv.groupName),
                        ScoreValue__c.Value__c =>
                            (String.isBlank(sv.value)) ? 0 : decimal.valueOf(sv.value)
                    }
                );
                scoreValueList.add(scoreValueInstance);
            }
            this.addRecords(scoreValueList);

            try {
                this.insertRecords();
            } catch (Exception e) {
                throw e;
            }
        }
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public ScoreValueDomain constructWithRecords(List<SObject> sObjectList) {
            return new ScoreValueDomain(sObjectList);
        }
        public ScoreValueDomain constructEmpty() {
            return new ScoreValueDomain();
        }
    }

    /**
     * Inner wrapper class for Scoring Value
     */
    public class ScoringValue {
        public String value {get;set;}
        public String optionId {get;set;}
        public String groupName {get;set;}

        public ScoringValue(ScoreValue__c source, String nameGroup) {
            this.value = String.valueOf(source.Value__c);
            this.optionId = source.Option__c;
            this.groupName = nameGroup;
        }

        public ScoringValue(string pValue, String pOptionId,string pGroupName) {
            this.value = pValue;
            this.optionId = pOptionId;
            this.groupName = pGroupName;
        }
    }
}