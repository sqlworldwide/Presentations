/************************************************************
015_Pre_ExternalModel.sql
Demo 2 setup - let SQL Server 2025 call an embedding model in Azure AI Foundry
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 9, 2026

Replace <your-resource>, <your-deployment>, <your-key> and <password> in your own copy.
Learn: the credential and model statements follow the Azure OpenAI (API key) example on the
CREATE EXTERNAL MODEL and AI_GENERATE_EMBEDDINGS pages. Only HTTPS endpoints with TLS are supported.
************************************************************/

USE [AdventureWorks2025];
GO

/*
1. Allow the engine to call an external endpoint (AI_GENERATE_EMBEDDINGS prerequisite).
*/
EXECUTE sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

/*
2. Database master key, only if the database does not have one.
*/
IF NOT EXISTS
(
  SELECT 1
  FROM   sys.symmetric_keys
  WHERE  [name] = N'##MS_DatabaseMasterKey##'
)
BEGIN
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'<password>';
END;
GO

/*
3. Credential (API key). Create if missing; alter if it already exists.
   The credential name matches the endpoint root.
*/
IF EXISTS
(
  SELECT 1
  FROM   sys.database_scoped_credentials
  WHERE  [name] = N'https://<your-resource>.openai.azure.com/'
)
BEGIN
  ALTER DATABASE SCOPED CREDENTIAL [https://<your-resource>.openai.azure.com/]
  WITH IDENTITY = 'HTTPEndpointHeaders',
       SECRET   = '{"api-key":"<your-key>"}';
END
ELSE
BEGIN
  CREATE DATABASE SCOPED CREDENTIAL [https://<your-resource>.openai.azure.com/]
  WITH IDENTITY = 'HTTPEndpointHeaders',
       SECRET   = '{"api-key":"<your-key>"}';
END;
GO

/*
4. External model. Drop/recreate so this script is rerunnable.
*/
IF EXISTS
(
  SELECT 1
  FROM   sys.external_models
  WHERE  [name] = N'Ada2Embeddings'
)
BEGIN
  DROP EXTERNAL MODEL Ada2Embeddings;
END;
GO

CREATE EXTERNAL MODEL Ada2Embeddings
WITH
(
  LOCATION   = 'https://<your-resource>.openai.azure.com/openai/deployments/<your-deployment>/embeddings?api-version=2023-05-15',
  API_FORMAT = 'Azure OpenAI',
  MODEL_TYPE = EMBEDDINGS,
  MODEL      = 'text-embedding-3-small',
  CREDENTIAL = [https://<your-resource>.openai.azure.com/]
);
GO

SELECT
  [name],
  api_format,
  model_type_desc,
  model,
  [location]
FROM sys.external_models
WHERE [name] = N'Ada2Embeddings';
GO

/*
5. Smoke test.
   Expect a long JSON-like vector string starting with [ (1536 values).
*/
DECLARE @qv vector(1536) =
  AI_GENERATE_EMBEDDINGS(N'a waterproof jacket' USE MODEL Ada2Embeddings);

SELECT LEFT(CAST(@qv AS nvarchar(max)), 120) AS first_values;
GO

/*
6. Other users need EXECUTE on the model to use it in an AI function.
   --GRANT EXECUTE ON EXTERNAL MODEL::Ada2Embeddings TO [<principal>];
*/

/*
7. Extended Events session EmbeddingCalls, written to a file like CopilotQueries in 003.
   Started now and left running for 019.
   Learn: AI_GENERATE_EMBEDDINGS has an extended event, ai_generate_embeddings_summary, with the REST
   request and response (status code, errors, model name). external_rest_endpoint_summary adds detail
   for troubleshooting REST requests.
   The package name is looked up, so this does not depend on where the events live.
   Each event also records host name, program and login, the first things a DBA looks at.
*/
USE [master];
GO

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'EmbeddingCalls')
  DROP EVENT SESSION [EmbeddingCalls] ON SERVER;
GO

DECLARE @events nvarchar(max);
DECLARE @sql    nvarchar(max);

SELECT
  @events = STRING_AGG(N'ADD EVENT ' + QUOTENAME(p.name) + N'.' + QUOTENAME(o.name) + N' (ACTION (sqlserver.client_hostname, sqlserver.client_app_name, sqlserver.server_principal_name))', N', ')
FROM sys.dm_xe_objects AS o
INNER JOIN sys.dm_xe_packages AS p
  ON o.package_guid = p.guid
WHERE o.object_type = N'event'
  AND o.name IN (N'ai_generate_embeddings_summary', N'external_rest_endpoint_summary');

IF @events IS NULL
  THROW 50001, N'The two embedding events were not found on this instance.', 1;

SET @sql =
  N'CREATE EVENT SESSION [EmbeddingCalls] ON SERVER ' + @events +
  N' ADD TARGET package0.event_file (SET filename = N''EmbeddingCalls'', max_file_size = 50)' +
  N' WITH (MAX_DISPATCH_LATENCY = 1 SECONDS, STARTUP_STATE = ON);';

EXECUTE (@sql);
GO

ALTER EVENT SESSION [EmbeddingCalls] ON SERVER STATE = START;
GO

/*
8. Check. One row per field of the two events (about 40 rows in total). Use it to see what each event carries.
*/
SELECT
  o.name AS event_name,
  c.name AS field_name,
  c.type_name
FROM sys.dm_xe_object_columns AS c
INNER JOIN sys.dm_xe_objects AS o
  ON  o.name = c.object_name
  AND o.package_guid = c.object_package_guid
WHERE o.name IN (N'ai_generate_embeddings_summary', N'external_rest_endpoint_summary')
  AND c.column_type = N'data'
ORDER BY o.name, c.name;
GO
