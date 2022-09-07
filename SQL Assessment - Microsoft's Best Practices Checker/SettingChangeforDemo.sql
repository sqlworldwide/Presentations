USE [master];
GO
-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  
-- Revert
-- To disable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 0;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO 


--Change one of the tempdb file size
USE [master];
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'temp8', SIZE = 10 );
GO
--Revert
USE [tempdb];
GO
DBCC SHRINKFILE (N'temp8' , 8);
GO

--Create a login with same password
USE [master];
GO
IF EXISTS 
  (SELECT 
    name  
   FROM master.sys.server_principals
   WHERE name = 'nesqlugdemo')
BEGIN
DROP LOGIN [nesqlugdemo];
END
CREATE LOGIN [nesqlugdemo] WITH PASSWORD=N'nesqlugdemo', DEFAULT_DATABASE=[master];
GO

/*
  Create sample table and indexes
  Copied form https://www.mssqltips.com/sqlservertip/3604/identify-sql-server-indexes-with-duplicate-columns/
*/
USE [SqlAssessmentDemo];
GO
DROP TABLE  IF EXISTS testtable1;
GO
CREATE TABLE testtable1 
(
  [col1] [int] NOT NULL primary key  clustered,
  [col2] [int]  NULL,
  [col3] [int]  NULL,
  [col4] [varchar](50) NULL
); 

CREATE INDEX idx_testtable1_col2col3 on testtable1 (col2  asc, col3 asc);
CREATE INDEX idx_testtable1_col2col4 on testtable1 (col2  asc, col4 asc);
CREATE INDEX idx_testtable1_col3 on testtable1 (col3  asc);
CREATE INDEX idx_testtable1_col3col4 on testtable1 (col3  asc, col4 asc);
GO

DROP TABLE  IF EXISTS testtable2  ;
GO
CREATE TABLE testtable2 
(
  [col1] [int] NOT NULL primary key  clustered,
  [col2] [int]  NULL,
  [col3] [int]  NULL,
  [col4] [varchar](50) NULL
); 
 
CREATE INDEX idx_testtable2_col3col4 on testtable2 (col3  asc, col4 asc);
CREATE INDEX idx_testtable2_col3col4_1 on testtable2 (col3  asc, col4 asc);

--Adjust Max Memory
USE [master];
GO
EXEC sys.sp_configure N'max server memory (MB)', N'32000';
GO
RECONFIGURE WITH OVERRIDE;
GO
--Revert
EXEC sys.sp_configure N'max server memory (MB)', N'28000';
GO
RECONFIGURE WITH OVERRIDE;
GO

--Change autogrowth to percent
USE [master]
GO
ALTER DATABASE [SqlAssessmentDemo] MODIFY FILE ( NAME = N'SqlAssessmentDemo', FILEGROWTH = 10%)
GO
--Revert
USE [master]
GO
ALTER DATABASE [SqlAssessmentDemo] MODIFY FILE ( NAME = N'SqlAssessmentDemo', FILEGROWTH = 65536KB )
GO


--Turn on Trace Flag 634
USE [master];
GO
DBCC TRACEON(634,-1);
GO
--Revert
--Turn off Trace Flag 634
DBCC TRACEOFF(634,-1);
GO