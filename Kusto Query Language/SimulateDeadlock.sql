/*
** Script Name: SimulateDeadlock.sql
** Written by Taiob M Ali
** SqlWorldWide.com

** Connect to sqlalertdemoserver.database.windows.net
** Change database context to sqlalertdemodatabase
*/

DROP TABLE IF EXISTS dbo.dt_Employees;
GO
CREATE TABLE dbo.dt_Employees (
    EmpId INT IDENTITY,
    EmpName VARCHAR(16),
    Phone VARCHAR(16)
);
GO

INSERT INTO dbo.dt_Employees (EmpName, Phone)
VALUES ('Martha', '800-555-1212'), ('Jimmy', '619-555-8080');
GO

DROP TABLE IF EXISTS dbo.dt_Suppliers;
GO
CREATE TABLE dbo.dt_Suppliers(
    SupplierId INT IDENTITY,
    SupplierName VARCHAR(64),
    Fax VARCHAR(16)
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

DROP TABLE IF EXISTS dbo.dt_Suppliers;
GO
DROP TABLE IF EXISTS dbo.dt_Employees
GO

/*
** After about 5~7 minuetes of running this deadlock should fire alert
** that was configured by DemoAlert.ps1 file
*/
