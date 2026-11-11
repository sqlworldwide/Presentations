/************************************************************
010_Constitution.sql
Demo 1, step 5 - database constitution (CONSTITUTION.md): one rule for every Copilot user
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 9, 2026

Learn: one database-level extended property; overrides AGENTS.md.
https://learn.microsoft.com/ssms/github-copilot/database-instructions
Copilot reads it when a Copilot session opens - start a NEW chat after running.
************************************************************/

USE [AdventureWorks2025];
GO

/*
1. Create the database constitution: one database-level property.
   It applies to every Copilot user of this database and takes precedence over AGENTS.md.
*/
EXECUTE sp_addextendedproperty
  @name  = N'CONSTITUTION.md',
  @value = N'## Constitution: AdventureWorks2025
- Do not use SELECT *. Always use explicit column lists.
- Always use schema-qualified object names, for example Sales.SalesOrderHeader.
- Any query that uses TOP must also have an ORDER BY.';
GO

/*
2. Run the EXECUTE sp_addextendedproperty above yourself, in a query window (plain T-SQL, not Copilot).
    Then start a NEW chat in ASK mode (the constitution is read when a session opens).
    Model: Claude Sonnet 5.5 (pin it in Chat customizations > Models). Models differ in whether
    they pick up database instructions (see 009), so rehearse with the model you will use.
    Ask mode shows the T-SQL it wrote, which is what this demo needs; it doesn't run it:

    "On server taiob2\MSSQLSERVER01, database AdventureWorks2025: show me the 10 most recent orders."

    Point at the code block: explicit columns (no SELECT *), schema-qualified names,
    TOP with ORDER BY. Those are the three rules in the constitution.
    Line to land: one property, and every Copilot user of this database gets the same rules.

3. Optional, same chat: it answers Yes and names the constitution.
    Point at "Ran ReadDatabaseConstitution" in the chat: a built-in tool reads the property.

    "On server taiob2\MSSQLSERVER01, database AdventureWorks2025: does this database have a constitution set?"
*/
