/*
Script Name:003_InfamousCXPacket.sql
	Infamous CXPacket
	CXCONSUMER Waittype (SQL2017 CU3, SQL2016 SP2) 
Making parallelism waits actionable:
https://docs.microsoft.com/en-us/archive/blogs/sql_server_team/making-parallelism-waits-actionable
*/

--Changing MaxDOP to 0
SELECT name, value_in_use  FROM SYS.configurations
WHERE [name] ='max degree of parallelism';
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

/*
Query is copied from 
https://blogs.msdn.microsoft.com/sql_server_team/making-parallelism-waits-actionable/
Turn on Actual Execution Plan (Ctrl+M)
Look at the properties of root node and waitstats, 
you will not see CXCONSUMER as this is not actionable
Run time about 10 seconds
*/
USE [AdventureWorks];
GO
SELECT *
FROM [Sales].[SalesOrderDetail] SOD
INNER JOIN [Production].[Product] P ON SOD.ProductID = P.ProductID
WHERE SalesOrderDetailID > 10
ORDER BY Style;
GO


/*
Do not assume 100% of CXCONSUMER WAIT is harmless.
https://www.brentozar.com/archive/2018/07/cxconsumer-is-harmless-not-so-fast-tiger/ by Erik Darling 
*/

/* Revert to pre demo satatus */
EXEC sp_configure 'max degree of parallelism', 2;  
GO  
RECONFIGURE;  
GO  
