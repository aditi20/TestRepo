/**
 * Selector class for the User object
 *
 * (c) Copyright 2014 Grameen Foundation USA. All rights reserved
 *
 * @author Kaushik Ray
 */
public with sharing class UserSelector extends SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return User.sObjectType;
    }

    public List<Schema.SObjectField> getDefaultSelectFields() {
        return new List<Schema.SObjectField>{
            User.Id,
            User.Name,
            User.Email
        };
    }

    public String pathToJobFiltering() {
        return null;
    }

    /**
     * Get user list based on profile value passed
     */
    public List<User> getForProfile(String profileName) {
        createProfileWhereClause(profileName);
        return (List<User>) runSoqlQuery(SObjectSelector.AND_OPERATOR, null);
    }

    /**
     * Method to add where clause for Profile
     */
    private void createProfileWhereClause(String profileName) {
        this.addToMainWhereClause(
            this.getMainQueryBuilder().generateStandardWhereClause(
                this.getMainQueryBuilder().generateLookUp(
                    new List<Schema.SObjectField> {
                        User.ProfileId,
                        Profile.Name
                    }
                ),
                SObjectSelector.EQUALS_OPERATOR,
                profileName
            )
        );
    }
}