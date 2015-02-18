/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
@isTest
private class XFormEditorTest {

     static testMethod void testEditXForm(){
        LicenseSettings__c testWithLicense = newLicense(false,'Test1');
        insert testWithLicense;

        XFormEditor x = new XFormEditor();

        Survey__c survey = new Survey__c(Name='name', Status__c = SurveyDO.STATUS_DRAFT);
        insert survey;
        SurveyVersion__c ver =[SELECT Id,Status__c,Survey__c FROM SurveyVersion__c WHERE Survey__c= :survey.Id];
        insert new Attachment(
                Name = c.SURVEY_ANSWER_ATTACHMENT_NAME,
                ParentId = ver.Id,
                Body = Blob.valueOf('testStringToBlob')
                );

        // Data ok
        ApexPages.currentPage().getParameters().put('surveyId', survey.Id);

        Test.startTest();
            // test survey with no document
            List<Attachment> theDoc = [SELECT Id FROM Attachment where ParentId = :ver.Id and Name = :C.SURVEY_ANSWER_ATTACHMENT_NAME ];
            delete theDoc[0];
            ApexPages.currentPage().getParameters().put('surveyId', survey.Id);
            x.editXForm();
            System.assertEquals(x.isEditable,true);

            //Published Survey
            ver.Status__c = SurveyDO.STATUS_PUBLISHED;
            update ver;
            x.editXForm();
            System.assertEquals(x.isEditable, false);

            //Closed Survey
            ver.Status__c = SurveyDO.STATUS_CLOSED;
            update ver;
            x.editXForm();
            System.assertEquals(x.isEditable, false);

            //Deprecated Survey
            ver.Status__c = 'Deprecated';
            update ver;
            PageReference page = new PageReference('/apex/SurveyManager');
            x.editXForm();
            System.assertEquals(x.isEditable, false);

            // test cancel method (returns to the surveymanager page)
            System.assert(x.cancel().getUrl() == page.getUrl());

            // surveyId null
            ApexPages.currentPage().getParameters().put('surveyId', null);
            x = new XFormEditor();
            x.editXForm();
            System.assert(x.Message == null);

        Test.stopTest();    

    }

    static testMethod void testSave(){
        LicenseSettings__c testWithLicense = newLicense(false,'Test1');
        insert testWithLicense;
        
        Test.startTest();
            XFormEditor x = new XFormEditor();
            x.body_actual_doc_val = null;
            x.save_type = 'save';

            Survey__c survey = new Survey__c(Name='name', Status__c = SurveyDO.STATUS_DRAFT);
            insert survey;

            Attachment att = new Attachment(
                    Name = XFormCreator.XFORM_ATTACHMENT,
                    ParentId = survey.Id,
                    Body = Blob.valueOf('testStringToBlob'));
            insert att;

            // Null XForm body
            PageReference pg_test = x.save();
            system.assert( pg_test == null );

            // Data ok
            PageReference pg = new PageReference('/apex/SurveyManager');
            x.actual_doc = att;
            x.body_actual_doc_val = att.Body.toString();
            pg_test = x.save();
        Test.stopTest();
        system.assert( pg_test.getUrl() == pg.getUrl() );
    }

    //This method delete de original license and create a new one
    static LicenseSettings__c newLicense(Boolean PPIEditable, String licName){
        list<LicenseSettings__c> lS = [SELECT PPI_Editable__c FROM LicenseSettings__c limit 1];
        delete lS;
        LicenseSettings__c li = new LicenseSettings__c(PPI_Editable__c = PPIEditable, Name = licName);
        return li;
    }

}
