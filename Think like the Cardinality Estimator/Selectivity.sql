--Generate Selectivity manually
--# rows that pass the predicate/total number of rows

USE WideWorldImporters;
GO

--150 records
SELECT COUNT(0) AS [NumberOfOrders90] FROM sales.Orders 
WHERE CustomerID=90;
GO

--75 records
SELECT COUNT(0) AS [NumberOfOrders577] FROM sales.Orders 
WHERE CustomerID=577;
GO

--High selectivity
--150/73595 .002
--150 records
SELECT CONVERT(DECIMAL(6,4),
CONVERT (DECIMAL,(SELECT COUNT(0) FROM sales.Orders WHERE CustomerID=90))/
CONVERT (DECIMAL, (SELECT count(0) FROM sales.Orders))) AS [HighSelectivity];
GO


--Low selectivity
--75/73595 .001
--75 records
SELECT CONVERT(DECIMAL(6,4),
CONVERT (DECIMAL,(SELECT count(0) FROM sales.Orders WHERE CustomerID=577))/
CONVERT (DECIMAL, (SELECT count(0) FROM sales.Orders))) AS [LowSelectivity];
GO


