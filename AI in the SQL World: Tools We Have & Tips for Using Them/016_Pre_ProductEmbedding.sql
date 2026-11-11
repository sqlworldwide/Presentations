/************************************************************
016_Pre_ProductEmbedding.sql
Demo 2 setup - embed the 504 products ahead of time
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 4, 2026

Needs 015. Safe to re-run: it drops and rebuilds dbo.ProductEmbedding and dbo.PhraseEmbedding.
It makes one model call per row (about 2.5 minutes for 504 rows), so back up the database
afterwards (step 7) and restore instead of re-running.
************************************************************/

USE [AdventureWorks2025];
GO

/*
1. Drop the table if it exists, then create it. Dropping also removes the vector index from 019.
   SearchText is the text we embed: name + subcategory + description. A missing part is skipped.
   Parts such as Blade and Bearing Ball have no subcategory or description, so only the name is embedded.
*/
DROP TABLE IF EXISTS dbo.ProductEmbedding;
GO

CREATE TABLE dbo.ProductEmbedding
(
  ProductID  int            NOT NULL CONSTRAINT PK_ProductEmbedding PRIMARY KEY,
  Color      nvarchar(15)   NULL,
  SearchText nvarchar(1000) NOT NULL,
  embedding  vector(1536)   NULL
);
GO

/*
2. Load all 504 products with their text. The vectors come next.
*/
INSERT INTO dbo.ProductEmbedding
(
  ProductID,
  Color,
  SearchText
)
SELECT
  p.ProductID,
  p.Color,
  LEFT(CONCAT_WS(N'. ', p.Name, psc.Name, pd.Description), 1000)
FROM Production.Product AS p
LEFT JOIN Production.ProductSubcategory AS psc
  ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Production.ProductModelProductDescriptionCulture AS pmx
  ON  p.ProductModelID = pmx.ProductModelID
  AND pmx.CultureID = N'en'
LEFT JOIN Production.ProductDescription AS pd
  ON pmx.ProductDescriptionID = pd.ProductDescriptionID;
GO

/*
3. Embed in batches of 50 (Learn: AI_GENERATE_EMBEDDINGS can be used in an UPDATE).
   If the endpoint fails part way, run this step again and it carries on.
   The pass limit stops a loop if a call returns NULL.
   Run time on my laptop: 2:25 minutes for 504 rows
*/
SET NOCOUNT ON;

DECLARE @pass int = 0;

WHILE EXISTS (SELECT 1 FROM dbo.ProductEmbedding WHERE embedding IS NULL) AND @pass < 20
BEGIN
  UPDATE TOP (50) dbo.ProductEmbedding
  SET embedding = AI_GENERATE_EMBEDDINGS(SearchText USE MODEL Ada2Embeddings)
  WHERE embedding IS NULL;

  SET @pass += 1;
  RAISERROR(N'  pass %d done', 0, 1, @pass) WITH NOWAIT;
END;
GO

/*
4. Check: total_rows should be 504 and still_null 0.
*/
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN embedding IS NULL THEN 1 ELSE 0 END) AS still_null
FROM dbo.ProductEmbedding;
GO

/*
5. Cache the demo phrase's vector, as an offline fallback if the endpoint is unreachable on stage.
   018 and 019 show the fallback line.
*/
DROP TABLE IF EXISTS dbo.PhraseEmbedding;
GO

CREATE TABLE dbo.PhraseEmbedding
(
  phrase    nvarchar(200) NOT NULL CONSTRAINT PK_PhraseEmbedding PRIMARY KEY,
  embedding vector(1536)  NOT NULL
);
GO

INSERT INTO dbo.PhraseEmbedding
(
  phrase,
  embedding
)
VALUES
(
  N'protect my head if I fall off',
  AI_GENERATE_EMBEDDINGS(N'protect my head if I fall off' USE MODEL Ada2Embeddings)
),
(
  N'I want a gliding, pillow-y feel on battered streets, zero buzz through the hands',
  AI_GENERATE_EMBEDDINGS(N'I want a gliding, pillow-y feel on battered streets, zero buzz through the hands' USE MODEL Ada2Embeddings)
);
GO

/*
6. Full-text index on Production.ProductDescription, for the keyword-search comparison in 018.
   Drop and recreate, so the script can be re-run. The catalog fills in the background:
   the check at the end shows 0 when it is done.
*/
IF 1 <> ISNULL(CONVERT(int, FULLTEXTSERVICEPROPERTY('IsFullTextInstalled')), 0)
  THROW 50002, N'Full-Text Search is not installed on this instance.', 1;
GO

IF EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'Production.ProductDescription'))
  DROP FULLTEXT INDEX ON Production.ProductDescription;
GO

IF EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'FTC_AdventureWorks')
  DROP FULLTEXT CATALOG FTC_AdventureWorks;
GO

CREATE FULLTEXT CATALOG FTC_AdventureWorks;
GO

CREATE FULLTEXT INDEX ON Production.ProductDescription
(
  Description LANGUAGE 1033
)
KEY INDEX PK_ProductDescription_ProductDescriptionID
ON FTC_AdventureWorks
WITH (CHANGE_TRACKING = AUTO, STOPLIST = SYSTEM);
GO

/*
7. Check the full-text population. PopulateStatus 0 = idle (done). Run again until it shows 0.
*/
SELECT
  FULLTEXTCATALOGPROPERTY(N'FTC_AdventureWorks', 'PopulateStatus') AS populate_status,
  FULLTEXTCATALOGPROPERTY(N'FTC_AdventureWorks', 'ItemCount')      AS item_count;
GO

/*
8. Optional: back up now, so 001 or a restore never needs 504 new model calls.
   --BACKUP DATABASE [AdventureWorks2025] TO DISK = N'C:\Presentations\PassSummit2026\AI in the SQL World\DemoFiles\AdventureWorks2025_WithVectors.bak' WITH INIT, COMPRESSION;
*/
