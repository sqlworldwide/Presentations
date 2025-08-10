/**************************************************************
Scirpt Name: 08_AppxCountDistinct.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modiefied
August 09, 2025
	
Tested on :
SQL Server 2022 CU20
SSMS 21.4.8

This code is copied from
https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing
	

Approximate count distinct
See https://aka.ms/IQP for more background
Demo scripts: https://aka.ms/IQPDemos 
Applies to: SQL Server (Starting with SQL Server 2019 (15.x)) regardless of the compatibility level, Azure SQL Database with any compatibility level
Available in all Editions

Based on HyperLogLog algorithm
The function implementation guarantees up to a 2% error rate within a 97% probability
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
OPTION (USE HINT('DISALLOW_BATCH_MODE'), RECOMPILE); -- Isolating out Batch Mode On RowCount

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

SELECT CAST(ROUND((30382637.0/29620736.0)*100, 1) AS DECIMAL(4,1)) AS percentage;
