# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Find All Nintex Forms (Excluding WF forms).ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    09/30/2021
#
# DESCRIPTION:	Queries the NintexForms hidden library and loops through each XML file to identify where the form in question is published. each XML file represents a published form. This script doesn't locate
#               Nintex task forms as task form definitions or stored directly within it's host workflow definition.
# =====================================================================================

asnp *sh*
$erroractionpreference = 'SilentlyContinue'
$sites = Get-SPWebApplication | get-spsite -Limit All | Get-SPWeb -Limit All
$formsTable = @()

    foreach($s in $sites){

        $formlib = $s.Lists | ? {$_.Title -eq "NintexForms"}
        $forms = $formlib.GetItems() | ? {$_.Name -notlike "*.preview.xml"}

        foreach($form in $forms){

            $list = $s.Lists | ? {$_.ID -eq $form.Properties.FormListId}
            $formsTable += [PSCustomObject]@{
                Site = $s.URL
                List = $list
                ContentTypeID = $form.Properties.FormContentTypeId
                }
            }
    }

    $formsTable | Export-CSV -LiteralPath C:\AllForms.csv -NoTypeInformation