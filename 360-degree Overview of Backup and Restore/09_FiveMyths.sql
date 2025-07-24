/*
09_FiveMyths.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Tested on:
SQL Server 2022 CU20
SSMS 21.4.8

Last Modified
July 21, 2025


In this script, I will discuss five common myths about SQL Server backup and demo each to show you the correct answer.
 
1. Does Full and Differential backup breaks the log chain?
2. Are Differential backups incremental?
3. What backups are allowed on system databases?
4  Is transactional backup necessary during full backup?
5. Does backup use a buffer pool to read data pages?

*/

/*
Run code 779-840 before the session starts to save time
Delete all files from folder: "C:\Temp\backupmythdemo\"
Creating an empty databse backupmythdemo for the demo
*/

/*
Ensure backup directory exists
*/
DECLARE @BackupPath NVARCHAR(256) = N'C:\Temp\backupmythdemo\';
DECLARE @CreateDirCmd NVARCHAR(500) = N'mkdir "' + @BackupPath + '"';
EXEC master.sys.xp_cmdshell @CreateDirCmd, NO_OUTPUT;

/*
Clean up old backup files
*/
EXEC master.sys.xp_delete_files N'C:\Temp\backupmythdemo\*'

/*
Setting up database and tables for demo
*/
USE master;
GO
IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = N'backupmythdemo')
BEGIN
  PRINT 'Database backupmythdemo exists, dropping it...'

  -- Kill any active connections first
  DECLARE @SQL NVARCHAR(1000) = 
    N'ALTER DATABASE backupmythdemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
      DROP DATABASE backupmythdemo;';

  BEGIN TRY
    EXEC (@SQL);
    PRINT 'Database dropped successfully.'
END TRY
  BEGIN CATCH
    PRINT 'Error dropping database: ' + ERROR_MESSAGE();
    RETURN;
  END CATCH
END
ELSE
BEGIN
   PRINT 'Database backupmythdemo does not exist, creating a new one...'
END
GO

CREATE DATABASE backupmythdemo;
GO

/*
Set Database into full recovery model
Take a full backup
*/

ALTER DATABASE backupmythdemo SET RECOVERY FULL ;
GO

BACKUP DATABASE backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\fb_backupmythdemo_1.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Create an empty table backupmythdemo
*/

USE backupmythdemo;
GO
SET NOCOUNT ON;
GO
DROP TABLE IF EXISTS dbo.backupTestTable ;
GO

CREATE TABLE dbo.backupTestTable (
	backupTestTableID bigint IDENTITY(1,1) NOT NULL,
  insertTime datetime2 DEFAULT getdate() NOT NULL
);
GO

/*
Create a store procedure to insert data in the table created above
*/

USE backupmythdemo;
GO

DROP PROCEDURE IF EXISTS dbo.p_backupTestTable_ins;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER OFF;
GO

CREATE PROCEDURE dbo.p_backupTestTable_ins
AS
SET NOCOUNT ON 

INSERT INTO backupmythdemo.dbo.backupTestTable
	(
		insertTime
	)
VALUES
	(
		getdate()
	);
SET NOCOUNT OFF
RETURN 0;
GO

/**********************************************************
*                 MYTH ONE                                *
* DOES FULL AND DIFFERENTIAL BACKUP BREAKS THE LOG CHAIN  *
**********************************************************/

/*
Insert 5 rows
Take a full backup
*/

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\fb_backupmythdemo_2.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Insert 5 rows
Take a transaction log backup
*/

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP LOG backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\tb_backupmythdemo_1.trn'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Insert 5 rows
Take a full backup
*/

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\fb_backupmythdemo_3.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Insert 5 rows
Take a transaction log backup
*/

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP LOG backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\tb_backupmythdemo_2.trn'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Quiz: How many rows we have now
*/

SELECT 
	backupTestTableID,
	insertTime
FROM backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO

/*
Does Full and Differential backup breaks the log chain?
Let's restore the full backup as a new database
*/

DROP DATABASE IF EXISTS myth1backupmythdemo;
GO

USE master;
GO

RESTORE DATABASE myth1backupmythdemo 
FROM  DISK = N'C:\Temp\backupmythdemo\fb_backupmythdemo_2.bak' 
WITH  FILE = 1,  
MOVE N'backupmythdemo' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\myth1backupmythdemo.mdf',  
MOVE N'backupmythdemo_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\myth1backupmythdemo_log.ldf',  
STANDBY = N'C:\Temp\backupmythdemo\backupmythdemo_RollbackUndo.bak',  
NOUNLOAD, STATS = 25;
GO

/*
Expect to see only five records
*/

SELECT 
	backupTestTableID,
	insertTime
FROM myth1backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO 

/*
Restoring the first transactional log backup
*/

ALTER DATABASE myth1backupmythdemo  SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE LOG myth1backupmythdemo FROM DISK=N'C:\Temp\backupmythdemo\tb_backupmythdemo_1.trn' 
WITH STANDBY=N'C:\Temp\backupmythdemo\backupmythdemo_RollbackUndo.bak'
ALTER DATABASE myth1backupmythdemo SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO

/*
Expect to see only ten records
*/

SELECT 
	backupTestTableID,
	insertTime
FROM myth1backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO

/*
Can I skip the second full backup and restore the last transaction log?
*/

ALTER DATABASE myth1backupmythdemo  SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE LOG myth1backupmythdemo FROM DISK= N'C:\Temp\backupmythdemo\tb_backupmythdemo_2.trn' 
WITH STANDBY=N'C:\Temp\backupmythdemo\backupmythdemo_RollbackUndo.bak'
ALTER DATABASE myth1backupmythdemo SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO

/*
Expect to see how many records?
*/

SELECT 
	backupTestTableID,
	insertTime
FROM myth1backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO

/*
Lets do the same with an intermediate differential backup instead of a full 
*/

/*
truncate backupTestTable table
Insert 5 rows
Take a full backup
*/

TRUNCATE TABLE backupmythdemo.dbo.backupTestTable;
GO

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\fb_backupmythdemo_4.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Insert 5 rows
Take a transaction log backup
*/

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP LOG backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\tb_backupmythdemo_3.trn'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Insert 5 rows
Take a differential backup
*/

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\db_backupmythdemo_1.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25; 
GO

/*
Insert 5 rows
Take a transaction log backup
*/

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP LOG backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\tb_backupmythdemo_4.trn'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Quiz: How many rows we have now
*/

SELECT 
	backupTestTableID,
	insertTime
FROM backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO

/*
Does Full and Differential backup breaks the log chain?
Let's restore the full backup as a new database
*/

DROP DATABASE IF EXISTS myth1backupmythdemo;
GO

USE master;
GO

RESTORE DATABASE myth1backupmythdemo 
FROM  DISK = N'C:\Temp\backupmythdemo\fb_backupmythdemo_4.bak' 
WITH  FILE = 1,  
MOVE N'backupmythdemo' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\myth1backupmythdemo.mdf',  
MOVE N'backupmythdemo_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\myth1backupmythdemo_log.ldf',  
STANDBY = N'C:\Temp\backupmythdemo\backupmythdemo_RollbackUndo.bak',  
NOUNLOAD, STATS = 25;
GO

/*
Expect to see only five records
*/

SELECT 
	backupTestTableID,
	insertTime
FROM myth1backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO 

/*
Restoring the first transactional log backup
*/

ALTER DATABASE myth1backupmythdemo  SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE LOG myth1backupmythdemo FROM DISK=N'C:\Temp\backupmythdemo\tb_backupmythdemo_3.trn' 
WITH STANDBY=N'C:\Temp\backupmythdemo\backupmythdemo_RollbackUndo.bak'
ALTER DATABASE myth1backupmythdemo SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO

/*
Expect to see only ten records
*/

SELECT 
	backupTestTableID,
	insertTime
FROM myth1backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO

/*
Can I skip the differential backup and restore the last transaction log?
*/

ALTER DATABASE myth1backupmythdemo  SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE LOG myth1backupmythdemo FROM DISK= N'C:\Temp\backupmythdemo\tb_backupmythdemo_4.trn' 
WITH STANDBY=N'C:\Temp\backupmythdemo\backupmythdemo_RollbackUndo.bak'
ALTER DATABASE myth1backupmythdemo SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO

/*
Expect to see how many records?
*/

SELECT 
	backupTestTableID,
	insertTime
FROM myth1backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO

/**********************************************************
*                    MYTH TWO                             *
*        ARE DIFFERENTIAL BACKUPS INCREMENTAL             *
**********************************************************/

/*
Truncate table to start a new demo
*/

TRUNCATE TABLE backupmythdemo.dbo.backupTestTable;
GO

/*
Insert 5 rows
Take a full backup
*/

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\fb_backupmythdemo_5.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Run this three times
Insert 5 rows
Take a diffential backup
*/

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\db_backupmythdemo_2.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\db_backupmythdemo_3.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\db_backupmythdemo_4.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

/*
Quiz: How many rows we have now
*/

SELECT 
	backupTestTableID,
	insertTime
FROM backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO

/*
Do we need to restore all three differential backup to get all twenty rows?
*/

DROP DATABASE IF EXISTS myth2backupmythdemo;
GO

USE master;
GO

/*
Restore the full backup
*/
RESTORE DATABASE myth2backupmythdemo 
FROM  DISK = N'C:\Temp\backupmythdemo\fb_backupmythdemo_5.bak' 
WITH  FILE = 1,  
MOVE N'backupmythdemo' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\myth2backupmythdemo.mdf',  
MOVE N'backupmythdemo_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\myth2backupmythdemo_log.ldf',  
STANDBY = N'C:\Temp\backupmythdemo\myth2backupmythdemo_RollbackUndo.bak',  
NOUNLOAD,  STATS = 25;
GO

SELECT 
	backupTestTableID,
	insertTime
FROM myth2backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO 

/*
Restore the last differential backup file
*/

RESTORE DATABASE myth2backupmythdemo FROM DISK = N'C:\Temp\backupmythdemo\db_backupmythdemo_4.diff' 
WITH STANDBY=N'C:\Temp\backupmythdemo\myth2backupmythdemo_RollbackUndo.bak'  
ALTER DATABASE myth2backupmythdemo SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO

SELECT 
	backupTestTableID,
	insertTime
FROM myth2backupmythdemo.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO 

/**********************************************************
*                  MYTH THREE                             *
*   WHAT BACKUPS ARE ALLOWED ON SYSTEM DATABASES          *
**********************************************************/

/*
master - by default simple recovery
You can switch to full and Bulk-logged
*/

ALTER DATABASE master SET RECOVERY SIMPLE;
GO

SELECT
	name,
	recovery_model_desc
FROM sys.databases
WHERE name = 'master';
GO

/*
Taking a full backup
*/

BACKUP DATABASE master TO DISK = N'C:\Temp\backupmythdemo\fb_master_1.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Will this work?
Will this work if it was a user database in simple recovery model?
*/

BACKUP DATABASE master TO DISK = N'C:\Temp\backupmythdemo\db_master_1.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

/*
Will setting the master database in full recovery make any difference?
*/
ALTER DATABASE master SET RECOVERY FULL;
GO

SELECT
	name,
	recovery_model_desc
FROM sys.databases
WHERE name = 'master';
GO

/*
Taking a full backup
*/

BACKUP DATABASE master TO DISK = N'C:\Temp\backupmythdemo\fb_master_2.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Taking a differential backup
Will this work because master database is in full recovery mode?
*/

BACKUP DATABASE master TO DISK = N'C:\Temp\backupmythdemo\db_master_2.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

/*
Taking a transaction log backup
Will this work because master database is in full recovery mode?
Most likely no as differential backup did not work
*/

BACKUP LOG master TO DISK = N'C:\Temp\backupmythdemo\tb_master_1.trn'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO


/*
model - by default full recovery model
You can switch to simple and Bulk-logged
*/

ALTER DATABASE model SET RECOVERY FULL;
GO

SELECT
	name,
	recovery_model_desc
FROM sys.databases
WHERE name = 'model';
GO

/*
Taking a full backup
*/

BACKUP DATABASE model TO DISK = N'C:\Temp\backupmythdemo\fb_model_1.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Taking a differential backup
Will this work because model database is in full recovery mode?
*/

BACKUP DATABASE model TO DISK = N'C:\Temp\backupmythdemo\db_model_1.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

/*
Taking a transaction log backup
Will this work because model database is in full recovery mode?
*/

BACKUP LOG model TO DISK = N'C:\Temp\backupmythdemo\tb_model_1.trn'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Lets set this up as simple recovery model
*/

ALTER DATABASE model SET RECOVERY SIMPLE;
GO

SELECT
	name,
	recovery_model_desc
FROM sys.databases
WHERE name = 'model';
GO

/*
Taking a full backup
*/

BACKUP DATABASE model TO DISK = N'C:\Temp\backupmythdemo\fb_model_2.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Taking a differential backup
Will this work because model database is in simple recovery model?
Not trying transaction log backup as database is in simple recovery model
*/

BACKUP DATABASE model TO DISK = N'C:\Temp\backupmythdemo\db_model_2.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

/*
msdb - by default simple recovery
You can switch to full and Bulk-logged
Behave exactly same as model database
I am skipping the demo but you can run the code at your leisure
*/

ALTER DATABASE msdb SET RECOVERY SIMPLE;
GO

SELECT
	name,
	recovery_model_desc
FROM sys.databases
WHERE name = 'msdb';
GO

/*
Taking a full backup
*/

BACKUP DATABASE msdb TO DISK = N'C:\Temp\backupmythdemo\fb_msdb_1.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Taking a differential backup
Will this work because model database is in simple recovery model?
Not trying transaction log backup as database is in simple recovery model
*/

BACKUP DATABASE msdb TO DISK = N'C:\Temp\backupmythdemo\db_msdb_1.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

/*
Will setting the msdb database in full recovery make any difference?
*/

ALTER DATABASE msdb SET RECOVERY FULL;
GO

SELECT
	name,
	recovery_model_desc
FROM sys.databases
WHERE name = 'msdb';
GO

/*
Taking a full backup
*/

BACKUP DATABASE msdb TO DISK = N'C:\Temp\backupmythdemo\fb_msdb_2.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Taking a differential backup
Will this work because msdb database is in full recovery mode?
*/

BACKUP DATABASE msdb TO DISK = N'C:\Temp\backupmythdemo\db_msdb_2.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

/*
Taking a transaction log backup
Will this work because msdb database is in full recovery mode?
*/

BACKUP LOG msdb TO DISK = N'C:\Temp\backupmythdemo\tb_msdb_1.trn'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
tempdb - by default simple recovery
You CANNOT change the recovery model
*/

SELECT
	name,
	recovery_model_desc
FROM sys.databases
WHERE name = 'tempdb';
GO

/*
Taking a full backup
It will fail, same will happen for differential.
Backup and restore operations are not allowed on database tempdb
*/

BACKUP DATABASE tempdb TO DISK = N'C:\Temp\backupmythdemo\fb_tempdb_2.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Summary:
------------------------------------------
dbName |default|can_change|full|diff|tlog|
------------------------------------------
master |simple |    Y     | Y  | N  | N  |
------------------------------------------
model  |full   |    Y     | Y  | Y  | Y  |
------------------------------------------
msdb   |full   |    Y     | Y  | Y  | Y  |
------------------------------------------
tempdb |simple |    N     | N  | N  | N  |
------------------------------------------

*/

/**********************************************************
*                 MYTH FOUR                               *
* IS TRANSACTIONAL BACKUP NECESSARY DURING FULL BACKUP    *
**********************************************************/

/*
Prerequisite
Restore 10GB version of StackOverflow2010
https://www.brentozar.com/archive/2015/10/how-to-download-the-stack-overflow-database-via-bittorrent/
Skip line 779-840 which was already executed before session started to save time.
Start demo from line 842
*/

/*
Create an empty table
*/

USE StackOverflow2010;
GO
SET NOCOUNT ON;
GO
DROP TABLE IF EXISTS [dbo].[backupTestTable] ;
GO

CREATE TABLE [dbo].[backupTestTable] (
	backupTestTableID bigint IDENTITY(1,1) NOT NULL,
  insertTime datetime2 DEFAULT getdate() NOT NULL
);
GO

/*
Create a store procedure to insert data in the table created above
*/

USE StackOverflow2010;
GO

DROP PROCEDURE IF EXISTS [dbo].[p_backupTestTable_ins];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER OFF;
GO

CREATE PROCEDURE [dbo].[p_backupTestTable_ins] 
AS
SET NOCOUNT ON 

INSERT INTO [dbo].[backupTestTable]
	(
		insertTime
	)
VALUES
	(
		getdate()
	);
SET NOCOUNT OFF
RETURN 0;
GO

/*
Set Database into full recovery model
Take a full backup
*/

ALTER DATABASE StackOverflow2010 SET RECOVERY FULL ;
GO

BACKUP DATABASE StackOverflow2010 TO DISK = N'C:\Temp\backupmythdemo\fb_StackOverflow2010_1.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Open below code in new window
*/

WHILE (1=1)
BEGIN
EXEC StackOverflow2010.dbo.p_backupTestTable_ins;
WAITFOR DELAY '00:00:02.000'
END

/*
Open below code in new window
*/

WHILE (1=1)
BEGIN
DECLARE @tlogBackup varchar(1000);
SELECT @tlogBackup = (SELECT 'C:\Temp\backupmythdemo\tlogBackup' + LEFT(replace(replace(replace(replace(convert(nvarchar, getdate(), 121), '-', ''), ':', ''), ' ', ''),'.',''), 14) + '.trn') 
BACKUP LOG StackOverflow2010 TO DISK = @tlogBackup
WITH CHECKSUM, COMPRESSION, STATS = 10;
WAITFOR DELAY '00:00:05.000'
END

/*
Start the insert loop
Start a full backup
Start the tlog backup loop
Once the full backup finishes
Stop the insert loop;
Stop the tlog backup loop
*/

BACKUP DATABASE StackOverflow2010 TO DISK = N'C:\Temp\backupmythdemo\fb_StackOverflow2010_2.bak'
WITH CHECKSUM, COMPRESSION, STATS = 10;
GO

/*
Look at backup files and the data in the table
Take a note of number or records included in the full backup files
*/

SELECT  
	database_name,
  backup_start_date,
  backup_finish_date,
  type,
  first_lsn ,
  last_lsn ,
  checkpoint_lsn ,
  database_backup_lsn
FROM msdb.dbo.backupset
WHERE database_name = 'StackOverflow2010'
AND backup_start_date >= dateadd(minute, -30, getdate())
ORDER BY backup_finish_date;
GO

SELECT 
	backupTestTableID,
	insertTime
FROM StackOverflow2010.dbo.backupTestTable
ORDER BY insertTime DESC;
GO 

/*
Restore the full backup and check the data
This means you could have skipped the transaction log file backup during full backup with some risk
- What will happen if full backup fails
- What will happen if you need to do a point in time restore between previous full/diff and the current fullbackup finishes
*/

DROP DATABASE IF EXISTS restoreStackOverflow2010;
GO

USE master;
GO

RESTORE DATABASE restoreStackOverflow2010 FROM DISK = N'C:\Temp\backupmythdemo\fb_StackOverflow2010_2.bak' 
WITH  FILE = 1, 
MOVE N'StackOverflow2010' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\restoreStackOverflow2010.mdf',  
MOVE N'StackOverflow2010_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\restoreStackOverflow2010_log.ldf' 
GO

SELECT 
	backupTestTableID,
	insertTime
FROM restoreStackOverflow2010.dbo.backupTestTable
ORDER BY backupTestTableID DESC;
GO 

/**********************************************************
*                 MYTH FIVE                               *
* DOES BACKUP USE A BUFFER POOL TO READ DATA PAGES        *
**********************************************************/

/*
Quick answer no.
Details read this.
https://learn.microsoft.com/en-us/archive/blogs/psssql/how-it-works-sql-server-backup-buffer-exchange-a-vdi-focus
*/

USE backupmythdemo;
GO

EXEC backupmythdemo.dbo.p_backupTestTable_ins;
GO 1000

SELECT 
  * 
FROM backupmythdemo.dbo.backupTestTable;
GO

/*
See how many page in buffer from this database
Code copied from Pinal Dave's blog. 
https://blog.sqlauthority.com/2019/06/14/sql-server-clean-pages-and-dirty-pages-count-memory-buffer-pools/
*/

USE backupmythdemo;
GO

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
GO

/*
Clear buffer
Why are you doing checkpoint?
This is a blogpost Paul Randal wrote in response to one my question.
https://www.sqlskills.com/blogs/paul/when-dbcc-dropcleanbuffers-doesnt-work/
*/

CHECKPOINT 
DBCC DROPCLEANBUFFERS
GO

USE backupmythdemo;
GO

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
GO


/*
Do a full backup
Check the buffer again and see if any pages are there?
*/

BACKUP DATABASE backupmythdemo TO DISK = N'C:\Temp\backupmythdemo\fb_backupmythdemo_6.bak'
WITH CHECKSUM, COMPRESSION, STATS = 10;
GO

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
GO

/*
Cleanup

USE master;
GO
DROP DATABASE IF EXISTS backupmythdemo;
GO
DROP DATABASE IF EXISTS myth1backupmythdemo;
GO
DROP DATABASE IF EXISTS myth2backupmythdemo;
GO
DROP DATABASE IF EXISTS StackOverflow2010;
GO
DROP DATABASE IF EXISTS restoreStackOverflow2010;
GO
*/