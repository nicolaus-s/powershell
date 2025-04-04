# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    FarmWorkflowInventory.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    08/24/2023
#
# DESCRIPTION:	Queries the Workflows and Consumptions table in the Nintex databases to compile a list of all workflows and their locations.
#
# REFERENCES: Previous scripts written by Nintex colleagues.
#
#
# =====================================================================================

Write-progress -Activity "Importing dependencies..." -Id 1 -PercentComplete "5" -Status "Please Wait."

#Adding SharePoint Powershell Snapin
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA silentlycontinue

# Loading SharePoint and Nintex Objects into the PS session
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
[void][System.Reflection.Assembly]::LoadWithPartialName("Nintex.Workflow")

Write-progress -Activity "Open SQL connection..." -Id 1 -PercentComplete "20" -Status "Please Wait."

#Creating SQL client
$cmd = New-Object -TypeName System.Data.SqlClient.SqlCommand
 
$cmd.CommandType = [System.Data.CommandType]::Text
$cmd.CommandTimeout = '0'

#Query Workflows table
$cmd.CommandText = "SELECT [WebApplicationId], [SiteId], [WebId], [ListId], [WorkflowId], [WorkflowName] FROM [dbo].[Workflows]"

$workflowNames = @{}

Write-progress -Activity "Querying all Nintex databases for workflows..." -Id 1 -PercentComplete "40" -Status "Please Wait."

#Find all Nintex content databases
foreach ($database in [Nintex.Workflow.Administration.ConfigurationDatabase]::GetConfigurationDatabase().ContentDatabases)
{
 
$reader = $database.ExecuteReader($cmd)

# Creating a table of all existing workflow names
while($reader.Read())
{
$hashKey = $reader["WebApplicationId"].toString() + $reader["SiteId"].toString() + $reader["ListId"].toString() + $reader["WorkflowId"].toString()
$workflowNames.Add($hashKey, $reader["WorkflowName"])
}
}

Write-progress -Activity "Retrieving licensing usage data..." -Id 1 -PercentComplete "60" -Status "Please Wait."

#Get Nintex configuration database name
$CFGDB = [Nintex.Workflow.Administration.ConfigurationDatabase]::GetConfigurationDatabase()

#Query Consumptions table
$cmd.CommandText = "SELECT [WebApplicationId], [SiteId], [WebId], [ListId], [WorkflowId], [ActionCount], [IsProduction], [AllActionCount] FROM [dbo].[Consumptions]"

$consumptionsTableIDs = @()
$reader = $CFGDB.ExecuteReader($cmd)

Write-progress -Activity "Converting and compiling data..." -Id 1 -PercentComplete "80" -Status "Please Wait."

#Combine Consumptions data with workflow names, site urls, and list names.
while($reader.Read()){
    if(![string]::IsNullOrEmpty($reader["SiteID"])){
    $Site = $(Get-SPSite -identity $reader["SiteID"])
    }
 
    if(![string]::IsNullOrEmpty($reader["WebID"])){
    $SubSite = $Site.Allwebs[[Guid]"$($reader["WebID"])"]
    }
    if(![string]::IsNullOrEmpty($reader["ListID"])){
    $List = $SubSite.Lists[[Guid]"$($reader["ListID"])"]
    }
    if($reader["ActionCount"] -gt 5){
    $isBillable = $true
    }
    if($reader["ActionCount"] -le 5){
    $isBillable = $false
    }
    $hashKey = $reader["WebApplicationId"].toString() + $reader["SiteId"].toString() + $reader["ListId"].toString() + $reader["WorkflowId"].toString()
    $consumptionsTableIDs += [PSCustomObject]@{
        URL = $SubSite.Url
        ListName = $List.Title
        WorkflowID = $reader["WorkflowId"]
        WorkflowName = $workflowNames[$hashKey]
        BillableWorkflow = $isBillable
        BillableActions = $reader["ActionCount"]
        IsProduction = $reader["IsProduction"]
        TotalActions = $reader["AllActionCount"]
    }
}

Write-progress -Activity "Outputting CSV file..." -Id 1 -PercentComplete "100" -Status "Awaiting user input..."

#Output CSV file
$path = Read-Host 'Enter a file path, file name, and .csv extension for output'
$consumptionsTableIDs | Export-CSV -Path $path -NoTypeInformation

#Out-GridView for testing
#$consumptionsTableIDs | Out-GridView
#$workflowNames | Out-GridView