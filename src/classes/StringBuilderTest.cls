/**
 * Test class for the String Builders
 */
@isTest
public class StringBuilderTest {

    private static String string1 = 'string1';
    private static String string2 = 'string2';
    private static String string3 = 'string3';
    private static String string4 = 'string4';
    private static String string5 = 'string5';

    /**
     * Test basic string builder
     */
    static testMethod void testStringBuilder() {

        String compareString = string1 +
            string2 +
            string3 +
            string5 +
            string4;

        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.add(string1);
        StringBuilder.addAll(new List<String>{string2, string3});
        StringBuilder.addAll(new Set<String>{string4, string5});
        runCompareTest(stringBuilder, compareString);
    }

    /**
     * Test CommaSeparatedBuilder
     */
    static testMethod void testCommaSeparatedBuilder() {

        String compareString = string1 + ',' +
            string2 + ',' +
            string3 + ',' +
            string4 + ',' +
            string5;

        StringBuilder.CommaSeparatedBuilder commaSeparatedBuilder =
            new StringBuilder.CommaSeparatedBuilder(
                new List<String>{
                    string1,
                    string2,
                    string3,
                    string4,
                    string5
                }
            );
        runCompareTest(commaSeparatedBuilder, compareString);
    }

    /**
     * Test InClauseBuilder
     */
    static testMethod void testInClauseBuilder() {

        String compareString = '\'' + string1 + '\',\'' +
            string2 + '\',\'' +
            string3 + '\',\'' +
            string4 + '\',\'' +
            string5 + '\'';

        StringBuilder.InClauseBuilder inClauseBuilder =
            new StringBuilder.InClauseBuilder(
                new List<String>{
                    string1,
                    string2,
                    string3,
                    string4,
                    string5
                }
            );
        runCompareTest(inClauseBuilder, compareString);
    }

    /**
     * Test in clause build escaping single quotes
     */
    static testMethod void testInClauseBuilderEscapeSingleQuotes() {

        String compareString = '\'' + string1 + '\\\'' + '\',\'' +
            string2 + '\',\'' +
            string3 + '\',\'' +
            string4 + '\',\'' +
            string5 + '\'';

        StringBuilder.InClauseBuilder inClauseBuilder =
            new StringBuilder.InClauseBuilder(
                new List<String>{
                    string1 + '\'',
                    string2,
                    string3,
                    string4,
                    string5
                }
            );
            inClauseBuilder.setShouldEscapeSingleQuotes(true);
        runCompareTest(inClauseBuilder, compareString);
    }

    /**
     * Test FieldListBuilder
     */
    static testMethod void testFieldListBuilder() {

        String compareString = Account.Name.getDescribe().getName() + ',' +
            Account.CreatedDate.getDescribe().getName() + ',' +
            Account.Id.getDescribe().getName();

        StringBuilder.FieldListBuilder fieldListBuilder =
            new StringBuilder.FieldListBuilder(
                new List<Schema.SObjectField>{
                    Account.Name,
                    Account.Name,
                    Account.Id,
                    Account.CreatedDate
                }
            );
        fieldListBuilder.processFieldList();
        runCompareTest(fieldListBuilder, compareString);
    }

    /**
     * Test OrderListBuilder
     */
    static testMethod void testOrderListBuilder() {
        String compareString = Account.Id.getDescribe().getName() + ' DESC,' +
            Account.Name.getDescribe().getName() + ' ASC';

        List<SObjectSelector.OrderByBuilder> orderByBuilderList =
            new List<SObjectSelector.OrderByBuilder> {
                new SObjectSelector.OrderByBuilder(Account.Id, 'DESC'),
                new SObjectSelector.OrderByBuilder(Account.Name, 'ASC')
            };

        StringBuilder.OrderListBuilder orderListBuilder =
            new StringBuilder.OrderListBuilder(orderByBuilderList);
        orderListBuilder.processOrderByClauseList();
        runCompareTest(orderListBuilder, compareString);
    }

    /**
     * Test String.format list building
     */
    static testMethod void testStringFormatBuilder() {
        String stringToAdd1 = 'stringToAdd1';
        String stringToAdd2 = 'stringToAdd2';
        String stringToAdd3 = 'stringToAdd3';

        String compareString = stringToAdd1 + ',' + stringToAdd2 + ',' + stringToAdd3;
        StringBuilder.FormatListBuilder formatListBuilder =
            new StringBuilder.FormatListBuilder(2);
        formatListBuilder.addMore(1);
        String testString = String.format(
            formatListBuilder.generateString(),
            new List<String>{stringToAdd1, stringToAdd2, stringToAdd3}
        );
        System.assertEquals(compareString, testString);
    }

    /**
     * Carry out the test
     */
    private static void runCompareTest(StringBuilder stringBuilder, String compareString) {

        Test.startTest();
        String testString = stringBuilder.generateString();
        Test.stopTest();
        System.assertEquals(compareString, testString);
    }
}