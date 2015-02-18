/**
* This class contains logic for SurveyMappingAsIntervieweeValidation Trigger
* on SurveyMapping object.
*
* (c) Copyright 2014 Grameen Foundation USA. All rights reserved
*
* @author - Aditi Satpute
*/
public with sharing class SurveyMappingTH extends TriggerHandler {

    private SurveyMappingDomain getTriggerDomain() {
        return (SurveyMappingDomain) this.domain;
    }

    /**
     * Validate selected object has namespace
     */
    public override void validate() {
        // Verify that Objects mapped does not contain any namespace
        validateObjectNamespace();
    }

    /**
     * Actions carried out:-
     *     - Throw an error if Survey Mapping contains a field having namespace
     *     - Custom object "PpiResult" inspite of having namespace should not be
     *       considered while throwing error 
     */
    public void validateObjectNamespace() {
        Survey__c[] surveys = new SurveySelector().getWithSurveyMappings(getRelatedSurveyIds());

        // Get the namespace prefix to validate
        String namespacePrefix = Survey__c.getSObjectType().getDescribe().getName().split('_')[0];

        for (Survey__c survey : surveys) {
            for (SurveyMapping__c surveyMappingInstance : survey.Survey_Mappings__r) {

                // A survey should not be mapped to any object having namespace except PpiResult
                if (surveyMappingInstance.ObjectApiName__c.contains(namespacePrefix) &&
                    !C.whiteListedObjects.contains(
                        surveyMappingInstance.ObjectApiName__c.toLowerCase()
                    )
                ) {
                    trigger.newMap.get(surveyMappingInstance.Id).addError(
                        system.Label.BUILDER_ERR_MOBILESURVEY_MAPPING
                    );
                }
            }
        }
    }

    /**
     * Return a set of Survey Ids related to SurveyMapping that is inserted/updated
     */
    public Set<Id> getRelatedSurveyIds() {
        Set<Id> surveyIds = new Set<Id>();

        for (SurveyMapping__c surveyMapping :
                (List<SurveyMapping__c>) getTriggerDomain().records
        ) {
            surveyIds.add(surveyMapping.Survey__c);
        }
        return surveyIds;
    }
}