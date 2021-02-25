/*
Script Name: 011_SearchingShowplan.sql
Demo
	Searching in Showplan (SQL2008, need new SSMS)
	Query_thread_profile new XE event (SQL2014 SP2, SQL2016)
	per-operator and thread level performance stats

Until 2014
<RunTimeInformation>
   <RunTimeCountersPerThread Thread="0" ActualRows="8001" ActualEndOfScans="1" 
   ActualExecutions="1" />
</RunTimeInformation>

2016 RC0
<RunTimeInformation>
   <RunTimeCountersPerThread Thread="0" ActualRows="8001" ActualRowsRead="10000000" 
   Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" 
   ActualElapsedms="965" ActualCPUms="965" ActualScans="1" ActualLogicalReads="26073" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
</RunTimeInformation>

How can I caputure the same information to analyze later on?

Details below about Query_thread_profile
https://blogs.msdn.microsoft.com/sql_server_team/added-per-operator-level-performance-stats-for-query-processing/
*/

--Run this in another window and start the trace
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='PerfStats_XE')  
  DROP EVENT session [PerfStats_XE] ON SERVER;  
GO
CREATE EVENT SESSION [PerfStats_XE] ON SERVER
ADD EVENT sqlserver.query_thread_profile(
ACTION(sqlos.scheduler_id,sqlserver.database_id,sqlserver.is_system,sqlserver.plan_handle,
	sqlserver.query_hash_signed,sqlserver.query_plan_hash_signed,sqlserver.server_instance_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text))
ADD TARGET package0.ring_buffer(SET max_memory=(25600))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,
	MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF);
GO


--Once the trace is running, start watch live data 
--Run following qeury
--Turn on Actual Execution Plan (Ctrl+M)
/*
Code copied from 
https://dba.stackexchange.com/questions/135455/what-does-option-fast-in-select-statement-do
*/

USE [AdventureWorks];
GO
SELECT 
  BusinessEntityID,
  TotalPurchaseYTD,
  DateFirstPurchase,
  BirthDate,
  MaritalStatus,
  YearlyIncome,
  Gender,
  TotalChildren,
  NumberChildrenAtHome,
  Education,
  Occupation,
  HomeOwnerFlag,
  NumberCarsOwned
FROM AdventureWorks.Sales.vPersonDemographics
ORDER BY BusinessEntityID;

/*
Stop the trace
Sort estimated rows column in descending order
Take a note of 19972 value and search for the nodes in Actual Execution Plan
Chost Execution plan TAB
ctrl+f
From dropdown chose 'EstimateRows' 

Review all other search options

You can also use the same feature from the plan in the cache
https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-profiles-transact-sql?view=sql-server-2017
*/