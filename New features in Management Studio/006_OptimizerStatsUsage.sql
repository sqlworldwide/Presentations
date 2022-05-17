/*
Script Name: 006_OptimizerStatsUsage.sql
Demo:
  OptimizerStatsUsage
	Statistics being used 
	Sampling percent
	Modification count
	Actionable insight

Read details: https://blogs.msdn.microsoft.com/sql_server_team/sql-server-2017-showplan-enhancements/ by Pedro Lopes
Code is copied from 
--https://github.com/Microsoft/tigertoolbox/blob/master/Sessions/PASS2017/Upgrade-to-SQL-Server-2017-Intelligent-Diagnostics-Just-Built-in/Demo-Showplan-Stats-info.zip
*/


/* Setup code */
USE [Adventureworks];
GO

DROP TABLE IF EXISTS CustomersStatus;
GO
CREATE TABLE CustomersStatus (CustomerID int IDENTITY(1,1) PRIMARY KEY, [EmailAddress] NCHAR(200), [PurchasesLst30d] bit);
GO
INSERT INTO CustomersStatus ([EmailAddress]) 
SELECT [EmailAddress] FROM Person.EmailAddress;
GO

UPDATE CustomersStatus SET [PurchasesLst30d] = 0 WHERE CustomerID % 100 <> 0;
UPDATE CustomersStatus SET [PurchasesLst30d] = 1 WHERE CustomerID % 100 = 0;
GO

CREATE INDEX IX_CustomersStatus ON CustomersStatus([PurchasesLst30d]);
GO

UPDATE STATISTICS CustomersStatus WITH NORECOMPUTE, ALL;
GO 

/* Update again */
UPDATE CustomersStatus SET [PurchasesLst30d] = 1 WHERE CustomerID % 100 <> 0;
UPDATE CustomersStatus SET [PurchasesLst30d] = 0 WHERE CustomerID IN (SELECT TOP 100 CustomerID FROM CustomersStatus WHERE CustomerID % 100 = 0);
GO

CREATE OR ALTER PROC CustomersByStatus @Status bit AS
BEGIN
	SELECT CustomerID FROM CustomersStatus es
	WHERE es.[PurchasesLst30d] = @Status
	OPTION (RECOMPILE)
END;
GO

/*
Start demo
Turn on Actual Execution Plan (Ctrl+M)
*/
EXEC CustomersByStatus 0;
GO

/*
Note skew estimated vs actual rows. Where are they coming from?
Estimated: 19773
Actual: 100

ANSWER: a little thing called statistics.
Look at OptimizerStatsUsage in root node of showplan
Get name of used statistics
dm_db_stats_histogram- new in SQL2016 SP1 CU2
Details here https://blogs.msdn.microsoft.com/sql_server_team/easy-way-to-get-statistics-histogram-programmatically/
*/
SELECT
  stats_name = S.[name], 
  DDSP.stats_id,
  DDSP.[rows],
  DDSP.modification_counter
FROM sys.stats AS S
CROSS APPLY sys.dm_db_stats_properties(S.object_id, S.stats_id) AS DDSP
WHERE
  S.[object_id] = OBJECT_ID(N'dbo.CustomersStatus', N'U');
GO

SELECT 
  hist.*
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_histogram(s.[object_id], s.stats_id) AS hist
WHERE s.[name] = N'IX_CustomersStatus'
AND CAST(range_high_key AS varchar) = 0;
GO

DBCC SHOW_STATISTICS ('CustomersStatus','IX_CustomersStatus');
GO

/*
Shows 19773 eq rows - so that's clearly the histogram. 
So why are estimates vs actuals so off?
*/

/* Execute again and notice other stats properties */
EXEC CustomersByStatus 0
GO

/*
Observe the mod counter - maybe stats are not updated? 
Let's update stats
*/
UPDATE STATISTICS CustomersStatus WITH FULLSCAN, ALL;
GO

/* Execute again and notice stats properties */
EXEC CustomersByStatus 0;
GO

/*
Accurate now? 
Look at stats again
*/
SELECT hist.*
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_histogram(s.[object_id], s.stats_id) AS hist
WHERE s.[name] = N'IX_CustomersStatus'
AND CAST(range_high_key AS varchar) = 0;

/*
What happens is more than one statistics is used in the same plan?
Query copied from
https://sqlserverfast.com/blog/hugo/2020/04/ssms-18-5-small-change-huge-effect/
Turn on Actual Execution Plan (Ctrl+M)
*/
USE [AdventureWorks];
GO
SELECT 
  sod.SalesOrderID,
  sod.SalesOrderDetailID,
  sod.CarrierTrackingNumber,
  soh.ShipDate
FROM Sales.SalesOrderDetail AS sod
JOIN Sales.SalesOrderHeader AS soh
ON soh.SalesOrderID = sod.SalesOrderID
WHERE soh.SalesPersonID = 285;

/*
Will it show Auto Created Statistics
Rafael Cuesta - asked this quesion and I was not sure
He sent me this demo code and it works.
*/
USE [Adventureworks];
GO
DROP TABLE IF EXISTS CustomersStatusDemo;
GO
CREATE TABLE CustomersStatusDemo
 (CustomerID int IDENTITY(1,1) PRIMARY KEY, 
  [EmailAddress] NCHAR(200), 
	[PurchasesLst30d] bit);
GO
INSERT INTO CustomersStatusDemo ([EmailAddress])
SELECT
  [EmailAddress]
FROM Person.EmailAddress;
GO

UPDATE CustomersStatusDemo
SET [PurchasesLst30d] = 0
WHERE CustomerID % 100 <> 0;
UPDATE CustomersStatusDemo
SET [PurchasesLst30d] = 1
WHERE CustomerID % 100 = 0;
GO

CREATE INDEX IX_CustomersStatus ON CustomersStatusDemo([PurchasesLst30d]);
GO

/* Check Table statistics with clustered and nonclustered index stats */
SELECT
  obj.name,
  ST.name,
  st.auto_created,
  stprop.last_updated,
  stprop.modification_counter,
  stprop.rows,
  stprop.rows_sampled
FROM sys.objects AS obj
JOIN sys.STATS st
ON obj.object_id = st.object_id
CROSS APPLY sys.dm_db_stats_properties(OBJECT_ID(obj.name), st.stats_id) AS stprop
WHERE obj.NAME = N'CustomersStatusDemo';

/* Run a query with predicate in a non-indexed column to auto create statistics for it */
SELECT 
	EmailAddress 
FROM CustomersStatusDemo 
WHERE EmailAddress LIKE 'aaron1%';

/* Now we have an autocreated statistic */
SELECT
  obj.name,
  ST.name,
  st.auto_created,
  stprop.last_updated,
  stprop.modification_counter,
  stprop.rows,
  stprop.rows_sampled
FROM sys.objects AS obj
JOIN sys.STATS st
ON obj.object_id = st.object_id
CROSS APPLY sys.dm_db_stats_properties(OBJECT_ID(obj.name), st.stats_id) AS stprop
WHERE obj.NAME = N'CustomersStatusDemo';

/* 
Turn on Actual Execution Plan (Ctrl+M)
to check the auto created stats information in the properties of the root node
*/
SELECT 
	EmailAddress 
FROM CustomersStatus 
WHERE EmailAddress LIKE 'aaron1%';
