/************************************************************
006_AskMode.sql
Demo 1, step 1 - Ask mode: it writes the T-SQL, you run it
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 4, 2026

Learn (SSMS 22.9.0 release notes): Ask mode "removed the ability to execute arbitrary queries".
************************************************************/

/*
1. New chat, Ask mode, query editor connected to AdventureWorks2025:

   "On server taiob2\MSSQLSERVER01, database AdventureWorks2025: which 5 products had the highest sales in 2024?"

   Point out: it read the schema and wrote the joins itself.

2. Follow up in the same chat:

   "On server taiob2\MSSQLSERVER01, database AdventureWorks2025: run it and show me the results."

   Expect: it hands you the script instead of running it.
   Line to land: Ask mode advises; you stay in the loop.

3. Show the four ways to use the script Copilot wrote. On the code block, open the
   Insert at Cursor drop-down:
     - Insert at Cursor        : drops it where your cursor is
     - Insert in New File      : opens a new query window with it
     - Apply in <file>:<line>  : puts it into the open script at that line
     - Copy (icon next to it)  : copies it to the clipboard
   Line to land: every option puts the T-SQL in front of you; none of them runs it.
   Pick Insert in New File, then run it yourself (F5).
*/
