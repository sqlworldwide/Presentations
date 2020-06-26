/*============================================================================
MultiplePredicate.sql
Written by Taiob M Ali
SqlWorldWide.com

This script will demonstrate how estimated numbers of rows are calculated 
when using multiple predicate.

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

--Estimated rows 342.625
SELECT OrderID, CustomerID, SalespersonPersonID, ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID between 1024 and 1027

--Estimated rows 1236.17
SELECT OrderID, CustomerID, SalespersonPersonID, ContactPersonID
FROM Sales.Orders
WHERE CustomerID  between 10 and 20 

--Include Actual Execution Plan (CTRL+M)
--Putting both top queries together
--Look at 'Estimated number of rows' for 'Nested Loops' operator 44.4052
SELECT OrderID, CustomerID, SalespersonPersonID, ContactPersonID
FROM Sales.Orders
WHERE (ContactPersonID between 1024 and 1027)
AND (CustomerID  between 10 and 20)


--2014 approach to conjunctive predicates is to use exponential backoff. 
--Pre 2014 I have explained below which I will not demonstrate in the interest of time.
--Given a table with cardinality C, and predicate selectivities S1, S2, S3 … Sn, where S1 is the most selective and Sn the least
--Estimate = C * S1 * SQRT(S2) * SQRT(SQRT(S3)) * SQRT(SQRT(SQRT(S4))) …
--Estimated rows on the nested loop operator 44.4052021967852
SELECT 
	'SQL 2014' AS [Version], 
	'C * S1 * SQRT(S2) * SQRT(SQRT(S3)) * SQRT(SQRT(SQRT(S4))) …' AS [Formula], 
	(73595)*(342.625/73595)* SQRT(1236.17/73595) AS [EstimatedNumRows], 
	'211' AS [ActualNumRows]
UNION ALL
SELECT 
	'PRE 2014' AS [Version], 
	'C * S1 * S2 * .......*Sn' AS [Formula], 
	(73595) *(261.00/73595)*(1236.17/73595) AS [EstimatedNumRows], 
	'211' AS [ActualNumRows]


--Changing conjunction to disjunction (AND to OR)
--Look at 'Estimated number of rows' for 'Clustered Index Scan' operator 1404.8
SELECT OrderID, CustomerID, SalespersonPersonID, ContactPersonID
FROM Sales.Orders
WHERE (ContactPersonID between 1024 and 1027)
OR (CustomerID  between 10 and 20)


--1404.80079282584
--C * 1-(1-S1) * SQRT(1-S2) .....* SQRT(1-Sn)
--S1, S2, S3 … Sn, where S1 is the least selective and Sn is the most selective
SELECT 
	'SQL 2014' AS [Version], 
	'C * 1-(1-S1) * SQRT(1-S2) .....* SQRT(1-Sn)' AS [Formula], 
	(73595) * (1-((1-1236.17/73595) * SQRT(1-342.625/73595))) AS [EstimatedNumRows], 
	'1235' AS [ActualNumRows]
UNION ALL
SELECT 
	'PRE 2014' AS [Version], 
	'C * (S1+S2+....+Sn)-(S1*S2*.....*Sn)' AS [Formula], 
	(73595) * ((261.0/73595+1236.17/73595)-(261.0/73595*1236.17/73595)) AS [EstimatedNumRows],
	'1235' AS [ActualNumRows]

/*
Following section shows how estimated rows were calculated pre 2014

--Estimated rows 261
SELECT OrderID, CustomerID, SalespersonPersonID, ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID between 1024 and 1027
OPTION(querytraceon  9481, RECOMPILE)

--Estimated rows 1236.17
SELECT OrderID, CustomerID, SalespersonPersonID, ContactPersonID
FROM Sales.Orders
WHERE CustomerID  between 10 and 20 
OPTION(querytraceon  9481, RECOMPILE)

--Include Actual Execution Plan (CTRL+M)
--Putting it together
--Estimated rows on the nested loop iterator output 4.38399
SELECT OrderID, CustomerID, SalespersonPersonID, ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID between 1024 and 1027
AND CustomerID  between 10 and 20
OPTION(querytraceon  9481, RECOMPILE)

-- 4.358028650060800
--C * S1 * SQRT(S2) * SQRT(SQRT(S3)) * SQRT(SQRT(SQRT(S4))) = SQL2014
--C * S1 * S2 * .......*Sn = Pre SQL2014
SELECT (735950 * (261.00/73595)*(1236.17/73595)

--Changing conjunction to disjunction (AND to OR)
--Estimated rows on the nested loop iterator output 1492.78
SELECT OrderID, CustomerID, SalespersonPersonID, ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID between 1024 and 1027
OR CustomerID  between 10 and 20
OPTION(querytraceon  9481, RECOMPILE)

--1485.499150896005240
--C * 1-(1-S1) * SQRT(1-S2) .....* SQRT(1-Sn) =  SQL2014
-- C * (S1+S2+....+Sn)-(S1*S2*.....*Sn) = Pre SQL 2014
SELECT (73595) * ((261.0/73595+1236.17/73595)-(261.0/73595*1236.17/73595))


*/