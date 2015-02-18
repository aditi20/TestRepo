/*
* (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*/
public with sharing class SurveyBuilderTemplateController{

    /**
     * Defines variables so they can be referenced in the visualforce page.
     * the variables are later replaced with the apex variables set in the "init" apex injection
     */
    public Survey__c survey {get;set;}
    public String selectedTab {get;set;}
    public Boolean isNew {get;set;}
    public Boolean hasError {get;set;}
    public Boolean isPublished {get;set;}
    public Boolean sameOrg {get;set;}
    public Boolean readOnly{get;set;}
    public Boolean isPreview{get;set;}

    public SurveyBuilderTemplateController() {

    }
}