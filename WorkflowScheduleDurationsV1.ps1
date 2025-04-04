# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    WorkflowScheduleDurationsV1.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    02/18/2022
#
# DESCRIPTION:	Parses the Schedule column from the WorkflowSchedule table to calculate runtime durations for each scheduled workflow over the last 24 hours. Simplified version 
#               of WorkflowSchedule Query and Projection.ps1 that accepts the data in a CSV format instead of querying the SQL database directly.
#
# =====================================================================================

<# 

Using this script:
1. In your Nintex Workflow Configuration Database, SELECT * FROM WorkflowSchedule and save the results in a CSV file.
2. Change line 48 to contain the file path to the CSV file from step 1.
3. Change line 105 to the output file path.

The output file is a CSV containing calculated runtimes of each scheduled workflow to help identify long-running scheduled workflows.

Using the report:
1. In the report, resolve the SiteId and WebId to a URL by running the following in the SharePoint Management Shell: Get-SPSite [SiteId] | Get-SPWeb [WebId] | fl ID, URL
2. Navigate to Nintex Administration > Database Management > Veiw Database Mappings and see which Nintex content database the site collection is mapped to.
3. Query the relevant Nintex Content Database with SELECT * FROM Workflows WHERE WorkflowId = '[WorkflowId]'
4. Locate the WorkflowName column.
5. Navigate to the URL found in step 4, review the Workflow Inventory, and look for the workflow in question.


Notes: 

The runtimes are calculated between the 'PreviousRunTime' of the current instance and the last instance. As such, it is possible for the first workflow instance that is run by the 
Nintex Workflow Scheduler to be incorrect. For example, if Workflow A was scheduled to run at 1:30, and Workflow B was scheduled workflow was at 2:30, the output of this script 
would suggest that Workflow B ran for 1 hour which may not be true. Check the workflow history of the workflow in question to ensure that the runtime duration in the report matches
the runtime of the workflow in the workflow history from that scheduled date/time. This will help ensure that you are reviewing a workflow that needs to be addressed.

#>

$errorLog = @()
$ErrorActionPreference = 'Continue'
$scriptStart = Get-Date

Write-Host 'Importing File...'

#File path to a CSV file containing the contents of the WorkflowSchedule table
$path = "C:\WorkflowSchedule.csv"

$csv = Import-Csv -Path $path

$WFScheduleTable = @()

$csv | ForEach-Object {

    #Simplify Schedule column XML to make it readable for PowerShell
    $str = $_.'Schedule'
    $index = $str.IndexOf("<MaximumRepeats>")
    $replaceMe = $str.Substring(0, $index)
    $trimSchedule = $str.Replace($replaceMe, "<ScheduleDetails>")
    $xmlSchedule = [xml]$trimSchedule
   
    #Create workflow schedule objects
    $WFScheduleTable += [PSCustomObject]@{
 
        ScheduleId = $_.'ScheduleId'
        ItemId = $_.'ItemId'
        ListId = $_.'ListId'
        WebId = $_.'WebId'
        SiteId = $_.'SiteId'
        WorkflowId = $_.'WorkflowId'
        NextRunTime = $_.'NextRunTime'
        User = $_.'IdentityUser'
        MaximumRepeats = $xmlSchedule.ScheduleDetails.MaximumRepeats
        CompletedInstances = $xmlSchedule.ScheduleDetails.CompletedInstances
        IntervalType = $xmlSchedule.ScheduleDetails.RepeatInterval.Type
        CountBetweenIntervals= $xmlSchedule.ScheduleDetails.RepeatInterval.CountBetweenIntervals
        RuntimeDuration = 0
        PreviousRuntime = $xmlSchedule.ScheduleDetails.PreviousRuntime
        IntendedNextRuntime = $xmlSchedule.ScheduleDetails.IntendedNextRuntime
        EndOn = $xmlSchedule.ScheduleDetails.EndOn
        StartTime = $xmlSchedule.ScheduleDetails.StartTime
        EndTime = $xmlSchedule.ScheduleDetails.EndTime
    }

}

#Sort workflows by PreviousRuntime
$WFScheduleTable = $WFScheduleTable | Sort-Object -Property PreviousRuntime

#Calculate RuntimeDuration for each workflow
for($i=0; $i -lt $WFScheduleTable.Count; $i++) {
Write-Host "Loop" $i
if($_.PreviousRuntime -notlike "0001-01-01*" ){
$plusOne = $i+1
[DateTime]$thisRuntime = $WFScheduleTable[$i].PreviousRuntime
[DateTime]$thatRuntime = $WFScheduleTable[$plusOne].PreviousRuntime
$diff = $thatRuntime - $thisRuntime
$WFScheduleTable[$plusOne].RuntimeDuration = $diff.TotalMinutes
}
}

Write-Host 'Exporting File...'
#Exporting CSV file
$WFScheduleTable | Export-Csv -LiteralPath Output.csv -NoTypeInformation

Write-Host 'Complete!'

$scriptEnd = Get-Date
$scriptRuntime = New-TimeSpan -Start $scriptStart -End $scriptEnd

Write-Host "Runtime $scriptRuntime"