/*
 * Controller for the CreateIndicatorTarget page
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Ernesto Quesada
 * @author - Aditi Satpute
 */
public with sharing class CreateIndicatorTargetController extends CreateTargetController {

    // List of all child objects of Contact
    public List<SelectOption> contactChildObjects {get; set;}

    // Map of the field labels to its object and API name
    private Map<String, Map<String, String>> fieldLabelByObjectAndName;

    // Json of the map of fields
    public String getFieldLabelByObjectAndName() {
        return JSON.serialize(fieldLabelByObjectAndName);
    }

    /**
     * Constructor of the class
     *
     * @param stdController - An instance of the standard controller
     */
    public CreateIndicatorTargetController(ApexPages.StandardController stdController) {
        super(stdController);
        this.contactChildObjects = new List<SelectOption>();
    }

    /**
     * Save performance target with assigned targets to data base
     *
     * @return - The reference of the page to redirect to
     */
    public PageReference save() {
        if (!DescribeHandler.validatePath(
                performanceTarget.TrackedSObjectApiName__c,
                performanceTarget.TrackedSObjectContactLookupFieldName__c
        )) {
            Apexpages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.FATAL,
                    System.Label.INDICATOR_CONFIGURATION_CHANGE
                )
            );
            return null;
        }
        return this.saveTarget(PerformanceTargetDO.TYPE_INDICATOR);
    }
}
