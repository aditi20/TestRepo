/**
 * Logic for trigger handling for the Score Value object.
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
public with sharing class ScoreValueTH extends TriggerHandler {

    private ScoreValueDomain getTriggerDomain() {
        return (ScoreValueDomain) this.domain;
    }

    public override void onAfterInsert() {
        addPpiScoringDetails(null);
    }

    public override void onAfterUpdate(Map<Id, sObject> oldMap) {
        addPpiScoringDetails(oldMap);
    }

    /**
     * Process Score value records to populate related Option records
     */
    public void addPpiScoringDetails(Map<Id, sObject> oldMap) {
        Map<Id, sObject> mapNewScoreValue = new Map<Id, sObject> (getTriggerDomain().records);
        List<ScoreValue__c> listScoreValue =
            new ScoreValueSelector().getWithParentFields(mapNewScoreValue.keySet());

        Map<Id, Decimal> mapOptionIdToScore = new Map<Id, Decimal>();
        for (ScoreValue__c scoreValueInstance : listScoreValue) {
            if (scoreValueInstance.ScoringGroup__r.IsPPI__c) {
                mapOptionIdToScore.put(scoreValueInstance.Option__c, scoreValueInstance.Value__c);
            }
        }
        populateOptionPpiScores(mapOptionIdToScore);
    }

    /**
     * Method to populate Option records with its corresponding Ppi Score
     */
    private void populateOptionPpiScores(Map<Id, Decimal> mapOptionIdToScore) {
        if (!mapOptionIdToScore.isEmpty()) {
            List<Option__c> listOption =
                new OptionSelector().getRecordsById(mapOptionIdToScore.keySet());
            GenericObjectCreator optionCreator = new GenericObjectCreator(Option__c.sObjectType);
            for (Option__c optionInstance : listOption) {
                optionCreator.populateField(
                    optionInstance,
                    Option__c.PPIScore__c,
                    mapOptionIdToScore.get(optionInstance.Id)
                );
            }

            OptionDomain optionDomain =
                new OptionDomain.Constructor().constructWithRecords(listOption);
            optionDomain.updateRecords();
        }
    }
}