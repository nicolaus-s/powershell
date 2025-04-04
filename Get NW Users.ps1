# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Get NAC Users.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    03/12/2025
#
# DESCRIPTION:	Queries the Nintex Automation Cloud tenant for all users and outputs them into a CSV file. This is necessary due to a limit in how many users can be viewed at once in the user interface.
#
# =====================================================================================

$now = Get-Date
$body = @{"client_id"="[NW CLIENT ID]";"client_secret"="[NW CLIENT SECRET]";"grant_type"="client_credentials"}
$authResponse = Invoke-WebRequest https://us.nintex.io/authentication/v1/token -Body ($body | ConvertTo-Json) -Method POST -ContentType "application/json"

$jsonResponse = $authResponse.Content | ConvertFrom-Json
$token = "Bearer " + $jsonResponse.access_token

$headers=@{}
$headers.Add("Accept", "application/json")
$headers.Add("Authorization", $token)
$body=@{}

$response = Invoke-RestMethod -Uri 'https://us.nintex.io/tenants/v1/users' -Method GET -Headers $headers -Body $body

$fileName = "C:\NW Users Report " + $now.ToShortDateString().Replace("/","-") + ".csv"
$response.users | Export-Csv -LiteralPath $fileName -NoTypeInformation
