/*
Script Name: 005_BatchModeOnRowStoreUsed.sql

Demo: 
	BatchModeOnRowStoreUsed (SQL2019 need new SSMS)
Watch this video  Niko Neugebauer
https://www.youtube.com/watch?v=NbIqVA-XZ9k
Highligt from the above video:
The difference between the Row Execution Mode and the Batch Execution Mode is that 
the traditional Row Execution Mode processes are performed on a row-by-row basis, 
essentially through the GetNext() function between different iterators in the execution plans. 

The Batch Execution Mode is vector-based, processing and grouping the data into batches 
- between 64 and 912 rows at a time. 
With the help of SIMD instructions, improvements by 10s and even 100s of times can be achieved 
when processing big amounts of data (millions and billions of rows).
*/


/*
Changing compatibility level to SQL 2017
Turn on Actual Execution Plan (Ctrl+M)
Look at the properties of the index scan
Look at the elapsed time from QueryTimeStats
For DEMO only, please do not do this in producito
*/
USE [AdventureWorks];
GO
DBCC FREESYSTEMCACHE ('Adventureworks');
GO
ALTER DATABASE Adventureworks SET COMPATIBILITY_LEVEL = 140;
GO
SELECT COUNT_BIG(*) AS [NumberOfRows] FROM dbo.bigTransactionHistory;
GO

/*
Changing compatibility level to SQL 2019
Turn on Actual Execution Plan (Ctrl+M)
Look at the properties of the index scan
Look at properties of select statement and you will see BatchModeOnRowStoreUsed=True
Look at the elapsed time from QueryTimeStats
For DEMO only, please do not do this in produciton
*/
USE [AdventureWorks];
GO
DBCC FREESYSTEMCACHE ('Adventureworks'); 
GO
ALTER DATABASE Adventureworks SET COMPATIBILITY_LEVEL = 150;
GO
SELECT COUNT_BIG(*) AS [NumberOfRows] FROM dbo.bigTransactionHistory;
GO


