/*
Script Name: 011_SearchingShowplan.sql
Demo
	Searching in Showplan (SQL2008, need new SSMS)
	Query_thread_profile new XE event (SQL2014 SP2, SQL2016)
	per-operator and thread level performance stats

Until 2014 (Clustered index scan)
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

And looking at the same Index Scan running in parallel:
<RunTimeInformation>
   <RunTimeCountersPerThread Thread="6" ActualRows="0" ActualRowsRead="932085" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="160" ActualCPUms="158" ActualScans="1" ActualLogicalReads="2466" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="8" ActualRows="0" ActualRowsRead="886279" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="138" ActualCPUms="137" ActualScans="1" ActualLogicalReads="2341" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="10" ActualRows="0" ActualRowsRead="828520" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="121" ActualCPUms="120" ActualScans="1" ActualLogicalReads="2192" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="12" ActualRows="0" ActualRowsRead="932085" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="155" ActualCPUms="155" ActualScans="1" ActualLogicalReads="2466" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="11" ActualRows="0" ActualRowsRead="828520" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="133" ActualCPUms="132" ActualScans="1" ActualLogicalReads="2192" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="9" ActualRows="0" ActualRowsRead="724955" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="124" ActualCPUms="124" ActualScans="1" ActualLogicalReads="1918" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="1" ActualRows="0" ActualRowsRead="724955" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="121" ActualCPUms="120" ActualScans="1" ActualLogicalReads="1918" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="7" ActualRows="0" ActualRowsRead="414260" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="111" ActualCPUms="109" ActualScans="1" ActualLogicalReads="1096" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="5" ActualRows="0" ActualRowsRead="1035650" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="168" ActualCPUms="165" ActualScans="1" ActualLogicalReads="2740" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="4" ActualRows="8001" ActualRowsRead="932086" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="160" ActualCPUms="158" ActualScans="1" ActualLogicalReads="2466" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="2" ActualRows="0" ActualRowsRead="828520" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="156" ActualCPUms="130" ActualScans="1" ActualLogicalReads="2192" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="3" ActualRows="0" ActualRowsRead="932085" Batches="0" ActualEndOfScans="1" ActualExecutions="1" ActualExecutionMode="Row" ActualElapsedms="159" ActualCPUms="158" ActualScans="1" ActualLogicalReads="2466" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
   <RunTimeCountersPerThread Thread="0" ActualRows="0" Batches="0" ActualEndOfScans="0" ActualExecutions="0" ActualExecutionMode="Row" ActualElapsedms="0" ActualCPUms="0" ActualScans="1" ActualLogicalReads="2" ActualPhysicalReads="0" ActualReadAheads="0" ActualLobLogicalReads="0" ActualLobPhysicalReads="0" ActualLobReadAheads="0" />
</RunTimeInformation>

How can I caputure the same information to analyze later on?

Details below about Query_thread_profile
https://blogs.msdn.microsoft.com/sql_server_team/added-per-operator-level-performance-stats-for-query-processing/
*/

/* Run this in another window and start the trace */

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

/*
Once the trace is running, start watch live data 
Run following qeury
Turn on Actual Execution Plan (Ctrl+M)

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