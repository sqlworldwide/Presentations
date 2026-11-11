# AI in the SQL World: Tools We Have & Tips for Using Them

```
README.md
AI in the SQL World - demo files for the PASS Data Community Summit West 2026 session
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 11, 2026
```

Demo files for my session at PASS Data Community Summit West 2026 (Seattle).

- **Learning pathway:** Adapting for AI Readiness as a Data Professional (session 2 of 3)
- **When:** Wednesday, November 11, 2026, 10:00 AM to 11:15 AM
- **Room:** 402 Chiliwack
- **Session page:** https://passdatacommunitysummit.com/west/sessions/#session-1384
- **Speaker:** Taiob Ali

The demo files are in [`DemoFiles`](DemoFiles). The slides will be added here later.

## What the demos cover

**Demo 1 - Copilot in SSMS, then VS Code**
- Ask mode and Agent mode, the built-in slow-query skill, and a custom skill
- Database instructions (AGENTS.md) and a database constitution (CONSTITUTION.md)
- Running Copilot as a low-privilege user, and seeing what it ran with Extended Events
- Instructions file, Plan mode and Schema Designer in VS Code

**Demo 2 - SQL Server 2025 vector search, then SQL MCP Server**
- A vector as a column, `AI_GENERATE_EMBEDDINGS`, and search by meaning with `VECTOR_DISTANCE`
- A vector index and `VECTOR_SEARCH` (preview), and the Extended Events trace of each model call
- SQL MCP Server with Data API builder: the config decides what an agent can reach

## What you need

| For | You need |
|---|---|
| Demo 1 | SQL Server, the `AdventureWorks2025` sample database, and SSMS 22.x with GitHub Copilot. Agent mode needs 22.7 or later; database instructions need 22.3 or later |
| Demo 1, VS Code part | VS Code with the SQL Server (mssql) extension and GitHub Copilot Chat |
| Demo 2 | SQL Server 2025, and an embedding model deployed in Azure AI Foundry (script 015). The vector index and `VECTOR_SEARCH` are preview in SQL Server 2025 |
| Demo 2, MCP part | The .NET SDK, VS Code with GitHub Copilot, and the `mcpDemo` folder (see the setup guide) |

`AdventureWorks2025` is the Microsoft sample database: https://learn.microsoft.com/sql/samples/adventureworks-install-configure

## Before you start

1. **Replace the server name.** The prompts and the connection string use my instance, `taiob2\MSSQLSERVER01`. Search the files for it and put your own server name in.
2. **Replace the placeholders in `015_Pre_ExternalModel.sql`.** It has `<your-resource>`, `<your-deployment>`, `<your-key>` and `<password>`. Use your own Azure AI Foundry resource. Never commit a real key.
3. **Install the custom skill once.** Copy the folder `Skills\sql-performance-triage` into your personal skills folder, `~/.copilot/skills/`. Script 008 uses it.
4. **Run the setup scripts in number order:**

| File | What it does |
|---|---|
| `002_Pre_SlowQueryWorkload.sql` | Builds slow-query history in Query Store (for 007 and 008) |
| `003_Pre_CopilotQueries_XE.sql` | Starts the Extended Events session that records what Copilot runs (for 012) |
| `004_Pre_CopilotReader_User.sql` | Creates the low-privilege user Copilot runs as (for 011) |
| `005_Pre_VSCode_BlankDatabase.sql` | Creates the empty `LibraryDemo` database (for 014) |
| `015_Pre_ExternalModel.sql` | Creates the embedding model and the Extended Events session that records its calls (Demo 2) |
| `016_Pre_ProductEmbedding.sql` | Builds the embedded products table, the full-text index and the cached phrases (Demo 2). About 2.5 minutes for 504 products |
| `017_Pre_McpDemoDatabase.sql` | Creates the small `mcpDemo` database (for 020) |

Files numbered 006 and up are the demos. `001_Reset_Demo.sql` resets everything the demos change, so you can run them again.

## Demo 1 - Copilot in SSMS, then VS Code

| Step | File | What it shows |
|---|---|---|
| 1A | `006_AskMode.sql` | Ask mode writes the T-SQL, you run it |
| 1B | `007_AgentMode_SlowQuery.sql` | The built-in skill, slow-query-investigation. Run it before 011 |
| 1C | `008_CustomSkill.sql` and `Skills\sql-performance-triage\SKILL.md` | Your own skill, asked the same way |
| 1D | `009_DatabaseInstructions_AGENTS.sql` | AGENTS.md: a wrong answer, then the right one |
| 1E | `010_Constitution.sql` | CONSTITUTION.md: one rule for every Copilot user |
| 1F | `011_ExecutionContext.sql` | `agentExecuteAsUser`: SQL Server refuses the write |
| 1G | `012_WhatCopilotRan.sql` | Everything Copilot ran |
| 1H | `013_VSCode_InstructionsFile.md` and `VSCodeWorkspace\.github\instructions\tsql-conventions.instructions.md` | VS Code's instructions file |
| 1I | `014_VSCode_PlanMode_SchemaDesigner.md` | Plan mode, then Schema Designer with Copilot |

## Demo 2 - vector search, then SQL MCP Server

| File | What it shows |
|---|---|
| `018_SemanticSearch.sql` | The vector is a column. One live `AI_GENERATE_EMBEDDINGS` call, then search by meaning |
| `019_VectorIndex_VectorSearch.sql` | Vector index (preview), `VECTOR_SEARCH`, then the trace of each model call |
| `020_Setup_SqlMcpServer_DAB.md` | Set up SQL MCP Server and Data API builder on your own laptop (about 10 minutes) |
| `020_SqlMcpServer_DAB.md` and `mcpDemo\` | The demo: the config file, a question, and the refusal |

## About the other `.md` files

A `.md` file with the same number as a script (for example `006_AskMode.md`, `010_Constitution.md`) is a saved Copilot chat from my rehearsal. `014_VSCode_PlanMode_SchemaDesigner_Plan.md` is a saved plan, and `020_Chat_SqlMcpServer_DAB.md` is a saved MCP chat. Use them to compare. **Your results will differ.** Copilot's wording, tool calls and model choice change from run to run. For example, with one model the AGENTS.md rule in 009 was ignored, and with another it was applied. Pick a model, and pin it in the Copilot settings.

## Not included

- The `AdventureWorks2025` database with the embedded vectors. Script 016 builds it for you.
- Any key or password. Add your own.

## Questions

taiob@sqlworldwide.com, or https://sqlworldwide.com/
