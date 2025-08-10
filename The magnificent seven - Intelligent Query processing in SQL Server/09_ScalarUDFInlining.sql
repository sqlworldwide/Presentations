/**************************************************************
09_ScalarUDFInlining.sql
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
	
Scalar UDF inlining
Applies to: SQL Server (Starting with SQL Server 2019 (15.x)), Azure SQL Database starting with database compatibility level 150
Available in all Edition
See https://aka.ms/IQP for more background
Demo scripts: https://aka.ms/IQPDemos 

Scalar UDFs are transformed into equivalent relational expressions that are "inlined" into the calling query, often resulting in significant performance gains.
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
WHERE is_inlineable = 1
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

Even the inlining worked elapsed is increase by 15 fold
*/

SELECT TOP 100
  [Customer Key], 
  [Customer],
  dbo.ufn_customer_category([Customer Key]) AS [Discount Price]
FROM [Dimension].[Customer]
ORDER BY [Customer Key]
OPTION (RECOMPILE);
GO

/*
Let's try another example 
Code copied and modified from (By Greg Larsen):
https://www.red-gate.com/simple-talk/databases/sql-server/performance-sql-server/get-your-scalar-udfs-to-run-faster-without-code-changes/
*/

USE WideWorldImportersDW
GO

CREATE OR ALTER FUNCTION dbo.GetRating(@CityKey int)
RETURNS VARCHAR(13) 
AS 
BEGIN
   DECLARE @AvgQty DECIMAL(5,2);
   DECLARE @Rating VARCHAR(13);
   SELECT @AvgQty  = AVG(CAST(Quantity AS DECIMAL(5,2)))
   FROM Fact.[Order]
   WHERE [City Key] = @CityKey;
   IF @AvgQty / 40 >= 1  
	  SET @Rating = 'Above Average';
   ELSE 
	  SET @Rating = 'Below Average'; 
   RETURN @Rating
END
GO

USE WideWorldImportersDW;
GO

ALTER DATABASE WideWorldImportersDW SET COMPATIBILITY_LEVEL = 140;
GO

/*
Turn on Actual Execution plan ctrl+M
Before (show actual query execution plan for legacy behavior)
In SSMS QueryTimeStats show the cpu and elapsed time for UDF

Runtime about 50 secs
*/
SELECT DISTINCT ([City Key]), dbo.GetRating([City Key]) AS CityRating
FROM Dimension.[City]

ALTER DATABASE WideWorldImportersDW SET COMPATIBILITY_LEVEL = 150;
GO

/*
Turn on Actual Execution plan ctrl+M
After (show actual query execution plan for Scalar UDF Inlining)
During inlining you can see this in the properties or XML plan  ContainsInlineScalarTsqlUdfs="true"
Show the properties of root node
*/
SELECT DISTINCT ([City Key]), dbo.GetRating([City Key]) AS CityRating
FROM Dimension.[City]
GO

/*
Not all Scalar Functions Can be Inlined
*/

CREATE OR ALTER FUNCTION dbo.GetRating_Loop(@CityKey int)
RETURNS VARCHAR(13) 
AS 
BEGIN
  DECLARE @AvgQty DECIMAL(5,2);
  DECLARE @Rating VARCHAR(13);
-- Dummy code to support WHILE loop
  DECLARE @I INT = 0;
  WHILE @I < 1
  BEGIN
	SET @I = @I + 1;
  END
  SELECT @AvgQty  = AVG(CAST(Quantity AS DECIMAL(5,2)))
  FROM Fact.[Order]
  WHERE [City Key] = @CityKey;
  IF @AvgQty / 40 >= 1  
	SET @Rating = 'Above Average';
  ELSE 
	SET @Rating = 'Below Average'; 
  RETURN @Rating
END
GO

USE WideWorldImportersDW;
GO

ALTER DATABASE WideWorldImportersDW SET COMPATIBILITY_LEVEL = 150;
GO

/*
Turn on Actual Execution plan ctrl+M
Test UDF With WHILE Loop it will not be inlined
Runtime 48 seconds
*/
SELECT DISTINCT ([City Key]), 
  dbo.GetRating_Loop([City Key]) AS CityRating
FROM Dimension.[City]
GO