/************************************************************
005_Pre_VSCode_BlankDatabase.sql
Prep - empty database for the VS Code part (014)
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 4, 2026

Run before the session. Recreate between rehearsals.
************************************************************/

USE [master];
GO

/*
1. Drop and recreate the empty database.
*/
IF DB_ID(N'LibraryDemo') IS NOT NULL
BEGIN
  ALTER DATABASE [LibraryDemo] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE [LibraryDemo];
END;
GO

CREATE DATABASE [LibraryDemo];
GO

/*
2. Check.
*/
SELECT
  name,
  state_desc,
  compatibility_level
FROM sys.databases
WHERE name = N'LibraryDemo';
GO
