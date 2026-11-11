## :bust_in_silhouette:  (11/9/2026 1:36 PM)
"On server taiob2\MSSQLSERVER01, database AdventureWorks2025: use the slow-query-investigation skill on all the data in Query Store, with LookbackMinutes = 10080."
## :speech_balloon: SSMS

1. Ran mssql_list_database_connections :white_check_mark:
1. Ran mssql_list_servers :white_check_mark:
1. Ran mssql_check_database_context :white_check_mark:
1. Ran mssql_list_skills :white_check_mark:
1. Ran mssql_load_skill :white_check_mark:
1. Ran mssql_load_skill_resource :white_check_mark:
1. Ran mssql_load_skill_resource :white_check_mark:
1. Running mssql_execute_query :white_check_mark:

1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
## `slow-query-investigation` run completed

Target: `taiob2\MSSQLSERVER01` / `AdventureWorks2025`  
Parameters used: `LookbackMinutes = 10080` (7 days), full Query Store scope (no `TOP` limit in diagnostic steps).

### Step 0 — Environment
- SQL Server: `17.0.5035.5` (Enterprise)
- Query Store: `READ_WRITE`
- Query Store wait stats: `Yes`

### Findings

#### 1) Volatile queries (Step 1)
Only 3 queries had enough intervals, and variability was low-to-moderate:
- Max CV% observed: **34.4%** (`Query ID 31`)
- No high-volatility pattern (`CV% > 50%`) detected.

#### 2) Wait categories (Step 2)
Dominant waits across returned data:
- **Network IO ~331 ms** (largest)
- Buffer IO ~30 ms
- CPU ~7 ms
- Memory ~3 ms

Primary signal: **network/result-delivery latency**, not CPU/locking pressure.

#### 3) Plan regression (Step 3)
- No rows returned (no regressions detected by this query logic).
- Note: with `LookbackMinutes = 10080`, Step 3’s default “historical vs recent” windows effectively leave no prior baseline window.

#### 4) Parameter sniffing candidates (Step 4)
- No rows returned.
- No multi-plan instability detected in this period.

#### 5) Time-of-day pattern (Step 5, last 24h)
- Clear spike at **17:00 UTC**: Avg duration **43.5 ms**
- 18:00 UTC: 4.1 ms, 19:00 UTC: 1.7 ms  
This suggests a short contention/load window.

#### 6) Statistics staleness (Step 6)
Returned 2 stats entries, but not critically stale:
- `dbo.DatabaseLog` mod% = 3.90
- `Production.Product` mod% = 1.19

## Conclusion
No strong evidence of plan regression or parameter sniffing.  
Current evidence points most to **Network IO / result-transfer overhead** plus a **time-window workload spike around 17:00 UTC**.

___

## :bust_in_silhouette:
"Which other built-in skills are available? Use mssql_list_skills and list just the names."
## :speech_balloon: SSMS
1. Running mssql_check_database_context :white_check_mark:
1. Ran mssql_list_skills :white_check_mark:
- `active-connections`
- `always-encrypted-columns`
- `analyze-readiness-at-scale`
- `authentication-diagnostics`
- `backup-history-azuresql`
- `backup-strategy-sqlserver`
- `blocking-root-cause-analysis`
- `check-live-blocking`
- `code-analysis`
- `connectivity-troubleshoot`
- `create-xe-session`
- `database-config-azuresql`
- `database-settings-review`
- `deadlock-analysis-azuresql`
- `deadlock-analysis`
- `evaluate-azure-migration-assessment`
- `geo-dr-assessment-health-check`
- `get-migration-assessment`
- `ha-assessment-health-check`
- `health-audit-sqlserver`
- `investigate-geo-dr-issues`
- `investigate-ha-issues`
- `investigate-sql-cpu-pressure`
- `investigate-sql-data-io-pressure`
- `investigate-sql-log-io-pressure`
- `investigate-sql-memory-issues`
- `investigate-statistics-issues`
- `ledger-tables`
- `missing-index-analysis`
- `partitioned-tables`
- `plan-cache-analysis`
- `query-store-investigation`
- `query-store-volatile-historical-slow-queries-comparison`
- `resource-usage-sqlserver`
- `schema-design-guidance`
- `sql-agent-job-failure-investigator`
- `table-access-analysis`
- `table-health-check`
- `top-queries-noqds`
- `wait-category-analysis`
