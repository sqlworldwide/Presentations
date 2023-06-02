/*
	Script Name: 05_DegreeOfParallelismFeedback.sql
	https://github.com/microsoft/bobsql/tree/master/demos/sqlserver2022/IQP/dopfeedback
	
	Modified by Taiob Ali
	May 29, 2023
	Degree of parallelism (DOP) feedback
	Applies to: SQL Server 2022 (16.x) and later, Azure SQL Managed Instance, Azure SQL Database (Preview)
*/

/*
	configure MAXDOP to 0 for the instance
*/

sp_configure 'show advanced', 1;
GO
reconfigure;
GO
sp_configure 'max degree of parallelism', 0;
go
reconfigure;
GO

/*
	Make sure Query Store is on and set runtime collection lower than default
*/

USE WideWorldImporters;
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE = ON;
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE (OPERATION_MODE = READ_WRITE, DATA_FLUSH_INTERVAL_SECONDS = 60, 
	INTERVAL_LENGTH_MINUTES = 1, QUERY_CAPTURE_MODE = ALL);
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR ALL;
GO

/*
	You must change dbcompat to 160
*/

ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 160;
GO
 
/*
	Enable DOP feedback
*/

ALTER DATABASE SCOPED CONFIGURATION SET DOP_FEEDBACK = ON;
GO

/* 
	Clear proc cache to start with new plans
*/

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
	create a stored procedure
*/

USE WideWorldImporters;
GO
CREATE OR ALTER PROCEDURE [Warehouse].[GetStockItemsbySupplier]  @SupplierID int
AS
BEGIN
SELECT StockItemID, SupplierID, StockItemName, TaxRate, LeadTimeDays
FROM Warehouse.StockItems s
WHERE SupplierID = @SupplierID
ORDER BY StockItemName;
END;
GO

/*
	Create an XEvent session
*/

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'DOPFeedback')
DROP EVENT SESSION [DOPFeedback] ON SERVER;
GO
CREATE EVENT SESSION [DOPFeedback] ON SERVER 
ADD EVENT sqlserver.dop_feedback_eligible_query(
    ACTION(sqlserver.query_hash_signed,sqlserver.query_plan_hash_signed,sqlserver.sql_text)),
ADD EVENT sqlserver.dop_feedback_provided(
    ACTION(sqlserver.query_hash_signed,sqlserver.query_plan_hash_signed,sqlserver.sql_text)),
ADD EVENT sqlserver.dop_feedback_reverted(
    ACTION(sqlserver.query_hash_signed,sqlserver.query_plan_hash_signed,sqlserver.sql_text)),
ADD EVENT sqlserver.dop_feedback_stabilized(
    ACTION(sqlserver.query_hash_signed,sqlserver.query_plan_hash_signed,sqlserver.sql_text)),
ADD EVENT sqlserver.dop_feedback_validation(
    ACTION(sqlserver.query_hash_signed,sqlserver.query_plan_hash_signed,sqlserver.sql_text))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=NO_EVENT_LOSS,MAX_DISPATCH_LATENCY=1 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF);
GO

/*
	Start XE
	Open Live data from SSMS
	Mangement->Extended Events->Sessions->DOPFeedback->Watch Live Data
*/

ALTER EVENT SESSION [DOPFeedback] ON SERVER
STATE = START;
GO

/*
	Run workload_index_scan_users.cmd from a command prompt.This will take around 15 minutes to run
*/

/*
	See the changes in DOP and resulting stats. 
	Note the small decrease in avg duration and decrease in needed CPU across the various last_dop values
	The hash value of 4128150668158729174 should be fixed for the plan from the workload
*/

USE WideWorldImporters;
GO
SELECT 
	qsp.query_plan_hash, 
	avg_duration/1000 as avg_duration_ms, 
	avg_cpu_time/1000 as avg_cpu_ms, 
	last_dop, 
	min_dop, max_dop, 
	qsrs.count_executions
FROM sys.query_store_runtime_stats qsrs
JOIN sys.query_store_plan qsp
ON qsrs.plan_id = qsp.plan_id
and qsp.query_plan_hash = CONVERT(varbinary(8), cast(4128150668158729174 as bigint))
ORDER by qsrs.last_execution_time;
GO

/*
	See the persisted DOP feedback. 
	Examine the values in the feedback_desc field to see the BaselineStats and LastGoodFeedback values.
*/

USE WideWorldImporters;
GO
SELECT 
	qspf.plan_feedback_id,
	qsq.query_id,
  qsqt.query_sql_text,
  qsp.query_plan,
  qspf.feature_desc,
  qspf.state_desc,
  qspf.feedback_data
FROM sys.query_store_query AS qsq
JOIN sys.query_store_plan AS qsp
	ON qsp.query_id = qsq.query_id
JOIN sys.query_store_query_text AS qsqt
	ON qsqt.query_text_id = qsq.query_text_id
JOIN sys.query_store_plan_feedback AS qspf
	ON qspf.plan_id = qsp.plan_id
WHERE qspf.feature_id = 3

/*
	Revert MAXDOP Setting
*/

EXEC sp_configure 'max degree of parallelism', 2;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
