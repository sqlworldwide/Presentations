/*============================================================================
4B_RunBookTsql
Written by Taiob M Ali
SqlWorldWide.com

This script will 
	Use a database in Azure named testRunBookDB in server 'ugdemotargetserver.database.windows.net'
	Above database was created by setup script '0_SetupDemo.ps1'
	Create a table with sample data
	Demo index fragmentation 
============================================================================*/
--Show in portal Azure automation account, runbook, credential
--replace runbook code with content from '4C_RunBookCode.txt
--Connect to ugdemotargetserver.database.windows.net
--Change database context to testRunBookDB as USE statement is not allowed an Azure

SET NOCOUNT ON
DROP TABLE IF EXISTS dbo.testRebuild 
GO
CREATE TABLE dbo.testRebuild 
(c1 int, c2 char (100), c3 int, c4 varchar(1000))
GO

--Create clustered index
CREATE CLUSTERED INDEX ci ON testRebuild(c1)
GO

--Inserting 1000 rows, takes about 8 seconds
DECLARE @i int
SELECT @i = 0
SET NOCOUNT ON
WHILE (@i < 1000)
BEGIN
INSERT INTO testRebuild VALUES (@i, 'hello', @i+10000, REPLICATE ('a', 100))
SET @i = @i + 1
END
GO

--inject fragmentation
UPDATE testrebuild 
SET    c4 = Replicate ('b', 1000) 
GO

--Check the fragmentation
SELECT 
  index_level,
	page_count,
	record_count,
	avg_fragmentation_in_percent, 
  avg_fragment_size_in_pages, 
  fragment_count, 
  avg_page_space_used_in_percent 
FROM sys.Dm_db_index_physical_stats (Db_id(), Object_id('testRebuild'), NULL, NULL, 'DETAILED') 
GO


