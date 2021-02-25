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
 Modified Estimated Number of Rows in SSMS to "Estimated Number of Rows Per Execution" 
 Estimated Number of Rows for All Executions 
 Modify the property Actual Number of Rows to Actual Number of Rows for All Executions
 Edit Query Button Tooltip(need new SSMS)
 Query store
   New Query Wait Statistics report
   Max Plan per query value in the dialog properties
   New Custom Capture Policies

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
 Estimated Number of Rows to be Read SQL2016 SP1, need new SSMS)
 Edit Query Button Tooltip(need new SSMS)
 New Query Wait Statistics report(SQL 2017, need new SSMS)
 Max Plan per query value in the dialog properties
 New Custom Capture Policies
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
OPTION (QUERYTRACEON 9481);
GO

/*
Query copied from 
https://sqlserverfast.com/blog/hugo/2020/04/ssms-18-5-small-change-huge-effect/

Modified Estimated Number of Rows in SSMS to "Estimated Number of Rows Per Execution" 
Estimated Number of Rows for All Executions 
Modify the property 'Actual Number of Rows' to 'Actual Number of Rows for All Executions'

Old confusion with estimated number of rows during nested loop join:
https://sqlserverfast.com/blog/hugo/2020/04/ssms-18-5-small-change-huge-effect/
*/
--Turn on Actual Execution Plan (Ctrl+M)
USE [AdventureWorks];
GO
SELECT 
  sod.SalesOrderID,
  sod.SalesOrderDetailID,
  sod.CarrierTrackingNumber,
  soh.ShipDate
FROM Sales.SalesOrderDetail AS sod
JOIN Sales.SalesOrderHeader AS soh
  ON soh.SalesOrderID = sod.SalesOrderID
WHERE soh.SalesPersonID = 285;

