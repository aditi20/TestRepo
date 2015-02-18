<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UpdatePerformanceTarget</fullName>
        <description>Set the performance target end date to the end of the next period</description>
        <field>EndDate__c</field>
        <formula>
            IF(
                ISPICKVAL(Timeframe__c, 'Weekly'),
                EndDate__c + 7,
                DATE(
                    IF(
                        MONTH( EndDate__c ) > 10,
                        YEAR( EndDate__c ) + 1,
                        YEAR( EndDate__c )
                    ),
                    IF(
                        MONTH(EndDate__c) = 10,
                        12,
                        MOD(MONTH(EndDate__c ) + 2, 12)
                    ),
                    1
                ) - 1
            )
        </formula>
        <name>Update Performance Target</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
