# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Remove Non-Existent User Data.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    02/08/2022
#
# DESCRIPTION: Written for a specific scenario. Nintex Forms wouldn't open due to non-existent users that couldn't be resolved by SharePoint. The script queries each form for user names, attempts
#	       to resolve each user, and removes the user if resolution failed. Lines 52 - 54 are commented out for testing, and a CSV file is output at the end to show which users were removed from where.
#              Original values have been replaced with placeholders for privacy of the original SharePoint environment.
# =====================================================================================

#Add SharePoint snap-in and Nintex Forms assembly
$ErrorActionPreference = "SilentlyContinue"
Add-PSSnapin Microsoft.SharePoint.Powershell
[void][System.Reflection.Assembly]::LoadWithPartialName("Nintex.Forms.SharePoint")

#Create People control properties object as required for Nintex Forms resolve method
[Nintex.Forms.SharePoint.FormControls.PeoplePickerFormControlProperties] $controlProperties = New-Object Nintex.Forms.SharePoint.FormControls.PeoplePickerFormControlProperties

#Get List Items
$siteURL = "[SITE URL]"
$list = "[LIST NAME]"
$web = Get-SPWeb -Identity $siteURL
$allItems = $web.Lists[$list].Items

$impactedItemsTable = @()

#Loop through each list item
foreach ($item in $allItems){
    [xml]$xml = $item["Form Data"]
    $repeaterData = Select-XML -xml $xml -XPath "//CONTROL_NAME"
    [xml]$xmlDecode = [System.Web.HttpUtility]::HtmlDecode($repeaterData.Node.'#text')
    $users = Select-XML -xml $xmlDecode -XPath "/RepeaterData/Items/Item/Control_Name" | ForEach-Object {$_.Node.InnerXML}
    $index = 0    
        #Loop through each user
        foreach ($user in $users){
            $index++
			$Error.Clear()
            if($user -ne ""){
            Write-Host "Resolving user:" $user
            [Nintex.Forms.SharePoint.Helper]::ResolvePeoplePickerValue($user, $web, $controlProperties)
            $errorText = $Error[0].Exception.ToString()                
                if ($errorText.Contains("was not resolved. Verify control configuration.")){
                    Write-Host $user "does not exist."
                    $impactedItemsTable += [PSCustomObject]@{                  
                    ItemID = $item.ID
                    BadUser = $user
                    Action = $user + " has been removed from the control on row " + $index + "."
                    ErrorMessage = $errorText
                    }
                    #Lines are commented out to protect data while reviewing and testing the script. Uncomment to allow the script to update list items.
                    #$item["Form Data"] = $item["Form Data"].Replace($user,"")
                    #$item.Update()
                }
                elseif ($errorText -ne $null){
                    $impactedItemsTable += [PSCustomObject]@{                  
                    ItemID = $item.ID
                    BadUser = $user
                    Action = $user + " failed to resolve, but was NOT removed from the form."
                    ErrorMessage = $errorText
                    }
                }
            }
        }
}

$impactedItemsTable | Export-CSV -LiteralPath C:\BadUsersReport.csv -NoTypeInformation
