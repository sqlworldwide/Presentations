/*****************************************************************
	Scirpt Name: 04A_MFG_RowModesql.sql
	This code is copied from
	https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing
	
	Modified by Taiob Ali
	December 6th, 2024
	
	Row mode memory grant feedback
	Applies to: SQL Server (Starting with SQL Server 2019 (15.x)), Azure SQL Database with database compatibility level 150
	Enterprise edition only

	See https://aka.ms/IQP for more background
	Demo scripts: https://aka.ms/IQPDemos 	
	Email IntelligentQP@microsoft.com for questions\feedback
****************************************************************/

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150;
GO

USE [WideWorldImportersDW];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
	Clean up Query Store data by using the following statement
*/

ALTER DATABASE WideWorldImportersDW SET QUERY_STORE CLEAR;
GO

/* Simulate out-of-date stats */

UPDATE STATISTICS Fact.OrderHistory 
WITH ROWCOUNT = 1;
GO

/*
	Include actual execution plan (ctrl+M)
	Execute once to see spills (row mode)
	Execute a second time to see correction

	First execution look at Table Scan of OrderHistory table
	Estimated number of rows =1
	Actual number of rows = 3,702,592
	Grnated Memory  =1056 KB

	Second execution
	GrantedMemory="625072" LastRequestedMemory="1056" IsMemoryGrantFeedbackAdjusted="Yes: Adjusting"

	Third execution
	LastRequestedMemory="625072" IsMemoryGrantFeedbackAdjusted="Yes: Stable"
*/

SELECT fo.[Order Key], fo.Description,
	si.[Lead Time Days]
FROM Fact.OrderHistory AS fo
INNER HASH JOIN Dimension.[Stock Item] AS si 
	ON fo.[Stock Item Key] = si.[Stock Item Key]
WHERE fo.[Lineage Key] = 9
	AND si.[Lead Time Days] > 19;

/*
	We want to ensure we have the latest persisted data in QDS 
*/

USE [WideWorldImportersDW];
GO
EXEC sys.sp_query_store_flush_db;
GO

/*
	Is the memory grant value persisted in Query store?
	Yes it does but less arributes in the feedback_data column compare to batch_mode
		
	You will need SQL2022 and Compatibility level 140 for this feature to work
	Query store must be enabled with read_write
	Query copied and from  Grant Fritchey's website:
	https://www.scarydba.com/2022/10/17/monitor-cardinality-feedback-in-sql-server-2022/
*/

SELECT 
	qspf.plan_feedback_id,
	qsq.query_id,
  qsqt.query_sql_text,
	 qspf.feedback_data,
  qsp.query_plan,
  qspf.feature_desc,
  qspf.state_desc
FROM sys.query_store_query AS qsq
JOIN sys.query_store_plan AS qsp
	ON qsp.query_id = qsq.query_id
JOIN sys.query_store_query_text AS qsqt
	ON qsqt.query_text_id = qsq.query_text_id
JOIN sys.query_store_plan_feedback AS qspf
	ON qspf.plan_id = qsp.plan_id
WHERE qspf.feature_id = 2

/* Cleanup */

UPDATE STATISTICS Fact.OrderHistory 
WITH ROWCOUNT = 3702672;
GO
