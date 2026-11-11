---
name: sql-performance-triage
description: Use when a user reports slow queries, intermittent slowness, high CPU, high IO, memory pressure, blocking, or a performance regression on SQL Server or Azure SQL. Finds the top resource-consuming queries in Query Store, classifies the dominant wait category, and returns a prioritized now / next / later remediation plan without changing anything.
compatibility: GitHub Copilot Agent mode in SSMS 22.7 or later. SQL Server 2017 or later with Query Store on.
metadata:
  author: Taiob Ali
  version: "2.1"
---

# SQL Server Performance Triage

## Use this skill when
- A user reports slow or intermittently slow queries
- CPU, IO, or memory pressure is high
- Sessions are blocked or waiting
- Performance regressed after a deployment or a plan change

## Before you start
1. Take the server and database from the request. If either is missing, ask. Don't guess.
2. Check that Query Store is on for the database (sys.database_query_store_options).
   If it's off, say so and use the DMVs instead.

## Investigation order
1. Find the top queries
   - Use Query Store runtime statistics for the recent window (default: last 24 hours).
   - Weight averages by execution count. Never average the averages.
   - Rank by total duration and total CPU. Keep the top 5.
   - Leave out diagnostic queries that tools ran, including Copilot's own queries.
2. Classify the bottleneck
   - Compare average CPU with average duration for each top query first.
     If average CPU is at least 80% of average duration, classify it as CPU.
     Waits don't include time spent running on a CPU, so don't let a small wait slice override this.
   - Otherwise, use Query Store wait statistics (sys.query_store_wait_stats) and classify it
     as IO, Memory, Locking, Network, or Other.
   - Check for current blocking in sys.dm_exec_requests (blocking_session_id).
3. Find the likely cause
   - Read the text of each top query before naming a cause. Look for:
     functions on filtered or joined columns (LEFT, SUBSTRING, CONVERT, ISNULL),
     implicit conversions, and joins that multiply rows (self-joins, missing join predicates).
   - Plan regression: the same query with more than one plan, and the newer plan slower.
   - Non-sargable predicates, implicit conversions, missing or unused indexes.
   - Parameter sensitivity: very different runtimes for the same query.
4. Build the plan
   - Now: safe, reversible steps (for example, update statistics on one table).
   - Next: targeted tuning (a query rewrite, an index candidate to review).
   - Later: prevention (monitoring, Query Store settings, coding standards).

## Never
- Change data, schema, configuration, or security without explicit confirmation.
- Clear the plan cache or Query Store, force a plan, or restart a service.
- Recommend an index without checking existing indexes and the write cost.
- Report a root cause without evidence (query ID, metric, wait category).

## Output format
Start with this line so everyone can see the skill was applied:
Skill: sql-performance-triage

Then a table:
| Rank | Query ID | Pattern | Avg duration (ms) | Avg CPU (ms) | Executions | Bottleneck | Likely cause |
Pattern is a few words a DBA recognizes, for example "self-join on TOP (6000)".

Then three short sections: Top issues, Why it's slow, Action plan (Now / Next / Later).
Top issues lists problems only. Don't report settings that are fine.
Keep the whole answer under 25 lines.

## Example
Skill: sql-performance-triage
| Rank | Query ID | Pattern | Avg duration (ms) | Avg CPU (ms) | Executions | Bottleneck | Likely cause |
| 1 | 4127 | LEFT() filter on Product.Name | 812 | 790 | 25 | CPU | Non-sargable filter LEFT(p.Name, 1) on Production.Product |

Action plan
- Now: confirm the plan is stable in Query Store; no change yet.
- Next: rewrite the filter as p.Name LIKE N'A%' and test.
- Later: add the pattern to the team's T-SQL review checklist.
