/************************************************************
003_Pre_CopilotQueries_XE.sql
Prep - Extended Events session that captures what Copilot runs
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 9, 2026

Run before the session and leave it running. Read it in 012.
Learn (SSMS troubleshoot): monitor Copilot's queries with Extended Events filtered on client_app_name.
https://learn.microsoft.com/ssms/github-copilot/troubleshoot#monitor-queries-from-github-copilot
************************************************************/

USE [master];
GO

/*
1. Create the Extended Events session for Copilot's queries, then start it.
   Run once before the session; leave it running during the demo.
   The filter values are from Learn's SSMS troubleshooting page.
*/
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'CopilotQueries')
  DROP EVENT SESSION [CopilotQueries] ON SERVER;
GO
CREATE EVENT SESSION [CopilotQueries] ON SERVER
ADD EVENT sqlserver.sql_batch_completed (
  ACTION (sqlserver.client_hostname, sqlserver.client_app_name, sqlserver.server_principal_name,
      sqlserver.session_server_principal_name, sqlserver.username, sqlserver.database_name)
  WHERE (sqlserver.client_app_name = N'Microsoft SQL Server Management Studio - GitHub Copilot')),
ADD EVENT sqlserver.rpc_completed (
  ACTION (sqlserver.client_hostname, sqlserver.client_app_name, sqlserver.server_principal_name,
      sqlserver.session_server_principal_name, sqlserver.username, sqlserver.database_name)
  WHERE (sqlserver.client_app_name = N'Microsoft SQL Server Management Studio - GitHub Copilot'))
ADD TARGET package0.event_file (SET filename = N'CopilotQueries', max_file_size = 50)
WITH (MAX_DISPATCH_LATENCY = 5 SECONDS, STARTUP_STATE = ON);
GO
ALTER EVENT SESSION [CopilotQueries] ON SERVER STATE = START;
GO
