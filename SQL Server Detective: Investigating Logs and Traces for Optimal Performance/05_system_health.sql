/*============================================================================
File: 05_system_health.sql
Author: Taiob Ali
Email: taiob@sqlworlwide.com
Bluesky: https://bsky.app/profile/sqlworldwide.bsky.social
Blog: https://sqlworldwide.com/
LinkedIn: https://www.linkedin.com/in/sqlworldwide/

Last Modified: October 08, 2025

Tested On:
	- SQL Server 2022 CU21
	- SSMS 21.5.14

Purpose: Explore data captured by the system_health Extended Events session.
============================================================================*/

/*
NOTE: Earlier I reduced the flush interval so data appears faster during the demo.
	Do NOT change this setting in production unless you understand the impact.
*/

/*
Events captured by system_health.
*/

SELECT 
	name, 
	description
FROM sys.dm_xe_objects
WHERE NAME IN (
	'clr_allocation_failure',
	'clr_virtual_alloc_failure',
	'memory_broker_ring_buffer_recorded',
	'memory_node_oom_ring_buffer_recorded',
	'scheduler_monitor_deadlock_ring_buffer_recorded',
	'scheduler_monitor_non_yielding_iocp_ring_buffer_recorded',
	'scheduler_monitor_non_yielding_ring_buffer_recorded',
	'scheduler_monitor_non_yielding_rm_ring_buffer_recorded',
	'scheduler_monitor_stalled_dispatcher_ring_buffer_recorded',
	'scheduler_monitor_system_health_ring_buffer_recorded',
	'wait_info',
	'wait_info_external',
	'connectivity_ring_buffer_recorded',
	'job_object_ring_buffer_stats',
	'nonyield_copiedstack_ring_buffer_recorded',
	'security_error_ring_buffer_recorded',
	'sp_server_diagnostics_component_result',
	'xml_deadlock_report'
) 

/*
What error messages are being tracked
*/

SELECT 
	message_id, 
	[text] AS [Description]
FROM sys.messages AS m
WHERE m.language_id = SERVERPROPERTY('LCID')
	AND (m.message_id=(17803)
  OR m.message_id=(701)
  OR m.message_id=(802)
	OR m.message_id=(8645)
	OR m.message_id=(8651)
	OR m.message_id=(8657)
	OR m.message_id=(8902)
	OR m.message_id=(41354)
	OR m.message_id=(41355)
	OR m.message_id=(41367)
	OR m.message_id=(41384)
	OR m.message_id=(41336)
	OR m.message_id=(41309)
	OR m.message_id=(41312)
	OR m.message_id=(41313)
) 

/*
Generate a severity 20 error and force it into the error log.
*/

RAISERROR (N'This is message %s %d.', -- Message text.
	20, -- Severity,
	1, -- State,
	N'number', -- First argument.
	5) WITH LOG; -- Second argument.

/*
Find details about the above error
*/

DECLARE @latestFileName NVARCHAR(MAX) 
SET @latestFileName =
(SELECT  
	CAST(target_data AS XML).value('(EventFileTarget/File/@name)[1]', 'NVARCHAR(256)') 
FROM sys.dm_xe_sessions AS s
INNER JOIN sys.dm_xe_session_targets AS t
ON s.address = t.event_session_address
WHERE s.name = 'system_health'
AND t.target_name = 'event_file'
)

SELECT 
  XEventData.xml_data.value('(/event/@name)[1]', 'varchar(max)') AS [Name],
  XEventData.xml_data.value('(/event/@timestamp)[1]', 'datetime') AS [timeLogged],
	XEventData.xml_data.value ('(/event/data[@name="error_number"]/value)[1]', 'int') AS [errorNumber],
	XEventData.xml_data.value ('(/event/data[@name="severity"]/value)[1]', 'int') AS [serverity],
	XEventData.xml_data.value ('(/event/data[@name="message"]/value)[1]', 'varchar(max)') AS [message],
	XEventData.xml_data.value ('(/event/data[@name="message"]/value)[1]', 'varchar(max)') AS [message],
	XEventData.xml_data.value('(/event/action[@name="sql_text"]/value)[1]', 'varchar(max)') AS [sqlText],
	XEventData.xml_data.value('(/event/action[@name="database_id"]/value)[1]', 'int') AS [databaseId],
	XEventData.xml_data.value('(/event/action[@name="session_id"]/value)[1]', 'int') AS [sessionId],
	XEventData.xml_data
FROM (
    SELECT object_name AS event,
			CONVERT(XML, event_data) AS xml_data
    FROM sys.fn_xe_file_target_read_file(@latestFileName, NULL, NULL, NULL)
		WHERE object_name='error_reported'
) AS XEventData
ORDER BY timeLogged DESC;


/*
Create a deadlock scenario.
*/

USE SqlDetective;
GO

DROP TABLE IF EXISTS dbo.dt_Employees;
GO
CREATE TABLE dbo.dt_Employees (
    EmpId INT IDENTITY,
    EmpName VARCHAR(16),
    Phone VARCHAR(16)
);
GO
INSERT INTO dbo.dt_Employees (EmpName, Phone)
VALUES ('Martha', '800-555-1212'), ('Jimmy', '619-555-8080');
GO
DROP TABLE IF EXISTS dbo.dt_Suppliers;
GO
CREATE TABLE dbo.dt_Suppliers(
    SupplierId INT IDENTITY,
    SupplierName VARCHAR(64),
    Fax VARCHAR(16)
);
GO
INSERT INTO dbo.dt_Suppliers (SupplierName, Fax)
VALUES ('Acme', '877-555-6060'), ('Rockwell', '800-257-1234');
GO

/*
Run this in the current window (Session 1).
*/

BEGIN TRAN;
UPDATE dbo.dt_Employees
SET EmpName = 'Mary'
WHERE EmpId = 1;

/*
Open another session (Session 2) and run this block.
*/

BEGIN TRAN;
UPDATE dbo.dt_Suppliers
SET Fax = N'555-1212'
WHERE SupplierId = 1;

UPDATE dbo.dt_Employees
SET Phone = N'555-9999'
WHERE EmpId = 1;

--COMMIT TRAN;
/*
Return to Session 1 and continue.
*/

UPDATE dbo.dt_Suppliers
SET Fax = N'555-1212'
WHERE SupplierId = 1;

/*
One session will receive a deadlock error.
Commit and clean up.
*/
COMMIT TRAN;

DROP TABLE IF EXISTS dbo.dt_Suppliers;
DROP TABLE IF EXISTS dbo.dt_Employees;
GO

/*
Retrieve details of the deadlock from system_health.
*/


/*
Parse the deadlock XML to extract session IDs, victim/winner, statements, and lock details.
*/
DECLARE @latestFileName nvarchar(260);

SELECT @latestFileName =
    CAST(t.target_data AS xml).value('(EventFileTarget/File/@name)[1]', 'nvarchar(260)')
FROM sys.dm_xe_sessions s
	JOIN sys.dm_xe_session_targets t
	ON s.address = t.event_session_address
WHERE s.name = 'system_health'
	AND t.target_name = 'event_file';

IF @latestFileName IS NULL
BEGIN
	RAISERROR('system_health event file not found.', 16, 1);
	RETURN;
END;

;
WITH
	RawEvents
	AS
	(
		SELECT CAST(event_data AS xml) AS event_xml
		FROM sys.fn_xe_file_target_read_file(@latestFileName, NULL, NULL, NULL)
		WHERE object_name = 'xml_deadlock_report'
	),
	DeadlockRoots
	AS
	(
		-- Get each raw payload (could be <deadlock> or <deadlock-list>)
		SELECT event_xml.value('(event/@timestamp)[1]', 'datetime2') AS UtcTime,
			event_xml.query('(event/data[@name="xml_report"]/value/*)[1]') AS PayloadXML
		FROM RawEvents
	),
	EachDeadlock
	AS
	(
		-- Single deadlock root
					SELECT UtcTime,
				PayloadXML.query('/deadlock') AS DeadlockXML
			FROM DeadlockRoots
			WHERE PayloadXML.exist('/deadlock') = 1
		UNION ALL
			-- Multiple deadlocks under deadlock-list
			SELECT UtcTime,
				DL.query('.') AS DeadlockXML
			FROM DeadlockRoots
    CROSS APPLY PayloadXML.nodes('/deadlock-list/deadlock') AS D(DL)
	),
	Parsed
	AS
	(
		SELECT
			UtcTime,
			DeadlockXML.value('(//victim-list/victimProcess/@id)[1]', 'varchar(60)') AS VictimProcessId,
			DeadlockXML
		FROM EachDeadlock
	)
SELECT
	p.UtcTime,
	p.VictimProcessId,
	pn.value('@id','varchar(60)')              AS ProcessId,
	pn.value('@spid','int')                   AS SessionId,
	CASE WHEN pn.value('@id','varchar(60)') = p.VictimProcessId THEN 1 ELSE 0 END AS IsVictim,
	pn.value('(./inputbuf/text())[1]','nvarchar(max)') AS InputBuffer,
	rn.value('local-name(.)','sysname')       AS ResourceType,
	rn.value('@mode','varchar(10)')           AS LockMode,
	rn.value('@objectname','nvarchar(256)')   AS ObjectName,
	rn.value('@dbid','int')                   AS DatabaseId
FROM Parsed p
CROSS APPLY p.DeadlockXML.nodes('/deadlock/process-list/process') AS ProcNodes(pn)
OUTER APPLY p.DeadlockXML.nodes('/deadlock/resource-list/*')      AS ResNodes(rn)
ORDER BY p.UtcTime DESC;
GO

/*
Simulate a wait > 30 seconds (blocking scenario).
*/

USE SqlDetective;
GO

DROP TABLE IF EXISTS dbo.dt_Employees;
GO
CREATE TABLE dbo.dt_Employees (
    EmpId INT IDENTITY,
    EmpName VARCHAR(16),
    Phone VARCHAR(16)
);
GO
INSERT INTO dbo.dt_Employees (EmpName, Phone)
VALUES ('Martha', '800-555-1212'), ('Jimmy', '619-555-8080');
GO
DROP TABLE IF EXISTS dbo.dt_Suppliers;
GO
CREATE TABLE dbo.dt_Suppliers(
    SupplierId INT IDENTITY,
    SupplierName VARCHAR(64),
    Fax VARCHAR(16)
);
GO
INSERT INTO dbo.dt_Suppliers (SupplierName, Fax)
VALUES ('Acme', '877-555-6060'), ('Rockwell', '800-257-1234');
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRAN
SELECT 
	*
FROM dbo.dt_Suppliers WITH (XLOCK)
--COMMIT TRAN

/*
In another session, run (let it block for at least 30 seconds):
	USE SqlDetective;
	UPDATE dbo.dt_Suppliers
	SET SupplierName = 'Acme111'
	WHERE SupplierId = 1;

Find blocked sessions
SELECT 
  session_id,
  status,
  blocking_session_id,
  wait_type,
  wait_time,
  wait_resource,
  transaction_id
FROM sys.dm_exec_requests
WHERE status = N'suspended';
GO
*/

/*
Inspect details of the blocking wait.
LCK_M_U: Waiting to acquire an Update lock while another incompatible lock is held.
*/

DECLARE @latestFileName NVARCHAR(MAX) 
SET @latestFileName =
(SELECT  
	CAST(target_data AS XML).value('(EventFileTarget/File/@name)[1]', 'NVARCHAR(256)') 
FROM sys.dm_xe_sessions AS s
INNER JOIN sys.dm_xe_session_targets AS t
ON s.address = t.event_session_address
WHERE s.name = 'system_health'
AND t.target_name = 'event_file')

SELECT 
  xml_data.value('(/event/@name)[1]', 'varchar(max)') AS [name],
  xml_data.value('(/event/@package)[1]', 'varchar(max)') AS [package],
  xml_data.value('(/event/@timestamp)[1]', 'datetime') AS [timeLogged],
	XEventData.xml_data
FROM (
    SELECT object_name AS event,
        CONVERT(XML, event_data) AS xml_data
    FROM sys.fn_xe_file_target_read_file(@latestFileName, NULL, NULL, NULL)
		WHERE object_name IN ('wait_info')
) AS XEventData
ORDER BY timeLogged DESC;
GO


/*
sp_server_diagnostics
Captures diagnostic data and health information about SQL Server to detect potential failures. The procedure runs in repeat mode and sends results periodically. It can be invoked from either a regular connection, or a dedicated admin connection.

Reference: https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-server-diagnostics-transact-sql
The output is saved in system_health periodically (default every 5 minutes).
You can also invoke it manually to inspect current state.

Load scenario suggestion (SQLQueryStress):
	Database: WideWorldImporters
	EXEC Warehouse.GetStockItemsbySupplier 4
	Iterations: 75
	Threads: 5
*/

EXEC sys.sp_server_diagnostics;
GO

USE SqlDetective;
GO
DROP TABLE IF EXISTS dbo.SpServerDiagnosticsResult;
GO
CREATE TABLE dbo.SpServerDiagnosticsResult (
    create_time DATETIME,
    component_type SYSNAME,
    component_name SYSNAME,
    [state] INT,
    state_desc SYSNAME,
    [data] XML
);

USE SqlDetective;
GO
INSERT INTO SpServerDiagnosticsResult
EXEC sp_server_diagnostics;
GO

SELECT 
	*
FROM SpServerDiagnosticsResult;
GO

/*
System component metrics.
*/

SELECT 
	data.value('(/system/@systemCpuUtilization)[1]', 'bigint') AS 'System_CPU',
  data.value('(/system/@sqlCpuUtilization)[1]', 'bigint') AS 'SQL_CPU',
  data.value('(/system/@nonYieldingTasksReported)[1]', 'bigint') AS 'NonYielding_Tasks',
  data.value('(/system/@pageFaults)[1]', 'bigint') AS 'Page_Faults',
  data.value('(/system/@latchWarnings)[1]', 'bigint') AS 'Latch_Warnings',
  data.value('(/system/@BadPagesDetected)[1]', 'bigint') AS 'BadPages_Detected',
  data.value('(/system/@BadPagesFixed)[1]', 'bigint') AS 'BadPages_Fixed'
FROM SpServerDiagnosticsResult
WHERE component_name LIKE 'system'
GO

/*
Resource Monitor memory report details.
*/
SELECT 
	data.value('(./Record/ResourceMonitor/Notification)[1]', 'VARCHAR(max)') AS [Notification],
	data.value('(/resource/memoryReport/entry[@description=''Working Set'']/@value)[1]', 'bigint') / 1024 AS [SQL_Mem_in_use_MB],
	data.value('(/resource/memoryReport/entry[@description=''Available Paging File'']/@value)[1]', 'bigint') / 1024 AS [Avail_Pagefile_MB],
	data.value('(/resource/memoryReport/entry[@description=''Available Physical Memory'']/@value)[1]', 'bigint') / 1024 AS [Avail_Physical_Mem_MB],
	data.value('(/resource/memoryReport/entry[@description=''Available Virtual Memory'']/@value)[1]', 'bigint') / 1024 AS [Avail_VAS_MB],
	data.value('(/resource/@lastNotification)[1]', 'varchar(100)') AS 'LastNotification',
	data.value('(/resource/@outOfMemoryExceptions)[1]', 'bigint') AS 'OOM_Exceptions'
FROM SpServerDiagnosticsResult
WHERE component_name LIKE 'resource'
GO

/*
Non-preemptive (cooperative) waits: Threads voluntarily yield based on SQL Server scheduling.
*/

SELECT 
	waits.evt.value('(@waitType)', 'varchar(100)') AS 'Wait_Type',
  waits.evt.value('(@waits)', 'bigint') AS 'Waits',
  waits.evt.value('(@averageWaitTime)', 'bigint') AS 'Avg_Wait_Time',
  waits.evt.value('(@maxWaitTime)', 'bigint') AS 'Max_Wait_Time'
FROM SpServerDiagnosticsResult
CROSS APPLY data.nodes('/queryProcessing/topWaits/nonPreemptive/byDuration/wait') AS waits(evt)
WHERE component_name LIKE 'query_processing';
GO

/*
Preemptive (non-cooperative) waits: SQL Server yields execution to the OS for higher-priority tasks.
*/

SELECT 
	waits.evt.value('(@waitType)', 'varchar(100)') AS 'Wait_Type',
  waits.evt.value('(@waits)', 'bigint') AS 'Waits',
  waits.evt.value('(@averageWaitTime)', 'bigint') AS 'Avg_Wait_Time',
  waits.evt.value('(@maxWaitTime)', 'bigint') AS 'Max_Wait_Time'
FROM SpServerDiagnosticsResult
CROSS APPLY data.nodes('/queryProcessing/topWaits/preemptive/byDuration/wait') AS waits(evt)
WHERE component_name LIKE 'query_processing';
GO

/*
CPU-intensive requests.
*/

SELECT 
	cpureq.evt.value('(@sessionId)', 'bigint') AS 'SessionID',
  cpureq.evt.value('(@command)', 'varchar(100)') AS 'Command',
  cpureq.evt.value('(@cpuUtilization)', 'bigint') AS 'CPU_Utilization',
  cpureq.evt.value('(@cpuTimeMs)', 'bigint') AS 'CPU_Time_ms'
FROM SpServerDiagnosticsResult
CROSS APPLY data.nodes('/queryProcessing/cpuIntensiveRequests/request') AS cpureq(evt)
WHERE component_name LIKE 'query_processing';
GO

/*
Blocked process report.
*/

SELECT 
	blk.evt.query('.') AS 'Blocked_Process_Report_XML'
FROM SpServerDiagnosticsResult
CROSS APPLY data.nodes('/queryProcessing/blockingTasks/blocked-process-report') AS blk(evt)
WHERE component_name LIKE 'query_processing';
GO

/*
I/O subsystem metrics.
*/

SELECT 
	data.value('(/ioSubsystem/@ioLatchTimeouts)[1]', 'bigint') AS 'Latch_Timeouts',
  data.value('(/ioSubsystem/@totalLongIos)[1]', 'bigint') AS 'Total_Long_IOs'
FROM SpServerDiagnosticsResult
WHERE component_name LIKE 'io_subsystem';
GO

/*
Miscellaneous Extended Events information.
*/

SELECT 
	xevts.evt.value('(@name)', 'varchar(100)') AS 'xEvent_Name',
  xevts.evt.value('(@package)', 'varchar(100)') AS 'Package',
  xevts.evt.value('(@timestamp)', 'datetime') AS 'xEvent_Time',
  xevts.evt.query('.') AS 'Event Data'
FROM SpServerDiagnosticsResult
CROSS APPLY data.nodes('/events/session/RingBufferTarget/event') AS xevts(evt)
WHERE component_name LIKE 'events'
ORDER BY xEvent_Name DESC;
GO