# ====================================================================================
# Microsoft PowerShell Script
# 
# NAME:		    Access Form Data XML.ps1
# AUTHOR:	    Nick Shaffer
# DATE:		    11/21/2023
#
# DESCRIPTION:	Queries a SharePoint list item to retrieve Nintex Form data, and Repeating Section data. This short script was written as an example for a Nintex user to 
#               help them understand how to retrieve this data, and write additional lines to process the data as they see fit.
#
# =====================================================================================

#Get Item object
#Change [SITE URL] to the relevant SharePoint site URL i.e. https://company.domain.com/mysubsite
$siteURL = "http://[SITE URL].com/"

#Change 'My Data' below to the SharePoint list name
$list = "My Data"
$web = Get-SPWeb -Identity $siteURL

#Item ID is hardcoded to 1, but can be hardcoded to any existing item ID on the SharePoint list. Alternatively, this line could be changed to get all item IDs, and all following lines could be placed within a loop.
$item = $web.Lists[$list].GetItemById('1')

#Convert 'Form Data' from string to XML
[xml]$formData = $item["Form Data"]

#Retrieve 'Repeater' node. This will only be present if a Repeating Section is on the form.
$repeaterData = Select-XML -Xml $formData -XPath '//Repeater'

#Decode 'Repeater' node to be proper XML
[xml]$decodeXML = [System.Web.HTTPUtility]::HtmlDecode($repeaterData.Node.InnerText)

#Note: At this point in the script, $formData variable is your form XML, and the $decodeXML variable is the Repeating Section XML nested within the Form XML. You can add additional processing below to work with these variables further.
