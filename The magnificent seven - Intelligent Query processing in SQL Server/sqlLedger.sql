/*
	https://github.com/microsoft/sqlworkshops-sql2022workshop/tree/main/sql2022workshop/04_Engine/sqlledger
*/
/*
	Create a SQL based sysadmin login called bob as the default sysadmin for the SQL Server instance.
*/

USE master;
GO
-- Create a login for bob and make him a sysadmin
IF EXISTS (SELECT * FROM sys.server_principals WHERE NAME = 'bob')
BEGIN
DROP LOGIN bob;
END
CREATE LOGIN bob WITH PASSWORD = N'September19$$';
EXEC sp_addsrvrolemember 'bob', 'sysadmin';  
GO

/*
	Create the database schema, add an app login, and users 
*/
USE master;
GO
-- Create the ContosoHR database
--
DROP DATABASE IF EXISTS ContosoHR;
GO
CREATE DATABASE ContosoHR;
GO
USE ContosoHR;
GO
-- Create a login for the app
IF EXISTS (SELECT * FROM sys.server_principals WHERE NAME = 'app')
BEGIN
DROP LOGIN app;
END
CREATE LOGIN app WITH PASSWORD = N'September19$$', DEFAULT_DATABASE = ContosoHR;
GO
-- Enable snapshot isolation to allow ledger to be verified
ALTER DATABASE ContosoHR SET ALLOW_SNAPSHOT_ISOLATION ON;
GO
-- Create an app user for the app login
CREATE USER app FROM LOGIN app;
GO
EXEC sp_addrolemember 'db_owner', 'app';
GO

/*
	Create an updatable ledger table for Employees.
	Use SSMS Object Explorer to see the tables have properties next to their name that they are ledger tables and a new visual icon to indicate it is a ledger table.
*/

USE ContosoHR;
GO
-- Create the Employees table and make it an updatetable Ledger table
DROP TABLE IF EXISTS [dbo].[Employees];
GO
CREATE TABLE [dbo].[Employees](
	[EmployeeID] [int] IDENTITY(1,1) NOT NULL,
	[SSN] [char](11) NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[Salary] [money] NOT NULL
	)
WITH 
(
  SYSTEM_VERSIONING = ON,
  LEDGER = ON
); 
GO

/*
	Populate initial employee data
*/
USE ContosoHR;
GO
-- Clear Employees table
DELETE FROM [dbo].[Employees];
GO
-- Insert 10 employees. The names and SSN are completely fictional and not associated with any person
DECLARE @SSN1 char(11) = '795-73-9833'; DECLARE @Salary1 Money = 61692.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN1, 'Catherine', 'Abel', @Salary1);
DECLARE @SSN2 char(11) = '990-00-6818'; DECLARE @Salary2 Money = 990.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN2, 'Kim', 'Abercrombie', @Salary2);
DECLARE @SSN3 char(11) = '009-37-3952'; DECLARE @Salary3 Money = 5684.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN3, 'Frances', 'Adams', @Salary3);
DECLARE @SSN4 char(11) = '708-44-3627'; DECLARE @Salary4 Money = 55415.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN4, 'Jay', 'Adams', @Salary4);
DECLARE @SSN5 char(11) = '447-62-6279'; DECLARE @Salary5 Money = 49744.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN5, 'Robert', 'Ahlering', @Salary5);
DECLARE @SSN6 char(11) = '872-78-4732'; DECLARE @Salary6 Money = 38584.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN6, 'Stanley', 'Alan', @Salary6);
DECLARE @SSN7 char(11) = '898-79-8701'; DECLARE @Salary7 Money = 11918.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN7, 'Paul', 'Alcorn', @Salary7);
DECLARE @SSN8 char(11) = '561-88-3757'; DECLARE @Salary8 Money = 17349.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN8, 'Mary', 'Alexander', @Salary8);
DECLARE @SSN9 char(11) = '904-55-0991'; DECLARE @Salary9 Money = 70796.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN9, 'Michelle', 'Alexander', @Salary9);
DECLARE @SSN10 char(11) = '293-95-6617'; DECLARE @Salary10 Money = 96956.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN10, 'Marvin', 'Allen', @Salary10);
GO

/*
	Examine the data in the employee table 
	Notice there are "hidden" columns that are not shown if you execute a SELECT *. 
	Some of these columns are NULL or 0 because no updates have been made to the data. 
	You normally will not use these columns but use the ledger view to see information about changes to the employees table. 
	Take note of Jay Adams salary which is 55415.00.
*/

USE ContosoHR;
GO
-- Use * for all columns
SELECT * FROM dbo.Employees;
GO
-- List out all the columns
SELECT EmployeeID, SSN, FirstName, LastName, Salary, 
ledger_start_transaction_id, ledger_end_transaction_id, ledger_start_sequence_number, 
ledger_end_sequence_number
FROM dbo.Employees;
GO

/*
	Look at the employees ledger view by executing the script getemployeesledger.sql. This is a view from the Employees table and a ledger history table. Notice the ledger has the transaction information from hidden columns in the table plus an indication of what type of operation was performed on the ledger for a specific row.
*/

USE ContosoHR;
GO
SELECT * FROM dbo.Employees_Ledger;
GO

/*
Examine the definition of the ledger view by executing getemployeesledgerview.sql. The ledger history table uses the name MSSQL_LedgerHistoryFor_[objectid of table]. Notice the view is a union of the original table (for new inserts) and updates from the history table (insert/delete pair).
*/

USE [ContosoHR];
GO
sp_helptext 'Employees_ledger';
GO

/*
	You can combine the ledger view with a system table to get more auditing information.  
	You can see that 'bob' inserted all the data along with a timestamp.
*/

USE ContosoHR;
GO
SELECT e.EmployeeID, e.FirstName, e.LastName, e.Salary, 
dlt.transaction_id, dlt.commit_time, dlt.principal_name, e.ledger_operation_type_desc, dlt.table_hashes
FROM sys.database_ledger_transactions dlt
JOIN dbo.Employees_Ledger e
ON e.ledger_transaction_id = dlt.transaction_id
ORDER BY dlt.commit_time DESC;
GO

/*
To verify the integrity of the ledger let's generate a digest by executing the script generatedigest.sql. Save the output value (including the braces) to be used for verifying the ledger.. You will use this in a later step. This provides me a snapshot of the data at a point in time
*/

USE ContosoHR;
GO
EXEC sp_generate_database_ledger_digest;
GO

/*
	You can now see blocks generated for the ledger table by executing the script getledgerblocks.sql
*/

USE ContosoHR;
GO
SELECT * FROM sys.database_ledger_blocks;
GO

/*
	Let's verify the current state of the ledger. 
	Edit the script verifyledger.sql by substituting the JSON value result from the generatedigest.sql script (include the brackets inside the quotes) you ran in a previous step.
	Note the last_verified_block_id matches the digest and the result in getledgerblocks.sql.
*/
USE ContosoHR;
GO
EXECUTE sp_verify_database_ledger 
N'{"database_name":"ContosoHR","block_id":0,"hash":"0x6FCB272F5D9D52E9E3F095881051E61CD41EF0CE012C3581AB7EE3CDF9F33C96","last_transaction_commit_time":"2023-06-06T15:41:26.4200000","digest_time":"2023-06-07T15:21:46.7046121"}'
GO

/*
Try to update Jay Adam's salary to see if no one will notice by executing the script updatejayssalary.sql.
*/
USE ContosoHR;
GO
UPDATE dbo.Employees
SET Salary = Salary + 50000
WHERE EmployeeID = 4;
GO

/*
	Execute the script getallemployees.sql to see that it doesn't look anyone updated the data. 
	If you had not run this script before you wouldn't have known Jay's salary had been increased by 50,000.
*/
USE ContosoHR;
GO
-- Use * for all columns
SELECT * FROM dbo.Employees;
GO
-- List out all the columns
SELECT EmployeeID, SSN, FirstName, LastName, Salary, 
ledger_start_transaction_id, ledger_end_transaction_id, ledger_start_sequence_number, 
ledger_end_sequence_number
FROM dbo.Employees;
GO

/*
	Execute the script viewemployeesledgerhistory.sql to see the audit of the changes and who made them. 
	Notice 3 rows for Jay Adam's. Two for the update (DELETE and INSERT) and 1 for the original INSERT.
*/

USE ContosoHR;
GO
SELECT e.EmployeeID, e.FirstName, e.LastName, e.Salary, 
dlt.transaction_id, dlt.commit_time, dlt.principal_name, e.ledger_operation_type_desc, dlt.table_hashes
FROM sys.database_ledger_transactions dlt
JOIN dbo.Employees_Ledger e
ON e.ledger_transaction_id = dlt.transaction_id
ORDER BY dlt.commit_time DESC;
GO

/*
	Let's generate another digest and verify it. 
	Execute the script again generatedigest2.sql. Save the new output value (including the braces) to be used for verifying the ledger..
*/

USE ContosoHR;
GO
EXEC sp_generate_database_ledger_digest;
GO

/*
	Let's verify the current state of the ledger again. 
	Edit the script verifyledger2.sql by substituting the JSON value result from the generatedigest2.sql script (include the brackets inside the quotes) you just ran and execute the script.
*/

USE ContosoHR;
GO
EXECUTE sp_verify_database_ledger 
N'{"database_name":"ContosoHR","block_id":1,"hash":"0x9FB772E045B5F3FE427997C846CF12F4C2F352189E5FC365F4BECE6473A665CF","last_transaction_commit_time":"2023-06-07T11:27:59.5066667","digest_time":"2023-06-07T15:30:57.8269756"}'
GO

/*
	Execute the script getledgerblocks.sql again. 
	Note the last_verified_block_id from verifyledger2.sql matches the digest and the result of the new row in getledgerblocks.sql. If someone had tried to fake out the system but tampering with Jay's salary without using a T-SQL update, the verification would have failed.
*/

USE ContosoHR;
GO
SELECT * FROM sys.database_ledger_blocks;
GO

/***********************************************
Exercise 2: Using an append-only ledger table
************************************************/

/*
Use the SQL login bob to create an append-only ledger table for auditing of the application by executing the script createauditledger.sql.
*/

USE ContosoHR;
GO
-- Create an append-only ledger table to track T-SQL commands from the app and the "real" user who initiated the transactkion
DROP TABLE IF EXISTS [dbo].[AuditEvents];
GO
CREATE TABLE [dbo].[AuditEvents](
	[Timestamp] [Datetime2] NOT NULL DEFAULT (GETDATE()),
	[UserName] [nvarchar](255) NOT NULL,
	[Query] [nvarchar](4000) NOT NULL
	)
WITH (LEDGER = ON (APPEND_ONLY = ON));
GO

/*
	To simulate a user using the application to change someone else's salary connect to SSMS as the app login created with the createdb.sql script and execute the script appchangemaryssalary.sql
*/

USE ContosoHR;
GO
BEGIN TRANSACTION;
GO
UPDATE dbo.Employees
SET Salary = Salary + 50000
WHERE EmployeeID = 8;
GO
INSERT INTO dbo.AuditEvents VALUES (getdate(), 'troy', 'UPDATE dbo.Employees SET Salary = Salary + 50000 WHERE EmployeeID = 8');
GO
COMMIT TRANSACTION;
GO

/*
Logging back in as bob login, look at the ledger by executing the script viewemployeesledgerhistory.sql. All you can see is that the app login changed Mary's salary. But what user from the web application made this change?
*/

USE ContosoHR;
GO
SELECT e.EmployeeID, e.FirstName, e.LastName, e.Salary, 
dlt.transaction_id, dlt.commit_time, dlt.principal_name, e.ledger_operation_type_desc, dlt.table_hashes
FROM sys.database_ledger_transactions dlt
JOIN dbo.Employees_Ledger e
ON e.ledger_transaction_id = dlt.transaction_id
ORDER BY dlt.commit_time DESC;
GO

/*
	Using the bob login again, look at the audit ledger by executing the script getauditledger.sql. 
	This ledger table cannot be updated so the app must "log" all operations and the originating user from the app who initiated the operation. 
	I can see from the Employees ledger history that the app user changed Mary's salary but the "app ledger table" shows troy was the actual person who used the app to make the change.
*/

USE ContosoHR;
GO
SELECT * FROM dbo.AuditEvents_Ledger;
GO


/***********************************************
Exercise 3: Protecting Ledger tables from DDL changes
************************************************/
/*
	You can also view which tables and columns have been created for SQL Server ledger by executing the script getledgerobjects.sql
*/

USE ContosoHR;
GO
SELECT * FROM sys.ledger_table_history;
GO
SELECT * FROM sys.ledger_column_history;
GO

/*
	Admins are restricted from altering certain aspects of a ledger table, removing the ledger history table, and there is a record kept of any dropped ledger table (which you cannot drop). 
	See these aspects of ledger by executing the script admindropledger.sql
*/

USE ContosoHR;
GO
-- You cannot turn off versioning for a ledger table
ALTER TABLE Employees SET (SYSTEM_VERSIONING = OFF);
GO
-- You cannot drop the ledger history table
DROP TABLE dbo.MSSQL_LedgerHistoryFor_901578250;
GO
-- You can drop a ledger table
DROP TABLE Employees;
GO
-- But we keep a history of the dropped table
SELECT * FROM sys.objects WHERE name like '%DroppedLedgerTable%';
GO

/*
	Execute getledgerobjects.sql again to see the original created and then dropped ledger table.
*/

USE ContosoHR;
GO
SELECT * FROM sys.database_ledger_blocks;
GO

/*
	Execute auditdroppedledgertable.sql to see who created and dropped the ledger tables.
	If you are using SSMS 19.X, Object Explorer also can show Dropped Ledger Tables.
*/

USE ContosoHR;
GO
-- See who dropped the ledger table
SELECT
t.[principal_name]
, t.[commit_time]
, h.[schema_name] + '.' + h.[table_name] AS [table_name]
, h.[ledger_view_schema_name] + '.' + h.[ledger_view_name] AS [view_name]
, h.[operation_type_desc]
FROM sys.ledger_table_history h
JOIN sys.database_ledger_transactions t
ON h.transaction_id = t.transaction_id;
GO