# Demos – AI in the SQL World (PASS Summit West 2026)

Old material is in `..\Demos_old`. Demo 2 here replaces its vector and SQL MCP Server scripts.

## Before the session (run in number order)
| File | What it does |
|---|---|
| `002_Pre_SlowQueryWorkload.sql` | Builds slow-query history in Query Store (for 1B) |
| `003_Pre_CopilotQueries_XE.sql` | Starts the Extended Events session that records what Copilot runs (read in 1G) |
| `004_Pre_CopilotReader_User.sql` | Creates the low-privilege user Copilot will run as (used in 1F) |
| `005_Pre_VSCode_BlankDatabase.sql` | Creates the empty `LibraryDemo` database (for 1I) |
| `015_Pre_ExternalModel.sql` | The Foundry embedding model, and the Extended Events session that records its calls (Demo 2) |
| `016_Pre_ProductEmbedding.sql` | The embedded products table, the full-text index and the cached phrases (Demo 2) |
| `017_Pre_McpDemoDatabase.sql` | Creates the small `mcpDemo` database (for 020) |

Custom skill (once): copy the folder `Skills\sql-performance-triage` into your personal skills folder,
`~/.copilot/skills/`. It stays there. You never move it again: switch it OFF in the Skills panel
before 1B and ON in 1C.

## Demo 1 - Copilot in SSMS, then VS Code
| Step | File | Beat |
|---|---|---|
| 1A | `006_AskMode.sql` | Ask mode writes the T-SQL; you run it |
| 1B | `007_AgentMode_SlowQuery.sql` | Built-in skill: slow-query-investigation (run before 1F) |
| 1C | `008_CustomSkill.sql` (+ `Skills\sql-performance-triage\SKILL.md`) | Your skill: switch sql-performance-triage ON, asked the same way |
| 1D | `009_DatabaseInstructions_AGENTS.sql` | AGENTS.md: wrong answer, then right answer |
| 1E | `010_Constitution.sql` | CONSTITUTION.md: one rule for every Copilot user |
| 1F | `011_ExecutionContext.sql` | agentExecuteAsUser: SQL Server refuses the write |
| 1G | `012_WhatCopilotRan.sql` | Everything Copilot ran |
| 1H | `013_VSCode_InstructionsFile.md` (+ `VSCodeWorkspace\.github\instructions\tsql-conventions.instructions.md`) | VS Code's instructions file |
| 1I | `014_VSCode_PlanMode_SchemaDesigner.md` | Plan mode, then Schema Designer with Copilot |

If time runs short: cut 1H first, then 1E.

## After / between rehearsals
Run in this order:
1. `001_Reset_Demo.sql`
2. `004_Pre_CopilotReader_User.sql`
3. `005_Pre_VSCode_BlankDatabase.sql`
4. `017_Pre_McpDemoDatabase.sql`

Then switch the custom skill OFF in the Skills panel.

## Demo 2 - vector search on SQL Server 2025, then SQL MCP Server + DAB (about 16 min)
| File | Beat | Min |
|---|---|---|
| `018_SemanticSearch.sql` | The vector is a column; one live AI_GENERATE_EMBEDDINGS call; search by meaning (VECTOR_DISTANCE), then the limit of LIKE, CONTAINS and FREETEXT against a long question | 6 |
| `019_VectorIndex_VectorSearch.sql` | Vector index (preview), VECTOR_SEARCH with TOP_N, WHERE, metric mismatch, then the Extended Events trace: how many Foundry calls, and what was sent (session started in 015) | 6 |
| `020_SqlMcpServer_DAB.md` (+ `mcpDemo\`) | SQL MCP Server: the config file, a question, the refusal | 4 |

Cut order: 019 step 6 (metric mismatch), 019 step 5 (WHERE), the trace in 019 step 7, the tool list in 020.
Never cut: the payroll refusal in 020.

## Time budget (75 min, estimates, not yet timed)
| Block | Slides | Min |
|---|---|---|
| Intro | 1-5 | 5 |
| Why and Copilot | 6-13 | 11 |
| Demo 1 | 14 | 20 |
| Tips, vector search, five steps, MCP + DAB, how an agent reaches your data | 15-21 | 10 |
| Demo 2 | 22 | 16 |
| Vector tips, GA or preview, tool changed, Next | 23-26 | 6 |
| Close | 27-30 | 5 |
| Spare / questions | | 2 |
