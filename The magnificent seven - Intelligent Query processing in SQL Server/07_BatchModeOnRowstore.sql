/*************************************************************
07_BatchModeOnRowstore.sql
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
https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing
	
Batch mode on rowstore
SQL Server (Starting with SQL Server 2019 (15.x)), Azure SQL Database starting with database compatibility level 160
Enterprise only
See https://aka.ms/IQP for more background
Demo scripts: https://aka.ms/IQPDemos 

Uses heuristics – during estimation phase
-Table sizes
-Operators used
-Estimated cardinalities 

Won’t kick in for
-Large Object (LOB) column
-XML column
-Sparse column sets
*************************************************************/

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150;
GO

USE [WideWorldImportersDW];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
Turn on Actual Execution plan ctrl+M
Row mode due to hint
Look at the properties of OrderHistoryExtended table scan
Also notice storage type = RowStore
Notice the CpuTime and ElapsedTime
*/

SELECT [Tax Rate],
	[Lineage Key],
	[Salesperson Key],
	SUM([Quantity]) AS SUM_QTY,
	SUM([Unit Price]) AS SUM_BASE_PRICE,
	COUNT(*) AS COUNT_ORDER
FROM [Fact].[OrderHistoryExtended]
WHERE [Order Date Key] <= DATEADD(dd, -73, '2015-11-13')
GROUP BY [Tax Rate],
	[Lineage Key],
	[Salesperson Key]
ORDER BY [Tax Rate],
	[Lineage Key],
	[Salesperson Key]
OPTION (RECOMPILE, USE HINT('DISALLOW_BATCH_MODE'));

/* 
Batch mode on rowstore eligible 
Notice the CpuTime and ElapsedTime and compare with previous run
*/

SELECT [Tax Rate],
	[Lineage Key],
	[Salesperson Key],
	SUM([Quantity]) AS SUM_QTY,
	SUM([Unit Price]) AS SUM_BASE_PRICE,
	COUNT(*) AS COUNT_ORDER
FROM [Fact].[OrderHistoryExtended]
WHERE [Order Date Key] <= DATEADD(dd, -73, '2015-11-13')
GROUP BY [Tax Rate],
	[Lineage Key],
	[Salesperson Key]
ORDER BY [Tax Rate],
	[Lineage Key],
	[Salesperson Key]
OPTION (RECOMPILE);

/* 
If you want to see that this feature is not available pre 2019 (15.x) 
CpuTime and ElapsedTime is back to rowmode run
*/

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 140;
GO

SELECT [Tax Rate],
	[Lineage Key],
	[Salesperson Key],
	SUM([Quantity]) AS SUM_QTY,
	SUM([Unit Price]) AS SUM_BASE_PRICE,
	COUNT(*) AS COUNT_ORDER
FROM [Fact].[OrderHistoryExtended]
WHERE [Order Date Key] <= DATEADD(dd, -73, '2015-11-13')
GROUP BY [Tax Rate],
	[Lineage Key],
	[Salesperson Key]
ORDER BY [Tax Rate],
	[Lineage Key],
	[Salesperson Key]
OPTION (RECOMPILE);
GO

/* 
Revert compatibility level for next demo 
*/

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150;
GO