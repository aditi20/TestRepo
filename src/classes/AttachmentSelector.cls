/**
 * Selector class for the Attachment object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class AttachmentSelector extends SObjectSelector {
    public Schema.SObjectType getSObjectType() {
        return Attachment.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            Attachment.Id,
            Attachment.Name,
            Attachment.Body,
            Attachment.ParentId
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get all Attachments for specified Parent Id and Name
     */
    public List<Attachment> getAllWithParentIdOrdered(
            Set<Id> parentIds,
            String attachmentName
    ) {
        this.addToMainOrderByClause(
            this.mainQueryBuilder.generateOrderByClause(
                new List<SObjectSelector.OrderByBuilder> {
                    new SObjectSelector.OrderByBuilder(
                        Attachment.LastModifiedDate,
                        SObjectSelector.ASCENDING_OPERATOR
                    )
                }
            )
        );
        return getAllWithParentId(parentIds, attachmentName);
    }

    /**
     * Get all Attachments for specified Parent Id and Name
     */
    public List<Attachment> getAllWithParentId(Set<Id> parentIds, String attachmentName) {
        this.createParentIdWhereClause(parentIds);
        this.createNameWhereClause(attachmentName);
        this.setMainLimitAmount(Limits.getLimitQueryRows());
        return
            (List<Attachment>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Method to add ParentId to where clause
     */
    public void createParentIdWhereClause(Set<Id> parentIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                Attachment.ParentId,
                SObjectSelector.IN_OPERATOR,
                parentIds
            )
        );
    }

    /**
     * Method to add Name to where clause
     */
    public void createNameWhereClause(String attachmentName, String operator) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                Attachment.Name,
                operator,
                attachmentName
            )
        );
    }

    /**
     * Method to add Name to where clause
     */
    private void createNameWhereClause(String attachmentName) {
        this.createNameWhereClause(attachmentName, SObjectSelector.EQUALS_OPERATOR);
    } 
}