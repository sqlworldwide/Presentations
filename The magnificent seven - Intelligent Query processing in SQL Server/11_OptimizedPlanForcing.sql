/*
11_OptimizedPlanForcing.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modiefied
August 17, 2025
	
Tested on :
SQL Server 2022 CU20
SSMS 21.4.12

This code is copied from
https://github.com/microsoft/bobsql/tree/master/demos/sqlserver2022/IQP/opf
	
Optimized plan forcing with Query Store
Applies to:  SQL Server 2022 (16.x)
Available in all Editions

Optimized plan forcing is enabled by default for new databases created in SQL Server 2022 (16.x) and higher. The Query Store must be enabled for every database where optimized plan forcing is used. 

Only query plans that go through full optimization are eligible, which can be verified by the presence of the StatementOptmLevel="FULL" property.
Statements with RECOMPILE hint and distributed queries aren't eligible.
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
Takes ~15 seconds
Notice compile time vs execution time and paste here
SQL Server parse and compile time: 
   CPU time = 125 ms, elapsed time = 157 ms.
 SQL Server Execution Times:
   CPU time = 1891 ms,  elapsed time = 10317 ms.
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
Take note of the numbers for compile duration and note here:
avg_compile_ms	last_compile_ms
169.313					169
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
Compare with line 43
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
Take note of the numbers for compile duration and note here:
Comapre with line 102
*/

USE WideWorldImporters;
GO
SELECT query_id, plan_id, avg_compile_duration/1000 as avg_compile_ms, 
last_compile_duration/1000 as last_compile_ms, has_compile_replay_script, 
cast(query_plan as xml) query_plan_xml
FROM sys.query_store_plan;
GO
