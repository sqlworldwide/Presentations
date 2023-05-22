/*
CheckpointThreeDemos.sql
Written by Taiob Ali
SqlWorldWide.com

This script will demonstrate 
1. Monitoring Checkpoint
2. Checkpoint behavior for simple recovery database
3. Automatic vs Indirect checkpoint IO behavior
*/

/*
Drop database if exists
Create an empty database
*/

USE master;
GO
DECLARE @SQL nvarchar(1000);

IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = N'eightkbonlinedemo2')
  BEGIN
    SET @SQL = 
      N'USE [master];
       ALTER DATABASE eightkbonlinedemo2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
       USE [master];
       DROP DATABASE eightkbonlinedemo2;';
    EXEC (@SQL);
  END;
ELSE
  BEGIN
    PRINT 'Database does not exist,creating a new one'
  END
GO

CREATE DATABASE eightkbonlinedemo2;
GO

/*
Change settings to reduce number of log records
*/
USE master;
GO
ALTER DATABASE eightkbonlinedemo2 SET RECOVERY SIMPLE;
GO
ALTER DATABASE eightkbonlinedemo2 SET AUTO_CREATE_STATISTICS OFF;
GO

/*
Create an empty table
*/
USE eightkbonlinedemo2;
GO
SET NOCOUNT ON;
GO
DROP TABLE IF EXISTS [dbo].[StressTestTable] ;
GO

CREATE TABLE [dbo].[StressTestTable] (
  [StressTestTableID] [BIGINT] IDENTITY(1,1) NOT NULL,
  [ColA] char(2000) NOT NULL,
  [ColB] char(2000) NOT NULL,
  [ColC] char(2000) NOT Null,
  [ColD] char(2000) NOT Null,
  CONSTRAINT [PK_StressTestTable] PRIMARY KEY CLUSTERED 
  (
	  [StressTestTableID] ASC
  )
);
GO

/*
Create store procedures
*/
USE eightkbonlinedemo2;
GO
DROP PROCEDURE IF EXISTS [dbo].[p_StressTestTable_ins];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER OFF;
GO

CREATE PROCEDURE [dbo].[p_StressTestTable_ins] 
AS
SET NOCOUNT ON 
DECLARE @l_cola char(1) , @l_colb char(1) ,@l_colc char(1) ,@l_cold char(1) , @p_seed int
SELECT  @p_seed=ABS(CHECKSUM(NewId())) % 127 
SELECT @l_cola =char(@p_seed) , @l_colb =char(@p_seed) ,@l_colc =char(@p_seed) ,@l_cold =char(@p_seed) 

INSERT INTO [dbo].[StressTestTable]
  (
		[ColA],
    [ColB],
    [ColC],
    [ColD]
	)
  VALUES
	(
	  REPLICATE(@l_cola,2000),
    REPLICATE(@l_colb,2000),
    REPLICATE(@l_colc,2000),
    REPLICATE(@l_cold,2000)
	)
SET NOCOUNT OFF
RETURN 0;
GO


DROP PROCEDURE IF EXISTS [dbo].[p_StressTestTable_upd];
GO

CREATE PROCEDURE [dbo].[p_StressTestTable_upd] 
AS
SET NOCOUNT ON 

DECLARE @l_cola char(1) , @l_colb char(1) ,@l_colc char(1) ,@l_cold char(1) , @p_seed int, @Upper int, @Lower int,@PK_ID bigint 
SELECT  @p_seed=ABS(CHECKSUM(NewId())) % 127 -- check asciitable.com 
SELECT @l_cola =char(@p_seed) , @l_colb =char(@p_seed) ,@l_colc =char(@p_seed) ,@l_cold =char(@p_seed) 
SELECT @Lower = (SELECT TOP 1 StressTestTableId FROM [StressTestTable] WITH(NOLOCK) ORDER BY StressTestTableId ASC)
SELECT @Upper = (SELECT TOP 1 StressTestTableId FROM [StressTestTable] WITH(NOLOCK) ORDER BY StressTestTableId DESC)

---http://kaniks.blogspot.com/search/label/generate%20random%20number%20from%20t-sql
SELECT @PK_ID = Round(((@Upper - @Lower -1) * Rand() + @Lower), 0)

UPDATE [dbo].[StressTestTable]
  SET [ColA] = REPLICATE(@l_cola,2000),
      [ColB] = REPLICATE(@l_cola,2000),
      [ColC] = REPLICATE(@l_cola,2000),
      [ColD] = REPLICATE(@l_cola,2000)
WHERE StressTestTableId = @PK_ID

SET NOCOUNT OFF
RETURN 0;   
GO

/*
Open Performance Monitor and add these counters for your test databse
-SQLServer:Databases - 
	Log File(s) Used Size (KB)
	Percent Log Used
-LogicalDisk
	Disk Write Bytes/sec (for the drive where testdatabse log file reside)

You can add two more if you are interested
-Log File(s) Size (KB)
-checkpoint pages/sec (not database specific)

Run this from query stress tool
EXEC eightkbonlinedemo2..p_StressTestTable_ins
EXEC eightkbonlinedemo2..p_StressTestTable_upd
https://github.com/ErikEJ/SqlQueryStress
Chose server name, database
Set number of threads = 20
Number of iterations = 100,000
Click GO
*/

/*
Demo: Monitoring checkpoint
*/
DBCC TRACEON (3605, -1);
DBCC TRACEON (3502, -1);
GO

/*
You only see Checkpoint start and end but not details
*/
EXEC sp_cycle_errorlog;  
EXEC xp_ReadErrorLog;
GO

/*
Turn on TF 3504
*/
DBCC TRACEON (3504, -1);
GO
EXEC sp_cycle_errorlog;  
EXEC xp_ReadErrorLog;
GO

/*
Remove trace flags
*/
DBCC TRACEOFF(3605, -1);
DBCC TRACEOFF (3502, -1);
DBCC TRACEOFF(3504, -1);
GO

/*
Demo:Checkpoint behavior for simple recovery database
looking at the "Log File(s) Used Size (KB)" 
"Disk Write Bytes/sec" counters 
Percent Log Used
*/

/*
Demo:Automatic vs Indirect checkpoint IO behavior
Change TARGET_RECOVERY_TIME to 15 seconds and see the change in write pattern
Change TARGET_RECOVERY_TIME to 120 seconds and see the change in write pattern
*/
ALTER DATABASE eightkbonlinedemo2 SET TARGET_RECOVERY_TIME = 15 SECONDS;
GO
ALTER DATABASE eightkbonlinedemo2 SET TARGET_RECOVERY_TIME = 120 SECONDS;
GO

/*
Clean up
Stop the Query Stress tool
Drop the database
*/
USE master;
GO
DROP DATABASE IF EXISTS eightkbonlinedemo2;
GO