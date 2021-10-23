/*============================================================================
GENERATE_DBCC_SHOW_STATISTICS.sql
Written by Taiob Ali
SqlWorldWide.com

This script will generate the numbers for DBCC SHOW_STATISTICS ouput using select statements.

Instruction to run this script
--------------------------------------------------------------------------
Run this on a separate window
USE WideWorldImporters;
GO

DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID]);
GO  
============================================================================*/

USE [WideWorldImporters]; 
GO

SELECT
	'STAT_HEADER'  AS [Section],
	'Updated' AS [ColumnName],
	CONVERT(VARCHAR(256),(SELECT
		STATS_DATE(OBJECT_ID, index_id) AS StatsUpdated
FROM sys.indexes
WHERE OBJECT_ID = OBJECT_ID('Sales.Orders')
	AND Name ='FK_Sales_Orders_ContactPersonID')) AS [Value],
	'When was statistics last updated' AS [Description]
UNION ALL
SELECT
	'STAT_HEADER'  AS [Section],
	'Rows'    AS [ColumnName],
	CONVERT (VARCHAR(256),COUNT(*)) AS [Value],
	'Total Number of Rows in the Table' AS [Description]
FROM [sales].[Orders]
UNION ALL
SELECT
	'DENSITY_VECTOR'   AS [Section],
	'All density'  AS [ColumnName],
	CONVERT (VARCHAR(256),CONVERT(DECIMAL(10, 9), 1.0 / ( Count(DISTINCT contactpersonid) ))) AS [Value],
	'1/Number of DISTINCT ContactPersonId' AS [Description]
FROM [sales].[Orders]
UNION ALL
SELECT
	'DENSITY_VECTOR'   AS [Section],
	'All density'  AS [ColumnName],
	CONVERT (VARCHAR(256), (CONVERT(DECIMAL(20, 12), 1.0 / 
		(SELECT Count(*)
	FROM (SELECT DISTINCT contactpersonid, orderid
		FROM sales.orders)T1)))) AS [Value],
	'1/Number of DISTINCT ContactPersonId + OrderID' AS [Description]
UNION ALL
SELECT
	'HISTOGRAM'   AS [Section],
	'RANGE_ROWS'  AS [ColumnName],
	CONVERT (VARCHAR(256),
	(SELECT COUNT(0) AS [RANGE_ROWS_KEY2083]
FROM sales.orders
WHERE ContactPersonID BETWEEN 2084 AND 2090)) AS [Value],
	'Total number or rows BETWEEN 2084 AND 2090' AS [Description]
UNION ALL
SELECT
	'HISTOGRAM'   AS [Section],
	'EQ_ROWS'    AS [ColumnName],
	CONVERT (VARCHAR(256),
	(SELECT COUNT(0) AS [EQ_ROWS_KEY2083]
FROM sales.orders
WHERE ContactPersonID=2083)) AS [Value],
	'Total number or rows WHERE ContactPersonID=2083 ' AS [Description]
UNION ALL
SELECT
	'HISTOGRAM'   AS [Section],
	'DISTINCT_RANGE_ROWS'    AS [ColumnName],
	CONVERT (VARCHAR(256),
	(SELECT COUNT(DISTINCT ContactPersonID) AS [DISTINCT_RANGE_ROWS_KEY2083]
FROM sales.orders
WHERE ContactPersonID BETWEEN 2084 AND 2090)) AS [Value],
	'DISTINCT ContactPersonID BETWEEN 2084 AND 2090' AS [Description]
UNION ALL
SELECT
	'HISTOGRAM'   AS [Section],
	'AVG_RANGE_ROWS'    AS [ColumnName],
	CONVERT (VARCHAR(256),
	(SELECT CONVERT(DECIMAL(7, 4), (CONVERT (DECIMAL (7,4),
	(SELECT COUNT(0)
FROM sales.orders
WHERE ContactPersonID BETWEEN 2084 AND 2090)))/
	(SELECT Count(0)
	 FROM (SELECT DISTINCT contactpersonid
	 FROM sales.orders
	 WHERE ContactPersonID BETWEEN 2084 AND 2090) t1)))) AS [Value],
	'RANGE_ROWS divided by DISTINCT_RANGE_ROWS' AS [Description];
GO