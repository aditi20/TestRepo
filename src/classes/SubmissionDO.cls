/**
 * Helper class that contains shared methods for submissions
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 */
public with sharing class SubmissionDO {

    public static final String SEPARATOR = ':';

    public class SubmissionException extends BaseException {}

    /**
     * Find and add the latest group that the surveyor joined to the Submission
     *
     * @param submissions - A list of the submissions to be processed
     *
     * @return - The submissions with the Assignment__c added to it
     */
    public static List<Submission__c> linkSubmissionsAssignmentGroups(List<Submission__c> submissions) {

        // Get the latest assignment for each survey:contact pair in the submissions
        SubmissionAssigner sa = new SubmissionAssigner();
        Map<String,Id> assignments = sa.getAssignments(submissions);
        if (!assignments.isEmpty()) {

            // Go through the submission map and add all the assignment groups to the submissions
            for (Submission__c submission : submissions) {
                sa.populateAssignment(submission, assignments);
            }
        }

        return submissions;
    }

    /**
     * Get the Submission PPI Values for the given submissions
     */
    public static Map<Id, List<SubmissionPPIValue__c>> getSubmissionsPPIValues(
            List<Submission__c> submissions
    ) {
        Map<Id, List<SubmissionPPIValue__c>> ppiValuesBySubmission =
                new Map<Id, List<SubmissionPPIValue__c>>();
        GenericObjectCreator ppiTableLineCreator =
            new GenericObjectCreator(PPITableLine__c.SObjectType);
        ppiTableLineCreator.checkObjectAccessible();
        ppiTableLineCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            PPITableLine__c.Probability__c,
            PPITableLine__c.PPITableDataSet__c
        });

        GenericObjectCreator submissionPpiValueCreator =
            new GenericObjectCreator(SubmissionPPIValue__c.SObjectType);
        submissionPpiValueCreator.checkObjectAccessible();
        submissionPpiValueCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
            SubmissionPPIValue__c.PPITableLine__c,
            SubmissionPPIValue__c.Submission__c
        });

        for (SubmissionPPIValue__c ppiValue : [
                SELECT
                    Id,
                    Submission__c,
                    PPITableLine__c,
                    PPITableLine__r.Probability__c,
                    PPITableLine__r.PPITableDataSet__c
                FROM
                    SubmissionPPIValue__c
                WHERE
                    Submission__c IN :submissions
        ]) {
            List<SubmissionPPIValue__c> ppiValues =
                    ppiValuesBySubmission.get(ppiValue.Submission__c);

            if (ppiValues == null) {
                ppiValues = new List<SubmissionPPIValue__c>();
                ppiValuesBySubmission.put(ppiValue.Submission__c, ppiValues);
            }
            ppiValues.add(ppiValue);
        }

        return ppiValuesBySubmission;
    }

    /**
     * Get all submission Ppi associations for a specific List of submissions
     */
    public static Map<Id, List<SubmissionPpiAssociation__c>> getSubmissionPpiAssociations(
            List<Submission__c> submissions
    ) {
        Map<Id, List<SubmissionPpiAssociation__c>> ppiAssociationsBySubmission =
            new Map<Id, List<SubmissionPpiAssociation__c>>();
        Set<Id> submissionIds = new Map<Id, Submission__c>(submissions).keySet();
        for (
                SubmissionPpiAssociation__c submissionPpiAssociation :
                    new SubmissionPpiAssociationSelector().getForSubmissionIds(submissionIds)
        ) {
            if (submissionPpiAssociation.Submission__c != null) {
                if (!ppiAssociationsBySubmission.containsKey(submissionPpiAssociation.Submission__c)) {
                    ppiAssociationsBySubmission.put(
                        submissionPpiAssociation.Submission__c,
                        new List<SubmissionPpiAssociation__c> {submissionPpiAssociation}
                    );
                } else {
                    List<SubmissionPpiAssociation__c> submissionPpiAssciations =
                        ppiAssociationsBySubmission.get(
                            submissionPpiAssociation.Submission__c
                        );
                    submissionPpiAssciations.add(submissionPpiAssociation);
                    ppiAssociationsBySubmission.put(
                        submissionPpiAssociation.Submission__c,
                        submissionPpiAssciations
                    );
                }
            }
        }
        return ppiAssociationsBySubmission;
    }

    /**
     * Helper class to get all assignments in the system regardless record sharing,
     * and to link submissions to their right assignment.
     */
    private without sharing class SubmissionAssigner {

        /**
         * Get all assignments for the surveys and surveyors of the given list of submissions.
         * @param submissions the list of submissions to assign
         * @return a map from 'SurveyId:ContactId' to AssignmentId, where the assignment is the
         * last assignment for that contact in that survey
         */
        public Map<String,Id> getAssignments(List<Submission__c> submissions) {

            // Get lists of contacts and surveys to consider
            Set<Id> surveyorIds = new Set<Id>();
            Set<Id> surveyIds   = new Set<Id>();
            for (Submission__c submission : submissions){
                surveyorIds.add(submission.Surveyor__c);
                surveyIds.add(submission.Survey__c);
            }

            GenericObjectCreator contactGroupCreator =
                new GenericObjectCreator(ContactGroup__c.SObjectType);
            contactGroupCreator.checkObjectAccessible();
            GenericObjectCreator contactGroupSurveyAssignmentCreator =
                new GenericObjectCreator(ContactGroupSurveyAssignment__c.SObjectType);
            contactGroupSurveyAssignmentCreator.checkObjectAccessible();
            contactGroupSurveyAssignmentCreator.checkFieldsAccessible(
                new List<Schema.SObjectField> {
                    ContactGroupSurveyAssignment__c.Survey__c
                }
            );
            GenericObjectCreator contactGroupMemberCreator =
                new GenericObjectCreator(ContactGroupMember__c.SObjectType);
            contactGroupMemberCreator.checkObjectAccessible();
            contactGroupMemberCreator.checkFieldsAccessible(new List<Schema.SObjectField> {
                ContactGroupMember__c.Contact__c
            });

            // Create the map
            Map<String,Id> assignments = new Map<String,Id>();
            for (ContactGroup__c cgroup : [
                    SELECT
                        Id,
                        (
                            SELECT
                                Id,
                                Contact__c
                            FROM
                                Contact_Group_Assignments__r
                            WHERE
                                Contact__c IN :surveyorIds
                                ORDER BY LastModifiedDate ASC
                        ),
                        (
                            SELECT
                                Id,
                                Survey__c
                            FROM
                                ContactGroupSurveyAssignment__r
                            WHERE
                                Survey__c IN :surveyIds
                        )
                    FROM
                        ContactGroup__c
                    WHERE
                        Status__c = :C.GROUP_STATUS_ACTIVE
                ]
            ) {

                // Create an entry on the map for each survey:contact pair (newer pairs overwrite old pairs)
                for (ContactGroupSurveyAssignment__c assignment : cgroup.ContactGroupSurveyAssignment__r){
                    for (ContactGroupMember__c member : cgroup.Contact_Group_Assignments__r){
                        String assignmentKey = assignment.Survey__c + SEPARATOR + member.Contact__c;
                        assignments.put(assignmentKey, assignment.Id);
                    }
                }
            }

            return assignments;
        }

        /**
         * Associates to the submission the corresponding assignment from the list.
         * @param submission the Submission__c object that will be associated to an assignment.
         * @param assignments a map from 'SurveyId:ContactId' to AssignmentId, where the assignment is the
         * last assignment for that contact in that survey
         */
        private void populateAssignment(Submission__c submission, Map<String,Id> assignments) {
            GenericObjectCreator submissionCreator =
                new GenericObjectCreator(Submission__c.SObjectType);
            String assignmentKey = submission.Survey__c + SEPARATOR + submission.Surveyor__c;
            submissionCreator.populateFields(
                submission,
                new Map<Schema.SObjectField, Object> {
                    Submission__c.Assignment__c => assignments.get(assignmentKey)
                }
            );
        }

    }
}
