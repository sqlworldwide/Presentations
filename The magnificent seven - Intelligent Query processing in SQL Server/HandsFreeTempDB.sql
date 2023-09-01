/******************************************************************************************************
	Exercise for "hands-free" tempdb in SQL Server 2022
https://github.com/microsoft/sqlworkshops-sql2022workshop/tree/main/sql2022workshop/04_Engine/tempdb
*******************************************************************************************************/

/*
	Configure perfmon to track SQL Server SQL Statistics:SQL Statistics/Batch requests/sec (set Scale to 0.1) and SQL Server:Wait Statistics/Page latch waits/Waits started per second (set scale to 0.01).
*/

/*
	Execute the script findtempdbfiles.sql and save the output. A script is provided for the end of this exercise to restore back your tempdb file settings.
*/

USE master;
GO
SELECT name, physical_name, size*8192/1024 as size_kb, growth*8192/1024 as growth_kb
FROM sys.master_files
WHERE database_id = 2;
GO

/*
	Start SQL Server in minimal mode using the command script startsqlminimal.cmd
	net stop mssqlserver
	net start mssqlserver /f /mSQLCMD
*/

/*
	Execute the command script modifytempdbfiles.cmd. 
	This will execute the SQL script modifytempdbfiles.sql to expand the log to 200Mb (avoid any autogrow) and remove all tempdb files other than 1. 
	If you have more than 4 tempdb files you need to edit this script to remove all of them except for tempdev.
	IMPORTANT: If you are using an named instance you will need to edit all the .cmd scripts in this exercise to use a named instance. All the scripts assume a default instance.
*/

/************************************************************************************************************************
Observe performance of a tempdb based workload without metadata optimization and without new SQL Server 2022 enhancements
*************************************************************************************************************************/

/*
	Run disableopttempdb.cmd from the command prompt.
	sqlcmd -E -idisableopttempdb.sql
	net stop mssqlserver
	net start mssqlserver
	
	and then disablegamsgam.cmd 
	net stop mssqlserver
	net start mssqlserver /T6950 /T6962
	Note: This will ensure tempdb metadata optimization is OFF and turn on two trace flags to disable GAM/SGAM concurrency enhancements. 
	These trace flags are not documented and not supported for production use. They are only use to demonstrate new built-in enhancements.
*/

/*
	Load the script pageinfo.sql into SSMS
*/

USE tempdb;
GO
SELECT object_name(page_info.object_id), page_info.* 
FROM sys.dm_exec_requests AS d 
  CROSS APPLY sys.fn_PageResCracker(d.page_resource) AS r
  CROSS APPLY sys.dm_db_page_info(r.db_id, r.file_id, r.page_id,'DETAILED')
    AS page_info;
GO

/*
	Run tempsql22stress.cmd 25 from the command prompt.
	Execute pageinfo.sql from SSMS and observe that all the latch waits are for system table page latches
	Observe perfmon stats
	Observe final duration elapsed from tempsql22stress.cmd
*/



/*******************************************************************************************************
	Observe performance with tempdb metadata optimization enabled and with new SQL Server 2022 enhancements
	You could setup SQL Server with only one tempdb data file so one thing you could do is add more files. 
	However, SQL Server 2022 includes enhancements to avoid latch contention for GAM and SGAM pages.
********************************************************************************************************/
/*
	Execute the command script restartsql.cmd
*/

/*
	Tempdb metadata optimization is already enabled and by restarting you are no longer using trace flags to disable new SQL Server 2022 enhancements.
	Load the script pageinfo.sql into SSMS
	Run tempsql22stress.cmd 25 from the command prompt.
	Execute pageinfo.sql from SSMS and observe there are no observable latch waits
	Observe perfmon stats
	Observe final duration elapsed from tempsql22stress.cmd 25
*/

USE tempdb;
GO
SELECT object_name(page_info.object_id), page_info.* 
FROM sys.dm_exec_requests AS d 
  CROSS APPLY sys.fn_PageResCracker(d.page_resource) AS r
  CROSS APPLY sys.dm_db_page_info(r.db_id, r.file_id, r.page_id,'DETAILED')
    AS page_info;
GO