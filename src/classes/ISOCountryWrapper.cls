/**
 * Wrapper class for ISO_Country custom setting
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class ISOCountryWrapper {

    /**
     * Get the instance of ISO_Country record for the specified Name
     */
    public static ISO_Country__c getInstanceWithName(String name) {
        return ISO_Country__c.getInstance(name);
    }
}