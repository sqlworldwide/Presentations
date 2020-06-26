/*============================================================================
PutThingsBackForDemo.sql
Written by Taiob M Ali
SqlWorldWide.com

This script will restore WideWorldImporters database to set things back as is for demo.

Instruction to run this script
--------------------------------------------------------------------------
Download WideWorldImporters backup from
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0

Change:
1. Backup location
2. Data file location
3. Log file location
============================================================================*/

USE [master]
GO
DECLARE @dbname nvarchar(128)
SET @dbname = N'WideWorldImporters'

IF (EXISTS (SELECT name 
FROM master.dbo.sysdatabases 
WHERE ('[' + name + ']' = @dbname 
  OR name = @dbname)))
BEGIN
ALTER DATABASE [WideWorldImporters] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
END
GO

DECLARE @fileName nvarchar(255)
SET @fileName = N'C:\WideWorldImporters-Full.bak'
--Restoring to default path
RESTORE DATABASE [WideWorldImporters] 
FROM DISK = N'C:\WideWorldImporters-Full.bak' WITH FILE = 1, 
NOUNLOAD, replace, stats = 5 ;
GO

SELECT 
	name,
	compatibility_level
FROM sys.databases;
GO

ALTER DATABASE WideWorldImporters  
SET COMPATIBILITY_LEVEL = 140;  
GO 

SELECT 
	name,
	compatibility_level
FROM sys.databases;
GO

--updating statistics since we are using an old backup
USE [WideWorldImporters]
GO
UPDATE STATISTICS Sales.Orders;
GO