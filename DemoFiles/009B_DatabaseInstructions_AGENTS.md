## :bust_in_silhouette:  (11/9/2026 3:08 PM)
"On server taiob2\MSSQLSERVER01, database AdventureWorks2025: what was total revenue by fiscal year?"
## :speech_balloon: SSMS

1. Ran mssql_list_database_connections :white_check_mark:
1. Ran mssql_check_database_context :white_check_mark:
1. Ran mssql_schema_get_objects_for_query_writing :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
Reseller revenue by fiscal year in AdventureWorks2025:

| Fiscal year | Revenue |
|---|---|
| FY2022 | $2,027,736.89 |
| FY2023 | $20,255,585.11 |
| FY2024 | $28,815,141.76 |
| FY2025 | $29,389,240.42 |

I applied the rules stored in the `AGENTS.md` extended property on `Sales.SalesOrderHeader`:
- **Revenue:** `SUM(SubTotal)`. It excludes tax and freight, so I didn't use `TotalDue`.
- **Fiscal year:** July 1 to June 30, named for the year it ends. For example, FY2025 runs from July 1, 2024 to June 30, 2025.
- **Scope:** Reseller orders only, so I excluded rows where `OnlineOrderFlag = 1`.
```sql
SELECT YEAR(DATEADD(MONTH, 6, OrderDate)) AS FiscalYear, SUM(SubTotal) AS Revenue
FROM Sales.SalesOrderHeader
WHERE OnlineOrderFlag = 0
GROUP BY YEAR(DATEADD(MONTH, 6, OrderDate))
ORDER BY FiscalYear;
```

___

## :bust_in_silhouette:
"On server taiob2\MSSQLSERVER01, database AdventureWorks2025: show me the query used to get this information."
## :speech_balloon: SSMS
Here is the query I ran against `AdventureWorks2025` on `taiob2\MSSQLSERVER01`:
```sql
SELECT YEAR(DATEADD(MONTH, 6, OrderDate)) AS FiscalYear, SUM(SubTotal) AS Revenue
FROM Sales.SalesOrderHeader
WHERE OnlineOrderFlag = 0
GROUP BY YEAR(DATEADD(MONTH, 6, OrderDate))
ORDER BY FiscalYear;
```

- **Fiscal year:** `DATEADD(MONTH, 6, OrderDate)` moves each date forward six months. July 1 through December 31 then falls in the next calendar year, and January 1 through June 30 stays in the same year. `YEAR()` of the shifted date is the fiscal year, so July 1, 2024 gives FY2025.
- **Revenue:** `SUM(SubTotal)`, which excludes tax and freight.
- **Filter:** `OnlineOrderFlag = 0` keeps reseller orders only.

These rules come from the `AGENTS.md` extended property on `Sales.SalesOrderHeader`.
