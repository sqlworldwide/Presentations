/*============================================================================
File: 07_telemetry_xevents.sql
Author: Taiob Ali
Email: taiob@sqlworlwide.com
Bluesky: https://bsky.app/profile/sqlworldwide.bsky.social
Blog: https://sqlworldwide.com/
LinkedIn: https://www.linkedin.com/in/sqlworldwide/

Last Modified: October 08, 2025

Tested On:
	- SQL Server 2022 CU21
	- SSMS 21.5.14

Purpose: Inspect the built-in telemetry_xevents Extended Events session (memory-only by default).

Notes:
- Available in SQL Server 2016 and later.
- Session buffers are memory-only; nothing is persisted to disk unless altered.
- Provides feedback/telemetry signals back to Microsoft (depending on settings/telemetry opt-in).
- Some guidance suggests recreating or cycling the session periodically to avoid repeated messages in the SQL error log.

References:
- https://blobeater.blog/2017/01/23/extended-events-telemetry-session/
- https://www.sqlservercentral.com/blogs/disable-or-turn-off-sql-server-telemetry-service
============================================================================*/

/*
Events currently monitored by the telemetry_xevents session (subset filter).
*/

SELECT 
	name, 
	description
FROM sys.dm_xe_objects
WHERE NAME IN (
	'query_store_db_diagnostics',
	'alter_column_event',
	'always_encrypted_query_count',
	'approximate_count_distinct_query_compiled',
	'auto_stats',
	'cardinality_estimation_version_usage',
	'column_store_index_build_low_memory',
	'column_store_index_build_throttle',
	'columnstore_delete_buffer_flush_failed',
	'columnstore_delta_rowgroup_closed',
	'columnstore_index_reorg_failed',
	'columnstore_log_exception',
	'columnstore_rowgroup_merge_failed',
	'columnstore_tuple_mover_delete_buffer_truncate_timed_out',
	'columnstore_tuple_mover_end_compress',
	'create_index_event',
	'data_classification_auditing_traffic',
	'data_classification_ddl_column_definition',
	'data_classification_traffic',
	'data_masking_ddl_column_definition',
	'data_masking_traffic',
	'data_masking_traffic_masked_only',
	'database_cmptlevel_change',
	'database_created',
	'database_dropped',	
	'fulltext_filter_usage',
	'graph_match_query_compiled',
	'index_build_error_event',
	'index_defragmentation',
	'interleaved_exec_status',
	'json_function_compiled',
	'ledger_digest_upload_success',
	'ledger_transaction_count',
	'login_protocol_count',
	'memory_grant_feedback_percentile_grant',
	'memory_grant_feedback_persistence_update',
	'memory_grant_updated_by_percentile_grant',
	'missing_column_statistics',
	'missing_join_predicate',
	'multistep_execution',
	'natively_compiled_module_inefficiency_detected',
	'natively_compiled_proc_slow_parameter_passing',
	'parameter_sensitive_plan_optimization',
	'query_ce_feedback_telemetry',
	'query_feedback_analysis',
	'query_feedback_validation',
	'query_memory_grant_blocking',
	'query_optimizer_compatibility_level_hint_usage',
	'query_optimizer_nullable_scalar_agg_iv_update',
	'query_tsql_scalar_udf_inlined',
	'reason_many_foreign_keys_operator_not_used',
	'recovery_checkpoint_stats',
	'repl_p2p_conflict_detection_policy_status',
	'resumable_add_constraint_executed',
	'rls_query_count',
	'sequence_function_used',
	'server_memory_change',
	'server_start_stop',
	'stretch_database_disable_completed',
	'stretch_database_enable_completed',
	'stretch_database_reauthorize_completed',
	'stretch_index_reconciliation_codegen_completed',
	'stretch_query_telemetry',
	'stretch_remote_column_execution_completed',
	'stretch_remote_column_reconciliation_codegen_completed',
	'stretch_remote_error',
	'stretch_remote_index_execution_completed',
	'stretch_table_alter_ddl',
	'stretch_table_codegen_completed',
	'stretch_table_create_ddl',
	'stretch_table_data_reconciliation_results_event',
	'stretch_table_hinted_admin_delete_event',
	'stretch_table_hinted_admin_update_event',
	'stretch_table_predicate_not_specified',
	'stretch_table_predicate_specified',
	'stretch_table_query_error',
	'stretch_table_remote_creation_completed',
	'stretch_table_row_migration_results_event',
	'stretch_table_row_unmigration_results_event',
	'stretch_table_unprovision_completed',
	'stretch_table_validation_error',
	'string_escape_compiled',
	'table_variable_deferred_compilation',
	'temporal_ddl_period_add',
	'temporal_ddl_period_drop',
	'temporal_ddl_schema_check_fail',
	'temporal_ddl_system_versioning',
	'temporal_dml_transaction_fail',
	'tsql_feature_usage_tracking',
	'tsql_scalar_udf_inlining_threshold',
	'tsql_scalar_udf_not_inlineable',
	'tx_commit_abort_stats',
	'window_function_used',
	'xtp_alter_table',
	'xtp_db_delete_only_mode_updatedhktrimlsn',
	'xtp_stgif_container_added',
	'xtp_stgif_container_deleted',
	'cl_duration',
	'parallel_alter_stats',
	'serial_alter_stats',
	'xtp_db_delete_only_mode_enter',
	'xtp_db_delete_only_mode_exit',
	'xtp_db_delete_only_mode_update',
	'xtp_physical_db_restarted'
)

/*
Error message IDs of interest (subset displayed).
*/

SELECT 
	message_id, 
	[text] AS [Description]
FROM sys.messages AS m
WHERE m.language_id = SERVERPROPERTY('LCID')
	AND (m.message_id=(18456)
  OR m.message_id=(17803)
  OR m.message_id=(701)
  OR m.message_id=(802)
  OR m.message_id=(8645)
  OR m.message_id=(8651)
  OR m.message_id=(8657)
  OR m.message_id=(8902)
  OR m.message_id=(41354)
  OR m.message_id=(41355)
  OR m.message_id=(41367)
  OR m.message_id=(41384)
  OR m.message_id=(41336)
  OR m.message_id=(41309)
  OR m.message_id=(41312)
  OR m.message_id=(41313)
  OR m.message_id=(33065)
  OR m.message_id=(33066)
) 
ORDER BY message_id

/*
auto_stats event: View recent automatic statistics updates.
*/

DECLARE @ShredMe XML;
SELECT @ShredMe = CAST(target_data AS XML)
FROM sys.dm_xe_sessions AS s
JOIN sys.dm_xe_session_targets AS t
ON t.event_session_address = s.address
WHERE s.name = N'telemetry_xevents';
 
SELECT 
	QP.value('(@timestamp)[1]', 'datetime2') AS [timestamp logged],
	QP.value('(data[@name="database_id"]/value)[1]', 'INT') as [DatabaseID],
	QP.value('(data[@name="object_id"]/value)[1]', 'INT') as [ObjectID],
	QP.value('(data[@name="index_id"]/value)[1]', 'INT') as [IndexID],
	QP.value('(data[@name="job_type"]/text)[1]', 'VARCHAR(MAX)') as [Job Type],
	QP.value('(data[@name="statistics_list"]/value)[1]', 'VARCHAR(MAX)') as [Stats List]
FROM @ShredMe.nodes('RingBufferTarget/event[@name=''auto_stats'']') AS q(QP);
GO

/*
Database creation times (quick create/drop demonstration).
*/

DROP DATABASE IF EXISTS nesqldemo;
GO
CREATE DATABASE nesqldemo;
GO
DROP DATABASE IF EXISTS nesqldemo;
GO

DECLARE @ShredMe XML;
SELECT @ShredMe = CAST(target_data AS XML)
FROM sys.dm_xe_sessions AS s
JOIN sys.dm_xe_session_targets AS t
ON t.event_session_address = s.address
WHERE s.name = N'telemetry_xevents';
 
SELECT 
	QP.value('(data[@name="database_name"]/value)[1]', 'varchar(20)') as [DatabaseName],
	QP.value('(@timestamp)[1]', 'datetime2') AS [timestamp created]
FROM @ShredMe.nodes('RingBufferTarget/event[@name=''database_created'']') AS q(QP);

/*
Database drop times.
*/

DECLARE @ShredMe XML;
SELECT @ShredMe = CAST(target_data AS XML)
FROM sys.dm_xe_sessions AS s
JOIN sys.dm_xe_session_targets AS t
ON t.event_session_address = s.address
WHERE s.name = N'telemetry_xevents';
 
SELECT
	QP.value('(data[@name="database_name"]/value)[1]', 'varchar(20)') as [DatabaseName],
	QP.value('(@timestamp)[1]', 'datetime2') AS [timestamp when dropped]
FROM @ShredMe.nodes('RingBufferTarget/event[@name=''database_dropped'']') AS q(QP);

/*
Database compatibility level changes.
*/

USE [master]
GO
ALTER DATABASE [SqlDetective] SET COMPATIBILITY_LEVEL = 150
GO
USE [master]
GO
ALTER DATABASE  [SqlDetective]  SET COMPATIBILITY_LEVEL = 160
GO

DECLARE @ShredMe XML;
SELECT @ShredMe = CAST(target_data AS XML)
FROM sys.dm_xe_sessions AS s
JOIN sys.dm_xe_session_targets AS t
ON t.event_session_address = s.address
WHERE s.name = N'telemetry_xevents';
 
SELECT
	QP.value('(data[@name="database_id"]/value)[1]', 'INT') as [DatabaseID],
	QP.value('(@timestamp)[1]', 'datetime2') AS [timestamp of change],
	QP.value('(data[@name="previous_value"]/value)[1]', 'INT') as [Previous cmptlevel],
	QP.value('(data[@name="new_value"]/value)[1]', 'INT') as [Newcmptlevel]
FROM @ShredMe.nodes('RingBufferTarget/event[@name=''database_cmptlevel_change'']') AS q(QP);

/*
Max server memory change events.
*/

DECLARE @ShredMe XML;
SELECT @ShredMe = CAST(target_data AS XML)
FROM sys.dm_xe_sessions AS s
JOIN sys.dm_xe_session_targets AS t
ON t.event_session_address = s.address
WHERE s.name = N'telemetry_xevents';

SELECT
	QP.value('(data[@name="memory_change"]/text)[1]', 'varchar(256)') as [Memory Change Desc],
	QP.value('(@timestamp)[1]', 'datetime2') AS [timestamp changed],
	QP.value('(data[@name="new_memory_size_mb"]/value)[1]', 'int') as [New Memory size(MB)]
FROM @ShredMe.nodes('RingBufferTarget/event[@name=''server_memory_change'']') AS q(QP);

/*
Generate a severity 20 error (forces logging).
*/

RAISERROR (N'This is message %s %d.', -- Message text.
	20, -- Severity,
	1, -- State,
	N'number', -- First argument.
	5) WITH LOG; -- Second argument.

/*
Error messages with severity > 16.
*/

DECLARE @ShredMe XML;
SELECT @ShredMe = CAST(target_data AS XML)
FROM sys.dm_xe_sessions AS s
JOIN sys.dm_xe_session_targets AS t
ON t.event_session_address = s.address
WHERE s.name = N'telemetry_xevents';
 
SELECT
	QP.value('(data[@name="severity"]/value)[1]', 'INT') as [severity level],
	QP.value('(@timestamp)[1]', 'datetime2') AS [timestamp logged],
	QP.value('(data[@name="message"]/value)[1]', 'VARCHAR(MAX)') as [Message]
FROM @ShredMe.nodes('RingBufferTarget/event[@name=''error_reported'']') AS q(QP);
GO