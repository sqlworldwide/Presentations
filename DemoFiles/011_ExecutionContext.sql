/************************************************************
011_ExecutionContext.sql
Demo 1, step 6 - choose who Copilot runs as (agentExecuteAsUser)
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 9, 2026

Needs 004 and 010. After this step Copilot runs as CopilotReader; 001_Reset_Demo.sql undoes it.
Learn: SSMS uses EXECUTE AS for Copilot queries in Ask and Agent mode; the approval
system is not a security boundary - SQL Server permissions are.
************************************************************/

USE [AdventureWorks2025];
GO

/*
1. Add agentExecuteAsUser to the constitution's front matter.
   The user CopilotReader was created ahead of time in 004.
   The body is the same as in 010; the front matter must come first.
*/
EXECUTE sp_updateextendedproperty
  @name  = N'CONSTITUTION.md',
  @value = N'---
agentExecuteAsUser: CopilotReader

---
## Constitution: AdventureWorks2025
- Do not use SELECT *. Always use explicit column lists.
- Always use schema-qualified object names, for example Sales.SalesOrderHeader.
- Any query that uses TOP must also have an ORDER BY.';
GO

/*
2. Open a NEW query window and run this first (rehearsal 1 Nov: without it, Copilot ran the
    update as the signed-in user; with it, SQL Server refused it):

      USE [AdventureWorks2025];

    Then open a NEW chat, Agent mode (Agent mode must be READ_WRITE in mcp.json, or the tool refuses the write).
    Model: Claude Sonnet 5.5, the same as 010 (pin it in Chat customizations > Models):

    "On server taiob2\MSSQLSERVER01, database AdventureWorks2025: increase the ListPrice of
     product 680 by 10 percent."

    Read the approval prompt out loud, then Allow once.
    Expect: "UPDATE permission was denied on Production.Product" (Msg 229).
    Copilot may then suggest a GRANT. Don't run it: that is the point.
    Line to land: SQL Server refused it, not the model - the approval dialog
    is not the boundary, permissions are.
*/

/*
3. Proof, by hand: the same thing SSMS does for Copilot.
*/
EXECUTE AS USER = N'CopilotReader';
SELECT USER_NAME() AS running_as;                -- CopilotReader
SELECT TOP (3) ProductID, Name, ListPrice
FROM   Production.Product
WHERE  ProductID = 680
ORDER BY ProductID;                               -- reads work
/*
--UPDATE Production.Product SET ListPrice = ListPrice * 1.10 WHERE ProductID = 680;  -- Msg 229
*/
REVERT;
SELECT USER_NAME() AS back_to;
GO
