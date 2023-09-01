/*
	Scirpt Name: 00_Setup.sql
	Setting up database for all the demo
	Modified by Taiob Ali
	August 15, 2023
*/

/*
	Changing MAXDOP as this query can advantage of parallel execution
	Download WideWorldImportersDW-Full.bak from https://aka.ms/wwidwbak
	Save here: C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\
*/

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
ALTER DATABASE [WideWorldImportersDW] SET RESTRICTED_USER;
END
GO
RESTORE DATABASE [WideWorldImportersDW] FROM  
DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\WideWorldImportersDW-Full.bak'
WITH  FILE = 1, 
MOVE N'WWI_Primary' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\WideWorldImportersDW.mdf',
MOVE N'WWI_UserData' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\WideWorldImportersDW_UserData.ndf',
MOVE N'WWI_Log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\WideWorldImportersDW.ldf',
MOVE N'WWIDW_InMemory_Data_1' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\WideWorldImportersDW_InMemory_Data_1',
NOUNLOAD,  REPLACE, STATS = 5;
GO

USE [WideWorldImportersDW]
GO
ALTER AUTHORIZATION ON DATABASE::[WideWorldImportersDW] TO [sa]
GO
USE [master]
GO
ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 160
GO

/*
Purpose of this script: make WideWorldImportersDW bigger so you can see more impactful 
Intelligent QP demonstrations (aka.ms/iqp)

Script last updated 05/03/2019

Database backup source: aka.ms/wwibak
 
Initial database file to restore before beginning this script: 
WideWorldImportersDW-Full.bak
*/

USE WideWorldImportersDW;
GO

/*
	Assumes a fresh restore of WideWorldImportersDW
*/
IF OBJECT_ID('Fact.OrderHistory') IS NULL 
BEGIN
    SELECT 
			[Order Key], 
			[City Key], 
			[Customer Key], 
			[Stock Item Key], 
			[Order Date Key], 
			[Picked Date Key], 
			[Salesperson Key], 
			[Picker Key], 
			[WWI Order ID], 
			[WWI Backorder ID], 
			Description, 
			Package, 
			Quantity, 
			[Unit Price], 
			[Tax Rate], 
			[Total Excluding Tax], 
			[Tax Amount], 
			[Total Including Tax], 
			[Lineage Key]
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
SELECT 
	COUNT(*) 
FROM Fact.OrderHistory;
GO

/*
	Make this table bigger (exec as desired)
	Notice the "GO 4"
*/
INSERT Fact.OrderHistory
	([City Key], 
	[Customer Key], [Stock Item Key], 
	[Order Date Key], 
	[Picked Date Key], 
	[Salesperson Key], 
	[Picker Key], 
	[WWI Order ID], 
	[WWI Backorder ID], 
	Description, 
	Package, 
	Quantity, 
	[Unit Price], 
	[Tax Rate], 
	[Total Excluding Tax], 
	[Tax Amount], 
	[Total Including Tax], 
	[Lineage Key])
SELECT 
	[City Key], 
	[Customer Key], 
	[Stock Item Key], 
	[Order Date Key], 
	[Picked Date Key], 
	[Salesperson Key], 
	[Picker Key], 
	[WWI Order ID], 
	[WWI Backorder ID], 
	Description, 
	Package, 
	Quantity, [Unit Price], 
	[Tax Rate], 
	[Total Excluding Tax], 
	[Tax Amount], 
	[Total Including Tax], 
	[Lineage Key]
FROM Fact.OrderHistory;
GO 4

/*
	Should be 3,702,592
*/
SELECT 
	COUNT(*) 
FROM Fact.OrderHistory;
GO

IF OBJECT_ID('Fact.OrderHistoryExtended') IS NULL 
BEGIN
    SELECT 
			[Order Key], 
			[City Key], 
			[Customer Key], 
			[Stock Item Key], 
			[Order Date Key], 
			[Picked Date Key], 
			[Salesperson Key], 
			[Picker Key], 
			[WWI Order ID], 
			[WWI Backorder ID], 
			Description, 
			Package, 
			Quantity, 
			[Unit Price], 
			[Tax Rate], 
			[Total Excluding Tax], 
			[Tax Amount], 
			[Total Including Tax], 
			[Lineage Key]
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

SELECT 
	COUNT(*) 
FROM Fact.OrderHistoryExtended;
GO

/*
	Make this table bigger (exec as desired)
	Notice the "GO 3"
*/
INSERT Fact.OrderHistoryExtended
	([City Key], 
	[Customer Key], 
	[Stock Item Key], 
	[Order Date Key], 
	[Picked Date Key], 
	[Salesperson Key], 
	[Picker Key], 
	[WWI Order ID], 
	[WWI Backorder ID], 
	Description, 
	Package, 
	Quantity, 
	[Unit Price], 
	[Tax Rate], 
	[Total Excluding Tax], 
	[Tax Amount], 
	[Total Including Tax], [Lineage Key])
SELECT 
	[City Key], 
	[Customer Key], 
	[Stock Item Key], 
	[Order Date Key], 
	[Picked Date Key], 
	[Salesperson Key], 
	[Picker Key], 
	[WWI Order ID], 
	[WWI Backorder ID], 
	Description, 
	Package, 
	Quantity, 
	[Unit Price], 
	[Tax Rate], 
	[Total Excluding Tax], 
	[Tax Amount], 
	[Total Including Tax], 
	[Lineage Key]
FROM Fact.OrderHistoryExtended;
GO 3

/*
	Should be 29,620,736
*/

SELECT 
	COUNT(*) 
FROM Fact.OrderHistoryExtended;
GO

UPDATE 
	Fact.OrderHistoryExtended
SET [WWI Order ID] = [Order Key];
GO

/*
	Repeat the following until log shrinks. These demos don't require much log space
*/

CHECKPOINT
GO
USE WideWorldImportersDW;
GO
DBCC SHRINKFILE (N'WWI_Log' , 0, TRUNCATEONLY)
GO
SELECT * FROM sys.dm_db_log_space_usage;
GO

/*
	Set up this section for CE Feedback for SQL Server 2022
	Code copied from https://github.com/microsoft/bobsql/tree/master/demos/sqlserver2022/IQP/cefeedback
	Download the AdventureWorks2016_EXT sample backup from https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2016_EXT.bak 
	Copy it to C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup folder
	Restore AdventureWorks_EXT
	Create and start an Extended Events session to view feedback events. Use SSMS in Object Explorer to view the session with Watch Live Data.
*/

USE [master]
GO
DECLARE @dbname nvarchar(128)
SET @dbname = N'AdventureWorks_EXT'

IF (EXISTS (SELECT name 
FROM master.dbo.sysdatabases 
WHERE ('[' + name + ']' = @dbname 
OR name = @dbname)))
BEGIN
ALTER DATABASE [AdventureWorks] SET RESTRICTED_USER;
END
GO

USE master;
GO
RESTORE DATABASE AdventureWorks_EXT FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorks2016_EXT.bak'
WITH MOVE 'AdventureWorks2016_EXT_Data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AdventureWorks2016_Data.mdf',
MOVE 'AdventureWorks2016_EXT_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AdventureWorks2016_log.ldf',
MOVE 'AdventureWorks2016_EXT_Mod' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AdventureWorks2016_EXT_mod'
GO

/*
	Add an ncl index on City column for Person.Address
*/

USE [AdventureWorks_EXT];
GO
CREATE NONCLUSTERED INDEX [IX_Address_City] ON [Person].[Address]
(
	[City] ASC
);
GO

/*
	Set up this section for DOP Feedback in SQL Server 2022
	Code copied from https://github.com/microsoft/bobsql/tree/master/demos/sqlserver2022/IQP/dopfeedback
	Download the WideWorldImporters sample backup from https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak 
	Copy it to C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup folder
	Restore WideWorldImporters
	Create and start an Extended Events session to view feedback events. Use SSMS in Object Explorer to view the session with Watch Live Data.
*/

USE [master]
GO
DECLARE @dbname nvarchar(128)
SET @dbname = N'WideWorldImporters'

IF (EXISTS (SELECT name 
FROM master.dbo.sysdatabases 
WHERE ('[' + name + ']' = @dbname 
OR name = @dbname)))
BEGIN
ALTER DATABASE [WideWorldImporters] SET RESTRICTED_USER;
END
GO

USE master;
GO
RESTORE DATABASE WideWorldImporters FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\WideWorldImporters-Full.bak'
WITH MOVE 'WWI_Primary' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\WideWorldImporters.mdf',
MOVE 'WWI_UserData' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\WideWorldImporters_UserData.ndf',
MOVE 'WWI_Log'  TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\WideWorldImporters.ldf',
MOVE 'WWI_InMemory_Data_1' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\WideWorldImporters_InMemory_Data_1',
stats=5;
GO

/*
	Extend the database
	This will take ~10-15 mins to execute. Because of the large transaction the log will grow to ~30Gb and the user FG will grow to about ~6.5Gb.
	Add StockItems to cause a data skew in Suppliers
*/

USE WideWorldImporters;
GO
DECLARE @StockItemID int;
DECLARE @StockItemName varchar(100);
DECLARE @SupplierID int;
SELECT @StockItemID = 228;
SET @StockItemName = 'Dallas Cowboys Shirt'+convert(varchar(10), @StockItemID);
SET @SupplierID = 4;
DELETE FROM Warehouse.StockItems WHERE StockItemID >= @StockItemID;
SET NOCOUNT ON;
BEGIN TRANSACTION;
WHILE @StockItemID <= 20000000
BEGIN
INSERT INTO Warehouse.StockItems
(StockItemID, StockItemName, SupplierID, UnitPackageID, OuterPackageID, LeadTimeDays,
QuantityPerOuter, IsChillerStock, TaxRate, UnitPrice, TypicalWeightPerUnit, LastEditedBy
)
VALUES (@StockItemID, @StockItemName, @SupplierID, 10, 9, 12, 100, 0, 15.00, 100.00, 0.300, 1);
SET @StockItemID = @StockItemID + 1;
SET @StockItemName = 'Dallas Cowboys Shirt'+convert(varchar(10), @StockItemID);
END
COMMIT TRANSACTION;
SET NOCOUNT OFF;
GO

/*
	Rebuild indexes
*/

USE WideWorldImporters;
GO
ALTER INDEX FK_Warehouse_StockItems_SupplierID ON Warehouse.StockItems REBUILD;
GO

/*
	Repeat the following until log shrinks. These demos don't require much log space
*/

CHECKPOINT
GO
USE WideWorldImporters;
GO
DBCC SHRINKFILE (N'WWI_Log' , 0, TRUNCATEONLY)
GO
SELECT * FROM sys.dm_db_log_space_usage;
GO

/*
	Set up this section for Parameter Sensitive Plan Optimization (PSP)in SQL Server 2022
	Script to load more data into the Warehouse.StockItems table. 
	This script will take 5-10 mins to run (timing depends on how many CPUs and the speed of your disk).
*/

DECLARE @StockItemID int;
DECLARE @StockItemName varchar(100);
DECLARE @SupplierID int;
SELECT @StockItemID = 4000001;
SET @StockItemName = 'Dallas Cowboys Mug'+convert(varchar(10), @StockItemID);
SET @SupplierID = 5;
DELETE FROM Warehouse.StockItems WHERE StockItemID >= @StockItemID;
SET NOCOUNT ON;
BEGIN TRANSACTION;
WHILE @StockItemID <= 8000000
BEGIN
INSERT INTO Warehouse.StockItems
(StockItemID, StockItemName, SupplierID, UnitPackageID, OuterPackageID, LeadTimeDays,
QuantityPerOuter, IsChillerStock, TaxRate, UnitPrice, TypicalWeightPerUnit, LastEditedBy
)
VALUES (@StockItemID, @StockItemName, @SupplierID, 10, 9, 12, 100, 0, 15.00, 100.00, 0.300, 1);
SET @StockItemID = @StockItemID + 1;
SET @StockItemName = 'Dallas Cowboys Mug'+convert(varchar(10), @StockItemID);
END;
COMMIT TRANSACTION;
SET NOCOUNT OFF;
GO

/*
	Rebuild an index associated with the table using the script rebuild_index.sql. 
	IMPORTANT: If you miss this step you will not be able to see the performance improvement for PSP optimization.
*/

USE WideWorldImporters;
GO
ALTER INDEX FK_Warehouse_StockItems_SupplierID ON Warehouse.StockItems REBUILD;
GO

/*
	Repeat the following until log shrinks. These demos don't require much log space
*/

CHECKPOINT
GO
USE WideWorldImporters;
GO
DBCC SHRINKFILE (N'WWI_Log' , 0, TRUNCATEONLY)
GO
SELECT * FROM sys.dm_db_log_space_usage;
GO

/*
	Set up this section if you want to test adaptive join when batchmode in rowstore kicks in.
	Test code is at the bottom of 01_AdaptiveJoin_BatchMode.sql
	Restore Adventureworks database
	https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver15&tabs=ssms
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
DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorks2022.bak' 
WITH  FILE = 1,  
MOVE N'AdventureWorks2022' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Data\AdventureWorks2022.mdf', 
MOVE N'AdventureWorks2022_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Data\AdventureWorks2022_log.ldf', 
NOUNLOAD,  REPLACE, STATS = 5;
GO

USE [AdventureWorks]
GO
ALTER AUTHORIZATION ON DATABASE::[AdventureWorks] TO [sa]
GO
USE [master]
GO
ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 160
GO

--Run code from here to make the database bigger
--https://www.sqlskills.com/blogs/jonathan/enlarging-the-adventureworks-sample-databases/
/*****************************************************************************
*   FileName:  Create Enlarged AdventureWorks Tables.sql
*
*   Summary: Creates an enlarged version of the AdventureWorks database
*            for use in demonstrating SQL Server performance tuning and
*            execution plan issues.
*
*   Date: November 14, 2011 
*
*   SQL Server Versions:
*         2008, 2008R2, 2012
*         
******************************************************************************
*   Copyright (C) 2011 Jonathan M. Kehayias, SQLskills.com
*   All rights reserved. 
*
*   For more scripts and sample code, check out 
*      http://sqlskills.com/blogs/jonathan
*
*   You may alter this code for your own *non-commercial* purposes. You may
*   republish altered code as long as you include this copyright and give 
*	due credit. 
*
*
*   THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
*   ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
*   TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
*   PARTICULAR PURPOSE. 
*
******************************************************************************/
USE AdventureWorks;
GO

IF OBJECT_ID('Sales.SalesOrderHeaderEnlarged') IS NOT NULL
	DROP TABLE Sales.SalesOrderHeaderEnlarged;
GO

CREATE TABLE Sales.SalesOrderHeaderEnlarged
	(
	SalesOrderID int NOT NULL IDENTITY (1, 1) NOT FOR REPLICATION,
	RevisionNumber tinyint NOT NULL,
	OrderDate datetime NOT NULL,
	DueDate datetime NOT NULL,
	ShipDate datetime NULL,
	Status tinyint NOT NULL,
	OnlineOrderFlag dbo.Flag NOT NULL,
	SalesOrderNumber  AS (isnull(N'SO'+CONVERT([nvarchar](23),[SalesOrderID],0),N'*** ERROR ***')),
	PurchaseOrderNumber dbo.OrderNumber NULL,
	AccountNumber dbo.AccountNumber NULL,
	CustomerID int NOT NULL,
	SalesPersonID int NULL,
	TerritoryID int NULL,
	BillToAddressID int NOT NULL,
	ShipToAddressID int NOT NULL,
	ShipMethodID int NOT NULL,
	CreditCardID int NULL,
	CreditCardApprovalCode varchar(15) NULL,
	CurrencyRateID int NULL,
	SubTotal money NOT NULL,
	TaxAmt money NOT NULL,
	Freight money NOT NULL,
	TotalDue  AS (isnull(([SubTotal]+[TaxAmt])+[Freight],(0))),
	Comment nvarchar(128) NULL,
	rowguid uniqueidentifier NOT NULL ROWGUIDCOL,
	ModifiedDate datetime NOT NULL
	)  ON [PRIMARY]
GO

SET IDENTITY_INSERT Sales.SalesOrderHeaderEnlarged ON
GO
INSERT INTO Sales.SalesOrderHeaderEnlarged 
	(SalesOrderID, 
	RevisionNumber, 
	OrderDate, 
	DueDate, 
	ShipDate, 
	Status, 
	OnlineOrderFlag, 
	PurchaseOrderNumber, 
	AccountNumber, 
	CustomerID, 
	SalesPersonID, 
	TerritoryID, 
	BillToAddressID, 
	ShipToAddressID, 
	ShipMethodID, 
	CreditCardID, 
	CreditCardApprovalCode, 
	CurrencyRateID, 
	SubTotal, 
	TaxAmt, 
	Freight, 
	Comment, 
	rowguid, 
	ModifiedDate)
SELECT 
	SalesOrderID, 
	RevisionNumber, 
	OrderDate, 
	DueDate, 
	ShipDate, 
	Status, 
	OnlineOrderFlag, 
	PurchaseOrderNumber, 
	AccountNumber, 
	CustomerID, 
	SalesPersonID, 
	TerritoryID, 
	BillToAddressID, 
	ShipToAddressID, 
	ShipMethodID, 
	CreditCardID, 
	CreditCardApprovalCode, 
	CurrencyRateID, 
	SubTotal, 
	TaxAmt, 
	Freight, 
	Comment, 
	rowguid, 
	ModifiedDate 
FROM Sales.SalesOrderHeader WITH (HOLDLOCK TABLOCKX)
GO
SET IDENTITY_INSERT Sales.SalesOrderHeaderEnlarged OFF
GO
ALTER TABLE Sales.SalesOrderHeaderEnlarged ADD CONSTRAINT
	PK_SalesOrderHeaderEnlarged_SalesOrderID PRIMARY KEY CLUSTERED 
	(
		SalesOrderID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO

CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderHeaderEnlarged_rowguid ON Sales.SalesOrderHeaderEnlarged
	(
		rowguid
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderHeaderEnlarged_SalesOrderNumber ON Sales.SalesOrderHeaderEnlarged
	(
		SalesOrderNumber
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_SalesOrderHeaderEnlarged_CustomerID ON Sales.SalesOrderHeaderEnlarged
	(
		CustomerID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_SalesOrderHeaderEnlarged_SalesPersonID ON Sales.SalesOrderHeaderEnlarged
	(
		SalesPersonID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

IF OBJECT_ID('Sales.SalesOrderDetailEnlarged') IS NOT NULL
	DROP TABLE Sales.SalesOrderDetailEnlarged;
GO
CREATE TABLE Sales.SalesOrderDetailEnlarged
	(
	SalesOrderID int NOT NULL,
	SalesOrderDetailID int NOT NULL IDENTITY (1, 1),
	CarrierTrackingNumber nvarchar(25) NULL,
	OrderQty smallint NOT NULL,
	ProductID int NOT NULL,
	SpecialOfferID int NOT NULL,
	UnitPrice money NOT NULL,
	UnitPriceDiscount money NOT NULL,
	LineTotal  AS (isnull(([UnitPrice]*((1.0)-[UnitPriceDiscount]))*[OrderQty],(0.0))),
	rowguid uniqueidentifier NOT NULL ROWGUIDCOL,
	ModifiedDate datetime NOT NULL
	)  ON [PRIMARY]
GO

SET IDENTITY_INSERT Sales.SalesOrderDetailEnlarged ON
GO
INSERT INTO Sales.SalesOrderDetailEnlarged 
	(SalesOrderID, 
	SalesOrderDetailID, 
	CarrierTrackingNumber, 
	OrderQty, 
	ProductID, 
	SpecialOfferID, 
	UnitPrice, 
	UnitPriceDiscount, 
	rowguid, 
	ModifiedDate)
SELECT 
	SalesOrderID, 
	SalesOrderDetailID, 
	CarrierTrackingNumber, 
	OrderQty, 
	ProductID, 
	SpecialOfferID, 
	UnitPrice, 
	UnitPriceDiscount, 
	rowguid, 
	ModifiedDate 
FROM Sales.SalesOrderDetail WITH (HOLDLOCK TABLOCKX)
GO
SET IDENTITY_INSERT Sales.SalesOrderDetailEnlarged OFF
GO
ALTER TABLE Sales.SalesOrderDetailEnlarged ADD CONSTRAINT
	PK_SalesOrderDetailEnlarged_SalesOrderID_SalesOrderDetailID PRIMARY KEY CLUSTERED 
	(
		SalesOrderID,
		SalesOrderDetailID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderDetailEnlarged_rowguid ON Sales.SalesOrderDetailEnlarged
	(
		rowguid
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX IX_SalesOrderDetailEnlarged_ProductID ON Sales.SalesOrderDetailEnlarged
	(
		ProductID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

BEGIN TRANSACTION
DECLARE @TableVar TABLE
(OrigSalesOrderID int, NewSalesOrderID int)
INSERT INTO Sales.SalesOrderHeaderEnlarged 
	(RevisionNumber, 
	OrderDate, 
	DueDate, 
	ShipDate, 
	Status, 
	OnlineOrderFlag, 
	 PurchaseOrderNumber, 
	 AccountNumber, 
	 CustomerID, 
	 SalesPersonID, 
	 TerritoryID, 
	 BillToAddressID, 
	 ShipToAddressID, 
	 ShipMethodID, 
	 CreditCardID, 
	 CreditCardApprovalCode, 
	 CurrencyRateID, 
	 SubTotal, 
	 TaxAmt, 
	 Freight, 
	 Comment, 
	 rowguid, 
	 ModifiedDate)
OUTPUT inserted.Comment, inserted.SalesOrderID
	INTO @TableVar
SELECT 
	RevisionNumber, 
	DATEADD(dd, number, OrderDate) AS OrderDate, 
	DATEADD(dd, number, DueDate),  
	DATEADD(dd, number, ShipDate), 
	Status, 
	OnlineOrderFlag, 
	PurchaseOrderNumber, 
	AccountNumber, 
	CustomerID, 
	SalesPersonID, 
	TerritoryID, 
	BillToAddressID, 
	ShipToAddressID, 
	ShipMethodID, 
	CreditCardID, 
	CreditCardApprovalCode, 
	CurrencyRateID, 
	SubTotal, 
	TaxAmt, 
	Freight, 
	SalesOrderID, 
	NEWID(), 
	DATEADD(dd, number, ModifiedDate)
FROM Sales.SalesOrderHeader AS soh WITH (HOLDLOCK TABLOCKX)
CROSS JOIN (
		SELECT number
		FROM (	SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
			UNION
				SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
			UNION
				SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
			UNION
				SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
		  ) AS tab
) AS Randomizer
ORDER BY OrderDate, number

INSERT INTO Sales.SalesOrderDetailEnlarged 
	(SalesOrderID, 
	CarrierTrackingNumber, 
	OrderQty, 
	ProductID, 
	SpecialOfferID, 
	UnitPrice, 
	UnitPriceDiscount, 
	rowguid, 
	ModifiedDate)
SELECT 
	tv.NewSalesOrderID, 
	CarrierTrackingNumber, 
	OrderQty, ProductID, 
	SpecialOfferID, 
	UnitPrice, 
	UnitPriceDiscount, 
	NEWID(), 
	ModifiedDate 
FROM Sales.SalesOrderDetail AS sod
JOIN @TableVar AS tv
	ON sod.SalesOrderID = tv.OrigSalesOrderID
ORDER BY sod.SalesOrderDetailID
COMMIT

/*
	Revert MAXDOP Setting
*/

EXEC sp_configure 'max degree of parallelism', 2;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
