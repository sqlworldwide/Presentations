/*
01_DefaultSetup.sql
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
Check and set default compression, checksum, and media retention settings for all databases in a server
Show the same in SSMS
ServerName-->Properties-->Database Settings
*/
USE master;
GO

SELECT 
	value
FROM sys.configurations
WHERE name = 'backup compression default';
GO

EXEC sys.sp_configure N'backup compression default', N'1'
GO

RECONFIGURE WITH OVERRIDE
GO

/*
When you use the CHECKSUM option during a backup operation, the following processes are enabled:

Validation of page checksum if the database has the PAGE_VERIFY option set to CHECKSUM and the database page was last written by using checksum protection. This checksum validation ensures that the data that is backed up is in a good state.

Generation of a backup checksum over the backup streams that are written to the backup file. During a restore operation, this validation ensures that the backup media wasn't damaged during file copy or transfers.

https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/mssqlserver-3043-database-engine-error?view=sql-server-ver17
*/
SELECT 
	value   
FROM sys.configurations   
WHERE name = 'backup checksum default';  
GO

EXEC sys.sp_configure N'backup checksum default', N'1'
GO

RECONFIGURE WITH OVERRIDE
GO

/*
The media retention option specifies the length of time to retain each backup set.
The option helps protect backups from being overwritten until the specified number of days elapses.
After you configure media retention option, you don't have to specify the length of time to retain system backups each time you perform a backup. 
The default value is 0 days, and the maximum value is 365 days.
*/
SELECT 
	value
FROM sys.configurations
WHERE name = 'media retention';
GO

EXEC sys.sp_configure N'media retention', N'0'
GO

RECONFIGURE WITH OVERRIDE
GO

