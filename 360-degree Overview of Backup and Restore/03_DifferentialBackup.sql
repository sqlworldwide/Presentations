/*
03_DifferentialBackup.sql
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
IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = N'backupOverview')
BEGIN
  PRINT 'Database backupOverview exists, dropping it...'
    
  -- Kill any active connections first
  DECLARE @SQL NVARCHAR(1000) = 
    N'ALTER DATABASE backupOverview SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
      DROP DATABASE backupOverview;';
    
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
Create database backupOverview
*/
CREATE DATABASE backupOverview;
GO

/*
Set recovery model 
*/
ALTER DATABASE backupOverview SET RECOVERY FULL;
GO

/*
Create demo table 
*/
USE backupOverview;
GO
DROP TABLE IF EXISTS dbo.backupTestTable;
GO

CREATE TABLE dbo.backupTestTable
(
  backupTestTableID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  insertTime DATETIME2 DEFAULT GETDATE() NOT NULL,
  sampleData NVARCHAR(100) DEFAULT 'Sample data for backup demo',
  INDEX IX_backupTestTable_insertTime NONCLUSTERED (insertTime)
);
GO

/*
Create stored procedure
*/
DROP PROCEDURE IF EXISTS dbo.p_backupTestTable_ins;
GO

CREATE PROCEDURE dbo.p_backupTestTable_ins
  @RecordCount INT = 1
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE @Counter INT = 1;
  
  WHILE @Counter <= @RecordCount
  BEGIN
      INSERT INTO dbo.backupTestTable (insertTime, sampleData)
      VALUES (GETDATE(), 'Demo record ' + CAST(@Counter AS NVARCHAR(10)));
      
      SET @Counter = @Counter + 1;
  END
    
  PRINT 'Inserted ' + CAST(@RecordCount AS NVARCHAR(10)) + ' records';
END
GO

/*
Insert 5 rows
Take a full backup
*/
USE backupOverview;
GO 

EXEC backupOverview.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupOverview TO DISK = N'C:\Temp\backupOverview\backupOverview_full.bak'
WITH CHECKSUM, COMPRESSION, STATS = 25;
GO

/*
Run this three times
Insert 5 rows
Take a diffential backup after each 5 row insert
*/
EXEC backupOverview.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupOverview TO DISK = N'C:\Temp\backupOverview\backupOverview_diff1.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

EXEC backupOverview.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupOverview TO DISK = N'C:\Temp\backupOverview\backupOverview_diff2.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

EXEC backupOverview.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupOverview TO DISK = N'C:\Temp\backupOverview\backupOverview_diff3.diff'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 25;  
GO

/*
Quiz: 
How many rows we have now?
What backups I need to restore all 20 rows?
Do we need to restore all three differential backup to get all twenty rows?
*/
USE master;
GO
-- Step 1: Kill connections and set single user mode
BEGIN TRY
  ALTER DATABASE backupOverview SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  PRINT 'Database set to single user mode successfully.';
END TRY
BEGIN CATCH
  PRINT 'Error setting single user mode: ' + ERROR_MESSAGE();
END CATCH

-- Step 2: Perform restore
USE master;
GO
RESTORE DATABASE backupOverview
FROM DISK = N'C:\Temp\backupOverview\backupOverview_full.bak'
WITH REPLACE, NORECOVERY; 
GO  

--Note which differential backup we are restoring?
RESTORE DATABASE backupOverview
FROM DISK = N'C:\Temp\backupOverview\backupOverview_diff3.diff'
WITH RECOVERY; 
GO  

-- Step 3: Set back to multi-user mode
ALTER DATABASE backupOverview SET MULTI_USER;
GO

/*
Confirm we have all the 20 records
*/
USE backupOverview;
GO

SELECT COUNT(*) AS TotalRecords FROM backupTestTable;
GO

/*
Clean up
*/
USE master;
GO

DROP DATABASE IF EXISTS backupOverview;
GO
