## :bust_in_silhouette:  (11/9/2026 2:08 PM)
"On server taiob2\MSSQLSERVER01, database AdventureWorks2025: use the sql-performance-triage skill."
## :speech_balloon: SSMS

1. Ran mssql_list_database_connections :white_check_mark:
1. Read skill 'sql-performance-triage', lines 1-400 :white_check_mark:
1. Ran mssql_check_database_context :white_check_mark:

1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:

1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
Skill: sql-performance-triage

| Rank | Query ID | Avg duration (ms) | Executions | Dominant wait | Likely cause |
|---|---:|---:|---:|---|---|
| 1 | 2 | 277.74 | 12 | Network | Expensive pairwise aggregation (`SalesOrderDetail` self-join pattern) plus large result transfer |
| 2 | 1 | 7.63 | 25 | CPU | Non-sargable predicate `LEFT(p.Name,1)=N'A'` |
| 3 | 48 | 151.32 | 1 | Other | Single heavy aggregate/join execution; likely plan/data-shape sensitive |
| 4 | 32 | 38.65 | 1 | IO | Aggregate over multi-table joins; likely scan/read heavy |
| 5 | 28 | 0.60 | 4 | IO | `INSERT dbo.DatabaseLog` write overhead (logging/audit path) |

**Top issues**
- Query `2` dominates total duration (~3332.83 ms) and CPU (~3071.20 ms) in the last 24h.
- Query `1` has a clear non-sargable filter pattern.
- No plan regression signal: top queries each have `plan_count = 1`.
- Current blocking check in `AdventureWorks2025`: none returned.

**Why it’s slow**
- Mix of CPU + IO work on aggregate/join queries, with `Network IO` leading for Query `2` (result transfer/client consumption impact).
- Predicate shape on Query `1` prevents efficient seek behavior.

**Action plan**
- **Now:** Capture actual row counts/result size for Query `2`; verify if client is over-fetching rows/columns.  
- **Next:** Rewrite Query `1` filter to `p.Name LIKE N'A%'`; review indexing for Query `2/48/32` join and grouping keys before adding new indexes.  
- **Later:** Keep Query Store baselines/alerts for duration+CPU regressions and add non-sargable predicate checks to T-SQL review standards.
