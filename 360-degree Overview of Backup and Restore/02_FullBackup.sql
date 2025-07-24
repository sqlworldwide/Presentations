/*
02_FullBackup.sql
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
Taking a full backup
Talk about options
What will happen if I run the same statement a second time?
*/
USE master;
GO 

BACKUP DATABASE backupOverview 
TO DISK = N'C:\Temp\backupOverview\backupOverview_full.bak'
  WITH CHECKSUM, --only use if server default is 0
  COMPRESSION, --only use if server default is 0
  STATS = 25;
GO

/*
Check the backup file
*/
RESTORE FILELISTONLY FROM DISK = N'C:\Temp\backupOverview\backupOverview_full.bak';

/*
Check the header information
*/
RESTORE HEADERONLY FROM DISK = N'C:\Temp\backupOverview\backupOverview_full.bak';

/*
Add INIT and run a full backup again
This will overwrite the existing backup file
*/
USE master;
GO 

BACKUP DATABASE backupOverview 
TO DISK = N'C:\Temp\backupOverview\backupOverview_full.bak'
  WITH CHECKSUM, --only use if server default is 0
  COMPRESSION, --only use if server default is 0
  STATS = 25,
	INIT;
GO

RESTORE HEADERONLY FROM DISK = N'C:\Temp\backupOverview\backupOverview_full.bak';

/*
Override default expiration date
How long a backup should be prohibited from being over written and not delete
Run it twice
*/
USE master;
GO 

BACKUP DATABASE backupOverview 
TO DISK = N'C:\Temp\backupOverview\backupOverview_full.bak'
  WITH CHECKSUM, --only use if server default is 0
  COMPRESSION, --only use if server default is 0
  STATS = 25,
	INIT,
	EXPIREDATE = '07/13/2025';
GO

/*
Show expiration date in backup header
*/
SELECT 
  database_name,
  backup_start_date,
  expiration_date,
  description
FROM msdb.dbo.backupset
WHERE database_name = 'backupOverview'
  AND type = 'D'  -- Full backup
ORDER BY backup_start_date DESC;
GO

/*
expiration date prohibit overwriting but;
Does not prohibit you from deleteing the file
*/
EXEC master.sys.xp_delete_files N'C:\Temp\backupOverview\backupOverview_full.bak'

/*
Clean up
*/
USE master;
GO

DROP DATABASE IF EXISTS backupOverview;
GO