/*
Scirpt Name: 001_Setup.sql
Setting up database for all the demo
Download AdventureWorks backup
https://github.com/Microsoft/sql-server-samples/releases/tag/adventureworks

In my machine it takes about 3 minutes.
*/

USE [master];
GO
DECLARE @dbname nvarchar(128);
SET @dbname = N'AdventureWorks';

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
DECLARE @dbname nvarchar(128);
SET @dbname = N'AdventureWorks';

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
USE [AdventureWorks];
GO
ALTER AUTHORIZATION ON DATABASE::[AdventureWorks] TO [sa];
GO
USE [master];
GO
ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 150;
GO

/*
Following code is written by Adam Machanic to make two big tables
Code was copied from here:
http://sqlblog.com/blogs/adam_machanic/archive/2011/10/17/thinking-big-adventure.aspx
*/

USE [AdventureWorks];
GO

SELECT
	p.ProductID + (a.number * 1000) AS ProductID,
	p.Name + CONVERT(VARCHAR, (a.number * 1000)) AS Name,
	p.ProductNumber + '-' + CONVERT(VARCHAR, (a.number * 1000)) AS ProductNumber,
	p.MakeFlag,
	p.FinishedGoodsFlag,
	p.Color,
	p.SafetyStockLevel,
	p.ReorderPoint,
	p.StandardCost,
	p.ListPrice,
	p.Size,
	p.SizeUnitMeasureCode,
	p.WeightUnitMeasureCode,
	p.Weight,
	p.DaysToManufacture,
	p.ProductLine,
	p.Class,
	p.Style,
	p.ProductSubcategoryID,
	p.ProductModelID,
	p.SellStartDate,
	p.SellEndDate,
	p.DiscontinuedDate
INTO dbo.bigProduct
FROM Production.Product AS p
CROSS JOIN master..spt_values AS a
WHERE
	a.type = 'p'
	AND a.number BETWEEN 1 AND 50;
GO


ALTER TABLE dbo.bigProduct
ALTER COLUMN ProductId INT NOT NULL;
GO

ALTER TABLE dbo.bigProduct
ADD CONSTRAINT pk_bigProduct PRIMARY KEY (ProductId);
GO


SELECT 
	ROW_NUMBER() OVER 
	(
		ORDER BY 
			x.TransactionDate,
			(SELECT NEWID())
	) AS TransactionID,
	p1.ProductID,
	x.TransactionDate,
	x.Quantity,
	CONVERT(MONEY, p1.ListPrice * x.Quantity * RAND(CHECKSUM(NEWID())) * 2) AS ActualCost
INTO dbo.bigTransactionHistory
FROM
(
	SELECT
		p.ProductID, 
		p.ListPrice,
		CASE
			WHEN p.productid % 26 = 0 THEN 26
			WHEN p.productid % 25 = 0 THEN 25
			WHEN p.productid % 24 = 0 THEN 24
			WHEN p.productid % 23 = 0 THEN 23
			WHEN p.productid % 22 = 0 THEN 22
			WHEN p.productid % 21 = 0 THEN 21
			WHEN p.productid % 20 = 0 THEN 20
			WHEN p.productid % 19 = 0 THEN 19
			WHEN p.productid % 18 = 0 THEN 18
			WHEN p.productid % 17 = 0 THEN 17
			WHEN p.productid % 16 = 0 THEN 16
			WHEN p.productid % 15 = 0 THEN 15
			WHEN p.productid % 14 = 0 THEN 14
			WHEN p.productid % 13 = 0 THEN 13
			WHEN p.productid % 12 = 0 THEN 12
			WHEN p.productid % 11 = 0 THEN 11
			WHEN p.productid % 10 = 0 THEN 10
			WHEN p.productid % 9 = 0 THEN 9
			WHEN p.productid % 8 = 0 THEN 8
			WHEN p.productid % 7 = 0 THEN 7
			WHEN p.productid % 6 = 0 THEN 6
			WHEN p.productid % 5 = 0 THEN 5
			WHEN p.productid % 4 = 0 THEN 4
			WHEN p.productid % 3 = 0 THEN 3
			WHEN p.productid % 2 = 0 THEN 2
			ELSE 1 
		END AS ProductGroup
	FROM dbo.bigproduct p
) AS p1
CROSS APPLY
(
	SELECT
		transactionDate,
		CONVERT(INT, (RAND(CHECKSUM(NEWID())) * 100) + 1) AS Quantity
	FROM
	(
		SELECT 
			DATEADD(dd, number, '20050101') AS transactionDate,
			NTILE(p1.ProductGroup) OVER 
			(
				ORDER BY number
			) AS groupRange
		FROM master..spt_values
		WHERE 
			type = 'p'
	) AS z
	WHERE
		z.groupRange % 2 = 1
) AS x;



ALTER TABLE dbo.bigTransactionHistory
ALTER COLUMN TransactionID INT NOT NULL;
GO


ALTER TABLE dbo.bigTransactionHistory
ADD CONSTRAINT pk_bigTransactionHistory PRIMARY KEY (TransactionID);
GO


CREATE NONCLUSTERED INDEX IX_ProductId_TransactionDate
ON dbo.bigTransactionHistory
(
	ProductId,
	TransactionDate
)
INCLUDE 
(
	Quantity,
	ActualCost
);
GO

/* Set MAXDOP=2 */
USE [master];
GO
EXEC sp_configure 'show advanced options', 1;  
GO
RECONFIGURE;  
GO
EXEC sp_configure 'max degree of parallelism', 2;  
GO  
RECONFIGURE;  
GO

/*
Turn on query store 
Ref: https://docs.microsoft.com/en-us/sql/relational-databases/performance/best-practice-with-the-query-store?view=sql-server-2017
*/

USE [AdventureWorks];
GO

ALTER DATABASE AdventureWorks
SET QUERY_STORE = ON 
(
  OPERATION_MODE = READ_WRITE, 
  CLEANUP_POLICY = ( STALE_QUERY_THRESHOLD_DAYS = 90 ),
  DATA_FLUSH_INTERVAL_SECONDS = 60,
  MAX_STORAGE_SIZE_MB = 1000, 
  INTERVAL_LENGTH_MINUTES = 60,
  SIZE_BASED_CLEANUP_MODE = AUTO, 
  MAX_PLANS_PER_QUERY = 200,
  WAIT_STATS_CAPTURE_MODE = ON,
  QUERY_CAPTURE_MODE = CUSTOM,
  QUERY_CAPTURE_POLICY = 
		(
		  STALE_CAPTURE_POLICY_THRESHOLD = 24 HOURS,
      EXECUTION_COUNT = 30,
      TOTAL_COMPILE_CPU_TIME_MS = 1000,
      TOTAL_EXECUTION_CPU_TIME_MS = 100 
    )
);