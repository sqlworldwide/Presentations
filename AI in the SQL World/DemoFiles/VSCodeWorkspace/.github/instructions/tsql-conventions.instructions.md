---
applyTo: "**/*.sql"
---
# T-SQL conventions for this repository

- Always use schema-qualified names, for example `dbo.Book`, never `Book`.
- Table names are singular PascalCase: `Book`, `Author`, `Member`, `BookLoan`.
- Every table has an `int IDENTITY(1,1)` primary key named `<TableName>ID`.
- Every table has `CreatedAt datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME()` and
  `ModifiedAt datetime2(0) NULL`.
- Never use `SELECT *`. Always use explicit column lists.
- Use `NVARCHAR` for text that people type.
