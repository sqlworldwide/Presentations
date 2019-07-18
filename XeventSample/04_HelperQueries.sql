/*
Script Name: 04_HelperQueries.sql
Copied from:
https://blogs.msdn.microsoft.com/extended_events/2010/06/23/todays-subject-predicates/
*/
--Find all the predicate source
SELECT name, description, 
    (SELECT name FROM sys.dm_xe_packages WHERE guid = o.package_guid) package 
FROM sys.dm_xe_objects o 
WHERE object_type = 'pred_source' 
ORDER BY name

--Find Predicate comparator
SELECT name, description,
    (SELECT name FROM sys.dm_xe_packages WHERE guid = o.package_guid) package 
FROM sys.dm_xe_objects o 
WHERE object_type = 'pred_compare' 
ORDER BY name

