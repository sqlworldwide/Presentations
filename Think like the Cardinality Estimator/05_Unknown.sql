/*============================================================================
Unknown.sql
Written by Taiob Ali
SqlWorldWide.com

This script will demonstrate how estimated numbers of rows are calculated 
in case of Unknown values.

Instruction to run this script
--------------------------------------------------------------------------
Run this on a separate window

USE [WideWorldImporters];
GO

DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID]);
GO
============================================================================*/

USE [WideWorldImporters]; 
GO

/*
run putthingsback.sql
*/

/*
Include Actual Execution Plan (CTRL+M)
Equality Operator
Unique column will always be 1
*/

DECLARE @OrderId AS SMALLINT = 1030;

SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE OrderId=@OrderId;
GO

/*
Look at 'Estimated number of rows' for 'Index Seek' 111.003
EQUALITY Operator
Not known, Using Statistics for FK_Sales_Orders_ContactPersonID
run time value using 'All density' 0.001508296 for column 'ContactPersonID'
*/

DECLARE @cpid AS SMALLINT = 1025;

SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID=@cpid;
GO

/*
Total number of rows * density of ContactPersonID
111.003044120
*/

SELECT 73595 * 0.001508296;
GO

/*
EQUALITY Operator
Statistics not available such as table variable
If we recompile the select statement, the cardinality estimator knows about the number of rows
in the table variable
Look at 'Estimated number of rows' for 'Table scan' will be either 1 or 271.3
Show this as is and after commenting our option(recompile).
*/

DECLARE @OrderDetails TABLE (
	ContactPersonID int);

INSERT INTO @OrderDetails
	(ContactPersonID)
SELECT 
	ContactPersonID
FROM Sales.Orders AS o;

SELECT 
	*
FROM @OrderDetails AS od
WHERE ContactPersonID=1025
OPTION (RECOMPILE);
GO

/*
That changes in 2019 with Table variable deferred compilation
https://docs.microsoft.com/en-us/sql/relational-databases/performance/intelligent-query-processing?view=sql-server-ver15#table-variable-deferred-compilation
I can get 271.3 without recompile hint
*/

ALTER DATABASE WideWorldImporters  
SET COMPATIBILITY_LEVEL = 150;  
GO

DECLARE @OrderDetails TABLE (
	ContactPersonID int);

INSERT INTO @OrderDetails
	(ContactPersonID)
SELECT 
	ContactPersonID
FROM Sales.Orders AS o;

SELECT 
	*
FROM @OrderDetails AS od
WHERE ContactPersonID=1025;
GO

/*
Setting back to 140 for future demo
*/

ALTER DATABASE WideWorldImporters  
SET COMPATIBILITY_LEVEL = 140;  
GO

/*
Estimated number was higher pre 2014
*/

SELECT
	'SQL 2014' AS [Version],
	'Total number of rows raise to the power of .5' AS [Formula],
	POWER(73595.0, .5) AS [EstimatedNumRows],
	'89' AS [ActualNumRows]
UNION ALL
SELECT
	'PRE 2014' AS [Version],
	'Total number of rows raise to the power of .75' AS [Formula],
	POWER(73595.0, .75) AS [EstimatedNumRows],
	'89' AS [ActualNumRows];
GO

/*
Following section shows how estimated rows were calculated pre 2014

--It was worst in pre 2014
--Estimated row 4468.24 compare to 271.3 in SQL2014
--2 Lines of hint to show the difference in estimation when recompile happens
--1 without recompile because no idea about how many rows in the table variable.

DECLARE @OrderDetails2012 TABLE (ContactPersonID int);

INSERT INTO @OrderDetails2012 
	(ContactPersonID)
SELECT 
	ContactPersonID
FROM Sales.Orders AS o;

SELECT 
	* 
FROM @OrderDetails2012 AS od 
WHERE ContactPersonID=1025
--OPTION (USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION')); 
OPTION(RECOMPILE, USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION'));

--Estimated row 4468.24
SELECT POWER(73595.0, .75)

*/

/*
< <=, >, >=
Inequlity with stats but unknown value
Statistics is of no use here as optimizer does not know about the value
Look at 'Estimated number of rows' for 'index seek' operator 22078.5
Estimated rows 22078.5, which is 30 percent of total number fo rows in the table
*/

DECLARE @LowerContactPersonID INT=1024;

SELECT 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID < @LowerContactPersonID;

SELECT 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID <= @LowerContactPersonID;

SELECT 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID > @LowerContactPersonID;

SELECT 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID >= @LowerContactPersonID;
GO

/*
22078.50
*/

SELECT 73595.0 *.3;
GO

/*
For LIKE Operator
9% 6623.55
*/

DECLARE @CustomerPurchaseOrderNumber INT=17521;

SELECT 
	CustomerPurchaseOrderNumber
FROM Sales.Orders
WHERE CustomerPurchaseOrderNumber LIKE @CustomerPurchaseOrderNumber;
GO

/*
6623.55
*/

SELECT 73595 * .09;
GO

/*
For BETWEEN 
SQL 2014  16.4317% = 12092.9
Pre 2014  9% = 6623.55
*/

DECLARE @LowerContactPersonID1 INT=1024;
DECLARE @UpperContactPersonID INT=1027;

SELECT 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID BETWEEN @LowerContactPersonID1 AND @UpperContactPersonID;

SELECT 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID BETWEEN @LowerContactPersonID1 AND @UpperContactPersonID
OPTION (USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION')); 
GO

/*
Looking at cardinality estimation for pre and post 2014
*/

SELECT
	'SQL 2014' AS [Version],
	'16.4317% of Total number of rows' AS [Formula],
	(73595 * .164317)  AS [EstimatedNumRows],
	'211' AS [ActualNumRows]
UNION ALL
SELECT
	'PRE 2014' AS [Version],
	'9% of Total number of rows' AS [Formula],
	(73595.0 * .09) AS [EstimatedNumRows],
	'211' AS [ActualNumRows];
GO