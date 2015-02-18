/*
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author : Kaushik Ray
 */
public with sharing class XFormEditor {

    public Attachment actual_doc{ get; set; }
    public String body_actual_doc_val {get; set;}
    public String save_type {get;set;}
    public String Message{get; set; }
    public Survey__c survey {get;set;}
    public boolean hasErrors {get;set;}
    public boolean isEditable {get;set;}

    public XFormEditor(){}

    // This method shows the document related to the selected Survey in a separate page.
    public void editXForm() {
        hasErrors = false;
        Id auxSurveyId = Apexpages.currentPage().getParameters().get('surveyId');
        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();
        attachmentCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Attachment.Name,
            Attachment.Body
        });

        if (auxSurveyId != null) {
            Attachment attachment=null;

            // Select the last survey in Draft status
            List<SurveyVersion__c> listVer = getSurvey(auxSurveyId);
            if (listVer != null && !listVer.isEmpty()) {
                SurveyVersion__c version = listVer[0];

                isEditable = (version.Status__c == SurveyDO.STATUS_DRAFT);
                List<Attachment> listDoc = [
                    SELECT
                        Id,
                        Body
                    FROM
                        Attachment
                    WHERE
                        ParentId = :version.Id AND Name = :XformCreator.XFORM_ATTACHMENT
                ];

                //if the document does not exist, creates a new one
                if( listDoc == null || listDoc.isEmpty()){
                    attachment = (new XFormCreator()).getAttachment(version);
                }
                else {
                    attachment = listDoc[0];
                }

                this.actual_doc = attachment;
                Blob blobDoc = this.actual_doc.Body;
                String docBodyStr = blobDoc.toString();
                this.Message = docBodyStr;
            }
        }
    }

    @RemoteAction
    public static List<SurveyVersion__c> getSurvey(Id surveyId) {
        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            SurveyVersion__c.Survey__c
        });
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.Name,
            Survey__c.Alias__c,
            Survey__c.IsPPI__c,
            Survey__c.Status__c,
            Survey__c.Gps_Location_Enabled__c,
            Survey__c.Close_Message__c,
            Survey__c.InterviewMapField__c,
            Survey__c.Gps_ShowMap__c
        });
        return [
            SELECT
                Status__c,
                Survey__c,
                Survey__r.Name,
                Survey__r.Alias__c,
                Survey__r.IsPPI__c,
                Survey__r.Status__c,
                Survey__r.Gps_Location_Enabled__c,
                Survey__r.Close_Message__c,
                Survey__r.InterviewMapField__c,
                Survey__r.Gps_ShowMap__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c = :surveyId
        ];
    }

    // saves changes. if it has an error, stays in the page and displays it. if it is a "save" return to survey manager, if it is a "quicksave" stays in the page
    public PageReference save () {

        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();

        if(body_actual_doc_val != null){
            attachmentCreator.populateFields(
                this.actual_doc,
                new Map<Schema.SObjectField, Object>{
                    Attachment.Body => Blob.valueof(body_actual_doc_val)
                }
            );

            attachmentCreator.checkObjectCreateable();
            attachmentCreator.checkObjectUpdateable();
            upsert this.actual_doc;

            GenericObjectCreator surveyCreator =
                new GenericObjectCreator(Survey__c.SObjectType);
            surveyCreator.checkObjectAccessible();
            surveyCreator.checkObjectUpdateable();
            surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
                Survey__c.XForm_Status__c,
                Survey__c.Saving_XForm__c
            });

            //update the XForm Status in the version
            List<Survey__c> listSur = [select Id, XForm_Status__c, Saving_XForm__c From Survey__c where Id = :this.actual_doc.ParentId];
            if( listSur != null && !listSur.isEmpty()) {
                Survey__c survey = listSur[0];
                surveyCreator.populateFields(
                    survey,
                    new Map<Schema.SObjectField, Object>{
                        Survey__c.XForm_Status__c => C.XFORM_STATUS_CUSTOM,
                        Survey__c.Saving_XForm__c => true
                    }
                );
                update survey;
            }
            hasErrors = false;
            if (this.save_type == 'save') return Page.SurveyManager;
        }
        return null;
    }

    //goes back to survey manager
    public PageReference cancel(){
        return Page.SurveyManager;
    }


}