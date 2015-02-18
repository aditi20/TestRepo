/**
 * Wrapper class for Language custom setting
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class LanguageWrapper {

    /**
     * Get the instance of Language record for the specified Name
     */
    public static Language__c getInstanceWithName(String name) {
        return Language__c.getInstance(name);
    }
}