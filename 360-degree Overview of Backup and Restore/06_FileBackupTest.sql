/*
06_FileBackupTest.sql
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
https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/full-file-backups-sql-server?view=sql-server-ver16&redirectedfrom=MSDN

The best practice is to perform a full database backup and start the transaction log backups before the first file backup
Transaction logs are necessary to roll forward transactions when restoring file backups taken at different times
Reduce the number of log files that need processing can be achieved by taking differnetial file backups
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

IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = N'fileBackupTest')
  BEGIN
    SET @SQL = 
      N'USE [master];
       ALTER DATABASE fileBackupTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
       USE [master];
       DROP DATABASE fileBackupTest;';
    EXEC (@SQL);
  END;
ELSE
  BEGIN
    PRINT 'Database fileBackupTest does not exist, creating a new one'
  END
GO

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

USE fileBackupTest;
GO  

CREATE TABLE dbo.table_DF1
(Message NVARCHAR(50) NOT NULL) ON  [PRIMARY];
GO 

CREATE TABLE dbo.table_DF2     
(Message NVARCHAR(50) NOT NULL) ON  [SECONDARY];
GO  

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
Insert another record into the tables
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
2023-08-26 08:22:09.357
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
Insert another record into the tables that is not in any backup
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
WITH REPLACE; ; 
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
Copy the time from 361 line and past at line 501
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
WITH RECOVERY, STOPAT = '2023-08-26 08:22:09.357' 
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

USE master;
GO
ALTER DATABASE fileBackupTest SET ONLINE
GO

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
FROM DISK = N'C:\Temp\backupOverview\fileBackupTest_log2.trn' 
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
