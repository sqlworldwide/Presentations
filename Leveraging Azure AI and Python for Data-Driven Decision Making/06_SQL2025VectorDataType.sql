/*
06_SQL2025VectorDataType

Author: Taiob Ali
Contact: taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified: September 10, 2025

Reference:
https://learn.microsoft.com/en-us/sql/t-sql/data-types/vector-data-type

Summary:
The vector type can be used in column definitions within a CREATE TABLE statement.
*/

USE tempdb;
GO

-- Re-create the demo table
DROP TABLE IF EXISTS dbo.taDemoVectors;
GO

CREATE TABLE dbo.taDemoVectors (
    id         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_taDemoVectors PRIMARY KEY,
    vectorData VECTOR(3)         NOT NULL,
    created_at DATETIME2(0)      NOT NULL CONSTRAINT DF_taDemoVectors_created_at DEFAULT SYSUTCDATETIME()
);
GO

/*
The following example inserts three rows into the table.
The first two rows use string literals to define the vector values.
The third row uses the JSON_ARRAY function (if available) to create a vector from an array of numbers.
*/
INSERT INTO dbo.taDemoVectors (vectorData) VALUES
('[0.1, 2.0, 30.0]'),
('[-100.2, 0.123, 9.876]'),
(JSON_ARRAY(1.0, 2.0, 3.0)); -- Requires JSON_ARRAY support
GO

-- Retrieve all rows
SELECT id, vectorData, created_at
FROM dbo.taDemoVectors
ORDER BY id;
GO