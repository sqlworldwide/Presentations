/*============================================================================
1_LinkedServer.sql
Written by Taiob M Ali
SqlWorldWide.com

This script will 
	Create linked server pointing to Azure SQL Database 
	Collect file size from Azure SQL Database and save result on-premise
	Collect file size locally in Azure SQL database

If you have large number of Azure SQL Database might not be practical
============================================================================*/
--Run this in your on-Premise Server
USE [master]
GO
--ALTER DATABASE [DbaDatabase] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE IF EXISTS DbaDatabase;
GO
CREATE DATABASE DbaDatabase;
GO

USE [DbaDatabase]
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

DROP TABLE IF EXISTS dbo.databaseSize;
GO
CREATE TABLE [dbo].[databaseSize](
	[collectedAT] [datetime] NOT NULL,
	[serverName] [nvarchar](128) NULL,
	[databaseName] [nvarchar](128) NULL,
	[fileName] [nvarchar](64) NULL,
	[fileId] [int] NOT NULL,
	[fileSizeMB] [int] NOT NULL,
	[spaceUsedMB] [numeric](12, 2) NULL,
	[freeSpaceMB] [numeric](12, 2) NULL,
	[percentFree] [numeric](12, 2) NULL,
	[physicalName] [nvarchar](260) NULL
) ON [PRIMARY];
GO

--Read the password from text file
DECLARE @password VARCHAR(MAX)
SELECT  @password = BulkColumn
FROM    OPENROWSET(BULK 'C:\Azure SQL Database - Where is my  SQL Agent\password.txt', SINGLE_BLOB) AS x   

--Drop and create linked server
IF EXISTS(SELECT * FROM sys.servers WHERE name = N'AzureDB_adventureworks')
EXEC master.dbo.sp_dropserver @server=N'AzureDB_adventureworks', @droplogins='droplogins';
EXEC master.dbo.sp_addlinkedserver
 @server = N'AzureDB_adventureworks', 
 @srvproduct=N'',
 @provider=N'SQLNCLI',
 @datasrc=N'ugdemotargetserver.database.windows.net',
 @catalog=N'adventureworks';

EXEC master.dbo.sp_addlinkedsrvlogin
 @rmtsrvname=N'AzureDB_adventureworks',
 @useself=N'False',
 @locallogin=NULL,
 @rmtuser=N'taiob',@rmtpassword=@password;
GO

--Collecting database file size from an Azure SQL Database and insert into local database
INSERT INTO dbaDatabase.dbo.databasesize 
SELECT *  FROM OPENQUERY 
(AzureDB_adventureworks, 
	'SELECT 
		GETDATE() AS collectedAT,
		@@SERVERNAME AS serverName, 
		DB_NAME() AS databaseName, 
		LEFT(a.name, 64) AS fileName,
		a.file_id AS fileId,
		a.size AS fileSizeMB,
		CONVERT(DECIMAL(12, 2), ROUND(FILEPROPERTY(a.name,''SpaceUsed'')/ 128.000, 2)) AS spaceUsedMB,
		CONVERT(DECIMAL(12, 2), ROUND(( a.size - FILEPROPERTY(a.name,''SpaceUsed''))/ 128.000, 2)) AS freeSpaceMB,
		CONVERT(DECIMAL(12, 2), (CONVERT(DECIMAL(12, 2), ROUND((a.size - FILEPROPERTY(a.name,''SpaceUsed''))/128.000, 2))*100)/ CONVERT(DECIMAL(12, 2), ROUND(a.size / 128.000, 2))) as percentFree,
		a.physical_name AS physicalName 
FROM adventureworks.sys.database_files a'
) ;

--Look at the result
SELECT [collectedAT]
      ,[serverName]
      ,[databaseName]
      ,[fileName]
      ,[fileId]
      ,[fileSizeMB]
      ,[spaceUsedMB]
      ,[freeSpaceMB]
      ,[percentFree]
      ,[physicalName]
  FROM [DbaDatabase].[dbo].[databasesize];

--If you want to save the result locally in Azure SQL Database
--Confirm collection table exist
--Connect to ugdemotargetserver.database.windows.net adventureworks database

DROP TABLE IF EXISTS dbo.databaseSize;
GO
CREATE TABLE [dbo].[databaseSize](
	[collectedAT] [datetime] NOT NULL,
	[serverName] [nvarchar](128) NULL,
	[databaseName] [nvarchar](128) NULL,
	[fileName] [nvarchar](64) NULL,
	[fileId] [int] NOT NULL,
	[fileSizeMB] [int] NOT NULL,
	[spaceUsedMB] [numeric](12, 2) NULL,
	[freeSpaceMB] [numeric](12, 2) NULL,
	[percentFree] [numeric](12, 2) NULL,
	[physicalName] [nvarchar](260) NULL
) ON [PRIMARY];
GO

--change connection back to local server
--Insert File Size 
INSERT INTO AzureDB_adventureworks.adventureworks.dbo.databasesize 
SELECT *  FROM OPENQUERY 
(AzureDB_adventureworks, 
	'
	SELECT 
		GETDATE() AS collectedAT,
		@@SERVERNAME AS serverName, 
		DB_NAME() AS databaseName, 
		LEFT(a.name, 64) AS fileName,
		a.file_id AS fileId,
		a.size AS fileSizeMB,
		CONVERT(DECIMAL(12, 2), ROUND(FILEPROPERTY(a.name,''SpaceUsed'')/ 128.000, 2)) AS spaceUsedMB,
		CONVERT(DECIMAL(12, 2), ROUND(( a.size - FILEPROPERTY(a.name,''SpaceUsed''))/ 128.000, 2)) AS freeSpaceMB,
		CONVERT(DECIMAL(12, 2), (CONVERT(DECIMAL(12, 2), ROUND((a.size - FILEPROPERTY(a.name,''SpaceUsed''))/128.000, 2))*100)/ CONVERT(DECIMAL(12, 2), ROUND(a.size / 128.000, 2))) as percentFree,
		a.physical_name AS physicalName 
 FROM sys.database_files a'
) ;

--Connect to ugdemotargetserver.database.windows.net adventureworks database
--See the result
SELECT [collectedAT]
      ,[serverName]
      ,[databaseName]
      ,[fileName]
      ,[fileId]
      ,[fileSizeMB]
      ,[spaceUsedMB]
      ,[freeSpaceMB]
      ,[percentFree]
      ,[physicalName]
  FROM [dbo].[databasesize];
