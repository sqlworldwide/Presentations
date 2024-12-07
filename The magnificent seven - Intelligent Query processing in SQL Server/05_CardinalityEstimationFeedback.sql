/*
	Script Name: 05_CardinalityEstimationFeedback.sql
	This code is copied from
	https://github.com/microsoft/bobsql/tree/master/demos/sqlserver2022/IQP/cefeedback
	
	Modified by Taiob Ali
	December 6th, 2024

	Cardinality estimation (CE) feedback
	Applies to: SQL Server 2022 (16.x) and later
	Enterprise only
	For Azure SQL Database starting with database compatibility level 160

	https://learn.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query?view=sql-server-ver16#use_hint
	This demo will show CE feedback 'ASSUME_MIN_SELECTIVITY_FOR_FILTER_ESTIMATES'

	Causes SQL Server to generate a plan using minimum selectivity when estimating AND predicates for filters to account for full correlation. This hint name is equivalent to Trace Flag 4137 when used with cardinality estimation model of SQL Server 2012 (11.x) and earlier versions, and has similar effect when Trace Flag 9471 is used with cardinality estimation model of SQL Server 2014 (12.x) and later versions.
*/

USE master;
GO
ALTER DATABASE [AdventureWorks_EXT] SET COMPATIBILITY_LEVEL = 160;
GO
ALTER DATABASE [AdventureWorks_EXT] SET QUERY_STORE CLEAR ALL;
GO
USE [AdventureWorks_EXT];
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
	Create and start an Extended Events session to view feedback events.
*/

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'CEFeedback')
DROP EVENT SESSION [CEFeedback] ON SERVER;
GO
CREATE EVENT SESSION [CEFeedback] ON SERVER 
ADD EVENT sqlserver.query_feedback_analysis(
    ACTION(sqlserver.query_hash_signed,sqlserver.query_plan_hash_signed,sqlserver.sql_text)),
ADD EVENT sqlserver.query_feedback_validation(
    ACTION(sqlserver.query_hash_signed,sqlserver.query_plan_hash_signed,sqlserver.sql_text))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=NO_EVENT_LOSS,MAX_DISPATCH_LATENCY=1 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF);
GO

/*
	Start XE
	Open Live data from SSMS
	Mangement->Extended Events->Sessions->CEFeedback->Watch Live Data
*/

ALTER EVENT SESSION [CEFeedback] ON SERVER
STATE = START;
GO

/*
	Run a batch to prime CE feedback
*/

USE AdventureWorks_EXT;
GO
SELECT AddressLine1, City, PostalCode FROM Person.Address
WHERE StateProvinceID = 79
AND City = 'Redmond';
GO 15

/*
	Run the query a single time to active CE feedback 
*/

USE AdventureWorks_EXT;
GO
SELECT AddressLine1, City, PostalCode FROM Person.Address
WHERE StateProvinceID = 79
AND City = 'Redmond';
GO

/*
	Run the query to see if CE feedback is initiated 
	You should see a statement of PENDING_VALIDATION 
*/

USE AdventureWorks_EXT;
GO
SELECT * from sys.query_store_plan_feedback;
GO

/*
	Run the query again
*/

USE AdventureWorks_EXT;
GO
SELECT AddressLine1, City, PostalCode FROM Person.Address
WHERE StateProvinceID = 79
AND City = 'Redmond';
GO

/*
	Run the query to see if CE feedback is initiated 
	You should see a statement of VERIFICATION_PASSED 
*/

USE AdventureWorks_EXT;
GO
SELECT * from sys.query_store_plan_feedback;
GO

/*
	View the XEvent session data to see how feedback was provided and then verified to be faster. 
	The query_feedback_validation event shows the feedback_validation_cpu_time is less than original_cpu_time
*/

/*
	With the hint now in place, run the queries from the batch to match the number of executions
	Using Query Store Reports for Top Resource Consuming Queries to compare the query with different plans with and without the hint. 
	The plan with the hint (now using an Index Scan should be overall faster and consume less CPU). 
	This includes Total and Avg Duration and CPU.
*/

USE AdventureWorks_EXT;
GO
SELECT AddressLine1, City, PostalCode FROM Person.Address
WHERE StateProvinceID = 79
AND City = 'Redmond';
GO 15

/*
	Stop the extended event session
*/

ALTER EVENT SESSION [CEFeedback] ON SERVER
STATE = STOP;
GO

