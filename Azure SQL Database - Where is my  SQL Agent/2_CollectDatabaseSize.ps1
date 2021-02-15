<#
============================================================================
2_CollectDatabaseSize.Ps1
Written by Taiob M Ali
SqlWorldWide.com

This script will  
    Iterate through all resource type SQL Server
    collect file size of from all server and all Azure SQL Database
    save the result in local server
============================================================================
#>
Import-module SqlServer
Import-Module dbatools

Set-AzContext -SubscriptionId '18d92f52-ac34-4379-ab8b-5a5106f1c54e'
# Putting my query in a variable
$databaseQuery = 
"
SELECT 
		GETDATE() AS collectedAT,
		@@SERVERNAME AS serverName, 
		DB_NAME() AS databaseName, 
		LEFT(a.name, 64) AS fileName,
		a.file_id AS fileId,
		a.size AS fileSizeMB,
		CONVERT(DECIMAL(12, 2), ROUND(FILEPROPERTY(a.name,'SpaceUsed')/ 128.000, 2)) AS spaceUsedMB,
		CONVERT(DECIMAL(12, 2), ROUND(( a.size - FILEPROPERTY(a.name,'SpaceUsed'))/ 128.000, 2)) AS freeSpaceMB,
		CONVERT(DECIMAL(12, 2), (CONVERT(DECIMAL(12, 2), ROUND((a.size - FILEPROPERTY(a.name,'SpaceUsed'))/128.000, 2))*100)/ CONVERT(DECIMAL(12, 2), ROUND(a.size / 128.000, 2))) as percentFree,
		a.physical_name AS physicalName 
FROM sys.database_files a
"
$localInstanceName = 'DESKTOP-50O69FS\SQL2019'
$localDatabaseName = 'dbadatabase'
$localTableName = 'databasesize'

# Set an admin login and password for your database
# The login information for the server
$adminlogin = "taiob"
#Replace with password file location
$password = Get-Content "C:\password.txt"
$password = ConvertTo-SecureString -String $password -AsPlainText -Force
#$databaseCredentials = Get-Credential -Message "Please provide credentials for $SqlInstance"
$databaseCredentials = New-Object System.Management.Automation.PSCredential($adminlogin, $password) 

#Get all resources type SQL Server, loop through all SQL Server and collect size for each database
$resources = Get-AzResource -ResourceGroupName 'sqlagentdemo' | Where-Object { $_.ResourceType -eq "Microsoft.Sql/servers" } | Select-Object name
foreach ($SqlInstance in $resources) { 
    $SqlInstance = "$($SqlInstance.Name).database.windows.net"
    $databases = Invoke-Sqlcmd -Query "select name from sys.databases" -ServerInstance $SqlInstance `
        -Username $databaseCredentials.GetNetworkCredential().UserName `
        -Password $databaseCredentials.GetNetworkCredential().Password `
        -Database 'master'

    foreach ($databaseName in $databases.name) {
        Write-Host "Query results for database $databaseName.`n"
        Invoke-Sqlcmd $databaseQuery -ServerInstance $SqlInstance `
            -Username $databaseCredentials.GetNetworkCredential().UserName `
            -Password $databaseCredentials.GetNetworkCredential().Password `
            -Database $databaseName | `
            Write-DbaDbTableData -SqlInstance $localInstanceName -Database $localDatabaseName -Table $localTableName
    }
}
<#
#See the result
Invoke-DbaQuery `
    -SqlInstance $localInstanceName `
    -Query 'SELECT TOP 20 * FROM DbaDatabase.dbo.databasesize ORDER BY collectedAT DESC ;' | Format-Table -AutoSize
#>

