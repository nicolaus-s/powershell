$errorLog = @()
$ErrorActionPreference = 'Continue'
$scriptStart = Get-Date

Write-Host 'Importing File...'

$logFile = Import-Csv -Delimiter "`t" -LiteralPath 'C:\Scripts\ParseLogs\USATRAMEGB069 Combined.log' | Where-Object {($_.'Message ' -Like 'In RunWorkflowElev(), begin processing events for instance:*') -OR ($_.'Message ' -Like 'RunWorkflow: Events successfully delivered to Instance:*')}

Write-Host 'Filtering Beginning Values...'

$beginTable = @()

$logFile | Where-Object -Property 'Message ' -Like 'In RunWorkflowElev(), begin processing events for instance:*' | ForEach-Object {


    $beginTable += [PSCustomObject]@{
        
        Timestamp = [datetime]::parseexact($_.'Timestamp '.Trim(), 'MM/dd/yyyy HH:mm:ss.ff', $null)
        Process = $_.'Process '
        Correlation = $_.'Correlation'
        # Message = $_.'Message '
        Instance = $_.'Message '.Replace('In RunWorkflowElev(), begin processing events for instance:','').Trim()

    }

}

Write-Host 'Filtering Ending Values...'

$endTable = @{}

$ErrorActionPreference = 'SilentlyContinue'

$logFile | Where-Object -Property 'Message ' -Like 'RunWorkflow: Events successfully delivered to Instance:*' | ForEach-Object {

    $Error.Clear()

    $parseEndMessage = $_.'Message '.Replace('RunWorkflow: Events successfully delivered to Instance:','').Trim()
    $parseEndMessage = $parseEndMessage.Substring(0,$parseEndMessage.IndexOf(',')).Trim()
    $hashKey = $_.'Correlation' + $parseEndMessage

    $endTable.Add($hashKey,[datetime]::parseexact($_.'Timestamp '.Trim(), 'MM/dd/yyyy HH:mm:ss.ff', $null))

    If ($Error) {

        $errorString = ("Duplication found on Correlation ID $($_.'Correlation') and Instance ID $parseEndMessage")
        Write-Host $errorString
        $errorLog += $errorString

    }

}

$ErrorActionPreference = 'Continue'

Write-Host 'Checking Run Times...'

$compareTable = @()

$beginTable | ForEach-Object {

    $startTime = $_.Timestamp
    $startCorrelation = $_.Correlation
    $startInstance = $_.Instance
    $hashKey = $startCorrelation + $startInstance
    
    $endTime = $endTable[$hashKey]

    If ($endTime -NE $null) {

        $runTime = New-TimeSpan -Start $startTime -End $endTime

        $compareTable += [PSCustomObject]@{

            Correlation = $startCorrelation
            Instance = $startInstance
            Process = $_.Process
            StartTime = $startTime
            EndTime = $endTime
            RunTimeMilliseconds = $runTime.TotalMilliseconds

        }

    } else {
   
        $compareTable += [PSCustomObject]@{

            Correlation = $startCorrelation
            Instance = $startInstance
            Process = $_.Process
            StartTime = $startTime
            EndTime = 'No EndTime Found'
            RunTimeMilliseconds = 'No EndTime Found'

        }                

    }

}

Write-Host 'Exporting File...'

$compareTable | Sort-Object RunTimeMilliseconds -Descending | Export-Csv -LiteralPath C:\Scripts\ParseLogs\Test5.csv -NoTypeInformation
$errorLog | Out-File -LiteralPath C:\Scripts\ParseLogs\Duplication_Log.txt

Write-Host "Counted $($errorLog.Count) duplication errors, please review Duplication Log for possible manual checks."
Write-Host 'Complete!'

$scriptEnd = Get-Date
$scriptRuntime = New-TimeSpan -Start $scriptStart -End $scriptEnd

Write-Host "Runtime $scriptRuntime"