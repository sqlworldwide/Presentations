## :bust_in_silhouette:  (11/9/2026 3:21 PM)
"On server taiob2\MSSQLSERVER01, database AdventureWorks2025: increase the ListPrice of  product 680 by 10 percent."
## :speech_balloon: SSMS
**Connection:** taiob2\MSSQLSERVER01.AdventureWorks2025 (as CopilotReader)

I can't run this update. In SSMS I can only execute predefined queries, and none of them modify data. The `CopilotReader` user from your file also has only SELECT permission. Below is a script for you to review and run yourself with a suitably privileged account.

I haven't inspected the schema in this session. The table and column names below assume the standard AdventureWorks `Production.Product` table with `ProductID` and `ListPrice` columns. Please confirm they match your database before running.
```sql
-- Created by GitHub Copilot in SSMS - review carefully before executing
-- Run as a user with UPDATE permission on Production.Product (not CopilotReader).

BEGIN TRANSACTION;

UPDATE Production.Product
SET ListPrice = ListPrice * 1.10
WHERE ProductID = 680;

-- Verify exactly 1 row was affected, then commit
SELECT ProductID, Name, ListPrice
FROM Production.Product
WHERE ProductID = 680;

-- COMMIT TRANSACTION;   -- run if the result looks correct
-- ROLLBACK TRANSACTION; -- run otherwise
```

| Note | Detail |
|---|---|
| Permissions | `CopilotReader` has SELECT only, so this must run under another account. |
| Safety | The transaction is left open until you run `COMMIT` or `ROLLBACK`. |
| Scope | The `WHERE ProductID = 680` filter limits the change to one product. |
| Business rules | Check whether `Production.ProductListPriceHistory` or other processes need a matching update. |

**Connection:** taiob2\MSSQLSERVER01.AdventureWorks2025 (as CopilotReader)
