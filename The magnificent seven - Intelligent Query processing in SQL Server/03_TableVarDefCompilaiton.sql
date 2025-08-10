/********************************************************** 
03_TableVarDefCompilaiton.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modiefied
August 08, 2025
	
Tested on :
SQL Server 2022 CU20
SSMS 21.4.8

This code is copied from
https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing
	
Table variable deferred compilation
Applies to: SQL Server (Starting with SQL Server 2019 (15.x)), starting with database compatibility level 150
Available in all editions
************************************************************/

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
Look at estimated rows, speed, join algorithm
Estimated number of rows: 1
Actual number of row: 490928
Thick flow going to Nested loop join
Row ID lookup
Low memory grant caused a sort spill
Takes about ~20 seconds in my laptop
*/

DECLARE @Order TABLE 
	([Order Key] BIGINT NOT NULL,
	 [Quantity] INT NOT NULL
	);

INSERT @Order
SELECT [Order Key], [Quantity]
FROM [Fact].[OrderHistory]
WHERE  [Quantity] > 99;

SELECT oh.[Order Key], oh.[Order Date Key],
   oh.[Unit Price], o.Quantity
FROM Fact.OrderHistoryExtended AS oh
INNER JOIN @Order AS o
ON o.[Order Key] = oh.[Order Key]
WHERE oh.[Unit Price] > 0.10
ORDER BY oh.[Unit Price] DESC;
GO


/*
Prior 'Table variable deferred compilation' feature was release we could mitigate 
the estimation problem with trace flag 2453
*/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

DBCC TRACEON(2453, -1);

DECLARE @Order TABLE 
	([Order Key] BIGINT NOT NULL,
	 [Quantity] INT NOT NULL
	);

INSERT @Order
SELECT [Order Key], [Quantity]
FROM [Fact].[OrderHistory]
WHERE  [Quantity] > 99;

SELECT oh.[Order Key], oh.[Order Date Key],
   oh.[Unit Price], o.Quantity
FROM Fact.OrderHistoryExtended AS oh
INNER JOIN @Order AS o
ON o.[Order Key] = oh.[Order Key]
WHERE oh.[Unit Price] > 0.10
ORDER BY oh.[Unit Price] DESC;
GO

DBCC TRACEOFF(2453, -1);

/*
Prior 'Table variable deferred compilation' feature was release we could mitigate 
the estimation problem with an option recompile hint
*/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

DECLARE @Order TABLE 
	([Order Key] BIGINT NOT NULL,
	 [Quantity] INT NOT NULL
	);

INSERT @Order
SELECT [Order Key], [Quantity]
FROM [Fact].[OrderHistory]
WHERE  [Quantity] > 99;

SELECT oh.[Order Key], oh.[Order Date Key],
   oh.[Unit Price], o.Quantity
FROM Fact.OrderHistoryExtended AS oh
INNER JOIN @Order AS o
ON o.[Order Key] = oh.[Order Key]
WHERE oh.[Unit Price] > 0.10
ORDER BY oh.[Unit Price] DESC
OPTION (RECOMPILE);
GO


USE [master]
GO

/* Changing MAXDOP as this query can advantage of parallel execution */
EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
EXEC sp_configure 'max degree of parallelism', 0;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150
GO

/* Disconnect and connect */
USE [WideWorldImportersDW];
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
Turn on Actual Execution plan ctrl+M
This will get a parllel execution which also help reducing runtime
Estimated number of rows: 490928
Actual number of row: 490928
Hash join
*/
DECLARE @Order TABLE 
	([Order Key] BIGINT NOT NULL,
	 [Quantity] INT NOT NULL
	);

INSERT @Order
SELECT [Order Key], [Quantity]
FROM [Fact].[OrderHistory]
WHERE [Quantity] > 99;

-- Look at estimated rows, speed, join algorithm
SELECT oh.[Order Key], oh.[Order Date Key],
	oh.[Unit Price], o.Quantity
FROM Fact.OrderHistoryExtended AS oh
INNER JOIN @Order AS o
ON o.[Order Key] = oh.[Order Key]
WHERE oh.[Unit Price] > 0.10
ORDER BY oh.[Unit Price] DESC;
GO

/*
Does the problem really go away?
*/

/*
Write a stored procedure that returns record from Fact.OrderHistoryExtended
based on the input parameter @UnitPrice
Use a table variable to store the result set    
Sample call:
  EXEC dbo.GetOrderHistoryByUnitPrice @UnitPrice = 100.00;
*/
DROP PROCEDURE IF EXISTS dbo.GetOrderHistoryByUnitPrice;
GO
CREATE PROCEDURE dbo.GetOrderHistoryByUnitPrice
(
    @UnitPrice DECIMAL(18, 2)
)
AS
BEGIN
    DECLARE @OrderHistory TABLE
    (
        [Order Key] INT,
        [City Key] INT,
        [Quantity] INT,
        [Unit Price] DECIMAL(18, 2)
    )

    INSERT INTO @OrderHistory
    SELECT [Order Key], [City Key], [Quantity], [Unit Price]
    FROM Fact.OrderHistoryExtended
    WHERE [Unit Price] = @UnitPrice

    SELECT * FROM @OrderHistory
		ORDER BY Quantity
END
GO   

/* 
Calling with three different values
Number of records returned are in Ascending order
Turn on Actual Execution plan ctrl+M
Show the estimated vs actual numbers for select statement
*/

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC dbo.GetOrderHistoryByUnitPrice @UnitPrice = 20.00;
EXEC dbo.GetOrderHistoryByUnitPrice @UnitPrice = 3.20;
EXEC dbo.GetOrderHistoryByUnitPrice @UnitPrice = 36.00;

/* 
Calling with three different values
Number of records returned are in descending order
Turn on Actual Execution plan ctrl+M
Show the estimated vs actual numbers for select statement
Look at the spill warnings
*/

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC dbo.GetOrderHistoryByUnitPrice @UnitPrice = 36.00;
EXEC dbo.GetOrderHistoryByUnitPrice @UnitPrice = 3.20;
EXEC dbo.GetOrderHistoryByUnitPrice @UnitPrice = 20.00;


/* Revert MAXDOP Setting */
EXEC sp_configure 'max degree of parallelism', 2;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
