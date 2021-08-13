-- To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

  
-- To enable the feature.  
EXECUTE sp_configure 'max server memory', 12700;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  