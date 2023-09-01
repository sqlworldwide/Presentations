/*
01_DefaultSetup.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://twitter.com/SqlWorldWide
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modiefied
May 29, 2023
	
Tested on :
SQL Server 2022 CU7
SSMS 19.1
*/

/*
Check and set default compression, checksum, and media retention settings for all databases in a server
Show the same in SSMS
ServerName-->Properties-->Database Settings
*/

USE master;
GO

SELECT value   
FROM sys.configurations   
WHERE name = 'backup compression default' ;  
GO
EXEC sys.sp_configure N'backup compression default', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO

SELECT value   
FROM sys.configurations   
WHERE name = 'backup checksum default' ;  
GO
EXEC sys.sp_configure N'backup checksum default', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO

SELECT value   
FROM sys.configurations   
WHERE name = 'media retention' ;  
EXEC sys.sp_configure N'media retention', N'0'
GO
RECONFIGURE WITH OVERRIDE
GO

