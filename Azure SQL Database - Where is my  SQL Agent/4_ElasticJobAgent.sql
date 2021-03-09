/*============================================================================
4_ElasticJobAgent.sql
Written by Taiob M Ali
SqlWorldWide.com

This script will demo Elastic Job Agent service in Azure
Before you can run this demo, you must run these two script successfully
DemoWhereIsMySqlAgent.ipynb

You can do the same using PowerShell
'Create an Elastic Job agent using PowerShell'
https://docs.microsoft.com/en-us/azure/sql-database/elastic-jobs-powershell

Following tsql script was created using below reference.
https://docs.microsoft.com/en-us/azure/sql-database/elastic-jobs-tsql
============================================================================*/

--Connect to ugdemojobserver.database.windows.net
--USE Master
CREATE LOGIN elasticJobTarget WITH PASSWORD = 'Pa$$w0rd123'
GO
CREATE LOGIN elasticJobMaster WITH PASSWORD = 'Pa$$w0rd123'
GO

--Create User in jobdatabase
--USE jobdatabase
CREATE USER elasticJobMaster FOR LOGIN elasticJobMaster
WITH DEFAULT_SCHEMA = dbo;
GO
EXEC sp_addrolemember N'db_owner', N'elasticJobMaster';
GO

CREATE USER elasticJobTarget FOR LOGIN elasticJobTarget
WITH DEFAULT_SCHEMA = dbo;
GO
EXEC sp_addrolemember N'db_owner', N'elasticJobTarget';
GO

--Creating credential which will be used 
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Pa$$w0rd123'
GO
CREATE DATABASE SCOPED CREDENTIAL elasticJobTargetCredential
WITH IDENTITY = 'elasticJobTarget',
SECRET = 'Pa$$w0rd123';
GO
CREATE DATABASE SCOPED CREDENTIAL elasticJobMasterCredential
WITH IDENTITY = 'elasticJobMaster',
SECRET = 'Pa$$w0rd123';
GO

--Create User in dbawarehouse
--USE dbawarehouse
CREATE USER elasticJobMaster FOR LOGIN elasticJobMaster
WITH DEFAULT_SCHEMA = dbo;
GO
EXEC sp_addrolemember N'db_owner', N'elasticJobMaster';
GO

CREATE USER elasticJobTarget FOR LOGIN elasticJobTarget
WITH DEFAULT_SCHEMA = dbo;
GO
EXEC sp_addrolemember N'db_owner', N'elasticJobTarget';
GO

--Connect to udgemotargetserver.database.windows.net
--USE master
CREATE LOGIN elasticJobMaster WITH PASSWORD = 'Pa$$w0rd123'
GO
CREATE LOGIN elasticJobTarget WITH PASSWORD = 'Pa$$w0rd123'
GO

CREATE USER elasticJobMaster FOR LOGIN elasticJobMaster
WITH DEFAULT_SCHEMA = dbo;
GO
CREATE USER elasticJobTarget FOR LOGIN elasticJobTarget
WITH DEFAULT_SCHEMA = dbo;
GO

--Run this in all user database
--This user need all privlege that jos will perform
--You will most likely use a powershell function to do for all databases

CREATE USER elasticJobTarget FOR LOGIN elasticJobTarget
WITH DEFAULT_SCHEMA = dbo;
GO
EXEC sp_addrolemember N'db_datareader', N'elasticJobTarget';
GO
GRANT VIEW DATABASE STATE TO elasticJobTarget;
GO

--Connect to ugdemojobserver.database.windows.net
--Change context to jobdatabase
--Add a target group containing server(s)
EXEC jobs.sp_add_target_group 'ServerGroup1'

-- Add a server target member
EXEC jobs.sp_add_target_group_member 
    @target_group_name = 'ServerGroup1',
    @target_type = 'SqlServer',
    @refresh_credential_name = 'elasticJobMasterCredential', --credential required to refresh the databases in server
    @server_name = 'ugdemotargetserver.database.windows.net'

--View the recently created target group and target group members
SELECT *
FROM jobs.target_groups
WHERE target_group_name = 'ServerGroup1';
SELECT *
FROM jobs.target_group_members
WHERE target_group_name = 'ServerGroup1';

/*
--How to exclude a database
--Exclude a database target member from the server target group
EXEC [jobs].sp_add_target_group_member
@target_group_name = N'ServerGroup1',
@membership_type = N'Exclude',
@target_type = N'SqlDatabase',
@server_name='ugdemo2.database.windows.net',
@database_name =N'master'
GO
--View the recently created target group and target group members
SELECT * FROM [jobs].target_groups WHERE target_group_name = N'ServerGroup1';
SELECT * FROM [jobs].target_group_members WHERE target_group_name = N'ServerGroup1';
*/
-- Add a job to collect perf results
EXEC jobs.sp_add_job 
    @job_name = 'ResultsJob',
    @description = 'Collection Performance data from all databases'

/*
Add a job step w/o schedule to collect results from sys.dm_db_resource_stats
Returns CPU, I/O, and memory consumption for an Azure SQL Database database. 
One row exists for every 15 seconds, even if there is no activity in the database. 
Historical data is maintained for approximately one hour.
More details: https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-resource-stats-azure-sql-database?view=azuresqldb-current
*/
EXEC jobs.sp_add_jobstep 
	@job_name = 'ResultsJob',
	@command = N' SELECT DB_NAME() DatabaseName, $(job_execution_id) AS job_execution_id, * FROM sys.dm_db_resource_stats WHERE end_time > DATEADD(mi, -20, GETDATE());',
	@credential_name = 'elasticJobTargetCredential',
	@target_group_name = 'ServerGroup1',
	@output_type = 'SqlDatabase',
	@output_credential_name = 'elasticJobTargetCredential',
	@output_server_name = 'ugdemojobserver.database.windows.net',
	@output_database_name = 'dbawarehouse',
	@output_table_name = 'perfResults'

-- View all jobs
SELECT *
FROM jobs.jobs;

-- View the steps of the current version of all jobs
SELECT js.*
FROM jobs.jobsteps js
JOIN jobs.jobs j
ON j.job_id = js.job_id
AND j.job_version = js.job_version;

-- View the steps of all versions of all jobs
SELECT *
FROM jobs.jobsteps;

-- Execute the latest version of a job
EXEC jobs.sp_start_job 'ResultsJob'
--EXEC jobs.sp_stop_job '87C309CA-A9FC-4121-8D6E-4F31C5661515'

--See job execution details
SELECT 
    [job_execution_id],
    [job_name],
    [step_name],
    [lifecycle],
    [step_id],
    [is_active],
    [create_time],
    [start_time],
    [end_time],
    [current_attempts],
    [current_attempt_start_time],
    [next_attempt_start_time],
    [last_message],
    [target_type],
    [target_id],
    [target_subscription_id],
    [target_resource_group_name],
    [target_server_name],
    [target_database_name],
    [target_elastic_pool_name]
FROM [jobs].[job_executions]
WHERE job_name = 'ResultsJob'
ORDER BY start_time DESC

--switch cotenxt to dbawarehouse
--see the result
SELECT 
    [DatabaseName],
    [job_execution_id],
    [end_time],
    [avg_cpu_percent],
    [avg_data_io_percent],
    [avg_log_write_percent],
    [avg_memory_usage_percent],
    [xtp_storage_percent],
    [max_worker_percent],
    [max_session_percent],
    [dtu_limit],
    [avg_login_rate_percent],
    [avg_instance_cpu_percent],
    [avg_instance_memory_percent],
    [cpu_limit],
    [internal_execution_id]
FROM [dbo].[perfResults];

--Change context to jobdatabase--Add a target group containing server(s)
EXEC jobs.sp_add_target_group 'ServerGroup2';

-- Add a server as target member
EXEC jobs.sp_add_target_group_member 
	@target_group_name = 'ServerGroup2',
	@target_type = 'SqlServer',
	@refresh_credential_name = 'elasticJobMasterCredential', --credential required to refresh the databases in server
	@server_name = 'ugdemotargetserver.database.windows.net';

--View the recently created target group and target group members
SELECT *
FROM jobs.target_groups
WHERE target_group_name = 'ServerGroup2';
SELECT *
FROM jobs.target_group_members
WHERE target_group_name = 'ServerGroup2';

-- Add a job to collect perf results
EXEC jobs.sp_add_job 
	@job_name = 'databaseSize',
	@description = 'Collection datafile size from all databases in cloud';

-- Add a job step w/o schedule to collect results
EXEC jobs.sp_add_jobstep 
	@job_name = 'databaseSize',
	@command = 
        N' 
        SELECT  
        collectedAt = GetDate(),
        serverName = @@SERVERNAME,
        databaseName= DB_NAME(),
        fileName = LEFT(a.NAME, 64) ,
        a.FILE_ID AS fileId,
        fileSizeMB = CONVERT(DECIMAL(12, 2), ROUND(a.size / 128.000, 2)),
        spaceUsedMB = CONVERT(DECIMAL(12, 2), ROUND(FILEPROPERTY(a.name,''SpaceUsed'')/ 128.000, 2)),
        freeSpaceMB = CONVERT(DECIMAL(12, 2), ROUND(( a.size - FILEPROPERTY(a.name,''SpaceUsed''))/ 128.000, 2)),
        percentFree = CONVERT(DECIMAL(12, 2), (CONVERT(DECIMAL(12, 2), ROUND((a.size - FILEPROPERTY(a.name,''SpaceUsed''))/128.000, 2))*100)/ CONVERT(DECIMAL(12, 2), ROUND(a.size / 128.000, 2))),
        a.physical_name 
        FROM sys.database_files a;',
	@credential_name = 'elasticJobTargetCredential',
	@target_group_name = 'ServerGroup2',
	@output_type = 'SqlDatabase',
	@output_credential_name = 'elasticJobTargetCredential',
	@output_server_name = 'ugdemojobserver.database.windows.net',
	@output_database_name = 'dbawarehouse',
	@output_table_name = 'databaseFileSize'

-- Execute the latest version of a job
EXEC jobs.sp_start_job 'databaseSize'

--see job execution details

--See job execution details
SELECT 
    [job_execution_id],
    [job_name],
    [step_name],
    [lifecycle],
    [step_id],
    [is_active],
    [create_time],
    [start_time],
    [end_time],
    [current_attempts],
    [current_attempt_start_time],
    [next_attempt_start_time],
    [last_message],
    [target_type],
    [target_id],
    [target_subscription_id],
    [target_resource_group_name],
    [target_server_name],
    [target_database_name],
    [target_elastic_pool_name]
FROM [jobs].[job_executions]
WHERE job_name = 'databaseSize'
ORDER BY start_time DESC;

--change context to dbawarehouse
--See result
SELECT 
    [collectedAt],
    [serverName],
    [databaseName],
    [fileName],
    [fileId],
    [fileSizeMB],
    [spaceUsedMB],
    [freeSpaceMB],
    [percentFree],
    [physical_name]
FROM [dbo].[databaseFileSize]
ORDER BY collectedAt DESC;


--Target an elastic pool
--Change context to jobdatabase--Add a target group containing server(s)
EXEC jobs.sp_add_target_group 'PoolGroup';

-- Add a server target member
EXEC jobs.sp_add_target_group_member 
	@target_group_name = 'PoolGroup',
	@target_type = 'SqlElasticPool',
	@refresh_credential_name = 'elasticJobMasterCredential', --credential required to refresh the databases in server
	@server_name = 'ugdemotargetserver.database.windows.net',
	@elastic_pool_name = 'sqlagentdemo';

--View the recently created target group and target group members
SELECT *
FROM jobs.target_groups
WHERE target_group_name = 'PoolGroup';
SELECT *
FROM jobs.target_group_members
WHERE target_group_name = 'PoolGroup';


--Now we can run any job against this resourcePool meaning all the database in the pool.

/*
copied from:
https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-resource-stats-azure-sql-database?view=azuresqldb-current#examples
The following example returns all databases that are averaging at least 80% of compute utilization over the last one week.

DECLARE @s datetime;  
DECLARE @e datetime;  
SET @s= DateAdd(d,-7,GetUTCDate());  
SET @e= GETUTCDATE();  
SELECT database_name, AVG(avg_cpu_percent) AS Average_Compute_Utilization   
FROM sys.resource_stats   
WHERE start_time BETWEEN @s AND @e  
GROUP BY database_name  
HAVING AVG(avg_cpu_percent) >= 80
*/
