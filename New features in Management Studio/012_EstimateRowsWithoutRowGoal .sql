/*
Script Name: 012_EstimateRowsWithoutRowGoal 
Demo-Row Goal (SQL2016 SP2, need new SSMS)
Common Scenarios you can introduce Row Goal:
	TOP clause 
	FAST number_rows query hint
	IN or EXISTS clause
	SET ROWCOUNT { number | @number_var } 
https://blogs.msdn.microsoft.com/sql_server_team/more-showplan-enhancements-row-goal/
https://support.microsoft.com/en-us/help/4051361/optimizer-row-goal-information-in-query-execution-plan-added-in-sql-se
https://www.sql.kiwi/2010/08/inside-the-optimiser-row-goals-in-depth.html
*/

/* Turn on Actual Execution Plan (Ctrl+M) */

USE [AdventureWorks];
GO
SELECT TOP (13) *
FROM Sales.SalesOrderHeader AS s 
    INNER JOIN Sales.SalesOrderDetail AS d ON s.SalesOrderID = d.SalesOrderID
WHERE s.TotalDue > 1000
OPTION (RECOMPILE);
GO

/*
Look at the plan
Notice the physical join type
Look at Clustered index scan.  See the diff in values for EstimateRows and EstimateRowsWithoutRowGoal

Running the same query using hint 'DISABLE_OPTIMIZER_ROWGOAL'
Intorduced in SQL2016 SP1
Same effect as previous TF4138
*/
USE [AdventureWorks];
GO
SELECT TOP (13) *
FROM Sales.SalesOrderHeader AS s 
    INNER JOIN Sales.SalesOrderDetail AS d ON s.SalesOrderID = d.SalesOrderID
WHERE s.TotalDue > 1000
OPTION (RECOMPILE, USE HINT('DISABLE_OPTIMIZER_ROWGOAL'));
GO

/*
look at the plan
Notice the join type changed
Look at the clustered index scan, notice 'Estimated number of rows'

Sometimes Row Goals hurt
Turn on Actual Execution Plan (Ctrl+M)
*/
SELECT TOP 250 *
FROM Production.TransactionHistory H
INNER JOIN Production.Product P ON  H.ProductID = P.ProductID
OPTION (RECOMPILE)
GO

/*
Disable Row Goal, physical join change and Product becomes build table for hash join
TransactionHistory is a big table but we only have to probe 250 times.
*/
SELECT TOP 250 *
FROM Production.TransactionHistory H
INNER JOIN Production.Product P ON  H.ProductID = P.ProductID
OPTION (RECOMPILE, USE HINT('DISABLE_OPTIMIZER_ROWGOAL'))
GO