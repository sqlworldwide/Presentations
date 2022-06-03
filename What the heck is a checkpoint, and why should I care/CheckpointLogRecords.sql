/*
CheckpointLogRecords.sql
Written by Taiob Ali
SqlWorldWide.com

This script will demonstrate log records created during checkpoint

Idea of this script was taken from Paul Randal's blog post.
"How do checkpoints work and what gets logged"
https://www.sqlskills.com/blogs/paul/how-do-checkpoints-work-and-what-gets-logged/
*/

/*
Drop database if exists
Create an empty database
*/

USE master;
GO
DECLARE @SQL nvarchar(1000);

IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = N'sqlfridaydemo')
  BEGIN
    SET @SQL = 
      N'USE [master];
       ALTER DATABASE sqlfridaydemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
       USE [master];
       DROP DATABASE sqlfridaydemo;';
    EXEC (@SQL);
  END;
ELSE
  BEGIN
    PRINT 'Database does not exist'
  END
GO

CREATE DATABASE sqlfridaydemo;
GO

/*
Change settings to reduce number of log records
*/
USE master;
GO
ALTER DATABASE sqlfridaydemo SET RECOVERY SIMPLE;
GO
ALTER DATABASE sqlfridaydemo SET AUTO_CREATE_STATISTICS OFF;
GO

/*
Drop table if exists
Create an empty table
Insert one record with implicit transaction
*/
USE sqlfridaydemo;
GO
SET NOCOUNT ON;
GO
DROP TABLE IF EXISTS dbo.checkpointdemo ;
GO
CREATE TABLE dbo.checkpointdemo (col1 INT);
GO
INSERT INTO dbo.checkpointdemo VALUES (1);
GO

/*
See how many dirty page in buffer from this database
Code copied from Pinal Dave's blog. 
https://blog.sqlauthority.com/2019/06/14/sql-server-clean-pages-and-dirty-pages-count-memory-buffer-pools/
*/
SELECT
  SCHEMA_NAME(objects.schema_id) AS SchemaName,
  objects.name AS ObjectName,
  objects.type_desc AS ObjectType,
  COUNT(*) AS [Total Pages In Buffer],
  COUNT(*) * 8 / 1024 AS [Buffer Size in MB],
  SUM(CASE dm_os_buffer_descriptors.is_modified 
              WHEN 1 THEN 1 ELSE 0
      END) AS [Dirty Pages],
  SUM(CASE dm_os_buffer_descriptors.is_modified 
              WHEN 1 THEN 0 ELSE 1
      END) AS [Clean Pages],
  SUM(CASE dm_os_buffer_descriptors.is_modified 
              WHEN 1 THEN 1 ELSE 0
      END) * 8 / 1024 AS [Dirty Page (MB)],
  SUM(CASE dm_os_buffer_descriptors.is_modified 
              WHEN 1 THEN 0 ELSE 1
      END) * 8 / 1024 AS [Clean Page (MB)]
FROM sys.dm_os_buffer_descriptors
INNER JOIN sys.allocation_units ON allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
INNER JOIN sys.partitions ON
  ((allocation_units.container_id = partitions.hobt_id AND type IN (1,3))
  OR (allocation_units.container_id = partitions.partition_id AND type IN (2)))
INNER JOIN sys.objects ON partitions.object_id = objects.object_id
WHERE allocation_units.type IN (1,2,3)
AND objects.is_ms_shipped = 0 
AND dm_os_buffer_descriptors.database_id = DB_ID()
GROUP BY objects.schema_id, objects.name, objects.type_desc
ORDER BY [Total Pages In Buffer] DESC;

/*
Let's do a checkpoint. Notice the log records about start and end of checkpoint.
Second record LOP_XACT_CKPT	with context LCX_BOOT_PAGE_CKPT will not be there pre SQL 2012
Then run the buffer page count query again. 
Notice the change in number of dirty pages to clean pages. Pages did not get removed from buffer, only written to disk.
*/
CHECKPOINT;
GO
SELECT 
	*
FROM fn_dblog (NULL, NULL)
WHERE  [Operation] <> 'LOP_COUNT_DELTA';
GO

/*
Began an explicit transaction
*/
BEGIN TRAN;
GO
INSERT INTO dbo.checkpointdemo VALUES (2);

/*
Do another checkpoint
Check log records
Excluding records, mostly related to system object modification
Show the log record of Operation = "LOP_XACT_CKPT" Context = "LCX_NULL"
Log record consist the LSN of the oldest uncommited transaction
*/
CHECKPOINT;
GO
SELECT 
	* 
FROM fn_dblog (NULL, NULL)
WHERE  [Operation] <> 'LOP_COUNT_DELTA';
GO

/*
Commit transaction
Issue a chekcpoint
Look at the records
Clean up
*/
COMMIT TRAN;
CHECKPOINT;
GO
SELECT 
	* 
FROM fn_dblog (NULL, NULL)
WHERE  [Operation] <> 'LOP_COUNT_DELTA';
GO

/*
Clean up
Drop the database
*/
USE master;
GO
DROP DATABASE IF EXISTS sqlfridaydemo;
GO