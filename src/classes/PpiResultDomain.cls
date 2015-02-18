/**
 * Domain class for PpiResult object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 * @author - Aditi Satpute
 */
public with sharing class PpiResultDomain extends SObjectDomain {

    public static final String SPLITTER = '_#@#_';

    public PpiResultDomain() {
        super(PpiResult__c.SObjectType);
    }

    public PpiResultDomain(List<PpiResult__c> sObjects) {
        super(sObjects);
    }

    public static PpiResult__c createRecord(PpiResultWrapper wrapper) {
        return createRecord(
            wrapper.ppiResultSequenceOption,
            wrapper.clientId,
            wrapper.gender,
            wrapper.householdSize,
            wrapper.joinedDate,
            wrapper.age,
            wrapper.geoLocation,
            '',
            wrapper.ppiTemplate,
            wrapper.surveyor,
            null
        );
    }

    /**
     * Method to create PpiResult Record
     */
    public static PpiResult__c createRecord(
            Map<Integer, String> ppiResultSequenceOption,
            String clientId,
            String gender,
            Decimal householdSize,
            Date joinedDate,
            Decimal age,
            String geoLocation,
            String organizationName,
            String ppiTemplate,
            Id surveyorId,
            DateTime ppiCollectionDateTime
    ) {
        if (ppiResultSequenceOption.keySet().isEmpty()) {
            return null;
        }
        GenericObjectCreator ppiResultCreator =
            new GenericObjectCreator(PpiResult__c.SObjectType);

        PpiResult__c newPpiResultInstance =
            (PpiResult__c) ppiResultCreator.createNewRecord();
        ppiResultCreator.populateFields(
            newPpiResultInstance,
            new Map<Schema.SObjectField, Object> {
                PpiResult__c.AnswerOne__c => ppiResultSequenceOption.get(1),
                PpiResult__c.AnswerTwo__c => ppiResultSequenceOption.get(2),
                PpiResult__c.AnswerThree__c => ppiResultSequenceOption.get(3),
                PpiResult__c.AnswerFour__c => ppiResultSequenceOption.get(4),
                PpiResult__c.AnswerFive__c => ppiResultSequenceOption.get(5),
                PpiResult__c.AnswerSix__c => ppiResultSequenceOption.get(6),
                PpiResult__c.AnswerSeven__c => ppiResultSequenceOption.get(7),
                PpiResult__c.AnswerEight__c => ppiResultSequenceOption.get(8),
                PpiResult__c.AnswerNine__c => ppiResultSequenceOption.get(9),
                PpiResult__c.AnswerTen__c => ppiResultSequenceOption.get(10),
                PpiResult__c.ClientId__c => clientId,
                PpiResult__c.Gender__c => gender,
                PpiResult__c.HouseholdSize__c => householdSize,
                PpiResult__c.JoinedDate__c => joinedDate,
                PpiResult__c.Age__c => age,
                PpiResult__c.Geolocation__c => geoLocation,
                PpiResult__c.OrganizationName__c => organizationName,
                PpiResult__c.PpiCollectionDate__c => ppiCollectionDateTime,
                PpiResult__c.Surveyor__c => surveyorId,
                PpiResult__c.PpiTemplate__c => ppiTemplate
            }
        );
        return newPpiResultInstance;
    }

    /**
     * Set Collection Date for each record while insert
     *
     * @param ppiResults List of all records on which we need to set Collection Date
     * @param isMigration Need to take care to not populate if package migrating to 3.1 
     */
    public void setCollectionDatePpiResults(List<PpiResult__c> ppiResults, Boolean isMigration) {
        if (!isMigration) {
            for (PpiResult__c ppiResult : ppiResults) {
                setCollectionDate(ppiResult);
            }
        }
    }

    private void setCollectionDate(PpiResult__c ppiResult) {
        GenericObjectCreator ppiResultCreator =
            new GenericObjectCreator(PpiResult__c.SObjectType);
        ppiResultCreator.populateFields(
            ppiResult,
            new Map<Schema.SObjectField, Object> {
                PpiResult__c.PpiCollectionDate__c => System.now(),
                PpiResult__c.OrganizationName__c => UserInfo.getOrganizationName()
            }
        );
    }

    /**
     * Set the unique key for each record in the domain
     */
    public void setUniqueKeys(List<PpiResult__c> ppiResults) {
        GenericObjectCreator ppiResultCreator =
            new GenericObjectCreator(PpiResult__c.SObjectType);

        Set<Id> surveyVersionIds = fetchPpiResultSurveyVersionIds(ppiResults);

        // Map used to fetch PpiIdentifier based on Survey Version Ids
        Map<String, SurveyVersion__c> mapSurveyVersionIdToInstance =
            SurveyVersionDomain.getSurveyVersionIdToInstanceMap(surveyVersionIds);

        for (PpiResult__c ppiResult : ppiResults) {

            String ppiIdentifier = '';
            if (mapSurveyVersionIdToInstance.containsKey(ppiResult.PpiTemplate__c)) {
                ppiIdentifier = mapSurveyVersionIdToInstance.get(
                    ppiResult.PpiTemplate__c
                ).Survey__r.PpiIdentifier__c;
            }

            ppiResultCreator.populateFields(
                ppiResult,
                new Map<Schema.SObjectField, Object> {
                    PpiResult__c.UniqueKey__c => encodePpiUniqueKey(
                        createPpiResultUniqueKey(
                            ppiResult,
                            ppiIdentifier,
                            populateSequenceOptionIdsMap(ppiResult)
                        )
                    )
                }
            );
        }
    }

    /**
     * Method to create hash digests that are compact representations of the original data
     */
    public static String encodePpiUniqueKey(String recievedPpiDataUniqueKey) {
        return EncodingUtil.base64Encode(
            Crypto.generateDigest('MD5', Blob.valueof(recievedPpiDataUniqueKey))
        );
    }

    /**
     * Method to create unique key based on PpiResult Data
     */
    public static String createPpiResultUniqueKey(
            PpiResult__c ppiResult,
            String ppiIdentifier,
            Map<Integer, String> ppiResultSequenceOptionIdsMap
    ) {
        List<String> uniqueKeyDataList = new List<String>();
        uniqueKeyDataList.add(ppiIdentifier);
        uniqueKeyDataList.addAll(populateGeneralFieldsList(ppiResult));
        uniqueKeyDataList.addAll(populateDemographicFieldsList(ppiResult));
        uniqueKeyDataList.addAll(
            populatePpiQuestionFieldsListInSequence(ppiResultSequenceOptionIdsMap)
        );

        StringBuilder stringBuilderInstance = new StringBuilder(uniqueKeyDataList);
        stringBuilderInstance.setJoiner(SPLITTER);

        return stringBuilderInstance.generateString();
    }

    /**
     * Method to populate a list of general fields of PpiResult
     */
    private static List<String> populateGeneralFieldsList(PpiResult__c ppiResult) {
        List<String> generalFieldsList = new List<String>();
        generalFieldsList.add(ppiResult.OrganizationName__c);
        generalFieldsList.add(String.valueOf(ppiResult.PpiCollectionDate__c));
        generalFieldsList.add(String.valueOf(
            ppiResult.PpiScore__c != null
            ? ppiResult.PpiScore__c.setScale(1)
            : ppiResult.PpiScore__c
        ));
        return generalFieldsList;
    }

    /**
     * Method to populate a list of demograpic fields of PpiResult
     */
    private static List<String> populateDemographicFieldsList(PpiResult__c ppiResult) {
        List<String> demographicFieldsList = new List<String>();
        demographicFieldsList.add(ppiResult.ClientId__c);
        demographicFieldsList.add(ppiResult.Gender__c);
        demographicFieldsList.add(String.valueOf(ppiResult.Age__c));
        demographicFieldsList.add(String.valueOf(ppiResult.HouseholdSize__c));
        demographicFieldsList.add(String.valueOf(ppiResult.JoinedDate__c));
        demographicFieldsList.add(String.valueOf(
            ppiResult.GeoLocation__Latitude__s != null
            ? ppiResult.GeoLocation__Latitude__s.setScale(6)
            : ppiResult.GeoLocation__Latitude__s
        ));
        demographicFieldsList.add(String.valueOf(
            ppiResult.GeoLocation__Longitude__s != null
            ? ppiResult.GeoLocation__Longitude__s.setScale(6)
            : ppiResult.GeoLocation__Longitude__s
        ));
        return demographicFieldsList;
    }

    /**
     * Method to populate a list of Ppi Question fields of PpiResult
     */
    private static List<String> populatePpiQuestionFieldsListInSequence(
            Map<Integer, String> ppiResultSequenceOptionIdsMap
    ) {
        List<String> ppiQuestionFieldsList = new List<String>();
        ppiQuestionFieldsList.add(ppiResultSequenceOptionIdsMap.get(1));
        ppiQuestionFieldsList.add(ppiResultSequenceOptionIdsMap.get(2));
        ppiQuestionFieldsList.add(ppiResultSequenceOptionIdsMap.get(3));
        ppiQuestionFieldsList.add(ppiResultSequenceOptionIdsMap.get(4));
        ppiQuestionFieldsList.add(ppiResultSequenceOptionIdsMap.get(5));
        ppiQuestionFieldsList.add(ppiResultSequenceOptionIdsMap.get(6));
        ppiQuestionFieldsList.add(ppiResultSequenceOptionIdsMap.get(7));
        ppiQuestionFieldsList.add(ppiResultSequenceOptionIdsMap.get(8));
        ppiQuestionFieldsList.add(ppiResultSequenceOptionIdsMap.get(9));
        ppiQuestionFieldsList.add(ppiResultSequenceOptionIdsMap.get(10));
        return ppiQuestionFieldsList;
    }

    /**
     * Method to populate Map of Sequence to Option Ids for specific PpiResult record
     */
    private static Map<Integer, String> populateSequenceOptionIdsMap(PpiResult__c ppiResult) {
        Map<Integer, String> ppiResultSequenceOptionIds = new Map<Integer, String>();
        ppiResultSequenceOptionIds.put(1, ppiResult.AnswerOne__c);
        ppiResultSequenceOptionIds.put(2, ppiResult.AnswerTwo__c);
        ppiResultSequenceOptionIds.put(3, ppiResult.AnswerThree__c);
        ppiResultSequenceOptionIds.put(4, ppiResult.AnswerFour__c);
        ppiResultSequenceOptionIds.put(5, ppiResult.AnswerFive__c);
        ppiResultSequenceOptionIds.put(6, ppiResult.AnswerSix__c);
        ppiResultSequenceOptionIds.put(7, ppiResult.AnswerSeven__c);
        ppiResultSequenceOptionIds.put(8, ppiResult.AnswerEight__c);
        ppiResultSequenceOptionIds.put(9, ppiResult.AnswerNine__c);
        ppiResultSequenceOptionIds.put(10, ppiResult.AnswerTen__c);

        return ppiResultSequenceOptionIds;
    }

    /**
     * Method to populate a map of Option remote Ids with sequence for specific PpiResult record
     */
    public static Map<Integer, String> populateSequenceOptionRemoteIdsMap(PpiResult__c ppiResult) {
        Map<Integer, String> ppiResultSequenceOptionRemoteIdsMap = new Map<Integer, String>();
        ppiResultSequenceOptionRemoteIdsMap.put(
            1,
            StringBuilder.convertID(
                ppiResult.AnswerOne__r.RemoteId__c
            )
        );
        ppiResultSequenceOptionRemoteIdsMap.put(
            2,
            StringBuilder.convertID(
                ppiResult.AnswerTwo__r.RemoteId__c
            )
        );
        ppiResultSequenceOptionRemoteIdsMap.put(
            3,
            StringBuilder.convertID(
                ppiResult.AnswerThree__r.RemoteId__c
            )
        );
        ppiResultSequenceOptionRemoteIdsMap.put(
            4,
            StringBuilder.convertID(
                ppiResult.AnswerFour__r.RemoteId__c
            )
        );
        ppiResultSequenceOptionRemoteIdsMap.put(
            5,
            StringBuilder.convertID(
                ppiResult.AnswerFive__r.RemoteId__c
            )
        );
        ppiResultSequenceOptionRemoteIdsMap.put(
            6,
            StringBuilder.convertID(
                ppiResult.AnswerSix__r.RemoteId__c
            )
        );
        ppiResultSequenceOptionRemoteIdsMap.put(
            7,
            StringBuilder.convertID(
                ppiResult.AnswerSeven__r.RemoteId__c
            )
        );
        ppiResultSequenceOptionRemoteIdsMap.put(
            8,
            StringBuilder.convertID(
                ppiResult.AnswerEight__r.RemoteId__c
            )
        );
        ppiResultSequenceOptionRemoteIdsMap.put(
            9,
            StringBuilder.convertID(
                ppiResult.AnswerNine__r.RemoteId__c
            )
        );
        ppiResultSequenceOptionRemoteIdsMap.put(
            10,
            StringBuilder.convertID(
                ppiResult.AnswerTen__r.RemoteId__c
            )
        );

        return ppiResultSequenceOptionRemoteIdsMap;
    }

    /**
     * Method used fetch surveyVersion Ids for specified PpiResult records
     */
    public static Set<Id> fetchPpiResultSurveyVersionIds(
            List<PpiResult__c> ppiResults
    ) {
        Set<Id> surveyVersionIds = new Set<Id>();

        for (PpiResult__c ppiResult : ppiResults) {
            surveyVersionIds.add(ppiResult.PpiTemplate__c);
        }

        return surveyVersionIds;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public PpiResultDomain constructWithRecords(List<sObject> sObjectList) {
            return new PpiResultDomain(sObjectList);
        }

        public PpiResultDomain constructEmpty() {
            return new PpiResultDomain();
        }
    }

    /**
     * Wrapper class for a PpiResult object. This allows for the result to be built up
     * from the Answers to a submission
     */
    public class PpiResultWrapper {
        private Map<Integer, String> ppiResultSequenceOption;
        public String clientId;
        @TestVisible
        private String gender;
        @TestVisible
        private Decimal householdSize;
        @TestVisible
        private Date joinedDate;
        @TestVisible
        private Decimal age;
        private String geoLocation;
        private String organizationName;
        private String ppiTemplate;
        private DateTime childPpiCreatedDate;
        private Id surveyor;

        public PpiResultWrapper(String ppiTemplate) {
            this.ppiTemplate = ppiTemplate;
            this.ppiResultSequenceOption = new Map<Integer, String>();
        }

        public void processAnswer(
                Question__c ppiQuestion,
                Answer__c ppiAnswer,
                Option__c option
        ) {
            if (ppiQuestion == null) {
                throw new SubmissionDO.SubmissionException();
            }
            if (ppiQuestion.PpiResultsField__c.equalsIgnoreCase('ClientId__c')) {
                this.clientId = ppiAnswer.Value__c;
            } else if (ppiQuestion.PpiResultsField__c.equalsIgnoreCase('Gender__c')) {
                this.gender = option.Caption__c;
            } else if (ppiQuestion.PpiResultsField__c.equalsIgnoreCase('Age__c')) {
                this.age = ppiAnswer.NumericValue__c;
            } else if (ppiQuestion.PpiResultsField__c.equalsIgnoreCase('HouseholdSize__c')) {
                this.householdSize = ppiAnswer.NumericValue__c;
            } else if (ppiQuestion.PpiResultsField__c.equalsIgnoreCase('JoinedDate__c')) {
                this.joinedDate = ppiAnswer.DateValue__c;
            } else if (ppiQuestion.PpiResultsField__c.equalsIgnoreCase('Geolocation__c')) {
                this.geoLocation = ppiAnswer.Value__c;
            } else {
                throw new SubmissionDO.SubmissionException();
            }
        }

        public void populateGeneralFields(Submission__c submission) {
            // Populate Surveyor
            this.surveyor = submission.Surveyor__c;
        }

        public void setPpiResultSequenceOption(Integer sequenceNumber, String optionId) {
            this.ppiResultSequenceOption.put(sequenceNumber, optionId);
        }

        public Map<Integer, String> getPpiResultSequenceOption() {
            return this.ppiResultSequenceOption;
        }

        /**
         * This method is used to populate ppi result wrapper with missing demographic data
         * Based on demographic Custom settings saved in Ppi Settings
         */
        public void updateDemographicFieldsWithExistingData(
                PpiSettings__c ppiSetting,
                Sobject demographicInstance
        ) {
            if (this.clientId != null) {
                if (this.gender == null && ppiSetting.GenderApiName__c != null) {
                    this.gender = String.valueOf(demographicInstance.get(ppiSetting.GenderApiName__c));
                }
                if (this.householdSize == null && ppiSetting.HouseholdSizeApiName__c != null) {
                    this.householdSize = Integer.valueOf(demographicInstance.get(ppiSetting.HouseholdSizeApiName__c));
                }
                if (this.joinedDate == null && ppiSetting.JoinedDateApiName__c != null) {
                    this.joinedDate = Date.valueOf(demographicInstance.get(ppiSetting.JoinedDateApiName__c));
                }
                if (this.age == null && ppiSetting.AgeApiName__c != null) {
                    this.age = Integer.valueOf(demographicInstance.get(ppiSetting.AgeApiName__c));
                }
            }
        }
    }
}