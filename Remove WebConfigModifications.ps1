# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Remove WebConfigModifications.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    06/10/2022
#
# DESCRIPTION:	Removes items from the WebConfigModifications property of a SharePoint Web Application; used in the context of removing remnants of removed features.
#
# =====================================================================================

#Enter your web application URL
$webApp = Get-SPWebApplication "[WEB APPLICATION URL]";

#This example removes 'Nintex.Workflow' modifications. Change this to target your desired group/type of entries.
$nwfMods = $webApp.WebConfigModifications | ? {$_.Value -like "*Nintex.Workflow*"};

#Loop through each modification that is found, removes it, and updates the change on each iteration.
foreach($mod in $nwfMods){
Write-Host "Removing " + $mod.Value;
$webApp.WebConfigModifications.Remove($mod);
$webApp.Update()
};