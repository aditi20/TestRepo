<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>SetPublishedDate</fullName>
        <description>Set current date when Job Status is Published.</description>
        <field>PublishedDate__c</field>
        <formula>TODAY()</formula>
        <name>Set Published Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Publish Job Template</fullName>
        <actions>
            <name>SetPublishedDate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>JobTemplate__c.Status__c</field>
            <operation>equals</operation>
            <value>Published</value>
        </criteriaItems>
        <criteriaItems>
            <field>JobTemplate__c.PublishedDate__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>If status is Published set published current date.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
