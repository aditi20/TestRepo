/**
 * Test class for the OptionDomain class.
 * Deals with Option creation for test
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies - odavies@grameenfoundation.org
 * @author - Aditi Satpute
 * @author - Kaushik Ray
 */
@isTest
public class OptionDomainTest {

    public static List<Option__c> createOptionsForQuestions(
            List<Question__c> questions,
            String namePrefix,
            String captionPrefix,
            Integer optionPerQuestion
    ) {
        List<Option__c> createdOptions = new List<Option__c>();
        for (Question__c question : questions) {
            for (Integer count = 1; count <= optionPerQuestion; count++) {
                createdOptions.add(
                    createOption(new Map<Schema.SObjectField, Object>{
                        Option__c.Name => namePrefix + '_' + count,
                        Option__c.Caption__c => captionPrefix + '_' + count,
                        Option__c.PPIScore__c => count,
                        Option__c.Position__c => count,
                        Option__c.Question__c => question.Id
                    })
                );
            }
        }
        return createdOptions;
    }

    public static List<Option__c> createOptions(Integer numberOfOptions) {

        List<String> captions = new List<String>();
        for (Integer i = 1; i <= numberOfOptions; i++) {
            captions.add('Caption_' + i);
        }
        return createOptions(captions);
    }

    public static List<Option__c> createOptions(List<String> captions) {
        Integer i = 1;
        List<Option__c> options = new List<Option__c>();
        for (String caption : captions) {
            options.add(createOption(caption, i));
            i++;
        }
        return options;
    }

    public static Option__c createOption(String caption, Integer position) {
        return createOption(
            new Map<Schema.SObjectField, Object>{
                Option__c.Caption__c => caption,
                Option__c.PPIScore__c => position,
                Option__c.Position__c => position
            }
        );
    }

    public static Option__c createOption(Map<Schema.SObjectField, Object> fieldMap) {
        GenericObjectCreator creator = new GenericObjectCreator(Option__c.getSObjectType());
        Option__c option = (Option__c) creator.createNewRecord();
        creator.populateFields(
            option,
            fieldMap
        );
        return option;
    }

    /**
     * Create record for Option 
     */
    public static Option__c createRecord(
            String name,
            Question__c question,
            Integer position
    ) {
        Option__c option = new Option__c(
            Name = name,
            Caption__c = name,
            Question__c = question.Id,
            Position__c = position
        );
        return option;
    }
}