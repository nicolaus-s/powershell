# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    SPResolveUser.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    03/02/2021
#
# DESCRIPTION: Test and comparison of resolving user accounts using the built-in SharePoint and Nintex methods.
#
# =====================================================================================

cls
asnp *sh*
#Update the site URL and Shared Mailbox user name below
$web = Get-SPWeb http://[SiteURL]/
$login = "i:0#.w|domain\username"

#Variables below are used for method output; leave them empty.
$displayName = ""
$email = "" 

#SharePoint Method
[Microsoft.SharePoint.Utilities.SPUtility]::GetFullNameandEmailfromLogin($web, $login, [ref]$displayName, [ref]$email)

Write-Host "--SharePoint method output--"
Write-Host ""
Write-Host "Display Name:" $displayName
Write-Host "Email:" $email
Write-Host ""

#Nintex Method
[void][System.Reflection.Assembly]::LoadWithPartialName("Nintex.Workflow")
[Nintex.Workflow.HumanApproval.UserInfo]::GetDisplayNameAndEmail($web, $login, [ref]$displayName, [ref]$email)

Write-Host "--Nintex Workflow method output--"
Write-Host ""
Write-Host "Display Name:" $displayName
Write-Host "Email:" $email
Write-Host ""