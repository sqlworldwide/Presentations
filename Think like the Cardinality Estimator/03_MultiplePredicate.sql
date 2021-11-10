/*============================================================================
MultiplePredicate.sql
Written by Taiob Ali
SqlWorldWide.com

This script will demonstrate how estimated numbers of rows are calculated 
when using multiple predicate.

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
Where is 342.625 coming from?
I have few email conversation with Paul White to understand this. Following text is modified from our
email conversation.

The relevant steps of the histogram are:

RANGE_HI_KEY	RANGE_ROWS	EQ_ROWS	DISTINCT_RANGE_ROWS	AVG_RANGE_ROWS
1021	        338	        113	    3	                112.6667
1025	        103	        89	    1	                103
1031	        241	        138	    2	                120.5

The range spans more than one step, so it is split into three component subranges:

1. >= 1024 < 1025
2. = 1025
3. > 1025 <= 1027

Step 2 is easy to calculate because we have EQ_ROWS for RANGE_HI_KEY 1025 = 89.

Step 1 and step 3 mean we need to estimate within a step.

The general idea is to estimate how many of the DISTINCT_RANGE_ROWS will lie within the subrange.

The new CE also assumes that >= and <= within a step will always match one of the distinct values 
(due to the equality part of the comparison) whereas < and > within a step will not.

For step 1, the estimator sees there is one distinct range row with 103 rows per value for the step 
with RANGE_HI_KEY 1025.

The subrange (>= 1024 < 1025) contains an equality component, 
so this part of the calculation assesses that the one distinct range row will be a match.

The step 1 subrange therefore contributes 103 rows.

For step 3, the estimator sees there are two distinct range rows with 120.5 rows per value 
for the covering step with RANGE_HI_KEY 1031.

One of those distinct values is assumed to match because the subrange (> 1025 <= 1027) 
contains an equality component.

The remaining question for step 3 is what are the chances that the one remaining 
DISTINCT_RANGE_ROW will fall within the range (> 1025 < 1027).

The range (> 1025 < 1027) contains one integer value (1026).

But, both ends of that range are excluded. 
The step 3 subrange (> 1025 < 1027) cannot match the 1025 or 1031 values and one of the distinct values
is assumed to match.
so that leaves 4 possible values.

The remainder of step 3 is therefore looking for one value among four values 
so the chance of a match is 1/4 = 0.25.

Step 3 matches one distinct value (the assumed equality match) plus 0.25 of a distinct value 
(chance of a match in the remaining range) = 1.25 distinct values.

Multiplying 1.25 distinct values by the AVG_RANGE_ROWS (120.5) 
gives a step 3 estimate of 150.625 rows.

The final total for all three subranges is 103 (from step 1) + 89 (from step 2) + 150.625 (from step 3)
= 342.625 rows.

The selectivity is 342.625 divided by the cardinality 73,595 
= CONVERT(real, 342.625) / CONVERT(real, 73595) = 0.00465555.

Related reading:
https://dba.stackexchange.com/questions/148523/cardinality-estimation-for-and-for-intra-step-statistics-value
https://dba.stackexchange.com/questions/249057/%d0%a1ardinality-estimation-of-partially-covering-range-predicates
*/

/*
Estimated rows 342.625
*/

SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID BETWEEN 1024 AND 1027;
GO

/*
Estimated rows 1236.17
*/

SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE CustomerID BETWEEN 10 AND 20;
GO

/*
Include Actual Execution Plan (CTRL+M)
Putting both top queries together
Look at 'Estimated number of rows' for 'Nested Loops' operator 44.4052
*/

SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE (ContactPersonID BETWEEN 1024 AND 1027)
	AND (CustomerID BETWEEN 10 AND 20);
GO

/*
2014 approach to conjunctive predicates is to use exponential backoff. 
Pre 2014 I have explained below which I will not demonstrate in the interest of time.
Given a table with cardinality C, and predicate selectivities S1, S2, S3 … Sn, where S1 is the most selective and Sn is the least
Estimate = C * S1 * SQRT(S2) * SQRT(SQRT(S3)) * SQRT(SQRT(SQRT(S4))) …
Estimated rows on the nested loop operator 44.4052021967852
*/

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
	'211' AS [ActualNumRows];
GO

/*
Changing conjunction to disjunction (AND to OR)
Look at 'Estimated number of rows' for 'Clustered Index Scan' operator 1404.8
*/

SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE (ContactPersonID BETWEEN 1024 AND 1027)
	OR (CustomerID  BETWEEN 10 AND 20);
GO

/*
1404.80079282584
C * 1-(1-S1) * SQRT(1-S2) .....* SQRT(1-Sn)
S1, S2, S3 … Sn, where S1 is the least selective and Sn is the most selective
*/

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
	'1235' AS [ActualNumRows];
GO

/*
Following section shows how estimated rows were calculated pre 2014

--Estimated rows 261
SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID BETWEEN 1024 AND 1027
OPTION (USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION'));  
GO
--Hint is encouraged over trace flag
SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID BETWEEN 1024 AND 1027
OPTION(querytraceon 9481, RECOMPILE);
GO

--Estimated rows 1236.17
SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE CustomerID  BETWEEN 10 AND 20 
OPTION (USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION')); 
GO

--Include Actual Execution Plan (CTRL+M)
--Putting it together
--Estimated rows on the nested loop iterator output 4.38399
SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID BETWEEN 1024 AND 1027
AND CustomerID  BETWEEN 10 AND 20
OPTION (USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION')); 
GO;

-- 4.358028650060800
--C * S1 * SQRT(S2) * SQRT(SQRT(S3)) * SQRT(SQRT(SQRT(S4))) = SQL2014
--C * S1 * S2 * .......*Sn = Pre SQL2014
SELECT (735950 * (261.00/73595)*(1236.17/73595);
GO

--Changing conjunction to disjunction (AND to OR)
--Estimated rows on the nested loop iterator output 1492.78
SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID BETWEEN 1024 AND 1027
OR CustomerID  BETWEEN 10 AND 20
OPTION (USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION')); 
GO

--1485.499150896005240
--C * 1-(1-S1) * SQRT(1-S2) .....* SQRT(1-Sn) =  SQL2014
-- C * (S1+S2+....+Sn)-(S1*S2*.....*Sn) = Pre SQL 2014
SELECT (73595) * ((261.0/73595+1236.17/73595)-(261.0/73595*1236.17/73595));
GO
*/