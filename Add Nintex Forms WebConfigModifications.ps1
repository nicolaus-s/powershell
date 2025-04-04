# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Add Nintex Forms WebConfigModifications.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    2/27/2024
#
# DESCRIPTION:	It's expected that activating the Nintex Forms web application feature will add the appropriate WebConfigModifications to the web application, and update the 
#               web.config file accordingly. If these entries aren't added as expected, this script is used to repeat the same procedure via PowerShell without manipulating the
#               Nintex Forms web application feature.
#
# REFERENCES: https://devblogs.microsoft.com/scripting/use-powershell-to-script-changes-to-the-sharepoint-web-config-file/
#
# NOTE: When in doubt, you can manully check the WebConfigModifications property of a web application by using the following code lines in PowerShell:
#          
#          $webApp = Get-SPWebApplication -Identity http://[WebAppURL] 
#          $webApp.WebConfigModifications | Out-GridView
#           
#        There should be 4 entries total for Nintex Forms. If the WebConfigModifications exist, but are still missing from the web.config file, you can update the web.config file
#        via PowerShell with the following lines.
#          
#          $SPCS = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
#	       $SPCS.ApplyWebConfigModifications()
#
#
# =====================================================================================

cls
Write-Host "This script will add Nintex Forms web.config entries for a web application.`n" 
Read-Host "Please ensure that the Nintex Forms web application feature is activated for the web application before proceeding. Press any key to continue"

$webAppUrl = Read-Host "Please enter the Web Application URL"
Write-Host `n
$SPCS = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
$webApp = Get-SPWebApplication -Identity $webAppUrl



if($webApp -ne $null) {

    Write-Progress -Activity "Found web application" -Status 'Progress'

    Write-Progress -Activity "Creating object for Nintex Forms web.config modification 1/4" -Status 'Progress' -PercentComplete 10
    $mod1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
    $mod1.Name = "add[@expressionPrefix='NFResources'][@type='Nintex.Forms.SharePoint.NFResourceExpressionBuilder, Nintex.Forms.SharePoint, Version=1.0.0.0, Culture=neutral, PublicKeyToken=c52d764dcf7ec883']"
    $mod1.Path = "configuration/system.web/compilation/expressionBuilders"
    $mod1.Sequence = 0
    $mod1.Owner = "NWF_C2EB4E26-3C47-4557-912B-1E72FC8FB593"
    $mod1.Value = "<add expressionPrefix='NFResources' type='Nintex.Forms.SharePoint.NFResourceExpressionBuilder, Nintex.Forms.SharePoint, Version=1.0.0.0, Culture=neutral, PublicKeyToken=c52d764dcf7ec883' />"
    $mod1.Type = "EnsureChildNode"

    Write-Progress -Activity "Creating object for Nintex Forms web.config modification 2/4" -Status 'Progress' -PercentComplete 20
    $mod2 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
    $mod2.Name = "SafeControl[@Assembly='Nintex.Forms.SharePoint, Version=1.0.0.0, Culture=neutral, PublicKeyToken=c52d764dcf7ec883'][@Namespace='Nintex.Forms.SharePoint.WebParts.InitiateWorkflow']"
    $mod2.Path = "/configuration/SharePoint/SafeControls"
    $mod2.Sequence = 0
    $mod2.Owner = "NWF_C2EB4E26-3C47-4557-912B-1E72FC8FB593"
    $mod2.Value = '<SafeControl Assembly="Nintex.Forms.SharePoint, Version=1.0.0.0, Culture=neutral, PublicKeyToken=c52d764dcf7ec883" Namespace="Nintex.Forms.SharePoint.WebParts.InitiateWorkflow" TypeName="*" Safe="True" SafeAgainstScript="False" />'
    $mod2.Type = "EnsureChildNode"

    Write-Progress -Activity "Creating object for Nintex Forms web.config modification 3/4" -Status 'Progress' -PercentComplete 30
    $mod3 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
    $mod3.Name = "SafeControl[@Assembly='Nintex.Forms.SharePoint, Version=1.0.0.0, Culture=neutral, PublicKeyToken=c52d764dcf7ec883'][@Namespace='Nintex.Forms.SharePoint.WebParts.NFListFormWebpart']"
    $mod3.Path = '/configuration/SharePoint/SafeControls'
    $mod3.Sequence = 0
    $mod3.Owner = "NWF_C2EB4E26-3C47-4557-912B-1E72FC8FB593"
    $mod3.Value = '<SafeControl Assembly="Nintex.Forms.SharePoint, Version=1.0.0.0, Culture=neutral, PublicKeyToken=c52d764dcf7ec883" Namespace="Nintex.Forms.SharePoint.WebParts.NFListFormWebpart" TypeName="*" Safe="True" SafeAgainstScript="False" />'
    $mod3.Type = "EnsureChildNode"

    Write-Progress -Activity "Creating object for Nintex Forms web.config modification 4/4" -Status 'Progress' -PercentComplete 40
    $mod4 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
    $mod4.Name = "SafeControl[@Assembly='Nintex.Forms.SharePoint, Version=1.0.0.0, Culture=neutral, PublicKeyToken=c52d764dcf7ec883'][@Namespace='Nintex.Forms.SharePoint.WebControls']"
    $mod4.Path = '/configuration/SharePoint/SafeControls'
    $mod4.Sequence = 0
    $mod4.Owner = "NWF_C2EB4E26-3C47-4557-912B-1E72FC8FB593"
    $mod4.Value = '<SafeControl Assembly="Nintex.Forms.SharePoint, Version=1.0.0.0, Culture=neutral, PublicKeyToken=c52d764dcf7ec883" Namespace="Nintex.Forms.SharePoint.WebControls" TypeName="*" Safe="True" SafeAgainstScript="False" />'
    $mod4.Type = "EnsureChildNode"

    Write-Progress -Activity "Checking if Nintex Forms web.config modification exists 1/4" -Status 'Progress' -PercentComplete 50
    if(!$webApp.WebConfigModifications.Contains($mod1)){
        Write-Progress -Activity "Not found - Adding Nintex Forms web.config modification 1/4" -Status 'Progress' -PercentComplete 55
        $webApp.WebConfigModifications.Add($mod1)
        $webApp.Update()
    }
    
    Write-Progress -Activity "Checking if Nintex Forms web.config modification exists 2/4" -Status 'Progress' -PercentComplete 60
    if(!$webApp.WebConfigModifications.Contains($mod2)){
        Write-Progress -Activity "Not found - Adding Nintex Forms web.config modification 2/4" -Status 'Progress' -PercentComplete 65
        $webApp.WebConfigModifications.Add($mod2)
        $webApp.Update()
    }

    Write-Progress -Activity "Checking if Nintex Forms web.config modification exists 3/4" -Status 'Progress' -PercentComplete 70
    if(!$webApp.WebConfigModifications.Contains($mod3)){
        Write-Progress -Activity "Not found - Adding Nintex Forms web.config modification 3/4" -Status 'Progress' -PercentComplete 75
        $webApp.WebConfigModifications.Add($mod3)
        $webApp.Update()
    }

    Write-Progress -Activity "Checking if Nintex Forms web.config modification exists 4/4" -Status 'Progress' -PercentComplete 80
    if(!$webApp.WebConfigModifications.Contains($mod4)){
        Write-Progress -Activity "Not found - Adding Nintex Forms web.config modification 4/4" -Status 'Progress' -PercentComplete 85
        $webApp.WebConfigModifications.Add($mod4)
        $webApp.Update()
}

    Write-Progress -Activity "All Nintex Forms web.config modifications exist. Updating web.config file" -Status 'Progress' -PercentComplete 100
    $SPCS.ApplyWebConfigModifications()

    Write-Host "Changes complete. Please test Nintex Forms on a site within your web application`n" -BackgroundColor Green
    }

if($webApp -eq $null) {
Write-Host "Web Application not found. Please check the web application URL in Central Administration and try again. URL Example: http://webapp.domain.com`n" -BackgroundColor Red
}