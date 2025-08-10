/****************************************************************************
12_QueryStoreHints.sql
Written by Taiob Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modiefied
August 10, 2025
	
Tested on :
SQL Server 2022 CU20
SSMS 21.4.8

This code is copied from
https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-query-store-set-hints-transact-sql?view=sql-server-ver17#supported-query-hints

Query Store Hints
Applies to:  SQL Server 2022 (16.x)  Azure SQL Database  Azure SQL Managed Instance
Available in all Editions
***************************************************************************/
USE AdventureWorksLT2022
GO
ALTER DATABASE [AdventureWorksLT2022] SET QUERY_STORE CLEAR;
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
Run this simple query
*/
SELECT *
FROM SalesLT.Address AS A
INNER JOIN SalesLT.CustomerAddress AS CA
ON A.AddressID = CA.AddressID
WHERE PostalCode = '98052'
ORDER BY A.ModifiedDate DESC;

/*
Identify the query in the Query Store system catalog views
Note the query_id
*/

EXEC sys.sp_query_store_flush_db;
GO
SELECT 
  q.query_id,
  qt.query_sql_text
FROM sys.query_store_query_text AS qt
INNER JOIN sys.query_store_query AS q
ON qt.query_text_id = q.query_text_id
WHERE query_sql_text LIKE N'%PostalCode =%'
AND query_sql_text NOT LIKE N'%query_store%';
GO

/*
Replace query_id from above
Apply single hint
*/

EXECUTE sys.sp_query_store_set_hints
@query_id = 3,
@query_hints = N'OPTION(RECOMPILE)';

EXECUTE sys.sp_query_store_set_hints
@query_id = 3,
@query_hints = N'OPTION(USE HINT(''FORCE_LEGACY_CARDINALITY_ESTIMATION''))';

/*
Replace query_id from above
Apply multiple hint
*/
EXECUTE sys.sp_query_store_set_hints
@query_id = 3,
@query_hints = N'OPTION(RECOMPILE, MAXDOP 1, USE HINT(''QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_110''))';

/*
Replace query_id from above
View Query Store hints
*/
SELECT query_hint_id,
  query_id,
  replica_group_id,
  query_hint_text,
  last_query_hint_failure_reason,
  last_query_hint_failure_reason_desc,
  query_hint_failure_count,
  source,
  source_desc
FROM sys.query_store_query_hints
WHERE query_id = 3;

/*
Turn on Actual Execution plan ctrl+M
Run the same query again
Look at the properties of root node and show:
QueryStoreStatementHintText
QueryStoreStatementHintSource
*/
SELECT *
FROM SalesLT.Address AS A
INNER JOIN SalesLT.CustomerAddress AS CA
ON A.AddressID = CA.AddressID
WHERE PostalCode = '98052'
ORDER BY A.ModifiedDate DESC;

/*
Replace query_id from above
Remove the hint from a query
*/
EXECUTE sys.sp_query_store_clear_hints @query_id = 3;

/*
Replace query_id from above
View Query Store hints
*/
SELECT query_hint_id,
  query_id,
  replica_group_id,
  query_hint_text,
  last_query_hint_failure_reason,
  last_query_hint_failure_reason_desc,
  query_hint_failure_count,
  source,
  source_desc
FROM sys.query_store_query_hints
WHERE query_id = 3;
