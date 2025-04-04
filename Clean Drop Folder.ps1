# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Clean Drop Folder.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    6/14/2023
#
# DESCRIPTION: Used to clean a SMTP Drop folder that was saturated with emails from an automated system, in which the automated system was emailing, and replying to, itself, causing an infinite loop of emails.
#              To break this cycle, this script was used to delete any of these undesired email messages. The script also offers the ability to copy the .eml files to another location prior
#              to deleting them. Original email addresses in this script have been replaced with [EMAIL ADDRESS] for privacy.
#
# =====================================================================================

#Regex to find 'To' and 'From' fields
[string]$toRegex = '^To:'
[string]$fromRegex = '^From:'

Get-ChildItem C:\inetpub\mailroot\Drop | ForEach-Object {

#Get eml file path
$filePath = $_.FullName
#Get eml file content
$emlFile = Get-Content -Path $filePath
#Get 'To' field
$emlTo = $emlFile -match $toRegex
#Get 'From' field
$emlFrom = $emlFile -match $fromRegex
#Remove 'To: ' from the value, leaving only the email
$toAddress = $emlTo.Replace("To: ", "")
#Remove 'From: ' from the value, leaving only the email
$fromAddress = $emlFrom.Replace("From: ", "")
#If the 'To' and 'From' fields both equal '[EMAIL ADDRESS]', delete the eml file from the Drop folder 
if($toAddress -eq '[EMAIL ADDRESS]' -and $fromAddress -eq '[EMAIL ADDRESS]'){
    #To backup eml files before deleting them, uncomment the line below and add a -Destination folder path.
    #Copy-Item -Path $filePath -Destination '[Folder Path]' #Create a new folder and replace [Folder Path] with the new folder's path
    Remove-Item -Path $filePath
    }

}
