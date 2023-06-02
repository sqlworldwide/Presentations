/*
	Script Name: 11_OptimizedPlanForcing.sql
	This code is copied from
	https://github.com/microsoft/bobsql/tree/master/demos/sqlserver2022/IQP/opf
	
	Modified by Taiob Ali
	May 29, 2023
	Optimized plan forcing with Query Store
	Applies to:  SQL Server 2022 (16.x)
	Available in all Editions
*/

USE WideWorldImporters;
GO
ALTER DATABASE current SET COMPATIBILITY_LEVEL = 160;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
ALTER DATABASE current SET QUERY_STORE CLEAR;
GO

/*
	Turn on Actual Execution plan ctrl+M
	Takes about 26 seconds
	Notice compile time vs execution time and paste here
*/

USE WideWorldImporters;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SET STATISTICS TIME ON;
GO
SELECT o.OrderID, ol.OrderLineID, c.CustomerName, cc.CustomerCategoryName, p.FullName, city.CityName, sp.StateProvinceName, country.CountryName, si.StockItemName
FROM Sales.Orders o
JOIN Sales.Customers c
ON o.CustomerID = c.CustomerID
JOIN Sales.CustomerCategories cc
ON c.CustomerCategoryID = cc.CustomerCategoryID
JOIN Application.People p
ON o.ContactPersonID = p.PersonID
JOIN Application.Cities city
ON city.CityID = c.DeliveryCityID
JOIN Application.StateProvinces sp
ON city.StateProvinceID = sp.StateProvinceID
JOIN Application.Countries country
ON sp.CountryID = country.CountryID
JOIN Sales.OrderLines ol
ON ol.OrderID = o.OrderID
JOIN Warehouse.StockItems si
ON ol.StockItemID = si.StockItemID
JOIN Warehouse.StockItemStockGroups sisg
ON si.StockItemID = sisg.StockItemID
UNION ALL
SELECT o.OrderID, ol.OrderLineID, c.CustomerName, cc.CustomerCategoryName, p.FullName, city.CityName, sp.StateProvinceName, country.CountryName, si.StockItemName
FROM Sales.Orders o
JOIN Sales.Customers c
ON o.CustomerID = c.CustomerID
JOIN Sales.CustomerCategories cc
ON c.CustomerCategoryID = cc.CustomerCategoryID
JOIN Application.People p
ON o.ContactPersonID = p.PersonID
JOIN Application.Cities city
ON city.CityID = c.DeliveryCityID
JOIN Application.StateProvinces sp
ON city.StateProvinceID = sp.StateProvinceID
JOIN Application.Countries country
ON sp.CountryID = country.CountryID
JOIN Sales.OrderLines ol
ON ol.OrderID = o.OrderID
JOIN Warehouse.StockItems si
ON ol.StockItemID = si.StockItemID
JOIN Warehouse.StockItemStockGroups sisg
ON si.StockItemID = sisg.StockItemID
ORDER BY OrderID;
GO

/*
	Find the plan_id and query_id for the recent query. 
	Notice the column has_compile_replay_script has a value = 1. 
	This means this query is a candidate for optimized plan forcing. 
	Take note of the numbers for compile duration and not here:
*/

USE WideWorldImporters;
GO
SELECT query_id, plan_id, avg_compile_duration/1000 as avg_compile_ms, 
last_compile_duration/1000 as last_compile_ms, has_compile_replay_script, 
cast(query_plan as xml) query_plan_xml
FROM sys.query_store_plan;
GO

/*
	Edit the script to put in the correct values for the @query_id and @plan_id parameter values. 
*/
EXEC sp_query_store_force_plan @query_id = 1, @plan_id = 1;
GO

/*
	Run the same join again. 
	Notice the significant reduction in SQL Server parse and compile time from the initial execution as a % of CPU time for the query. 
	It can drop down as low as 2-3%.
*/

USE WideWorldImporters;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SET STATISTICS TIME ON;
GO
SELECT o.OrderID, ol.OrderLineID, c.CustomerName, cc.CustomerCategoryName, p.FullName, city.CityName, sp.StateProvinceName, country.CountryName, si.StockItemName
FROM Sales.Orders o
JOIN Sales.Customers c
ON o.CustomerID = c.CustomerID
JOIN Sales.CustomerCategories cc
ON c.CustomerCategoryID = cc.CustomerCategoryID
JOIN Application.People p
ON o.ContactPersonID = p.PersonID
JOIN Application.Cities city
ON city.CityID = c.DeliveryCityID
JOIN Application.StateProvinces sp
ON city.StateProvinceID = sp.StateProvinceID
JOIN Application.Countries country
ON sp.CountryID = country.CountryID
JOIN Sales.OrderLines ol
ON ol.OrderID = o.OrderID
JOIN Warehouse.StockItems si
ON ol.StockItemID = si.StockItemID
JOIN Warehouse.StockItemStockGroups sisg
ON si.StockItemID = sisg.StockItemID
UNION ALL
SELECT o.OrderID, ol.OrderLineID, c.CustomerName, cc.CustomerCategoryName, p.FullName, city.CityName, sp.StateProvinceName, country.CountryName, si.StockItemName
FROM Sales.Orders o
JOIN Sales.Customers c
ON o.CustomerID = c.CustomerID
JOIN Sales.CustomerCategories cc
ON c.CustomerCategoryID = cc.CustomerCategoryID
JOIN Application.People p
ON o.ContactPersonID = p.PersonID
JOIN Application.Cities city
ON city.CityID = c.DeliveryCityID
JOIN Application.StateProvinces sp
ON city.StateProvinceID = sp.StateProvinceID
JOIN Application.Countries country
ON sp.CountryID = country.CountryID
JOIN Sales.OrderLines ol
ON ol.OrderID = o.OrderID
JOIN Warehouse.StockItems si
ON ol.StockItemID = si.StockItemID
JOIN Warehouse.StockItemStockGroups sisg
ON si.StockItemID = sisg.StockItemID
ORDER BY OrderID;
GO

/*
	We want to ensure we have the latest persisted data in QDS 
*/
USE WideWorldImporters;
GO
EXEC sys.sp_query_store_flush_db;
GO


/*
	Find the plan_id and query_id for the recent query. 
	Notice the column has_compile_replay_script has a value = 1. 
	This means this query is a candidate for optimized plan forcing. 
	Take note of the numbers for compile duration and not here:
	Comapre with line 81
*/

USE WideWorldImporters;
GO
SELECT query_id, plan_id, avg_compile_duration/1000 as avg_compile_ms, 
last_compile_duration/1000 as last_compile_ms, has_compile_replay_script, 
cast(query_plan as xml) query_plan_xml
FROM sys.query_store_plan;
GO
