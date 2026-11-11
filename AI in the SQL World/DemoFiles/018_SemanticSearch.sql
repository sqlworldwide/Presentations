/************************************************************
018_SemanticSearch.sql
Demo 2 - a vector is a column, T-SQL asks a model for one; search by meaning vs keyword search (about 6 min)
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 10, 2026

Learn: the VECTOR type and vector functions are GA on SQL Server 2025, as are
AI_GENERATE_EMBEDDINGS and CREATE EXTERNAL MODEL (Preview features FAQ).
AI_GENERATE_EMBEDDINGS sends the text to the model's endpoint over HTTPS (TLS only).
Learn: VECTOR_DISTANCE is always exact and does not use a vector index.
Cosine distance runs from 0 (identical) to 2 (opposing); smaller means closer.
************************************************************/

USE [AdventureWorks2025];
GO

/*
1. The pre-built table: 504 products, each with its text and a vector.
   Say: the vector is an ordinary column in an ordinary table.
   Point at SearchText: name + subcategory + description.
   The WHERE skips products with only a name (parts such as Blade).
*/
SELECT TOP (5)
  ProductID,
  SearchText,
  embedding
FROM dbo.ProductEmbedding
WHERE LEN(SearchText) > 100
ORDER BY ProductID;
GO

/*
2. The model is a database object. The endpoint and key (a database scoped credential)
   stay out of the query.
*/
SELECT
  name,
  api_format,
  model,
  location
FROM sys.external_models;
GO

/*
3. Ask for what you mean. The phrase never says helmet.
   Select all of it and run it as one batch:
   a. The live call, from T-SQL, to the model in Azure AI Foundry. Line to land: no Python, no app code - one function call.
   b. Show the vector.
   c. The exact search: VECTOR_DISTANCE scores every row, ORDER BY keeps the 10 smallest.
      Every row is read, so the result is exact. Cosine distance: 0 to 2, smaller means closer.
   No answer from the endpoint in 20 seconds: stop and swap the DECLARE below for this line
   (the vector was cached in 016).
--DECLARE @qv vector(1536) = (SELECT embedding FROM dbo.PhraseEmbedding WHERE phrase = N'protect my head if I fall off');
*/
DECLARE @qv vector(1536) =
  AI_GENERATE_EMBEDDINGS(N'protect my head if I fall off' USE MODEL Ada2Embeddings);

SELECT @qv AS query_vector;

SELECT TOP (10)
  ProductID,
  SearchText,
  VECTOR_DISTANCE('cosine', @qv, embedding) AS distance
FROM dbo.ProductEmbedding
ORDER BY distance;
GO

/*
4. The limit of keyword search. One long question, in the words a person would use.
   Three queries on Production.ProductDescription (full-text index from 016). Run one at a time:
   a. LIKE needs the exact text.
   b. CONTAINS needs an exact phrase.
   c. FREETEXT is as close as full-text gets to a sentence.
   Say what comes back, then run step 5 for the same question.
*/
SELECT
  ProductDescriptionID,
  Description
FROM Production.ProductDescription
WHERE Description LIKE N'%pillow-y%';
GO

SELECT
  ProductDescriptionID,
  Description
FROM Production.ProductDescription
WHERE CONTAINS(Description, N'"zero buzz"');
GO

SELECT
  ProductDescriptionID,
  Description
FROM Production.ProductDescription
WHERE FREETEXT(Description, N'I want a gliding, pillow-y feel on battered streets, zero buzz through the hands');
GO

/*
5. The same question, by meaning. Another live call.
   Offline fallback: swap the DECLARE below for this line (cached in 016).
--DECLARE @qv vector(1536) = (SELECT embedding FROM dbo.PhraseEmbedding WHERE phrase = N'I want a gliding, pillow-y feel on battered streets, zero buzz through the hands');
*/
DECLARE @qv vector(1536) =
  AI_GENERATE_EMBEDDINGS(N'I want a gliding, pillow-y feel on battered streets, zero buzz through the hands' USE MODEL Ada2Embeddings);

SELECT TOP (10)
  ProductID,
  SearchText,
  VECTOR_DISTANCE('cosine', @qv, embedding) AS distance
FROM dbo.ProductEmbedding
ORDER BY distance;
GO
