<#
0_SetupDemo.Ps1
Written by Taiob M Ali
SqlWorldWide.com

This script will create 
    A resource group 
    A logical SQL server
    Few sample databases
    Clean up code at the end

Script can take between 40~50 minutes during my test. Mileage will vary in your case

Credit:
https://docs.microsoft.com/en-us/azure/sql-database/sql-database-get-started-powershell
https://gallery.technet.microsoft.com/scriptcenter/Get-ExternalPublic-IP-c1b601bb
#>


# Starting with Azure PowerShell version 7.0, Azure PowerShell requires PowerShell version 5.0. 
# To check the version of PowerShell running on your machine, run the following command.
# If you have an outdated version, 
# visit https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6#upgrading-existing-windows-powershell.

$PSVersionTable.PSVersion
#Import-Module Az 

# Sign in to Azure
#$VerbosePreference = $DebugPreference = "Continue"
Connect-AzAccount
#Use below code if you have multiple subscription and you want to use a particular one
Set-AzContext -SubscriptionId 'bda7bbb8-69a4-4354-818c-416f42c60a58'

# Declare variables
# The data center and resource name for your resources
$resourceGroupName = "sqlagentdemo"
$primaryLocation = "East US"  
$elasticPoolName = "sqlagentdemo"

# The logical server name: Use a random value or replace with your own value (do not capitalize)
$jobServerName = "ugdemojobserver"
$targetServerName = "ugdemotargetserver"

# Set an admin login and password for your database
# The login information for the server
$adminlogin = "taiob"
#Replace with password file location
$password = Get-Content "C:\Azure SQL Database - Where is my  SQL Agent\password.txt"

# The ip address range that you want to allow to access your server - change as appropriate
$ipinfo = Invoke-RestMethod http://ipinfo.io/json 
$startip = $ipinfo.ip
$endip = $ipinfo.ip 

# The database name
$jobDatabase = "jobdatabase"
$collectionDatabase = "dbawarehouse"
$databaseName1 = "adventureworks"
$databaseName2 = "WideWorldImporters"


#Check if resource group exist
$resGrpChk = Get-AzResourceGroup `
    -Name $resourceGroupName `
    -ev notPresent `
    -ea 0

if ($resGrpChk) {  
    #Delete resource group
    Remove-AzResourceGroup `
        -Name $resourceGroupName -Confirm   
    Write-Host 'Resource group deleted' `
        -fore white `
        -back green
}
 
#Creates new resource group
New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $primaryLocation    

$resGrpChk = Get-AzResourceGroup `
    -Name $resourceGroupName `
    -ev Present `
    -ea 1
if ($resGrpChk) {
    Write-Host 'Resource group created' `
        -fore white `
        -back green 
}  
  
#Create job server
New-AzSqlServer `
    -ResourceGroupName $resourceGroupName `
    -ServerName $jobServerName `
    -Location $primaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

#Configure a server firewall rule for job server
New-AzSqlServerFirewallRule `
    -ResourceGroupName $resourceGroupName `
    -ServerName $jobServerName `
    -FirewallRuleName "TaiobDesktop" `
    -StartIpAddress $startip `
    -EndIpAddress $endip

#Set Allow access to Azure services 
New-AzSqlServerFirewallRule `
    -ServerName $jobServerName `
    -ResourceGroupName $resourceGroupName  `
    -AllowAllAzureIPs

#Create an empty database to hold job metadata
New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $jobServerName `
    -DatabaseName $jobDatabase `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0" `
    -MaxSizeBytes 10737418240 
#Create an empty database to hold job output
New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $jobServerName `
    -DatabaseName $collectionDatabase `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0" `
    -MaxSizeBytes 10737418240 


#Create target server
New-AzSqlServer `
    -ResourceGroupName $resourceGroupName `
    -ServerName $targetServerName `
    -Location $primaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

#Configure a server firewall rule for target server
New-AzSqlServerFirewallRule `
    -ResourceGroupName $resourceGroupName `
    -ServerName $targetServerName `
    -FirewallRuleName "TaiobDesktop" `
    -StartIpAddress $startip `
    -EndIpAddress $endip

#Set Allow access to Azure services 
New-AzSqlServerFirewallRule `
    -ServerName $targetServerName `
    -ResourceGroupName $resourceGroupName  `
    -AllowAllAzureIPs


#Create a database using adventureworks smaple
New-AzSqlDatabase  `
    -ResourceGroupName $resourceGroupName `
    -ServerName $targetServerName `
    -DatabaseName $databasename1 `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0" `
    -MaxSizeBytes 10737418240 `
    -SampleName "AdventureWorksLT"

#Create a database using wideworldimporters bacpac file
#https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "http://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac"
$output = "c:\WideWorldImporters-Standard.bacpac"
Invoke-WebRequest -Uri $url -OutFile $output

Set-Location "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\"

.\sqlpackage.exe /a:Import /sf:$output /tsn:"$targetServerName.database.windows.net" `
    /tdn:$databaseName2 /tu:$adminlogin /tp:$password


New-AzSqlElasticPool `
    -ResourceGroupName $resourceGroupName `
    -ServerName $targetServerName `
    -ElasticPoolName $elasticPoolName `
    -Edition "Standard" `
    -Dtu 400 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 100

New-AzSqlDatabase  `
    -ResourceGroupName $resourceGroupName `
    -ServerName $targetServerName `
    -DatabaseName "test1" `
    -MaxSizeBytes 10737418240 `
    -ElasticPoolName $elasticPoolName

#Create a database for runbook demo later on 
New-AzSqlDatabase  `
    -ResourceGroupName $resourceGroupName `
    -ServerName $targetServerName `
    -DatabaseName testRunBookDB `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0" `
    -MaxSizeBytes 10737418240 `



#To use Elastic Jobs, register the feature in your Azure subscription by running the following command 
#(this only needs to be run once in each subscription where you want to use Elastic Jobs):
Register-AzProviderFeature `
    -FeatureName sqldb-JobAccounts `
    -ProviderNamespace Microsoft.Sql

#Clean up by removing resource group name
#Run this command after you are done testing with all other script
#Remove-AzResourceGroup -ResourceGroupName $resourceGroupName
