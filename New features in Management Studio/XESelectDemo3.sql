--This query is copied form Adam Machanic's 'Five Query Plan Culprits' training class
USE AdventureWorks;
GO
WHILE(1=1)
BEGIN
IF OBJECT_ID('tempdb..#products') IS NOT NULL DROP TABLE #products
SELECT 
	ProductId
INTO #products
FROM bigProduct
CROSS APPLY 
(
	SELECT 
		1

	UNION ALL

	SELECT
		2
	WHERE
		ProductId % 5 = 0

	UNION ALL

	SELECT
		3
	WHERE
		ProductId % 7 = 0
) x(m)
WHERE
	ProductId BETWEEN 1001 AND 12001
SELECT
	p.ProductId,
	AVG(x.ActualCost) AS AvgCostTop40
FROM #products AS p
CROSS APPLY
(
	SELECT
		t.*,
		ROW_NUMBER() OVER 
		(
			PARTITION BY 
				p.ProductId 
			ORDER BY 
				t.ActualCost DESC
		) AS r
	FROM bigTransactionHistory AS t 
	WHERE
		p.ProductId = t.ProductId
) AS x
WHERE
	x.r BETWEEN 1 AND 40
GROUP BY
	p.ProductId
END
