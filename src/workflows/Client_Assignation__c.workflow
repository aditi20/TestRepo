<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Fill_Assignation_field</fullName>
        <description>Fill the field with the concatenation of Client__c and Mobile_User__c</description>
        <field>Assignation__c</field>
        <formula>Client__c  &amp;  Mobile_User__c</formula>
        <name>Fill Assignation field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Repeated_Assignation</fullName>
        <actions>
            <name>Fill_Assignation_field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Client_Assignation__c.Assignation__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>