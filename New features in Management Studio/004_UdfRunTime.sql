/*
Script Name:004_UdfRunTime.sql
DEMO:
	UdfCpuTime and UdfElapsedTime (SQL2016 SP2, Need New SSMS)
	New attribute "ContainsInlineScalarTsqludfs" when inline scalar UDF feature is enabled
Script copied form:
https://blogs.msdn.microsoft.com/sql_server_team/more-showplan-enhancements-udfs/
*/

/*
Run this in SQL2017 and then in SQL2019
Create UDF
*/

USE [AdventureWorks];
GO
DROP FUNCTION IF EXISTS ufn_CategorizePrice;
GO
CREATE FUNCTION ufn_CategorizePrice(@Price money)
RETURNS NVARCHAR(50)
AS
BEGIN
  DECLARE @PriceCategory NVARCHAR(50)

  IF @Price < 100 SELECT @PriceCategory = 'Cheap'
  IF @Price BETWEEN 101 and 500 SELECT @PriceCategory =  'Mid Price'
  IF @Price BETWEEN 501 and 1000 SELECT @PriceCategory =  'Expensive'
  IF @Price > 1001 SELECT @PriceCategory =  'Unaffordable'
  RETURN @PriceCategory 
END;
GO

--Changing compatibility level to SQL 2017
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; 
GO

--Turn on Actual Execution Plan (Ctrl+M)
--Look at the properties of root node. Expand QueryTimeStats node
--You will two new attributes 'UdfCpuTime' and 'UdfElapsedTime' 
USE [AdventureWorks];
GO
SELECT 
  dbo.ufn_CategorizePrice(UnitPrice) AS [AffordAbility], 
  SalesOrderID, SalesOrderDetailID, 
  CarrierTrackingNumber, OrderQty, 
  ProductID, SpecialOfferID, 
  UnitPrice, UnitPriceDiscount, 
  LineTotal, rowguid, ModifiedDate 
FROM Sales.SalesOrderDetail;
GO

--Changing compatibility level to SQL 2019
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 150; 
GO

--Turn on Actual Execution Plan (Ctrl+M)
--Look at the properties of root node. 
--You will NOT see the attributes 'UdfCpuTime' and 'UdfElapsedTime' as we saw in 2017
--Rather you will see a new one 'ContainsInlineScalarTsqludfs=True' under Misc
USE [AdventureWorks];
GO
SELECT 
  dbo.ufn_CategorizePrice(UnitPrice) AS [AffordAbility], 
  SalesOrderID, SalesOrderDetailID, 
  CarrierTrackingNumber, OrderQty, 
  ProductID, SpecialOfferID, 
  UnitPrice, UnitPriceDiscount, 
  LineTotal, rowguid, ModifiedDate 
FROM Sales.SalesOrderDetail;
GO