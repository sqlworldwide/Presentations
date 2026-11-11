/************************************************************
004_Pre_CopilotReader_User.sql
Prep - the dedicated low-privilege user Copilot will run as (011)
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 4, 2026

Run before the session. Learn (execution context): create a dedicated low-privilege
database user; the signed-in SSMS user needs IMPERSONATE on it.
************************************************************/

USE [AdventureWorks2025];
GO

/*
1. A dedicated low-privilege user that exists only to be impersonated.
   It can only SELECT: no INSERT, UPDATE, DELETE or DDL.
*/
IF DATABASE_PRINCIPAL_ID(N'CopilotReader') IS NULL
  CREATE USER [CopilotReader] WITHOUT LOGIN;

GRANT SELECT ON SCHEMA::Sales TO [CopilotReader];
GRANT SELECT ON SCHEMA::Production TO [CopilotReader];
GRANT SELECT ON SCHEMA::Person TO [CopilotReader];
GO

/*
2. Whoever uses Copilot needs IMPERSONATE on that user.
   If you connect as sysadmin or db_owner you can already impersonate,
   so this grant matters for everyone else. Replace the placeholder.
--GRANT IMPERSONATE ON USER::[CopilotReader] TO [<your database user>];
*/
