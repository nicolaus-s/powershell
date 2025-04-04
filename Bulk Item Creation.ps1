# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Bulk Item Creation.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    7/25/2022
#
# DESCRIPTION: Used when many items are needed on a SharePoint list for testing, but creating items manually isn't feasible. This script simply loops 5000 times, using the AddItem() method on the List object.
#
#
# =====================================================================================
 
Add-PSSnapin Microsoft.Sharepoint.Powershell

$web = get-spweb "http://[SITE URL].com/"
$list = $web.Lists["Random Data List"]
for ($i=1; $i -le 5000; $i++) 
{
$item = $list.AddItem()
$item["Title"] = "Test " + $i
$item.Update()
} 
