/************************************************************ 
01_AdaptiveJoin_BatchMode.sql
Will also demo that Bathmode on Rowstore qualifes for Adaptive Join from compatibility mode 150
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://twitter.com/SqlWorldWide
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/


Last Modiefied
August 16, 2025
	
Tested on :
SQL Server 2022 CU20
SSMS 21.4.12

This code is copied from
https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing

Batch mode Adaptive Join
	Applies to: SQL Server (Starting with SQL Server 2017 (14.x)), Azure SQL Database starting with database compatibility level 140
	Enterprise edition only
	
*************************************************************/

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 140;
GO

USE [WideWorldImportersDW];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
 Turn on Actual Execution plan ctrl+M
 Notice Order table has a clustered columnstore index 
 Notice the operators related to adaptive join in propterties:
 -Actual execution mode
 -Estimated join type
 -Actual join type
 -Is adaptive
 -Description
 -Adaptive threshold rows
*/

SELECT [fo].[Order Key], [si].[Lead Time Days], [fo].[Quantity]
FROM [Fact].[Order] AS [fo]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE [fo].[Quantity] = 360;
GO

/* 
Inserting five rows with Quantity =361 that doesn't exist in the table yet 
*/

DELETE [Fact].[Order] 
WHERE Quantity = 361;
GO

INSERT [Fact].[Order] 
	([City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], 
	[Picker Key], [WWI Order ID], [WWI Backorder ID], Description, Package, Quantity, [Unit Price], [Tax Rate], 
	[Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT TOP 5 [City Key], [Customer Key], [Stock Item Key],
	[Order Date Key], [Picked Date Key], [Salesperson Key], 
	[Picker Key], [WWI Order ID], [WWI Backorder ID], 
	Description, Package,361, [Unit Price], [Tax Rate], 
	[Total Excluding Tax], [Tax Amount], [Total Including Tax], 
	[Lineage Key]
FROM [Fact].[Order];
GO

/* 
Now run the same query with value 361 
*/

SELECT [fo].[Order Key], [si].[Lead Time Days], [fo].[Quantity]
FROM [Fact].[Order] AS [fo]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE [fo].[Quantity] = 361;
GO

/*
Question:
With the introduction of Batch Mode on Rowstore can I take adavantge of adaptive join in rowstore?
Yes from SQL Server 2019 and with Compatibility level 150
	
Set up before you can run the demo code:
Restore Adventureworks database
https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver15&tabs=ssms
Enlarge the restored adventureworks database (which we did using setup file)
https://www.sqlskills.com/blogs/jonathan/enlarging-the-adventureworks-sample-databases/
*/

/*
Turn on Actual Execution plan ctrl+M
SalesOrderDetailEnlarged table only rowstore, we get batch mode on rowstore and followed by
adaptive join
*/

USE [master];
GO

ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 150;
GO

USE [AdventureWorks];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

SELECT 
  ProductID, 
	SUM(LineTotal) [sumOfLineTotal], 
	SUM(UnitPrice) [sumOfUnitPrice], 
	SUM(UnitPriceDiscount) [sumOfUnitPriceDiscount]
FROM Sales.SalesOrderDetailEnlarged sode
INNER JOIN Sales.SalesOrderHeaderEnlarged  sohe
  ON sode.SalesOrderID = sohe.SalesOrderID
GROUP BY ProductID;
GO

/*
If you have a cached plan and you might not get the advantage of adaptive join.
It depends on the plan that is in cache
*/

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 140;
GO

USE [WideWorldImportersDW];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
Creating a stored procedure for demo
*/

DROP PROCEDURE IF EXISTS dbo.countByQuantity;
GO
CREATE PROCEDURE dbo.countByQuantity
    @quantity int = 0
AS
SELECT [fo].[Order Key], [si].[Lead Time Days], [fo].[Quantity]
FROM [Fact].[Order] AS [fo]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE [fo].[Quantity] = @quantity
RETURN 0;
GO

/*
Turn on Actual Execution plan ctrl+M
Execute same stored procedure with 2 different parameter value
Turn on Actual Execution plan ctrl+M
Depends on if the first one will qualify for an adaptive join, the second one will use the same plan
*/

EXEC dbo.countByQuantity 10;
GO
EXEC dbo.countByQuantity 361;
GO

/*
Now evict the plan from the cache and run the same statement in reverse order
Removes the plan from cache for single stored procedure
Get plan handle
*/

DECLARE @PlanHandle VARBINARY(64);
SELECT  @PlanHandle = cp.plan_handle 
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st 
WHERE OBJECT_NAME (st.objectid) LIKE '%countByQuantity%';
IF @PlanHandle IS NOT NULL
    BEGIN
        DBCC FREEPROCCACHE(@PlanHandle);
    END
GO

/* 
Turn on Actual Execution plan ctrl+M 
This time we reverse the execution order
As the first query qualified for the adaptive join and the plan is cached, second query will use the same plan
*/

EXEC dbo.countByQuantity 361;
GO
EXEC dbo.countByQuantity 10;
GO


