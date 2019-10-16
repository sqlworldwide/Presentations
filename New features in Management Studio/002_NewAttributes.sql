/*
Script Name:002_NewAttributes.sql
DEMO: 
 Time Query Finished
 Per Node
   Actual Time Elapsed
   Actual vs Estimated rows
   Percent of Actual rows
 QueryTimeStats
 WaitStats
   Trace Flag
   Actual I/O Statistics
 Actual Time Statistics
   Actual Elapsed CPU time
   Actual Elapse time ms
 Estimated Number of Rows Read
 Edit Query Button Tooltip(need new SSMS)
 Query store
   new Query Wait Statistics report
*/

/*
Run this to show 
 Time Query Finished (SQL 2012, need new SSMS)
 Per Node
   Actual Time Elapsed (SQL 2012, need new SSMS)
   Actual vs Estimated rows (SQL 2012, need new SSMS)
 QueryTimeStats (SQL2012 SP2, need new SSMS)
 WaitStats (SQL2012 SP2, need new SSMS)
   Trace Flag (SQL2012 SP2, need new SSMS)
   Actual I/O Statistics (SQL2016 RC0, SQL2014SP2, need new SSMS) 
 Actual Time Statistics (SQL2016 RC0, SQL2014SP2, need new SSMS) 
   Actual Number of Rows Read (SQL2016, need new SSMS)
   Estimated Number of Rows Read SQL2016 SP1, need new SSMS)
 Edit Query Button Tooltip(need new SSMS)
 New Query Wait Statistics report(SQL 2017, need new SSMS)
Open 2014plan.sqlplan and show that above features did not exist
*/

--Turn on Actual Execution Plan (Ctrl+M)
USE [AdventureWorks];
GO
SELECT *
FROM [Sales].[SalesOrderDetail] SOD
INNER JOIN [Production].[Product] P ON SOD.ProductID = P.ProductID
WHERE SalesOrderDetailID > 10
ORDER BY Style
OPTION (QUERYTRACEON 9481)
GO

