/*
	Script Name: 10_ParameterSensitivePlanOptimization.sql
	This code is copied from
	https://github.com/microsoft/bobsql/tree/master/demos/sqlserver2022/IQP/pspopt
	
	Modified by Taiob Ali
  December 6th, 2024

	Parameter Sensitive Plan optimization
	Applies to:  SQL Server 2022 (16.x) and later versions, Azure SQL Database starting with database compatibility level 160
	Available in all Editions

	Parameter Sensitive Plan optimization addresses the scenario where a single cached plan for a parameterized query is not optimal for all possible incoming parameter values, for example non-uniform data distributions.
*/

USE WideWorldImporters;
GO
ALTER DATABASE current SET COMPATIBILITY_LEVEL = 150;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
ALTER DATABASE current SET QUERY_STORE CLEAR;
GO

/*
	configure MAXDOP to 0 for the instance
*/

sp_configure 'show advanced', 1;
GO
RECONFIGURE;
GO
sp_configure 'max degree of parallelism', 0;
GO
RECONFIGURE;
GO


/*
	Turn on Actual Execution plan ctrl+M
	Run the query twice in a query window in SSMS. 
	Note the query execution time is fast (< 1 second). 
	Check the timings from SET STATISTICS TIME ON from the second execution. 
	The query is run twice so the 2nd execution will not require a compile. 
	This is the time we want to compare. 
	Note the query plan uses an Index Seek and paste here
	 First run
	 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 71 ms.
	 After
	 SQL Server Execution Times:
   CPU time = 1640 ms,  elapsed time = 252 ms.
*/

USE WideWorldImporters;
GO
SET STATISTICS TIME ON;
GO
-- The best plan for this parameter is an index seek
EXEC Warehouse.GetStockItemsbySupplier 2;
GO

/*
	In a different query window set the actual execution option in SSMS. 
	Run the Query in a new window in SSMS. 
	It takes 5 minutes 36 seconds in my machine
	Note the query plan uses an Clustered Index Scan and parallelism.
*/



/*
	Now go back and run the previous query again. 
	Note that even though the query executes quickly (< 1 sec), the timing from SET STATISTICS TIME is significantly longer than the previous execution. 
	Also note the query plan also uses a clustered index scan and parallelism.
*/

/*
 Setup perfmon to capture % processor time and batch requests/second
 Run workload_index_seek.cmd 10 from the command prompt. This should finish very quickly. The parameter is the number of users. You may want to increase this for machines with 8 CPUs or more. Observe perfmon counters.
 Run workload_index_scan.cmd. This should take longer but now locks into cache a plan for a scan.
 Run workload_index_seek.cmd 10 again. Observe perfmon counters. Notice much higher CPU and much lower batch requests/sec. Also note the workload doesn't finish in a few seconds as before.
 Hit + in the command window for workload_index_seek.cmd as it can take minutes to complete.
*/

/*
	See the skew in supplierID values in the table. 
	This explains why "one size does not fit all" for the stored procedure based on parameter values.
*/

USE WideWorldImporters;
GO
SELECT SupplierID, count(*) as supplier_count
FROM Warehouse.StockItems
GROUP BY SupplierID;
GO

/*
	Solve the problem in SQL Server 2022 with no code changes
*/

USE WideWorldImporters;
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 160;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
ALTER DATABASE CURRENT SET QUERY_STORE CLEAR;
GO

/*
 Run workload_index_seek.cmd 10 from the command prompt. This should finish very quickly
 Run workload_index_scan.cmd
 Run workload_index_seek.cmd 10 again. See that it now finishes again in a few seconds. Observe perfmon counters and see consistent performance
 Run Top Resource Consuming Queries report from SSMS and see that there are two plans for the same stored procedure. The one difference is that there is new OPTION applied to the query for each procedure which is why there are two different "queries" in the Query Store.
*/

/*
	Look into the details of the results to see the query text is the same but slightly different with the option to use variants. 
	But notice the query_hash is the same value.
*/

USE WideWorldImporters;
GO

/*
	Look at the queries variants. Expand column query_sql_text and look at the QueryVariantID value in both rows
	Look at the plans for variants. Click on both xml_plan.
	Notice each query is from the same parent_query_id and the query_hash is the same
*/

SELECT qt.query_sql_text, qq.query_id, qv.query_variant_query_id, qv.parent_query_id, 
qq.query_hash,qr.count_executions, qp.plan_id, qv.dispatcher_plan_id, qp.query_plan_hash,
cast(qp.query_plan as XML) as xml_plan
FROM sys.query_store_query_text qt
JOIN sys.query_store_query qq
ON qt.query_text_id = qq.query_text_id
JOIN sys.query_store_plan qp
ON qq.query_id = qp.query_id
JOIN sys.query_store_query_variant qv
ON qq.query_id = qv.query_variant_query_id
JOIN sys.query_store_runtime_stats qr
ON qp.plan_id = qr.plan_id
ORDER BY qv.parent_query_id;
GO

/*
	Observe this is the text of the query from the stored procedure without variant options. 
	This is the text from the parent plan.
*/

USE WideWorldImporters;
GO

/*
	Look at the "parent" query
	Notice this is the SELECT statement from the procedure with no OPTION for variants
*/
SELECT qt.query_sql_text
FROM sys.query_store_query_text qt
JOIN sys.query_store_query qq
ON qt.query_text_id = qq.query_text_id
JOIN sys.query_store_query_variant qv
ON qq.query_id = qv.parent_query_id;
GO

/*
	If you click on the dispatcher_plan value you will see a graphical plan operator called Multiple Plan.
*/

USE WideWorldImporters;
GO
-- Look at the dispatcher plan
-- If you "click" on the SHOWPLAN XML output you will see a "multiple plans" operator
SELECT qp.plan_id, qp.query_plan_hash, cast (qp.query_plan as XML)
FROM sys.query_store_plan qp
JOIN sys.query_store_query_variant qv
ON qp.plan_id = qv.dispatcher_plan_id;
GO


/*
	Revert MAXDOP Setting
*/

EXEC sp_configure 'max degree of parallelism', 2;  
GO  
RECONFIGURE WITH OVERRIDE;  
GO  
