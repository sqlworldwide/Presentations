/**************************************************************
	Scirpt Name: 08_AppxCountDistinct.sql
	This code is copied from
	https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing
	
	Modified by Taiob Ali
	December 6th, 2024
	
	Approximate count distinct
	See https://aka.ms/IQP for more background
	Demo scripts: https://aka.ms/IQPDemos 
	Applies to: SQL Server (Starting with SQL Server 2019 (15.x)) regardless of the compatibility level, Azure SQL Database with any compatibility level
	Available in all Editions

	Based on HyperLogLog algorithm
	The function implementation guarantees up to a 2% error rate within a 97% probability

	Email IntelligentQP@microsoft.com for questions\feedback
*************************************************************/

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 160;
GO

USE [WideWorldImportersDW];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
	Turn on Actual Execution plan ctrl+M
	Compare execution time and distinct counts
	Show run time statistics and memory grant
	Run all three at the same time
*/

SELECT COUNT(DISTINCT [WWI Order ID])
FROM [Fact].[OrderHistoryExtended]
OPTION (USE HINT('DISALLOW_BATCH_MODE'), RECOMPILE); -- Isolating out Batch Mmod On RowCount

SELECT APPROX_COUNT_DISTINCT([WWI Order ID])
FROM [Fact].[OrderHistoryExtended]
OPTION (USE HINT('DISALLOW_BATCH_MODE'), RECOMPILE); -- Isolating out BMOR
GO

SELECT APPROX_COUNT_DISTINCT([WWI Order ID])
FROM [Fact].[OrderHistoryExtended]
OPTION (RECOMPILE); 
GO

/* 
	With in 2.6% 
*/

SELECT (30382637.0/29620736.0)*100
