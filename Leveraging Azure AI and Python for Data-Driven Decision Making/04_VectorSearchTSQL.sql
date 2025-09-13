/*
04_VectorSearchTSQL

Author: Taiob Ali
Contact: taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified: September 10, 2025
Create a function to create embeddings. You will need to change the the url and api-key value.

An embedding is a special format of data representation that machine learning models and algorithms can easily use. 
The embedding is an information dense representation of the semantic meaning of a piece of text. 
Each embedding is a vector of floating-point numbers, such that the distance between two embeddings in the vector space is correlated with semantic similarity between two inputs in the original format. 
For example, if two texts are similar, then their vector representations should also be similar.
*/
CREATE OR ALTER PROCEDURE dbo.create_embeddings
@inputText nvarchar(max),
@embedding vector(1536) OUT
AS
DECLARE @url nvarchar(4000) = N'https://ta-openai2.openai.azure.com/openai/deployments/ta-model-text-embedding-ada-002/embeddings?api-version=2023-05-15';

DECLARE @headers nvarchar(300) = N'{"api-key": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}';

DECLARE @message nvarchar(max);
DECLARE @payload nvarchar(max) = N'{"input": "' + @inputText + '"}';
DECLARE @retval int, @response nvarchar(max);

exec @retval = sp_invoke_external_rest_endpoint 
    @url = @url,
    @method = 'POST',
    @headers = @headers,
    @payload = @payload,
    @timeout = 230,
    @response = @response output;

DECLARE @re vector(1536);
IF (@retval = 0) 
	BEGIN
    SET @re = cast(json_query(@response, '$.result.data[0].embedding') AS vector(1536))
	END ELSE BEGIN
	DECLARE @msg nvarchar(max) =  
			'Error calling OpenAI API' + char(13) + char(10) + 
			'[HTTP Status: ' + json_value(@response, '$.response.status.http.code') + '] ' +
			json_value(@response, '$.result.error.message');
	THROW 50000, @msg, 1;
END

SET @embedding = @re;

RETURN @retval
GO


/*
A function to clean up your data (My colleague Howard Dunn wrote this )
Do not execute this cell during live demo.
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[cleanString] (@str NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @i INT = 1
    DECLARE @cleaned NVARCHAR(MAX) = ''

    WHILE @i <= LEN(@str)
    BEGIN
        IF SUBSTRING(@str, @i, 1) LIKE '[a-zA-Z0-9 .,!?]'
            SET @cleaned = @cleaned + SUBSTRING(@str, @i, 1)
        SET @i = @i + 1
    END

    RETURN @cleaned
END
GO

SELECT
    sku, 
    brand, 
    review_count, 
    trim(dbo.cleanString(description)) as description, 
    product_id, 
    product_name, 
    root_category_name, 
    unit_price, 
    unit, aisle, 
    free_returns, 
    discount, id
INTO dbo.walmartProductsNew
FROM [dbo].[walmart-products]
GO

/*
Creating a table to store the embeddings
*/
DROP TABLE IF EXISTS  vectorTable
SELECT TOP 250 ID, product_name, sku, brand, review_count, description
INTO dbo.vectortable
FROM [dbo].[walmartProducts]
WHERE ID not IN (2, 7)
ORDER BY [ID]
GO

/*
Creating a vector column to store the embeddings
*/
ALTER TABLE vectorTable
ADD description_vector vector(1536) NULL;
GO

DECLARE @i int = 1;
DECLARE @text nvarchar(max);
DECLARE @vector vector(1536);

while @i <= 1000
    BEGIN
    SET @text = (SELECT isnull([product_name],'') + ': ' + isnull([brand],'')+': ' + isnull([description],'' ) 
	  FROM dbo.vectortable 
	  WHERE ID = @i);

    IF(@text <> '')
        BEGIN TRY
          exec dbo.create_embeddings @text, @vector OUTPUT;
          update dbo.vectortable set [description_vector ] = @vector WHERE ID= @i;
        END TRY
        BEGIN CATCH
          SELECT ERROR_NUMBER() AS ErrorNumber,
          ERROR_MESSAGE() AS ErrorMessage;
        END CATCH
    
    SET @i = @i + 1;
END


DECLARE @id INT
DECLARE @text NVARCHAR(MAX)
DECLARE @vector VECTOR(1536)

DECLARE row_cursor CURSOR FOR
SELECT 
  ID, 
  ISNULL(product_name, '') + ': ' + ISNULL(brand, '') + ': ' + ISNULL(description, '') AS text
FROM dbo.vectortable

OPEN row_cursor
FETCH NEXT FROM row_cursor INTO @id, @text

WHILE @@FETCH_STATUS = 0
BEGIN
	IF (@text <> '')
	BEGIN TRY
	EXEC dbo.create_embeddings @text, @vector OUTPUT
	UPDATE dbo.vectortable 
	SET description_vector = @vector 
	WHERE ID = @id
	END TRY
	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_MESSAGE() AS ErrorMessage
	END CATCH
  FETCH NEXT FROM row_cursor INTO @id, @text
END

CLOSE row_cursor
DEALLOCATE row_cursor


/*
Cleaning up the vector table by removing rows with NULL vectors
*/
DELETE FROM dbo.vectortable WHERE description_vector IS NULL
SELECT Count(*) FROM dbo.vectortable
SELECT TOP 10 * FROM dbo.vectortable

/*
  DECLARE the search text
  DECLARE a variable to hold the search vector
*/
DECLARE @search_text NVARCHAR(MAX) = 'help me plan a high school graduation party'
DECLARE @search_vector VECTOR(1536)

/*
  GENERATE the search vector using the 'create_embeddings' stored procedure
*/
EXEC dbo.create_embeddings @search_text, @search_vector OUTPUT

/*
  PERFORM the search query
  CALCULATE the cosine distance between the search vector and product description vectors
  ORDER BY the closest distance
*/
SELECT TOP(10) 
  product_name, 
  brand, 
  DESCRIPTION,
  vector_distance('cosine', @search_vector, description_vector) AS distance
FROM [dbo].[vectorTable]
WHERE vector_distance('cosine', @search_vector, description_vector) IS NOT NULL
ORDER BY distance

/*
### Filtered Semantic Search with SQL

[](https:\github.com\AzureSQLDB\GenAILab\blob\main\docs\4-filtered-semantic-search.md#filtered-semantic-search-with-sql)

This section explains how to implement a Filtered Search query in SQL. Hybrid Search combines traditional SQL queries with vector-based search capabilities to enhance search results.

### SQL Query for Hybrid Search

[](https:\github.com\AzureSQLDB\GenAILab\blob\main\docs\4-filtered-semantic-search.md#sql-query-for-hybrid-search)

The following SQL script demonstrates a hybrid search in an SQL database. It uses vector embeddings to find the most relevant products based on a textual description and combines with the availability of free returns
*/

/*
  DECLARE the search text
  DECLARE a variable to hold the search vector
*/
DECLARE @search_text NVARCHAR(MAX) = 'help me plan a high school graduation party' 
DECLARE @search_vector VECTOR(1536)

/*
  GENERATE the search vector using the 'create_embeddings' stored procedure
*/
EXEC dbo.create_embeddings @search_text, @search_vector OUTPUT

/*
  PERFORM the search query
  CALCULATE the cosine distance between the search vector and product description vectors
  ORDER BY the closest distance plus filter for free returns
*/
SELECT TOP(10) 
  vt.product_name, 
  vt.brand, 
  vt.DESCRIPTION,
  vector_distance('cosine', @search_vector, description_vector) AS distance
FROM [dbo].[vectorTable] AS vt
JOIN dbo.walmartProducts AS wpn
  ON vt.id = wpn.id
WHERE vector_distance('cosine', @search_vector, description_vector) IS NOT NULL
  AND wpn.free_returns = 'Free 30-day returns'
ORDER BY distance