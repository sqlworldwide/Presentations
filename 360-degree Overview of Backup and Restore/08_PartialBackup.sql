/*
08_PartialBackup.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://twitter.com/SqlWorldWide
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Code copied from this link and modified for this presentation
https://www.red-gate.com/simple-talk/wp-content/uploads/RedGateBooks/ShawnMcGehee/sql-server-backup-restore.pdf

Last Modiefied
August 28, 2023
	
Tested on :
SQL Server 2022 CU7
SSMS 19.1

Read more about file backups
https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/partial-backups-sql-server?view=sql-server-ver16

Partial backups are not supported by SQL Server Management Studio or the Maintenance Plan Wizard.

Even thought partial backup support all recovery models, designed for use with simple recovery model for very large databases consists of read_only file groups.

A partial backup resembles a full database backup, but a partial backup does not contain all the filegroups. 
Instead, for a read-write database, a partial backup contains the data in the primary filegroup, every read-write filegroup, and, optionally, one or more read-only files. 
*/

/*
Delete all old backups
*/

EXEC master.sys.xp_delete_files N'C:\Temp\backupOverview\*'

/*
Setting up database and tables for demo
*/

USE master;
GO

DECLARE @SQL nvarchar(1000);

IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = N'partialBackupTest')
  BEGIN
    SET @SQL = 
      N'USE [master];
       ALTER DATABASE partialBackupTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
       USE [master];
       DROP DATABASE partialBackupTest;';
    EXEC (@SQL);
  END;
ELSE
  BEGIN
    PRINT 'Database partialBackupTest does not exist, creating a new one'
  END
GO

CREATE DATABASE partialBackupTest ON PRIMARY 
	(	NAME = N'partialBackupTest', 
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\partialBackupTest.mdf', 
		SIZE = 5120KB, FILEGROWTH = 1024KB ), 
	FILEGROUP [Archive] 
	(	NAME = N'partialBackupTestData2', 
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\partialBackupTestData2.ndf', 
		SIZE = 5120KB, FILEGROWTH = 1024KB )
	LOG ON 
	( NAME = N'partialBackupTestData2_log', 
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\partialBackupTestData2_log.ldf', 
		SIZE = 1024KB, FILEGROWTH = 512KB ) 
GO 

ALTER DATABASE partialBackupTest SET RECOVERY FULL;
GO

USE partialBackupTest;
GO  

CREATE TABLE dbo.mainData
	(ID INT NOT NULL IDENTITY(1,1),
	 [Message] NVARCHAR(50) NOT NULL) 
ON  [PRIMARY];
GO  

CREATE TABLE dbo.archiveData
	(ID INT NOT NULL,
	 [Message] NVARCHAR(50) NOT NULL)  
ON  [Archive];
GO 

INSERT INTO dbo.mainData
VALUES 
	('Data for initial database load: Data 1'),
	('Data for initial database load: Data 2'),
	('Data for initial database load: Data 3');
GO

/*
Move data to archive table
Set the Acrchive filegroup to read_only
Delete the data from mainData table
Load next set of live data
*/

USE partialBackupTest;
GO

INSERT INTO dbo.archiveData
	SELECT 
		ID,
		Message
	FROM dbo.mainData;
GO

ALTER DATABASE partialBackupTest MODIFY FILEGROUP Archive READONLY;
GO 

DELETE FROM dbo.mainData;
GO

INSERT INTO dbo.mainData
VALUES 
	('Data for initial database load: Data 4'),
	('Data for initial database load: Data 5'),
	('Data for initial database load: Data 6');
GO

/*
Taking a full backup which is not pre-requisite for partial backup but best practice
Notice it backs up all files
*/

BACKUP DATABASE partialBackupTest
TO  DISK = N'C:\Temp\backupOverview\partialBackupTest_full.bak';
GO

/*
Taking a partial backup which will exclude read_only filegroups which in our case is archive filegroup
*/

BACKUP DATABASE partialBackupTest READ_WRITE_FILEGROUPS
TO  DISK = N'C:\Temp\backupOverview\partialBackupTest_partial_full.bak';
GO

/*
Insert another set of data before we take differential backup
Take a differential partial backup
*/

USE partialBackupTest;
GO

INSERT INTO dbo.mainData
VALUES 
	('Data for initial database load: Data 7'),
	('Data for initial database load: Data 8'),
	('Data for initial database load: Data 9');
GO

BACKUP DATABASE partialBackupTest READ_WRITE_FILEGROUPS
TO  DISK = N'C:\Temp\backupOverview\partialBackupTest_partial_diff.bak'
WITH DIFFERENTIAL;
GO

/*
Restore from partial backup
*/

USE master;
GO

RESTORE DATABASE partialBackupTest 
FROM DISK = N'C:\Temp\backupOverview\partialBackupTest_partial_full.bak'
WITH REPLACE, NORECOVERY;
GO

RESTORE DATABASE partialBackupTest 
FROM DISK = N'C:\Temp\backupOverview\partialBackupTest_partial_diff.bak'
WITH RECOVERY;
GO

/*
Check the data
*/

USE partialBackupTest;
GO

SELECT 
	ID, 
	[Message]
FROM dbo.mainData;
GO

USE partialBackupTest;
GO

SELECT 
	ID, 
	[Message]
FROM dbo.archiveData;
GO

/*
Clean up
*/

USE master;
GO

DROP DATABASE IF EXISTS partialBackupTest;
GO
