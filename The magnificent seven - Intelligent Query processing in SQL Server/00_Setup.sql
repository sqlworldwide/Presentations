/*
Scirpt Name: 00_Setup.sql
Setting up database for all the demo
Download WideWorldImportersDW-Full.bak from https://aka.ms/wwidwbak
*/

--Changing MAXDOP as this query can advantage of parallel execution
USE [master]
GO
EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
EXEC sp_configure 'max degree of parallelism', 0;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  

USE [master]
GO
DECLARE @dbname nvarchar(128)
SET @dbname = N'WideWorldImportersDW'

IF (EXISTS (SELECT name 
FROM master.dbo.sysdatabases 
WHERE ('[' + name + ']' = @dbname 
OR name = @dbname)))
BEGIN
ALTER DATABASE [AdventureWorks] SET RESTRICTED_USER;
END
GO
USE [master]
GO
DECLARE @dbname nvarchar(128)
SET @dbname = N'WideWorldImportersDW'

IF (EXISTS (SELECT name 
FROM master.dbo.sysdatabases 
WHERE ('[' + name + ']' = @dbname 
OR name = @dbname)))
BEGIN
ALTER DATABASE [WideWorldImportersDW] SET RESTRICTED_USER;
END
GO
RESTORE DATABASE [WideWorldImportersDW] FROM  
DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\Backup\WideWorldImportersDW-Full.bak'
WITH  FILE = 1, 
MOVE N'WWI_Primary' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\Data\WideWorldImportersDW.mdf',
MOVE N'WWI_UserData' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\Data\WideWorldImportersDW_UserData.ndf',
MOVE N'WWI_Log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\Log\WideWorldImportersDW.ldf',
MOVE N'WWIDW_InMemory_Data_1' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\data\WideWorldImportersDW_InMemory_Data_1',
NOUNLOAD,  REPLACE, STATS = 5;
GO

USE [WideWorldImportersDW]
GO
ALTER AUTHORIZATION ON DATABASE::[WideWorldImportersDW] TO [sa]
GO
USE [master]
GO
ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150
GO

-- ***************************************************** --
-- Purpose of this script: make WideWorldImportersDW
-- bigger - so you can see more impactful 
-- Intelligent QP demonstrations (aka.ms/iqp)
--
-- Script last updated 05/03/2019
--
-- Database backup source: aka.ms/wwibak
-- 
-- Initial database file to restore before beginning this script: 
--		WideWorldImportersDW-Full.bak
-- ***************************************************** --

USE WideWorldImportersDW;
GO

/*
	Assumes a fresh restore of WideWorldImportersDW
*/

IF OBJECT_ID('Fact.OrderHistory') IS NULL 
BEGIN
    SELECT [Order Key], [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key]
    INTO Fact.OrderHistory
    FROM Fact.[Order];
END;

ALTER TABLE Fact.OrderHistory
ADD CONSTRAINT PK_Fact_OrderHistory PRIMARY KEY NONCLUSTERED([Order Key] ASC, [Order Date Key] ASC) WITH (DATA_COMPRESSION = PAGE);
GO

CREATE INDEX IX_Stock_Item_Key
ON Fact.OrderHistory([Stock Item Key])
INCLUDE(Quantity)
WITH (DATA_COMPRESSION = PAGE);
GO

CREATE INDEX IX_OrderHistory_Quantity
ON Fact.OrderHistory([Quantity])
INCLUDE([Order Key])
WITH (DATA_COMPRESSION = PAGE);
GO

CREATE INDEX IX_OrderHistory_CustomerKey
ON Fact.OrderHistory([Customer Key])
INCLUDE ([Total Including Tax])
WITH (DATA_COMPRESSION = PAGE);
GO

/*
	Reality check... Starting count should be 231,412
*/
SELECT COUNT(*) FROM Fact.OrderHistory;
GO

/*
	Make this table bigger (exec as desired)
	Notice the "GO 4"
*/
INSERT Fact.OrderHistory([City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key]
FROM Fact.OrderHistory;
GO 4

/*
	Should be 3,702,592
*/
SELECT COUNT(*) FROM Fact.OrderHistory;
GO

IF OBJECT_ID('Fact.OrderHistoryExtended') IS NULL 
BEGIN
    SELECT [Order Key], [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key]
    INTO Fact.OrderHistoryExtended
    FROM Fact.[OrderHistory];
END;

ALTER TABLE Fact.OrderHistoryExtended
ADD CONSTRAINT PK_Fact_OrderHistoryExtended PRIMARY KEY NONCLUSTERED([Order Key] ASC, [Order Date Key] ASC)
WITH(DATA_COMPRESSION=PAGE);
GO

CREATE INDEX IX_Stock_Item_Key
ON Fact.OrderHistoryExtended([Stock Item Key])
INCLUDE(Quantity);
GO

/*
	Should be 3,702,592
*/
SELECT COUNT(*) FROM Fact.OrderHistoryExtended;
GO

/*
	Make this table bigger (exec as desired)
	Notice the "GO 3"
*/
INSERT Fact.OrderHistoryExtended([City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key]
FROM Fact.OrderHistoryExtended;
GO 3

/*
	Should be 29,620,736
*/
SELECT COUNT(*) FROM Fact.OrderHistoryExtended;
GO

UPDATE Fact.OrderHistoryExtended
SET [WWI Order ID] = [Order Key];
GO

-- Repeat the following until log shrinks. These demos don't require much log space
CHECKPOINT
GO
USE WideWorldImportersDW;
GO
DBCC SHRINKFILE (N'WWI_Log' , 0, TRUNCATEONLY)
GO
SELECT * FROM sys.dm_db_log_space_usage;
GO

/*
Set up this section if you want to test adaptive join when batchmode in rowstore kicks in.
Test code is at the bottom of 01_AdaptiveJoin_BatchMode.sql
Restore Adventureworks database
https://docs.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver15&tabs=ssms
Enlarge the restored adventureworks database
https://www.sqlskills.com/blogs/jonathan/enlarging-the-adventureworks-sample-databases/
*/
USE [master]
GO
DECLARE @dbname nvarchar(128)
SET @dbname = N'AdventureWorks'

IF (EXISTS (SELECT name 
FROM master.dbo.sysdatabases 
WHERE ('[' + name + ']' = @dbname 
OR name = @dbname)))
BEGIN
ALTER DATABASE [AdventureWorks] SET RESTRICTED_USER;
END
GO
USE [master]
GO
DECLARE @dbname nvarchar(128)
SET @dbname = N'AdventureWorks'

IF (EXISTS (SELECT name 
FROM master.dbo.sysdatabases 
WHERE ('[' + name + ']' = @dbname 
OR name = @dbname)))
BEGIN
ALTER DATABASE [AdventureWorks] SET RESTRICTED_USER;
END
GO
RESTORE DATABASE [AdventureWorks] FROM  
DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\Backup\AdventureWorks2017.bak' 
WITH  FILE = 1,  
MOVE N'AdventureWorks2017' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\AdventureWorks2017.mdf', 
MOVE N'AdventureWorks2017_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\AdventureWorks2017_log.ldf', 
NOUNLOAD,  REPLACE, STATS = 5;
GO
USE [AdventureWorks]
GO
ALTER AUTHORIZATION ON DATABASE::[AdventureWorks] TO [sa]
GO
USE [master]
GO
ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 150
GO

--Run code from here to make the database bigger
--https://www.sqlskills.com/blogs/jonathan/enlarging-the-adventureworks-sample-databases/

--Revert MAXDOP Setting
EXEC sp_configure 'max degree of parallelism', 2;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
