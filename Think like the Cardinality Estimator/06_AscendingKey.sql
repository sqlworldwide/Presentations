/*============================================================================
AscendingKey.sql
Written by Taiob M Ali
SqlWorldWide.com

This script will demonstrate how estimated numbers of rows are calculated when there is an
ascending key column in the table and cardinality estimates are not available for newly inserted rows.

Instruction to run this script
Run this on a separate window
--------------------------------------------------------------------------
Run this on a separate window

USE [WideWorldImporters];
GO
DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID])
WITH HISTOGRAM;
GO
============================================================================*/

USE [WideWorldImporters]; 
GO

--Out of range value estimation
--73595
SELECT COUNT(*) AS [TotalRowsInTable]
FROM Sales.Orders
GO

--Statistics
SELECT  [s].[object_id], [s].[name], [s].[auto_created],
        COL_NAME([s].[object_id], [sc].[column_id]) AS [col_name]
FROM    sys.[stats] AS [s]
        INNER JOIN sys.[stats_columns] AS [sc]
		ON [s].[stats_id] = [sc].[stats_id]
		AND [s].[object_id] = [sc].[object_id]
WHERE   [s].[object_id] = OBJECT_ID(N'Sales.Orders');


--Lets pick _WA_Sys_0000000E_44CA3770 as an example which is for column PickingCompletedWhen 
--where datatype is Datetime 
--Max RANGE_HI_KEY 2016-05-31 12:00:00.0000000
DBCC SHOW_STATISTICS ('Sales.Orders', [_WA_Sys_0000000E_44CA3770]);
GO 

--Inserting 50 more rows which is not enough to trigger auto update statistics
SET NOCOUNT ON;
INSERT INTO 
[Sales].[Orders]
  ([OrderID]
  ,[CustomerID]
  ,[SalespersonPersonID]
  ,[PickedByPersonID]
  ,[ContactPersonID]
  ,[BackorderOrderID]
  ,[OrderDate]
  ,[ExpectedDeliveryDate]
  ,[CustomerPurchaseOrderNumber]
  ,[IsUndersupplyBackordered]
  ,[Comments]
  ,[DeliveryInstructions]
  ,[InternalComments]
  ,[PickingCompletedWhen]
  ,[LastEditedBy]
  ,[LastEditedWhen])
VALUES
		((NEXT VALUE FOR [Sequences].[OrderID]), 832, 2, 3, 1113, 47,'2013-01-01', '2013-01-01', 12211, 1,
		NULL, NULL, NULL,'2017-03-01 11:00:00', 3, GETDATE());
GO 50
SET NOCOUNT OFF;
--73595+50=73645
SELECT COUNT(*) AS [TotalRowsInTable]
FROM Sales.Orders
GO

--Confirm statistics did not get updated
--Look at
--	Total rows
--	Max RANGE_HI_KEY 
--None of these values changed

DBCC SHOW_STATISTICS ('Sales.Orders', [_WA_Sys_0000000E_44CA3770]);
GO 

--Include Actual Execution Plan (CTRL+M)
--Look at 'Estimated number of rows' for 'Clustered Index Scan' operator 34.6329385790
SELECT OrderID
FROM Sales.Orders
WHERE [PickingCompletedWhen]='2017-03-01 11:00:00'


--Looking at cardinality estimation for pre and post 2014
--If you are still in pre 2014 and have this issue
--TF 2389, 2390 might help, link available in resource slide
SELECT 
	'SQL 2014' AS [Version], 
	'Total number of rows times All density for the column' AS [Formula], 
	(73595 * 0.0004705882) AS [EstimatedNumRows], 
	'50' AS [ActualNumRows]
UNION ALL
SELECT 
	'PRE 2014' AS [Version], 
	'It is fixed number which is 1' AS [Formula], 
	1 AS [EstimatedNumRows], 
	'50' AS [ActualNumRows]         


--Rollback for future demos
--Run PutThingsBackForDemo.sql