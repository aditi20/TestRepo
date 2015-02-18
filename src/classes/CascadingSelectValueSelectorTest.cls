/**
 * Test class for the CascadingSelectValueSelector class
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Owen Davies - odavies@grameenfoundation.org
 */
@isTest
public class CascadingSelectValueSelectorTest {

    /**
     * Test get all for a survey
     */
    static testMethod void testGetAllForCascadingSelect() {
        CascadingSelectDomainTest.CascadingSelectWrapper cascadingSelectWrapper =
            CascadingSelectDomainTest.createInsertedCascadingSelectWrapper(true);
        CascadingSelectValueSelector cascadingSelectValueSelector =
            new CascadingSelectValueSelector();
        List<CascadingSelectValue__c> selectValues =
            cascadingSelectValueSelector.getAllForCascadingSelect(new Set<Id> {
                cascadingSelectWrapper.cascadingSelect.Id
            });
        System.assertEquals(39, selectValues.size());
    }
}