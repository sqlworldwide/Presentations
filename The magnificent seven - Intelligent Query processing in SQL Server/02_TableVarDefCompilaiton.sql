/********************************************************** 
-- Scirpt Name: 02_TableVarDefCompilaiton.sql
-- This code is copied from
-- https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing

-- Modified by Taiob Ali
-- May 19, 2022

-- Table variable deferred compilation

-- See https://aka.ms/IQP for more background

-- Demo scripts: https://aka.ms/IQPDemos 

-- This demo is on SQL Server 2019 and Azure SQL DB

-- Email IntelligentQP@microsoft.com for questions\feedback
************************************************************/

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 140;
GO

USE [WideWorldImportersDW];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
Turn on Actual Execution plan ctrl+M
Look at estimated rows, speed, join algorithm
Estimated number of rows: 1
Actual number of row: 490928
Thick flow going to Nested loop join
Row ID lookup
Low memory grant caused a sort spill
Takes about ~20 seconds in my laptop
*/

DECLARE @Order TABLE 
	([Order Key] BIGINT NOT NULL,
	 [Quantity] INT NOT NULL
	);

INSERT @Order
SELECT [Order Key], [Quantity]
FROM [Fact].[OrderHistory]
WHERE  [Quantity] > 99;

SELECT oh.[Order Key], oh.[Order Date Key],
   oh.[Unit Price], o.Quantity
FROM Fact.OrderHistoryExtended AS oh
INNER JOIN @Order AS o
	ON o.[Order Key] = oh.[Order Key]
WHERE oh.[Unit Price] > 0.10
ORDER BY oh.[Unit Price] DESC;
GO

USE [master]
GO

/* Changing MAXDOP as this query can advantage of parallel execution */
EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
EXEC sp_configure 'max degree of parallelism', 0;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150
GO

/* Disconnect and connect */
USE [WideWorldImportersDW];
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
Turn on Actual Execution plan ctrl+M
This will get a parllel execution which also help reducing runtime
Estimated number of rows: 490928
Actual number of row: 490928
Hash join
*/
DECLARE @Order TABLE 
	([Order Key] BIGINT NOT NULL,
	 [Quantity] INT NOT NULL
	);

INSERT @Order
SELECT [Order Key], [Quantity]
FROM [Fact].[OrderHistory]
WHERE [Quantity] > 99;

-- Look at estimated rows, speed, join algorithm
SELECT oh.[Order Key], oh.[Order Date Key],
	oh.[Unit Price], o.Quantity
FROM Fact.OrderHistoryExtended AS oh
INNER JOIN @Order AS o
	ON o.[Order Key] = oh.[Order Key]
WHERE oh.[Unit Price] > 0.10
ORDER BY oh.[Unit Price] DESC;
GO

/* Revert MAXDOP Setting */
EXEC sp_configure 'max degree of parallelism', 2;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
