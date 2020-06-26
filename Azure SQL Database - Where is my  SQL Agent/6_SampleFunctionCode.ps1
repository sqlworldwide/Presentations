<#
6_SampleFunctionCode.Ps1
Written by Taiob M Ali
SqlWorldWide.com

This code will replace the built in code for Azure function
Please refer to my blog post about setting up a function app
http://sqlworldwide.com/how-to-use-managed-identity-with-azure-function-app/
#>

# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}
<#
 This function app is using 'Managed Service Identity' to connect to the Azure SQL Database
 In the interest of time I will not show the set up
 Please see details from my blog post:
 http://sqlworldwide.com/how-to-use-managed-identity-with-azure-function-app/
 I already ran the code in Azure SQL Server 'ugdemotargetserver.database.windows.net'
 Database Name:testRunBookDB 

 CREATE USER BostonAzureDemo FROM EXTERNAL PROVIDER
 GO
 ALTER  ROLE db_owner ADD MEMBER BostonAzureDemo
 GO

 Used help from following resources in setting up 'Managed Service Identity'
 https://docs.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-connect-msi
 https://www.azurecorner.com/using-managed-service-identity-in-azure-functions-to-access-azure-sql-database/
 https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity?tabs=powershell
#>

$resourceURI = "https://database.windows.net/"
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=2017-09-01"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $tokenAuthURI
$accessToken = $tokenResponse.access_token

$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Data Source =ugdemotargetserver.database.windows.net ; Initial Catalog = testRunBookDB"
$SqlConnection.AccessToken = $AccessToken
$SqlConnection.Open()

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText =  "ALTER INDEX ALL ON testRebuild REBUILD;"
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet) 