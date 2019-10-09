USE AdventureWorks;
GO
SET QUOTED_IDENTIFIER ON
WHILE(1=1)
BEGIN
SELECT 
	     [BusinessEntityID]
      ,[TotalPurchaseYTD]
      ,[DateFirstPurchase]
      ,[BirthDate]
      ,[MaritalStatus]
      ,[YearlyIncome]
      ,[Gender]
      ,[TotalChildren]
      ,[NumberChildrenAtHome]
      ,[Education]
      ,[Occupation]
      ,[HomeOwnerFlag]
      ,[NumberCarsOwned]
  FROM [AdventureWorks].[Sales].[vPersonDemographics]
  ORDER BY BusinessEntityID;
END