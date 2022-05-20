/**************************************************************
-- Scirpt Name: 05_ScalarUDFInlining.sql
-- This code is copied from
-- https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing

-- Modified by Taiob Ali
-- May 19, 2022

-- Scalar UDF Inlining

-- See https://aka.ms/IQP for more background

-- Demo scripts: https://aka.ms/IQPDemos 

-- Demo uses SQL Server 2019 and Azure SQL DB

-- Email IntelligentQP@microsoft.com for questions\feedback
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
Adapted from SQL Server Books Online
https://docs.microsoft.com/sql/relational-databases/user-defined-functions/scalar-udf-inlining
*/

CREATE OR ALTER FUNCTION 
	dbo.ufn_customer_category(@CustomerKey INT) 
RETURNS CHAR(10) AS
BEGIN
	DECLARE @total_amount DECIMAL(18,2);
	DECLARE @category CHAR(10);

	SELECT @total_amount = SUM([Total Including Tax]) 
	FROM [Fact].[OrderHistory]
	WHERE [Customer Key] = @CustomerKey;

	IF @total_amount < 500000
		SET @category = 'REGULAR';
	ELSE IF @total_amount < 1000000
		SET @category = 'GOLD';
	ELSE 
		SET @category = 'PLATINUM';

	RETURN @category;
END
GO

/* Checking if the UDF is inlineable by looking at the value of is_inlineable column */
SELECT 
  object_id,
  definition,
  is_inlineable
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('ufn_customer_category')
GO

/*
Turn on Actual Execution plan ctrl+M
Before (show actual query execution plan for legacy behavior)
In SSMS QueryTimeStats show the cpu and elapsed time for UDF
During inlining you can see this in the properties or XML plan  ContainsInlineScalarTsqlUdfs="true"
*/
SELECT TOP 100
  [Customer Key], 
	[Customer],
	dbo.ufn_customer_category([Customer Key]) AS [Discount Price]
FROM [Dimension].[Customer]
ORDER BY [Customer Key]
OPTION (RECOMPILE,USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'));
GO

/* After (show actual query execution plan for Scalar UDF Inlining) */
SELECT TOP 100
  [Customer Key], 
  [Customer],
  dbo.ufn_customer_category([Customer Key]) AS [Discount Price]
FROM [Dimension].[Customer]
ORDER BY [Customer Key]
OPTION (RECOMPILE);
GO