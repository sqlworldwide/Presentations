/*
Script Name:05_InfamousCXPacket.sql
DEMO:
	QueryTimeStats
    WaitStats
	Trace Flag
	Actual I/O Statistics
    Actual Time Statistics
	Actual Number of Rows Read
	Estimated Number of Rows Read
	Infamous CXPacket
		CXCONSUMER Waittype (SQL2017 CU3, SQL2016 SP2) 
*/

/*
Run this to show 
    QueryTimeStats (SQL2012 SP2, need new SSMS)
    WaitStats (SQL2012 SP2, need new SSMS)
	Trace Flag (SQL2012 SP2, need new SSMS)
	Actual I/O Statistics (SQL2016 RC0, SQL2014SP2, need new SSMS) 
    Actual Time Statistics (SQL2016 RC0, SQL2014SP2, need new SSMS) 
	Actual Number of Rows Read (SQL2016, need new SSMS)
	Estimated Number of Rows Read SQL2016 SP1, need new SSMS)

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

/***********************************
STARTING DEMO FOR CXPACKET
************************************/

--Changing MaxDOP to 0
SELECT name, value_in_use  FROM SYS.configurations
WHERE [name] ='max degree of parallelism'
GO

EXEC sp_configure 'show advanced options', 1;  
GO
RECONFIGURE;  
GO
EXEC sp_configure 'max degree of parallelism', 0;  
GO  
RECONFIGURE;  
GO  

/*
Recycle session
Run this on a separate window
Get current session_id and replace 56
SELECT  *
FROM    sys.dm_exec_session_wait_stats
WHERE   session_id = 56
*/

--Query is copied from 
--https://blogs.msdn.microsoft.com/sql_server_team/making-parallelism-waits-actionable/
--Turn on Actual Execution Plan (Ctrl+M)
--About 10 seconds
USE [AdventureWorks];
GO
SELECT *
FROM [Sales].[SalesOrderDetail] SOD
INNER JOIN [Production].[Product] P ON SOD.ProductID = P.ProductID
WHERE SalesOrderDetailID > 10
ORDER BY Style
GO


--Revert to pre demo satatus
EXEC sp_configure 'max degree of parallelism', 2;  
GO  
RECONFIGURE;  
GO  

