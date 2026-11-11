## :bust_in_silhouette:  (11/9/2026 3:14 PM)
"On server taiob2\MSSQLSERVER01, database AdventureWorks2025: show me the 10 most recent orders."
## :speech_balloon: SSMS
**Connection:** taiob2\MSSQLSERVER01.AdventureWorks2025 (as taiob2\\taiob)

1. Ran FindRelevantDatabaseObjects :white_check_mark:
Here is a script for you to review and run. It uses `Sales.SalesOrderHeader` and follows the constitution: explicit columns, schema-qualified names, and `TOP` with `ORDER BY`.
```sql
-- Created by GitHub Copilot in SSMS - review carefully before executing
SELECT TOP (10)
    soh.SalesOrderNumber,
    soh.OrderDate,
    soh.DueDate,
    soh.ShipDate,
    soh.Status,
    soh.OnlineOrderFlag,
    soh.SubTotal,
    soh.TaxAmt,
    soh.Freight,
    soh.TotalDue
FROM Sales.SalesOrderHeader AS soh
ORDER BY soh.OrderDate DESC, soh.SalesOrderID DESC;
```

- **Order type:** I assumed "orders" means sales orders. For purchase orders, use `Purchasing.PurchaseOrderHeader` instead.
- **Reseller filter:** The `AGENTS.md` note on `Sales.SalesOrderHeader` limits *revenue* reporting to reseller orders (`OnlineOrderFlag = 0`). I didn't apply it because this query lists orders and doesn't report revenue. To restrict it to reseller orders, add `WHERE soh.OnlineOrderFlag = 0`.
- **Customer name:** I left it out because I haven't explored the customer tables. I can add it if you want.
- **Execution:** I didn't run the query, so I have no results to show.

**Connection:** taiob2\MSSQLSERVER01.AdventureWorks2025 (as taiob2\\taiob)
