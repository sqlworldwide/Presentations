/*============================================================================
File: 01_Setup.sql
Author: Taiob Ali
Email: taiob@sqlworlwide.com
Bluesky: https://bsky.app/profile/sqlworldwide.bsky.social
Blog: https://sqlworldwide.com/
LinkedIn: https://www.linkedin.com/in/sqlworldwide/

Last Modified: October 08, 2025

Tested On:
	- SQL Server 2022 CU21
	- SSMS 21.5.14

Preparation:
- Set up the 10 GB Stack Overflow database following instructions from:
		https://www.brentozar.com/archive/2015/10/how-to-download-the-stack-overflow-database-via-bittorrent/
- Restart SQL Server to generate new log files.
- Run this script before the presentation to save time.

Approximate runtime on my machine: 3 minutes 20 seconds.
============================================================================*/

/*
Drop database if exists
*/

USE [master];
GO
DROP DATABASE IF EXISTS SqlDetective; 
GO

/*
Create database
*/

USE master;
GO
CREATE DATABASE [SqlDetective]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'SqlDetective', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\SqlDetective.mdf' , SIZE = 1024KB , FILEGROWTH = 2048KB )
 LOG ON 
( NAME = N'SqlDetective_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\SqlDetective_log.ldf' , SIZE = 1024KB , FILEGROWTH = 2048KB )
 WITH LEDGER = OFF
GO

USE [SqlDetective]
GO
ALTER AUTHORIZATION ON DATABASE::[SqlDetective] TO [sa]
GO

/*
Create table, stored procedure and insert data
*/

USE [SqlDetective]
GO
DROP TABLE IF EXISTS [dbo].[StressTestTableA]
GO
CREATE TABLE [dbo].[StressTestTableA] (
 StressTestTableID [BIGINT] IDENTITY(1,1) NOT NULL,
 [ColA] char(2000) NOT NULL,
 [ColB] char(2000) NOT NULL,
 [ColC] char(2000) NOT Null,
 [ColD] char(2000) NOT Null,
 CONSTRAINT [PK_StressTestTable] PRIMARY KEY CLUSTERED 
	(
		[StressTestTableID] ASC
	)
)
GO

DROP TABLE IF EXISTS [dbo].[StressTestTableB]
GO
CREATE TABLE [dbo].[StressTestTableB] (
 StressTestTableID [BIGINT] IDENTITY(1,1) NOT NULL,
 [ColA] char(2000) NOT NULL,
 [ColB] char(2000) NOT NULL,
 [ColC] char(2000) NOT Null,
 [ColD] char(2000) NOT Null,
 CONSTRAINT [PK_StressTestTableB] PRIMARY KEY CLUSTERED 
	(
		[StressTestTableID] ASC
	)
)
GO

DROP TABLE IF EXISTS [dbo].[StressTestTableC]
GO
CREATE TABLE [dbo].[StressTestTableC] (
 StressTestTableID [BIGINT] IDENTITY(1,1) NOT NULL,
 [ColA] char(2000) NOT NULL,
 [ColB] char(2000) NOT NULL,
 [ColC] char(2000) NOT Null,
 [ColD] char(2000) NOT Null,
 CONSTRAINT [PK_StressTestTableC] PRIMARY KEY CLUSTERED 
	(
		[StressTestTableID] ASC
	)
)
GO

DROP PROCEDURE IF EXISTS [dbo].[StressTestTable_insA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[StressTestTable_insA] 
AS
BEGIN
	Set NOCOUNT ON 
	DECLARE @l_cola char(1) , @l_colb char(1) ,@l_colc char(1) ,@l_cold char(1) , @p_seed int
	SELECT  @p_seed=ABS(CHECKSUM(NewId())) % 127 
	SELECT @l_cola =char(@p_seed) , @l_colb =char(@p_seed) ,@l_colc =char(@p_seed) ,@l_cold =char(@p_seed) 
	
	INSERT INTO [dbo].[StressTestTableA]
	           ([ColA]
	           ,[ColB]
	           ,[ColC]
	           ,[ColD])
	     VALUES
	           (REPLICATE(@l_cola,2000)
	           ,REPLICATE(@l_colb,2000)
	           ,REPLICATE(@l_colc,2000)
	           ,REPLICATE(@l_cold,2000))
	Set NOCOUNT OFF
	RETURN 0
END    
GO

DROP PROCEDURE IF EXISTS [dbo].[StressTestTable_insB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[StressTestTable_insB] 
AS
BEGIN
	Set NOCOUNT ON 
	BEGIN
	DECLARE @l_cola char(1) , @l_colb char(1) ,@l_colc char(1) ,@l_cold char(1) , @p_seed int
	SELECT  @p_seed=ABS(CHECKSUM(NewId())) % 127 
	SELECT @l_cola =char(@p_seed) , @l_colb =char(@p_seed) ,@l_colc =char(@p_seed) ,@l_cold =char(@p_seed) 
	
	INSERT INTO [dbo].[StressTestTableB]
	           ([ColA]
	           ,[ColB]
	           ,[ColC]
	           ,[ColD])
	     VALUES
	           (REPLICATE(@l_cola,2000)
	           ,REPLICATE(@l_colb,2000)
	           ,REPLICATE(@l_colc,2000)
	           ,REPLICATE(@l_cold,2000))
	Set NOCOUNT OFF
	RETURN 0
	END
END
GO

DROP PROCEDURE IF EXISTS [dbo].[StressTestTable_insC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[StressTestTable_insC] 
AS
BEGIN
	Set NOCOUNT ON 
	
	DECLARE @l_cola char(1) , @l_colb char(1) ,@l_colc char(1) ,@l_cold char(1) , @p_seed int
	SELECT  @p_seed=ABS(CHECKSUM(NewId())) % 127 
	SELECT @l_cola =char(@p_seed) , @l_colb =char(@p_seed) ,@l_colc =char(@p_seed) ,@l_cold =char(@p_seed) 
	
	INSERT INTO [dbo].[StressTestTableC]
	           ([ColA]
	           ,[ColB]
	           ,[ColC]
	           ,[ColD])
	     VALUES
	           (REPLICATE(@l_cola,2000)
	           ,REPLICATE(@l_colb,2000)
	           ,REPLICATE(@l_colc,2000)
	           ,REPLICATE(@l_cold,2000))
	Set NOCOUNT OFF
	RETURN 0
END    
GO

DROP PROCEDURE IF EXISTS [dbo].[StressTestTable_updA]
GO

CREATE PROCEDURE [dbo].[StressTestTable_updA] 
AS
BEGIN
	Set NOCOUNT ON 
	
	DECLARE @l_cola char(1) , @l_colb char(1) ,@l_colc char(1) ,@l_cold char(1) , @p_seed int, @Upper int, @Lower int,@PK_ID bigint 
	SELECT  @p_seed=ABS(CHECKSUM(NewId())) % 127 -- check asciitable.com 
	SELECT @l_cola =char(@p_seed) , @l_colb =char(@p_seed) ,@l_colc =char(@p_seed) ,@l_cold =char(@p_seed) 
	SELECT @Lower = (SELECT TOP 1 StressTestTableId FROM [StressTestTableA] WITH(NOLOCK) ORDER BY StressTestTableId ASC)
	SELECT @Upper = (SELECT TOP 1 StressTestTableId FROM [StressTestTableA] WITH(NOLOCK) ORDER BY StressTestTableId DESC)
	
	---http://kaniks.blogspot.com/search/label/generate%20random%20number%20from%20t-sql
	SELECT @PK_ID = Round(((@Upper - @Lower -1) * Rand() + @Lower), 0)
	
	UPDATE [dbo].[StressTestTableA]
	   SET [ColA] = REPLICATE(@l_cola,2000)
	      ,[ColB] = REPLICATE(@l_cola,2000)
	      ,[ColC] = REPLICATE(@l_cola,2000)
	      ,[ColD] = REPLICATE(@l_cola,2000)
	WHERE StressTestTableId = @PK_ID
	
	SET NOCOUNT OFF
	RETURN 0
END    
GO

DROP PROCEDURE IF EXISTS [dbo].[StressTestTable_updB]
GO

CREATE PROCEDURE [dbo].[StressTestTable_updB] 
AS
BEGIN
	Set NOCOUNT ON 
	
	DECLARE @l_cola char(1) , @l_colb char(1) ,@l_colc char(1) ,@l_cold char(1) , @p_seed int, @Upper int, @Lower int,@PK_ID bigint 
	SELECT  @p_seed=ABS(CHECKSUM(NewId())) % 127 -- check asciitable.com 
	SELECT @l_cola =char(@p_seed) , @l_colb =char(@p_seed) ,@l_colc =char(@p_seed) ,@l_cold =char(@p_seed) 
	SELECT @Lower = (SELECT TOP 1 StressTestTableId FROM [StressTestTableB] WITH(NOLOCK) ORDER BY StressTestTableId ASC)
	SELECT @Upper = (SELECT TOP 1 StressTestTableId FROM [StressTestTableB] WITH(NOLOCK) ORDER BY StressTestTableId DESC)
	
	---http://kaniks.blogspot.com/search/label/generate%20random%20number%20from%20t-sql
	SELECT @PK_ID = Round(((@Upper - @Lower -1) * Rand() + @Lower), 0)
	
	UPDATE [dbo].[StressTestTableB]
	   SET [ColA] = REPLICATE(@l_cola,2000)
	      ,[ColB] = REPLICATE(@l_cola,2000)
	      ,[ColC] = REPLICATE(@l_cola,2000)
	      ,[ColD] = REPLICATE(@l_cola,2000)
	WHERE StressTestTableId = @PK_ID
	
	SET NOCOUNT OFF
	RETURN 0
END    
GO

DROP PROCEDURE IF EXISTS [dbo].[StressTestTable_updC]
GO

CREATE PROCEDURE [dbo].[StressTestTable_updC] 
AS
BEGIN
	Set NOCOUNT ON 
	
	DECLARE @l_cola char(1) , @l_colb char(1) ,@l_colc char(1) ,@l_cold char(1) , @p_seed int, @Upper int, @Lower int,@PK_ID bigint 
	SELECT  @p_seed=ABS(CHECKSUM(NewId())) % 127 -- check asciitable.com 
	SELECT @l_cola =char(@p_seed) , @l_colb =char(@p_seed) ,@l_colc =char(@p_seed) ,@l_cold =char(@p_seed) 
	SELECT @Lower = (SELECT TOP (1) StressTestTableId FROM [dbo.StressTestTableC] WITH(NOLOCK) ORDER BY StressTestTableId ASC)
	SELECT @Upper = (SELECT TOP (1) StressTestTableId FROM [dbo.StressTestTableC] WITH(NOLOCK) ORDER BY StressTestTableId DESC)
	
	---http://kaniks.blogspot.com/search/label/generate%20random%20number%20from%20t-sql
	SELECT @PK_ID = Round(((@Upper - @Lower -1) * Rand() + @Lower), 0)
	
	UPDATE [dbo].[StressTestTableC]
	   SET [ColA] = REPLICATE(@l_cola,2000)
	      ,[ColB] = REPLICATE(@l_cola,2000)
	      ,[ColC] = REPLICATE(@l_cola,2000)
	      ,[ColD] = REPLICATE(@l_cola,2000)
	WHERE StressTestTableId = @PK_ID
	
	SET NOCOUNT OFF
	RETURN 0
END    
GO

DROP PROCEDURE IF EXISTS [dbo].[StressTestTable_delA] 
GO

CREATE PROCEDURE [dbo].[StressTestTable_delA] 
AS
BEGIN
	SET NOCOUNT ON 
	---http://kaniks.blogspot.com/search/label/generate%20random%20number%20from%20t-sql
	DECLARE @Upper int, @Lower int,@PK_ID bigint 
	SELECT @Lower = (SELECT TOP 1 StressTestTableId FROM [StressTestTableA] WITH(NOLOCK) ORDER BY StressTestTableId ASC)
	SELECT @Upper = (SELECT TOP 1 StressTestTableId FROM [StressTestTableA] WITH(NOLOCK) ORDER BY StressTestTableId DESC)
	SELECT @PK_ID = Round(((@Upper - @Lower -1) * Rand() + @Lower), 0)
	
	DELETE [dbo].[StressTestTableA]
	    WHERE StressTestTableId = @PK_ID
	SET NOCOUNT OFF
	RETURN 0  
	
	DROP PROCEDURE IF EXISTS [dbo].[StressTestTable_delB]
END 
GO

CREATE PROCEDURE [dbo].[StressTestTable_delB] 
AS
BEGIN
	SET NOCOUNT ON 
	---http://kaniks.blogspot.com/search/label/generate%20random%20number%20from%20t-sql
	DECLARE @Upper int, @Lower int,@PK_ID bigint 
	SELECT @Lower = (SELECT TOP 1 StressTestTableId FROM [dbo.StressTestTableB] WITH(NOLOCK) ORDER BY StressTestTableId ASC)
	SELECT @Upper = (SELECT TOP 1 StressTestTableId FROM [dbo.StressTestTableB] WITH(NOLOCK) ORDER BY StressTestTableId DESC)
	SELECT @PK_ID = Round(((@Upper - @Lower -1) * Rand() + @Lower), 0)
	
	DELETE [dbo].[StressTestTableB]
	    WHERE StressTestTableId = @PK_ID
	SET NOCOUNT OFF
	RETURN 0  
	
	
	DROP PROCEDURE IF EXISTS [dbo].[StressTestTable_delC]
END 
GO

CREATE PROCEDURE [dbo].[StressTestTable_delC] 
AS
BEGIN
	SET NOCOUNT ON 
	---http://kaniks.blogspot.com/search/label/generate%20random%20number%20from%20t-sql
	DECLARE @Upper int, @Lower int,@PK_ID bigint 
	SELECT @Lower = (SELECT TOP 1 StressTestTableId FROM [dbo.StressTestTableC] WITH(NOLOCK) ORDER BY StressTestTableId ASC)
	SELECT @Upper = (SELECT TOP 1 StressTestTableId FROM [dbo.StressTestTableC] WITH(NOLOCK) ORDER BY StressTestTableId DESC)
	SELECT @PK_ID = Round(((@Upper - @Lower -1) * Rand() + @Lower), 0)
	
	DELETE [dbo].[StressTestTableC]
	    WHERE StressTestTableId = @PK_ID
	SET NOCOUNT OFF
	RETURN 0;
END
GO

USE [SqlDetective]
GO
EXEC [dbo].[StressTestTable_insA]
GO 30000
EXEC [dbo].[StressTestTable_insB]
GO 30000
EXEC [dbo].[StressTestTable_insC]
GO 30000

/*
Forcing a sort warning
*/

DROP TABLE IF EXISTS SortTable;
GO
SELECT 
  TOP (100000)
	IDENTITY(INT, 1,1) AS OrderID,
	ABS(CHECKSUM(NEWID()) / 10000000) AS CustomerID,
	CONVERT(DATETIME, GETDATE() - (CHECKSUM(NEWID()) / 1000000)) AS OrderDate,
	ISNULL(ABS(CONVERT(NUMERIC(18,2), (CHECKSUM(NEWID()) / 1000000.5))),0) AS Value,
	CONVERT(CHAR(500), NEWID()) AS ColChar
INTO dbo.SortTable
FROM sysobjects A
CROSS JOIN sysobjects B CROSS JOIN sysobjects C CROSS JOIN sysobjects D;
GO

CREATE CLUSTERED INDEX ix1 ON dbo.SortTable (OrderID)
GO
DECLARE @v1 Char(500), @v2 Int
SELECT 
  @v1 = ColChar, 
	@v2 = OrderID
FROM dbo.SortTable
ORDER BY ColChar
OPTION  (MAXDOP 1, RECOMPILE)

/*
Creating a login
*/

USE [master]
GO
IF NOT EXISTS 
    (SELECT name  
     FROM master.sys.server_principals
     WHERE name = 'nesqldemo')
BEGIN
    CREATE LOGIN [nesqldemo] WITH PASSWORD=N'1s7MQ$y23d!Eu!Iu' MUST_CHANGE, DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON;
END
GO

/*
Creating Memory event
*/

USE StackOverflow2010
GO
SELECT * FROM dbo.Posts
select * FROM dbo.Comments