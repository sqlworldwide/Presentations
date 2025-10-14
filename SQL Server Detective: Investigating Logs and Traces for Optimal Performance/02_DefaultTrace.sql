/*============================================================================
File: 02_DefaultTrace.sql
Author: Taiob Ali
Email: taiob@sqlworlwide.com
Bluesky: https://bsky.app/profile/sqlworldwide.bsky.social
Blog: https://sqlworldwide.com/
LinkedIn: https://www.linkedin.com/in/sqlworldwide/

Last Modified: October 08, 2025

Tested On:
	- SQL Server 2022 CU21
	- SSMS 21.5.14

References:
- https://www.red-gate.com/simple-talk/databases/sql-server/performance-sql-server/the-default-trace-in-sql-server-the-power-of-performance-and-security-auditing/
- https://www.mssqltips.com/sqlservertip/1739/using-the-default-trace-in-sql-server/
- https://www.mssqltips.com/sqlservertip/3445/using-the-sql-server-default-trace-to-audit-events/
============================================================================*/
/*
Check whether the default trace is running.
*/

SELECT 
	configuration_id,
  name,
  value,
  minimum,
  maximum,
  value_in_use,
  description,
  is_dynamic,
  is_advanced 
FROM sys.configurations 
WHERE configuration_id = 1568;
GO

/*
Display properties of the default trace.
*/

SELECT 
	id,
  status,
  path,
  max_size,
  stop_time,
  max_files,
  is_rowset,
  is_rollover,
  is_shutdown,
  is_default,
  buffer_count,
  buffer_size,
  file_position,
  reader_spid,
  start_time,
  last_event_time,
  event_count,
  dropped_event_count 
FROM sys.traces 
WHERE is_default = 1;
GO

/*
List distinct event IDs and names captured (e.g., currently 34 events).
*/

DECLARE @id INT
SELECT @id=id FROM sys.traces WHERE is_default = 1

SELECT 
	DISTINCT ei.eventid, 
	te.name 
FROM  sys.fn_trace_geteventinfo(@id) AS ei
JOIN sys.trace_events AS te 
ON ei.eventid = te.trace_event_id;
GO

/*
Example: Database event (data file auto-growth).
*/

SELECT  
	TE.name AS [EventName] ,
  T.DatabaseName ,
  t.DatabaseID ,
  t.ApplicationName ,
  t.LoginName ,
  t.SPID ,
  t.Duration ,
  t.StartTime ,
  t.EndTime
FROM sys.fn_trace_gettable(CONVERT(VARCHAR(150), 
	( SELECT TOP (1)
			f.[value]
    FROM sys.fn_trace_getinfo(NULL) f
    WHERE f.property = 2
  )), DEFAULT) T
JOIN sys.trace_events TE 
ON T.EventClass = TE.trace_event_id
WHERE te.name = 'Data File Auto Grow'
ORDER BY t.StartTime; 

/*
Errors and Warnings: Entries written to the application log (source: MSSQLSERVER).
*/

SELECT  
	TE.name AS [EventName] ,
  T.DatabaseName ,
  t.DatabaseID ,
  t.ApplicationName ,
  t.LoginName ,
  t.SPID ,
  t.StartTime ,
  t.TextData ,
  t.Severity ,
  t.Error
FROM sys.fn_trace_gettable(CONVERT(VARCHAR(150), 
	( SELECT TOP (1)
			f.[value]
    FROM sys.fn_trace_getinfo(NULL) f
    WHERE f.property = 2
  )), DEFAULT) T
JOIN sys.trace_events TE 
ON T.EventClass = TE.trace_event_id
WHERE te.name = 'ErrorLog'
GO

/*
Errors and Warnings: Sort warnings.
*/

SELECT TOP(50)
	TE.name AS [EventName] ,
  v.subclass_name ,
  T.DatabaseName ,
  t.DatabaseID ,
  t.ApplicationName ,
  t.LoginName ,
  t.SPID ,
  t.StartTime
FROM sys.fn_trace_gettable(CONVERT(VARCHAR(150), 
	( SELECT TOP (1)
			f.[value]
    FROM sys.fn_trace_getinfo(NULL) f
    WHERE f.property = 2
  )), DEFAULT) T
JOIN sys.trace_events TE 
ON T.EventClass = TE.trace_event_id
JOIN sys.trace_subclass_values v 
ON v.trace_event_id = TE.trace_event_id AND v.subclass_value = t.EventSubClass
WHERE te.name = 'Sort Warnings'
ORDER BY t.StartTime DESC;
GO

/*
Object events: Created.
*/

SELECT  
	TE.name ,
  v.subclass_name ,
  DB_NAME(t.DatabaseId) AS DBName ,
	t.StartTime ,
  t.ObjectName ,
  CASE t.ObjectType
    WHEN 8259 THEN 'Check Constraint'
    WHEN 8260 THEN 'Default (constraint or standalone)'
    WHEN 8262 THEN 'Foreign-key Constraint'
    WHEN 8272 THEN 'Stored Procedure'
    WHEN 8274 THEN 'Rule'
    WHEN 8275 THEN 'System Table'
    WHEN 8276 THEN 'Trigger on Server'
    WHEN 8277 THEN '(User-defined) Table'
    WHEN 8278 THEN 'View'
    WHEN 8280 THEN 'Extended Stored Procedure'
    WHEN 16724 THEN 'CLR Trigger'
    WHEN 16964 THEN 'Database'
    WHEN 16975 THEN 'Object'
    WHEN 17222 THEN 'FullText Catalog'
    WHEN 17232 THEN 'CLR Stored Procedure'
    WHEN 17235 THEN 'Schema'
    WHEN 17475 THEN 'Credential'
    WHEN 17491 THEN 'DDL Event'
    WHEN 17741 THEN 'Management Event'
    WHEN 17747 THEN 'Security Event'
    WHEN 17749 THEN 'User Event'
    WHEN 17985 THEN 'CLR Aggregate Function'
    WHEN 17993 THEN 'Inline Table-valued SQL Function'
    WHEN 18000 THEN 'Partition Function'
    WHEN 18002 THEN 'Replication Filter Procedure'
    WHEN 18004 THEN 'Table-valued SQL Function'
    WHEN 18259 THEN 'Server Role'
    WHEN 18263 THEN 'Microsoft Windows Group'
    WHEN 19265 THEN 'Asymmetric Key'
    WHEN 19277 THEN 'Master Key'
    WHEN 19280 THEN 'Primary Key'
    WHEN 19283 THEN 'ObfusKey'
    WHEN 19521 THEN 'Asymmetric Key Login'
    WHEN 19523 THEN 'Certificate Login'
    WHEN 19538 THEN 'Role'
    WHEN 19539 THEN 'SQL Login'
    WHEN 19543 THEN 'Windows Login'
    WHEN 20034 THEN 'Remote Service Binding'
    WHEN 20036 THEN 'Event Notification on Database'
    WHEN 20037 THEN 'Event Notification'
    WHEN 20038 THEN 'Scalar SQL Function'
    WHEN 20047 THEN 'Event Notification on Object'
    WHEN 20051 THEN 'Synonym'
    WHEN 20549 THEN 'End Point'
    WHEN 20801 THEN 'Adhoc Queries which may be cached'
    WHEN 20816 THEN 'Prepared Queries which may be cached'
    WHEN 20819 THEN 'Service Broker Service Queue'
    WHEN 20821 THEN 'Unique Constraint'
    WHEN 21057 THEN 'Application Role'
    WHEN 21059 THEN 'Certificate'
    WHEN 21075 THEN 'Server'
    WHEN 21076 THEN 'Transact-SQL Trigger'
    WHEN 21313 THEN 'Assembly'
    WHEN 21318 THEN 'CLR Scalar Function'
    WHEN 21321 THEN 'Inline scalar SQL Function'
    WHEN 21328 THEN 'Partition Scheme'
    WHEN 21333 THEN 'User'
    WHEN 21571 THEN 'Service Broker Service Contract'
    WHEN 21572 THEN 'Trigger on Database'
    WHEN 21574 THEN 'CLR Table-valued Function'
    WHEN 21577
    THEN 'Internal Table (For example, XML Node Table, Queue Table.)'
    WHEN 21581 THEN 'Service Broker Message Type'
    WHEN 21586 THEN 'Service Broker Route'
    WHEN 21587 THEN 'Statistics'
    WHEN 21825 THEN 'User'
    WHEN 21827 THEN 'User'
    WHEN 21831 THEN 'User'
    WHEN 21843 THEN 'User'
    WHEN 21847 THEN 'User'
    WHEN 22099 THEN 'Service Broker Service'
    WHEN 22601 THEN 'Index'
    WHEN 22604 THEN 'Certificate Login'
    WHEN 22611 THEN 'XMLSchema'
    WHEN 22868 THEN 'Type'
    ELSE 'Hmmm???'
  END AS ObjectType,
	t.ApplicationName ,
  t.LoginName
FROM sys.fn_trace_gettable(CONVERT(VARCHAR(150), 
	( SELECT TOP (1)
			f.[value]
    FROM sys.fn_trace_getinfo(NULL) f
    WHERE f.property = 2
  )), DEFAULT) T
JOIN sys.trace_events TE 
ON T.EventClass = TE.trace_event_id
JOIN sys.trace_subclass_values v 
ON v.trace_event_id = TE.trace_event_id AND v.subclass_value = t.EventSubClass
WHERE TE.name = 'Object:Created'
-- filter statistics created by SQL server                                         
AND t.ObjectType NOT IN ( 21587 )
-- filter tempdb objects
AND DatabaseID <> 2
-- get only events in the past 24 hours
AND StartTime > DATEADD(HH, -24, GETDATE())
ORDER BY t.StartTime DESC;
GO

/*
Test scenario: Attempt login with 'nesqldemo' using an incorrect password.

Security Audit Events of interest:
- Audit Addlogin Event
- Audit Login Failed
*/

SELECT  
	TE.name AS [EventName] ,
  v.subclass_name ,
  T.DatabaseName ,
  t.DatabaseID ,
  t.ApplicationName ,
  t.LoginName ,
  t.SPID ,
  t.StartTime ,
  t.SessionLoginName
FROM sys.fn_trace_gettable(CONVERT(VARCHAR(150), 
	( SELECT TOP (1)
			f.[value]
    FROM sys.fn_trace_getinfo(NULL) f
    WHERE f.property = 2
  )), DEFAULT) T
JOIN sys.trace_events TE 
ON T.EventClass = TE.trace_event_id
JOIN sys.trace_subclass_values v 
ON v.trace_event_id = TE.trace_event_id AND v.subclass_value = t.EventSubClass
WHERE te.name IN ( 'Audit Addlogin Event', 'Audit Login Failed')
ORDER BY T.StartTime DESC;
GO

/*
Server memory change events.
*/

SELECT  
	TE.name AS [EventName] ,
  v.subclass_name ,
  t.IsSystem,
	t.StartTime
FROM sys.fn_trace_gettable(CONVERT(VARCHAR(150), 
	( SELECT TOP (1)
			f.[value]
    FROM sys.fn_trace_getinfo(NULL) f
    WHERE f.property = 2
  )), DEFAULT) T
JOIN sys.trace_events TE 
ON T.EventClass = TE.trace_event_id
JOIN sys.trace_subclass_values v 
ON v.trace_event_id = TE.trace_event_id AND v.subclass_value = t.EventSubClass
WHERE   te.name IN ('Server Memory Change');
GO