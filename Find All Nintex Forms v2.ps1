# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Find All Nintex Forms v2.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    01/18/2024
#
# DESCRIPTION:	Searches for the 'NintexForms' library on each site within the SharePoint farm. If the 'NintexForms' library exist, the script will retrieve the properties of each XML file and
#               outputs the information into a CSV file.
#
# =====================================================================================
 
Add-PSSnapin Microsoft.SharePoint.PowerShell
$erroractionpreference = 'Continue'
$sites = Get-SPWebApplication | get-spsite -Limit All | Get-SPWeb -Limit All
$formsTable = @()

    foreach($s in $sites){

        $formlib = $s.Lists | ? {$_.Title -eq "NintexForms"}
        if($formlib.Title -ne $null){
        $forms = $formlib.GetItems() | ? {$_.Name -notlike "*.preview.xml"}

        foreach($form in $forms){
            [xml]$xml = $form.Xml
            $list = $s.Lists | ? {$_.ID -eq $form.Properties.FormListId}
            $formsTable += [PSCustomObject]@{
                Site = $s.URL
                List = $list
                LastPublished = $xml.ChildNodes.ows_Modified
                Author = $xml.ChildNodes.ows_Modified_x0020_By
                LastUsed = $list.LastItemUserModifiedDate.ToShortDateString()
                }
            }
        }
    }

    $formsTable | Export-CSV -LiteralPath C:\AllForms.csv -NoTypeInformation
    #$formsTable | Out-GridView
