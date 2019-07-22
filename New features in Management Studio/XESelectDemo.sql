USE AdventureWorks;
GO
WHILE(1=1)
BEGIN
	SELECT *
	FROM Production.Product
	ORDER BY Name ASC;
END