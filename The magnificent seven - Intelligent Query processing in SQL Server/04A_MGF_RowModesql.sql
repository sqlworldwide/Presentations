/*****************************************************************
-- Scirpt Name: 04A_MFG_RowModesql.sql
-- This code is copied from
-- https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/intelligent-query-processing

-- Modified by Taiob Ali
-- May 19, 2022

-- Row mode memory grant feedback

-- See https://aka.ms/IQP for more background
-- Demo scripts: https://aka.ms/IQPDemos 

-- This demo is on SQL Server 2019 and Azure SQL DB 
-- SSMS v17.9 or higher

-- Email IntelligentQP@microsoft.com for questions\feedback
****************************************************************/

USE [master];
GO

ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 150;
GO

USE [WideWorldImportersDW];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/* Simulate out-of-date stats */
UPDATE STATISTICS Fact.OrderHistory 
WITH ROWCOUNT = 1;
GO

/*
Include actual execution plan (ctrl+M)
Execute once to see spills (row mode)
Execute a second time to see correction

First execution look at Table Scan or OrderHistory table
Estimated number of rows =1
Actual number of rows = 3,702,592
Grnated Memory  =1056 KB

Second execution
GrantedMemory="625072" LastRequestedMemory="1056" IsMemoryGrantFeedbackAdjusted="Yes: Adjusting"

Third execution
LastRequestedMemory="625072" IsMemoryGrantFeedbackAdjusted="Yes: Stable"
*/
SELECT fo.[Order Key], fo.Description,
	si.[Lead Time Days]
FROM Fact.OrderHistory AS fo
INNER HASH JOIN Dimension.[Stock Item] AS si 
	ON fo.[Stock Item Key] = si.[Stock Item Key]
WHERE fo.[Lineage Key] = 9
	AND si.[Lead Time Days] > 19;

/* Cleanup */
UPDATE STATISTICS Fact.OrderHistory 
WITH ROWCOUNT = 3702672;
GO
