/**
 * Test contact domain class. This is a test implementation for the Domain layer base classes
 * It cannot be annotated with @isTest as Type.newInstance cannot see test classes
 */
public class SObjectDomainContactTest extends SObjectDomain {

    public static String FIRST_NAME = 'TestFirstName';
    public static String LAST_NAME = 'TestLastName';
    public static String BAD_LAST_NAME = 'BadLastName';
    public static String VALIDATE_FIELD_ERROR = 'LastName cannot have this value';
    public static String VALIDATE_MAP_FIELD_ERROR = 'LastName must change';

    public SObjectDomainContactTest() {
        super(Contact.SObjectType);
    }
    public SObjectDomainContactTest(List<Contact> sObjects) {
        super(sObjects);
    }

    /**
     * IDomainConstructor class for the TestContactDomain class
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {

        public SObjectDomainContactTest constructWithRecords(List<SObject> sObjectList) {
            return new SObjectDomainContactTest(sObjectList);
        }
        public SObjectDomainContactTest constructEmpty() {
            return new SObjectDomainContactTest();
        }
    }
}