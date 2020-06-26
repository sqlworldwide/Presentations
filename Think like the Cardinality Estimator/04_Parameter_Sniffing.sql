/*============================================================================
Parameter_Sniffing.sql
Written by Taiob M Ali
SqlWorldWide.com

This script will demonstrate how estimated numbers of rows are calculated 
in case of parameter sniffing.

Instruction to run this script
--------------------------------------------------------------------------
Run this on a separate window

USE [WideWorldImporters];
GO
DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID])
WITH HISTOGRAM;
GO
============================================================================*/

USE [WideWorldImporters];
GO

--Creating a simple store procedure to select by ContactPersonID
DROP PROCEDURE IF EXISTS [dbo].[OrderID_by_ContactPersonID];
GO

CREATE PROCEDURE [dbo].[OrderID_by_ContactPersonID]
	@contactPersonID INT
AS
SELECT OrderID, CustomerID, SalespersonPersonID, ContactPersonID
FROM Sales.Orders
WHERE ContactPersonID=@contactPersonID
GO

--Include Actual Execution Plan (CTRL+M)
--Look at 'Estimated number of rows' for 'Index Seek' operator 89
--Look at row 5 in the histogram, which is a direct hit for RANGE_HI_KEY=1025
EXECUTE [dbo].[OrderID_by_ContactPersonID] @contactPersonID = 1025;


--As seen before direct hit for RANGE_HI_KEY  1025
DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID])
WITH HISTOGRAM;
GO

--Include Actual Execution Plan (CTRL+M)
--Calling with different value 1057
--Click to see properties of select operator and look at for parameter list
--Parameter compile with
--Parameter runtime value 
EXECUTE [dbo].[OrderID_by_ContactPersonID] @contactPersonID = 1057;


--What the value should be for 1057?
--118.6667
DBCC SHOW_STATISTICS ('Sales.Orders', [FK_Sales_Orders_ContactPersonID])
WITH HISTOGRAM;
GO

--Removes all elements from the plan cache for Wideworldimporters database 
--WARNING: Do not run this in your production server
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO


--Include Actual Execution Plan (CTRL+M)
--Calling with 1057 again
--Look at 'Estimated number of rows' for 'Index Seek' operator, now we get 118.667
--Click to see properties of select operator and look at for parameter list
--Parameter compile with
--Parameter runtime value 
EXECUTE [dbo].[OrderID_by_ContactPersonID] @contactPersonID = 1057;

