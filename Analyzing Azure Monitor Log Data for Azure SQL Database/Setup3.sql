/*
Setup3.sql
Rhode Island Data Platform User Group
August 09, 2023
Taiob Ali 
SqlWorldWide.com
*/

/*
Connect to server risqldemoservertaiob.database.windows.net
Change database context to nesqldemodatabase
With Azure SQL Database cannot use 'USE DBName' statement
Create an empty table
*/

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
Run this from query stress tool
EXEC p_StressTestTable_ins
EXEC p_StressTestTable_upd
https://github.com/ErikEJ/SqlQueryStress
Chose server name, database
Set number of threads = 20
Number of iterations = 100,000
Click GO
*/