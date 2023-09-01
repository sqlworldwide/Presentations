/*
04_TransactionLogBackup.sql
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

EXEC backupOverview.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupOverview TO DISK = N'C:\Temp\backupOverview\backupOverview_full1.bak';
GO

/*
Insert 5 rows
Take a transaction log backup
*/

EXEC backupOverview.dbo.p_backupTestTable_ins;
GO 5

BACKUP LOG backupOverview TO DISK = N'C:\Temp\backupOverview\backupOverview_tlog1.trn';
GO

/*
Insert 5 rows
Take a full backup
*/

EXEC backupOverview.dbo.p_backupTestTable_ins;
GO 5

BACKUP DATABASE backupOverview TO DISK = N'C:\Temp\backupOverview\backupOverview_full2.bak';
GO

/*
Insert 5 rows
Take a transaction log backup
*/

EXEC backupOverview.dbo.p_backupTestTable_ins;
GO 5

BACKUP LOG backupOverview TO DISK = N'C:\Temp\backupOverview\backupOverview_tlog2.trn'
GO

/*
Quiz: 
How many rows we have now?
What backups I need to restore all 20 rows?
Did the second full backup break logchain?
Would I see the same behavior for differential backup?
*/

USE master;
GO

RESTORE DATABASE backupOverview
FROM  DISK = N'C:\Temp\backupOverview\backupOverview_full1.bak'
WITH REPLACE, NORECOVERY;
GO

RESTORE LOG backupOverview FROM DISK = N'C:\Temp\backupOverview\backupOverview_tlog1.trn'
WITH NORECOVERY;
GO

RESTORE LOG backupOverview FROM DISK = N'C:\Temp\backupOverview\backupOverview_tlog2.trn'
WITH RECOVERY;
GO

SELECT 
	COUNT(0) AS numberOfRows
FROM backupOverview.dbo.backupTestTable;
GO

/*
Clean up
*/

USE master;
GO

DROP DATABASE IF EXISTS backupOverview;
GO