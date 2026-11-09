/************************************************************
002_Pre_SlowQueryWorkload.sql
Prep - build slow-query history in Query Store for 007
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 4, 2026

NON-PRODUCTION ONLY: it runs intentionally expensive queries.
************************************************************/

USE [master];
GO

/*
1. Confirm the server, the database and the Query Store state.
*/
SELECT @@SERVERNAME AS ConnectedServer;
GO

SELECT
  d.name,
  d.state_desc,
  d.compatibility_level,
  d.is_query_store_on
FROM sys.databases AS d
WHERE d.name = N'AdventureWorks2025';
GO

/*
2. Query Store must be ON: the slow-query skill reads it.
*/
ALTER DATABASE [AdventureWorks2025]
SET QUERY_STORE = ON;
GO

/*
3. Optional reset for a clean rerun. WARNING: clears the Query Store history for this database.
--ALTER DATABASE [AdventureWorks2025] SET QUERY_STORE CLEAR ALL;
*/

USE [AdventureWorks2025];
GO

/*
4. Generate the workload: slow queries for Query Store to record.
   Fast rehearsal: @LoopA = 6,  @LoopB = 3
   Full run:       @LoopA = 25, @LoopB = 12
*/
DECLARE @LoopA int = 25;
DECLARE @LoopB int = 12;

BEGIN TRY
  SET NOCOUNT ON;

  /* Workload A: a non-sargable filter (CPU and reads) */
  DECLARE @iA int = 0;
  WHILE @iA < @LoopA
  BEGIN
    SELECT
      sod.ProductID,
      SUM(sod.LineTotal) AS TotalSales
    FROM Sales.SalesOrderDetail AS sod
    INNER JOIN Production.Product AS p
      ON p.ProductID = sod.ProductID
    WHERE LEFT(p.Name, 1) = N'A'  -- intentionally non-sargable
    GROUP BY sod.ProductID
    ORDER BY TotalSales DESC;

    SET @iA += 1;
  END;

  /* Workload B: a heavier join, sort and hash */
  DECLARE @iB int = 0;
  WHILE @iB < @LoopB
  BEGIN
    WITH d AS
    (
      SELECT TOP (6000)
        SalesOrderID,
        ProductID,
        LineTotal
      FROM Sales.SalesOrderDetail
      ORDER BY SalesOrderID DESC
    )
    SELECT
      d1.ProductID,
      COUNT_BIG(*) AS PairCount,
      SUM(d1.LineTotal + d2.LineTotal) AS TotalValue
    FROM d AS d1
    INNER JOIN d AS d2
      ON d1.ProductID = d2.ProductID
    GROUP BY d1.ProductID
    ORDER BY TotalValue DESC;

    SET @iB += 1;
  END;
END TRY
BEGIN CATCH
  SELECT
    ERROR_NUMBER()   AS ErrorNumber,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_STATE()    AS ErrorState,
    ERROR_LINE()     AS ErrorLine,
    ERROR_MESSAGE()  AS ErrorMessage;
END CATCH;
GO


/*
5. Check that Query Store now holds the slow queries.
*/
SELECT TOP (10)
  qsq.query_id,
  SUM(rs.count_executions) AS total_executions,
  CAST(
    SUM(CONVERT(float, rs.avg_duration) * rs.count_executions)
    / NULLIF(SUM(rs.count_executions), 0)
    / 1000.0
    AS decimal(18,2)
  ) AS weighted_avg_duration_ms,
  LEFT(qst.query_sql_text, 100) AS query_text_100
FROM sys.query_store_query AS qsq
JOIN sys.query_store_query_text AS qst
  ON qsq.query_text_id = qst.query_text_id
JOIN sys.query_store_plan AS qsp
  ON qsq.query_id = qsp.query_id
JOIN sys.query_store_runtime_stats AS rs
  ON qsp.plan_id = rs.plan_id
GROUP BY qsq.query_id, qst.query_sql_text
ORDER BY weighted_avg_duration_ms DESC;
GO
