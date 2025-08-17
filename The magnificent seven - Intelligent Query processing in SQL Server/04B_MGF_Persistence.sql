/**************************************************************
04B_MGF_Persistence.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modiefied
August 17, 2025
	
Tested on :
SQL Server 2022 CU20
SSMS 21.4.12

This code is copied from
https://github.com/microsoft/sqlworkshops-sql2022workshop/tree/main/sql2022workshop/03_BuiltinQueryIntelligence/persistedmgf

Memory Grant Feedback Persistence
Applies to: SQL Server 2022 (16.x) and later with	Database compatibility level 140
Enterprise only
Enabled by default in Azure SQL database

The initial phases of this project only stored the memory grant adjustment with the plan in the cache – if a plan is evicted from the cache, the feedback process must start again, resulting in poor performance the first few times a query is executed after eviction. The new solution is to persist the grant information with the other query information in the Query Store so that the benefits last across cache evictions.
*************************************************************/

USE [master];
GO

/*
Setup the demo
*/

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 160;
GO
USE WideWorldImportersDW;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
ALTER DATABASE WideWorldImportersDW SET QUERY_STORE CLEAR ALL;
GO

/*
Simulate statistics out of date
*/

USE WideWorldImportersDW;
GO
UPDATE STATISTICS Fact.OrderHistory 
WITH ROWCOUNT = 1000;
GO

/*
Turn on Actual Execution plan ctrl+M
Execute the query that will use a memory grant
The query will take about 47 seconds to complete

You will see a graphical showplan. 
Notice the yellow warning on the hash join operator. 
If you hover over this operator with the cursor you will see a warning about a spill to tempdb. 
Notice the spill involves writing out ~406Mb of pages to tempdb. 
Hash Match:
You can also see the estimated number of rows is far lower than the actual number of rows.
*/

USE WideWorldImportersDW;
GO
SELECT fo.[Order Key], fo.Description, si.[Lead Time Days]
FROM  Fact.OrderHistory AS fo
INNER HASH JOIN Dimension.[Stock Item] AS si 
ON fo.[Stock Item Key] = si.[Stock Item Key]
WHERE fo.[Lineage Key] = 9
AND si.[Lead Time Days] > 19;
GO

/*
We want to ensure we have the latest persisted data in QDS 
Flushes the in-memory portion of the Query Store data to disk.
You will see that feedback has been stored to allocate a significant larger memory grant on next query execution.

Run this on a separate window while below while loop keeps running
*/

USE [WideWorldImportersDW];
GO
EXEC sys.sp_query_store_flush_db;
GO
SELECT qpf.feature_desc, qpf.feedback_data, qpf.state_desc, qt.query_sql_text, (qrs.last_query_max_used_memory * 8192)/1024 as last_query_memory_kb 
FROM sys.query_store_plan_feedback qpf
JOIN sys.query_store_plan qp
ON qpf.plan_id = qp.plan_id
JOIN sys.query_store_query qq
ON qp.query_id = qq.query_id
JOIN sys.query_store_query_text qt
ON qq.query_text_id = qt.query_text_id
JOIN sys.query_store_runtime_stats qrs
ON qp.plan_id = qrs.plan_id;
GO
SELECT * FROM sys.query_store_plan_feedback;
GO

/*
Run the select statement again.
Turn on Actual Execution plan ctrl+M

This time the query runs in seconds. 
Notice there is no spill warning for the hash join. 
Hovering over the SELECT operator will show a significantly larger grant. 
*/
-- set discard results after execution
USE WideWorldImportersDW;
GO
WHILE (1=1)
BEGIN
	SELECT fo.[Order Key], fo.Description, si.[Lead Time Days]
	FROM  Fact.OrderHistory AS fo
	INNER HASH JOIN Dimension.[Stock Item] AS si 
	ON fo.[Stock Item Key] = si.[Stock Item Key]
	WHERE fo.[Lineage Key] = 9
	AND si.[Lead Time Days] > 19;
END
GO


/*
This will clear the plan cache. Prior to SQL Server 2022, this would have "lost" the memory grant feedback.
*/
USE [WideWorldImportersDW];
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
You will see the grant is still using the feedback now in the query store and runs in a few seconds
After executing a query that uses feedback from the Query Store the SELECT operator will not show IsMemoryGrantFeedbackAdjusted = YesAdjusting
*/

USE WideWorldImportersDW;
GO
SELECT fo.[Order Key], fo.Description, si.[Lead Time Days]
FROM  Fact.OrderHistory AS fo
INNER HASH JOIN Dimension.[Stock Item] AS si 
ON fo.[Stock Item Key] = si.[Stock Item Key]
WHERE fo.[Lineage Key] = 9
AND si.[Lead Time Days] > 19;
GO

/* Cleanup */

UPDATE STATISTICS Fact.OrderHistory 
WITH ROWCOUNT = 3702672;
GO
