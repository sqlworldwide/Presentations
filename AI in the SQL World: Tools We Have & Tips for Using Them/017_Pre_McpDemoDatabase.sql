/************************************************************
017_Pre_McpDemoDatabase.sql
Demo 2 setup - the small mcpDemo database for SQL MCP Server (020)
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 4, 2026

Drops and recreates mcpDemo, so it is safe to re-run.
dbo.EmployeePayroll is deliberately NOT published in DemoFiles\mcpDemo\dab-config.json:
that table is the point of 020.
************************************************************/

USE [master];
GO

/*
1. Drop and recreate the database.
*/
IF DB_ID(N'mcpDemo') IS NOT NULL
BEGIN
  ALTER DATABASE [mcpDemo] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE [mcpDemo];
END;
GO

CREATE DATABASE [mcpDemo];
GO

USE [mcpDemo];
GO

/*
2. Create the tables. dbo.EmployeePayroll is the table that 020 must not reach.
*/
DROP TABLE IF EXISTS dbo.Product;
GO

CREATE TABLE dbo.Product
(
  ProductId int            IDENTITY(1, 1) PRIMARY KEY,
  Name      nvarchar(100)  NOT NULL,
  Category  nvarchar(50)   NOT NULL,
  ListPrice decimal(10, 2) NOT NULL
);
GO

DROP TABLE IF EXISTS dbo.SalesOrder;
GO

CREATE TABLE dbo.SalesOrder
(
  OrderId   int  IDENTITY(1, 1) PRIMARY KEY,
  ProductId int  NOT NULL REFERENCES dbo.Product (ProductId),
  Quantity  int  NOT NULL,
  OrderDate date NOT NULL
);
GO

DROP TABLE IF EXISTS dbo.EmployeePayroll;
GO

CREATE TABLE dbo.EmployeePayroll
(
  EmployeeId   int            IDENTITY(1, 1) PRIMARY KEY,
  FullName     nvarchar(100)  NOT NULL,
  NationalId   char(11)       NOT NULL,
  AnnualSalary decimal(12, 2) NOT NULL
);
GO

/*
3. Load a few rows.
*/
INSERT INTO dbo.Product (Name, Category, ListPrice)
VALUES
  (N'Trail Runner 200', N'Bikes',       1299.00),
  (N'Rain Shell',       N'Clothing',     149.00),
  (N'Trail Helmet',     N'Accessories',   89.00),
  (N'Commuter 500',     N'Bikes',        899.00);
GO

INSERT INTO dbo.SalesOrder (ProductId, Quantity, OrderDate)
VALUES
  (1,  3, '2026-07-14'),
  (2, 12, '2026-07-15'),
  (3,  7, '2026-08-01'),
  (1,  2, '2026-08-05'),
  (4,  5, '2026-08-09');
GO

INSERT INTO dbo.EmployeePayroll (FullName, NationalId, AnnualSalary)
VALUES
  (N'A. Employee', '000-00-0000', 125000.00);
GO

/*
4. Check. Expect Clothing 12, Bikes 10, Accessories 7 - the answer 020 should reach.
*/
SELECT
  p.Category,
  SUM(o.Quantity) AS total_quantity
FROM dbo.SalesOrder AS o
INNER JOIN dbo.Product AS p
  ON o.ProductId = p.ProductId
GROUP BY p.Category
ORDER BY total_quantity DESC;
GO
