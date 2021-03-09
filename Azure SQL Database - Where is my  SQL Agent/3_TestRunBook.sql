/*
This script will 
Use a database in Azure named testRunBookDB in server 'ugdemotargetserver.database.windows.net'
Above database was created by setup 
Create a table with sample data
Demo index fragmentation 
============================================================================*/

/*
Show in portal Azure automation account, runbook, credential
Connect to ugdemotargetserver.database.windows.net
Change database context to testRunBookDB as USE statement is not allowed an Azure
*/

SET NOCOUNT ON
DROP TABLE IF EXISTS dbo.testRebuild;
GO

CREATE TABLE dbo.testRebuild
(
  c1 INT,
  c2 CHAR(100),
  c3 INT,
  c4 VARCHAR(1000)
);
GO

--Create clustered index
CREATE CLUSTERED INDEX ci ON testRebuild (c1);
GO

--Inserting 1000 rows, takes about 8 seconds
DECLARE @i INT
SELECT @i = 0
SET NOCOUNT ON

WHILE (@i < 1000)
BEGIN
  INSERT INTO testRebuild
  VALUES
  (@i, 'hello', @i + 10000, REPLICATE('a', 100))
  SET @i = @i + 1
END;
GO

--inject fragmentation
UPDATE testrebuild
SET c4 = REPLICATE('b', 1000);
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
FROM sys.Dm_db_index_physical_stats(DB_ID(), OBJECT_ID('testRebuild'), NULL, NULL, 'DETAILED');
GO