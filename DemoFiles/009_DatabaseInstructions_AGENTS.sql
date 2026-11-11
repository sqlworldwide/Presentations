/************************************************************
009_DatabaseInstructions_AGENTS.sql
Demo 1, step 4 - database instructions (AGENTS.md): wrong answer, then right answer
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 9, 2026

Learn (database instructions): extended properties named AGENTS.md, SSMS 22.3+.
https://learn.microsoft.com/ssms/github-copilot/database-instructions
************************************************************/

USE [AdventureWorks2025];
GO

/*
1. Ask first, with NO instruction in place. New chat, Agent mode (it runs the query itself;
   choose Allow for this session for mssql_execute_query, as in 007).
   Model: Claude Sonnet 5.5 (pin it in Chat customizations > Models). Rehearsed 9 Nov: with
   GPT-5.3-Codex the rule was ignored; with Claude Sonnet 5.5 it was applied.

   "On server taiob2\MSSQLSERVER01, database AdventureWorks2025: what was total revenue by fiscal year?"

   If it asks when your fiscal year starts, answer "July 1".
   Expect: a total that includes online orders. It probably uses SubTotal and a July-to-June year,
   because it knows the AdventureWorks sample. That is fine; the rule that changes the number
   is the one it cannot guess: reseller orders only.
   Write down FY2025: about 44.99M in rehearsal (9 Nov). You compare it in step 4.
   Say nothing judgmental: it did fine with what it knew.
*/

/*
2. Teach it the business rule, on the object the rule belongs to.
   You execute this yourself, so the audience sees where the rule is stored.
   Learn: in Ask mode Copilot can't run modification queries.
*/
EXECUTE sp_addextendedproperty
  @name       = N'AGENTS.md',
  @value      = N'Revenue is SUM(SubTotal). SubTotal excludes tax and freight; never use TotalDue for revenue.
Our fiscal year runs from July 1 to June 30 and is named for the year it ends: FY2025 is July 1, 2024 to June 30, 2025.
We report reseller revenue only: exclude online orders (OnlineOrderFlag = 1).',
  @level0type = N'SCHEMA', @level0name = N'Sales',
  @level1type = N'TABLE',  @level1name = N'SalesOrderHeader';
GO

/*
3. Show the audience where the rule lives: it is just an extended property.
*/
SELECT
  SCHEMA_NAME(o.schema_id)        AS schema_name,
  o.name                          AS object_name,
  ep.name                         AS property_name,
  CAST(ep.value AS nvarchar(max)) AS instruction
FROM sys.extended_properties AS ep
INNER JOIN sys.objects AS o
  ON o.object_id = ep.major_id
WHERE ep.class = 1
  AND ep.name = N'AGENTS.md';
GO

/*
4. NEW chat, Agent mode. Ask the same question again:

    "On server taiob2\MSSQLSERVER01, database AdventureWorks2025: what was total revenue by fiscal year?"

    Then ask:

    "On server taiob2\MSSQLSERVER01, database AdventureWorks2025: show me the query used to get this information."

    Point at SUM(SubTotal), the July-to-June year boundary and WHERE OnlineOrderFlag = 0.
    FY2025 drops from about 44.99M to 29.39M (rehearsal 9 Nov) because online orders are now out.
    That is the rule Copilot could not guess.
    Use a new chat: Learn says Copilot applies the instruction to "subsequent interactions"
    but doesn't say whether the same chat picks it up. Rehearse the same chat once to find out.
*/
