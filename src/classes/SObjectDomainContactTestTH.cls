/**
 * Test contact trigger handler class. This is a test implementation for the Domain layer base classes
 * It cannot be annotated with @isTest as Type.newInstance cannot see test classes
 */
public class SObjectDomainContactTestTH extends TriggerHandler {

    public override void applyDefaults() {

        // This is not required in production code. It is here to get code coverage
        super.applyDefaults();
        for (Contact record : (List<Contact>) getRecords()) {
            record.FirstName = SObjectDomainContactTest.FIRST_NAME;
            record.LastName = SObjectDomainContactTest.LAST_NAME;
        }
    }

    public override void validate() {

        // This is not required in production code. It is here to get code coverage
        super.validate();
        for (Contact record : (List<Contact>) getRecords()) {
            if (record.LastName.equals(SObjectDomainContactTest.BAD_LAST_NAME)) {
                tests.errorFactory.logError(
                    SObjectDomainContactTest.VALIDATE_FIELD_ERROR,
                    record,
                    Contact.LastName
                );
            }
        }
    }

    public override void validate(Map<Id, sObject> oldMap) {

        // This is not required in production code. It is here to get code coverage
        super.validate(oldMap);
        for (Contact record : (List<Contact>) getRecords()) {
            Contact oldContact = (Contact) oldMap.get(record.Id);
            if (record.LastName.equals(oldContact.LastName)) {
                tests.errorFactory.logError(
                    SObjectDomainContactTest.VALIDATE_MAP_FIELD_ERROR,
                    record,
                    Contact.LastName
                );
            }
        }
    }
}