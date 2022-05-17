/*
Script Name: 010_CompareShowplan.sql

Demo: 
	New Icon(SSMS 17.4)
	Compare Showplan Improvement (new SSMS)
*/

USE [AdventureWorks];
GO

/*
Making sure it is reverted from previous demo
Changing compatibility level to SQL 2019
*/
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 150; 
GO

/* Create a stored procedure */

DROP PROCEDURE IF EXISTS Sales.SalesFromDate;
GO

CREATE PROCEDURE Sales.SalesFromDate (@StartOrderdate datetime) AS 
SELECT *
FROM Sales.SalesOrderHeader AS h 
INNER JOIN Sales.SalesOrderDetail AS d ON h.SalesOrderID = d.SalesOrderID
WHERE (h.OrderDate >= @StartOrderdate);
GO

/*
Turn on Actual Execution Plan (Ctrl+M)
Run only first one
Save execution plan
Note run time
*/
EXEC sp_executesql N'exec Sales.SalesFromDate @P1',N'@P1 datetime2(0)','2014-6-15 00:00:00';
GO

/*
Run second one
Note run time
If time permits show with recompile
SP_RECOMPILE  N'Sales.SalesFromDate'
*/
EXEC sp_executesql N'exec Sales.SalesFromDate @P1',N'@P1 datetime2(0)','2012-3-28 00:00:00'
GO

/*
Compare plan and see runtime, parameter, estimated vs actual row
*/