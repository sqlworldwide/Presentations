USE [SqlAssessmentDemo];
GO
SELECT 
	CONVERT(date, Timestamp) AS [Date],
	Severity,
	COUNT(RulesetName) AS [NotCompliant]
FROM [SqlAssessmentDemo].[dbo].[Results]
GROUP BY CONVERT(date, Timestamp),Severity
ORDER BY [Date] DESC;
GO

USE [SqlAssessmentDemo];
GO
SELECT 
	CONVERT(date, Timestamp) AS [Date],
	COUNT(RulesetName) AS [NotCompliant]
FROM [SqlAssessmentDemo].[dbo].[Results]
GROUP BY CONVERT(date, Timestamp)
ORDER BY [Date] DESC;
GO