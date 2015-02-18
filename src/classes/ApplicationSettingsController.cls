/**
 * Controller for the Application Settings page
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class ApplicationSettingsController {

    private static final String VALUE_INTEGER = 'INTEGER';
    private static final String VALUE_TEXT = 'STRING';
    private static final String VALUE_PICKLIST = 'PICKLIST';
    private static final String VALUE_ID = 'ID';
    private static final String VALUE_DATE = 'DATE';
    private static final String VALUE_DOUBLE = 'DOUBLE';
    private static final String SELECT_FIELDS = 'selectFields';
    private static final String RESET_FIELDS = 'resetFields';

    public Settings__c setting {get; set;}
    public PpiSettings__c ppiSettingsInstance {get; set;}

    public List<SelectOption> clientIdSelectOption {get; set;}
    public List<SelectOption> genderSelectOption {get; set;}
    public List<SelectOption> ageSelectOption {get; set;}
    public List<SelectOption> householdMembersSelectOption {get; set;}
    public List<SelectOption> dateOfJoiningSelectOption {get; set;}

    public List<ApplicationVersionSettings__c> applicationVersionSettingsList {get; set;}
    public String namespace;
    public List<PpiSettings__c> ppiConfigurationList = new List<PpiSettings__c>();

    // The sort direction defaults to ASC
    public String sortDirection {
        get {
            if (String.isEmpty(sortDirection)) {
                sortDirection = 'ASC'; 
            }
            return sortDirection;
        }
        set;
    }

    // The field to sort for ApplicationVersionSettings__c defaults to Release Date
    public String sortField {
        get {
            if (String.isEmpty(sortField)) {
                sortField =
                    ApplicationVersionSettings__c.ReleaseDate__c.getDescribe().getName();
            }
            return sortField;
        }
        set;
    }

    /**
     * Constructor for the controller
     */
    public ApplicationSettingsController() {
        this.ppiSettingsInstance = new PpiSettings__c();
        this.setting = ApplicationSettingsUtils.getDefaultSetting(false);

        // Default sorting should be with Release Date
        applicationVersionSettingsList =
            ApplicationVersionSettingsSelector.getAllSortedRecords(
                this.sortField,
                'DESC'
            );
        this.namespace = C.getNamespace();

        fetchPpiRecords();
    }

    /**
     * Method to get all PpiSettings data
     */
    public void fetchPpiRecords() {
        this.ppiConfigurationList = PpiSettingsWrapper.getAllRecords();
        if (this.ppiConfigurationList.size() > 0) {
            this.ppiSettingsInstance = this.ppiConfigurationList[0];
        }
        loadFieldsbasedOnType();
    }

    /**
     * Fetch fields depending on their type and assign to list of SelectOption
     */
    public void loadFieldsbasedOnType() {
        initVariables();

        if (DescribeHandler.getFieldMap(this.ppiSettingsInstance.Name) != null) {
            for (String fieldName :
                    DescribeHandler.getFieldMap(this.ppiSettingsInstance.Name).keySet()
            ) {
                Schema.DescribeFieldResult fieldResult = 
                    DescribeHandler.getFieldDescribe(this.ppiSettingsInstance.Name, fieldName);
                fetchFields(fieldResult);
            }
        }
    }

    /**
     * Method to fetch fields based on type and assign to SelectList
     */
    private void fetchFields(Schema.DescribeFieldResult fieldResult) {
        SFDCEncoder encode = new SFDCEncoder();
        String fieldType = encode.SFDC_JSENCODE(String.valueOf(fieldResult.getType()));
        String name = encode.SFDC_JSENCODE(fieldResult.getName());
        String label = encode.SFDC_JSENCODE(fieldResult.getLabel());

        if (fieldType.equalsIgnoreCase(VALUE_INTEGER) ||
                fieldType.equalsIgnoreCase(VALUE_DOUBLE)
        ) {
            if (!SurveyUtils.isGeoLocationComponentField(name)) {
                this.clientIdSelectOption.add(new SelectOption(name, label));
                this.householdMembersSelectOption.add(new SelectOption(name, label));
                this.ageSelectOption.add(new SelectOption(name, label));
            }
        } else if (fieldType.equalsIgnoreCase(VALUE_TEXT)) {
            this.clientIdSelectOption.add(new SelectOption(name, label));
            if (!fieldResult.isAutoNumber()) {
                this.genderSelectOption.add(new SelectOption(name, label));
            }
        } else if (fieldType.equalsIgnoreCase(VALUE_PICKLIST)) {
            this.genderSelectOption.add(new SelectOption(name, label));
        } else if (fieldType.equalsIgnoreCase(VALUE_ID)) {
            this.clientIdSelectOption.add(new SelectOption(name, label));
        } else if (fieldType.equalsIgnoreCase(VALUE_DATE)) {
            this.dateOfJoiningSelectOption.add(new SelectOption(name, label));
        }
        sortFieldsSelectList();
    }

    /**
     * Method to sort Fields 
     */
    private void sortFieldsSelectList() {
        sortSelectOptions(this.clientIdSelectOption);
        sortSelectOptions(this.ageSelectOption);
        sortSelectOptions(this.genderSelectOption);
        sortSelectOptions(this.dateOfJoiningSelectOption);
        sortSelectOptions(this.householdMembersSelectOption);
    }

    /**
     * Method to sort all select lists based on its label
     */
    private void sortSelectOptions(List<SelectOption> selectOptionList) {
        Map<String, SelectOption> mapOptionLabelToSelectOption = new Map<String, SelectOption>();
        Integer counter = 0;
        for (SelectOption selectOption : selectOptionList) {
            mapOptionLabelToSelectOption.put(selectOption.getLabel() + counter++, selectOption);
        }
        List<String> optionLabelList = new List<String>();
        optionLabelList.addAll(mapOptionLabelToSelectOption.keySet());
        optionLabelList.sort();
        selectOptionList.clear();

        for (String label : optionLabelList) {
            selectOptionList.add(mapOptionLabelToSelectOption.get(label));
        }
    }

    /**
     * Method to initailize the fields options list on load
     */
    private void initVariables() {
        this.clientIdSelectOption = new List<SelectOption>();
        this.genderSelectOption = new List<SelectOption>();
        this.ageSelectOption = new List<SelectOption>();
        this.householdMembersSelectOption = new List<SelectOption>();
        this.dateOfJoiningSelectOption = new List<SelectOption>();

        this.clientIdSelectOption.add(new SelectOption('', '-'));
        this.ageSelectOption.add(new SelectOption('', '-'));
        this.genderSelectOption.add(new SelectOption('', '-'));
        this.householdMembersSelectOption.add(new SelectOption('', '-'));
        this.dateOfJoiningSelectOption.add(new SelectOption('', '-'));

        if (ApexPages.currentPage().getParameters().get(SELECT_FIELDS) != null) {
            if (ApexPages.currentPage().getParameters().get(SELECT_FIELDS) == RESET_FIELDS) {
                this.ppiSettingsInstance.ObjectIdApiName__c = '';
                this.ppiSettingsInstance.AgeApiName__c = '';
                this.ppiSettingsInstance.GenderApiName__c = '';
                this.ppiSettingsInstance.HouseholdSizeApiName__c = '';
                this.ppiSettingsInstance.JoinedDateApiName__c = '';
            }
        }
    }

    /**
     * Save the Custom settings of Application version and Settings 
     */
    public PageReference save() {

        Settings__c setting = ApplicationSettingsUtils.getDefaultSetting(true);
        setting.FilterJobsBySalesforceUser__c =
            System.currentPageReference().getParameters().get(
                ApplicationSettingsUtils.JOBS_FILTER_NAME
            );

        if (setting != null) {
            update setting;
        }

        if (!applicationVersionSettingsList.isEmpty()) {
            update this.applicationVersionSettingsList;
        }

        savePpiSettings();

        ApexPages.addMessage(new ApexPages.Message(
            ApexPages.Severity.INFO, System.Label.APPLICATION_SETTINGS_SUCCESS
        ));

        return null;
    }

    /**
     * Save the Custom settings of PpiSettings 
     */
    public void savePpiSettings() {

        if (String.isEmpty(this.ppiSettingsInstance.Name)) {
            List<PpiSettings__c> ppiSettings = PpiSettingsWrapper.getAllRecords();
            if (ppiSettings.size() == 1) {
                delete ppiSettings;

                // Reset the instance if record is deleted
                this.ppiSettingsInstance = new PpiSettings__c();
            }
            this.ppiConfigurationList = PpiSettingsWrapper.getAllRecords();
        } else {

            if (this.ppiSettingsInstance != null) {
                this.ppiSettingsInstance.ObjectApiName__c = ppiSettingsInstance.Name;
                upsert this.ppiSettingsInstance;
            }
        }
    }

    /**
     * Sort the Application version Settings based on field and sorting order selected
     */
    public PageReference sortData() {
        this.applicationVersionSettingsList =
            ApplicationVersionSettingsSelector.getAllSortedRecords(
                (!String.isEmpty(this.namespace) && (this.sortfield.endsWith('__c'))) ?
                    this.namespace + '__' + this.sortField :
                    this.sortField,
                this.sortDirection
            );
        this.sortDirection = this.sortDirection.equals('ASC') ? 'DESC NULLS LAST' : 'ASC';
        return null;
    }

    /**
     * Method that retrieves all objects from the org.
     * TODO : Combine this method with canBeSelected() of ObjectAssignmentController
     */
    public List<SelectOption> getObjectSelectList() {
        SFDCEncoder encoder = new SFDCEncoder();
        Map<String, Schema.SObjectType> objectsMap = DescribeHandler.getGlobalDescribe();
        List<SelectOption> objectSelectOption = new List<SelectOption>();
        objectSelectOption.add(new SelectOption('', '-'));

        for (String objectName : objectsMap.keySet()) {
            GenericObjectCreator creator =
                new GenericObjectCreator(objectName);
            if (creator.isObjectAccessible(false)) {
                // Add all object that do not have the manage package namespace prefix
                // Can not select the mobile-surveys objects to map except PpiResult
                if (!C.hasNameSpacePrefix(objectsMap.get(objectName)) ||
                    C.whiteListedObjects.contains(objectName.toLowerCase())
                ) {
                    Map<String, String> dummyObj = new Map<String, String>();
                    objectSelectOption.add(new SelectOption(
                        encoder.SFDC_JSENCODE(objectsMap.get(objectName).getDescribe().getName()),
                        encoder.SFDC_JSENCODE(objectsMap.get(objectName).getDescribe().getLabel()))
                    );
                }
            }
        }
        sortSelectOptions(objectSelectOption);
        return objectSelectOption;
    }
}
