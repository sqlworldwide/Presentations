/************************************************************
012_WhatCopilotRan.sql
Demo 1, step 7 - what did Copilot run?
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 9, 2026

Needs 003 running since before the demo. Alternative on stage: Object Explorer >
Management > Extended Events > Sessions > CopilotQueries > Watch Live Data.
************************************************************/

/*
1. Everything Copilot executed during the demo, newest first.
   After 011, running_as shows CopilotReader while real_login shows you.
   CopilotReader is a user without a login, so Extended Events records its SID (S-1-9-3-...)
   instead of a name. The CASE below turns that SID back into the name.
*/
DECLARE @file nvarchar(260) =
(
  SELECT CAST(t.target_data AS xml).value('(EventFileTarget/File/@name)[1]', 'nvarchar(260)')
  FROM sys.dm_xe_sessions AS s
  INNER JOIN sys.dm_xe_session_targets AS t
    ON t.event_session_address = s.address
  WHERE s.name = N'CopilotQueries'
    AND t.target_name = N'event_file'
);

/* The current file is ...\CopilotQueries_0_<timestamp>.xel. This reads all files: ...\CopilotQueries*.xel */
SET @file = LEFT(@file, LEN(@file) - CHARINDEX(N'_', REVERSE(@file), CHARINDEX(N'_', REVERSE(@file)) + 1)) + N'*.xel';

WITH x AS
(
  SELECT CAST(event_data AS xml) AS e
  FROM sys.fn_xe_file_target_read_file(@file, NULL, NULL, NULL)
)
SELECT
  e.value('(event/@timestamp)[1]', 'datetime2(0)')                                     AS utc_time,
  e.value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(256)')         AS host_name,
  e.value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(256)')         AS program,
  e.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'sysname') AS real_login,
  CASE
    WHEN e.value('(event/action[@name="username"]/value)[1]', 'nvarchar(256)') LIKE N'S-1-9-3-%'
      THEN N'CopilotReader'
    ELSE e.value('(event/action[@name="username"]/value)[1]', 'nvarchar(256)')
  END                                                                                  AS running_as,
  e.value('(event/action[@name="database_name"]/value)[1]', 'sysname')                 AS database_name,
  COALESCE
  (
    e.value('(event/data[@name="batch_text"]/value)[1]', 'nvarchar(max)'),
    e.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)')
  )                                                                                    AS query_text
FROM x
ORDER BY utc_time DESC;
GO
