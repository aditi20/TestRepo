/*
 * This class is used to run database operations without consider
 * the sharing permissions.
 *   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public without sharing class DBFullAccess {

    /**
     * Delete the specified object
     *
     * @param objectToDelete - an object to delete from the database
     */
    public static void deleteSObject(SObject objectToDelete){
        delete objectToDelete;
    }

    /**
     * Delete a list of objects
     *
     * @param objectsToDelete - a list with the objects to delete
     */
    public static void deleteSObject(List<SObject> objectsToDelete){
        delete objectsToDelete;
    }

    /**
     * Insert the specified object
     *
     * @param objectToInsert - an object to insert
     */
    public static void insertSObject(SObject objectToInsert){
        insert objectToInsert;
    }

    /**
     * Insert a list of objects
     *
     * @param objectsToInsert - a list with the objects to insert
     */
    public static void insertSObject(List<SObject> objectsToInsert){
        insert objectsToInsert;
    }

    /**
     * Update the specified object
     *
     * @param objectToUpdate - an object to update
     */
    public static void updateSObject(SObject objectToUpdate){
        update objectToUpdate;
    }

    /**
     * Update a list of objects
     *
     * @param objectsToUpdate - a list of objects to update
     */
    public static void updateSObject(List<SObject> objectsToUpdate){
        update objectsToUpdate;
    }

    /**
     * Update or insert the specified object
     *
     * @param objectToUpsert - an object to update or insert
     */
    public static void upsertSObject(SObject objectToUpsert){
        upsert objectToUpsert;
    }

    /**
     * Update or insert a list of objects
     *
     * @param objectsToUpsert - a list of objects to update or insert
     */
    public static void upsertSObject(List<SObject> objectsToUpsert){
        upsert objectsToUpsert;
    }

    /**
     * Run a query to the database
     *
     * @param queryString - a string with query to run
     * @return a list of SObjects with the records fetched from the database
     */
    public static List<SObject> querySObject(String queryString){
        return DataBase.query(queryString);
    }

    /**
     * Run a query to the database
     *
     * @param queryString  - a string with query to run
     * @param listToFilter - a list of objects to filter the results of the query. This list
     *                       will be used with the IN operator of the WHERE clause. To use
     *                       it, the query string must contain "IN :listToFilter" in the
     *                       WHERE clause.
     * @return a list of SObjects with the records fetched from the database
     */
    public static List<SObject> querySObject(String queryString, List<SObject> listToFilter){
        return DataBase.query(queryString);
    }

    /**
     * Run a query to the database
     *
     * @param queryString  - a string with query to run
     * @param listToFilter - a list of objects to filter the results of the query. This list
     *                       will be used with the IN operator of the WHERE clause. To use
     *                       it, the query string must contain "IN :listToFilter" in the
     *                       WHERE clause.
     * @return a list of SObjects with the records fetched from the database
     */
    public static List<SObject> querySObject(String queryString, List<Id> listToFilter){
        return DataBase.query(queryString);
    }

    /**
     * Run a query to the database
     *
     * @param queryString  - a string with query to run
     * @param listToFilter - a set of objects to filter the results of the query. This set
     *                       will be used with the IN operator of the WHERE clause. To use
     *                       it, the query string must contain "IN :listToFilter" in the
     *                       WHERE clause.
     * @return a list of SObjects with the records fetched from the database
     */
    public static List<SObject> querySObject(String queryString, Set<Id> listToFilter){
        return DataBase.query(queryString);
    }


    // TODO - Move the methods below to infrastructure classes when the architecture model is
    // confirmed
    /**
     * Convert a date to a datetime at the start of the day
     *
     * @param dateToConvert - The date being converted to the datetime
     *
     * @return - The date time initiated to the start of the day
     */
    public static Datetime convertToStartDateTime(Date dateToConvert) {

        return datetime.newInstanceGmt(dateToConvert, Time.newInstance(0, 0, 0, 0));
    }

    /**
     * Convert a date to a datetime at the end of the day
     *
     * @param dateToConvert - The date being converted to the datetime
     *
     * @return - The date time initiated to the end of the day
     */
    public static Datetime convertToEndDateTime(Date dateToConvert) {

        return datetime.newInstanceGmt(dateToConvert, Time.newInstance(23, 59, 59, 0));
    }

    /**
     * Converts a datetime into a string that can be passed in to a dynamic query
     *
     * @param dateTimeToConvert - The date time to convert
     *
     * @return - A string that can be passed in to a query in the GMT timezone
     */
    public static String convertDateTimeToGmtSoqlString(Datetime dateTimeToConvert, Boolean isDate) {

        String output;
        if (isDate) {
            output = dateTimeToConvert.formatGMT('yyyy-MM-dd');
        } else {
            output = dateTimeToConvert.formatGMT('yyyy-MM-dd HH:mm:ss');
            output = output.replace(' ', 'T');
            output = output + 'Z';
        }
        return output;
    }
}