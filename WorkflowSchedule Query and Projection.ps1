# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    WorkflowSchedule Query and Projection.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    12/23/2021
#
# DESCRIPTION:	Parses the Schedule column from the WorkflowSchedule table to calculate runtime durations for each scheduled workflow over the last 24 hours.
#
#
# =====================================================================================

#$outputPath = Read-Host "Enter full output path"

#Add PowerShell Snap-in
Add-PSSnapin Microsoft.SharePoint.PowerShell

#Load Nintex Workflow Assembly
[void][System.Reflection.Assembly]::LoadWithPartialName("Nintex.Workflow")

#Open connection to Nintex Configuration Database
$sqlConn = New-Object System.Data.SqlClient.SqlConnection
$sqlConn.ConnectionString = [Nintex.Workflow.Administration.ConfigurationDatabase]::GetConfigurationDatabase().SQLConnectionString
$sqlConn.Open()

#Construct and Execute SQL Command to get contents of WorkflowSchedule table
$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
$sqlCmd.CommandText = "SELECT * FROM WorkflowSchedule"
$sqlCmd.Connection = $sqlConn

#Instantiate array for workflow schedules
$WFScheduleTable = @()


$sqlRead = $sqlCmd.ExecuteReader()
$sqlCount = $sqlRead.FieldCount

#Iterate through each row
while($sqlRead.Read()){
    #Iterate through each field
    for($i=0; $i -lt $sqlCount; $i++){
        #Set variables for each field
        switch($sqlRead.GetName($i)) {

            'ScheduleId' {$scheduleId = $sqlRead.GetValue($i)}
            'ItemId' {$itemId = $sqlRead.GetValue($i)}
            'ListId' {$listId = $sqlRead.GetValue($i)}
            'WebId' {$webId = $sqlRead.GetValue($i)}
            'SiteId' {$siteId = $sqlRead.GetValue($i)}
            'WorkflowId' {$workflowId = $sqlRead.GetValue($i)}
            'NextRunTime' {$nextRunTime = $sqlRead.GetValue($i)}
            'Schedule' {$schedule = $sqlRead.GetValue($i)}
            'StartData' {$startData = $sqlRead.GetValue($i)}
            'ModifiedBy' {$modifiedBy = $sqlRead.GetValue($i)}
            'IsBroken' {$isBroken = $sqlRead.GetValue($i)}
            'IdentityUser' {$identityUser = $sqlRead.GetValue($i)}

        }
    }

        #Parse and extract data from shedule XML
        $str = $schedule
        $index = $str.IndexOf("<MaximumRepeats>")
        $replaceMe = $str.Substring(0, $index)
        $trimSchedule = $str.Replace($replaceMe, "<ScheduleDetails>")
        $xmlSchedule = [xml]$trimSchedule

        #Create workflow schedule object for current row
        $WFScheduleTable += [PSCustomObject]@{
 
        ScheduleId = $scheduleId
        ItemId = $itemId
        ListId = $listId
        WebId = $webId
        SiteId = $siteId
        WorkflowId = $workflowId
        NextRunTime = $nextRunTime
        User = $identityUser
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

#Reading all records is complete; closing SQL connection
$sqlConn.Close()

#Sort arary by last run time
$WFScheduleTable = $WFScheduleTable | Sort-Object -Property PreviousRuntime
$ntxWfScheduler = Get-SPTimerJob | ? {$_.DisplayName -eq "Nintex Workflow Scheduler"}
$ntxWFSLast24Hours = $ntxWfScheduler.HistoryEntries | ? {$_.StartTime -ge (Get-Date).AddHours(-24)}


#Calculate runtime duration for each workflow schedule
for($i=0; $i -lt $WFScheduleTable.Count; $i++) {
Write-Host "Loop" $i
if($_.PreviousRuntime -notlike "0001-01-01*"){
for($h=1;$ntxWFSLast24Hours[$ntxWFSLast24Hours.Count-$h].StartTime -lt $WFScheduleTable[$i].PreviousRuntime;$h++){
[DateTime]$lastWFSInstance = $ntxWFSLast24Hours[$ntxWFSLast24Hours.Count-$h].StartTime
}
[DateTime]$thisRuntime = $WFScheduleTable[$i].PreviousRuntime
[DateTime]$thenRuntime = $WFScheduleTable[$i-1].PreviousRuntime
if($lastWFSInstance -gt $thenRuntime -or $i -lt 1){
$diff = $thisRuntime - $lastWFSInstance
}
else {
$diff = $thisRuntime - $thenRuntime
}
$WFScheduleTable[$i].RuntimeDuration = $diff.TotalMinutes
}
}

$WFScheduleByDuration = $WFScheduleTable | Sort-Object -Property RuntimeDuration -Descending



#$WFScheduleTable | Export-Csv -LiteralPath $outputPath -NoTypeInformation

#$WFScheduleTable | Out-GridView

