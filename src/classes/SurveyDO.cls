/**
 * Domain class for the Survey__c object
 *
 * TODO:
 *    - Refactor code based on SOC architechture
 *    - Use appropriate selector and domain layers and update all queries and DML operations
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Aditi Satpute
 * @author - Kaushik Ray
 */
public with sharing class SurveyDO extends SObjectDomain {

    static public final String STATUS_DRAFT = 'Draft';
    static public final String STATUS_PUBLISHED = 'Published';
    static public final String STATUS_CLOSED = 'Closed';
    static public final String STATUS_CLOSED_AUTO = 'Automatically Closed';
    static public final String STATUS_DEPRECATED = 'Deprecated';
    static public final String STATUS_INVALID = 'Invalid';
    static public final String DEPLOYMENT_VALUE = 'Smartphone';

    public SurveyDO() {
        super(Survey__c.SObjectType);
    }

    public SurveyDO(List<Survey__c> sObjects) {
        super(sObjects);
    }

    public static Map<String, String> getStatusTranslations() {
        return new Map<String, String>{
            STATUS_DRAFT => Label.SURVEY_STATUS_DRAFT,
            STATUS_PUBLISHED => Label.SURVEY_STATUS_PUBLISHED,
            STATUS_CLOSED => Label.SURVEY_STATUS_CLOSED,
            STATUS_CLOSED_AUTO => Label.SURVEY_STATUS_CLOSED_AUTO,
            STATUS_DEPRECATED => Label.SURVEY_STATUS_DEPRECATED,
            STATUS_INVALID => Label.SURVEY_STATUS_INVALID
        };
    }

    /**
     * Clone surveys
     */
    public List<Survey__c> cloneSurveys() {
        List<Survey__c> clonedSurveys = new List<Survey__c>();
        for (Survey__c surveyToClone : (List<Survey__c>) this.records) {
            clonedSurveys.add(cloneSurveyCheckingNameAndAlias(surveyToClone));
        }
        return clonedSurveys;
    }

    /**
     * Clone a survey but check that the name and alias are not in use already
     * Change the name and alias if needed. Not this makes two SOQL queries each
     * time it is called. TODO - bulkify this more when we allow for cloning multiple
     * surveys at a time (if we ever do)
     */
    @TestVisible
    private Survey__c cloneSurveyCheckingNameAndAlias(Survey__c surveyToClone) {
        Survey__c clonedSurvey = cloneSurvey(surveyToClone);
        checkAlias(clonedSurvey);
        checkName(clonedSurvey);
        return clonedSurvey;
    }

    private Survey__c cloneSurvey(Survey__c surveyToClone) {
        surveyToClone.Id = null;
        Survey__c clonedSurvey = surveyToClone.clone(false, true, false, false);
        return clonedSurvey;
    }

    /**
     * Check that the survey alias has already been used
     */
    private void checkAlias(Survey__c surveyToCheck) {

        if (!String.isBlank(surveyToCheck.Alias__c)) {
            SurveySelector selector = new SurveySelector();
            List<Survey__c> clashingAliases = selector.getByAlias(
                surveyToCheck.Alias__c,
                SObjectSelector.EQUALS_OPERATOR
            );
            if (clashingAliases.size() > 0) {
                changeAliasField(surveyToCheck);
            }
        }
    }

    /**
     * Change the survey alias as it has already been used
     */
    private void changeAliasField(Survey__c surveyToChange) {
        SurveySelector selector = new SurveySelector();
        String filterString = createCloneFilterString(surveyToChange.Alias__c);
        List<Survey__c> clashingAliases = selector.getByAlias(
            filterString,
            SObjectSelector.LIKE_OPERATOR
        );
        surveyToChange.Alias__c = createCloneString(
            clashingAliases.size() + 1,
            surveyToChange.Alias__c
        );
    }

    /**
     * Change the survey name if they has already been used
     */
    private void checkName(Survey__c surveyToCheck) {
        SurveySelector selector = new SurveySelector();
        List<Survey__c> clashingSurveyName = selector.getByName(
            surveyToCheck.Name,
            SObjectSelector.EQUALS_OPERATOR
        );
        if (clashingSurveyName.size() > 0) {
            changeNameField(surveyToCheck);
        }
    }

    /**
     * Change the survey alias as it has already been used
     */
    private void changeNameField(Survey__c surveyToChange) {
        SurveySelector selector = new SurveySelector();
        String filterString = createCloneFilterString(surveyToChange.Name);
        List<Survey__c> clashingNames = selector.getByName(
            filterString,
            SObjectSelector.LIKE_OPERATOR
        );
        surveyToChange.Name = createCloneString(
            clashingNames.size() + 1,
            surveyToChange.Name
        );
        if (surveyToChange.Name.length() > 80) {
            throw new SObjectSelector.SelectorException(
                System.label.CREATESURVEY_ERR_NAMETOOLONG
            );
        }
    }

    private String createCloneFilterString(String baseString) {
        return '%' + System.label.CLONE_SURVEY_NAME + '%' + baseString + '%';
    }

    @TestVisible
    private String createCloneString(Integer instance, String baseString) {
        return System.label.CLONE_SURVEY_NAME + ' ' + instance + ' ' + baseString;
    }

    /**
     * Change the status of a survey from DRAFT to PUBLISHED
     *
     * @param   survey  the survey that will be published
     * @return          the survey version of the published survey
     */
    public static SurveyVersion__c publishSurvey(Survey__c survey) {
        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Status__c,
                SurveyVersion__c.Survey__c
            }
        );
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Survey__c.Name,
                Survey__c.Alias__c,
                Survey__c.Close_Message__c,
                Survey__c.Gps_Location_Enabled__c,
                Survey__c.Gps_ShowMap__c
            }
        );

        // Change the survey status
        SurveyVersion__c version =[
            SELECT
                Id,
                Status__c,
                Survey__c,
                Survey__r.Name,
                Survey__r.Alias__c,
                Survey__r.Id,
                Survey__r.Close_Message__c,
                Survey__r.CreatedDate,
                Survey__r.Gps_Location_Enabled__c,
                Survey__r.Gps_ShowMap__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__c = :survey.Id
                ORDER BY Version__c
                DESC LIMIT 1
        ];

        surveyVersionCreator.populateFields(
            version,
            new Map<Schema.SObjectField, Object> {
                SurveyVersion__c.Status__c => SurveyDO.STATUS_PUBLISHED
            }
        );

        // Obtain the map of permissions for needed object (from PrivilegeHelper).
        String surveyVersionName = Schema.sObjectType.SurveyVersion__c.getName();
        Set<String> objectSet    = new Set<String> {surveyVersionName};

        // Obtain profile permissions for the current user.
        Map<String, DescribeSObjectResult> mapPermissions =
            PrivilegesHelper.obtainObjectPermissions(objectSet);

        // Check User has permission to update versions.
        surveyVersionCreator.checkObjectUpdateable();
        update version;

        GenericObjectCreator attachmentCreator =
            new GenericObjectCreator(Attachment.SObjectType);
        attachmentCreator.checkObjectAccessible();

        // Generate XForm on Publish, if there is no xform yet
        if ([
                SELECT
                    Id
                FROM
                    Attachment
                WHERE
                    ParentId = :version.Id
                    AND Name = :XformCreator.XFORM_ATTACHMENT
            ].isEmpty()
        ) {
            new XformCreator().createDocument(version);
        }
        return version;
    }

    /**
     * Gets the survey data for the results logic
     *
     * @param  surveyId the id of the selected survey
     * @return          the survey record for the given id
     */
    public static Survey__c getSurveyDataForResults(Id surveyId) {

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            Survey__c.Name,
            Survey__c.Alias__c,
            Survey__c.IsPPI__c
        });
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Question__c.Type__c
        });
        GenericObjectCreator scoringGroupCreator =
            new GenericObjectCreator(ScoringGroup__c.SObjectType);
        scoringGroupCreator.checkObjectAccessible();
        scoringGroupCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            ScoringGroup__c.Caption__c
        });
        GenericObjectCreator ppiTableDataSetCreator =
            new GenericObjectCreator(PPITableDataSet__c.SObjectType);
        ppiTableDataSetCreator.checkObjectAccessible();
        ppiTableDataSetCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                PPITableDataSet__c.PPITable__c
            }
        );
        GenericObjectCreator ppiTableCreator =
            new GenericObjectCreator(PPITable__c.SObjectType);
        ppiTableCreator.checkObjectAccessible();
        ppiTableCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                PPITable__c.Name
            }
        );

        // Survey + Question + ScoringGroup + PPITableDataSet
        return [
            SELECT
                Id,
                Name,
                Alias__c,
                IsPPI__c,
                (
                    SELECT
                        Id,
                        Type__c
                    FROM
                        Questions__r
                    WHERE
                        Parent__c = :null
                        AND Type__c IN (
                            :QuestionDO.TYPE_SECTION,
                            :QuestionDO.TYPE_REPEAT
                        )
                        ORDER BY Position__c
                ),
                (
                    SELECT
                        Id,
                        Caption__c,
                        IsPpi__c
                    FROM
                        Scoring_Groups__r
                        ORDER BY Id
                ),
                (
                    SELECT
                        PPITable__c,
                        PPITable__r.Name
                    FROM
                        PPI_Table_Data_Sets__r
                        ORDER BY Name ASC
                )
            FROM
                Survey__c
            WHERE
                Id = :surveyId
        ];
    }

    /**
     * This method will be used to check if a survey is based on new Ppi data model or
     * Created with old Ppi data model. We are not using Ppi Identifier field of Survey object
     * as we may decide to populate it in future. Current check is based on Ppiresult fields populated on Question 
     * records, which stores demographic questions.
     */
    public static Boolean isNewPpiSurvey(Survey__c survey) {
        List<Question__c> questions =
            new QuestionSelector().getAllForSurveyIds(new Set<String> {survey.Id});
        Integer count = 0;
        for (Question__c questionInstance : questions) {
            if (!String.isBlank(questionInstance.PpiResultsField__c)) {
                count++;
            }
        }

        // Count will be 16 based on demographic questions and Ppi questions
        if (count == 16) {
            return true;
        }
        return false;
    }

    /**
     * Gets a map with the questions of the given survey with the needed data for the results logic
     *
     * @param  surveyId the id of the selected survey
     * @return          a map with the questions
     */
    public static Map<Id, Question__c> getQuestionsDataForResults(Id surveyId) {
        GenericObjectCreator questionCreator =
            new GenericObjectCreator(Question__c.SObjectType);
        questionCreator.checkObjectAccessible();
        questionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                Question__c.Name,
                Question__c.Type__c,
                Question__c.Parent__c,
                Question__c.Caption__c
            }
        );
        return new Map<Id, Question__c>(
            [
                SELECT
                    Id,
                    Name,
                    Caption__c,
                    Type__c,
                    Parent__r.Id,
                    Parent__r.Name,
                    Parent__r.Caption__c,
                    Parent__r.Type__c,
                    (
                        SELECT
                            Id,
                            Name,
                            Caption__c,
                            Type__c,
                            Parent__r.Id,
                            Parent__r.Name,
                            Parent__r.Caption__c,
                            Parent__r.Type__c
                        FROM
                            Questions__r
                        WHERE
                            Type__c NOT IN (
                                :QuestionDO.TYPE_STATIC,
                                :QuestionDO.TYPE_FINAL
                            )
                            ORDER BY Position__c
                    )
                FROM
                    Question__c
                WHERE
                    Survey__c = :surveyId
                    AND Type__c IN (
                        :QuestionDO.TYPE_SECTION,
                         :QuestionDO.TYPE_REPEAT,
                         :QuestionDO.TYPE_CASCADING_SELECT
                    )
                    ORDER BY Parent__r.Position__c, Position__c
            ]
        );
    }

    /**
     * Set several surveys status.
     * Setting the status to some surveys through their most recent version.
     * By setting the status of the most recent version the survey status is set via a trigger.
     * Cannot set a SurveyVersion back to draft so to set a Survey back to draft use SurveyDO.reopenSurveys()
     *
     * @param surveys - List of Survey to change the status
     * @param status  - Status to set to surveys
    */
    public static void updateSurveysStatus(List <Survey__c> surveys, String status) {

        GenericObjectCreator surveyVersionCreator =
            new GenericObjectCreator(SurveyVersion__c.SObjectType);
        surveyVersionCreator.checkObjectAccessible();
        surveyVersionCreator.checkFieldsAccessible(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Version__c,
                SurveyVersion__c.Survey__c,
                SurveyVersion__c.Status__c
            }
        );
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();

        Map <Id, SurveyVersion__c> mapVersions = new Map <Id, SurveyVersion__c>();
        List <SurveyVersion__c> versionsLoaded = [
            SELECT
                Id,
                Version__c,
                Survey__r.Id,
                Status__c
            FROM
                SurveyVersion__c
            WHERE
                Survey__r.Id IN :surveys
            ORDER BY Version__c DESC
        ];
        for (SurveyVersion__c version : versionsLoaded) {

            // Get only the last version of survey
            if (!mapVersions.containsKey(version.Survey__r.Id)) {
                surveyVersionCreator.populateFields(
                    version,
                    new Map<Schema.SObjectField, Object> {
                        SurveyVersion__c.Status__c => status
                    }
                );
                mapVersions.put(version.Survey__r.Id, version);
            }
        }
        if (mapVersions.size() > 0) {
            surveyVersionCreator.checkObjectUpdateable();
            // Update version list
            update mapVersions.values();
        }
    }

    /**
     * Re-open surveys. This will set them back to draft status and create a new version
     *
     * @param surveys - A list of surveys to be re-opened
     */
    public static void reopenSurveys(List<Survey__c> surveys) {

        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.Status__c
        });

        SurveyTriggerLogic.setOverrideDeleteChecks(true);
        for (Survey__c survey : surveys) {
            surveyCreator.populateFields(
                survey,
                new Map<Schema.SObjectField, Object> {
                    Survey__c.Status__c => SurveyDO.STATUS_DRAFT
                }
            );
        }
        surveyCreator.checkObjectUpdateable();
        update surveys;
        SurveyTriggerLogic.setOverrideDeleteChecks(false);
    }

    /**
     * Set the Ppi Identifier before inserting each record in the domain
     */
    public void setPpiIdentifier(List<Survey__c> surveyList) {
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.IsPPI__c,
            Survey__c.RemoteId__c,
            Survey__c.IsTemplate__c,
            Survey__c.PpiIdentifier__c
        });

        for (Survey__c survey : surveyList) {
            if (survey.IsPPI__c && survey.IsTemplate__c && survey.RemoteId__c == null) {
                surveyCreator.populateFields(
                    survey,
                    new Map<Schema.SObjectField, Object> {
                        Survey__c.PpiIdentifier__c => createPpiIdentifier(survey)
                    }
                );
            }
        }
    }

    /**
     * Update the Ppi Identifier for each record in the domain
     */
    public void setPpiIdentifier(Map<Id, Survey__c> oldSurveyMap, List<Survey__c> surveyList) {
        GenericObjectCreator surveyCreator =
            new GenericObjectCreator(Survey__c.SObjectType);
        surveyCreator.checkObjectAccessible();
        surveyCreator.checkFieldsAccessible(new List<Schema.SObjectField>{
            Survey__c.IsPPI__c,
            Survey__c.RemoteId__c,
            Survey__c.IsTemplate__c,
            Survey__c.PpiIdentifier__c,
            Survey__c.CountryCode__c,
            Survey__c.PPIDataYear__c
        });

        for (Survey__c survey : surveyList) {
            Survey__c oldSurveyRecord = oldSurveyMap.get(survey.Id);
            if (survey.IsPPI__c && survey.IsTemplate__c && survey.RemoteId__c == null &&
                (
                    survey.CountryCode__c != oldSurveyRecord.CountryCode__c ||
                    survey.PPIDataYear__c != oldSurveyRecord.PPIDataYear__c
                )
            ) {
                surveyCreator.populateFields(
                    survey,
                    new Map<Schema.SObjectField, Object> {
                        Survey__c.PpiIdentifier__c => createPpiIdentifier(survey)
                    }
                );
            }
        }
    }

    /**
     * Create a string that should identify this record as ppi Identifier
     */
    private String createPpiIdentifier(Survey__c survey) {
        ISO_Country__c country =
            ISOCountryWrapper.getInstanceWithName(survey.CountryCode__c);
        if (country != null) {
            return
                ISO_Country__c.getInstance(survey.CountryCode__c).ShortName__c + '_' +
                    survey.PPIDataYear__c;
        }
        return null;
    }

    /**
     * IDomainConstructor class for Separation of Concerns
     */
    public class Constructor implements SObjectDomain.IDomainConstructor {
        public SurveyDO constructWithRecords(List<SObject> sObjectList) {
            return new SurveyDO(sObjectList);
        }
        public SurveyDO constructEmpty() {
            return new SurveyDO();
        }
    }
}