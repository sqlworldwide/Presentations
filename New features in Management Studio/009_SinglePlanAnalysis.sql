/*
Script Name: 009_SinglePlanAnalysis.sql
To save time run 3 section in 3 separate windows
Demo
	1. Single Plan Analysis (need new SSMS)
	2. Spill information (SQL2012 SP3, do not need new SSMS)
	3. Memory grant--MaxQeryMemory is higher than requested memory.  Spill was not due lack of available memory
	   look at the estimated/actual number of rows.
	   Details in KB3170112
	   https://support.microsoft.com/en-us/help/3170112/update-to-expose-maximum-memory-enabled-for-a-single-query-in-showplan
	   https://dba.stackexchange.com/questions/196785/difference-between-grantedmemory-and-maxquerymemory-attributes-in-showplan-x

How to reduce runtime by 90% just by using information exposed in SSMS
*/

/* Turn on Actual Execution Plan (Ctrl+M) */

USE [AdventureWorks];
GO

/*
Changing compatibility level to SQL 2017
Demo purpose only
*/
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; 
GO

USE [AdventureWorks];
GO
DECLARE @ProductID TABLE (ProductID INT)
/* populating table variable */
INSERT INTO @ProductID (ProductID)
SELECT ProductID
FROM dbo.bigTransactionHistory;
/* Now selecting from the table variable */
SELECT DISTINCT	ProductID FROM @ProductID 
WHERE ProductID>1700
ORDER BY ProductID;

/*
Right Click-->Analyze execution plan
Looking at the table scan Estimated =1 and Actual=31005899
Memory granted 1024kb and Spill about 2453 pages
Add recomile with increase the Estimated number of rows and will decrease the amount of spill
Decrease runtime by about 25%

Turn on Actual Execution Plan (Ctrl+M)
*/

USE [AdventureWorks];
GO

/*
Changing compatibility level to SQL 2017
Demo purpose only
*/

ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; 
GO
DECLARE @ProductID TABLE (ProductID INT);

INSERT INTO @ProductID (ProductID)
SELECT ProductID
FROM dbo.bigTransactionHistory;

SELECT DISTINCT	ProductID FROM @ProductID 
WHERE ProductID>1700
ORDER BY ProductID
OPTION (RECOMPILE);

/*
Analyze the plan again
Your numbers may vary slightly
Looking at the table scan Estimated=9379080 Actual=31005899
*/

/*
Get rid of spill using temp table instead of table variable
This will increase run time due creating the index
Will be a better option only if you are using the temp table multiple times
*/


USE [AdventureWorks];
GO
/*
Changing compatibility level to SQL 2017
Demo purpose only
*/
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; 
GO
IF OBJECT_ID('tempdb..#ProductId') IS NOT NULL 
DROP TABLE #ProductId;
GO
CREATE TABLE #ProductId (ProductID INT);

INSERT INTO #ProductID (ProductID)
SELECT ProductID
FROM dbo.bigTransactionHistory;

CREATE NONCLUSTERED INDEX NCI_ProductID
ON dbo.#ProductID (ProductID);

/*
Turn on Actual Execution Plan (Ctrl+M)
No spill
*/
SELECT DISTINCT	ProductID FROM #ProductID
WHERE ProductID>1700
ORDER BY ProductID;
GO

/* Changing compatibility level to SQL 2019 */
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 150; 
GO