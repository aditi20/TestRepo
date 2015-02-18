/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class DeviceMassStatusUpdateController {
    ApexPages.StandardsetController setDev;

    public DeviceMassStatusUpdateController(ApexPages.StandardsetController controller) {
        setDev = controller;
        ApexPages.currentpage().getheaders().put(C.XFRAME_OPTIONS_HEADER,C.XFRAME_OPTIONS_DENY);
    }

    /**
     * Changes the status of selected Devices to Active.
     */
    public PageReference activateDevices(){
        return changeStatus('Active');
    }

    /**
     * Changes the status of selected Devices to Inactive.
     */
    public PageReference deactivateDevices(){
        return changeStatus('Inactive');
    }

    /**
     * This method changes the status of the selected Devices to given parameter.
     */
    public PageReference changeStatus(String status) {
        GenericObjectCreator deviceCreator =
            new GenericObjectCreator(Device__c.SObjectType);
        deviceCreator.checkObjectAccessible();

        if (setDev.getSelected() != null && !setDev.getSelected().isEmpty()) {
            for (Integer i = 0; i < setDev.getSelected().size(); i++) {
                setDev.getSelected().get(i).put('Status__c', status);
            }

            deviceCreator.checkObjectUpdateable();
            update setDev.getSelected();
        }
        return redirectToList();
    }

    /**
     * Deletes the selected Devices.
     */
    public PageReference deleteDevices() {
        GenericObjectCreator deviceCreator =
            new GenericObjectCreator(Device__c.SObjectType);
        deviceCreator.checkObjectAccessible();

        PageReference DeviceListPage =
            new PageReference(ApexPages.currentPage().getHeaders().get('Referer'));
        DeviceListPage.setRedirect(true);

        if (setDev.getSelected() != null && !setDev.getSelected().isEmpty()) {
            deviceCreator.checkObjectDeletable();
            delete setDev.getSelected();
        }
        return redirectToList();
    }

    /**
     * Returns the list pagerefence
     */
    private  PageReference redirectToList() {
        String ObjectPrefix = Device__c.sObjectType.getDescribe().getKeyPrefix();
        PageReference p = new PageReference('/'+ObjectPrefix);
        p.setRedirect(true);
        return p;
    }
}