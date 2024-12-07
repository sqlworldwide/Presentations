/**************************************************************
	Scirpt Name: 09_ScalarUDFInlining.sql
	This code is copied from
	https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing
	
	Modified by Taiob Ali
	December 6th, 2024
	
	Scalar UDF inlining
	Applies to: SQL Server (Starting with SQL Server 2019 (15.x)), Azure SQL Database starting with database compatibility level 150
	Available in all Edition
	See https://aka.ms/IQP for more background
	Demo scripts: https://aka.ms/IQPDemos 

	Scalar UDFs are transformed into equivalent relational expressions that are "inlined" into the calling query, often resulting in significant performance gains.
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
	Adapted from SQL Server Books Online
	https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sql-server-ver16
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

/* 
	Checking if the UDF is inlineable by looking at the value of is_inlineable column 
*/

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
	
*/

SELECT TOP 100
  [Customer Key], 
	[Customer],
	dbo.ufn_customer_category([Customer Key]) AS [Discount Price]
FROM [Dimension].[Customer]
ORDER BY [Customer Key]
OPTION (RECOMPILE,USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'));
GO

/* 
	After (show actual query execution plan for Scalar UDF Inlining)
	During inlining you can see this in the properties or XML plan  ContainsInlineScalarTsqlUdfs="true"
	Show the properties of root node
*/

SELECT TOP 100
  [Customer Key], 
  [Customer],
  dbo.ufn_customer_category([Customer Key]) AS [Discount Price]
FROM [Dimension].[Customer]
ORDER BY [Customer Key]
OPTION (RECOMPILE);
GO