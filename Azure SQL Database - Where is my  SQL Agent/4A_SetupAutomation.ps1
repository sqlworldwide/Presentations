<#
============================================================================
4A_SetupAutomation
Written by Taiob M Ali
SqlWorldWide.com

This script will create 
    Azure automation account
    Create Credential
    Create Blank runbook (Type PowerShellWorkflow)
============================================================================
#>
Import-Module Az 

# Sign in to Azure
#$VerbosePreference = $DebugPreference = "Continue"
Connect-AzAccount
#Use below code if you have multiple subscription and you want to use a particular one
Set-AzContext -SubscriptionId 'your subscription id'

# Declare variables
# The data center and resource name for your resources
$resourceGroupName = "sqlagentdemo"
$primaryLocation = "East US 2" 

# The logical server name: Use a random value or replace with your own value (do not capitalize)
$automationAccountName = "ugdemo2"
$credentialName = "sqlservercredentials"

# Set an admin login and password for your database
# The login information for the server
$adminlogin = "taiob"

#Replace with password file location
$password = Get-Content "C:\Azure SQL Database - Where is my  SQL Agent\password.txt"
$passwordSecure =ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $passwordSecure

#Creating a automation account
New-AzAutomationAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $automationAccountName `
    -Location $primaryLocation

#Creating credential
New-AzAutomationCredential `
    -AutomationAccountName $automationAccountName `
    -Name $credentialName `
    -Value $credential `
    -ResourceGroupName $resourceGroupName

#Creating a blank runbook
New-AzAutomationRunbook `
    -ResourceGroupName $resourceGroupName `
    -AutomationAccountName $automationAccountName `
    -Name 'Update-SQLIndexRunbook' `
    -Type 'PowerShellWorkflow' `
    -LogProgress $true `
    -LogVerbose $true
