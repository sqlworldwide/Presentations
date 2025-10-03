/*
SimulateDeadlock.sql
Written by Taiob M Ali
taiob@sqlworlwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

 Connect to sqlserverfdddemo.database.windows.net
 Change database context to dbfdddemo
*/

DROP TABLE IF EXISTS dbo.dt_Employees;
GO
CREATE TABLE dbo.dt_Employees (
    EmpId INT IDENTITY,
    EmpName VARCHAR(16) NOT NULL,
    Phone VARCHAR(16) NOT NULL
);
GO

INSERT INTO dbo.dt_Employees (EmpName, Phone)
VALUES ('Martha', '800-555-1212'), ('Jimmy', '619-555-8080');
GO

DROP TABLE IF EXISTS dbo.dt_Suppliers;
GO
CREATE TABLE dbo.dt_Suppliers(
    SupplierId INT IDENTITY,
    SupplierName VARCHAR(64) NOT NULL,
    Fax VARCHAR(16) NOT NULL
);
GO

INSERT INTO dbo.dt_Suppliers (SupplierName, Fax)
VALUES ('Acme', '877-555-6060'), ('Rockwell', '800-257-1234');
GO

/*
** Run this in current window
*/
BEGIN TRAN;
UPDATE dbo.dt_Employees
SET EmpName = 'Mary'
WHERE EmpId = 1;

/*
** Open another window and run this
*/
BEGIN TRAN;
UPDATE dbo.dt_Suppliers
SET Fax = N'555-1212'
WHERE SupplierId = 1;

UPDATE dbo.dt_Employees
SET Phone = N'555-9999'
WHERE EmpId = 1;

/*
** Come back to this window and run this
*/
UPDATE dbo.dt_Suppliers
SET Fax = N'555-1212'
WHERE SupplierId = 1;

/*
** You will get a deadlock message in one of the window
** Commit session 
** Clean up
*/
COMMIT tran
DROP TABLE IF EXISTS dbo.dt_Suppliers;
GO
DROP TABLE IF EXISTS dbo.dt_Employees
GO

/*
** After about 5~7 minuetes of running this deadlock should fire alert
** that was configured in portal
*/

/*
After dropping the two tables from above demo
Use the query below to find the drop event
*/

/*
// This is Kusto Query
// Ref: https://techcommunity.microsoft.com/t5/azure-database-support-blog/azure-sql-db-and-log-analytics-better-together-part-3-query/ba-p/1034222
// Who DROPPED my table?

let ServerName = "sqlserverfdddemo";
let DBName = "dbfdddemo";
AzureDiagnostics
| where TimeGenerated >= ago(1d)
| where LogicalServerName_s =~ ServerName
| where database_name_s =~ DBName
| where Category =~ "SQLSecurityAuditEvents"
| where action_name_s in ("BATCH COMPLETED", "RPC COMPLETED")
| where statement_s contains "DROP" or statement_s contains "TRUNCATE" 
| project TimeGenerated, event_time_t, LogicalServerName_s, database_name_s, succeeded_s, session_id_d, action_name_s,
            client_ip_s, session_server_principal_name_s , database_principal_name_s, statement_s, additional_information_s, application_name_s
| top 1000 by TimeGenerated desc

*/