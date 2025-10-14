/*============================================================================
File: 06_AlwaysOn_health.sql
Author: Taiob Ali
Email: taiob@sqlworlwide.com
Bluesky: https://bsky.app/profile/sqlworldwide.bsky.social
Blog: https://sqlworldwide.com/
LinkedIn: https://www.linkedin.com/in/sqlworldwide/

Last Modified: October 08, 2025

Tested On:
	- SQL Server 2022 CU21
	- SSMS 21.5.14

Purpose: Explore selected Always On availability group events captured via Extended Events.

References:
 - https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/always-on-extended-events
 - https://www.sqlshack.com/monitor-sql-server-always-on-availability-groups-using-extended-events/
============================================================================*/

/*
Events captured in the AlwaysOn_health session (subset shown).
*/

SELECT 
	name, 
	description
FROM sys.dm_xe_objects
WHERE NAME IN (
	'alwayson_ddl_executed',
	'availability_group_lease_expired',
	'availability_replica_automatic_failover_validation',
	'availability_replica_manager_state_change',
	'availability_replica_state',
	'availability_replica_state_change',
	'error_reported',
	'hadr_db_partner_set_sync_state',
	'hadr_trace_message',
	'lock_redo_blocked'
) 

/*
Error message IDs of interest for Always On troubleshooting.
*/

SELECT 
	message_id, 
	[text] AS [Description]
FROM sys.messages AS m
WHERE m.language_id = SERVERPROPERTY('LCID')
    AND  (m.message_id=(9691)
        OR m.message_id=(35204)
        OR m.message_id=(9693)
        OR m.message_id=(26024)
        OR m.message_id=(28047)
        OR m.message_id=(26023)
        OR m.message_id=(9692)
        OR m.message_id=(28034)
        OR m.message_id=(28036)
        OR m.message_id=(28048)
        OR m.message_id=(28080)
        OR m.message_id=(28091)
        OR m.message_id=(26022)
        OR m.message_id=(9642)
        OR m.message_id=(35201)
        OR m.message_id=(35202)
        OR m.message_id=(35206)
        OR m.message_id=(35207)
        OR m.message_id=(26069)
        OR m.message_id=(26070)
        OR m.message_id>(41047)
        AND m.message_id<(41056)
        OR m.message_id=(41142)
        OR m.message_id=(41144)
        OR m.message_id=(1480)
        OR m.message_id=(823)
        OR m.message_id=(824)
        OR m.message_id=(829)
        OR m.message_id=(35264)
        OR m.message_id=(35265)
				OR m.message_id=(41188)
				OR m.message_id=(41189) 
				OR m.message_id=(35217)
) 
ORDER BY message_id

/*
Inspect specific error_reported events for selected error numbers.
*/

DECLARE @FileName NVARCHAR(4000)
SELECT @FileName ='C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Log\AlwaysOn_health_0_133660743036950000.xel'

SELECT
  XEData.value('(event/@timestamp)[1]','datetime2(3)') AS event_timestamp,
  XEData.value('(event/data[@name="error_number"]/value)[1]', 'int') AS error_number,
  XEData.value('(event/data[@name="message"]/value)[1]', 'varchar(max)') AS message
FROM (
        SELECT CAST(event_data AS XML) XEData, *
        FROM sys.fn_xe_file_target_read_file(@FileName, NULL, NULL, NULL)
        WHERE object_name = 'error_reported'
        ) event_data
WHERE XEData.value('(event/data[@name="error_number"]/value)[1]', 'int')  
	IN ( 41052, 41052, 41053, 41054)
ORDER BY event_timestamp DESC;

/*
Inspect availability_replica_state_change events (AG and replica names masked).
*/

DECLARE @FileName1 NVARCHAR(4000)
SELECT @FileName1 ='C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Log\AlwaysOn_health_0_133660743036950000.xel'

SELECT
  XEData.value('(event/@timestamp)[1]','datetime2(3)') AS event_timestamp,
  XEData.value('(event/data[@name="previous_state"]/text)[1]', 'varchar(max)') AS previousState,
	XEData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(max)') AS currentState,
	--XEData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(max)') AS AG_GroupName,
	--XEData.value('(event/data[@name="availability_replica_name"]/value)[1]', 'varchar(max)') AS AG_ReplicaName
	'SQLNESQLAG_Group' AS AG_GroupName,
	'SQLNESQLReplica' AS AG_ReplicaName
FROM (
        SELECT CAST(event_data AS XML) XEData, *
        FROM sys.fn_xe_file_target_read_file(@FileName1, NULL, NULL, NULL)
        WHERE object_name = 'availability_replica_state_change'
        ) event_data
ORDER BY event_timestamp DESC;

/*
Inspect availability_replica_state events (AG name masked).
*/

DECLARE @FileName2 NVARCHAR(4000)
SELECT @FileName2 ='C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Log\AlwaysOn_health_0_133660743036950000.xel'

SELECT
  XEData.value('(event/@timestamp)[1]','datetime2(3)') AS event_timestamp,
  XEData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(max)') AS currentState,
	--XEData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(max)') AS AG_GroupName,
	'SQLNESQLAG_Group' AS AG_GroupName
FROM (
        SELECT CAST(event_data AS XML) XEData, *
        FROM sys.fn_xe_file_target_read_file(@FileName2, NULL, NULL, NULL)
        WHERE object_name = 'availability_replica_state'
        ) event_data
ORDER BY event_timestamp DESC;


/*
Inspect availability_replica_manager_state_change events.
*/

DECLARE @FileName3 NVARCHAR(4000)
SELECT @FileName3 ='C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Log\AlwaysOn_health_0_133660743036950000.xel'

SELECT
  XEData.value('(event/@timestamp)[1]','datetime2(3)') AS event_timestamp,
  XEData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(max)') AS previousState
FROM (
        SELECT CAST(event_data AS XML) XEData, *
        FROM sys.fn_xe_file_target_read_file(@FileName3, NULL, NULL, NULL)
        WHERE object_name = 'availability_replica_manager_state_change'
        ) event_data
ORDER BY event_timestamp DESC;