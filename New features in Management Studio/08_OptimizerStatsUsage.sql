/*
Script Name: 08_OptimizerStatsUsage.sql
Demo:
   1.OptimizerStatsUsage
	 		Statistics being used 
			Sampling percent
			Modification count
			Actionable insight

Code is copied from 
--https://github.com/Microsoft/tigertoolbox/blob/master/Sessions/PASS2017/Upgrade-to-SQL-Server-2017-Intelligent-Diagnostics-Just-Built-in/Demo-Showplan-Stats-info.zip
*/
-- Setup
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

-- Update again
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

-- Start demo
--Turn on Actual Execution Plan (Ctrl+M)

EXEC CustomersByStatus 0;
GO

/*
Note skew estimated vs actual rows. Where are they coming from?
Estimated: 19773
Actual: 100
*/

-- ANSWER: a little thing called statistics.
-- Look at OptimizerStatsUsage in root node of showplan
-- Get name of used stat
-- dm_db_stats_histogram- new in SQL2016 SP1 CU2
-- Details here https://blogs.msdn.microsoft.com/sql_server_team/easy-way-to-get-statistics-histogram-programmatically/
SELECT hist.*
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_histogram(s.[object_id], s.stats_id) AS hist
WHERE s.[name] = N'IX_CustomersStatus'
AND CAST(range_high_key AS varchar) = 0;


-- Shows 19773 eq rows - so that's clearly the histogram. 
-- So why are estimates vs actuals so off?

-- Execute again and notice other stats properties
EXEC CustomersByStatus 0
GO

-- Observe the mod counter - maybe stats are not updated? 
-- Let's update stats
UPDATE STATISTICS CustomersStatus WITH FULLSCAN, ALL;
GO

-- Execute again and notice stats properties
EXEC CustomersByStatus 0;
GO

-- Accurate now? Look at stats again
SELECT hist.*
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_histogram(s.[object_id], s.stats_id) AS hist
WHERE s.[name] = N'IX_CustomersStatus'
AND CAST(range_high_key AS varchar) = 0;

