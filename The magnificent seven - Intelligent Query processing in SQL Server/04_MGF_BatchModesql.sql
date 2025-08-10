/**************************************************************
04_MGF_BatchModesql.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://twitter.com/SqlWorldWide
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modiefied
August 08, 2025
	
Tested on :
SQL Server 2022 CU20
SSMS 21.4.8
	
This code is copied from
https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing

Batch mode Memory Grant Feedback
Applies to: SQL Server (Starting with SQL Server 2017 (14.x)), Azure SQL Database with database compatibility level 140
Enterprise only
See https://aka.ms/IQP for more background
Demo scripts: https://aka.ms/IQPDemos 	

Percentile and persistence mode memory grant feedback
Applies to: SQL Server 2022 (16.x) and later
Database compatibility level 140 (introduced in SQL Server 2017) or higher
Enterprise edition only 
Enabled on all Azure SQL Databases by default

Not applicable for memory grant undre 1 MB
Granted memory is more than two times the size of the actual used memory, memory grant feedback will recalculate the memory grant and update the cached plan.
Insufficiently sized memory grant condition that result in a spill to disk for batch mode operators, memory grant feedback will trigger a recalculation of the memory grant. 


*************************************************************/

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 140;
GO

USE [WideWorldImportersDW];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
Clean up Query Store data by using the following statement
Please DO NOT do this in your production servers
*/

ALTER DATABASE WideWorldImportersDW SET QUERY_STORE CLEAR;
GO

/* 
Intentionally forcing a row underestimate 
*/

CREATE OR ALTER PROCEDURE [FactOrderByLineageKey]
	@LineageKey INT 
AS
SELECT [fo].[Order Key], [fo].[Description] 
FROM [Fact].[Order] AS [fo]
INNER HASH JOIN [Dimension].[Stock Item] AS [si] 
ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE [fo].[Lineage Key] = @LineageKey
	AND [si].[Lead Time Days] > 0
ORDER BY [fo].[Stock Item Key], [fo].[Order Date Key] DESC
OPTION (MAXDOP 1);
GO

/*
Turn on Actual Execution plan ctrl+M
Compiled and executed using a lineage key that doesn't have rows
Run both at the same time and then run the second one separate
Look at the warning about excessive memory grant
Show 'IsMemoryGrantFeedbackAdjusted' on both plan root node
*/

EXEC [FactOrderByLineageKey] 8;
GO
EXEC [FactOrderByLineageKey] 9;
GO

/*
Execute this query a few times - each time looking at 
the plan to see impact on spills, memory grant size, and run time
New feature of SQL 2022 IsMemoryGrantFeedbackAdjusted = YesPercentileAdjusting
	
During my test started with 22MB and stablized at 91MB after 19 execution
Using a percentile-based calculation over the recent history of the query
You will need SQL 2022 but work with Compatibility level 140+

Description of 'IsMemoryGrantFeedbackAdjusted' values:
https://learn.microsoft.com/en-us/sql/relational-databases/performance/intelligent-query-processing-feedback?view=sql-server-ver15#batch-mode-memory-grant-feedback
*/

WHILE (1=1)
BEGIN
	EXEC [FactOrderByLineageKey] 9;
END
GO

/*
Is the memory grant value persisted in Query store?

During the while loop execution run the below query on a separate window.
See how "AdditionalMemoryKB" value changes in the feedback columm (JSON)

You will need SQL2022 and Compatibility level 140 for this feature to work
Query store must be enabled with read_write
Query copied from  Grant Fritchey's website and modified by me.
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

