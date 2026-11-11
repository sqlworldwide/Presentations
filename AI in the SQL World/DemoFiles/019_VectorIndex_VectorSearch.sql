/************************************************************
019_VectorIndex_VectorSearch.sql
Demo 2 - vector index and VECTOR_SEARCH (about 6 min)
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 10, 2026

Needs 015 and 016.
Learn: the vector index and VECTOR_SEARCH are preview on SQL Server 2025 (the PREVIEW_FEATURES
database scoped configuration must be ON). They are GA in Azure SQL Database, SQL database in
Fabric and Azure SQL Managed Instance with the Always-up-to-date policy.
Learn: while the vector index exists the table is read-only, so load rows first and index last.
************************************************************/

USE [AdventureWorks2025];
GO

/*
1. Turn the preview feature on (SQL Server 2025 only). Say: this is the line your change board will ask about.
*/
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

/*
2. Build the index. Learn: the table needs at least 100 rows with non-NULL vectors
   (otherwise Msg 42266). 504 is enough.
   The metric in the index must match the metric in VECTOR_SEARCH.
*/
DROP INDEX IF EXISTS ix_ProductEmbedding_embedding ON dbo.ProductEmbedding;
GO

CREATE VECTOR INDEX ix_ProductEmbedding_embedding
  ON dbo.ProductEmbedding (embedding)
  WITH (METRIC = 'cosine', TYPE = 'DiskANN');
GO

/*
3. The index we just built. Learn's check reads the version from build_parameters; 3 is the latest version.
   On my CU10 instance build_parameters has no Version value (StartId, L, M, R only), so index_version is NULL
   and the index is not version 3. The searches below use TOP_N.
*/
SELECT
  i.name                                      AS index_name,
  t.name                                      AS table_name,
  JSON_VALUE(v.build_parameters, '$.Version') AS index_version,
  v.build_parameters
FROM sys.vector_indexes AS v
INNER JOIN sys.indexes AS i
  ON  v.object_id = i.object_id
  AND v.index_id  = i.index_id
INNER JOIN sys.tables AS t
  ON v.object_id = t.object_id
WHERE v.object_id = OBJECT_ID(N'dbo.ProductEmbedding');
GO

/*
4. Approximate search with the index. TOP_N tells VECTOR_SEARCH how many rows to return.
   Learn marks TOP_N deprecated and points to SELECT TOP (N) WITH APPROXIMATE:
   https://learn.microsoft.com/sql/t-sql/functions/vector-search-transact-sql
   Learn: "The latest version of vector indexes is available in Azure SQL Database, SQL database in Microsoft Fabric,
   and Azure SQL Managed Instance with the Always-up-to-date update policy."
   https://learn.microsoft.com/sql/t-sql/statements/create-vector-index-transact-sql
   On SQL Server 2025 RTM-CU10 the new syntax is not recognized (Msg 102, near 'APPROXIMATE'), so TOP_N is the form that works here.
   Offline fallback: swap the DECLARE below for this line (cached in 016).
--DECLARE @qv vector(1536) = (SELECT embedding FROM dbo.PhraseEmbedding WHERE phrase = N'protect my head if I fall off');
*/
DECLARE @qv vector(1536) =
  AI_GENERATE_EMBEDDINGS(N'protect my head if I fall off' USE MODEL Ada2Embeddings);

SELECT TOP (10)
  t.ProductID,
  t.SearchText,
  r.distance
FROM VECTOR_SEARCH
(
  TABLE = dbo.ProductEmbedding AS t,
  COLUMN = embedding,
  SIMILAR_TO = @qv,
  METRIC = 'cosine',
  TOP_N = 10
) AS r
ORDER BY r.distance;
GO

/*
5. Keep your WHERE clause. Learn: the search returns the top k first and
   the predicate is applied after, so you can get fewer rows, or none. Compare the rows with step 4.
   Line to land: we asked for 10 rows and got 1. The filter ran after the top 10 were picked.
*/
DECLARE @qv vector(1536) =
  AI_GENERATE_EMBEDDINGS(N'protect my head if I fall off' USE MODEL Ada2Embeddings);

SELECT TOP (10)
  t.ProductID,
  t.Color,
  t.SearchText,
  r.distance
FROM VECTOR_SEARCH
(
  TABLE = dbo.ProductEmbedding AS t,
  COLUMN = embedding,
  SIMILAR_TO = @qv,
  METRIC = 'cosine',
  TOP_N = 10
) AS r
WHERE t.Color = N'Black'
ORDER BY r.distance;
GO

/*
6. A metric that does not match the index.
   The index was built with cosine, so this euclidean search finds no index.
   Expect Msg 42227: Cannot find a vector index with metric 'euclidean' on column 'embedding'.
   Line to land: the metric in the query must match the metric of the index.
   Learn describes a warning followed by an exact search (METRIC argument):
   https://learn.microsoft.com/sql/t-sql/functions/vector-search-transact-sql
   On this server, SQL Server 2025 RTM-CU10, it is an error.
*/
DECLARE @qv vector(1536) =
  AI_GENERATE_EMBEDDINGS(N'protect my head if I fall off' USE MODEL Ada2Embeddings);

SELECT TOP (10)
  t.ProductID,
  t.SearchText,
  r.distance
FROM VECTOR_SEARCH
(
  TABLE = dbo.ProductEmbedding AS t,
  COLUMN = embedding,
  SIMILAR_TO = @qv,
  METRIC = 'euclidean',
  TOP_N = 10
) AS r
ORDER BY r.distance;
GO

/*
7. How many times did SQL Server call Foundry? Every VECTOR_SEARCH above embedded the question first.
   Line to land: the index is local, but each search still sends the question text to the model.
   The session is EmbeddingCalls, started in 015. Learn: ai_generate_embeddings_summary holds the REST request
   and response (status code, errors, model name); external_rest_endpoint_summary adds detail for troubleshooting.
   Check the XML on screen before you present: make sure it shows nothing you do not want on a projector.
   a. The count per event.
*/
DECLARE @file nvarchar(260) =
(
  SELECT
    CAST(t.target_data AS xml).value('(EventFileTarget/File/@name)[1]', 'nvarchar(260)')
  FROM sys.dm_xe_sessions AS s
  INNER JOIN sys.dm_xe_session_targets AS t
    ON t.event_session_address = s.address
  WHERE s.name = N'EmbeddingCalls'
    AND t.target_name = N'event_file'
);
/* The current file is ...\EmbeddingCalls_0_<timestamp>.xel. This reads all files: ...\EmbeddingCalls*.xel */
SET @file = LEFT(@file, LEN(@file) - CHARINDEX(N'_', REVERSE(@file), CHARINDEX(N'_', REVERSE(@file)) + 1)) + N'*.xel';

SELECT
  y.event_name,
  COUNT(*)              AS events,
  MAX(y.event_time_utc) AS last_event_utc
FROM
(
  SELECT
    x.e.value('(event/@name)[1]', 'nvarchar(100)')     AS event_name,
    x.e.value('(event/@timestamp)[1]', 'datetime2(3)') AS event_time_utc
  FROM
  (
    SELECT
      CAST(event_data AS xml) AS e
    FROM sys.fn_xe_file_target_read_file(@file, NULL, NULL, NULL)
  ) AS x
) AS y
GROUP BY y.event_name;
GO

/*
b. The 2 newest rows of each event, with every field as name=value (long values cut at 80 characters).
   Click event_xml for the full event. Say: this is the traffic from SQL Server to Foundry.
*/
DECLARE @file nvarchar(260) =
(
  SELECT
    CAST(t.target_data AS xml).value('(EventFileTarget/File/@name)[1]', 'nvarchar(260)')
  FROM sys.dm_xe_sessions AS s
  INNER JOIN sys.dm_xe_session_targets AS t
    ON t.event_session_address = s.address
  WHERE s.name = N'EmbeddingCalls'
    AND t.target_name = N'event_file'
);
/* The current file is ...\EmbeddingCalls_0_<timestamp>.xel. This reads all files: ...\EmbeddingCalls*.xel */
SET @file = LEFT(@file, LEN(@file) - CHARINDEX(N'_', REVERSE(@file), CHARINDEX(N'_', REVERSE(@file)) + 1)) + N'*.xel';

SELECT
  d.event_name,
  d.event_time_utc,
  d.e.value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(256)')         AS host_name,
  d.e.value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(256)')         AS program,
  d.e.value('(event/action[@name="server_principal_name"]/value)[1]', 'nvarchar(256)')   AS login_name,
  f.details,
  d.e AS event_xml
FROM
(
  SELECT
    y.e,
    y.event_name,
    y.event_time_utc,
    ROW_NUMBER() OVER (PARTITION BY y.event_name ORDER BY y.event_time_utc DESC) AS rn
  FROM
  (
    SELECT
      x.e,
      x.e.value('(event/@name)[1]', 'nvarchar(100)')     AS event_name,
      x.e.value('(event/@timestamp)[1]', 'datetime2(3)') AS event_time_utc
    FROM
    (
      SELECT
        CAST(event_data AS xml) AS e
      FROM sys.fn_xe_file_target_read_file(@file, NULL, NULL, NULL)
    ) AS x
  ) AS y
) AS d
CROSS APPLY
(
  SELECT
    STRING_AGG(n.v.value('@name', 'nvarchar(100)') + N'=' + LEFT(COALESCE(n.v.value('(value)[1]', 'nvarchar(max)'), N''), 80), N'; ') AS details
  FROM d.e.nodes('event/data') AS n(v)
) AS f
WHERE d.rn <= 2
ORDER BY d.event_name, d.event_time_utc DESC;
GO

/*
Q&A, not part of the demo: how do you know the approximate search is right?
Recall is how many of the exact top 10 the index also found. Run both on the same vector
and count the overlap. 1.00 means the same 10 rows. Select the lines below and uncomment them
(the vector is the one cached in 016, so there is no model call).
--DECLARE @qv vector(1536) = (SELECT embedding FROM dbo.PhraseEmbedding WHERE phrase = N'protect my head if I fall off');

WITH exact AS
(
  SELECT TOP (10) ProductID
  FROM dbo.ProductEmbedding
  ORDER BY VECTOR_DISTANCE('cosine', @qv, embedding)
),
approx AS
(
  SELECT t.ProductID
  FROM VECTOR_SEARCH
  (
    TABLE = dbo.ProductEmbedding AS t,
    COLUMN = embedding,
    SIMILAR_TO = @qv,
    METRIC = 'cosine',
    TOP_N = 10
  ) AS r
)
SELECT CAST(COUNT(*) * 1.0 / NULLIF((SELECT COUNT(*) FROM exact), 0) AS decimal(4, 2)) AS recall
FROM exact
INNER JOIN approx
  ON approx.ProductID = exact.ProductID;
GO
*/

/*
8. To reset, run 001_Reset_Demo.sql.
*/
