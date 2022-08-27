--Connect to readscaleoutserver1004.database.windows.net
--Chage database context to sqlDatabaseReadScale1004
SELECT DB_NAME() AS [DatabaseName], DATABASEPROPERTYEX(DB_NAME(), 'Updateability') AS [Writable?]
--change connectin string to ApplicationIntent=READONLY
--Chage database context to sqlDatabaseReadScale1004
SELECT DB_NAME() AS [DatabaseName], DATABASEPROPERTYEX(DB_NAME(), 'Updateability') AS [Writable]