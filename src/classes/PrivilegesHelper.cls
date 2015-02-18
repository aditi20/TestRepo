/**
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 *  @author Claudio Soto csoto@altimetrik.com
 */
public with sharing class PrivilegesHelper {
    static public final Integer CREATE_PERMISSION = 0;
    static public final Integer UPDATE_PERMISSION = 1;
    static public final Integer DELETE_PERMISSION = 2;

    /**
     *  How to use PrivilegesHelper
     *  If we need to know the DescribeSObjectResult of two Objects
     *  (i.e. Question__c, and SurveyMapping__c) we must:
     *  1- Obtain the names of the object (not hardcoded because of issues in manage packages).
     *     String surveyMappingName   = Schema.sObjectType.SurveyMapping__c.getName();
     *     String questionName        = Schema.sObjectType.Question__c.getName();
     *  2- Create a set of Strings with the given names.
     *     Set<String> objectList     = new Set<String>{surveyMappingName, questionName};
     *  3- Obtain the map calling obtainObjectPermissions method.
     *     Map<String, DescribeSObjectResult> mapPermissions = PrivilegesHelper.obtainObjectPermissions(objectList);
     *  4- Finally we can know the permissions of the object this way...
     *     mapPermissions.get(surveyMappingName).isUpdateable() => Here we know if current user can update
     *                                                                     Survey mappings.
     *     mapPermissions.get(questionName).isUpdateable() => Here we know if current user can create
     *                                                        Questions.
     *
     *  Also you can check individual permissions using the constants defined previously
     *  Example this would verify delete permission for Survey__c object:
     *  PrivilegesHelper.checkPermission(Schema.sObjectType.Survey__c.getName(),PrivilegesHelper.DELETE_PERMISSION)
     *
     **/

    /**
     *  Method in charge to obtain a Map<String, DescribeSObjectResult> of the objects contained in the given set.
     *  @param Set of object names that the user wants to know its privileges.
     *  For example if we pass Set{'SurveyMapping__c', 'Survey__c'} we will obtain permissions only for
     *  those objects.
     *  @return Map<String, DescribeSObjectResult> with the format: <Object name, DescribeSObjectResult of the object>
     */
    public static Map<String, DescribeSObjectResult> obtainObjectPermissions(Set<String> objectNameSetGiven){
        Map<String, DescribeSObjectResult> mapPermissions = new Map<String, DescribeSObjectResult>();
        for (String objectName : objectNameSetGiven) {
            mapPermissions.put(objectName, DescribeHandler.getObjectDescribeResult(objectName, false));
        }

        return mapPermissions;
    }

    /**
     *  Method in charge to obtain a given permission for a given object
     *
     *  @param objectName - Name of the object
     *  @param permission - Type of permission to obtain
     *
     *  @return - Oject level permission according to the parameter passed in "permission"
     */
    public static boolean checkPermission(String objectName, Integer permission) {


        Schema.DescribeSObjectResult describe = DescribeHandler.getObjectDescribeResult(objectName, false);
        if (permission == CREATE_PERMISSION) {
            return describe.isCreateable();
        } else if (permission == UPDATE_PERMISSION) {
            return describe.isUpdateable();
        } else if (permission == DELETE_PERMISSION) {
            return describe.isDeletable();
        } else {
            return false;
        }
    }
}