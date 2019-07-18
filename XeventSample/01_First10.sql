/*
Script Name: 01_First10.sql
Written by Taiob M Ali
SqlWorldWide.com

Reference:
https://blogs.msdn.microsoft.com/extended_events/2010/03/08/reading-event-data-101-whats-up-with-the-xml/
https://blogs.msdn.microsoft.com/extended_events/2010/05/14/try-a-sample-using-the-counter-predicate-for-event-sampling/

This script will 
1. Create an Extended Event trace defination to capture first 10 events
2. Run the trace
3. Look at the collected data
4. Stop the trace
5. Clean up

Need 03_SelectStatement to run this demo
*/

--Housekeeping--deleting old files if exist
--Do not use xp_cmdshell unless you know the risk
DECLARE @deletefile varchar(20)='target_reading*.*';
DECLARE @cmd NVARCHAR(MAX) =  
'xp_cmdshell ''del "C:\temp\' + @deletefile + '"''';
EXEC (@cmd)

--Crate a session to collect the first 10 events only
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='counter_test_10')
    DROP EVENT session counter_test_10 ON SERVER;
GO
CREATE EVENT SESSION counter_test_10 ON SERVER
ADD EVENT sqlserver.sql_statement_completed
    (ACTION (sqlserver.sql_text)
		WHERE sqlserver.sql_text like '%This is the%'
    AND package0.counter <= 10)
ADD TARGET package0.asynchronous_file_target
    (SET filename=N'C:\Temp\target_reading.xel')
WITH (MAX_DISPATCH_LATENCY = 1 SECONDS)
GO
--Start the session
ALTER EVENT SESSION counter_test_10 ON SERVER  
STATE = start;  
GO 

--Run the 03_SelectStatement query

--Looking at the data
SELECT CAST(event_data AS XML) xml_event_data, *
FROM sys.fn_xe_file_target_read_file('C:\Temp\target_reading*.xel', 'C:\Temp\target_reading*.xem', NULL, NULL)

--check how many event collected
--you can use the logic to stop the trace
SELECT COUNT(0) AS [howmanyevent] 
FROM sys.fn_xe_file_target_read_file('C:\Temp\target_reading*.xel', 'C:\Temp\target_reading*.xem', NULL, NULL)

--Stop the session
ALTER EVENT SESSION counter_test_10 ON SERVER
STATE = stop

--List of columns collected with the event which helps you writing the xpath query
SELECT * FROM sys.dm_xe_object_columns 
WHERE column_type = 'data' AND object_name IN ('sql_statement_completed')
ORDER BY column_id

--Extract the result
SELECT
    event_xml.value('(./@name)', 'varchar(1000)') as event_name,
		event_xml.value('(./@timestamp)', 'varchar(1000)') as timestamp_UTC,
    event_xml.value('(./data[@name="duration"]/value)[1]', 'bigint') as duration,
    event_xml.value('(./data[@name="cpu_time"]/value)[1]', 'bigint') as cpu,
		event_xml.value('(./data[@name="physical_reads"]/value)[1]', 'bigint') as physical_reads,
		event_xml.value('(./data[@name="logical_reads"]/value)[1]', 'bigint') as logical_reads,
		event_xml.value('(./data[@name="writes"]/value)[1]', 'bigint') as writes,
    event_xml.value('(./data[@name="row_count"]/value)[1]', 'int') as row_count,
    event_xml.value('(./action[@name="sql_text"]/value)[1]', 'varchar(4000)') as sql_text
FROM  (SELECT CAST(event_data AS XML) xml_event_data 
      FROM sys.fn_xe_file_target_read_file('C:\Temp\target_reading*.xel', 'C:\Temp\target_reading*.xem', NULL, NULL)) AS event_table
			CROSS APPLY xml_event_data.nodes('//event') n (event_xml)

--Cleanup--Drop the session
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='counter_test_10')
    DROP EVENT session counter_test_10 ON SERVER;
GO
