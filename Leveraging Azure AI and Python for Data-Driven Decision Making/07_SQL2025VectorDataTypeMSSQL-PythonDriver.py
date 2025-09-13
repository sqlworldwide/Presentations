'''
07_SQL2025VectorDataTypeMSSQL-PythonDrive.py
Author: Taiob Ali
Contact: taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified: September 10, 2025

Reference:
https://learn.microsoft.com/en-us/sql/connect/python/mssql-python/python-sql-driver-mssql-python-quickstart
https://learn.microsoft.com/en-us/sql/t-sql/data-types/vector-data-type

Summary:
The vector type can be used in column definitions within a CREATE TABLE statement.
'''

# activate your venv (if not already)
#C:\Users\taiob> .\.venv\Scripts\Activate.ps1

# set the env var for this session (or open a new terminal if you used setx earlier)
#$env:SQL2025_CONNSTR = "Driver={ODBC Driver 18 for SQL Server};Server=taiob2\SQL2025;Database=Tempdb;Trusted_Connection=yes;Encrypt=yes;TrustServerCertificate=yes"

# run the script
#py "C:\Presentations\Leveraging Azure AI and Python for Data-Driven Decision Making\mssqlPython.py" 

import os 
import json
import mssql_python
import random

# Read the SQL Server connection string from the 'SQL2025_CONNSTR' environment variable
conn_str = os.getenv("SQL2025_CONNSTR")
if not conn_str:
    raise RuntimeError("Set SQL2025_CONNSTR environment variable with your SQL connection string")

conn = mssql_python.connect(conn_str)

# Drop and recreate the table (this will delete existing data)
cur = conn.cursor()
cur.execute("""
DROP TABLE IF EXISTS dbo.taDemoVectors;
CREATE TABLE dbo.taDemoVectors (
    id         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_taDemoVectors PRIMARY KEY,
    vectorData VECTOR(3)         NOT NULL,
    created_at DATETIME2(0)      NOT NULL CONSTRAINT DF_taDemoVectors_created_at DEFAULT SYSUTCDATETIME()
)
""")
conn.commit()
cur.close()

cur = conn.cursor()
cur.execute("""
INSERT INTO dbo.taDemoVectors (vectorData) VALUES
('[0.1, 2.0, 30.0]'),
('[-100.2, 0.123, 9.876]'),
(JSON_ARRAY(1.0, 2.0, 3.0)); -- Requires JSON_ARRAY support
""")
conn.commit()  # commit the insert
cur.close()

cur = conn.cursor()
cur.execute("SELECT id, vectorData, created_at FROM dbo.taDemoVectors ORDER BY id")

# Fetch and print results
rows = cur.fetchall()
cols = [d[0] for d in cur.description]
print('\t'.join(cols))
for r in rows:
    print(f"{r[0]}\t{r[1]}\t{r[2]}")
    
cur.close()

conn.close()