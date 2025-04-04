# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Parse Logs for Stuck Timer Jobs.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    11/08/2022
#
# DESCRIPTION:	Imports and parses a ULS log file from SharePoint to quantify how many instances are running for each workflow, and how much time each workflow instance is consuming.
#
#
# =====================================================================================

$errorLog = @()
$ErrorActionPreference = 'Continue'
$scriptStart = Get-Date

Write-Host 'Importing Log File...'

$logFile = Import-Csv -Delimiter "`t" -LiteralPath 'C:\Users\ShaffeN\Downloads\USATRAMEGB045-20221107-1629\f44776a0-f545-c0e2-63eb-bab6c6651e9f.log' -Header 'Time', 'Process', 'Thread', 'Product', 'Category', 'EventID', 'Level', 'Message', 'Correlation' | Where-Object {($_.'Message' -Like 'In RunWorkflowElev(), begin processing events for instance:*') -OR ($_.'Message' -Like 'RunWorkflow: Events successfully delivered to Instance:*')}

Write-Host 'Finding All Workflow Instance Start Times...'

$beginTable = @()

$logFile | Where-Object -Property 'Message' -Like 'In RunWorkflowElev(), begin processing events for instance:*' | ForEach-Object {


    $beginTable += [PSCustomObject]@{
        
        Time = [datetime]::parseexact($_.'Time'.Trim(), 'MM/dd/yyyy HH:mm:ss.ff', $null)
        Process = $_.'Process'
        Correlation = $_.'Correlation'
        Instance = $_.'Message'.Replace('In RunWorkflowElev(), begin processing events for instance:','').Trim()

    }

}

Write-Host 'Finding All Workflow Instance Ending Times...'

$endTable = @{}
$wfIdTable = @{}

$ErrorActionPreference = 'SilentlyContinue'

$logFile | Where-Object -Property 'Message' -Like 'RunWorkflow: Events successfully delivered to Instance:*' | ForEach-Object {

    $Error.Clear()

    $parseEndMessage = $_.'Message'

    #Trim end message to get Instance Id
    $parseEndMessage = $parseEndMessage.Replace('RunWorkflow: Events successfully delivered to Instance:','').Trim()
    $endInstanceId = $parseEndMessage.Substring(0,$parseEndMessage.IndexOf(',')).Trim()

    #Continue trimming end message to get Workflow Id
    $trimBeforeText = 'BaseTemplate: '
    $trimBeforeAt = $parseEndMessage.IndexOf($trimBeforeText) + $trimBeforeText.Length
    $parseEndMessage = $parseEndMessage.Substring($trimBeforeAt)
    $endWorkflowId = $parseEndMessage.Substring(0,$parseEndMessage.IndexOf(',')).Trim()

    #Create hashkey
    $hashKey = $_.'Correlation' + $endInstanceId

    #Add hashkey and Id's to respective tables
    $endTable.Add($hashKey,[datetime]::parseexact($_.'Time'.Trim(), 'MM/dd/yyyy HH:mm:ss.ff', $null))
    $wfIdTable.Add($hashKey,$endWorkflowId)

    If ($Error) {

        $errorString = ("Duplication found on Correlation ID $($_.'Correlation') and Instance ID $endInstanceId")
        Write-Host $errorString
        $errorLog += $errorString

    }

}

$ErrorActionPreference = 'Continue'

Write-Host 'Calculating Run Times...'

$compareTable = @()

$beginTable | ForEach-Object {

    $startTime = $_.Time
    $startCorrelation = $_.Correlation
    $startInstance = $_.Instance
    $hashKey = $startCorrelation + $startInstance
    
    $endTime = $endTable[$hashKey]
    $wfId = $wfIdTable[$hashKey]

    If ($endTime -NE $null) {

        $runTime = New-TimeSpan -Start $startTime -End $endTime

        $compareTable += [PSCustomObject]@{

            Correlation = $startCorrelation
            Instance = $startInstance
            WorkflowId = $wfId
            Process = $_.Process
            StartTime = $startTime
            EndTime = $endTime
            RunTimeMinutes = $runTime.TotalMinutes

        }

    } else {
   
        $compareTable += [PSCustomObject]@{

            Correlation = $startCorrelation
            Instance = $startInstance
            WorkflowId = 'No Workflow Id Found'
            Process = $_.Process
            StartTime = $startTime
            EndTime = 'No EndTime Found'
            RunTimeMinutes = 'No EndTime Found'

        }                

    }

}

Write-Host 'Counting Instances and Accumulative Runtimes'
$runtimeTable = @()

$compareTable | ? {$_.WorkflowId -ne 'No Workflow Id Found'} | Group-Object WorkflowId | Sort-Object Count -Descending | ForEach-Object {
    $currWfId = $_.Name
    $totalRunTime = 0
        $compareTable | ? {$_.WorkflowId -ne 'No Workflow Id Found'}| ForEach-Object {
                if ($currWfId -eq $_.WorkflowId) {
                $totalRuntime = $totalRuntime + $_.RunTimeMinutes
                }
        }

        $runtimeTable += [PSCustomObject]@{
            WorkflowId = $currWfId
            InstanceCount = $_.Count
            AccumulativeRuntime = $totalRunTime
        }
}

$compareTable | Sort-Object StartTime | Out-GridView
$runtimeTable | Sort-Object AccumulativeRuntime -Descending | Out-GridView


<#Write-Host 'Exporting Files...'

$compareTable | Sort-Object StartTime | Export-Csv -LiteralPath C:\Scripts\ParseLogs\AllInstances.csv -NoTypeInformation
$runtimeTable | Sort-Object AccumulativeRuntime -Descending | Export-Csv -LiteralPath C:\Scripts\ParseLogs\Runtimes.csv -NoTypeInformation
$errorLog | Out-File -LiteralPath C:\Scripts\ParseLogs\Duplication_Log.txt
#>
Write-Host "Counted $($errorLog.Count) duplication errors, please review Duplication Log for possible manual checks."
Write-Host 'Complete!'

$scriptEnd = Get-Date
$scriptRuntime = New-TimeSpan -Start $scriptStart -End $scriptEnd

Write-Host "Runtime $scriptRuntime"