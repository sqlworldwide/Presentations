# AI in the SQL World: Tools We Have & Tips for Using Them

Slides and demo code for my session at PASS Data Community Summit West 2026.

- **Learning Pathway:** Adapting for AI Readiness as a Data Professional
- **When:** Wednesday, November 11, 2026, 10:00 AM to 11:15 AM, Room 307 Methow
- **Session page:** https://passdatacommunitysummit.com/west/sessions/#session-1384
- **Speaker:** Taiob Ali

The slides, reference PDFs and numbered demo scripts are all in this folder.

## What the demos cover

- GitHub Copilot in SSMS, including Query Store analysis and custom skills
- Running Copilot as a low-privilege user and auditing what it ran with Extended Events
- AI-assisted SQL development in VS Code
- AI search in the database with embeddings and vector indexes
- MCP with a demo database

## What you need

- SQL Server 2025 on a test server
- The AdventureWorks sample database, restored as `AdventureWorks2025` ([download the samples](https://learn.microsoft.com/sql/samples/adventureworks-install-configure))
- SSMS with GitHub Copilot ([get started](https://learn.microsoft.com/ssms/github-copilot/get-started))
- VS Code with these extensions: SQL Server (mssql), Data Workspace, SQL Database Projects, SQL Bindings
- An embedding model endpoint for the vector demo (calls to it may cost money)

## Setup

Run these once, in this order, before the demos:

| Script | What it does |
|---|---|
| `002_Pre_SlowQueryWorkload.sql` | Turns on Query Store and builds slow-query history for 007 |
| `003_Pre_CopilotQueries_XE.sql` | Creates and starts the `CopilotQueries` Extended Events session, read in 012 |
| `004_Pre_CopilotReader_User.sql` | Creates the low-privilege `CopilotReader` user used in 011 |
| `005_Pre_VSCode_BlankDatabase.sql` | Drops and recreates the empty `LibraryDemo` database for 014 |

If you don't connect as sysadmin or db_owner, uncomment the `GRANT IMPERSONATE` line in 004 and add your database user.

## Running the demos

Scripts numbered 006 and up are the demos. Run them in number order. Files with `Pre` in the name are prep steps.

## Resetting between runs

**Skip `001_Reset_Demo.sql` on your first run.** It resets the demos after they have run and expects the vector demo's table to exist.

After running 001, run 004 and 005 again. Optional steps to remove the Extended Events sessions and `LibraryDemo` are commented out in the script.

## Before you run anything

- This is demo code. Do not run it in production.
- 002 runs intentionally expensive queries.
- The scripts were written with assistance from GitHub Copilot.
- AI output varies, so your results may not match mine. Review anything it generates before you use it.

## License

See [LICENSE](../LICENSE).

## Contact

- Email: taiob@sqlworldwide.com
- Blog: https://sqlworldwide.com/
- Bluesky: https://bsky.app/profile/sqlworldwide.bsky.social
- LinkedIn: https://www.linkedin.com/in/sqlworldwide/
