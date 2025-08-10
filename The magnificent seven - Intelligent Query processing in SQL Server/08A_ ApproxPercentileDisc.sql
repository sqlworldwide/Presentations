/**************************************************************
08A_ ApproxPercentileDisc.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modiefied
August 09, 2025
	
Tested on :
SQL Server 2022 CU20
SSMS 21.4.8
	
Approximate Percentile
Applies to: SQL Server (Starting with SQL Server 2022 (16.x)) with compatibility level 110, Azure SQL Database with compatibility level 110
Available in all Editions
The function implementation guarantees up to a 1.33% error bounds within a 99% confidence
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
Using existing PERCENTILE_CONT and PERCENTILE_DISC

PERCENTILE_CONT
Calculates a percentile based on a continuous distribution of the column value in the SQL Server Database Engine. The result is interpolated, and might not equal any of the specific values in the column.

PERCENTILE_DISC
Computes a specific percentile for sorted values in an entire rowset or within a rowset's distinct partitions in SQL Server. 

Memory Grant 3400 MB
*/

USE AdventureWorks_ext
GO
SELECT 
  DISTINCT Name AS DepartmentName, 
  PERCENTILE_CONT(0.1) WITHIN GROUP (ORDER BY ph.Rate) OVER (PARTITION BY Name) AS MedianContP10,
  PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY ph.Rate) OVER (PARTITION BY Name) AS MedianContP90,
  PERCENTILE_DISC(0.1) WITHIN GROUP (ORDER BY ph.Rate) OVER (PARTITION BY Name) AS MedianDiscP10,
  PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY ph.Rate) OVER (PARTITION BY Name) AS MedianDiscP90 
FROM HumanResources.Department AS d  
INNER JOIN HumanResources.EmployeeDepartmentHistory AS dh   
ON dh.DepartmentID = d.DepartmentID  
INNER JOIN HumanResources.EmployeePayHistory AS ph  
ON ph.BusinessEntityID = dh.BusinessEntityID  
WHERE dh.EndDate IS NULL;  
GO

/*
Turn on Actual Execution plan ctrl+M
Using new APPROX_PERCENTILE_CONT and APPROX_PERCENTILE_DISC
Memory Grant 2768 MB
*/
USE AdventureWorks_ext
GO
SELECT 
  DISTINCT Name AS DepartmentName,
  APPROX_PERCENTILE_CONT(0.1) WITHIN GROUP (ORDER BY ph.Rate) AS AppxMedianContP10, 
  APPROX_PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY ph.Rate) AS AppxMedianContP90, 
  APPROX_PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY ph.Rate) AS AppxMedianDiscP10,
  APPROX_PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY ph.Rate) AS AppxMedianDiscP90
FROM HumanResources.Department AS d  
INNER JOIN HumanResources.EmployeeDepartmentHistory AS dh   
ON dh.DepartmentID = d.DepartmentID  
INNER JOIN HumanResources.EmployeePayHistory AS ph  
ON ph.BusinessEntityID = dh.BusinessEntityID  
WHERE dh.EndDate IS NULL
GROUP BY Name;  

/*
Turn on Actual Execution plan ctrl+M
Using existing PERCENTILE_CONT
Calculates a percentile based on a continuous distribution of the column value in the SQL Server Database Engine. The result is interpolated, and might not equal any of the specific values in the column.
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
