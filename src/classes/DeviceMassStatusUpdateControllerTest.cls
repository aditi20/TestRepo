/*
*   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
*/
@isTest
private class DeviceMassStatusUpdateControllerTest {

     /**
     * Test for changeStatus() method.
     */
     public static testMethod void testChangeStatus() {

        Device__c dev = getNewDevice('Active');
        List<SObject> list_dev = new List<Device__c>();
        list_dev.add(dev);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(list_dev);
        
        Test.startTest();
            sc.setSelected(list_dev);
            DeviceMassStatusUpdateController mud = new DeviceMassStatusUpdateController(sc);
            PageReference pg = mud.ChangeStatus('StatusTest');
        Test.stopTest();
        
        List<Device__c> list_after = [select Id, Status__c from Device__c where Id = :dev.Id ];

        system.assertEquals('StatusTest', list_after[0].Status__c );

    }

    /**
     * Test for deactivateDevices() method.
     */
    public static testMethod void testDeactivateDevices() {

        Device__c dev = getNewDevice('Active');

        List<SObject> list_dev = new List<Device__c>();
        list_dev.add(dev);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(list_dev);
        
        Test.startTest();
            sc.setSelected(list_dev);
            DeviceMassStatusUpdateController muc = new DeviceMassStatusUpdateController(sc);
            PageReference pg = muc.deactivateDevices();
        Test.stopTest();
        
        List<Device__c> list_after = [select Id,Status__c from Device__c where Id = :dev.Id ];

        system.assertEquals('Inactive', list_after[0].Status__c );

    }

    /**
     * Test for activateContacts() method.
     */
    public static testMethod void testActivateDevices() {

        Device__c dev = getNewDevice('Inactive');

        List<SObject> list_dev = new List<Device__c>();
        list_dev.add(dev);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(list_dev);
        
        Test.startTest();
            sc.setSelected(list_dev);
            String previousPage = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/003';
            ApexPages.currentPage().getHeaders().put('Referer', previousPage);

            DeviceMassStatusUpdateController muc = new DeviceMassStatusUpdateController(sc);
            PageReference pg = muc.activateDevices();
        Test.stopTest();
        
        List<Device__c> list_after = [select Id,Status__c from Device__c where Id = :dev.Id ];

        system.assertEquals('Active', list_after[0].Status__c );

    }

    //------------- Util methods---------

    public static Device__c getNewDevice(String status){
        Device__c dev = new Device__c(Status__c = status,imei__c = 'some imei',Name='some imei');
        insert dev;
        return dev;
    }

 }