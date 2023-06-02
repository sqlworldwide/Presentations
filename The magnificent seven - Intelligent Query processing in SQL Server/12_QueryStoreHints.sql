/************************************************************************** --
	Scirpt Name: 12_QueryStoreHints.sql
	This code is copied from
	https://learn.microsoft.com/en-us/sql/relational-databases/performance/query-store-hints?view=azuresqldb-current

	Modified by Taiob Ali
	May 29, 2023

	Query Store Hints
	Applies to:  SQL Server 2022 (16.x)  Azure SQL Database  Azure SQL Managed Instance
	Available in all Editions
	Demo uses "PropertyMLS" database which can be imported from BACPAC here:
	https://github.com/microsoft/sql-server-samples/tree/master/samples/features/query-store

	Email QSHintsFeedback@microsoft.com for questions\feedback
-- ************************************************************************/

/*
	Demo prep, connect to the PropertyMLS database
	Server Name:qshints.database.windows.net
*/

ALTER DATABASE [PropertyMLS] SET QUERY_STORE CLEAR;
ALTER DATABASE CURRENT SET QUERY_STORE = ON;
ALTER DATABASE CURRENT SET QUERY_STORE  (QUERY_CAPTURE_MODE = ALL);
GO

/*
 Should be READ_WRITE
*/

SELECT actual_state_desc 
FROM sys.database_query_store_options;
GO

/*
	You can verify Query Store Hints in sys.query_store_query_hints.
	Checking if any already exist (should be none).
*/

SELECT	
	query_hint_id,
  query_id,
  query_hint_text,
  last_query_hint_failure_reason,
  last_query_hint_failure_reason_desc,
  query_hint_failure_count,
  source,
  source_desc
FROM sys.query_store_query_hints;
GO

/*
	The PropertySearchByAgent stored procedure has a parameter
	used to filter AgentId.  Looking at the statistics for AgentId,
	you will see that there is a big skew for AgentId 101.
*/

SELECT	
	hist.range_high_key AS [AgentId], 
  hist.equal_rows
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_histogram(s.[object_id], s.stats_id) AS hist
WHERE s.[name] = N'NCI_Property_AgentId'
ORDER BY hist.range_high_key DESC;
GO

/*
	Show actual query execution plan to see plan compiled.
	Turn on actual execution plan ctrl+M
	Agent with many properties will have a scan with parallelism.
*/

EXEC [dbo].[PropertySearchByAgent] 101;
GO

/*
	Agents with few properties still re-use this plan (assuming no recent plan eviction).
*/

EXEC [dbo].[PropertySearchByAgent] 4;
GO

/*
	Now let's find the query_id associated with this query.
*/

SELECT 
 query_sql_text, 
 q.query_id
FROM sys.query_store_query_text qt 
INNER JOIN sys.query_store_query q 
 ON qt.query_text_id = q.query_text_id 
WHERE query_sql_text LIKE N'%ORDER BY ListingPrice DESC%' 
AND query_sql_text NOT LIKE N'%query_store%';
GO

/*
	We can set the hint associated with the query_id returned in the previous result set, as below.
	Note, we can designate one or more query hints
	Replace @query_id value from the above query
*/

EXEC sp_query_store_set_hints @query_id=4, @value = N'OPTION(RECOMPILE)';
GO

/*
	You can verify Query Store Hints in sys.query_store_query_hints
*/

SELECT	
	query_hint_id,
  query_id,
  query_hint_text,
  last_query_hint_failure_reason,
  last_query_hint_failure_reason_desc,
  query_hint_failure_count,
  source,
  source_desc
FROM sys.query_store_query_hints;
GO

/*
	Execute both at the same time and show actual query execution plan.
	You should see two different plans, one for AgentId 101 and one for AgentId 4.
*/

EXEC [dbo].[PropertySearchByAgent] 101;
EXEC [dbo].[PropertySearchByAgent] 4;
GO

SELECT	
	query_hint_id,
  query_id,
  query_hint_text,
  last_query_hint_failure_reason,
  last_query_hint_failure_reason_desc,
  query_hint_failure_count,
  source,
  source_desc
FROM sys.query_store_query_hints;
GO

/*
	We can remove the hint using sp_query_store_clear_query_hints
*/

EXEC sp_query_store_clear_hints @query_id = 4;
GO

/*
That Query Store Hint is now removed
*/

SELECT	
	query_hint_id,
  query_id,
  query_hint_text,
  last_query_hint_failure_reason,
  last_query_hint_failure_reason_desc,
  query_hint_failure_count,
  source,
  source_desc
FROM sys.query_store_query_hints;
GO

/*
Execute both at the same time and show actual query execution plan.
You should see one plan again.
*/

EXEC [dbo].[PropertySearchByAgent] 101;
EXEC [dbo].[PropertySearchByAgent] 4;
GO