/*
Script Name: 04_WaitEvents.sql
Written by Taiob M Ali
SqlWorldWide.com

This script will 
1. Create a stored procedure on adventureworks database for demo purposes only
2. Create an Extended Event trace defination to capture wait_type=179 (ASYNC_NETWORK_IO)
   if it happens over 4000 times. Only capture 4 of those. 
2. Run the trace
3. Look at the collected data
4. Stop the trace
5. Clean up

Pre-requisite:
Download and restore AdventureWorks backup from github before you attempt the scripts below.
https://github.com/Microsoft/sql-server-samples/releases/tag/adventureworks
*/


USE [AdventureWorks];
GO
--Create a stored procedure 
DROP PROCEDURE IF EXISTS Sales.SalesFromDate;
GO
CREATE PROCEDURE Sales.SalesFromDate
  (@StartOrderdate datetime)
AS
SELECT *
FROM Sales.SalesOrderHeader AS h
  INNER JOIN Sales.SalesOrderDetail AS d ON h.SalesOrderID = d.SalesOrderID
WHERE (h.OrderDate >= @StartOrderdate);
GO

--Housekeeping--deleting old files if exist.
--Do not use xp_cmdshell unless you know the risk.
DECLARE @deletefile varchar(20)='LongRunningSP*.*';
DECLARE @cmd NVARCHAR(MAX) =  
'xp_cmdshell ''del "C:\temp\' + @deletefile + '"''';
EXEC (@cmd)

--Drop session if exists
IF EXISTS(SELECT *
FROM sys.server_event_sessions
WHERE name='LongRunningSP')
  DROP EVENT session LongRunningSP ON SERVER;
GO

--Create the session
CREATE EVENT SESSION LongRunningSP ON SERVER 
ADD EVENT sqlos.wait_info(
  ACTION(sqlserver.sql_text)
  WHERE ([package0].[equal_uint64]([wait_type],(179))
    AND [opcode]=(1)
    AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%SalesFromDate%') 
    AND [package0].[less_than_uint64]([package0].[counter],(4005))
    AND [package0].[greater_than_uint64]([package0].[counter],(4000))     
    ))
ADD TARGET package0.event_file(SET filename=N'c:\temp\LongRunningSP')
WITH (MAX_DISPATCH_LATENCY = 1 SECONDS);
GO

--Start the session
ALTER EVENT SESSION LongRunningSP ON SERVER  
STATE = start;  
GO

--Calling the stored procedure.
USE [AdventureWorks];
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
EXEC sp_executesql N'exec Sales.SalesFromDate @P1',N'@P1 datetime2(0)','2011-3-28 00:00:00';
GO

--Stop the Extended Event session
ALTER EVENT SESSION LongRunningSP ON SERVER  
STATE = stop;  
GO

--Looking at the result.
SELECT CAST(event_data AS XML) xml_event_data, *
FROM sys.fn_xe_file_target_read_file('C:\Temp\LongRunningSP*.xel', 'C:\Temp\LongRunningSP*.xem', NULL, NULL);
GO

--Clean up
--Drop the session
IF EXISTS(SELECT *
FROM sys.server_event_sessions
WHERE name='LongRunningSP')
  DROP EVENT session LongRunningSP ON SERVER;
GO