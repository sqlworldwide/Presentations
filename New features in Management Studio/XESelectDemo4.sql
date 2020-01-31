--This query is copied form Adam Machanic's 'Five Query Plan Culprits' training class
USE AdventureWorks;
GO
WHILE(1=1)
BEGIN
SELECT TOP(500) WITH TIES
	ProductId,
	ActualCost
FROM
(

	SELECT
		ProductId,
		ActualCost,
		ROW_NUMBER() OVER
		(
			PARTITION BY
				ProductId
			ORDER BY
				ActualCost DESC
		) AS r
	FROM bigTransactionHistory
	WHERE
		ActualCost >= 5000
		AND ProductId BETWEEN 1000 AND 20000
) AS x
WHERE
	x.r = 1
ORDER BY
	x.ActualCost DESC
END
