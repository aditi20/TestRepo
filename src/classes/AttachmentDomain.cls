/**
 * Domain class for the Attachment object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Aditi Satpute
 */
public with sharing class AttachmentDomain extends SObjectDomain {

    public AttachmentDomain() {
        super(Attachment.SObjectType);
    }

    public AttachmentDomain(List<Attachment> sObjects) {
        super(sObjects);
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public AttachmentDomain constructWithRecords(List<SObject> sObjectList) {
            return new AttachmentDomain(sObjectList);
        }
        public AttachmentDomain constructEmpty() {
            return new AttachmentDomain();
        }
    }
}