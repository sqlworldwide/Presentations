/**************************************************************
	Scirpt Name: 04B_MGF_Persistence.sql
	This code is copied from
	https://github.com/microsoft/sqlworkshops-sql2022workshop/tree/main/sql2022workshop/03_BuiltinQueryIntelligence/persistedmgf

	Modified by Taiob Ali
	December 6th, 2024

	Memory Grant Feedback Persistence
	Applies to: SQL Server 2022 (16.x) and later with	Database compatibility level 140
	Enterprise only
	Enabled by default in Azure SQL database

	The initial phases of this project only stored the memory grant adjustment with the plan in the cache – if a plan is evicted from the cache, the feedback process must start again, resulting in poor performance the first few times a query is executed after eviction. The new solution is to persist the grant information with the other query information in the Query Store so that the benefits last across cache evictions.
	
	Email IntelligentQP@microsoft.com for questions\feedback
*************************************************************/

USE [master];
GO

/*
	Setup the demo
*/

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150;
GO

USE WideWorldImportersDW;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
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
Clean up Query store data
USE master
GO

ALTER DATABASE WideWorldImportersdw SET QUERY_STORE CLEAR ALL
GO
*/


/*
	Turn on Actual Execution plan ctrl+M
	Execute a query that will use a memory grant
	The query will take about 30 seconds to complete
	Select the Execution Plan in the results. 
	You will see a graphical showplan. 
	Notice the yellow warning on the hash join operator. 
	If you hover over this operator with the cursor you will see a warning about a spill to tempdb. 
	Notice the spill involves writing out ~400Mb of pages to tempdb. 
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
*/
USE [WideWorldImportersDW];
GO
EXEC sys.sp_query_store_flush_db;
GO

/*
	You will see that feedback has been stored to allocate a significant larger memory grant on next query execution.
*/

USE WideWorldImportersDW;
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


/*
	Run the select statement again.
	This time the query runs in seconds. 
	Notice there is no spill warning for the hash join. 
	Hovering over the SELECT operator will show a significantly larger grant. 
	Right clicking on the SELECT operator and selecting properties will show in the MemoryGrantInfo section IsMemoryGrantFeedbackAdjusted = YesAdjusting.
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
*/

USE [WideWorldImportersDW];
GO
EXEC sys.sp_query_store_flush_db;
GO

/*
	See the last_query_memory_kb reflect the new larger memory grant.
*/

USE WideWorldImportersDW;
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
