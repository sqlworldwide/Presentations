/*
05_TailLogBackup.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/


Tested on:
SQL Server 2022 CU20
SSMS 21.4.8

Code copied from this link and modified for this presentation
https://thesqlpro.wordpress.com/2014/01/16/sql-snacks-video-tail-log-backup-and-recovery-demo/

Last Modified
July 21, 2025
*/

/*
Ensure backup directory exists
*/
DECLARE @BackupPath NVARCHAR(256) = N'C:\Temp\backupOverview\';
DECLARE @CreateDirCmd NVARCHAR(500) = N'mkdir "' + @BackupPath + '"';
EXEC master.sys.xp_cmdshell @CreateDirCmd, NO_OUTPUT;

/*
Clean up old backup files
*/
EXEC master.sys.xp_delete_files N'C:\Temp\backupOverview\*'

/*
Setting up database and tables for demo
*/
USE master;
GO
IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = N'tailLogTest')
BEGIN
  PRINT 'Database tailLogTest exists, dropping it...'

  -- Kill any active connections first
  DECLARE @SQL NVARCHAR(1000) = 
    N'ALTER DATABASE tailLogTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
      DROP DATABASE tailLogTest;';

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
  PRINT 'Database backupOverview does not exist, creating a new one...'
END
GO

/*
Create database tailLogTest
*/
CREATE DATABASE tailLogTest;
GO

/*
Set recovery model 
*/
ALTER DATABASE tailLogTest SET RECOVERY FULL;
GO

/*
Create demo table 
*/
USE tailLogTest;
GO
CREATE TABLE Test1
	(
		column1 int,
		column2 varchar(10),
		column3 datetime default getdate()
	);
GO

/*
Insert 2 rows
Take a full backup
*/
INSERT INTO Test1 (column1, column2) 
VALUES (1,'One'),
	     (2,'Two');
GO

BACKUP DATABASE tailLogTest TO DISK = N'C:\Temp\backupOverview\tailLogTest_full.bak';
GO

/*
Insert 2 rows
Take a transactional log backup
*/
INSERT INTO Test1 (column1, column2) 
VALUES (3,'Three'),
	     (4,'Four');
GO

USE tailLogTest;
GO
BACKUP LOG TailLogTest TO DISK = N'C:\Temp\backupOverview\tailLogTest_tlog1.trn';
GO

/*
Insert 2 rows
*/
INSERT INTO Test1 (column1, column2) 
VALUES (5,'Five'),
	     (6,'Six');
GO

/*
Set Database Offline
*/
USE MASTER;
GO
ALTER Database tailLogTest SET OFFLINE;
GO

/*
Delete the Datafile from the drive 🙂 simulate a disaster
Set the Database Back Online
*/
EXEC master.sys.xp_delete_files 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\tailLogTest.mdf';
GO

USE master;
GO

ALTER Database tailLogTest SET ONLINE;
GO

/*
What is the status of database tailLogTest database?
*/
SELECT 
	name, 
	state,
	state_desc
FROM sys.databases 
WHERE name ='tailLogTest'

/*
Oppssss! Let's get a TailLog Backup before we lose those last two rows we inserted
If you try without NO_TRUNCATE options what will happen?
You will get an error that the database is in recovery mode and you cannot take a tail log backup
*/

USE MASTER;
GO

BACKUP LOG TailLogTest
TO DISK = N'C:\Temp\backupOverview\tailLogTest_taillog.trn'
WITH NO_TRUNCATE;
GO

/*
Let's restore it to another DB and check to see if our data is there
*/
DROP DATABASE IF EXISTS tailLogTest2;
GO

/*
Restore the full backup
*/
USE master;
GO

RESTORE DATABASE tailLogTest2 
FROM  DISK = N'C:\Temp\backupOverview\tailLogTest_full.bak'
WITH  FILE = 1,  
MOVE N'tailLogTest' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\tailLogTest2.mdf',  
MOVE N'tailLogTest_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\tailLogTest2_log.ldf',  
NOUNLOAD, STATS = 25, NORECOVERY;
GO

/*
Restore the first transaction log backup
*/
RESTORE DATABASE tailLogTest2 
FROM DISK = N'C:\Temp\backupOverview\tailLogTest_tlog1.trn'
WITH NORECOVERY;
GO

/*
Restore the tail log backup
*/
RESTORE DATABASE tailLogTest2 
FROM DISK = N'C:\Temp\backupOverview\tailLogTest_taillog.trn'
WITH RECOVERY;
GO

/*
Check if we have six records
*/
USE tailLogTest2;
GO

SELECT 
	column1,
	column2,
	column3
FROM Test1;
GO

/*
Clean up
*/
USE master;
GO

DROP DATABASE IF EXISTS tailLogTest;
GO

DROP DATABASE IF EXISTS tailLogTest2;
GO

EXEC master.sys.xp_delete_files 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\tailLogTest_log.ldf';
GO

