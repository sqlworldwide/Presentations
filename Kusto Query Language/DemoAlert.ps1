<#
DemoAlert.Ps1
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

# Run below code if you need to check what version of PowerShell you are running
# $PSVersionTable.PSVersion

# Run below code if Az Module is not in your profile 
Import-Module Az 

# Sign in to Azure
#$VerbosePreference = $DebugPreference = "Continue"
Connect-AzAccount
#if you need to see the list of your subscription
#$SubscriptionList =Get-AzSubscription
#$SubscriptionList
#Use below code if you have multiple subscription and you want to use a particular one
Set-AzContext -SubscriptionId 'bda7bbb8-69a4-4354-818c-416f42c60a58'

<#
Breaking change warnings are a means for the cmdlet authors to communicate with the end users any upcoming breaking changes in the cmdlet. Most of these changes will be taking effect in the next breaking change release.
How do I get rid of the warnings?
To suppress these warning messages, set the environment variable 'SuppressAzurePowerShellBreakingChangeWarnings' to 'true'.
#>
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

# Declare variables
# The data center and resource name for your resources
$resourceGroupName = "sqlalertdemo"
$rgLocation = "East US"  
$workspaceName = "Sqlalertdemo"
# The logical server name: Use a random value or replace with your own value (do not capitalize)
$sqlServerName = "sqlalertdemoserver"

# Set an admin login and password for your database
# The login information for the server
$adminlogin = "taiob"
#Replace with password file location
$password = Get-Content "C:\password.txt"

# The ip address range that you want to allow to access your server - change as appropriate
$ipinfo = Invoke-RestMethod http://ipinfo.io/json 
$startip = $ipinfo.ip
$endip = $ipinfo.ip 

# The database name
$alertDemoDatabase = "sqlalertdemodatabase"

#Check if resource group exist
$resGrpChk = Get-AzResourceGroup `
    -Name $resourceGroupName `
    -ev notPresent `
    -ea 0

if ($resGrpChk)
  {  
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
    -Location $rgLocation    

$resGrpChk = Get-AzResourceGroup `
    -Name $resourceGroupName `
    -ev Present `
    -ea 1
if ($resGrpChk)
{
Write-Host 'Resource group created' `
    -fore white `
    -back green 
 }  
  
#Create job server
New-AzSqlServer `
    -ResourceGroupName $resourceGroupName `
    -ServerName $sqlServerName `
    -Location $rgLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential `
    -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

#Configure a server firewall rule for job server
 New-AzSqlServerFirewallRule `
    -ResourceGroupName $resourceGroupName `
    -ServerName $sqlServerName `
    -FirewallRuleName "TaiobDesktop" `
    -StartIpAddress $startip `
    -EndIpAddress $endip

#Set Allow access to Azure services 
New-AzSqlServerFirewallRule `
-ServerName $sqlServerName `
-ResourceGroupName $resourceGroupName  `
-AllowAllAzureIPs


#Create a empty database
New-AzSqlDatabase  `
    -ResourceGroupName $resourceGroupName `
    -ServerName $sqlServerName `
    -DatabaseName $alertDemoDatabase `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0" `
    -MaxSizeBytes 10737418240 

# Create a log analytics workspace
New-AzOperationalInsightsWorkspace `
  -Location $rgLocation `
  -Name $workspaceName `
  -Sku Standard `
  -ResourceGroupName $resourceGroupName

# List of solutions to enable
$Solutions = "Security", "Updates", "SQLAssessment"
# Add solutions
foreach ($solution in $Solutions) {
    Set-AzOperationalInsightsIntelligencePack `
    -ResourceGroupName $resourceGroupName `
    -WorkspaceName $workspaceName `
    -IntelligencePackName $solution -Enabled $true
}

# Setting up Database to send diagonstic data to log analytics workspace created above
$workspaceId = (Get-AzResource -name $workspaceName).ResourceId
$databaseId = (Get-AzsqlDatabase -ServerName $sqlServerName -DatabaseName $alertDemoDatabase -ResourceGroupName $resourceGroupName).ResourceId

# Make sure your subscription is registered for microsoft.insights
# If you get an error about 'not registered' read this
# https://kasunkodagoda.com/2019/03/10/registering-azure-resource-providers-to-enable-azure-features/
Set-AzDiagnosticSetting `
    -WorkspaceId $workspaceId `
    -ResourceId $databaseId `
    -Enabled $True `
    -Name "sqlalertdemo"


#Setting up action group
$emailaddress = 'taiob@sqlworldwide.com'
$phoneNumber = 9784272092
$emailDBA = New-AzActionGroupReceiver -Name 'emailDBA' -EmailAddress $emailaddress
$smsDBA = New-AzActionGroupReceiver -Name 'smsDBA' -SmsReceiver -CountryCode '1' -PhoneNumber $phoneNumber 
$phoneDBA = New-AzActionGroupReceiver -Name 'phoneDBA' -VoiceReceiver -VoiceCountryCode '1' -VoicePhoneNumber $phoneNumber 
 
Set-AzActionGroup `
    -Name 'notifydbadeadlock' `
    -ResourceGroupName $resourceGroupName `
    -ShortName 'deadlock' `
    -Receiver $emailDBA,$smsDBA,$phoneDBA
   
#Run SimulateDeadlock.sql script

#Clean up by removing resource group name
#Run this command after you are done testing with all other script
#Remove-AzResourceGroup -ResourceGroupName $resourceGroupName
 