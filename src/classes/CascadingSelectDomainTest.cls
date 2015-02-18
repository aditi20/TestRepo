/**
 * Test class for the CascadingSelect__c object domain class
 * Deals with:
 *     - Creation of a cascading select
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class CascadingSelectDomainTest {

    public static final String TEST_CASCADING_SELECT_NAME = 'testCascadingSelect';

    public static CascadingSelect__c createCascadingSelect() {
        return createCascadingSelect('');
    }

    public static CascadingSelect__c createCascadingSelect(String suffix) {
        return createCascadingSelect(new Map<Schema.SObjectField, Object>{
            CascadingSelect__c.Name => TEST_CASCADING_SELECT_NAME  + suffix,
            CascadingSelect__c.Status__c => C.CASCADING_STATUS_UPLOADED
        });
    }

    public static CascadingSelect__c createCascadingSelect(Map<Schema.SObjectField, Object> fieldMap) {

        GenericObjectCreator creator = new GenericObjectCreator(CascadingSelect__c.getSObjectType());
        CascadingSelect__c cascadingSelect = (CascadingSelect__c) creator.createNewRecord();
        creator.populateFields(
            cascadingSelect,
            fieldMap
        );
        return cascadingSelect;
    }

    public static UnitOfWork addCascadingSelectToUnitOfWork(
            CascadingSelect__c cascadingSelect,
            UnitOfWork unitOfWork
    ) {
        Integer level = unitOfWork.addToInsertionOrder(CascadingSelect__c.getSObjectType());
        unitOfWork.addToInsertList(cascadingSelect, level);
        return unitOfWork;
    }


    /**
     * Create a Cascading Select and insert it into the database with new unit of work
     */
    public static CascadingSelectWrapper createInsertedCascadingSelectWrapper(Boolean includeValues) {
        return createInsertedCascadingSelectWrapper(new UnitOfWork(), includeValues);
    }

    /**
     * Create a Cascading Select and insert it into the database
     */
    public static CascadingSelectWrapper createInsertedCascadingSelectWrapper(
            UnitOfWork unitOfWork,
            Boolean includeValues
    ) {
        CascadingSelectWrapper wrapper = new CascadingSelectWrapper(unitOfWork);
        wrapper.createDefaultWrapper(includeValues);
        wrapper.getUnitOfWork().commitWork();
        return wrapper;
    }

    /**
     * This one will not commit the unit of work. The calling code does that.
     * This is so that this can be used whilst creating a survey
     */
    public static CascadingSelectWrapper createCascadingSelectWrapper(
            UnitOfWork unitOfWork,
            Boolean includeValues,
            Survey__c surveySObject,
            Question__c regularSection
    ) {
        CascadingSelectWrapper wrapper =
            new CascadingSelectWrapper(unitOfWork, surveySObject, regularSection);
        wrapper.createDefaultWrapper(includeValues);
        return wrapper;
    }

    /**
     * Class to create a complete cascading select
     */
    public class CascadingSelectWrapper {
        public CascadingSelect__c cascadingSelect;
        private List<CascadingLevel__c> cascadingLevels;
        private Map<Integer, Map<String, CascadingValueWrapper>> cascadingValues;

        public Question__c cascadingSelectQuestion;
        public List<Question__c> cascadingLevelQuestions;

        private Survey__c surveySObject;
        private Question__c regularSection;

        private UnitOfWork unitOfWork;

        /**
         * Use this constructor to create a cascading select on its own
         */
        public CascadingSelectWrapper(UnitOfWork unitOfWork) {
            this.unitOfWork = unitOfWork;
            this.cascadingValues = new Map<Integer, Map<String, CascadingValueWrapper>>();
        }

        /**
         * Use this constructor to add a cascading select to a survey
         */
        public CascadingSelectWrapper(
                UnitOfWork unitOfWork,
                Survey__c surveySObject,
                Question__c regularSection
        ) {
            this(unitOfWork);
            this.surveySObject = surveySObject;
            this.regularSection = regularSection;
        }

        /**
         * Get the UnitOfWork
         */
        public UnitOfWork getUnitOfWork() {
            return this.unitOfWork;
        }

        public void createDefaultWrapper(Boolean addCascadingValues) {

            this.cascadingSelect = CascadingSelectDomainTest.createCascadingSelect();
            CascadingSelectDomainTest.addCascadingSelectToUnitOfWork(
                this.cascadingSelect,
                this.unitOfWork
            );
            this.cascadingLevels = CascadingLevelDomainTest.createCascadingLevels(3);
            CascadingLevelDomainTest.addLevelsToUnitOfWork(
                this.cascadingLevels,
                this.cascadingSelect,
                this.unitOfWork
            );
            if (addCascadingValues) {
                this.addCascadingValues(3);
                this.saveCascadingValueSObjects();
            }
        }

        public void addCascadingValues(Integer amountPerNode) {
            this.createTopLevelValues(amountPerNode);
            this.createChildValues(amountPerNode);
        }

        /**
         * Create the top level values for the cascading select
         */
        private void createTopLevelValues(Integer amountPerNode) {
            Map<String, CascadingValueWrapper> topLevelValueMap =
                new Map<String, CascadingValueWrapper>();
            for (Integer i = 0; i < amountPerNode; i++) {
                 CascadingValueWrapper cascadingValueWrapper =
                    new CascadingValueWrapper(
                        this.cascadingLevels[0],
                        i,
                        'Depth_' + 0 + '_Child_' + i + '_',
                        0,
                        null
                    );
                topLevelValueMap.put(cascadingValueWrapper.getValue(), cascadingValueWrapper);
            }
            this.cascadingValues.put(0, topLevelValueMap);
        }

        /**
         * Create the child values for the remaining cascading values
         */
        private void createChildValues(Integer amountPerNode) {
            for (Integer i = 1; i < this.cascadingLevels.size(); i++) {
                Map<String, CascadingValueWrapper> valueMap =
                    new Map<String, CascadingValueWrapper>();
                for (
                        CascadingValueWrapper cascadingValueWrapper :
                            this.cascadingValues.get(i - 1).values()
                ) {
                    for (
                            CascadingValueWrapper childWrapper :
                            cascadingValueWrapper.createChildren(
                                amountPerNode, this.cascadingLevels[i]
                            )
                    ) {
                        valueMap.put(childWrapper.getValue(), childWrapper);
                    }
                }
                this.cascadingValues.put(i, valueMap);
            }
        }

        public void saveCascadingValueSObjects() {
            for (Integer i = 0; i < this.cascadingLevels.size(); i++) {
                for (CascadingValueWrapper wrapper : this.cascadingValues.get(i).values()) {
                    wrapper.addToUnitOfWork(this.unitOfWork);
                }
            }
        }

        /**
         * Use this to update the internal unitOfWork. Used when not creating this in isolation
         */
        public UnitOfWork addQuestionsToWrapper(
                Integer positionInSurvey,
                UnitOfWork unitOfWork
        ) {
            this.unitOfWork = unitOfWork;
            this.addQuestionsToWrapper(positionInSurvey);
            return this.unitOfWork;
        }

        public void addQuestionsToWrapper(Integer positionInSurvey) {
            this.cascadingSelectQuestion =
                QuestionDOTest.createCascadingSelectQuestion(positionInSurvey);
            this.unitOfWork = QuestionDOTest.addCascadingSelectToUnitOfWork(
                cascadingSelect,
                this.cascadingSelectQuestion,
                this.regularSection,
                this.surveySObject,
                this.unitOfWork
            );
            this.cascadingLevelQuestions =
                QuestionDOTest.createCascadingLevelQuestions(this.cascadingLevels);
            this.unitOfWork = QuestionDOTest.addCascadingLevelToUnitOfWork(
                this.cascadingLevelQuestions,
                this.cascadingSelectQuestion,
                this.surveySObject,
                this.unitOfWork
            );
        }
    }

    private class CascadingValueWrapper {
        private CascadingLevel__c cascadingLevel;
        private Integer position;
        private String value;
        private Integer depth;

        private Map<String, CascadingValueWrapper> childValues;
        private CascadingValueWrapper parentWrapper;
        private CascadingSelectValue__c record;

        public CascadingValueWrapper(
                CascadingLevel__c cascadingLevel,
                Integer position,
                String value,
                Integer depth,
                CascadingValueWrapper parentWrapper
        ) {
            this.cascadingLevel = cascadingLevel;
            this.position = position;
            this.value = value;
            this.depth = depth;
            this.parentWrapper = parentWrapper;
            this.childValues = new Map<String, CascadingValueWrapper>();
            this.record = new CascadingSelectValue__c(Value__c = value, Position__c = position);
        }

        public String getValue() {
            return this.value;
        }

        public List<CascadingValueWrapper> getChildren() {
            return this.childValues.values();
        }

        public CascadingSelectValue__c getSObject() {
            return this.record;
        }

        public List<CascadingValueWrapper> createChildren(
                Integer numberOfChildren,
                CascadingLevel__c childLevel
        ) {
            List<CascadingValueWrapper> childWrappers = new List<CascadingValueWrapper>();
            Integer newDepth = this.depth + 1;
            for (Integer i = 0; i < numberOfChildren; i++) {
                String newValue = this.value + 'Depth_' + newDepth + '_Child_' + i + '_';
                childWrappers.add(
                    new CascadingValueWrapper(childLevel, i, newValue, newDepth, this)
                );
            }
            return childWrappers;
        }

        public void addToUnitOfWork(UnitOfWork unitOfWork) {
            unitOfWork.addToInsertionOrder(CascadingSelectValue__c.getSObjectType(), this.depth);
            unitOfWork.addToInsertList(
                this.record,
                CascadingSelectValue__c.CascadingLevel__c,
                this.cascadingLevel,
                depth
            );
            if (this.parentWrapper != null) {
                unitOfWork.createRelationship(
                    this.record,
                    CascadingSelectValue__c.ControllingSelectValue__c,
                    this.parentWrapper.getSObject(),
                    depth
                );
            }
        }
    }
}