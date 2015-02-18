/**
 * Selector class for the SurveyVersion__c object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author - Kaushik Ray
 * @author - Aditi Satpute
 * @author - Owen Davies - odavies@grameenfoundation.org
 */
public with sharing class SurveyVersionSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return SurveyVersion__c.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField> {
            SurveyVersion__c.Distributed__c,
            SurveyVersion__c.DistributionDate__c,
            SurveyVersion__c.Id,
            SurveyVersion__c.Name,
            SurveyVersion__c.Status__c,
            SurveyVersion__c.Survey__c,
            SurveyVersion__c.Version__c,
            SurveyVersion__c.Distributed__c
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Fetch all survey version records for specified Ids along with Survey details
     */
    public List<SurveyVersion__c> getAllWithSurveyDetails(Set<Id> surveyVersionIds) {
        this.mainQueryBuilder.addRelationshipToSelect(
            new List<Schema.SObjectField> {
                SurveyVersion__c.Survey__c,
                Survey__c.PpiIdentifier__c
            }
        );
        return
            (List<SurveyVersion__c>) getRecordsById(surveyVersionIds);
    }

    /**
     * Get the most recent SurveyVersions for a list of surveys
     *
     * @param surveyList - List of surveys
     *
     * @return - A map of the surveyVersions with the key being the survey.Id
     */
    public Map<Id, SurveyVersion__c> getLatestSurveyVersion(List<Survey__c> surveyList) {

        Map<Id, SurveyVersion__c> versionMap = new Map<Id, SurveyVersion__c>();
        Set<String> setSurveyId = new Set<String>(
            String.join(new List<Id>(
                new Map<Id, Survey__c>(surveyList).keySet()
            ), ',').split(',')
        );
        for (SurveyVersion__c version : getAllWithSurveyIds(setSurveyId)) {
            versionMap.put(version.Survey__c, version);
        }
        return versionMap;
    }

    /**
     * Fetch all survey version records for specified Survey Ids
     */
    public List<SurveyVersion__c> getAllWithSurveyIds(Set<String> surveyIds) {

        return getAllForSurveyIds(new Set<Id> (C.convertListToId(new List<String> (surveyIds))));
    }

    /**
     * Fetch all survey version records for specified Survey Ids
     */
    public List<SurveyVersion__c> getAllForSurveyIds(Set<Id> surveyIds) {

        this.createSurveyIdsWhereClause(surveyIds);
        this.addToMainOrderByClause(
             SurveyVersion__c.Version__c.getDescribe().getName() +
             SObjectSelector.ASCENDING_OPERATOR
        );
        return
            (List<SurveyVersion__c>)
                runSoqlQueryDbFullAccess(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Fetch all survey version records for specified IsPpi, IsTemplate, SurveyLibrary and
     * Status not equal to Deprecated
     */
    public List<SurveyVersion__c> getAllTemplatesForLicense(
            String libraryToView,
            Boolean showPpi,
            Boolean showAll,
            String orderByClause
    ) {
 
        // Check the license. Everyone can use PPI but stop seeing templates if license doesn't allow
        LicenseSettings__c license = C.getLicense();
        if (!license.UseTemplates__c) {
            showAll = false;
            showPPI = true;
        }

        this.createSurveyRelations();

        if (showAll) {
            this.createShowAllTemplatesWithStatusWhereClause(
                showPpi,
                true,
                SurveyDO.STATUS_DEPRECATED
            );
        } else {
            this.createShowPpiTemplatesWithStatusWhereClause(
                showPpi,
                true,
                SurveyDO.STATUS_DEPRECATED
            );
        }

        // Form where clause based on libraryToView
        this.generateSurveyLibraryWhereClause(libraryToView);
        this.addToMainOrderByClause(orderByClause);
        return (List<SurveyVersion__c>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Create and add relationship fields to be used in query
     */
    private void createSurveyRelations() {
        this.getMainQueryBuilder().addRelationshipToSelect(
            new List<List<Schema.SObjectField>> {
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.Name
                },
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.Id
                },
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.Status__c
                },
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.Description__c
                },
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.Version__c
                },
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.IsPPI__c
                },
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.IsTemplate__c
                },
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.CreatedDate
                },
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.SurveyLibrary__c,
                    SurveyLibrary__c.Name
                },
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.CreatedById,
                    User.Name
                }
            }
        );
    }

    private void createShowAllTemplatesWithStatusWhereClause(
            Boolean isPpi,
            Boolean isTemplate,
            String statusValue
    ) {
        this.getMainQueryBuilder().addToWhereClause(returnIsPpiWhereClause(isPpi));
        this.getMainQueryBuilder().addToWhereClause(returnIsTemplateWhereClause(isTemplate));
        String ppiTemplateWhereClause =
            '(' +
            this.getMainQueryBuilder().generateConcatenatedWhereClause(
                SObjectSelector.AND_OPERATOR
            ) +
            ')';
        this.getMainQueryBuilder().resetWhereClause();
        this.getMainQueryBuilder().addToWhereClause(ppiTemplateWhereClause);
        this.getMainQueryBuilder().addToWhereClause(returnIsTemplateWhereClause(isTemplate));
        ppiTemplateWhereClause = 
            '(' +
            this.getMainQueryBuilder().generateConcatenatedWhereClause(
                SObjectSelector.OR_OPERATOR
            ) +
            ')';
        this.getMainQueryBuilder().resetWhereClause();
        this.getMainQueryBuilder().addToWhereClause(ppiTemplateWhereClause);
        this.getMainQueryBuilder().addToWhereClause(returnStatusNotEqualWhereClause(statusValue));
        ppiTemplateWhereClause = 
            '(' +
            this.getMainQueryBuilder().generateConcatenatedWhereClause(
                SObjectSelector.AND_OPERATOR
            ) +
            ')';
        this.getMainQueryBuilder().resetWhereClause();
        this.getMainQueryBuilder().addToWhereClause(ppiTemplateWhereClause);
    }

    private void createShowPpiTemplatesWithStatusWhereClause(
            Boolean isPpi,
            Boolean isTemplate,
            String statusValue
    ) {
        this.createIsPpiWhereClause(isPpi);
        this.createIsTemplateWhereClause(isTemplate);
        this.createStatusNotEqualWhereClause(statusValue);
    }

    /**
     * Create where clause with Survey isPpi for main Survey Version query
     */
    private void createIsPpiWhereClause(Boolean isPpi) {
        this.addToMainWhereClause(
            returnIsPpiWhereClause(isPpi)
        );
    }

    private String returnIsPpiWhereClause(Boolean isPpi) {
        return this.getMainQueryBuilder().generateStandardWhereClause(
            this.getMainQueryBuilder().generateLookUp(
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.IsPPI__c
                }
            ),
            SObjectSelector.EQUALS_OPERATOR,
            isPpi
        );
    }

    /**
     * Create where clause with Survey isTemplate for main Survey Version query
     */
    private void createIsTemplateWhereClause(Boolean value) {
        this.addToMainWhereClause(
            returnIsTemplateWhereClause(value)
        );
    }

    private String returnIsTemplateWhereClause(Boolean value) {
        return this.getMainQueryBuilder().generateStandardWhereClause(
            this.getMainQueryBuilder().generateLookUp(
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.IsTemplate__c
                }
            ),
            SObjectSelector.EQUALS_OPERATOR,
            value
        );
    }

    /**
     * Create where clause with survey status for main Survey Version query
     */
    private void createStatusNotEqualWhereClause(String value) {
        this.addToMainWhereClause(
            returnStatusNotEqualWhereClause(value)
        );
    }

    private String returnStatusNotEqualWhereClause(String value) {
        return this.getMainQueryBuilder().generateStandardWhereClause(
            this.getMainQueryBuilder().generateLookUp(
                new List<Schema.SObjectField> {
                    SurveyVersion__c.Survey__c,
                    Survey__c.Status__c
                }
            ),
            SObjectSelector.NOT_EQUALS_OPERATOR,
            value
        );
    }

    /**
     * Method to create SurveyLibrary where clause for specified library
     */
    private void generateSurveyLibraryWhereClause(String libraryToView) {
        if (libraryToView.equals('myLib')) {
            this.createSurveyLibraryNullWhereClause();
        } else if (!libraryToView.equals('default')) {
            this.createSurveyLibraryNameWhereClause(libraryToView);
        } 
    }

    /**
     * Create where clause with Survey Library for main Survey Version query
     */
    private void createSurveyLibraryNullWhereClause() {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        SurveyVersion__c.Survey__c,
                        Survey__c.SurveyLibrary__c
                    }
                ),
                SObjectSelector.EQUALS_OPERATOR,
                SObjectSelector.NULL_VALUE
            )
        );
    }

    /**
     * Create where clause with Survey Library Name for main Survey Version query
     */
    private void createSurveyLibraryNameWhereClause(String libraryToView) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        SurveyVersion__c.Survey__c,
                        Survey__c.SurveyLibrary__c,
                        SurveyLibrary__c.Name
                    }
                ),
                SObjectSelector.EQUALS_OPERATOR,
                libraryToView
            )
        );
    }

    /**
     * Create where clause with survey Ids for main query of SurveyVersion object
     */
    private void createSurveyIdsWhereClause(Set<Id> surveyIds) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardInWhereClause(
                SurveyVersion__c.Survey__c,
                SObjectSelector.IN_OPERATOR,
                surveyIds
            )
        );
    }
}
