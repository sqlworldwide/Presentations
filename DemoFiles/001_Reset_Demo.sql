/************************************************************
001_Reset_Demo.sql
Reset everything Demo 1 and Demo 2 change, between rehearsals
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 4, 2026

After running this, run 004 and 005 again before the next rehearsal.
Demo 2 part (steps 5 and 6): drops the vector index and turns the preview feature off. It keeps the
external model, dbo.ProductEmbedding and the cached phrase vector, so no new model calls are needed.
017_Pre_McpDemoDatabase.sql rebuilds mcpDemo.
************************************************************/

USE [AdventureWorks2025];
GO

/*
1. Demo 1: remove the database instructions and the CopilotReader user.
*/
IF EXISTS
(
  SELECT 1
  FROM sys.extended_properties
  WHERE class = 0
    AND name = N'CONSTITUTION.md'
)
  EXECUTE sp_dropextendedproperty @name = N'CONSTITUTION.md';

IF EXISTS
(
  SELECT 1
  FROM sys.extended_properties
  WHERE class = 1
    AND name = N'AGENTS.md'
    AND major_id = OBJECT_ID(N'Sales.SalesOrderHeader')
    AND minor_id = 0
)
  EXECUTE sp_dropextendedproperty
    @name       = N'AGENTS.md',
    @level0type = N'SCHEMA', @level0name = N'Sales',
    @level1type = N'TABLE',  @level1name = N'SalesOrderHeader';

IF DATABASE_PRINCIPAL_ID(N'CopilotReader') IS NOT NULL
  DROP USER [CopilotReader];
GO

/*
2. Optional: stop and remove the Extended Events sessions.
--ALTER EVENT SESSION [CopilotQueries] ON SERVER STATE = STOP;
--DROP EVENT SESSION [CopilotQueries] ON SERVER;
--ALTER EVENT SESSION [EmbeddingCalls] ON SERVER STATE = STOP;
--DROP EVENT SESSION [EmbeddingCalls] ON SERVER;
*/

/*
3. VS Code part: the blank database (005 recreates it).
--USE [master];
--ALTER DATABASE [LibraryDemo] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--DROP DATABASE [LibraryDemo];
*/

/*
4. Custom skill from 008: switch it OFF in the Skills panel (keep it installed).
*/

/*
5. Demo 2: drop the vector index that 019 builds.
*/
DROP INDEX IF EXISTS ix_ProductEmbedding_embedding ON dbo.ProductEmbedding;
GO

/*
6. Demo 2: turn the preview feature off.
*/
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = OFF;
GO

/*
7. Check: no vector index left, and every product still has its vector (still_null = 0).
*/
SELECT COUNT(*) AS vector_indexes
FROM sys.vector_indexes
WHERE object_id = OBJECT_ID(N'dbo.ProductEmbedding');

SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN embedding IS NULL THEN 1 ELSE 0 END) AS still_null
FROM dbo.ProductEmbedding;
GO

/*
8. These four VS Code extensions go together (T-SQL cannot check them; look at the Extensions view):
   SQL Server (mssql), Data Workspace, SQL Database Projects, SQL Bindings.
   014: all four enabled, connected to LibraryDemo.
   020: all four disabled for the mcpDemo workspace.
*/
