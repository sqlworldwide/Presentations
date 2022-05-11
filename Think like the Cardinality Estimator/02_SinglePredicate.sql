/*============================================================================
SinglePredicate.sql
Written by Taiob Ali
SqlWorldWide.com

This script will demonstrate how estimated number of rows are calculated 
when using single predicate.  

Instruction to run this script
--------------------------------------------------------------------------
Run this on a separate window

USE [WideWorldImporters];
GO

DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID]);
GO
============================================================================*/

USE [Wideworldimporters]; 
GO

/*
Include Actual Execution Plan (CTRL+M)
Histogram direct hit RANGE_HI_KEY
Look at row number 5 of histogram where RANGE_HI_KEY value is 1025
Look at 'Estimated number of rows' for 'NonClustered Index Seek' operator which is 89
*/

SELECT
	OrderID,
	CustomerID,
	SalespersonPersonID,
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID=1025;
GO

/*
Scaling the estimate
Inserting 2759 records and check if statistics were update automatically
Turn off Actual Execual Plan (CTRL+M)
*/

INSERT INTO sales.orders
	(customerid,
	salespersonpersonid,
	pickedbypersonid,
	contactpersonid,
	backorderorderid,
	orderdate,
	expecteddeliverydate,
	customerpurchaseordernumber,
	isundersupplybackordered,
	comments,
	deliveryinstructions,
	internalcomments,
	pickingcompletedwhen,
	lasteditedby,
	lasteditedwhen)
SELECT
	customerid,
	salespersonpersonid,
	pickedbypersonid,
	contactpersonid,
	backorderorderid,
	orderdate,
	expecteddeliverydate,
	customerpurchaseordernumber,
	isundersupplybackordered,
	comments,
	deliveryinstructions,
	internalcomments,
	pickingcompletedwhen,
	lasteditedby,
	lasteditedwhen
FROM sales.orders
WHERE contactpersonid = 1025;
GO 5

/*
Confirm statistics did not get updated
Look at
	Total rows
	Max RANGE_HI_KEY 
None of these values changed
*/

DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID]);
GO

/*
Removes all elements from the plan cache for Wideworldimporters database 
WARNING: Do not run this in your production server
*/

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
Include Actual Execution Plan (CTRL+M)
2759+89=2848 records
Histogram direct hit RANGE_HI_KEY
Look at 'Estimated number of rows' for 'NonClustered Index Seek' operator which should be 89 
as this is a direct hit (seen above) but it is 92.3365 why?
*/

SELECT
	OrderID,
	CustomerID,
	SalespersonPersonID,
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID=1025;
GO

/*
Selectivity * New row count
(EQ_ROWS/Total rows in statistics) * (New Row Count)
92.3365109048

Count query borrowed from:
https://sqlperformance.com/2014/10/t-sql-queries/bad-habits-count-the-hard-way
*/

SELECT
	(89.0000/73595) * 
	(SELECT 
		SUM(p.rows)
	FROM sys.partitions AS p
	INNER JOIN sys.tables AS t
	ON p.[object_id] = t.[object_id]
	INNER JOIN sys.schemas AS s
	ON t.[schema_id] = s.[schema_id]
	WHERE p.index_id IN (0,1) -- heap or clustered index
	AND t.name = N'Orders'
	AND s.name = N'Sales');
GO



/*
Run PutThingsBackForDemo.sql
*/

/*
Include Actual Execution Plan (CTRL+M)
Histogram intra step hit
In histogram look AT line  11
Look at 'Estimated number of rows' for 'NonClustered Index Seek' operator 118.667
*/

SELECT
	OrderID,
	CustomerID,
	SalespersonPersonID,
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID=1057;
GO

/*
Include Actual Execution Plan (CTRL+M)
Distinct values reciprocal of Density Vector
Look at 'Estimated number of rows' for 'Stream Aggregate' operator 663
*/

SELECT
	DISTINCT (ContactPersonID)
FROM Sales.Orders;
GO

/*
Reciprocal of Density vector
662.9998355760
Rounded to 663
*/

SELECT
	1/ 0.001508296 AS [ReciprocalOfAllDensity];
GO