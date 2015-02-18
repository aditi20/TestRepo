/**
 * Domain class for the ScoringGroup__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 * @author Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class ScoringGroupDomain extends SObjectDomain {

    public static final String ERR_NO_EDITABLE_SURVEY =
        'The Survey that contains this Question cannot be edited';

    public ScoringGroupDomain() {
        super(ScoringGroup__c.SObjectType);
    }

    public ScoringGroupDomain(List<ScoringGroup__c> sObjects) {
        super(sObjects);
    }

    /**
     * Given a list<String> (names of the Scoring calculation groups),
     * creates and insert each of these SCG.
     */
    public List<ScoringGroup__c> saveGroups(
            List<ScoringGroup> scoringGroups,
            Survey__c survey
    ) {
        return saveGroups(scoringGroups, survey, survey.SurveyVersions__r[0].Id);
    }
    public List<ScoringGroup__c> saveGroups(
            List<ScoringGroup> scoringGroups,
            Survey__c survey,
            Id surveyVersionId
    ) {

        List<ScoringGroup__c> realGroupList = new List<ScoringGroup__c>();
        if (scoringGroups != null && scoringGroups.size() > 0) {
            GenericObjectCreator scoringGroupCreator =
                    new GenericObjectCreator(ScoringGroup__c.sObjectType);
            for (ScoringGroup sg : scoringGroups) {
                ScoringGroup__c scoringGroupInstance =
                    (ScoringGroup__c) scoringGroupCreator.createNewRecord();
                scoringGroupCreator.populateFields(
                    scoringGroupInstance,
                    new Map<Schema.SObjectField, Object>{
                        ScoringGroup__c.Caption__c => sg.caption,
                        ScoringGroup__c.Survey__c => survey.Id,
                        ScoringGroup__c.SurveyVersion__c => surveyVersionId
                    }
                );

                // Mark Scoring Group IsPPI__c true when caption is "PPI" and Survey is of Ppi type
                if (sg.caption == SurveyScoringController.PPI_ID && survey.IsPPI__c) {
                    scoringGroupInstance.IsPPI__c = true;
                }
                realGroupList.add(scoringGroupInstance);
            }
            this.addRecords(realGroupList);

            try {
                insert this.records;
            } catch (Exception e) {
                throw e;
            }
        }
        return realGroupList ;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public ScoringGroupDomain constructWithRecords(List<SObject> sObjectList) {
            return new ScoringGroupDomain(sObjectList);
        }
        public ScoringGroupDomain constructEmpty() {
            return new ScoringGroupDomain();
        }
    }

    /**
     * Inner Wrapper class for Scoring Group
     */
    public class ScoringGroup {
        public String caption {get;set;}
        public String id {get;set;}

        public ScoringGroup(ScoringGroup__c source) {
            this.caption = source.Caption__c;
            this.id = source.Id;
        }
        public ScoringGroup(String pCaption, String pId) {
            this.caption = pCaption;
            this.id = pId;
        }
    }
}