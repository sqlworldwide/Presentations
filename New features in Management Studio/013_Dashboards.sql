/*
Script Name: 013_Dashboard.sql

Demo:
  1. SQL Data Discovery and Classification
  2. Performance Dashboard (Updated for SQL2012 need new SSMS 17.2)
  3. Activity Monitor
			Open Activity Monitor 
			Point out 'Active Expensive Queries' is a new additon (SQL2012 need new SSMS)
			Start 'Add4Clinets.cmd' file and those queries will show up as 'Active Expensive Queries'
			Start 'KillWorkers.cmd' to stop the processes
	 
Data discovery and Classification--How it is done?
http://sqlworldwide.com/data-discovery-and-classification-how-it-is-done/
*/

/* To view the data from Discovery */
USE [AdventureWorks];
GO
SELECT t.name AS TableName
 , c.name AS ColumnName
 , MAX(CASE WHEN ep.name = 'sys_information_type_name' THEN ep.value ELSE '' END) AS InformationType
 , MAX(CASE WHEN ep.name = 'sys_sensitivity_label_name' THEN ep.value ELSE '' END) AS SensitivityType
FROM sys.extended_properties ep
 JOIN sys.tables t ON ep.major_id = t.object_id
 JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
WHERE ep.[name] IN ( 'sys_sensitivity_label_name', 'sys_information_type_name')
GROUP BY t.name, c.name
ORDER BY t.name, c.name;
GO



