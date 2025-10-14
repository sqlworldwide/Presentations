/*============================================================================
File: 04_AgentErrorLog.sql
Author: Taiob Ali
Email: taiob@sqlworlwide.com
Bluesky: https://bsky.app/profile/sqlworldwide.bsky.social
Blog: https://sqlworldwide.com/
LinkedIn: https://www.linkedin.com/in/sqlworldwide/

Last Modified: October 08, 2025

Tested On:
	- SQL Server 2022 CU21
	- SSMS 21.5.14
============================================================================*/

/*
Change error log location (DO NOT RUN IN DEMO)

Example:
  USE [msdb];
  EXEC msdb.dbo.sp_set_sqlagent_properties @errorlog_file = N'C:\\temp\\test.out';
*/

/*
Write OEM file (DO NOT RUN IN DEMO)
Writes the error log as a non-Unicode (OEM) file, reducing disk usage.
Trade-off: Messages containing Unicode characters may be harder to read.

Example:
  USE [msdb];
  EXEC msdb.dbo.sp_set_sqlagent_properties @oem_errorlog = 0;
*/

/*
Include execution trace messages
Enables detailed execution trace output in the SQL Agent error log. This consumes more disk space
and should be enabled only for troubleshooting.
Examples of trace entries:
  [184] Job completion for DummyJob is being logged to sysjobhistory
  [177] Job DummyJob has been requested to run by User taiob2\taiob
*/

USE [msdb]
GO
EXEC dbo.sp_set_sqlagent_properties @errorlogging_level=7
GO
EXEC dbo.sp_start_job @job_name = 'DummyJob'
GO
-- See the first two records
EXEC xp_ReadErrorLog 0, 2, N'', N'', NULL, NULL, 'DESC';
GO
-- Revert to default logging level
EXEC dbo.sp_set_sqlagent_properties @errorlogging_level=3
GO
        
/*
Configure idle CPU condition
Use this to trigger maintenance tasks (e.g., backups, index maintenance) when CPU usage
falls below a specified threshold for a defined duration.
*/

USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties 
	@cpu_poller_enabled=1, 
	@idle_cpu_percent=15, 
	@idle_cpu_duration=1200
GO

/*
Other configurable properties (for reference):
 @auto_start                  INT           = NULL, -- 1 or 0
  -- Non-SQLDMO exposed properties
  @sqlserver_restart           INT           = NULL, -- 1 or 0
  @jobhistory_max_rows         INT           = NULL, -- No maximum = -1, otherwise must be > 1
  @jobhistory_max_rows_per_job INT           = NULL, -- 1 to @jobhistory_max_rows
  @errorlog_file               NVARCHAR(255) = NULL, -- Full drive\path\name of errorlog file
  @errorlogging_level          INT           = NULL, -- 1 = error, 2 = warning, 4 = information
  @error_recipient             NVARCHAR(30)  = NULL, -- Network address of error popup recipient
  @monitor_autostart           INT           = NULL, -- 1 or 0
  @local_host_server           SYSNAME      = NULL, -- Alias of local host server
  @job_shutdown_timeout        INT           = NULL, -- 5 to 600 seconds
  @cmdexec_account             VARBINARY(64) = NULL, -- CmdExec account information
  @regular_connections         INT           = NULL, -- obsolete
  @host_login_name             SYSNAME       = NULL, -- obsolete
  @host_login_password         VARBINARY(512) = NULL, -- obsolete
  @login_timeout               INT           = NULL, -- 5 to 45 (seconds)
  @idle_cpu_percent            INT           = NULL, -- 1 to 100
  @idle_cpu_duration           INT           = NULL, -- 20 to 86400 seconds
  @oem_errorlog                INT           = NULL, -- 1 or 0
  @sysadmin_only               INT           = NULL, -- not applicable to Yukon server, for backwards compatibility only
  @email_profile               NVARCHAR(64)  = NULL, -- obsolete - SQLMail profile, Rely on DBMail for notifications
  @email_save_in_sent_folder   INT           = NULL, -- obsolete
  @cpu_poller_enabled          INT           = NULL, -- 1 or 0
  @alert_replace_runtime_tokens INT          = NULL, -- 1 or 0
  @use_databasemail            INT           = NULL,  -- 1 or 0
  @databasemail_profile        SYSNAME       = NULL
*/

/*
Read current SQL Agent error log using sp_readerrorlog (wrapper around xp_ReadErrorLog).
Parameters (max 4):
  @p1 = Log number (0 = current; 1 = previous, etc.).
  @p2 = Log type (1 = SQL Server, 2 = SQL Agent). NULL similar to 1.
  @p3 = Search string 1 (optional).
  @p4 = Search string 2 (optional, further filters results).
*/

EXEC sp_readerrorlog 0, 2;
EXEC sp_readerrorlog 0, 2, N'SQLServerAgent';
EXEC sp_readerrorlog 0, 2, N'SQLServerAgent', N'startup service account';

/*
Read SQL Agent error log using xp_ReadErrorLog.
7 parameters (3 more than sp_readerrorlog):
  @p1 = Log number.
  @p2 = Log type (2 = SQL Agent here).
  @p3 = Search string 1.
  @p4 = Search string 2.
  @p5 = Start time (optional).
  @p6 = End time (optional).
  @p7 = Sort order ('asc' or 'desc').
*/
EXEC xp_readerrorlog 0, 2;
EXEC xp_readerrorlog 0, 2, N'SQLServerAgent';
EXEC xp_readerrorlog 0, 2, N'SQLServerAgent', N'startup service account';

/*
Use the three additional parameters (start time, end time, sort order filter via execution order).
*/
DECLARE @logFileType SMALLINT= 2;
DECLARE @start DATETIME;
DECLARE @end DATETIME;
DECLARE @logno INT= 0;
SET @start = dateadd(dd,-3,getdate());
SET @end = GETDATE()
DECLARE @searchString1 NVARCHAR(256)= 'SQLServerAgent';
DECLARE @searchString2 NVARCHAR(256)= 'startup service account';
EXEC master.dbo.xp_readerrorlog 
	@logno, 
	@logFileType, 
	@searchString1, 
	@searchString2, 
	@start, 
	@end;

/*
Load Agent error log entries into a temporary table.
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
EXEC xp_readerrorlog 1, 2, N'', N'', @StartDate, @EndDate, 'DESC';
-- Display extracted error log records
SELECT 
	LogDate,
	ProcessInfo,
	Text 
FROM #ErrorLogForYesterday;
-- Cleanup
DROP TABLE #ErrorLogForYesterday;
GO

