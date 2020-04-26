<#
5_CreateElasticJobAgent.ps1
Written by Taiob M Ali
SqlWorldWide.com

This script will create 
    A elastic job agent using resources created in 0_SetupDemo.ps1 
    
Credit:
https://docs.microsoft.com/en-us/azure/sql-database/elastic-jobs-powershell#create-the-elastic-job-agent
https://docs.microsoft.com/en-us/powershell/module/az.sql/new-azsqlelasticjobagent?view=azps-3.1.0
#>

New-AzSqlElasticJobAgent `
-ResourceGroupName 'sqlagentdemo' `
-ServerName 'ugdemojobserver' `
-DatabaseName 'jobdatabase' `
-Name 'agentdemo'

