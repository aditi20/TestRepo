/**
*   Before update: This trigger validate if the score value of an option in a distributed survey was edited
*	In affirmative case, an error is shown.
*	Before delete: Select and delete all related skip logic.
*
*   @author Santiago Blankleider
*
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*
*/
trigger DeleteRelatedSkipLogic on Option__c (before delete, before update) {
    if(trigger.isUpdate){
        GenericObjectCreator optionCreator =
            new GenericObjectCreator(Option__c.SObjectType);
        optionCreator.checkObjectAccessible();
        optionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Option__c.PPIScore__c,
            Option__c.Position__c
        });

        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Position__c,
                Question__c.RemoteServerId__c
            }
        );

        List<Option__c> oldOptions = [SELECT PPIScore__c,Position__c, Question__r.Position__c, Question__r.RemoteServerId__c
							          FROM Option__c
							          WHERE Id IN :trigger.old AND Question__r.RemoteServerId__c != null
							          ORDER BY Question__r.Position__c, Position__c];

		if(oldOptions.size() > 0){
			for(Option__c newOp : trigger.new){
				if(trigger.oldMap.get(newOp.Id).PPIScore__c != newOp.PPIScore__c){
					newOp.addError(system.label.SCORE_ERR_CANTEDITDISTRUBUTEDPPISCORE);
					break;
				}
			}
		}
    } else {
        GenericObjectCreator skipConditionCreator =
            new GenericObjectCreator(SkipCondition__c.SObjectType);
        skipConditionCreator.checkObjectAccessible();
        skipConditionCreator.checkObjectDeletable();

        delete [
            SELECT
                Id
            FROM
                SkipCondition__c
            WHERE
                SkipValue__c IN :trigger.oldMap.keyset()
        ];
    }
}
