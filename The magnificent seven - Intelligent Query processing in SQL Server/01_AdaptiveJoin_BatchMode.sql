-- ******************************************************** --
-- Scirpt Name: 01_AdaptiveJoin_BatchMode.sql
-- This code is copied from
-- https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing

-- Modified by Taiob Ali
-- July 20, 2020
-- Batch mode Adaptive Join

-- See https://aka.ms/IQP for more background

-- Demo scripts: https://aka.ms/IQPDemos 

-- This demo is on SQL Server 2017 and Azure SQL DB

-- Email IntelligentQP@microsoft.com for questions\feedback
-- ******************************************************** --

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
Show with Live Query Stats
Order table has a clustered columnstore index 
*/

SELECT [fo].[Order Key], [si].[Lead Time Days], [fo].[Quantity]
FROM [Fact].[Order] AS [fo]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE [fo].[Quantity] = 360;
GO

-- Inserting quantity row that doesn't exist in the table yet
DELETE [Fact].[Order] 
WHERE Quantity = 361;

--Inserting new rows (only 5) with Quantity=361
INSERT [Fact].[Order] 
	([City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], 
	[Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], 
	[Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT TOP 5 [City Key], [Customer Key], [Stock Item Key],
	[Order Date Key], [Picked Date Key], [Salesperson Key], 
	[Picker Key], [WWI Order ID], [WWI Backorder ID], 
	Description, Package, 361, [Unit Price], [Tax Rate], 
	[Total Excluding Tax], [Tax Amount], [Total Including Tax], 
	[Lineage Key]
FROM [Fact].[Order];
GO

-- Show with Live Query Stats
SELECT [fo].[Order Key], [si].[Lead Time Days], [fo].[Quantity]
FROM [Fact].[Order] AS [fo]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE [fo].[Quantity] = 361;
GO


/*
Question:
With the introduction of Batch Mode on Rowstore can I take adavantge of adaptive join in rowstor?
Yes 
Ref: https://www.sqlshack.com/sql-server-2019-new-features-batch-mode-on-rowstore/
Set up before you can run the demo code:
Restore Adventureworks database
https://docs.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver15&tabs=ssms
Enlarge the restored adventureworks database
https://www.sqlskills.com/blogs/jonathan/enlarging-the-adventureworks-sample-databases/
*/

/*
Turn on Actual Execution plan ctrl+M
Show with Live Query Stats
SalesOrderDetailEnlarged table only rowstore, we get batch mode on rowstore and followed by
adaptive join
*/

USE [master];
GO

ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 150;
GO

USE [AdventureWorks];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

SELECT  ProductID,SUM(LineTotal)  ,
SUM(UnitPrice) , SUM(UnitPriceDiscount) FROM 
Sales.SalesOrderDetailEnlarged SOrderDet 
INNER JOIN Sales.SalesOrderHeaderEnlarged  SalesOr
ON SOrderDet.SalesOrderID = SalesOr.SalesOrderID
GROUP  BY ProductID;
GO
