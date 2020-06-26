/*============================================================================
SinglePredicate.sql
Written by Taiob M Ali
SqlWorldWide.com

This script will demonstrate how estimated numbers of rows are calculated 
when using single predicate.  

Instruction to run this script
--------------------------------------------------------------------------
Run this on a separate window

USE [WideWorldImporters];
GO
DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID])
WITH HISTOGRAM;
GO
============================================================================*/

USE [Wideworldimporters]; 
GO

--Include Actual Execution Plan (CTRL+M)
--Histogram direct hit RANGE_HI_KEY
--Look at row number 5 of histogram where RANGE_HI_KEY value is 1025
--Look at 'Estimated number of rows' for 'NonClustered Index Seek' operator which is 89
SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID=1025

--Scaling the estimate
--Inserting 2759 records and check if statistics were not update automatically
--Turn off Actual Execual Plan (CTRL+M)
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
WHERE contactpersonid = 1025 
GO 5

--Confirm statistics did not get updated
--Look at
--	Total rows
--	Max RANGE_HI_KEY 
--None of these values changed

DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID]);
GO 

--Removes all elements from the plan cache for Wideworldimporters database 
--WARNING: Do not run this in your production server
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

--Include Actual Execution Plan (CTRL+M)
--Histogram direct hit RANGE_HI_KEY
--Look at 'Estimated number of rows' for 'NonClustered Index Seek' operator which should be 89 as this is a direct hit (seen above) but it is 92.3365 why?
SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID=1025

--Selectivity * New row count
--(EQ_ROWS/Total rows in statistics) * (New Row Count)
--92.3365109048
SELECT 
	(89.0000/73595) * (SELECT COUNT(0) FROM Sales.Orders)

--Run PutThingsBackForDemo.sql

--Include Actual Execution Plan (CTRL+M)
--Histogram intra step hit
--In histogram look AT line  11
--Look at 'Estimated number of rows' for 'NonClustered Index Seek' operator 118.667
SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID=1057

--Include Actual Execution Plan (CTRL+M)
--Distinct values reciprocal of Density Vector
--Look at 'Estimated number of rows' for 'Stream Aggregate' operator 663
SELECT 
	DISTINCT (ContactPersonID)
FROM Sales.Orders 

--Reciprocal of Density vector
--662.9998355760
--Rounded to 663
SELECT 
	1/ 0.001508296 AS [ReciprocalOfAllDensity]




