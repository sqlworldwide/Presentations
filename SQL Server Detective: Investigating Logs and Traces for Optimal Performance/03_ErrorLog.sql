/*
File: 03_ErrorLog.sql
Author: Taiob Ali
Email: taiob@sqlworlwide.com
Bluesky: https://bsky.app/profile/sqlworldwide.bsky.social
Blog: https://sqlworldwide.com/
LinkedIn: https://www.linkedin.com/in/sqlworldwide/

Last Modified: October 08, 2025

Tested On:
	- SQL Server 2022 CU21
	- SSMS 21.5.14

References:
- https://www.sqlshack.com/read-sql-server-error-logs-using-the-xp_readerrorlog-command/
- https://www.red-gate.com/simple-talk/databases/sql-server/database-administration-sql-server/search-sql-server-error-log-files/
*/

/*
List error log files with date and size (in bytes).
*/

EXEC sys.sp_enumerrorlogs;
GO

/*
Change retention (SSMS and Registry):
	SSMS: Management -> SQL Server Logs -> Configure

Change location (Configuration Manager, startup parameter):
	SQL Server Configuration Manager
	SQL Server Services -> SQL Server (MSSQLSERVER) -> Properties -> Advanced -> Dump Directory
*/

/*
Change the error log retention.
*/

USE master;
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE',N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQLServer',
N'NumErrorLogs', REG_DWORD, 20;
GO

/*
Demo: SSMS Search vs. Filter
Use the keyword: "wideworldimporters".
*/

/*
Read the error log using sp_readerrorlog (wrapper around xp_ReadErrorLog).
Parameters (max 4):
	@p1 = Log number. Default 0 = current file; 1 = previous; 2 = one before previous, etc.
	@p2 = Log type. NULL or 1 = SQL Server error log; 2 = SQL Server Agent error log.
	@p3 = First search string (optional).
	@p4 = Second search string (optional, further filters results).
*/

EXEC sp_readerrorlog;
EXEC sp_readerrorlog 1, 1;
EXEC sp_readerrorlog 0, 1, N'Warning'
EXEC sp_readerrorlog 0, 1, N'Database',N'Initialization'

/*
Read the error log using xp_ReadErrorLog.
Total of 7 parameters (3 more than sp_readerrorlog):
	@p1 = Log number (0 = current).
	@p2 = Log type (1 = SQL Server, 2 = SQL Server Agent).
	@p3 = First search string (optional).
	@p4 = Second search string (optional).
	@p5 = Start time (optional).
	@p6 = End time (optional).
	@p7 = Sort order ('asc' or 'desc').
*/

EXEC xp_ReadErrorLog
EXEC xp_ReadErrorLog 0, 1, N'Warning'
EXEC xp_ReadErrorLog 0, 1, N'Database',N'Initialization'

/*
Use the three additional parameters: start time, end time, and sort order.
*/

DECLARE @logFileType SMALLINT= 1;
DECLARE @start DATETIME;
DECLARE @end DATETIME;
DECLARE @logno INT= 0;
SET @start = dateadd(dd,-1,getdate()); -- Yesterday's date
Set @end = getdate(); -- Today's date
DECLARE @searchString1 NVARCHAR(256)= 'Database';
DECLARE @searchString2 NVARCHAR(256)= 'Initialization';
EXEC master.dbo.xp_readerrorlog 
	@logno, 
	@logFileType, 
	@searchString1, 
	@searchString2, 
	@start, 
	@end;

/*
Load error log entries into a temporary table.
*/

-- Declare required variables
DECLARE @StartDate DATETIME,
        @EndDate   DATETIME;
-- Create a temporary table to hold error log records
CREATE TABLE #ErrorLogForYesterday (
  LogDate DATETIME NOT NULL, 
  ProcessInfo VARCHAR(MAX) NOT NULL, 
  Text VARCHAR(MAX) NOT NULL);
SET @StartDate = dateadd(dd,-1,getdate()); -- Yesterday's date
Set @EndDate = getdate(); -- Today's date
-- Extract error log records for yesterday into the temporary table
INSERT INTO #ErrorLogForYesterday
(
    LogDate,
    ProcessInfo,
    Text
)
EXEC xp_readerrorlog 0, 1, N'', N'', @StartDate, @EndDate, 'DESC';
-- Display extracted error log records
SELECT 
	LogDate,
	ProcessInfo,
	Text 
FROM #ErrorLogForYesterday;
-- Cleanup
DROP TABLE #ErrorLogForYesterday;
GO
