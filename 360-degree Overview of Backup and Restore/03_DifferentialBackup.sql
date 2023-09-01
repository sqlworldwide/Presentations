/*
03_DifferentialBackup.sql
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

We don't need to be taking file backups in order to perform a partial/piecemeal restore. 
If the database is small enough, we can still take full database backups and then restore just a certain filegroup from that backup file as shown in this demo
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

IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = N'backupOverview')
  BEGIN
    SET @SQL = 
      N'USE [master];
       ALTER DATABASE backupOverview SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
       USE [master];
       DROP DATABASE backupOverview;';
    EXEC (@SQL);
  END;
ELSE
  BEGIN
    PRINT 'Database backupOverview does not exist, creating a new one'
  END
GO

CREATE DATABASE backupOverview;
GO

ALTER DATABASE backupOverview SET RECOVERY FULL ;
GO

USE backupOverview;
GO
SET NOCOUNT ON;
GO
DROP TABLE IF EXISTS dbo.backupTestTable ;
GO

CREATE TABLE dbo.backupTestTable
(
  backupTestTableID bigint IDENTITY(1,1) NOT NULL,
  insertTime datetime2 DEFAULT getdate() NOT NULL
);
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

INSERT INTO backupOverview.dbo.backupTestTable
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
Insert 5 rows
Take a full backup
*/

USE master;
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

RESTORE DATABASE backupOverview
FROM DISK =N'C:\Temp\backupOverview\backupOverview_full.bak'
WITH REPLACE, NORECOVERY; 
GO  

RESTORE DATABASE backupOverview
FROM DISK =N'C:\Temp\backupOverview\backupOverview_diff3.diff'
WITH RECOVERY; 
GO  

/*
Confirm we have all the 20 records
*/

USE backupOverview;
GO

SELECT * FROM backupTestTable;
GO

/*
Clean up
*/

USE master;
GO

DROP DATABASE IF EXISTS backupOverview;
GO
