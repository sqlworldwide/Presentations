/************************************************************
007_AgentMode_SlowQuery.sql
Demo 1, step 2 - Agent mode with a built-in skill (slow-query-investigation)
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 9, 2026

Needs 002 run first. Run this BEFORE 011. After 011, Copilot runs as CopilotReader, which has only
SELECT on Sales, Production and Person, so it can't read Query Store or the DMVs:
  - Query Store views need VIEW DATABASE PERFORMANCE STATE (SQL Server 2022 and later)
    https://learn.microsoft.com/sql/relational-databases/system-catalog-views/sys-query-store-runtime-stats-interval-transact-sql
  - DMVs such as sys.dm_exec_sql_text need VIEW SERVER PERFORMANCE STATE, a server permission
    https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sql-text-transact-sql
  - EXECUTE AS USER is scoped to the current database, so server permissions don't apply
    https://learn.microsoft.com/sql/t-sql/statements/execute-as-transact-sql
Learn (Agent mode): Agent mode doesn't inherit context from the active query editor;
include the server and database in the prompt.
https://learn.microsoft.com/ssms/github-copilot/agent-mode
Learn (SSMS 22.8.0 release notes): Agent mode "Added several skills, including ...
slow query investigation". 22.10.2 updated the bundled SQL Tools MCP server, "adding the latest skills".
https://learn.microsoft.com/ssms/release-notes-22
************************************************************/

/*
Before this step: Copilot Chat > Tools icon > Skills panel > sql-performance-triage is
switched OFF (it stays installed; you only switch it ON and OFF). Rehearse once that Copilot
then loads only the built-in skill.
This run shows a skill that ships with SSMS. 008 asks the same way with your own skill.

1. New chat, Agent mode:

   "On server taiob2\MSSQLSERVER01, database AdventureWorks2025: use the slow-query-investigation skill on all the data in Query Store, with LookbackMinutes = 10080."

2. Approvals: read the first prompt out loud, then choose Allow for this session for
   mssql_execute_query.

3. Point at the steps in the chat:
   - mssql_list_skills, mssql_load_skill, mssql_load_skill_resource: the built-in skill loads
   - "Used slow-query-investigation": the skill's name in the answer
   - its fixed runbook: environment, volatile queries, waits, plan regression,
     parameter sniffing, time pattern, statistics

4. Same chat. The end of the answer varies between runs, so ask for the list:

   "Which other built-in skills are available? Use mssql_list_skills and list just the names."

   Point at the names (rehearsal: missing-index-analysis, investigate-sql-data-io-pressure,
   check-live-blocking).
   Line to land: Microsoft ships a library of these runbooks.
*/
