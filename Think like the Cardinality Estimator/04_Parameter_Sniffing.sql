/*============================================================================
Parameter_Sniffing.sql
Written by Taiob Ali
SqlWorldWide.com

This script will demonstrate how estimated numbers of rows are calculated 
in case of parameter sniffing.

Instruction to run this script
--------------------------------------------------------------------------
Run this on a separate window

USE [WideWorldImporters];
GO
DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID]);
GO
============================================================================*/

USE [WideWorldImporters];
GO

/*
Creating a simple store procedure to select by ContactPersonID
*/

DROP PROCEDURE IF EXISTS [dbo].[OrderID_by_ContactPersonID];
GO

CREATE PROCEDURE [dbo].[OrderID_by_ContactPersonID]
	@contactPersonID INT
AS
SELECT 
	OrderID, 
	CustomerID, 
	SalespersonPersonID, 
	ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID=@contactPersonID;
GO

/*
Include Actual Execution Plan (CTRL+M)
Look at 'Estimated number of rows' for 'Index Seek' operator 89
Look at row 5 in the histogram, which is a direct hit for RANGE_HI_KEY=1025
*/

EXECUTE [dbo].[OrderID_by_ContactPersonID] @contactPersonID = 1025;
GO

/*
As seen before direct hit for RANGE_HI_KEY  1025
*/

DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID])
WITH HISTOGRAM;
GO

/*
Include Actual Execution Plan (CTRL+M)
Calling with different value 1057
Click to see properties of select operator and look at for parameter list
Parameter compile with
Parameter runtime value 
*/

EXECUTE [dbo].[OrderID_by_ContactPersonID] @contactPersonID = 1057;
GO

/*
What the value should be for 1057?
118.6667
*/

DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID])
WITH HISTOGRAM;
GO

/*
Removes the plan from cache for single stored procedure
Get plan handle
*/

DECLARE @PlanHandle VARBINARY(64);
SELECT 
	@PlanHandle = cp.plan_handle
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE OBJECT_NAME (st.objectid) LIKE '%OrderID_by_ContactPersonID%';
IF @PlanHandle IS NOT NULL
  BEGIN
		DBCC FREEPROCCACHE(@PlanHandle);
	END
GO

/*
Include Actual Execution Plan (CTRL+M)
Calling with 1057 again
Look at 'Estimated number of rows' for 'Index Seek' operator, now we get 118.667
Click to see properties of select operator and look at for parameter list
Parameter compile with
Parameter runtime value 
*/

EXECUTE [dbo].[OrderID_by_ContactPersonID] @contactPersonID = 1057;
GO