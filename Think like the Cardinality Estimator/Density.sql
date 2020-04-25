--Generate DENSITY manually
--1/# of distinct values in a column


USE WideWorldImporters;
GO
--10 records
SELECT COUNT(DISTINCT SalespersonPersonID) AS [DistinctSalesPersonID] 
FROM sales.Orders;
GO

--663 records
SELECT COUNT(DISTINCT CustomerID)  AS [CustomerID]
FROM sales.Orders;
GO

--Higher density (less number of records qualified)
--10 records
--0.10000000
SELECT CONVERT(DECIMAL(10,8),1.0 / ( Count(DISTINCT SalespersonPersonID))) AS [densityOfSalespersonPersonID] 
FROM sales.Orders;


--Lower density (less number of records qualified)
--663 records
--0.00150830
SELECT CONVERT(DECIMAL(10,8),1.0 / ( Count(DISTINCT CustomerID))) AS [densityOfCustomerID] 
FROM sales.Orders;
