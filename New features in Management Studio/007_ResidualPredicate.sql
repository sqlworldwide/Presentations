/*
Script Name: 007_ResidualPredicate.sql
Demo: Residual predicate
All the information is exposed in showplan
*/

USE [AdventureWorks];
GO
--Confirm the index does not exist (for demo purpose)
DROP INDEX IF EXISTS [NCI_TransactionHistory_ProductID_included] ON [Production].[TransactionHistory];
GO

--Create index
CREATE NONCLUSTERED INDEX [NCI_TransactionHistory_ProductID_included]
ON [Production].[TransactionHistory] ([ProductID])
INCLUDE ([TransactionDate], [TransactionType], [Quantity], [ActualCost]);
GO

/*
Turn on Actual Execution Plan (Ctrl+M)
Looking at the plan looks perfect, index seek only
*/
USE [AdventureWorks];
GO
SELECT 
  ProductID,
  Quantity 
FROM Production.TransactionHistory
WHERE ProductID=880 and Quantity>10;
GO

/*
Turn on Actual Execution Plan (Ctrl+M)
Run the same query with TF9130 which is undocumented
Do not use in production and use it at your own risk
You will see an extra node which is the residual predicate
*/

USE [AdventureWorks];
GO
SELECT 
  ProductID,
	Quantity 
FROM Production.TransactionHistory
WHERE ProductID=880 and Quantity>10
OPTION (QUERYTRACEON 9130);
GO

/*
Run the previsous query again  and show that this information is exposed now
with difference of 'Actual number of rows' vs 'Number of rows read'
*/

/* Drop index */
USE [AdventureWorks];
GO
DROP INDEX IF EXISTS [NCI_TransactionHistory_ProductID_included] ON [Production].[TransactionHistory];
GO

/* Create index with more columns */
USE [AdventureWorks];
GO
CREATE NONCLUSTERED INDEX [NCI_TransactionHistory_ProductID_included]
ON [Production].[TransactionHistory] ([ProductID],[Quantity])
INCLUDE ([TransactionDate], [TransactionType], [ActualCost]);
GO

/*
Turn on Actual Execution Plan (Ctrl+M)
Now look at the 'Actual number of rows' vs 'Number of rows read'
Both numbers are same
and we do not see a residual predicate
*/
USE [AdventureWorks];
GO
SELECT 
	ProductID,
	Quantity 
FROM Production.TransactionHistory
WHERE ProductID=880 and Quantity>10;
GO

