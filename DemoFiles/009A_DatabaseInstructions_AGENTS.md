## :bust_in_silhouette:  (11/9/2026 3:06 PM)
"On server taiob2\MSSQLSERVER01, database AdventureWorks2025: what was total revenue by fiscal year?"
## :speech_balloon: SSMS

1. Ran mssql_list_database_connections :white_check_mark:
1. Ran mssql_check_database_context :white_check_mark:
1. Ran mssql_schema_get_objects_for_query_writing :white_check_mark:
1. Ran mssql_execute_query :white_check_mark:
Revenue by fiscal year in `AdventureWorks2025` on `taiob2\MSSQLSERVER01`:

| Fiscal year | Revenue (SubTotal) | Revenue (TotalDue) | Orders |
|---|---|---|---|
| 2022 | 14,561,051.59 | 16,316,694.17 | 1,692 |
| 2023 | 31,604,921.95 | 35,514,705.67 | 3,830 |
| 2024 | 43,671,889.50 | 49,020,486.51 | 14,244 |
| 2025 | 20,008,518.36 | 22,364,899.78 | 11,699 |

- **Fiscal year:** The database has no fiscal calendar. I used the calendar year of `OrderDate`, so a fiscal year that starts in a month other than January would give different totals.
- **Revenue columns:** `SubTotal` is revenue before tax and freight. `TotalDue` includes tax and freight. I'd use `SubTotal` as revenue.
- **Order status:** I counted every order regardless of `Status`, including cancelled ones.
- **2025:** The total is lower than 2024 and may cover only part of the year.

The query, in case you want to adjust it:
```sql
SELECT YEAR(OrderDate) AS FiscalYear,
       SUM(SubTotal)   AS SubTotalRevenue,
       SUM(TotalDue)   AS TotalDueRevenue,
       COUNT(*)        AS Orders
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY FiscalYear;
```

If your fiscal year starts in July, group by `YEAR(DATEADD(MONTH, 6, OrderDate))` instead.
