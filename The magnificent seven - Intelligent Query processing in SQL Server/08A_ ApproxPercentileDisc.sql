/**************************************************************
	Scirpt Name: 08A_ ApproxPercentileDisc.sql
	Written by Taiob Ali
	June 01, 2023
	
	Approximate Percentile
	Applies to: SQL Server (Starting with SQL Server 2022 (16.x)), Azure SQL Database
	Available in all Editions
	Using a table with 20,000,000 records
*************************************************************/
SET NOCOUNT ON;
GO

/*
	Set maxdop to zero
*/

USE [master]
GO
EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
EXEC sp_configure 'max degree of parallelism', 0;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  

/*
	Turn on Actual Execution plan ctrl+M
	Using existing PERCENTILE_DISC
	Takes 2 min 59 seconds to run
	Estimated subtree cost 10131
	Memory Grant 822 MB
*/

USE WideWorldImporters;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SELECT DISTINCT
	Brand,
	PERCENTILE_DISC(0.10) WITHIN GROUP(ORDER BY Brand) OVER (PARTITION BY SupplierId) AS 'P10',
	PERCENTILE_DISC(0.90) WITHIN GROUP(ORDER BY Brand) OVER (PARTITION BY SupplierId) AS 'P90'
FROM Warehouse.StockItems;
GO

/*
	Turn on Actual Execution plan ctrl+M
	Using new  APPROX_PERCENTILE_DISC
	Takes 5 seconds to run
	Estimated subtree cost 305
	Memory Grant 6.1 MB
*/

USE WideWorldImporters;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SELECT DISTINCT
	Brand,
	APPROX_PERCENTILE_DISC(0.10) WITHIN GROUP(ORDER BY SupplierId) AS 'P10',
	APPROX_PERCENTILE_DISC(0.90) WITHIN GROUP(ORDER BY SupplierId) AS 'P90'
FROM Warehouse.StockItems
GROUP BY Brand;
GO

/*
	Turn on Actual Execution plan ctrl+M
	Using existing PERCENTILE_CONT
	Takes 25 seconds to run
	Estimated subtree cost 2927
	Memory Grant 1467 MB
*/

USE WideWorldImporters;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SELECT DISTINCT
	Brand,
	PERCENTILE_CONT(0.10) WITHIN GROUP(ORDER BY SupplierId) OVER (PARTITION BY Brand) AS 'P10',
	PERCENTILE_CONT(0.90) WITHIN GROUP(ORDER BY SupplierId) OVER (PARTITION BY Brand) AS 'P90'
FROM Warehouse.StockItems;
GO

/*
	Turn on Actual Execution plan ctrl+M
	Using new  APPROX_PERCENTILE_CONT
	Takes 6 seconds to run
	Estimated subtree cost 305
	Memory Grant 6.2 MB
*/

USE WideWorldImporters;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SELECT DISTINCT
	Brand,
	APPROX_PERCENTILE_CONT(0.10) WITHIN GROUP(ORDER BY SupplierId) AS 'P10',
	APPROX_PERCENTILE_CONT(0.90) WITHIN GROUP(ORDER BY SupplierId) AS 'P90'
FROM Warehouse.StockItems
GROUP BY Brand;
GO

/*
	Revert MAXDOP Setting
*/

EXEC sp_configure 'max degree of parallelism', 2;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
