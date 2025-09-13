/*
08_SQL2025OpenAIVectorSearch

Author: Taiob Ali
Contact: taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified: September 10, 2025

Credit:
https://github.com.mcas.ms/microsoft/bobsql/tree/master/demos/sqlserver2025/AI/azureopenai
https://learn.microsoft.com/en-us/sql/t-sql/functions/ai-generate-embeddings-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/functions/vector-search-transact-sql
*/

/*
This will enable the REST API support for the system procedure sp_invoke_external_rest_endpoint using sp_configure.
*/
USE master;
GO
sp_configure 'external rest endpoint enabled', 1;
GO
RECONFIGURE WITH OVERRIDE;
GO

/*
Download backup 
from: https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak
to: C:\Program Files\Microsoft SQL Server\MSSQL17.SQL2025\MSSQL\Backup

Restore the backup as AdventureWorks
*/

USE [master]
GO
DECLARE @dbname nvarchar(128)
SET @dbname = N'AdventureWorks'

IF (EXISTS (SELECT name 
FROM master.dbo.sysdatabases 
WHERE ('[' + name + ']' = @dbname 
OR name = @dbname)))
BEGIN
ALTER DATABASE [AdventureWorks] SET RESTRICTED_USER;
END
GO
RESTORE DATABASE [AdventureWorks] FROM  
DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL17.SQL2025\MSSQL\Backup\AdventureWorks2022.bak'
WITH MOVE 'AdventureWorks2022' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.SQL2025\MSSQL\DATA\AdventureWorks.mdf',
MOVE 'AdventureWorks2022_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.SQL2025\MSSQL\Log\AdventureWorks_log.ldf'
GO
ALTER AUTHORIZATION ON DATABASE::[AdventureWorks] TO [sa]
GO
ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 170
GO

/*
This script is used to create a database scoped credential to be used to communicate with the Azure AI model using an API key. 
Using the Azure AI Foundry user interface in the Azure Portal, 
select the text-embedding-ada-002 model and copy the API key from the Endpoint definition. 
You will need to make a few edits.

* Replace the <pwd> in the script with a strong password inside the quotes.
* Replace the <apikey> in the script with the API key from your Azure AI model deployment inside the quotes
* Replace the <azureai> in the script with the hostname portion of your endpoint. 
  For example, if your endpoint is https://productsopenai.openai.azure.com/openai/deployments/text-embedding-ada-002/embeddings?api-version=2023-05-15 the hostname would be https://productsopenai.openai.azure.com inside the quotes or brackets.
*/


USE [AdventureWorks];
GO
IF NOT EXISTS(SELECT * FROM sys.symmetric_keys WHERE [name] = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'strongPW';
END;
GO
IF EXISTS(SELECT * FROM sys.[database_scoped_credentials] WHERE NAME = 'https://ta-openai2.openai.azure.com')
BEGIN
	DROP DATABASE SCOPED CREDENTIAL [https://ta-openai2.openai.azure.com]
END
CREATE DATABASE SCOPED CREDENTIAL [https://ta-openai2.openai.azure.com]
WITH IDENTITY = 'HTTPEndpointHeaders', 
SECRET = 
'{"api-key": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}';
GO

/*
This script will create a table called ProductDescriptionEmbeddings with a vector column called Embedding.
Embeddings are generated based on the Description column in the ProductDescription table using the AI_GENERATE_EMBEDDINGS function. 
This table will have keys to be able to join with other tables in the database to help with vector searching.
*/

USE AdventureWorks;
GO
-- Create a new table to store embeddings
--
DROP TABLE IF EXISTS Production.ProductDescriptionEmbeddings;
GO
CREATE TABLE Production.ProductDescriptionEmbeddings
( 
  ProductDescEmbeddingID INT IDENTITY NOT NULL PRIMARY KEY CLUSTERED, -- Need a single column as cl index to support vector index reqs
  ProductID INT NOT NULL,
  ProductDescriptionID INT NOT NULL,
  ProductModelID INT NOT NULL,
  CultureID nchar(6) NOT NULL,
  Embedding vector(1536)
);

-- Create an external model to call the Azure OpenAI embeddings REST endpoint
CREATE EXTERNAL MODEL TaAzureOpenAiModel
WITH (
      LOCATION = 'https://ta-openai2.openai.azure.com/openai/deployments/ta-model-text-embedding-ada-002/embeddings?api-version=2023-05-15',
      API_FORMAT = 'Azure OpenAI',
      MODEL_TYPE = EMBEDDINGS,
      MODEL = 'ta-model-text-embedding-ada-002',
      CREDENTIAL = [https://ta-openai2.openai.azure.com]
);

/*
Run time in my laptop:1 min 10 seconds
Populate rows with embeddings
Need to make sure and only get Products that have ProductModels
*/
INSERT INTO Production.ProductDescriptionEmbeddings
SELECT p.ProductID, pmpdc.ProductDescriptionID, pmpdc.ProductModelID, pmpdc.CultureID, 
AI_GENERATE_EMBEDDINGS(pd.Description USE MODEL TaAzureOpenAiModel)
FROM Production.ProductModelProductDescriptionCulture pmpdc
JOIN Production.Product p
ON pmpdc.ProductModelID = p.ProductModelID
JOIN Production.ProductDescription pd
ON pd.ProductDescriptionID = pmpdc.ProductDescriptionID
ORDER BY p.ProductID;
GO

/*
Create an alternate key using an ncl index
*/
CREATE UNIQUE NONCLUSTERED INDEX [IX_ProductDescriptionEmbeddings_AlternateKey]
ON [Production].[ProductDescriptionEmbeddings]
(
    [ProductID] ASC,
    [ProductModelID] ASC,
    [ProductDescriptionID] ASC,
    [CultureID] ASC
);
GO

/*
https://learn.microsoft.com/en-us/sql/t-sql/functions/vector-search-transact-sql?view=sql-server-ver17
VECTOR_SEARCH (Transact-SQL) (Preview)
This function is in preview and is subject to change. In order to use this feature, you must enable the PREVIEW_FEATURES database scoped configuration.
*/

ALTER DATABASE SCOPED CONFIGURATION 
SET PREVIEW_FEATURES = ON;
GO

/*
This script will create a vector index on the Embedding column of the ProductDescriptionEmbeddings table. This index will be used to optimize vector searches against the embeddings stored in this table.
*/
USE [AdventureWorks];
GO
CREATE VECTOR INDEX product_vector_index 
ON Production.ProductDescriptionEmbeddings (Embedding)
WITH (METRIC = 'cosine', TYPE = 'diskann', MAXDOP = 8);
GO

/*
This script will create a stored procedure called find_relevant_products_vector_search that will execute a vector search against the ProductDescriptionEmbeddings table using the vector index created in the previous step. 
The stored procedure will take a natural language prompt as input, generate embeddings with AI_GENERATE_EMBEDDINGS() from the prompt, and return the top 10 most relevant products based on the vector search.
*/

USE [AdventureWorks];
GO

CREATE OR ALTER PROCEDURE [find_relevant_products_vector_search]
@prompt NVARCHAR(max), -- NL prompt
@stock SMALLINT = 500, -- Only show product with stock level of >= 500. User can override
@top INT = 10, -- Only show top 10. User can override
@min_similarity DECIMAL(19,16) = 0.3 -- Similarity level that user can change but recommend to leave default
AS
IF (@prompt is null) RETURN;

DECLARE @retval INT, @vector VECTOR(1536);

SELECT @vector = AI_GENERATE_EMBEDDINGS(@prompt USE MODEL TaAzureOpenAiModel)

IF (@retval != 0) RETURN;

SELECT 
 p.Name as ProductName, 
 pd.Description AS ProductDescription, 
 p.SafetyStockLevel AS StockLevel
FROM VECTOR_SEARCH(
	TABLE = [Production].[ProductDescriptionEmbeddings] AS t,
	COLUMN = [Embedding],
	SIMILAR_TO = @vector,
	 METRIC = 'cosine',
	TOP_N = @top
	) AS s
JOIN Production.ProductDescriptionEmbeddings pe
ON t.ProductDescEmbeddingID = pe.ProductDescEmbeddingID
JOIN Production.Product p
ON pe.ProductID = p.ProductID
JOIN Production.ProductDescription pd
ON pd.ProductDescriptionID = pe.ProductDescriptionID
WHERE (1-s.distance) > @min_similarity
AND p.SafetyStockLevel >= @stock
ORDER by s.distance;
GO

/*
You can now perform a vector search using the stored procedure. 
Load the script find_products_prompt_vector_search. 
In this script you can provide a natural language prompt with words and phrases that are not exactly in product descriptions. 
Vector search allows you to find similar results based on embeddings. Notice in the script examples are provided for mulitple languages and the results match the language of the prompt without changing any code because the embedding model used from Azure OpenAI is optimized for multiple languages. 
You can also use the TOP clause to limit the number of results returned. 
The default is 10. You can change this to any number you want.
*/
USE [AdventureWorks];
GO

EXEC find_relevant_products_vector_search
@prompt = N'Show me stuff for extreme outdoor sports',
@stock = 100, 
@top = 20;
GO

-- Do the same prompt but in Chinese
EXEC find_relevant_products_vector_search
@prompt = N'请向我展示极限户外运动的装备',
@stock = 100,
@top = 20;
GO


