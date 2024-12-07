/*************************************************************
	 Script Name: 02_InterleavedExecution.sql
	 This code is copied from
	 https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing
	
	 Modified by Taiob Ali
	 December 3rd, 2024
	
	 Interleaved Execution
	 Applies to: SQL Server (Starting with SQL Server 2017 (14.x)), Azure SQL Database starting with database compatibility level 140
	 Available in all editions
	 
	 See https://aka.ms/IQP for more background
	 Demo scripts: https://aka.ms/IQPDemos	 
	
	 Last updated 1/29/2020 (Credit: Milos Radivojevic)
	 Changed @event to varchar(30) from varchar(15)
	 Added date range to 'Mild Recession' branch
	
	 Email IntelligentQP@microsoft.com for questions\feedback
**************************************************************/

/*
	Create a multi-statement table-valued functions (MSTVFs)
*/

USE [WideWorldImportersDW];
GO

CREATE OR ALTER FUNCTION [Fact].[ufn_WhatIfOutlierEventQuantity]
	(@event VARCHAR(30), @beginOrderDateKey DATE, @endOrderDateKey DATE)
RETURNS @OutlierEventQuantity TABLE (
	[Order Key] [bigint],
	[City Key] [int] NOT NULL,
	[Customer Key] [int] NOT NULL,
	[Stock Item Key] [int] NOT NULL,
	[Order Date Key] [date] NOT NULL,
	[Picked Date Key] [date] NULL,
	[Salesperson Key] [int] NOT NULL,
	[Picker Key] [int] NULL,
	[OutlierEventQuantity] [int] NOT NULL)
AS 
BEGIN

-- Valid @event values
	-- 'Mild Recession'
	-- 'Hurricane - South Atlantic'
	-- 'Hurricane - East South Central'
	-- 'Hurricane - West South Central'
	IF @event = 'Mild Recession'
    INSERT  @OutlierEventQuantity
	SELECT [o].[Order Key], [o].[City Key], [o].[Customer Key],
           [o].[Stock Item Key], [o].[Order Date Key], [o].[Picked Date Key],
           [o].[Salesperson Key], [o].[Picker Key], 
           CASE
			WHEN [o].[Quantity] > 2 THEN [o].[Quantity] * .5
			ELSE [o].[Quantity]
		   END 
	FROM [Fact].[Order] AS [o]
	INNER JOIN [Dimension].[City] AS [c]
		ON [c].[City Key] = [o].[City Key]
	WHERE [o].[Order Date Key] BETWEEN @beginOrderDateKey AND @endOrderDateKey

	IF @event = 'Hurricane - South Atlantic'
    INSERT  @OutlierEventQuantity
	SELECT [o].[Order Key], [o].[City Key], [o].[Customer Key],
           [o].[Stock Item Key], [o].[Order Date Key], [o].[Picked Date Key],
           [o].[Salesperson Key], [o].[Picker Key], 
           CASE
			WHEN [o].[Quantity] > 10 THEN [o].[Quantity] * .5
			ELSE [o].[Quantity]
		   END 
	FROM [Fact].[Order] AS [o]
	INNER JOIN [Dimension].[City] AS [c]
		ON [c].[City Key] = [o].[City Key]
	WHERE [c].[State Province] IN
		('Florida', 'Georgia', 'Maryland', 'North Carolina',
		'South Carolina', 'Virginia', 'West Virginia',
		'Delaware')
	AND [o].[Order Date Key] BETWEEN @beginOrderDateKey AND @endOrderDateKey

	IF @event = 'Hurricane - East South Central'
    INSERT @OutlierEventQuantity
	SELECT [o].[Order Key], [o].[City Key], [o].[Customer Key],
           [o].[Stock Item Key], [o].[Order Date Key], [o].[Picked Date Key],
           [o].[Salesperson Key], [o].[Picker Key], 
           CASE
			WHEN [o].[Quantity] > 50 THEN [o].[Quantity] * .5
			ELSE [o].[Quantity]
		   END
	FROM [Fact].[Order] AS [o]
	INNER JOIN [Dimension].[City] AS [c]
		ON [c].[City Key] = [o].[City Key]
	INNER JOIN [Dimension].[Stock Item] AS [si]
		ON [si].[Stock Item Key] = [o].[Stock Item Key]
	WHERE [c].[State Province] IN
	('Alabama', 'Kentucky', 'Mississippi', 'Tennessee')
	AND [si].[Buying Package] = 'Carton'
	AND [o].[Order Date Key] BETWEEN @beginOrderDateKey AND @endOrderDateKey

	IF @event = 'Hurricane - West South Central'
    INSERT @OutlierEventQuantity
	SELECT [o].[Order Key], [o].[City Key], [o].[Customer Key],
           [o].[Stock Item Key], [o].[Order Date Key], [o].[Picked Date Key],
           [o].[Salesperson Key], [o].[Picker Key], 
           CASE
		    WHEN [cu].[Customer] = 'Unknown' THEN 0
			WHEN [cu].[Customer] <> 'Unknown' AND
			 [o].[Quantity] > 10 THEN [o].[Quantity] * .5
			ELSE [o].[Quantity]
		   END
	FROM [Fact].[Order] AS [o]
	INNER JOIN [Dimension].[City] AS [c]
		ON [c].[City Key] = [o].[City Key]
	INNER JOIN [Dimension].[Customer] AS [cu]
		ON [cu].[Customer Key] = [o].[Customer Key]
	WHERE [c].[State Province] IN
	('Arkansas', 'Louisiana', 'Oklahoma', 'Texas')
	AND [o].[Order Date Key] BETWEEN @beginOrderDateKey AND @endOrderDateKey

    RETURN
END
GO

/* 
	Demo starts here 
*/

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 130;
GO

USE [WideWorldImportersDW];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/*
	Turn on Actual Execution plan ctrl+M
	look at the new estimated number of rows=100 at Node Id =4, Table scan
	Look at the spill warning due to low estimate
	Show the new attribute 'ContainsInterleavedExecutionCandidates' but not executed
*/

SELECT [fo].[Order Key], [fo].[Description], [fo].[Package],
		[fo].[Quantity], [foo].[OutlierEventQuantity]
FROM [Fact].[Order] AS [fo]
INNER JOIN [Fact].[ufn_WhatIfOutlierEventQuantity]
 ('Mild Recession',
  '1-01-2013',
  '10-15-2014') AS [foo] 
	ON [fo].[Order Key] = [foo].[Order Key]
AND [fo].[City Key] = [foo].[City Key]
AND [fo].[Customer Key] = [foo].[Customer Key]
AND [fo].[Stock Item Key] = [foo].[Stock Item Key]
AND [fo].[Order Date Key] = [foo].[Order Date Key]
AND [fo].[Picked Date Key] = [foo].[Picked Date Key]
AND [fo].[Salesperson Key] = [foo].[Salesperson Key]
AND [fo].[Picker Key] = [foo].[Picker Key]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE [si].[Lead Time Days] > 0
	AND [fo].[Quantity] > 50;
GO

/*
	We no longer have spill-warnings, as we're granting more memory based on the true row count 
	flowing from the MSTVF table scan
	look at the new estimated and actual row for the function call
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
	Show the new attribute 'ContainsInterleavedExecutionCandidates' in the root node
	Show the new attribute 'IsInterleavedExecuted' in the table valued function node id = 1
*/

SELECT [fo].[Order Key], [fo].[Description], [fo].[Package],
		[fo].[Quantity], [foo].[OutlierEventQuantity]
FROM [Fact].[Order] AS [fo]
INNER JOIN [Fact].[ufn_WhatIfOutlierEventQuantity]
 ('Mild Recession',
  '1-01-2013',
  '10-15-2014') AS [foo] 
	ON [fo].[Order Key] = [foo].[Order Key]
AND [fo].[City Key] = [foo].[City Key]
AND [fo].[Customer Key] = [foo].[Customer Key]
AND [fo].[Stock Item Key] = [foo].[Stock Item Key]
AND [fo].[Order Date Key] = [foo].[Order Date Key]
AND [fo].[Picked Date Key] = [foo].[Picked Date Key]
AND [fo].[Salesperson Key] = [foo].[Salesperson Key]
AND [fo].[Picker Key] = [foo].[Picker Key]
INNER JOIN [Dimension].[Stock Item] AS [si] 
	ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE [si].[Lead Time Days] > 0
	AND [fo].[Quantity] > 50;
GO