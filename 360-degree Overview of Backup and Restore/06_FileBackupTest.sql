/*
06_FileBackupTest.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/


Tested on:
SQL Server 2022 CU20
SSMS 21.4.8

Code copied from this link and modified for this presentation
https://www.red-gate.com/simple-talk/wp-content/uploads/RedGateBooks/ShawnMcGehee/sql-server-backup-restore.pdf

Last Modified
July 21, 2025
	
Read more about file backups
https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/full-file-backups-sql-server?view=sql-server-ver16&redirectedfrom=MSDN

The best practice is to perform a full database backup and start the transaction log backups before the first file backup
Transaction logs are necessary to roll forward transactions when restoring file backups taken at different times
Reduce the number of log files that need processing can be achieved by taking differnetial file backups
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
IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = N'fileBackupTest')
BEGIN
  PRINT 'Database fileBackupTest  exists, dropping it...'

  -- Kill any active connections first
  DECLARE @SQL NVARCHAR(1000) = 
    N'ALTER DATABASE fileBackupTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
      DROP DATABASE fileBackupTest;';

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
  PRINT 'Database fileBackupTest does not exist, creating a new one...'
END
GO

/*
Create database fileBackupTest
*/
CREATE DATABASE fileBackupTest ON PRIMARY 
	(	NAME = N'fileBackupTest', 
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\fileBackupTest.mdf', 
		SIZE = 5120KB, FILEGROWTH = 1024KB ), 
	FILEGROUP [Secondary] 
	(	NAME = N'fileBackupTestUserData1', 
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\fileBackupTestUserData1.ndf', 
		SIZE = 5120KB, FILEGROWTH = 1024KB )
	LOG ON 
	( NAME = N'fileBackupTest_log', 
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\fileBackupTest_log.ldf', 
		SIZE = 1024KB, FILEGROWTH = 512KB ) 
GO 

ALTER DATABASE fileBackupTest SET RECOVERY FULL;
GO

/*
Create tables for testing
*/
USE fileBackupTest;
GO  

CREATE TABLE dbo.table_DF1
(Message NVARCHAR(50) NOT NULL) ON  [PRIMARY];
GO 

CREATE TABLE dbo.table_DF2     
(Message NVARCHAR(50) NOT NULL) ON  [SECONDARY];
GO  

/*
Insert initial data into tables
*/
INSERT INTO table_DF1 
VALUES ('This is the initial data load for the table_DF1');
GO

INSERT INTO table_DF2 
VALUES ('This is the initial data load for the table_DF2');
GO

/*
Perform full file backups of each of our data files for the Database fileBackupTest
Show it from the GUI first
*/
BACKUP DATABASE fileBackupTest
FILEGROUP = N'Primary' 
TO  DISK = N'C:\Temp\backupOverview\fileBackupTest_FG1_Full.bak';
GO

BACKUP DATABASE fileBackupTest
FILEGROUP = N'Secondary' 
TO  DISK = N'C:\Temp\backupOverview\fileBackupTest_FG2_Full.bak';
GO

BACKUP LOG fileBackupTest 
TO DISK = N'C:\Temp\backupOverview\fileBackupTest_log.trn';
GO

/*
Insert another set of records into the tables
*/
USE fileBackupTest;
GO  
 
INSERT INTO table_DF1 
VALUES ('This is the second data load for the table_DF1 ');
GO

INSERT INTO table_DF2 
VALUES ('This is the second data load for the table_DF2');
GO

/*
Perform differential file backup
Not using filegroup here, need to list all files in the filegroup
In our case we only have one
*/
BACKUP DATABASE fileBackupTest
FILE = N'fileBackupTest' 
TO  DISK = N'C:\Temp\backupOverview\fileBackupTest_FG1_Diff.bak'
WITH DIFFERENTIAL;
GO

BACKUP DATABASE fileBackupTest
FILE = N'fileBackupTestUserData1' 
TO  DISK = N'C:\Temp\backupOverview\fileBackupTest_FG2_Diff.bak' 
WITH DIFFERENTIAL;
GO

/*
Note the time here:
2025-07-13 10:28:42.670
*/
SELECT GETDATE();
GO

/*
Insert another record into the tables
Take a transaction log backup
*/
USE fileBackupTest;
GO  
 
INSERT INTO table_DF1 
VALUES ('Point in time data load for the table_DF1');
GO

INSERT INTO table_DF2 
VALUES ('Point in time data load for the table_DF2');
GO

BACKUP LOG fileBackupTest 
TO DISK = N'C:\Temp\backupOverview\fileBackupTest_log2.trn';
GO

/*
Insert another set of records into the tables that is not in any backup
*/
USE fileBackupTest;
GO

INSERT INTO table_DF1
VALUES ('This is the third data load for the table_DF1');
GO

INSERT INTO table_DF2 
VALUES ('This is the third data load for the table_DF2');
GO

/*
Look at restore scenarios
Taking a tail log backup with NORECOVERY
In SQL Server, performing a log backup with the NORECOVERY option is often done to prepare a database for a restore operation. This backup type preserves the transaction log and keeps the database in a "restoring" state, preventing further modifications until a recovery operation is performed.
*/
USE master;
GO

BACKUP LOG fileBackupTest 
TO DISK = N'C:\Temp\backupOverview\fileBackupTest_tail-log.trn'
WITH NORECOVERY;
GO

/*
Restore first set of full bakcups
Look at the message why SQL Server could not bring the database online
*/
USE master;
GO 

RESTORE DATABASE fileBackupTest FILE = N'fileBackupTest'  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_FG1_Full.bak'
WITH REPLACE;
GO  

RESTORE DATABASE fileBackupTest FILE = N'fileBackupTestUserData1'  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_FG2_Full.bak' 
WITH NORECOVERY; 
GO

/*
Restore differential
skipping the first transaction log backup
*/
USE master;
GO 

RESTORE DATABASE fileBackupTest FILE = N'fileBackupTest'  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_FG1_Diff.bak'
WITH NORECOVERY; ; 
GO  

RESTORE DATABASE fileBackupTest FILE = N'fileBackupTestUserData1'  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_FG2_Diff.bak' 
WITH NORECOVERY; 
GO

/*
Restoring the second transaction log backup
*/
USE master;
GO 

RESTORE DATABASE fileBackupTest  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_log2.trn' 
WITH NORECOVERY; 
GO

/*
Restoring the tail log backup with RECOVERY
*/
USE master;
GO 

RESTORE DATABASE fileBackupTest  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_tail-log.trn'
WITH RECOVERY; 
GO

/*
Check if we restored all the data
*/
USE fileBackupTest;
GO

SELECT * FROM dbo.table_DF1;
GO

SELECT * FROM dbo.table_DF2;
GO

/*
Restoring to a point in time
Copy the time from 165 line and past at line 312
*/
USE master;
GO 

RESTORE DATABASE fileBackupTest FILE = N'fileBackupTest'  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_FG1_Full.bak'
WITH REPLACE; 
GO  

RESTORE DATABASE fileBackupTest FILE = N'fileBackupTestUserData1'  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_FG2_Full.bak' 
WITH NORECOVERY; 
GO

RESTORE DATABASE fileBackupTest FILE = N'fileBackupTest'  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_FG1_Diff.bak'
WITH NORECOVERY; ; 
GO  

RESTORE DATABASE fileBackupTest FILE = N'fileBackupTestUserData1'  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_FG2_Diff.bak' 
WITH NORECOVERY; 
GO

RESTORE DATABASE fileBackupTest 
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_log2.trn' 
WITH RECOVERY, STOPAT = '2025-07-13 10:28:42.670' 
GO

/*
We should only have the first two records in each table
*/
USE fileBackupTest;
GO

SELECT * FROM dbo.table_DF1;
GO

SELECT * FROM dbo.table_DF2;
GO

/*
Simulate a file (not in Primary Group) damaged or missing
*/
USE master;
GO

ALTER DATABASE fileBackupTest SET OFFLINE
GO

/*
delete this file 
C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\fileBackupTestUserData1.ndf
Attempt to bring the database online
*/
EXEC master.sys.xp_delete_files 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\fileBackupTestUserData1.ndf';
GO

USE master;
GO
ALTER DATABASE fileBackupTest SET ONLINE
GO

/*
What is the status of database tailLogTest database?
*/
SELECT 
	name, 
	state,
	state_desc
FROM sys.databases 
WHERE name ='fileBackupTest'

/*
Take a tail log backup
*/
USE master;
GO

BACKUP LOG fileBackupTest 
TO DISK = N'C:\Temp\backupOverview\fileBackupTest_tail-log1.trn'
WITH NO_TRUNCATE;
GO

/*
Restore missing file only
*/
USE master;
GO 

RESTORE DATABASE fileBackupTest FILE = N'fileBackupTestUserData1'  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_FG2_Full.bak' 
WITH NORECOVERY; 
GO

RESTORE DATABASE fileBackupTest FILE = N'fileBackupTestUserData1'  
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_FG2_Diff.bak' 
WITH NORECOVERY; 
GO

RESTORE DATABASE fileBackupTest 
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_tail-log1.trn' 
WITH RECOVERY;
GO


/*
Did it work?
*/
USE fileBackupTest;
GO

SELECT * FROM dbo.table_DF1;
GO

SELECT * FROM dbo.table_DF2;
GO

/*
Clean up
*/
USE master;
GO

DROP DATABASE IF EXISTS fileBackupTest;
GO
