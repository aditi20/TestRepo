/**
 * Class used to build strings. Implement this class to build strings for different situations
 *
 * Current Implementations
 *   Comma delimited list
 *   Values for IN clause in SOQL
 *   Field list for select or order by clause
 */
public virtual with sharing class StringBuilder {

    private List<String> constituentParts;
    private String joiner;
    private Boolean shouldEscapeSingleQuotes;

    public StringBuilder() {
        this.shouldEscapeSingleQuotes = false;
        this.joiner = '';
        this.constituentParts = new List<String>();
    }

    public StringBuilder(List<String> initialParts) {
        this();
        this.constituentParts = initialParts;
    }

    public StringBuilder(Set<String> initialParts) {
        this();
        this.constituentParts.addAll(initialParts);
    }

    public void add(String newPart) {
        this.constituentParts.add(newPart);
    }

    public void addAll(List<String> newParts) {
        this.constituentParts.addAll(newParts);
    }

    public void addAll(Set<String> newParts) {
        this.constituentParts.addAll(newParts);
    }

    public void addAll(Set<Id> newParts) {
        for (Id newPart : newParts) {
            this.constituentParts.add((String) newPart);
        }
    }

    public void setJoiner(String newJoiner) {
        this.joiner = newJoiner;
    }

    public void setShouldEscapeSingleQuotes(Boolean value) {
        this.shouldEscapeSingleQuotes = value;
    }

    public void escapeSingleQuotes() {
        List<String> escapedValues = new List<String>();
        for (String constituentPart : this.constituentParts) {
            escapedValues.add(
                String.escapeSingleQuotes(constituentPart)
            );
        }
        this.constituentParts = escapedValues;
    }

    public virtual String generateString() {
        return generateString(this.joiner);
    }

    public String generateString(String joiner) {
        return join(joiner);
    }

    public String join(String joiner) {
        if (this.shouldEscapeSingleQuotes) {
            escapeSingleQuotes();
        }
        return String.join(this.constituentParts, joiner);
    }

    public Boolean hasValues() {
        return !this.constituentParts.isEmpty();
    }

    /**
     * Convert Ids to 18 digit and return
     */
     public static String convertID(String idValue) {
        if (String.isBlank(idValue) || idValue.length() == 18) {
            return idValue;
        }

        return  String.valueOf(Id.valueOf(idValue));
    }

    /**
     * Implementation to build a comma sepqarated string
     */
    public virtual with sharing class CommaSeparatedBuilder extends StringBuilder {

        public CommaSeparatedBuilder() {
            super();
            setJoiner(',');
        }

        public CommaSeparatedBuilder(List<String> initialParts) {
            super(initialParts);
            setJoiner(',');
        }

        public CommaSeparatedBuilder(Set<String> initialParts) {
            super(initialParts);
            setJoiner(',');
        }

        public CommaSeparatedBuilder(Set<Id> initialParts) {
            super();
            addAll(initialParts);
            setJoiner(',');
        }
    }

    /**
     * Implementation to allow creation of a formatted String that can be used in an IN clause
     */
    public with sharing class InClauseBuilder extends StringBuilder {

        public InClauseBuilder() {
            super();
            setJoiner('\',\'');
        }

        public InClauseBuilder(List<String> initialParts) {
            super(initialParts);
            setJoiner('\',\'');
        }

        public InClauseBuilder(Set<String> initialParts) {
            super(initialParts);
            setJoiner('\',\'');
        }

        public override String generateString() {
            return '\'' + join(this.joiner) + '\'';
        }
    }

    /**
     * Implementation allows creating Order by clause with help of SObjectSelector.OrderByBuilder
     */
    public with sharing class OrderListBuilder extends CommaSeparatedBuilder {

        private List<SObjectSelector.OrderByBuilder> orderByClauseList;

        public OrderListBuilder() {
            super();
            this.orderByClauseList = new List<SObjectSelector.OrderByBuilder>();
        }

        public OrderListBuilder(List<SObjectSelector.OrderByBuilder> orderByClauseList) {
            super();
            this.orderByClauseList = orderByClauseList;
        }

        public void setOrderByClauseList(List<SObjectSelector.OrderByBuilder> orderByClauseList) {
            this.orderByClauseList = orderByClauseList;
        }

        public void processOrderByClauseList() {
            List<String> orderByClauseList = new List<String>();
            for (SObjectSelector.OrderByBuilder orderByClause : this.orderByClauseList) {
                orderByClauseList.add(orderByClause.getOrderByClause());
            }
            addAll(orderByClauseList);
        }
    }

    /**
     * Implementation to create a field list
     * TODO - allow inclusion of fieldSets
     */
    public with sharing class FieldListBuilder extends CommaSeparatedBuilder {

        private List<Schema.SObjectField> fieldList;

        public FieldListBuilder() {
            super();
            this.fieldList = new List<Schema.SObjectField>();
        }

        public FieldListBuilder(List<Schema.SObjectField> fieldList) {
            this();
            setFieldList(fieldList);
        }

        public void setFieldList(List<Schema.SObjectField> fieldList) {
            this.fieldList = fieldList;
        }

        public List<Schema.SObjectField> getFieldList() {
            return this.fieldList;
        }

        public void processFieldList() {

            Set<String> fieldNames = new Set<String>();
            for (Schema.SObjectField field : fieldList) {
                fieldNames.add(field.getDescribe().getName());
            }
            addAll(fieldNames);
        }
    }

    /**
     * Build a comma separated string for use in String.format
     */
    public with sharing class FormatListBuilder extends CommaSeparatedBuilder {

        private Integer totalInCurrentList;

        public FormatListBuilder(Integer numberOfExpectedString) {
            super();
            totalInCurrentList = 0;
            addMore(numberOfExpectedString);
        }

        public void addMore(Integer amountToAdd) {
            Integer newTotal = totalInCurrentList + amountToAdd;
            while (totalInCurrentList < newTotal) {
                this.add('{' + totalInCurrentList + '}');
                totalInCurrentList++;
            }
        }
    }
}