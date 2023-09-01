/*
02_FullBackup.sql
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

RESTORE FILELISTONLY FROM DISK = N'C:\Temp\backupOverview\backupOverview_full.bak';
RESTORE HEADERONLY FROM DISK = N'C:\Temp\backupOverview\backupOverview_full.bak';

/*
Add INIT and run a full backup again
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
	EXPIREDATE = '10/01/2023';
GO

/*
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