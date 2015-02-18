/**
 * Wrapper class for the PpiSettings Custom Settings
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 * 
 * @author - Aditi Satpute
 */
public class PpiSettingsWrapper {

    public static Map<String, PpiSettings__c> getAllRecordsMap() {
        return PpiSettings__c.getAll();
    }

    /**
     * Fetch all record from PpiSettings custom setting 
     */
    public static List<PpiSettings__c> getAllRecords() {
        return getAllRecordsMap().values();
    }

    /**
     * Fetch record from custom setting for specified Name
     */
    public static PpiSettings__c getRecordForName(String customSettingName) {
        return PpiSettings__c.getValues(customSettingName);
    }

    public static String getFieldValue(String customSettingName, String fieldApi) {
        return String.valueOf(getRecordForName(customSettingName).get(fieldApi));
    }

    public static String createDemographicDataQuery(
            PpiSettings__c demographicMapping,
            PpiResultDomain.PpiResultWrapper ppiResultWrapper
    ) {
        Map<String, Schema.SObjectField> demographicObjectFieldMap =
            DescribeHandler.getFieldMap(demographicMapping.Name);
        Map<String, String> demographicObjectFieldsApiToValueMap =
            getPopulatedApiFields(demographicMapping);
        List<Schema.Sobjectfield> relevantSobjectFields = new List<Schema.Sobjectfield>();
        for (String demographicObjectField : demographicObjectFieldsApiToValueMap.values()) {
            if (demographicObjectFieldMap.containsKey(demographicObjectField)) {
                relevantSobjectFields.add(demographicObjectFieldMap.get(demographicObjectField));
            }
        }
        SObjectSelector.SoqlQueryBuilder soqlQueryBuilder =
            formActualQuery(demographicMapping, ppiResultWrapper, relevantSobjectFields);

        return soqlQueryBuilder.generateSoqlQuery(SObjectSelector.AND_OPERATOR, 0);
    }

    private static SObjectSelector.SoqlQueryBuilder formActualQuery(
            PpiSettings__c demographicMapping,
            PpiResultDomain.PpiResultWrapper ppiResultWrapper,
            List<Schema.Sobjectfield> releavantSobjectFields
    ) {
        SObjectSelector.SoqlQueryBuilder soqlQueryBuilder =
            new SObjectSelector.SoqlQueryBuilder(
                demographicMapping.Name,
                demographicMapping.Name,
                releavantSobjectFields,
                ''
            );
        soqlQueryBuilder.addToWhereClause(
            soqlQueryBuilder.generateStandardWhereClause(
                getFieldValue(
                    demographicMapping.Name,
                    PpiSettings__c.ObjectIdApiName__c.getDescribe().getName()
                ),
                SObjectSelector.EQUALS_OPERATOR,
                ppiResultWrapper.clientId
            )
        );
        return soqlQueryBuilder;
    }

    /**
     * Method to create Map of Api names for custom fields 
     */
    private static Map<String, String> getPopulatedApiFields(PpiSettings__c demographicMapping) {
        Map<String, String> populatePpiSettingsApiFieldsMap = new Map<String, String>();
        for (
                Schema.Sobjectfield field :
	                DescribeHandler.getFieldMap(
	                    PpiSettings__c.getSObjectType().getDescribe().getName()
	                ).values()
        ) {
            if (
                    field.getDescribe().isCustom() &&
                    demographicMapping.get(field.getDescribe().getName()) != null
            ) {
                populatePpiSettingsApiFieldsMap.put(
                    field.getDescribe().getName(),
                    getFieldValue(demographicMapping.Name, field.getDescribe().getName())
                );
            }
        }
        return populatePpiSettingsApiFieldsMap;
    }

    /**
     * Insert a new Ppi Settings custom Setting record
     */
    public static PpiSettings__c insertRecord(
            String name,
            String age,
            String clientId,
            String dateJoinedOrganization,
            String gender,
            String householdMembers
    ) {
        PpiSettings__c ppiSetting =
            createRecord(
                name,
                age,
                clientId,
                dateJoinedOrganization,
                gender,
                householdMembers
        );
        insert ppiSetting;
        return ppiSetting;
    }

    /**
     * Create a new Ppi Settings custom Setting record
     */
    public static PpiSettings__c createRecord(
            String name,
            String age,
            String clientId,
            String dateJoinedOrganization,
            String gender,
            String householdMembers
    ) {
        PpiSettings__c ppiSetting =
            new PpiSettings__c(
                Name = name,
                ObjectApiName__c = name,
                AgeApiName__c = age,
                ObjectIdApiName__c = clientId,
                JoinedDateApiName__c = dateJoinedOrganization,
                GenderApiName__c = gender,
                HouseholdSizeApiName__c = householdMembers
            );
        return ppiSetting;
    }
}