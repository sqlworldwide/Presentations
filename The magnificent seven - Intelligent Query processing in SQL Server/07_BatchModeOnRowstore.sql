/*************************************************************
	Scirpt Name: 07_BatchModeOnRowstore.sql
	This code is copied from
	https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing
	
	Modified by Taiob Ali
	May 29, 2023
	Batch mode on rowstore
	SQL Server (Starting with SQL Server 2019 (15.x)), Azure SQL Database
	Enterprise only
	See https://aka.ms/IQP for more background
	Demo scripts: https://aka.ms/IQPDemos 
	mail IntelligentQP@microsoft.com for questions\feedback
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