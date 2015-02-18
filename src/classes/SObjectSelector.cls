/**
 * Abstract class that defines the interface required to implement a selector. This is the base
 * class for the Selector layer in the Separation of Concerns architecture used in this application
 * The purpose of a selector class is to provide access to records via a standard interface.
 * It deals with:
 *   - Managing accessability of the object
 *   - Selecting records from the DB
 *   - Managing fields that should be returned in the query
 *   - Manage way fields are made available to the Domain and Service layer
 *
 * Usage:
 *   - Each standard and custom sObject should implement this class
 *   - Only queries that require fields from one object alone should return the actual sObjects
 *       If child objects are required as well a wrapper class should be implemented with the parent
 *        sObject as a variable and the child object fields in individual fields
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies - odavies@grameenfoundation.org
 *
 * Based on Separation of Concerns concept by Andrew Fawcett
 * Copyright (c), FinancialForce.com, inc
 * All rights reserved.
 */
public abstract with sharing class SObjectSelector {

    public static final String LIST_TO_FILTER = 'listToFilter';
    public static final String AND_OPERATOR = ' AND ';
    public static final String OR_OPERATOR = ' OR ';
    public static final String NOT_OPERATOR = ' NOT IN ';
    public static final String IN_OPERATOR = ' IN ';
    public static final String EQUALS_OPERATOR = ' = ';
    public static final String NOT_EQUALS_OPERATOR = ' != ';
    public static final String LIKE_OPERATOR = ' LIKE ';
    public static final String ASCENDING_OPERATOR = ' ASC ';
    public static final String DESCENDING_OPERATOR = ' DESC';
    public static final String NULL_VALUE  = ' null ';

    private String objectName;
    private Boolean isAccessible;
    private Boolean isQueryable;

    public SoqlQueryBuilder mainQueryBuilder { get; private set; }
    private List<SoqlQueryBuilder> innerSelectQueries;

    /**
     * Implement this method to get the object type for the selector
     */
    abstract Schema.SObjectType getSObjectType();

    /**
     * Implement this method to get the field list that will be used by a query for this object
     */
    abstract List<Schema.SObjectField> getDefaultSelectFields();

    /**
     * Implement this method to add the lookup to Contact to implement JobFiltering
     * Should be deprecated when we switch to using Queues for group management
     */
    abstract String pathToJobFiltering();

    /**
     * Constructror. Will set the default field list to the select clause
     */
    public SObjectSelector() {
        Schema.DescribeSObjectResult describeResult = getSObjectType().getDescribe();
        this.objectName = describeResult.getName();
        this.isAccessible = describeResult.isAccessible();
        this.isQueryable = describeResult.isQueryable();
        this.mainQueryBuilder = new SoqlQueryBuilder(
            this.objectName,
            getDefaultSelectFields(),
            getDefaultOrderByClause()
        );
        this.innerSelectQueries = new List<SoqlQueryBuilder>();
    }

    /**
     * Get the name of the SObject
     */
    public String getObjectName() {
        return this.objectName;
    }

    /**
     * Get a singleton record by it's id
     */
    public sObject getRecordById(Id idToFind) {
        this.setMainLimitAmount(1);
        List<sObject> records = getRecordsById(new Set<Id>{idToFind});
        return (records.isEmpty()) ? null : records[0];
    }

    /**
     * Get records by id. This will use the select and order by clause that are already
     * passed into the class. It will add the id filter
     */
    public List<sObject> getRecordsById(Set<Id> listToFilter) {
        assertIsQueryable();
        this.addToMainWhereClause('Id = :' + LIST_TO_FILTER);
        return runSoqlQuery(AND_OPERATOR, listToFilter);
    }

    /**
     * Get records by only id. Will clear out any previously added where clauses
     */
    public List<sObject> getRecordsByOnlyId(Set<Id> listToFilter) {
        this.mainQueryBuilder.resetWhereClause();
        return getRecordsById(listToFilter);
    }

    /**
     * Get a singleton record by it's id
     */
    public sObject getRecordByIdWithAllFields(Id idToFind) {
        this.setMainLimitAmount(1);
        List<sObject> records = getRecordsByIdWithAllFields(new Set<Id>{idToFind});
        return (records.isEmpty()) ? null : records[0];
    }

    /**
     * Get records by id with all fields
     */
    public List<sObject> getRecordsByIdWithAllFields(Set<Id> listToFilter) {
        this.mainQueryBuilder.setSelectClauseWithAllFields();
        return getRecordsById(listToFilter);
    }

    /**
     * Get records by only id. Clears all previously added where clauses
     */
    public List<sObject> getRecordsByOnlyIdWithAllFields(Set<Id> listToFilter) {
        this.mainQueryBuilder.resetWhereClause();
        return getRecordsByIdWithAllFields(listToFilter);
    }

    /**
     * Run a SOQL query
     */
    public List<sObject> runSoqlQuery(String operator, Set<Id> listToFilter) {
        assertIsAccessible();
        return Database.query(generateSoqlQuery(operator));
    }

    /**
     * Run a SOQL query with DBFullAccess
     */
    public List<sObject> runSoqlQueryDbFullAccess(String operator, Set<Id> listToFilter) {
        assertIsAccessible();
        return DBFullAccess.querySObject(generateSoqlQuery(operator), listToFilter);
    }

    /**
     * Build the SOQL string for the object
     */
    private String generateSoqlQuery(String operator) {
        String baseQuery =
            this.mainQueryBuilder.generateSoqlQuery(operator, this.innerSelectQueries.size());
        List<String> innerQueries = new List<String>();
        for (SObjectSelector.SoqlQueryBuilder innerQuery : this.innerSelectQueries) {
            innerQueries.add(innerQuery.generateInnerSoqlQuery(operator));
        }
        return (this.innerSelectQueries.isEmpty()) ?
            baseQuery:
            String.format(baseQuery.replace('\'','\'\''), innerQueries);
    }

    /**
     * Add an inner select query
     */
    public void addInnerSelectQuery(SObjectSelector.SoqlQueryBuilder innerSelectQuery) {
        this.innerSelectQueries.add(innerSelectQuery);
    }

    /**
     * Check that the current User has access to a given object to perform queries
     */
    private void assertIsAccessible() {

        if (!isAccessible()) {
            throw new SObjectSelector.SelectorException(
                System.Label.ACCESS_DENIED,
                new List<String>{this.objectName}
            );
       }
    }

    /**
     * Check that the current User has access to a given object to perform queries
     */
    private void assertIsQueryable() {

        if (!isQueryable()) {
            throw new SObjectSelector.SelectorException(
                System.Label.QUERY_DENIED,
                new List<String>{this.objectName}
            );
       }
    }

    /**
     * Check that the current User has access to a given object to perform queries
     */
    private Boolean isAccessible() {
        return this.isAccessible;
    }

    /**
     * Check that the current User has access to a given object to perform queries
     */
    private Boolean isQueryable() {
        return this.isQueryable;
    }

    /**
     * Clear all query clauses
     */
    public void resetQueryClauses() {
        this.mainQueryBuilder.resetQuery(getDefaultSelectFields(), getDefaultOrderByClause());
        this.innerSelectQueries = new List<SoqlQueryBuilder>();
    }

    /**
     * Add to main where clause
     */
    public void addToMainWhereClause(String clause) {
        this.mainQueryBuilder.addToWhereClause(clause);
    }

    /**
     * Add to main order by clause
     */
    public void addToMainOrderByClause(String clause) {
        this.mainQueryBuilder.setOrderByClause(clause);
    }

    /**
     * Add to main group by clause
     */
    public void addToMainGroupByClause(String clause) {
        this.mainQueryBuilder.setGroupByClause(clause);
    }

    /**
     * Set an amount to be used in the limit clause
     */
    public void setMainLimitAmount(Integer limitAmount) {
        this.mainQueryBuilder.setLimitAmount(limitAmount);
    }

    /**
     * Set an amount to be used in the offset clause
     */
    public void setOffsetAmount(Integer offsetAmount) {
        this.mainQueryBuilder.setOffsetAmount(offsetAmount);
    }

    /**
     * Return the main query builder
     */
    public SoqlQueryBuilder getMainQueryBuilder() {
        return this.mainQueryBuilder;
    }

    /**
     * Get the default order by clause
     */
    public virtual String getDefaultOrderByClause() {
        return 'Name';
    }

    /**
     * Class to construct InnerWhereClause
     */
    public with sharing class InnerWhereClause {

        private String leftHandSideFieldApiName;
        private SObjectSelector.SoqlQueryBuilder whereClauseQuery;
        private String operator;
        private String rightHandSideFieldApiName;
        private String objectName;

        public InnerWhereClause(
                String leftHandSideFieldApiName,
                String operator,
                Schema.SObjectField rightHandSideField,
                String objectName
        ) {
            this.leftHandSideFieldApiName = leftHandSideFieldApiName;
            this.operator = operator;
            whereClauseQuery = new SoqlQueryBuilder(
                objectName,
                new List<Schema.SObjectField>{rightHandSideField},
                ''
            );
        }

        /**
         * Access the SoqlQueryBuilder for the inner where clause
         */
        public SObjectSelector.SoqlQueryBuilder getWhereClauseQuery() {
            return this.whereClauseQuery;
        }

        /**
         * Generate the inner where clause query string
         */
        public String generateInnerWhereClause(String operator) {
            return ' ' + this.leftHandSideFieldApiName + ' ' +
                this.operator + ' (' +
                this.whereClauseQuery.generateSoqlQuery(operator, 0) + ') ';
        }
    }

    /**
     * Inner class for building the SOQL query
     * This can be used to build inner queries as well
     */
    public class SoqlQueryBuilder {

        private String objectName;
        private StringBuilder.FieldListBuilder selectClause;
        private StringBuilder.OrderListBuilder orderClause;
        private String fromObject;
        private StringBuilder whereClauses;
        private InnerWhereClause innerWhereClause;
        private String orderByClause;
        private String orderByDirection;
        private String groupByClause;
        private Integer limitAmount;
        private Integer offsetAmount;

        public SoqlQueryBuilder(
                String fromObject,
                List<Schema.SObjectField> selectFields,
                String orderByClause
        ) {
            this(fromObject, fromObject, selectFields, orderByClause);
        }

        public SoqlQueryBuilder(
                String fromObject,
                String objectName,
                List<Schema.SObjectField> selectFields,
                String orderByClause
        ) {
            this.objectName = objectName;
            this.fromObject = fromObject;
            this.selectClause = new StringBuilder.FieldListBuilder(selectFields);
            this.whereClauses = new StringBuilder();
            this.orderByClause = orderByClause;
            this.orderClause = new StringBuilder.OrderListBuilder();
            this.orderByDirection = '';
            this.limitAmount = 0;
        }

        /**
         * Construct SOQL Query if this was an inner query
         */
        public String generateInnerSoqlQuery(String operator) {
            return '(' + this.generateSoqlQuery(operator, 0) + ')';
        }

        /**
         * Construct SOQL Query
         */
        public String generateSoqlQuery(String operator, Integer numberOfSubSelectClauses) {

            if (DescribeHandler.getGlobalDescribe().containsKey(this.objectName)) {
                GenericObjectCreator genericObjectCreator =
                    new GenericObjectCreator(DescribeHandler.getGlobalDescribe().get(this.objectName));
                genericObjectCreator.checkObjectAccessible();
                genericObjectCreator.checkFieldsAccessible(this.selectClause.getFieldList());
            } else {
                throw new SObjectSelector.SelectorException(
                    System.Label.OBJECT_DOES_NOT_EXIST,
                    new List<String>{this.objectName}
                );
            }
    
            String baseQuery = this.getSelectClause();
            if (numberOfSubSelectClauses > 0) {
                baseQuery += ', ' +
                    new StringBuilder.FormatListBuilder(numberOfSubSelectClauses).generateString();
            }
            baseQuery += this.getFromClause();
            if (this.innerWhereClause != null) {
                this.addToWhereClause(
                    this.innerWhereClause.generateInnerWhereClause(operator)
                );
            }
            baseQuery += this.generateWhereClause(operator);
            baseQuery += this.generateOrderByClause();
            baseQuery += this.generateLimitClause();
            baseQuery += this.generateOffsetClause();
            baseQuery += this.generateGroupByClause();
            return baseQuery;
        }

        /**
         * Reset entire query
         */
        public void resetQuery(
                List<Schema.SObjectField> selectFields,
                String orderByClause
        ) {
            this.whereClauses = new StringBuilder();
            this.selectClause = new StringBuilder.FieldListBuilder(selectFields);
            this.orderByClause = orderByClause;
            this.limitAmount = 0;
            this.orderByDirection = '';
        }

        /**
         * Set a field list to be used in future queries on this object
         */
        public void setSelectClause(List<Schema.SObjectField> selectFields) {
            this.selectClause = new StringBuilder.FieldListBuilder(selectFields);
        }

        /**
         * Set a field list to be used apart from default fields
         */
        public void setSelectClause(List<String> selectFields) {
            this.selectClause = new StringBuilder.FieldListBuilder();
            this.selectClause.addAll(selectFields);
        }

        /**
         * Set the select field list to get all the fields for the object
         */
        public void setSelectClauseWithAllFields() {
            this.selectClause = new StringBuilder.FieldListBuilder(getAllFields());
        }

        private String joinSelectClause() {
            this.selectClause.processFieldList();
            return this.selectClause.generateString();
        }

        /**
         * Generate a field list that includes all the available fields for this object
         */
        private List<Schema.SObjectField> getAllFields() {
            List<Schema.SObjectField> allowedFields = new List<Schema.SObjectField>();
            GenericObjectCreator genericObjectCreator =
                new GenericObjectCreator(DescribeHandler.getGlobalDescribe().get(this.objectName));
            for (
                    Schema.SObjectField field :
                        DescribeHandler.getFieldMap(this.objectName).values()
            ) {
                try {
                    genericObjectCreator.checkFieldsAccessible(
                        new List<Schema.SObjectField>{field}
                    );
                    allowedFields.add(field);
                } catch (GenericObjectCreator.GenericObjectCreatorException goce) {
                    // Do nothing as we just don't add the field to the list of available fields
                }
            }
            return allowedFields;
        }

        /**
         * Create a relationship look up
         */
        public String generateLookUp(List<Schema.SObjectField> path) {
            List<String> pathStringList = new List<String>();
            Integer amountLeft = path.size();
            for (Schema.SObjectField field : path) {
                String fieldName = field.getDescribe().getName();
                if (amountLeft > 1) {
                    pathStringList.add(convertField(fieldName));
                } else {
                    pathStringList.add(fieldName);
                }
                amountLeft--;
            }
            return String.join(pathStringList, '.');
        }

        /**
         * Convert a field name so it can be used in a relationship path
         */
        private String convertField(String fieldToConvert) {
            if (fieldToConvert.endsWithIgnoreCase('__c')) {
                fieldToConvert = fieldToConvert.subString(0, fieldToConvert.length() - 1) + 'r';
            } else {
                fieldToConvert = fieldToConvert.subString(0, fieldToConvert.length() - 2);
            }
            return fieldToConvert;
        }

        /**
         * Create a relationship and add it to the select clause
         */
        public void addRelationshipToSelect(List<Schema.SObjectField> path) {
            this.selectClause.add(generateLookUp(path));
        }

        /**
         * Create a relationship and add it to the select clause
         */
        public void addRelationshipToSelect(List<List<Schema.SObjectField>> paths) {
            for (List<Schema.SObjectField> path : paths) {
                this.addRelationshipToSelect(path);
            }
        }

        /**
         * Add to the Where clause. This can be used to pass in either
         * individual clauses that can be built up by joining the clauses using the same
         * operator or it can just be an entire clause to allow for more complex 
         */
        public void addToWhereClause(String clauseToAdd) {
            this.whereClauses.add(clauseToAdd);
        }

        /**
         * Initiate the inner where clause
         * TODO - Convert to use DescribeHandler
         */
        public InnerWhereClause initInnerWhereClause(
                Schema.SObjectField leftHandSideFieldApiName,
                String operator,
                Schema.SObjectField rightHandSideFieldApiName,
                Schema.SObjectType innerObject
        ) {
            this.innerWhereClause = new InnerWhereClause(
                leftHandSideFieldApiName.getDescribe().getName(),
                operator,
                rightHandSideFieldApiName,
                innerObject.getDescribe().getName()
            );
            return this.innerWhereClause;
        }

        /**
         * Get the inner where clause
         */
        public InnerWhereClause getInnerWhereClause() {
            return this.innerWhereClause;
        }

        /**
         * Generate like clause and wrap in %
         */
        public String generateWrappedLikeClause(Schema.SObjectField field, String value) {
            return generateStandardWhereClause(
                field,
                SObjectSelector.LIKE_OPERATOR,
                '%' + String.escapeSingleQuotes(value) + '%'
            );
        }

        /**
         * Generate like clause and wrap in %%
         */
        public String generateWrappedLikeClause(String field, String value) {
            return generateStandardWhereClause(
                field,
                SObjectSelector.LIKE_OPERATOR,
                '%' + String.escapeSingleQuotes(value) + '%'
            );
        }

        /**
         * Create a standard where clause
         */
        public String generateStandardWhereClause(
                List<Schema.SObjectField> fields,
                String operator,
                String value
        ) {
            return generateStandardWhereClause(
                generateLookUp(fields),
                operator,
                value
            );
        }

        /**
         * Create a standard where clause
         */
        public String generateStandardWhereClause(
                Schema.SObjectField field,
                String operator,
                String value
        ) {
            return generateStandardWhereClause(
                field.getDescribe().getName(),
                operator,
                value
            );
        }

        /**
         * Create a standard where clause
         */
        public String generateStandardWhereClause(
                String field,
                String operator,
                String value
        ) {
            if (value.equals(NULL_VALUE)) {
                return field + ' ' + operator +
                    ' ' + value + '';
            } else {
                return field + ' ' + operator +
                    ' \'' + String.escapeSingleQuotes(value) + '\' ';
            }
        }

        /**
         * Create a standard where clause
         */
        public String generateStandardWhereClause(
                Schema.SObjectField field,
                String operator,
                Date value
        ) {
            return generateStandardWhereClause(
                field.getDescribe().getName(),
                operator,
                value
            );
        }

        /**
         * Create a standard where clause
         */
        public String generateStandardWhereClause(
                String field,
                String operator,
                Date value
        ) {
            return field + ' ' + operator + ' ' + String.valueOf(value);
        }

        /**
         * Create standard where clause with Boolean value
         */
        public String generateStandardWhereClause(
                List<Schema.SObjectField> fields,
                String operator,
                Boolean value
        ) {
            return generateStandardWhereClause(
                generateLookUp(fields),
                operator,
                value
            );
        }

        /**
         * Create standard where clause with Boolean value
         */
        public String generateStandardWhereClause(
                Schema.SObjectField field,
                String operator,
                Boolean value
        ) {
            return generateStandardWhereClause(
                field.getDescribe().getName(),
                operator,
                value
            );
        }

        /**
         * Create a standard where clause with Boolean value
         */
        public String generateStandardWhereClause(
                String field,
                String operator,
                Boolean value
        ) {
            return field + ' ' + operator + ' ' + value;
        }

        /**
         * Create a standard where clause with Boolean value
         */
        public String generateStandardWhereClause(
                String field,
                String operator,
                Double value
        ) {
            return field + ' ' + operator + ' ' + value;
        }

        /**
         * Create standard IN clause
         */
        public String generateStandardInWhereClause(
                List<Schema.SObjectField> fields,
                String operator,
                Set<Id> values
        ) {
            return generateStandardInWhereClause(
                generateLookUp(fields),
                operator,
                new Set<String> (
                    String.join(new List<Id> (values), ',').split(',')
                )
            );
        }

        /**
         * Create standard (NOT) IN clause
         */
        public String generateStandardInWhereClause(
                Schema.SObjectField field,
                String operator,
                Set<Id> values
        ) {
            return generateStandardInWhereClause(
                field,
                operator,
                new Set<String> (
                    String.join(new List<Id> (values), ',').split(',')
                )
            );
        }

        /**
         * Create standard (NOT) IN clause
         */
        public String generateStandardInWhereClause(
                Schema.SObjectField field,
                String operator,
                Set<String> values
        ) {
            List<String> valueList = new List<String>();
            valueList.addAll(values);
            return generateStandardInWhereClause(
                field,
                operator,
                valueList
            );
        }

        /**
         * Create standard (NOT) IN clause
         */
        public String generateStandardInWhereClause(
                Schema.SObjectField field,
                String operator,
                List<String> values
        ) {
            return generateStandardInWhereClause(
                field.getDescribe().getName(),
                operator,
                values
            );
        }

        /**
         * Create standard IN clause
         */
        public String generateStandardInWhereClause(
                String field,
                String operator,
                Set<Id> values
        ) {
            return generateStandardInWhereClause(
                field,
                operator,
                new Set<String> (
                    String.join(new List<Id> (values), ',').split(',')
                )
            );
        }

        /**
         * Create standard IN clause
         */
        public String generateStandardInWhereClause(
                String field,
                String operator,
                Set<String> values
        ) {
            List<String> valueList = new List<String>();
            valueList.addAll(values);
            return generateStandardInWhereClause(
                field,
                operator,
                valueList
            );
        }

        /**
         * Create standard IN clause
         */
        public String generateStandardInWhereClause(
                String field,
                String operator,
                List<String> values
        ) {
            StringBuilder.InClauseBuilder inclauseBuilder =
                new StringBuilder.InClauseBuilder(values);
            inclauseBuilder.setShouldEscapeSingleQuotes(true);
            return
                field + ' ' +
                operator + ' (' + inclauseBuilder.generateString() + ')';
        }

        /**
         * Reset the where clause to being empty
         */
        public void resetWhereClause() {
            this.whereClauses = new StringBuilder();
        }

        /**
         * Get a list of fields and generate order by clause
         */
        public String generateOrderByClause(List<OrderByBuilder> orderByClauses) {
            this.orderClause.setOrderByClauseList(orderByClauses);
            this.orderClause.processOrderByClauseList();
            return orderClause.generateString();
        }

        /**
         * Set a string to be used in the order by clause
         */
        public void setOrderByClause(String orderByClause) {
            this.orderByClause = orderByClause;
        }

        /**
         * Set the order by directions
         */
        public void setOrderByDirection(String direction) {
            this.orderByDirection = direction;
        }

        /**
         * Set a string to be used in the group by clause
         */
        public void setGroupByClause(String groupByClause) {
            this.groupByClause = groupByClause;
        }

        /**
         * Set the amount to limit a query by
         */
        public void setLimitAmount(Integer amount) {
            this.limitAmount = amount;
        }

        /**
         * Set an amount to be used in the offset clause
         */
        public void setOffsetAmount(Integer offsetAmount) {
            this.offsetAmount = offsetAmount;
        }

        /**
         * Build the Select and From clause for the default SOQL query
         */
        private String getSelectClause() {
            return String.format(
                'SELECT ' +
                    '{0} ',
                new List<String>{this.joinSelectClause()}
            );
        }

        /**
         * Get the From clause for the query
         */
        private String getFromClause() {
            return String.format(
                ' FROM ' +
                    ' {0}',
                new List<String>{this.fromObject}
            );
        }

        /**
         * Generate the where clause to 
         */
        private String generateWhereClause(String operator) {

            String whereClause = '';
            if (this.whereClauses.hasValues()) {
                whereClause = ' WHERE ' + this.whereClauses.generateString(operator);
            }
            return whereClause;
        }

        /**
         * Generate concatenated where clause values
         */
        public String generateConcatenatedWhereClause(String operator) {
            String whereClause = '';
            if (this.whereClauses.hasValues()) {
                whereClause = this.whereClauses.generateString(operator);
            }
            return whereClause;
        }

        /**
         * Generate the order by clause
         */
        private String generateOrderByClause() {
            String returnValue = '';
            if (String.isNotEmpty(this.orderByClause)) {
                returnValue = String.format(
                    ' ORDER BY {0} {1}',
                    new List<String>{this.orderByClause, this.orderByDirection}
                );
            }
            return returnValue;
        }

        /**
         * Generate the limit clause
         */
        private String generateLimitClause() {
       	    String limitClause = '';
            if (this.limitAmount > 0) {
                limitClause = String.format(
                    ' LIMIT {0} ',
                    new List<String>{String.valueOf(this.limitAmount)}
                );
            }
            return limitClause;
        }

        /**
         * Generate the offset clause
         */
        private String generateOffsetClause() {
            String offsetClause = '';
            if (this.offsetAmount >= 0) {
                offsetClause = String.format(
                    ' OFFSET {0}',
                    new List<String> {String.valueOf(this.offsetAmount)}
                );
            }
            return offsetClause;
        }

        /**
         * Generate the group by clause
         */
        private String generateGroupByClause() {
            String groupByClauseFragment = '';
            if (!String.isEmpty(this.groupByClause)) {
                groupByClauseFragment = String.format(
                    ' GROUP BY {0}',
                    new List<String>{this.groupByClause}
                );
            }
            return groupByClauseFragment;
        }
    }

    /**
     * Structure to form order clause
     */
    public class OrderByBuilder {
        private String field;
        private String direction;

        public OrderByBuilder(Schema.SObjectField field, String direction) {
            this(field.getDescribe().getName(), direction);
        }

        public OrderByBuilder(String field, String direction) {
            this.field = field;
            this.direction = direction;
        }

        public String getField() {
            return this.field;
        }

        public String getDirection() {
            return this.direction;
        }

        public String getOrderByClause() {
            return this.getField() + ' ' + this.getDirection();
        }
    }

    public class SelectorException extends BaseException {
        public SelectorException(String message, String[] args) {
            super(message, args);
        }
    }
}