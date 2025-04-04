# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Get and Parse NAC Workflows.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    11/21/2023
#
# DESCRIPTION:	Retrieves and parses metadata of workflows in Nintex Automation Cloud. An additional loop, commented out below, can be used to delete the workflows.
#
# =====================================================================================

$now = Get-Date
$twoYearsAgo = $now.AddMonths(-24)
$body = @{"client_id"="[CLIENT ID]";"client_secret"="[CLIENT SECRET]";"grant_type"="client_credentials"}
$authResponse = Invoke-WebRequest https://us.nintex.io/authentication/v1/token -Body ($body | ConvertTo-Json) -Method POST -ContentType "application/json"

$jsonResponse = $authResponse.Content | ConvertFrom-Json
$token = "Bearer " + $jsonResponse.access_token

$headers=@{}
$headers.Add("Accept", "application/json")
$headers.Add("Authorization", $token)
$body=@{}
$body.Add("limit", "2000")
$workflowResponse = Invoke-RestMethod -Uri 'https://us.nintex.io/workflows/v1/designs' -Method GET -Headers $headers -Body $body

$workflowDetails = @()
$workflowResponse.workflows | ForEach-Object{

    if($_.published.author.name -ne $null){
    $author = $_.published.author.name
    $email = $_.published.author.email
    $lastModified = $_.published.lastPublished
    $status = "Published"
    }
    else{
    $author = $_.draft.author.name
    $email = $_.draft.author.email
    $lastModified = $_.draft.lastModified
    $status = "Draft"
    }
    if([Datetime]$lastModified -lt $twoYearsAgo){
    $workflowDetails += [PSCustomObject]@{
        WorkflowName = $_.name
        WorkflowId = $_.id
        Author = $author
        Email = $email
        LastModified = $lastModified
        Status = $status
        }
    }
}


<# Run the loop below to delete any workflows in the $workflowDetails collection.
$workflowDetails | ForEach-Object{
    $uri = 'https://us.nintex.io/workflows/v1/designs/' + $_.WorkflowId
    Write-Host "Preparing to delete workflow at:" 
    Write-Host $uri 
    Write-Host "Last Modified: " $_.LastModified
    Write-Host "Workflow ID: " $_.WorkflowId
    Write-Host "Workflow Name: " $_.WorkflowName
    Write-Host "Author: " $_.Author
    Write-Host ""
    #Read-Host "Continue?"
    $workflowResponse = Invoke-RestMethod -Uri $uri -Method DELETE -Headers $headers
    }
    #>