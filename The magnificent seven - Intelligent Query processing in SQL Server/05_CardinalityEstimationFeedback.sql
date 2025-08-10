/*
05_CardinalityEstimationFeedback.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modiefied
August 08, 2025
	
Tested on :
SQL Server 2022 CU20
SSMS 21.4.8

This code is copied from
https://github.com/microsoft/bobsql/tree/master/demos/sqlserver2022/IQP/cefeedback
	
Cardinality estimation (CE) feedback
Applies to: SQL Server 2022 (16.x) and later
Enterprise only
For Azure SQL Database starting with database compatibility level 160
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
Cardinality estimation (CE) feedback correlation

Correlation:
Fully independent (default for CE70), where cardinality is calculated by multiplying the selectivities of all predicates.
Partially correlated (default for CE120 and higher), where cardinality is calculated using a variation on exponential backoff, ordering the selectivities from most to the least selective predicate.
Fully correlated, where cardinality is calculated by using the minimum selectivities for all predicates.

When the database compatibility is set to 160, and default correlation is used, CE feedback attempts to move the correlation to the correct direction one step at a time based on whether the estimated cardinality was underestimated or overestimated compared to the actual number of rows. Use full correlation if an actual number of rows is greater than the estimated cardinality. Use full independence if an actual number of rows is smaller than the estimated cardinality.
https://learn.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query?view=sql-server-ver16#use_hint
This demo will show CE feedback 'ASSUME_MIN_SELECTIVITY_FOR_FILTER_ESTIMATES'

Causes SQL Server to generate a plan using minimum selectivity when estimating AND predicates for filters to account for full correlation. This hint name is equivalent to Trace Flag 4137 when used with cardinality estimation model of SQL Server 2012 (11.x) and earlier versions, and has similar effect when Trace Flag 9471 is used with cardinality estimation model of SQL Server 2014 (12.x) and later versions.
*/

/*
Include actual execution plan (ctrl+M)
Run a batch to prime CE feedback
*/

USE AdventureWorks_EXT;
GO
SELECT AddressLine1, City, PostalCode FROM Person.Address
WHERE StateProvinceID = 79
AND City = 'Redmond';
GO 15

/*
Include actual execution plan (ctrl+M)
Run the query a single time to active CE feedback 
Look at the XE live output
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
EXEC sys.sp_query_store_flush_db;
GO
SELECT * from sys.query_store_plan_feedback;
GO

/*
Include actual execution plan (ctrl+M)
Run the query again
Look at the XE live output. 
Notice three values:
*feedback_validation_cpu_time	
*original_cpu_time	
*stdev_cpu_time	
*/

USE AdventureWorks_EXT;
GO
SELECT AddressLine1, City, PostalCode FROM Person.Address
WHERE StateProvinceID = 79
AND City = 'Redmond';
GO

/*
Run the query to see if CE feedback is initiated 
You should see the value of state_desc VERIFICATION_REGRESSED due to the cpu usage increase
*/

USE AdventureWorks_EXT;
GO
EXEC sys.sp_query_store_flush_db;
GO
SELECT * from sys.query_store_plan_feedback;
GO

/*
Stop the extended event session
*/

ALTER EVENT SESSION [CEFeedback] ON SERVER
STATE = STOP;
GO

