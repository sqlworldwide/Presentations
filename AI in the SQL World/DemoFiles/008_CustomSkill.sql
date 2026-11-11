/************************************************************
008_CustomSkill.sql
Demo 1, step 3 - your own skill changes how Agent mode works
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 9, 2026

Needs the skill installed once (see README) and 007 run first (built-in skill, asked the same way).
The on/off switch in the Skills panel is shown in SSMS but not yet described on Learn.
Skill source: Skills\sql-performance-triage\SKILL.md
Learn (Agent skills): skills are reusable instructions for a task, SSMS 22.7 and later,
used in Agent mode. Copilot activates a skill when its description matches the request,
and the skill's name appears in the chat. Personal skills live in ~/.copilot/skills/.
https://learn.microsoft.com/ssms/github-copilot/agent-skills
************************************************************/

/*
1. The skill is already installed and has been switched off since 007.

2. In SSMS: Copilot Chat > Tools icon > Skills panel.
   Switch sql-performance-triage ON in front of the audience.
   Point out: it is listed under User (your personal skills folder).

3. NEW chat, Agent mode, asked the same way as 007:

   "On server taiob2\MSSQLSERVER01, database AdventureWorks2025: use the sql-performance-triage skill."

4. Point at:
   - "Read skill 'sql-performance-triage'" in the chat
   - the first line of the answer: Skill: sql-performance-triage
   - the table and the Now / Next / Later plan, the format the skill asked for
   - the top rows: the self-join over TOP (6000) and the LEFT(p.Name, 1) filter from 002
     (query IDs change between rehearsals; on Nov 1 they were 763 and 762)

5. Open SKILL.md for 10 seconds:
   - description: the keywords decide when Copilot uses it
   - Never: the limits you set, applied every time
   Line to land: Microsoft's skill answers Microsoft's questions; mine answers my team's.
   Write it once and the whole team gets it.
*/

/*
Reset (after the session or between rehearsals):
Skills panel > switch sql-performance-triage OFF, ready for 007.
*/
