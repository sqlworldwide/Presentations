
/*
Scirpt Name: 12_AutoGrowAllFiles.sql
DEMO:
	AUTOGROW_ALL_FILES

Script modified from:
https://www.mssqltips.com/sqlservertip/4937/expand-all-database-files-simultaneously-using-sql-server-2016-autogrowallfiles/
*/

USE [master]
GO
DROP DATABASE IF EXISTS AutoGrowthTest
GO
DROP DATABASE IF EXISTS AutoGrowthTest_WithAUTOGROW_All
GO
CREATE DATABASE [AutoGrowthTest]
ON  PRIMARY
( NAME = N'AutoGrowth_1', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\AutoGrowth_1.mdf' , SIZE = 8192KB , FILEGROWTH = 1024KB ),
( NAME = N'AutoGrowth_2', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\AutoGrowth_2.ndf' , SIZE = 8192KB , FILEGROWTH = 1024KB ),
( NAME = N'AutoGrowth_3', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\AutoGrowth_3.ndf' , SIZE = 8192KB , FILEGROWTH = 1024KB )
LOG ON
( NAME = N'AutoGrowth_1_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\AutoGrowth_1_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10% )
GO
 
 
CREATE DATABASE [AutoGrowthTest_WithAUTOGROW_All]
ON  PRIMARY
( NAME = N'AutoGrowthAGAll_1', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\AutoGrowthAGAll_1.mdf' , SIZE = 8192KB , FILEGROWTH = 1024KB ),
( NAME = N'AutoGrowthAGAll_2', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\AutoGrowthAGAll_2.ndf' , SIZE = 8192KB , FILEGROWTH = 1024KB ),
( NAME = N'AutoGrowthAGAll_3', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\AutoGrowthAGAll_3.ndf' , SIZE = 8192KB , FILEGROWTH = 1024KB )
LOG ON
( NAME = N'AutoGrowthAGAll_1_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\AutoGrowthAGAll_1_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10% )
GO
ALTER DATABASE [AutoGrowthTest_WithAUTOGROW_All]
MODIFY FILEGROUP [PRIMARY] AUTOGROW_ALL_FILES;
GO 

USE [AutoGrowthTest]
GO
SELECT
    DB_NAME() DatabaseName,
    DBF.name AS FileName,
    FileG.name as FileGroupName,
    FileG.is_autogrow_all_files AutoGrowthEnable
FROM sys.database_files AS DBF
JOIN sys.filegroups AS FileG
    ON DBF.data_space_id = FileG.data_space_id
GO
USE [AutoGrowthTest_WithAUTOGROW_All]
GO
SELECT
    DB_NAME() DatabaseName,
    DBF.name AS FileName,
    FileG.name as FileGroupName,
    FileG.is_autogrow_all_files AutoGrowthEnable
FROM sys.database_files AS DBF
JOIN sys.filegroups AS FileG
    ON DBF.data_space_id = FileG.data_space_id
GO
USE [AutoGrowthTest]
GO
CREATE TABLE Employees
( EmpID int IDENTITY(1,1),
  EmpName NVARCHAR(500)
)
GO
USE [AutoGrowthTest_WithAUTOGROW_All]
GO
CREATE TABLE Employees
( EmpID int IDENTITY(1,1),
  EmpName NVARCHAR(500)
) 
GO
SET NOCOUNT ON
INSERT INTO AutoGrowthTest.dbo.Employees VALUES ('Mohammad Yaseen')
GO 520000
INSERT INTO AutoGrowthTest_WithAUTOGROW_All.dbo.Employees VALUES ('Mohammad Yaseen')
GO 520000
SET NOCOUNT OFF

USE AutoGrowthTest
GO
EXEC Sp_helpfile
GO

USE AutoGrowthTest_WithAUTOGROW_All
GO
EXEC Sp_helpfile
GO

USE [master]
GO
DROP DATABASE IF EXISTS AutoGrowthTest
GO
DROP DATABASE IF EXISTS AutoGrowthTest_WithAUTOGROW_All
GO






